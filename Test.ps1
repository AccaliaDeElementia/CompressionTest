Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

$Source = Get-Item -Path '.\Corpus\King James.txt'
$Dest = Compress_7z $Source
$Result = $Dest | %{ Analyze_Result $_ $False}
Write-Host $Result
#Remove-Item $Dest.Result
