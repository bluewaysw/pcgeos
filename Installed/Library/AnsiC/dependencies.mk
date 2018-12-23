scanf.obj \
scanf.eobj: scanf.c geos.h object.h geode.h lmem.h file.h system.h \
                math.h Ansi/string.h Ansi/stdio.h
stdio.obj \
stdio.eobj: stdio.c geos.h object.h geode.h lmem.h graphics.h fontID.h \
                font.h color.h system.h Ansi/string.h Ansi/stdio.h
string.obj \
string.eobj: string.c geos.h object.h geode.h lmem.h Ansi/string.h \
                geoMisc.h localize.h Ansi/ctype.h timedate.h file.h \
                sllang.h
stdlib_asm.obj \
stdlib_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
stdio_asm.obj \
stdio_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
string_asm.obj \
string_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
ansic.obj \
ansic.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
malloc_asm.obj \
malloc_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
memory_asm.obj \
memory_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def \
                product.def
wcc_rtl.obj \
wcc_rtl.eobj: 

ansicEC.geo ansic.geo : geos.ldf math.ldf 