

Function Analyze_Result {
    Param(
        $TestItem
    )

    $CompressionRatio = $TestItem.InputSize / $TestItem.OutputSize
    $PercentCompression = (1 - ($TestItem.OutputSize / $TestItem.InputSize)) * 100
    $BitsPerByte = $TestItem.OutputSize * 8 / $TestItem.InputSize

    $Result = New-Object -TypeName PSObject -Property @{
        Label=$TestItem.Label;
        Executable=$TestItem.Executable;
        Arguments=$TestItem.Arguments
        Input=$TestItem.Input;
        Output=$TestItem.Output;
        InputSize=$TestItem.InputSize;
        OutputSize=$TestItem.OutputSize;
        CompressionRatio=$CompressionRatio;
        PercentCompression = $PercentCompression;
        BitsPerByte = $BitsPerByte;
        ExecutionTime = $TestItem.ExecutionTime;
    }
    return $Result
}

Function Write_ResultsCSV {
    Param(
        $Results,
        $Filename = 'CompressionResults.csv',
        $SortByRatio = $true
    )
    $Results = $Results | Sort-Object @{Expression = "CompressionRatio"; Descending = $true}, @{Expression = "ExecutionTime"}

    $OutputPath = (Resolve-Path '.').Path + '\Results\' + $Filename
    $Results | Export-Csv -Path $OutputPath -NoTypeInformation
}

Export-ModuleMember *_*