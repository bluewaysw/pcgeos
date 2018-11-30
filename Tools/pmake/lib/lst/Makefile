obj_files = lstAppnd.obj lstAtEnd.obj lstAtFnt.obj lstCat.obj lstClose.obj lstCur.obj lstDatum.obj lstDeQ.obj lstDest.obj lstDupl.obj lstEnQ.obj lstFake.obj lstFind.obj lstFindF.obj lstFirst.obj lstForE.obj lstForEF.obj lstIndex.obj lstInit.obj lstIns.obj lstIsEnd.obj lstIsMT.obj lstLast.obj lstLnth.obj lstMembr.obj lstMove.obj lstNext.obj lstOpen.obj lstPred.obj lstPrev.obj lstRem.obj lstRepl.obj lstSetC.obj lstSucc.obj
o_files = lstAppnd.o lstAtEnd.o lstAtFnt.o lstCat.o lstClose.o lstCur.o lstDatum.o lstDeQ.o lstDest.o lstDupl.o lstEnQ.o lstFake.o lstFind.o lstFindF.o lstFirst.o lstForE.o lstForEF.o lstIndex.o lstInit.o lstIns.o lstIsEnd.o lstIsMT.o lstLast.o lstLnth.o lstMembr.o lstMove.o lstNext.o lstOpen.o lstPred.o lstPrev.o lstRem.o lstRepl.o lstSetC.o lstSucc.o

.c.obj
	wcc386 -bt=nt -i="$(%WATCOM)/h" -i="$(%WATCOM)/h/nt" -i="../../src/lib/include" -i="../../../include" -i="../../src/lib/sprite" -fo=$*.obj $<
.c.o
		wcc386 -bt=linux -d_LINUX -i="$(%WATCOM)/h" -i="$(%WATCOM)/h/nt" -i="../../src/lib/include" -i="../../../include" -i="../../src/lib/sprite" -fo=$*.o $<

lst.lib: $(obj_files)
  wlib $@ +lstAppnd.obj +lstAtEnd.obj +lstAtFnt.obj +lstCat.obj +lstClose.obj +lstCur.obj +lstDatum.obj +lstDeQ.obj +lstDest.obj +lstDupl.obj +lstEnQ.obj +lstFake.obj +lstFind.obj +lstFindF.obj +lstFirst.obj +lstForE.obj +lstForEF.obj +lstIndex.obj +lstInit.obj +lstIns.obj +lstIsEnd.obj +lstIsMT.obj +lstLast.obj +lstLnth.obj +lstMembr.obj +lstMove.obj +lstNext.obj +lstOpen.obj +lstPred.obj +lstPrev.obj +lstRem.obj +lstRepl.obj +lstSetC.obj +lstSucc.obj

liblst.a: $(o_files)
	 wlib $@ +lstAppnd.o +lstAtEnd.o +lstAtFnt.o +lstCat.o +lstClose.o +lstCur.o +lstDatum.o +lstDeQ.o +lstDest.o +lstDupl.o +lstEnQ.o +lstFake.o +lstFind.o +lstFindF.o +lstFirst.o +lstForE.o +lstForEF.o +lstIndex.o +lstInit.o +lstIns.o +lstIsEnd.o +lstIsMT.o +lstLast.o +lstLnth.o +lstMembr.o +lstMove.o +lstNext.o +lstOpen.o +lstPred.o +lstPrev.o +lstRem.o +lstRepl.o +lstSetC.o +lstSucc.o

all:	liblst.a lst.lib
