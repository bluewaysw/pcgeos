##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	grev -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Wed Sep 18 16:43:55 PDT 1996
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	all			create the tool for all possible architectures
#	install			create and install for all architectures
#	depend			generate dependencies for all architectures
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

MACHINES	=  win32
MAKEFILE	= Makefile
NAME		= grev
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

MISRCS          = grev.c

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/grev.obj
win32LIBS       =


SUBDIRS         = CVS

#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif


# Allow mkmf
