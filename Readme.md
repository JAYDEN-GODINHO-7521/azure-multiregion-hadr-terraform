# Multi-Region Active-Active HA/DR Architecture on Microsoft Azure

A production-grade, multi-region High Availability and Disaster Recovery (HA/DR) cloud architecture deployed across Microsoft Azure's `centralindia` and `indiasouthcentral` regions. Designed around Site Reliability Engineering (SRE) principles, this project demonstrates automated global traffic failover, blast-radius state isolation, zero-trust identity federation, multi-region data replication, and multi-replica Kubernetes load balancing using **Terraform** and **Kubernetes**.

## 1. Architectural Overview & Design Decisions

### Blast-Radius Isolation via Per-Region Terraform State

Rather than managing the entire global footprint inside a single monolithic Terraform state file, this project separates infrastructure into three isolated root stacks (`live/centralindia`, `live/indiasouthcentral`, and `live/global`).

* **Why it matters:** A misconfiguration, provider lock, or state corruption in `centralindia` cannot impact `indiasouthcentral` or the global routing layer. Regional upgrades and rollbacks can be executed independently with zero cross-region blast radius.

### Non-Overlapping Network Topology

Each region operates within its own dedicated Virtual Network (VNet) using strictly non-overlapping CIDR blocks. This prevents IP address collisions across regions and prepares the network for seamless VNet peering, private endpoint routing, and hybrid connectivity without NAT workarounds.

### Global DNS Routing & Automated Failover (Azure Traffic Manager)

Incoming client traffic hits a single global DNS endpoint (`tm-hadr-global.trafficmanager.net`) managed by **Azure Traffic Manager**:

* **Active-Active Distribution:** Configured with weighted/priority routing across the regional Azure `LoadBalancer` public IPs.

* **Continuous Health Probing:** Traffic Manager actively probes regional endpoints at `10s` intervals. If a region fails consecutive health checks, Traffic Manager automatically marks the endpoint `Degraded` and removes it from DNS responses (`30s` TTL), shifting traffic to the surviving region.

* *(Architectural Note: Azure Front Door was evaluated for L7 anycast routing and WAF, with Azure Traffic Manager selected for broad subscription tier compatibility and deterministic DNS-level failover.)*

### Multi-Region Data Layer (Azure Cosmos DB)

Stateless compute failover only works if the underlying data tier survives a regional outage without data loss:

* **Geo-Replication & Low Latency:** **Azure Cosmos DB** replicates data across `centralindia` and `indiasouthcentral`, allowing regional AKS pods to read and write against their local region with minimal latency.

* **Automated Regional Failover:** In the event of a regional outage in `centralindia`, Cosmos DB automatically promotes the `indiasouthcentral` replica to maintain read/write availability with near-zero Recovery Point Objective (RPO).

### Zero-Trust Workload Identity Federation

To eliminate hardcoded credentials, service principal secrets, and manual secret rotation:

* Regional **AKS clusters** (`aks-hadr-centralindia`, `aks-hadr-indiasouthcentral`) are configured with OIDC Issuer and Workload Identity enabled.

* A User-Assigned Managed Identity is bound to a Kubernetes `ServiceAccount` via `azurerm_federated_identity_credential` (`api://AzureADTokenExchange`), granting pods direct, short-lived token access to **Azure Key Vault** and regional Azure services.

### Multi-Tier Compute & Regional Load Balancing

* **Node Pool Separation:** AKS clusters separate system workloads (`systempool`) from application workloads (`appspool`) so traffic spikes cannot starve critical cluster components (`coredns`, `metrics-server`, cloud controller manager).

* **Redundant Pod Replicas & L4 Load Balancing:** Each regional cluster runs `4` replicas of the `api` Deployment inside the `app2` namespace with active `readinessProbe` and `livenessProbe` health checks (`HTTP GET /` on port `8080`). An Azure Standard `LoadBalancer` Service (`api-lb`) exposes port `80` externally and distributes traffic across healthy pods in that region.

## 2. Repository Structure

