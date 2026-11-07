source /usr/share/cachyos-fish-config/cachyos-config.fish

set fish_greeting ""
set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# alias
alias c='clear'
alias l='eza -lh --icons=auto'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias home="cd ~"
alias g='git'
alias le='live-server'
command -qv nvim && alias vim nvim

alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

set -gx EDITOR nvim

function fish_greeting
end

# Auto start tmux
if status is-interactive; and not set -q TMUX
    exec tmux
end

# Added by Antigravity CLI installer
set -gx PATH "/home/admin/.local/bin" $PATH

fish_add_path /home/admin/.spicetify

# opencode
fish_add_path /home/admin/.opencode/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
