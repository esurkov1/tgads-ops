# Настройка SSH аутентификации в ArgoCD

## Обзор

Этот документ описывает процесс настройки SSH аутентификации для доступа ArgoCD к Git репозиториям. SSH аутентификация более безопасна по сравнению с HTTPS, так как не требует хранения паролей.

## Структура

В репозитории `tgads-ops` для аутентификации ArgoCD используются следующие компоненты:

- `argocd/repo-ssh-key-secret.yaml` - Kubernetes Secret, содержащий SSH ключ
- Конфигурации приложений с SSH URL репозиториев

## Применение Secret с SSH ключом

Перед развертыванием приложений в ArgoCD, нужно создать Secret с SSH ключом:

```bash
kubectl apply -f argocd/repo-ssh-key-secret.yaml
```

## Генерация нового SSH ключа

Если требуется создать новый SSH ключ:

1. Создайте ключ:
   ```bash
   ssh-keygen -t ed25519 -C "argocd@example.com" -f ~/.ssh/argocd_key
   ```

2. Получите содержимое приватного ключа:
   ```bash
   cat ~/.ssh/argocd_key
   ```

3. Обновите Secret в файле `argocd/repo-ssh-key-secret.yaml`, заменив заглушку значением `sshPrivateKey`. 
   
   **ВАЖНО**: Не коммитьте приватный ключ в Git! Вместо этого:
   - Создайте временный файл с полной конфигурацией Secret
   - Примените его напрямую в кластер (`kubectl apply -f /tmp/secret.yaml`)
   - Не сохраняйте файл с реальным ключом в репозитории

4. Добавьте публичный ключ в GitHub:
   ```bash
   cat ~/.ssh/argocd_key.pub
   ```
   Скопируйте вывод в настройки GitHub репозитория (Settings -> Deploy Keys)

## Смена URL репозитория

При смене URL репозитория с HTTPS на SSH формат:
- Используйте формат `git@github.com:организация/репозиторий.git` вместо `https://github.com/организация/репозиторий.git`
- Обновите все ссылки в конфигурации приложений ArgoCD

## Проверка настройки

Чтобы проверить, что ArgoCD может использовать SSH ключ:

1. Откройте интерфейс ArgoCD
2. Перейдите в Settings -> Repositories 
3. Убедитесь, что репозиторий отображается как "Connected"

## Устранение неполадок

Если возникли проблемы с подключением:

1. Проверьте логи ArgoCD:
   ```bash
   kubectl logs -n argocd deployment/argocd-repo-server
   ```

2. Убедитесь, что Secret правильно создан:
   ```bash
   kubectl get secret -n argocd tgads-repo-ssh-key -o yaml
   ```

3. Проверьте, что публичный ключ добавлен в настройки репозитория на GitHub
