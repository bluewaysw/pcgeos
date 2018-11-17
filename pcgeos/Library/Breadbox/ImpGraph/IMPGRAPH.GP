name impgraph.lib

longname "Breadbox Graphics Imp Library"

type library, single

tokenchars "MIMD"
tokenid 16431

library geos
library ansic
ifdef PRODUCT_FJPEG
#library fjpeg
#library ijgjpeg
else
library ijgjpeg
endif

export MIMEDRVGRAPHIC
export MIMEDRVINFO
export MIMEDRVTEXT

incminor

export MIMEDRVGRAPHICEX

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

