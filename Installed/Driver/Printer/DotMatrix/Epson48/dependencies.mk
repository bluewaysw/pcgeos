# DO NOT DELETE THIS LINE
epson48.rdef    : generic.uih UI/uiOptions1ASFOnlyEpsonLQ.ui\
                  UI/uiOptions1ASFEpsonLQ.ui UI/uiOptions2ASFEpsonLQ.ui
epson48Manager.eobj \
epson48Manager.obj: Buffer/bufferClearOutput.asm Buffer/bufferCreate.asm\
                  Buffer/bufferDestroy.asm Buffer/bufferLoadBand.asm\
                  Buffer/bufferScanBand.asm Buffer/bufferSendOutput.asm\
                  Color/Correct/correctGamma175.asm\
                  Color/Correct/correctGamma20.asm\
                  Color/Correct/correctInk.asm Color/colorGetFormat.asm\
                  Color/colorMapRGBToCMYK.asm Color/colorSet.asm\
                  Color/colorSetFirstCMYK.asm Color/colorSetNextCMYK.asm\
                  Color/colorSetRibbon.asm Cursor/cursorConvert360.asm\
                  Cursor/cursorDotMatrixCommon.asm\
                  Cursor/cursorPrFormFeed60.asm\
                  Cursor/cursorPrLineFeedSet.asm\
                  Cursor/cursorSetCursorAbs72.asm\
                  Graphics/Rotate/rotate24.asm Graphics/Rotate/rotate48.asm\
                  Graphics/Rotate/rotate8.asm\
                  Graphics/graphics3Resolutions.asm\
                  Graphics/graphicsCommon.asm\
                  Graphics/graphicsEpsonCommon.asm\
                  Graphics/graphicsHi48.asm Graphics/graphicsLo8.asm\
                  Graphics/graphicsMed24.asm\
                  Graphics/graphicsPrintSwath360.asm Internal/fontDr.def\
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
                  Page/pageStartSetLength.asm Stream/streamSendCodeOut.asm\
                  Stream/streamWrite.asm Stream/streamWriteByte.asm\
                  Styles/stylesGet.asm Styles/stylesSRBold.asm\
                  Styles/stylesSRCondensed.asm Styles/stylesSRDblHeight.asm\
                  Styles/stylesSRDblWidth.asm Styles/stylesSRItalic.asm\
                  Styles/stylesSRNLQ.asm Styles/stylesSRSubSuperScript.asm\
                  Styles/stylesSRUnderline.asm Styles/stylesSet.asm\
                  Styles/stylesTest.asm Text/Font/fontEpsonLQInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadEpsonSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval12ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm alb.def char.def chunkarr.def\
                  color.def disk.def drive.def driver.def ec.def\
                  epson48Constant.def epson48ControlCodes.asm\
                  epson48Dialog.asm epson48DriverInfo.asm\
                  epson48Manager.asm epson48bjc800Info.asm\
                  epson48bjc800MInfo.asm epson48sq1170Info.asm\
                  epson48sq870Info.asm epson48stylus800Info.asm file.def\
                  font.def fontID.def gcnlist.def geode.def geos.def\
                  geoworks.def graphics.def gstring.def heap.def\
                  hugearr.def hwr.def iacp.def input.def lmem.def\
                  localize.def object.def print.def printcomAdmin.asm\
                  printcomConstant.def printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonJob.asm\
                  printcomEpsonLQ2Cursor.asm printcomEpsonLQ4Graphics.asm\
                  printcomEpsonLQText.asm printcomEpsonStyles.asm\
                  printcomInclude.def printcomInfo.asm printcomMacro.def\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm resource.def sem.def sllang.def\
                  spool.def stylesh.def sysstats.def system.def text.def\
                  timer.def token.def uDialog.def ui.def vm.def win.def
epson48Manager.eobj \
epson48Manager.obj:  epson48.rdef
epson48ec.geo epson48.geo: geos.ldf ui.ldf spool.ldf
