[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param ()

BeforeDiscovery {
    Import-Module "$PSScriptRoot/stub/UpdateServices/bin/Debug/net462/UpdateServices.psd1"
    Import-Module "$PSScriptRoot/../src/UpdateServicesPlus.psd1"
    Import-Module "$PSScriptRoot/Helper.psm1"
}

Describe "UpdateServicesPlus" {
    BeforeAll {
        function Assert-Result {
            param (
                [Parameter(Mandatory, ValueFromPipeline)]
                [AllowNull()]
                [Microsoft.UpdateServices.Administration.IComputerTargetGroup[]]
                $Groups
            )

            $Groups | Should -BeOfType Microsoft.UpdateServices.Administration.IComputerTargetGroup
            $Groups.Id | Should -Not -Be ([guid]::Empty)
            $Groups.Name | Should -Be test
        }

        $GetWsusServerMock = @{
            CommandName = "Get-WsusServer"
            MockWith    = { Get-TestUpdateServer }
            ModuleName  = "UpdateServicesPlus"
        }
    }

    Context "Get-WsusComputerGroup" {
        It "Gets WSUS computer groups on the default update server" {
            Mock @GetWsusServerMock -Verifiable

            Get-WsusComputerGroup | Assert-Result
            Should -InvokeVerifiable
        }

        It "Gets WSUS computer groups with the specified update server" {
            $server = Get-TestUpdateServer

            Get-WsusComputerGroup -UpdateServer $server | Assert-Result
        }

        It "Gets WSUS computer groups from the piped update server" {
            Get-TestUpdateServer | Get-WsusComputerGroup | Assert-Result
        }
    }

    Context "New-WsusComputerGroup" {
        It "Throws an exception if the specified name is too long" {
            $er = { New-WsusComputerGroup -Name ("a" * 257) } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType System.Management.Automation.ParameterBindingException
            $er.FullyQualifiedErrorId | Should -Be "ParameterArgumentValidationError,New-WsusComputerGroup"
            $er.CategoryInfo.Category | Should -Be InvalidData
        }

        It "Throws an exception if the specified name contains an invalid character" {
            $server = Get-TestUpdateServerThrowsArgumentException
            $name = "invalid@name" # @ is an invalid character
            $params = @{ UpdateServer = $server; Name = $name; ErrorAction = "Stop" }

            $er = { New-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType System.ArgumentException
            $er.FullyQualifiedErrorId | Should -Be "InvalidName,New-WsusComputerGroup"
            $er.TargetObject | Should -Be $name
            $er.CategoryInfo.Category | Should -Be InvalidArgument
        }

        It "Throws an exception if the specified server is a replica update server" {
            $server = Get-TestUpdateServerThrowsInvalidOperationException
            $params = @{ UpdateServer = $server; Name = "test"; ErrorAction = "Stop" }

            $er = { New-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType System.InvalidOperationException
            $er.FullyQualifiedErrorId | Should -Be "CreateWsusComputerTargetGroupFailed,New-WsusComputerGroup"
            $er.TargetObject | Should -Be $server
            $er.CategoryInfo.Category | Should -Be InvalidOperation
        }

        It "Throws an exception if a WSUS computer group already exists" {
            $server = Get-TestUpdateServerThrowsWsusObjectAlreadyExistsException
            $name = "test"
            $params = @{ UpdateServer = $server; Name = $name; ErrorAction = "Stop" }

            $er = { New-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType Microsoft.UpdateServices.Administration.WsusObjectAlreadyExistsException
            $er.FullyQualifiedErrorId | Should -Be "WsusComputerTargetGroupAlreadyExist,New-WsusComputerGroup"
            $er.TargetObject | Should -Be $name
            $er.CategoryInfo.Category | Should -Be ResourceExists
        }

        It "Creates a WSUS computer group on the default update server" {
            Mock @GetWsusServerMock -Verifiable

            New-WsusComputerGroup -Name test | Assert-Result
            Should -InvokeVerifiable
        }

        It "Creates a WSUS computer group with the specified update server" {
            $server = Get-TestUpdateServer

            New-WsusComputerGroup -UpdateServer $server -Name test | Assert-Result
        }

        It "Creates a WSUS computer group from the piped update server" {
            Get-TestUpdateServer | New-WsusComputerGroup -Name test | Assert-Result
        }

        It "Show a message without creating a WSUS computer group" {
            Mock @GetWsusServerMock -Verifiable

            New-WsusComputerGroup -Name test -WhatIf | Should -BeNullOrEmpty
            Should -InvokeVerifiable
        }
    }

    Context "Remove-WsusComputerGroup" {
        It "Throws an exception when removing an invalid WSUS computer group" {
            $group = Get-TestComputerGroupThrowsInvalidOperationException
            $params = @{ ComputerTargetGroup = $group; ErrorAction = "Stop" }

            $er = { Remove-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType System.InvalidOperationException
            $er.FullyQualifiedErrorId | Should -Be "DeleteWsusComputerTargetGroupFailed,Remove-WsusComputerGroup"
            $er.TargetObject | Should -Be $group
            $er.CategoryInfo.Category | Should -Be InvalidOperation
            $group.LastActivity | Should -BeNullOrEmpty
        }

        It "Removes a WSUS computer group" {
            $group = Get-TestComputerGroup

            { Remove-WsusComputerGroup -ComputerTargetGroup $group -ErrorAction Stop } | Should -Not -Throw
            $group.LastActivity | Should -Be "Delete"
        }

        It "Removes a WSUS computer group from the piped computer target group" {
            $group = Get-TestComputerGroup

            { $group | Remove-WsusComputerGroup -ErrorAction Stop } | Should -Not -Throw
            $group.LastActivity | Should -Be "Delete"
        }

        It "Shows a message without removing a WSUS computer group" {
            $group = Get-TestComputerGroup

            { Remove-WsusComputerGroup -ComputerTargetGroup $group -WhatIf } | Should -Not -Throw
            $group.LastActivity | Should -BeNullOrEmpty
        }
    }
}
