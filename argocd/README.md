# ArgoCD App-of-Apps

Это базовая конфигурация паттерна "App-of-Apps" для ArgoCD.

## Структура

- `app-of-apps.yaml` - Главное приложение ArgoCD, которое управляет другими приложениями.
- `apps/` - Директория с определениями приложений, которые будут развернуты через ArgoCD.
- `repo-ssh-key-secret.yaml` - Kubernetes Secret с SSH ключом для аутентификации в Git репозиториях.
- `docs/` - Документация по настройке и использованию ArgoCD:
  - `ssh-auth.md` - Инструкция по настройке SSH аутентификации.

## Добавление нового приложения

Для добавления нового приложения необходимо создать новый файл в директории `apps/` с конфигурацией Application.

Пример:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-application
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/esurkov1/tgads-ops.git
    targetRevision: HEAD
    path: services/new-application
  destination:
    server: https://kubernetes.default.svc
    namespace: new-application
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Применение

Для применения конфигурации в кластере Kubernetes:

```bash
kubectl apply -f app-of-apps.yaml
```

После этого ArgoCD автоматически развернет все приложения, указанные в директории `apps/`.
