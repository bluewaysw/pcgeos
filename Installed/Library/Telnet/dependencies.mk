telnetManager.obj \
telnetManager.eobj: geos.def heap.def geode.def resource.def ec.def \
                library.def object.def lmem.def timer.def assert.def \
                disk.def file.def drive.def sockmisc.def \
                Internal/semInt.def Internal/heapInt.def sysstats.def \
                ui.def vm.def text.def fontID.def graphics.def font.def \
                color.def char.def win.def input.def hwr.def localize.def \
                sllang.def Objects/processC.def Objects/metaC.def \
                chunkarr.def geoworks.def gcnlist.def timedate.def \
                Objects/Text/tCommon.def stylesh.def iacp.def \
                Objects/uiInputC.def Objects/visC.def Objects/vCompC.def \
                Objects/vCntC.def Internal/vUtils.def Objects/genC.def \
                uDialog.def Objects/gInterC.def token.def \
                Objects/clipbrd.def Objects/gSysC.def Objects/gProcC.def \
                alb.def Objects/gFieldC.def Objects/gScreenC.def \
                Objects/gFSelC.def Objects/gViewC.def Objects/gContC.def \
                Objects/gCtrlC.def Objects/gDocC.def Objects/gDocCtrl.def \
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
                socket.def telnet.def telnetConstant.def \
                telnetVariable.def telnetMacro.def telnetEC.asm \
                telnetApi.asm telnetConnection.asm telnetOption.asm \
                telnetCommand.asm telnetParser.asm telnetUtils.asm

telnetEC.geo telnet.geo : geos.ldf ui.ldf socket.ldf 