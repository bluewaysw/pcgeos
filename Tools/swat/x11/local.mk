##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jul 18, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/18/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for x11 interface library
#
#	$Id: local.mk,v 1.1 89/07/21 04:03:01 adam Exp $
#
###############################################################################
PMAKE		= $(ROOT_DIR)/Tools/pmake
.PATH.h		: .. $(INSTALL_DIR:H) \
                  ../tcl $(INSTALL_DIR:H)/tcl \
                  $(PMAKE)/src/lib/lst \
                  /usr/include.sun3/X11
TYPE		= library
CFLAGS		+= -DISSWAT

#include	<$(SYSMAKEFILE)>
