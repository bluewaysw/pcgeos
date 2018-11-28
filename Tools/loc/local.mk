##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	goc -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Josh   11/92
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	josh	11/92		Initial
#
# DESCRIPTION:
#	Special definitions for goc
#
#	$Id: local.mk,v 1.1 92/11/19 19:13:57 josh Exp Locker: don $
#
###############################################################################

CFLAGS		= -DYYDEBUG=1 -DLEXDEBUG=1 
#CFLAGS		+= -DMEM_TRACE
#if defined(unix)
LIBS		= $(.TARGET:H)/libutils.a
.PATH.a		: ../utils $(INSTALL_DIR:H)/utils
#else
win32LIBS            = $(.TARGET:H)/utils.lib $(.TARGET:H)/compat.lib
linuxLIBS            = $(.TARGET:H)/libutils.a $(.TARGET:H)/libcompat.a
.SUFFIXES       : .lib .a
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat \
		  ../utils $(INSTALL_DIR:H)/utils
.PATH.a		: ../compat $(INSTALL_DIR:H)/compat \
		  ../utils $(INSTALL_DIR:H)/utils
#endif
YFLAGS		= -dv

#  enable this for gprof.
#
#LIBS		= $(.TARGET:H)/libutils_p.a

.PATH.h		: #clear this out for now
.PATH.h		: . $(INSTALL_DIR) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils

#include    <$(SYSMAKEFILE)>

#
# Special rule to make sure parse.h exists before people try to include it
#
parse.h		: parse.c
