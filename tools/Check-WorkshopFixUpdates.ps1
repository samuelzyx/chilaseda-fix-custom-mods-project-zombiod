param(
    [string]$StatePath = 'Workshop_Fix_Tracking_State.json',
    [string]$TrackingPath = 'Workshop_Fix_Tracking.md',
    [string]$RunLogPath = 'Workshop_Fix_Checker.log',
    [switch]$Notify
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $workspaceRoot
$runLog = Join-Path $workspaceRoot $RunLogPath

function Write-CheckerLog([string]$Message) {
    $entry = '{0} {1}{2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'), $Message, [Environment]::NewLine
    [IO.File]::AppendAllText($runLog, $entry, (New-Object Text.UTF8Encoding($true)))
}

$items = @(
    @{ Id='3767335348'; ModId='XGlueTapeCrafting'; Fix='ChilaSeda_Fix_XGlueTapeCrafting_Translation_B42_3767335348'; NoModVersion=$true },
    @{ Id='3300688173'; ModId='CheckAround'; Fix='ChilaSeda_Fix_Check_Around_VoiceLineLists_B42_3300688173' },
    @{ Id='2335368829'; ModId='Authentic Z - Current'; Fix='ChilaSeda_Fix_Authentic_Z_InstantCraft_B42_2335368829'; NoModVersion=$true },
    @{ Id='3818605688'; ModId='DGVFlags'; Fix='ChilaSeda_Fix_Any_Wall_Flags_3D_Weight_B42_3818605688' },
    @{ Id='3761218629'; ModId='DismantleAllAtOnce'; Fix='ChilaSeda_Fix_Dismantle_All_at_Once_MenuOrder_B42_3761218629' },
    @{ Id='3428272880'; ModId='DoggyLibrary'; Fix='ChilaSeda_Fix_Doggy_Library_RayBeam_B42_3428272880' },
    @{ Id='3786994541'; ModId='HunterExpansion'; Fix='ChilaSeda_Fix_Hunter_Expansion_Filth_B42_3786994541' },
    @{ Id='3818729237'; ModId='NeatUI_Core'; Fix='ChilaSeda_Fix_NeatUI_Core_Format_B42_3818729237' },
    @{ Id='3818605173'; ModId='DGVPosters'; Fix='ChilaSeda_Fix_Any_Wall_Posters_3D_Weight_B42_3818605173' },
    @{ Id='3656190498'; ModId='ReactiveSE'; Fix='ChilaSeda_Fix_Reactive_Sound_Events_Viewpoint_B42_3656190498' },
    @{ Id='3386906181'; ModId='SandboxSettings'; Fix='ChilaSeda_Fix_Sandbox_Options_ContextMenu_B42_3386906181' },
    @{ Id='3781571720'; ModId='UndeadWildlife'; Fix='ChilaSeda_AnimalBalance_B42' },
    @{ Id='3768669395'; ModId='TrueWeight'; Fix='ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395' },
    @{ Id='3812616893'; ModId='ViewpointUI'; Fix='ChilaSeda_Fix_Viewpoint_Interface_ActionProgress_B42_3812616893' },
    @{ Id='3814994364'; ModId='ViewpointForaging'; Fix='ChilaSeda_Fix_ViewpointForaging_B42_3814994364' },
    @{ Id='3546314080'; ModId='Waterpipes'; Fix='ChilaSeda_Fix_Water_Pipes_ModData_B42_3546314080' },
    @{ Id='3779759338'; ModId='Wilderness QoL'; Fix='ChilaSeda_Fix_Wilderness_QoL_Identification_B42_3779759338' }
)

function Get-ModInfoValue([string]$Path, [string]$Key) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $line = Get-Content -LiteralPath $Path | Where-Object { $_ -match "^$([regex]::Escape($Key))=" } | Select-Object -First 1
    if ($line) { return ($line -replace "^$([regex]::Escape($Key))=", '').Trim() }
    return $null
}

function Get-InstalledWorkshopVersion([string]$WorkshopId, [string]$ModId) {
    $roots = @()
    # This machine's Steam library is on J:, which may not be present in the
    # registry roots available to scheduled or sandboxed checker runs.
    if (Test-Path -LiteralPath 'J:\SteamLibrary') { $roots += 'J:\SteamLibrary' }
    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $entry = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($entry) {
            foreach ($property in @('SteamPath', 'InstallPath')) {
                if ($entry.$property) { $roots += $entry.$property }
            }
        }
    }
    $libraries = @()
    foreach ($root in ($roots | Select-Object -Unique)) {
        $libraries += $root
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s*"([^"]+)"')) {
                $libraries += $match.Groups[1].Value.Replace('\\', '\')
            }
        }
    }
    foreach ($library in ($libraries | Select-Object -Unique)) {
        $content = Join-Path $library "steamapps\workshop\content\108600\$WorkshopId"
        if (-not (Test-Path -LiteralPath $content)) { continue }
        $matches = @(Get-ChildItem -LiteralPath $content -Filter 'mod.info' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { (Get-ModInfoValue $_.FullName 'id') -eq $ModId })
        $info = $matches | Sort-Object -Property @{ Expression = {
            $build = [regex]::Match($_.DirectoryName, '\\(42(?:\.\d+)+)(?:\\|$)')
            if ($build.Success) { [version]::Parse($build.Groups[1].Value) } else { [version]'42.0' }
        }; Descending = $true } | Select-Object -First 1
        if ($info) {
            $version = Get-ModInfoValue $info.FullName 'modversion'
            if (-not $version) { $version = Get-ModInfoValue $info.FullName 'version' }
            return $version
        }
    }
    return $null
}

