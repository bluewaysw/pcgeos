##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	termcap -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Adam de Boor, Thu Jan 20 20:45:46 PST 1994
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
#	$Id: Makefile.tool,v 1.4 92/01/03 20:18:13 johnm Exp $
#
###############################################################################


#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= linux
MAKEFILE	= Makefile
NAME		= termcap
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	!defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= linux
#endif

MISRCS          = termcap.c tparam.c version.c

linuxSRCS	= $(MISRCS) linux.md/
linuxOBJS      	= termcap.o \
		  tparam.o \
		  version.o

linuxLIBS       =


#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(linux.md/dependencies.mk)
#include	"linux.md/dependencies.mk"
#endif


# Allow mkmf
