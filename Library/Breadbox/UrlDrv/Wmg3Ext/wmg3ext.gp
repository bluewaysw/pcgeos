##############################################################################
#
# PROJECT:      WebMagick
# FILE:         wmg3ext.gp
#
# AUTHOR:       Brian Chin
#
##############################################################################

name            wmg3ext.lib
longname        "External URL Driver"
tokenchars      "URLD"
tokenid         16431

type            library, single, c-api
entry           LIBRARYENTRY

library         geos
library         ansic
library         ui

export          URLDRVMAIN
export          URLDRVABORT
export          URLDRVINFO
export          URLDRVFLUSH

resource HTMLResource shared lmem data


