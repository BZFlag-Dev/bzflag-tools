#!/bin/sh -e
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

SOURCE="`dirname $0`"
SOURCE="`readlink -f $SOURCE`"			# use full path
REPO_LIST='bzflag-archive bzflag-bzflag bzflag-tools bzflag-web bzworkbench'
UPSTREAM_REPO=https://svn.code.sf.net/p/bzflag/code
UPSTREAM_UUID=08b3d480-bf2c-0410-a26f-811ee3361c24
SVN_REPO=file:///scratch/bzflag/bzflag.svn
BASE=/tmp
SVNDIR=$BASE/svn2git.validate-svn
GITDIR=$BASE/svn2git.validate-git
if [ "x$1" != x ] ; then
	STARTING_REVISION=$1
else
	STARTING_REVISION=1
fi

cd $BASE					# be somewhere else
rm -rf /var$GITDIR $GITDIR $SVNDIR
mkdir $GITDIR
lastrev=1
svn checkout -q $SVN_REPO@$lastrev $SVNDIR	# empty tree

(
for repo in $REPO_LIST ; do
	# use awk to remove UPSTREAM_REPO/ and to convert @ to a space
	GIT_DIR=$BASE/svn2git.$repo/.git git log --all | awk \$1==\"git-svn-id:\"\&\&\$3==\"$UPSTREAM_UUID\"\{print\ gensub\(\"@\",\"\ \",1,gensub\(\"$UPSTREAM_REPO/\",\"\",1,\$2\)\),\"$repo\"\}
done
# add commits that completely delete a branch or tag
echo tags/V1_10_6 13939 trash
echo tags/merge-2_0-2_1-1 13940 trash
echo tags/merge-2_0-2_1-2 13941 trash
echo tags/merge-2_0-2_1-3 13942 trash
echo tags/merge-2_0-2_1-4 13943 trash
echo tags/merge-2_0-2_1-5 13944 trash
echo tags/merge-2_0-2_1-6 13945 trash
echo tags/merge-2_0-2_1-7 13946 trash
echo tags/merge-2_0-2_1-8 13947 trash
echo tags/merge-2_0-2_1-9 13948 trash
echo tags/merge-2_0-2_1-10 13949 trash
echo tags/merge-2_0-2_1-11 13950 trash
echo branches/ftgl 14692 trash
echo branches/remove_flag_id 15875 trash
# add commits that move or create directories
echo branches/experimental 21384 reorg
echo . 21386 reorg
echo branches/summer_of_code 21388 reorg
echo branches/release_maint 21399 reorg
# add commit that should have only been in Git
echo trunk/bzflag 22829 bzflag
echo . 99999 eof
) | sort -n -k2 | while read dir rev repo ; do
	if [ $rev -gt $lastrev ] ; then
		case $lastrev in
		    8130)
			wait				# serialize
			cd $BASE			# be somewhere else
			rm -r $GITDIR/trunk/admin/.git
			rmdir $GITDIR/trunk/admin	# should be empty
			;;
		    14252)
			wait				# serialize
			mkdir $GITDIR/trunk/bzworkbench/windows
			;;
		    14253|14258)
			wait				# serialize
			mkdir $GITDIR/trunk/bzworkbench/windows/.settings
			;;
		    14257)
			wait				# serialize
			mkdir $GITDIR/trunk/bzworkbench/windows/Debug
			;;
		    14300)
			wait				# serialize
			mkdir $GITDIR/trunk/bzworkbench/render
			;;
		    14716|15220)
			wait				# serialize
			# put relaybot.cpp where Subversion expects it to be
			mkdir $GITDIR/$lastdir/../relaybot
			mv $GITDIR/$lastdir/src/other/libirc/examples $GITDIR/$lastdir/../relaybot/src
			if [ $lastrev -eq 14716 ] ; then
				rmdir $GITDIR/$lastdir/src/other/libirc
			else
				mkdir $GITDIR/$lastdir/src/other/libirc/examples
			fi
			;;
		    14750)
			wait				# serialize
			mkdir $GITDIR/branches/gsoc_irc/bzflag/src/other/libirc/examples
			;;
		    15217)
			wait				# serialize
			mkdir $GITDIR/tags/soc-bzworkbench/windows/.settings $GITDIR/tags/soc-bzworkbench/windows/Debug
			;;
		    15218)
			wait				# serialize
			mkdir -p $GITDIR/trunk/bzwgen/MSVC/VC71 $GITDIR/trunk/bzwgen/MSVC/VC8
			;;
		    15545)
			wait				# serialize
			mkdir $GITDIR/trunk/bzworkbench/src
			;;
		    15546)
			wait				# serialize
			mv $GITDIR/trunk/bzworkbench/windows/.settings $GITDIR/trunk/bzworkbench/windows/Debug $GITDIR/trunk/bzworkbench/src/windows
			rmdir $GITDIR/trunk/bzworkbench/windows
			;;
		    15586)
			wait				# serialize
			mkdir -p $GITDIR/trunk/bzflag/bots/testbot
			;;
		    16354)
			wait				# serialize
			mkdir $GITDIR/trunk/db/bzgrpmgr/img
			;;
		    16519)
			wait				# serialize
			mkdir $GITDIR/trunk/bzflag/data/geometry/tank/low $GITDIR/trunk/bzflag/data/geometry/tank/medium
			;;
		    16574)
			wait				# serialize
			mv $GITDIR/trunk/bzflag/data/geometry/tank/* $GITDIR/trunk/bzflag/data/models/tank
			rmdir $GITDIR/trunk/bzflag/data/geometry/tank $GITDIR/trunk/bzflag/data/geometry
			;;
		    16946)
			wait				# serialize
			mkdir $GITDIR/branches/v2_99_shot_branch/data/models/tank/low $GITDIR/branches/v2_99_shot_branch/data/models/tank/medium
			;;
		    16968|17271)
			wait				# serialize
			rmdir $GITDIR/$lastdir/data/models/tank/low $GITDIR/$lastdir/data/models/tank/medium $GITDIR/$lastdir/data/models/tank $GITDIR/$lastdir/data/models
			;;
		    17431)
			wait				# serialize
			mkdir -p $GITDIR/trunk/bzauthd/MSVC/VC8
			;;
		    17432)
			wait				# serialize
			mkdir $GITDIR/trunk/bzauthd/MSVC/VC7.1
			;;
		    17433)
			wait				# serialize
			mkdir $GITDIR/trunk/bzauthd/tcp-net/src $GITDIR/trunk/bzauthd/tcp-net/include
			;;
		    18215)
			wait				# serialize
			mkdir $GITDIR/branches/gsoc_collisions/gsoc_bzauthd
			;;
		    18216)
			wait				# serialize
			rmdir $GITDIR/branches/gsoc_collisions/gsoc_bzauthd
			;;
		    18221)
			wait				# serialize
			mkdir $GITDIR/branches/gsoc_bzauthd/src/bzAuthCommon
			;;
		    19111|19840|21402|21560|22053|22528|22532)
			wait				# serialize
			mkdir $GITDIR/$lastdir/src/other/glew/{bin,lib}
			;;
		    19446)
			wait				# serialize
			mkdir -p $GITDIR/trunk/web/mainsite/oldwiki/applets/TWikiDrawPlugin
			;;
		    20701)
			wait				# serialize
			mkdir $GITDIR/$lastdir/src/other/ares/m4
			;;
		    21077|21206)
			wait				# serialize
			if [ $lastrev -eq 21077 ] ; then
				mkdir $GITDIR/$lastdir/src/other/ares/m4
			fi
			mkdir $GITDIR/$lastdir/src/other/glew/{bin,lib}
			# copy all but bzflag to fill out the v3_0_alpha* tags
			cp -r $GITDIR/trunk/[^b]* $GITDIR/trunk/bz[^f]* $GITDIR/$lastdir/.. &	# parallelize
			;;
		    21454)
			wait				# serialize
			mkdir -p $GITDIR/trunk/bzflag/package/win32/nsis
			;;
		    21574)
			wait				# serialize
			rmdir $GITDIR/$lastdir/src/other/glew/* $GITDIR/$lastdir/src/other/glew $GITDIR/$lastdir/src/other
			mkdir $GITDIR/$lastdir/other_src/glew/{bin,lib}
			;;
		    22224)
			wait				# serialize
			rm -r $GITDIR/trunk/db/*
			mkdir $GITDIR/trunk/db/{images,support}
			;;
		    22427)
			wait				# serialize
			mkdir $GITDIR/trunk/web/gamestats
			;;
		    22534)
			wait				# serialize
			mkdir -p $GITDIR/branches/experimental/2_4_OSX_Lion_Rebuild_branch/MacOSX/{BZFlag.xcworkspace,BZFlag/BZFlag.xcodeproj,Common/Common.xcodeproj,Game/Game.xcodeproj}
			;;
		esac
		if [ $rev -ge $STARTING_REVISION ] ; then
			cd $SVNDIR
			if ! svn revert -q -R . ; then
				for file in plugin_HTTP.cpp plugin_HTTP.h ; do
					mv /tmp/$file branches/gsoc_server_listing/plugins/plugin_utils/$file
				done
				svn status --no-ignore
			fi
			for ext in trunk/web/mainsite tags/v3_0_alpha1/web/mainsite tags/v3_0_alpha2/web/mainsite ; do
				if [ -d $ext/bans ] ; then
					# reference local copy of repo
					svn propset -q svn:externals "bans $SVN_REPO/trunk/admin" $ext
				fi
			done
			svn update -q -r $lastrev
			# undo keyword expansion, which Git does not support
			svn propdel -q -R svn:keywords .
			svn diff --ignore-properties | patch -s -p0 -R
			case $lastrev in
			    1833[3-9]|183[45]?|1836[0-8])
				# svn fails with "E135000: Inconsistent line ending style" on these files
				# correct plugin_HTTP.cpp MD5=3cfec4dd8bbdb6b4753c2720b41a1356
				# correct plugin_HTTP.h   MD5=be721291b3336256e08d127a35ba1b02
				for file in plugin_HTTP.cpp plugin_HTTP.h ; do
					mv branches/gsoc_server_listing/plugins/plugin_utils/$file /tmp	# save for later
					cp $SOURCE/$file branches/gsoc_server_listing/plugins/plugin_utils/$file
				done
			esac
			wait	# serialize before reading the Git tree
			diff -r -x .git -x .svn $GITDIR $SVNDIR
		fi
		lastrev=$rev
	fi
	lastdir=$dir
#	echo $rev $dir $repo ; continue
	echo -n "$rev "
	cd $GITDIR
	wait	# serialize before modifiying the Git tree
	case $rev in
	    1)
		mkdir branches tags trunk
		continue
		;;
	    14524|15902|16945|21393)
		# in Subversion only an empty directory was created, but
		# in Git it is simplest to branch with an unchanged file tree
		mkdir $dir
		continue
		;;
	    16016)
		mv tags/v2_0_10RC3 $dir
		continue
		;;
	    16946)
		# r19645 created an empty directory; now we will populate it
		rmdir $dir
		# fall through for normal processing
		;;
	    17409)
		mv branches/gsoc_08_libbzw $dir
		continue
		;;
	    17840|18373|18911|20677|22225)
		rm -r $dir &		# parallelize
		continue
		;;
	    18415)
		cd $BASE
		mv $GITDIR /var$GITDIR	# /tmp is almost full
		GITDIR=/var$GITDIR	# use /var/tmp from now on
		cd $GITDIR
		sync
		;;
	    18417)
		mkdir -p $dir/{d.sanders,h.reiser,i.szakats,j.bodine,k.kisielewicz,l.rewega} &	# parallelize
		continue
		;;
	    19307)
		# rebased in Git; place it correctly for the Subversion view
		cd $dir/libgcrypt
		git show :/$dir@$rev.$UPSTREAM_UUID | patch -s -p4
		cd $GITDIR
		continue
		;;
	    19450)
		# simulate the Subversion external link
		git clone -q --shared -b masterban $BASE/svn2git.$repo $dir/mainsite/bans &	# parallelize
		continue
		;;
	    21384)
		mkdir $dir
		mv branches/v2_0_cs_branch branches/v2_99_net_branch branches/v2_99_shot_branch $dir
		continue
		;;
	    21386)
		mkdir branches/release_maint branches/summer_of_code
		continue
		;;
	    21388)
		mv branches/gsoc_* $dir
		continue
		;;
	    21389|21392)
		rm -r `dirname $dir` &		# parallelize
		continue
		;;
	    21390)
		rm -r tags/v1_7temp `dirname $dir` &	# parallelize
		continue
		;;
	    21391)
		mv branches/v1_8 `dirname $dir`
		continue
		;;
	    21394)
		mv branches/v1_10branch `dirname $dir`
		continue
		;;
	    21395)
		mv trunk/bzflag $dir
		continue
		;;
	    21398)
		mv branches/v2_0branch `dirname $dir`
		# fall through for normal processing
		;;
	    21399)
		mv branches/v1_7 branches/v1_10 branches/v2_0 $dir
		continue
		;;
	    21401)
		GIT_DIR=$BASE/svn2git.$repo/.git git cat-file --textconv branch_note:BRANCHES.txt > $dir/BRANCHES.txt
		continue
		;;
	    22829)
		cd $dir
		git show ':/^Use only 1 level of square' | patch -s -p1
		continue
		;;
	    22830)
		cd $dir
		git show :/$dir@$rev.$UPSTREAM_UUID | patch -s -p1
		continue
		;;
	    99999)	# end marker
		continue
		;;
	esac
	if [ -d $dir ] ; then
		case $repo in
		    trash)
			rm -r $dir &	# parallelize
			continue
			;;
		    *)
			cd $dir
			;;
		esac
	else
		mkdir -p $dir
		cd $dir
		git clone -q --shared --no-checkout $BASE/svn2git.$repo .
	fi
	git checkout -q :/$dir@$rev.$UPSTREAM_UUID &	# parallelize
done
echo ''
