Document.obj \
Document.eobj: Document/documentManager.asm \
                ntakerGeode.def geos.def heap.def geode.def resource.def \
                ec.def vm.def dbase.def initfile.def object.def lmem.def \
                graphics.def fontID.def font.def color.def gstring.def \
                text.def char.def Objects/winC.def win.def \
                Objects/metaC.def chunkarr.def geoworks.def timedate.def \
                system.def localize.def sllang.def hugearr.def ui.def \
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
                pen.def Objects/vTextC.def spool.def print.def \
                Internal/prodFeatures.def Objects/Text/tCtrlC.def \
                ruler.def Objects/colorC.def Objects/styles.def \
                ntakerDocument.def ntakerProcess.def \
                ntakerApplication.def ntakerTitledButton.def \
                ntakerInk.def ntakerText.def ntakerDisplay.def \
                ntakerGlobal.def ntakerErrors.def documentConstant.def \
                documentVariable.def documentCode.asm documentMisc.asm \
                documentInk.asm documentText.asm documentDisplay.asm \
                documentPrint.asm documentApplication.asm \
                documentTitledButton.asm
UI.obj \
UI.eobj: UI/uiManager.asm \
                ntakerGeode.def geos.def heap.def geode.def resource.def \
                ec.def vm.def dbase.def initfile.def object.def lmem.def \
                graphics.def fontID.def font.def color.def gstring.def \
                text.def char.def Objects/winC.def win.def \
                Objects/metaC.def chunkarr.def geoworks.def timedate.def \
                system.def localize.def sllang.def hugearr.def ui.def \
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
                pen.def Objects/vTextC.def spool.def print.def \
                Internal/prodFeatures.def Objects/Text/tCtrlC.def \
                ruler.def Objects/colorC.def Objects/styles.def \
                ntakerDocument.def ntakerProcess.def \
                ntakerApplication.def ntakerTitledButton.def \
                ntakerInk.def ntakerText.def ntakerDisplay.def \
                ntakerGlobal.def uiMain.rdef
uiMain.rdef: generic.uih product.uih ink.uih spool.uih \
                Objects/Text/tCtrl.uih ruler.uih Objects/colorC.uih \
                Objects/styles.uih Art/mkrNTakerApp.ui \
                Art/mkrNTakerDoc.ui Art/mkrNewPage.ui UI/uiDocument.ui \
                Art/mkrUpArrow.ui Art/mkrDownArrow.ui Art/mkrNewCard.ui \
                usrLevel.uih

ntakerEC.geo ntaker.geo : geos.ldf ui.ldf pen.ldf text.ldf spool.ldf 