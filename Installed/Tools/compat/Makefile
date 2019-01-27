##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	compat -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Mathias, Thu Nov 17 14:21:36 CET 2005
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
NAME		= compat
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = bcmp.c bcopy.c bzero.c compat.c dirent.c ffs.c getopt.c\
                  mkstemp.c pagesize.c queue.c

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/bcmp.o linux.md/bcopy.o linux.md/bzero.o\
                  linux.md/compat.o linux.md/dirent.o linux.md/ffs.o\
                  linux.md/getopt.o linux.md/mkstemp.o linux.md/pagesize.o\
                  linux.md/queue.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/bcmp.obj win32.md/bcopy.obj win32.md/bzero.obj\
                  win32.md/compat.obj win32.md/dirent.obj win32.md/ffs.obj\
                  win32.md/getopt.obj win32.md/mkstemp.obj win32.md/pagesize.obj\
                  win32.md/queue.obj
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
