
Function Calculate-Size {
    Param(
        $Input
    )
    if ($Input.PSIsContainer -eq $false) {
        return $Input.Length
    }
    $Size = 0
    foreach ($Item in Get-ChildItem -Recurse -Path $Input.FullName | Where-Object {$_.PSIsContainer -eq $false}) {
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
        $Arguments
    )
    $obj = New-Object -TypeName PSObject -Prop (@{
        "Label" = $Label;
        "Executable" = $Executable;
        "Arguments" = $Arguments;
        "Input" = $Source.Name;
        "Output" = $Result.Name;
        "InputSize" = (Calculate-Size $Source);
        "OutputSize"= $Result.Length;
    })

    Remove-Item $Result

    return $obj
}

Function Compress-7z {
    Param(
        $Target,
        [string]$FileName = [guid]::NewGuid().Guid + '.7z',
        [string]$Type = '7z',
        [string]$Mode = 'LZMA',
        [int]$Level = 9,
        [string]$Label = 'Generic 7Zip Test'
    )
    $Path = (Resolve-Path '.').Path
    $Dest = $($Path + '\' + $FileName)

    $ArchiveType = '-t' + $Type
    $ArchiveMode = '-m0=' + $Mode
    $CompressionLevel = '-mx=' + $Level
    
    $Arguments = "$ArchiveType $ArchiveMode $CompressionLevel"
    
    $stdout = 7z a $ArchiveType $ArchiveMode $CompressionLevel $Dest $Target.FullName
    $archive = Get-Item $Dest

    return Format-Result $Target $archive $Label '7z' $Arguments
}

Function Compress_7z {
    Param(
        $Target
    )
    $Results = @(
        (Compress-7z $Target -Label '7z LZMA Fastest Preset' -Mode 'LZMA' -Level 1),
        (Compress-7z $Target -Label '7z LZMA Fast Preset' -Mode 'LZMA' -Level 3),
        (Compress-7z $Target -Label '7z LZMA Normal Preset' -Mode 'LZMA' -Level 5),
        (Compress-7z $Target -Label '7z LZMA Maximum Preset' -Mode 'LZMA' -Level 7),
        (Compress-7z $Target -Label '7z LZMA Ultra Preset' -Mode 'LZMA' -Level 9),
        (Compress-7z $Target -Label '7z LZMA2 Fastest Preset' -Mode 'LZMA2' -Level 1),
        (Compress-7z $Target -Label '7z LZMA2 Fast Preset' -Mode 'LZMA2' -Level 3),
        (Compress-7z $Target -Label '7z LZMA2 Normal Preset' -Mode 'LZMA2' -Level 5),
        (Compress-7z $Target -Label '7z LZMA2 Maximum Preset' -Mode 'LZMA2' -Level 7),
        (Compress-7z $Target -Label '7z LZMA2 Ultra Preset' -Mode 'LZMA2' -Level 9),
        (Compress-7z $Target -Label '7z Deflate Fastest Preset' -Mode 'Deflate' -Level 1),
        (Compress-7z $Target -Label '7z Deflate Fast Preset' -Mode 'Deflate' -Level 3),
        (Compress-7z $Target -Label '7z Deflate Normal Preset' -Mode 'Deflate' -Level 5),
        (Compress-7z $Target -Label '7z Deflate Maximum Preset' -Mode 'Deflate' -Level 7),
        (Compress-7z $Target -Label '7z Deflate Ultra Preset' -Mode 'Deflate' -Level 9),
        (Compress-7z $Target -Label '7z Deflate64 Fastest Preset' -Mode 'Deflate64' -Level 1),
        (Compress-7z $Target -Label '7z Deflate64 Fast Preset' -Mode 'Deflate64' -Level 3),
        (Compress-7z $Target -Label '7z Deflate64 Normal Preset' -Mode 'Deflate64' -Level 5),
        (Compress-7z $Target -Label '7z Deflate64 Maximum Preset' -Mode 'Deflate64' -Level 7),
        (Compress-7z $Target -Label '7z Deflate64 Ultra Preset' -Mode 'Deflate64' -Level 9),
        (Compress-7z $Target -Label '7z BZip2 Fastest Preset' -Mode 'BZip2' -Level 1),
        (Compress-7z $Target -Label '7z BZip2 Fast Preset' -Mode 'BZip2' -Level 3),
        (Compress-7z $Target -Label '7z BZip2 Normal Preset' -Mode 'BZip2' -Level 5),
        (Compress-7z $Target -Label '7z BZip2 Maximum Preset' -Mode 'BZip2' -Level 7),
        (Compress-7z $Target -Label '7z BZip2 Ultra Preset' -Mode 'BZip2' -Level 9),
        (Compress-7z $Target -Label '7z BZip2 Fastest Preset' -Mode 'PPMd' -Level 1),
        (Compress-7z $Target -Label '7z PPMd Fast Preset' -Mode 'PPMd' -Level 3),
        (Compress-7z $Target -Label '7z PPMd Normal Preset' -Mode 'PPMd' -Level 5),
        (Compress-7z $Target -Label '7z PPMd Maximum Preset' -Mode 'PPMd' -Level 7),
        (Compress-7z $Target -Label '7z PPMd Ultra Preset' -Mode 'PPMd' -Level 9)
    )
    return $Results
}


Function Compress_7zLZMA {
    Param(
        $Target,
        [string]$Path = (Resolve-Path '.').Path,
        [string]$FileName = [guid]::NewGuid().Guid + '.7z',
        [int]$Level=9
    )
    $Dest = $($Path + '\' + $FileName)
    return Compress-7z $Target $Dest '7z' 'LZMA' $Level
}

Function Compress_7zDeflate {
    Param(
        $Target,
        [string]$Path = (Resolve-Path '.').Path,
        [string]$FileName = [guid]::NewGuid().Guid + '.7z',
        [int]$Level=9
    )
    $Dest = $($Path + '\' + $FileName)
    return Compress-7z $Target $Dest '7z' 'Deflate64' $Level
}

Export-ModuleMember *_*