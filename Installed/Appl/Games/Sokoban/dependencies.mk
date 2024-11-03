sokoban.rdef: generic.uih product.uih game.uih Objects/colorC.uih \
                screens.ui sokobanStrings.ui sokobanEditor.ui \
                Art/mksok.ui Art/mkrSokobanDoc.ui
sokobanJBitmaps.obj \
sokobanJBitmaps.eobj: 
sokobanManager.obj \
sokobanManager.eobj: stdapp.def geos.def geode.def resource.def ec.def lmem.def \
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
                Objects/emomC.def Objects/emTrigC.def Internal/uProcC.def \
                hugearr.def initfile.def system.def Internal/threadIn.def \
                assert.def Objects/winC.def Objects/inputC.def game.def \
                sound.def driver.def Internal/soundFmt.def \
                Internal/semInt.def Objects/vTextC.def spool.def \
                print.def Internal/prodFeatures.def dbase.def \
                Objects/colorC.def sokoban.def sokoban.rdef \
                sokobanBitmaps.asm sokoban.asm sokobanUI.asm \
                sokobanDocument.asm sokobanApplication.asm \
                sokobanSolve.asm sokobanMove.asm sokobanSounds.asm \
                sokobanScores.asm sokobanLevels.asm sokobanEditor.asm

sokobanEC.geo sokoban.geo : geos.ldf ui.ldf game.ldf 