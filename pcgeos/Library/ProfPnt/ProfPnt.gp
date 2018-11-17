##############################################################################
#
# PROJECT:      Profile point tool
# FILE:         profpnt.gp
#
# AUTHOR:       Lysle Shields
#
##############################################################################

name            profpnt.lib
longname        "Profile Point Tool"
tokenchars      "PfPt"
tokenid         0

type            library, single, c-api
entry           PROFPNT_ENTRY

library         geos
library         ansic

export          PROFPOINTROUTINE
export          PROFILEPOINTSTART
export          PROFILEPOINTEND
export          PROFILEPOINTTALLY
export          PROFILEPOINTDUMPTALLIES

resource        PROFPNT_TEXT fixed

usernotes "Copyright 2000 MyTurn.com company.  All Rights Reserved."

