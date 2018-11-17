##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
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
#	Special definitions for Sprite compatibility library
#
#	$Id: local.mk,v 1.1 96/07/15 17:10:30 jacob Exp $
#
###############################################################################
#
# Look in source include directory for Sprite headers, not here
#
.PATH.h         : ../../src/lib/include $(INSTALL_DIR:H:H)/src/lib/include \
		  ..\lst

#
# We're a library, so make libsprite.a, not sprite
#
TYPE		= library
CFLAGS		+= -X

#
# Include appropriate system makefile
#
#include    <$(SYSMAKEFILE)>
