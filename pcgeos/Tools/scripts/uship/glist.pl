#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	Tools
# MODULE:	ubership
# FILE: 	glist.pl
# AUTHOR: 	Jacob A. Gabrielson, Jan 18, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	JAG	1/18/96   	Initial Revision
#
# DESCRIPTION:
#	This engine is used to maintain lists of stuff that would otherwise
#	have to be directly encoded in the uship script.
#
#	$Id: glist.pl,v 1.3 96/01/30 20:19:08 stevey Exp $
#
###############################################################################

package glist;

$GLIST_START_REGEXP	= "^$GLIST_REGEXP" . '.*:\s*$';
$BLANK_LINE_REGEXP	= '^\s*$';
$COMMENT_REGEXP		= '^\s*\#';
$LIST_ELEMENT_REGEXP	= '^\s+[^\s]+';

1;

#
# Exported subroutines
#

##############################################################################
#	glist_Init
##############################################################################
#
# SYNOPSIS:	Must be called before any other glist routines.  Pass in 
#		the filename of the database.
# PASS:		$file	= file name of glist database
# CALLED BY:	(GLOBAL)
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JAG 	9/28/95   	Initial Revision
#
##############################################################################
sub main'glist_Init {
    local($file) = @_;
    local($pos);
    local(@glists);
    local($glist);

    open(DB, "<$file") || die "Cannot open DB file '$file'.\n";

    ## Get location of all the keys.
    $pos = tell DB;
    while (<DB>) {

	## Throw away blank lines and comments.
	if (/$BLANK_LINE_REGEXP/ || /$COMMENT_REGEXP/) {
	    $pos = tell DB;
	    next;
	}

	## Keys are on lines that look like "soli solitaire sol:".
	if (/$GLIST_START_REGEXP/) {

	    ## Remove the trailing ":".
	    s/:\s*$//;

	    ## Split the keys up into their requisite parts.
	    @glists = split(' ');

	    ## Save location in file of this key for later use.
	    foreach $glist (@glists) {
		$glistToFilePos{$glist} = $pos;
	    }
	}

	$pos = tell DB;
    }
}


##############################################################################
#	glist_Exit
##############################################################################
#
# SYNOPSIS:	Call this before exiting your app (duh).
# PASS:		nothing
# CALLED BY:	(GLOBAL)
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JAG 	9/28/95   	Initial Revision
#
##############################################################################
sub main'glist_Exit {
    close DB;
}

##############################################################################
#	glist_GetListAsString
##############################################################################
#
# SYNOPSIS:	Given a key, return all the elements of the list in one
#		big ol' string (elements are space-separated)
# PASS:		glist	= keyword to get list for
# CALLED BY:	(GLOBAL)
# RETURN:	string
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JAG 	1/18/96   	Initial Revision
#
##############################################################################
sub main'glist_GetListAsString {
    local($glist) = @_;
    local($oldpos);
    local($retString);
    local($string);

    ## Make sure the glist is defined in this DB.
    die "'$glist' is not defined in the geodeList file.\n"
	if (!$glistToFilePos{$glist});

    ## To make this routine recursive, we must not trash the file position.
    $oldpos = tell DB;

    ## Go to start of DB for this glist.
    seek(DB, $glistToFilePos{$glist}, 0);

    ## Skip first line (it'll be $GLIST_START_REGEXP).
    <DB>;

    ## Now evaluate all th' variables.
    while(<DB>) {

	## Stop if we bump into the next glist's data.
	last if (/$GLIST_START_REGEXP/);

	## Ignore blank lines and comments.
	next if (/$BLANK_LINE_REGEXP/);
	next if (/$COMMENT_REGEXP/);

	#
	# Otherwise look for any non-blank line that starts with 
	# whitespace.
	#
	if (/$LIST_ELEMENT_REGEXP/) {
	    #
	    # Split the line, which may have multiple keywords on it,
	    # into separate strings.  Expand all the strings that
	    # begin with @.
	    #
	    # Then add the resulting shme to $retString with exactly
	    # 1 space prepended.
	    #
	    foreach $string (split) {
		next if length $string < 1;
		if ($string =~ s/^@//) {
		    ## Recursively expand strings that began with '@'.
		    $retString .= 
			' ' . &main'glist_GetListAsString($string); #'
		} else {
		    ## Append the line into our big ol' return value.
		    $retString .= ' '. $string;
		}
	    }
	}
    }

    #
    # Remove leading whitespace.
    #
    $retString =~ s/^\s+//og;

    ## This should be the only exit point!
    seek(DB, $oldpos, 0);

    return $retString;
}

##############################################################################
#	glist_Expand
##############################################################################
#
# SYNOPSIS:	Expand several keywords into a single space-separated list.
# PASS:		as many args as you like, each one should be a string
# CALLED BY:	(GLOBAL)
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JAG 	1/18/96   	Initial Revision
#
##############################################################################
sub main'glist_Expand {
    local(@args) = @_;
    local($arg);
    local($glist);
    local($retString);

    foreach $arg (@args) {
	## Allow an arg to be a space-separated list, just for fun.
	foreach $glist (split('\s', $arg)) {
	    ## Add an extra space at the end so it doesn't run into
	    ## the next entry.
	    $retString .= &main'glist_GetListAsString($glist) . " "; #'
	}
    }

    ## Remove trailing whitespace.
    $retString =~ s/\s+$//og;

    return $retString;
}
