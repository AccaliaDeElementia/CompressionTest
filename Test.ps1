Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

# Create end results Directory
$ignored = New-Item -Type Directory Results -Force

$Source = Get-Item -Path '.\Corpus\King James.txt'

Write-Host "Performing Compression Test for $($Source.Name)"
$Results = Test_7zCompression $Source | %{Analyze_Result $_}
$Results += Test_WinRarCompression $Source | %{Analyze_Result $_}
Write-Host "Analyzing Results..."
Write_ResultsCSV $Results


Write-Host "Done"
