## nodenv
eval "$(nodenv init -)"

## pyenv
eval "$(pyenv init -)"

# git
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{yellow}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

# プロンプトカスタマイズ
PROMPT='
[%B%F{red}%n@%m%f%b:%F{green}%~%f]%F{cyan}$vcs_info_msg_0_%f
%F{yellow}$%f '

#zplug
source ~/.zplug/init.zsh
zplug "b4b4r07/enhancd", use:"init.sh"
 
if ! zplug check --verbose; then
    printf "インストールしますか？[y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
 
zplug load
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
