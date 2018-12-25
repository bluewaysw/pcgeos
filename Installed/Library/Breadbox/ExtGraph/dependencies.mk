ASMTOOLS.obj \
ASMTOOLS.eobj: ASMTOOLS/asmtoolsManager.asm \
                stdapp.def geos.def geode.def resource.def ec.def lmem.def \
                object.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def heap.def ui.def file.def \
                vm.def win.def input.def hwr.def localize.def sllang.def \
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
                Objects/emomC.def Objects/emTrigC.def Internal/uProcC.def
pal.obj \
pal.eobj: extgraph.goh Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh
pal.obj \
pal.eobj: geos.h heap.h gstring.h graphics.h fontID.h font.h color.h \
                Ansi/string.h lmem.h vm.h chunkarr.h object.h geode.h \
                Objects/helpCC.h file.h input.h char.h hwr.h win.h
extgr.obj \
extgr.eobj: extgraph.goh Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh
extgr.obj \
extgr.eobj: geos.h gstring.h graphics.h fontID.h font.h color.h \
                chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h hwr.h win.h vm.h timer.h ec.h
bmp.obj \
bmp.eobj: extgraph.goh Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh
bmp.obj \
bmp.eobj: geos.h gstring.h graphics.h fontID.h font.h color.h \
                chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h hwr.h win.h vm.h timer.h ec.h \
                heap.h Ansi/string.h hugearr.h
bmpRotate.obj \
bmpRotate.eobj: extgraph.goh Objects/winC.goh Objects/metaC.goh object.goh \
                Objects/inputC.goh Objects/uiInputC.goh Objects/visC.goh
bmpRotate.obj \
bmpRotate.eobj: geos.h gstring.h graphics.h fontID.h font.h color.h \
                chunkarr.h object.h geode.h lmem.h Objects/helpCC.h \
                file.h input.h char.h hwr.h win.h vm.h hugearr.h ec.h

extgraphEC.geo extgraph.geo : geos.ldf ansic.ldf 