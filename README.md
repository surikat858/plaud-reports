# Plaud Reports

[Русский](#русский) · [English](#english)

## Русский

[![GitHub release](https://img.shields.io/github/v/release/surikat858/plaud-reports)](https://github.com/surikat858/plaud-reports/releases)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6)](https://www.microsoft.com/windows)
[![Plaud](https://img.shields.io/badge/Plaud-CLI-4A90D9)](https://plaud.ai)

---

### 📌 О проекте

**Plaud Reports** – это набор PowerShell-скриптов для автоматического получения расшифровок, саммари и списка задач из записей [Plaud](https://plaud.ai) и отправки их на почту.

Решение предназначено для пользователей Windows, которые хотят автоматизировать процесс обработки встреч и отправки отчётов без ручного участия.

**Автор:** [surikat858](https://github.com/surikat858)

---

### 📖 Оглавление

- [О проекте](#-о-проекте)
- [Что сделано](#-что-сделано)
- [Как работает (схема)](#-как-работает-схема)
- [Требования](#-требования)
- [Установка и настройка](#-установка-и-настройка)
- [Использование](#-использование)
- [Структура файлов и папок](#-структура-файлов-и-папок)
- [Тестирование](#-тестирование)
- [Сборка EXE](#-сборка-exe)
- [Часто задаваемые вопросы (FAQ)](#-часто-задаваемые-вопросы-faq)
- [Дальнейшее развитие](#-дальнейшее-развитие)
- [Вклад в проект](#-вклад-в-проект)
- [Лицензия](#-лицензия)
- [Контакты](#-контакты)

---

### 🚀 Что сделано

| Функция | Описание |
|---------|----------|
| **Два варианта скрипта** | Интерактивный (с выводом в консоль) и для Планировщика (без пауз) |
| **Несколько получателей** | Отправка на любое количество email-адресов |
| **Подробное логирование** | Ежедневные логи в папке `PlaudReports` |
| **Автоматическая ротация** | Удаление логов и отчётов старше 14 дней |
| **Кириллица** | Полная поддержка русского языка (UTF-8 с BOM) |
| **Умная отправка** | Отправляются только новые записи (не дублируются) |
| **Прогресс** | Отображение хода выполнения в интерактивном режиме |
| **Безопасность** | Использование паролей приложений для SMTP |

---

### 🔧 Как работает (схема)

```mermaid
flowchart TD
    A[Запуск скрипта] --> R[Удаление логов и отчётов старше 14 дней]
    R --> B[plaud today]
    B --> C[Извлечение ID записей]
    C --> D[Сравнение с plaud_sent.log]
    D --> E{Есть новые записи?}
    E -->|Нет| F[Завершение]
    E -->|Да| G[Цикл по каждой записи]
    G --> H[Получение транскрипции]
    G --> I[Получение саммари]
    G --> J[Получение задач]
    H --> K[Формирование отчёта]
    I --> K
    J --> K
    K --> L[Сохранение в файл]
    L --> M[Отправка письма с вложением]
    M --> N[Запись ID в plaud_sent.log]
    N --> O{Все записи обработаны?}
    O -->|Нет| G
    O -->|Да| F
```

---

### 📦 Требования

| Компонент | Версия / Команда |
|---|---|
| Операционная система | Windows 10 / 11 |
| PowerShell | 5.1 или выше |
| Node.js | 14.x или выше |
| Plaud CLI | `npm install -g @plaud-ai/cli` |
| Авторизация Plaud | `plaud login` |
| SMTP-аккаунт | Логин и пароль приложения |

---

### ⚙️ Установка и настройка

#### 1️⃣ Клонирование репозитория

```bash
git clone https://github.com/surikat858/plaud-reports.git
cd plaud-reports
```

Или скачайте ZIP-архив и распакуйте в любую папку.

#### 2️⃣ Установка Plaud CLI

```powershell
# Установка Plaud CLI через npm
npm install -g @plaud-ai/cli

# Авторизация в Plaud (откроется браузер)
plaud login
```

#### 3️⃣ Настройка скрипта

Откройте файл `send-plaud-report.ps1` или `send-plaud-report-scheduled.ps1` в любом текстовом редакторе.

Найдите блок КОНФИГУРАЦИЯ и замените значения:

```powershell
# ============================================================
# 🔐 КОНФИГУРАЦИЯ (ЗАМЕНИТЕ НА СВОИ ДАННЫЕ)
# ============================================================
$smtpServer = "smtp.your-provider.com"          # SMTP-сервер
$smtpPort = 587                                 # Порт (587 или 465)
$username = "your-email@example.com"            # Логин (полный email)
$password = "your-app-password"                 # Пароль приложения
$from = "sender@example.com"                    # Адрес отправителя

# Список получателей (можно один или несколько)
$recipients = @(
    "recipient1@example.com",
    "recipient2@example.com"
)
```

> ⚠️ **ВАЖНО:** Используйте пароль приложения, а не основной пароль от почтового ящика. Это повышает безопасность.

#### 4️⃣ Разрешение выполнения скриптов

Выполните один раз в PowerShell (от имени администратора):

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 5️⃣ Настройка SMTP

Для популярных почтовых сервисов:

| Сервис | SMTP-сервер | Порт | SSL/TLS |
|---|---|---|---|
| Gmail | smtp.gmail.com | 587 | STARTTLS |
| Yandex | smtp.yandex.ru | 587 | STARTTLS |
| Mail.ru | smtp.mail.ru | 587 | STARTTLS |
| Outlook/Hotmail | smtp-mail.outlook.com | 587 | STARTTLS |
| Reg.ru хостинг | mail.hosting.reg.ru | 587 | STARTTLS |

Для Gmail см. [инструкцию по созданию пароля приложения](#-часто-задаваемые-вопросы-faq).

---

### 🚀 Использование

#### Ручной запуск

```powershell
# Перейдите в папку со скриптом
cd C:\путь\к\plaud-reports

# Запустите интерактивный скрипт
.\send-plaud-report.ps1
```

Что вы увидите:

```text
==================================================
  📧 PLAUD ОТЧЁТ
==================================================

Найдено новых записей: 2

Обработка [1/2]: a1b2c3d4...
  Получение транскрипции... ✅
  Получение саммари... ✅
  Получение задач... ✅
  Сохранение файла... ✅
  Отправка письма... ✅

Обработка [2/2]: e5f6g7h8...
  Получение транскрипции... ✅
  Получение саммари... ✅
  Получение задач... ✅
  Сохранение файла... ✅
  Отправка письма... ✅

==================================================
  📊 ИТОГИ
==================================================
✅ Обработано: 2
✅ Ошибок: 0

📁 Лог сохранён в: C:\Users\...\PlaudReports\plaud_log_2026-08-31.txt
==================================================
```

#### Автоматический запуск (Планировщик)

1. Откройте Планировщик заданий:
   - Нажмите `Win + R`
   - Введите `taskschd.msc`
   - Нажмите Enter

2. Создайте новую задачу:
   - Нажмите "Создать задачу" (справа)

3. Вкладка "Общие":
   - Имя: `Plaud Reports`
   - ✅ "Выполнять независимо от того, зарегистрирован ли пользователь"
   - ✅ "Скрыть"
   - Настроить для: Windows 10

4. Вкладка "Триггеры" → Создать:
   - Начать задачу: По расписанию
   - Повторять каждые: 1 час
   - Продолжительность: Бесконечно

5. Вкладка "Действия" → Создать:
   - Действие: Запуск программы
   - Программа/сценарий: `powershell.exe`
   - Аргументы:

     ```text
     -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\путь\к\plaud-reports\send-plaud-report-scheduled.ps1"
     ```

6. Нажмите ОК и введите пароль учётной записи.

---

### 📁 Структура файлов и папок

```text
plaud-reports/
├── README.md                                    # Документация
├── LICENSE                                      # Лицензия MIT
├── send-plaud-report.ps1                        # Интерактивный скрипт
├── send-plaud-report-scheduled.ps1              # Скрипт для планировщика
├── .gitignore                                    # Игнорируемые файлы
└── docs/
    └── images/                                   # Скриншоты (опционально)

%USERPROFILE%\Documents\PlaudReports\
├── plaud_log_2026-08-31.txt                     # Лог работы за день
├── plaud_sent.log                               # ID отправленных записей
├── 20260831_120000_a1b2c3d4e5f6.txt             # Отчёт 1
└── 20260831_130000_e5f6g7h8i9j0.txt             # Отчёт 2
```

---

### 🧪 Тестирование

Чтобы убедиться, что всё работает:

1. Создайте тестовую запись в приложении Plaud (телефон или компьютер).
2. Дождитесь обработки (1-2 минуты).
3. Запустите скрипт вручную:

   ```powershell
   .\send-plaud-report.ps1
   ```

4. Проверьте результаты:
   - ✅ Новый файл появился в `PlaudReports`
   - ✅ Письмо пришло на все указанные адреса
   - ✅ ID записи добавлен в `plaud_sent.log`

5. Запустите скрипт повторно — он должен сообщить, что все записи уже отправлены.

---

### 📦 Сборка EXE

#### Способ 1: PS2EXE (рекомендуется)

Установите модуль:

```powershell
Install-Module -Name PS2EXE -Scope CurrentUser
```

Создайте EXE:

```powershell
# Для интерактивной версии (с окном)
ps2exe -inputFile .\send-plaud-report.ps1 -outputFile .\PlaudReports.exe -title "Plaud Reports" -version "1.0.0"

# Для версии для планировщика (без окна)
ps2exe -inputFile .\send-plaud-report-scheduled.ps1 -outputFile .\PlaudReportsScheduled.exe -title "Plaud Reports (Scheduled)" -version "1.0.0" -noconsole
```

Готовые EXE-файлы появятся в текущей папке.

#### Способ 2: PowerShell Pro Tools (платный)

1. Откройте PowerShell Pro Tools.
2. Выберите "Package" → "Windows Application".
3. Укажите путь к скрипту и настройте параметры.
4. Нажмите "Build".

> Важно: при создании EXE пути к файлам (`$env:USERPROFILE`) работают корректно, так как они разрешаются во время выполнения.

---

### ❓ Часто задаваемые вопросы (FAQ)

**1. Что делать, если скрипт не видит `plaud`?**

```powershell
# Проверьте установку
plaud --version

# Если не работает, переустановите:
npm uninstall -g @plaud-ai/cli
npm install -g @plaud-ai/cli
```

**2. Как обновить Plaud CLI до последней версии?**

```powershell
npm update -g @plaud-ai/cli
```

**3. Где найти пароль приложения для Gmail?**

Зайдите в Google Аккаунт → Безопасность → включите "Двухфакторную аутентификацию" → выберите "Пароли приложений" → создайте пароль для приложения (выберите "Другое" и назовите "Plaud").

**4. Скрипт запускается, но письма не приходят. Что делать?**

- Проверьте настройки SMTP (сервер, порт, логин, пароль).
- Убедитесь, что пароль приложения правильный.
- Проверьте папку "Спам" в почте.
- Посмотрите лог в `PlaudReports\plaud_log_*.txt`.

**5. Как удалить все отчёты вручную?**

```powershell
Remove-Item -Path "$env:USERPROFILE\Documents\PlaudReports\*.txt" -Force
```

**6. Можно ли изменить срок хранения файлов?**

Да, в скрипте найдите строку:

```powershell
$cutoffDate = (Get-Date).AddDays(-14)  # 14 дней
```

Измените число на нужное (например, `-30` для 30 дней).

**7. Почему в письмах кракозябры вместо текста?**

Убедитесь, что в скрипте установлена кодировка UTF-8:

```powershell
$mail.BodyEncoding = [System.Text.Encoding]::UTF8
$mail.SubjectEncoding = [System.Text.Encoding]::UTF8
```

Также при сохранении файла используется `UTF8Encoding $true` (с BOM).

**8. Можно ли запускать скрипт на нескольких компьютерах?**

Да, просто скопируйте папку со скриптами и настройте Plaud CLI (`plaud login`) и SMTP-параметры на каждом компьютере.

---

### 🔄 Дальнейшее развитие

| Идея | Описание | Приоритет |
|---|---|---|
| 📄 Конфигурационный файл | Вынести SMTP-настройки и получателей в JSON/XML | ⭐⭐⭐ |
| 📎 Форматы отчётов | Добавить PDF, DOCX, HTML, Markdown | ⭐⭐⭐ |
| 📱 Telegram / Slack | Отправка через ботов в мессенджеры | ⭐⭐ |
| 🌐 Веб-интерфейс | Локальный веб-сервер для просмотра отчётов | ⭐⭐ |
| 🧩 Несколько источников | Разные SMTP-аккаунты для разных получателей | ⭐⭐ |
| 🐳 Контейнеризация | Docker-образ для простого развёртывания | ⭐ |
| 📊 Статистика | Сбор метрик и формирование отчётов | ⭐⭐ |
| 🔄 Интеграция с CRM | Битрикс24, Salesforce, AmoCRM | ⭐ |
| 🔐 Шифрование пароля | Хранение пароля в защищённом виде | ⭐⭐⭐ |
| 📈 Графический интерфейс | WinForms или WPF для управления | ⭐ |

---

### 🤝 Вклад в проект

Если у вас есть идеи, предложения или вы нашли ошибку:

1. Создайте Issue с описанием проблемы.
2. Форкните репозиторий.
3. Внесите изменения и создайте Pull Request.

Все идеи и улучшения приветствуются!

---

### 📄 Лицензия

Проект распространяется под лицензией MIT.
Это означает, что вы можете свободно использовать, изменять и распространять код.

Подробнее: [LICENSE](LICENSE)

---

### 📬 Контакты

- **Автор:** [surikat858](https://github.com/surikat858)
- **Репозиторий:** [github.com/surikat858/plaud-reports](https://github.com/surikat858/plaud-reports)
- **По вопросам:** создавайте Issue в репозитории

#### ⭐ Поддержка проекта

Если проект оказался полезным:

- Поставьте ⭐ на GitHub
- Расскажите о нём коллегам
- Сделайте форк и добавьте свои улучшения

---

🚀 Enjoy automated reporting with Plaud Reports!

---

## English

[![GitHub release](https://img.shields.io/github/v/release/surikat858/plaud-reports)](https://github.com/surikat858/plaud-reports/releases)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6)](https://www.microsoft.com/windows)
[![Plaud](https://img.shields.io/badge/Plaud-CLI-4A90D9)](https://plaud.ai)

---

### 📌 About

**Plaud Reports** is a set of PowerShell scripts that retrieve transcripts, summaries and action items from [Plaud](https://plaud.ai) recordings and email them as reports.

It helps Windows users automate meeting follow-up and report delivery.

**Author** [surikat858](https://github.com/surikat858)

---

### 📖 Table of Contents

- [About](#-about)
- [Features](#-features)
- [How It Works](#-how-it-works)
- [Requirements](#-requirements)
- [Installation and Setup](#-installation-and-setup)
- [Usage](#-usage)
- [File and Folder Structure](#-file-and-folder-structure)
- [Testing](#-testing)
- [Building the EXE](#-building-the-exe)
- [FAQ](#-faq)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

### 🚀 Features

| Feature | Description |
|---------|----------|
| **Two script variants** | Interactive mode with console output and scheduled mode without pauses |
| **Multiple recipients** | Send reports to any number of email addresses |
| **Detailed logging** | Daily logs in the `PlaudReports` folder |
| **Automatic cleanup** | Removes logs and reports older than 14 days |
| **Cyrillic support** | Supports Russian text using UTF-8 with a BOM |
| **Duplicate prevention** | Sends each new recording only once |
| **Progress** | Shows progress in interactive mode |
| **SMTP authentication** | Uses app passwords |

---

### 🔧 How It Works

```mermaid
flowchart TD
    A[Start the script] --> R[Remove logs and reports older than 14 days]
    R --> B[plaud today]
    B --> C[Extract recording IDs]
    C --> D[Compare with plaud_sent.log]
    D --> E{Any new recordings?}
    E -->|No| F[Exit]
    E -->|Yes| G[Process each recording]
    G --> H[Retrieve transcript]
    G --> I[Retrieve summary]
    G --> J[Retrieve action items]
    H --> K[Build report]
    I --> K
    J --> K
    K --> L[Save report to a file]
    L --> M[Email the report as an attachment]
    M --> N[Record the ID in plaud_sent.log]
    N --> O{All recordings processed?}
    O -->|No| G
    O -->|Yes| F
```

---

### 📦 Requirements

| Component | Version or command |
|---|---|
| Operating system | Windows 10 or 11 |
| PowerShell | 5.1 or later |
| Node.js | 14.x or later |
| Plaud CLI | `npm install -g @plaud-ai/cli` |
| Plaud authentication | `plaud login` |
| SMTP account | Username and app password |

---

### ⚙️ Installation and Setup

#### 1️⃣ Clone the repository

```bash
git clone https://github.com/surikat858/plaud-reports.git
cd plaud-reports
```

You can also download the ZIP archive and extract it to any folder.

#### 2️⃣ Install the Plaud CLI

```powershell
# Install the Plaud CLI with npm
npm install -g @plaud-ai/cli

# Sign in to Plaud (opens your browser)
plaud login
```

#### 3️⃣ Configure the script

Open `send-plaud-report.ps1` or `send-plaud-report-scheduled.ps1` in a text editor.

Find the configuration block and replace the example values with your own.

```powershell
# ============================================================
# 🔐 CONFIGURATION (REPLACE WITH YOUR OWN VALUES)
# ============================================================
$smtpServer = "smtp.your-provider.com"          # SMTP server
$smtpPort = 587                                 # Port (587 or 465)
$username = "your-email@example.com"            # Username (full email address)
$password = "your-app-password"                 # App password
$from = "sender@example.com"                    # Sender address

# Enter one or more recipient email addresses.
$recipients = @(
    "recipient1@example.com",
    "recipient2@example.com"
)
```

> ⚠️ **Important** Use an app password to authenticate to your email provider.

#### 4️⃣ Enable script execution

Run the following command once in an elevated PowerShell window.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 5️⃣ Configure SMTP

Use the settings for your email provider.

| Provider | SMTP server | Port | SSL/TLS |
|---|---|---|---|
| Gmail | smtp.gmail.com | 587 | STARTTLS |
| Yandex | smtp.yandex.ru | 587 | STARTTLS |
| Mail.ru | smtp.mail.ru | 587 | STARTTLS |
| Outlook/Hotmail | smtp-mail.outlook.com | 587 | STARTTLS |
| Reg.ru Hosting | mail.hosting.reg.ru | 587 | STARTTLS |

For Gmail, see the [app password instructions](#-faq) below.

---

### 🚀 Usage

#### Run manually

```powershell
# Change to the folder containing the script.
cd C:\path\to\plaud-reports

# Run the interactive script.
.\send-plaud-report.ps1
```

Example console output, translated into English.

```text
==================================================
  📧 PLAUD REPORT
==================================================

New recordings found: 2

Processing [1/2]: a1b2c3d4...
  Retrieving transcript... ✅
  Retrieving summary... ✅
  Retrieving action items... ✅
  Saving report... ✅
  Sending email... ✅

Processing [2/2]: e5f6g7h8...
  Retrieving transcript... ✅
  Retrieving summary... ✅
  Retrieving action items... ✅
  Saving report... ✅
  Sending email... ✅

==================================================
  📊 SUMMARY
==================================================
✅ Processed: 2
✅ Errors: 0

📁 Log saved to: C:\Users\...\PlaudReports\plaud_log_2026-08-31.txt
==================================================
```

#### Run automatically with Task Scheduler

1. Open Task Scheduler.
   - Press `Win + R`.
   - Enter `taskschd.msc`.
   - Press Enter.

2. Select **Create Task** on the right.


3. On the **General** tab, configure the task.
   - **Name** — `Plaud Reports`
   - Enable **Run whether user is logged on or not**.
   - Enable **Hidden**.
   - Select **Windows 10** under **Configure for**.

4. On the **Triggers** tab, select **New**.
   - Set **Begin the task** to **On a schedule**.
   - Set **Repeat task every** to **1 hour**.
   - Set **for a duration of** to **Indefinitely**.

5. On the **Actions** tab, select **New**.
   - Set **Action** to **Start a program**.
   - Set **Program/script** to `powershell.exe`.
   - Enter the following arguments under **Add arguments**.

     ```text
     -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\plaud-reports\send-plaud-report-scheduled.ps1"
     ```

6. Select **OK** and enter your Windows account password.

---

### 📁 File and Folder Structure

```text
plaud-reports/
├── README.md                                    # Documentation
├── LICENSE                                      # MIT license
├── send-plaud-report.ps1                        # Interactive script
├── send-plaud-report-scheduled.ps1              # Task Scheduler script
├── .gitignore                                  # Ignored files
└── docs/
    └── images/                                 # Optional screenshots

%USERPROFILE%\Documents\PlaudReports\
├── plaud_log_2026-08-31.txt                     # Daily log
├── plaud_sent.log                               # IDs of emailed recordings
├── 20260831_120000_a1b2c3d4e5f6.txt             # First report
└── 20260831_130000_e5f6g7h8i9j0.txt             # Second report
```

---

### 🧪 Testing

Verify that the script processes and delivers a new recording.

1. Create a test recording in the Plaud app on your phone or computer.
2. Allow one to two minutes for Plaud to process it.
3. Run the script manually.

   ```powershell
   .\send-plaud-report.ps1
   ```

4. Verify the results.
   - ✅ A new report file appears in `PlaudReports`.
   - ✅ All specified recipients receive the email.
   - ✅ The recording ID appears in `plaud_sent.log`.

5. Run the script again. It should report that all recordings have already been sent.

---

### 📦 Building the EXE

#### Method 1 — PS2EXE (recommended)

Install the module.

```powershell
Install-Module -Name PS2EXE -Scope CurrentUser
```

Build the executables.

```powershell
# Interactive version with a console window
ps2exe -inputFile .\send-plaud-report.ps1 -outputFile .\PlaudReports.exe -title "Plaud Reports" -version "1.0.0"

# Scheduled version without a console window
ps2exe -inputFile .\send-plaud-report-scheduled.ps1 -outputFile .\PlaudReportsScheduled.exe -title "Plaud Reports (Scheduled)" -version "1.0.0" -noconsole
```

The executables appear in the current folder.

#### Method 2 — PowerShell Pro Tools (paid)

1. Open PowerShell Pro Tools.
2. Select **Package** → **Windows Application**.
3. Specify the script path and configure the packaging options.
4. Select **Build**.

> The executable resolves paths based on `$env:USERPROFILE` at runtime.

---

### ❓ FAQ

**1. What should I do if the script cannot find `plaud`?**

```powershell
# Check whether the CLI is installed.
plaud --version

# Reinstall it if needed.
npm uninstall -g @plaud-ai/cli
npm install -g @plaud-ai/cli
```

**2. How do I update the Plaud CLI?**

```powershell
npm update -g @plaud-ai/cli
```

**3. Where do I get a Gmail app password?**

In your Google Account security settings, enable 2-Step Verification. Open **App passwords** and create a password for Plaud.

**4. The script runs but the emails never arrive. What should I check?**

- Check the SMTP server, port, username and password.
- Confirm that the app password is correct.
- Check your spam folder.
- Review the log in `PlaudReports\plaud_log_*.txt`.

**5. How do I delete all reports manually?**

```powershell
Remove-Item -Path "$env:USERPROFILE\Documents\PlaudReports\*.txt" -Force
```

**6. Can I change the retention period?**

Find the following line in the script.

```powershell
$cutoffDate = (Get-Date).AddDays(-14)  # 14 days
```

Change the number to the desired retention period, such as `-30` for 30 days.

**7. Why is the text garbled in emails?**

Verify that the script uses UTF-8 for the message body and subject.

```powershell
$mail.BodyEncoding = [System.Text.Encoding]::UTF8
$mail.SubjectEncoding = [System.Text.Encoding]::UTF8
```

The script also uses `UTF8Encoding $true` to save reports with a BOM.

**8. Can I run the script on multiple computers?**

Yes. Copy the script folder, run `plaud login` and configure SMTP on each computer.

---

### 🔄 Roadmap

| Idea | Description | Priority |
|---|---|---|
| 📄 Configuration file | Move SMTP settings and recipients to JSON or XML | ⭐⭐⭐ |
| 📎 Report formats | Add PDF, DOCX, HTML and Markdown | ⭐⭐⭐ |
| 📱 Telegram and Slack | Deliver reports through messaging bots | ⭐⭐ |
| 🌐 Web interface | View reports through a local web server | ⭐⭐ |
| 🧩 Multiple sources | Use different SMTP accounts for different recipients | ⭐⭐ |
| 🐳 Containerization | Package the scripts in a Docker image | ⭐ |
| 📊 Statistics | Collect metrics and generate reports | ⭐⭐ |
| 🔄 CRM integration | Integrate with Bitrix24, Salesforce and AmoCRM | ⭐ |
| 🔐 Password encryption | Store passwords securely | ⭐⭐⭐ |
| 📈 Graphical interface | Manage reports through WinForms or WPF | ⭐ |

---

### 🤝 Contributing

To report a bug or suggest an improvement, follow these steps.

1. Open an issue describing the problem or idea.
2. Fork the repository.
3. Make your changes and open a pull request.

Ideas and improvements are welcome!

---

### 📄 License

This project is available under the MIT License.
You may use, modify and distribute the code.

See [LICENSE](LICENSE) for details.

---

### 📬 Contact

- **Author** [surikat858](https://github.com/surikat858)
- **Repository** [github.com/surikat858/plaud-reports](https://github.com/surikat858/plaud-reports)
- **Questions** Open an issue in the repository.

#### ⭐ Supporting the Project

If you find the project useful, consider supporting it.

- Star it on GitHub.
- Share it with colleagues.
- Fork it and contribute improvements.

---

🚀 Enjoy automated reporting with Plaud Reports!
