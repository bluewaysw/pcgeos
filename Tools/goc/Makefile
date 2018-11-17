##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	goc -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Mathias Winkler, Mon Nov 28 12:14:15 CET 2005
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

MACHINES	=  sparc
MAKEFILE	= Makefile
NAME		= goc
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

MISRCS          = buf.c buf.h cond.c cond.h depends.c depends.h goc.c goc.h\
                  japan.h map.c map.h output.c parse.c parse.h parse.y\
                  scan.c scan.h semantic.c sprite.h stringt.c stringt.h\
                  strwid.c strwid.h symbol.c symbol.h

sparcSRCS       = $(MISRCS) sparc.md/
sparcOBJS       = sparc.md/buf.o sparc.md/cond.o sparc.md/depends.o\
                  sparc.md/goc.o sparc.md/map.o sparc.md/output.o\
                  sparc.md/parse.o sparc.md/scan.o sparc.md/semantic.o\
                  sparc.md/stringt.o sparc.md/strwid.o sparc.md/symbol.o
sparcLIBS       =


SUBDIRS         = dos linux

#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(sparc.md/dependencies.mk)
#include	"sparc.md/dependencies.mk"
#endif


# Allow mkmf
