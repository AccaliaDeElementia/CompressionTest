Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

$Source = Get-Item -Path '.\Corpus\'
$Dest = Compress_7zDeflate $Source -Level 0
$Result = Analyze_Result $Dest
Write-Host $Result
Remove-Item $Dest.Result
