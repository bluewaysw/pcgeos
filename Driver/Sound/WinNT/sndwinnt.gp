##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS Sound System
# MODULE:	Sound Driver (Standard)
# FILE:		standard.gp
#
# AUTHOR:	Todd Stumpf, Aug  5, 1992
#
#	$Id: sndwinnt.gp,v 1.1 97/04/18 11:57:57 newdeal Exp $
#
#
##############################################################################
#
name ntstandardsound.drvr
#
longname "NT Standard Sound Driver"
#
type	driver, single
#
# this token must match both the token in the GenApplication and the
# token in the GenUIDocumentControl
#
tokenchars "SNDD"
tokenid 0
#
library	geos
#
resource ResidentCode fixed code read-only
#
#
# XIP-enabled
#

