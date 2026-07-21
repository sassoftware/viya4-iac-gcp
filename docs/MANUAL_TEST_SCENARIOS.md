# viya4-iac-gcp – Minimum Test Scenarios for Release

**Purpose:** Define the minimum manual test scenarios required before releasing the viya4-iac-gcp code. These scenarios focus on the highest-risk configurations and common use cases.

---

## Quick Release Checklist (5–10 minutes)

Before running full test scenarios, verify these static checks:

- [ ] Terraform code lints cleanly: `terraform fmt -check` and `terraform validate`
- [ ] No hard-coded credentials in `.tfvars` examples
- [ ] Example `.tfvars` files are syntactically valid HCL
- [ ] README.md and CONFIG-VARS.md are up-to-date with new variable changes
- [ ] Module documentation reflects recent changes
- [ ] Version constraints in `versions.tf` are reasonable (Terraform, Google provider)
- [ ] No deprecated GCP resources are used (check Google provider docs)
- [ ] Changelog or release notes document breaking changes (if any)

---

## Minimum Test Scenarios

Run **AT LEAST** these three scenarios before releasing. Each takes 20–40 minutes.

### Scenario 1: Zonal + Standard NFS (Fastest)

**Purpose:** Validate baseline single-zone deployment with NFS storage.  
**Time:** ~20–25 min | **Cost:** ~$3–5  
**Terraform file:** `sample-input.tfvars` or use defaults

#### Pre-flight Checks
```bash
export PROJECT_ID="<your-gcp-project>"
export REGION="us-east1"
export ZONE="us-east1-b"
export PREFIX="test-zonal-nfs-$(date +%s)"

gcloud config set project $PROJECT_ID
gcloud container get-server-config --region=$REGION  # verify GKE availability
```

#### Terraform Steps
```bash
cd /path/to/viya4-iac-gcp

# 1. Prepare tfvars
cat > /tmp/test-scenario1.tfvars <<EOF
prefix                  = "$PREFIX"
location                = "$ZONE"
project                 = "$PROJECT_ID"
service_account_keyfile = "<your-sa-json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"
kubernetes_version      = "1.34"
storage_type            = "standard"
storage_type_backend    = "nfs"
postgres_servers = {
  default = {}
}
EOF

# 2. Initialize
terraform init

# 3. Plan
terraform plan -var-file=/tmp/test-scenario1.tfvars -out=/tmp/plan1.tfplan

# Expected: ~40–50 resources (GKE, VPC, subnets, NFS VM, Postgres, etc.)
# Verify: NFS VM is in the plan, Postgres server is created

# 4. Apply
terraform apply /tmp/plan1.tfplan

# Time: 15–20 minutes
```

#### Post-Deployment Tests
```bash
# A. Get credentials
gcloud container clusters get-credentials \
  $(terraform output -raw kubernetes_cluster_name) \
  --zone=$ZONE --project=$PROJECT_ID

# B. Verify cluster health
kubectl cluster-info
kubectl get nodes        # All nodes should be Ready
kubectl get pods -A      # System pods should be Running

# C. Test storage mount
cat <<'K8SEOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
  namespace: default
spec:
  accessModes: [ "ReadWriteMany" ]
  storageClassName: "standard-rwo"
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-pod
  namespace: default
spec:
  containers:
  - name: test
    image: alpine:latest
    volumeMounts:
    - name: nfs
      mountPath: /mnt/nfs
    command: ['sh', '-c']
    args:
      - |
        echo "Testing NFS storage" > /mnt/nfs/test.txt
        cat /mnt/nfs/test.txt
        sleep 300
  volumes:
  - name: nfs
    persistentVolumeClaim:
      claimName: test-nfs-pvc
K8SEOF

# Wait 30 seconds, then check pod logs
kubectl logs test-nfs-pod  # Should show "Testing NFS storage"

# D. Test Postgres connectivity (if provisioned)
# Get Postgres IP from Terraform output
POSTGRES_IP=$(terraform output -raw postgres_server_ip)
POSTGRES_ADMIN_PW=$(terraform output -raw postgres_admin_password)

# From a VM with psql installed:
psql -h $POSTGRES_IP -U postgres -W  # Use password from output
\dt                                   # Should list system tables
\q

# E. Cleanup test resources
kubectl delete pvc test-nfs-pvc
kubectl delete pod test-nfs-pod
```

#### Pass Criteria
- ✅ `terraform plan` shows expected resource count
- ✅ `terraform apply` completes with 0 errors
- ✅ GKE cluster status is `RUNNING`; all nodes `Ready`
- ✅ All system pods (dns, logging, monitoring) are `Running` or `Succeeded`
- ✅ Storage mount test pod writes and reads file successfully
- ✅ Postgres accepts connections and has system tables

