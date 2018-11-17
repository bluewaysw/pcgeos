# DO NOT DELETE THIS LINE
perf.rdef       : generic.uih Objects/colorC.uih Art/mkrPerf.ui strings.ui
perf.eobj \
perf.obj        : Internal/gUtils.def Internal/geodeStr.def\
                  Internal/heapInt.def Internal/semInt.def\
                  Internal/swap.def Internal/swapDr.def Internal/uProcC.def\
                  Internal/vUtils.def Objects/Text/tCommon.def\
                  Objects/clipbrd.def Objects/colorC.def Objects/eMenuC.def\
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
                  Objects/inputC.def Objects/metaC.def Objects/processC.def\
                  Objects/uiInputC.def Objects/vCntC.def Objects/vCompC.def\
                  Objects/vTextC.def Objects/visC.def Objects/winC.def\
                  alb.def calc.asm char.def chunkarr.def color.def\
                  dbase.def disk.def draw.asm drive.def driver.def ec.def\
                  file.def fixedCommonCode.asm font.def fontID.def\
                  gcnlist.def geode.def geos.def geoworks.def graphics.def\
                  gstring.def heap.def hugearr.def hwr.def iacp.def\
                  init.asm initfile.def input.def lmem.def localize.def\
                  object.def perf.asm print.def resource.def sllang.def\
                  spool.def stylesh.def sysstats.def system.def text.def\
                  thread.def timedate.def timer.def token.def uDialog.def\
                  ui.def user.asm vm.def win.def
perf.eobj \
perf.obj:  perf.rdef
perfec.geo perf.geo: geos.ldf ui.ldf color.ldf
