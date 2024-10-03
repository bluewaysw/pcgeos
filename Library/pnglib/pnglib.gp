##############################################################################
#
# PNG Library
#
##############################################################################

name            pnglib.lib
longname        "PNG Library"
tokenchars      "PngL"
tokenid         0

type            library, single, c-api

library         geos
library         ansic
library         zlib

stack           4000

export PNGCONVERTFILE
export PNGCHECKHEADER
export PNGPROCESSCHUNKS
export PNGWHATOUTPUTFORMAT
export PNGINITIATEOUTPUTBITMAP
export PNGHANDLEPALETTE
export PNGINITIDATPROCESSINGSTATE
export PNGGETNEXTIDATSCANLINE
export PNGPAUSEIDATPROCESSING
export PNGAPPLYGEOSFORMATTRANSFORMATIONS
export PNGWRITESCANLINETOBITMAP
export PNGRESUMEIDATPROCESSING
export PNGCLEANUPIDATPROCESSINGSTATE
