param(
    [string]$JarPath = (Join-Path $PSScriptRoot '..\42\media\java\client\ChilaSedaAuditSuite.jar')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression

function Convert-Bytes {
    param([byte[]]$Bytes, [object[]]$Mappings)
    $output = [System.Collections.Generic.List[byte]]::new()
    $i = 0
    while ($i -lt $Bytes.Length) {
        $matched = $false
        foreach ($mapping in $Mappings) {
            $old = $mapping.Old
            if ($i + $old.Length -gt $Bytes.Length) { continue }
            $same = $true
            for ($j = 0; $j -lt $old.Length; $j++) {
                if ($Bytes[$i + $j] -ne $old[$j]) { $same = $false; break }
            }
            if ($same) {
                $output.AddRange($mapping.New)
                $i += $old.Length
                $matched = $true
                break
            }
        }
        if (-not $matched) { $output.Add($Bytes[$i]); $i++ }
    }
    return ,$output.ToArray()
}

function Move-ClassPackage {
    param([byte[]]$Bytes, [byte[][]]$Mappings)
    if ($Bytes.Length -lt 10 -or $Bytes[0] -ne 0xCA -or $Bytes[1] -ne 0xFE -or
        $Bytes[2] -ne 0xBA -or $Bytes[3] -ne 0xBE) {
        throw 'Invalid Java class file.'
    }
    $constantCount = ($Bytes[8] -shl 8) -bor $Bytes[9]
    $offset = 10
    $result = [System.Collections.Generic.List[byte]]::new()
    $result.AddRange([byte[]]$Bytes[0..9])
    for ($index = 1; $index -lt $constantCount; $index++) {
        $tag = $Bytes[$offset]
        $result.Add($tag)
        $offset++
        switch ($tag) {
            1 {
                $length = ($Bytes[$offset] -shl 8) -bor $Bytes[$offset + 1]
                $offset += 2
                $value = [byte[]]$Bytes[$offset..($offset + $length - 1)]
                $value = Convert-Bytes -Bytes $value -Mappings $Mappings
                if ($value.Length -gt 65535) { throw 'Constant pool UTF-8 entry exceeded 65535 bytes.' }
                $result.Add([byte](($value.Length -shr 8) -band 0xFF))
                $result.Add([byte]($value.Length -band 0xFF))
                $result.AddRange($value)
                $offset += $length
            }
            { $_ -in 3, 4 } { $result.AddRange([byte[]]$Bytes[$offset..($offset + 3)]); $offset += 4 }
            { $_ -in 5, 6 } { $result.AddRange([byte[]]$Bytes[$offset..($offset + 7)]); $offset += 8; $index++ }
            { $_ -in 7, 8, 16, 19, 20 } { $result.AddRange([byte[]]$Bytes[$offset..($offset + 1)]); $offset += 2 }
            { $_ -in 9, 10, 11, 12, 17, 18 } { $result.AddRange([byte[]]$Bytes[$offset..($offset + 3)]); $offset += 4 }
            15 { $result.AddRange([byte[]]$Bytes[$offset..($offset + 2)]); $offset += 3 }
            default { throw "Unsupported Java constant pool tag $tag." }
        }
    }
    if ($offset -lt $Bytes.Length) { $result.AddRange([byte[]]$Bytes[$offset..($Bytes.Length - 1)]) }
    return ,$result.ToArray()
}

$mapText = @(
    'chilaseda/errorlogs/Main$Entry|chilaseda/ErrorLogsMain$Entry',
    'chilaseda/errorlogs/Main|chilaseda/ErrorLogsMain',
    'chilaseda/errorlogs|chilaseda',
    'chilaseda/perf/Main$Event|chilaseda/PerformanceMain$Event',
    'chilaseda/perf/Main$Row|chilaseda/PerformanceMain$Row',
    'chilaseda/perf/Main|chilaseda/PerformanceMain',
    'chilaseda/perf|chilaseda',
    'chilaseda/weightmonitor/Main|chilaseda/WeightLogMain',
    'chilaseda/weightmonitor|chilaseda',
    'chilaseda.errorlogs.Main$Entry|chilaseda.ErrorLogsMain$Entry',
    'chilaseda.errorlogs.Main|chilaseda.ErrorLogsMain',
    'chilaseda.errorlogs|chilaseda',
    'chilaseda.perf.Main$Event|chilaseda.PerformanceMain$Event',
    'chilaseda.perf.Main$Row|chilaseda.PerformanceMain$Row',
    'chilaseda.perf.Main|chilaseda.PerformanceMain',
    'chilaseda.perf|chilaseda',
    'chilaseda.weightmonitor.Main|chilaseda.WeightLogMain',
    'chilaseda.weightmonitor|chilaseda'
)
$mappings = @($mapText | ForEach-Object {
    $parts = $_.Split('|', 2)
    [pscustomobject]@{ Old=[Text.Encoding]::UTF8.GetBytes($parts[0]); New=[Text.Encoding]::UTF8.GetBytes($parts[1]) }
})

$fullJar = [IO.Path]::GetFullPath($JarPath)
$tempJar = "$fullJar.repack.tmp"
$input = [IO.Compression.ZipFile]::OpenRead($fullJar)
$output = [IO.Compression.ZipArchive]::new([IO.File]::Open($tempJar, [IO.FileMode]::Create), [IO.Compression.ZipArchiveMode]::Create)
$changed = 0
try {
    foreach ($entry in $input.Entries) {
        $newName = $entry.FullName
        $rename = @(
            @('chilaseda/errorlogs/Main$Entry.class', 'chilaseda/ErrorLogsMain$Entry.class'),
            @('chilaseda/errorlogs/Main.class', 'chilaseda/ErrorLogsMain.class'),
            @('chilaseda/perf/Main$Event.class', 'chilaseda/PerformanceMain$Event.class'),
            @('chilaseda/perf/Main$Row.class', 'chilaseda/PerformanceMain$Row.class'),
            @('chilaseda/perf/Main.class', 'chilaseda/PerformanceMain.class'),
            @('chilaseda/weightmonitor/Main.class', 'chilaseda/WeightLogMain.class')
        )
        foreach ($pair in $rename) { if ($newName -eq $pair[0]) { $newName = $pair[1]; break } }
        $target = $output.CreateEntry($newName, [IO.Compression.CompressionLevel]::Optimal)
        if ($entry.FullName.EndsWith('.class')) {
            $stream = $entry.Open()
            try { $memory = [IO.MemoryStream]::new(); $stream.CopyTo($memory); $bytes = $memory.ToArray() }
            finally { $stream.Dispose(); $memory.Dispose() }
            $bytes = Move-ClassPackage -Bytes $bytes -Mappings $mappings
            $write = $target.Open()
            try { $write.Write($bytes, 0, $bytes.Length) } finally { $write.Dispose() }
            $changed++
        } else {
            $stream = $entry.Open()
            $write = $target.Open()
            try { $stream.CopyTo($write) } finally { $stream.Dispose(); $write.Dispose() }
        }
    }
} finally {
    $input.Dispose()
    $output.Dispose()
}
if ($changed -ne 6) {
    Remove-Item -LiteralPath $tempJar -Force
    throw "Expected to relocate 6 Java classes; found $changed. Original JAR was left intact."
}
Move-Item -LiteralPath $tempJar -Destination $fullJar -Force
"Relocated $changed bridge/helper classes into exact javaPkgName chilaseda: $fullJar"

