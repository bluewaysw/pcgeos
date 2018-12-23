DBCS/scanf.obj \
DBCS/scanf.eobj: scanf.c geos.h object.h geode.h lmem.h file.h system.h \
                math.h Ansi/string.h Ansi/stdio.h
DBCS/stdio.obj \
DBCS/stdio.eobj: stdio.c geos.h object.h geode.h lmem.h graphics.h fontID.h \
                font.h color.h system.h Ansi/string.h Ansi/stdio.h
DBCS/string.obj \
DBCS/string.eobj: string.c geos.h object.h geode.h lmem.h Ansi/string.h \
                geoMisc.h localize.h Ansi/ctype.h timedate.h file.h \
                sllang.h
DBCS/stdlib_asm.obj \
DBCS/stdlib_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
DBCS/stdio_asm.obj \
DBCS/stdio_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
DBCS/string_asm.obj \
DBCS/string_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
DBCS/ansic.obj \
DBCS/ansic.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
DBCS/malloc_asm.obj \
DBCS/malloc_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def
DBCS/memory_asm.obj \
DBCS/memory_asm.eobj: ansicGeode.def geos.def file.def heap.def ec.def lmem.def \
                library.def geode.def resource.def chunkarr.def \
                localize.def sllang.def ansic.def ansicErrors.def \
                product.def
DBCS/wcc_rtl.obj \
DBCS/wcc_rtl.eobj: 

DBCS/ansicEC.geo DBCS/ansic.geo : geos.ldf math.ldf 