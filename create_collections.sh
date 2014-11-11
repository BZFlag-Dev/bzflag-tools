#!/bin/sh
# bzflag
# Copyright (c) 1993-2014 Tim Riker
#
# This package is free software;  you can redistribute it and/or
# modify it under the terms of the license found in the file
# named COPYING that should have accompanied this file.
#
# THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

(
date "+svn_to_git started %c"
repo=/tmp/svn2git.svn_to_git
exec > $repo.log 2>&1
set -xe
rm -rf $repo
git clone file:///$HOME/bzflag/git-master $repo
cd $repo
git remote remove origin
git filter-branch --subdirectory-filter svn_to_git master | tr \\r \\n
rm -rf .git/refs/original	# discard old commits saved by filter-branch
git gc --prune=now				# tidy
rm -f .git/FETCH_HEAD				# tidy
rm -r .git/logs/refs/remotes .git/refs/remotes	# tidy
git status --ignored				# update index and show state
)

# if false ; then
for repo in admin bzauthd bzedit bzeditw32 bzstats bzview bzwgen bzworkbench custom_plugins db pybzflag tools web bzflag ; do
	date "+$repo started %c"
	svn2git.sh $repo
	status=$?
	if [ $status -ne 0 ] ; then
		echo $repo: status $status
	fi
done
# fi
date

combine_repos()
{
combined_repo=/tmp/svn2git.$1
shift
rm -rf $combined_repo
git init $combined_repo
cd $combined_repo
for svn_repo in $* ; do
	git remote add -f temp /tmp/svn2git.$svn_repo
	case $svn_repo in
	    admin)
		repo=masterban
		;;
	    custom_plugins)
		repo=irclink_plugin
		;;
	    tools)
		repo=stat_collector
		;;
	    *)
		repo=$svn_repo
		;;
	esac
	for branch in `git branch -a` ; do
		case $branch in
		    remotes/temp/master)
			git branch $repo $branch
			;;
		    remotes/temp/*)
			local=`echo $branch | sed 's=^remotes/temp/=='`
			git branch ${repo}_$local $branch
			;;
		esac
	done
	git remote remove temp
	# rm -rf /tmp/svn2git.$svn_repo
done
git checkout $repo
git gc --prune=now				# tidy
rm -f .git/FETCH_HEAD				# tidy
rm -r .git/logs/refs/remotes .git/refs/remotes	# tidy
git status --ignored				# update index and show state
}

(
set -xe
combine_repos bzflag-archive pybzflag custom_plugins
combine_repos bzflag-tools bzedit bzview bzeditw32 bzworkbench tools bzwgen svn_to_git
combine_repos bzflag-web bzstats bzauthd admin db web
) > /tmp/svn2git.combine_repos.log 2>&1
