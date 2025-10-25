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
library         extgraph

export PNGIMPORTCONVERTFILE
export PNGIMPORTCHECKHEADER
export PNGIMPORTPROCESSCHUNKS
export PNGIMPORTWHATOUTPUTFORMAT
export PNGIMPORTINITIATEOUTPUTBITMAP
export PNGIMPORTHANDLEPALETTE
export PNGIMPORTINITIDATPROCESSINGSTATE
export PNGIMPORTGETNEXTIDATSCANLINE
export PNGIMPORTIDATPROCESSINGUNLOCKHANDLES
export PNGIMPORTAPPLYGEOSFORMATTRANSFORMATIONS
export PNGIMPORTWRITESCANLINETOBITMAP
export PNGIMPORTIDATPROCESSINGLOCKHANDLES
export PNGIMPORTCLEANUPIDATPROCESSINGSTATE

export PNGCALCBYTESPERROW
export PNGCALCBYTESPERPIXEL
export PNGCALCLINEALLOCSIZE
# export PNGREMOVEALPHACHANNEL - has been replaced
# with ...BLEND and ...TOMASK
skip 1
export PNGCONVERT16BITLINETO8BIT
export PNGPAD1BITTO4BIT
export PNGPAD2BITTO4BIT

incminor

export PNGALPHACHANNELBLEND
export PNGALPHACHANNELTOMASK

export PNGEXPORTBITMAPFHANDLE