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

MACHINES	=  sparc win32
MAKEFILE	= Makefile
NAME		= glue
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

MISRCS          = borland.c borland.h codeview.c codeview.h com.c cv.h\
                  exe.c font.c geo.c geo.h glue.h kernel.c library.c\
                  library.h main.c msl.c msobj.c msobj.h obj.c obj.h\
                  output.c output.h parse.c parse.h parse.y pass1ms.c\
                  pass1vm.c pass2ms.c pass2vm.c segattrs.h segment.c sym.c\
                  sym.h tokens.h vector.c vector.h vm.c codeview32.c\
									codeview32.h

sparcSRCS       = $(MISRCS) sparc.md/
sparcOBJS       = sparc.md/borland.o sparc.md/codeview.o sparc.md/com.o\
                  sparc.md/exe.o sparc.md/font.o sparc.md/geo.o\
                  sparc.md/kernel.o sparc.md/library.o sparc.md/main.o\
                  sparc.md/msl.o sparc.md/msobj.o sparc.md/obj.o\
                  sparc.md/output.o sparc.md/parse.o sparc.md/pass1ms.o\
                  sparc.md/pass1vm.o sparc.md/pass2ms.o sparc.md/pass2vm.o\
                  sparc.md/segment.o sparc.md/sym.o sparc.md/vector.o\
                  sparc.md/vm.o sparc.md/codeview32.o
sparcLIBS       =

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


SUBDIRS         = CVS dos win

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
