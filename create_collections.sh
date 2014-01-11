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

for repo in admin bzauthd bzedit bzeditw32 bzstats bzview bzwgen bzworkbench custom_plugins db pybzflag tools web bzflag ; do
	date "+$repo started %c"
	svn2git.sh $repo
	status=$?
	if [ $status -ne 0 ] ; then
		echo $repo: status $status
	fi
done
date
