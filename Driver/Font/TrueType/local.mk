##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	TrueType Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson
#
# DESCRIPTION:
#	Special definitions required for the TrueType font driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:45:28 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i

_PROTO = 3.0

.PATH.asm .PATH.def: ../FontCom $(INSTALL_DIR:H)/FontCom \

#include	<$(SYSMAKEFILE)>
