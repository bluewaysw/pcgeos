EXPSTR.obj \
EXPSTR.eobj: Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh \
                giflib.goh extgraph.goh
EXPSTR.obj \
EXPSTR.eobj: geos.h chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h graphics.h fontID.h font.h color.h \
                hwr.h win.h vm.h gstring.h config.h Ansi/string.h heap.h \
                hugearr.h
IMPFILE.obj \
IMPFILE.eobj: giflib.goh extgraph.goh Objects/winC.goh Objects/metaC.goh \
                object.goh Objects/inputC.goh Objects/uiInputC.goh \
                Objects/visC.goh
IMPFILE.obj \
IMPFILE.eobj: geos.h heap.h vm.h lmem.h file.h graphics.h fontID.h \
                font.h color.h hugearr.h Ansi/string.h config.h gstring.h \
                chunkarr.h object.h geode.h Objects/helpCC.h input.h \
                char.h hwr.h win.h
EXPFILE.obj \
EXPFILE.eobj: Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh \
                giflib.goh extgraph.goh
EXPFILE.obj \
EXPFILE.eobj: geos.h chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h graphics.h fontID.h font.h color.h \
                hwr.h win.h vm.h gstring.h config.h Ansi/string.h heap.h \
                hugearr.h

giflibEC.geo giflib.geo : geos.ldf ansic.ldf extgraph.ldf 