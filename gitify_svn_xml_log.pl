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

use File::Basename ('dirname');
use XML::LibXML;

# Get the list of Subversion commits that are not it Git at all.
my %not_in_git;
my $revlist = (dirname $0) . '/revision_list';
open(REVISIONS, '<', $revlist) or die "$revlist: $!\n";
while (<REVISIONS>) {
	if (/^(\d+),tidy,/) {
		$not_in_git{$1} = 0 unless ($1 == 22830);
		}
	}
close REVISIONS or warn "Cannot close $revlist: $!\n";

my $tree = XML::LibXML->new()->parse_fh('STDIN');
my $root = $tree->getDocumentElement;
my $rootname = $root->getName;
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<$rootname>\n";
my $childname = 'logentry';
foreach my $logentry ($root->getElementsByTagName($childname)) {
	my $revision = $logentry->getAttribute('revision');
	next if (defined $not_in_git{$revision});
	my %elements = ();
	foreach my $element (qw(author date msg)) {
		my @element_list = $logentry->getElementsByTagName($element);
		if (scalar @element_list == 1) {
			my $e = $element_list[$[]->getFirstChild;
			$elements{$element} = $e->getData if (defined $e);
			}
		}
	if (defined $elements{author}) {
		$elements{author} = lc "<author>$elements{author}</author>\n"
		}
	else {
		$elements{author} = '';	# e.g., cvs2svn
		}
	$elements{date} =~ s/\.\d{6}Z$/Z/;
	# need UTF-8 (2 bytes) instead of ISO-8859-1 (1 byte) encoding
	my $msg = $elements{msg} || '';	# ensure it is defined
	$msg =~ s/^\n+//;		# remove leading newlines
	$msg =~ s/ +\n/\n/g;		# remove spaces at the end of lines
	$msg =~ s/\s+$//;		# remove whitespace at the end
	$msg =~ s/&/&amp;/g;
	$msg =~ s/</&lt;/g;
	$msg =~ s/>/&gt;/g;
	print "<$childname\n   revision=\"$revision\">\n$elements{author}<date>$elements{date}</date>\n<msg>$msg</msg>\n</$childname>\n";
	}
print "</$rootname>\n";
