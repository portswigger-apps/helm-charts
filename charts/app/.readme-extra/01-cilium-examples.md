## CiliumNetworkPolicy examples

Allow access from an app named `my-other-app` in your product namespace
```yaml
ciliumNetworkPolicy:
  fromApps:
    - name: my-other-app
```

Allow access from an app named `admin-frontend` in the `web` product namespace
```yaml
ciliumNetworkPolicy:
  fromApps:
    - name: admin-frontend
      namespace: web
```

Allow access to an app named `orders` in your product namespace
```yaml
ciliumNetworkPolicy:
  toApps:
    - name: orders
```

Allow access to an app named `updates` in the `web` product namespace
```yaml
ciliumNetworkPolicy:
  toApps:
    - name: updates
      namespace: web
```

Allow access to a HTTPS API `api.example.com` and `api.openai.com`
```yaml
ciliumNetworkPolicy:
  externalHttpsServices:
    - api.example.com
    - api.openai.com
```