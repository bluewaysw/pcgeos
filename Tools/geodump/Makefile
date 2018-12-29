##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	glue -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Tue Sep 24 18:06:24 PDT 1996
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	all			create the tool for all possible architectures
#	install			create and install for all architectures
#	depend			generate dependencies for all architectures
#	sparc                   create tool for sparc
#	installsparc            create and install tool for sparc
#	dependsparc             generate dependencies for sparc
#	win32                   create tool for win32
#	installwin32            create and install tool for win32
#	dependwin32             generate dependencies for win32
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.tool
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.tool,v 1.5 96/09/05 15:58:56 jacob Exp $
#
###############################################################################


#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= linux win32
MAKEFILE	= Makefile
NAME		= geodump
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = geodump.c geodis.c dumpfont.c disasm.c table.c geos.h geos2.h

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/geodump.o linux.md/geodis.o linux.md/dumpfont.o linux.md/disasm.o linux.md/table.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/geodump.obj win32.md/geodis.obj win32.md/dumpfont.obj win32.md/disasm.obj win32.md/table.obj
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
