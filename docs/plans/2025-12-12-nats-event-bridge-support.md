# NATS Event Bridge Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add conditional NATS event bridge support to Helm charts with network policy, projected service account token, and environment variables.

**Architecture:** Extend the existing `infra` configuration pattern (similar to postgres, redis, s3) with a new `infra.nats` section that conditionally adds: (1) Cilium NetworkPolicy egress rule for NATS service, (2) Projected service account token volume with "nats" audience, (3) Environment variables for NATS_URL and NATS_TOKEN_FILE.

**Tech Stack:** Helm templates, Kubernetes resources (CiliumNetworkPolicy, ServiceAccount projections), helm-unittest for testing

---

## Task 1: Add NATS Configuration to App Chart Values

**Files:**
- Modify: `charts/app/values.yaml`

**Step 1: Write test for NATS configuration in values**

Create test file: `charts/app/tests/nats_configuration_test.yaml`

```yaml
suite: NATS Configuration

templates:
  - kubernetes/deployment.yaml
  - cilium/networkpolicy.yaml

tests:
  - it: should not enable NATS by default
    template: kubernetes/deployment.yaml
    asserts:
      - notContains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_URL
      - notContains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_TOKEN_FILE

  - it: should not add NATS volume when disabled
    template: kubernetes/deployment.yaml
    asserts:
      - notContains:
          path: spec.template.spec.volumes
          content:
            name: nats-token
```

**Step 2: Run test to verify it fails**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: FAIL - test file doesn't exist yet

**Step 3: Create the test file**

Create the test file with content from Step 1.

**Step 4: Run test to verify it passes (baseline)**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: PASS - NATS not enabled by default

**Step 5: Add NATS configuration to values.yaml**

In `charts/app/values.yaml`, add after the `infra.opensearch` section (around line 461):

```yaml
  nats:
    # infra.nats.enabled -- Set to `true` to enable NATS event bridge support
    # @section -- infra
    enabled: false
    # infra.nats.serviceAddress -- The NATS service address in the cluster
    # @default -- `nats.messaging.svc.cluster.local`
    # @section -- infra
    serviceAddress: "nats.messaging.svc.cluster.local"
    # infra.nats.port -- The NATS service port
    # @default -- `4222`
    # @section -- infra
    port: 4222
    # infra.nats.tokenPath -- The path where the NATS token will be mounted
    # @default -- `/var/run/secrets/nats`
    # @section -- infra
    tokenPath: "/var/run/secrets/nats"
    # infra.nats.tokenExpirationSeconds -- Token expiration time in seconds
    # @default -- `3600`
    # @section -- infra
    tokenExpirationSeconds: 3600
```

**Step 6: Run tests to verify configuration**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: PASS - values added correctly

**Step 7: Commit changes**

```bash
git add charts/app/values.yaml charts/app/tests/nats_configuration_test.yaml
git commit -m "feat: add NATS configuration to app chart values"
```

---

## Task 2: Add NATS Projected Service Account Token Volume to Pod Template

**Files:**
- Modify: `charts/app/templates/kubernetes/_podtemplate.tpl:155-201`

**Step 1: Write test for NATS volume and volumeMount**

Add to `charts/app/tests/nats_configuration_test.yaml`:

```yaml
  - it: should add NATS projected service account token volume when enabled
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.template.spec.volumes
          content:
            name: nats-token
            projected:
              sources:
                - serviceAccountToken:
                    audience: nats
                    expirationSeconds: 3600
                    path: token

  - it: should add NATS volume mount when enabled
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].volumeMounts
          content:
            mountPath: /var/run/secrets/nats
            name: nats-token
            readOnly: true

  - it: should use custom token expiration when configured
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
          tokenExpirationSeconds: 7200
    asserts:
      - contains:
          path: spec.template.spec.volumes
          content:
            name: nats-token
            projected:
              sources:
                - serviceAccountToken:
                    audience: nats
                    expirationSeconds: 7200
                    path: token
```

**Step 2: Run test to verify it fails**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml' -t 'should add NATS projected'`

Expected: FAIL - volume not present in template

**Step 3: Add NATS volume to pod template**

In `charts/app/templates/kubernetes/_podtemplate.tpl`, add after line 163 (after secretVolume volumeMount):

