#!/bin/bash

#==========================================================================================================
#	Script name: 	git_svn_fetch.sh
#	Description: 	This script migrates an SVN repository to a local Git repository, preserving histry for
#					standard layouts.
#
#
#	Developed by:	Renjith (sa.renjith@gmail.com)
#	
#	Usage:			./git_svn_fetch.sh
#	Prerequisites:	
#					SVN command line installed
#					Git command line tool installed
#					Access to SVN repository
#					SVN URL
#					List of SVN folders that needs to be migrated
#					A text file composed of SVN autors, in the format: username=username	<username@mailserver.com>
#							example:
#						sa.renjith=sa.renjith	<sa.renjith@gmail.com9
#					You can geneate the list using: svn log YOUR_SVN_URL --quiet | grep -E '^r[0-9]+' | awk '{print #3}' | sort | uniq > output.txt
#
#
#	Script input:	None
#	Script output:	A Git repository with SVN history (for SVN trunk, branches, tags)
#	
#==========================================================================================================

FOLDER_LIST="folderList.txt"
SVN_HOST_URL="https://localhost.com/mysvnrepo"
SVN_PATH_URL="retail/clients"
SVN_BASE_URL="${SVN_HOST_URL}/${SVN_PATH_URL}"
AUTHORS_FILE="../commiterList.txt"

STD_LAYOUT_SVN=true
EDIT_GIT_CONFIG=false
DEPLOY_TAGS=false

if [[ ! -f $FOLDER_LIST ]]; then
	echo "Error: File `$FOLDER_LIST` not found!"
	exit 1
fi


while IFS= read -r FOLDER_NAME || [[ -n "$FOLDER_NAME" ]]; do
	FOLDER_NAME=$(echo "$FOLDER_NAME" | tr -d '\r' | xargs)
	if [[ -z "$FOLDER_NAME" ]]; then
		continue
	fi

	echo "Processing folder: $FOLDER_NAME"
	mkdir -p "$FOLDER_NAME"
	if [[ $? -ne 0 ]]; then
		echo "Error: Could not create directory `$FOLDER_NAME`.   Skipping..."
		continue
	fi

	cd "$FOLDER_NAME" || 
	{ 
		echo "Error: Could not cd into `$FOLDER_NAME`.  Skipping..."; 
		continue; 
	}
	echo "Current directory: $(pwd)"
	
	SVN_URL="${SVN_BASE_URL}/${FOLDER_NAME}"
	
	echo "initializing git"
	####NOTE: if you add a flag --prefix=svn/, files will be created under refs/remotes/svn/*.  If not, it will be created under :refs/remotes/orgin/*.  Hence this script (the sed stanzas) need to be adjusted based on your usage.
	if [ "$STD_LAYOUT_SVN" = true ]; then
		echo "standard svn layout"
		git svn init --stdlayout --no-metadata "$SVN_URL" || 
		{ 
			echo "Error: Could not initialize Git repository in `$FOLDER_NAME`.  Skipping..."; 
			cd ..; 
			continue; 
		}
	else
		echo "non-standard svn layout"
		git svn init --trunk=trunk --branches=branches/* --tags=tags/* --no-metadata "$SVN_URL" || 
		{ 
			echo "Error: Could not initialize Git repository in `$FOLDER_NAME`.  Skipping..."; 
			cd ..; 
			continue; 
		}
	fi
	
	echo "Linking svn committer\'s file name"
	git config svn.authorsfile "$AUTHORS_FILE" || 
	{ 	
		echo "Error: Could not set svn.authorsfile `$AUTHORS_FILE`.  Skipping..."; 
		cd ..; 
		continue; 
	}
	
	###NOTE: If you need an extra tag to be fetched, one way is to update it in your .git/config file.
	###Example, if there is additional tag named 'deployTag', you can add a section in config file.
	if [ "$EDIT_GIT_CONFIG" = true ]; then
		GIT_CONFIG_STANZA="fetch = ${SVN_PATH_URL}/${FOLDER_NAME}/deployTags/*:refs/remotes/origin/deployTags/*"
		echo "Updating .git/config file with $GIT_CONFIG_STANZA"
		git config --add svn-remote.svn.fetch "$GIT_CONFIG_STANZA"
	fi
	
	echo "Retreiving revision number"
	FIRST_REVISION=$(svn log --stop-on-copy "$SVN_URL" | grep -E '^r[0-9]+' | tail -1 | awk '{print $1}' | sed 's/r//')
	#FINAL_REVISION=$(svn info $SVN_URL | grep "Revision" | awk '{print $2}')
	
	
	echo "Fecthing SVN data for ${FOLDER_NAME} from revision# ${FIRST_REVISION}"
	###NOTE: CLONE = git svn init AND git svn fetch.  
	###EXAMPLE: git svn clone "$SVN_URL" --trunk=trunk --branches=branches/* --tags=tags/* -A authors.txt -r 330000:HEAD .
	git svn fetch -r "$FIRST_REVISION":HEAD > /dev/null || 
	{ 
		echo "Error: git svn failed for `$FOLDER_NAME`."; 
		cd ..; 
		continue; 
	} 
	
	echo "Converting tags to git tags"
	for t in `git branch -a | grep 'tags/' | sed s_remotes/origin/tags/__`; do 
		git tag $t origin/tags/$t
		git branch -d -r origin/tags/$t
	done
	
	if [ "$DEPLOY_TAGS" = true ]; then
		echo "Converting deployTags to git tags"
		for dT in `git branch -a | grep 'tags/' | sed s_remotes/origin/deployTags/__`; do 
			git tag $dT origin/deployTags/$dT
			git branch -d -r origin/deployTags/$dT
		done
	fi
	
	echo "Converting brances to git branches"
	for b in `git branch -r | sed s_origin/__`; do 
		git branch $b origin/$b
		git branch -D -r origin/$b
	done
	
	echo "Cleaning up"
	#delete the trunk brach as it is already copied into master
	git branch -d trunk
	
	git config --remove-section svn-remote.svn
	git config --remove-section svn
	rm -fr .gti/svn .git/{logs,}/refs/remote/svn

	cd ..
done < "$FOLDER_LIST"

echo "Parsed all folders."
