##############################################################################
#
# Static lossy WebP decoder
#
##############################################################################

name            webplib.lib
longname        "WebP Library"
tokenchars      "WEBP"
tokenid         0

type            library, single, c-api

library         geos
library         ansic

resource        WebPDspCode code read-only shared
resource        WebPPredCode code read-only shared
resource        WebPRowCode code read-only shared
resource        WebPHeaderCode code read-only shared

export WEBPIMPORTBEGIN
export WEBPIMPORTNEXT
export WEBPIMPORTDESTROY
