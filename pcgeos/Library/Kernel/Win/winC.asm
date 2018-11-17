COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Win
FILE:		winC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: winC.asm,v 1.1 97/04/05 01:16:15 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGetWinScreenBounds

C DECLARATION:	extern void
			_far _pascal WinGetWinScreenBounds(WindowHandle win,
						    Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINGETWINSCREENBOUNDS	proc	far
	C_GetThreeWordArgs	ax, cx, dx,  bx	;ax = gs, cx = seg, dx = off

	push	di, es
	mov	es, cx
	push	dx
	mov_trash	di, ax
	call	WinGetWinScreenBounds
	pop	di
	stosw
	mov_trash	ax, bx
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw

	pop	di, es
	ret

WINGETWINSCREENBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrBeginUpdate

C DECLARATION:	extern void
			_far _pascal GrBeginUpdate(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRBEGINUPDATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	GrBeginUpdate
	xchg	ax, di
	ret

GRBEGINUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEndUpdate

C DECLARATION:	extern void
			_far _pascal GrEndUpdate(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRENDUPDATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	GrEndUpdate
	xchg	ax, di
	ret

GRENDUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinAckUpdate

C DECLARATION:	extern void
			_far _pascal WinAckUpdate(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINACKUPDATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	WinAckUpdate
	xchg	ax, di
	ret

WINACKUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinInvalReg

C DECLARATION:	extern void
		    _far _pascal WinInvalReg(WindowHandle win,
					const Region _far *reg, word axParam,
					word bxParam, word cxParam,
					word dxParam);
			Note: "reg" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WININVALREG	proc	far	win:hptr, preg:fptr, axParam:word,
				bxParam:word, cxParam:word, dxParam:word
				uses si, di
	.enter

	mov	ax, axParam
	mov	bx, bxParam
	mov	cx, cxParam
	mov	dx, dxParam
	mov	di, win
	mov	si, preg.offset
	push	bp
	mov	bp, preg.segment
	call	WinInvalReg
	pop	bp

	.leave
	ret

WININVALREG	endp


C_Common	ends

;---

C_Graphics	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinOpen

C DECLARATION:	extern WindowHandle
		    _far _pascal WinOpen(Handle parentWinOrVidDr,
			optr inputRecipient, optr exposureRecipient,
			word colorFlags, word redOrIndex, word green,
			word blue, word flags, word layerID, GeodeHandle owner,
			const Region _far *winReg, word axParam, word bxParam,
			word cxParam, word dxParam);
			Note: "winReg" *cannot* be pointing to the XIP movable 
				code resource.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINOPEN	proc	far	parentWinOrVidDr:hptr, inputRecipient:optr,
			exposureRecipient:optr,
			colorFlags:word, redOrIndex:word,
			green:word, blue:word, flags:word, layerID:word,
			owner:hptr, winReg:fptr, axParam:word, bxParam:word,
			cxParam:word, dxParam:word
				uses si, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, winReg					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	push	bp
	push	layerID
	push	owner
	push	parentWinOrVidDr
	push	winReg.segment
	push	winReg.offset
	push	dxParam
	push	cxParam
	push	bxParam
	push	axParam

	mov	al, redOrIndex.low
	mov	ah, colorFlags.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	si, flags
	mov	cx, inputRecipient.handle
	mov	dx, inputRecipient.chunk
	mov	di, exposureRecipient.handle
	mov	bp, exposureRecipient.chunk
	call	WinOpen
	pop	bp
	mov_trash	ax, bx

	.leave
	ret

WINOPEN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinClose

C DECLARATION:	extern void
			_far _pascal WinClose(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINCLOSE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	WinClose
	xchg	ax, di
	ret

WINCLOSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinMove

C DECLARATION:	extern void
		    _far _pascal WinMove(WindowHandle win, sword xMove,
						sword yMove, word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINMOVE	proc	far	win:hptr, xMove:sword, yMove:sword, flags:word
				uses si, di
	.enter

	mov	ax, xMove
	mov	bx, yMove
	mov	si, flags
	mov	di, win
	call	WinMove

	.leave
	ret

WINMOVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinResize

C DECLARATION:	extern void
		    _far _pascal WinResize(WindowHandle win,
					const Region _far *reg, word axParam,
					word bxParam, word cxParam,
					word dxParam, word flags);
			Note: "preg" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINRESIZE	proc	far	win:hptr, preg:fptr, axParam:word,
				bxParam:word, cxParam:word, dxParam:word,
				flags:word
				uses si, di
	.enter

	push	bp
	push	flags
	mov	ax, axParam
	mov	bx, bxParam
	mov	cx, cxParam
	mov	dx, dxParam
	mov	di, win
	mov	si, preg.offset
	mov	bp, preg.segment
	call	WinResize
	pop	bp

	.leave
	ret

WINRESIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinDecRefCount

C DECLARATION:	extern void
			_far _pascal WinDecRefCount(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINDECREFCOUNT	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	WinDecRefCount
	xchg	ax, di
	ret

WINDECREFCOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinChangePriority

C DECLARATION:	extern void
			_far _pascal WinChangePriority(WindowHandle win,
						word flags, word layerID);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINCHANGEPRIORITY	proc	far
	C_GetThreeWordArgs	bx, ax, dx,  cx	;bx = win, ax = flags, dx = id

	xchg	bx, di
	call	WinChangePriority
	xchg	bx, di
	ret

WINCHANGEPRIORITY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinScroll

C DECLARATION:	extern void
		    _far _pascal WinScroll(WindowHandle win, sword xMove,
						sword yMove);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINSCROLL	proc	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = win, ax = x, bx = y

	xchg	dx, di
	call	WinScroll
	xchg	dx, di
	ret

WINSCROLL	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinSuspendUpdate

C DECLARATION:	extern void
			_far _pascal WinSuspendUpdate(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINSUSPENDUPDATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	WinSuspendUpdate
	xchg	ax, di
	ret

WINSUSPENDUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinUnSuspendUpdate

C DECLARATION:	extern void
			_far _pascal WinUnSuspendUpdate(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINUNSUSPENDUPDATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = win

	xchg	ax, di
	call	WinUnSuspendUpdate
	xchg	ax, di
	ret

WINUNSUSPENDUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGetInfo

C DECLARATION:	extern void
		    _far _pascal WinGetInfo(WindowHandle win,
					WinInfoType type, void _far *data);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINGETINFO	proc	far	win:hptr, gtype:word, gdata:fptr
				uses si, di, es
	.enter

	mov	si, gtype
	mov	di, win
	call	WinGetInfo

	les	di, gdata
	cmp	si, WIT_INPUT_OBJ
	jz	storeDXCX
	cmp	si, WIT_EXPOSURE_OBJ
	jz	storeDXCX
	cmp	si, WIT_STRATEGY
	je	storeDXCX

	stosw
	mov_trash	ax, bx
	cmp	si, WIT_COLOR
	jz	store
	cmp	si, WIT_PRIVATE_DATA
	jnz	done
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
store:
	stosw
done:

	.leave
	ret

storeDXCX:
	mov_trash	ax, dx
	stosw
	mov_trash	ax, cx
	jmp	store

WINGETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinSetInfo

C DECLARATION:	extern void
			_far _pascal WinSetInfo(WindowHandle win,
					WinInfoType type, dword data);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINSETINFO	proc	far	win:hptr, wtype:word, wdata:dword
				uses si, di, ds
	.enter

	mov	si, wtype
	mov	cx, wdata.high
	mov	dx, wdata.low
	cmp	si, WIT_PRIVATE_DATA
	jz	privateData
	cmp	si, WIT_COLOR
	jnz	setinfo
	mov_trash	ax, dx
	mov_trash	bx, cx
setinfo:
	mov	di, win
	call	WinSetInfo

	.leave
	ret

privateData:
	mov	ds, cx
	mov	di, dx
	mov	ax, ds:[di]
	mov	bx, ds:[di]+2
	mov	cx, ds:[di]+4
	mov	dx, ds:[di]+6
	jmp	setinfo

WINSETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinApplyRotation

C DECLARATION:	extern void
		    _far _pascal WinApplyRotation(WindowHandle win,
				WWFixedAsDWord angle, WinInvalFlag flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINAPPLYROTATION	proc	far	win:hptr, angle:dword, flag:word
				uses si, di
	.enter

	mov	dx, angle.high
	mov	ax, angle.low
	mov	si, flag
	mov	di, win
	call	WinApplyRotation

	.leave
	ret

WINAPPLYROTATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinApplyScale

C DECLARATION:	extern void
		    _far _pascal WinApplyScale(WindowHandle win,
				WWFixedAsDWord xScale, WWFixedAsDWord yScale,
				WinInvalFlag flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINAPPLYSCALE	proc	far	win:hptr, xScale:sdword, yScale:sdword,
				flag:word
				uses si, di
	.enter

	mov	dx, xScale.high
	mov	ax, xScale.low
	mov	bx, yScale.high
	mov	cx, yScale.low
	mov	si, flag
	mov	di, win
	call	WinApplyScale

	.leave
	ret

WINAPPLYSCALE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinApplyTranslation

C DECLARATION:	extern void
		    _far _pascal WinApplyTranslation(WindowHandle win,
				sword xTrans, sword yTrans, WinInvalFlag flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINAPPLYTRANSLATION	proc	far	win:hptr, xTrans:sword, yTrans:sword,
				flag:word
				uses si, di
	.enter

	mov	ax, xTrans
	mov	bx, yTrans
	mov	si, flag
	mov	di, win
	call	WinApplyTranslation

	.leave
	ret

WINAPPLYTRANSLATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinApplyTranslationDWord

C DECLARATION:	extern void
		    _far _pascal WinApplyTranslationDWord(WindowHandle win,
				sdword xTrans, sdword yTrans,
				WinInvalFlag flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINAPPLYTRANSLATIONDWORD	proc	far	win:hptr, xTrans:sdword, yTrans:sdword,
					flag:word
				uses si, di
	.enter

	mov	dx, xTrans.high
	mov	cx, xTrans.low
	mov	bx, yTrans.high
	mov	ax, yTrans.low
	mov	si, flag
	mov	di, win
	call	WinApplyTranslationDWord

	.leave
	ret

WINAPPLYTRANSLATIONDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinTransform

C DECLARATION:	extern XYValueAsDWord
			_far _pascal WinTransform(WinHandle win,
						sword xCoord, sword yCoord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINTRANSFORM	proc	far
	clc
CWinTransCommon	label	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = win, ax = x, bx = y

	xchg	dx, di
	jc	untrans
	call	WinTransform
	jmp	common
untrans:
	call	WinUntransform
common:
	xchg	dx, di

	mov	dx, bx
	ret

WINTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinTransformDWord

C DECLARATION:	extern void
		    _far _pascal WinTransCoordWWFixed(WinHandle win,
				sdword xCoord, sdword yCoord,
				PointDWord _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINTRANSFORMDWORD	proc	far	win:hptr, xCoord:sdword,
					yCoord:sdword,
					deviceCoordinates:fptr
				uses si, di, es

	clc
CWinExtTransCommon	label	far

	.enter

	mov	dx, xCoord.high
	mov	cx, xCoord.low
	mov	bx, yCoord.high
	mov	ax, yCoord.low
	mov	di, win
	jc	untrans
	call	WinTransformDWord
	jmp	common
untrans:
	call	WinUntransformDWord
common:

	les	di, deviceCoordinates
	push	ax
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw
	pop	ax
	stosw
	mov_trash	ax, bx
	stosw

	.leave
	ret

WINTRANSFORMDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinUntransform

C DECLARATION:	extern XYValueAsDWord
			_far _pascal WinUntransform(WinHandle win,
						sword xCoord, sword yCoord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINUNTRANSFORM	proc	far
	stc
	jmp	CWinTransCommon

WINUNTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinUntransformDWord

C DECLARATION:	extern void
		    _far _pascal WinUnTransCoordWWFixed(WinHandle win,
				sdword xCoord, sdword yCoord,
				PointDWord _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINUNTRANSFORMDWORD	proc	far
	stc
	jmp	CWinExtTransCommon

WINUNTRANSFORMDWORD	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinSetTransform

C DECLARATION:	extern void
			_far _pascal WinSetTransform(WindowHandle win,
				const TransMatrix _far *tm, WinInvalFlag flag);
			Note: "tm" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINSETTRANSFORM	proc	far	win:hptr, tm:fptr, flag:word
					uses si, di, ds
	.enter

	mov	cx, flag
	lds	si, tm
	mov	di, win
	call	WinSetTransform

	.leave
	ret

WINSETTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinApplyTransform

C DECLARATION:	extern void
			_far _pascal WinApplyTransform(WindowHandle win,
				const TransMatrix _far *tm, WinInvalFlag flag);
			Note: "tm" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINAPPLYTRANSFORM	proc	far	win:hptr, tm:fptr, flag:word
					uses si, di, ds
	.enter

	mov	cx, flag
	lds	si, tm
	mov	di, win
	call	WinApplyTransform

	.leave
	ret

WINAPPLYTRANSFORM	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinSetNullTransform

C DECLARATION:	extern void
			_far _pascal WinSetNullTransform(WindowHandle win,
						WinInvalFlag flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINSETNULLTRANSFORM	proc	far
	C_GetTwoWordArgs	ax, cx,   dx,bx	;ax = gstate, cx = flag

	xchg	ax, di
	call	WinSetNullTransform
	xchg	ax, di
	ret

WINSETNULLTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGetTransform

C DECLARATION:	extern void
			_far _pascal WinGetTransform(WindowHandle win,
							TransMatrix _far *tm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
WINGETTRANSFORM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	dx, di
	xchg	ax, si
	call	WinGetTransform
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

WINGETTRANSFORM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinSetPtrImage

C DECLARATION:	extern void
	WinSetPtrImage(WindowHandle win, WinPtrImageLevel ptrLevel,
		       optr ptrCh);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	AMS	9/6/92		Now passed an optr (instead of
				separate Mem & Chunk handles)

------------------------------------------------------------------------------@
WINSETPTRIMAGE	proc	far	win:hptr, ptrLevel:word, ptrCh:optr
				uses	di, bp
	.enter
	movdw	cxdx, ptrCh
	mov	di, win
	mov	bp, ptrLevel
	call	WinSetPtrImage
	.leave
	ret

WINSETPTRIMAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeSetPtrImage

C DECLARATION:	extern void
	WinGeodeSetPtrImage(GeodeHandle gh, optr ptrCh);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	AMS	9/6/92		Now passed an optr (instead of
				separate Mem & Chunk handles)

------------------------------------------------------------------------------@
WINGEODESETPTRIMAGE	proc	far	gh:hptr, ptrCh:optr
	.enter
	mov	bx, gh
	movdw	cxdx, ptrCh
	call	WinGeodeSetPtrImage
	.leave
	ret

WINGEODESETPTRIMAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeGetInputObj

C DECLARATION:	extern optr
	WinGeodeGetInputObj(GeodeHandle gh);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@
WINGEODEGETINPUTOBJ	proc	far	gh:hptr
	.enter
	mov	bx, gh
	call	WinGeodeGetInputObj
	mov	ax, dx
	mov	dx, cx
	.leave
	ret

WINGEODEGETINPUTOBJ	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeSetInputObj

C DECLARATION:	extern void
	WinGeodeSetInputObj(GeodeHandle gh, optr iObj);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	AMS	9/6/92		Now passed an optr (instead of
				separate Mem & Chunk handles)

------------------------------------------------------------------------------@
WINGEODESETINPUTOBJ	proc	far	gh:hptr, iObj:optr
	.enter
	mov	bx, gh
	movdw	cxdx, iObj
	call	WinGeodeSetInputObj
	.leave
	ret

WINGEODESETINPUTOBJ	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeGetParentObj

C DECLARATION:	extern optr
	WinGeodeGetParentObj(GeodeHandle gh);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@
WINGEODEGETPARENTOBJ	proc	far	gh:hptr
	.enter
	mov	bx, gh
	call	WinGeodeGetParentObj
	mov	ax, dx
	mov	dx, cx
	.leave
	ret

WINGEODEGETPARENTOBJ	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeSetParentObj

C DECLARATION:	extern void
	WinGeodeSetParentObj(GeodeHandle gh, optr pObj);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	AMS	9/6/92		Now passed an optr (instead of
				separate Mem & Chunk handles)

------------------------------------------------------------------------------@
WINGEODESETPARENTOBJ	proc	far	gh:hptr, pObj:optr
	.enter
	mov	bx, gh
	movdw	cxdx, pObj
	call	WinGeodeSetParentObj
	.leave
	ret

WINGEODESETPARENTOBJ	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinGeodeSetActiveWin

C DECLARATION:	extern void
	WinGeodeSetActiveWin(GeodeHandle gh,
				WindowHandle win);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@
WINGEODESETACTIVEWIN	proc	far	gh:hptr, win:hptr
					uses di
	.enter
	mov	bx, gh
	mov	di, win
	call	WinGeodeSetActiveWin
	.leave
	ret

WINGEODESETACTIVEWIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	WinRealizePalette

C DECLARATION:	extern void
		WinRealizePalette(WindowHandle win);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/92		Initial version

------------------------------------------------------------------------------@
WINREALIZEPALETTE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = window

	xchg	ax, di
	call	WinRealizePalette
	xchg	ax, di
	ret
WINREALIZEPALETTE	endp

C_Graphics	ends


	SetDefaultConvention
