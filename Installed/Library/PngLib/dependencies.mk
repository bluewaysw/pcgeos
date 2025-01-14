pnglib.obj \
pnglib.eobj: 
pnglib.obj \
pnglib.eobj: geos.h Ansi/stdio.h Ansi/stdlib.h Ansi/string.h graphics.h \
                fontID.h font.h color.h vm.h lmem.h hugearr.h zlib.h \
                zconf.h file.h ec.h heap.h

pnglibEC.geo pnglib.geo : geos.ldf ansic.ldf zlib.ldf 