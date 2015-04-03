#!/usr/bin/perl -T -w
use strict;
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

my ($revision, $author, $date, $msg, @entries);

sub add_log_entry()
{
if (defined $author) {
	$author = "<author>$author</author>\n";
	}
else {
	$author = '';
	}
$msg =~ s/^\n//;
chomp $msg;
chomp $msg;
chomp $msg;
$msg =~ s/&/&amp;/g;
$msg =~ s/</&lt;/g;
$msg =~ s/>/&gt;/g;
$entries[$revision] = "<logentry\n   revision=\"$revision\">\n$author<date>$date</date>\n<msg>$msg</msg>\n</logentry>\n";
$revision = $author = $date = $msg = undef;
}

while (<>) {
	if (/^commit [0-9a-f]{40}$/) {
		# flush previous
		add_log_entry if (defined $revision or defined $date or defined $msg);
		}
	elsif (/^Merge: [0-9a-f]{7} [0-9a-f]{7}$/) {
		# ignore
		}
	elsif (/^Author: ([^<]+) <([^\@]+)\@users\.sourceforge\.net>$/) {
		if ($1 ne 'cvs2svn') {
			$author = ($1 eq 'uid125564') ? $1 : $2;
			}
		}
	elsif (/^Date:   (\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d) \+0000$/) {
		$date = "$1T${2}Z";
		}
	elsif (m=^    git-svn-id: https://svn.code.sf.net/p/bzflag/code/[^\@]+@(\d+) 08b3d480-bf2c-0410-a26f-811ee3361c24$=) {
		$revision = $1;
		}
	else {
		s/^    //;
		$msg .= $_;
		}
	}
add_log_entry;
print '<?xml version="1.0" encoding="UTF-8"?>', "\n<log>\n";
for my $ent (reverse @entries) {
	print $ent if (defined $ent);
}
print "</log>\n";
