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

BASE=/tmp
UPSTREAM_REPO=https://svn.code.sf.net/p/bzflag/code
UPSTREAM_UUID=08b3d480-bf2c-0410-a26f-811ee3361c24
SVN_REPO=file:///scratch/bzflag/bzflag.svn	# $UPSTREAM_REPO will be slower

svn log --xml $SVN_REPO | sed -e 's=\.[0-9][0-9][0-9][0-9][0-9][0-9]Z</date>=Z</date>=' -e 's=\(.\)</msg>=\1\n</msg>=' -e 's/>JeffM2501</>jeffm2501</' -e 's/  *$//' > $BASE/log.svn

for repo in bzflag-bzflag bzflag-archive bzflag-tools bzflag-web bzworkbench ; do
	cd $BASE/svn2git.$repo
	git log --date=iso --all --grep=git-svn-id:
done | `dirname $0`/git_log_to_xml.pl > $BASE/log.git
