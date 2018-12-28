IMPTPROC.obj \
IMPTPROC.eobj: stdapp.goh object.goh ui.goh Objects/metaC.goh \
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
                Objects/helpCC.goh impex.goh
IMPTPROC.obj \
IMPTPROC.eobj: geos.h heap.h geode.h resource.h ec.h object.h lmem.h \
                graphics.h fontID.h font.h color.h gstring.h timer.h vm.h \
                dbase.h localize.h Ansi/ctype.h timedate.h file.h \
                sllang.h system.h geoworks.h chunkarr.h Objects/helpCC.h \
                disk.h drive.h input.h char.h hwr.h win.h uDialog.h \
                Objects/gInterC.h Objects/Text/tCommon.h stylesh.h \
                driver.h thread.h print.h Internal/spoolInt.h serialDr.h \
                parallDr.h hugearr.h fileEnum.h ieCommon.h xlatLib.h \
                Ansi/string.h sstor.h libFmt.h wfwlib.h
Manager.obj \
Manager.eobj: geos.def geode.def Objects/processC.def Objects/metaC.def \
                object.def lmem.def chunkarr.def geoworks.def file.def \
                library.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def win.def system.def \
                localize.def sllang.def resource.def heap.def ec.def \
                sem.def ui.def vm.def input.def hwr.def gcnlist.def \
                timedate.def Objects/Text/tCommon.def stylesh.def \
                iacp.def Objects/uiInputC.def Objects/visC.def \
                Objects/vCompC.def Objects/vCntC.def Internal/vUtils.def \
                Objects/genC.def disk.def drive.def uDialog.def \
                Objects/gInterC.def token.def Objects/clipbrd.def \
                Objects/gSysC.def Objects/gProcC.def alb.def \
                Objects/gFieldC.def Objects/gScreenC.def \
                Objects/gFSelC.def Objects/gViewC.def Objects/gContC.def \
                Objects/gCtrlC.def Objects/gDocC.def Objects/gDocCtrl.def \
                Objects/gDocGrpC.def Objects/gEditCC.def \
                Objects/gViewCC.def Objects/gToolCC.def \
                Objects/gPageCC.def Objects/gPenICC.def \
                Objects/gGlyphC.def Objects/gTrigC.def \
                Objects/gBoolGC.def Objects/gItemGC.def \
                Objects/gDListC.def Objects/gItemC.def Objects/gBoolC.def \
                Objects/gDispC.def Objects/gDCtrlC.def Objects/gPrimC.def \
                Objects/gAppC.def Objects/gTextC.def Objects/gGadgetC.def \
                Objects/gValueC.def Objects/gToolGC.def \
                Internal/gUtils.def Objects/helpCC.def Objects/eMenuC.def \
                Objects/emomC.def Objects/emTrigC.def Internal/uProcC.def \
                math.def impex.def ieCommon.def Internal/xlatLib.def \
                transCommonGlobal.def transLibEntry.asm \
                transSemaphore.asm

winword8EC.geo winword8.geo : geos.ldf impex.ldf ansic.ldf text.ldf sstor.ldf wfwlib.ldf 