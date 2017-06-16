Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

# Create end results Directory
$OutputDir = New-Item -Type Directory Results -Force
$TempDir = New-Item -Type Directory Temp -Force

$Source = Get-Item -Path '.\Corpus\King James.txt'


$Compressors = Get_Compressors

foreach($Compressor in $Compressors) {
    if ($Source.PSIsContainer -and -not $Compressor.CanRecurse) {
        Continue
    }
    Execute_Compression $Source $TempDir $Compressor
}

#Write-Host "Performing Compression Test for $($Source.Name)"
#$Results = @()
#$Results += Test_7zCompression $Source | %{Analyze_Result $_}
#$Results += Test_WinRarCompression $Source | %{Analyze_Result $_}
#$Results += Test_BuiltinCompression $Source | %{Analyze_Result $_}
#Write-Host "Analyzing Results..."
#Write_ResultsCSV $Results


Remove-Item -Recurse $TempDir

Write-Host "Done"
