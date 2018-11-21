##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	nmkmf -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Tue Feb 25 21:23:17 PST 1997
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

MACHINES	=  sparc win32
MAKEFILE	= Makefile
NAME		= nmkmf
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(sun) && defined(sparc)
DEFTARGET	= sparc
#elif	defined(sun)
DEFTARGET	= sun3
#elif   defined(isi)
DEFTARGET	= isi
#else
DEFTARGET	= win32
#endif

MISRCS          = mkmf.c

sparcSRCS       = $(MISRCS) sparc.md/
sparcOBJS       = sparc.md/mkmf.o
sparcLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/mkmf.obj
win32LIBS       =


SUBDIRS         = CVS

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
