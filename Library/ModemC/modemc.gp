##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# FILE:		modemc.gp
#
# AUTHOR:	Chris Thomas, Aug 28, 1996
#
#
# 
#
#	$Id: modemc.gp,v 1.1 97/04/05 01:23:55 newdeal Exp $
#
##############################################################################

#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name modemc.lib

#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "C Modem Driver Library"

#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "CMDM"
tokenid 0

#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type	library, single, discardable-dgroup

#
# Libraries: list which libraries are used by the application.
#
library	geos
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#


entry ModemLibraryEntry

export MODEMOPEN
export MODEMCLOSE
export MODEMSETROUTINEDATANOTIFY
export MODEMSETMESSAGEDATANOTIFY
export MODEMSETROUTINERESPONSENOTIFY
export MODEMSETMESSAGERESPONSENOTIFY
export MODEMDIAL
export MODEMANSWERCALL
export MODEMHANGUP
export MODEMRESET
export MODEMFACTORYRESET
export MODEMINITMODEM
export MODEMAUTOANSWER
export MODEMSETMESSAGEENDCALLNOTIFY
