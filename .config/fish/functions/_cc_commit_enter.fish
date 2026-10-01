function _cc_commit_enter --description 'Enter: "cc-commit" is replaced with a git commit command (not run); anything else runs as usual'
    if test (string trim -- (commandline)) = cc-commit
        # repaint is queued until this function returns, so draw the
        # waiting line straight to the terminal while Claude runs
        printf '\r\e[2K> working...' >/dev/tty
        commandline -r -- (_cc_commit_cmd)
        commandline -f repaint
    else
        commandline -f execute
    end
end
