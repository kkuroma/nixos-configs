preexec() {
    timer=$(($(date +%s%N)/1000000))
}

precmd() {
    local return_code=$?

    if [ -n "$timer" ]; then
        local now=$(($(date +%s%N)/1000000))
        local elapsed=$(($now-$timer))

        local minutes=$((elapsed / 60000))
        local seconds=$(((elapsed % 60000) / 1000))
        local ms=$((elapsed % 1000))

        if [ $return_code -eq 0 ]; then
            local code_color="\033[32m"
        else
            local code_color="\033[31m"
        fi

        if [ $elapsed -gt 1000 ]; then
            if [ $minutes -gt 0 ]; then
                print -P "\033[34m󰁔\033[0m ${code_color}${return_code}\033[0m took ${minutes}m ${seconds}s"
            else
                print -P "\033[34m󰁔\033[0m ${code_color}${return_code}\033[0m took ${seconds}.$(printf "%03d" $ms)s"
            fi
        fi

        unset timer
    fi

    print ""
}

PROMPT=$'%F{cyan}╭──${VIRTUAL_ENV:+[$(basename $VIRTUAL_ENV)]─}[%B%F{red}%n%b%F{yellow}@%B%F{green}%m%b%F{cyan}][%B%F{blue}%25<…<%~%<<%b%F{cyan}]──[%B%F{magenta}%D{%Y/%m/%d}%b%F{cyan}][%B%F{yellow}%D{%H:%M:%S}%b%F{cyan}]\n%F{cyan}╰─%B%(#.%F{red}#.%F{green}▶)%b%F{reset} '
RPROMPT=''