```go
        {{- if .Values.infra.nats.enabled }}
        - mountPath: {{ .Values.infra.nats.tokenPath }}
          name: nats-token
          readOnly: true
        {{- end }}
```

And add after line 197 (after secretVolume volume):

```go
      {{- if .Values.infra.nats.enabled }}
      - name: nats-token
        projected:
          sources:
            - serviceAccountToken:
                audience: nats
                expirationSeconds: {{ .Values.infra.nats.tokenExpirationSeconds }}
                path: token
      {{- end }}
```

**Step 4: Run test to verify it passes**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: PASS - all NATS volume tests pass

**Step 5: Commit changes**

```bash
git add charts/app/templates/kubernetes/_podtemplate.tpl charts/app/tests/nats_configuration_test.yaml
git commit -m "feat: add NATS projected service account token volume to pod template"
```

---

## Task 3: Add NATS Environment Variables to Pod Template

**Files:**
- Modify: `charts/app/templates/kubernetes/_podtemplate.tpl:99-144`
- Create: `charts/app/templates/_helpers.tpl` (add helper function)

**Step 1: Write test for NATS environment variables**

Add to `charts/app/tests/nats_configuration_test.yaml`:

```yaml
  - it: should add NATS_URL environment variable when enabled
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_URL
            value: nats://nats.messaging.svc.cluster.local:4222

  - it: should add NATS_TOKEN_FILE environment variable when enabled
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_TOKEN_FILE
            value: /var/run/secrets/nats/token

  - it: should use custom NATS service address when configured
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
          serviceAddress: nats.custom.svc.cluster.local
          port: 4223
    asserts:
      - contains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_URL
            value: nats://nats.custom.svc.cluster.local:4223

  - it: should use custom token path when configured
    template: kubernetes/deployment.yaml
    set:
      infra:
        nats:
          enabled: true
          tokenPath: /custom/path/nats
    asserts:
      - contains:
          path: spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_TOKEN_FILE
            value: /custom/path/nats/token
```

**Step 2: Run test to verify it fails**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml' -t 'should add NATS_URL'`

Expected: FAIL - environment variables not present

**Step 3: Add helper function for NATS environment variables**

In `charts/app/templates/_helpers.tpl`, add at the end of the file:

```go
{{/*
NATS connection environment variables
*/}}
{{- define "app.natsConnectionEnv" }}
{{- if .Values.infra.nats.enabled }}
- name: NATS_URL
  value: {{ printf "nats://%s:%d" .Values.infra.nats.serviceAddress (.Values.infra.nats.port | int) }}
- name: NATS_TOKEN_FILE
  value: {{ printf "%s/token" .Values.infra.nats.tokenPath }}
{{- end }}
{{- end }}
```

**Step 4: Add NATS environment variables to pod template**

In `charts/app/templates/kubernetes/_podtemplate.tpl`, add after line 139 (after openSearchCollectionEnvs):

```go
          {{- include "app.natsConnectionEnv" . | nindent 10 }}
```

**Step 5: Run test to verify it passes**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: PASS - all NATS environment variable tests pass

**Step 6: Commit changes**

```bash
git add charts/app/templates/_helpers.tpl charts/app/templates/kubernetes/_podtemplate.tpl charts/app/tests/nats_configuration_test.yaml
git commit -m "feat: add NATS connection environment variables"
```

---

## Task 4: Add NATS Egress Rule to Cilium NetworkPolicy

**Files:**
- Modify: `charts/app/templates/cilium/networkpolicy.yaml:88-165`

**Step 1: Write test for NATS egress network policy**

Add to `charts/app/tests/nats_configuration_test.yaml`:

```yaml
  - it: should add NATS egress rule to CiliumNetworkPolicy when enabled
    template: cilium/networkpolicy.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.egress
          content:
            toFQDNs:
              - matchName: nats.messaging.svc.cluster.local
            toPorts:
              - ports:
                  - port: "4222"
                    protocol: TCP

  - it: should use custom NATS service address in egress rule
    template: cilium/networkpolicy.yaml
    set:
      infra:
        nats:
          enabled: true
          serviceAddress: nats.custom.svc.cluster.local
          port: 4223
    asserts:
      - contains:
          path: spec.egress
          content:
            toFQDNs:
              - matchName: nats.custom.svc.cluster.local
            toPorts:
              - ports:
                  - port: "4223"
                    protocol: TCP

  - it: should not add NATS egress rule when disabled
    template: cilium/networkpolicy.yaml
    set:
      infra:
        nats:
          enabled: false
    asserts:
      - notContains:
          path: spec.egress
          content:
            toFQDNs:
              - matchName: nats.messaging.svc.cluster.local
```

