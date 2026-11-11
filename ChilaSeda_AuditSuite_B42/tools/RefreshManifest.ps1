param(
    [string]$SaveModsPath,
    [string]$WorkshopRoot
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $SaveModsPath) {
    $SaveModsPath = Join-Path $workspaceRoot 'Saves\Sandbox\Jill_Valantine_1_mes_2K_Zombies_4_Vida_42_KM_25_10_2026_7PM\mods.txt'
}
if (-not [IO.Path]::IsPathRooted($SaveModsPath)) { $SaveModsPath = Join-Path $workspaceRoot $SaveModsPath }
if (-not $WorkshopRoot) { $WorkshopRoot = 'J:\SteamLibrary\steamapps\workshop\content\108600' }
$localModsRoot = Join-Path $workspaceRoot 'mods'
$manifestPath = Join-Path $PSScriptRoot '..\42\media\lua\shared\ChilaSeda_ModMemoryAuditManifest_B42.lua'
$manifestPath = [IO.Path]::GetFullPath($manifestPath)

if (-not (Test-Path -LiteralPath $SaveModsPath)) { throw "Sandbox mods.txt not found: $SaveModsPath" }
if (-not (Test-Path -LiteralPath $WorkshopRoot)) { throw "Workshop content folder not found: $WorkshopRoot" }

function Quote-Lua([string]$value) {
    if ($null -eq $value) { return '""' }
    $escaped = $value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
    return '"' + $escaped + '"'
}

function Get-PngRgbaEstimate([string]$path) {
    $stream = $null
    try {
        $stream = [IO.File]::OpenRead($path)
        if ($stream.Length -lt 24) { return [long]0 }
        $stream.Position = 16
        $bytes = New-Object byte[] 8
        if ($stream.Read($bytes, 0, 8) -ne 8) { return [long]0 }
        $width = ([long]$bytes[0] * 16777216) + ([long]$bytes[1] * 65536) + ([long]$bytes[2] * 256) + $bytes[3]
        $height = ([long]$bytes[4] * 16777216) + ([long]$bytes[5] * 65536) + ([long]$bytes[6] * 256) + $bytes[7]
        if ($width -le 0 -or $height -le 0) { return [long]0 }
        return [long]($width * $height * 4)
    } catch { return [long]0 }
    finally { if ($stream) { $stream.Dispose() } }
}

