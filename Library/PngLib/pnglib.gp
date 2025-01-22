##############################################################################
#
# PNG Library
#
##############################################################################

name            pnglib.lib
longname        "PNG Library"
tokenchars      "PNGL"
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

export PNGCALCBYTESPERROW
export PNGCALCBYTESPERPIXEL
export PNGCALCLINEALLOCSIZE
export PNGREMOVEALPHACHANNEL
export PNGCONVERT16BITLINETO8BIT
export PNGPAD1BITTO4BIT
export PNGPAD2BITTO4BIT
