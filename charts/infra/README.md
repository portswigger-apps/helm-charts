# infra

![Version: 0.0.3](https://img.shields.io/badge/Version-0.0.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.1](https://img.shields.io/badge/AppVersion-0.0.1-informational?style=flat-square)

A Helm "monochart" for deploying common infrastructure

## Installation
```
helm repo add utility-charts https://portswigger-apps.github.io/helm-charts/
helm install infra helm-charts/infra
```

## Values

### cloudfront

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cloudfront.defaultCacheBehavior.allowedMethods | list | `["GET","HEAD","OPTIONS"]` | The HTTP methods that the `CloudFrontSite` allows |
| cloudfront.defaultCacheBehavior.cachedMethods | list | `["GET","HEAD"]` | The HTTP methods that the `CloudFrontSite` caches |
| cloudfront.defaultCacheBehavior.cookies.allowlistedNames | list | `[]` | A list of cookie names to include in the cache key. |
| cloudfront.defaultCacheBehavior.cookies.behavior | string | `"all"` | Whether 'All', 'AllExcept', 'None' or 'Whitelist'ed cookies are included in the cache key. |
| cloudfront.defaultCacheBehavior.headers.allowlistedNames | list | `[]` | A list of header names to include in the cache key. |
| cloudfront.defaultCacheBehavior.headers.behavior | string | `"none"` | Whether 'None' or 'Whitelist'ed headers are included in the cache key. |
| cloudfront.defaultCacheBehavior.queryStrings.allowlistedNames | list | `[]` | A list of query parameter names to include in the cache key. |
| cloudfront.defaultCacheBehavior.queryStrings.behavior | string | `"none"` | Whether 'All', 'AllExcept', 'None' or 'Whitelist'ed  query parameters are included in the cache key. |
| cloudfront.defaultCacheBehavior.ttl | int | `3600` | The time-to-live for the `CloudFrontSite` cache |
| cloudfront.domainName | string | `""` | The presentation domain name for the `CloudFrontSite` resource |
| cloudfront.enabled | bool | `false` | Set to `true` to deploy an `CloudFrontSite` resource |
| cloudfront.geoRestriction.locations | list | `["GB"]` | A list of ISO ALPHA-2 country codes to apply restrictions to |
| cloudfront.geoRestriction.restrictionType | string | `"allow"` | Whether to `allow` or `deny` the configured locations access to the `CloudFrontSite`. Set to `none` to remove all restrictions |
| cloudfront.hostedZoneId | string | `""` | The Route53 hosted zone ID to create the certificates and domain names for the `CloudFrontSite` resource |
| cloudfront.targetOriginDomainName | string | `.Values.global.ingress.host` | The target origin domain name that the `CloudFrontSite` resource fronts |

### global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.ingress.host | string | `""` | Ingress host used to configure cloudfront target |
| global.serviceAccount.name | string | `""` | ServiceAccount name to configure IRSA role and IAM Policies for: s3Bucket |

### postgres

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| postgres.create | bool | `true` | Set to `false` to skip creation of the `PostgresInstance` if it has been created elsewhere |
| postgres.enabled | bool | `false` | Set to `true` to deploy a `PostgresInstance` resource |
| postgres.multiAz | bool | `false` | Set to `true` to deploy the `PostgresInstance` across multiple availability zones |
| postgres.nameOverride | string | `""` | Override the `PostgresInstance` name or use with `create: false` to map the secrets of an instance created elsewhere |
| postgres.size | string | `micro` | Options: micro, small, medium, large or xlarge |
| postgres.version | string | `"16.2"` | Options: 16.2, 15.6 or 14.11 |

### s3Bucket

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| s3Bucket.create | bool | `true` | Set to `false` to skip creation of the `s3Bucket` if it has been created elsewhere |
| s3Bucket.enabled | bool | `false` | Set to `true` to deploy an `s3Bucket` resource |
| s3Bucket.lifecycleRules | list | `[]` | Configure the `s3Bucket` storage [lifecycle rules](https://marketplace.upbound.io/providers/upbound/provider-aws-s3/v1.2.1/resources/s3.aws.upbound.io/BucketLifecycleConfiguration/v1beta1#doc:spec-forProvider-rule) |
| s3Bucket.nameOverride | string | `""` | Override the `s3Bucket` name or use with `create: false` to map the secrets of an instance created elsewhere |

---
