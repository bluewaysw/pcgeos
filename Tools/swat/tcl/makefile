##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tcl -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Adam R de Boor, Thu Apr 18 14:28:02 PDT 1991
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
#
#	$Id: makefile,v 1.2 92/10/07 20:25:22 jimmy Exp $
#
###############################################################################


NAME		= tcl

.SUFFIXES	: .OBJ .ASM .C

MISRCS          = tclBasic.c tcl.h tclCmdAH.c tclInt.h tclCmdIZ.c \
                  tclUtil.c tcl.c tclExpr.c tsh.c tclProc.c

OBJS       	= tclBasic.obj tclCmdAH.obj tclCmdIZ.obj tclUtil.obj \
                  tclExpr.obj tclProc.obj

CC		= hc386
CFLAGS		= -fsoft -g -I..\..\include -I..\..\utils -IT:\phar386\includes -Heol=10
AS		= 386asm
AFLAGS		= 
LINK		= 386link

.c.obj	:
	$(CC) -c $(CFLAGS) $<
.asm.obj:
	$(AS) $(AFLAGS) -o $@ $<

tcl.lib : $(OBJS)
	386lib @tcl.lbc

$(OBJS)		: tcl.h tclInt.h

tsh.exp		: tsh.obj tcl.lib
	$(LINK) @tsh.lnk
