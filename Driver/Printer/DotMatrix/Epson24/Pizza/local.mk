##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson 24-pin Printer Driver for Pizza
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, 26 Feb 1990
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	2/26/90		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Printer Driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:53:22 newdeal Exp $
#
###############################################################################

GEODE		= epson24

#
# to allow i/o instructions, and interrupt disabling
#
ASMFLAGS	+= -i

.PATH.asm .PATH.def: . .. ../../../PrintCom $(INSTALL_DIR:H:H:H)/PrintCom \
		$(INSTALL_DIR:H)
#
#
#
.PATH.uih .PATH.ui: UI ../../../PrintCom $(INSTALL_DIR:H:H:H)/PrintCom
UICFLAGS        += -IUI -I../../../PrintCom -I$(INSTALL_DIR:H:H:H)/PrintCom

#
# set include file path
#
-IFLAGS		= -I$(.TARGET:R) -I$(INSTALL_DIR)/$(.TARGET:R) \
		  -I. -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \
		  -I../../PrintCom -I$(INSTALL_DIR:H:H:H)/PrintCom \
		  -I.. -I$(INSTALL_DIR:H)/..  \
		  -I$(INSTALL_DIR) \

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
PROTOCONST	= PRINT

#include	<pizza.mk>

#include	<$(SYSMAKEFILE)>
