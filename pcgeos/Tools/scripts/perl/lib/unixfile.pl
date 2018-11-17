#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Tools
# FILE: 	unixfile.pl
# AUTHOR: 	Paul Canavese, Aug 15, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	PC	8/15/96   	Initial Revision
#
# DESCRIPTION:
#	General UNIX file utilities.
#
#	$Id: unixfile.pl,v 1.3 96/10/08 14:17:58 jeremyb Exp $
#
###############################################################################

1;

##############################################################################
#	MakePath
##############################################################################
#
# SYNOPSIS:	Create <path> if it does not exist.
# PASS:		<path>
# CALLED BY:	global
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       PC 	8/15/96   	Initial Revision
#
##############################################################################
sub MakePath {

    local($passedpath)=@_;
    if ( -d "$passedpath" ) {
	return 0;
    }

    local($directory, $path);
    if ( $passedpath =~ m|^/| ) {		# Cut off the starting slash.
	$passedpath =~ s|^/||;
	$path="/";
    }

    foreach $directory (split('/', "$passedpath")) {

	# We presume that if the DOS name of the directory matches, it is
	# a match.

	if ( ! -d "$path$directory" ) {
	    local($result)=system("mkdir $path$directory");
	    if ( "$result" ) {
		return $result;
	    }
	}
	$path .= "$directory/";
    }
}    

##############################################################################
#	FullPathToFile
##############################################################################
#
# SYNOPSIS:	Returns filename from a fullpath
# PASS:		<path>
# CALLED BY:	global
# RETURN:	filename
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	9/ 3/96   	Initial Revision
#
##############################################################################
sub FullPathToFile {
    local($fullpath)=@_;
    $fullpath=~s|.*/([^/]*)$|$1|;
    return("$fullpath");
}
