Import-Module ".\Utilities.psm1"

# Create end results Directory
$OutputDir = New-Item -Type Directory Results -Force
$TempDir = New-Item -Type Directory "Temp_$([guid]::NewGuid().Guid)" -Force

function Calculate-Size {
    param(
        $Target
    )
    if ($Target.PSIsContainer -eq $false) {
        return $Target.Length
    }

    $Size = 0
    foreach ($Item in Get-ChildItem -Recurse -Path $Target.FullName | Where-Object { $_.PSIsContainer -eq $false }) {
        $Size += $Item.Length
    }
    return $Size
}

function Format-Result {
    param(
        $CorpusConfig,
        $CompressorConfig,
        $Source,
        $Target,
        $ExecutionTime
    )
    
    $SourceItem = Get-Item $Source
    try {
        $TargetItem = Get-Item $Target
    } catch {}
    $InputSize = (Calculate-Size $SourceItem)
    
    if ($Target -eq $null -or $TargetItem -eq $null -or $TargetItem.Length -eq 0) {
        $OutputSize = $null

        $CompressionRatio = $null
        $PercentCompression = $null
        $BitsPerByte = $null
    } else {
        $OutputSize = (Calculate-Size $TargetItem)
        
        $CompressionRatio = $InputSize / $OutputSize
        $PercentCompression = (1 - ($OutputSize / $InputSize)) * 100
        $BitsPerByte = 8 / $CompressionRatio
    }
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


function Run-CompressionSuite {
    param(
        $CorpusConfig,
        $CompressorsConfig
    )
    $ResultsArray = New-Object System.Collections.Generic.List[System.Object]

    Write-Host "Collecting $($CorpusConfig.Label) Corpus..."
    $TimeData = Measure-Command { $SourceItem = Invoke-Expression $CorpusConfig.Source }
    Write-Host "$($CorpusConfig.Label) Corpus collected in $($TimeData.TotalSeconds)s"
    Write-Host

    Write-Host "Performing Compression Test for $($CorpusConfig.Label)"
    foreach ($Compressor in $CompressorsConfig) {
        if ($Compressor.Enabled -ne $null -and  -not $Compressor.Enabled){
            continue
        }
        if ($SourceItem.PSIsContainer -and -not ($Compressor.CanRecurse -eq $null -or $Compressor.CanRecurse)) {
            continue;
        }
        $Source = $SourceItem.FullName
        $Target = "$($TempDir.Fullname)/$([guid]::NewGuid().Guid).$($Compressor.Extension)"
        
        $Arguments = $Compressor.Arguments

        $EnvPath = $env:Path;
        try{
            if ($Compressor.Path){
                $env:Path = "$($Compressor.Path);$($env:Path)"
            }
            $TimeData = Measure-Command { Invoke-Expression $Compressor.Command }
        } catch  {
            Write-Error "An Error occured testing $($Compressor.Label)"
            Write-Debug $_
            $Target = $null
        }
        $env:Path = $EnvPath;
        Write-Host "$($Compressor.Label) in $($TimeData.TotalMilliseconds)"
        $ResultsArray.Add((Format-Result $CorpusConfig $Compressor $Source $Target $TimeData))
    }
    Write-Host
    return $ResultsArray
}

function Write_ResultsCSV {
    param(
        $Results,
        $OutputPath,
        $Filename = 'CompressionResults'
    )
    $Destination = $OutputPath.FullName + "\$Filename.csv"
    $Results | Sort-Object @{ Expression = "CompressionRatio"; Descending = $true },@{ Expression = "ExecutionTime" } | Export-Csv -Path $Destination -NoTypeInformation
}
function Write_ResultsJSON {
    param(
        $Results,
        $OutputPath,
        $Filename = 'CompressionResults'
    )
    $Destination = $OutputPath.FullName + "\$Filename"
    $ResultsText = $Results | ConvertTo-Json -Depth 50
    $ResultsText | Out-File "$Destination.json"
    "Compression_Results_Loaded($ResultsText)" | Out-File "$Destination.jsonp"
}

Function Get_CompressorTests{
    Param(
        $Configuration
    )
    $Results = @()
    foreach ($Config in $Configuration.Compressors) {
        if ($Config.Tests -eq $null) {
            $Results += $Config
            continue
        }
        foreach ($Test in $Config.Tests) {
            $TestObject = $Config | Select-Object -Property * -ExcludeProperty Tests
            $Test.PsObject.Properties | % {
                Add-Member -InputObject $TestObject -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
            }
            $Results += $TestObject
        }
    }
    return $Results
}

$Configuration = Get-Content .\configuration.json | ConvertFrom-Json
$Compressors = Get_CompressorTests $Configuration
$Results = New-Object -TypeName PSObject
foreach ($CorpusConfig in $Configuration.Corpuses) {
    if ($CorpusConfig.Enabled -ne 'true') {
        Write-Host "Skipping Disabled $($CorpusConfig.Label) Corpus..."
        Write-Host
        continue
    }

    $Result = Run-CompressionSuite $CorpusConfig $Compressors
    Add-Member -InputObject $Results -NotePropertyName $CorpusConfig.Id -NotePropertyValue $Result

    Write-Host
    Write-Host "Writing Results CSV for $($CorpusConfig.Label)"
    Write_ResultsCSV $Result $OutputDir "Results_$($CorpusConfig.Id)"

    Write-Host
}

Write-Host "Writing Output JSON"
Add-Member -InputObject $Configuration -NotePropertyName Results -NotePropertyValue $Results
Write_ResultsJSON $Configuration $OutputDir "TestResults"
Write-Host

Write-Host "Performing Cleanup"
Remove-Item -Recurse -Force $TempDir

Write-Host "Done" 