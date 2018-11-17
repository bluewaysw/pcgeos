##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Customs -- special definitions
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
#	Special definitions for customs
#
#	$Id: local.mk,v 1.1 91/06/09 15:11:59 adam Exp Locker: adam $
#
###############################################################################
#
# Search for .h files in the source directories only.
#
.PATH.h		: ../src/lib/lst ../src/lib/include ../src/customs \
		  $(INSTALL_DIR:H)/src/lib/lst \
		  $(INSTALL_DIR:H)/src/lib/include \
		  $(INSTALL_DIR:H)/src/customs
#
# Find the libraries in the machine-dependent directories, though.
#
.PATH.a		: ../lib/lst \
		  $(INSTALL_DIR:H)/lib/lst

#
# Perform extra optimizations
#
CFLAGS		+= -fstrength-reduce -finline-functions -fcombine-regs \
                   -DLOG_BASE=\"/staff/pcgeos/Tools/pmake/customs/log/log\" \
                   -DINSECURE -DNO_IDLE

#
# Install this thing in /usr/etc, as it's a system daemon
#
DEST		= `set - $(.ALLSRC:H:S/.md//); echo /usr/etc.$1`

#
# Define the libraries we use
#
LIBS		= -llst -lkvm

#include	<$(SYSMAKEFILE)>

.SUFFIXES: .i
.c.i:; $(CC) $(CFLAGS) -E $(.IMPSRC)
.c.s:; $(CC) $(CFLAGS) -S $(.IMPSRC)
sparc.md/os-sunos4.s:sparc.md/os-sunos4.c
sparc.md/os-sunos4.i:sparc.md/os-sunos4.c
