#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# alias ls='ls --color=auto'
# alias grep='grep --color=auto'

GREEN='\[\e[01;32m\]'
RED='\[\e[01;31m\]'
RESET='\[\e[00m\]'
# if root ? set red : set green
(( EUID == 0 )) && MAIN=$RED || MAIN=$GREEN
PS1='[\t] '$MAIN'[\u] '$RESET'in '$MAIN'[\w]\n \$ '$RESET

PATH="$PATH:~/bin"


color_prompt=yes
alias mount='udisksctl mount -b'
alias bs='cat ~/.bash_history | grep'
alias feh='feh -.Z $@'

alias nsearch='nix --extra-experimental-features "nix-command flakes" search nixpkgs'
alias nedit='sudo hx /etc/nixos/configuration.nix'
alias nswitch='sudo nixos-rebuild switch'

export HISTSIZE=9000
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r;"
export EDITOR=hx
export VISUAL=hx

n ()
{
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        exit
    }
    [ -n "$NNNLVL" ] && PS1="N$NNNLVL $PS1"

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TRASH=1

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    # command nnn -e -x -d -r "$@"
    command nnn -e -x -d "$@"

    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f -- "$NNN_TMPFILE" > /dev/null
    }
}

lc() {
    if [ -z "$2" ]; then
        lua -e "print(string.format('%.2f', $1))"  # по умолчанию 2 знака
    else
        lua -e "print(string.format('%.${2}f', $1))"  # кастомный scale
    fi
}

u() { 
    local mount_dir="/run/media/frivermen"
    local drives=()
    local choice selected i
    
    # Check if mount directory exists
    [[ -d "$mount_dir" ]] || { echo "Mount directory not found"; return 1; }
    
    # Get list of flash drives
    for dir in "$mount_dir"/*; do
        [[ -d "$dir" ]] && drives+=("$dir")
    done
    
    # Check if any drives found
    if [[ ${#drives[@]} -eq 0 ]]; then
        echo "No flash drives connected"
        return 0
    fi
    
    # Display list
    echo "Connected flash drives:"
    for i in "${!drives[@]}"; do
        echo "$((i+1)). ${drives[i]##*/}"
    done
    
    # Get user choice
    read -p "Select drive to unmount (1-${#drives[@]}, or 0 to cancel): " choice
    
    # Validate input
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -gt ${#drives[@]} ]]; then
        echo "Invalid selection"
        return 1
    fi
    
    [[ "$choice" -eq 0 ]] && { echo "Cancelled"; return 0; }
    
    # Unmount selected drive
    selected="${drives[$((choice-1))]}"
    echo "Unmounting $selected..."
    if umount "$selected"; then
        echo "Successfully unmounted"
        rmdir "$selected" 2>/dev/null && echo "Directory removed"
    else
        echo "Unmount failed"
        return 1
    fi
}
