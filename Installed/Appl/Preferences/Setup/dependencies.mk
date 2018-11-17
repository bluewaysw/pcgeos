# DO NOT DELETE THIS LINE
setup.rdef      : generic.uih spool.uih config.uih Objects/colorC.uih\
                  setupVideo.ui setupMouse.ui setupPrinter.ui\
                  setupSysInfo.ui setupSerialNum.ui setupUpgrade.ui\
                  setupUI.ui Art/mkrMotif.ui Art/mkrNewUI.ui\
                  Art/mkrBWMotif.ui Art/mkrBWNewUI.ui Art/mkrCGAMotif.ui\
                  Art/mkrCGANewUI.ui
setup.eobj \
setup.obj       : Internal/dos.def Internal/driveInt.def\
                  Internal/fileInt.def Internal/gUtils.def\
                  Internal/geodeStr.def Internal/im.def\
                  Internal/mouseDr.def Internal/parallDr.def\
                  Internal/powerDr.def\
                  Internal/printDr.def Internal/prodFeatures.def\
                  Internal/semInt.def Internal/serialDr.def\
                  Internal/spoolInt.def Internal/streamDr.def\
                  Internal/swap.def Internal/swapDr.def Internal/uProcC.def\
                  Internal/vUtils.def Internal/videoDr.def\
                  Objects/Text/tCommon.def Objects/clipbrd.def\
                  Objects/colorC.def Objects/eMenuC.def Objects/emTrigC.def\
                  Objects/emomC.def Objects/gAppC.def Objects/gBoolC.def\
                  Objects/gBoolGC.def Objects/gContC.def Objects/gCtrlC.def\
                  Objects/gDCtrlC.def Objects/gDListC.def\
                  Objects/gDispC.def Objects/gDocC.def Objects/gDocCtrl.def\
                  Objects/gDocGrpC.def Objects/gEditCC.def\
                  Objects/gFSelC.def Objects/gFieldC.def\
                  Objects/gGadgetC.def Objects/gGlyphC.def\
                  Objects/gInterC.def Objects/gItemC.def\
                  Objects/gItemGC.def Objects/gPageCC.def\
                  Objects/gPenICC.def Objects/gPrimC.def Objects/gProcC.def\
                  Objects/gScreenC.def Objects/gSysC.def Objects/gTextC.def\
                  Objects/gToolCC.def Objects/gToolGC.def\
                  Objects/gTrigC.def Objects/gValueC.def Objects/gViewC.def\
                  Objects/gViewCC.def Objects/genC.def Objects/helpCC.def\
                  Objects/inputC.def Objects/metaC.def Objects/processC.def\
                  Objects/uiInputC.def Objects/vCntC.def Objects/vCompC.def\
                  Objects/vTextC.def Objects/visC.def alb.def char.def\
                  chunkarr.def color.def commonUtils.asm config.def\
                  cvttool.def dbase.def disk.def drive.def driver.def\
                  ec.def file.def fileEnum.def fmtool.def font.def\
                  fontID.def gcnlist.def geode.def geos.def geoworks.def\
                  graphics.def gstring.def heap.def hugearr.def hwr.def\
                  iacp.def initfile.def input.def library.def lmem.def\
                  localize.def object.def prefConstant.def prefPrinter.asm\
                  prefVariable.def print.def resource.def setup.asm\
                  setupConstant.def setupDispRes.asm setupMouse.asm\
                  setupPorts.asm setupPrinter.asm setupProcess.asm\
                  setupScreenClass.asm setupSerialNum.asm setupSysInfo.asm\
                  setupUI.asm setupUpgrade.asm setupUtils.asm\
                  setupVariable.def setupVideo.asm sllang.def spool.def\
                  stylesh.def sysstats.def system.def text.def thread.def\
                  timedate.def timer.def token.def uDialog.def ui.def\
                  vm.def win.def
setup.eobj \
setup.obj:  setup.rdef
setupec.geo setup.geo: geos.ldf ui.ldf spool.ldf config.ldf serial.ldf parallel.ldf
