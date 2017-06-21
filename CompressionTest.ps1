Import-Module ".\Utilities.psm1"


# Create end results Directory
$OutputDir = New-Item -Type Directory Results -Force
$TempDir = New-Item -Type Directory "Temp_$([guid]::NewGuid().Guid)" -Force

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
        $CorpusConfig,
        $CompressorConfig,
        $Source,
        $Target,
        $ExecutionTime
    )
    $SourceItem = Get-Item $Source
    $TargetItem = Get-Item $Target
    $InputSize = (Calculate-Size $SourceItem)
    $OutputSize = $TargetItem.Length
    
    $CompressionRatio = $InputSize / $OutputSize
    $PercentCompression = (1 - ($OutputSize / $InputSize)) * 100
    $BitsPerByte = 8 / $CompressionRatio

    $Result = New-Object -TypeName PSObject -Property @{
        Corpus = $CorpusConfig.Id;
        Compressor = $CompressorConfig.Id;
        Label = $CompressorConfig.Label;
        Command = $CompressorConfig.Command;
        Arguments = $CompressorConfig.Arguments;
        InputSize = $InputSize;
        OutputSize = $OutputSize;
        ExecutionTime = $ExecutionTime.TotalMilliseconds
        CompressionRatio = $CompressionRatio;
        PercentCompression = $PercentCompression;
        BitsPerByte = $BitsPerByte;
    }

    return $Result
}


Function Run-CompressionSuite {
    Param(
        $CorpusConfig,
        $CompressorsConfig
    )
    $ResultsArray = New-Object System.Collections.Generic.List[System.Object]

    Write-Host "Collecting $($CorpusConfig.Label) Corpus..."
    $TimeData = Measure-Command {$SourceItem = Invoke-Expression $CorpusConfig.Source}
    Write-Host "$($CorpusConfig.Label) Corpus collected in $($TimeData.TotalSeconds)s"
    Write-Host

    Write-Host "Performing Compression Test for $($CorpusConfig.Label)"
    foreach ($Compressor in $CompressorsConfig){
        if ($SourceItem.PSIsContainer -and -not $Compressor.CanRecurse) {
            Continue;
        }
        $Source = $SourceItem.FullName
        $Target = "$($TempDir.Fullname)/$([guid]::NewGuid().Guid).$($Compressor.Extension)"
        $Arguments = $Compressor.Arguments
        $TimeData = Measure-Command {Invoke-Expression $Compressor.Command}
        Write-Host "$($Compressor.Label) in $($TimeData.TotalMilliseconds)"
        $ResultsArray.add((Format-Result $CorpusConfig $Compressor $Source $Target $TimeData))
    }
    Write-Host
    return $ResultsArray
}

Function Write_ResultsCSV {
    Param(
        $Results,
        $OutputPath,
        $Filename = 'CompressionResults'
    )
    $Destination = $OutputPath.FullName + "\$Filename.csv"
    $Results | Sort-Object @{Expression = "CompressionRatio"; Descending = $true}, @{Expression = "ExecutionTime"} | Export-Csv -Path $Destination -NoTypeInformation
 }
 Function Write_ResultsJSON {
    Param(
        $Results,
        $OutputPath,
        $Filename = 'CompressionResults'
    )
    $Destination = $OutputPath.FullName + "\$Filename.json"
    $Results | ConvertTo-Json -Depth 50 | Out-File $Destination
 }

$Configuration = Get-Content .\configuration.json | ConvertFrom-Json
$Results = New-Object -TypeName PSObject
foreach ($testConfig in $Configuration.Corpuses) {
    if ($testConfig.Enabled -ne 'true'){
        Write-Host "Skipping Disabled $($testConfig.Label) Corpus..."
        Write-Host
        Continue
    }

    $ResultsArray = Run-CompressionSuite $testConfig $Configuration.Compressors
    Add-Member -InputObject $Results -NotePropertyName $testConfig.id -NotePropertyValue $ResultsArray
    
    Write_ResultsCSV $Result $OutputDir "Results_$($testConfig.Id)"
    Write-Host
}



Write-Host "Writing Output JSON"
Add-Member -InputObject $Configuration -NotePropertyName Results -NotePropertyValue $Results
Write_ResultsJSON $Configuration $OutputDir "TestResults"
Write-Host

Write-Host "Performing Cleanup"
Remove-Item -Recurse -Force $TempDir

Write-Host "Done"