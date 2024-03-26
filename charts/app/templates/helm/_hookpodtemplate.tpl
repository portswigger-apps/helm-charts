{{/* vim: set filetype=mustache: */}}


{{/*
Outputs a pod spec for use in helm hooks.
*/}}
{{- define "app.hookPodTemplate" }}
    metadata:
      annotations:
        checksum/secret-env: {{ $envSec := include (print $.Template.BasePath "/kubernetes/secret-env.yaml") . | fromYaml }}{{ $envSec.data | toYaml | sha256sum }}
        checksum/secret-volume: {{ $envSec := include (print $.Template.BasePath "/kubernetes/secret-volume.yaml") . | fromYaml }}{{ $envSec.data | toYaml | sha256sum }}
      {{- with .Values.pod.annotations }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
      {{- include "app.labels" . | nindent 8 }}
      {{- with .Values.pod.labels }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      restartPolicy: OnFailure
      serviceAccountName: {{ include "app.serviceAccountName" . }}
      terminationGracePeriodSeconds: 30
      containers:
      - image: "{{ .Values.image.name }}:{{ .Values.image.tag }}"
        imagePullPolicy: Always
        name: {{ template "app.name" . }}
        command: {{ toYaml .command | nindent 8 }}
        resources:
          requests:
            memory: {{ quote .Values.resources.memory }}
            cpu: {{ quote .Values.resources.cpu }}
          limits:
            memory: {{ quote .Values.resources.memory }}
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
              - ALL
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
          - name: IMAGE_TAG
            value: {{ .Values.image.tag | quote }}
          {{- range $key, $value := .Values.env}}
          - name: {{ $key }}
            value: {{ $value | quote }}
          {{- end }}
          {{- if .Values.infra.postgres.name }}
          - name: DATABASE_NAME
            value: app
          - name: DATABASE_HOST
            valueFrom:
              secretKeyRef:
                name: {{ .Values.infra.postgres.name}}-postgres
                key: host
          - name: DATABASE_PORT
            valueFrom:
              secretKeyRef:
                name: {{ .Values.infra.postgres.name}}-postgres
                key: port
          - name: DATABASE_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ .Values.infra.postgres.name}}-postgres
                key: username
          - name: DATABASE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ .Values.infra.postgres.name}}-postgres
                key: password
          - name: DATABASE_URL
            value: "postgres://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"
          - name: JDBC_DATABASE_URL
            value: "jdbc:postgresql://$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)?user=$(DATABASE_USERNAME)&password=$(DATABASE_PASSWORD)"
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
      {{- if .Values.secretVolume }}
      - name: {{ $.Release.Name }}-volume
        secret:
          secretName: {{ $.Release.Name }}-volume
      {{- end }}
      {{- if .Values.pod.additionalVolumes }}
      {{- toYaml .Values.pod.additionalVolumes | nindent 6 }}
      {{- end }}
{{- end }}
