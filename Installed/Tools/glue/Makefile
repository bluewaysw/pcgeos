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
NAME		= glue
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif

MISRCS          = borland.c borland.h codeview.c codeview.h com.c cv.h\
                  exe.c font.c geo.c geo.h glue.h kernel.c library.c\
                  library.h main.c msl.c msobj.c msobj.h obj.c obj.h\
                  output.c output.h parse.c parse.h parse.y pass1ms.c\
                  pass1vm.c pass2ms.c pass2vm.c segattrs.h segment.c sym.c\
                  sym.h tokens.h vector.c vector.h vm.c codeview32.c\
                  codeview32.h

linuxSRCS       = $(MISRCS) linux.md/
linuxOBJS       = linux.md/borland.o linux.md/codeview.o linux.md/com.o\
                  linux.md/exe.o linux.md/font.o linux.md/geo.o\
                  linux.md/kernel.o linux.md/library.o linux.md/main.o\
                  linux.md/msl.o linux.md/msobj.o linux.md/obj.o\
                  linux.md/output.o linux.md/parse.o linux.md/pass1ms.o\
                  linux.md/pass1vm.o linux.md/pass2ms.o linux.md/pass2vm.o\
                  linux.md/segment.o linux.md/sym.o linux.md/vector.o\
                  linux.md/vm.o linux.md/codeview32.o
linuxLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/borland.obj win32.md/codeview.obj\
                  win32.md/com.obj win32.md/exe.obj win32.md/font.obj\
                  win32.md/geo.obj win32.md/kernel.obj win32.md/library.obj\
                  win32.md/main.obj win32.md/msl.obj win32.md/msobj.obj\
                  win32.md/obj.obj win32.md/output.obj win32.md/parse.obj\
                  win32.md/pass1ms.obj win32.md/pass1vm.obj\
                  win32.md/pass2ms.obj win32.md/pass2vm.obj\
                  win32.md/segment.obj win32.md/sym.obj win32.md/vector.obj\
                  win32.md/vm.obj win32.md/codeview32.obj
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
