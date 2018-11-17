COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpHelp.asm

AUTHOR:		Gene Anderson, Feb 23, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/23/93		Initial revision


DESCRIPTION:
	Code for help on help

	$Id: helpHelp.asm,v 1.1 97/04/07 11:47:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up help on help

CALLED BY:	MSG_META_BRING_UP_HELP
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlBringUpHelp		method dynamic HelpControlClass,
						MSG_META_BRING_UP_HELP,
						MSG_HC_BRING_UP_HELP
	uses	cx, dx, bp
HELP_LOCALS
	;
	; We borrow stack space because the we may have used a lot
	; of stack space getting here, and the VMOpen() we'll do
	; requires a decent amount, too.
	;
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	.enter
	;
	; Get child block and features for a controller into local vars
	;
	call	HUGetChildBlockAndFeaturesLocals
	test	ss:features, mask HPCF_HELP
	jz	openError			;don't bring up help on help
	;					; if no help button
	; Get the name "TOC"
	;
	mov	di, offset TableOfContents
	call	HNGetStandardName
	;
	; Get the appropriate file name based on whether we are on a
	; keyboard only system or not
	;
	mov	di, offset MouseHelpOnHelp
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	notKeyboardOnly
	mov	di, offset KbdHelpOnHelp
notKeyboardOnly:
	lea	bx, ss:filename
	call	HNGetStandardNameCommon
	;
	; Bring up the help on help.  Display the new text
	;
	call	HLDisplayText
	jc	openError			;branch if error
	;
	; Update various things for history
	;
	call	HHUpdateHistoryForLink
openError:
	.leave

	pop	di
	call	ThreadReturnStackSpace
	ret
HelpControlBringUpHelp		endm


HelpControlCode	ends
