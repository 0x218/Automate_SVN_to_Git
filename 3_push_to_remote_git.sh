#!/bin/bash

#==========================================================================================================
#	Script name: 	push_to_remote_git.sh
#	Description: 	This script creates a git repository in the remote server, and push the local repository
#					into the remote server.
#
#
#	Developed by:	Renjith (sa.renjith@gmail.com)
#	
#	Usage:			./push_to_remote_git.sh
#	Prerequisites:	
#					Git command line tool installed
#					Access to Git repository
#					List of local Git repositries that needs to be pushed to remote.
#
#	Script input:	None
#	Script output:	A remote Git repository with the data that is in local repository.
#			Note: As 'master' branch will have exact copy of trunk, before pushing remote, I am deleting the 'trunk' branch
#				  All the SVN branches and SVN tags will be turned into git branches.
#				  In svn the tags are also branches, not as in git tag.  Hence I'm converting tags to git branches.
#	
#==========================================================================================================

GITLAB_URL="https://REPLACE_THIS_WITH_YOUR_GITLAB_URL"
GITLAB_USER="renjith.sa@gmail.com"
ACCESS_TOKEN="glpat-xxxxxxxyyyyyyzzzzzzTOKEN"
GROUP_PATH="REPLACE_THIS_WITH_YOUR_GIT_PATH_WHERE_YOU_WILL_PUSH_THE_CODE_TO"
VISIBILITY="private" #can be public or internal.
DEFAULT_BRANCH="master"


REPO_LIST_FILE="local_repo_list.txt"
if [[ ! -f "$REPO_LIST_FILE" ]]; then
	echo "Error: File `$REPO_LIST_FILE` not found!"
	exit 1
fi

while IFS= read -r local_repo_folder; do
	echo "name of folder before truncating: $local_repo_folder"
	#Clear the carriage return.
	local_repo_folder=$(echo "$local_repo_folder" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r' )
	echo "name of folder after truncate: $local_repo_folder"
	#read -n 1 -s -r #wait for a keypress
	
	PROJECT_NAME="$local_repo_folder"
	LOCAL_REPO_PATH="$local_repo_folder"
	DESCRIPTION="Replacement project created svn repo: $local_repo_folder"


	#get namespace id for the subgroup
	echo  "Fetching namespace id for $GROUP_PATH"

	NAMESPACE_ID=$(curl -s --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$GITLAB_URL/api/v4/groups?search=$(basename $GROUP_PATH)" | jq ".[] | select(.full_path==\"$GROUP_PATH\") | .id")
	if [ -z "$NAMESPACE_ID" ]; then
		echo "Error: namespace id not found for $GROUP_PATH.  Exiting."
		exit 1
	fi
	echo "Namespace id: $NAMESPACE_ID"


	#create repo.
	echo "Creating remote repository $PROJECT_NAME"
	PROJECT_RESPONSE=$(curl -s --request POST --header "PRIVATE-TOKEN: $ACCESS_TOKEN"\
		--data "name=$PROJECT_NAME&namespace_id=$NAMESPACE_ID&visibility=private"\
		"$GITLAB_URL/api/v4/projects")

	REMOTE_PROJECT_ID=$(echo $PROJECT_RESPONSE | jq '.id')
	SSH_PROJECT_URL=$(echo $PROJECT_RESPONSE | jq -r '.ssh_url_to_repo')
	##HTTPS_PROJECT_URL="https://$(echo $SSH_URL | sed 's/git@//' | sed 's/:/\//')"

	if [ -z "$REMOTE_PROJECT_ID" ]; then
		echo "Error: Failed to create project. Exiting."
		exit 1
	fi
	echo "Remote project created.  ID: $REMOTE_PROJECT_ID"
	echo "Repository URL: $SSH_PROJECT_URL"

	#echo "press enter key to continue..."
	#read -n 1 -s -r #wait for a keypress


	##Unproject the branch
	#curl -s --request DELETE --header "PRIVATE-TOKEN: $ACCESS_TOKEN" \
	#	"$GITLAB_URL/api/v4/projects/$REMOTE_PROJECT_ID/protected_branches/$DEFAULT_BRANCH"
	
	#echo "Branch '$DEFAULT_BRANCH' is unprotected"
	cd "$LOCAL_REPO_PATH" || { echo "Error: Local repository path not found.  Exiting"; exit 1; }
	echo "$(pwd)"

	#echo "To push the code to remote, press enter key..."
	#read -n 1 -s -r #wait for a keypress

	#git init 
	#git add .
	#git commit -m "initial commit"
	echo "Pushing local remote to remote"
	git remote add origin "$SSH_PROJECT_URL"
	#git push -u origin "$DEFAULT_BRANCH"
	git push --set-upstream --all origin
	git push --tags

	echo "Upload complete for $local_repo_folder.  Press enter key to continue with next repo..."
	cd ..
	#read -n 1 -s -r #wait for a keypress

done < "$REPO_LIST_FILE"

echo "All the local repositories are now pushed to remote!"