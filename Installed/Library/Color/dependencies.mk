UI.obj \
UI.eobj: UI/uiManager.asm \
                colorGeode.def geos.def heap.def resource.def geode.def \
                ec.def library.def object.def lmem.def graphics.def \
                fontID.def font.def color.def gstring.def text.def \
                char.def timer.def file.def vm.def dbase.def localize.def \
                sllang.def initfile.def chunkarr.def geoworks.def \
                Objects/inputC.def Objects/metaC.def ui.def win.def \
                input.def hwr.def Objects/processC.def gcnlist.def \
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
                colorConstant.def Objects/colorC.def \
                Internal/prodFeatures.def uiManager.rdef uiColor.asm \
                uiOtherColor.asm
uiManager.rdef: generic.uih product.uih Objects/colorC.uih \
                Internal/prodFeatures.uih UI/uiColor.ui \
                Art/mkrAreaColor.ui Art/mkrAreaMask.ui \
                Art/mkrAreaPattern.ui Art/mkrLineColor.ui \
                Art/mkrLineMask.ui Art/mkrTextColor.ui Art/mkrTextMask.ui \
                Art/mkrTextPattern.ui

colorEC.geo color.geo : geos.ldf ui.ldf 