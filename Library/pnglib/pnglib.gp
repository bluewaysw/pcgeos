##############################################################################
#
#
##############################################################################

name            pnglib.lib
longname        "PNG Lib Test"
tokenchars      "png0"
tokenid         0

type            library, single, c-api

platform        geos20

library         geos
library         ansic
library 	ui

library         zlib
exempt          zlib

stack           4000

export          CONVERTPNG
