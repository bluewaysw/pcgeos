##############################################################################
#
# PROJECT:	PC GEOS host tools
# MODULE:	fatfs -- FAT file system library (FatFs by ChaN)
# FILE: 	Makefile
#
# DESCRIPTION:
#	Builds the FatFs library used by host tools that read or write
#	FAT disk images (img86box). Sources live in Tools/fatfs.
#
###############################################################################

#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= linux win32
MAKEFILE	= Makefile
NAME		= fatfs
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = ff.c fatimg.c

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/ff.o linux.md/fatimg.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/ff.obj win32.md/fatimg.obj
win32LIBS       =

SUBDIRS         =

#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(linux.md/dependencies.mk)
#include	"linux.md/dependencies.mk"
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif
