COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the user interface definition for the
	GeoWrite application.

	$Id: uiManager.asm,v 1.3 98/02/17 03:42:11 gene Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include writeGeode.def
UseLib  spell.def
include writeConstant.def
include writeDocument.def
include writeApplication.def
include writeProcess.def
include writeDisplay.def
include	writeSuperImpex.def

PZ< include writeControls.def >

include gstring.def

UseLib Objects/styles.def
UseLib Objects/Text/tCtrlC.def
include writeGrObjHead.def

include pageInfo.def

if FAX_SUPPORT or LIMITED_FAX_SUPPORT
UseLib	Internal/spoolInt.def
UseLib  mailbox.def
include Mailbox/vmtree.def
include Mailbox/spooltd.def
include Mailbox/faxsendtd.def
include	initfile.def
endif

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

if	_DWP
include	uiPrint.asm
endif

if PZ_PCGEOS
include uiFixed.asm
include uiRowColumn.asm
endif

ifdef _SUPER_IMPEX
include uiSuperIC.asm
endif
include uiWriteDC.asm
include uiTemplate.asm
include uiGifImage.asm
