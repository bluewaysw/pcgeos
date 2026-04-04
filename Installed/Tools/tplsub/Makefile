##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tplsub -- Makefile
# FILE: 	Makefile
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	all			create the tool for all possible architectures
#	install			create and install for all architectures
#	depend			generate dependencies for all architectures
#	linux			create tool for linux
#	installlinux		create and install tool for linux
#	dependlinux		generate dependencies for linux
#	win32			create tool for win32
#	installwin32		create and install tool for win32
#	dependwin32		generate dependencies for win32
#
# DESCRIPTION:
#	This makefile was generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.tool
#
###############################################################################

#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= linux win32
MAKEFILE	= Makefile
NAME		= tplsub
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = tplsub.c

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/tplsub.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/tplsub.obj
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

# Allow mkmf
