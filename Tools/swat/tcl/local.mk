##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	TCL -- Special definitions
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
#	$Id: local.mk,v 1.6 97/04/18 12:12:54 dbaumann Exp $
#
###############################################################################

TYPE		= library
#if defined(unix)
CFLAGS		+= -g
#endif

.PATH.h		:
.PATH.h		: ../../include ../../utils $(INSTALL_DIR:H:H)/utils .

sun3OBJS	:= $(sun3OBJS:N*tsh.o:N*tcl.o)
isiOBJS		:= $(isiOBJS:N*tsh.o:N*tcl.o)
sparcOBJS	:= $(sparcOBJS:N*tsh.o:N*tcl.o)
win32OBJS       := $(win32OBJS:N*tsh.obj:N*tcl.obj)

#include    <$(SYSMAKEFILE)>

sparc.md/tsh	: sparc.md/tsh.o sparc.md/libtcl.a -lm
	$(CC) $(CFLAGS) -o $(.TARGET) $(.ALLSRC)

sparc.md/tsh_p	: sparc.md/tsh.po sparc.md/libtcl_p.a -lm_p
	$(CC) $(CFLAGS) -pg -o $(.TARGET) $(.ALLSRC)
