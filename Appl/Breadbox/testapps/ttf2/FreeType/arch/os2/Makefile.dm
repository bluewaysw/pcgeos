# This file is part of the FreeType project.
#
# It builds the library and test programs for emx-gcc under OS/2
#
# You will need dmake.
#
# Use this file while in the lib directory with the following statement:
#
#   dmake -r -f arch/os2/Makefile.dm

ARCH = arch/os2
FT_MAKEFILE = $(ARCH)/Makefile.dm
FT_MAKE = dmake -r

.IMPORT: COMSPEC
SHELL := $(COMSPEC)
SHELLFLAGS := /c
GROUPSHELL := $(SHELL)
GROUPFLAGS := $(SHELLFLAGS)
GROUPSUFFIX := .cmd
SHELLMETAS := *"?<>&|

CC = gcc

CFLAGS = -Wall -O2 -g -ansi -pedantic -I$(ARCH) -I. -Iextend
# CFLAGS = -Wall -ansi -O2 -s -I$(ARCH) -I. -Iextend

TTFILE = $(ARCH)/os2file.c
TTMEMORY = ./ttmemory.c
TTMUTEX = ./ttmutex.c

PORT = $(TTFILE) $(TTMEMORY) $(TTMUTEX)

SRC_X = extend/ftxgasp.c extend/ftxkern.c  extend/ftxpost.c \
        extend/ftxcmap.c extend/ftxwidth.c extend/ftxsbit.c \
        extend/ftxgsub.c extend/ftxgpos.c  extend/ftxopen.c \
        extend/ftxgdef.c
OBJS_X = $(SRC_X:.c=.o)

SRC_M = ttapi.c     ttcache.c   ttcalc.c   ttcmap.c  ttdebug.c \
        ttgload.c   ttinterp.c  ttload.c   ttobjs.c  \
        ttraster.c  ttextend.c  $(PORT)
OBJS_M = $(SRC_M:.c=.o) $(OBJS_X)

SRC_S = $(ARCH)/freetype.c
OBJ_S = $(SRC_S:.c=.o)
OBJS_S = $(OBJ_S) $(OBJS_X)


%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all debug clean distclean depend


all:
	$(FT_MAKE) -f $(FT_MAKEFILE) LIB_FILES=OBJS_S libttf.a

debug:
	$(FT_MAKE) -f $(FT_MAKEFILE) LIB_FILES=OBJS_M libttf.a


$(OBJ_S): $(SRC_S) $(SRC_M)
	$(CC) $(CFLAGS) -c -o $@ $(SRC_S)


libttf.a: $($(LIB_FILES))
	+-del $@
	ar src $@ @$(mktmp $(<:t"\n")\n)

clean:
	-+del $(subst,/,\ $($(LIB_FILES)))

distclean: clean
	-+del dep.end libttf.a

# depend: $(SRC_S) $(SRC_M) $(SRC_X)
#	$(CC) -E -M @$(mktmp $(<:t"\n")\n) > dep.end

# ifeq (dep.end,$(wildcard dep.end))
#   include dep.end
# endif

# end of Makefile.dm
