##############################################################################
#
#
##############################################################################

name            pnglib.lib
longname        "PNG Library"
tokenchars      "PngL"
tokenid         0

type            library, single, c-api

platform        geos20

library         geos
library         ansic
library 	ui

library         zlib
exempt          zlib

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
