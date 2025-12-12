# NATS Event Bridge Configuration

This Helm chart supports conditional integration with NATS event bridge for event-driven applications.

## Chart Support

**Current Status**: NATS support is implemented for the **app chart only**.

The cron and infra charts do not currently include NATS support, following the YAGNI (You Aren't Gonna Need It) principle. These can be added in the future if use cases emerge that require NATS integration for cron jobs or infra components.

## Configuration

Enable NATS support in your `values.yaml`:

```yaml
infra:
  nats:
    enabled: true
    serviceAddress: "nats.messaging.svc.cluster.local"  # optional, default shown
    port: 4222                                           # optional, default shown
    tokenPath: "/var/run/secrets/nats"                  # optional, default shown
    tokenExpirationSeconds: 3600                         # optional, default shown
```

## What Gets Configured

When `infra.nats.enabled: true`, the following resources are automatically configured:

### Environment Variables

- **NATS_URL**: Connection URL (e.g., `nats://nats.messaging.svc.cluster.local:4222`)
- **NATS_TOKEN_FILE**: Path to the authentication token file (e.g., `/var/run/secrets/nats/token`)

### Projected Service Account Token

A Kubernetes projected service account token volume is automatically mounted with:
- **Audience**: `nats`
- **Expiration**: Configurable (default 3600 seconds)
- **Auto-rotation**: Kubernetes rotates tokens at 80% of expiration time
- **Mount path**: Configurable (default `/var/run/secrets/nats`)

### Network Policy

A Cilium NetworkPolicy egress rule is added allowing:
- **Protocol**: TCP
- **Port**: Configurable (default 4222)
- **Destination**: NATS service FQDN

## Client Usage

Your application should:

1. Read the NATS connection URL from `NATS_URL` environment variable
2. Read the authentication token from the file specified in `NATS_TOKEN_FILE`
3. Use the token when establishing NATS connections

Example (pseudocode):
```
natsUrl = os.getenv("NATS_URL")
tokenFile = os.getenv("NATS_TOKEN_FILE")
token = readFile(tokenFile)
conn = nats.connect(natsUrl, token=token)
```

## Security Considerations

- Tokens are automatically rotated by Kubernetes before expiration
- Tokens are audience-restricted to "nats"
- Network access is restricted via Cilium NetworkPolicy
- Tokens are mounted read-only

## Example: Enabling NATS for an Application

Here's a complete example of how to enable NATS for an application deployment:

```yaml
# values-with-nats.yaml
app:
  name: my-event-driven-app
  image:
    repository: my-org/my-app
    tag: "1.0.0"

infra:
  nats:
    enabled: true
    # Use defaults for other values
```

Deploy with:
```bash
helm upgrade --install my-app charts/app -f values-with-nats.yaml
```

## Custom NATS Configuration

If your NATS service is deployed at a custom location:

```yaml
infra:
  nats:
    enabled: true
    serviceAddress: "nats.custom-namespace.svc.cluster.local"
    port: 4223
    tokenPath: "/var/run/secrets/custom-nats"
    tokenExpirationSeconds: 7200  # 2 hours
```

## Verifying NATS Configuration

After deploying with NATS enabled, verify the configuration:

```bash
# Check environment variables
kubectl exec deployment/my-app -- env | grep NATS

# Check mounted token
kubectl exec deployment/my-app -- ls -la /var/run/secrets/nats/

# View the NetworkPolicy
kubectl get ciliumnetworkpolicy -o yaml | grep -A 10 nats
```

## Troubleshooting

### Token not found
- Verify `infra.nats.enabled: true` in your values
- Check that the projected volume is mounted: `kubectl describe pod <pod-name>`
- Ensure the service account has permissions to request tokens

### Connection refused
- Verify the NATS service is running: `kubectl get svc -n messaging`
- Check the NetworkPolicy allows egress: `kubectl get ciliumnetworkpolicy <app-name> -o yaml`
- Verify the service address and port match your NATS deployment

### Authentication failed
- Check token expiration: tokens rotate at 80% of `tokenExpirationSeconds`
- Verify the NATS service is configured to accept tokens with audience "nats"
- Ensure the service account is authorized in the NATS OIDC configuration

## Reference

For detailed NATS server setup and client integration patterns, see:
- [NATS Kubernetes OIDC Callout](https://github.com/portswigger-tim/nats-k8s-oidc-callout)
- [Client Usage Guide](https://github.com/portswigger-tim/nats-k8s-oidc-callout/blob/main/docs/CLIENT_USAGE.md)

## Future Enhancements

Potential future additions (not currently implemented):
- NATS support for cron chart (if cron jobs need to publish/subscribe to events)
- NATS support for infra chart (if infrastructure components need event integration)
- Support for NATS JetStream-specific configuration
- Support for multiple NATS clusters/contexts
