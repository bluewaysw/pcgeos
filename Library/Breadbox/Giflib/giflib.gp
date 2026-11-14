name giflib.lib

longname "Gif Library"

type library, single

tokenchars "GifL"
tokenid    16431

library geos
library ansic 
library extgraph


# proto 1.0

export	GIFIMPORTBITMAPFNAME
export	GIFEXPORTBITMAPFNAME
export	GIFIMPORTBITMAPFHANDLE
export	GIFEXPORTBITMAPFHANDLE

incminor

# proto 1.1

export GIFIMPORTTESTBITMAPFNAME
export GIFIMPORTTESTBITMAPFHANDLE

incminor

# proto 1.2

export GIFEXPORTSTREAMCREATE
export GIFEXPORTSTREAMWRITELINE
export GIFEXPORTSTREAMDESTROY
