#!/bin/bash

# Скрипт для деплоя приложений в ArgoCD
# Автор: Eugene Surkov

set -e

echo "Начинаем деплой приложений в ArgoCD"

# Проверяем, установлен ли kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl не установлен. Пожалуйста, установите kubectl и попробуйте снова."
    exit 1
fi

# Проверяем, установлен ли ArgoCD CLI
if ! command -v argocd &> /dev/null; then
    echo "ArgoCD CLI не установлен. Рекомендуется установить для более удобного управления."
    echo "Продолжаем с использованием только kubectl..."
fi

# Проверяем доступность кластера
echo "Проверка соединения с кластером Kubernetes..."
if ! kubectl get nodes &> /dev/null; then
    echo "Ошибка соединения с кластером Kubernetes. Проверьте ваш kubeconfig."
    exit 1
fi

# Проверяем наличие namespace argocd
if ! kubectl get namespace argocd &> /dev/null; then
    echo "Namespace argocd не найден. Создаем..."
    kubectl create namespace argocd
else
    echo "Namespace argocd уже существует"
fi

# Проверка установки ArgoCD
if ! kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server &> /dev/null; then
    echo "ArgoCD не установлен в кластере. Устанавливаем..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "Ожидание запуска ArgoCD..."
    kubectl wait --for=condition=available --timeout=300s -n argocd deployment/argocd-server
    
    # Установка ArgoCD CLI (если не установлен)
    if ! command -v argocd &> /dev/null; then
        echo "Инструкция по установке ArgoCD CLI: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    fi
else
    echo "ArgoCD уже установлен в кластере"
fi

# Проверяем наличие секрета для SSH-ключа доступа к репозиторию
echo "Проверка наличия секрета для доступа к репозиторию..."
if ! kubectl get secret tgads-repo-ssh-key -n argocd &> /dev/null; then
    echo "ВНИМАНИЕ: Секрет для SSH-ключа не найден в кластере!"
    echo "Для корректной работы с Git-репозиторием через SSH необходимо создать секрет вручную."
    echo "Инструкции находятся в файле argocd/README.md"
    echo "Пример шаблона секрета: argocd/secret-template.yaml"
    echo ""
    echo "Для продолжения работы с HTTPS вместо SSH, можете продолжить деплой."
    echo "Для использования SSH, прервите скрипт (Ctrl+C) и создайте секрет вручную."
    
    # Спрашиваем пользователя о продолжении
    read -p "Продолжить деплой без SSH-ключа? (y/n): " answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "Деплой прерван. Создайте секрет и запустите скрипт снова."
        exit 1
    fi
else
    echo "Секрет для доступа к репозиторию найден в кластере."
fi

# Применяем конфигурацию ArgoCD
echo "Применяем конфигурацию ArgoCD..."
kubectl apply -f $(dirname "$0")/argocd/config.yaml

# Проверка CRD ApplicationSet
echo "Проверка наличия CRD ApplicationSet..."
if ! kubectl get crd applicationsets.argoproj.io &> /dev/null; then
    echo "Устанавливаем CRD ApplicationSet..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/applicationset/v0.4.1/manifests/install.yaml
    echo "Ожидание установки ApplicationSet контроллера..."
    kubectl wait --for=condition=available --timeout=300s -n argocd deployment/argocd-applicationset-controller
fi

# Применяем ApplicationSet
echo "Применяем ApplicationSet для генерации приложений..."
kubectl apply -f $(dirname "$0")/argocd/applicationset.yaml

# Применяем app-of-apps
echo "Применяем app-of-apps манифест..."
kubectl apply -f $(dirname "$0")/argocd/app-of-apps.yaml

echo "Ожидание создания ресурсов..."
sleep 5

# Проверка статуса ApplicationSet
echo "Проверка статуса ApplicationSet в ArgoCD..."
kubectl get applicationset -n argocd

# Проверка статуса приложений
echo "Проверка статуса приложений в ArgoCD..."
kubectl get applications -n argocd

echo "Деплой завершен. Все приложения настроены в ArgoCD."
echo "Для проверки статуса синхронизации выполните: kubectl get applications -n argocd"
echo "Для доступа к UI ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Пароль администратора по умолчанию хранится в секрете: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
