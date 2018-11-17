# DO NOT DELETE THIS LINE
oki9.rdef       : generic.uih UI/uiOptions0ASF1Man1Trac.ui
oki9Manager.eobj \
oki9Manager.obj : Buffer/bufferClearOutput.asm Buffer/bufferCreate.asm\
                  Buffer/bufferDestroy.asm Buffer/bufferLoadBand.asm\
                  Buffer/bufferOkiSendOutput.asm Buffer/bufferScanBand.asm\
                  Color/colorGetFormat.asm Color/colorSetFirstMono.asm\
                  Color/colorSetNextMono.asm Color/colorSetNone.asm\
                  Cursor/cursor1ScanlineFeed.asm\
                  Cursor/cursorConvert144.asm\
                  Cursor/cursorDotMatrixCommon.asm\
                  Cursor/cursorPrFormFeed72ASCII.asm\
                  Cursor/cursorPrLineFeedSet.asm\
                  Cursor/cursorSetCursorTab72ASCII.asm\
                  Graphics/Rotate/rotate7Back.asm\
                  Graphics/graphics2Resolutions.asm\
                  Graphics/graphicsCommon.asm Graphics/graphicsHi7IntY.asm\
                  Graphics/graphicsLo7.asm\
                  Graphics/graphicsPrintSwath144.asm Internal/fontDr.def\
                  Internal/gUtils.def Internal/gstate.def\
                  Internal/heapInt.def Internal/interrup.def\
                  Internal/parallDr.def Internal/printDr.def\
                  Internal/semInt.def Internal/serialDr.def\
                  Internal/spoolInt.def Internal/streamDr.def\
                  Internal/tmatrix.def Internal/uProcC.def\
                  Internal/vUtils.def Internal/videoDr.def\
                  Internal/window.def Job/jobEndDotMatrix.asm\
                  Job/jobPaperInfo.asm Job/jobPaperPathNoASFControl.asm\
                  Job/jobResetPrinterAndWait.asm Job/jobStartDotMatrix.asm\
                  Objects/Text/tCommon.def Objects/clipbrd.def\
                  Objects/eMenuC.def Objects/emTrigC.def Objects/emomC.def\
                  Objects/gAppC.def Objects/gBoolC.def Objects/gBoolGC.def\
                  Objects/gContC.def Objects/gCtrlC.def Objects/gDCtrlC.def\
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
                  Stream/streamWriteByte.asm Styles/stylesGet.asm\
                  Styles/stylesSRBold.asm Styles/stylesSRItalic.asm\
                  Styles/stylesSRNLQ.asm Styles/stylesSRSubscript.asm\
                  Styles/stylesSRSuperscript.asm\
                  Styles/stylesSRUnderline.asm Styles/stylesSet.asm\
                  Styles/stylesTest.asm Text/Font/fontOkiInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEvalNoASF.asm UI/uiGetNoMain.asm UI/uiGetOptions.asm\
                  alb.def char.def chunkarr.def color.def disk.def\
                  drive.def driver.def ec.def file.def font.def fontID.def\
                  gcnlist.def geode.def geos.def geoworks.def graphics.def\
                  gstring.def heap.def hugearr.def hwr.def iacp.def\
                  input.def lmem.def localize.def object.def oki992Info.asm\
                  oki993Info.asm oki9Constant.def oki9ControlCodes.asm\
                  oki9Dialog.asm oki9DriverInfo.asm oki9Manager.asm\
                  oki9Styles.asm print.def printcomAdmin.asm\
                  printcomConstant.def printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomHex0Stream.asm\
                  printcomIBMJob.asm printcomInclude.def printcomInfo.asm\
                  printcomMacro.def printcomNoColor.asm\
                  printcomNoEscapes.asm printcomOkiBuffer.asm\
                  printcomOkiCursor.asm printcomOkiGraphics.asm\
                  printcomOkiText.asm printcomTables.asm resource.def\
                  sem.def sllang.def spool.def stylesh.def sysstats.def\
                  system.def text.def timer.def token.def uDialog.def\
                  ui.def vm.def win.def
oki9Manager.eobj \
oki9Manager.obj:  oki9.rdef
oki9ec.geo oki9.geo: geos.ldf ui.ldf spool.ldf
