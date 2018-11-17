COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC/GEOS
MODULE:		Windowing System
FILE:		Win/winGeode.asm

AUTHOR:		Doug Fults

ROUTINES:
	Name			Description
	----			-----------
GLB	WinGeodeSetPtrImage	Set the PIL_GEODE level ptr image for geode
GLB	WinGeodeGetInputObj	Get input [application] object for geode
GLB	WinGeodeSetInputObj	Set input [application] object for geode
GLB	WinGeodeGetParentObj	Get focus/target parent [field] object for geode
GLB	WinGeodeSetParentObj	Set focus/target parent [field] object for geode
GLB	WinGeodeGetFlags	Get GeodeWinFlags for geode
GLB	WinGeodeSetFlags	Set GeodeWinFlags for geode
GLB	WinGeodeSetInputObj	Set input [application] object for geode
GLB	WinGeodeSetActiveWin	Set active window for geode
GLB	WinSysSetActiveGeode	Make geode "active" geode within system

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/20/92		Initial version

DESCRIPTION:
	This file contains library functions of the PC/GEOS Window Manager.


	$Id: winGeode.asm,v 1.1 97/04/05 01:16:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinMovable segment resource


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeSetPtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows setting of PIL_GEODE ptr image

CALLED BY:	GLOBAL

PASS:		^lcx:dx	- PointerDef in sharable memory block, OR
			  cx = 0, and dx = PtrImageValue (see Internal/im.def)
		^hbx	- Geode

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeSetPtrImage	proc	far uses	ax, ds
	.enter
EC <	call	ECCheckGeodeHandle					>
	LoadVarSeg	ds
					; Get access to W_*PtrImage variables,
					; wPtrActiveWin, & ActivateWinPtrImages
	push	bx
	PSem	ds, winPtrImageSem, TRASH_AX_BX
	pop	bx

	tst	cx			; if PIV_UPDATE, skip changing window
	jnz	setNewImage
	cmp	dx, PIV_UPDATE
	je	afterGeodeUpdate

setNewImage:
	push	si
	call	ReadGeodeWinVars
	cmp	ds:[si].GWV_ptrImage.handle, cx
	jne	setNew
	cmp	ds:[si].GWV_ptrImage.chunk, dx
	je	skipSetting
setNew:
	; Store new ptr image
	mov	ds:[si].GWV_ptrImage.handle, cx
	mov	ds:[si].GWV_ptrImage.chunk, dx
	call	WriteGeodeWinVars
skipSetting:
	pop	si
	je	exit			; if no change, exit

afterGeodeUpdate:
					; update if this is the final Geode
	cmp	bx, ds:[wPtrFinalGeode]
	jne	exit
	push	bp
	mov	bp, PIL_GEODE
	call	ImSetPtrImage		; Set new ptr image at level passed
	pop	bp
exit:
	push	bx
	VSem	ds, winPtrImageSem, TRASH_AX_BX
	pop	bx
	.leave
	ret
WinGeodeSetPtrImage	endp

;----------------------------------------

ReadGeodeWinVars	proc	near	uses	cx, di
	.enter
	mov	di, ds:[wGeodeWinVarsOffset]
	mov	si, offset wGeodeVarsBuffer
	mov	cx, (size GeodeWinVars)/2
	call	GeodePrivRead
	.leave
	ret
ReadGeodeWinVars	endp

WriteGeodeWinVars	proc	near	uses	cx, di
	.enter
	pushf
	mov	di, ds:[wGeodeWinVarsOffset]
	mov	si, offset wGeodeVarsBuffer
	mov	cx, (size GeodeWinVars)/2
	call	GeodePrivWrite
	popf
	.leave
	ret
WriteGeodeWinVars	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeGetInputObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows fetching geode's input object

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode

RETURN:		cx:dx	- Input object, or 0 if none

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeGetInputObj	proc	far uses	di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_inputObj
	call	GetGeodeWinVarOptr
	.leave
	ret
WinGeodeGetInputObj	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeGetParentObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows fetching geode's parent object

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode

RETURN:		cx:dx	- parent object, or 0 if none

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeGetParentObj	proc	far uses	di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_parentObj
	call	GetGeodeWinVarOptr
	.leave
	ret
WinGeodeGetParentObj	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows fetching geode's GeodeWinFlags

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode

RETURN:		ax	- GeodeWinFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeGetFlags	proc	far uses	di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_flags	; get two words starting here
	push	cx, dx
	call	GetGeodeWinVarOptr
	mov	ax, dx			; keep only first one
	pop	cx, dx
	.leave
	ret
WinGeodeGetFlags	endp

;----------------------------------------

