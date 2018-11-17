COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript print driver
FILE:		pscriptGraphics.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/15/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the PostScript
	print driver graphics mode support

	$Id: pscriptGraphics.asm,v 1.1 97/04/18 11:56:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		bx	- PState handle
		bp	- PState segment
		dx.cx	- VM file and block handle for Huge bitmap

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSwath	proc	far
bitmapFile	local	word		push	dx
bitmapBlock	local	word		push	cx
bitmapXres	local	word
bitmapYres	local	word
gstate		local	word
		
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter

		call	MemDerefES		; es = PState segment

	; We need to get the bitmap height so we can update the cursor
	; position for the next swath, and the bitmap resolution so we
	; can scale the bitmap correctly.

		push	bp
		movdw	bxax, dxcx		; bx.ax = file.block
		call	VMLock
		mov	dx, bp
		pop	bp

		mov	ds, ax			; ds <- HugeArray dir block
		mov	si, size HugeArrayDirectory	; skip past dir header
		mov	ax, ds:[si].B_height
		mov	es:[PS_swath].B_height, ax
		mov	ax, ds:[si].CB_xres
		mov	ss:[bitmapXres], ax
		mov	ax, ds:[si].CB_yres
		mov	ss:[bitmapYres], ax
	
	; If we're dealing with a fax bitmap, we need to change bitmap's
	; resolution to doc coordintates for the call into EPS.  A fax bitmap
	; will not have a resolution of 72 dpi.

		cmp	ax, 72		
		je	unlock
		
		mov	ds:[si].CB_yres, 72
		mov	ds:[si].CB_xres, 72
unlock:
		push	bp
		mov	bp, dx
		call	VMUnlock
		pop	bp

	; Create a gstate so we can specify how we want the bitmap drawn

		clr	di			; no window
		call	GrCreateState		; di = gstate
		mov	ss:[gstate], di

	; Again, if this is a fax bitmap, we figure the scale differently
	; (doc coords / fax res)	
		cmp	ss:[bitmapYres], 72
		je	normal

		mov	dx, 72
		mov	bx, ss:[bitmapYres]
		clr	cx, ax
		call	GrUDivWWFixed
		push	dx, cx			; save y res
		
		mov	dx, 72
		mov	bx, ss:[bitmapXres]
		clr	cx, ax
		call	GrUDivWWFixed
		pop	bx, ax		
		jmp	applyScale
normal:
	; set scale factor

		mov	bx, es:[PS_deviceInfo]
		call	MemLock
		mov	ds, ax
		clr	ax
		mov	al, es:[PS_mode]
		mov	si, ax			; si <- mode 
		mov	si, ds:[si].PI_firstMode; ds:si <- GraphicsProperties
		mov	ax, ds:[si].GP_xres	; ax <- printer xres
		mov	cx, ds:[si].GP_yres	; bx <- printer yres
		call	MemUnlock

		push	ax			; save printer xres
		mov	dx, ss:[bitmapYres]	; dx.cx <- bitmap yres
		mov	bx, cx
		clr	ax, cx			; bx.ax <- printer yres
		call	GrUDivWWFixed		; dx.cx <- scaleY
		pop	ax

		push	dx, cx			; save scaleY
		mov	dx, ss:[bitmapXres]	; dx.cx <- bitmap xres
		mov	bx, ax
		clr	ax, cx			; bx.ax <- printer xres
		call	GrUDivWWFixed		; dx.cx <- scaleX
		pop	bx, ax			; bx.ax <- scaleY
applyScale:
		call	GrApplyScale		; apply scale bitmap

		; set draw position

		mov	ax, es:[PS_cursorPos].P_x
		mov	bx, es:[PS_cursorPos].P_y
		call	GrMoveTo

	; Now, call the eps library to translate the bitmap

		mov	dx, es:[PS_expansionInfo]
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	di, ds:[GEO_hFile]	; di = get stream block handle
		call	MemUnlock

		mov	bx, ss:[bitmapFile]
		mov	ss:[TPD_dataBX], bx	; bx = bitmap file
		mov	ax, ss:[bitmapBlock]
		mov	ss:[TPD_dataAX], ax	; ax = bitmap block

		mov	si, ss:[gstate]		; si = gstate
		mov	bx, es:[PS_epsLibrary]
		mov	ax, TR_EXPORT_BITMAP
		call	CallEPSLibrary

	;
	; Reset the bitmap's resolution for next time
	;
		push	bp, ax
		mov	bx, ss:[bitmapFile]
		mov	ax, ss:[bitmapBlock]
		mov	cx, ss:[bitmapXres]
		mov	dx, ss:[bitmapYres]
		call	VMLock

		mov	ds, ax
		mov	si, size HugeArrayDirectory	; skip past dir heade
		mov	ds:[si].CB_xres, cx
		mov	ds:[si].CB_yres, dx

		call	VMUnlock
		pop	bp, ax

	; Update cursor position and destroy gstate

		mov	cx, es:[PS_swath].B_height
		add	es:[PS_cursorPos].P_y, cx	; update cursor pos

		mov	di, ss:[gstate]
		call	GrDestroyState

	; Return carry set if error

		cmp	ax, TE_NO_ERROR
		je	done
		stc				; error
done:
		.leave
		ret
PrintSwath	endp
