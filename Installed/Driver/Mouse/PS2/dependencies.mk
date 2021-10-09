ps2.obj \
ps2.eobj: ../mouseCommon.asm geos.def heap.def lmem.def geode.def \
                resource.def ec.def assert.def disk.def file.def \
                drive.def driver.def initfile.def char.def timer.def \
                input.def graphics.def fontID.def font.def color.def \
                hwr.def timedate.def sem.def Internal/im.def \
                Internal/semInt.def Objects/processC.def \
                Objects/metaC.def object.def chunkarr.def geoworks.def \
                Internal/heapInt.def sysstats.def Internal/interrup.def \
                Internal/kbdMap.def Objects/uiInputC.def localize.def \
                sllang.def Internal/kbdDr.def Internal/mouseDr.def \
                Internal/dos.def fileEnum.def system.def \
                Internal/powerDr.def ui.def vm.def text.def win.def \
                gcnlist.def Objects/Text/tCommon.def stylesh.def iacp.def \
                Objects/visC.def Objects/vCompC.def Objects/vCntC.def \
                Internal/vUtils.def Objects/genC.def uDialog.def \
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
                Objects/emomC.def Objects/emTrigC.def Internal/uProcC.def

ps2EC.geo ps2.geo : geos.ldf 