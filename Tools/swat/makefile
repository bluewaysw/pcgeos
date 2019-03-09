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

MACHINES	= sparc win32
MAKEFILE	= Makefile
NAME		= swat
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


.SUFFIXES	: .OBJ .C .ASM .exe .exp .obj

MISRCS          = serial.asm assert.h break.c break.h buf.c buf.h cache.c \
                  cache.h cmd.c cmd.h cmdAM.c cmdNZ.c curses.c event.c event.h\
                  expr.c expr.h expr.y file.c file.h gc.c geos.h handle.c\
                  handle.h help.c i86Opc.c i86Opc.h ibm.c\
                  ibm.h ibm86.c ibmCache.c ibmCmd.c ibmInt.h makedoc.c\
                  patient.c private.h rpc.c rpc.h setjmp.h shell.c sprite.h\
                  src.c swat.c swat.h sym.c sym.h syn.c table.c table.h\
                  tclDebug.c tclDebug.h tokens.h type.c type.h ui.c ui.h\
                  value.c value.h var.c var.h vector.c vector.h version.c\
                  vmsym.h mouse.c netware.c

OBJS       	= serial.obj break.obj buf.obj cache.obj\
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
                  vector.obj version.obj mouse.obj netware.obj
LIBS		= curses\curses.lib tcl\tcl.lib lst\lst.lib ..\utils\utils.lib
CC		= hc386
CFLAGS		= -g -fsoft -DMEM_TRACE -DISSWAT -I..\include -I..\utils -Itcl \
                  -Icurses -Ilst -IT:\phar386\includes -Heol=10
LINK		= 386link
AS		= 386asm
AFLAGS		= -twocase -INCLUDE T:\phar386\includes\ # trailing space reqd

PHARSDK_DIR	= T:\PHARSDK\BIN

.c.obj		:
	$(CC) -c $(CFLAGS) $<

.asm.obj:
	$(AS) $(AFLAGS) -o $@ $<

.exp.exe:
	$(PHARSDK_DIR)\bind386 $(PHARSDK_DIR)\RUN386B $(.IMPSRC)
	$(PHARSDK_DIR)\cfig386 swat.exe -maxv 0

swat.exe	: swat.exp
swat.exp 	: $(OBJS) $(LIBS)
	$(LINK) @swat.lnk
$(OBJS)		: swat.h
