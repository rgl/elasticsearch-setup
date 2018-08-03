Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}

# wrap the choco command (to make sure this script aborts when it fails).
function Start-Choco([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    $command, $commandArguments = $Arguments
    if ($command -eq 'install') {
        $Arguments = @($command, '--no-progress') + $commandArguments
    }
    for ($n = 0; $n -lt 10; ++$n) {
        if ($n) {
            # NB sometimes choco fails with "The package was not found with the source(s) listed."
            #    but normally its just really a transient "network" error.
            Write-Host "Retrying choco install..."
            Start-Sleep -Seconds 3
        }
        &C:\ProgramData\chocolatey\bin\choco.exe @Arguments
        if ($SuccessExitCodes -Contains $LASTEXITCODE) {
            return
        }
    }
    throw "$(@('choco')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
}
function choco {
    Start-Choco $Args
}

Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1

Write-Output "Installing Kibana..."
Push-Location $env:TEMP
$p = Start-Process git clone,https://github.com/rgl/kibana-chocolatey-package -PassThru -Wait
if ($p.ExitCode) {
    throw "git failed with exit code $($p.ExitCode)"
}
cd kibana-chocolatey-package
choco pack
choco install -y nssm
choco install -y kibana -Source $PWD
Pop-Location

$kibanaHome = "$env:ChocolateyInstall\lib\kibana\kibana"
$serviceName = 'kibana'
$serviceUsername = "NT SERVICE\$serviceName"
Write-Output "Modifying the $serviceName service to use the $serviceUsername managed service account instead of LocalSystem..."
$result = sc.exe sidtype $serviceName unrestricted
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe sidtype failed with $result"
}
$result = sc.exe config $serviceName obj= $serviceUsername
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}
$result = sc.exe failure $serviceName reset= 0 actions= restart/1000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure failed with $result"
}
$result = sc.exe config $serviceName start= auto
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}

Write-Output "Modifying the $serviceName service to write the kibana output into a log file..."
nssm set $serviceName AppRotateFiles 1
nssm set $serviceName AppRotateOnline 1
nssm set $serviceName AppRotateSeconds 86400
nssm set $serviceName AppRotateBytes (10*1024*1024)
nssm set $serviceName AppStdout $kibanaHome\logs\service-stdout.log
nssm set $serviceName AppStderr $kibanaHome\logs\service-stderr.log

choco install -y carbon
Update-SessionEnvironment

Write-Output "Granting write permissions to selected directories...."
@('optimize', 'data', 'logs') | ForEach-Object {
    $path = "$kibanaHome\$_"
    mkdir -Force $path | Out-Null
    Disable-AclInheritance $path
    'Administrators',$serviceUsername | ForEach-Object {
        Write-Host "Granting $_ FullControl to $path..."
        Grant-Permission `
            -Identity $_ `
            -Permission FullControl `
            -Path $path
    }
}

Write-Output "Starting the $serviceName service..."
Start-Service $serviceName

# add Local Kibana shortcut to the Desktop.
[IO.File]::WriteAllText(
    "$env:USERPROFILE\Desktop\Kibana.url",
    @"
[InternetShortcut]
URL=http://localhost:5601
"@)
