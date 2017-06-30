Param(
	[string]$SelectCorpora = '*',
	[string]$SelectCompressors = '*',
	[switch]$IncludeDisabled
)

if ($SelectCorpora -eq '*'){
	$SelectCorpora = @()
} else {
	$SelectCorpora = $SelectCorpora -split ','
}

if ($SelectCompressors -eq '*'){
	$SelectCompressors = @()
} else {
	$SelectCompressors = $SelectCompressors -split ','
}

Import-Module ".\Utilities.psm1"

# Create end results Directory
$OutputDir = New-Item -Type Directory Results -Force
$TempDir = New-Item -Type Directory "Temp_$([guid]::NewGuid().Guid)" -Force
$FailedTests = $false

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
        $Target = "$($TempDir.Fullname)/$($CorpusConfig.Id)_$($Compressor.Id).$($Compressor.Extension)"
        
        $Arguments = $Compressor.Arguments

        $EnvPath = $env:Path;
        try{
            if ($Compressor.Path){
                $env:Path = "$($Compressor.Path);$($env:Path)"
            }
            $TimeData = Measure-Command { Invoke-Expression $Compressor.Command }
			$ResultsArray.Add((Format-Result $CorpusConfig $Compressor $Source $Target $TimeData))
        } catch  {
            Write-Error "An Error occured testing $($Compressor.Label)"
            Write-Debug $_
            $Target = $null
            Set-Variable -Scope Script -Name FailedTests -Value $true
        }
        $env:Path = $EnvPath;
        Write-Host "$($Compressor.Label) in $($TimeData.TotalMilliseconds)"
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
    $ResultsText | Out-File -Encoding utf8 "$Destination.json"
    "Compression_Results_Loaded($ResultsText)" | Out-File -Encoding utf8 "$Destination.jsonp"
}

Function Get_TestSetup{
    Param(
        $Setup,
		$SubTests,
		$Filter,
		$IncludeDisabled
    )
    $Results = @()
    foreach ($Config in $Setup) {
        if ($Config."$SubTests" -eq $null) {
			if ($Config.Disabled -and -not $IncludeDisabled) {
				continue;
			}
			if ($Filter.Length -le 0 -or $Filter -contains $Config.Id) {
                $Results += $Config
            }
            continue;
        }
        foreach ($Test in $Config."$SubTests") {
            $TestObject = $Config | Select-Object -Property * -ExcludeProperty $SubTests
            $Test.PsObject.Properties | % {
                Add-Member -InputObject $TestObject -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
            }
			if ($TestObject.Disabled -and -not $IncludeDisabled) {
				continue;
			}
     		if ($Filter.Length -le 0 -or $Filter -contains $TestObject.Id) {
                $Results += $TestObject
            }
        }
    }
    return $Results
}

$TestStart = Get-Date
Write-Host "Compression Tests Starting at $TestStart"
Write-Host

try {
    $Configuration = Get-Content -Encoding utf8 .\configuration.json | ConvertFrom-Json
    $Compressors = Get_TestSetup -Setup $Configuration.Compressors -SubTests "Tests" -Filter $SelectCompressors -IncludeDisabled $IncludeDisabled
	$Corpora = Get_TestSetup -Setup $Configuration.Corpora -SubTests "SubCorpora" -Filter $SelectCorpora -IncludeDisabled $IncludeDisabled
} catch {
    Write-Error "Failed to load test Configuration"
    Write-Debug $_
    Exit 1
}

$Results = New-Object -TypeName PSObject
foreach ($CorpusConfig in $Corpora) {
    if ($CorpusConfig.Enabled -ne $null -and $CorpusConfig.Enabled -ne 'true') {
        Write-Host "Skipping Disabled $($CorpusConfig.Label) Corpus..."
        Write-Host
        continue
    }

    $Result = Run-CompressionSuite $CorpusConfig $Compressors
    Add-Member -InputObject $Results -NotePropertyName $CorpusConfig.Id -NotePropertyValue $Result

    Write-Host "Writing Results CSV for $($CorpusConfig.Label)"
    Write_ResultsCSV $Result $OutputDir "Results_$($CorpusConfig.Id)"
    Write-Host
}
Add-Member -InputObject $Configuration -NotePropertyName Results -NotePropertyValue $Results

Write-Host "Performing Cleanup"
Remove-Item -Recurse -Force $TempDir

if ($FailedTests) {
    Write-Error "Not all Test Compressors Succeeded, Test run Failed."
    Exit 1
}

$TestComplete = Get-Date
$TestRunTime = $TestComplete - $TestStart
$BuildStats = New-Object -TypeName PSObject -Property @{
    Start = $TestStart.ToUniversalTime().ToString("O");
    Complete = $TestComplete.ToUniversalTime().ToString("O");
    RunTime = $TestRunTime.TotalMilliseconds;
    Id = $env:APPVEYOR_BUILD_ID;
    Number = $env:APPVEYOR_BUILD_NUMBER;
    Version = $env:APPVEYOR_BUILD_VERSION;
    Commit = $env:APPVEYOR_REPO_COMMIT;
    CommitAuthor = $env:APPVEYOR_REPO_COMMIT_AUTHOR;
    CommitTimestamp = $env:APPVEYOR_REPO_COMMIT_TIMESTAMP;
    CommitMessage = $env:APPVEYOR_REPO_COMMIT_MESSAGE;
}
Add-Member -InputObject $Configuration -NotePropertyName Build -NotePropertyValue $BuildStats
Write-Host "Compression Tests completed at $TestComplete"
Write-Host

Write-Host "Writing Output JSON"
Write_ResultsJSON $Configuration $OutputDir "TestResults"
Write-Host

Write-Host "Done" 