$stateFile = Join-Path (Get-Location) $StatePath
$trackingFile = Join-Path (Get-Location) $TrackingPath
$oldState = @{}
if (Test-Path -LiteralPath $stateFile) {
    $parsed = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    foreach ($property in $parsed.items.PSObject.Properties) { $oldState[$property.Name] = $property.Value }
}

$form = @{ itemcount = $items.Count }
for ($i = 0; $i -lt $items.Count; $i++) { $form["publishedfileids[$i]"] = $items[$i].Id }
$started = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
Write-CheckerLog "Inicio consulta Steam ($($items.Count) Workshop IDs)."
try {
    $response = Invoke-RestMethod -Method Post -Uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Body $form
} catch {
    Write-CheckerLog "ERROR al consultar Steam: $($_.Exception.Message)"
    throw
}
$now = (Get-Date).ToUniversalTime().ToString('o')
$newState = @{}
$events = @()
$tableRows = @()

foreach ($item in $items) {
    $detail = $response.response.publishedfiledetails | Where-Object { [string]$_.publishedfileid -eq $item.Id } | Select-Object -First 1
    if (-not $detail -or $detail.result -ne 1) {
        Write-Warning "Steam no devolvió datos para $($item.Id) ($($item.ModId)); se conserva la última observación."
        Write-CheckerLog "WARN Steam sin datos para $($item.Id) ($($item.ModId)); se conserva la última observación."
        $previous = $oldState[$item.Id]
        if ($previous) {
            $newState[$item.Id] = $previous
            $fixDir = Join-Path (Get-Location) $item.Fix
            $fixInfo = Get-ChildItem -LiteralPath $fixDir -Filter 'mod.info' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            $fixVersion = if ($fixInfo) { Get-ModInfoValue $fixInfo.FullName 'modversion' } else { 'sin etiqueta' }
            $linkedTitle = "[$($previous.title)](https://steamcommunity.com/sharedfiles/filedetails/?id=$($item.Id))"
            $tableRows += ('| {0} | {1} | {2} | {3} | {4} | Sin registro histórico | {5} | {6} | Consulta fallida; último dato |' -f $linkedTitle, $item.Id, $item.ModId, $item.Fix, $fixVersion, $previous.updated_utc, $(if($previous.installed_version){$previous.installed_version}else{'no disponible'}))
        } else {
            $tableRows += ('| Sin respuesta de Steam | {0} | {1} | {2} | sin etiqueta | Sin registro histórico | Sin consultar | Sin consultar | Consulta fallida |' -f $item.Id, $item.ModId, $item.Fix)
        }
        continue
    }
    $updatedUtc = [DateTimeOffset]::FromUnixTimeSeconds([long]$detail.time_updated).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss') + ' UTC'
    $installedVersion = if ($item.NoModVersion) { $null } else { Get-InstalledWorkshopVersion $item.Id $item.ModId }
    $previous = $oldState[$item.Id]
    if (-not $previous) {
        Write-Output "LÍNEA BASE: $($detail.title) [$($item.Id)] actualizado $updatedUtc; versión instalada: $(if ($installedVersion) {$installedVersion} else {'sin modversion local'})"
    } else {
        $dateChanged = [long]$previous.time_updated -ne [long]$detail.time_updated
        $versionChanged = $previous.installed_version -and $installedVersion -and ($previous.installed_version -ne $installedVersion)
        if ($dateChanged -or $versionChanged) {
            $oldDate = $previous.updated_utc
            $oldVersion = if ($previous.installed_version) { $previous.installed_version } else { 'sin dato' }
            $newVersion = if ($installedVersion) { $installedVersion } else { 'sin dato' }
            $events += [pscustomobject]@{ checked=$now; title=$detail.title; id=$item.Id; old_date=$oldDate; new_date=$updatedUtc; old_version=$oldVersion; new_version=$newVersion }
            Write-Warning "ACTUALIZACIÓN: $($detail.title) [$($item.Id)]: $oldDate -> $updatedUtc; versión instalada $oldVersion -> $newVersion. Revisar el fix $($item.Fix)."
            Write-CheckerLog "ACTUALIZACION: $($detail.title) [$($item.Id)]; time_updated $oldDate -> $updatedUtc; modversion $oldVersion -> $newVersion; fix $($item.Fix)."
        }
    }
    $newState[$item.Id] = [pscustomobject]@{ title=$detail.title; time_updated=[long]$detail.time_updated; updated_utc=$updatedUtc; installed_version=$installedVersion; checked_utc=$now }
    $fixDir = Join-Path (Get-Location) $item.Fix
    $fixInfo = Get-ChildItem -LiteralPath $fixDir -Filter 'mod.info' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $fixVersion = if ($fixInfo) { Get-ModInfoValue $fixInfo.FullName 'modversion' } else { $null }
    $sourceVersionLabel = if ($item.NoModVersion) { 'mod.info sin modversion' } elseif ($installedVersion) { $installedVersion } else { 'no disponible en disco' }
    $fixVersionLabel = if ($fixVersion) { $fixVersion } else { 'sin etiqueta' }
    $stateLabel = if ($previous) { 'En seguimiento' } else { 'Línea base' }
    $linkedTitle = "[$($detail.title)](https://steamcommunity.com/sharedfiles/filedetails/?id=$($item.Id))"
    $tableRows += ('| {0} | {1} | {2} | {3} | {4} | Sin registro histórico | {5} | {6} | {7} |' -f $linkedTitle, $item.Id, $item.ModId, $item.Fix, $fixVersionLabel, $updatedUtc, $sourceVersionLabel, $stateLabel)
}
$tableRows += '| Project Zomboid (juego base) | - | - | ChilaSeda_Fix_Project_Zomboid_AutoTools_B42_Vanilla | 1.0.1 | No aplica | No aplica | No aplica | Sin Workshop original |'

