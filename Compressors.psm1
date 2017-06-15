Function Format-Result {
    Param(
        $Source,
        $Result,
        $Command,
        $Arguments
    )
    return New-Object -TypeName PSObject -Prop (@{
        "Source"=$Source;
        "Result"=$Result;
        "Command"=$Command;
        "Arguments"=$Arguments
    })
}

Function Compress-7z {
    Param(
        $Target,
        [string]$Dest,
        [string]$Type,
        [string]$Mode,
        [int]$Level=9
    )
    $ArchiveType = '-t' + $Type
    $ArchiveMode = '-m0=' + $Mode
    $CompressionLevel = '-mx=' + $Level
    $Arguments = "$ArchiveType $ArchiveMode $CompressionLevel"
    $stdout = 7z a $ArchiveType $ArchiveMode $CompressionLevel $Dest $Target.FullName
    $archive = Get-Item $Dest
    return Format-Result $Target $archive '7z' $Arguments
}

Function Compress_7zLZMA {
    Param(
        $Target,
        [string]$Path = (Resolve-Path '.').Path,
        [string]$FileName = [guid]::NewGuid().Guid + '.7z',
        [int]$Level=9
    )
    $Dest = $($Path + '\' + $FileName)
    return Compress-7z $Target $Dest '7z' 'LZMA' $Level
}

Function Compress_7zDeflate {
    Param(
        $Target,
        [string]$Path = (Resolve-Path '.').Path,
        [string]$FileName = [guid]::NewGuid().Guid + '.7z',
        [int]$Level=9
    )
    $Dest = $($Path + '\' + $FileName)
    return Compress-7z $Target $Dest '7z' 'Deflate64' $Level
}

Export-ModuleMember *_*