bigcalcMain.rdef: bigcalcMain.ui generic.uih product.uih Art/mkrBigCalc.ui \
                Art/mkrBigCalcTiny.ui bigcalcMain.uih bigcalcPCF.uih \
                bigcalcExtraMain.ui Art/mkrConsumer.ui Art/mkrRetail.ui \
                bigcalcCalc.uih bigcalcCalc.ui Art/mkrMemPlus.ui \
                Art/mkrMemMinus.ui Art/mkrPlusMinus.ui Art/mkrPlus.ui \
                Art/mkrMinus.ui Art/mkrTimes.ui Art/mkrDivide.ui \
                Art/mkrBackspace.ui Art/mkrEquals.ui bigcalcMath.uih \
                bigcalcMath.ui bigcalcPCF.ui Art/mkrStats.ui \
                Art/mkrFinance.ui bigcalcData.ui bigcalcTemplate.ui \
                Art/mkrGetCalc.ui Art/mkrSendCalc.ui
bigcalcDCtrl.obj \
bigcalcDCtrl.eobj: 
bigcalcMainCode.obj \
bigcalcMainCode.eobj: geos.def heap.def geode.def resource.def ec.def object.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def win.def localize.def \
                sllang.def initfile.def vm.def dbase.def timer.def \
                timedate.def system.def Objects/inputC.def \
                Objects/metaC.def chunkarr.def geoworks.def ui.def \
                file.def input.def hwr.def Objects/processC.def \
                gcnlist.def Objects/Text/tCommon.def stylesh.def iacp.def \
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
                Objects/vTextC.def spool.def print.def \
                Internal/prodFeatures.def hugearr.def math.def parse.def \
                bigcalcMain.def bigcalcProcess.def bigcalcCalc.def \
                bigcalcMath.def bigcalcPCF.def bigcalcMain.rdef \
                bigcalcProcess.asm bigcalcCalc.asm bigcalcMath.asm \
                bigcalcApplication.asm bigcalcFiniteState.asm \
                bigcalcPCF.asm bigcalcHolder.asm bigcalcMemory.asm \
                bigcalcUnaryCvt.asm bigcalcBuildPCF.asm \
                bigcalcBuildFixedArgsPCF.asm \
                bigcalcBuildVariableArgsPCF.asm bigcalcFixedArgsPCF.asm \
                bigcalcVariableArgsPCF.asm

bigcalcEC.geo bigcalc.geo : geos.ldf ui.ldf math.ldf parse.ldf 