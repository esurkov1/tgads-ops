#!/bin/bash

# Скрипт для настройки SSH ключей для GitHub репозитория
# Автор: Eugene Surkov

# Проверка наличия параметров
if [ "$#" -lt 2 ]; then
    echo "Использование: $0 <имя_ключа> <email> [github_repo]"
    echo "Пример: $0 my_project user@example.com my-org/my-repo"
    exit 1
fi

KEY_NAME=$1
EMAIL=$2
REPO=${3:-""}

# Создание директории для SSH ключей, если её нет
mkdir -p ~/.ssh

# Проверка существования ключа
if [ -f ~/.ssh/${KEY_NAME} ]; then
    echo "Ключ ~/.ssh/${KEY_NAME} уже существует. Хотите перезаписать? (y/n)"
    read overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Операция отменена."
        exit 0
    fi
fi

# Создание SSH ключа
echo "Создание SSH ключа..."
ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/${KEY_NAME}

# Добавление ключа в ssh-agent
echo "Добавление ключа в ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/${KEY_NAME}

# Добавление записи в SSH config
CONFIG_ENTRY="Host github.com-${KEY_NAME}
  HostName github.com
  User git
  IdentityFile ~/.ssh/${KEY_NAME}"

if grep -q "Host github.com-${KEY_NAME}" ~/.ssh/config 2>/dev/null; then
    echo "Запись для github.com-${KEY_NAME} уже существует в ~/.ssh/config"
else
    echo "Добавление записи в ~/.ssh/config..."
    echo -e "\n$CONFIG_ENTRY" >> ~/.ssh/config
fi

# Вывод публичного ключа
echo -e "\n\nВаш публичный ключ (добавьте его на GitHub):\n"
cat ~/.ssh/${KEY_NAME}.pub
echo -e "\n"

# Инструкции для GitHub
echo "Инструкции:"
echo "1. Перейдите на GitHub.com и войдите в свой аккаунт"
echo "2. Перейдите в Settings -> SSH and GPG keys -> New SSH key"
echo "3. Вставьте приведенный выше ключ и дайте ему название"
echo "4. Нажмите 'Add SSH key'"

# Если указан репозиторий, вывести инструкции для изменения remote URL
if [ -n "$REPO" ]; then
    echo -e "\nДля настройки Git репозитория выполните:"
    echo "git remote set-url origin git@github.com-${KEY_NAME}:${REPO}.git"
    echo -e "\nДля тестирования соединения выполните:"
    echo "ssh -T git@github.com-${KEY_NAME}"
fi

echo -e "\nГотово! После добавления ключа на GitHub вы сможете использовать SSH аутентификацию."
