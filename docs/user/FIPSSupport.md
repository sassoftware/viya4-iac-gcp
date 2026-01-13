# FIPS 140-2 Support for viya4-iac-gcp

## Overview

This document outlines the implementation plan for adding Federal Information Processing Standard (FIPS) 140-2 support to the viya4-iac-gcp project, based on the implementation in viya4-iac-azure.

The Federal Information Processing Standard (FIPS) 140 is a US government standard that defines minimum security requirements for cryptographic modules in information technology products and systems. Enabling FIPS 140-2 support helps meet security controls as part of FedRAMP compliance.

## Reference Implementation (Azure)

The Azure implementation (`viya4-iac-azure`) provides FIPS support through:

1. **Variable Declaration** (`variables.tf`):
   ```hcl
   ## Enable FIPS support
   variable "fips_enabled" {
     description = "Enables the Federal Information Processing Standard for the nodes and VMs in this cluster. Changing this forces a new resource to be created."
     type        = bool
     default     = false
   }
   ```

2. **AKS Cluster Integration** (`main.tf`):
   - Passes `fips_enabled` to the AKS module
   - Applies to the default node pool

3. **Additional Node Pools** (`modules/aks_node_pool`):
   - Each node pool accepts `fips_enabled` parameter
   - Applied uniformly across all node pools

4. **Jump and NFS VMs** (`modules/azurerm_vm`):
   - When `fips_enabled=true`, uses Ubuntu Pro FIPS 22.04 LTS image
   - Dynamically switches OS offer and SKU:
     ```hcl
     source_image_reference {
       publisher = var.os_publisher
       offer     = var.fips_enabled ? "0001-com-ubuntu-pro-jammy-fips" : var.os_offer
       sku       = var.fips_enabled ? "pro-fips-22_04" : var.os_sku
       version   = var.os_version
     }
     
     dynamic "plan" {
       for_each = var.fips_enabled ? [1] : []
       content {
         name      = "pro-fips-22_04"
         publisher = "canonical"
         product   = "0001-com-ubuntu-pro-jammy-fips"
       }
     }
     ```

5. **Documentation** (`docs/CONFIG-VARS.md`):
   - Explains FIPS 140-2 standard
   - Provides acceptance command for Ubuntu Pro FIPS image terms
   - Documents the `fips_enabled` variable

## GCP Implementation Plan

### 1. GKE FIPS Support

Google Kubernetes Engine (GKE) does **not** natively support FIPS-validated cryptographic modules at the node pool level like Azure AKS does. However, there are alternative approaches:

#### Option A: Use COS with FIPS Kernel Module (Recommended)
- GKE nodes can use **Container-Optimized OS (COS)** with FIPS-validated kernel crypto modules
- Not a full FIPS-validated image, but kernel cryptography is FIPS 140-2 validated
- Reference: [GKE FIPS Compliance Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/fips-compliance)

#### Option B: Use Ubuntu with FIPS Enabled
- Use **Ubuntu Pro FIPS 22.04 LTS** images for GKE nodes
- Requires custom node pool configuration with specific image
- May require GKE node image customization

#### Option C: Custom Node Image with FIPS
- Build custom GCE images with FIPS-enabled Ubuntu
- Use custom images for GKE node pools
- More complex but provides full FIPS validation

### 2. Jump/NFS VM FIPS Support

For Jump and NFS VMs (created via `modules/google_vm`), implement similar logic to Azure:

1. **Add Ubuntu Pro FIPS Image Support**:
   - Google Cloud Marketplace offers Ubuntu Pro FIPS images
   - Image family: `ubuntu-pro-fips-2204-lts-amd64`
   - Project: `ubuntu-os-pro-cloud`
   - **Note**: Ubuntu 22.04 LTS is used because FIPS 140-2 certification for Ubuntu 24.04 may not yet be available. FIPS certification requires 12-18 months of NIST validation, so certified images are typically 1-2 LTS versions behind the latest Ubuntu release.

2. **Conditional Image Selection**:
   ```hcl
   # In modules/google_vm/main.tf
   data "google_compute_image" "vm_image" {
     family  = var.fips_enabled ? "ubuntu-pro-fips-2204-lts" : var.os_image_family
     project = var.fips_enabled ? "ubuntu-os-pro-cloud" : var.os_image_project
   }
   
   resource "google_compute_instance" "vm" {
     # ... other configuration
     boot_disk {
       initialize_params {
         image = data.google_compute_image.vm_image.self_link
       }
     }
   }
   ```

### 3. Files to Modify

#### 3.1 `variables.tf` (root level)
Add global FIPS variable:
```hcl
## Enable FIPS support
variable "fips_enabled" {
  description = "Enables the Federal Information Processing Standard for the nodes and VMs in this cluster. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}
```

#### 3.2 `main.tf` (root level)
Pass `fips_enabled` to GKE and VM modules:
```hcl
module "gke" {
  source = "./modules/google_gke"
  # ... existing parameters
  fips_enabled = var.fips_enabled
}
```

