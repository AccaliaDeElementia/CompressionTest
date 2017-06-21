$Assembly = Add-Type -AssemblyName System.Web

function New_RandomBinaryFile {
    param(
        $Target,
        $FileSize = 4kb,
        $ChunkSize = 4kb
    )
    $chunks = [math]::Ceiling($FileSize / $ChunkSize)
    [io.FileStream]$file = $null
    try {
        $file = [io.file]::OpenWrite($Target)
        $random = New-Object System.Random
        for ($i = 0; $i -lt $chunks; $i += 1) {
            [byte[]]$bytes = New-Object byte[] $ChunkSize
            $random.NextBytes($bytes)
            $file.Write($bytes,0,$ChunkSize)
        }
    } finally {
        if ($null -ne $file) {
            $file.Dispose();
        }
    }
    $di = Get-Item $Target
    return $di
}

function New_RandomTextFile {
    param(
        $Target,
        $FileSize = 4kb,
        $ChunkSize = 128
    )
    $enc = [System.Text.Encoding]::UTF8
    if ($ChunkSize -gt 128) {
        $ChunkSize = 128
    }
    $chunks = [math]::Ceiling($FileSize / $ChunkSize)
    [io.FileStream]$file = $null
    try {
        $file = [io.file]::OpenWrite($Target)
        for ($i = 0; $i -lt $chunks; $i += 1) {
            $chunk = [System.Web.Security.Membership]::GeneratePassword($ChunkSize,0)
            $file.Write($enc.GetBytes($chunk),0,$ChunkSize)
        }
    } finally {
        if ($null -ne $file) {
            $file.Dispose();
        }
    }
    $di = Get-Item $Target
    return $di
}

Export-ModuleMember *_* 