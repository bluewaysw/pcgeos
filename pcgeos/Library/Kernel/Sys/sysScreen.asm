COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel -- System notification
FILE:		sysScreen.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

DESCRIPTION:
	This file contains error handling routines.

	$Id: sysScreen.asm,v 1.1 97/04/05 01:15:01 newdeal Exp $

------------------------------------------------------------------------------@

ObscureInitExit	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysRegisterScreen

DESCRIPTION:	Register another screen with our error mechanism, creating
		the needed gstate and window.

CALLED BY:	Kernel (SysRegisterScreen)

PASS:
	cx	= handle of root window for the screen
	dx	= handle of video driver for the screen

RETURN:
	none

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

------------------------------------------------------------------------------@

SysRegisterScreen	proc	far	uses ax, bx, cx, dx, si, di, bp, es, ds
	.enter
	mov	ax, handle 0		; Tell WinOpen to give us ownership
					; of the window
	push	ax			; Layer ID
	push	ax			; Ownership
	push	dx			; Pass video driver to WinOpen

	; compute location for error box using VideoDriverInfo structure for
	; driver

	push	cx

	mov	bx, dx
	call	GeodeInfoDriver
	mov	ax,ds:[si].VDI_pageW
	mov	cx, ERROR_WIDTH
	sub	ax,cx

	sar	ax,1
		
	jge	figureX
	clr	ax
	mov	cx, ds:[si].VDI_pageW
figureX:
	mov	bx,ds:[si].VDI_pageH
	mov	dx,ERROR_HEIGHT
	sub	bx, dx
	sar	bx,1
	jge	getStrat
	clr	bx
	mov	dx, ds:[si].VDI_pageH
getStrat:
	; (ax, bx) = upper-left
	; (cx, dx) = (width, height)
	
	mov	di, ds:[si].DIS_strategy.segment
	mov	bp, ds:[si].DIS_strategy.offset

	segmov	ds, dgroup, si
	mov	si, ds:[nextScreen]
	pop	ds:[actualRoots][si]
	mov	ds:[errorStratOffs][si], bp
	mov	ds:[errorStratSegs][si], di

	; allocate window and GState for errors

						;push region (0 for rect)
	clr	di
	push	di
	push	di

	; push bounds

	add	cx, ax
	add	dx, bx
	dec	cx
	dec	dx
	push	dx
	push	cx
	push	bx
	push	ax

	mov	ax, (mask WCF_TRANSPARENT or mask WCF_PLAIN) shl 8
					;No back color fills, no expose events

	;clr	di			; output descriptor (none)
	clr	bp, cx, dx 		; enter leave OD (none)

	mov	si,mask WPF_ROOT or WIN_PRIO_STD or mask WPF_CREATE_GSTATE

	call	WinOpen			; open the window di = gstate, bx = win

	mov	si, ds:nextScreen
	mov	ds:errorWins[si], bx
	mov	ds:errorStates[si], di
	inc	si
	inc	si
	mov	ds:nextScreen, si

	;
	; Initialize colors for the things we use
	;
	mov	ax, C_BLACK
	call	GrSetLineColor
	mov	ax, C_WHITE
	call	GrSetAreaColor
	mov	ax, C_BLACK
	call	GrSetTextColor

	push	bx			; save window
	mov	ax,-100
	mov	bx, ax
	mov	cx, ax
	inc	cx
	mov	dx, cx
	call	GrFillRect		; draw dummy point to cause structure
					; to be validated

	;
	; Make the gstate and window be neither swapable nor discardable,
	; ensuring they're always around when we need them. Make the gstate
	; owned by the kernel so it doesn't get freed during detach...
	;
	mov	bx, di			;bx = handle
	call	abuseBlock

	pop	bx
	call	abuseBlock

	.leave
	ret

abuseBlock:
	mov	ax, ((mask HF_DISCARDABLE or mask HF_SWAPABLE) shl 8) or \
			(mask HF_SHARABLE)
	call	MemModifyFlags
	mov	ax, handle 0
	call	HandleModifyOwner

	; nuke extra bytes

	call	LMemContractBlock
	retn

SysRegisterScreen	endp

ObscureInitExit ends
