# app

![Version: 0.2.7](https://img.shields.io/badge/Version-0.2.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add helm-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../infra/ | infra | 0.0.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `[]` | Arguments to be passed to the container |
| ciliumNetworkPolicy | object | `{"egress":[],"enabled":false,"ingress":[],"ingressControllerEndpointMatchLabels":{"app.kubernetes.io/name":"nginx","k8s:io.kubernetes.pod.namespace":"ingress"}}` | Configuration for the ciliumNetworkPolicy, allowing restriction of network access to pods. |
| ciliumNetworkPolicy.egress | list | `[]` | Cilium egress rules. See examples below. |
| ciliumNetworkPolicy.ingress | list | `[]` | Cilium ingress rules. See examples below. |
| ciliumNetworkPolicy.ingressControllerEndpointMatchLabels | object | `{"app.kubernetes.io/name":"nginx","k8s:io.kubernetes.pod.namespace":"ingress"}` | Label matchers for the ingress controller. Used so that the ingress controller can access your application. |
| deployment.enabled | bool | `true` |  |
| deployment.maxReplicas | int | `nil` | The maximum number of replicas of the application |
| deployment.replicas | int | `1` | The minimum number of replicas of the application |
| env | object | `{}` | Environment variables that will be available in the container. Formatted as ```<environment variable name>: <plain text value>``` |
| envFrom | list | `[]` | Used to specify environment variables from ConfigMaps. See https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ |
| extraDeploy | list | `[]` | Extra Kubernetes configuration |
| healthcheckEndpoint | object | `{"path":"/health","port":"app-port"}` | Configuration for startup, liveness and readiness probes |
| healthcheckEndpoint.path | string | `"/health"` | The path of the healthcheck endpoint |
| healthcheckEndpoint.port | string | `"app-port"` | The port that the healthcheck endpoint is exposed on. Referenced by the port's name |
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
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
| secretEnv | object | `{}` | Secret values that are mounted as environment variables. Formatted as ```<environment variable name>: <plain text value>``` |
| secretVolume | object | `{}` | Secret values that are mounted as a file to /secrets. Formatted as ```<file name>: <base64 encoded value>``` |
| service.annotations | object | `{}` |  |
| service.enabled | bool | `true` | Adds a service to expose the application to the rest of the cluster |

---

## Cilium Network Policy Examples
```
# Ingress Example
- fromEndpoints:
  - matchLabels:
      app.kubernetes.io/name: frontend # Pods with this label will be able to access your application
  toPorts:
    - ports:
      - port: "8080"
        protocol: TCP

# Egress Example
- toEndpoints:
  - matchLabels:
    k8s:io.kubernetes.pod.namespace: kube-system
    k8s-app: kube-dns
  toPorts:
  - ports:
     - port: "53"
       protocol: ANY
    rules:
      dns:
      - matchPattern: "*"

# Egress Example
- toFQDNs:
  - matchName: "my-remote-service.com"

```
