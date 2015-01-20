#!/bin/sh
# bzflag
# Copyright (c) 1993-2015 Tim Riker
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
elif [ "x$1" = x-12 ] ; then
	FORMULA=`date '+\( 12 - %-I \) \* 3600 - %-M \* 60 + 61'`
	DELTA=`eval expr $FORMULA`
	date -d "+$DELTA seconds" '+conversion process will begin at %T'
	sleep $DELTA
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
git checkout $repo || git checkout master
sleep 1						# let the clock advance
git clean -d -x -f				# tidy the working tree
git reflog expire --expire=now --all		# purge reflogs
git gc --prune=now				# tidy
rm -f .git/COMMIT_EDITMSG .git/FETCH_HEAD .git/ORIG_HEAD	# tidy
rm -r .git/logs/refs/remotes .git/refs/remotes	# tidy
git status --ignored				# update index and show state
)

if [ "$QUICK" != yes ] ; then
	for repo in admin bzauthd branch_note bzedit bzeditw32 bzstats bzview bzwgen bzworkbench custom_plugins db pybzflag tools web bzflag ; do
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
combined_repo=$1
combined_repo_dir=$BASE/svn2git.$combined_repo
shift
rm -rf $combined_repo_dir
git init $combined_repo_dir
cd $combined_repo_dir
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
			# preserve "master" branch name in bzflag and web repos
			if [ $svn_repo_name = bzflag -o $svn_repo_name = web ] ; then
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
		# conjoin the gsoc_bzauthd and bzauthd branches
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
		git branch new_bzauthd			# an easy way to mark the current location
		git branch gsoc_bzauthd gsoc_bzauthd	# change gsoc_bzauthd back from
		git tag -d gsoc_bzauthd			# a tag to a branch for correct rebase operation
		git rebase --keep-empty --preserve-merges -Xours new_bzauthd gsoc_bzauthd | tr \\r \\n
		git branch -d new_bzauthd
		git branch -m bzauthd gsoc_bzauthd_trunk

		time git filter-branch --env-filter "$COMMITTER_IS_AUTHOR" -- --all | tr \\r \\n
		rm -rf .git/refs/original		# discard old commits saved by filter-branch

		# rebase late commit r19307 to elimiate a pointless single-commit branch
		GIT_COMMITTER_DATE='1417595400 -0800' GIT_COMMITTER_NAME='Jeff Makey' GIT_COMMITTER_EMAIL='jeff@makey.net' git rebase gsoc_bzauthd gsoc_bzauthd_trunk
		git checkout master			# be somewhere else
		git tag gsoc_bzauthd gsoc_bzauthd_trunk	# change branch to tag
		git branch -D gsoc_bzauthd gsoc_bzauthd_trunk
	elif [ $svn_repo_name = web ] ; then		# admin and db repos are already done
		# conjoin the admin and master branches
		git checkout :/@8126.$UPSTREAM_UUID
		git merge --no-commit -Xours :/@8149.$UPSTREAM_UUID
		git rm -q -f -r .cvsignore [^m]* master_ban.txt
		LOCATION=trunk/admin
		rev=8157
		for file in master-bans.txt ; do
			svn cat $SVN_REPO/$LOCATION/$file@$rev > $file
			git add $file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git branch new_masterban	# an easy way to mark the current location
		git rebase new_masterban masterban | tr \\r \\n
		git branch -d new_masterban

		# merge the db branch into the master branch
		git checkout :/@22223.$UPSTREAM_UUID
		git merge --no-commit :/@22064.$UPSTREAM_UUID
		mkdir bzfls bzfls/css bzfls/images oldstats
		git mv css/weblogin.css bzfls/css
		git mv images/webauth_*.png bzfls/images
		git mv banfunctions.php bzfls.php bzflsadmin.php bzfman.cgi bzfsinfo.php bzidtools.php bzidtools2.php serversettings.php.tmpl weblogin.php bzfls
		git mv css i18n images includes support templates templates_c *.* oldstats
		cp bzfls/serversettings.php.tmpl oldstats
		git add oldstats/serversettings.php.tmpl 
		LOCATION=trunk/$svn_repo_name
		rev=22224
		for file in oldstats/config.php.tmpl ; do
			svn cat $SVN_REPO/$LOCATION/$file@22228 > $file
			git add $file
		done
		DATE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<date>==s and s=</date>.*==s and print'`"
		AUTHOR="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<author>==s and s=</author>.*==s and print'`"
		MESSAGE="`svn log --xml -r $rev $SVN_REPO | perl -wle 'undef \$/; \$_ = <>; s=.*<msg>==s and s=</msg>.*==s and print'`"
		git commit --allow-empty "--date=$DATE" "--author=$AUTHOR" "-m$MESSAGE

