if status is-interactive
	and not set -q TMUX
	and not set -q SSH_TTY
	    test $TERM != "screen"; and exec tmux
end
set -x VIRTUALFISH_HOME /home/nebojsa/projects/.virtualenvs
set -x GOPATH /home/nebojsa/projects/.go
set -x GOROOT /usr/lib/go
set -x GOBIN /home/nebojsa/projects/.go/bin
#set -x GOPATH /home/nebojsa/tools/golang_courses/workspace
set PATH $PATH ~/.local/bin
set PATH $PATH $GOPATH/bin
# set PATH $PATH ~/tools/android/tools
# set PATH $PATH ~/tools/android/tools/bin
# set ANDROID_SDK_ROOT ~/tools/android/ 

set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
status --is-interactive; and source (pyenv init --path | psub)
status --is-interactive; and source (pyenv init - | psub)

# -------------------------------------------------------------------
# directory information
# -------------------------------------------------------------------
alias lh 'ls -d .*' # show hidden files/directories only
alias lsd 'ls -aFhlG'
alias l 'ls -lah'
alias ll 'ls -lah' # Same as above, but in long listing format

# -------------------------------------------------------------------
# Git
# -------------------------------------------------------------------
alias ga 'git add'
alias gp 'git push'
alias gl 'git log'
alias gpl "git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --aliasev-commit"
alias gs 'git status'
alias gd 'git diff'
alias gm 'git commit -m'
alias gma 'git commit -am'
alias gb 'git branch'
alias gc 'git checkout'
alias gcb 'git checkout -b'
alias gra 'git remote add'
alias grr 'git remote rm'
alias gpu 'git pull'
alias gcl 'git clone'
alias gta 'git tag -a -m'
alias gf 'git reflog'
alias gv 'git log --pretty=format:'%s' | cut -d " " -f 1 | sort | uniq -c | sort -nr'
alias gmn 'git merge --no-ff'
alias gmm 'git merge'
alias gms 'git merge --squash'
alias gmt 'git mergetool'

# -------------------------------------------------------------------
# Docker
# -------------------------------------------------------------------
alias docker-compose 'docker compose'
alias d-c 'docker compose'
alias d-s 'docker stop (docker ps -q)'
alias d-u 'docker compose up -d'
# -------------------------------------------------------------------
# K8s
# -------------------------------------------------------------------
alias kc 'kubectl'
alias kx 'kubectx'
# -------------------------------------------------------------------
# Headphone aliases
# -------------------------------------------------------------------
alias WI-C100 'bluetoothctl connect 74:B7:E6:03:73:42'
alias WI-C310 'bluetoothctl connect 90:7A:58:67:88:9D'
alias touchpad_off 'xinput set-prop 17 214 0'
alias touchpad_on 'xinput set-prop 17 214 1'
