# Claude Code hook: shows a native Windows toast.
# Receives hook JSON on stdin: { "message": "...", "title": "..." , ... }
# DefaultTitle/DefaultMessage let one script serve multiple hook events
# (stdin title/message still win when the hook payload provides them).
param(
    [string]$DefaultTitle = "Claude Code",
    [string]$DefaultMessage = "Claude needs your input"
)

$raw = [Console]::In.ReadToEnd()
$data = $null
try { $data = $raw | ConvertFrom-Json } catch [System.ArgumentException] { $data = $null }

$title = $DefaultTitle
$message = $DefaultMessage
if ($null -ne $data) {
    if ($data.PSObject.Properties["title"] -and $data.title) { $title = [string]$data.title }
    if ($data.PSObject.Properties["message"] -and $data.message) { $message = [string]$data.message }
}

# XML-escape for the toast template
$esc = { param($s) $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' }
$titleEsc = & $esc $title
$messageEsc = & $esc $message

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$template = "<toast><visual><binding template=""ToastGeneric""><text>$titleEsc</text><text>$messageEsc</text></binding></visual><audio src=""ms-winsoundevent:Notification.Default""/></toast>"

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = New-Object Windows.UI.Notifications.ToastNotification($xml)

# Use the Windows PowerShell AppUserModelID so the toast is attributed to an installed app
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
