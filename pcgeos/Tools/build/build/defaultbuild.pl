#!/usr/public/perl5
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	Build tool tool
# FILE: 	defaultbuild.pl
# AUTHOR: 	Paul Canavese, Nov  9, 1996
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	canavese	11/ 9/96   	Initial Revision
#
# DESCRIPTION:
#	Grep through the entries in the default.build file for a matching
#       string.
#
#	$Id: defaultbuild.pl,v 1.2 96/12/05 19:04:17 canavese Exp $
#
###############################################################################

open(DEFAULTBUILD,"/staff/pcgeos/Tools/build/product/Common/default.build");

# Look until we find the first entry.

while ( <DEFAULTBUILD> ) {
    if ( !/^\#|^$/ ) {
	last;
    }
}

$entry=$_;
while ( <DEFAULTBUILD> ) {    
    if ( /^\S/ ) {
	&DoGrep($entry);
	if ( !/^\#/ ) {
	    $entry=$_;		# Start new entry.
	} else {
	    $entry="";
	}
    } else {
	$entry.=$_;
    }
}

&DoGrep($entry);


sub DoGrep {
    my ($entry) = @_;
    $*=1;
    foreach $matcher ( @ARGV ) {
	if ( grep(/$matcher/i, $entry )) {
	    print $entry;
	    return 0;
	}			 
    }
    $*=0;
}

