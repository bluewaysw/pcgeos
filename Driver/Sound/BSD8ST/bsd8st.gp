##############################################################################
#
#	Copyright (c) 2000 Dirk Lausecker -- All Rights Reserved
#
# PROJECT:	BestSound
# DATEI:	bsd8st.gp
#
# AUTHOR:       Dirk Lausecker
#
##############################################################################
#
name bsd8st.drvr
#
longname "Soundblaster Pro driver"
#
type	driver, single

# platform geos20
#

tokenchars "SNDD"
tokenid 0


#
# tokenchars "BSDD"
# tokenid 16427
#
library	geos

driver stream
#
resource ResidentCode fixed code

#
usernotes "\xa9 2000 Dirk Lausecker"
