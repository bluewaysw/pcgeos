##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Glue -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, October 22, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/22/89	Initial Revision
#
# DESCRIPTION:
#	Special definitions for Glue
#
#	$Id: local.mk,v 2.4 94/10/12 18:20:09 adam Exp $
#
###############################################################################

CFLAGS		= -DYYDEBUG=1 -DLEXDEBUG=1
YFLAGS		= -vt

#if defined(unix)
CFLAGS		+= -fstrength-reduce -fcombine-regs \
		   -finline-functions -W -Wreturn-type -Wunused
LIBS		= $(.TARGET:H)/libutils.a
.PATH.a		: ../utils $(INSTALL_DIR:H)/utils
#else
LIBS		= $(.TARGET:H)/utils.lib  $(.TARGET:H)/compat.lib
.SUFFIXES	: .lib
.PATH.lib	: ../utils $(INSTALL_DIR:H)/utils \
		  ../compat $(INSTALL_DIR:H)/compat
#endif

.PATH.h		: # clear this out for now
.PATH.h		: . $(INSTALL_DIR) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils
.PATH.goh	:
.PATH.goh	: . $(INSTALL_DIR) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils

#XLINKFLAGS = -link -DEFAULTLIB:kernel32.lib
#include    <$(SYSMAKEFILE)>

TABLES		= tokens.h segattrs.h
$(MACHINES:S|$|.md/parse.o|g): $(TABLES)

#
# Initial values arrived at empirically -- best values < $(MAX)
#
GPFLAGS		= -agSDptlC

.SUFFIXES	: .gperf
.PATH.gperf	: $(INSTALL_DIR)

MAX		= 20
# -i1 gives 58
tokens.h	: tokens.gperf
	$(GPERF) -i1 -o -j1 $(GPFLAGS) -k1-3 $(.ALLSRC) > $@
tokens.opt	::
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k1-3 tokens.gperf

# -i16 gives 14
segattrs.h	: segattrs.gperf
	$(GPERF) -i16 -o -j1 $(GPFLAGS) -N findSegAttr -H hashSegAttr $(.ALLSRC) > $@
segattrs.opt	::
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) segattrs.gperf


allopt		: $(TABLES:S/.h$/.opt/g)

#if defined(unix)
CFLAGS		:= $(CFLAGS:N-finline-functions)
#else
CFLAGS_COMMON  = -d2 -w3 -zp=1
#endif

.SUFFIXES	: .i

.c.i		:; $(CC) $(CFLAGS) -E $(.IMPSRC)
.c.s		:; $(CC) $(CFLAGS) -S $(.IMPSRC)
