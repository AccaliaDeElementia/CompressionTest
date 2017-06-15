$Assembly = Add-Type -AssemblyName System.Web

Function New_RandomBinaryFile {
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

Function New_RandomTextFile {
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

Function Calculate-Size {
    Param(
        $Target
    )
    if ($Target.PSIsContainer -eq $false) {
        return $Target.Length
    }
    
    $Size = 0
    foreach ($Item in Get-ChildItem -Recurse -Path $Target.FullName | Where-Object {$_.PSIsContainer -eq $false}) {
        $Size += $Item.Length
    }
    return $Size
}

Function Format-Result {
    Param(
        $Source,
        $Result,
        $Label,
        $Executable,
        $Arguments,
        $ExecutionTime
    )
    $obj = New-Object -TypeName PSObject -Prop (@{
        "Label" = ($Executable + ' ' + $Label);
        "Executable" = $Executable;
        "Arguments" = $Arguments;
        "Input" = $Source.Name;
        "Output" = $Result.Name;
        "InputSize" = (Calculate-Size $Source);
        "OutputSize" = $Result.Length;
        "ExecutionTime" = $ExecutionTime.TotalMilliseconds
    })


    return $obj
}

Function Execute_Compression {
    Param (
        $CompressorSource,
        $CompressorTarget,
        $CompressorLabel,
        $CompressorExecutable,
        $CompressorArguments,
        $CompressorCommand
    )

    Write-Host "Compressing $CompressorExecutable $CompressorLabel..."

    $CompressorSource = Get-Item $CompressorSource;
    $TimeInfo = Measure-Command $CompressorCommand
    $CompressorTarget = Get-Item $CompressorTarget
    
    $Result = Format-Result $CompressorSource $CompressorTarget $CompressorLabel $CompressorExecutable $CompressorArguments $TimeInfo.TotalMilliseconds
    
    Remove-Item $CompressorTarget

    return $Result
}


Export-ModuleMember *_*