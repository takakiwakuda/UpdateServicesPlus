function Get-WsusComputerGroup {
    [CmdletBinding()]
    [OutputType([Microsoft.UpdateServices.Administration.IComputerTargetGroup])]
    param (
        [Parameter(ValueFromPipeline)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        $UpdateServer
    )

    process {
        if ($null -eq $UpdateServer) {
            $UpdateServer = Get-WsusServer
        }
        $UpdateServer.GetComputerTargetGroups()
    }
}

function New-WsusComputerGroup {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([Microsoft.UpdateServices.Administration.IComputerTargetGroup])]
    param (
        [Parameter(ValueFromPipeline)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        $UpdateServer,

        [Parameter(Mandatory)]
        [ValidateLength(1, 256)]
        [string]
        $Name
    )

    process {
        if ($null -eq $UpdateServer) {
            $UpdateServer = Get-WsusServer
        }

        if ($PSCmdlet.ShouldProcess($Name, "Create computer target group")) {
            try {
                $UpdateServer.CreateComputerTargetGroup($Name)
            } catch [System.ArgumentException] {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception,
                    "InvalidName",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Name
                )

                $PSCmdlet.WriteError($errorRecord)
            } catch [System.InvalidOperationException] {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception,
                    "CreateWsusComputerTargetGroupFailed",
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $UpdateServer
                )

                $PSCmdlet.WriteError($errorRecord)
            } catch [Microsoft.UpdateServices.Administration.WsusObjectAlreadyExistsException] {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception,
                    "WsusComputerTargetGroupAlreadyExist",
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Name
                )

                $PSCmdlet.WriteError($errorRecord)
            }
        }
    }
}

function Remove-WsusComputerGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.UpdateServices.Administration.IComputerTargetGroup]
        $ComputerTargetGroup
    )

    process {
        if ($PSCmdlet.ShouldProcess($ComputerTargetGroup.Name, "Delete computer target group")) {
            try {
                $ComputerTargetGroup.Delete()
            } catch [System.InvalidOperationException] {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception,
                    "DeleteWsusComputerTargetGroupFailed",
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $ComputerTargetGroup
                )

                $PSCmdlet.WriteError($errorRecord)
            }
        }
    }
}

Export-ModuleMember -Function Get-WsusComputerGroup, New-WsusComputerGroup, Remove-WsusComputerGroup
