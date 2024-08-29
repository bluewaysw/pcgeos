pnglib.obj \
pnglib.eobj: 
pnglib.obj \
pnglib.eobj: geos.h Ansi/stdio.h Ansi/stdlib.h Ansi/string.h zlib.h \
                zconf.h file.h ec.h heap.h

pnglibEC.geo pnglib.geo : geos.ldf ansic.ldf ui.ldf zlib.ldf 