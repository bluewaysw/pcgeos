noid.obj \
noid.eobj: stdapp.goh object.goh ui.goh Objects/metaC.goh \
                Objects/inputC.goh Objects/clipbrd.goh \
                Objects/uiInputC.goh iacp.goh Objects/winC.goh \
                Objects/gProcC.goh alb.goh Objects/processC.goh \
                Objects/visC.goh Objects/vCompC.goh Objects/vCntC.goh \
                Objects/gAppC.goh Objects/genC.goh Objects/gInterC.goh \
                Objects/gPrimC.goh Objects/gDispC.goh Objects/gTrigC.goh \
                Objects/gViewC.goh Objects/gTextC.goh Objects/vTextC.goh \
                Objects/gCtrlC.goh gcnlist.goh spool.goh \
                Objects/gFSelC.goh Objects/gGlyphC.goh \
                Objects/gDocCtrl.goh Objects/gDocGrpC.goh \
                Objects/gDocC.goh Objects/gContC.goh Objects/gDCtrlC.goh \
                Objects/gEditCC.goh Objects/gBoolGC.goh \
                Objects/gItemGC.goh Objects/gDListC.goh \
                Objects/gItemC.goh Objects/gBoolC.goh \
                Objects/gGadgetC.goh Objects/gToolCC.goh \
                Objects/gValueC.goh Objects/gToolGC.goh \
                Objects/helpCC.goh Objects/colorC.goh game.goh \
                Art/icon.goh Art/ball.goh Art/oppon1.goh Art/oppon2.goh \
                Art/oppon3.goh Art/oppon4.goh Art/oppon5.goh \
                Art/brick1.goh Art/brick2.goh Art/brick3.goh \
                Art/brick4.goh Art/brick5.goh Art/brick6.goh \
                Art/brick7.goh Art/brick8.goh Art/brick9.goh \
                Art/brick10.goh Art/brick11.goh Art/brick12.goh \
                Art/brick13.goh Art/brick14.goh Art/brick15.goh \
                Art/QTip1.goh Art/QTip2.goh
noid.obj \
noid.eobj: geos.h heap.h geode.h resource.h ec.h object.h lmem.h \
                graphics.h fontID.h font.h color.h gstring.h timer.h vm.h \
                dbase.h localize.h Ansi/ctype.h timedate.h file.h \
                sllang.h system.h geoworks.h chunkarr.h Objects/helpCC.h \
                disk.h drive.h input.h char.h hwr.h win.h uDialog.h \
                Objects/gInterC.h Objects/Text/tCommon.h stylesh.h \
                driver.h thread.h print.h Internal/spoolInt.h serialDr.h \
                parallDr.h hugearr.h fileEnum.h initfile.h Ansi/stdlib.h \
                sound.h sem.h

noidEC.geo noid.geo : geos.ldf ui.ldf sound.ldf game.ldf color.ldf 