#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) GlobalPC 1999.  All rights reserved.
#       GLOBALPC CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE: 	diffgeo.pl
# AUTHOR: 	, Aug 19, 1999
#
# REVISION HISTORY:
#	Name	        Date		Description
#	----	        ----		-----------
#	porteous	8/19/99   	Initial Revision
#       dhunter         5/12/2000       Performance enhancement
#
# DESCRIPTION:
#	compare two geodes ignoring differences that do not matter.
#
#	$Id$
#
###############################################################################

1;
use Cwd;

sub compare {
    my ($file1, $file2) = @_;
    my $pos = 0;
    my $done = 0;
    my $buflen = 512;

    open(A, $file1) or return true;
    open(B, $file2) or return true; 
    binmode A;
    binmode B;

    while (!(eof A) and !(eof B) and !$done) {
	$i = (read A, $charA, $buflen);
	$j = (read B, $charB, $buflen);
	$done = ($i != $j);
	if (!$done) {
	    @listA = unpack "c$i", $charA;
	    @listB = unpack "c$i", $charB;
	    if ($pos == 0 && $i > 387) {
		$done = (checkrange(\@listA, \@listB, 0, 43)
		    or checkrange(\@listA, \@listB, 52, 199)
		    or checkrange(\@listA, \@listB, 204, 285)
		    or checkrange(\@listA, \@listB, 294, 297)
		    or checkrange(\@listA, \@listB, 300, $i-1));
	    } else {
		$done = ($i != $j);
		if (!$done) {
		    for ($i = 0; $i < scalar @listA; $i++) {
			$done = 1 if (@listA[$i] != @listB[$i]);
		    }
		}
	    }
	}
	$pos += $buflen;
    }
    $done ||= !((eof A) and (eof B));
    close A;
    close B;
    return $done ? true : false;
}

sub checkrange {
    my ($a, $b, $x, $y) = @_;
    my $i;
    my $done = 0;

    for ($i = $x; $i <= $y && !$done; $i++) {
	$done = 1 if (@$a[$i] != @$b[$i]);
    }
    return $done;
}
