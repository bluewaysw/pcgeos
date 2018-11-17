
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		jobPaperInfo.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/92	initial version

DESCRIPTION:
	Routines to return Information about the paper or paper path for
	this job.
	They are all external routines.

	$Id: jobPaperInfo.asm,v 1.1 97/04/18 11:51:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		al	- PaperInputOptions record
		ah	- PaperOutputOptions record
		carry cleared

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintGetPaperPath	proc	far
	uses	bx, es
	.enter
	mov	es,bp			;es ----> PState
	mov	bx,es:[PS_deviceInfo]	;handle of the device specific data.
	call	MemLock
	mov	es,ax			;address of the device specific data.
	mov	al,es:[PI_paperInput]
	mov	ah,es:[PI_paperOutput]
	call	MemUnlock
	clc
	.leave
	ret
PrintGetPaperPath	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the margins set in the PState for this job.

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		ax	= left margin
		si	= top margin
		cx	= right margin
		dx	= bottom margin
		carry cleared

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintGetMargins	proc	far
	uses	bx,es
	.enter
	mov	es,bp			;es ----> PState
	mov	bx, es:[PS_deviceInfo]	; get handle to info
	call	MemLock			; lock it down
	mov	ds, ax			; ds -> device info
	mov	bx,offset PI_marginTractor ;assume tractor margins.
        mov     al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
        test    al,mask PIO_TRACTOR     ;check for tractor feed paths first.
	jnz	haveIndex
	mov	bx,offset PI_marginASF	;use SSheet margins.
haveIndex:
	mov	ax,ds:[bx].[PM_left]
	mov	si,ds:[bx].[PM_top]
	mov	cx,ds:[bx].[PM_right]
	mov	dx,ds:[bx].[PM_bottom]
		; unlock the device info resource
	mov	bx, es:[PS_deviceInfo]	; retrieve the handle
	call	MemUnlock		; release it
	clc
	.leave
	ret
PrintGetMargins	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetPrintArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the imageable area for the current page size 

CALLED BY:	GLOBAL

PASS:		bp	- PState segment	

RETURN:		ax	= left side coordinate 	 (points)
		si	= top side coordinate 	 (points)
		cx	= right side coordinate  (points)
		dx	= bottom side coordinate (points)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Take a look at the margins for the device and the current
		page size, and do the "right thing"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version
	Dave 	02/92		2.0 version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetPrintArea proc	far
 	uses	ds, es
	.enter


	call	PrintGetMargins		;get the margin info.


	push	ax			;save the left

	push	dx			;save the right and bottom
	push	cx

	mov	es, bp			; es -> PState
	mov	cx, es:[PS_customWidth]	; get width and height
	mov	dx, es:[PS_customHeight] 
		; get the size of the imageable area of the largest paper
		; size supported by the device.  If the size we want is smaller,
		; then let them have the whole thing...
	cmp	cx, ds:[PI_paperWidth]	; get max paper size
	jbe	applyMargins		; use smaller size in CX
	mov	cx, ds:[PI_paperWidth]	; else move smaller size to CX
applyMargins:
	pop	ax			;pop right margin into ax
	sub	cx, ax			; figure max right bound
	pop	ax			;pop bottom margin into ax
	sub	dx, ax			 ; subtract margin

	pop	ax			;get back the left

	clc				; no errors
	.leave
	ret

PrintGetPrintArea endp
