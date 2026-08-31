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
# 1. НАСТРОЙКА ЛОГИРОВАНИЯ (без консольного вывода)
# ============================================================
$outputFolder = "$env:USERPROFILE\Documents\PlaudReports"
$logDate = Get-Date -Format 'yyyy-MM-dd'
$logFile = Join-Path $outputFolder "plaud_log_$logDate.txt"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    # Только запись в файл (консоль не используется)
    try { Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

# ============================================================
# 2. РОТАЦИЯ СТАРЫХ ФАЙЛОВ (14 дней)
# ============================================================
$cutoffDate = (Get-Date).AddDays(-14)
$oldLogs = Get-ChildItem -Path $outputFolder -Filter "plaud_log_*.txt" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoffDate }
foreach ($log in $oldLogs) { Remove-Item -Path $log.FullName -Force -ErrorAction SilentlyContinue }

$oldFiles = Get-ChildItem -Path $outputFolder -File -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -lt $cutoffDate -and $_.Name -notlike "plaud_log_*" -and $_.Name -ne "plaud_sent.log"
}
foreach ($file in $oldFiles) { Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue }

Write-Log "==================================================" "INFO"
Write-Log "ЗАПУСК СКРИПТА (планировщик)" "INFO"
Write-Log "==================================================" "INFO"

# ============================================================
# 3. ФУНКЦИЯ ПОЛУЧЕНИЯ ДАННЫХ
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
    exit
}

$regex = "[a-f0-9]{32}"
$idMatches = [regex]::Matches($recordings, $regex)
if ($idMatches.Count -eq 0) {
    Write-Log "Нет новых записей" "WARNING"
    Write-Log "==================================================" "INFO"
    exit
}

if (-not (Test-Path $sentLogFile)) {
    New-Item -ItemType File -Path $sentLogFile -Force | Out-Null
    Write-Log "Создан файл лога отправленных ID" "INFO"
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
    exit
}

Write-Log "Найдено новых записей: $($newIds.Count)" "INFO"

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
        $smtp.EnableSsl = $false
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

Write-Log "==================================================" "INFO"
Write-Log "ГОТОВО!" "SUCCESS"
Write-Log "Обработано: $processedCount, Ошибок: $errorCount" "INFO"
Write-Log "==================================================" "INFO"