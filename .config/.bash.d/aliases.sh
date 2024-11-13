######################
# SETTING UP ALIASES #
######################
alias sudo='sudo '
alias rm='rm -i' # Ask before removing file
alias mv='mv -i' # Ask before moving file
alias mkdir='mkdir -p'
alias ll='ls -alF'
alias la='ls -a'
alias cp="cp -i" # Confirm before overwriting something
alias df='df -h' # Human-readable sizes
alias ..="cd ..;pwd"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    if test -r $HOME/.dircolors; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# apt is nala if nala is installed
if [ -x /usr/bin/apt ] && [ -x /usr/bin/nala ]; then
    alias apt='nala'
fi