$state = [pscustomobject]@{ checked_utc=$now; items=$newState }
$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $stateFile -Encoding utf8
$document = Get-Content -LiteralPath $trackingFile -Raw
$lineBreak = [Environment]::NewLine
$tableText = [string]::Join($lineBreak, [string[]]$tableRows)
$currentBlock = '<!-- CURRENT_STATE_START -->' + $lineBreak + '| Mod original de Workshop | Workshop ID | Mod ID fuente | Fix local | Version del fix | Version fuente aplicada | Workshop actualizado | Version fuente instalada | Estado |' + $lineBreak + '|---|---:|---|---|---:|---|---|---|---|' + $lineBreak + $tableText + $lineBreak + '<!-- CURRENT_STATE_END -->'
$document = [regex]::Replace($document, '(?s)<!-- CURRENT_STATE_START -->.*?<!-- CURRENT_STATE_END -->', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $currentBlock })
if ($events.Count -gt 0) {
    $eventRows = foreach ($event in $events) { '| {0} | {1} | {2} | {3} -> {4} | {5} -> {6} | Pendiente de revision |' -f $event.checked, $event.title, $event.id, $event.old_date, $event.new_date, $event.old_version, $event.new_version }
    $marker = '<!-- CHANGE_LOG_END -->'
    $lineBreak = [Environment]::NewLine
    $eventText = [string]::Join($lineBreak, [string[]]$eventRows)
    $document = $document.Replace($marker, ($eventText + $lineBreak + $marker))
}
Set-Content -LiteralPath $trackingFile -Value $document -Encoding utf8
if ($oldState.Count -eq 0) {
    Write-Output 'Primera consulta completada: se estableció la línea base. No se marcaron cambios históricos.'
    Write-CheckerLog 'Primera línea base establecida; no se marcaron cambios históricos.'
} elseif ($events.Count -eq 0) {
    Write-Output 'Sin cambios nuevos desde la consulta anterior.'
    Write-CheckerLog 'Sin cambios desde la consulta anterior.'
}
if ($Notify -and $events.Count -gt 0) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $names = @($events | Select-Object -First 3 | ForEach-Object { $_.title }) -join ', '
        if ($events.Count -gt 3) { $names += " y $($events.Count - 3) más" }
        $balloon = New-Object System.Windows.Forms.NotifyIcon
        $balloon.Icon = [System.Drawing.SystemIcons]::Warning
        $balloon.BalloonTipTitle = 'Actualización de mods de Project Zomboid'
        $balloon.BalloonTipText = "$names. Revisa Workshop_Fix_Tracking.md antes de la siguiente partida."
        $balloon.Visible = $true
        $balloon.ShowBalloonTip(15000)
        Start-Sleep -Seconds 15
        $balloon.Dispose()
        Write-CheckerLog "Notificación visible mostrada para $($events.Count) cambio(s)."
    } catch {
        Write-CheckerLog "ERROR al mostrar la notificación: $($_.Exception.Message)"
        Write-Warning 'No se pudo mostrar la notificación visible; el cambio sí quedó guardado en Workshop_Fix_Tracking.md.'
    }
}
