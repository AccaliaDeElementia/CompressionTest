

Function Analyze_Result {
    Param(
        $TestItem
    )

    Write-Host $TestItem

    $CompressionRatio = $TestItem.InputSize / $TestItem.OutputSize
    $PercentCompression = (1 - ($TestItem.OutputSize / $TestItem.InputSize)) * 100
    $BitsPerByte = $TestItem.OutputSize * 8 / $TestItem.InputSize

    $Result = New-Object -TypeName PSObject -Prop (@{
        "Label"=$TestItem.Label;
        "Executable"=$TestItem.Executable;
        "Arguments"=$TestItem.Arguments
        "Input"=$TestItem.Input;
        "Output"=$TestItem.Output;
        "InputSize"=$TestItem.InputSize;
        "OutputSize"=$TestItem.OutputSize;
        "CompressionRatio"=$CompressionRatio;
        "PercentCompression"=$PercentCompression;
        "BitsPerByte"=$BitsPerByte;
    })
    return $Result
}

Export-ModuleMember *_*