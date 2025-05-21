{{/* vim: set filetype=mustache: */}}


{{/*
Outputs a pod spec for use in different resources.
*/}}
{{- define "cron.podTemplate" }}
        metadata:
          {{- if .Values.pod.annotations }}
          annotations:
            {{- toYaml .Values.pod.annotations | nindent 12 }}
          {{- end }}
          labels:
            {{- include "cron.labels" . | nindent 12 }}
            {{- with .Values.pod.labels }}
            {{- toYaml . | nindent 12 }}
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
              command:  {{- toYaml . | nindent 14 }}
              {{- end }}
              {{- with .Values.cron.args }}
              args: {{- toYaml . | nindent 14 }}
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
                {{- if .Values.infra.eventing.producer.enabled }}
                - name: EVENTING_BUS_NAME
                  value: {{ .Values.infra.eventing.producer.eventBusName }}
                {{- end }}
                {{- if .Values.infra.eventing.consumer.enabled }}
                - name: EVENTING_QUEUE_NAME
                  value: {{ include "cron.aws.name" . }}-events
                {{- end }}
                {{- include "cron.s3BucketConnectionSecretEnv" . | nindent 16 }}
                {{- include "cron.postgresConnectionSecretEnv" . | nindent 16 }}
                {{- include "cron.dynamodbTableEnvs" . | nindent 16 }}
                {{- range $key, $value := .Values.env}}
                - name: {{ $key }}
                  value: {{ $value | quote }}
                {{- end }}
              {{- if or .Values.envFrom .Values.secretEnv}}
              envFrom:
                {{- with .Values.envFrom }}
                {{- toYaml . | nindent 16 }}
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
          volumes:
          - name: tmp-volume
            emptyDir: {}
          {{- if .Values.secretVolume }}
          - name: {{ $.Release.Name }}-volume
            secret:
              secretName: {{ $.Release.Name }}-volume
          {{- end }}
{{- end }}
