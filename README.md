# 
<h1> <p align="center"> <span style='font-weight:bold;align=center'>Migrating your SVN project into Git</span></p></h1>

There are three scripts you need to use to migrate any number of projects from your SVN repository into git.

 ---
# Pre-requisites
 ---
You must be able to execute svn commands.
You must have git command line tool installed.

 ---
# Execution order
 ---
 1. 1_generate_committer_file.sh.  It generates a file that consist of list of svn committer names.  Input: SVN url, output file.
   Example: 1_generate_committer_file.sh https://mysvnserver.com/core_section/projectname svnCommitter.txt

2. 2_git_svn_fetch.sh.  Reads the svn_project_folder_List.txt and converts corresponding svn repositories into git repositories.
  This script assumes you have already filled in the name of svn projects in svn_project_folder_List.txt.
  You can do customization inside this script.  The default logic assumes you are running this script against svn repository that has a standard SVN layout.

3. 3_push_to_remote_git.sh.  Reads local_repo_list.txt and creates remote repositories based on the names documented in this file (which will be the same name of local repositories), push local repositories into remote repositories.
   By default this script performs an SSH connection, but you can configure this script to use HTTPS connection.


   
