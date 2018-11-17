#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Tools
# FILE: 	branch.pl
# AUTHOR: 	Paul Canavese, Aug 15, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	PC	8/15/96   	Initial Revision
#
# DESCRIPTION:
#	Branch subroutines.
#
#	$Id: branch.pl,v 1.5 96/12/16 22:40:05 canavese Exp $
#
###############################################################################


1;

##############################################################################
#	Branch
##############################################################################
#
# SYNOPSIS:	Returns branch name of the passed (or current) tree.
# PASS:		[<directory>]
# CALLED BY:	global
# RETURN:	branch name if successful, else null
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       PC 	8/15/96   	Initial Revision
#
##############################################################################
sub Branch {

    # Determine directory to diagnose.

    local($currentdir, $topdir, $branch);
    if ( "@_" ) {
        $currentdir="@_";
    } else {
        chop($currentdir=`pwd`);
    }

    # Determine top directory.

    $rootdir=$currentdir;
    if ( $rootdir eq "/staff/pcgeos" ) {
        return "Trunk";
    }
    $rootdir=~s|(.*/pcgeos/[^/]*)/.*$|\1|;

    # Determine branch.

    $_="$rootdir";
    if ( ! /pcgeos/ ) {
        return 0;
    } else {

        if ( -f "$rootdir/BRANCH" ) {
            chop($branch=`cat $rootdir/BRANCH`);
        } else {
            $branch="Trunk";
        }
        return "$branch";
    }
}


##############################################################################
#	OtherIDir
##############################################################################
#
# SYNOPSIS:	Returns equivalent Installed directory for the passed (or 
#               current) dir.
# PASS:		[<directory>]
# CALLED BY:	global
# RETURN:	directory name (or null on error)
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       PC 	8/15/96   	Initial Revision
#
##############################################################################
sub OtherIDir {

    # Determine directory to diagnose.

    local($currentdir, $branch);
    if ( "@_" ) {
        $currentdir="@_";
    } else {
        chop($currentdir=`pwd`);
    }

    # Find branch.

    $branch=&Branch("$currentdir");
    if ( ! "$branch" ) {
	#print "Error: not in GEOS source tree\n";
	return 0;
    }

    # Determine other directory
	
    $_=$currentdir;
    if ( m|/Installed\b| ) {
	s|/Installed||;
    } elsif ( m|/pcgeos/[A-Z]| ) {
	if ( $branch eq "Trunk" ) {
	    s|^.*/pcgeos/|/staff/pcgeos/Installed/|;
	} else {
	    s|^.*(/pcgeos/[^/]*)[/]|/staff\1/Installed/|;
	    s|^.*(/pcgeos/[^/\n\0]*)$|/staff\1/Installed/|;
	}
    } else {
	if ( "$_" eq "/staff/pcgeos" ) {
	    $_.="/Installed";
	} else {
	    #print "Error: not in GEOS source tree\n";
	    return 0;
	}
    }		     

    # Get rid of training /, if it exists.

    s|/$||;

    return "$_";
}
