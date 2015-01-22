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
rm -rf $GITDIR $SVNDIR
mkdir $GITDIR
lastrev=1
svn checkout -q $SVN_REPO@$lastrev $SVNDIR	# empty tree

for repo in $REPO_LIST ; do
	# use awk to remove UPSTREAM_REPO/ and to convert @ to a space
	GIT_DIR=$BASE/svn2git.$repo/.git git log --all | awk \$1==\"git-svn-id:\"\&\&\$3==\"$UPSTREAM_UUID\"\{print\ gensub\(\"@\",\"\ \",1,gensub\(\"$UPSTREAM_REPO/\",\"\",1,\$2\)\),\"$repo\"\} 
done | sort -n -k2 | while read dir rev repo ; do
	if [ $rev -gt $lastrev ] ; then
		if [ $rev -ge $STARTING_REVISION ] ; then
			cd $SVNDIR
			svn revert -q -R .
			svn up -q -r $lastrev
			svn propdel -q -R svn:keywords .
			wait	# serialize
			svn diff --ignore-properties | patch -s -p0 -R
			diff -r -x .git -x .svn $GITDIR $SVNDIR
		fi
		lastrev=$rev
	fi
	case $dir in
	    branches|branches/gamestats_live|branches/gsoc_bzauthd_db|trunk*)
		realdir=$dir
		;;
	    *)
		realdir=$dir/bzflag
		;;
	esac
#	echo $rev $realdir $repo
	echo -n "$rev "
	cd $GITDIR
	case $rev in
	    1)
		mkdir branches tags trunk
		continue
		;;
	esac
	if [ -d $realdir ] ; then
		cd $realdir
	else
		mkdir -p $realdir
		cd $realdir
		git clone -q --shared $BASE/svn2git.$repo .
	fi
	wait	# serialize
	git checkout -q :/$dir@$rev.$UPSTREAM_UUID &	# parallelize
done
echo ''
