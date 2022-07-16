Main.obj \
Main.eobj: Main/mainManager.asm \
                geos.def heap.def geode.def resource.def ec.def driver.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def sem.def file.def \
                localize.def sllang.def system.def fileEnum.def \
                Internal/fontDr.def Internal/tmatrix.def \
                Internal/grWinInt.def Internal/gstate.def \
                Internal/window.def win.def Internal/threadIn.def \
                truetypeConstant.def truetypeVariable.def \
                truetypeMacros.def truetypeWidths.asm \
                ../FontCom/fontcomUtils.asm truetypeChars.asm \
                truetypeMetrics.asm truetypePath.asm truetypeInit.asm \
                truetypeEscape.asm ../FontCom/fontcomEscape.asm \
                truetypeEC.asm ansic_runtime.asm ansic_memory.asm \
                ansic_malloc.asm ansic_string.asm
ttadapter.obj \
ttadapter.eobj: Adapter/ttadapter.h geos.h Adapter/../FreeType/freetype.h \
                Adapter/../FreeType/fterrid.h \
                Adapter/../FreeType/ftnameid.h
ttcache.obj \
ttcache.eobj: FreeType/ttengine.h FreeType/tttypes.h FreeType/ttconfig.h \
                FreeType/ft_conf.h geos.h file.h resource.h graphics.h \
                fontID.h font.h color.h heap.h ec.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h \
                FreeType/ttmemory.h Ansi/string.h FreeType/ttcache.h \
                FreeType/ttobjs.h FreeType/tttables.h FreeType/ttcmap.h \
                FreeType/ttdebug.h
ttraster.obj \
ttraster.eobj: FreeType/ttraster.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/freetype.h \
                FreeType/fterrid.h FreeType/ftnameid.h \
                FreeType/ttengine.h FreeType/tttypes.h FreeType/ttmutex.h \
                FreeType/ttdebug.h FreeType/ttcalc.h FreeType/ttmemory.h \
                Ansi/string.h
ttmutex.obj \
ttmutex.eobj: FreeType/ttmutex.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h
ttgload.obj \
ttgload.eobj: FreeType/tttypes.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/freetype.h \
                FreeType/fterrid.h FreeType/ftnameid.h FreeType/ttdebug.h \
                FreeType/ttcalc.h FreeType/ttfile.h FreeType/ttengine.h \
                FreeType/ttmutex.h FreeType/tttables.h FreeType/ttobjs.h \
                FreeType/ttcache.h FreeType/ttcmap.h FreeType/ttgload.h \
                FreeType/ttmemory.h Ansi/string.h FreeType/tttags.h \
                FreeType/ttload.h
ttextend.obj \
ttextend.eobj: FreeType/ttextend.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttobjs.h FreeType/ttengine.h \
                FreeType/ttmutex.h FreeType/ttcache.h FreeType/tttables.h \
                FreeType/ttcmap.h FreeType/ttmemory.h Ansi/string.h
ttcalc.obj \
ttcalc.eobj: FreeType/ttcalc.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/freetype.h \
                FreeType/fterrid.h FreeType/ftnameid.h FreeType/ttdebug.h \
                FreeType/tttypes.h FreeType/tttables.h
ttapi.obj \
ttapi.eobj: FreeType/ttconfig.h FreeType/ft_conf.h geos.h file.h \
                resource.h graphics.h fontID.h font.h color.h heap.h ec.h \
                Ansi/stdlib.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttengine.h \
                FreeType/tttypes.h FreeType/ttmutex.h FreeType/ttcalc.h \
                FreeType/ttmemory.h Ansi/string.h FreeType/ttcache.h \
                FreeType/ttfile.h FreeType/ttdebug.h FreeType/ttobjs.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttload.h \
                FreeType/ttgload.h FreeType/ttraster.h \
                FreeType/ttextend.h
ttdebug.obj \
ttdebug.eobj: FreeType/ttdebug.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/tttables.h FreeType/ttobjs.h \
                FreeType/ttengine.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/ttcmap.h
ftxkern.obj \
ftxkern.eobj: FreeType/ftxkern.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h geos.h FreeType/ttextend.h \
                FreeType/ttconfig.h FreeType/ft_conf.h file.h resource.h \
                graphics.h fontID.h font.h color.h heap.h ec.h \
                Ansi/stdlib.h FreeType/tttypes.h FreeType/ttobjs.h \
                FreeType/ttengine.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttdebug.h \
                FreeType/ttmemory.h Ansi/string.h FreeType/ttfile.h \
                FreeType/ttload.h FreeType/tttags.h
ttinterp.obj \
ttinterp.eobj: FreeType/freetype.h FreeType/fterrid.h FreeType/ftnameid.h \
                geos.h FreeType/tttypes.h FreeType/ttconfig.h \
                FreeType/ft_conf.h file.h resource.h graphics.h fontID.h \
                font.h color.h heap.h ec.h Ansi/stdlib.h \
                FreeType/ttdebug.h FreeType/ttcalc.h FreeType/ttmemory.h \
                Ansi/string.h FreeType/ttinterp.h FreeType/ttobjs.h \
                FreeType/ttengine.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h
ttload.obj \
ttload.eobj: FreeType/tttypes.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/freetype.h \
                FreeType/fterrid.h FreeType/ftnameid.h FreeType/ttdebug.h \
                FreeType/ttcalc.h FreeType/ttfile.h FreeType/ttengine.h \
                FreeType/ttmutex.h FreeType/tttables.h FreeType/ttobjs.h \
                FreeType/ttcache.h FreeType/ttcmap.h FreeType/ttmemory.h \
                Ansi/string.h FreeType/tttags.h FreeType/ttload.h
ttfile.obj \
ttfile.eobj: FreeType/ttconfig.h FreeType/ft_conf.h geos.h file.h \
                resource.h graphics.h fontID.h font.h color.h heap.h ec.h \
                Ansi/stdlib.h Ansi/stdio.h Ansi/string.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/tttypes.h FreeType/ttdebug.h \
                FreeType/ttengine.h FreeType/ttmutex.h \
                FreeType/ttmemory.h FreeType/ttfile.h
ttcmap.obj \
ttcmap.eobj: FreeType/ttobjs.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/ttengine.h \
                FreeType/tttypes.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttdebug.h \
                FreeType/ttfile.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttload.h
ttobjs.obj \
ttobjs.eobj: FreeType/ttobjs.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/ttengine.h \
                FreeType/tttypes.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttfile.h \
                FreeType/ttdebug.h FreeType/ttcalc.h FreeType/ttmemory.h \
                Ansi/string.h FreeType/ttload.h FreeType/ttinterp.h \
                FreeType/ttextend.h
ttmemory.obj \
ttmemory.eobj: FreeType/ttdebug.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h graphics.h fontID.h font.h \
                color.h heap.h ec.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttengine.h FreeType/ttmutex.h

truetypeEC.geo truetype.geo : geos.ldf 