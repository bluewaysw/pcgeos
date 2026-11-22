##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	gfs -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Tony Requist, May 2, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	5/2/91		Initial Revision
#
# DESCRIPTION:
#	Special definitions for gfs
#
#	$Id: local.mk,v 1.2 97/04/28 16:34:17 clee Exp $
#
###############################################################################

#if !defined(unix)
.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/compat.lib
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat
#endif

.PATH.h		:  #clear for now
.PATH.h		: . $(INSTALL_DIR)

#include    <$(SYSMAKEFILE)>