```text
.
├── live/
│   ├── centralindia/            # centralindia regional Terraform stack (isolated state)
│   ├── indiasouthcentral/       # indiasouthcentral regional Terraform stack (isolated state)
│   └── global/                  # Global Azure Traffic Manager stack (isolated state)
├── modules/
│   ├── networking/              # Regional VNets, subnets, and non-overlapping CIDRs
│   ├── compute/                 # AKS clusters, node pools, Managed Identity & OIDC federation
│   ├── data/                    # Multi-region Azure Cosmos DB & Azure Key Vault
│   └── routing/                 # Azure Traffic Manager profile, DNS config & health probes
└── k8s/
    └── sample-app.yaml          # `app2` Namespace, 4-replica `api` Deployment & `api-lb` LoadBalancer
```

## 3. End-to-End Deployment Guide

### Prerequisites

* **Azure CLI** (`az login` authenticated to your target subscription)

* **Terraform** `>= 1.7.0`

* **kubectl** `>= 1.28`

### Step 1: Provision Regional Infrastructure (`centralindia` & `indiasouthcentral`)

Deploy both regional stacks to stand up the VNets, Cosmos DB, Key Vaults, and AKS clusters:

```bash
# Deploy centralindia
cd live/centralindia
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# Deploy indiasouthcentral
cd ../indiasouthcentral
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Deploy Workloads & LoadBalancer to Both AKS Clusters

Authenticate to each regional AKS cluster and deploy the `app2` namespace, the `4`-replica `api` Deployment, and the `api-lb` `LoadBalancer` Service:

```bash
# centralindia Cluster
az aks get-credentials -g rg-ha-dr-compute-centralindia -n aks-hadr-centralindia --overwrite-existing
kubectl apply -f k8s/base/sample-app.yaml
kubectl get pods,svc -n app1

# indiasouthcentral Cluster
az aks get-credentials -g rg-ha-dr-compute-indiasouthcentral -n aks-hadr-indiasouthcentral --overwrite-existing
kubectl apply -f k8s/base/sample-app2.yaml
kubectl get pods,svc -n app2
```

> **Note:** Wait 1–2 minutes for Azure to provision the external LoadBalancer IPs, then record the `EXTERNAL-IP` of `api-lb` in each region and pass them into `live/global/terraform.tfvars`.

### Step 3: Deploy Global Traffic Manager Routing

Update `live/global/terraform.tfvars` with your `centralindia` and `indiasouthcentral` `api-lb` external IP addresses, then deploy the global stack:

```bash
cd live/global
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## 4. Validating Active-Active Routing & Failover

### Verify Global Endpoint Health

Confirm that Azure Traffic Manager resolves and marks both regional endpoints as `Online`:

```bash
terraform -chdir=live/global output fqdn

az network traffic-manager profile show \
  -g rg-ha-dr-global \
  -n tm-hadr-global \
  --query "endpoints[].{Name:name,Status:endpointMonitorStatus,Target:target,Weight:weight}" \
  -o table
```

### Simulate a Regional Outage (Failover Drill)

1. **Start continuous traffic polling** against the Traffic Manager FQDN:

   ```bash
   TM_FQDN=$(terraform -chdir=live/global output -raw fqdn)
   while true; do
     printf "%s | " "$(date -u +%H:%M:%S)"
     curl -s -m 3 -w "HTTP %{http_code} | %{time_total}s\n" "http://${TM_FQDN}/" || echo "TIMEOUT"
     sleep 2
   done
   ```

2. **Induce failure in `centralindia`** by scaling the regional deployment in `app1` to zero replicas:

   ```bash
   kubectl config use-context aks-hadr-centralindia
   kubectl scale deployment api -n app1 --replicas=0
   ```

3. **Observe recovery:** Traffic Manager detects probe failures (`10s` interval × `2` tolerated failures), transitions `ep-centralindia` to `Degraded`, and shifts 100% of DNS responses to `indiasouthcentral` once the `30s` DNS TTL expires.

4. **Restore `centralindia`:**

   ```bash
   kubectl scale deployment api -n app1 --replicas=4
   ```

## 5. Cost Management & Teardown

Running multi-region AKS clusters, LoadBalancers, and Cosmos DB incurs continuous hourly charges. Tear down the stacks in reverse order (`global` first, then regional stacks) when testing is complete:

```bash
terraform -chdir=live/global destroy -auto-approve
terraform -chdir=live/indiasouthcentral destroy -auto-approve
terraform -chdir=live/centralindia destroy -auto-approve
```