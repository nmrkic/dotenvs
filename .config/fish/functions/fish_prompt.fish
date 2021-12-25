set normal (set_color normal)
set magenta (set_color magenta)
set yellow (set_color yellow)
set green (set_color green)
set red (set_color red)
set gray (set_color -o black)

# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red
set __fish_git_prompt_color_dirtystate red
set __fish_git_prompt_color_upstream green
set __fish_git_prompt_color_upstream_equal green
set __fish_git_prompt_color_untrackedfiles blue

# Status Chars
set __fish_git_prompt_char_dirtystate ' ⬤ '
set __fish_git_prompt_char_stagedstate ' S'
set __fish_git_prompt_char_untrackedfiles ' ⬤ '
set __fish_git_prompt_char_stashstate ' ↩'
set __fish_git_prompt_char_upstream_ahead ' A'
set __fish_git_prompt_char_upstream_behind ' B'
set __fish_git_prompt_char_upstream_equal ' ◯ '
set __fish_git_prompt_char_upstream_prefix ''



function fish_prompt --description 'Write out the prompt'
	#Save the return status of the previous command
    set stat $status

    # Just calculate these once, to save a few cycles when displaying the prompt
    if not set -q __fish_prompt_hostname
        set -g __fish_prompt_hostname (hostname|cut -d . -f 1)
    end

    set kubenv (kubectl config current-context)
    echo -n -s "(" $kubenv ")" " "

    if set -q VIRTUAL_ENV
        echo -n -s "(" (basename "$VIRTUAL_ENV") ")" (set_color normal) " "
    end


    if not set -q __fish_prompt_normal
        set -g __fish_prompt_normal (set_color normal)
    end

    if not set -q __fish_color_blue
        set -g __fish_color_blue (set_color -o blue)
    end

    #Set the color for the status depending on the value
    set __fish_color_status (set_color -o green)
    if test $stat -gt 0
        set __fish_color_status (set_color -o red)
    end


    switch $USER

        case root toor

            if not set -q __fish_prompt_cwd
                if set -q fish_color_cwd_root
                    set -g __fish_prompt_cwd (set_color $fish_color_cwd_root)
                else
                    set -g __fish_prompt_cwd (set_color $fish_color_cwd)
                end
            end

            printf '%s@%s %s%s%s# ' $USER $__fish_prompt_hostname "$__fish_prompt_cwd" (prompt_pwd) "$__fish_prompt_normal"

        case '*'

            if not set -q __fish_prompt_cwd
                set -g __fish_prompt_cwd (set_color $fish_color_cwd)
            end

            printf '%s%s@%s %s%s %s %s %s  \f\r> ' "$__fish_color_blue" $USER $__fish_prompt_hostname "$__fish_prompt_cwd" "$PWD" (__fish_git_prompt) "$__fish_color_status" "$__fish_prompt_normal"
    end
end
