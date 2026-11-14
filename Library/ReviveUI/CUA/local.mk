##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	CUA (Specific User Interface)
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
#	$Id: local.mk,v 1.1 97/04/07 10:56:54 newdeal Exp $
#
###############################################################################

#
#	Rules for updating cualib.def
#

MERGE_FILES	= copenButton.asm copenCtrl.asm copenGroup.asm copenMenuBar.asm\
		  copenMenuButton.asm copenTrace.asm copenTriggerBar.asm\
		  copenApplication.asm copenSystem.asm\
		  copenGauge.asm copenGlyphDisplay.asm \
		  copenTextDisplay.asm copenTextEdit.asm\
		  copenSettingCtrl.asm copenSetting.asm \
		  cwinClass.asm cwinBase.asm cwinMenu.asm cwinNotice.asm\
		  cwinField.asm cwinScreen.asm cwinPopup.asm cwinCommand.asm \
		  cwinWinIcon.asm cwinGlyphDisplay.asm\
		  cviewPane.asm cviewScrollbar.asm\
		  copenScrollList.asm copenScrollItem.asm copenCheckbox.asm\
		  copenMenuItemGroup.asm cwinDisplayControl.asm\
		  cwinDisplay.asm cwinMenuedWin.asm copenMenuBar.asm\
		  copenGadget.asm copenGadgetComp.asm copenContent.asm \
		  copenIsoContent.asm copenSpinGadget.asm copenRange.asm\
		  copenDynamicList.asm cmainUIDocumentControl.asm \
		  cmainAppDocumentControl.asm \
		  cmainDocument.asm copenFileSelector.asm

LIBHDR		= cualib.def

PROTOCONST	= SPUI

#
#	Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS	+= -DCOMMON_USER_ACCESS

UICFLAGS	+= -DCOMMON_USER_ACCESS

#include    <$(SYSMAKEFILE)>
