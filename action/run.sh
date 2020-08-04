#!/bin/bash
echo "I solemnly swear that I am up to no good."
current_branch=$(git branch --show-current)
# If there's no selected branch, select default branch
if [ -n ${current_branch+x} ]; then
    current_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
fi
export ACTION_CURRENT_BRANCH="${current_branch}"

timestamp=$(date +%s)
export ACTION_BRANCHNAME="dockerfile-updater/${timestamp}"

# Init git config
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

# Crate new branch
git checkout -b "${ACTION_BRANCHNAME}"

# Execute action
python3 /action/run.py
if [ "$?" != "0" ]; then
    exit 1
fi


# Push branch and create PR if needed
if [ -s changes ]; then
    git push "https://x-access-token:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "${ACTION_BRANCHNAME}"
    if [ -n ${INPUT_DISABLE_PR+x} ] || [ "${INPUT_DISABLE_PR}" = "false" ]; then
        python3 /action/create_pr.py 
    fi
    else
        echo "Automatic PR disabled"
    if [ "$?" != "0" ]; then
        exit 1
    fi
fi

# Set output variables
# Branch name
echo "::set-output name=branch_name::${ACTION_BRANCHNAME}"
# SHA of the branch
SHA=$(git rev-parse ${ACTION_BRANCHNAME})
echo "::set-output name=sha::${SHA}"

# Set back the active branch
git checkout "${ACTION_CURRENT_BRANCH}"
echo "Mischief managed!"