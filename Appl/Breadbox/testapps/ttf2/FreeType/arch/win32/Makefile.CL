# This file is part of the FreeType project.
#
# It builds the library for Microsoft Visual C++ for 32-bit Windows.
#
# You will need NMAKE.
#
# Use this file while in the lib directory with the following statement:
#
#   nmake /f arch\win32\Makefile.CL
#
#
# A DLL version of the library can be built with
#
#   nmake DLL=1 /f arch\win32\Makefile.CL dll
#
# Debug versions can be obtained with
#
#   nmake DEBUG=1 /f arch\win32\Makefile.CL

ARCH = arch\win32
FT_MAKEFILE = $(ARCH)\Makefile.CL
FT_DLL = ft13_32.dll

CC = cl /nologo
LIB = lib /nologo
LINK = link /nologo

CFLAGS = /Za /W2 -I$(ARCH) -I. -Iextend

!ifndef DEBUG
CFLAGS = $(CFLAGS) /Ox
DLLFLAGS = /RELEASE
!else
CFLAGS = $(CFLAGS) /Zi /Ge
DLLFLAGS = /DEBUG
!endif

!ifdef DLL
CFLAGS = $(CFLAGS) /GD \
    /DEXPORT_DEF=__declspec(dllexport) /DEXPORT_FUNC=__declspec(dllexport)
!else
CFLAGS = $(CFLAGS) /GA
!endif


TTFILE = .\ttfile.c
TTMEMORY = .\ttmemory.c
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
# See ..\msdos\Makefile.TC for an application.
.c.obj:
	@$(CC) /c /Fo$@ @<<
	    $(CFLAGS) $*.c
<<


!ifndef DEBUG
# Skipped if DEBUG build
all: $(OBJS_S)
	-del libttf.lib
	$(LIB) /OUT:libttf.lib @<<response
+ $(OBJS_S: = + );
<<KEEP

dll $(FT_DLL): $(OBJS_S)
!ifdef DLL
	$(LINK) @<<response
	  $(DLLFLAGS)
	  /DLL
	  /OUT:$(FT_DLL)
	  /IMPLIB:libttf.lib
	  /DEF:$(ARCH)\ttf.def
	  $**
<<KEEP
!else
	$(MAKE) DLL=1 /f $(FT_MAKEFILE) dll    # Re-invoke with flag set.
!endif

!endif


debug: $(OBJS_M)
	-del libttf.lib
	$(LIB) /OUT:libttf.lib @<<response
+ $(OBJS_M: = + );
<<KEEP

!ifdef DEBUG
dll $(FT_DLL): $(OBJS_M)
!ifdef DLL
	$(LINK) @<<response
	  $(DLLFLAGS)
	  /DLL
	  /OUT:$(FT_DLL)
	  /IMPLIB:libttf.lib
	  /DEF:$(ARCH)\ttf.def
	  $**
<<KEEP
!else
	$(MAKE) DLL=1 DEBUG=1 /f $(FT_MAKEFILE) dll    # Re-invoke with flag set.
!endif
!endif

install: $(FT_DLL)
!ifdef INSTALL_DIR
	copy $(FT_DLL) $(INSTALL_DIR)
!else
	copy $(FT_DLL) C:\WINDOWS
!endif


$(OBJ_S): $(SRC_S) $(SRC_M)

# Not used here because it excesses the capacity of COMMAND.COM...
libttf.lib: $(LIB_FILES)
	$(LIB) $@ +-$(?: =-+);


clean:
	-del *.obj
	-del extend\*.obj
	-del $(ARCH)\*.obj
	-del libttf.bak
	-del response
	-del *.exp
	-del *.pch
	-del *.ilk

distclean: clean
	-del libttf.lib
	-del *.dll
	-del *.pdb
	-del C:\WINDOWS\$(FT_DLL)
!ifdef INSTALL_DIR
	-del $(INSTALL_DIR)\$(FT_DLL)
!endif

!include "$(ARCH)\depend.win"

# end of Makefile.CL
