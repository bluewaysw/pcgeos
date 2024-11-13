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

export PNGIMPORTCONVERTFILE
export PNGIMPORTCHECKHEADER
export PNGIMPORTPROCESSCHUNKS
export PNGIMPORTWHATOUTPUTFORMAT
export PNGIMPORTINITIATEOUTPUTBITMAP
export PNGIMPORTHANDLEPALETTE
export PNGIMPORTINITIDATPROCESSINGSTATE
export PNGIMPORTGETNEXTIDATSCANLINE
export PNGIMPORTPAUSEIDATPROCESSING
export PNGIMPORTAPPLYGEOSFORMATTRANSFORMATIONS
export PNGIMPORTWRITESCANLINETOBITMAP
export PNGIMPORTRESUMEIDATPROCESSING
export PNGIMPORTCLEANUPIDATPROCESSINGSTATE
