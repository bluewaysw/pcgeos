ttf2.obj \
ttf2.eobj: stdapp.goh object.goh ui.goh Objects/metaC.goh \
                Objects/inputC.goh Objects/clipbrd.goh \
                Objects/uiInputC.goh iacp.goh Objects/winC.goh \
                Objects/gProcC.goh alb.goh Objects/processC.goh \
                Objects/visC.goh Objects/vCompC.goh Objects/vCntC.goh \
                Objects/gAppC.goh Objects/genC.goh Objects/gInterC.goh \
                Objects/gPrimC.goh Objects/gDispC.goh Objects/gTrigC.goh \
                Objects/gViewC.goh Objects/gTextC.goh Objects/vTextC.goh \
                Objects/gCtrlC.goh gcnlist.goh spool.goh \
                Objects/gFSelC.goh Objects/gGlyphC.goh \
                Objects/gDocCtrl.goh Objects/gDocGrpC.goh \
                Objects/gDocC.goh Objects/gContC.goh Objects/gDCtrlC.goh \
                Objects/gEditCC.goh Objects/gBoolGC.goh \
                Objects/gItemGC.goh Objects/gDListC.goh \
                Objects/gItemC.goh Objects/gBoolC.goh \
                Objects/gGadgetC.goh Objects/gToolCC.goh \
                Objects/gValueC.goh Objects/gToolGC.goh \
                Objects/helpCC.goh
ttf2.obj \
ttf2.eobj: geos.h heap.h geode.h resource.h ec.h object.h lmem.h \
                graphics.h fontID.h font.h color.h gstring.h timer.h vm.h \
                dbase.h localize.h Ansi/ctype.h timedate.h file.h \
                sllang.h system.h geoworks.h chunkarr.h Objects/helpCC.h \
                disk.h drive.h input.h char.h hwr.h win.h uDialog.h \
                Objects/gInterC.h Objects/Text/tCommon.h stylesh.h \
                driver.h thread.h print.h Internal/spoolInt.h serialDr.h \
                parallDr.h hugearr.h fileEnum.h Ansi/stdlib.h \
                Ansi/string.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h
ttcache.obj \
ttcache.eobj: FreeType/ttengine.h FreeType/tttypes.h FreeType/ttconfig.h \
                FreeType/ft_conf.h geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h \
                FreeType/ttmemory.h Ansi/string.h FreeType/ttcache.h \
                FreeType/ttobjs.h FreeType/tttables.h FreeType/ttcmap.h \
                FreeType/ttdebug.h
ttraster.obj \
ttraster.eobj: FreeType/ttraster.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttengine.h \
                FreeType/tttypes.h FreeType/ttmutex.h FreeType/ttdebug.h \
                FreeType/ttcalc.h FreeType/ttmemory.h Ansi/string.h
ttmutex.obj \
ttmutex.eobj: FreeType/ttmutex.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h
ttgload.obj \
ttgload.eobj: FreeType/tttypes.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttdebug.h FreeType/ttcalc.h \
                FreeType/ttfile.h FreeType/ttengine.h FreeType/ttmutex.h \
                FreeType/tttables.h FreeType/ttobjs.h FreeType/ttcache.h \
                FreeType/ttcmap.h FreeType/ttgload.h FreeType/ttmemory.h \
                Ansi/string.h FreeType/tttags.h FreeType/ttload.h
ttextend.obj \
ttextend.eobj: FreeType/ttextend.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttobjs.h FreeType/ttengine.h \
                FreeType/ttmutex.h FreeType/ttcache.h FreeType/tttables.h \
                FreeType/ttcmap.h FreeType/ttmemory.h Ansi/string.h
ttcalc.obj \
ttcalc.eobj: FreeType/ttcalc.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttdebug.h FreeType/tttypes.h \
                FreeType/tttables.h
ttapi.obj \
ttapi.eobj: FreeType/ttconfig.h FreeType/ft_conf.h geos.h file.h \
                resource.h Ansi/stdlib.h FreeType/freetype.h \
                FreeType/fterrid.h FreeType/ftnameid.h \
                FreeType/ttengine.h FreeType/tttypes.h FreeType/ttmutex.h \
                FreeType/ttcalc.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttcache.h FreeType/ttfile.h FreeType/ttdebug.h \
                FreeType/ttobjs.h FreeType/tttables.h FreeType/ttcmap.h \
                FreeType/ttload.h FreeType/ttgload.h FreeType/ttraster.h \
                FreeType/ttextend.h
ttdebug.obj \
ttdebug.eobj: FreeType/ttdebug.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/tttables.h FreeType/ttobjs.h \
                FreeType/ttengine.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/ttcmap.h
ftxkern.obj \
ftxkern.eobj: FreeType/ftxkern.h FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttextend.h \
                FreeType/ttconfig.h FreeType/ft_conf.h geos.h file.h \
                resource.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/ttobjs.h FreeType/ttengine.h FreeType/ttmutex.h \
                FreeType/ttcache.h FreeType/tttables.h FreeType/ttcmap.h \
                FreeType/ttdebug.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttfile.h FreeType/ttload.h FreeType/tttags.h
ttinterp.obj \
ttinterp.eobj: FreeType/freetype.h FreeType/fterrid.h FreeType/ftnameid.h \
                FreeType/tttypes.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h FreeType/ttdebug.h \
                FreeType/ttcalc.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttinterp.h FreeType/ttobjs.h FreeType/ttengine.h \
                FreeType/ttmutex.h FreeType/ttcache.h FreeType/tttables.h \
                FreeType/ttcmap.h
ttload.obj \
ttload.eobj: FreeType/tttypes.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttdebug.h FreeType/ttcalc.h \
                FreeType/ttfile.h FreeType/ttengine.h FreeType/ttmutex.h \
                FreeType/tttables.h FreeType/ttobjs.h FreeType/ttcache.h \
                FreeType/ttcmap.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/tttags.h FreeType/ttload.h
ttfile.obj \
ttfile.eobj: FreeType/ttconfig.h FreeType/ft_conf.h geos.h file.h \
                resource.h Ansi/stdlib.h Ansi/stdio.h Ansi/string.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/tttypes.h FreeType/ttdebug.h \
                FreeType/ttengine.h FreeType/ttmutex.h \
                FreeType/ttmemory.h FreeType/ttfile.h
ttcmap.obj \
ttcmap.eobj: FreeType/ttobjs.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/ttengine.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttdebug.h \
                FreeType/ttfile.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttload.h
ttobjs.obj \
ttobjs.eobj: FreeType/ttobjs.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h \
                FreeType/ttengine.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmutex.h FreeType/ttcache.h \
                FreeType/tttables.h FreeType/ttcmap.h FreeType/ttfile.h \
                FreeType/ttdebug.h FreeType/ttcalc.h FreeType/ttmemory.h \
                Ansi/string.h FreeType/ttload.h FreeType/ttinterp.h \
                FreeType/ttextend.h
ttmemory.obj \
ttmemory.eobj: FreeType/ttdebug.h FreeType/ttconfig.h FreeType/ft_conf.h \
                geos.h file.h resource.h Ansi/stdlib.h FreeType/tttypes.h \
                FreeType/freetype.h FreeType/fterrid.h \
                FreeType/ftnameid.h FreeType/ttmemory.h Ansi/string.h \
                FreeType/ttengine.h FreeType/ttmutex.h

ttf2EC.geo ttf2.geo : geos.ldf ui.ldf ansic.ldf 