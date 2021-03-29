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
export LOCATION="<your current working zone">
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone $LOCATION
```

The output for this command will display a list of currently supported kubernetes versions that can be used on the current control plane nodes of your cluster.

Here's an example of running the command and that output:

```bash
export LOCATION="us-east1-b"
gcloud container get-server-config --format "yaml(validMasterVersions)" --zone $LOCATION
Fetching server config for us-east1-b
validMasterVersions:
- 1.18.16-gke.1200
- 1.18.16-gke.500
- 1.18.16-gke.302
- 1.18.16-gke.300
- 1.18.15-gke.1502
- 1.18.15-gke.1501
- 1.18.15-gke.1500
- 1.18.15-gke.1102
- 1.18.15-gke.1100
- 1.18.14-gke.1600
- 1.18.14-gke.1200
- 1.18.12-gke.1210
- 1.17.17-gke.3700
- 1.17.17-gke.3000
- 1.17.17-gke.2800
- 1.17.17-gke.1500
- 1.17.17-gke.1101
- 1.17.17-gke.1100
- 1.17.15-gke.800
- 1.16.15-gke.12500
- 1.16.15-gke.11800
- 1.16.15-gke.10600
- 1.16.15-gke.7801
- 1.15.12-gke.6002
```

**NOTE**: This value will also be the value applied to the compute nodes of your custer.

From here you would take one of these values and set the `kubernets_version` variable in your tfvars files like this:

```bash
kubernetes_version = "1.18.15-gke.1102"
```

Do not set the `kubernetes_channel` variable.

**NOTE**: If you find that the version you would like to use in your kubernetes cluster is not listed, you will need to go the [Channel Based](#channel-based) section to find the desired version.

## Channel Based

Setting a specific channel for  your kubernetes cluster will use the `defaultVersion` provided by that channel. This is the only way to work with a version of kubernetes that has been recently released and/or is not listed in the [Version Based](#version-based) section.

To find out what versions are supported by which channel you first run this command:

```bash
export LOCATION="us-east1-b"
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
  defaultVersion: 1.19.8-gke.1000
  validVersions:
  - 1.20.4-gke.1800
  - 1.19.8-gke.1600
  - 1.19.8-gke.1000
- channel: REGULAR
  defaultVersion: 1.18.15-gke.1501
  validVersions:
  - 1.18.16-gke.302
  - 1.18.15-gke.1502
  - 1.18.15-gke.1501
- channel: STABLE
  defaultVersion: 1.17.17-gke.1101
  validVersions:
  - 1.17.17-gke.2800
  - 1.17.17-gke.1101
  - 1.16.15-gke.7801
```

From this example output if you are looking to create a kubernetes cluster with v1.19 then you would choose the 'RAPID' channel.

From here you would set the `kubernetes_channel` variable in your tfvars files like this:

```bash
kubernetes_channel = "RAPID"
```

This assignment results in a cluster being created with the version: `1.19.8-gke.1000` for this example.

Do not set the `kubernetes_version` variable.
