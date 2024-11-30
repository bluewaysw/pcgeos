hostif.obj \
hostif.eobj: geos.def ec.def heap.def geode.def resource.def \
                library.def vm.def dbase.def object.def lmem.def \
                graphics.def fontID.def font.def color.def thread.def \
                gstring.def text.def char.def Objects/inputC.def \
                Objects/metaC.def chunkarr.def geoworks.def \
                Objects/winC.def win.def hostif.def

hostifEC.geo hostif.geo : geos.ldf 