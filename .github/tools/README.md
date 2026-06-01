# IaC Deprecation Scanner for viya4-iac-gcp

This directory contains tools to scan the Terraform codebase for deprecations and breaking changes in the Google Cloud Provider.

## Overview

The deprecation scanner validates your Terraform code against:
- **Google Provider CHANGELOG** - Tracks breaking changes, deprecations, and behavior changes in `hashicorp/google` and `hashicorp/google-beta` providers
- **IaC Best Practices** - Scans for deprecated patterns in Terraform, GitHub Actions, Kubernetes manifests, Docker, and shell scripts

## Quick Start

### Option 1: Run Full Integrated Scan (Recommended)

Runs both scanners and generates a unified HTML report:

```bash
cd /path/to/viya4-iac-gcp
python3 .github/tools/iac-scanner/run_full_scan.py
```

**Output files:**
- `iac-deprecation-report.html` - Visual report with all findings
- `iac-deprecation-report.json` - Machine-readable combined data

### Option 2: Run Individual Scanners

**IaC Pattern Scanner Only:**
```bash
python3 .github/tools/iac-scanner/demo.py
```

**Google Provider CHANGELOG Scanner Only:**
```bash
# Step 1: Generate manifest of current resources
python3 .github/tools/manifest/generate_manifest.py --root .

# Step 2: Check for deprecations
python3 .github/tools/manifest/check_deprecations.py --root .
```

## Using the Copilot Agent

An AI agent is available to run these scans automatically. In VS Code with GitHub Copilot:

1. Open the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. Type "run iac scan" or "check deprecations"
3. The agent will execute the appropriate scanner and present results

See `.github/agents/iac-deprecation.agent.md` for full agent documentation.

## How It Works

### Manifest Scanner (Google Provider CHANGELOG)

1. **Generate Manifest** (`generate_manifest.py`):
   - Scans all `.tf` files in the repository
   - Extracts all `google_*` resources and data sources
   - Records resource types, arguments, and file hashes
   - Saves to `.iac-manifest.json`

2. **Check Deprecations** (`check_deprecations.py`):
   - Reads current Google provider version from `versions.tf`
   - Fetches latest version from Terraform Registry
   - Downloads CHANGELOG from terraform-provider-google GitHub repo
   - Parses changes between your version and latest
   - Identifies resources you use that have breaking changes or deprecations
   - Generates `deprecation-report.json`

### IaC Pattern Scanner

Scans multiple file types for known deprecation patterns:
- **Terraform**: Deprecated resources, legacy syntax, outdated provider patterns
- **GitHub Actions**: Deprecated action versions, obsolete workflows
- **Kubernetes**: Deprecated API versions (e.g., `extensions/v1beta1`)
- **Docker**: Deprecated Dockerfile instructions
- **Shell Scripts**: Deprecated CLI commands

## Requirements

- Python 3.6 or higher (standard library only, no pip dependencies needed)
- Internet connection (to fetch Terraform Registry API and CHANGELOG)

## File Structure

```
.github/tools/
├── README.md                          # This file
├── manifest/
│   ├── generate_manifest.py          # Creates resource inventory
│   └── check_deprecations.py         # Compares against Google CHANGELOG
└── iac-scanner/
    ├── demo.py                        # Standalone pattern scanner demo
    ├── run_full_scan.py               # Integrated scanner (both tools)
    ├── requirements.txt               # Python dependencies (optional)
    └── scanner/                       # Scanner core modules
        ├── core.py
        ├── findings.py
        ├── report_generator.py
        └── ...
```

## Output Files

### `.iac-manifest.json`
Resource inventory showing:
- Google provider version from `versions.tf`
- All `google_*` resources in the codebase
- Arguments used for each resource type
- File hashes for change detection

### `deprecation-report.json`
Deprecation findings with:
- Severity levels (BREAKING, DEPRECATED, CHANGED)
- Affected resource types
- Specific files using deprecated features
- CHANGELOG excerpts with GitHub issue links
- Upgrade recommendations

### `iac-deprecation-report.html`
Visual HTML report combining:
- Manifest scanner findings (Google provider)
- IaC pattern scanner findings
- Summary statistics
- Detailed findings by severity

## Severity Levels

- **BREAKING** - Feature already removed or renamed; will break on upgrade
- **DEPRECATED** - Feature marked deprecated; still works but removal is planned
- **CHANGED** - Behavior change or bug fix; review recommended before upgrading

## Example Workflow

```bash
# 1. Clone the repository
git clone https://github.com/sassoftware/viya4-iac-gcp
cd viya4-iac-gcp

# 2. Run the integrated scan
python3 .github/tools/iac-scanner/run_full_scan.py

# 3. Open the HTML report
# Windows: start iac-deprecation-report.html
# macOS: open iac-deprecation-report.html
# Linux: xdg-open iac-deprecation-report.html

# 4. Review findings and plan upgrades
```

## Troubleshooting

**Error: "Python not found"**
- Install Python 3.6+ from python.org or via package manager
- On Windows, enable Python in Microsoft Store or use Chocolatey/Scoop

**Error: "Could not reach registry.terraform.io"**
- Check internet connection
- Verify firewall/proxy settings
- Try running with `--offline` flag (if available)

**Error: "versions.tf not found"**
- Ensure you're running from repository root
- Check that `versions.tf` exists in the root directory

**Error: "No resources found"**
- Verify `.tf` files exist in the repository
- Check that resources use `google_*` or `google-beta_*` naming

## Migration from Azure Version

This tool was adapted from the viya4-iac-azure deprecation scanner. Key changes:
- Azure Provider (`azurerm`) → Google Provider (`google`, `google-beta`)
- Azure CHANGELOG → Google CHANGELOG
- Registry endpoints updated for Google provider
- Resource type patterns updated for GCP naming conventions

## Contributing

To add new deprecation patterns or improve scanning:
1. Update pattern definitions in `scanner/data/`
2. Modify resource extraction logic in `manifest/generate_manifest.py`
3. Enhance severity classification in `manifest/check_deprecations.py`
4. Test against sample Terraform configurations

## License

Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
