# DO NOT DELETE THIS LINE
canonBJC.rdef    : generic.uih canonBJC.ui UI/uiOptions1ASFCanonBJC.ui
canonBJCManager.eobj \
canonBJCManager.obj: canonBJCControlCodes.asm canonBJCDialog.asm\
                  canonBJCDriverInfo.asm canonBJCManager.asm\
                  canonBJCcmykInfo.asm canonBJCcmyInfo.asm\
                  canonBJCmonoInfo.asm UI/UIGetNoMain.asm\
                  UI/UIGetOptions.asm UI/UIEval.asm UI/UIEvalDummyASF.asm\
                  printcomEntry.asm printcomInfo.asm printcomAdmin.asm\
                  printcomTables.asm printcomNoEscapes.asm\
                  printcomCanonBJCJob.asm printcomASFOnlyPage.asm\
                  printcomCanonBJCCursor.asm printcomStream.asm\
                  printcomCanonBJCColor.asm printcomCanonBJCGraphics.asm\
                  printcomNoStyles.asm printcomNoText.asm\
                  Buffer/bufferCreate.asm Buffer/bufferDestroy.asm\
                  canonBJCConstant.def canonBJC.rdef\
		  Internal/fontDr.def Internal/gUtils.def\
                  Internal/gstate.def Internal/heapInt.def\
                  Internal/interrup.def Internal/parallDr.def\
                  Internal/printDr.def Internal/semInt.def\
                  Internal/serialDr.def Internal/spoolInt.def\
                  Internal/streamDr.def Internal/tmatrix.def\
                  Internal/uProcC.def Internal/vUtils.def\
                  Internal/videoDr.def Internal/window.def\
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
                  char.def\
		  chunkarr.def color.def disk.def drive.def driver.def\
                  ec.def file.def font.def fontID.def gcnlist.def geode.def\
                  geos.def geoworks.def graphics.def gstring.def heap.def\
                  hugearr.def hwr.def iacp.def input.def lmem.def\
                  localize.def object.def print.def\
                  resource.def\
                  sem.def sllang.def spool.def stylesh.def sysstats.def\
                  system.def text.def timer.def token.def uDialog.def\
                  ui.def vm.def win.def
canonBJCec.geo canonBJC.geo: geos.ldf ui.ldf spool.ldf
