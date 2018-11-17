#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script (library)
# FILE: 	debug.pl
# AUTHOR: 	Paul Canavese, May  7, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	5/ 7/96   	Initial Revision
#
# DESCRIPTION:
#	Subroutines for handling general error, warning, and debugging 
#       functionality in perl scripts.
#
#	$Id: debug.pl,v 1.4 96/11/08 23:07:34 canavese Exp $
#
###############################################################################

$errorcount=0;
$warningcount=0;

1;

sub Error {
    local($line)=shift(@_);
    $errors .= "$line\n";
    &printreversefullline("ERROR: $line");
    foreach $line (@_) {
	&printreversefullline("       $line");
	$errors .= "$line\n";
    }
    $errorcount++;
    print "\n";
}

sub Warning {
    local($line)=shift(@_);
    $warnings .= "$line\n";
    &printreversefullline("WARNING: $line");
    foreach $line (@_) {
	&printreversefullline("         $line");
	$warnings .= "$line\n";
    }
    $warningcount++;
    print "\n";
}

sub PrintErrorsAndWarnings {

    if ( $errorcount ) {
	print "_____________________ Errors _____________________\n\n";
	if ( $errorcount>1 ) {
	    &printbold("There were $errorcount errors:\n");
	} else {
	    &printbold("There was 1 error:\n");
	}
	&printbold("$errors\n");
    } else {
	&printbold("No errors.\n");
    }
    if ( $warningcount ) {
	print "____________________ Warnings ____________________\n\n";
	if ( $warningcount>1 ) {
	    &printbold("There were $warningcount warnings:\n");
	} else {
	    &printbold("There was 1 warning:\n");
	}
	&printbold("$warnings\n");
    } else {
	&printbold("No warnings.\n");
    }
}




