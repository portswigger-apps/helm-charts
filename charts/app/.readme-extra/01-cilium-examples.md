## CiliumNetworkPolicy examples

```
# Ingress Example
- fromEndpoints:
  - matchLabels:
      app.kubernetes.io/name: frontend # Pods with this label will be able to access your application
  toPorts:
    - ports:
      - port: "8080"
        protocol: TCP


# Egress Example
- toEndpoints:
  - matchLabels:
    k8s:io.kubernetes.pod.namespace: kube-system
    k8s-app: kube-dns
  toPorts:
  - ports:
     - port: "53"
       protocol: ANY
    rules:
      dns:
      - matchPattern: "*"

# Egress Example
- toFQDNs:
  - matchName: "my-remote-service.com"
```
