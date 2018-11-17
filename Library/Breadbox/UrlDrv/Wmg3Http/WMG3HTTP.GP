##############################################################################
#
# PROJECT:      WebMagick
# FILE:         wmg3http.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name            wmg3http.lib
longname        "Breadbox HTTP URL Driver"
tokenchars      "URLD"
tokenid         16431

type            library, single, c-api
entry           WMG3HTTPENTRY

library         geos
library         ansic
library         socket

library         ui

ifdef SSL_ENABLE
library         ssl
endif

ifdef COOKIE_ENABLE
library         netutils
library         cookies
endif

export          URLDRVMAIN
export          URLDRVABORT
export          URLDRVINFO
export          URLDRVFLUSH

#resource        WMG3HTTP_TEXT code fixed
resource HTMLRESOURCE shared lmem data
resource STATUSRESOURCE shared lmem data

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

