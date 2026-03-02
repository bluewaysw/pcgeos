prefmgr.rdef: generic.uih product.uih spool.uih config.uih \
                Objects/colorC.uih spell.uih mkrPrefMgr.ui \
                mkrPrefMgrTiny.ui mkrModem.ui mkrPrinter.ui mkrText.ui
prefmgr.obj \
prefmgr.eobj: stdapp.def geos.def geode.def resource.def ec.def lmem.def \
                object.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def heap.def ui.def file.def \
                vm.def win.def input.def hwr.def localize.def sllang.def \
                Objects/processC.def Objects/metaC.def chunkarr.def \
                geoworks.def gcnlist.def timedate.def \
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
                Internal/prodFeatures.def library.def timer.def \
                assert.def fileEnum.def initfile.def system.def \
                thread.def medium.def Objects/inputC.def Internal/im.def \
                Internal/semInt.def Internal/geodeStr.def \
                Objects/vTextC.def spool.def print.def hugearr.def \
                dbase.def Objects/Text/tCtrlC.def ruler.def \
                Objects/colorC.def Objects/styles.def \
                Internal/spoolInt.def driver.def Internal/serialDr.def \
                Internal/streamDr.def Internal/parallDr.def spell.def \
                config.def Internal/mouseDr.def Internal/printDr.def \
                prefConstant.def prefmgrConstant.def prefmgrClass.def \
                prefmgrMacros.def prefmgrApplication.def prefmgr.rdef \
                prefmgrVariable.def prefVariable.def prefmgrModem.asm \
                prefmgrPrinter.asm prefmgrSerial.asm prefPrinter.asm \
                prefmgrText.asm prefmgrModule.asm prefmgrModuleList.asm \
                prefmgrReboot.asm prefmgrApplication.asm customSpin.asm \
                prefmgrDialogGroup.asm prefmgrTitledSummons.asm \
                commonUtils.asm prefmgrDynamic.asm prefmgrFormats.asm \
                prefmgrMtdHan.asm prefmgrUtils.asm prefmgrInitExit.asm

prefmgrEC.geo prefmgr.geo : geos.ldf ui.ldf spool.ldf text.ldf spell.ldf config.ldf serial.ldf 
