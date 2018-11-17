##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Memory Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, August 29, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	8/28/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Memory video  driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:55 newdeal Exp $
#
###############################################################################

#
# to allow i/o instructions, and interrupt disabling
#
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../DumbCom $(INSTALL_DIR:H)/DumbCom \
		../../VGAlike/VGA8 $(INSTALL_DIR:H)/../VGAlike/VGA8 \
		../../VidCom $(INSTALL_DIR:H)/../VidCom

#
# change the order that we do Modules, so that Mono comes before Color
#
MODULES		= Main Mono Clr4 Clr8 Clr24 CMYK

#
# re-assign the nine include directories to exclude the current one
#
-IFLAGS		= -I$(.TARGET:T:R) -I$(INSTALL_DIR)/$(.TARGET:T:R) \
		  -I. -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \
		  -I../DumbCom -I$(INSTALL_DIR:H)/DumbCom \
		-I../../VGAlike/VGA8 -I$(INSTALL_DIR:H)/../VGAlike/VGA8 \
		  -I../../VidCom -I$(INSTALL_DIR:H)/../VidCom  \
		  -I$(INSTALL_DIR) \

#include	<$(SYSMAKEFILE)>
