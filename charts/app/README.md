# app

![Version: 0.26.5](https://img.shields.io/badge/Version-0.26.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.26.5](https://img.shields.io/badge/AppVersion-0.26.5-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://portswigger-apps.github.io/helm-charts/ | infra | 0.22.7 |

## Values

### global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.aws.accountId | string | Taken from deployment pipeline environment | The AWS account that this application is being deployed into |
| global.ingress.enabled | bool | `false` | Set to `true` to expose the application with a Kubernetes `Ingress` |
| global.ingress.host | string | `""` | Ingress host used to configure cloudfront target |
| global.ingress.extraHosts | list | `[]` | Extra Ingress hosts used to configure extra host headers recognized by Traefik |
| global.ingress.annotations | object | `{}` | Set annotations on the `Ingress` |
| global.ingress.className | string | `"traefik"` | Override the `Ingress` class. In most cases this should be left as default |
| global.ingress.paths | list | `["/"]` | Path prefixes that you want to make available externally with the `Ingress` |
| global.ingress.customResponseHeaders | object | `{"X-Robots-Tag":"noindex"}` | Add custom response headers to an apps `Ingress` |
| global.ingress.allowFromOffice | bool | `true` | Allow access to the Traefik `Ingress` from PortSwigger office IP ranges |
| global.ingress.ipAllowListCIDRs | list | `[]` | Extra IP CIDR ranges to allow access from. |
| global.ingress.authentication.enabled | bool | `false` | Set to `true` to require SSO authentication to access the application. |
| global.ingress.allowFromCloudfront | bool | `false` | Allow access to the Traefik `Ingress` from Cloudfront IP ranges |
| global.ingress.stripPrefixes | list | `[]` | A list of prefixes to strip from requests. |
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
| deployment.maxReplicas | int | `.Values.deployment.replicas` | The maximum number of replicas of the application |
| deployment.averageCpuUtilization | int | `9` | The target average CPU utilization percentage for the HorizontalPodAutoscaler |
| deployment.averageMemoryUtilization | int | `disabled` | The target average Memory utilization percentage for the HorizontalPodAutoscaler |
| deployment.customAutoscalingMetrics | list | `disabled` | Advanced: A list of custom metrics scalers. |
| ports.app-port.port | int | `8080` | The port the application is listening on |
| ports.app-port.protocol | string | `"TCP"` | The protocol the application uses. This should alost always be TCP |
| ports.app-port.expose | bool | `true` | Whether the port should be accessible to the cluster and outside world |
| metricsEndpoint.path | string | `"/metrics"` | The path to a Prometheus compatible metrics endpoint |
| metricsEndpoint.port | string | `"app-port"` | The name of the port that the metrics endpoint is listening on |
| metricsEndpoint.honorLabels | bool | `false` | When `true`, honorLabels preserves the metric’s labels when they collide with the target’s labels. |
| healthcheckEndpoint.path | string | `"/health"` | The path of the applications HTTP healthcheck endpoint |
| healthcheckEndpoint.port | string | `"app-port"` | TThe name of the port that the healthcheck endpoint is listening on |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |

### network

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.enabled | bool | `true` | Set to true to expose your application within the Kubernetes cluster |
| service.labels | object | `{}` | Add labels to the Service resource |
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
| infra.postgres.version | string | `"16.4"` | Options: 16.2, 16.3 or 16.4 |
| infra.postgres.multiAz | bool | `false` | Set to `true` to deploy the `PostgresInstance` across multiple availability zones |
| infra.postgres.enablePerformanceInsights | bool | `false` | Set to `true` to enable Performance Insights on the `PostgresInstance` |
| infra.s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| infra.s3Bucket.create | bool | `true` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| infra.s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.s3Bucket.lifecycleRules | list | `[]` | Configure the `s3Bucket` storage [lifecycle rules](https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule) |
| infra.s3Bucket.enableDataInsights | list | `false` | Add IAM Role & IAM policy for data insight access to the `s3Bucket` |
| infra.cloudfront.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontSite` resource |
| infra.cloudfront.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontSite` resource |
| infra.cloudfront.domainName | string | `""` | The presentation domain name for the `CloudFrontSite` resource |
| infra.cloudfront.targetOriginDomainName | string | `.Values.global.ingress.host` | The target origin domain name that the `CloudFrontSite` resource fronts |
| infra.cloudfront.restrictToOffice | bool | `true` | Set to `false` to allow access to the `CloudFrontSite` outside of the office IPs. (managed outside of app-chart) |
| infra.cloudfront.originHeaderAuth | bool | `true` | Set to 'true' to enable authentication between CloudFront and the origin |
| infra.cloudfront.defaultCacheBehavior.allowedMethods | string | `"read"` | Whether `read` or `all` HTTP methods are allowed by the `CloudFrontSite` |
| infra.cloudfront.defaultCacheBehavior.minTtl | int | `0` | The minimum time-to-live for the `CloudFrontSite` cache objects |
| infra.cloudfront.defaultCacheBehavior.maxTtl | int | `31536000` | The maximum time-to-live for the `CloudFrontSite` cache objects |
| infra.cloudfront.defaultCacheBehavior.defaultTtl | int | `0` | The default time-to-live for the `CloudFrontSite` cache objects, applies only when your origin does not add HTTP headers such as Cache-Control max-age, Cache-Control s-maxage, or Expires |
| infra.redis.enabled | bool | `false` | Set to `true` to deploy a `RedisCluster` resource |
| infra.redis.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| infra.redis.version | string | `7` | Options: 7 |
| infra.bedrock.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable bedrock access. |
| infra.eventing.producer.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable eventbridge access. |
| infra.eventing.consumer.enabled | bool | `false` | Set to `true` to deploy an eventrule. |
| infra.eventing.consumer.eventPattern | string | `""` | The pattern the rule should use to decide whether to send an event |
| infra.eventing.consumer.inputPath | string | `""` | An optional method to extract specific data from events |
| infra.kinesis.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role attached to your application to allow assuming a Kinesis stream role |
| infra.kinesis.streamName | string | `""` | Set to the name of the Kinesis stream. Required if `kinesis.enabled` is `true` |
| infra.dynamodb.create | bool | `true` | Set to `false` to skip creation of the dynamodb tables if they have been created elsewhere |
| infra.dynamodb.tables | list | `[]` | A list containing details about dynamodb tables |
| infra.opensearch.create | bool | `true` | Set to `false` to skip creation of the opensearch collection if it has been created elsewhere |
| infra.opensearch.nameOverride | string | `""` | Use with `create: false` to map the secrets of an instance created elsewhere |
| infra.opensearch.enabled | bool | `false` | Set to `true` to deploy an opensearch collection |
| infra.opensearch.type | string | `"TIMESERIES"` | The type of the collection. Must be either TIMESERIES, VECTORSEARCH, or SEARCH |
| infra.opensearch.standbyReplicas | bool | `false` | Set to 'true' to use standby replicas for the collection. |
| infra.opensearch.lifecycleRules | list | `[]` | A list of rules configuring the retention period of indexes |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pod.additionalVolumes | list | `[]` | Configuration for additional volumes. See example in values.yaml |
| pod.additionalVolumeMounts | list | `[]` | Configuration for additional volume mounts. References additionalVolumes, see example in values.yaml |
| pod.labels | object | `{}` | Additional labels to add to pods |
| pod.annotations | object | `{}` | Additional annotations to add to pods |
| pod.nodeSelector | object | `{}` | Set a nodeSelector(s) on your pods |
| podLogs.pipelineStages | list | `[]` | Grafana logging agent [pipeline stage](https://grafana.com/docs/loki/latest/send-data/promtail/pipelines/). Only available on v1alpha1 |
| initContainers | list | `[]` | Configuration for [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), which are containers that run before the app container is started. @section == application |
| infra.cloudfrontrouter | object | `{}` |  |
| infra.dynamodb.prefixOverride | string | `""` |  |
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
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)