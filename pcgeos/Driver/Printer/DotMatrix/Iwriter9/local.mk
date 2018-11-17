##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ImageWriter 9-pin Printer Driver
# FILE: 	local.mk
# AUTHOR: 	Dave Durran
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dave	2/26/90		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Printer Driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:53:40 newdeal Exp $
#
###############################################################################

#
# to allow i/o instructions, and interrupt disabling
#
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../PrintCom $(INSTALL_DIR:H)/../PrintCom \
		.. $(INSTALL_DIR:H) ../Citoh9 $(INSTALL_DIR:H)/Citoh9

#
# set include file path
#
-IFLAGS		= -I$(.TARGET:R) -I$(INSTALL_DIR)/$(.TARGET:R) \
		  -I. -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \
		  -I../../PrintCom -I$(INSTALL_DIR:H)/../PrintCom \
		  -I../Citoh9 -I$(INSTALL_DIR:H)/Citoh9 \
		  -I.. -I$(INSTALL_DIR:H)/..  \
		  -I$(INSTALL_DIR) \

#include	<$(SYSMAKEFILE)>
