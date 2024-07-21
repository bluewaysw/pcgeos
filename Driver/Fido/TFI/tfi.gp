##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Fido I/O drivers
# FILE:		tb.gp
#
# AUTHOR:	Paul DuBois, Nov 29, 1994
#
#	$Revision:   1.1  $
#
##############################################################################
#
name tfi.drvr
#
longname "Fido Text Input Driver"
#
type	driver, single
#
# FIDR is taken by fax input
#
tokenchars "Finp"
tokenid 0
#
library	geos
#
# Fixed code resource for strategy routine
#
resource ResidentCode fixed code read-only shared

