# ============================================================
# 🔐 КОНФИГУРАЦИЯ (ЗАМЕНИТЕ НА СВОИ ДАННЫЕ)
# ============================================================
$smtpServer = "smtp.your-provider.com"
$smtpPort = 587
$username = "your-email@example.com"
$password = "your-password"
$from = "sender@example.com"
$recipients = @("recipient1@example.com", "recipient2@example.com")

# ============================================================
# 1. НАСТРОЙКА ЛОГИРОВАНИЯ
# ============================================================
$outputFolder = "$env:USERPROFILE\Documents\PlaudReports"
$logDate = Get-Date -Format 'yyyy-MM-dd'
$logFile = Join-Path $outputFolder "plaud_log_$logDate.txt"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Вывод в консоль (цветной)
    if ($Level -eq "ERROR") {
        Write-Host $logEntry -ForegroundColor Red
    } elseif ($Level -eq "WARNING") {
        Write-Host $logEntry -ForegroundColor Yellow
    } elseif ($Level -eq "SUCCESS") {
        Write-Host $logEntry -ForegroundColor Green
    } else {
        Write-Host $logEntry -ForegroundColor Gray
    }
    
    # Запись в файл
    try { Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    Write-Log "Создана папка: $outputFolder" "INFO"
}

# ============================================================
# 2. РОТАЦИЯ СТАРЫХ ФАЙЛОВ (14 дней)
# ============================================================
$cutoffDate = (Get-Date).AddDays(-14)
Write-Log "Проверка старых файлов..." "INFO"

$oldLogs = Get-ChildItem -Path $outputFolder -Filter "plaud_log_*.txt" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoffDate }
foreach ($log in $oldLogs) {
    Remove-Item -Path $log.FullName -Force -ErrorAction SilentlyContinue
    Write-Log "  Удалён старый лог: $($log.Name)" "INFO"
}

$oldFiles = Get-ChildItem -Path $outputFolder -File -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -lt $cutoffDate -and $_.Name -notlike "plaud_log_*" -and $_.Name -ne "plaud_sent.log"
}
foreach ($file in $oldFiles) {
    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
    Write-Log "  Удалён старый отчёт: $($file.Name)" "INFO"
}

Write-Log "==================================================" "INFO"
Write-Log "ЗАПУСК СКРИПТА" "INFO"
Write-Log "==================================================" "INFO"

# ============================================================
# 3. ФУНКЦИЯ ПОЛУЧЕНИЯ ДАННЫХ ИЗ PLAUD CLI
# ============================================================
function Get-PlaudData {
    param($Command, $Arguments)
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $cmd = "plaud $Command $Arguments > `"$tempFile`" 2>&1"
        cmd /c "chcp 65001 > nul & $cmd"
        if (Test-Path $tempFile) {
            $content = Get-Content -Path $tempFile -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
            return $content
        }
        return ""
    } finally {
        if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue }
    }
}

# ============================================================
# 4. ОСНОВНАЯ ЛОГИКА
# ============================================================
$sentLogFile = "$env:USERPROFILE\Documents\plaud_sent.log"
$ErrorActionPreference = "SilentlyContinue"

Write-Log "Получение списка записей за сегодня..." "INFO"
$recordings = Get-PlaudData -Command "today" -Arguments ""

if ([string]::IsNullOrWhiteSpace($recordings)) {
    Write-Log "Нет новых записей" "WARNING"
    Write-Log "==================================================" "INFO"
    Write-Host "`nНажмите Enter для выхода..."
    Read-Host
    exit
}

$regex = "[a-f0-9]{32}"
$idMatches = [regex]::Matches($recordings, $regex)
if ($idMatches.Count -eq 0) {
    Write-Log "Нет новых записей" "WARNING"
    Write-Log "==================================================" "INFO"
    Write-Host "`nНажмите Enter для выхода..."
    Read-Host
    exit
}

if (-not (Test-Path $sentLogFile)) {
    New-Item -ItemType File -Path $sentLogFile -Force | Out-Null
    Write-Log "Создан файл лога отправленных ID: $sentLogFile" "INFO"
}

$sentIds = Get-Content $sentLogFile
$newIds = @()
foreach ($match in $idMatches) {
    $id = $match.Value
    if ($sentIds -notcontains $id) { $newIds += $id }
}

if ($newIds.Count -eq 0) {
    Write-Log "Все записи уже обработаны" "INFO"
    Write-Log "==================================================" "INFO"
    Write-Host "`nНажмите Enter для выхода..."
    Read-Host
    exit
}

Write-Log "Найдено новых записей: $($newIds.Count)" "SUCCESS"

$processedCount = 0
$errorCount = 0
$total = $newIds.Count
$current = 0

