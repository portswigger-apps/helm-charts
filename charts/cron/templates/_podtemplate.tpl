{{/* vim: set filetype=mustache: */}}


{{/*
Outputs a pod spec for use in different resources.
*/}}
{{- define "cron.podTemplate" }}
          metadata:
            {{- if .Values.pod.annotations }}
            annotations:
              {{- toYaml .Values.pod.annotations | nindent 14 }}
            {{- end }}
            labels:
              {{- include "cron.labels" . | nindent 14 }}
              {{- with .Values.pod.labels }}
              {{- toYaml . | nindent 14 }}
              {{- end }}
          spec:
            serviceAccountName: {{ include "cron.serviceAccountName" . }}
            terminationGracePeriodSeconds: 30
            restartPolicy: {{ .Values.cron.restartPolicy}}
            securityContext:
              fsGroup: 1000
              fsGroupChangePolicy: "OnRootMismatch"
            containers:
              - name: {{ template "cron.name" . }}
                image: "{{ .Values.image.name }}:{{ .Values.image.tag }}"
                imagePullPolicy: Always
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
                {{- with .Values.cron.command}}
                command:  {{- toYaml . | nindent 16 }}
                {{- end }}
                {{- with .Values.cron.args }}
                args:
                {{- toYaml . | nindent 16 }}
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
                  - name: IMAGE_TAG
                    value: {{ .Values.image.tag | quote }}
                  {{- range $key, $value := .Values.env}}
                  - name: {{ $key }}
                    value: {{ $value | quote }}
                  {{- end }}
                  {{- if .Values.infra.s3Bucket.name }}
                  - name: S3_REGION
                    valueFrom:
                     secretKeyRef:
                       name: {{ .Values.infra.s3Bucket.name}}-s3bucket
                       key: region
                  - name: S3_ID
                    valueFrom:
                      secretKeyRef:
                        name: {{ .Values.infra.s3Bucket.name}}-s3bucket
                        key: id
                  - name: S3_ARN
                    valueFrom:
                      secretKeyRef:
                        name: {{ .Values.infra.s3Bucket.name}}-s3bucket
                        key: arn
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
                volumeMounts:
                - mountPath: /tmp
                  name: tmp-volume
                {{- if .Values.secretVolume }}
                - mountPath: /secrets
                  name: {{ $.Release.Name }}-volume
                  readOnly: true
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
            volumes:
            - name: tmp-volume
              emptyDir: {}
            {{- if .Values.secretVolume }}
            - name: {{ $.Release.Name }}-volume
              secret:
                secretName: {{ $.Release.Name }}-volume
        {{- end }}
{{- end }}
