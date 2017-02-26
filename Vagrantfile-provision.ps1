Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# wrap the choco command (to make sure this script aborts when it fails).
function Start-Choco([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    for ($n = 0; $n -lt 10; ++$n) {
        if ($n) {
            # NB sometimes choco fails with "The package was not found with the source(s) listed."
            #    but normally its just really a transient "network" error.
            Write-Host "Retrying choco install..."
            Start-Sleep -Seconds 3
        }
        &C:\ProgramData\chocolatey\bin\choco.exe @Arguments `
            | Where-Object { $_ -NotMatch '^Progress: ' }
        if ($SuccessExitCodes -Contains $LASTEXITCODE) {
            return
        }
    }
    throw "$(@('choco')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
}
function choco {
    Start-Choco $Args
}

# install classic shell.
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu -Force `
    | New-ItemProperty -Name ShowedStyle2      -Value 1 -PropertyType DWORD `
    | Out-Null
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu\Settings -Force `
    | New-ItemProperty -Name EnableStartButton -Value 1 -PropertyType DWORD `
    | New-ItemProperty -Name SkipMetro         -Value 1 -PropertyType DWORD `
    | Out-Null
choco install -y classic-shell -installArgs ADDLOCAL=ClassicStartMenu

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
choco install -y googlechrome
$chromeLocation = 'C:\Program Files (x86)\Google\Chrome\Application'
cp -Force c:/vagrant/Vagrantfile-GoogleChrome-external_extensions.json (Get-Item "$chromeLocation\*\default_apps\external_extensions.json").FullName
cp -Force c:/vagrant/Vagrantfile-GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force c:/vagrant/Vagrantfile-GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# install other useful applications and dependencies.
choco install -y notepad2
choco install -y baretail
choco install -y --allow-empty-checksums dependencywalker
choco install -y procexp
choco install -y phantomjs
choco install -y innosetup
# for building the setup-helper.dll we need the 32-bit version
# of the win32 libraries, for having them we have to force the
# installation of the 32-bit mingw package.
$env:chocolateyForceX86 = 'true'
choco install -y mingw -params '/threads:win32'
del env:chocolateyForceX86
choco install -y git --params '/GitOnlyOnPath /NoAutoCrlf'
choco install -y gitextensions
choco install -y meld

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# configure git.
# see http://stackoverflow.com/a/12492094/477532
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global push.default simple
git config --global diff.guitool meld
git config --global difftool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global difftool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$REMOTE\"'
git config --global merge.tool meld
git config --global mergetool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global mergetool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" --diff \"$LOCAL\" \"$BASE\" \"$REMOTE\" --output \"$MERGED\"'
#git config --list --show-origin

# install msys2.
# NB we have to manually build the msys2 package from source because the
#    current chocolatey package is somewhat brittle to install.
Push-Location $env:TEMP
$p = Start-Process git clone,https://github.com/rgl/choco-packages -PassThru -Wait
if ($p.ExitCode) {
    throw "git failed with exit code $($p.ExitCode)"
}
cd choco-packages/msys2
choco pack
choco install -y msys2 -Source $PWD
Pop-Location

# configure the msys2 launcher to let the shell inherith the PATH.
$msys2BasePath = 'C:\tools\msys64'
$msys2ConfigPath = "$msys2BasePath\msys2.ini"
[IO.File]::WriteAllText(
    $msys2ConfigPath,
    ([IO.File]::ReadAllText($msys2ConfigPath) `
        -replace '#?(MSYS2_PATH_TYPE=).+','$1inherit')
)

# define a function for easying the execution of bash scripts.
$bashPath = "$msys2BasePath\usr\bin\bash.exe"
function Bash($script) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        echo 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH";export HOME=/c/Users/vagrant;' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# install the remaining dependencies.
Bash 'pacman --noconfirm -Sy make unzip tar dos2unix'

# configure the shell.
Bash @'
pacman --noconfirm -Sy vim

cat>~/.bash_history<<"EOF"
cd /c/vagrant
cd /c/vagrant && make clean all
make clean all
tail -f /c/Program\ Files/Elasticsearch/logs/elasticsearch.log
net start elasticsearch
curl localhost:9200/_cluster/state?pretty
curl localhost:9200/_cluster/health?pretty
curl localhost:9200/_cluster/pending_tasks?pretty
curl localhost:9200/_cat/indices?v
net stop elasticsearch
EOF

cat>~/.bashrc<<"EOF"
# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

export EDITOR=vim
export PAGER=less

alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat>~/.inputrc<<"EOF"
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

cat>~/.vimrc<<"EOF"
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup

autocmd BufNewFile,BufRead Vagrantfile set ft=ruby
autocmd BufNewFile,BufRead *.config set ft=xml

" Usefull setting for working with Ruby files.
autocmd FileType ruby set tabstop=2 shiftwidth=2 smarttab expandtab softtabstop=2 autoindent
autocmd FileType ruby set smartindent cinwords=if,elsif,else,for,while,try,rescue,ensure,def,class,module

" Usefull setting for working with Python files.
autocmd FileType python set tabstop=4 shiftwidth=4 smarttab expandtab softtabstop=4 autoindent
" Automatically indent a line that starts with the following words (after we press ENTER).
autocmd FileType python set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class

" Usefull setting for working with Go files.
autocmd FileType go set tabstop=4 shiftwidth=4 smarttab expandtab softtabstop=4 autoindent
" Automatically indent a line that starts with the following words (after we press ENTER).
autocmd FileType go set smartindent cinwords=if,else,switch,for,func
EOF
'@

# install ConEmu
choco install -y conemu
cp C:\vagrant\Vagrantfile-ConEmu.xml $env:APPDATA\ConEmu.xml
reg import C:\vagrant\Vagrantfile-ConEmu.reg

# install vscode.
choco install -y visualstudiocode -params '/NoDesktopIcon /NoQuicklaunchIcon'

# build the setup.
Bash 'cd /c/vagrant && make clean all'

# install elasticsearch.
Start-Process `
    (dir C:\vagrant\elasticsearch-*-setup*.exe).FullName `
    '/VERYSILENT','/SUPPRESSMSGBOXES' `
    -Wait
# install plugins.
function Install-ElasticsearchPlugin($name) {
    cmd /C "call ""C:\Program Files\Elasticsearch\bin\elasticsearch-plugin.bat"" install --silent $name"
    if ($LASTEXITCODE) {
        throw "failed to install Elasticsearch plugin $name with exit code $LASTEXITCODE"
    }
}
Install-ElasticsearchPlugin 'ingest-attachment'
# start it.
Start-Service elasticsearch

# remove the default desktop shortcuts.
del C:\Users\Public\Desktop\*.lnk

# add MSYS2 shortcut to the Desktop and Start Menu.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\MSYS2 Bash.lnk" `
  -TargetPath 'C:\Program Files\ConEmu\ConEmu64.exe' `
  -Arguments '-run {MSYS2} -icon C:\tools\msys64\msys2.ico' `
  -IconLocation C:\tools\msys64\msys2.ico `
  -WorkingDirectory $env:USERPROFILE
Install-ChocolateyShortcut `
  -ShortcutFilePath "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\MSYS2 Bash.lnk" `
  -TargetPath 'C:\Program Files\ConEmu\ConEmu64.exe' `
  -Arguments '-run {MSYS2} -icon C:\tools\msys64\msys2.ico' `
  -IconLocation C:\tools\msys64\msys2.ico `
  -WorkingDirectory $env:USERPROFILE

# add Services shortcut to the Desktop.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
  -TargetPath "$env:windir\system32\services.msc" `
  -Description 'Windows Services'

# add Elasticsearch shortcut to the Desktop.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\Elasticsearch.lnk" `
  -TargetPath 'C:\Program Files\Elasticsearch' `
  -Description 'Elasticsearch installation directory'

# add Local Elasticsearch HTTP endpoint shortcut to the Desktop.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\Elasticsearch Endpoint.lnk" `
  -TargetPath 'http://localhost:9200' `
  -IconLocation 'C:\vagrant\elasticsearch.ico' `
  -Description 'Local Elasticsearch HTTP endpoint'

# add Elasticsearch Logs shortcut to the Desktop.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\Elasticsearch Logs.lnk" `
  -TargetPath 'C:\ProgramData\chocolatey\lib\baretail\tools\baretail.exe' `
  -Arguments '"C:\Program Files\Elasticsearch\logs\elasticsearch.log"' `
  -Description 'Local Elasticsearch HTTP endpoint'

# enable show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show protected operating system files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSuperHidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null

# never combine the taskbar buttons.
#
# possibe values:
#   0: always combine and hide labels (default)
#   1: combine when taskbar is full
#   2: never combine
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 2
