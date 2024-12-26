function Get-WsusComputerGroup {
    [CmdletBinding(DefaultParameterSetName = "AllTargetGroups")]
    [OutputType([Microsoft.UpdateServices.Administration.IComputerTargetGroup])]
    param (
        [Parameter(ValueFromPipeline)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        $UpdateServer,

        [Parameter(Mandatory, ParameterSetName = "ID")]
        [guid]
        $TargetGroupId
    )

    process {
        if ($null -eq $UpdateServer) {
            $UpdateServer = Get-WsusServer
        }

        if ($PSCmdlet.ParameterSetName -eq "ID") {
            Get-ComputerGroupWithId -UpdateServer $UpdateServer -Id $TargetGroupId
        } else {
            $UpdateServer.GetComputerTargetGroups()
        }
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

#region Utility functions
function Get-ComputerGroupWithId {
    [OutputType([Microsoft.UpdateServices.Administration.IComputerTargetGroup])]
    param (
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        $UpdateServer,

        [guid]
        $Id
    )

    try {
        $UpdateServer.GetComputerTargetGroup($Id)
    } catch [Microsoft.UpdateServices.Administration.WsusObjectNotFoundException] {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $_.Exception,
            "WsusComputerTargetGroupNotFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $Id
        )
        $message = "Cannot find the WSUS computer group with the specified ID '{0}'." -f $Id
        $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($message)

        $PSCmdlet.WriteError($errorRecord)
    }
}
#endregion

Export-ModuleMember -Function Get-WsusComputerGroup, New-WsusComputerGroup, Remove-WsusComputerGroup
