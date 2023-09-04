#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2023 Amplify Security
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

system=$(uname -s)

# Check if 'jq' is installed
if [ -z "$(command -v jq)" ]; then
    echo "'jq' is required but not installed."
    if [ "$system" == "Darwin" ]; then
      echo "Please install 'jq' using the following command:"
      echo "brew install jq"
    elif [ "$system" == "Linux" ]; then
      if [ -x "$(command -v apt)" ]; then
        echo "Please install 'jq' using the following command:"
        echo "sudo apt install jq"
      elif [ -x "$(command -v apt-get)" ]; then
        echo "Please install 'jq' using the following command:"
        echo "sudo apt-get install jq"
      elif [ -x "$(command -v apk)" ]; then
        echo "Please install 'jq' using the following command:"
        echo "sudo apk add jq"
      elif [ -x "$(command -v dnf)" ]; then
        echo "Please install 'jq' using the following command:"
        echo "sudo dnf install jq"
      elif [ -x "$(command -v zypper)" ]; then
        echo "Please install 'jq' using the following command:"
        echo "sudo zypper install jq"
      fi
    fi
    exit 1
fi

# Check if a command-line argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <GitHub Organization Name>"
    echo "Example: $0 MyGitHubOrg"
    exit 1
fi

# GitHub Organization Name
GH_ORG=$1

# Path to the JSON file
CONFIG_FILE="config.json"

if test -f "$CONFIG_FILE"; then
  echo "Using $CONFIG_FILE..."
else
  echo "$CONFIG_FILE not found"
  exit 1
fi

# Read the JSON file into a variable
CONFIG_JSON=$(<${CONFIG_FILE})

# Get the length of the array in the JSON file
length=$(echo $CONFIG_JSON | jq '. | length')

# Print the list of repositories from the JSON file
echo "This script will install the Amplify Secure Pipeline GitHub Action in the following repositories:"
for i in $(seq 0 $(($length - 1))); do
  repo=$(echo $CONFIG_JSON | jq -r ".[$i].repo")
  echo "- $repo"
done

read -p "Would you like to continue? Y/n: " continue
if [ "$continue" == "Y" ]; then
  echo "Installing Amplify..."
else
  exit 0
fi

# Iterate through each object in the array
for i in $(seq 0 $(($length - 1))); do
  
  # Parse the keys for the current object
  repo=$(echo $CONFIG_JSON | jq -r ".[$i].repo")
  file_dest=$(echo $CONFIG_JSON | jq -r ".[$i].file_dest")
  action=$(echo $CONFIG_JSON | jq -r ".[$i].action")
  commit_message=$(echo $CONFIG_JSON | jq -r ".[$i].commit_message")
  branch=$(echo $CONFIG_JSON | jq -r ".[$i].branch")
  
  # clone the repo
  tmpdir=$(mktemp -d -t gitrepo-XXXX)
  git clone git@github.com:$GH_ORG/$repo.git $tmpdir

  # create the github workflows directory if not exists
  mkdir -p "$(dirname "$tmpdir/$file_dest")"
  
  # copy the GitHub action
  cp $action $tmpdir/$file_dest

  # Navigate into the cloned repository directory
  cd $tmpdir

  if [ ! -z $branch ]; then
    # checkout the correct branch
    if [ ! `git show-ref --verify --quiet refs/heads/$branch` ]; then
      # create branch if not exists
      git branch $branch
    fi
    git checkout $branch
  fi
  
  # Add the file to the staging area
  git add $file_dest
  
  # Commit the changes with the specified commit message
  git commit -m "$commit_message"
  
  # Capture the return status of the git commit command
  commit_status=$?
  
  # Print the status based on the return status
  if [ $commit_status -eq 0 ]; then
    echo "Successfully committed $file_dest into $repo"
    # Push the changes to the remote repository
    # Uncomment the next line if you want the script to push automatically
    # Make sure your SSH keys are set up to push without entering a passphrase
    echo "Pushing commit to origin..."
    if [ ! -z $branch ]; then
      git push -u origin $branch
    else
      git push
    fi
  else
    echo "Failed to commit $file_dest into $repo"
  fi
  
  # Navigate back to the original directory and remove the temporary directory
  cd -
  rm -rf $tmpdir

done