##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	New UI -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 15, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for new ui
#
#	$Id: local.mk,v 1.1 97/04/07 10:56:34 newdeal Exp $
#
###############################################################################
# ASMFLAGS	+= -Wall
# LINKFLAGS	+= -Wunref

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE		= ol

#
#	Rules for updating ollib.def
#

MERGE_FILES	= copenButton.asm copenCtrl.asm copenReplyBar.asm \
		  copenMenuButton.asm copenTrace.asm \
		  copenApplication.asm copenSystem.asm\
		  copenGauge.asm copenGlyphDisplay.asm \
		  copenTextDisplay.asm copenTextEdit.asm\
		  copenSettingCtrl.asm copenSetting.asm \
		  cwinClass.asm cwinBase.asm cwinMenu.asm\
		  cwinField.asm cwinScreen.asm cwinPopup.asm cwinDialog.asm \
		  cwinWinIcon.asm cwinGlyphDisplay.asm\
		  cviewPane.asm cviewPort.asm cviewPortGroup.asm\
		  cviewSimplePane.asm cviewPortWindow.asm cviewScrollbar.asm\
		  copenScrollList.asm copenScrollItem.asm copenCheckbox.asm\
		  copenMenuItemGroup.asm cwinDisplayControl.asm\
		  cwinDisplay.asm cwinMenuedWin.asm copenMenuBar.asm\
		  copenTriggerBar.asm\
		  copenGadget.asm copenGadgetComp.asm copenContent.asm\
		  copenIsoContent.asm copenSpinGadget.asm copenRange.asm\
		  copenDynamicList.asm cmainUIDocumentControl.asm \
		  cmainAppDocumentControl.asm \
		  cmainDocument.asm copenFileSelector.asm

LIBHDR		= ollib.def

PROTOCONST	= SPUI

#
#	Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS	+= -DOPEN_LOOK

UICFLAGS	+= -DOPEN_LOOK

#include    <$(SYSMAKEFILE)>
