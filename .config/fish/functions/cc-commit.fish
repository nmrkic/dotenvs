function cc-commit --description 'Puts a Claude-written git commit command on the command line'
    # Normally Enter (_cc_commit_enter) catches "cc-commit" before it runs;
    # this only runs when it's called some other way, e.g. from a script.
    _cc_commit_cmd
end
