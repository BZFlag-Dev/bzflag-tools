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

# change all committer info to match the author's
COMMITTER_IS_AUTHOR='
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"'

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
	git remote add --tags -f temp $BASE/svn2git.$svn_repo_name
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
			# preserve master branch name in bzflag repo
			if [ $repo = bzflag ] ; then
				git branch master $branch
			else
				git branch $repo $branch
			fi
			;;
		    remotes/temp/*)
			local=`echo $branch | sed 's=^remotes/temp/=='`
			git branch $local $branch
			;;
		esac
	done
	git remote remove temp
	if [ $svn_repo_name = bzflag ] ; then		# bzauthd repo is already done
		# conjoin the 2.99_bzauthd and bzauthd branches
		git checkout :/@18217.$UPSTREAM_UUID
		git merge --no-commit -Xours :/@18154.$UPSTREAM_UUID
		git mv bzauthd ldap libgcrypt libgpg-error tcp-net src
		git mv test src/bzauthd_test
		git rm -q -f -r MSVC/VC7.1
		LOCATION=branches/gsoc_bzauthd
		rev=18218
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git cherry-pick --allow-empty :/@18218.$UPSTREAM_UUID..:/@18426.$UPSTREAM_UUID

		# synthesize r19840
		git merge --no-commit -Xtheirs :/@19834.$UPSTREAM_UUID
		git rm -q -r MSVC/VC8
		git rm -q -f src/ogl/OpenGLContext.cxx src/other/freetype/builds/win32/visualc/freetype_vc8.vcproj src/other/freetype/include/freetype/ftcid.h src/other/freetype/include/freetype/internal/services/svcid.h src/other/freetype/include/freetype/internal/services/svttglyf.h
		rev=19840
		EXCEPTIONS='MSVC/build/bzflag.sln MSVC/build/bzflag.vcproj MSVC/build/bzfs.sln include/ServerList.h plugins/configure.ac src/bzflag/bzflag.cxx src/bzfs/ListServerConnection.cxx src/bzfs/bzfs.cxx src/common/global.cxx src/game/ServerList.cxx src/other/curl/buildconf.bat'
		SUBDIR=
		for file in $EXCEPTIONS ; do
			svn cat $SVN_REPO/$LOCATION/$file@$rev > $SUBDIR$file
			case $file in
			    configure.ac|plugins/HoldTheFlag/HoldTheFlag.cpp|plugins/nagware/nagware.cpp|src/bzflag/ScoreboardRenderer.cxx)
				sed -i -e 's/\$Id: .* \$/$Id$/' -e 's/\$Revision: .* \$/$Revision$/' $SUBDIR$file	# unexpand keywords
				;;
			esac
			git add $SUBDIR$file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"

		# synthesize r19841
		git merge --no-commit :/@19838.$UPSTREAM_UUID
		rev=19841
		EXCEPTIONS=src/bzfs/bzfs.cxx
		for file in $EXCEPTIONS ; do
			svn cat $SVN_REPO/$LOCATION/$file@$rev > $SUBDIR$file
			case $file in
			    configure.ac|plugins/HoldTheFlag/HoldTheFlag.cpp|plugins/nagware/nagware.cpp|src/bzflag/ScoreboardRenderer.cxx)
				sed -i -e 's/\$Id: .* \$/$Id$/' -e 's/\$Revision: .* \$/$Revision$/' $SUBDIR$file	# unexpand keywords
				;;
			esac
			git add $SUBDIR$file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git branch new_bzauthd	# an easy way to mark the current location
		git rebase --keep-empty --preserve-merges -Xours new_bzauthd 2.99_bzauthd | tr \\r \\n
		git branch -d new_bzauthd
		git tag 2.99_bzauthd_trunk bzauthd	# change branch to tag
		git branch -D bzauthd
		time git filter-branch --env-filter "$COMMITTER_IS_AUTHOR" -- --all | tr \\r \\n
		rm -rf .git/refs/original	# discard old commits saved by filter-branch
	elif [ $svn_repo_name = web ] ; then		# admin and db repos are already done
		# conjoin the admin and web branches
		git checkout :/@8126.$UPSTREAM_UUID
		git merge --no-commit -Xours :/@8149.$UPSTREAM_UUID
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
		git checkout :/@22223.$UPSTREAM_UUID
		git merge --no-commit :/@22064.$UPSTREAM_UUID
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
		git rebase --keep-empty -Xours new_web :/@22369.$UPSTREAM_UUID | tr \\r \\n
		git cherry-pick --allow-empty :/@22427.$UPSTREAM_UUID	# merge fails to keep it
		git rev-parse HEAD > .git/refs/heads/new_web
		git rebase --keep-empty -Xours new_web web | tr \\r \\n	# merge the remaining web branch
		git branch -d new_web
		git branch -m gamestats_live old_gamestats_live
		git checkout -b gamestats_live :/@22436.$UPSTREAM_UUID
		if ! git cherry-pick :/@22437.$UPSTREAM_UUID ; then
			git rm -q -r bzfls
			sed -i '1,/^git-svn-id:/!d' .git/MERGE_MSG
			git commit --allow-empty -F .git/MERGE_MSG	# instead of "git cherry-pick --continue"
		fi
		LOCATION=branches/gamestats_live
		rev=22442
		git merge -q --no-commit -Xsubtree=gamestats :/@22441.$UPSTREAM_UUID
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
		git merge -q --no-commit -Xsubtree=gamestats :/@22470.$UPSTREAM_UUID
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git branch -D db old_gamestats_live
		git filter-branch --env-filter "$COMMITTER_IS_AUTHOR" -- --all | tr \\r \\n
		rm -rf .git/refs/original	# discard old commits saved by filter-branch
	fi
	# rm -rf $BASE/svn2git.$svn_repo_name
done
git checkout $repo || git checkout master
sleep 1						# let the clock advance
git reflog expire --expire=now --all		# purge reflogs
git gc --prune=now				# tidy
rm -f .git/COMMIT_EDITMSG .git/FETCH_HEAD	# tidy
rm -r .git/logs/refs/remotes .git/refs/remotes	# tidy
git status --ignored				# update index and show state
}

(
set -xe
combine_repos bzflag-archive pybzflag custom_plugins
combine_repos bzflag-tools bzedit bzview bzeditw32 bzstats bzworkbench tools bzwgen svn_to_git
combine_repos bzflag-web admin db web
combine_repos bzflag-bzflag bzauthd bzflag
) > $BASE/svn2git.combine_repos.log 2>&1
