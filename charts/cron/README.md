# cron

![Version: 0.0.0-alpha-13](https://img.shields.io/badge/Version-0.0.0--alpha--13-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

A Helm "monochart" for deploying cron jobs

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install cron helm-charts/cron
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://portswigger-apps.github.io/helm-charts/ | infra | 0.0.0-alpha-18 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.name | string | `"public.ecr.aws/nginx/nginx"` | The container image of your application |
| image.tag | string | `"alpine"` | The container tag that will be run |
| cron.schedule | string | `"* * * * *"` | Cron formatted schedule for job. |
| cron.timeZone | string | `"Europe/London"` | One of: Allow, Forbid and Replace. Allow - allows concurrently running cron jobs. Forbid - No concurrent runs, if last cron job hasn't finished then skip the new run Replace - Replace the currently running cron job with a new instance. |
| cron.concurrencyPolicy | string | `"Allow"` |  |
| cron.retries | int | `0` | Number of retries on failure of job |
| cron.parallelism | int | `1` | Number of pods of the cron job to start |
| cron.command | string[] | `nil` | Command to run on the image. e.g [/bin/bash, my-script.sh] |
| cron.args | string[] | `nil` | Arguments for the command |
| cron.restartPolicy | string | `"OnFailure"` | One of: Never or OnFailure. Never - does not restart. OnFailure - will re-run the job if it fails |
| cron.timeoutSeconds | int | `nil` | The maximum amount of time the job should run for in seconds. |
| env | object | `{}` | List of environment variables for job container. |
| secretEnv | object | `{}` | Secret values that are mounted as environment variables. Formatted as ```<environment variable name>: <plain text value>``` |
| secretVolume | object | `{}` | Secret values that are mounted as a file to /secrets. Formatted as ```<file name>: <base64 encoded value>``` |
| pod.annotations | object | `{}` |  |
| resources.cpu | string | `"100m"` | Requested CPU time for the pod |
| resources.memory | string | `"64Mi"` | Maximum memory usage for the pod |
| infra | object | `{"postgres":{"create":true,"multiAz":null,"name":"","size":null,"version":null},"s3Bucket":{"create":true,"lifecycleRules":[{"expiration":[{"days":0}],"status":"Disabled"}],"name":""},"serviceAccount":{"annotations":{},"automountServiceAccountToken":false,"enabled":true,"name":""}}` | Configuration for infra |
| infra.postgres | object | `{"create":true,"multiAz":null,"name":"","size":null,"version":null}` | Postgres database configuration. Leave as null for no database. |
| infra.postgres.name | string | `""` | The database's name. If the database is created in another app, use the same name as the database in that app. |
| infra.postgres.create | bool | `true` | If a database should be created. Set to false if another app is creating the database. |
| infra.postgres.size | string | `nil` | The instance size. Options: micro, small, medium, large or xlarge. |
| infra.postgres.version | string | `nil` | The postgres version to use. Options: 16.2, 15.6 or 14.11 |
| infra.postgres.multiAz | string | `nil` | If database should be a multi-az deployment |
| infra.s3Bucket | object | `{"create":true,"lifecycleRules":[{"expiration":[{"days":0}],"status":"Disabled"}],"name":""}` | S3 Bucket configuration. Set to null for no s3 bucket. |
| infra.s3Bucket.name | string | `""` | Name of the bucket. If the s3 bucket is created in another app, use the same name as the s3 bucket in that app. You must also use the same service account name, provide the aws account id and set automountServiceAccountToken to true |
| infra.s3Bucket.create | bool | `true` | If an s3 bucket should be created. Set to false if another app creates the s3 bucket. |
| infra.s3Bucket.lifecycleRules | list | `[{"expiration":[{"days":0}],"status":"Disabled"}]` | Lifecycle rules. See docs at https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule The status field is required on the rule object. |
| infra.serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"enabled":true,"name":""}` | Service account configuration. Configuration is required for accessing AWS resources |
| infra.serviceAccount.name | string | `""` | The name of the service account. If accessing S3 buckets, this name must match the serviceAccountName in the infra chart. Defaults to the helmfile release name |
| infra.serviceAccount.automountServiceAccountToken | bool | `false` | If the service account token should be mounted into pods that use the service account. Set to true if using AWS resources. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)