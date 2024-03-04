# app

![Version: 0.0.0-alpha-5](https://img.shields.io/badge/Version-0.0.0--alpha--5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

A Helm "monochart" for deploying common application patterns

## Installation
```
helm repo add helm-charts https://portswigger-apps.github.io/helm-charts/
helm install app helm-charts/app
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `[]` |  |
| ciliumNetworkPolicy.egress | list | `[]` |  |
| ciliumNetworkPolicy.enabled | bool | `false` |  |
| ciliumNetworkPolicy.ingress | list | `[]` |  |
| ciliumNetworkPolicy.ingressControllerEndpointMatchLabels."app.kubernetes.io/name" | string | `"nginx"` |  |
| ciliumNetworkPolicy.ingressControllerEndpointMatchLabels."k8s:io.kubernetes.pod.namespace" | string | `"ingress"` |  |
| deployment.enabled | bool | `true` |  |
| deployment.kind | string | `"Deployment"` |  |
| deployment.replicas | int | `1` |  |
| deployment.updateStrategy | string | `nil` |  |
| env | list | `[]` |  |
| envFrom | list | `[]` |  |
| extraDeploy | list | `[]` |  |
| healthcheckEndpoint.path | string | `"/health"` |  |
| healthcheckEndpoint.port | string | `"app-port"` |  |
| image.name | string | `"public.ecr.aws/nginx/nginx"` |  |
| image.tag | string | `"alpine"` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.host | string | `""` |  |
| ingress.paths[0] | string | `"/"` |  |
| initContainers | list | `[]` |  |
| metricsEndpoint.path | string | `"/metrics"` |  |
| metricsEndpoint.port | string | `"app-port"` |  |
| pod.additionalVolumeMounts | list | `[]` |  |
| pod.additionalVolumes | list | `[]` |  |
| podLogs.pipelineStages | list | `[]` |  |
| ports.app-port.expose | bool | `true` |  |
| ports.app-port.port | int | `8080` |  |
| ports.app-port.protocol | string | `"TCP"` |  |
| resources.cpu | string | `"100m"` |  |
| resources.memory | string | `"64Mi"` |  |
| secretEnv | object | `{}` |  |
| service.enabled | bool | `true` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `false` |  |
| serviceAccount.enabled | bool | `true` |  |

---
