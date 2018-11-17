##############################################################################
#
#	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved
#
# PROJECT:	Breadbox Home Automation
# MODULE:	X10 Power Code Driver
# FILE:		X10drvr.gp
#
# AUTHOR:	Fred Goya
#
##############################################################################
#
name x10code.drvr
#
longname "X-10 Code Driver"
#
type	driver, single
#
# this token must match both the token in the GenApplication and the
# token in the GenUIDocumentControl
#
tokenchars "X10D"
tokenid 0
#
library	geos

#
resource ResidentCode fixed code
#
