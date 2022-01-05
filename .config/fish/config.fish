test $TERM != "screen"; and exec tmux
set -x VIRTUALFISH_HOME /Users/nmrkic/projects/.virtualenvs
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/opt/mysql-client/bin

# eval (python -m virtualfish compat_aliases)


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
alias d-c 'docker-compose'
alias d-s 'docker stop (docker ps -q)'
alias d-u 'docker-compose up -d'
# -------------------------------------------------------------------
# K8s
# -------------------------------------------------------------------
alias kc 'kubectl'
alias kx 'kubectx'

# -------------------------------------------------------------------
# Survey Monkey docker image aliases
# -------------------------------------------------------------------
function pullimages
    APP_IMAGE=docker.t1.smapply.test:5000/smapply/smapply-app:branch-"$argv" JOBS_IMAGE=docker.t1.smapply.test:5000/smapply/smapply-jobs:branch-"$argv" docker-compose pull
end

function startimages
    APP_IMAGE=docker.t1.smapply.test:5000/smapply/smapply-app:branch-"$argv" JOBS_IMAGE=docker.t1.smapply.test:5000/smapply/smapply-jobs:branch-"$argv" docker-compose up -d
end

# Setting PATH for Python 3.10
# The original version is saved in /Users/nmrkic/.config/fish/config.fish.pysave
set -x PATH "/Library/Frameworks/Python.framework/Versions/3.10/bin" "$PATH"
