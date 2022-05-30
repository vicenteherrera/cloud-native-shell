if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Installed programs configurations -----------------------------------------

## Starship
starship init fish | source

## Local Python/PIP3 binary path
set -x PATH "$HOME/.local/bin:$PATH"

## Go
set -x GOPATH "$HOME/.go/"
set -x PATH "$GOPATH/bin:/usr/local/go/bin:$PATH"

## Kubectl, Kubectx, Kubens, Krew
alias k kubectl
set -gx PATH $PATH $HOME/.krew/bin

## Ruby
set -x GEM_PATH "$HOME/.gem/bin"
set -x GEM_HOME "$HOME/.gem"
set -x PATH "$HOME/.gem/bin:$PATH"

## npm
set -x PATH "$HOME/node_modules/.bin:$PATH"

## Dot Net
set -x DOTNET_CLI_TELEMETRY_OPTOUT 1

## direnv
eval (direnv hook fish)

## batcat
alias bat "batcat"

## The F*ck
thefuck --alias | source
alias please fuck

# ## PyEnv
set -x PYENV_ROOT "$HOME/.pyenv"
set -x PATH "$PYENV_ROOT/bin:$PATH"
#eval "(pyenv init -)"
#status --is-interactive; and pyenv init - | source
#status --is-interactive; and pyenv virtualenv-init - | source
status --is-interactive; and source (pyenv init -|psub)

# ## Java
# set -x PATH "$PATH:/usr/lib/jvm/java-11-openjdk-amd64/bin/"
# set -x JAVA_HOME "/usr/lib/jvm/java-11-openjdk-amd64/"

# ## Maven
# set -x M2_HOME "/opt/maven"
# set -x PATH "$M2_HOME/bin:$PATH"

# Personal configurations ------------------------------------------------------------

## Keys
set -x KEYS "$HOME/.keys"

## ls colors
# eval (dircolors -c $HOME/.config/.dircolors)

## Scripts
# set -x PATH "$HOME/code/_vh/scripts:$PATH"

## Do not use fish history for a screen session (recording video)
if [ "$TERM" = "screen" ]
  set -x fish_histfile ""
end

# ## Git repo sign config
# alias vsign 'git-config-repo.sh "Vicente Herrera" "vicenteherrera@vicenteherrera.com" "F037765BA5F7111A"'

# Machine specific -------------------------------------------------------------------

# set -l HOST (hostname -s)
# source $HOME/.config/fish/config-{$HOST}.fish

# Additional alias ----------------------------------------------

source $HOME/.config/fish/config-alias.fish

# Simple Functions ------------------------------------------------------

# 1password command line sign in
# See https://support.1password.com/command-line/#appendix-session-management
# See https://1password.community/discussion/81823/op-and-fish-shell-environment

function opsign
      set cmd (op signin my)
      eval $cmd
end