**Step 2: Run test to verify it fails**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml' -t 'should add NATS egress'`

Expected: FAIL - NATS egress rule not present

**Step 3: Add NATS to conditional AWS services check**

In `charts/app/templates/cilium/networkpolicy.yaml`, modify line 88-95 to include NATS:

```go
  {{- $s3Enabled := .Values.infra.s3Bucket.enabled }}
  {{- $bedrockEnabled := .Values.infra.bedrock.enabled }}
  {{- $eventbridgeEnabled := .Values.infra.eventing.producer.enabled }}
  {{- $sqsEnabled := .Values.infra.eventing.consumer.enabled }}
  {{- $dynamodbEnabled := (not (empty (.Values.infra.dynamodb.tables ))) }}
  {{- $kinesisEnabled := .Values.infra.kinesis.enabled }}
  {{- $opensearchEnabled := .Values.infra.opensearch.enabled }}
  {{- $natsEnabled := .Values.infra.nats.enabled }}
```

**Step 4: Add NATS egress rule**

Add after line 148 (after postgres egress rule):

```go
  {{- if $natsEnabled }}
  - toFQDNs:
      - matchName: {{ .Values.infra.nats.serviceAddress }}
    toPorts:
      - ports:
          - port: {{ .Values.infra.nats.port | quote }}
            protocol: TCP

  {{- end }}
```

**Step 5: Run test to verify it passes**

Run: `helm unittest charts/app -f 'charts/app/tests/nats_configuration_test.yaml'`

Expected: PASS - all NATS tests pass

**Step 6: Commit changes**

```bash
git add charts/app/templates/cilium/networkpolicy.yaml charts/app/tests/nats_configuration_test.yaml
git commit -m "feat: add NATS egress rule to Cilium NetworkPolicy"
```

---

## Task 5: Add NATS Support to Cron Chart

**Files:**
- Modify: `charts/cron/values.yaml`
- Modify: `charts/cron/templates/kubernetes/_podtemplate.tpl`
- Create: `charts/cron/tests/nats_configuration_test.yaml`

**Step 1: Write test for cron NATS configuration**

Create test file: `charts/cron/tests/nats_configuration_test.yaml`

```yaml
suite: NATS Configuration for Cron

templates:
  - kubernetes/cronjob.yaml

tests:
  - it: should not enable NATS by default
    template: kubernetes/cronjob.yaml
    asserts:
      - notContains:
          path: spec.jobTemplate.spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_URL

  - it: should add NATS environment variables when enabled
    template: kubernetes/cronjob.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.jobTemplate.spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_URL
            value: nats://nats.messaging.svc.cluster.local:4222
      - contains:
          path: spec.jobTemplate.spec.template.spec.containers[?(@.name == "RELEASE-NAME")].env
          content:
            name: NATS_TOKEN_FILE
            value: /var/run/secrets/nats/token

  - it: should add NATS volume and volumeMount when enabled
    template: kubernetes/cronjob.yaml
    set:
      infra:
        nats:
          enabled: true
    asserts:
      - contains:
          path: spec.jobTemplate.spec.template.spec.volumes
          content:
            name: nats-token
            projected:
              sources:
                - serviceAccountToken:
                    audience: nats
                    expirationSeconds: 3600
                    path: token
      - contains:
          path: spec.jobTemplate.spec.template.spec.containers[?(@.name == "RELEASE-NAME")].volumeMounts
          content:
            mountPath: /var/run/secrets/nats
            name: nats-token
            readOnly: true
```

**Step 2: Run test to verify it fails**

Run: `helm unittest charts/cron -f 'charts/cron/tests/nats_configuration_test.yaml'`

Expected: FAIL - test file doesn't exist, NATS not configured

