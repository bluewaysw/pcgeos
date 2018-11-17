#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1997.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	nt tools
# MODULE:	rgrep
# FILE: 	rgrep-helper.pl
# AUTHOR: 	Tim Bradley, Mar 10, 1997
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	tbradley	3/10/97   	Initial Revision
#
# DESCRIPTION:
#	Attempting to make rgrep faster by spawning the grep operation off to
#       a separate process and then overlapping cpu time.
#
#	$Id: rgrep-helper.pl,v 1.1 97/05/02 11:51:14 tbradley Exp $
#
###############################################################################

#first get the pattern
$pat = shift @ARGV;

# if there's another argument, then we're ignorin' case
$ignorecase = shift @ARGV;

if ($ignorecase) {
    while ($file = <STDIN>) {
	$file =~ s/\s+$//o;
	
	open(FILE, $file);
	$line = 1;

	while(<FILE>) {
	    print "$file: $line: $_" if (m/$pat/oi);
	    $line++;
	}
    }
} else {
    while ($file = <STDIN>) {
	$file =~ s/\s+$//o;
	
	open(FILE, $file);
	$line = 1;

	while(<FILE>) {
	    print "$file: $line: $_" if (m/$pat/o);
	    $line++;
	}
    }
}



