taskmax.rdef: generic.uih product.uih \
                /home/konstantinmeyer/github/pcgeos/Driver/Task/Common/task.ui
taskmaxManager.obj \
taskmaxManager.eobj: taskGeode.def geos.def heap.def geode.def resource.def \
                ec.def lmem.def system.def localize.def sllang.def \
                drive.def disk.def file.def driver.def timedate.def \
                initfile.def char.def thread.def Internal/taskDr.def \
                Internal/interrup.def Internal/dos.def fileEnum.def \
                Internal/semInt.def Internal/fileInt.def \
                Internal/driveInt.def Internal/im.def \
                Objects/processC.def Objects/metaC.def object.def \
                chunkarr.def geoworks.def ui.def vm.def text.def \
                fontID.def graphics.def font.def color.def win.def \
                input.def hwr.def gcnlist.def Objects/Text/tCommon.def \
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
                Objects/vTextC.def spool.def print.def \
                Internal/prodFeatures.def hugearr.def dbase.def \
                Objects/winC.def taskConstant.def taskMacro.def \
                taskVariable.def taskmaxConstant.def taskmaxVariable.def \
                taskmax.rdef taskStrings.asm taskmaxStrings.asm \
                taskInit.asm taskmaxInitExit.asm taskSwitch.asm \
                taskApplication.asm taskmaxApplication.asm taskDriver.asm \
                taskmaxDriver.asm taskTrigger.asm taskItem.asm \
                taskmaxItem.asm taskUtils.asm taskmaxUtils.asm \
                taskmaxMain.asm taskmaxSummons.asm taskClipboard.asm \
                taskmaxClipboard.asm

taskmaxEC.geo taskmax.geo : ui.ldf geos.ldf text.ldf 