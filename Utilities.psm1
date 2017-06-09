$Assembly = Add-Type -AssemblyName System.Web

Function New-RandomBinaryFile {
    Param(
        $FileSize = 4kb,
        $Path = (Resolve-Path '.').Path,
        $FileName = [guid]::NewGuid().Guid + '.dat',
        $ChunkSize = 4kb
    )
    $chunks = [math]::Ceiling($FileSize / $ChunkSize)
    [io.FileStream]$file = $null
    try {
        $file = [io.file]::OpenWrite($Path + '\' + $FileName)
        $random = New-Object System.Random
        for ($i = 0; $i -lt $chunks; $i += 1) {
            [Byte[]] $bytes = New-Object byte[] $ChunkSize
            $random.NextBytes($bytes)
            $file.Write($bytes,0,$ChunkSize)
        }
    } finally {
        if ($null -ne $file) {
            $file.Dispose();
        }
    }
    $di = Get-ChildItem $path -Filter $FileName
    return $di
}

Function New-RandomTextFile {
    Param(
        $FileSize = 4kb,
        $Path = (Resolve-Path '.').Path,
        $FileName = [guid]::NewGuid().Guid + '.dat',
        $ChunkSize = 128
    )
    $enc = [System.Text.Encoding]::UTF8
    if ($ChunkSize -gt 128) {
        $ChunkSize = 128
    }
    $chunks = [math]::Ceiling($FileSize / $ChunkSize)
    [io.FileStream]$file = $null
    try {
        $file = [io.file]::OpenWrite($Path + '\' + $FileName)
        for ($i = 0; $i -lt $chunks; $i += 1) {
            $chunk = [System.Web.Security.Membership]::GeneratePassword($ChunkSize, 0)
            $file.Write($enc.GetBytes($chunk),0,$ChunkSize)
        }
    } finally {
        if ($null -ne $file) {
            $file.Dispose();
        }
    }
    $di = Get-ChildItem $path -Filter $FileName
    return $di
}