**Step 3: Add NATS configuration to cron values.yaml**

In `charts/cron/values.yaml`, add after the `infra.opensearch` section (similar to app chart):

```yaml
  nats:
    # infra.nats.enabled -- Set to `true` to enable NATS event bridge support
    # @section -- infra
    enabled: false
    # infra.nats.serviceAddress -- The NATS service address in the cluster
    # @default -- `nats.messaging.svc.cluster.local`
    # @section -- infra
    serviceAddress: "nats.messaging.svc.cluster.local"
    # infra.nats.port -- The NATS service port
    # @default -- `4222`
    # @section -- infra
    port: 4222
    # infra.nats.tokenPath -- The path where the NATS token will be mounted
    # @default -- `/var/run/secrets/nats`
    # @section -- infra
    tokenPath: "/var/run/secrets/nats"
    # infra.nats.tokenExpirationSeconds -- Token expiration time in seconds
    # @default -- `3600`
    # @section -- infra
    tokenExpirationSeconds: 3600
```

**Step 4: Add helper function to cron _helpers.tpl**

In `charts/cron/templates/_helpers.tpl`, add at the end:

```go
{{/*
NATS connection environment variables
*/}}
{{- define "cron.natsConnectionEnv" }}
{{- if .Values.infra.nats.enabled }}
- name: NATS_URL
  value: {{ printf "nats://%s:%d" .Values.infra.nats.serviceAddress (.Values.infra.nats.port | int) }}
- name: NATS_TOKEN_FILE
  value: {{ printf "%s/token" .Values.infra.nats.tokenPath }}
{{- end }}
{{- end }}
```

**Step 5: Add NATS to cron pod template**

In `charts/cron/templates/kubernetes/_podtemplate.tpl`, add after line 79 (after openSearchCollectionEnvs):

```go
                {{- include "cron.natsConnectionEnv" . | nindent 16 }}
```

Add after line 100 (after secretVolume volumeMount):

```go
                {{- if .Values.infra.nats.enabled }}
                - mountPath: {{ .Values.infra.nats.tokenPath }}
                  name: nats-token
                  readOnly: true
                {{- end }}
```

Add after line 112 (after secretVolume volume):

```go
          {{- if .Values.infra.nats.enabled }}
          - name: nats-token
            projected:
              sources:
                - serviceAccountToken:
                    audience: nats
                    expirationSeconds: {{ .Values.infra.nats.tokenExpirationSeconds }}
                    path: token
          {{- end }}
```

**Step 6: Run test to verify it passes**

Run: `helm unittest charts/cron -f 'charts/cron/tests/nats_configuration_test.yaml'`

Expected: PASS - all cron NATS tests pass

**Step 7: Commit changes**

```bash
git add charts/cron/values.yaml charts/cron/templates/_helpers.tpl charts/cron/templates/kubernetes/_podtemplate.tpl charts/cron/tests/nats_configuration_test.yaml
git commit -m "feat: add NATS support to cron chart"
```

---

## Task 6: Add NATS Support to Infra Chart

**Files:**
- Modify: `charts/infra/values.yaml`

**Step 1: Add NATS configuration to infra values**

In `charts/infra/values.yaml`, add after the `opensearch` section (around line 323):

```yaml
nats:
  # nats.enabled -- Set to `true` to enable NATS event bridge support
  # @section -- nats
  enabled: false
  # nats.serviceAddress -- The NATS service address in the cluster
  # @default -- `nats.messaging.svc.cluster.local`
  # @section -- nats
  serviceAddress: "nats.messaging.svc.cluster.local"
  # nats.port -- The NATS service port
  # @default -- `4222`
  # @section -- nats
  port: 4222
  # nats.tokenPath -- The path where the NATS token will be mounted
  # @default -- `/var/run/secrets/nats`
  # @section -- nats
  tokenPath: "/var/run/secrets/nats"
  # nats.tokenExpirationSeconds -- Token expiration time in seconds
  # @default -- `3600`
  # @section -- nats
  tokenExpirationSeconds: 3600
```

**Step 2: Verify configuration format**

Run: `helm lint charts/infra`

Expected: No errors or warnings

**Step 3: Commit changes**

```bash
git add charts/infra/values.yaml
git commit -m "feat: add NATS configuration to infra chart values"
```

