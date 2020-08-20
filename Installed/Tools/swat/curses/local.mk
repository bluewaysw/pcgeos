##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Curses -- Special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 22, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/22/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: local.mk,v 1.3 92/07/13 21:41:04 adam Exp $
#
###############################################################################

TYPE		= library
CFLAGS		+= -g

sun3OBJS	:= $(sun3OBJS:N*test*.o)
isiOBJS		:= $(isiOBJS:N*test*.o)
sparcOBJS	:= $(sparcOBJS:N*test*.o)

#include    <$(SYSMAKEFILE)>

sparc.md/test	: sparc.md/test.o sparc.md/libcurses.a -ltermcap
	$(CC) $(CFLAGS) -o $(.TARGET) $(.ALLSRC)
sparc.md/test2	: sparc.md/test2.o sparc.md/libcurses.a -ltermcap
	$(CC) $(CFLAGS) -o $(.TARGET) $(.ALLSRC)
sparc.md/test3	: sparc.md/test3.o sparc.md/libcurses.a -ltermcap
	$(CC) $(CFLAGS) -o $(.TARGET) $(.ALLSRC)
