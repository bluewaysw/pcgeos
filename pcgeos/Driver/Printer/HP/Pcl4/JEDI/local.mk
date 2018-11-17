##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PCL level 4 driver for Zoomer
# FILE: 	local.mk
# AUTHOR: 	Dave Durran
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dave	4/28/93		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Printer Driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:52:17 newdeal Exp $
#
###############################################################################

GEODE		= pcl4j

#
# to allow i/o instructions, and interrupt disabling
#
ASMFLAGS	+= -i

.PATH.asm .PATH.def: .. $(INSTALL_DIR:H) \
		../../../PrintCom $(INSTALL_DIR:H:H:H)/PrintCom

#
#
#
.PATH.uih .PATH.ui: UI .. $(INSTALL_DIR:H) \
		../../../PrintCom $(INSTALL_DIR:H:H:H)/PrintCom
UICFLAGS        += -DZOOMER -IUI -I.. -I$(INSTALL_DIR:H) \
		-I../../../PrintCom -I$(INSTALL_DIR:H:H:H)/PrintCom

#
# set include file path
#
-IFLAGS		= -I$(.TARGET:R) -I$(INSTALL_DIR)/$(.TARGET:R) \
		  -I$(INSTALL_DIR) \
		  -I.. -I$(INSTALL_DIR:H) \
		  -I../../../PrintCom -I$(INSTALL_DIR:H:H:H)/PrintCom \
		  -I. -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
PROTOCONST	= PRINT

#include	<$(SYSMAKEFILE)>
