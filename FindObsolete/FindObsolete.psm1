function Get-CommandCache
{
    if($null -eq $Script:commandMap)
    {
        $commandList = Get-Command
        $Script:commandMap = @{}
        $command = Get-Command $commandList[0]
        foreach ($command in $commandList)
        {
            $name = $command.Name
            $Script:commandMap[$name] = @{}
            foreach ($key in $command.Parameters.keys)
            {
                if ($command.Parameters[$key].Attributes | ? { $_ -is [System.ObsoleteAttribute]})
                {
                    $Script:commandMap[$name][$key] = $true
                    foreach($alias in $command.Parameters[$key].Aliases)
                    {
                        $Script:commandMap[$name][$alias] = $true
                    }
                }
            }
        }
    }
}

function Clear-ObsoleteCache
{
    $Script:commandMap = $null
}

function Find-Obsolete
{
    <#
    .SYNOPSIS
    Searches a script for use of Obsolete Parameters

    .Notes
    The first time this executes, it will cache all command info
    this can take several minutes so be patient
    #>
    [Alias('FullName')]
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline
        )]
        [String]
        $Path
    )

    begin
    {
        Write-Verbose "Gathering cached command data for obsolete parameters"
        $commandMap = Get-CommandCache
    }

    process
    {
        if ($commandMap.Count -eq 0)
        {
            Write-Verbose "Could not find any commands with obsolete parameters"
            return
        }

        Write-Debug "Resolve path [$Path]"
        $fileList = Resolve-Path -Path $Path
        foreach($file in $fileList)
        {   
            Write-Verbose "Loading data from [$file]"
            $data = Get-Content -Path $file -Raw

            try
            {
                $script = [scriptblock]::Create($Data)
            }
            catch
            {
                Write-Verbose "Unable to get scriptblock from [$Path]"
                return
            }
            $astCommandList = $script | Select-AST -Type CommandAst

            foreach ($astCommand in $astCommandList)
            {
                $name = $astCommand.CommandElements[0].Value
                if ($null -ne $name -and $commandMap[$name])
                {
                    $parameterList = $astCommand | 
                        Select-AST -Type CommandParameterAst
                    
                    foreach ($param in $parameterList)
                    {
                        if ($commandMap[$name][$param.ParameterName])
                        {
                            Write-Verbose ('obsolete [{0}][{1}] line [{2}:{3}]' -f $name,$param.ParameterName, $path, $param.extent.StartLineNumber ) -Verbose
                        }
                    }
                }
            }
        }
    }
}

