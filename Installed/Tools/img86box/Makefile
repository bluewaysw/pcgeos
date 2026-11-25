##############################################################################
#
# PROJECT:	PC GEOS host tools
# MODULE:	img86box -- bootable FreeDOS + GEOS disk image for 86Box
# FILE: 	Makefile
#
# DESCRIPTION:
#	Builds img86box, installed to $(ROOT_DIR)/bin. Sources live in
#	Tools/img86box; the FAT code comes from the fatfs library.
#
###############################################################################

#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= win32 linux
MAKEFILE	= Makefile
NAME		= img86box
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = img86box.c hostdir.c

#
# Headers of the fatfs library (ff.h, fatimg.h). Added as a search path
# rather than as a compiler flag so tool.mk converts the slashes for
# Watcom on Windows, where "/" starts an option.
#
.PATH.h		: $(INSTALL_DIR:H)/fatfs

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/img86box.obj win32.md/hostdir.obj
win32LIBS       = ../fatfs/win32.md/fatfs.lib

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/img86box.o linux.md/hostdir.o
linuxLIBS       = ../fatfs/linux.md/libfatfs.a

SUBDIRS         =

#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif

#if	exists(linux.md/dependencies.mk)
#include	"linux.md/dependencies.mk"
#endif
