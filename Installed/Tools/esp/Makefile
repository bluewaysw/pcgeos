##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	esp -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Wed Sep 25 20:03:00 PDT 1996
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
NAME		= esp
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = assert.c assert.h class.h code.c code.h cond.h data.c\
                  data.h dword.h esp.h expr.c expr.h fixup.c fixup.h\
                  flopcode.h flopcodes.h keywords.h lmem.c main.c model.h\
                  object.c object.h opcodes.h parse.c parse.h parse.y\
                  printobj.c scan.c scan.h segment.h symbol.c symbol.h\
                  table.c table.h type.c type.h

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/assert.o linux.md/code.o linux.md/data.o\
                  linux.md/expr.o linux.md/fixup.o linux.md/lmem.o\
                  linux.md/main.o linux.md/object.o linux.md/parse.o\
                  linux.md/printobj.o linux.md/scan.o linux.md/symbol.o\
                  linux.md/table.o linux.md/type.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/assert.obj win32.md/code.obj win32.md/data.obj\
                  win32.md/expr.obj win32.md/fixup.obj win32.md/lmem.obj\
                  win32.md/main.obj win32.md/object.obj win32.md/parse.obj\
                  win32.md/printobj.obj win32.md/scan.obj\
                  win32.md/symbol.obj win32.md/table.obj win32.md/type.obj
win32LIBS       =


SUBDIRS         = test

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
