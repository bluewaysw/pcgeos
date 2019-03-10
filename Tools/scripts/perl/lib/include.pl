#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	include.pl
# AUTHOR: 	Paul Canavese, May  1, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	5/ 1/96   	Initial Revision
#
# DESCRIPTION:
#	Routines for finding and including the appropriate perl file,
#       based on whether we are being run from a local GEOS tree, and
#       if the file exists there.
#
#	$Id: include.pl,v 1.7 96/12/03 18:27:52 clee Exp $
#
###############################################################################

# Set the default path and the local geos paths.
#
$geosPath = $ENV{"ROOT_DIR"};
$geosPath =~ tr|\\|/|;	# Make it looks like Unix style.
$localgeospath = $ENV{"LOCAL_ROOT"};
$localgeospath =~ tr|\\|/|;	# Make it looks like Unix style.

1;

###############################################################################
# Include(<perl file>)
#
# <perl file> = full path of file to include
#
# If script was run from a local GEOS tree, and the specified file exists
# there, include it.  Otherwise, include the installed version.
#
# Returns: nothing
#
sub Include {

	# We were just given a filename

	if ( -f "$localgeospath/@_" ) {

	    require "$localgeospath/@_";
	    print("## Using local build file:\n");
	    print("##       $localgeospath/@_\n");

	} elsif ( -f "$geosPath/@_" ) {

	    require "$geosPath/@_";

	} elsif ( -f "$localgeospath/Tools/scripts/perl/lib/@_" ) {

	    require "$localgeospath/Tools/scripts/perl/lib/@_";
	    print("## Using local build file:\n");
	    print("##       $localgeospath/Tools/scripts/perl/lib/@_\n");

	} elsif ( -f "$geosPath/Tools/scripts/perl/lib/@_" ) {

	    require "$geosPath/Tools/scripts/perl/lib/@_";

	} else {

	    print("ERROR: Cannot find @_\n");
	    exit 1;
	}

}