#### Cleanup
```bash
terraform destroy -var-file=/tmp/test-scenario1.tfvars -auto-approve
# Wait 5 minutes for all resources to fully delete
gcloud compute networks list  # Verify VPC is gone
```

---

### Scenario 2: Regional Multi-Zone + HA NetApp (Complex)

**Purpose:** Validate multi-zone HA deployment with NetApp zone-redundant storage.  
**Time:** ~35–40 min | **Cost:** ~$8–12  
**Terraform file:** `sample-input-multizone.tfvars`

#### Pre-flight Checks
```bash
export PROJECT_ID="<your-gcp-project>"
export REGION="us-east1"           # Must be a REGION, not a ZONE
export PREFIX="test-multizone-$(date +%s)"

gcloud config set project $PROJECT_ID
# Verify NetApp availability in region
gcloud compute regions list --filter="name:$REGION" --format="value(name)"
```

#### Terraform Steps
```bash
cd /path/to/viya4-iac-gcp

# 1. Prepare tfvars (or use sample-input-multizone.tfvars)
cat > /tmp/test-scenario2.tfvars <<EOF
prefix                  = "$PREFIX"
location                = "$REGION"
project                 = "$PROJECT_ID"
service_account_keyfile = "<your-sa-json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"
kubernetes_version      = "1.34"
regional                = true
kubernetes_channel      = "REGULAR"
storage_type            = "ha"
storage_type_backend    = "netapp"
enable_netapp_dns       = true
netapp_service_level    = "FLEX"
netapp_capacity_gib     = 2048
default_nodepool_locations = "us-east1-b,us-east1-c,us-east1-d"
nodepools_locations        = "us-east1-b,us-east1-c,us-east1-d"
postgres_servers = {
  default = {}
}
EOF

# 2. Initialize
terraform init

# 3. Plan
terraform plan -var-file=/tmp/test-scenario2.tfvars -out=/tmp/plan2.tfplan

# Expected: ~60–80 resources (regional GKE, NetApp volumes, CZR setup, DNS zone, etc.)
# Verify: "google_netapp_storage_pool" and "google_private_dns_zone" in plan

# 4. Apply
terraform apply /tmp/plan2.tfplan

# Time: 20–25 minutes
```

#### Post-Deployment Tests
```bash
# A. Get credentials (regional cluster)
gcloud container clusters get-credentials \
  $(terraform output -raw kubernetes_cluster_name) \
  --region=$REGION --project=$PROJECT_ID

# B. Verify cluster health across zones
kubectl get nodes -o wide  # Nodes in 3 zones (b, c, d)
kubectl top nodes          # CPU/memory usage (may take 1 min)

# C. Verify GKE is regional
gcloud container clusters describe \
  $(terraform output -raw kubernetes_cluster_name) \
  --region=$REGION \
  --format="value(location_type, locations)"
# Should show: location_type = REGION, locations = [us-east1-b, us-east1-c, us-east1-d]

# D. Test NetApp volume
cat <<'K8SEOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-netapp-pvc
spec:
  accessModes: [ "ReadWriteMany" ]
  storageClassName: "netapp-cvs"   # For NetApp backend
  resources:
    requests:
      storage: 100Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-netapp-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-netapp
  template:
    metadata:
      labels:
        app: test-netapp
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: ["test-netapp"]
              topologyKey: topology.kubernetes.io/zone
      containers:
      - name: test
        image: alpine:latest
        volumeMounts:
        - name: netapp
          mountPath: /mnt/netapp
        command: ['sh', '-c']
        args:
          - |
            hostname > /mnt/netapp/$(hostname).txt
            sleep 300
      volumes:
      - name: netapp
        persistentVolumeClaim:
          claimName: test-netapp-pvc
K8SEOF

# Wait 30 seconds
kubectl get pods -o wide | grep test-netapp
# Should show 3 pods distributed across 3 zones

# E. Verify NetApp DNS
DNS_ZONE=$(terraform output -raw netapp_dns_zone_name)
DNS_RECORD=$(terraform output -raw netapp_dns_record_name)
# Query private DNS from a pod inside the cluster
kubectl exec -it $(kubectl get pod -l app=test-netapp -o name | head -1) -- \
  sh -c "nslookup $DNS_RECORD"
# Should resolve to NetApp endpoint IP

# F. Cleanup test resources
kubectl delete deployment test-netapp-deploy
kubectl delete pvc test-netapp-pvc
```

