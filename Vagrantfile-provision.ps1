$ErrorActionPreference = 'Stop'

# install useful applications and dependencies.
choco install -y googlechrome
choco install -y notepad2
choco install -y baretail
choco install -y --allow-empty-checksums dependencywalker
choco install -y procexp
choco install -y phantomjs
choco install -y --allow-empty-checksums innosetup
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

# we have to manually build another version of the msys2 package
# because the current one is broken.
Push-Location $env:TEMP
$p = Start-Process git 'clone','-b','update_to_20160719','https://github.com/petemounce/choco-packages' -PassThru -Wait
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
        echo 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH"' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# install the remaining dependencies.
Bash 'pacman --noconfirm -Sy make unzip tar'

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

# build the setup.
Bash 'cd /c/vagrant && make clean all'

# install and start elasticsearch.
Start-Process `
    (dir C:\vagrant\elasticsearch-*-setup*.exe).FullName `
    '/VERYSILENT','/SUPPRESSMSGBOXES' `
    -Wait
net start elasticsearch

# remove the default desktop shortcuts.
del C:\Users\Public\Desktop\*.lnk

# add MSYS2 shortcut to the Desktop and Start Menu.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\MSYS2 Bash.lnk" `
  -TargetPath "$msys2BasePath\msys2.exe"
Install-ChocolateyShortcut `
  -ShortcutFilePath "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\MSYS2 Bash.lnk" `
  -TargetPath "$msys2BasePath\msys2.exe"

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

# never combine the taskbar buttons.
#
# possibe values:
#   0: always combine and hide labels (default)
#   1: combine when taskbar is full
#   2: never combine
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 2
