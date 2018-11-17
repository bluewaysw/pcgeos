##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Sound Driver
# FILE:		soundblaster.gp
#
# AUTHOR:	Todd Stumpf, Aug  5, 1992
#
#
# 
#
#	$Id: sblaster.gp,v 1.1 97/04/18 11:57:41 newdeal Exp $
#
##############################################################################
#
name sblaster.drvr
#
longname "Sound Blaster Driver"
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

driver stream
#
resource ResidentCode fixed code
#
