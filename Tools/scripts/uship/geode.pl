#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	Tools
# MODULE:	Geode Database Engine
# FILE: 	geode.pl
# AUTHOR: 	Jacob Gabrielson, Sep 28, 1995
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	JAG	9/28/95   	Initial Revision
#
# DESCRIPTION:
#	Routines for searching a database of geode info.  Can be used to
#	replace all or part of ship, pcs, send, etc.
#
#	$Id: geode.pl,v 1.3 96/01/18 21:46:51 jacob Exp $
#
###############################################################################

package geode;

## Constants.

$GEODE_REGEXP		= '([a-zA-Z]+)';
$GEODE_START_REGEXP	= "^$GEODE_REGEXP" . '.*:\s*$';
$BLANK_LINE_REGEXP	= '^\s*$';
$COMMENT_REGEXP		= '^\s*\#';
$CONDITION_REGEXP	= '\(([^\)]+)\)';
$VAR_REGEXP		= '([^\s=(]+)';

1;

#
# Exported subroutines
#

##############################################################################
#	geode_Init
##############################################################################
#
# SYNOPSIS:	Must be called before any other geode routines.  Pass in 
#		the filename of the database.
# PASS:		$file	= file name of geode database
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
sub main'geode_Init {
    local($file) = @_;
    local($pos);
    local(@geodes);
    local($geode);

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
	if (/$GEODE_START_REGEXP/) {

	    ## Remove the trailing ":".
	    s/:\s*$//;

	    ## Split the keys up into their requisite parts.
	    @geodes = split(' ');

	    ## Save location in file of this key for later use.
	    foreach $geode (@geodes) {
		## Warn user if key is multiply defined.
		warn "warning: $geode multiply defined in '$file'\n"
		    if defined $geodeToFilePos{$geode};

		$geodeToFilePos{$geode} = $pos;
	    }
	}

	$pos = tell DB;
    }
}

##############################################################################
#	geode_Exit
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
sub main'geode_Exit {
    close DB;
}

##############################################################################
#	geode_LoadInfo
##############################################################################
#
# SYNOPSIS:	Loads up all the variables associated with the geode 
#		passed in.
# PASS:		prod		= string of whitespace-separated product
#				  definitions (e.g. "jediGFSProduct ecOn",
#				  basically stuff from the Products 
#				  of geode.db)
#		geode		= keyword of geode to get info for
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
sub main'geode_LoadInfo {
    local($prod, $geode) = @_;
    local($p);

    ## Go thru all the variables and undef 'em.
    foreach $var (keys %transientVar) {
	eval "undef \$$var";
    }
    undef %transientVar;

    &load("preDefaults");

    # Set up all the product-specific variables.
    foreach $p (split(' ', $prod)) {
	&load($p);
    }
    &load($geode);
    &load("postDefaults");
}

#
# Internal subroutines
#

##############################################################################
#	load
##############################################################################
#
# SYNOPSIS:	Load in info about a geode.
# PASS:		geode	= geode keyword to get info about
# CALLED BY:	(INTERNAL)
# RETURN:	nothing
# SIDE EFFECTS:	Sets a bunch of Perl variables (whatever the keyword 
#		defined).
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JAG 	9/28/95   	Initial Revision
#
##############################################################################
sub load {
    local($geode) = @_;
    local($oldpos);

    ## Make sure the geode is defined in this DB.
    die "'$geode' is not defined in the DB file.\n"
	if (!$geodeToFilePos{$geode});

    ## To make this routine recursive, we must not trash the file position.
    $oldpos = tell DB;

    ## Go to start of DB for this geode.
    seek(DB, $geodeToFilePos{$geode}, 0);

    ## Skip first line (it'll be $GEODE_START_REGEXP).
    <DB>;

    ## Now evaluate all th' variables.
    while(<DB>) {

	## Stop if we bump into the next geode's data.
	last if (/$GEODE_START_REGEXP/);

	## Ignore blank lines and comments.
	next if (/$BLANK_LINE_REGEXP/);
	next if (/$COMMENT_REGEXP/);

	## Handle "inherit(<condition>)=<geode>".
	if (/\s+inherit\s*$CONDITION_REGEXP\s*=\s*$GEODE_REGEXP/) {
	    &load($2) if eval $1;
	}

	## Handle "inherit=<geode>".
	elsif (/\s+inherit\s*=\s*($GEODE_REGEXP)/) {
	    &load($1);
	}

	## Handle "<var>(<condition>)=<stuff>".
	elsif (/\s+$VAR_REGEXP\s*$CONDITION_REGEXP\s*=(.*)/) {
	    
	    #
	    # Evaluate the condition.  If it's true, then do the assignment
	    # if the variable is not already defined.
	    #
	    if (!$transientVar{$1} && eval $2) {
		eval "\$$1 = \"$3\"";
		$transientVar{$1} = 1;
	    }

	}

	## Handle "<var>=<stuff>".
	elsif (/\s+$VAR_REGEXP\s*=(.*)/) {
	    if (!$transientVar{$1}) {
		eval "\$$1 = \"$2\"";
		$transientVar{$1} = 1;
	    }
	}
    }

    ## This should be the only exit point!
    seek(DB, $oldpos, 0);
    return;
}