#### Pass Criteria
- ✅ GKE cluster location_type is `REGION`, not `ZONE`
- ✅ Nodes exist in all 3 zones
- ✅ NetApp storage pool is created (check Cloud Console)
- ✅ Private DNS zone exists with A record for NetApp endpoint
- ✅ Multi-pod deployment distributes pods across zones
- ✅ All pods successfully mount and write to NetApp volume
- ✅ Pod DNS queries resolve NetApp endpoint

#### Cleanup
```bash
terraform destroy -var-file=/tmp/test-scenario2.tfvars -auto-approve
# Wait 10 minutes (NetApp volumes may take time to delete)
```

---

### Scenario 3: BYO Network + Optional CAS (Edge Case)

**Purpose:** Validate bring-your-own-network path and optional CAS pool (programming-only).  
**Time:** ~30 min | **Cost:** ~$4–6  
**Terraform file:** Use custom tfvars combining BYO + minimal CAS

#### Pre-flight: Create VPC + Subnets (Manual or Terraform)
```bash
export PROJECT_ID="<your-gcp-project>"
export REGION="us-east1"
export PREFIX="test-byo-$(date +%s)"

# Create VPC
gcloud compute networks create "${PREFIX}-vpc" --region=$REGION

# Create subnets
gcloud compute networks subnets create "${PREFIX}-gke-subnet" \
  --network="${PREFIX}-vpc" \
  --region=$REGION \
  --range="10.0.1.0/24" \
  --secondary-range="pods=10.4.0.0/14,services=10.0.16.0/20"

gcloud compute networks subnets create "${PREFIX}-misc-subnet" \
  --network="${PREFIX}-vpc" \
  --region=$REGION \
  --range="10.0.2.0/24"

# Reserve static IP for NAT
gcloud compute addresses create "${PREFIX}-nat-ip" --region=$REGION

# Record values for tfvars
VPC_NAME="${PREFIX}-vpc"
SUBNET_GKE="${PREFIX}-gke-subnet"
SUBNET_MISC="${PREFIX}-misc-subnet"
NAT_IP="${PREFIX}-nat-ip"
```

#### Terraform Steps
```bash
cd /path/to/viya4-iac-gcp

# 1. Prepare tfvars for BYO network + optional CAS
cat > /tmp/test-scenario3.tfvars <<EOF
prefix                  = "$PREFIX"
location                = "$REGION-b"  # Single zone
project                 = "$PROJECT_ID"
service_account_keyfile = "<your-sa-json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"
kubernetes_version      = "1.34"

# BYO Network
vpc_name = "$VPC_NAME"
subnet_names = {
  gke                     = "$SUBNET_GKE"
  gke_pods_range_name     = "pods"
  gke_services_range_name = "services"
  misc                    = "$SUBNET_MISC"
}
nat_address_name = "$NAT_IP"

# No CAS node pool (optional)
node_pools = {
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels = {
      "workload.sas.com/class" = "compute"
    }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels = {
      "workload.sas.com/class" = "stateless"
    }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

storage_type         = "standard"
storage_type_backend = "nfs"
postgres_servers = {
  default = {}
}
EOF

# 2. Initialize
terraform init

# 3. Plan
terraform plan -var-file=/tmp/test-scenario3.tfvars -out=/tmp/plan3.tfplan

# Expected: GKE uses pre-existing VPC/subnets; no new VPC created
# Verify: google_container_cluster has network = $VPC_NAME and network_config references subnets

# 4. Apply
terraform apply /tmp/plan3.tfplan

# Time: 15–20 minutes
```

#### Post-Deployment Tests
```bash
# A. Verify GKE is in BYO VPC
gcloud container clusters describe \
  $(terraform output -raw kubernetes_cluster_name) \
  --zone=$REGION-b \
  --format="value(network, subnetwork)"
# Should show: network = $VPC_NAME, subnetwork = $SUBNET_GKE

# B. Get credentials
gcloud container clusters get-credentials \
  $(terraform output -raw kubernetes_cluster_name) \
  --zone=$REGION-b

# C. Verify no CAS node pool
kubectl get nodes -L workload.sas.com/class
# Should show only 'compute' and 'stateless' labels; no 'cas' nodes

# D. Test NFS storage from compute pool
COMPUTE_NODE=$(kubectl get nodes -l "workload.sas.com/class=compute" -o name | head -1 | cut -d/ -f3)
kubectl debug node/$COMPUTE_NODE -it --image=alpine:latest -- \
  sh -c "mount | grep nfs"
# Should show NFS mount for SAS storage

# E. Cleanup test resources
```

