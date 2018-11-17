obj_files = lstAppnd.obj lstAtEnd.obj lstAtFnt.obj lstCat.obj lstClose.obj lstCur.obj lstDatum.obj lstDeQ.obj lstDest.obj lstDupl.obj lstEnQ.obj lstFake.obj lstFind.obj lstFindF.obj lstFirst.obj lstForE.obj lstForEF.obj lstIndex.obj lstInit.obj lstIns.obj lstIsEnd.obj lstIsMT.obj lstLast.obj lstLnth.obj lstMembr.obj lstMove.obj lstNext.obj lstOpen.obj lstPred.obj lstPrev.obj lstRem.obj lstRepl.obj lstSetC.obj lstSucc.obj

.c.obj
	wcc386 -d_LINUX -i=$(WATCOM)\h -i=$(WATCOM)\h\nt -i=..\..\src\lib\include -i=..\..\..\include -i..\..\src\lib\lst -i=c:\g6_\pcgeos\include -fo=$*.obj $<

lst.lib: $(obj_files)
  wlib $@ +lstAppnd.obj +lstAtEnd.obj +lstAtFnt.obj +lstCat.obj +lstClose.obj +lstCur.obj +lstDatum.obj +lstDeQ.obj +lstDest.obj +lstDupl.obj +lstEnQ.obj +lstFake.obj +lstFind.obj +lstFindF.obj +lstFirst.obj +lstForE.obj +lstForEF.obj +lstIndex.obj +lstInit.obj +lstIns.obj +lstIsEnd.obj +lstIsMT.obj +lstLast.obj +lstLnth.obj +lstMembr.obj +lstMove.obj +lstNext.obj +lstOpen.obj +lstPred.obj +lstPrev.obj +lstRem.obj +lstRepl.obj +lstSetC.obj +lstSucc.obj
