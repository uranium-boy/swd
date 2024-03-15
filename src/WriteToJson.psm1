function WriteToJson {
    param (
        [Parameter(Mandatory=$true)]
        [object]$data,

        [Parameter(Mandatory=$true)]
        [string]$filePath
    )
    try {            
        $jsonString = $data | ConvertTo-Json
        $jsonString | Out-File -FilePath $filePath -Force
        # Write-Host "File correctly overwrited"
    }
    catch {
        Write-Error "Json error: $($_.ErrorDetails.GetType().FullName)"
    }
}