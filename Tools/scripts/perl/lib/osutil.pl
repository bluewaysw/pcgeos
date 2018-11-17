#!/usr/public/perl5
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE: 	osutil.pl
# AUTHOR: 	Chris Lee, Nov 27, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	clee	11/27/96   	Initial Revision
#
# DESCRIPTION:
#	
# Provide some convenient utilities for writing specific Unix or Win32 (NT) 
# code. Right now, we only support Unix and NT, so IsUnix() and IsWin32() are
# are simple. They might get more complicated if we support more systems.
#
#	$Id: osutil.pl,v 1.1 96/12/03 18:28:35 clee Exp $
#
###############################################################################
1;

##############################################################################
#	IsUnix
##############################################################################
#
# SYNOPSIS:	Check if we are running on Unix system.
# PASS:		nothing
# CALLED BY:	GLOBAL
# RETURN:	1  if running on Unix
#               "" if NOT running on Unix
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/27/96   	Initial Revision
#
##############################################################################
sub IsUnix {
    return $ENV{"OS"} ne "Windows_NT";
}

##############################################################################
#	IsWin32
##############################################################################
#
# SYNOPSIS:	Check if we are running on Win32 system.
# PASS:		nothing
# CALLED BY:	GLOBAL
# RETURN:	1 if running on Win32 system
#               "" if NOT running on Win32 system
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/27/96   	Initial Revision
#
##############################################################################
sub IsWin32 {
    return $ENV{"OS"} eq "Windows_NT";
}
