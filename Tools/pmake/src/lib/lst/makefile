all		: lst.lib

.SUFFIXES	: .c .obj .lib

#if _MSDOS
CC		= dosfriend D:\bc45\bin\bcc -v -x -w -D_MSDOS
MACHINE		= DOS
#else
CC		= bcc32 -v -X -a4 -w
MACHINE		= win32
#endif

CFLAGS		= -I\tools2\pmake\src\lib\include -I. -IX:\tools\include

OBJS		= lstAppnd.obj lstAtEnd.obj lstAtFnt.obj lstCat.obj lstClose.obj lstCur.obj lstDatum.obj lstDeQ.obj lstDest.obj lstDupl.obj lstEnQ.obj lstFake.obj lstFind.obj lstFindF.obj lstFirst.obj lstForE.obj lstForEF.obj lstIndex.obj lstInit.obj lstIns.obj lstIsEnd.obj lstIsMT.obj lstLast.obj lstLnth.obj lstMembr.obj lstMove.obj lstNext.obj lstOpen.obj lstPred.obj lstPrev.obj lstRem.obj lstRepl.obj lstSetC.obj lstSucc.obj

.c.obj		:
	$(CC) -c -o$(.TARGET) $(CFLAGS) $(.IMPSRC)

lst.lib		: $(OBJS:S/^/$(MACHINE).md\\/g) .PRECIOUS
	tlib $(MACHINE).md\lst $(OBJS:S/^/-+ $(MACHINE).md\\/g)

clean		:
	-del $(OBJS:S/^/$(MACHINE).md\\/g) $(MACHINE).md\lst.lib 2>NUL

#include "lst.dep"
