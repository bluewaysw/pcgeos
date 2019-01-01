##############################################################################
#
# PROJECT:      Cookies for HTTP
# FILE:         cookies.gp
#
# AUTHOR:       Lysle Shields
#
##############################################################################

name            cookies.lib
longname        "Cookies"
tokenchars      "Cook"
tokenid         16431

type            library, single, c-api
entry           COOKIES_ENTRY

library         geos
library         ansic
library         netutils

export          COOKIEFIND
export          COOKIEPARSE
export          COOKIESET
export          COOKIESWRITE
export          COOKIEPARSETIME


