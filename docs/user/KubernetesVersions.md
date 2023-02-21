# Kubernetes Versions

Setting versions within the Google Cloud Platform (GCP) environment is slightly different from setting a version within other cloud providers

There are two scenarios that are supported. These are:

- Version Based
- Channel Based

These options are ***mutually exclusive***. If you choose [Version Based](#version-based) you can specify a version and not a channel. If you choose [Channel Based](#channel-based) you can choose a channel and you'll be assigned the `defaultVersion` for that channel.

In the examples below value `LOCATION` can refer to a region or zone depending on how you are setting up your cluster. it's up to you to determine the correct value for the location that will translate back into the tfvars file value to create the cluster.

## Version Based

Setting a specific version of your kubernetes cluster is derived by finding the active `version` values for your zone/region.

To do this run the following command:

```bash
export LOCATION="<your desired location>"
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone $LOCATION
```

The output for this command will display a list of currently supported kubernetes versions that can be used on the current control plane nodes of your cluster.

Here's an example of running the command and that output:

```bash
export LOCATION="us-east1-b"
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone $LOCATION
Fetching server config for us-east1-b
validMasterVersions:
- 1.25.6-gke.1000
- 1.25.6-gke.200
- 1.25.5-gke.2000
- 1.24.9-gke.3200
- 1.24.9-gke.2000
- 1.24.9-gke.1500
- 1.24.8-gke.2000
- 1.23.16-gke.1100
- 1.23.16-gke.200
- 1.23.15-gke.1900
- 1.23.15-gke.1400
- 1.23.14-gke.1800
- 1.23.14-gke.401
- 1.23.13-gke.900
- 1.22.17-gke.4000
- 1.22.17-gke.3100
- 1.22.16-gke.2000
- 1.22.16-gke.1300
- 1.22.15-gke.2500
- 1.22.15-gke.1000
- 1.21.14-gke.15800
- 1.21.14-gke.14600
- 1.21.14-gke.14100
- 1.21.14-gke.8500
- 1.21.14-gke.7100
```

**NOTE**: This value will also be the value applied to the compute nodes of your custer.

From here you would take one of these values and set the `kubernetes_version` variable in your tfvars files like this:

```terraform
kubernetes_version = "1.24.9-gke.3200"
```

Do not set the `kubernetes_channel` variable.

**NOTE**: If you find that the version you would like to use in your kubernetes cluster is not listed, you will need to go the [Channel Based](#channel-based) section to find the desired version.

### Aliased Versions

Only applicable in the "version based" scenario (omitting `kubernetes_channel` or setting it to "UNSPECIFIED"), Google supports the use of [aliased versions](https://cloud.google.com/kubernetes-engine/versioning#specifying_cluster_version) when creating your kubernetes cluster. The format required looks like:

* 1.X
  * Specifies the highest valid patch+gke.N patch release in the 1.X minor version
* 1.X.Y
  * Specifies the highest valid gke.N patch in the 1.X.Y patch release.


**Example: 1.X Format**

In your tfvars you would set the `kubernetes_version` variable in like so:

```terraform
kubernetes_version = "1.24"
```

Going by the list of versions from the output of the `gcloud container get-server-config` command above, this assignment results in a cluster being created with the version `1.24.9-gke.3200`, since Google chooses the "highest valid patch+gke.N patch release in the 1.24 minor version"

**Example: 1.X.Y Format**

In your tfvars you would set the `kubernetes_version` variable in like so:

```terraform
kubernetes_version = "1.23.15"
```

Going by the list of versions from the output of the `gcloud container get-server-config` command above, this assignment results in a cluster being created with the version `1.23.15-gke.1900`, since Google chooses the "highest valid gke.N patch in the 1.23.15 patch release."


## Channel Based

Setting a specific channel for  your kubernetes cluster will use the `defaultVersion` provided by that channel. This is the only way to work with a version of kubernetes that has been recently released and/or is not listed in the [Version Based](#version-based) section.

To find out what versions are supported by which channel you first run this command:

```bash
export LOCATION="<your desired location>"
gcloud container get-server-config --format "yaml(channels)" --zone $LOCATION
```

The output from this command will display the channels and their current `defaultVersion` value. This `defaultVersion` value is what will be assigned to your cluster upon creation.

Here's an example of running the command and that output:

```bash
export LOCATION="us-east1-b"
gcloud container get-server-config --format "yaml(channels)" --zone $LOCATION
Fetching server config for us-east1-b
channels:
- channel: RAPID
  defaultVersion: 1.25.6-gke.200
  validVersions:
  - 1.26.1-gke.200
  - 1.25.6-gke.1000
  - 1.25.6-gke.200
  - 1.24.9-gke.3200
  - 1.23.16-gke.1100
  - 1.23.16-gke.200
  - 1.22.17-gke.4000
  - 1.22.17-gke.3100
  - 1.21.14-gke.15800
- channel: REGULAR
  defaultVersion: 1.24.9-gke.2000
  validVersions:
  - 1.25.5-gke.2000
  - 1.24.9-gke.2000
  - 1.23.14-gke.1800
  - 1.22.16-gke.2000
  - 1.21.14-gke.14600
- channel: STABLE
  defaultVersion: 1.23.14-gke.1800
  validVersions:
  - 1.24.9-gke.1500
  - 1.23.14-gke.1800
  - 1.22.16-gke.2000
  - 1.21.14-gke.14600
  - 1.21.14-gke.14100
```

From this example output if you are looking to create a kubernetes cluster with v1.25 then you would choose the 'RAPID' channel.

From here you would set the `kubernetes_channel` variable in your tfvars files like this:

```terraform
kubernetes_channel = "RAPID"
```

This assignment results in a cluster being created with the version: `1.25.6-gke.200` for this example.

Do not set the `kubernetes_version` variable.
