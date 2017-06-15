Add-Type -TypeDefinition @"
   public enum CompressionPreset
   {
      Fastest=1,
      Fast=3,
      Normal=5,
      Maximum=7,
      Ultra=9
   }
"@

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
        [string]$Type = '7z',
        [string]$Mode = 'LZMA',
        [int]$Level = 9,
        [string]$Label = 'Generic 7Zip Test'
    )
    $FileName = [guid]::NewGuid().Guid + '.' + $Type.ToLower()

    $Path = (Resolve-Path '.').Path
    $Dest = $($Path + '\' + $FileName)

    $ArchiveType = '-t' + $Type
    $ArchiveMode = '-mm=' + $Mode
    $CompressionLevel = '-mx=' + $Level
    
    $Arguments = "$ArchiveType $ArchiveMode $CompressionLevel"
    
    $stdout = 7z a $Dest $ArchiveType $ArchiveMode $CompressionLevel $Target.FullName
    $archive = Get-Item $Dest

    return Format-Result $Target $archive $Label '7z' $Arguments
}

Function Compress_7z {
    Param(
        $Target
    )

    $Results = @()
    foreach ($Mode in @('LZMA', 'LZMA2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in [CompressionPreset].GetEnumValues()) {
           #$Results += Compress-7z $Target -Label "7z *.7z $Mode $($Level -As [CompressionPreset]) Preset" -Mode $Mode -Level $Level
        }
    }
    foreach ($Mode in @('LZMA', 'LZMA2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in [CompressionPreset].GetEnumValues()) {
            #$Results += Compress-7z $Target -Label "7z *.zip $Mode $($Level -As [CompressionPreset]) Preset" -Type 'Zip' -Mode $Mode -Level $Level
        }
    }
    foreach ($Level in [CompressionPreset].GetEnumValues()) {
        $Results += Compress-7z $Target -Label "7z *.xz $($Level -As [CompressionPreset]) Preset" -Type 'xz' -Mode 'LZMA2' -Level $Level
    }
    if ($Target.PSIsContainer -eq $false) {
        # Cannot compress folders directly into gzip or bz2
        foreach ($Type in @('gzip', 'bzip2')) {
            foreach ($Level in [CompressionPreset].GetEnumValues()) {
                #$Results += Compress-7z $Target -Label "7z *.$Type $($Level -As [CompressionPreset]) Preset" -Type $Type -Mode 'deflate' -Level $Level
            }
        }
    }
    return $Results
}

Export-ModuleMember *_*