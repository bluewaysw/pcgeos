##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Legos
# MODULE:	Fido input drivers
# FILE:		flatfi.gp
# AUTHOR:	Paul L. DuBois
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dubois	 1/20/95	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Revision:   1.0  $
#
###############################################################################
#
name flatfi.drvr
#
longname "Fido Flat-file Input Driver"
#
type	driver, single

#export just so we get an ldf and can then force load through .gp file
export  FFIOpen

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

