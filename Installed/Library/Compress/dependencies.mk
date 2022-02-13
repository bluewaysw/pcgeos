explode.obj \
explode.eobj: Ansi/assert.h geos.h ec.h Ansi/string.h pklib.h
implode.obj \
implode.eobj: Ansi/assert.h geos.h ec.h Ansi/string.h pklib.h
explode.obj \
explode.eobj: Ansi/assert.h geos.h ec.h Ansi/string.h pklib.h
implode.obj \
implode.eobj: Ansi/assert.h geos.h ec.h Ansi/string.h pklib.h
compressManager.obj \
compressManager.eobj: geos.def geode.def ec.def library.def resource.def \
                object.def lmem.def graphics.def fontID.def font.def \
                color.def gstring.def text.def char.def win.def heap.def \
                timer.def timedate.def system.def localize.def sllang.def \
                file.def fileEnum.def vm.def chunkarr.def thread.def \
                sem.def compress.def compressConstant.def \
                compressVariable.def compressIO.asm compressMain.asm
memory.obj \
memory.eobj: memory_asm.asm ansicGeode.def geos.def file.def heap.def \
                ec.def lmem.def library.def geode.def resource.def \
                chunkarr.def localize.def sllang.def ansic.def \
                ansicErrors.def product.def

compressEC.geo compress.geo : geos.ldf 