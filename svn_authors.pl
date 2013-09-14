#!/usr/bin/perl -w
use strict;
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

# From a Subversion repository generate an authors-file with
# synthesized @users.sourceforge.net e-mail addresses, suitable
# for use by git-svn.

my ($email, $name, %list);

my $repo = shift @ARGV;
die "Usage: $0 subversion_repo_url\n       (perhaps https://svn.code.sf.net/p/bzflag/code)\n" unless (defined $repo);

# extract author account names from "svn log" output
open(SVNLOG, "svn log -r 0:HEAD $repo|") or die "svn: $!\n";
while (<SVNLOG>) {
    if (/^r\d+ \| ([^|]+) \| .* lines?$/) {
	if ($1 eq '(no author)') {
	    $name = 'cvs2svn';
	    $email = 'davidtrowbridge';	# he did the CVS->SVN conversion
	    }
	else {
	    $name = $email = lc $1;
	    }
	$list{$1} = "$name <$email";
	}
    }
close SVNLOG or warn"svn: $!\n";

# print one instance of each author mapping
foreach (sort keys %list) {
    print "$_ = $list{$_}\@users.sourceforge.net>\n";
    }
