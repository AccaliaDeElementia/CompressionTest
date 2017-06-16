Import-Module ".\Compressors.psm1"
Import-Module ".\Analysis.psm1"
Import-Module ".\Utilities.psm1"


# Create end results Directory
$OutputDir = New-Item -Type Directory Results -Force
$TempDir = New-Item -Type Directory Temp -Force

Function Test-Source {
    Param(
        $Source,
        $Compressors,
        $Label = $Source.BaseName.Replace(' ', '_')
    )

    Write-Host "Performing Compression Test for $Label"

    $Results = @()
    foreach($Compressor in $Compressors) {
        if ($Source.PSIsContainer -and -not $Compressor.CanRecurse) {
            Continue
        }
        $Results += Execute_Compression $Source $TempDir $Compressor | %{Analyze_Result $_}
    }

    Write-Host "Analyzing Results..."
    Write_ResultsCSV $Results $OutputDir "Results_$Label"
}


$Compressors = Get_Compressors

# Disable Individual Text File Tests. They took too long to run in CI and were not very valuable
#$Sources = Get-Item -Path '.\Corpus\*.txt'
#
#foreach ($Source in $Sources) {
#    Test-Source $Source $Compressors
#}

$Source = Get-Item -Path './Corpus'
Test-Source $Source $Compressors

Write-Host "Generating 10MB of Random Binary Data..."
$TimeData = Measure-Command {$Source = New_RandomBinaryFile "$TempDir/RandomBinary.dat" -FileSize 10mb}
Write-Host "Generated in $($TimeData.TotalSeconds)s"
Test-Source $Source $Compressors

Write-Host "Generating 10MB of Random ASCII Data"
$TimeData = Measure-Command {$Source = New_RandomTextFile "$TempDir/RandomASCII.dat" -FileSize 10mb}
Write-Host "Generated in $($TimeData.TotalSeconds)s"
Test-Source $Source $Compressors

Write-Host "Fetching jQuery Source"
$Source = New-Item -ItemType Directory "$TempDir/jquery"
$TimeData = Measure-Command {git clone https://github.com/jquery/jquery.git $Source}
Write-Host "Source fetched in $($TimeData.TotalSeconds)s"
Test-Source $Source $Compressors

Remove-Item -Recurse -Force $TempDir

Write-Host "Done"