foreach ($recordingId in $newIds) {
    $current++
    Write-Log "Обработка [$current/$total]: $recordingId" "INFO"

    Write-Log "  Получение транскрипции..." "INFO"
    $transcript = Get-PlaudData -Command "transcript" -Arguments $recordingId
    if ([string]::IsNullOrWhiteSpace($transcript)) {
        $transcript = "Транскрипция не найдена"
        Write-Log "  Транскрипция не найдена" "WARNING"
    }

    Write-Log "  Получение саммари..." "INFO"
    $summary = Get-PlaudData -Command "summary" -Arguments $recordingId
    if ([string]::IsNullOrWhiteSpace($summary) -or $summary -match "not available") {
        $summary = "Саммари не найдено"
        Write-Log "  Саммари не найдено" "WARNING"
    }

    Write-Log "  Получение задач..." "INFO"
    $tasks = Get-PlaudData -Command "tasks" -Arguments $recordingId
    if ([string]::IsNullOrWhiteSpace($tasks) -or $tasks -match "error") {
        $tasks = "Задачи не найдены"
        Write-Log "  Задачи не найдены" "WARNING"
    }

    $currentDate = Get-Date -Format 'yyyyMMdd_HHmmss'
    $fileName = "$currentDate`_$recordingId.txt"
    $filePath = Join-Path $outputFolder $fileName

    $content = @"
============================================================
САММАРИ, ТРАНСКРИПЦИЯ И ЗАДАЧИ
Дата: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
ID записи: $recordingId
============================================================

САММАРИ:
------------------------------------------------------------
$summary

ТРАНСКРИПЦИЯ:
------------------------------------------------------------
$transcript

ЗАДАЧИ:
------------------------------------------------------------
$tasks

============================================================
Автоматически отправлено из Plaud
============================================================
"@

    Write-Log "  Сохранение файла..." "INFO"
    try {
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)
        Write-Log "  ✅ Файл сохранён: $fileName" "SUCCESS"
    } catch {
        Write-Log "  ❌ Ошибка сохранения файла: $($_.Exception.Message)" "ERROR"
        $errorCount++
        continue
    }

    Write-Log "  Отправка письма..." "INFO"
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
        # STARTTLS: нужно для порта 587 у Gmail/Yandex/Mail.ru/Outlook
        # (см. таблицу SMTP в README). Если ваш релей не требует SSL/TLS - поставьте $false.
        $smtp.EnableSsl = $true
        $smtp.DeliveryMethod = [System.Net.Mail.SmtpDeliveryMethod]::Network
        $smtp.UseDefaultCredentials = $false
        $smtp.Credentials = New-Object System.Net.NetworkCredential($username, $password)
        $smtp.Timeout = 60000

        $mail = New-Object System.Net.Mail.MailMessage
        $mail.From = New-Object System.Net.Mail.MailAddress($from)
        foreach ($recipient in $recipients) {
            $mail.To.Add($recipient)
            Write-Log "    Получатель: $recipient" "INFO"
        }
        $mail.Subject = "Отчёт Plaud: $recordingId"
        $mail.SubjectEncoding = [System.Text.Encoding]::UTF8

        $bodyText = @"
Отчёт Plaud во вложении.

Дата: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
ID записи: $recordingId

Содержит:
- Саммари
- Транскрипцию
- Список задач

---
Автоматически отправлено из Plaud
"@
        $mail.Body = $bodyText
        $mail.BodyEncoding = [System.Text.Encoding]::UTF8
        $mail.IsBodyHtml = $false

        $attachment = New-Object System.Net.Mail.Attachment($filePath)
        $mail.Attachments.Add($attachment)
        $smtp.Send($mail)
        Write-Log "  ✅ Письмо отправлено на все адреса" "SUCCESS"
        $attachment.Dispose()
        Add-Content -Path $sentLogFile -Value $recordingId -Encoding UTF8
        $processedCount++
    } catch {
        Write-Log "  ❌ Ошибка отправки: $($_.Exception.Message)" "ERROR"
        if ($_.Exception.InnerException) {
            Write-Log "  Причина: $($_.Exception.InnerException.Message)" "ERROR"
        }
        $errorCount++
    }
}

# ============================================================
# 5. ИТОГИ
# ============================================================
Write-Log "==================================================" "INFO"
Write-Log "ГОТОВО!" "SUCCESS"
Write-Log "Обработано: $processedCount, Ошибок: $errorCount" "INFO"
Write-Log "==================================================" "INFO"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  📊 ИТОГИ" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "✅ Обработано: $processedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "❌ Ошибок: $errorCount" -ForegroundColor Red
} else {
    Write-Host "✅ Ошибок: $errorCount" -ForegroundColor Green
}
Write-Host ""
Write-Host "📁 Лог сохранён в: $logFile" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`nНажмите Enter для выхода..."
Read-Host