GetGeodeWinVarOptr	proc	near	uses	si, bp, ds
	.enter
	LoadVarSeg	ds
	add	di, ds:[wGeodeWinVarsOffset]
	sub	sp, size optr
	mov	bp, sp
	segmov	ds, ss		; get ds:si = ptr to stack frame
	mov	si, bp
	mov	cx, (size optr)/2
	call	GeodePrivRead
	mov	cx, ss:[bp].handle
	mov	dx, ss:[bp].chunk
	add	sp, size optr
	.leave
	ret
GetGeodeWinVarOptr	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeSetActiveWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets window passed to be the "active" window within its geode.

CALLED BY:	GLOBAL

PASS:		bx	- Geode
		di	- Window to make active, or 0 if no active win in geode

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeSetActiveWin	proc	far	uses	bx, si, ds
	.enter
EC <	call	ECCheckGeodeHandle					>
	LoadVarSeg	ds
	call	PTreeAndPtrImageSem

	call	ReadGeodeWinVars
	cmp	di, ds:[si].GWV_activeWin
	je	done

	mov	ds:[si].GWV_activeWin, di
	call	WriteGeodeWinVars	; store new active window

	cmp	di, ds:[wPtrFinalWin]	; window whose ptr images are already
					; being shown?
	je	done			; if so, out of here!

	push	es
	push	ds
	pop	es
	call	UpdatePtrImages		; otherwise, refigure new ptr image
	pop	es

done:
	call	VTreeAndPtrImageSem
	.leave
	ret
WinGeodeSetActiveWin	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSysSetActiveGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets geode passed to be the "active" geode within system

CALLED BY:	GLOBAL

PASS:		bx	- geode to make active, or zero to set none active

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinSysSetActiveGeode	proc	far	uses	ds
	.enter
EC <	tst	bx							>
EC <	jz	10$							>
EC <	call	ECCheckGeodeHandle					>
EC <10$:								>
	LoadVarSeg	ds
	call	PTreeAndPtrImageSem
					; see if was active geode
	cmp	bx, ds:[wPtrActiveGeode]
	je	done			; skip out if so,
	mov	ds:[wPtrActiveGeode], bx; else set new active geode

	push	es
	push	ds
	pop	es
	call	UpdatePtrImages		; update PIL_GADGET, PIL_WINDOW,
					; PIL_LAYER ptr images
	pop	es
done:
	call	VTreeAndPtrImageSem
	.leave
	ret
WinSysSetActiveGeode	endp


;----------------------------------------


PTreeAndPtrImageSem	proc	near	uses	ax, bx
	.enter
	PSem	ds, winTreeSem, TRASH_AX_BX
	PSem	ds, winPtrImageSem, TRASH_AX_BX
	.leave
	ret
PTreeAndPtrImageSem	endp


VTreeAndPtrImageSem	proc	near	uses	ax, bx
	.enter
	VSem	ds, winTreeSem, TRASH_AX_BX
	VSem	ds, winPtrImageSem, TRASH_AX_BX
	.leave
	ret
VTreeAndPtrImageSem	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeSetInputObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows setting geode's input object

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode
		cx:dx	- Input object, or 0 if none

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeSetInputObj	proc	far uses	ax, di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_inputObj
	mov	ax, (size optr)/2	; # of words to write
	call	SetGeodeWinVarOneOrTwoWords
	.leave
	ret
WinGeodeSetInputObj	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeSetParentObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows setting geode's parent object

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode
		cx:dx	- parent object, or 0 if none

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeSetParentObj	proc	far uses	ax, di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_parentObj
	mov	ax, (size optr)/2	; # of words to write
	call	SetGeodeWinVarOneOrTwoWords
	.leave
	ret
WinGeodeSetParentObj	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGeodeSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows setting geode's parent object

CALLED BY:	GLOBAL

PASS:		^hbx	- Geode
		ax	- GeodeWinFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinGeodeSetFlags	proc	far uses	di
	.enter
EC <	call	ECCheckGeodeHandle					>
	mov	di, offset GWV_flags
	push	ax, dx
	mov	dx, ax			; setup word to write
	mov	ax, (size word)/2	; # of words to write
	call	SetGeodeWinVarOneOrTwoWords
	pop	ax, dx
	.leave
	ret
WinGeodeSetFlags	endp

;----------------------------------------

SetGeodeWinVarOneOrTwoWords	proc	near	uses	cx, si, bp, ds
				; AX = # of words to write (1 or 2 allowed)
				; DX = first word
				; CX = 2nd word
	.enter
	LoadVarSeg	ds
	add	di, ds:[wGeodeWinVarsOffset]
	sub	sp, size optr
	mov	bp, sp
	mov	ss:[bp].handle, cx
	mov	ss:[bp].chunk, dx
	segmov	ds, ss		; get ds:si = ptr to stack frame
	mov	si, bp
	mov	cx, ax		; get # of words to write (from AX)
	call	GeodePrivWrite
	add	sp, size optr
	.leave
	ret
SetGeodeWinVarOneOrTwoWords	endp

WinMovable ends
