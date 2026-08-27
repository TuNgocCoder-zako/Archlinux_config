# ╔══════════════════════════════════════╗
# ║           Zsh Config                 ║
# ║     Catppuccin Mocha — Anime Rice    ║
# ╚══════════════════════════════════════╝

# ── History ──
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ── Options ──
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS

# ── Completion ──
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Keybindings ──
bindkey '^[[A' history-search-backward    # Up arrow
bindkey '^[[B' history-search-forward     # Down arrow
bindkey '^[[H' beginning-of-line          # Home
bindkey '^[[F' end-of-line                # End
bindkey '^[[3~' delete-char               # Delete
bindkey '^[[1;5C' forward-word            # Ctrl+Right
bindkey '^[[1;5D' backward-word           # Ctrl+Left

# ── Aliases ──
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -a --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias vi='vim'
alias cls='clear'
alias fetch='fastfetch'

# Pacman / yay shortcuts
alias pac='sudo pacman'
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias paci='pacman -Qi'
alias pacl='pacman -Ql'
alias pacf='pacman -F'

alias yays='yay -S'
alias yayu='yay -Syu'

# System
alias reload='source ~/.zshrc'
alias hypr-reload='hyprctl reload'
alias hypr-log='cat ~/.hyprland/hyprland.log'

# ── Starship Prompt ──
eval "$(starship init zsh)"

# ── Fastfetch on new terminal ──
if [[ -o interactive ]]; then
    fastfetch
fi
