Write-Host "Resetting Powershell Modules"
Import-Module -Force './Utilities.psm1'

# Create end results Directory
Write-Host "Resetting Temporary Directories"
Remove-Item -Recurse -Force ./Temp_*

Write-Host "Done"
