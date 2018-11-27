##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	UIC -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 19, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/19/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for UIC
#
#	$Id: local.mk,v 1.6 96/06/18 20:25:21 jacob Exp $
#
###############################################################################

CFLAGS		= -DYYDEBUG=1 -DLEXDEBUG=1 -DUIC=1
#CFLAGS		+= -DMEM_TRACE
YFLAGS		= -dv

#if defined(unix)
LIBS		= $(.TARGET:H)/libutils.a
.PATH.a		: ../utils $(INSTALL_DIR:H)/utils
#else
.SUFFIXES	: .lib .a
linuxLIBS		= $(.TARGET:H)/libutils.a $(.TARGET:H)/libcompat.a
.PATH.a		: ../utils $(INSTALL_DIR:H)/utils \
		  ../compat $(INSTALL_DIR:H)/compat
win32LIBS		= $(.TARGET:H)/utils.lib $(.TARGET:H)/compat.lib
.PATH.lib	: ../utils $(INSTALL_DIR:H)/utils \
		  ../compat $(INSTALL_DIR:H)/compat
#endif

.PATH.h		:
.PATH.h		: . $(INSTALL_DIR) \
		  ../utils $(INSTALL_DIR:H)/utils

#include    <$(SYSMAKEFILE)>

#
# Special rule to make sure parse.h exists before people try to include it
#
parse.h		: parse.c




