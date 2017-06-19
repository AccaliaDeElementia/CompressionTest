Import-Module "./Utilities.psm1"

Function New-Compressor {
    Param(
        $Label,
        $Extension,
        $Executable,
        $Arguments,
        $Command = $null,
        $CanRecurse = $true,
        $TargetFirst = $true
    )
    if ($Command -eq $null) {
        if ($TargetFirst) {
            $Command = {Param($_)  &$_.Executable @($_.Arguments) $_.Target $_.Source}
        } else {
            $Command = {Param($_)  &$_.Executable @($_.Arguments) $_.Source $_.Target}
        }
    }
    return New-Object -TypeName PSObject -Property @{
            Label = $Label
            Extension = $Extension
            Executable = $Executable
            Arguments = $Arguments;
            CanRecurse = $CanRecurse
            Command = $Command
        }
}



Function Get_Compressors {
    $Results = @(
        (New-Compressor "Builtin Zip Compression" "zip" "Compress-Archive" @() {Param($_)  &$_.Executable $_.Source $_.Target}),
        (New-Compressor "Builtin Cab Compression" "cab" "makecab" @() -TargetFirst $false -CanRecurse $False)
    )
    
    foreach ($Level in @((New_Pair "Fastest" 1),(New_Pair "Fast" 2),(New_Pair "Normal" 3),(New_Pair "Maximum" 4),(New_Pair "Ultra" 5))) {
        $Results += New-Compressor "$($Level.First) Preset" "rar" "C:\Program Files\WinRAR\Rar.exe" @("a", "-m$($Level.Second)")
    }

    $SevenZLevels = @((New_Pair "Fastest" 1),(New_Pair "Fast" 3),(New_Pair "Normal" 5),(New_Pair "Maximum" 7),(New_Pair "Ultra" 9))
    foreach ($Type in @("Zip", "7z")) {
        foreach ($Level in $SevenZLevels) {
            $Results += New-Compressor "$Type $($Level.First) Preset" $Type "7z.exe" @("a", "-t$Type", "-mx=$($Level.Second)")
        }
    }

    # These algotithms can only handle one file so exclude from directory tests
    foreach ($Type in @("Gzip", "Bzip2", "Xz")) {
        foreach ($Level in $SevenZLevels) {
            $Results += New-Compressor "$Type $($Level.First) Preset" $Type "7z.exe" @("a", "-t$Type", "-mx=$($Level.Second)") -CanRecurse $false
        }
    }

    return $Results
}

Export-ModuleMember *_*