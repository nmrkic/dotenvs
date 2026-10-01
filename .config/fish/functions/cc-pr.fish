function cc-pr --description 'Claude code review of the current uncommitted changes'
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "cc-pr: not a git repo" >&2
        return 1
    end

    set -l untracked (git ls-files --others --exclude-standard)
    if git diff HEAD --quiet 2>/dev/null; and test (count $untracked) -eq 0
        echo "cc-pr: nothing to review"
        return
    end

    set -l prompt 'Do a code review of the uncommitted changes below (git diff against HEAD). You may read files in the repo for context.
Look for real problems: bugs, wrong logic, edge cases, missing error handling, security issues, data loss, missing migrations or tests for new behaviour. Skip style nitpicks and do not praise.
Answer in Serbian (latin script). For each problem: file:line, what is wrong, and a concrete fix. Order from most to least serious. If there is nothing serious, say so in one line.'

    echo "working..."
    # without the API key claude uses the logged-in subscription
    begin
        echo "## git diff --stat"
        git diff HEAD --stat
        echo
        echo "## untracked files (not in the diff, run git add to include them)"
        printf '%s\n' $untracked
        echo
        echo "## git diff"
        git diff HEAD | head -c 200000
    end | env -u ANTHROPIC_API_KEY claude -p --model opus --allowedTools Read Grep Glob -- $prompt
end
