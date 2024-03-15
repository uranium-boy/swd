[CmdletBinding(DefaultParameterSetName='dirAlias')]
param (    
    [Parameter(ParameterSetName='set', Mandatory=$true)]
    [switch]$set,

    [Parameter(ParameterSetName='change', Mandatory=$true)]
    [switch]$change,

    [Parameter(ParameterSetName='remove')]
    [switch]$remove,

    [Parameter(ParameterSetName='set', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='change', Mandatory=$true, Position=0)]
    [string]$Path,

    [Parameter(ParameterSetName='dirAlias', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='set', Mandatory=$true, Position=1)]
    [Parameter(ParameterSetName='change', Mandatory=$true, Position=1)]
    [Parameter(ParameterSetName='remove', Mandatory=$true, Position=0)]
    [string]$aliasName,

    [Parameter(ParameterSetName='list')]
    [switch]$list
)

# $ErrorActionPreference = 'Stop'

# names of files used
$jsonFileName = 'aliases.json'
$moduleFilename = 'WriteToJson.psm1'

# getting the path of script file
$scriptDirPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# 
# setting the file path for saved data to be in the same folder as the script
$jsonFilePath = Join-Path -Path $scriptDirPath -ChildPath $jsonFileName
$modulePath = Join-Path -Path $scriptDirPath -ChildPath $moduleFilename
# $modulePath
# importing module with WriteToJson function
Import-Module $modulePath

try {
    $jsonString = Get-Content -Path $jsonFilePath -Raw -ErrorAction Stop
    $data = $jsonString | ConvertFrom-Json -AsHashtable
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "Creating aliases.json file..."
    New-Item -Path $jsonFilePath -ItemType File
} catch {
    Write-Error "The JSON file failed to open: $($_.Exception.Message)"
}


switch ($PSCmdlet.ParameterSetName) {

    # changing the working directory
    'dirAlias' {  
        try {
            if ($data.ContainsKey($aliasName)) {
                $dirPath = $data[$aliasName]
                Set-Location $dirPath
                Write-Host "Directory changed to $dirPath"
            } else {
                Write-Error "Alias '$aliasName' not found"
            }
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            
            Write-Host "Alias: $aliasName Path: $($data[$aliasName])"
            Write-Error "Path is not valid."
        }
        catch [System.Management.Automation.RuntimeException] {
            Write-Host "No aliases saved."
        }
    }

    # adding new alias to json file
    'set' {
        if ($data.Count -eq 0) {
            $data = @{}
        }

        # argument validation
        if (-Not (Test-Path -Path $Path -PathType Container) -And (Test-Path -Path $aliasName -PathType Container)) {
            $Path, $aliasName = $aliasName, $Path
            Write-Host "Argument order has been changed."
        }
        elseif (-Not (Test-Path -Path $Path -PathType Container) -And (-Not (Test-Path -Path $aliasName -PathType Container))) {
            Write-Error "The provided parameter is not a valid path."
            return
        }
        try {
            $data.Add($aliasName, $Path)    
            WriteToJson -data $data -filePath $jsonFilePath
            Write-Host "The alias '$aliasName' was successfully assigned to the $Path"  
        }
        catch [System.Management.Automation.MethodInvocationException] {
            Write-Error "Alias already exists. Use 'swd -change [path] [alias]' to change the alias."
        }
    }

    # assign an existing alias to a new path
    'change' {
        if (-Not (Test-Path -Path $Path -PathType Container) -And (Test-Path -Path $aliasName -PathType Container)) {
            $Path, $aliasName = $aliasName, $Path
            Write-Host "Argument order has been changed."
        }
        elseif (-Not (Test-Path -Path $Path -PathType Container) -And (-Not (Test-Path -Path $aliasName -PathType Container))) {
            Write-Error "The provided parameter is not a valid path."
            return
        }
        if ($data.ContainsKey($aliasName)) {
            $data[$aliasName] = $Path
            WriteToJson -data $data -filePath $jsonFilePath
            Write-Host "The alias '$aliasName' was successfully changed to the $Path" 
        } else {
            Write-Error "Alias '$aliasName' does not exist, it cannot be changed."
        }
        
    }

    # shows all saved aliases
    'list' {
        $data
    }

    'remove' {
        if ($data.ContainsKey($aliasName)) {
            $data.Remove($aliasName)
            WriteToJson -data $data -filePath $jsonFilePath
            Write-Host "Alias '$aliasName' successfully removed."
        } else {
            Write-Host "Alias '$aliasName' not found."
        }
    }

    Default {
        Write-Error "If you see this message, probably an error occurred..."
    }
}
