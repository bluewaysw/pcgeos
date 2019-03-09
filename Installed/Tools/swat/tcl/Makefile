##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tcl -- Makefile
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

MACHINES	= linux win32
MAKEFILE	= Makefile
NAME		= tcl
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = tcl.c tcl.h tclBasic.c tclBC.c tclCmdAH.c\
                  tclCmdIZ.c tclExpr.c tclInt.h tclProc.c tclUtil.c tsh.c

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/tcl.o linux.md/tclBasic.o linux.md/tclBC.o\
                  linux.md/tclCmdAH.o linux.md/tclCmdIZ.o\
                  linux.md/tclExpr.o linux.md/tclProc.o linux.md/tclUtil.o\
                  linux.md/tsh.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/tcl.obj win32.md/tclBasic.obj\
 		  win32.md/tclBC.obj\
                  win32.md/tclCmdAH.obj win32.md/tclCmdIZ.obj\
                  win32.md/tclExpr.obj win32.md/tclProc.obj\
		  win32.md/tclUtil.obj win32.md/tsh.obj
win32LIBS       =


SUBDIRS         = New

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
