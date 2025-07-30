# Community-Contributed Configuration Variables

Community contributed configuration variables are listed in the tables below. These variables can also be specified on the terraform command line.

> [!CAUTION]
> Community members are responsible for maintaining these features. While project maintainers try to verify these features work as expected when merged, they cannot guarantee future releases will not break them. If you encounter issues while using these features, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-gcp/discussions) or open a Pull Request to fix them. As a last resort, you can create a GitHub Issue.

**Instructions for use**: Replace the Community Feature TOC entry and section name with your new Community Feature name. Include information about the feature. Include any warnings and a table documenting the associated community contributed configuration variables by replacing each placeholder below with the information relevant to your community contributed feature.

## Table of Contents

- [Community-Contributed Configuration Variables](#community-contributed-configuration-variables)
  - [Table of Contents](#table-of-contents)
  - [Community Feature](#community-feature)
  - [Netapp Networking Components Enabled](#netapp-networking-components-enabled)

<a name="community_feature"></a>
## Community Feature

Here is some information about Community Feature.

Here is a warning about why it might cause issues.

Here is a table with the variables you would use to configure it

| Name | Description | Type | Default | Release Added | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| community_enable_community_feature | Enable community feature | bool | false | vMajor.Minor.Patch | |

<a name="netapp_networking_components_enabled"></a>
## Netapp Networking Components Enabled

Netapp Networking Components Enabling allows for control of the deployment of Netapp networking components when deploying HA with Netapp Volumes as the backend. This leaves the expectation that the Network Peering and IP ranges for Netapp have already been configured for the subscription and this Terraform project is just deploying some extra volumes. 

An example case where this would be necessary: two clusters using HA with Netapp Volumes are being deployed to the same project. In this case, the first cluster will be able to register the private IP range and the peering. The second cluster will need to disable the deployment of these components.

There are no checks that the Netapp Peering and IP Ranges have been properly configured. That is left to the Terraform Apply to detect any deployment issues or the usability of the resulting platform to determine any permission issues.

| Name | Description | Type | Default | Release Added | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| community_netapp_networking_components_enabled | Enable Netapp networking components | bool | true | v7.6.3 | |
