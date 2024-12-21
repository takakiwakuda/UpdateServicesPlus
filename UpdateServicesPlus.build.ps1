[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("Core", "Desktop")]
    [string]
    $Edition
)

if ($Edition.Length -eq 0) {
    $Edition = $PSEdition
}

task RunTest {
    $command = "Invoke-Pester -Path '$PSScriptRoot\test\UpdateServicesPlus.Tests.ps1'"

    switch ($Edition) {
        "Core" {
            pwsh -nop -c $command
        }
        "Desktop" {
            powershell -NoProfile -Command $command
        }
    }
}

task . RunTest
