##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS Sound System
# MODULE:	Tandy Sound Driver (Zoomer)
# FILE:		tandy.gp
#
# AUTHOR:	Todd Stumpf, Nov. 19th, 1992
#
#	$Id: tandy.gp,v 1.1 97/04/18 11:57:45 newdeal Exp $
#
##############################################################################
#
name casiosnd.drvr
#
longname "Tandy 1000 Sound Driver"
#
type	driver, single
#
#
tokenchars "SNDD"
tokenid 0
#
library	geos
driver	stream
#
resource ResidentCode fixed code
#
