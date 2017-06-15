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
    
    $Arguments = "7z.exe a $ArchiveType $ArchiveMode $CompressionLevel"
    
    Write-Host "Compressing $Label..."
    $time = Measure-Command {7z a $ArchiveType $ArchiveMode $CompressionLevel $Dest $Target.FullName}

    $archive = Get-Item $Dest

    $Result = Format-Result $Target $archive $Label '7z' $Arguments $time
    
    Remove-Item $archive

    return $Result
}

Function Compress_7z {
    Param(
        $Target
    )

    $Levels = [CompressionPreset].GetEnumValues()

    $Results = @()
    
    foreach ($Mode in @('LZMA', 'LZMA2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in $Levels) {
           $Results += Compress-7z $Target -Label "7z 7z $Mode $($Level -As [CompressionPreset]) Preset" -Mode $Mode -Level $Level
        }
    }

    foreach ($Mode in @('LZMA', 'BZip2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in $Levels) {
            $Results += Compress-7z $Target -Label "7z Zip $Mode $($Level -As [CompressionPreset]) Preset" -Type 'Zip' -Mode $Mode -Level $Level
        }
    }
    
    if ($Target.PSIsContainer -eq $false) {
        # Cannot compress folders directly into gzip, bzip2, or xz
        foreach ($Level in $Levels) {
            $Results += Compress-7z $Target -Label "7z Xz $($Level -As [CompressionPreset]) Preset" -Type 'Xz' -Mode 'LZMA2' -Level $Level
        }
        foreach ($Type in @('Gzip', 'Bzip2')) {
            foreach ($Level in $Levels) {
                $Results += Compress-7z $Target -Label "7z $Type $($Level -As [CompressionPreset]) Preset" -Type $Type -Mode 'deflate' -Level $Level
            }
        }
    }
    return $Results
}

Export-ModuleMember *_*