---

## Task 7: Run Full Test Suite and Validation

**Files:**
- Test: All test files created

**Step 1: Run app chart tests**

Run: `helm unittest charts/app`

Expected: All tests PASS (including new NATS tests)

**Step 2: Run cron chart tests**

Run: `helm unittest charts/cron`

Expected: All tests PASS (including new NATS tests)

**Step 3: Lint all charts**

Run: `helm lint charts/app charts/cron charts/infra`

Expected: No errors or warnings

**Step 4: Test rendering with NATS enabled**

Run:
```bash
helm template test-nats charts/app --set infra.nats.enabled=true --debug
```

Expected: YAML renders correctly with NATS configuration

**Step 5: Verify all NATS components present**

Verify output contains:
- NATS_URL environment variable
- NATS_TOKEN_FILE environment variable
- nats-token volume with projected serviceAccountToken
- nats-token volumeMount
- NATS egress rule in CiliumNetworkPolicy

**Step 6: Test rendering with NATS disabled (default)**

Run:
```bash
helm template test-nats charts/app --debug
```

Expected: No NATS configuration present in output

**Step 7: Create final verification commit**

```bash
git add -A
git commit -m "test: validate NATS implementation with full test suite"
```

---

## Task 8: Update Documentation

**Files:**
- Create or modify: `docs/NATS.md` or update existing README

**Step 1: Create NATS usage documentation**

Create `docs/NATS.md`:

```markdown
# NATS Event Bridge Configuration

This Helm chart supports conditional integration with NATS event bridge for event-driven applications.

## Configuration

Enable NATS support in your `values.yaml`:

\`\`\`yaml
infra:
  nats:
    enabled: true
    serviceAddress: "nats.messaging.svc.cluster.local"  # optional, default shown
    port: 4222                                           # optional, default shown
    tokenPath: "/var/run/secrets/nats"                  # optional, default shown
    tokenExpirationSeconds: 3600                         # optional, default shown
\`\`\`

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
\`\`\`
natsUrl = os.getenv("NATS_URL")
tokenFile = os.getenv("NATS_TOKEN_FILE")
token = readFile(tokenFile)
conn = nats.connect(natsUrl, token=token)
\`\`\`

## Security Considerations

- Tokens are automatically rotated by Kubernetes before expiration
- Tokens are audience-restricted to "nats"
- Network access is restricted via Cilium NetworkPolicy
- Tokens are mounted read-only

## Reference

For detailed client integration patterns, see:
https://github.com/portswigger-tim/nats-k8s-oidc-callout/blob/main/docs/CLIENT_USAGE.md
```

**Step 2: Commit documentation**

```bash
git add docs/NATS.md
git commit -m "docs: add NATS event bridge configuration guide"
```

---

## Completion Checklist

After completing all tasks, verify:

- [ ] NATS configuration added to app chart values
- [ ] NATS configuration added to cron chart values
- [ ] NATS configuration added to infra chart values
- [ ] Projected service account token volume configured
- [ ] Environment variables (NATS_URL, NATS_TOKEN_FILE) configured
- [ ] Cilium NetworkPolicy egress rule added
- [ ] All tests pass for app chart
- [ ] All tests pass for cron chart
- [ ] Helm lint passes for all charts
- [ ] Template rendering verified with NATS enabled
- [ ] Template rendering verified with NATS disabled (default)
- [ ] Documentation created
- [ ] All commits have clear, descriptive messages

## Testing Strategy

This implementation follows Test-Driven Development (TDD):

1. Write failing test first
2. Implement minimal code to pass test
3. Verify test passes
4. Refactor if needed
5. Commit with clear message

Tests use `helm unittest` with assertions to verify:
- Default behavior (NATS disabled)
- NATS enabled configuration
- Custom configuration values
- Correct resource rendering

## Notes for Implementation

- The implementation follows existing patterns from other infra resources (postgres, redis, s3)
- All configuration is conditional based on `infra.nats.enabled`
- Default values match the requirements from nats-k8s-oidc-callout documentation
- Tests cover both app and cron charts to ensure consistency
- Network policy follows existing AWS service patterns
- Projected service account tokens are a Kubernetes-native feature requiring no external dependencies
