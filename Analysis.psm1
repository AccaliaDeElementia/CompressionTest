Function Calculate-Size {
    Param(
        $Input
    )
    if ($Input.PSIsContainer) {
        return $Input.Length
    }
    $Size = 0
    foreach ($Item in Get-ChildItem -Recurse -Path $Input.FullName | Where-Object {$_.PSIsContainer -eq $False}) {
        $Size += $Item.Length
    }
    return $Size
}

Function Analyze_Result {
    Param(
        $Result
    )
    $InputSize = Calculate-Size $Result.Source
    $OutputSize = $Result.Result.Length

    $CompressionRatio = $InputSize / $OutputSize
    $PercentCompression = (1 - ($OutputSize / $InputSize)) * 100
    $BitsPerByte = $OutputSize * 8 / $InputSize

    $Result | Add-Member -MemberType NoteProperty -Name 'InputSize' -Value $InputSize
    $Result | Add-Member -MemberType NoteProperty -Name 'OutputSize' -Value $OutputSize
    $Result | Add-Member -MemberType NoteProperty -Name 'CompressionRatio' -Value $CompressionRatio
    $Result | Add-Member -MemberType NoteProperty -Name 'PercentCompression' -Value $PercentCompression
    $Result | Add-Member -MemberType NoteProperty -Name 'BitsPerByte' -Value $BitsPerByte
    return $Result
}

Export-ModuleMember *_*