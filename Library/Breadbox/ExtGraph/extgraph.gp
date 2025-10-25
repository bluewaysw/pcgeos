name extgraph.lib

longname "Extended Graphics Lib"

type library, single

tokenchars "ExGr"
tokenid    16431

library geos
library ansic

# 1.0
export PALPARSEGSTRING
export PALQUANTPALETTE

incminor

# 1.1
export BMPGETBITMAPSIZE
export BMPFILLBITMAPMOSAIC

incminor

# 1.2
export BMPGETBITMAPTYPE
export BMPGETBITMAPPALETTE
export BMPGSTRINGTOBITMAP

export EXTGRFILLMOSAIC
export EXTGRGETGSTRINGSIZE
export EXTGRDRAWGSTRING

incminor

# 1.3
export BMPSETBITMAPPALETTE
export BMPSETBITMAPPALETTEENTRY

incminor
incminor
incminor
incminor
incminor
incminor

incminor

export BMPROTATE90
export BMPROTATE180
export BMPROTATE270
export BMPFLIPVERTICAL
export BMPFLIPHORIZONTAL

incminor

export BMPGETBITMAPCOMPACT

#usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

