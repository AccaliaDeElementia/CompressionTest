Import-Module './Utilities.psm1'

Add-Type -TypeDefinition @"
   public enum CompressionPreset_7z
   {
      Fastest=1,
      Fast=3,
      Normal=5,
      Maximum=7,
      Ultra=9
   }
"@
Add-Type -TypeDefinition @"
   public enum CompressionPreset_WinRar
   {
      Fastest=1,
      Fast=2,
      Normal=3,
      Maximum=4,
      Ultra=5
   }
"@



Function Compress-7z {
    Param(
        $Source,
        [string]$Type = '7z',
        [string]$Mode = 'LZMA',
        [int]$Level = 9,
        [string]$Label = 'Generic 7Zip Test'
    )
    $FileName = [guid]::NewGuid().Guid + '.' + $Type.ToLower()

    $Path = (Resolve-Path '.').Path
    $Target = $($Path + '\' + $FileName)
    
    $Executable = "7z.exe"
    $Arguments = 'a', ('-t'+$Type), ('-mm='+ $Mode), ('-mx='+ $Level)
    $Command = {7z @Arguments $Target $Source.FullName}

    return Execute_Compression $Source $Target $Label $Executable $Arguments $Command
}


Function Compress-WinRar {
    Param(
        $Source,
        [int]$Level = 9,
        [string]$Label = 'Generic WinRar Test'
    )
    $FileName = [guid]::NewGuid().Guid + '.rar'

    $Path = (Resolve-Path '.').Path
    $Target = $($Path + '\' + $FileName)
    
    $Executable = "WinRar"
    $Arguments = 'a', ('-m'+ $Level)
    $Command = {&'C:\Program Files\WinRAR\Rar.exe' @Arguments $Target $Source.FullName}

    return Execute_Compression $Source $Target $Label $Executable $Arguments $Command
}

Function Test_7zCompression {
    Param(
        $Target
    )

    $Levels = [CompressionPreset_7z].GetEnumValues()

    $Results = @()
    
    foreach ($Mode in @('LZMA', 'LZMA2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in $Levels) {
           $Results += Compress-7z $Target -Label "7z $Mode $($Level -As [CompressionPreset_7z]) Preset" -Mode $Mode -Level $Level
        }
    }

    foreach ($Mode in @('LZMA', 'BZip2', 'Deflate', 'Deflate64', 'PPMd')) {
        foreach ($Level in $Levels) {
            $Results += Compress-7z $Target -Label "Zip $Mode $($Level -As [CompressionPreset_7z]) Preset" -Type 'Zip' -Mode $Mode -Level $Level
        }
    }
    
    if ($Target.PSIsContainer -eq $false) {
        # Cannot compress folders directly into gzip, bzip2, or xz
        foreach ($Level in $Levels) {
            $Results += Compress-7z $Target -Label "Xz $($Level -As [CompressionPreset_7z]) Preset" -Type 'Xz' -Mode 'LZMA2' -Level $Level
        }
        foreach ($Type in @('Gzip', 'Bzip2')) {
            foreach ($Level in $Levels) {
                $Results += Compress-7z $Target -Label "$Type $($Level -As [CompressionPreset_7z]) Preset" -Type $Type -Mode 'deflate' -Level $Level
            }
        }
    }

    # Add the where filter to cover the case when a compression fails
    return $Results | Where-Object {$_ -ne $null}
}

Function Test_WinRarCompression {
Param(
        $Target
    )

    $Levels = [CompressionPreset_WinRar].GetEnumValues()

    $Results = @()

    foreach ($Level in $Levels) {
        $Results += Compress-WinRar $Target -Label "WinRar $($Level -As [CompressionPreset_WinRar]) Preset" -Level $Level
    }
    # Add the where filter to cover the case when a compression fails
    return $Results | Where-Object {$_ -ne $null}
}

Export-ModuleMember *_*