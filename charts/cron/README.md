# cron

![Version: 0.4.5](https://img.shields.io/badge/Version-0.4.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.5](https://img.shields.io/badge/AppVersion-0.4.5-informational?style=flat-square)

A Helm "monochart" for deploying cron jobs

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install cron helm-charts/cron
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
| global.serviceAccount.enabled | bool | `true` | Set to `false` to prevent the `ServiceAccount` from being created |
| global.serviceAccount.name | string | `.Release.Name` | `ServiceAccount` name. Use with `global.serviceAccount.enabled: false` to use an existing `ServiceAccount` |
| global.serviceAccount.automountServiceAccountToken | bool | `false` | Set to `true` to mount tokens for access to the Kubernetes API. This should almost always be `false` |
| global.serviceAccount.annotations | object | `{}` | Set annotations on the `ServiceAccount` |

### application

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
| image.tag | string | `"alpine"` | The tag for the image that you want to deploy |
| cron.command | list | `[]` | Command to run on the image. e.g [/bin/bash, my-script.sh] |
| cron.args | list | `[]` | Arguments for the command |
| env | object | `{}` | **Non-secret** environment variables to configure your application. Formatted as `ENV_VAR_NAME: env-var-value` |
| envFrom | list | `[]` | Create environment variables from `Secret` or `ConfigMap` resources. See https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ |
| secretEnv | object | `{}` | Secret values that are mounted as environment variables. Formatted as `ENV_VAR_NAME: env-var-value` in a SOPS encrypted `secrets.yaml` file |
| secretVolume | object | `{}` | Secret values that will be available as files in `/secrets` inside the container. Formatted as `file.name: <base64 encoded file>` |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |

### cron

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cron.schedule | string | `"0 1 31 2 *"` | Cron formatted schedule for job |
| cron.timeZone | string | `"Europe/London"` | A valid IANA TZ name |
| cron.concurrencyPolicy | string | `"Forbid"` | WHether or not to allow the cron to overlap with the previous run. Valid values are: `Allow`, `Forbid` or `Replace` |
| cron.retries | int | `0` | Number of retries on failure of job |
| cron.parallelism | int | `1` | Number of pods of the cron job to start |
| cron.restartPolicy | string | `"Never"` | Whether or not the pod should restart on failure. Valid values are: `Never` or `onFailure` |
| cron.timeoutSeconds | int | `86400` | The maximum amount of time the job should run for in seconds. |

### infra

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| infra.postgres.enabled | bool | `false` | Set to `true` to deploy a `PostgresInstance` resource |
| infra.postgres.create | bool | `false` | Set to `false` to skip creation of the `PostgresInstance` if it has been created elsewhere |
| infra.postgres.nameOverride | string | `""` | Override the `PostgresInstance` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| infra.s3Bucket.create | bool | `false` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| infra.s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |
| infra.bedrock.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable bedrock access. |
| infra.eventing.producer.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable eventbridge access. |
| infra.eventing.consumer.enabled | bool | `false` | Set to `true` to deploy an eventrule. |
| infra.eventing.consumer.eventPattern | string | `""` | The pattern the rule should use to decide whether to send an event |
| infra.eventing.consumer.inputPath | string | `""` | An optional method to extract specific data from events |
| infra.dynamodb.create | bool | `false` | Set to `false` to skip creation of the dynamodb tables if they have been created elsewhere |
| infra.dynamodb.tables | list | `[]` | A list containing details about dynamodb tables |
| infra.opensearch.create | bool | `false` | Set to `false` to skip creation of the opensearch collection if it has been created elsewhere |
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
| infra.dynamodb.prefixOverride | string | `""` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)