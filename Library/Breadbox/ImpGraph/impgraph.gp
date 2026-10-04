name impgraph.lib

longname "Graphics Imp Library"

type library, single

tokenchars "MIMD"
tokenid 16431

library geos
library ansic
ifdef PRODUCT_FJPEG
library fjpeg
library ijgjpeg
else
library ijgjpeg
endif
library pnglib

export MIMEDRVGRAPHIC
export MIMEDRVINFO
export MIMEDRVTEXT

incminor

export MIMEDRVGRAPHICEX


