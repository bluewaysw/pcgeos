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

MACHINES	=  sparc win32
MAKEFILE	= Makefile
NAME		= compat
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	defined(sun) && defined(sparc)
DEFTARGET	= sparc
#elif	defined(sun)
DEFTARGET	= sun3
#elif   defined(isi)
DEFTARGET	= isi
#else
DEFTARGET	= win32
#endif

MISRCS          = bcmp.c bcopy.c bzero.c compat.c dirent.c ffs.c getopt.c\
                  mkstemp.c pagesize.c queue.c

sparcSRCS       = $(MISRCS) sparc.md/
sparcOBJS       = sparc.md/bcmp.o sparc.md/bcopy.o sparc.md/bzero.o\
                  sparc.md/compat.o sparc.md/dirent.o sparc.md/ffs.o\
                  sparc.md/getopt.o sparc.md/mkstemp.o sparc.md/pagesize.o\
                  sparc.md/queue.o
sparcLIBS       =

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

#if	exists(sparc.md/dependencies.mk)
#include	"sparc.md/dependencies.mk"
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif

# Allow mkmf
