#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:      
# FILE: 	prettyprint.pl
# AUTHOR: 	Paul Canavese, Oct 31, 1996
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	canavese	10/31/96   	Initial Revision
#
# DESCRIPTION:
#	Routines for printing out text with styles in certain terminals.
#
#	$Id: prettyprint.pl,v 1.1 96/11/08 23:08:32 canavese Exp $
#
###############################################################################

1;

##############################################################################
#	printbold
##############################################################################
#
# SYNOPSIS:	Print the passed string in bold text.
# PASS:		<string>
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub printbold {
    local($string) = @_;
    if ( $ENV{TERM} eq "xterm" ) {
	print "\e[1m$string\e[m";
    } else {
	print "$string";
    }
}


##############################################################################
#	printunderline
##############################################################################
#
# SYNOPSIS:	Print the passed string in underlined text.
# PASS:		<string>
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub printunderline {
    local($string) = @_;
    if ( $ENV{TERM} eq "xterm" ) {
	print "\e[4m$string\e[m";
    } else {
	print "$string";
    }
}

##############################################################################
#	printreverse
##############################################################################
#
# SYNOPSIS:	Print the passed string in reversed text.
# PASS:		<string>
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub printreverse {
    local($string) = @_;
    if ( $ENV{TERM} eq "xterm" ) {
	print "\e[7m$string\e[m";
    } else {
	print "$string";
    }
}


##############################################################################
#	printreversefullline
##############################################################################
#
# SYNOPSIS:	Print a string on a fully-reversed line.
# PASS:		<string>
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub printreversefullline {
    local($string)=@_;
    if ( $ENV{TERM} eq "xterm" ) {
	local($rows,$columns)=split(/ /,`stty size`);
	local($spaces)=$columns-length($string);
	if ( $spaces > 0 ) {
	    $string .= " " x $spaces;
	}
    }
    &printreverse("$string\n");
}

