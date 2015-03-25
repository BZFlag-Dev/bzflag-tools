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

use XML::LibXML;

my $tree = XML::LibXML->new()->parse_fh('STDIN');
my $root = $tree->getDocumentElement;
my $rootname = $root->getName;
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<$rootname>\n";
my $childname = 'logentry';
foreach my $logentry ($root->getElementsByTagName($childname)) {
	my $revision = $logentry->getAttribute('revision');
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
		$elements{author} = '';
		}
	$elements{date} =~ s/\.\d{6}Z$/Z/;
	$elements{msg} =~ s/^\n+//;
	$elements{msg} =~ s/\s+$//;
	$elements{msg} =~ s/&/&amp;/g;
	$elements{msg} =~ s/</&lt;/g;
	$elements{msg} =~ s/>/&gt;/g;
	print "<$childname\n   revision=\"$revision\">\n$elements{author}<date>$elements{date}</date>\n<msg>$elements{msg}</msg>\n</$childname>\n";
	}
print "</$rootname>\n";
