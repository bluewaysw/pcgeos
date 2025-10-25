common.obj \
common.eobj: 
common.obj \
common.eobj: common.h geos.h
pngexp.obj \
pngexp.eobj: extgraph.goh Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh
pngexp.obj \
pngexp.eobj: pnglib.h geos.h Ansi/stdio.h Ansi/stdlib.h Ansi/string.h \
                graphics.h fontID.h font.h color.h vm.h lmem.h hugearr.h \
                zlib.h zconf.h file.h ec.h heap.h htmldrv.h product.h \
                math.h timedate.h htmlfstr.h awatcher.h htmlprog.h \
                common.h gstring.h chunkarr.h object.h geode.h \
                Objects/helpCC.h input.h char.h hwr.h win.h
pngimp.obj \
pngimp.eobj: 
pngimp.obj \
pngimp.eobj: pnglib.h geos.h Ansi/stdio.h Ansi/stdlib.h Ansi/string.h \
                graphics.h fontID.h font.h color.h vm.h lmem.h hugearr.h \
                zlib.h zconf.h file.h ec.h heap.h htmldrv.h product.h \
                math.h timedate.h htmlfstr.h awatcher.h htmlprog.h \
                common.h

pnglibEC.geo pnglib.geo : geos.ldf ansic.ldf zlib.ldf extgraph.ldf 