#!/bin/sh -e
# bzflag
# Copyright (c) 1993-2013 Tim Riker
#
# This package is free software;  you can redistribute it and/or
# modify it under the terms of the license found in the file
# named COPYING that should have accompanied this file.
#
# THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# Generate a preliminary list of the revisions in the BZFlag
# Subversion repository that are for things other than the game
# itself.  Doing this requires looking into the innards of a local
# copy of the Subversion repo.
(
cd /scratch/bzflag/bzflag.svn/db/revs
grep -a '^cpath: /trunk/[^/]*$' */* | sed -e '/\/bzflag$/d' -e 's=:cpath: /trunk/=,=' -e 's=.*/==' -e 's=$=,auto,,='
grep -a '^cpath: /branches/gsoc_bzauthd[^/]*$' */* | sed -e 's=:cpath: /branches/gsoc_bzauthd.*=,bzauthd,auto,,=' -e 's=.*/=='
) | sort -n
