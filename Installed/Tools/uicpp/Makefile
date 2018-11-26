##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	uicpp -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Thu Nov 21 22:27:46 PST 1996
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
NAME		= uicpp
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = cccp.c cexp.c cexp.y obstack.c obstack.h tm-i386.h\
                  version.c

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/cccp.o linux.md/cexp.o linux.md/obstack.o\
                  linux.md/version.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/cccp.obj win32.md/cexp.obj win32.md/obstack.obj\
                  win32.md/version.obj
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
