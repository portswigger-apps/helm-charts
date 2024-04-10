# app

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.3.0](https://img.shields.io/badge/AppVersion-0.3.0-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add helm-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://portswigger-apps.github.io/helm-charts/ | infra | 0.0.4 |


## Values

### application

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `[]` | Arguments to be passed to your application container |
| deployment.maxReplicas | int | `.Values.deployment.replicas | The maximum number of replicas of the application |
| deployment.replicas | int | `1` | The minimum number of replicas of the application |
| env | object | `{}` | **Non-secret** environment variables to configure your application. Formatted as `ENV_VAR_NAME: env-var-value` |
| envFrom | list | `[]` | Create environment variables from `Secret` or `ConfigMap` resources. See https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ |
| healthcheckEndpoint.path | string | `"/health"` | The path of the applications HTTP healthcheck endpoint |
| healthcheckEndpoint.port | string | `"app-port"` | TThe name of the port that the healthcheck endpoint is listening on |
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
| image.tag | string | `"alpine"` | The tag for the image that you want to deploy |
| metricsEndpoint.path | string | `"/metrics"` | The path to a Prometheus compatible metrics endpoint |
| metricsEndpoint.port | string | `"app-port"` | The name of the port that the metrics endpoint is listening on |
| ports.app-port.expose | bool | `true` | Whether the port should be accessible to the cluster and outside world |
| ports.app-port.port | int | `8080` | The port the application is listening on |
| ports.app-port.protocol | string | `"TCP"` | The protocol the application uses. This should alost always be TCP |
| image.tag | string | `"alpine"` | The container tag that will be run |
| infra.aws.accountId | string | `"0123456789"` | The AWS account id for the deployment. |
| infra.cloudfront | object | `{"domainName":"","enabled":false,"geoRestriction":{"locations":[],"restrictionType":"none"},"headerAuth":{"enabled":false},"hostedZoneId":""}` | Cloudfront configuration |
| infra.cloudfront.domainName | string | `""` | The domain name that the cloudfront distribution will be available on |
| infra.cloudfront.geoRestriction.locations | list | `[]` | The countries that are allowed or disallowed from accessing the cloudfront distribution |
| infra.cloudfront.geoRestriction.restrictionType | string | `"none"` | The restriction type for the cloudfront distribution. Options: none, whitelist, blacklist |
| infra.cloudfront.hostedZoneId | string | `""` | The hosted zone id of the domain name |
| infra.ingress.annotations | object | `{}` |  |
| infra.ingress.enabled | bool | `false` | Adds an ingress to expose the application to the outside world |
| infra.ingress.host | string | `""` | The host name the application will be accessible from |
| infra.ingress.paths | list | `["/"]` | The path prefixes that are exposed |
| infra.postgres | object | `{"multiAz":null,"name":"","size":null,"version":null}` | Postgres database configuration. Leave as null for no database. |
| infra.postgres.multiAz | string | `nil` | If database should be a multi-az deployment |
| infra.postgres.name | string | `""` | The database's name. |
| infra.postgres.size | string | `nil` | The instance size. Options: micro, small, medium, large or xlarge. |
| infra.postgres.version | string | `nil` | The postgres version to use. Options: 16.2, 15.6 or 14.11 |
| infra.s3Bucket | object | `{"lifecycleRules":[{"expiration":[{"days":0}],"status":"Disabled"}],"name":""}` | S3 Bucket configuration. Set to null for no s3 bucket. |
| infra.s3Bucket.lifecycleRules | list | `[{"expiration":[{"days":0}],"status":"Disabled"}]` | Lifecycle rules. See docs at https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule The status field is required on the rule object. |
| infra.s3Bucket.name | string | `""` | Name of the bucket |
| infra.serviceAccount.annotations | object | `{}` |  |
| infra.serviceAccount.automountServiceAccountToken | bool | `false` | If the service account token should be mounted into pods that use the service account. Set to true if using AWS resources. |
| infra.serviceAccount.enabled | bool | `true` |  |
| infra.serviceAccount.name | string | `""` | The name of the service account. If accessing S3 buckets, this name must match the serviceAccountName in the infra chart. Defaults to the helmfile release name |
| initContainers | list | `[]` | Configuration for [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), which are containers that run before the app container is started. |
| metricsEndpoint.path | string | `"/metrics"` | The path of the metrics endpoint |
| metricsEndpoint.port | string | `"app-port"` | The port that the metrics endpoint is exposed on. Referenced by the port's name |
| pod.additionalVolumeMounts | list | `[]` | Configuration for additional volume mounts. References additionalVolumes, see example in values.yaml |
| pod.additionalVolumes | list | `[]` | Configuration for additional volumes. See example in values.yaml |
| podLogs.pipelineStages | list | `[]` | Grafana Loki pipeline stages configuration. See https://grafana.com/docs/loki/latest/send-data/promtail/pipelines/ |
| ports | object | `{"app-port":{"expose":true,"port":8080,"protocol":"TCP"}}` | Configuration for the ports that the application listens on. |
| ports.app-port.expose | bool | `true` | Whether the port should be accessible to the cluster and outside world. |
| ports.app-port.port | int | `8080` | The port the application is running on |
| ports.app-port.protocol | string | `"TCP"` | The protocol the application uses |
| preDeployCommand | string[] | `[]` | Command to run before install and upgrade of your application. |
| preRollbackCommand | string[] | `[]` | Command to run before a rollback. |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |
| secretEnv | object | `{}` | Secret values that are mounted as environment variables. Formatted as `ENV_VAR_NAME: env-var-value` in a SOPS encrypted `secrets.yaml` file |
| secretVolume | object | `{}` | Secret values that will be available as files in `/secrets` inside the container. Formatted as `file.name: <base64 encoded file>` |

### network

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ciliumNetworkPolicy.egress | list | `[]` | Cilium egress rules. See examples in values.yaml |
| ciliumNetworkPolicy.ingress | list | `[]` | Cilium ingress rules. See examples in values.yaml |
| service.annotations | object | `{}` | Add annotations to the Service resource |
| service.enabled | bool | `true` | Set to true to expose your application within the Kubernetes cluster |

### global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.aws.accountId | string | Taken from deployment pipeline environment | The AWS account that this application is being deployed into |
| global.ingress.annotations | object | `{}` | Set annotations on the `Ingress` |
| global.ingress.className | string | `""` | Override the `Ingress` class. In most cases this should be left as default |
| global.ingress.enabled | bool | `false` | Set to `true` to expose the application with a Kubernetes `Ingress` |
| global.ingress.host | string | `""` | Ingress host used to configure cloudfront target |
| global.ingress.paths | list | `["/"]` | Path prefixes that you want to make available externally with the `Ingress` |
| global.serviceAccount.annotations | object | `{}` | Set annotations on the `ServiceAccount` |
| global.serviceAccount.automountServiceAccountToken | bool | `false` | Set to `true` to mount tokens for access to the Kubernetes API. This should almost always be `false` |
| global.serviceAccount.enabled | bool | `true` | Set to `false` to prevent the `ServiceAccount` from being created |
| global.serviceAccount.name | string | `.Release.Name` | `ServiceAccount` name. Use with `global.serviceAccount.enabled: false` to use an existing `ServiceAccount` |

### infra

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| infra.cloudfront.domainName | string | `""` | The presentation domain name for the `CloudFrontSite` resource |
| infra.cloudfront.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontSite` resource |
| infra.cloudfront.geoRestriction.locations | list | `["GB"]` | A list of ISO ALPHA-2 country codes to apply restrictions to |
| infra.cloudfront.geoRestriction.restrictionType | string | `"allow"` | Whether to `allow` or `deny` the configured locations access to the `CloudFrontSite`. Set to `none` to remove all restrictions |
| infra.cloudfront.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontSite` resource |
| infra.cloudfront.targetOriginDomainName | string | `.Values.global.ingress.host` | The target origin domain name that the `CloudFrontSite` resource fronts |
| infra.postgres.create | bool | `true` | Set to `false` to skip creation of the `PostgresInstance` if it has been created elsewhere |
| infra.postgres.enabled | bool | `false` | Set to `true` to deploy a `PostgresInstance` resource |
| infra.postgres.multiAz | bool | `false` | Set to `true` to deploy the `PostgresInstance` across multiple availability zones |
| infra.postgres.nameOverride | string | `""` | Override the `PostgresInstance` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.postgres.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| infra.postgres.version | string | `"16.2"` | Options: 16.2, 15.6 or 14.11 |
| infra.s3Bucket.create | bool | `true` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| infra.s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| infra.s3Bucket.lifecycleRules | list | `[]` | Configure the `s3Bucket` storage [lifecycle rules](https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule) |
| infra.s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ciliumNetworkPolicy.externalHttpsServices | list | `[]` |  |
| ciliumNetworkPolicy.fromApps | list | `[]` |  |
| ciliumNetworkPolicy.toApps | list | `[]` |  |
| extraDeploy | list | `[]` | Extra Kubernetes configuration |
| initContainers | list | `[]` | Configuration for [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), which are containers that run before the app container is started. @section == application |
| pod.additionalVolumeMounts | list | `[]` | Configuration for additional volume mounts. References additionalVolumes, see example in values.yaml |
| pod.additionalVolumes | list | `[]` | Configuration for additional volumes. See example in values.yaml |
| podLogs.pipelineStages | list | `[]` | Grafana logging agent [pipeline stage](https://grafana.com/docs/loki/latest/send-data/promtail/pipelines/) |
| preDeployCommand | string[] | `[]` | Command to run before install and upgrade of your application. See examples in values.yaml |
| preRollbackCommand | string[] | `[]` | Command to run before a rollback. See examples in values.yaml |

---

