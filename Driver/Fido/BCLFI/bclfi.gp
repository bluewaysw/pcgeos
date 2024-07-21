##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Legos
# MODULE:	Fido input drivers
# FILE:		vmfi.gp
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
#	$Revision:   1.1  $
#
###############################################################################
#
name vmfi.drvr
#
longname "Fido VM Input Driver"
#
type	driver, single

#export just so we get an ldf and can then force load through .gp file
export  VMFIOpen

#
# FIDR is taken by fax input
#

tokenchars "Finp"
tokenid 0
#
library	geos
library ansic
#
# Fixed code resource for strategy routine
#
resource ResidentCode fixed code read-only shared

