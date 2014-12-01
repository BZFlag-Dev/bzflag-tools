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

BASE=/tmp
UPSTREAM_REPO=https://svn.code.sf.net/p/bzflag/code
UPSTREAM_UUID=08b3d480-bf2c-0410-a26f-811ee3361c24
SVN_REPO=file:///scratch/bzflag/bzflag.svn	# $UPSTREAM_REPO will be much slower

if [ "x$1" = x-q ] ; then
	QUICK=yes
fi

(
date "+svn_to_git started %c"
repo=$BASE/svn2git.svn_to_git
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

if [ "$QUICK" != yes ] ; then
	for repo in admin bzauthd bzedit bzeditw32 bzstats bzview bzwgen bzworkbench custom_plugins db pybzflag tools web bzflag ; do
		date "+$repo started %c"
		svn2git.sh $repo
		status=$?
		if [ $status -ne 0 ] ; then
			echo $repo: status $status
		fi
	done
fi
date

combine_repos()
{
combined_repo=$BASE/svn2git.$1
shift
rm -rf $combined_repo
git init $combined_repo
cd $combined_repo
for svn_repo_name in $* ; do
	git remote add -f temp $BASE/svn2git.$svn_repo_name
	case $svn_repo_name in
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
		repo=$svn_repo_name
		;;
	esac
	for branch in `git branch -a` ; do
		case $branch in
		    remotes/temp/master)
			git branch $repo $branch
			;;
		    remotes/temp/*)
			local=`echo $branch | sed 's=^remotes/temp/=='`
			git branch $local $branch
			;;
		esac
	done
	git remote remove temp
	if [ $svn_repo_name = web ] ; then		# admin and db repos are already done
		# conjoin the admin and web branches
		git checkout :/@8126.08b3d480
		git merge --no-commit -Xours :/@8149.08b3d480
		git rm -q -f -r .cvsignore [^m]* master_ban.txt
		rev=8157
		for file in master-bans.txt ; do
			svn cat $SVN_REPO/trunk/admin/$file@$rev > $file
			git add $file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/trunk/admin@$rev $UPSTREAM_UUID"
		git branch new_masterban	# an easy way to mark the current location
		git rebase new_masterban masterban | tr \\r \\n
		git branch -d new_masterban

		# merge the db branch into the web branch
		git checkout :/@22223.08b3d480
		git merge --no-commit :/@22064.08b3d480
		mkdir bzfls bzfls/css bzfls/images oldstats
		git mv css/weblogin.css bzfls/css
		git mv images/webauth_*.png bzfls/images
		git mv banfunctions.php bzfls.php bzflsadmin.php bzfman.cgi bzfsinfo.php bzidtools.php bzidtools2.php serversettings.php.tmpl weblogin.php bzfls
		git mv css i18n images includes support templates templates_c *.* oldstats
		cp bzfls/serversettings.php.tmpl oldstats
		git add oldstats/serversettings.php.tmpl 
		for file in oldstats/config.php.tmpl ; do
			svn cat $SVN_REPO/trunk/$svn_repo_name/$file@22228 > $file
			git add $file
		done
		rev=22224
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/trunk/db@$rev $UPSTREAM_UUID"
		git branch new_web	# an easy way to mark the current location
		git rebase --keep-empty -Xours new_web :/@22369.08b3d480 | tr \\r \\n
		git cherry-pick --allow-empty :/@22427.08b3d480		# merge fails to keep it
		git rev-parse HEAD > .git/refs/heads/new_web
		git rebase --keep-empty -Xours new_web web | tr \\r \\n	# merge the remaining web branch
		git branch -d new_web
		git branch -m gamestats_live old_gamestats_live
		git checkout -b gamestats_live :/@22436.08b3d480
		if ! git cherry-pick :/@22437.08b3d480 ; then
			git rm -q -r bzfls
			sed -i '1,/^git-svn-id:/!d' .git/MERGE_MSG
			git commit --allow-empty -F .git/MERGE_MSG	# instead of "git cherry-pick --continue"
		fi
		LOCATION=branches/gamestats_live
		rev=22442
		git merge -q --no-commit -Xsubtree=gamestats :/@22441.08b3d480
		for file in config/config.php ; do
			svn cat $SVN_REPO/$LOCATION/$file@$rev > $file
			git add $file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		rev=22471
		git merge -q --no-commit -Xsubtree=gamestats :/@22470.08b3d480
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git branch -D db old_gamestats_live
		git filter-branch --env-filter 'export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME";export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL";export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"' -- --all | tr \\r \\n
		rm -rf .git/refs/original	# discard old commits saved by filter-branch
	fi
	# rm -rf $BASE/svn2git.$svn_repo_name
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
combine_repos bzflag-tools bzedit bzview bzeditw32 bzstats bzworkbench tools bzwgen svn_to_git
combine_repos bzflag-web bzauthd admin db web
) > $BASE/svn2git.combine_repos.log 2>&1
