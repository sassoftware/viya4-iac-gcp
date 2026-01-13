<!-- Copilot instructions for the viya4-iac-gcp repository -->
# Copilot usage guidance — viya4-iac-gcp

Purpose: help AI coding agents be immediately productive editing, testing, and extending this Terraform-based GCP IaC repository for SAS Viya 4.

- Big picture
  - This repository is a Terraform project that provisions Google Cloud resources needed to deploy SAS Viya 4 (network, GKE cluster, nodepools, storage, optional Cloud SQL). See `README.md` and the architecture diagram in `docs/images/viya4-iac-gcp-diag.png`.
  - High-level entry points: `main.tf`, `vms.tf`, `network.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`. Reusable code lives under `modules/` (e.g. `modules/google_vm`, `modules/network`, `modules/google_netapp`, `modules/kubeconfig`).

- Where to look first (quick map)
  - Top-level: `README.md` (workflow summary), `versions.tf` (Terraform/provider constraints), `variables.tf` and `docs/CONFIG-VARS.md` (expected inputs).
  - Example configurations: `examples/` and `config/sample-input-tf-enterprise.tfvars`.
  - Authentication: `docs/user/TerraformGCPAuthentication.md` — Terraform uses a GCP service account (either via `GOOGLE_APPLICATION_CREDENTIALS` or `service_account_keyfile` TF variable).
  - Tests: `test/` contains Go/Terratest tests. `test/go.mod` shows dependencies (uses `gruntwork-io/terratest`).

- Project-specific conventions and important patterns
  - Variable-first design: most runtime behaviour is controlled by input variables and `.tfvars` files. Use `examples/*.tfvars` or `terraform.tfvars` for local runs.
  - Network safety: the project intentionally restricts administrative access by default — you must set `default_public_access_cidrs` / `cluster_endpoint_public_access_cidrs` in `docs/CONFIG-VARS.md` or your `tfvars` to permit admin access from your IPs.
  - Storage modes: `storage_type` controls NFS vs HA storage backends. When `storage_type=ha`, additional variables and roles are required (Filestore or NetApp). See `docs/CONFIG-VARS.md` storage sections and `docs/user/APIServices.md`.
  - Kubeconfig behavior: `create_static_kubeconfig` toggles generation of a static kubeconfig (service-account based) versus provider-managed kubeconfig.
  - FIPS support: `fips_enabled` enables FIPS 140-2 for Jump/NFS VMs using Ubuntu Pro FIPS 22.04 LTS images. GKE nodes use COS with FIPS-validated kernel crypto by default.

- Build / run / test workflows (how humans run things)
  - Local Terraform: ensure Terraform version matches `README.md` / `versions.tf` (referenced v1.10.x in docs). Typical flow:
    - `terraform init`
    - `terraform plan -var-file=examples/sample-input.tfvars` (or `-var-file=terraform.tfvars`)
    - `terraform apply -var-file=...`
  - Docker option: the repo supports running Terraform from `Dockerfile` / `docker-entrypoint.sh` — see `docs/user/DockerUsage.md` for containerized workflows.
  - Tests (Terratest): tests live under `test/` and use Terratest. To run locally:
    - Ensure Go toolchain and credentials are available.
    - Export credentials: `setx GOOGLE_APPLICATION_CREDENTIALS "C:\path\to\key.json"` (Windows PowerShell) or set `service_account_keyfile` in your tfvars.
    - Run: `cd test && go test ./... -v` (may require network, GCP access, and a real project).
  - CI: treat Terratest runs as integration-level; they require real cloud credentials and are usually gated in CI or run in isolated test projects.

- Integration points & external dependencies to be aware of
  - Google Cloud APIs and IAM roles: provisioning requires many GCP IAM roles (see `docs/user/TerraformGCPAuthentication.md` for the role list). Code assumes those roles exist on the service account used by Terraform.
  - Providers pinned via `versions.tf` — avoid changing provider constraints without cross-checking `README.md` and `test/go.mod` for compatibility.
  - Optional external systems: Filestore, NetApp, Cloud SQL; enabling those features changes required IAM roles and variables.

- Helpful examples and file references for common tasks
  - Add a new module: mirror patterns used in `modules/google_vm/main.tf` and `modules/network/main.tf` (inputs via `variables.tf`, outputs via `outputs.tf`).
  - Debugging Terraform: check `.tfstate` outputs and run `terraform plan` with `-var-file` matching examples in `examples/`.
  - Running tests locally: `cd test && go test -v` (Terratest uses real resource creation/destruction).

- Safeguards and dos/don'ts for an AI agent
  - Do not make changes that presume global resource names — preserve the `prefix` and other name variables used to avoid collisions.
  - When modifying provider or Terraform versions, update `README.md`, `versions.tf` and re-check `test/go.mod` for compatibility.
  - Add tests for changes that affect infrastructure behavior by updating or adding Terratest cases under `test/` rather than only unit tests.

- Next steps and how to ask for more
  - If you want a module template, a small `tfvars` example for a minimal test, or a checklist for running a local Terratest run in an ephemeral project, ask for that specific artifact and I will add it.
