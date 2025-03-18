#!/bin/bash
set -e  # エラーが発生したらスクリプトを終了する

# pub
git remote set-url origin git@github.com:katsu-ds-lab/ds-drills.git
git remote -v
\cp -f .gitignore-pub .gitignore
git rm -r --cached .
git status

git add -A
git commit -m "commit"
git push -u origin main

\cp -f .gitignore-dev .gitignore
git remote set-url origin git@github.com:katsu-ds-lab/ds-drills-dev.git

