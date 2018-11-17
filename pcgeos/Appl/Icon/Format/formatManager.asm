COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	icon editor
MODULE:		format
FILE:		formatManager.asm

AUTHOR:		Steve Yegge, Aug 31, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/31/92		Initial revision


DESCRIPTION:
		

	$Id: formatManager.asm,v 1.1 97/04/04 16:06:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	iconGeode.def
; include any other .def files local to this module

include	formatConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

idata	segment

	FormatContentClass
	VisFormatClass
	TransformDisplayClass
	TransformFormatDialogClass

idata	ends

;-----------------------------------------------------------------------------
;		StandardDialogResponseTriggerTable
;-----------------------------------------------------------------------------
if 0
FormatCode	segment	resource

SDRT_formatChangedSaveChanges	label	StandardDialogResponseTriggerTable
	word	3			; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SFD_saveChangesYes,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SFD_saveChangesNo,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		SFD_cancel,
		IC_DISMISS
	>

FormatCode	ends
endif
;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include	formatFormat.asm
include	formatTransform.asm
include	formatUI.asm
include formatFlip.asm
include	formatVMFile.asm
