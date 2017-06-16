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

$Sources = Get-Item -Path '.\Corpus\*.txt'

foreach ($Source in $Sources) {
    Test-Source $Source $Compressors
}

$Source = Get-Item -Path './Corpus'
Test-Source $Source $Compressors

Write-Host "Generating 50MB of random binary data"
$Source = New_RandomBinaryFile "$TempDir/RandomBinary.dat" -FileSize 50mb
Test-Source $Source $Compressors 'RandomBinary'

Write-Host "Generating 50MB of random ASCII data"
$Source = New_RandomTextFile "$TempDir/RandomASCII.dat" -FileSize 50mb
Test-Source $Source $Compressors 'RandomBinary'

Remove-Item -Recurse $TempDir

Write-Host "Done"