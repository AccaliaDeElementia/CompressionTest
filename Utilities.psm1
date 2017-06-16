$Assembly = Add-Type -AssemblyName System.Web

Function New_RandomBinaryFile {
    Param(
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
            [Byte[]] $bytes = New-Object byte[] $ChunkSize
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

Function New_RandomTextFile {
    Param(
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
            $chunk = [System.Web.Security.Membership]::GeneratePassword($ChunkSize, 0)
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
        "Label" = $Label;
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
        $Source,
        $TempDir,
        $Compressor
    )

    Write-Host "Compressing $($Compressor.Executable) $($Compressor.Label)..."

    $Target = "$($TempDir.Fullname)\$([guid]::NewGuid().Guid).$($Compressor.Extension)" 

    $Payload = New-Object -TypeName PSObject -Property @{
        Source = $Source
        Target = $Target
        Executable = $Compressor.Executable
        Arguments = $Compressor.Arguments
        Extension = $Compressor.Extension
        Label = $Compressor.Label
    }
    
    $TimeInfo = Measure-Command {&$Compressor.Command $Payload}

    $Target = Get-Item $Target

    $Result = Format-Result $Source $Target $Compressor.Label $Compressor.Executable $Compressor.Arguments $TimeInfo
    
    Remove-Item $Target

    return $Result
}


Function New_Pair {
    return New-Object -TypeName PSObject -Property @{
        First = $Args[0]
        Second = $Args[1]
    }
}

Export-ModuleMember *_*