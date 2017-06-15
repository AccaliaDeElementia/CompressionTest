Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

$Source = Get-Item -Path '.\Corpus\King James.txt'
$Dest = Compress_7z $Source
$Result = $Dest | Where-Object {$_ -ne $null} | %{Analyze_Result $_ $False}
$ignored = New-Item -Type Directory Results -Force
Write-Host "Analyzing Results..."
Write_ResultsCSV $Result
Write-Host "Done"
