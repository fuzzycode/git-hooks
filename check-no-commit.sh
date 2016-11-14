#!/bin/sh

# Taken from:
# http://jakemccrary.com/blog/2015/05/31/use-git-pre-commit-hooks-to-stop-unwanted-commits/

if git rev-parse --verify HEAD >/dev/null 2>&1
then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against=$(git hash-object -t tree /dev/null)
fi

patch_filename=$(mktemp -t commit_hook_changes.XXXXXX)
git diff --exit-code --binary --ignore-submodules --no-color > $patch_filename
has_unstaged_changes=$?

if [ $has_unstaged_changes -ne 0 ]; then
    echo "Stashing unstaged changes in $patch_filename."
    git checkout -- .
fi

quit() {
    if [ $has_unstaged_changes -ne 0 ]; then
        git apply $patch_filename
        if [ $? -ne 0 ]; then
            git checkout -- .
            git apply $patch_filename
        fi
    fi

    exit $1
}


# Redirect output to stderr.
exec 1>&2

files_with_nocommit=$(git diff --cached --name-only --diff-filter=ACM $against | xargs grep -i "nocommit" -l | tr '\n' ' ')

if [ "x${files_with_nocommit}x" != "xx" ]; then
    tput setaf 1
    echo "File being committed with 'nocommit' in it:"
    echo $files_with_nocommit | tr ' ' '\n'
    tput sgr0
    quit 1
fi

quit 0
