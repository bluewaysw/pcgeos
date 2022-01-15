# This file is part of the FreeType project.
#
# DESCRIP.MMS: Make file for VMS using MMS or MMK
# Created by Jouk Jansen (joukj@hrem.stm.tudelft.nl)

ARCH = arch.unix

CC = cc

############### PORTABILITY COMPONENTS ########################

# location of memory component
MEMSRC = ttmemory.c

# location of file component
FILESRC = ttfile.c

# location of mutex component
MUTEXSRC = ttmutex.c

# location of default extensions
FTEXTDIR = [.lib.extend]

# default extensions sources
EXTSRC = $(FTEXTDIR)ftxkern.c  \
         $(FTEXTDIR)ftxgasp.c  \
         $(FTEXTDIR)ftxpost.c  \
         $(FTEXTDIR)ftxcmap.c  \
         $(FTEXTDIR)ftxsbit.c  \
         $(FTEXTDIR)ftxwidth.c \
         $(FTEXTDIR)ftxerr18.c \
         $(FTEXTDIR)ftxgsub.c  \
         $(FTEXTDIR)ftxgpos.c  \
         $(FTEXTDIR)ftxopen.c  \
         $(FTEXTDIR)ftxgdef.c

EXTOBJ = [.lib]ftxkern.obj,  \
         [.lib]ftxgasp.obj,  \
         [.lib]ftxpost.obj,  \
         [.lib]ftxcmap.obj,  \
         [.lib]ftxsbit.obj,  \
         [.lib]ftxwidth.obj, \
         [.lib]ftxerr18.obj, \
         [.lib]ftxgsub.obj,  \
         [.lib]ftxgpos.obj,  \
         [.lib]ftxopen.obj,  \
         [.lib]ftxgdef.obj

# all engine sources
SRC_M = [.lib]ttapi.c     \
        [.lib]ttcache.c   \
        [.lib]ttcalc.c    \
        [.lib]ttcmap.c    \
        [.lib]ttdebug.c   \
        [.lib]ttextend.c  \
        [.lib]ttgload.c   \
        [.lib]ttinterp.c  \
        [.lib]ttload.c    \
        [.lib]ttobjs.c    \
        [.lib]ttraster.c  \
        [.lib]$(FILESRC)  \
        [.lib]$(MEMSRC)   \
        [.lib]$(MUTEXSRC)
SRC_S = [.lib.$(ARCH)]freetype.c

# all header files with path
HEADERS = [.lib]freetype.h      \
          [.lib]fterrid.h       \
          [.lib]ftnameid.h      \
          $(FTEXTDIR)ftxkern.h  \
          $(FTEXTDIR)ftxgasp.h  \
          $(FTEXTDIR)ftxcmap.h  \
          $(FTEXTDIR)ftxsbit.h  \
          $(FTEXTDIR)ftxpost.h  \
          $(FTEXTDIR)ftxwidth.h \
          $(FTEXTDIR)ftxerr18.h \
          $(FTEXTDIR)ftxgsub.h  \
          $(FTEXTDIR)ftxgpos.h  \
          $(FTEXTDIR)ftxgdef.h  \
          $(FTEXTDIR)ftxopen.h

# all engine objects
OBJ_M = [.lib]ttapi.obj,    \
        [.lib]ttcache.obj,  \
        [.lib]ttcalc.obj,   \
        [.lib]ttcmap.obj,   \
        [.lib]ttdebug.obj,  \
        [.lib]ttextend.obj, \
        [.lib]ttgload.obj,  \
        [.lib]ttinterp.obj, \
        [.lib]ttload.obj,   \
        [.lib]ttobjs.obj,   \
        [.lib]ttraster.obj, \
        [.lib]file.obj,     \
        [.lib]memory.obj,   \
        [.lib]mutex.obj,    \
        $(EXTOBJ)
OBJ_S = [.lib]freetype.obj


# include paths
INCLUDES = /include=([.lib],[],$(FTEXTDIR))

# C flags
CFLAGS = $(INCLUDES)/obj=[.lib]

all : do_link [.lib]libttf.olb
	library/compress [.lib]libttf.olb

do_link :
	if f$search( "[.lib]memory.c" ) .nes. "" then set file/remove [.lib]memory.c;
	if f$search( "[.lib]file.c" ) .nes. "" then set file/remove [.lib]file.c;
	if f$search( "[.lib]mutex.c" ) .nes. "" then set file/remove [.lib]mutex.c;
	if f$search( "[.lib]ft_conf.h" ) .nes. "" then set file/remove [.lib]ft_conf.h;
	set file/enter=[.lib]memory.c [.lib]$(MEMSRC)
	set file/enter=[.lib]file.c [.lib]$(FILESRC)
	set file/enter=[.lib]mutex.c [.lib]$(MUTEXSRC)
	set file/enter=[.lib]ft_conf.h [.lib.arch.vms]ft_conf.h

[.lib]ftxkern.obj : $(FTEXTDIR)ftxkern.c

[.lib]ftxgasp.obj : $(FTEXTDIR)ftxgasp.c

[.lib]ftxpost.obj : $(FTEXTDIR)ftxpost.c

[.lib]ftxcmap.obj : $(FTEXTDIR)ftxcmap.c

[.lib]ftxsbit.obj : $(FTEXTDIR)ftxsbit.c

[.lib]ftxwidth.obj : $(FTEXTDIR)ftxwidth.c

[.lib]ftxerr18.obj : $(FTEXTDIR)ftxerr18.c

[.lib]ftxgsub.obj : $(FTEXTDIR)ftxgsub.c

[.lib]ftxgpos.obj : $(FTEXTDIR)ftxgpos.c

[.lib]ftxgdef.obj : $(FTEXTDIR)ftxgdef.c

[.lib]ftxopen.obj : $(FTEXTDIR)ftxopen.c

[.lib]freetype.obj : $(SRC_S) $(SRC_M)


[.lib]libttf.olb : $(OBJ_M)
	library/create [.lib]libttf.olb $(OBJ_M)


clean :
	delete [.lib]*.obj;*
	delete [.lib]*.olb;*
	if f$search( "[.lib]memory.c" ) .nes. "" then set file/remove [.lib]memory.c;
	if f$search( "[.lib]file.c" ) .nes. "" then set file/remove [.lib]file.c;
	if f$search( "[.lib]mutex.c" ) .nes. "" then set file/remove [.lib]mutex.c;
	if f$search( "[.lib]ft_conf.h" ) .nes. "" then set file/remove [.lib]ft_conf.h;
