# DO NOT DELETE THIS LINE
pcl4Manager.eobj \
pcl4Manager.obj : Color/colorGetFormat.asm Color/colorSetFirstMono.asm\
                  Color/colorSetNextMono.asm Color/colorSetNone.asm\
                  Cursor/cursorConvert300.asm Cursor/cursorPCLCommon.asm\
                  Cursor/cursorSetCursorPCL.asm\
                  Graphics/graphicsAdjustForResolution.asm\
                  Graphics/graphicsCommon.asm\
                  Graphics/graphicsPrintSwathPCL4.asm\
                  Graphics/graphicsSendBitmapCompressedPCL4.asm\
                  Graphics/graphicsSendBitmapPCL4.asm Internal/fontDr.def\
                  Internal/gUtils.def Internal/gstate.def\
                  Internal/heapInt.def Internal/interrup.def\
                  Internal/parallDr.def Internal/printDr.def\
                  Internal/semInt.def Internal/serialDr.def\
                  Internal/spoolInt.def Internal/streamDr.def\
                  Internal/tmatrix.def Internal/uProcC.def\
                  Internal/vUtils.def Internal/videoDr.def\
                  Internal/window.def Job/Custom/customIBMPJLToPCL.asm\
                  Job/Custom/customLJ4PCL.asm Job/Custom/customPJLToPCL.asm\
                  Job/Custom/customPPDSToPCL.asm\
                  Job/Custom/customTotalResetPCL.asm Job/jobCopiesPCL4.asm\
                  Job/jobEndPCL4.asm Job/jobPaperInfo.asm\
                  Job/jobPaperPCL.asm Job/jobStartPCL.asm\
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
                  Objects/visC.def Page/pageEndPCL4.asm\
                  Page/pageStartPCL4.asm Stream/streamHexToASCII.asm\
                  Stream/streamPCLCommand.asm Stream/streamSendCodeOut.asm\
                  Stream/streamWrite.asm Stream/streamWriteByte.asm\
                  Styles/stylesGetPCL4.asm Styles/stylesSetPCL4.asm\
                  Styles/stylesTestPCL4.asm Text/Font/fontDownloadPCL4.asm\
                  Text/Font/fontInternalPCL4.asm Text/Font/fontPCLInfo.asm\
                  Text/Font/fontTopLevelPCL4.asm\
                  Text/Font/fontUtilsPCL4.asm Text/textGetLineSpacing.asm\
                  Text/textInitFontPCL4.asm Text/textLoadNoISOSymbolSet.asm\
                  Text/textPrintRaw.asm Text/textPrintStyleRunPCL4.asm\
                  Text/textPrintTextPCL4.asm Text/textSetFontPCL4.asm\
                  Text/textSetLineSpacing.asm Text/textSetSymbolSet.asm\
                  UI/uiEval.asm UI/uiEvalPCL4Duplex.asm\
                  UI/uiEvalPCL4Simplex.asm UI/uiGetMain.asm\
                  UI/uiGetOptions.asm alb.def char.def chunkarr.def\
                  color.def disk.def downloadDuplexInfo.asm\
                  downloadInfo.asm drive.def driver.def ec.def file.def\
                  font.def fontID.def gcnlist.def geode.def geos.def\
                  geoworks.def graphics.def gstring.def heap.def\
                  hugearr.def hwr.def iacp.def ibm4019Info.asm\
                  ibm4039Info.asm input.def internalDuplexInfo.asm\
                  internalInfo.asm laserjet2CompInfo.asm laserjet2Info.asm\
                  laserjet3SiInfo.asm laserjet4Info.asm lmem.def\
                  localize.def object.def paintjetXL300Info.asm\
                  pcl4Constant.def pcl4ControlCodes.asm pcl4DriverInfo.asm\
                  pcl4Manager.asm pcl4Tables.asm ppdsInfo.asm print.def\
                  printcomAdmin.asm printcomConstant.def printcomEntry.asm\
                  printcomInclude.def printcomInfo.asm printcomMacro.def\
                  printcomNoColor.asm printcomPCL4Cursor.asm\
                  printcomPCL4Dialog.asm printcomPCL4Graphics.asm\
                  printcomPCL4Job.asm printcomPCL4Page.asm\
                  printcomPCL4Styles.asm printcomPCL4Text.asm\
                  printcomPCLStream.asm printcomTables.asm resource.def\
                  sem.def sllang.def spool.def stylesh.def sysstats.def\
                  system.def text.def timer.def token.def\
                  totalResetInfo.asm uDialog.def ui.def vm.def win.def
pcl4Manager.eobj \
pcl4Manager.obj:  printcomPCL4.rdef
pcl4ec.geo pcl4.geo: geos.ldf ui.ldf spool.ldf
