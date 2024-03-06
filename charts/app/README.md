# app

![Version: 0.0.0-alpha-10](https://img.shields.io/badge/Version-0.0.0--alpha--10-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add helm-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `[]` | Arguments to be passed to the container |
| ciliumNetworkPolicy | object | `{"egress":[],"enabled":false,"ingress":[],"ingressControllerEndpointMatchLabels":{"app.kubernetes.io/name":"nginx","k8s:io.kubernetes.pod.namespace":"ingress"}}` | Configuration for the ciliumNetworkPolicy, allowing restriction of network access to pods. |
| ciliumNetworkPolicy.egress | list | `[]` | Cilium egress rules. See example in values.yaml |
| ciliumNetworkPolicy.ingress | list | `[]` | Cilium ingress rules. See example in values.yaml |
| ciliumNetworkPolicy.ingressControllerEndpointMatchLabels | object | `{"app.kubernetes.io/name":"nginx","k8s:io.kubernetes.pod.namespace":"ingress"}` | Pods that have these labels with be able to access your application |
| deployment.enabled | bool | `true` |  |
| deployment.maxReplicas | string | `nil` | The maximum number of replicas of the application |
| deployment.replicas | int | `1` | The minimum number of replicas of the application |
| env | object | `{}` | Environment variables that will be available in the container |
| envFrom | list | `[]` | Used to specify environment variables from ConfigMaps. See https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ |
| extraDeploy | list | `[]` | Extra Kubernetes configuration |
| healthcheckEndpoint | object | `{"path":"/health","port":"app-port"}` | Configuration for startup, liveness and readiness probes |
| healthcheckEndpoint.path | string | `"/health"` | The path of the healthcheck endpoint |
| healthcheckEndpoint.port | string | `"app-port"` | The port that the healthcheck endpoint is exposed on. Referenced by the port's name |
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
| image.tag | string | `"alpine"` | The container tag that will be run |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` | Adds an ingress to expose the application to the outside world |
| ingress.host | string | `""` | The host name the application will be accessible from |
| ingress.paths | list | `["/"]` | The path prefixes that are exposed |
| initContainers | list | `[]` | Configuration for [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), which are containers that run before the app container is started. |
| metricsEndpoint.path | string | `"/metrics"` | The path of the metrics endpoint |
| metricsEndpoint.port | string | `"app-port"` | The port that the metrics endpoint is exposed on. Referenced by the port's name |
| pod.additionalVolumeMounts | list | `[]` | Configuration for additional volume mounts. References additionalVolumes, see example in values.yaml |
| pod.additionalVolumes | list | `[]` | Configuration for additional volumes. See example in values.yaml |
| podLogs.pipelineStages | list | `[]` |  |
| ports | object | `{"app-port":{"expose":true,"port":8080,"protocol":"TCP"}}` | Configuration for the ports that the application listens on. |
| ports.app-port.expose | bool | `true` | Whether the port should be accessible to the cluster and outside world. |
| ports.app-port.port | int | `8080` | The port the application is running on |
| ports.app-port.protocol | string | `"TCP"` | The protocol the application uses |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |
| secretEnv | object | `{}` | Secret values that are mounted as environment variables |
| secretVolume | object | `{}` | Secret values that are mounted as a file to /secrets |
| service.annotations | object | `{}` |  |
| service.enabled | bool | `true` | Adds a service to expose the application to the rest of the cluster |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"enabled":true}` | Service account configuration. Configuration is required for accessing AWS resources |
| serviceAccount.automountServiceAccountToken | bool | `false` | If the service account token should be mounted into pods that use the service account |

---
