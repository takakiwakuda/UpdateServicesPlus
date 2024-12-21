function Get-WsusServer {
    [CmdletBinding(DefaultParameterSetName = "DefaultServer")]
    [OutputType([Microsoft.UpdateServices.Administration.IUpdateServer])]
    param (
        [Parameter(Mandatory, ParameterSetName = "ServerSpecified", Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 260)]
        [string]
        $Name,

        [Parameter(ParameterSetName = "ServerSpecified")]
        [switch]
        $UseSsl,

        [Parameter(Mandatory, ParameterSetName = "ServerSpecified")]
        [int]
        $PortNumber
    )
}

Export-ModuleMember -Function Get-WsusServer
