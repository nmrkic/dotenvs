function _cc_commit_cmd --description 'Prints a git commit command with a Claude-written message for the current diff'
    # messages are comment lines, so pressing Enter on them does nothing
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "# cc-commit: not a git repo"
        return
    end

    set -l untracked (git ls-files --others --exclude-standard)
    if git diff HEAD --quiet 2>/dev/null; and test (count $untracked) -eq 0
        echo "# cc-commit: nothing to commit"
        return
    end

    set -l prompt 'Write a git commit message for the changes below.
Rules: ONE line, lowercase, English, short (max ~100 chars), list only the main changes separated by commas, no prefix, no quotes, no trailing period, no explanation. Output ONLY the message.'

    # without the API key claude uses the logged-in subscription
    set -l out (begin
        echo "## git diff --stat"
        git diff HEAD --stat
        echo
        echo "## untracked files"
        printf '%s\n' $untracked
        echo
        echo "## git diff"
        git diff HEAD | head -c 60000
    end | env -u ANTHROPIC_API_KEY claude -p --model sonnet $prompt 2>&1)
    set -l claude_status $status

    # on an error leave a harmless comment line instead of a commit
    if test $claude_status -ne 0; or test -z "$out"
        echo "# cc-commit error: "(string join ' ' -- $out | string trim)
        return
    end

    set -l msg (string trim -- $out[1])

    echo "git commit -a -m "(string escape -- "-- $msg")
end
