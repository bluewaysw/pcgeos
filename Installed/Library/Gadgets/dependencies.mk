Main.obj \
Main.eobj: Main/mainManager.asm \
                gadgetsGeode.def geos.def stdapp.def geode.def \
                resource.def ec.def lmem.def object.def graphics.def \
                fontID.def font.def color.def gstring.def text.def \
                char.def heap.def ui.def file.def vm.def win.def \
                input.def hwr.def localize.def sllang.def \
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
                assert.def library.def timer.def dbase.def initfile.def \
                system.def Objects/inputC.def Objects/vTextC.def \
                spool.def print.def Internal/prodFeatures.def hugearr.def \
                Internal/Jedi/jutils.def Internal/powerDr.def driver.def \
                gadgetsConstant.def gadgetsVisMonikerUtil.def \
                Main/mainVisMonikerUtil.asm
UI.obj \
UI.eobj: UI/uiManager.asm \
                gadgetsGeode.def geos.def stdapp.def geode.def \
                resource.def ec.def lmem.def object.def graphics.def \
                fontID.def font.def color.def gstring.def text.def \
                char.def heap.def ui.def file.def vm.def win.def \
                input.def hwr.def localize.def sllang.def \
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
                assert.def library.def timer.def dbase.def initfile.def \
                system.def Objects/inputC.def Objects/vTextC.def \
                spool.def print.def Internal/prodFeatures.def hugearr.def \
                Internal/Jedi/jutils.def Internal/powerDr.def driver.def \
                gadgetsConstant.def gadgetsVisMonikerUtil.def \
                Objects/gadgets.def uiManager.rdef uiCommon.asm \
                uiRepeatTrigger.asm uiDateSelector.asm uiDateInput.asm \
                uiTimeInputParse.asm uiTimeInputText.asm uiTimeInput.asm \
                uiStopwatch.asm uiTimer.asm uiBatteryIndicator.asm
uiManager.rdef: generic.uih product.uih Objects/gadgets.uih \
                UI/uiStrings.ui UI/uiDateSelector.ui \
                UI/Art/mkrSelector.ui UI/uiDateInput.ui \
                UI/Art/mkrDateInput.ui UI/uiTimeInput.ui \
                UI/Art/mkrTimeInput.ui UI/uiStopwatch.ui UI/uiTimer.ui

gadgetsEC.geo gadgets.geo : geos.ldf ui.ldf 