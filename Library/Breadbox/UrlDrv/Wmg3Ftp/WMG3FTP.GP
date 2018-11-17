##############################################################################
#
# PROJECT:      WebMagick
# FILE:         wmg3ftp.gp
#
# AUTHOR:       Gerd Boerrigter
#
##############################################################################

name            wmg3ftp.lib
longname        "Breadbox FTP URL Driver"
tokenchars      "URLD"
tokenid         16431

type            library, single, c-api

library         geos
library         ansic
library         html4par
library         socket

library         ui

export          URLDRVMAIN
export          URLDRVABORT
export          URLDRVINFO
export          URLDRVFLUSH

resource HTMLRESOURCE shared lmem data
resource STATUSRESOURCE shared lmem data

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

entry           WMG3FTPENTRY
