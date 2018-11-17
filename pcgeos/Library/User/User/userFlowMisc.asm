COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userFlowMisc.asm

ROUTINES:
	Name			Description
	----			-----------

; Global routines, callable from ANY thread

;
; Button utilities
;
GLB	FlowTranslatePassiveButton	; Translate a
					; MSG_META_PRE_PASSIVE_BUTTON or
					; MSG_META_POST_PASSIVE_BUTTON to a
					; generic method

GLB	FlowGetUIButtonFlags		; Return the current UIButtonFlag

GLB	FlowCheckKbdShortcut


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Doug	12/89		Cleaned up file organization

DESCRIPTION:
	This file contains routines to handle input processing for the
	User Interface.
	
	$Id: userFlowMisc.asm,v 1.1 97/04/07 11:46:00 newdeal Exp $

-------------------------------------------------------------------------------@

FlowCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowTranslatePassiveButton

DESCRIPTION:	Translate a MSG_META_PRE_PASSIVE_BUTTON or
		MSG_META_POST_PASSIVE_BUTTON to a generic method

CALLED BY:	GLOBAL

PASS:
	ax	- MSG_META_PRE_PASSIVE_BUTTON or MSG_META_POST_PASSIVE_BUTTON
	cx, dx	- mouse position (not used here, but left intact through call)
	bp	- Data as passed in bp to above methods:
	   low  - ButtonInfo
		  mask BI_PRESS		- set if press
		  mask BI_DOUBLE_PRESS	- set if double-press
		  mask BI_B3_DOWN	- state of button 3
		  mask BI_B2_DOWN	- state of button 2
		  mask BI_B1_DOWN	- state of button 1
		  mask BI_B0_DOWN	- state of button 0
	   high - UIFunctionsActive


RETURN:
	ax, cx, dx, bp - translated method (ready to send)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

FlowTranslatePassiveButton	proc	far

if	(0)
	push	ds
	push	ax
	mov	ax, segment idata
	mov	ds, ax
	pop	ax

	cmp	ax,MSG_META_PRE_PASSIVE_BUTTON
	mov	ax,MSG_META_PRE_PASSIVE_START_SELECT - MSG_META_START_SELECT
	jz	FTPB_10
	mov	ax,MSG_META_POST_PASSIVE_START_SELECT - MSG_META_START_SELECT
FTPB_10:

EC <	tst	ds:[activeMouseMethod]					>
EC <	ERROR_Z	UI_ERROR_CURRENT_MOUSE_MSG_SHOULD_NOT_BE_NULL	>

	add	ax,ds:[activeMouseMethod]	;add method
					;get [UIFunctionsActive | buttonInfo]
;	mov	bp,word ptr ds:[activeMouseButtonInfo]
	pop	ds

else
	push	bx
	mov	bx, bp

	cmp	ax, MSG_META_PRE_PASSIVE_BUTTON
	mov	ax, MSG_META_PRE_PASSIVE_START_SELECT - MSG_META_START_SELECT
	jz	prePostDone
	mov	ax,MSG_META_POST_PASSIVE_START_SELECT - MSG_META_START_SELECT
prePostDone:

	test	bh, mask UIFA_SELECT
	jnz	startSelect
	test	bh, mask UIFA_MOVE_COPY
	jnz	moveCopy
	test	bh, mask UIFA_FEATURES
	jnz	features
;other:
	add	ax, MSG_META_START_OTHER
	jmp	short haveFunction
startSelect:
	add	ax, MSG_META_START_SELECT
	jmp	short haveFunction
moveCopy:
	add	ax, MSG_META_START_MOVE_COPY
	jmp	short haveFunction
features:
	add	ax, MSG_META_START_FEATURES
haveFunction:
	test	bl, mask BI_PRESS
	jnz	havePressRelease
	inc	ax			; switch to END method if release
havePressRelease:
	pop	bx
endif
	ret

FlowTranslatePassiveButton	endp

FlowCommon	ends
;
;-------------------
;
Resident	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	FlowGetUIButtonFlags

DESCRIPTION:	Return the current UIButtonFlags

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	al - UIButtonFlags (UIBF_CLICK_TO_TYPE, etc)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	5/91		Changed name, changed to only get ButtonFlags

------------------------------------------------------------------------------@


FlowGetUIButtonFlags	proc	far
	push	ds
	push	ax
	mov	ax, segment idata
	mov	ds, ax
	pop	ax
	mov	al, ds:[uiButtonFlags]		; get UIButtonFlags var
	pop	ds
	ret
FlowGetUIButtonFlags	endp

ife FULL_EXECUTE_IN_PLACE

Resident	ends
;
;---------------
;
Navigation	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlowCheckKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the key event maps to a shortcut.

CALLED BY:	utility
PASS:		ds:si	= pointer to a shortcut table.
		(ds:si *can* be pointing to the movable XIP code resource.)
		ax	= # of entries in the table.
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		si	= offset into table where shortcut was found.
		carry set if a kbd shortcut match was found.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Should cache entry point and deal with changing keyboard
		drivers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/20/90		Initial version
	Eric/Tony 2/21/90	moved from User/Text to User/User/userFlowUtils

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlowCheckKbdShortcut	proc	far
	uses	bx, es, ds, di
	.enter

	sub	sp, size dword
	mov	di, sp
	segmov	es, ds				; es:si <- ptr to table.
	push	ax, si
	mov	ax, GDDT_KEYBOARD
	call	GeodeGetDefaultDriver		; ax <- keyboard driver
	mov	bx, ax				; bx <- kbd driver handle.
	call	GeodeInfoDriver			; ds:si <- ptr to struct.
	mov	ax, ds:[si].DIS_strategy.segment
	mov	bx, ds:[si].DIS_strategy.offset
	mov	({fptr} ss:[di]).segment, ax	; Save strategy routine addr.
	mov	({fptr} ss:[di]).offset, bx
	pop	ax, si
	mov	bx, di				; ss:bx = entry point
	mov	di, DR_KBD_CHECK_SHORTCUT
	call	{fptr} ss:[bx]			; Call the driver.
	lea	sp, ss:[bx][size dword]		; preserve carry

	.leave
	ret
FlowCheckKbdShortcut	endp

if FULL_EXECUTE_IN_PLACE
Resident	ends
else
Navigation ends
endif
