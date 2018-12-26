configui.rdef: generic.uih product.uih config.uih Objects/colorC.uih \
                Art/mkrConfigUI.ui configuiExpress.ui configuiApp.ui \
                configuiInterface.ui configuiAdvanced.ui \
                configuiAppearance.ui configuiFileMgr.ui
configui.obj \
configui.eobj: geos.def heap.def geode.def resource.def ec.def \
                library.def system.def localize.def sllang.def object.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def win.def initfile.def \
                Internal/specUI.def ui.def file.def vm.def input.def \
                hwr.def Objects/processC.def Objects/metaC.def \
                chunkarr.def geoworks.def gcnlist.def timedate.def \
                Objects/Text/tCommon.def stylesh.def iacp.def \
                Objects/uiInputC.def Objects/visC.def Objects/vCompC.def \
                Objects/vCntC.def Internal/vUtils.def Objects/genC.def \
                disk.def drive.def uDialog.def Objects/gInterC.def \
                token.def Objects/clipbrd.def Objects/gSysC.def \
                Objects/gProcC.def alb.def Objects/gFieldC.def \
                Objects/gScreenC.def Objects/gFSelC.def \
                Objects/gViewC.def Objects/gContC.def Objects/gCtrlC.def \
                Objects/gDocC.def Objects/gDocCtrl.def \
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
                config.def Objects/colorC.def Objects/vTextC.def \
                spool.def print.def Internal/prodFeatures.def hugearr.def \
                dbase.def configui.def configui.rdef configuiProgList.asm \
                configuiFileAssoc.asm fileEnum.def prefMinuteValue.asm

configuiEC.geo configui.geo : geos.ldf ui.ldf config.ldf color.ldf 