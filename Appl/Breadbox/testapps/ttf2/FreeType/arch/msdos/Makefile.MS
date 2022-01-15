# This file is part of the FreeType project.
#
# It builds the library for Microsoft C for MS-DOS, large model.
# It also works for Visual C++ 1.x 16-bits compiler, but you should
# instead use the Makefile customized for it, Makefile.VC.
# Due to size constraints, it does not try to pack all modules into one.
#
# You will need NMAKE.
#
# Use this file while in the lib directory with the following statement:
#
#   nmake /f arch\msdos\Makefile.MS
#
#
# A debug version can be obtained with
#
#   nmake DEBUG=1 /f arch\msdos\Makefile.MS
#
# A special version enabled to handle big fonts (with more than 16,384
# glyphs) can be obtained with
#
#   nmake BIGFONTS=1 /f arch\msdos\Makefile.MS

ARCH = arch\msdos
FT_MAKEFILE = $(ARCH)\Makefile.MS

CC = cl /nologo
LIB = lib /noignorecase /nologo

!ifndef DEBUG
CFLAGS = /Ox /AL /W2 /G2 /I$(ARCH) /I. /Iextend
!else
CFLAGS = /Zi /AL /W2 /G2 /I$(ARCH) /I. /Iextend
!endif


!ifndef BIGFONTS
CFLAGS = $(CFLAGS) /Za

TTFILE = .\ttfile.c
TTMEMORY = .\ttmemory.c
!else
CFLAGS = $(CFLAGS) /DTT_HUGE_PTR=__huge /Ze

TTFILE = $(ARCH)\hugefile.c
TTMEMORY = $(ARCH)\hugemem.c
!endif

TTMUTEX = .\ttmutex.c

PORT = $(TTFILE) $(TTMEMORY) $(TTMUTEX)

# Do not insert spaces between the file names or at end of line, otherwise
# the substitution for LIB command line will fail. Thank you.
#
SRC_X = extend\ftxgasp.c extend\ftxkern.c extend\ftxpost.c\
extend\ftxcmap.c extend\ftxwidth.c extend\ftxerr18.c extend\ftxsbit.c\
extend\ftxopen.c extend\ftxgsub.c extend\ftxgpos.c extend\ftxgdef.c
OBJS_X = $(SRC_X:.c=.obj)

SRC_M = ttapi.c ttcache.c ttcalc.c ttcmap.c ttdebug.c\
ttgload.c ttinterp.c ttload.c ttobjs.c ttraster.c ttextend.c $(PORT)
OBJS_M = $(SRC_M:.c=.obj) $(OBJS_X)

SRC_S = $(ARCH)\freetype.c
OBJ_S = $(SRC_S:.c=.obj)
OBJS_S = $(OBJ_S) $(OBJS_X)


# Since Microsoft's NMAKE does not handle $($(LIB_FILES)), and using
# LIB_FILES="$(OBJS_S)" will excess the capacity of COMMAND.COM, we cheat
# by constructing LIB's response file directly in the `all' target.
#
# Another solution, useful during debugging of part of the library,
# would be to include each .obj in the library as soon as it is compiled.
# It is commented out below.  See Makefile.TC for an application.
.c.obj:
	@$(CC) /c /Fo$@ @<<
	    $(CFLAGS) $*.c
<<
#	$(LIB) libttf +-$*.obj


!ifndef DEBUG
# Skipped if DEBUG build
#   (but it changes nothing, since we always build in multiple parts).
all: $(OBJS_M)
	-del libttf.lib
	$(LIB) libttf.lib @<<response
+ $(OBJS_M: = ^ );
<<KEEP
!endif

debug: $(OBJS_M)
	-del libttf.lib
	$(LIB) libttf.lib @<<response
+ $(OBJS_M: = ^ );
<<KEEP

$(OBJ_S): $(SRC_S) $(SRC_M)

# Not used here because it excesses the capacity of COMMAND.COM...
libttf.lib: $(LIB_FILES)
	$(LIB) $@ +-$(?: =-+);

clean:
	-del *.obj
	-del extend\*.obj
	-del $(ARCH)\*.obj
	-del response

distclean: clean
	-del libttf.lib

!include "$(ARCH)\depend.dos"

# end of Makefile.MS