#### 3.3 `modules/google_vm/variables.tf`
Add FIPS variable to VM module:
```hcl
variable "fips_enabled" {
  description = "Should the VM use FIPS 140-2 validated cryptographic modules? Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "os_image_family" {
  description = "The image family to use for the VM."
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "os_image_project" {
  description = "The project containing the OS image."
  type        = string
  default     = "ubuntu-os-cloud"
}
```

#### 3.4 `modules/google_vm/main.tf`
Implement conditional image selection:
```hcl
data "google_compute_image" "vm_image" {
  family  = var.fips_enabled ? "ubuntu-pro-fips-2204-lts" : var.os_image_family
  project = var.fips_enabled ? "ubuntu-os-pro-cloud" : var.os_image_project
}

resource "google_compute_instance" "vm" {
  # ... existing configuration
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.vm_image.self_link
      size  = var.os_disk_size
      type  = var.os_disk_type
    }
  }
  
  # ... rest of configuration
}
```

#### 3.5 `vms.tf` (root level)
Pass `fips_enabled` to Jump and NFS modules:
```hcl
module "jump" {
  source = "./modules/google_vm"
  # ... existing parameters
  fips_enabled = var.fips_enabled
}

module "nfs" {
  source = "./modules/google_vm"
  # ... existing parameters
  fips_enabled = var.fips_enabled
}
```

#### 3.6 `docs/CONFIG-VARS.md`
Add FIPS section similar to Azure:
```markdown
## Security

The Federal Information Processing Standard (FIPS) 140 is a US government standard that defines minimum security requirements for cryptographic modules in information technology products and systems. Enabling FIPS 140-2 support helps meet security controls as part of FedRAMP compliance. For more information on FIPS 140-2, see [Federal Information Processing Standard (FIPS) 140](https://csrc.nist.gov/pubs/fips/140-2/upd2/final).

### FIPS Support for Jump and NFS VMs

To enable FIPS support for Jump and NFS VMs, set the `fips_enabled` variable to `true`. This will use Ubuntu Pro FIPS 22.04 LTS images for these VMs.

**Note:** You must accept the terms for Ubuntu Pro FIPS images before deploying. You can do this via:
1. Google Cloud Console: Visit the [Ubuntu Pro FIPS 22.04 LTS](https://console.cloud.google.com/marketplace/product/ubuntu-os-pro-cloud/ubuntu-pro-fips-2204-lts) marketplace page
2. Or use gcloud CLI (if available for programmatic acceptance)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| fips_enabled | Enables the Federal Information Processing Standard for Jump and NFS VMs in this deployment | bool | false | Ensure marketplace terms are accepted before enabling |

### FIPS Support for GKE Nodes

Google Kubernetes Engine (GKE) provides FIPS 140-2 validated cryptographic modules through Container-Optimized OS (COS). For full FIPS compliance requirements, consult [GKE FIPS Compliance Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/fips-compliance).

**Current Limitations:**
- GKE does not provide a direct `fips_enabled` flag like Azure AKS
- COS nodes use FIPS-validated kernel crypto modules by default
- For stricter FIPS requirements, custom node images may be required
```

#### 3.7 `docs/user/FIPSSupport.md` (this document)
Create comprehensive FIPS support documentation.

### 4. Testing Considerations

1. **Acceptance Tests**:
   - Verify Ubuntu Pro FIPS image is used when `fips_enabled=true`
   - Confirm standard Ubuntu image is used when `fips_enabled=false`
   - Test Jump VM and NFS VM boot with FIPS images

2. **Terratest Updates** (`test/`):
   - Add test case in `test/nondefaultplan/` for FIPS-enabled configuration
   - Validate image family and project in plan output
   - Example:
     ```go
     func TestFIPSEnabled(t *testing.T) {
       // Verify FIPS image is selected when fips_enabled=true
       expectedImageFamily := "ubuntu-pro-fips-2204-lts"
       expectedImageProject := "ubuntu-os-pro-cloud"
       // ... assertions
     }
     ```

3. **Example tfvars** (`examples/`):
   - Add `examples/sample-input-fips.tfvars` demonstrating FIPS configuration

### 5. GKE-Specific Considerations

Since GKE doesn't have native FIPS node pool flags, document the following:

1. **Current State**:
   - GKE COS nodes use FIPS 140-2 validated kernel modules
   - No additional configuration needed for kernel-level FIPS

2. **Future Enhancement (if required)**:
   - For full FIPS-validated images, consider:
     - Custom GKE node pools with Ubuntu Pro FIPS images
     - Use `node_config.image_type` to specify custom images
     - Requires building and maintaining custom node images

3. **Documentation Clarity**:
   - Clearly state that `fips_enabled` applies to Jump/NFS VMs only
   - Direct users to GCP documentation for GKE FIPS compliance
   - Provide guidance on custom node images if stricter requirements exist

