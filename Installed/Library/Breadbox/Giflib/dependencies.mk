EXPFILE.obj \
EXPFILE.eobj: Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh \
                giflib.goh
EXPFILE.obj \
EXPFILE.eobj: geos.h chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h graphics.h fontID.h font.h color.h \
                hwr.h win.h vm.h extgraph.h gstring.h config.h \
                Ansi/string.h heap.h hugearr.h
EXPSTR.obj \
EXPSTR.eobj: Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh \
                giflib.goh
EXPSTR.obj \
EXPSTR.eobj: geos.h chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h graphics.h fontID.h font.h color.h \
                hwr.h win.h vm.h extgraph.h gstring.h config.h \
                Ansi/string.h heap.h hugearr.h
IMPFILE.obj \
IMPFILE.eobj: giflib.goh
IMPFILE.obj \
IMPFILE.eobj: geos.h heap.h vm.h lmem.h file.h graphics.h fontID.h \
                font.h color.h hugearr.h Ansi/string.h config.h \
                extgraph.h gstring.h

giflibEC.geo giflib.geo : geos.ldf ansic.ldf extgraph.ldf 