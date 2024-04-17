# app

![Version: 0.4.6](https://img.shields.io/badge/Version-0.4.6-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.6](https://img.shields.io/badge/AppVersion-0.4.6-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://portswigger-apps.github.io/helm-charts/ | infra | 0.1.3 |

## Values

### global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.aws.accountId | string | Taken from deployment pipeline environment | The AWS account that this application is being deployed into |
| global.ingress.enabled | bool | `false` | Set to `true` to expose the application with a Kubernetes `Ingress` |
| global.ingress.host | string | `""` | Ingress host used to configure cloudfront target |
| global.ingress.annotations | object | `{}` | Set annotations on the `Ingress` |
| global.ingress.className | string | `"traefik"` | Override the `Ingress` class. In most cases this should be left as default |
| global.ingress.paths | list | `["/"]` | Path prefixes that you want to make available externally with the `Ingress` |
| global.serviceAccount.enabled | bool | `true` | Set to `false` to prevent the `ServiceAccount` from being created |
| global.serviceAccount.name | string | `.Release.Name` | `ServiceAccount` name. Use with `global.serviceAccount.enabled: false` to use an existing `ServiceAccount` |
| global.serviceAccount.automountServiceAccountToken | bool | `false` | Set to `true` to mount tokens for access to the Kubernetes API. This should almost always be `false` |
| global.serviceAccount.annotations | object | `{}` | Set annotations on the `ServiceAccount` |

### application

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
| image.tag | string | `"alpine"` | The tag for the image that you want to deploy |
| args | list | `[]` | Arguments to be passed to your application container |
| env | object | `{}` | **Non-secret** environment variables to configure your application. Formatted as `ENV_VAR_NAME: env-var-value` |
| envFrom | list | `[]` | Create environment variables from `Secret` or `ConfigMap` resources. See https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ |
| secretEnv | object | `{}` | Secret values that are mounted as environment variables. Formatted as `ENV_VAR_NAME: env-var-value` in a SOPS encrypted `secrets.yaml` file |
| secretVolume | object | `{}` | Secret values that will be available as files in `/secrets` inside the container. Formatted as `file.name: <base64 encoded file>` |
| deployment.replicas | int | `1` | The minimum number of replicas of the application |
| deployment.maxReplicas | int | `.Values.deployment.replicas | The maximum number of replicas of the application |
| ports.app-port.port | int | `8080` | The port the application is listening on |
| ports.app-port.protocol | string | `"TCP"` | The protocol the application uses. This should alost always be TCP |
| ports.app-port.expose | bool | `true` | Whether the port should be accessible to the cluster and outside world |
| metricsEndpoint.path | string | `"/metrics"` | The path to a Prometheus compatible metrics endpoint |
| metricsEndpoint.port | string | `"app-port"` | The name of the port that the metrics endpoint is listening on |
| healthcheckEndpoint.path | string | `"/health"` | The path of the applications HTTP healthcheck endpoint |
| healthcheckEndpoint.port | string | `"app-port"` | TThe name of the port that the healthcheck endpoint is listening on |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |

### network

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.enabled | bool | `true` | Set to true to expose your application within the Kubernetes cluster |
| service.annotations | object | `{}` | Add annotations to the Service resource |
| ciliumNetworkPolicy.ingress | list | `[]` | Cilium ingress rules. See examples in values.yaml |
| ciliumNetworkPolicy.egress | list | `[]` | Cilium egress rules. See examples in values.yaml |
| ciliumNetworkPolicy.externalHttpsServices | list | `[]` | A list of external domain names that your app depends on. See examples in values.yaml |
| ciliumNetworkPolicy.fromApps | list | `[]` | A list of app names and optional namespace to allow ingress from. See examples in values.yaml |
| ciliumNetworkPolicy.toApps | list | `[]` | A list of app names and optional namespace to allow egress to. See examples in values.yaml |

### infra

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| infra.postgres.enabled | bool | `false` | Set to `true` to deploy a `PostgresInstance` resource |
| infra.postgres.create | bool | `true` | Set to `false` to skip creation of the `PostgresInstance` if it has been created elsewhere |
| infra.postgres.nameOverride | string | `""` | Override the `PostgresInstance` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.postgres.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| infra.postgres.version | string | `"16.2"` | Options: 16.2, 15.6 or 14.11 |
| infra.postgres.multiAz | bool | `false` | Set to `true` to deploy the `PostgresInstance` across multiple availability zones |
| infra.s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| infra.s3Bucket.create | bool | `true` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| infra.s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.s3Bucket.lifecycleRules | list | `[]` | Configure the `s3Bucket` storage [lifecycle rules](https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule) |
| infra.cloudfront.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontSite` resource |
| infra.cloudfront.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontSite` resource |
| infra.cloudfront.domainName | string | `""` | The presentation domain name for the `CloudFrontSite` resource |
| infra.cloudfront.targetOriginDomainName | string | `.Values.global.ingress.host` | The target origin domain name that the `CloudFrontSite` resource fronts |
| infra.cloudfront.geoRestriction.restrictionType | string | `"allow"` | Whether to `allow` or `deny` the configured locations access to the `CloudFrontSite`. Set to `none` to remove all restrictions |
| infra.cloudfront.geoRestriction.locations | list | `["GB"]` | A list of ISO ALPHA-2 country codes to apply restrictions to |
| infra.cloudfront.originHeaderAuth | bool | `true` | Set to 'true' to enable authentication between CloudFront and the origin |
| infra.redis.enabled | bool | `false` | Set to `true` to deploy a `RedisCluster` resource |
| infra.redis.nodeGroups | int | `1` | Set the number of node groups for the `RedisCluster` |
| infra.redis.replicasPerNodeGroup | int | `0` | Set the number of replicas per node group for the `RedisCluster` |
| infra.redis.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| infra.redis.version | string | `7.1` | Options: 7.1, 7.0 |
| infra.redis.multiAz | bool | `false` | Set to `true` to deploy the `RedisCluster` across multiple availability zones |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pod.additionalVolumes | list | `[]` | Configuration for additional volumes. See example in values.yaml |
| pod.additionalVolumeMounts | list | `[]` | Configuration for additional volume mounts. References additionalVolumes, see example in values.yaml |
| pod.labels | object | `{}` | Additional labels to add to pods |
| pod.annotations | object | `{}` | Additional annotations to add to pods |
| pod.nodeSelector | object | `{}` | Set a nodeSelector(s) on your pods |
| podLogs.pipelineStages | list | `[]` | Grafana logging agent [pipeline stage](https://grafana.com/docs/loki/latest/send-data/promtail/pipelines/) |
| initContainers | list | `[]` | Configuration for [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), which are containers that run before the app container is started. @section == application |
| infra.redis.password | string | `""` |  |
| extraDeploy | list | `[]` | Extra Kubernetes configuration |
| preDeployCommand | string[] | `[]` | Command to run before install and upgrade of your application. See examples in values.yaml |
| preRollbackCommand | string[] | `[]` | Command to run before a rollback. See examples in values.yaml |

---

## CiliumNetworkPolicy examples

Allow access from an app named `my-other-app` in your product namespace
```yaml
ciliumNetworkPolicy:
  fromApps:
    - name: my-other-app
```

Allow access from an app named `admin-frontend` in the `web` product namespace
```yaml
ciliumNetworkPolicy:
  fromApps:
    - name: admin-frontend
      namespace: web
```

Allow access to an app named `orders` in your product namespace
```yaml
ciliumNetworkPolicy:
  toApps:
    - name: orders
```

Allow access to an app named `updates` in the `web` product namespace
```yaml
ciliumNetworkPolicy:
  toApps:
    - name: updates
      namespace: web
```

Allow access to a HTTPS API `api.example.com` and `api.openai.com`
```yaml
ciliumNetworkPolicy:
  externalHttpsServices:
    - api.example.com
    - api.openai.com
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)