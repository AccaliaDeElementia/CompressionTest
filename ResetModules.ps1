Write-Host "Resetting Powershell modules"
Import-Module -Force './Utilities.psm1'
Import-Module -Force './Compressors.psm1'
Import-Module -Force './Analysis.psm1'

# Create end results Directory
$TempDir = New-Item -Type Directory Temp -Force
Remove-Item -Recurse $TempDir

Write-Host "Done"
