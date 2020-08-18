##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	esp -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Adam R de Boor, Thu Nov 30 18:29:48 PST 1989
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
#	sun3                    create tool for sun3
#	installsun3             create and install tool for sun3
#	dependsun3              generate dependencies for sun3
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.tool
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: makefile,v 1.7 95/01/24 17:06:42 jimmy Exp $
#
###############################################################################

#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= win32
MAKEFILE	= Makefile
NAME		= swat
SYSMAKEFILE	= tool.mk
TYPE		= tool

#if	defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= win32
#endif


MISRCS          = serial.asm assert.h break.c break.h buf.c buf.h cache.c \
                  cache.h cmd.c cmd.h cmdAM.c cmdNZ.c curses.c event.c event.h\
                  expr.c expr.h expr.y file.c file.h gc.c geos.h handle.c\
                  handle.h help.c i86Opc.c i86Opc.h ibm.c\
                  ibm.h ibm86.c ibmCache.c ibmCmd.c ibmInt.h makedoc.c\
                  patient.c private.h rpc.c rpc.h setjmp.h shell.c sprite.h\
                  src.c swat.c swat.h sym.c sym.h syn.c table.c table.h\
                  tclDebug.c tclDebug.h tokens.h type.c type.h ui.c ui.h\
                  value.c value.h var.c var.h vector.c vector.h version.c\
                  vmsym.h mouse.c netware.c ibmXms.c

linuxSRCS       = $(MISRCS)

linuxOBJS       = serial.o break.o buf.o cache.o\
                  cmd.o cmdAM.o cmdNZ.o\
                  curses.o event.o expr.o\
                  file.o gc.o handle.o\
                  help.o i86Opc.o\
                  ibm.o ibm86.o ibmCache.o\
                  ibmCmd.o patient.o\
                  rpc.o shell.o src.o \
                  swat.o sym.o \
                  table.o tclDebug.o type.o\
                  ui.o value.o var.o \
                  vector.o version.o mouse.o netware.o

linuxLIBS		    = curses\curses.lib tcl\tcl.lib lst\lst.lib ..\utils\utils.lib

win32SRCS       = $(MISRCS) win32.md/npipe.c win32.md/ntserial.c

win32OBJS       = break.obj buf.obj cache.obj\
                  cmd.obj cmdAM.obj cmdNZ.obj\
                  curses.obj event.obj expr.obj\
                  file.obj gc.obj handle.obj\
                  help.obj i86Opc.obj\
                  ibm.obj ibm86.obj ibmCache.obj\
                  ibmCmd.obj patient.obj\
                  rpc.obj shell.obj src.obj\
                  swat.obj sym.obj \
                  table.obj tclDebug.obj type.obj\
                  ui.obj value.obj var.obj\
                  vector.obj version.obj mouse.obj netware.obj npipe.obj \
                  ntserial.obj ibmXms.obj

win32LIBS       = ntcurses\win32.md\ntcurses.lib tcl\win32.md\tcl.lib \
                  ..\..\..\Tools\pmake\lib\lst\lst.lib \
                  ..\utils\win32.md\utils.lib \
                  ..\winutil\win32.md\winutil.lib \
                  ..\compat\win32.md\compat.lib


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