#### Pass Criteria
- ✅ Terraform does NOT create new VPC (uses pre-existing)
- ✅ GKE cluster network matches BYO VPC name
- ✅ No CAS node pool; only compute and stateless pools exist
- ✅ NFS server is deployed and mounted on Compute nodes
- ✅ All nodes have correct workload class labels

#### Cleanup
```bash
terraform destroy -var-file=/tmp/test-scenario3.tfvars -auto-approve
# Wait 5 minutes

# Delete BYO network resources
gcloud compute addresses delete "${PREFIX}-nat-ip" --region=$REGION --quiet
gcloud compute networks delete "${PREFIX}-vpc" --quiet
```

---

## Full Test Permutation Matrix (Optional – Extended Release)

For **major releases** (0.1.0 → 0.2.0), run all 20 scenarios from `REGRESSION_TEST_MATRIX.md`.  
For **patch releases** (0.1.0 → 0.1.1), run minimum 3 scenarios above + any scenarios related to code changes.

---

## Known Issues & Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Error: Error creating Network: conflict` | VPC already exists from previous failed run | `terraform destroy` first; or use different `prefix` |
| `Error: Error creating GKECluster: 403 Forbidden` | Insufficient IAM permissions or quotas | Check GCP quotas; ensure service account has `container.admin` role |
| `terraform plan` shows old storage pool | State file mismatch | `terraform refresh` or `terraform state pull > backup.tfstate` |
| Nodes stuck in `NotReady` state for 5+ min | CNI networking issue or image pull timeout | Check node logs: `gcloud compute ssh <node> -- sudo journalctl -xe` |
| NetApp volume mount fails with permission error | Volume not provisioned yet | Wait 2–3 minutes after apply; NetApp is async |
| Postgres connection times out | Security group / firewall rule missing | Check GCP Compute Engine → VPC → Firewall rules for `postgres-allow-internal` |

---

## Test Automation Recommendations

For future sprint planning:

- **CI/CD Integration:** Use `terraform test` (Terraform 1.6+) to validate all tfvars examples
- **Scheduled Nightly Runs:** Deploy scenario 1 (zonal NFS) every night; verify and destroy
- **Multi-Cloud Testing:** Once Azure/AWS IAC mature, run parallel scenarios on all clouds
- **Performance Benchmarking:** Capture `terraform plan` timing; alert if plan time > 30s
- **Cost Tracking:** Log cloud billing per test run; alert if test cost exceeds budget

---

## Release Sign-Off Checklist

Before marking the release as "complete":

- [ ] All 3 minimum scenarios pass
- [ ] No Terraform warnings or linting errors
- [ ] Example `.tfvars` files are valid and documented
- [ ] Changelog is updated
- [ ] CHANGELOG.md / RELEASE_NOTES.md reference bug fixes and new features
- [ ] No hard-coded secrets in code or examples
- [ ] Git tag created: `git tag v<version> && git push origin v<version>`
- [ ] Release notes posted to GitHub / internal wiki
- [ ] Stakeholders notified (Slack, email, etc.)

---

## Test Automation Script (Optional)

Save as `test-release.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ID="${1:?Usage: ./test-release.sh <gcp-project-id>}"
SA_KEYFILE="${2:?Usage: ./test-release.sh <gcp-project-id> <sa-keyfile>}"

echo "=== Running Scenario 1: Zonal + NFS ==="
PREFIX="test-scenario1-$(date +%s)"
terraform apply -var="prefix=$PREFIX" -var="project=$PROJECT_ID" \
  -var="service_account_keyfile=$SA_KEYFILE" -auto-approve
echo "Waiting 5 min for cluster to stabilize..."
sleep 300
gcloud container clusters get-credentials "$(terraform output -raw kubernetes_cluster_name)" --zone=us-east1-b
kubectl cluster-info
terraform destroy -auto-approve

echo "=== Running Scenario 2: Regional Multi-Zone + NetApp ==="
PREFIX="test-scenario2-$(date +%s)"
# ... (similar pattern)

echo "✅ All scenarios passed!"
```

---

## Summary Table

| Scenario | Focus | Duration | Cost | Sample File | Storage |
|----------|-------|----------|------|-------------|---------|
| **1** | Baseline zonal | 20–25 min | $3–5 | `sample-input.tfvars` | NFS |
| **2** | Regional HA multi-zone | 35–40 min | $8–12 | `sample-input-multizone.tfvars` | NetApp |
| **3** | BYO network + optional CAS | 30 min | $4–6 | custom | NFS |

**Total for minimum release:** ~85–95 minutes, ~$15–23 per run.

