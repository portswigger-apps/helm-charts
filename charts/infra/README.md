# infra

![Version: 0.22.3](https://img.shields.io/badge/Version-0.22.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.22.3](https://img.shields.io/badge/AppVersion-0.22.3-informational?style=flat-square)

A Helm "monochart" for deploying common infrastructure

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install infra helm-charts/infra
```

## Values

### global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.ingress.host | string | `""` | Ingress host used to configure cloudfront target |
| global.serviceAccount.name | string | `""` | ServiceAccount name to configure IRSA role and IAM Policies for: s3Bucket |

### postgres

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| postgres.enabled | bool | `false` | Set to `true` to deploy a `PostgresInstance` resource |
| postgres.create | bool | `true` | Set to `false` to skip creation of the `PostgresInstance` if it has been created elsewhere |
| postgres.nameOverride | string | `""` | Override the `PostgresInstance` name or use with `create: false` to map the secrets of an instance created elsewhere |
| postgres.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| postgres.version | string | `"16.2"` | Options: 16.2, 15.6 or 14.11 |
| postgres.multiAz | bool | `false` | Set to `true` to deploy the `PostgresInstance` across multiple availability zones |
| postgres.enablePerformanceInsights | bool | `false` | Set to `true` to enable Performance Insights on the `PostgresInstance` |

### s3Bucket

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| s3Bucket.create | bool | `true` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |
| s3Bucket.enableDataInsights | bool | `false` | Set to `true` to allow data insights access to the `s3Bucket` |
| s3Bucket.lifecycleRules | list | `[]` | Configure the `s3Bucket` storage [lifecycle rules](https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule) |

### cloudfront

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cloudfront.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontSite` resource |
| cloudfront.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontSite` resource |
| cloudfront.domainName | string | `""` | The presentation domain name for the `CloudFrontSite` resource |
| cloudfront.targetOriginDomainName | string | `.Values.global.ingress.host` | The target origin domain name that the `CloudFrontSite` resource fronts |
| cloudfront.restrictToOffice | bool | `true` | Set to `true` to restrict access to the `CloudFrontSite` to the office IP ranges |
| cloudfront.geoRestriction.restrictionType | string | `"none"` | Whether to `allow` or `deny` the configured locations access to the `CloudFrontSite`. Set to `none` to remove all restrictions |
| cloudfront.geoRestriction.locations | list | `[]` | A list of ISO ALPHA-2 country codes to apply restrictions to |
| cloudfront.defaultCacheBehavior.allowedMethods | string | `"read"` | Whether `read` or `all` HTTP methods are allowed by the `CloudFrontSite` |
| cloudfront.defaultCacheBehavior.minTtl | int | `0` | The minimum time-to-live for the `CloudFrontSite` cache objects |
| cloudfront.defaultCacheBehavior.maxTtl | int | `31536000` | The maximum time-to-live for the `CloudFrontSite` cache objects |
| cloudfront.defaultCacheBehavior.defaultTtl | int | `0` | The default time-to-live for the `CloudFrontSite` cache objects, applies only when your origin does not add HTTP headers such as Cache-Control max-age, Cache-Control s-maxage, or Expires |
| cloudfront.defaultCacheBehavior.cookies.behavior | string | `"none"` | Whether `All`, `AllExcept`, `None` or `Allowlist`ed cookies are included in the cache key. |
| cloudfront.defaultCacheBehavior.cookies.allowlistedNames | list | `[]` | A list of cookie names to include in the cache key. |
| cloudfront.defaultCacheBehavior.headers.behavior | string | `"none"` | Whether `None` or `Allowlist`ed headers are included in the cache key. |
| cloudfront.defaultCacheBehavior.headers.allowlistedNames | list | `[]` | A list of header names to include in the cache key. |
| cloudfront.defaultCacheBehavior.queryStrings.behavior | string | `"none"` | Whether `All`, `AllExcept`, `None` or `Allowlist`ed  query parameters are included in the cache key. |
| cloudfront.defaultCacheBehavior.queryStrings.allowlistedNames | list | `[]` | A list of query parameter names to include in the cache key. |

### redis

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| redis.enabled | bool | `false` | Set to `true` to deploy a `RedisCluster` resource |
| redis.size | string | `"micro"` | The size of the Redis instance |
| redis.version | string | `7` | Options: "7" |

### bedrock

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bedrock.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable bedrock access. |

### cloudfront router

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cloudfrontrouter.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontRouter` resource |
| cloudfrontrouter.domainName | string | `""` | The presentation domain name for the `CloudFrontRouter` resource |
| cloudfrontrouter.acmCertificateARN | string | `""` | The presentation domain name for the `CloudFrontRouter` resource |
| cloudfrontrouter.origins | list | `[]` | A map of custom origins to be used by path configurations |
| cloudfrontrouter.orderedCacheBehavior | list | `[]` | An ordered list of paths to direct to different origins |
| cloudfrontrouter.default | object | `{"cachePolicyId":"","cachePolicyName":"CachingDisabled","customCachePolicyName":"","domainName":"","originKeepaliveTimeout":"","originReadTimeout":"","originRequestPolicyId":"","originRequestPolicyName":"AllViewerExceptHostHeader"}` | Values for the default origin config |
| cloudfrontrouter.customCachePolicies | object | `{}` | Values for dynamic custom cache policies |
| cloudfrontrouter.restrictToOffice | bool | `true` | Set to `true` to restrict access to the `CloudFrontRouter` to the office IP ranges |
| cloudfrontrouter.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontRouter` resource |

### eventing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| eventing.producer.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role to be attached to your application to enable eventbridge access. |
| eventing.consumer.enabled | bool | `false` | Set to `true` to deploy an Event Rule. |
| eventing.consumer.eventPattern | string | `""` | The pattern the rule should use to decide whether to send an event |
| eventing.consumer.inputPath | string | `""` | An optional method to extract specific data from events |

### kinesis

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kinesis.enabled | bool | `false` | Set to `true` to deploy an IAM policy and role attached to your application to allow assuming a Kinesis stream role |
| kinesis.streamName | string | `""` | Set to the name of the Kinesis stream. Required if `kinesis.enabled` is `true` |

### dynamodb

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dynamodb.tables | list | `[]` | A list containing details about dynamodb tables |

### opensearch

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opensearch.create | bool | `true` | Set to `false` to skip creation of the opensearch collection if it has been created elsewhere |
| opensearch.nameOverride | string | `""` | Use with `create: false` to map the secrets of an instance created elsewhere |
| opensearch.enabled | bool | `false` | Set to `true` to deploy an opensearch collection |
| opensearch.type | string | `"TIMESERIES"` | The type of the collection. Must be either TIMESERIES, VECTORSEARCH, or SEARCH |
| opensearch.lifecycleRules | list | `[]` | A list of rules configuring the retention period of indexes |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dynamodb.create | bool | `true` |  |
| dynamodb.prefixOverride | string | `""` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)