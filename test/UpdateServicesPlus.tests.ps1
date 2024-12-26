[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param ()

BeforeDiscovery {
    Import-Module "$PSScriptRoot/stub/UpdateServices/bin/Debug/net462/UpdateServices.psd1"
    Import-Module "$PSScriptRoot/../src/UpdateServicesPlus.psd1"
    Import-Module "$PSScriptRoot/Helper.psm1"
}

Describe "UpdateServicesPlus" {
    BeforeAll {
        function Assert-ComputerGroup {
            param (
                [Parameter(Mandatory, ValueFromPipeline)]
                [AllowNull()]
                [Microsoft.UpdateServices.Administration.IComputerTargetGroup[]]
                $Groups,

                [Parameter(Position = 0)]
                [string]
                $Name = "test",

                [Parameter(Position = 1)]
                [guid]
                $Id = [guid]::Empty
            )

            $Groups | Should -BeOfType Microsoft.UpdateServices.Administration.IComputerTargetGroup
            if ($Id -eq [guid]::Empty) {
                $Groups.Id | Should -Not -Be $Id
            } else {
                $Groups.Id | Should -Be $Id
            }
            $Groups.Name | Should -Be $Name
        }

        $GetWsusServerMock = @{
            CommandName = "Get-WsusServer"
            MockWith    = { Get-TestUpdateServer }
            ModuleName  = "UpdateServicesPlus"
        }
    }

    Context "Get-WsusComputerGroup" {
        It "Throws an exception if the WSUS computer group with the specified ID does not exist" {
            $targetGroupId = [guid]::Empty
            Mock @GetWsusServerMock -Verifiable

            $er = { Get-WsusComputerGroup -TargetGroupId $targetGroupId -ErrorAction Stop } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType Microsoft.UpdateServices.Administration.WsusObjectNotFoundException
            $er.ErrorDetails.Message | Should -Be "Cannot find the WSUS computer group with the specified ID '$targetGroupId'."
            $er.FullyQualifiedErrorId | Should -Be "WsusComputerTargetGroupNotFound,Get-WsusComputerGroup"
            $er.TargetObject | Should -Be $targetGroupId
            $er.CategoryInfo.Category | Should -Be ObjectNotFound
            Should -InvokeVerifiable
        }

        It "Gets WSUS computer groups on the default update server" {
            Mock @GetWsusServerMock -Verifiable

            Get-WsusComputerGroup | Assert-ComputerGroup
            Should -InvokeVerifiable
        }

        It "Gets WSUS computer groups with the specified update server" {
            $server = Get-TestUpdateServer

            Get-WsusComputerGroup -UpdateServer $server | Assert-ComputerGroup
        }

        It "Gets WSUS computer groups from the piped update server" {
            Get-TestUpdateServer | Get-WsusComputerGroup | Assert-ComputerGroup
        }

        It "Gets WSUS computer group with the specified ID" {
            Mock @GetWsusServerMock -Verifiable

            Get-WsusComputerGroup -TargetGroupId $TestTargetGroupId | Assert-ComputerGroup -Id $TestTargetGroupId
            Should -InvokeVerifiable
        }

        It "Gets WSUS computer groups with the specified update server and ID" {
            $params = @{ UpdateServer = Get-TestUpdateServer; TargetGroupId = $TestTargetGroupId }

            Get-WsusComputerGroup @params | Assert-ComputerGroup -Id $TestTargetGroupId
        }

        It "Gets WSUS computer groups with the specified ID from the piped update server" {
            Get-TestUpdateServer | Get-WsusComputerGroup -TargetGroupId $TestTargetGroupId | Assert-ComputerGroup -Id $TestTargetGroupId
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
            $name = "existing group"
            $params = @{ UpdateServer = $server; Name = $name; ErrorAction = "Stop" }

            $er = { New-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType Microsoft.UpdateServices.Administration.WsusObjectAlreadyExistsException
            $er.FullyQualifiedErrorId | Should -Be "WsusComputerTargetGroupAlreadyExist,New-WsusComputerGroup"
            $er.TargetObject | Should -Be $name
            $er.CategoryInfo.Category | Should -Be ResourceExists
        }

        It "Creates a WSUS computer group on the default update server" {
            Mock @GetWsusServerMock -Verifiable
            $name = "group01"

            New-WsusComputerGroup -Name $name | Assert-ComputerGroup $name
            Should -InvokeVerifiable
        }

        It "Creates a WSUS computer group with the specified update server" {
            $server = Get-TestUpdateServer
            $name = "group02"

            New-WsusComputerGroup -UpdateServer $server -Name $name | Assert-ComputerGroup $name
        }

        It "Creates a WSUS computer group from the piped update server" {
            $name = "group03"

            Get-TestUpdateServer | New-WsusComputerGroup -Name $name | Assert-ComputerGroup $name
        }

        It "Show a message without creating a WSUS computer group" {
            Mock @GetWsusServerMock -Verifiable

            New-WsusComputerGroup -Name "do not create" -WhatIf | Should -BeNullOrEmpty
            Should -InvokeVerifiable
        }
    }

    Context "Remove-WsusComputerGroup" {
        It "Throws an exception when removing an invalid WSUS computer group" {
            $group = Get-TestComputerGroupThrowsInvalidOperationException
            $params = @{ TargetGroup = $group; ErrorAction = "Stop" }

            $er = { Remove-WsusComputerGroup @params } | Should -Throw -PassThru
            $er.Exception | Should -BeOfType System.InvalidOperationException
            $er.FullyQualifiedErrorId | Should -Be "DeleteWsusComputerTargetGroupFailed,Remove-WsusComputerGroup"
            $er.TargetObject | Should -Be $group
            $er.CategoryInfo.Category | Should -Be InvalidOperation
            $group.LastActivity | Should -BeNullOrEmpty
        }

        It "Removes a WSUS computer group" {
            $group = Get-TestComputerGroup

            { Remove-WsusComputerGroup -TargetGroup $group -ErrorAction Stop } | Should -Not -Throw
            $group.LastActivity | Should -Be "Delete"
        }

        It "Removes a WSUS computer group from the piped computer target group" {
            $group = Get-TestComputerGroup

            { $group | Remove-WsusComputerGroup -ErrorAction Stop } | Should -Not -Throw
            $group.LastActivity | Should -Be "Delete"
        }

        It "Shows a message without removing a WSUS computer group" {
            $group = Get-TestComputerGroup

            { Remove-WsusComputerGroup -TargetGroup $group -WhatIf } | Should -Not -Throw
            $group.LastActivity | Should -BeNullOrEmpty
        }
    }
}
