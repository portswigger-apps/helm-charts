{{/* vim: set filetype=mustache: */}}


{{/*
Outputs a pod spec for use in different resources.
*/}}
{{- define "app.podTemplate" }}
    metadata:
      annotations:
        checksum/secret-env: {{ (fromYaml (include (print $.Template.BasePath "/kubernetes/secret-env.yaml") . )).data | toYaml | sha256sum}}
        checksum/secret-volume: {{ (fromYaml (include (print $.Template.BasePath "/kubernetes/secret-volume.yaml") .)).data | toYaml | sha256sum }}
      {{- with .Values.pod.annotations }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
      {{- include "app.labels" . | nindent 8 }}
      {{- with .Values.pod.labels }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      serviceAccountName: {{ include "app.serviceAccountName" . }}
      terminationGracePeriodSeconds: 30
      {{- with .Values.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - image: "{{ .Values.image.name }}:{{ .Values.image.tag }}"
        imagePullPolicy: Always
        name: {{ template "app.name" . }}
        resources:
          requests:
            memory: {{ quote .Values.resources.memory }}
            cpu: {{ quote .Values.resources.cpu }}
          limits:
            memory: {{ quote .Values.resources.memory }}
        ports:
        {{- range $portName, $portSpec := .Values.ports }}
          - name: {{ $portName }}
            containerPort: {{ $portSpec.port }}
            protocol: {{ $portSpec.protocol }}
        {{- end }}
        startupProbe:
          httpGet:
            path: {{ .Values.healthcheckEndpoint.path }}
            port: {{ .Values.healthcheckEndpoint.port }}
            scheme: HTTP
          failureThreshold: 60
          periodSeconds: 5
          timeoutSeconds: 2
        readinessProbe:
          httpGet:
            path: {{ .Values.healthcheckEndpoint.path }}
            port: {{ .Values.healthcheckEndpoint.port }}
            scheme: HTTP
          failureThreshold: 1
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        livenessProbe:
          httpGet:
            path: {{ .Values.healthcheckEndpoint.path }}
            port: {{ .Values.healthcheckEndpoint.port }}
            scheme: HTTP
          failureThreshold: 3
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
              - ALL
        {{- with .Values.args }}
        args:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        env:
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: DOTNET_GCHeapHardLimit
            value: {{ .Values.env.DOTNET_GCHeapHardLimit | default (printf "0x%x" (mulf (include "app.toBytes" .Values.resources.memory) 0.94 | int)) | quote }}
          - name: GOMEMLIMIT
            value: {{ .Values.env.GOMEMLIMIT | default (mulf (include "app.toBytes" .Values.resources.memory) 0.94 | int) | quote }}
          - name: _JAVA_OPTIONS
            value: {{ .Values.env._JAVA_OPTIONS | default "-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=60.0 -XX:MaxRAMPercentage=80.0 -Djava.security.properties=/java-config/java.security" | quote }}
          - name: IMAGE_TAG
            value: {{ .Values.image.tag | quote }}
          {{- if and .Values.infra.eventbridge.enabled .Values.infra.eventbridge.eventBusARN }}
          - name: EVENTBUS_ARN
            value: {{ .Values.infra.eventbridge.eventBusARN }}
          {{- end }}
          {{- include "app.s3BucketConnectionSecretEnv" . | nindent 10 }}
          {{- include "app.postgresConnectionSecretEnv" . | nindent 10 }}
          {{- include "app.redisConnectionSecretEnv" . | nindent 10 }}
          {{- range $key, $value := omit .Values.env "DOTNET_GCHeapHardLimit" "GOMEMLIMIT" "_JAVA_OPTIONS" }}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end }}
        {{- if or .Values.envFrom .Values.secretEnv}}
        envFrom:
          {{- with .Values.envFrom }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
          {{- if .Values.secretEnv }}
          - secretRef:
              name: {{ .Release.Name }}-env
          {{- end }}
        {{- end }}
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
        - mountPath: /java-config
          name: java-config
        {{- if .Values.secretVolume }}
        - mountPath: /secrets
          name: {{ $.Release.Name }}-volume
          readOnly: true
        {{- end }}
        {{- if .Values.pod.additionalVolumeMounts }}
        {{- toYaml .Values.pod.additionalVolumeMounts | nindent 8 }}
        {{- end }}
      {{- with .Values.pod.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        fsGroup: 1000
        fsGroupChangePolicy: "OnRootMismatch"
      topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            {{- include "app.labelselector" . | nindent 12 }}
        maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
      - labelSelector:
          matchLabels:
            {{- include "app.labelselector" . | nindent 12 }}
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
      volumes:
      - name: tmp-volume
        emptyDir: {}
      - name: java-config
        configMap:
          name: {{ $.Release.Name }}-java-config
      {{- if .Values.secretVolume }}
      - name: {{ $.Release.Name }}-volume
        secret:
          secretName: {{ $.Release.Name }}-volume
      {{- end }}
      {{- if .Values.pod.additionalVolumes }}
      {{- toYaml .Values.pod.additionalVolumes | nindent 6 }}
      {{- end }}
{{- end }}