$activeIds = @(
    Select-String -LiteralPath $SaveModsPath -Pattern '^\s*mod\s*=\s*([^,]+),\s*$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } |
        Select-Object -Unique
)
if ($activeIds.Count -eq 0) { throw 'No mod IDs found in the selected Sandbox mods.txt.' }
$activeSet = [Collections.Generic.HashSet[string]]::new([string[]]$activeIds, [StringComparer]::OrdinalIgnoreCase)
$idPattern = '^id\s*=\s*(' + (($activeIds | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\s*$'

$infoPaths = @(& rg -l -i --hidden -g 'mod.info' $idPattern $WorkshopRoot $localModsRoot 2>$null)
if ($LASTEXITCODE -gt 1) { throw "Could not search mod.info files (rg exit $LASTEXITCODE)." }
$locations = @{}
foreach ($infoPath in $infoPaths) {
    if (-not (Test-Path -LiteralPath $infoPath)) { continue }
    $infoText = [IO.File]::ReadAllText($infoPath)
    $idMatch = [regex]::Match($infoText, '(?im)^\s*id\s*=\s*(.*?)\s*$')
    if (-not $idMatch.Success) { continue }
    $id = $idMatch.Groups[1].Value.Trim()
    if (-not $activeSet.Contains($id)) { continue }

    $infoParent = Split-Path -Parent $infoPath
    $leaf = Split-Path -Leaf $infoParent
    $versionScore = 0
    $versionDir = ''
    if ($leaf -match '^42(?:\.(\d+))?$') {
        $versionScore = 100 + [int]($Matches[1] -as [string] -as [int])
        if ($leaf -eq '42') { $versionScore = 100 }
        $versionDir = $infoParent
        $modRoot = Split-Path -Parent $infoParent
    } elseif ($leaf -eq 'common') {
        $versionScore = -10
        $modRoot = Split-Path -Parent $infoParent
    } else {
        $modRoot = $infoParent
    }

    if (-not $locations.ContainsKey($id) -or $versionScore -gt $locations[$id].versionScore) {
        $locations[$id] = [pscustomobject]@{ id=$id; modRoot=$modRoot; versionDir=$versionDir; versionScore=$versionScore }
    }
}

$rows = [Collections.Generic.List[object]]::new()
$vehicleOwners = @{}
$duplicateVehicleScripts = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$missing = [Collections.Generic.List[string]]::new()
$textureTotal = [long]0
$pngRgbaTotal = [long]0
$processed = 0

foreach ($id in $activeIds) {
    $processed++
    if (($processed % 25) -eq 0) { Write-Output "Scanning assets $processed/$($activeIds.Count): $id" }
    $mediaFiles = [long]0; $mediaBytes = [long]0
    $textureFiles = [long]0; $textureBytes = [long]0; $pngRgbaBytes = [long]0
    $modelFiles = [long]0; $modelBytes = [long]0
    $luaBytes = [long]0; $scriptBytes = [long]0
    $vehicleScriptCount = 0

    if (-not $locations.ContainsKey($id)) {
        $missing.Add($id)
        $rows.Add([pscustomobject]@{ id=$id; media_files=0; media_bytes=0; texture_files=0; texture_bytes=0; png_rgba_est_bytes=0; model_files=0; model_bytes=0; lua_bytes=0; script_bytes=0; vehicle_script_count=0 })
        continue
    }

    $loc = $locations[$id]
    if (-not $loc.versionDir) {
        $versionCandidates = @(Get-ChildItem -LiteralPath $loc.modRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^42(?:\.\d+)?$' })
        if ($versionCandidates.Count -gt 0) {
            $loc.versionDir = $versionCandidates | Sort-Object { if ($_.Name -match '^42\.(\d+)$') { [int]$Matches[1] } else { 0 } } -Descending | Select-Object -First 1 -ExpandProperty FullName
        }
    }

    $mediaRoots = [Collections.Generic.List[string]]::new()
    foreach ($candidate in @((Join-Path $loc.modRoot 'media'), (Join-Path $loc.modRoot 'common\media'), $(if ($loc.versionDir) { Join-Path $loc.versionDir 'media' }))) {
        if ($candidate -and (Test-Path -LiteralPath $candidate) -and -not $mediaRoots.Contains([IO.Path]::GetFullPath($candidate))) { $mediaRoots.Add([IO.Path]::GetFullPath($candidate)) }
    }
    $seenFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $scriptFiles = [Collections.Generic.List[string]]::new()
    foreach ($root in $mediaRoots) {
        foreach ($filePath in [IO.Directory]::EnumerateFiles($root, '*', [IO.SearchOption]::AllDirectories)) {
            $fullPath = [IO.Path]::GetFullPath($filePath)
            if (-not $seenFiles.Add($fullPath)) { continue }
            $fileLength = ([IO.FileInfo]::new($fullPath)).Length
            $mediaFiles++
            $mediaBytes += $fileLength
            $ext = [IO.Path]::GetExtension($fullPath).ToLowerInvariant()
            if ($ext -in @('.png','.dds','.jpg','.jpeg','.tga','.bmp','.webp')) {
                $textureFiles++
                $textureBytes += $fileLength
                if ($ext -eq '.png') { $pngRgbaBytes += Get-PngRgbaEstimate $fullPath }
            }
            if ($ext -in @('.fbx','.x','.obj','.mesh','.glb','.gltf')) { $modelFiles++; $modelBytes += $fileLength }
            if ($ext -eq '.lua') { $luaBytes += $fileLength }
            if ($ext -eq '.txt' -and $fullPath -match '\\scripts\\') { $scriptBytes += $fileLength }
            if ($ext -eq '.txt' -and $fullPath -match '\\scripts\\') { $scriptFiles.Add($fullPath) }
        }
    }

    foreach ($scriptFile in $scriptFiles) {
        $content = [IO.File]::ReadAllText($scriptFile)
        $moduleMatch = [regex]::Match($content, '(?im)^\s*module\s+([A-Za-z0-9_.-]+)')
        if (-not $moduleMatch.Success) { continue }
        $module = $moduleMatch.Groups[1].Value
        foreach ($vehicleMatch in [regex]::Matches($content, '(?im)^\s*vehicle\s+([A-Za-z0-9_.-]+)')) {
            $scriptName = $module + '.' + $vehicleMatch.Groups[1].Value
            $vehicleScriptCount++
            if (-not $vehicleOwners.ContainsKey($scriptName)) { $vehicleOwners[$scriptName] = $id }
            elseif ($vehicleOwners[$scriptName] -ne $id) { $vehicleOwners[$scriptName] = 'AMBIGUOUS'; [void]$duplicateVehicleScripts.Add($scriptName) }
        }
    }

    $textureTotal += $textureBytes
    $pngRgbaTotal += $pngRgbaBytes
    $rows.Add([pscustomobject]@{ id=$id; media_files=$mediaFiles; media_bytes=$mediaBytes; texture_files=$textureFiles; texture_bytes=$textureBytes; png_rgba_est_bytes=$pngRgbaBytes; model_files=$modelFiles; model_bytes=$modelBytes; lua_bytes=$luaBytes; script_bytes=$scriptBytes; vehicle_script_count=$vehicleScriptCount })
}

$generated = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$builder = [Text.StringBuilder]::new()
[void]$builder.AppendLine('return {')
[void]$builder.AppendLine('    generated_utc = ' + (Quote-Lua $generated) + ',')
[void]$builder.AppendLine('    mods = {')
foreach ($row in $rows) {
    [void]$builder.AppendLine('        [' + (Quote-Lua $row.id) + '] = { media_files=' + $row.media_files + ', media_bytes=' + $row.media_bytes + ', texture_files=' + $row.texture_files + ', texture_bytes=' + $row.texture_bytes + ', png_rgba_est_bytes=' + $row.png_rgba_est_bytes + ', model_files=' + $row.model_files + ', model_bytes=' + $row.model_bytes + ', lua_bytes=' + $row.lua_bytes + ', script_bytes=' + $row.script_bytes + ', vehicle_script_count=' + $row.vehicle_script_count + ' },')
}
[void]$builder.AppendLine('    },')
[void]$builder.AppendLine('    vehicle_owners = {')
foreach ($scriptName in @($vehicleOwners.Keys | Sort-Object)) {
    [void]$builder.AppendLine('        [' + (Quote-Lua $scriptName) + '] = ' + (Quote-Lua $vehicleOwners[$scriptName]) + ',')
}
[void]$builder.AppendLine('    },')
[void]$builder.AppendLine('}')
[IO.File]::WriteAllText($manifestPath, $builder.ToString(), [Text.UTF8Encoding]::new($false))

"Generated manifest: $manifestPath"
"Active mods=$($activeIds.Count); mapped=$($rows.Count - $missing.Count); missing=$($missing.Count); vehicle scripts=$($vehicleOwners.Count); ambiguous=$($duplicateVehicleScripts.Count)"
"Texture files=$($rows | Measure-Object texture_files -Sum | Select-Object -ExpandProperty Sum); compressed MiB=$([math]::Round($textureTotal/1MB,1)); PNG RGBA estimate MiB=$([math]::Round($pngRgbaTotal/1MB,0))"
if ($missing.Count -gt 0) { 'Missing IDs: ' + ($missing -join ', ') }
