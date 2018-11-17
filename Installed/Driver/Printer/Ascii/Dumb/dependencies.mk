# DO NOT DELETE THIS LINE
dumb.rdef       : generic.uih UI/uiOptionsNoSettings.ui
dumbManager.eobj \
dumbManager.obj : Color/colorGetFormat.asm Color/colorSetFirstMono.asm\
                  Color/colorSetNextMono.asm Color/colorSetNone.asm\
                  Cursor/cursorConvert48.asm\
                  Cursor/cursorDotMatrixCommon.asm\
                  Cursor/cursorPrFormFeedGuess.asm\
                  Cursor/cursorPrLineFeedDumb6LPI.asm\
                  Cursor/cursorSetCursorSpace72.asm Internal/fontDr.def\
                  Internal/gUtils.def Internal/gstate.def\
                  Internal/heapInt.def Internal/interrup.def\
                  Internal/parallDr.def Internal/printDr.def\
                  Internal/semInt.def Internal/serialDr.def\
                  Internal/spoolInt.def Internal/streamDr.def\
                  Internal/tmatrix.def Internal/uProcC.def\
                  Internal/vUtils.def Internal/videoDr.def\
                  Internal/window.def Job/jobEndDotMatrix.asm\
                  Job/jobPaperInfo.asm Job/jobPaperPathASFControl.asm\
                  Job/jobResetPrinterAndWait.asm\
                  Job/jobStartDefeatPaperout.asm Objects/Text/tCommon.def\
                  Objects/clipbrd.def Objects/eMenuC.def\
                  Objects/emTrigC.def Objects/emomC.def Objects/gAppC.def\
                  Objects/gBoolC.def Objects/gBoolGC.def Objects/gContC.def\
                  Objects/gCtrlC.def Objects/gDCtrlC.def\
                  Objects/gDListC.def Objects/gDispC.def Objects/gDocC.def\
                  Objects/gDocCtrl.def Objects/gDocGrpC.def\
                  Objects/gEditCC.def Objects/gFSelC.def\
                  Objects/gFieldC.def Objects/gGadgetC.def\
                  Objects/gGlyphC.def Objects/gInterC.def\
                  Objects/gItemC.def Objects/gItemGC.def\
                  Objects/gPageCC.def Objects/gPenICC.def\
                  Objects/gPrimC.def Objects/gProcC.def\
                  Objects/gScreenC.def Objects/gSysC.def Objects/gTextC.def\
                  Objects/gToolCC.def Objects/gToolGC.def\
                  Objects/gTrigC.def Objects/gValueC.def Objects/gViewC.def\
                  Objects/gViewCC.def Objects/genC.def Objects/helpCC.def\
                  Objects/metaC.def Objects/processC.def\
                  Objects/uiInputC.def Objects/vCntC.def Objects/vCompC.def\
                  Objects/visC.def Page/pageEndLFSetLength.asm\
                  Page/pageStartSetLength.asm\
                  Stream/streamHexToASCIILeading0.asm\
                  Stream/streamSendCodeOut.asm Stream/streamWrite.asm\
                  Stream/streamWriteByte.asm Text/Font/fontDumbInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRunAddX.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEvalDummyTractor.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm alb.def char.def chunkarr.def\
                  color.def disk.def drive.def driver.def dumbConstant.def\
                  dumbControlCodes.asm dumbDialog.asm dumbDriverInfo.asm\
                  dumbInfo.asm dumbManager.asm dumbText.asm ec.def file.def\
                  font.def fontID.def gcnlist.def geode.def geos.def\
                  geoworks.def graphics.def gstring.def heap.def\
                  hugearr.def hwr.def iacp.def input.def lmem.def\
                  localize.def object.def print.def printcomAdmin.asm\
                  printcomConstant.def printcomDotMatrixPage.asm\
                  printcomDumbSpaceCursor.asm printcomEntry.asm\
                  printcomEpsonJob.asm printcomHex0Stream.asm\
                  printcomInclude.def printcomInfo.asm printcomMacro.def\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomNoGraphics.asm printcomNoStyles.asm\
                  printcomTables.asm resource.def sem.def sllang.def\
                  spool.def stylesh.def sysstats.def system.def text.def\
                  timer.def token.def uDialog.def ui.def vm.def win.def
dumbManager.eobj \
dumbManager.obj:  dumb.rdef
dumbec.geo dumb.geo: geos.ldf ui.ldf spool.ldf