## Implementation Checklist

- [ ] Add `fips_enabled` variable to root `variables.tf`
- [ ] Update `modules/google_vm/variables.tf` with FIPS-related variables
- [ ] Implement conditional image selection in `modules/google_vm/main.tf`
- [ ] Pass `fips_enabled` from root to modules in `vms.tf`
- [ ] Update `docs/CONFIG-VARS.md` with FIPS documentation
- [ ] Create comprehensive `docs/user/FIPSSupport.md` (this document)
- [ ] Add example configuration in `examples/sample-input-fips.tfvars`
- [ ] Add Terratest coverage for FIPS configurations
- [ ] Update `.github/copilot-instructions.md` with FIPS guidance
- [ ] Verify Ubuntu Pro FIPS image availability in target GCP regions
- [ ] Test deployment with `fips_enabled=true` and `fips_enabled=false`

## Ubuntu Pro Licensing and Billing

### ⚠️ Premium Image - Additional Costs Apply

Ubuntu Pro FIPS 22.04 LTS is a **premium image** that incurs additional costs beyond standard Compute Engine charges.

#### Key Points:
- **On-Demand Licensing**: Ubuntu Pro images running on GCP have on-demand licenses and do NOT require a separate Ubuntu Pro subscription
- **Automatic Billing**: GCP automatically reports usage to Canonical for licensing compliance
- **Billing Information Shared**: Google reports your billing entity name, region, country, SKU, and total usage hours to Canonical
- **Premium Pricing**: Additional per-hour fees apply on top of standard VM costs
- **No Separate Agreement Needed**: Unlike Azure marketplace images, GCP does not require explicit terms acceptance via CLI

#### Cost Estimation
Before deploying with `fips_enabled = true`, estimate costs for:
- **Jump VM**: Uses machine type from `jump_vm_machine_type` variable with Ubuntu Pro FIPS premium charges
- **NFS VM** (only if `storage_type=standard`): Uses machine type from `nfs_vm_machine_type` variable with Ubuntu Pro FIPS premium charges

**Resources:**
- [Ubuntu Pro Pricing on GCP](https://cloud.google.com/compute/docs/images/os-details#ubuntu_pro)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

## Image Verification

### Verifying Ubuntu Pro FIPS Image Availability

Before deploying, you can verify the Ubuntu Pro FIPS image exists in your GCP project:

```bash
# List all Ubuntu Pro FIPS images
gcloud compute images list \
  --project=ubuntu-os-pro-cloud \
  --filter="name:fips" \
  --format="table(name,family,creationTimestamp)"

# Check specific image family
gcloud compute images describe-from-family ubuntu-pro-fips-2204-lts-amd64 \
  --project=ubuntu-os-pro-cloud
```

**Expected image format**: `ubuntu-os-pro-cloud/ubuntu-pro-fips-2204-lts-amd64`

**Why Ubuntu 22.04 and not 24.04?**
- FIPS 140-2 certification requires 12-18 months of NIST validation
- Ubuntu 24.04 LTS (released April 2024) may not have completed FIPS certification yet
- Ubuntu 22.04 LTS has validated, production-ready FIPS images
- Once Ubuntu 24.04 FIPS images become available, the image name can be updated

**Note**: If the `gcloud` commands fail, ensure:
1. You have authenticated: `gcloud auth login`
2. Your project has access to public image projects
3. The Compute Engine API is enabled in your project

## References

- [Azure FIPS Implementation](https://github.com/sassoftware/viya4-iac-azure/blob/main/docs/CONFIG-VARS.md#security)
- [GKE FIPS Compliance](https://cloud.google.com/kubernetes-engine/docs/how-to/fips-compliance)
- [Ubuntu Pro FIPS on GCP](https://ubuntu.com/gcp/pro)
- [FIPS 140-2 Standard](https://csrc.nist.gov/pubs/fips/140-2/upd2/final)
- [Google Cloud Marketplace - Ubuntu Pro FIPS](https://console.cloud.google.com/marketplace/product/ubuntu-os-pro-cloud/ubuntu-pro-fips-2204-lts)

## Next Steps

1. **Prioritize Implementation Scope**:
   - Phase 1: Jump/NFS VM FIPS support (easier, follows Azure pattern)
   - Phase 2: Document GKE FIPS compliance (existing COS behavior)
   - Phase 3 (optional): Custom GKE node images with full FIPS validation

2. **Stakeholder Review**:
   - Confirm FIPS requirements for GKE nodes
   - Verify if COS kernel-level FIPS is sufficient or if custom images are needed

3. **Implementation**:
   - Follow the checklist above
   - Test thoroughly in isolated GCP project
   - Update CI/CD pipelines if needed

4. **Documentation**:
   - Ensure clarity on what is and isn't FIPS-validated
   - Provide clear guidance for users with strict compliance requirements
