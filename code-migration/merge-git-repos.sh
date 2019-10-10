#!/usr/bin/env bash

USAGE="

./merge-git-repos.sh result config.file

result - github repository under trilogy organization, use ssh git address

config.file - path to configuration file with repositories to merge in a special format: {repository} {folder}

"

if [[ $1 == "-h" ]]
then
  echo "$USAGE"
  exit 0
fi

TRILOGY_REPOSITORY_PATTERN="git@github.com:trilogy-group/(.*).git"

if [[ $1 =~ $TRILOGY_REPOSITORY_PATTERN ]] 
then
  INIT_REPOSITORY=$1
else
  echo 'Invalid trilogy github repository, run command with "-h" for usage options'
  exit 1
fi

REPOS=()
FOLDERS=()

if [[ -f $2 ]]
then
  while IFS= read -r line; do
    SPLIT=($line)

    REPOS+=(${SPLIT[0]})
    FOLDERS+=(${SPLIT[1]})
  done < "$2"
else
  echo 'Config file does not exist, run command with "-h" for usage options'
  exit 1
fi

if [[ ${#REPOS[*]} != ${#FOLDERS[*]} ]]
then
  echo "Invalid config file format: repos count is not equal to folders count"
  exit 1
fi

TMP_PATH="/tmp/merge-git-repos"

rm -rf $TMP_PATH
mkdir -p $TMP_PATH

cd $TMP_PATH

test=$(git ls-remote --heads $INIT_REPOSITORY master)

echo $test

if [[ $test != "" ]]
then
  echo "This tool must run on empty repository, otherwise it will lead to unpredictable results"
  exit 1
fi

# start migration
git init
git remote add origin $INIT_REPOSITORY

touch .merge-git-repos
git add .merge-git-repos
git commit -m "Initial commit"

git push origin master

# migrate repositories
FIND_CMD='find . -maxdepth 1 ! -name "." ! -name ".git" ! -name ".merge-git-repos"'

for item in ${FOLDERS[*]}
do
  FIND_CMD="$FIND_CMD ! -path \"./$item\" "
done

i=0
for item in ${REPOS[*]}
do
  echo "Processing $item"
  git remote add tmp $item
  git remote update
  git merge --no-edit --allow-unrelated-histories tmp/master

  mkdir ${FOLDERS[$i]}

  CMD="$FIND_CMD -exec mv {} ./${FOLDERS[$i]}/ \;"
  echo $CMD
  eval $CMD

  git add .
  git commit -m "Move files from $item to ${FOLDERS[$i]}"

  ((i++))

  git remote remove tmp
done

# Finish migration
rm -rf .merge-git-repos
git add .
git commit -m "Finish repositories migration"

git push origin master
