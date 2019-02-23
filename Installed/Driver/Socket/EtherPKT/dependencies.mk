ethpktManager.obj \
ethpktManager.eobj: geos.def heap.def geode.def resource.def ec.def thread.def \
                sem.def driver.def lmem.def system.def localize.def \
                sllang.def medium.def assert.def disk.def file.def \
                drive.def Internal/interrup.def ui.def vm.def text.def \
                fontID.def graphics.def font.def color.def char.def \
                win.def input.def hwr.def Objects/processC.def \
                Objects/metaC.def object.def chunkarr.def geoworks.def \
                gcnlist.def timedate.def Objects/Text/tCommon.def \
                stylesh.def iacp.def Objects/uiInputC.def \
                Objects/visC.def Objects/vCompC.def Objects/vCntC.def \
                Internal/vUtils.def Objects/genC.def uDialog.def \
                Objects/gInterC.def token.def Objects/clipbrd.def \
                Objects/gSysC.def Objects/gProcC.def alb.def \
                Objects/gFieldC.def Objects/gScreenC.def \
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
                Internal/netutils.def socket.def Internal/socketInt.def \
                Internal/heapInt.def Internal/semInt.def sysstats.def \
                Internal/ip.def Internal/socketDr.def sockmisc.def \
                timer.def Internal/im.def accpnt.def \
                ../EtherCom/ethercomConstant.def \
                ../EtherCom/ethercomMacro.def arp.def ethpktConstant.def \
                ../EtherCom/ethercomVariable.def ethpktVariable.def \
                ../EtherCom/ethercomUtil.asm \
                ../EtherCom/ethercomStrategy.asm \
                ../EtherCom/ethercomGetInfo.asm \
                ../EtherCom/ethercomTransceive.asm \
                ../EtherCom/ethercomLink.asm \
                ../EtherCom/ethercomClient.asm \
                ../EtherCom/ethercomOption.asm \
                ../EtherCom/ethercomMedium.asm \
                ../EtherCom/ethercomProcess.asm ethpktInit.asm \
                ethpktTransceive.asm ethpktArp.asm

etherpktEC.geo etherpkt.geo : geos.ldf netutils.ldf accpnt.ldf 