git-svn-id: $UPSTREAM_REPO/$LOCATION@$rev $UPSTREAM_UUID"
		git branch new_master	# an easy way to mark the current location
		git rebase --keep-empty -Xours new_master :/@22369.$UPSTREAM_UUID | tr \\r \\n
		git cherry-pick --allow-empty :/@22427.$UPSTREAM_UUID	# merge fails to keep it
		git rev-parse HEAD > .git/refs/heads/new_master
		git rebase --keep-empty -Xours new_master master | tr \\r \\n	# merge the remaining master branch
		git branch -d new_master
		git branch -m gamestats_live old_gamestats_live
		git checkout -b gamestats_live :/@22436.$UPSTREAM_UUID
		if ! git cherry-pick :/@22437.$UPSTREAM_UUID ; then
			git rm -q -r bzfls
			sed -i '1,/^git-svn-id:/!d' .git/MERGE_MSG
			git commit --allow-empty -F .git/MERGE_MSG	# instead of "git cherry-pick --continue"
		fi
		git merge -q --no-commit -Xsubtree=gamestats :/@22441.$UPSTREAM_UUID
		LOCATION=branches/gamestats_live
		rev=22442
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
git clean -d -x -f				# tidy the working tree
git reflog expire --expire=now --all		# purge reflogs
git gc --prune=now				# tidy
rm -f .git/COMMIT_EDITMSG .git/FETCH_HEAD .git/ORIG_HEAD	# tidy
rm -r .git/logs/refs/remotes .git/refs/remotes	# tidy
git status --ignored				# update index and show state
case $combined_repo in
    bzflag-archive)
	origin=${combined_repo}-rc1
	;;
    bzflag-bzflag)
	origin=bzflag-import-7
	;;
    bzflag-tools)
	origin=${combined_repo}-rc2
	;;
    bzflag-web)
	origin=${combined_repo}-rc1
	;;
esac
git remote add origin git@github.com:BZFlag-Dev/$origin.git
if git fetch --all ; then
	for branch in `git branch | tr -d \*` ; do
		git branch -u origin/$branch $branch
	done
#else	# don't do this automatically!
#	git push -u origin --all
#	git push -u origin --tags
	# add the new repo to the GitHub "developers" team (JeffM)
	# add the new repo at http://n.tkte.ch/BZFlag/ (JeffM)
fi
git branch -vv
}

(
set -xe
combine_repos bzflag-archive pybzflag branch_note custom_plugins
combine_repos bzflag-tools bzedit bzview bzeditw32 bzstats tools svn_to_git bzwgen
combine_repos bzflag-web admin db web
combine_repos bzflag-bzflag bzauthd bzflag
cd $BASE/svn2git.bzworkbench
if git remote add origin git@github.com:BZFlag-Dev/bzworkbench-rc2.git ; then
	git fetch --all
	git branch -u origin/master master
fi
git branch -vv
) > $BASE/svn2git.combine_repos.log 2>&1
status=$?
if [ $status -ne 0 ] ; then
	echo collection status $status
fi

# report any missing/extra Subversion commits
EXPECTED=$BASE/svn2git.expected.$$
HAVE=$BASE/svn2git.have.$$
(
seq 1 22835
echo 298 722 4194 4195 4197 4198 5793 5794 5943 5997 5998 6006 6007 6008 6084 6130 6162 6170 6171 6204 6455 6456 6459 6492 6654 6706 6789 6909 7461 7462 7468 7587 7828 8480 9311 11953 11974 12096 12102 12103 12104 12205 12355 12362 12450 12523 12524 12529 12550 12653 12797 12801 12803 12815 13008 13053 13152 13226 13247 13300 13328 13581 13585 13653 13654 13655 13656 13660 13664 13665 13667 13679 13680 13706 13782 13801 13842 13913 13915 17165 17165 17169 19100 22830 | tr ' ' \\n	# known duplicates
) | sort -n > $EXPECTED

awk -F, '$2 == "tidy" {print $1}' `dirname $0`/revision_list > $HAVE
for repo in bzflag-bzflag bzflag-archive bzflag-tools bzflag-web bzworkbench ; do
	cd $BASE/svn2git.$repo
	git log --all | awk '$1 == "git-svn-id:" && $3 == "08b3d480-bf2c-0410-a26f-811ee3361c24" {print substr($2,index($2,"@")+1)}'
done >> $HAVE

sort -n $HAVE | diff $EXPECTED -
rm $EXPECTED $HAVE
