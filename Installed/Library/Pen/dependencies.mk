Ink.obj \
Ink.eobj: Ink/inkManager.asm \
                penGeode.def geos.def heap.def geode.def resource.def \
                ec.def assert.def disk.def file.def drive.def object.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def chunkarr.def timer.def \
                vm.def input.def hwr.def library.def dbase.def \
                geoworks.def Internal/prodFeatures.def pen.def ui.def \
                win.def localize.def sllang.def Objects/processC.def \
                Objects/metaC.def gcnlist.def timedate.def \
                Objects/Text/tCommon.def stylesh.def iacp.def \
                Objects/uiInputC.def Objects/visC.def Objects/vCompC.def \
                Objects/vCntC.def Internal/vUtils.def Objects/genC.def \
                uDialog.def Objects/gInterC.def token.def \
                Objects/clipbrd.def Objects/gSysC.def Objects/gProcC.def \
                alb.def Objects/gFieldC.def Objects/gScreenC.def \
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
                Internal/im.def Internal/semInt.def Objects/winC.def \
                Objects/inputC.def Objects/vTextC.def spool.def print.def \
                hugearr.def penConstant.def system.def \
                Internal/mouseDr.def driver.def inkMacro.def \
                inkConstant.def inkCursors.asm inkClassCommon.asm \
                inkClassEdit.asm inkMouse.asm inkControlClass.asm \
                inkControl.rdef inkSelection.asm inkBackspace.asm \
                inkMP.asm thread.def Objects/inkfix.def
File.obj \
File.eobj: File/fileManager.asm \
                penGeode.def geos.def heap.def geode.def resource.def \
                ec.def assert.def disk.def file.def drive.def object.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def chunkarr.def timer.def \
                vm.def input.def hwr.def library.def dbase.def \
                geoworks.def Internal/prodFeatures.def pen.def ui.def \
                win.def localize.def sllang.def Objects/processC.def \
                Objects/metaC.def gcnlist.def timedate.def \
                Objects/Text/tCommon.def stylesh.def iacp.def \
                Objects/uiInputC.def Objects/visC.def Objects/vCompC.def \
                Objects/vCntC.def Internal/vUtils.def Objects/genC.def \
                uDialog.def Objects/gInterC.def token.def \
                Objects/clipbrd.def Objects/gSysC.def Objects/gProcC.def \
                alb.def Objects/gFieldC.def Objects/gScreenC.def \
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
                Internal/im.def Internal/semInt.def Objects/winC.def \
                Objects/inputC.def Objects/vTextC.def spool.def print.def \
                hugearr.def penConstant.def fileMacro.def \
                fileConstant.def fileStrings.rdef fileAccess.asm \
                fileC.asm
inkControl.rdef: Ink/inkControl.ui generic.uih product.uih ink.uih \
                Art/mkrEraser.ui Art/mkrPencil.ui Art/mkrSelector.ui
fileStrings.rdef: File/fileStrings.ui

penEC.geo pen.geo : geos.ldf ui.ldf 