using namespace System
using namespace Microsoft.UpdateServices.Administration

class TestComputerTargetGroup : IComputerTargetGroup {
    [guid]$Id
    [string]$Name
    [string]$LastActivity
    [scriptblock] $DeleteAction

    TestComputerTargetGroup() {
        $this.Init()
    }

    TestComputerTargetGroup([scriptblock] $deleteAction) {
        $this.Init()
        $this.DeleteAction = $deleteAction
    }

    [void] Init() {
        $this.Id = [guid]::NewGuid()
        $this.Name = "test"
        $this.LastActivity = ""
    }

    [void] Delete() {
        if ($null -ne $this.DeleteAction) {
            & $this.DeleteAction
        }
        $this.LastActivity = "Delete"
    }

    #region For Windows PowerShell. You can remove this region if you don't need to support Windows PowerShell.
    [guid] get_Id() {
        return $this.Id
    }

    [string] get_Name() {
        return $this.Name
    }
    #endregion
}

class TestUpdateServer : IUpdateServer {
    [scriptblock] $CreateComputerTargetGroupAction

    TestUpdateServer() {
        $this.Init({ return [TestComputerTargetGroup]::new() })
    }

    TestUpdateServer([scriptblock] $createComputerTargetGroupAction) {
        $this.Init($createComputerTargetGroupAction)
    }

    [void] Init([scriptblock] $createComputerTargetGroupAction) {
        $this.CreateComputerTargetGroupAction = $createComputerTargetGroupAction
    }

    [IComputerTargetGroup] CreateComputerTargetGroup([string] $name) {
        return & $this.CreateComputerTargetGroupAction
    }

    [ComputerTargetGroupCollection] GetComputerTargetGroups() {
        $groups = [ComputerTargetGroupCollection]::new()
        $groups.Add([TestComputerTargetGroup]::new())

        return $groups
    }
}

function Get-TestComputerGroup {
    [TestComputerTargetGroup]::new()
}

function Get-TestComputerGroupThrowsInvalidOperationException {
    [TestComputerTargetGroup]::new({ throw [InvalidOperationException]::new() })
}

function Get-TestUpdateServer {
    [TestUpdateServer]::new()
}

function Get-TestUpdateServerThrowsArgumentException {
    [TestUpdateServer]::new({ throw [ArgumentException]::new() })
}

function Get-TestUpdateServerThrowsInvalidOperationException {
    [TestUpdateServer]::new({ throw [InvalidOperationException]::new() })
}

function Get-TestUpdateServerThrowsWsusObjectAlreadyExistsException {
    [TestUpdateServer]::new({ throw [WsusObjectAlreadyExistsException]::new() })
}
