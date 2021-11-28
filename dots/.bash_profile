export PATH="$HOME/.ndenv/bin:$PATH"
eval "$(ndenv init -)"
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
eval "$(nodenv init -)"
