##############################################################################
#
#	Copyright (c) 2000 Dirk Lausecker -- All Rights Reserved
#
# PROJECT:	BestSound
# DATEI:	bsd16.gp
#
# AUTHOR:       Dirk Lausecker
#
##############################################################################
#
name bsd16.drvr
#
longname "Soundblaster 16 driver"
#
type	driver, single

# platform geos20
#

tokenchars "SNDD"
tokenid 0
#
library	geos

driver stream
#
resource ResidentCode fixed code

#
usernotes "\xa9 2000 Dirk Lausecker"
