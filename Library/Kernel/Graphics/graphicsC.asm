COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the graphics.h

	$Id: graphicsC.asm,v 1.1 97/04/05 01:12:29 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention



C_Common	segment resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRect

C DECLARATION:	extern void
		    _far _pascal GrDrawRect(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWRECT	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrDrawRect

	.leave
	ret

GRDRAWRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRectTo

C DECLARATION:	extern void
			_far _pascal GrDrawRectTo(GStateHandle gstate,
							sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWRECTTO	proc	far	gstate:hptr.GState,
				x:sword,
				y:sword
		;uses di		;saves di in ax...
	.enter
		mov_tr	ax, di		;save di in ax
		mov	di, gstate
		mov	cx, x
		mov	dx, y
		call	GrFillRectTo
		mov_tr	di, ax		;restore di
	.leave
	ret

GRDRAWRECTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillRect

C DECLARATION:	extern void
		    _far _pascal GrFillRect(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLRECT	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrFillRect

	.leave
	ret

GRFILLRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillRectTo

C DECLARATION:	extern void
			_far _pascal GrFillRectTo(GStateHandle gstate,
							sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLRECTTO	proc	far	gstate:hptr.GState,
				x:sword,
				y:sword
		;uses di		;saves di in ax...
	.enter
		mov_tr	ax, di		;save di in ax
		mov	di, gstate
		mov	cx, x
		mov	dx, y
		call	GrFillRectTo
		mov_tr	di, ax		;restore di
	.leave
	ret

GRFILLRECTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCharWidth

C DECLARATION:	extern dword
			_far _pascal GrCharWidth(GStateHandle gstate, word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCHARWIDTH	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = gstate, ax = character

	push	di
	mov	di, bx
	call	GrCharWidth
	pop	di
	clr	al
	ret

GRCHARWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTextWidth

C DECLARATION:	extern word
		    _far _pascal GrTextWidth(GStateHandle gstate,
					const char _far *str, word size);
			Note: "str" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTEXTWIDTH	proc	far	gstate:hptr, pstr:fptr.char, ssize:word
				uses si, ds, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, pstr					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, pstr
	mov	di, gstate
	mov	cx, ssize
	call	GrTextWidth
	mov_trash	ax, dx

	.leave
	ret

GRTEXTWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetCharInfo

C DECLARATION:	extern CharInfo
		    _far _pascal GrGetCharInfo(GStateHandle gstate, word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/94		Initial version

------------------------------------------------------------------------------@
GRGETCHARINFO	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = gstate, ax = character

	push	di
	mov	di, bx
	call	GrGetCharInfo		; cl - flags
	pop	di
	clr	ax
	mov	al, cl			; return flags in AX
	ret

GRGETCHARINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTextWidthWWFixed

C DECLARATION:	extern dword
		    _far _pascal GrTextWidthWWFixed(GStateHandle gstate,
					const char _far *str, word size);
			Note: "str" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTEXTWIDTHWWFIXED	proc	far	gstate:hptr, pstr:fptr.char, ssize:word
				uses si, ds, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, pstr					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, pstr
	mov	di, gstate
	mov	cx, ssize
	call	GrTextWidthWBFixed
	clr	ah

	.leave
	ret

GRTEXTWIDTHWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRegion

C DECLARATION:	extern void
		    _far _pascal GrDrawRegion(GStateHandle gstate, sword xPos,
					sword yPos, const Region _far *reg,
					word cxParam, word dxParam);
			Note: "reg" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWREGION	proc	far	gstate:hptr, px:sword, py:sword, preg:fptr,
				cxParam:word, dxParam:word
				uses si, di, ds
	.enter

	mov	ax, px
	mov	bx, py
	mov	cx, cxParam
	mov	dx, dxParam
	lds	si, preg
	mov	di, gstate
	call	GrDrawRegion

	.leave
	ret

GRDRAWREGION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRegionAtCP

C DECLARATION:	extern void
		    _far _pascal GrDrawRegionAtCP(GStateHandle gstate,
					const Region _far *reg,
					word axParam, word bxParam,
					word cxParam, word dxParam);
			Note: "reg" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWREGIONATCP	proc	far	gstate:hptr, preg:fptr,
					axParam:word, bxParam:word,
					cxParam:word, dxParam:word
				uses si, di, ds
	.enter

	mov	ax, axParam
	mov	bx, bxParam
	mov	cx, cxParam
	mov	dx, dxParam
	lds	si, preg
	mov	di, gstate
	call	GrDrawRegionAtCP

	.leave
	ret

GRDRAWREGIONATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMulWWFixed

C DECLARATION:	extern WWFixedAsDWord
		    _far _pascal GrMulWWFixed(WWFixedAsDWord i,
							WWFixedAsDWord j);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMULWWFIXED	proc	far	ni:dword, nj:dword
	.enter

	mov	dx, ni.high
	mov	cx, ni.low
	mov	bx, nj.high
	mov	ax, nj.low
	call	GrMulWWFixed
	mov_trash	ax, cx

	.leave
	ret

GRMULWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMulDWFixed

C DECLARATION:	extern void
		    _far _pascal GrMulDWFixed(const DWFixed _far *i,
				const DWFixed _far *j, DWFixed _far *result);
			Note:The fptrs *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMULDWFIXED	proc	far	ni:fptr, nj:fptr, result:fptr
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ni					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, nj					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, ni
	les	di, nj
	call	GrMulDWFixed
	les	di, result
	mov_trash	ax, bx
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw

	.leave
	ret

GRMULDWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSDivWWFixed

C DECLARATION:	extern WWFixedAsDWord
		    _far _pascal GrSDivWWFixed(WWFixedAsDWord dividend,
						    WWFixedAsDWord divisor);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSDIVWWFIXED	proc	far	dividend:dword, divisor:dword
	.enter

	mov	dx, dividend.high
	mov	cx, dividend.low
	mov	bx, divisor.high
	mov	ax, divisor.low
	call	GrSDivWWFixed
	mov_trash	ax, cx
	jnc	done
	clr	ax
	clr	dx
done:

	.leave
	ret

GRSDIVWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUDivWWFixed

C DECLARATION:	extern WWFixedAsDWord
		    _far _pascal GrUDivWWFixed(WWFixedAsDWord dividend,
						    WWFixedAsDWord divisor);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRUDIVWWFIXED	proc	far	dividend:dword, divisor:dword
	.enter

	mov	dx, dividend.high
	mov	cx, dividend.low
	mov	bx, divisor.high
	mov	ax, divisor.low
	call	GrUDivWWFixed
	mov_trash	ax, cx
	jnc	done
	clr	ax
	clr	dx
done:

	.leave
	ret

GRUDIVWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSDivDWFbyWWF

C DECLARATION:	extern void
		    _far _pascal GrSDivDWFbyWWF(const DWFixed _far *dividend,
			const WWFixed _far *divisor, DWFixed _far *quotient);
			Note:The fptrs *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	4/92		Initial version

------------------------------------------------------------------------------@
GRSDIVDWFBYWWF	proc	far	dividend:fptr, divisor:fptr, quotient:fptr
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dividend					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, divisor					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, divisor
	mov	ax,ds:[si].WWF_frac
	mov	bx,ds:[si].WWF_int
	push	bp
	lds	si, dividend
	mov	bp,ds:[si].DWF_frac
	mov	cx,ds:[si].DWF_int.low
	mov	dx,ds:[si].DWF_int.high
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp
	les	di, quotient
	stosw
	mov_tr	ax, cx
	stosw
	mov_tr	ax, dx
	stosw

	.leave
	ret

GRSDIVDWFBYWWF	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCreateState

C DECLARATION:	extern GStateHandle
			_far _pascal GrCreateState(WindowHandle win);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCREATESTATE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = window

	xchg	ax, di
	call	GrCreateState
	xchg	ax, di
	ret

GRCREATESTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDestroyState

C DECLARATION:	extern void
			_far _pascal GrDestroyState(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDESTROYSTATE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = gstate

	xchg	ax, di
	call	GrDestroyState
	xchg	ax, di
	ret

GRDESTROYSTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSaveState

C DECLARATION:	extern void
			_far _pascal GrSaveState(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSAVESTATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrSaveState
	xchg	ax, di
	ret

GRSAVESTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrRestoreState

C DECLARATION:	extern void
			_far _pascal GrRestoreState(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRRESTORESTATE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrRestoreState
	xchg	ax, di
	ret

GRRESTORESTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSaveTransform

C DECLARATION:	extern void
			_far _pascal GrSaveTransform(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	11/92		Initial version

------------------------------------------------------------------------------@
GRSAVETRANSFORM	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrSaveTransform
	xchg	ax, di
	ret

GRSAVETRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrRestoreTransform

C DECLARATION:	extern void
			_far _pascal GrRestoreTransform(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	11/92		Initial version

------------------------------------------------------------------------------@
GRRESTORETRANSFORM	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrRestoreTransform
	xchg	ax, di
	ret

GRRESTORETRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawLine

C DECLARATION:	extern void
		    _far _pascal GrDrawLine(GStateHandle gstate, sword x1,
					sword y1, sword x2, sword y2);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWLINE	proc	far	gstate:hptr, x1:sword, y1:sword,
						x2:sword, y2:sword
				uses di
	.enter

	mov	ax, x1
	mov	bx, y1
	mov	cx, x2
	mov	dx, y2
	mov	di, gstate
	call	GrDrawLine

	.leave
	ret

GRDRAWLINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawLineTo

C DECLARATION:	extern void
			_far _pascal GrDrawLineTo(GStateHandle gstate,
							sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWLINETO	proc	far
	C_GetThreeWordArgs	ax, cx, dx,  bx	;ax = gstate, cx = x, dx = y

	xchg	ax, di
	call	GrDrawLineTo
	mov	di, ax
	ret

GRDRAWLINETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRelLineTo

C DECLARATION:	extern void
			_far _pascal GrDrawRelLineTo(GStateHandle gstate,
					WWFixedAsDWord x, WWFixedAsDWord y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/92		Initial version

------------------------------------------------------------------------------@
GRDRAWRELLINETO	proc	far	gstate:hptr, xoff:dword, yoff:dword
	uses	di
	.enter

	mov	cx, xoff.low
	mov	dx, xoff.high
	mov	ax, yoff.low
	mov	bx, yoff.high
	mov	di, gstate
	call	GrDrawRelLineTo
	.leave
	ret

GRDRAWRELLINETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawHLine

C DECLARATION:	extern void
		    _far _pascal GrDrawHLine(GStateHandle gstate, sword x1,
							sword y, sword x2);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWHLINE	proc	far	gstate:hptr, x1:sword, y1:sword, x2:sword
				uses di
	.enter

	mov	ax, x1
	mov	bx, y1
	mov	cx, x2
	mov	di, gstate
	call	GrDrawHLine

	.leave
	ret

GRDRAWHLINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawHLineTo

C DECLARATION:	extern void
			_far _pascal GrDrawHLineTo(GStateHandle gstate,
								sword x);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWHLINETO	proc	far
	C_GetTwoWordArgs	ax, cx,   bx,dx	;ax = gstate, cx = x

	xchg	ax, di
	call	GrDrawHLineTo
	xchg	ax, di
	ret

GRDRAWHLINETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawVLine

C DECLARATION:	extern void
		    _far _pascal GrDrawVLine(GStateHandle gstate, sword x,
							sword y1, sword y2);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWVLINE	proc	far	gstate:hptr, x1:sword, y1:sword, x2:sword
				uses di
	.enter

	mov	ax, x1
	mov	bx, y1
	mov	dx, x2
	mov	di, gstate
	call	GrDrawVLine

	.leave
	ret

GRDRAWVLINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawVLineTo

C DECLARATION:	extern void
			_far _pascal GrDrawVLineTo(GStateHandle gstate,
								sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWVLINETO	proc	far
	C_GetTwoWordArgs	ax, dx,   bx,cx	;ax = gstate, dx = y

	xchg	ax, di
	call	GrDrawVLineTo
	xchg	ax, di
	ret

GRDRAWVLINETO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
		    _far _pascal GrDrawImage(GStateHandle gstate, sword x,
			    sword y, ImageFlags flags, const Bitmap _far *bm);
			Note: "bm" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GRDRAWIMAGE	proc	far	gstate:hptr, px:sword, py:sword, flags:word,
				bm:fptr
	uses	si, di
	.enter

	mov	ax, px
	mov	bx, py
	mov	cx, flags
	mov	dx, bm.segment
	mov	si, bm.offset
	mov	di, gstate
	call	GrDrawImage

	.leave
	ret
GRDRAWIMAGE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawHugeImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
		    _far _pascal GrDrawHugeImage(GStateHandle gstate, sword x,
			    sword y, ImageFlags flags, VMFileHandle vmFile,
			    VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GRDRAWHUGEIMAGE	proc	far	gstate:hptr, px:sword, py:sword, flags:word,
				vmfile:word, vmblk:word
	uses	si, di
	.enter

	mov	ax, px
	mov	bx, py
	mov	cx, flags
	mov	dx, vmfile
	mov	si, vmblk
	mov	di, gstate
	call	GrDrawHugeImage

	.leave
	ret
GRDRAWHUGEIMAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawBitmap

C DECLARATION:	extern void
		    _far _pascal GrDrawBitmap(GStateHandle gstate, sword x,
			    sword y, const Bitmap _far *bm,
			    Bitmap _far * _far (*callback)(Bitmap _far *bm));
			Note: "bm" *cannot* be pointing to the XIP movable
				code resource.
			      "callback" must be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWBITMAP	proc	far	gstate:hptr, px:sword, py:sword, bm:fptr,
				callback:fptr.far
realDS	local	sptr
				uses si, di, ds
	.enter
		ForceRef	callback

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC < xipSafe:							>
EC <	popdw	bxsi						>
endif

	mov	realDS, ds
	push	ss:[TPD_error]
	mov	ss:[TPD_error], bp

	mov	ax, px
	mov	bx, py
	lds	si, bm
	mov	dx, SEGMENT_CS
	mov	cx, offset _GRDRAWBITMAP_callback
	mov	di, gstate
	call	GrDrawBitmap

	pop	ss:[TPD_error]

	.leave
	ret

GRDRAWBITMAP	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_GRDRAWBITMAP_callback

DESCRIPTION:	Callback routine for GRDRAWBITMAP.  Call the real callback
		after pushing args on the stack

CALLED BY:	GrDrawBitmap

PASS:
	ds:si - bitmap

RETURN:
	ds:si - next piece of the bitmap
	carry - set if completely drawn

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
			    Bitmap _far * _far (*callback)(Bitmap _far *bm));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_GRDRAWBITMAP_callback	proc	far	gstate:hptr, px:sword, py:sword,
					bm:fptr, callback:fptr.far
realDS	local	sptr
				uses ax, bx, cx, dx, di
	ForceRef	gstate
	ForceRef	px
	ForceRef	py
	ForceRef	bm
	.enter inherit far

	push	bp
	mov	bp, ss:[TPD_error]

	push	ds			;bm.segment
	push	si			;bm.offset

	mov	ax, callback.offset
	mov	bx, callback.segment
	mov	ds, realDS
	call	ProcCallFixedOrMovable

	; if NULL returned then return carry set

	tst	dx
	stc
	jz	common

	mov	ds, dx
	mov_trash	si, ax
	clc
common:

	pop	bp

	.leave
	ret

_GRDRAWBITMAP_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawBitmapAtCP

C DECLARATION:	extern void
		    _far _pascal GrDrawBitmapAtCP(GStateHandle gstate
			    const Bitmap _far *bm,
			    Bitmap _far * _far (*callback)(Bitmap _far *bm));
			Note: "bm" *cannot* be pointing to the XIP movable
				code resource.
			      "callback" must be vfptr for XIP.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@

	; NOTE: This routine works only because of some rather non-obvious
	;	stack goings-on

GRDRAWBITMAPATCP	proc	far	gstate:hptr, bm:fptr,
					callback:fptr.far
	ForceRef	callback
realDS	local	sptr
				uses si, di, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <	popdw	bxsi						>
endif

	mov	realDS, ds
	push	ss:[TPD_error]
	mov	ss:[TPD_error], bp

	lds	si, bm
	mov	dx, SEGMENT_CS
	mov	cx, offset _GRDRAWBITMAP_callback
	mov	di, gstate
	call	GrDrawBitmapAtCP

	pop	ss:[TPD_error]

	.leave
	ret

GRDRAWBITMAPATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillBitmap

C DECLARATION:	extern void
		    _far _pascal GrFillBitmap(GStateHandle gstate, sword x,
			    sword y, const Bitmap _far *bm,
			    Bitmap _far * _far (*callback)(Bitmap _far *bm));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/92		Initial version

------------------------------------------------------------------------------@
GRFILLBITMAP	proc	far	gstate:hptr, px:sword, py:sword, bm:fptr,
				callback:fptr.far
realDS	local	sptr
				uses si, di, ds
	.enter
	ForceRef	callback

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <	popdw	bxsi						>
endif

	mov	realDS, ds
	push	ss:[TPD_error]
	mov	ss:[TPD_error], bp

	mov	ax, px
	mov	bx, py
	lds	si, bm
	mov	dx, SEGMENT_CS
	mov	cx, offset _GRDRAWBITMAP_callback
	mov	di, gstate
	call	GrFillBitmap

	pop	ss:[TPD_error]

	.leave
	ret

GRFILLBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillBitmapAtCP

C DECLARATION:	extern void
		    _far _pascal GrFillBitmapAtCP(GStateHandle gstate
			    const Bitmap _far *bm,
			    Bitmap _far * _far (*callback)(Bitmap _far *bm));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/92		Initial version

------------------------------------------------------------------------------@

	; NOTE: This routine works only because of some rather non-obvious
	;	stack goings-on

GRFILLBITMAPATCP	proc	far	gstate:hptr, bm:fptr,
					callback:fptr.far
	ForceRef	callback
realDS	local	sptr
				uses si, di, ds
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC < xipSafe:								>
EC <	popdw	bxsi						>
endif

	mov	realDS, ds
	push	ss:[TPD_error]
	mov	ss:[TPD_error], bp

	lds	si, bm
	mov	dx, SEGMENT_CS
	mov	cx, offset _GRDRAWBITMAP_callback
	mov	di, gstate
	call	GrFillBitmapAtCP

	pop	ss:[TPD_error]

	.leave
	ret

GRFILLBITMAPATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawHugeBitmap

C DECLARATION:	extern void
		    _far _pascal GrDrawHugeBitmap(GStateHandle gstate, sword x,
			    sword y, VMFileHandle vmFile, VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/92		Initial version

------------------------------------------------------------------------------@
GRDRAWHUGEBITMAP proc	far	gstate:hptr, px:sword, py:sword, vmFile:hptr,
				vmBlk:hptr
        uses di
	.enter
	mov	ax, px
	mov	bx, py
	mov	dx, vmFile
	mov	cx, vmBlk
	mov	di, gstate
	call	GrDrawHugeBitmap
	.leave
	ret

GRDRAWHUGEBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawHugeBitmapAtCP

C DECLARATION:	extern void
		    _far _pascal GrDrawHugeBitmapAtCP(GStateHandle gstate,
			    VMFileHandle vmFile, VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/92		Initial version

------------------------------------------------------------------------------@
GRDRAWHUGEBITMAPATCP proc	far	gstate:hptr,  vmFile:hptr, vmBlk:hptr
        uses di
	.enter
	mov	dx, vmFile
	mov	cx, vmBlk
	mov	di, gstate
	call	GrDrawHugeBitmapAtCP
	.leave
	ret

GRDRAWHUGEBITMAPATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillHugeBitmap

C DECLARATION:	extern void
		    _far _pascal GrFillHugeBitmap(GStateHandle gstate, sword x,
			    sword y, VMFileHandle vmFile, VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/92		Initial version

------------------------------------------------------------------------------@
GRFILLHUGEBITMAP proc	far	gstate:hptr, px:sword, py:sword, vmFile:hptr,
				vmBlk:hptr
        uses di
	.enter
	mov	ax, px
	mov	bx, py
	mov	dx, vmFile
	mov	cx, vmBlk
	mov	di, gstate
	call	GrFillHugeBitmap
	.leave
	ret

GRFILLHUGEBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawHugeBitmapAtCP

C DECLARATION:	extern void
		    _far _pascal GrFillHugeBitmapAtCP(GStateHandle gstate,
			    VMFileHandle vmFile, VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/92		Initial version

------------------------------------------------------------------------------@
GRFILLHUGEBITMAPATCP proc	far	gstate:hptr,  vmFile:hptr, vmBlk:hptr
        uses di
	.enter
	mov	dx, vmFile
	mov	cx, vmBlk
	mov	di, gstate
	call	GrFillHugeBitmapAtCP
	.leave
	ret

GRFILLHUGEBITMAPATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetMixMode

C DECLARATION:	extern void
			_far _pascal GrSetMixMode(GStateHandle gstate,
							MixMode mode);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETMIXMODE	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = gstate, ax = mode

	push	di
	mov	di, bx
	call	GrSetMixMode
	pop	di
	ret

GRSETMIXMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrRelMoveTo

C DECLARATION:	extern void
			_far _pascal GrRelMoveTo(GStateHandle gstate,
					WWFixedAsDWord x, WWFixedAsDWord y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/92		Initial version

------------------------------------------------------------------------------@
GRRELMOVETO	proc	far	gstate:hptr, xoff:dword, yoff:dword
	uses	di
	.enter
	mov	cx, xoff.low
	mov	dx, xoff.high
	mov	ax, yoff.low
	mov	bx, yoff.high
	mov	di, gstate
	call	GrRelMoveTo
	.leave
	ret

GRRELMOVETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMoveTo

C DECLARATION:	extern void
			_far _pascal GrMoveTo(GStateHandle gstate,
							sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMOVETO	proc	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = gs, ax = x, bx = y

	xchg	dx, di
	call	GrMoveTo
	xchg	dx, di
	ret

GRMOVETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMoveToWWFixed

C DECLARATION:	extern void
		    _far _pascal GrMoveToWWFixed(GStateHandle gstate,
				WWFixedAsDWord xPos, WWFixedAsDWord yPos);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	-------		-----------
	JimG	6/21/94		Initial version

------------------------------------------------------------------------------@
GRMOVETOWWFIXED	proc	far	gstate:hptr, xPos:sdword, yPos:sdword
				uses di
	.enter

	movwwf	dxcx, xPos
	movwwf	bxax, yPos
	mov	di, gstate
	call	GrMoveToWWFixed

	.leave
	ret

GRMOVETOWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineColor

C DECLARATION:	extern void
		    _far _pascal GrSetLineColor(GStateHandle gstate,
					ColorFlag flag, word redOrIndex,
					word green, word blue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINECOLOR	proc	far	gstate:hptr, flag:word, redOrIndex:word,
				green:word, blue:word
				uses di
	.enter

	mov	ah, flag.low
	mov	al, redOrIndex.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	di, gstate
	call	GrSetLineColor

	.leave
	ret

GRSETLINECOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineMaskSys

C DECLARATION:	extern void
			_far _pascal GrSetLineMaskSys(GStateHandle gstate,
							word sysDM);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINEMASKSYS	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = sysDM

	xchg	dx, di
	call	GrSetLineMask
	xchg	dx, di
	ret

GRSETLINEMASKSYS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineMaskCustom

C DECLARATION:	extern void
			_far _pascal GrSetLineMaskCustom(GStateHandle gstate,
						const DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINEMASKCUSTOM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	xchg	dx, di
	mov	al, SDM_CUSTOM
	call	GrSetLineMask
	xchg	dx, di
	pop	si, ds
	ret

GRSETLINEMASKCUSTOM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineColorMap

C DECLARATION:	extern void
			_far _pascal GrSetLineColorMap(GStateHandle gstate,
							word colorMap);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINECOLORMAP	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = colorMap

	xchg	dx, di
	call	GrSetLineColorMap
	xchg	dx, di
	ret

GRSETLINECOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineWidth

C DECLARATION:	extern void
			_far _pascal GrSetLineWidth(GStateHandle gstate,
							WWFixedAsDWord width);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jim	4/92		Updated for WWFixed arg

------------------------------------------------------------------------------@
GRSETLINEWIDTH	proc	far
	C_GetThreeWordArgs	bx, dx, ax   ,cx ; bx = gs, dx.ax = width

	xchg	bx, di
	call	GrSetLineWidth
	xchg	bx, di
	ret

GRSETLINEWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineJoin

C DECLARATION:	extern void
			_far _pascal GrSetLineJoin(GStateHandle gstate,
							LineJoin join);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINEJOIN	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = join

	xchg	dx, di
	call	GrSetLineJoin
	xchg	dx, di
	ret

GRSETLINEJOIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineEnd

C DECLARATION:	extern void
			_far _pascal GrSetLineEnd(GStateHandle gstate,
							LineEnd end);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINEEND	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = end

	xchg	dx, di
	call	GrSetLineEnd
	xchg	dx, di
	ret

GRSETLINEEND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetMiterLimit

C DECLARATION:	extern void
			_far _pascal GrSetMiterLimit(GStateHandle gstate,
							WWFixedAsDWord limit);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETMITERLIMIT	proc	far
	C_GetThreeWordArgs	dx, bx, ax,  cx	;dx = gs, bx.ax = limit

	xchg	dx, di
	call	GrSetMiterLimit
	xchg	dx, di
	ret

GRSETMITERLIMIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineStyle

C DECLARATION:	extern void
		    _far _pascal GrSetLineStyle(GStateHandle gstate,
					LineStyle style, word skipDistance,
					const DashPairArray _far *dpa,
					word numPairs);
			Note: "dpa" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETLINESTYLE	proc	far	gstate:hptr, style:word, skipDistance:word,
				dpa:fptr, numPairs:word
				uses si, di, ds
	.enter

	mov	al, style.low
	mov	ah, numPairs.low
	mov	bl, skipDistance.low
	lds	si, dpa
	mov	di, gstate
	call	GrSetLineStyle

	.leave
	ret

GRSETLINESTYLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaColor

C DECLARATION:	extern void
		    _far _pascal GrSetAreaColor(GStateHandle gstate,
					ColorFlag flag, word redOrIndex,
					word green, word blue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETAREACOLOR	proc	far	gstate:hptr, flag:word, redOrIndex:word,
				green:word, blue:word
				uses di
	.enter

	mov	ah, flag.low
	mov	al, redOrIndex.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	di, gstate
	call	GrSetAreaColor

	.leave
	ret

GRSETAREACOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaMaskSys

C DECLARATION:	extern void
			_far _pascal GrSetAreaMaskSys(GStateHandle gstate,
							word sysDM);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETAREAMASKSYS	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = sysDM

	xchg	dx, di
	call	GrSetAreaMask
	xchg	dx, di
	ret

GRSETAREAMASKSYS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaMaskCustom

C DECLARATION:	extern void
			_far _pascal GrSetAreaMaskCustom(GStateHandle gstate,
						const DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETAREAMASKCUSTOM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	xchg	dx, di
	mov	al, SDM_CUSTOM
	call	GrSetAreaMask
	xchg	dx, di
	pop	si, ds
	ret

GRSETAREAMASKCUSTOM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaColorMap

C DECLARATION:	extern void
			_far _pascal GrSetAreaColorMap(GStateHandle gstate,
							word colorMap);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETAREACOLORMAP	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = colorMap

	xchg	dx, di
	call	GrSetAreaColorMap
	xchg	dx, di
	ret

GRSETAREACOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextColor

C DECLARATION:	extern void
		    _far _pascal GrSetTextColor(GStateHandle gstate,
					ColorFlag flag, word redOrIndex,
					word green, word blue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTCOLOR	proc	far	gstate:hptr, flag:word, redOrIndex:word,
				green:word, blue:word
				uses di
	.enter

	mov	ah, flag.low
	mov	al, redOrIndex.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	di, gstate
	call	GrSetTextColor

	.leave
	ret

GRSETTEXTCOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextMaskSys

C DECLARATION:	extern void
			_far _pascal GrSetTextMaskSys(GStateHandle gstate,
							word sysDM);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTMASKSYS	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = sysDM

	xchg	dx, di
	call	GrSetTextMask
	xchg	dx, di
	ret

GRSETTEXTMASKSYS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextMaskCustom

C DECLARATION:	extern void
			_far _pascal GrSetTextMaskCustom(GStateHandle gstate,
						const DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTMASKCUSTOM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	xchg	dx, di
	mov	al, SDM_CUSTOM
	call	GrSetTextMask
	xchg	dx, di
	pop	si, ds
	ret

GRSETTEXTMASKCUSTOM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextColorMap

C DECLARATION:	extern void
			_far _pascal GrSetTextColorMap(GStateHandle gstate,
							word colorMap);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTCOLORMAP	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = colorMap

	xchg	dx, di
	call	GrSetTextColorMap
	xchg	dx, di
	ret

GRSETTEXTCOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextStyle

C DECLARATION:	extern void
			_far _pascal GrSetTextStyle(GStateHandle gstate,
					word bitsToSet, word bitsToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTSTYLE	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = gs, ax = bS, cx = bC

	mov	ah, cl
	xchg	bx, di
	call	GrSetTextStyle
	xchg	bx, di
	ret

GRSETTEXTSTYLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextMode

C DECLARATION:	extern void
			_far _pascal GrSetTextMode(GStateHandle gstate,
					word bitsToSet, word bitsToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTMODE	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = gs, ax = bS, cx = bC

	mov	ah, cl
	xchg	bx, di
	call	GrSetTextMode
	xchg	bx, di
	ret

GRSETTEXTMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextDirection

C DECLARATION:	extern void
			_far _pascal GrSetTextDirection(GStateHandle gstate,
					TextDirection direction);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	les	02/12/02	Initial version.

------------------------------------------------------------------------------@
if SIMPLE_RTL_SUPPORT
GRSETTEXTDIRECTION	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, al = dir

	xchg	dx, di
	call	GrSetTextDirection
	xchg	dx, di
	ret
GRSETTEXTDIRECTION	endp
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextDrawOffset

C DECLARATION:	extern void
			_pascal GrSetTextDrawOffset(GStateHandle gstate,
							 word numToDraw);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/93		Initial version

------------------------------------------------------------------------------@
GRSETTEXTDRAWOFFSET	proc	far
	C_GetTwoWordArgs	bx,ax,  cx,dx	;bx = gstate, ax = numToDraw

	xchg	bx, di			; di <- gstate
	call	GrSetTextDrawOffset
	xchg	bx, di
	ret

GRSETTEXTDRAWOFFSET	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextSpacePad

C DECLARATION:	extern void
			_far _pascal GrSetTextSpacePad(GStateHandle gstate,
					WWFixedAsDWord padding);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTSPACEPAD	proc	far
	C_GetThreeWordArgs	ax, dx, bx,  cx	;bx = gs, dx.bx = pad

	mov	bl, bh
	xchg	ax, di
	call	GrSetTextSpacePad
	xchg	ax, di
	ret

GRSETTEXTSPACEPAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextAttr

C DECLARATION:	extern void
			_far _pascal GrSetTextAttr(GStateHandle gstate,
						    const TextAttr _far *ta);
			Note: "ta" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTEXTATTR	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrSetTextAttr
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRSETTEXTATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetFont

C DECLARATION:	extern void
		    _far _pascal GrSetFont(GStateHandle gstate, FontID id,
						WWFixedAsDWord pointSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETFONT	proc	far	gstate:hptr, fid:word, pointSize:dword
				uses di
	.enter

	mov	dx, pointSize.high
	mov	ah, (pointSize.low).high
	mov	cx, fid
	mov	di, gstate
	call	GrSetFont

	.leave
	ret

GRSETFONT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetClipRect

C DECLARATION:	extern void
		    _far _pascal GrSetClipRect(GStateHandle gstate, word flags,
						sword left, sword top,
						sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETCLIPRECT	proc	far	gstate:hptr, flags:word, left:sword, top:sword,
						right:sword, bottom:sword
	uses si, di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	si, flags
	mov	di, gstate
	call	GrSetClipRect

	.leave
	ret

GRSETCLIPRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetWinClipRect

C DECLARATION:	extern void
		    _far _pascal GrSetWinClipRect(GStateHandle gstate,
						word flags,
						sword left, sword top,
						sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETWINCLIPRECT	proc	far	gstate:hptr, flags:word, left:sword,
					top:sword, right:sword, bottom:sword
	uses si, di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	si, flags
	mov	di, gstate
	call	GrSetWinClipRect

	.leave
	ret

GRSETWINCLIPRECT	endp

C_Common	ends

;---

C_Graphics	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPoint

C DECLARATION:	extern RGBColorAsDWord
		    _far _pascal GrGetPoint(GStateHandle gstate, sword x,
								 sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/92		Initial version

------------------------------------------------------------------------------@
GRGETPOINT	proc	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = gs, ax = x, bx = y

	xchg	di, dx		; save di
	call	GrGetPoint
	xchg	di, dx		; restore di
	xchg	ah, bl		; ah <- green, bl <- index
	xchg	bl, bh		; bh <- index  bl <- blue
				; dxax now set up as RGBColorAsDWord
	ret

GRGETPOINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetBitmap

C DECLARATION:	extern MemHandle
		    _far _pascal GrGetBitmap(GStateHandle gstate, sword x,
						sword y, word width,
						word height,
						XYSize _far *sizeCopied);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETBITMAP	proc	far	gstate:hptr, px:sword, py:sword, bwidth:word,
				bheight:word, sizeCopied:fptr.XYSize
				uses di, ds
	.enter

	mov	ax, px
	mov	bx, py
	mov	cx, bwidth
	mov	dx, bheight
	mov	di, gstate
	call	GrGetBitmap
	lds	di, sizeCopied
	mov	ds:[di].XYS_width, cx
	mov	ds:[di].XYS_height, dx
	mov_trash	ax, bx

	.leave
	ret

GRGETBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCreateBitmap

C DECLARATION:	extern VMBlockHandle
		    _far _pascal GrCreateBitmap(BMFormat initFormat,
					word initWidth, word initHeight,
					VMFileHandle vmFile,
					MemHandle exposureODHan,
					ChunkHandle exposureODCh,
					GStateHandle _far *bmgs);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Jim	1/92		Fixed for new GrCreateBitmap

------------------------------------------------------------------------------@
GRCREATEBITMAP	proc	far	initFormat:word, initWidth:word,
				initHeight:word, vmFile:word,
				exposureODHan:hptr, exposureODCh:word,
				bmgs:fptr
					uses si, di, ds
	.enter

	mov	al, initFormat.low
	mov	cx, initWidth
	mov	dx, initHeight
	mov	bx, vmFile
	mov	di, exposureODHan
	mov	si, exposureODCh
	call	GrCreateBitmap

	lds	si, bmgs
	mov	ds:[si], di

	.leave
	ret

GRCREATEBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCreateBitmapRaw

C DECLARATION:	extern VMBlockHandle
		    _far _pascal GrCreateBitmapRaw(BMFormat initFormat,
					word initWidth, word initHeight,
					VMFileHandle vmFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mg	12/00		Initial version

------------------------------------------------------------------------------@
GRCREATEBITMAPRAW	proc	far	initFormat:word, initWidth:word,
				initHeight:word, vmFile:word
	.enter

	mov	al, initFormat.low
	mov	cx, initWidth
	mov	dx, initHeight
	mov	bx, vmFile
	call	GrCreateBitmapRaw

	.leave
	ret

GRCREATEBITMAPRAW	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEditBitmap

C DECLARATION:	extern GStateHandle
		    _far _pascal GrCreateBitmap(VMFileHandle vmFile,
					VMBlockHandle vmBlock,
					MemHandle exposureODHan,
					ChunkHandle exposureODCh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/92		Initial version

------------------------------------------------------------------------------@
GREDITBITMAP	proc	far	vmFile:word, vmBlock:word,
				exposureODHan:hptr, exposureODCh:word
					uses si, di
	.enter

	mov	bx, vmFile
	mov	ax, vmBlock
	mov	di, exposureODHan
	mov	si, exposureODCh
	call	GrEditBitmap
	mov	ax, di			; return handle in ax

	.leave
	ret

GREDITBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDestroyBitmap

C DECLARATION:	extern void
			_far _pascal GrDestroyBitmap(GStateHandle gstate,
						     word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Jim	1/92		Fixed for new GrDestroyBitmap

------------------------------------------------------------------------------@
GRDESTROYBITMAP	proc	far
	C_GetTwoWordArgs	bx,ax,  cx,dx	;bx = gs, ax = flags

	xchg	bx, di
	call	GrDestroyBitmap
	xchg	bx, di
	ret

GRDESTROYBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetBitmapMode

C DECLARATION:	extern void
			_far _pascal GrSetBitmapMode(GStateHandle gstate,
						     word flags,
						     MemHandle colorCorr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/92		Initial version

------------------------------------------------------------------------------@
GRSETBITMAPMODE		proc	far
	C_GetThreeWordArgs	bx,ax,dx,  cx	;bx = gs, ax = flags, dx=hptr

	xchg	bx, di
	call	GrSetBitmapMode
	xchg	bx, di
	ret

GRSETBITMAPMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetBitmapMode

C DECLARATION:	extern word
			_far _pascal GrGetBitmapMode(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/92		Initial version

------------------------------------------------------------------------------@
GRGETBITMAPMODE		proc	far
	C_GetOneWordArg	bx,   dx,cx	;ax = gstate

	xchg	bx, di
	call	GrGetBitmapMode
	xchg	bx, di
	ret

GRGETBITMAPMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetBitmapRes

C DECLARATION:	extern void
			_far _pascal GrSetBitmapRes(GStateHandle gstate,
							word xRes, word yRes);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETBITMAPRES	proc	far
	C_GetThreeWordArgs	dx, ax, bx, cx	; dx=gs, ax-xres, bx=yres

	xchg	dx, di
	call	GrSetBitmapRes
	xchg	dx, di

	.leave
	ret

GRSETBITMAPRES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetBitmapRes

C DECLARATION:	extern XYValueAsDWord
			_far _pascal GrGetBitmapRes(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETBITMAPRES	proc	far
	C_GetOneWordArg	dx,    ax,cx	; dx = gstate

	xchg	dx, di
	call	GrGetBitmapRes
	xchg	dx, di
	mov	dx, bx

	ret

GRGETBITMAPRES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrClearBitmap

C DECLARATION:	extern void
			_far _pascal GrClearBitmap(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCLEARBITMAP	proc	far gstate:hptr
	uses	di
	.enter
	mov	di, gstate
	call	GrClearBitmap
	.leave
	ret

GRCLEARBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCompactBitmap

C DECLARATION:	extern VMBlockHandle
		    _far _pascal GrCompactBitmap(VMFileHandle srcFile,
					VMBlockHandle srcBlock,
					VMFileHandle destFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

------------------------------------------------------------------------------@
GRCOMPACTBITMAP	proc	far	srcFile:word, srcBlock:word,destFile:word
	.enter

	mov	bx, srcFile
	mov	ax, srcBlock
	mov	dx, destFile
	call	GrCompactBitmap
	mov	ax, cx			; return handle in ax

	.leave
	ret

GRCOMPACTBITMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUncompactBitmap

C DECLARATION:	extern VMBlockHandle
		    _far _pascal GrUncompactBitmap(VMFileHandle srcFile,
					VMBlockHandle srcBlock,
					VMFileHandle destFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

------------------------------------------------------------------------------@
GRUNCOMPACTBITMAP proc	far	srcFile:word, srcBlock:word,destFile:word
	.enter

	mov	bx, srcFile
	mov	ax, srcBlock
	mov	dx, destFile
	call	GrUncompactBitmap
	mov	ax, cx			; return handle in ax

	.leave
	ret

GRUNCOMPACTBITMAP endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetHugeBitmapSize

C DECLARATION:	extern XYValueAsDWord
	    _far _pascal GrGetHugeBitmapSize(VMFileHandle vmFile, VMBlockHandle vmBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	3/93		Initial version

------------------------------------------------------------------------------@
GRGETHUGEBITMAPSIZE proc far	vmFile:hptr, vmBlk:hptr
        uses di
	.enter

	mov	bx, vmFile
	mov	di, vmBlk
	call	GrGetHugeBitmapSize
	mov	dx,bx

	.leave
	ret

GRGETHUGEBITMAPSIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetBitmapSize

C DECLARATION:	extern XYValueAsDWord
			_far _pascal GrGetBitmapSize(const Bitmap _far *bm);
			Note: "bm" *cannot* be pointing to the XIP code
				resource.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETBITMAPSIZE	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	call	GrGetBitmapSize
	mov	dx, bx
	pop	si, ds

	ret

GRGETBITMAPSIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMoveReg

C DECLARATION:	extern void
		    _far _pascal GrMoveReg(Region _far *reg, sword xOffset,
							sword yOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMOVEREG	proc	far	preg:fptr, xOffset:sword, yOffset:sword
					uses si, ds
	.enter

	mov	cx, xOffset
	mov	dx, yOffset
	lds	si, preg
	call	GrMoveReg

	.leave
	ret

GRMOVEREG	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPtrRegBounds

C DECLARATION:	extern word
		    _far _pascal GrGetPtrRegBounds(const Region _far *reg,
						Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETPTRREGBOUNDS	proc	far	preg:fptr, bounds:fptr
				uses si, di, ds, es
	.enter

	lds	si, preg
	call	GrGetPtrRegBounds
	les	di, bounds
	stosw
	mov_trash	ax, bx
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw

	sub	si, preg.offset
	mov_trash	ax, si

	.leave
	ret

GRGETPTRREGBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestPointInReg

C DECLARATION:	extern Boolean
		    _far _pascal GrTestPointInReg(const Region _far *reg,
						word xPos, word yPos,
						Rectangle *boundingRect);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTESTPOINTINREG	proc	far	preg:fptr, xPos:sword, yPos:sword,
					boundingRect:fptr
				uses si, ds
	.enter

	mov	cx, xPos
	mov	dx, yPos
	lds	si, preg
	call	GrTestPointInReg
	push	ds:[si-2]		;right
	push	ds:[si-4]		;left
	lds	si, boundingRect
	pop	ds:[si].R_left
	pop	ds:[si].R_right
	mov	ds:[si].R_top, ax
	mov	ds:[si].R_bottom, bx

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

GRTESTPOINTINREG	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestRectInReg

C DECLARATION:	extern TestRectReturnType
		    _far _pascal GrTestRectInReg(const Region _far *reg,
						sword left, sword top,
						sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTESTRECTINREG	proc	far	preg:fptr, left:sword, top:sword,
				right:sword, bottom:sword
				uses si, ds
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	lds	si, preg
	clc
	call	GrTestRectInReg
	clr	ah

	.leave
	ret

GRTESTRECTINREG	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestRectInMask

C DECLARATION:	extern TestRectReturnType
		    _far _pascal GrTestRectInMask(GStateHandle gstate,
						sword left, sword top,
						sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/92		Initial version

------------------------------------------------------------------------------@
GRTESTRECTINMASK	proc	far	gstate:hptr, left:sword, top:sword,
					right:sword, bottom:sword
	uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrTestRectInMask
	clr	ah

	.leave
	ret

GRTESTRECTINMASK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSqrRootWWFixed

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrSqrRootWWFixed(WWFixedAsDWord i);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSQRROOTWWFIXED	proc	far
	C_GetOneDWordArg	dx, cx,   ax,bx	;dx = high, cx = low

	call	GrSqrRootWWFixed
	mov_trash	ax, cx
	ret

GRSQRROOTWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrQuickSine

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrQuickSine(WWFixedAsDWord angle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRQUICKSINE	proc	far
	C_GetOneDWordArg	dx, ax,   cx,bx	;dx = high, ax = low

	call	GrQuickSine
	ret

GRQUICKSINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrQuickCosine

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrQuickCosine(WWFixedAsDWord angle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRQUICKCOSINE	proc	far
	C_GetOneDWordArg	dx, ax,   cx,bx	;dx = high, ax = low

	call	GrQuickCosine
	ret

GRQUICKCOSINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrQuickTangent

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrQuickTangent(WWFixedAsDWord angle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/91		Initial version

------------------------------------------------------------------------------@
GRQUICKTANGENT	proc	far
	C_GetOneDWordArg	dx, ax,   cx,bx	;dx = high, ax = low

	call	GrQuickTangent
	ret

GRQUICKTANGENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrQuickArcSine

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrQuickArcSine(
					WWFixedAsDWord deltaYDivDistance,
					word origDeltaX);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRQUICKARCSINE	proc	far
	C_GetThreeWordArgs	dx, cx, bx,  ax	;dx.cx = deltaYDiv, bx = orig

	call	GrQuickArcSine
	mov_trash	ax, cx
	ret

GRQUICKARCSINE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetVMFile

C DECLARATION:	extern void
			_far _pascal GrSetVMFile(GStateHandle gstate,
						VMFileHandle vmFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/95		Initial version

------------------------------------------------------------------------------@
GRSETVMFILE	proc	far
	C_GetTwoWordArgs	dx,ax, 	bx,cx	;AX <- VM file handle
						;DX <- GState handle

	xchg	di, dx
	call	GrSetVMFile
	xchg	di, dx
	ret

GRSETVMFILE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetExclusive

C DECLARATION:	extern void
			_far _pascal GrGetExclusive(GeodeHandle videoDriver);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETEXCLUSIVE	proc	far
	C_GetOneWordArg		bx, 	ax,dx	;BX <- video driver

	call	GrGetExclusive			;
	mov_tr	ax,bx				;AX <- gstate with exclusive
	ret

GRGETEXCLUSIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGrabExclusive

C DECLARATION:	extern void
			_far _pascal GrGrabExclusive(GeodeHandle videoDriver,
					GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGRABEXCLUSIVE	proc	far
	C_GetTwoWordArgs	bx, cx,  ax, dx	;bx = video, cx = gs

	xchg	cx, di		;DI <- gstate, cx = old DI value
	call	GrGrabExclusive
	xchg	cx, di		;Restore old DI value
	ret

GRGRABEXCLUSIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrReleaseExclusive

C DECLARATION:	extern void
			_far _pascal GrReleaseExclusive(GeodeHandle videoDriver, GeodeHandle gstate, Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Jim	11/92		Changed to return bounds

------------------------------------------------------------------------------@
GRRELEASEEXCLUSIVE	proc	far	videoDriver:hptr, gstate:hptr, bounds:fptr
	uses	ds, si, di
	.enter

	mov	bx, videoDriver
	mov	di, gstate
	call	GrReleaseExclusive
	lds	si, bounds
	mov	ds:[si].R_left, ax	; store bounds
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx

	.leave
	ret

GRRELEASEEXCLUSIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTransformWWFixed

C DECLARATION:	extern void
		    _far _pascal GrTransformWWFixed(GStateHandle gstate,
				WWFixedAsDWord xPos, WWFixedAsDWord yPos,
				PointWWFixed _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTRANSFORMWWFIXED	proc	far	gstate:hptr, xPos:sdword, yPos:sdword,
					deviceCoordinates:fptr
				uses si, di, es
routineToCall	local	fptr

	mov	ax, offset GrTransformWWFixed
CTransWWCommon	label	far

	.enter

	mov	routineToCall.offset, ax
	mov	ax, segment GrTransformWWFixed
	mov	routineToCall.segment, ax

	mov	dx, xPos.high
	mov	cx, xPos.low
	mov	bx, yPos.high
	mov	ax, yPos.low
	mov	di, gstate
	call	routineToCall

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

GRTRANSFORMWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTransformDWFixed

C DECLARATION:	extern void
			_far _pascal GrTransformDWFixed(GStateHandle gstate,
						PointDWFixed _far *coord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTRANSFORMDWFIXED	proc	far
	clc
CTransDWCommon	label	far
	C_GetThreeWordArgs	ax, cx, dx,  bx	;ax = gs, cx = seg, dx = off

	push	es
	mov	es, cx
	xchg	ax, di
	jc	untrans
	call	GrTransformDWFixed
	jmp	common
untrans:
	call	GrUntransformDWFixed
common:
	xchg	ax, di
	pop	es
	ret

GRTRANSFORMDWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUntransformWWFixed

C DECLARATION:	extern void
		    _far _pascal GrUntransformWWFixed(GStateHandle gstate,
				WWFixedAsDWord xPos, WWFixedAsDWord yPos,
				PointWWFixed _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRUNTRANSFORMWWFIXED	proc	far
	mov	ax, offset GrUntransformWWFixed
	jmp	CTransWWCommon
	.assert	(seg GrTransformWWFixed) eq (seg GrUntransformWWFixed)

GRUNTRANSFORMWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUntransformDWFixed

C DECLARATION:	extern void
			_far _pascal GrUntransformDWFixed(GStateHandle gstate,
						PointDWFixed _far *coord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRUNTRANSFORMDWFIXED	proc	far
	stc
	jmp	CTransDWCommon

GRUNTRANSFORMDWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrBitBlt

C DECLARATION:	extern void
		    _far _pascal GrBitBlt(GStateHandle gstate, sword sourceX,
						sword sourceY, sword destX,
						sword destY, word width,
						word height, BLTMode mode);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRBITBLT	proc	far	gstate:hptr, sourceX:sword, sourceY:sword,
				destX:sword, destY:sword, bwidth:word,
				bheight:word, bmode:word
				uses si, di
	.enter

	mov	ax, sourceX
	mov	bx, sourceY
	mov	cx, destX
	mov	dx, destY
	mov	si, bwidth
	mov	di, gstate
	push	bheight
	push	bmode
	call	GrBitBlt

	.leave
	ret

GRBITBLT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTransform

C DECLARATION:	extern XYValueAsDWord
			_far _pascal GrTransform(GStateHandle gstate,
						sword xCoord, sword yCoord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTRANSFORM	proc	far
	clc
CTransCommon	label	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = gs, ax = x, bx = y

	xchg	dx, di
	jc	untrans
	call	GrTransform
	jmp	common

untrans:
	call	GrUntransform
common:
	xchg	dx, di
	jc	commonError
	mov	dx, bx
	ret

commonError:
	mov	ax, 0x8000
	mov	dx, ax
	ret
GRTRANSFORM	endp

COMMENT @----------------------------------------------------------------------
n
C FUNCTION:	GrTransformDWord

C DECLARATION:	extern void
		    _far _pascal GrTransformWWFixed(GStateHandle gstate,
				sdword xCoord, sdword yCoord,
				PointDWord _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTRANSFORMDWORD	proc	far
	mov	ax, offset GrTransformDWord
	jmp	CTransWWCommon
	.assert	(seg GrTransformWWFixed) eq (seg GrTransformDWord)

GRTRANSFORMDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUntransform

C DECLARATION:	extern XYValueAsDWord
			_far _pascal GrUntransform(GStateHandle gstate,
						sword xCoord, sword yCoord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRUNTRANSFORM	proc	far
	stc
	jmp	CTransCommon

GRUNTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrUntransformDWord

C DECLARATION:	extern void
		    _far _pascal GrUntransformWWFixed(GStateHandle gstate,
				sdword xCoord, sdword yCoord,
				PointDWord _far *deviceCoordinates);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRUNTRANSFORMDWORD	proc	far
	mov	ax, offset GrUntransformDWord
	jmp	CTransWWCommon
	.assert	(seg GrTransformWWFixed) eq (seg GrUntransformDWord)

GRUNTRANSFORMDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMapColorIndex

C DECLARATION:	extern RGBColorAsDWord
			_far _pascal GrMapColorIndex(GStateHandle gstate,
								Color c);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMAPCOLORINDEX	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gstate, ax = character

	xchg	dx, di			; save di
	mov	ah, al
	call	GrMapColorIndex
	xchg	dx, di			; restore di

	mov	dh, ah			; dh = index
	mov	dl, bh			; dl = blue
	mov	ah, bl			; ah = green
	ret				; al = red

GRMAPCOLORINDEX	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrMapColorRGB

C DECLARATION:	extern RGBColorAsDWord
		    _far _pascal GrMapColorRGB(GStateHandle gstate, word red,
						    word green, word blue,
						    Color _far *index);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Return dh = index, dl = blue, ah = green, al = red

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRMAPCOLORRGB	proc	far	gstate:hptr, red:word, green:word, blue:word,
				index:fptr
				uses di, es
	.enter

	mov	al, red.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	di, gstate
	call	GrMapColorRGB
	les	di, index
	mov	es:[di], ah

	mov	dh, ah			;dh = index
	mov	dl, bh			;dl = blue
	mov	ah, bl			;ah = green
					;al = red
	.leave
	ret

GRMAPCOLORRGB	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPalette

C DECLARATION:	extern MemHandle
		    _far _pascal GrGetPalette(GStateHandle gstate,
				GetPalType flag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETPALETTE	proc	far	gstate:hptr, flag:word
				uses di, ds
	.enter

	mov	al, flag.low
	mov	di, gstate
	call	GrGetPalette
	mov_trash	ax, bx

	.leave
	ret

GRGETPALETTE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetPrivateData

C DECLARATION:	extern void
		    _far _pascal GrSetPrivateData(GStateHandle gstate,
						dataAX:word, dataBX:word,
						dataCX:word, dataDX:word);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETPRIVATEDATA	proc	far	gstate:hptr, dataAX:word, dataBX:word,
					dataCX:word, dataDX:word
				uses di
	.enter

	mov	ax, dataAX
	mov	bx, dataBX
	mov	cx, dataCX
	mov	dx, dataDX
	mov	di, gstate
	call	GrSetPrivateData

	.leave
	ret

GRSETPRIVATEDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetMixMode

C DECLARATION:	extern MixMode
			_far _pascal GrGetMixMode(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETMIXMODE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetMixMode
	pop	di
	ret

GRGETMIXMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineColor

C DECLARATION:	extern RGBColorAsDWord
			_far _pascal GrGetLineColor(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINECOLOR	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetLineColor
CReturnRGBCommon	label	far
	mov	dl, bh
	mov	ah, bl
	pop	di
	ret

GRGETLINECOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetAreaColor

C DECLARATION:	extern RGBColorAsDWord
			_far _pascal GrGetAreaColor(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETAREACOLOR	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetAreaColor
	jmp	CReturnRGBCommon

GRGETAREACOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextColor

C DECLARATION:	extern RGBColorAsDWord
			_far _pascal GrGetTextColor(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTCOLOR	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetTextColor
	jmp	CReturnRGBCommon

GRGETTEXTCOLOR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineMask

C DECLARATION:	extern word	/* SysDrawMask */
		    _far _pascal GrGetLineMask(GStateHandle gstate,
					DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINEMASK	proc	far	gstate:hptr, dmask:fptr
				uses si, di, ds
	clr	cx
CGetMaskCommon	label	far
	.enter

	mov	di, gstate

	tst	dmask.segment
	jz	noMask
	lds	si, dmask
	mov	al, GMT_BUFFER
	call	CallLineMaskRoutine
noMask:

	clr	ax
	mov	al, GMT_ENUM
	call	CallLineMaskRoutine

	.leave
	ret

GRGETLINEMASK	endp

CallLineMaskRoutine	proc	near
	jcxz	line
	cmp	cx, 1
	jz	area
	call	GrGetTextMask
	ret
area:
	call	GrGetAreaMask
	ret
line:
	call	GrGetLineMask
	ret
CallLineMaskRoutine	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetAreaMask

C DECLARATION:	extern word	/* SysDrawMask */
		    _far _pascal GrGetAreaMask(GStateHandle gstate,
					DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETAREAMASK	proc	far
	mov	cx, 1
	jmp	CGetMaskCommon

GRGETAREAMASK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextMask

C DECLARATION:	extern word	/* SysDrawMask */
		    _far _pascal GrGetTextMask(GStateHandle gstate,
					DrawMask _far *dm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTMASK	proc	far
	mov	cx, 1
	jmp	CGetMaskCommon

GRGETTEXTMASK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineColorMap

C DECLARATION:	extern word
			_far _pascal GrGetLineColorMap(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINECOLORMAP	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetLineColorMap
	pop	di
	ret

GRGETLINECOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetAreaColorMap

C DECLARATION:	extern word
			_far _pascal GrGetAreaColorMap(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETAREACOLORMAP	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetAreaColorMap
	pop	di
	ret

GRGETAREACOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextColorMap

C DECLARATION:	extern word
			_far _pascal GrGetTextColorMap(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTCOLORMAP	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetTextColorMap
	pop	di
	ret

GRGETTEXTCOLORMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextSpacePad

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrGetTextSpacePad(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTSPACEPAD	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetTextSpacePad
	clr	ax
	mov	ah, bl
	pop	di
	ret

GRGETTEXTSPACEPAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextStyle

C DECLARATION:	extern word
			_far _pascal GrGetTextStyle(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTSTYLE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetTextStyle
	pop	di
	ret

GRGETTEXTSTYLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextDrawOffset

C DECLARATION:	extern word
			_pascal GrGetTextDrawOffset(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/93		Initial version

------------------------------------------------------------------------------@
GRGETTEXTDRAWOFFSET	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_tr	di, ax
	call	GrGetTextDrawOffset
	pop	di
	ret

GRGETTEXTDRAWOFFSET	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextMode

C DECLARATION:	extern word
			_far _pascal GrGetTextMode(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTEXTMODE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetTextMode
	pop	di
	ret

GRGETTEXTMODE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineWidth

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrGetLineWidth(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINEWIDTH	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetLineWidth
	pop	di
	ret

GRGETLINEWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineEnd

C DECLARATION:	extern LineEnd
			_far _pascal GrGetLineEnd(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINEEND	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetLineEnd
	pop	di
	ret

GRGETLINEEND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineJoin

C DECLARATION:	extern LineJoin
			_far _pascal GrGetLineJoin(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINEJOIN	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetLineJoin
	pop	di
	ret

GRGETLINEJOIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetLineStyle

C DECLARATION:	extern LineStyle
			_far _pascal GrGetLineStyle(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETLINESTYLE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	clr	ax
	call	GrGetLineStyle
	pop	di
	ret

GRGETLINESTYLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetMiterLimit

C DECLARATION:	extern WWFixedAsDWord
			_far _pascal GrGetMiterLimit(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETMITERLIMIT	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetMiterLimit
	pop	di
	mov	dx, bx
	ret

GRGETMITERLIMIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetCurPos

C DECLARATION:	extern XYValueAsDWord
			_far _pascal GrGetCurPos(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETCURPOS	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrGetCurPos
	pop	di
	jc	errorPos
	mov	dx, bx
	ret

errorPos:
	mov	ax, 0x8000
	mov	dx, ax
	ret
GRGETCURPOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetCurPosWWFixed

C DECLARATION:	extern void
			_far _pascal GrGetCurPosWWFixed(GStateHandle gstate,
						PointWWFixed _far *cp);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/93		Initial version

------------------------------------------------------------------------------@
GRGETCURPOSWWFIXED	proc	far	gstate:hptr, cp:fptr
	uses	di, ds
	.enter
	mov	di, gstate
	call	GrGetCurPosWWFixed
	lds	di, cp
	movwwf	ds:[di].PF_x, dxcx
	movwwf	ds:[di].PF_y, bxax
	.leave
	ret
GRGETCURPOSWWFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetInfo

C DECLARATION:	extern void
		    _far _pascal GrGetInfo(GStateHandle gstate,
					GrInfoType type, void _far *data);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETINFO	proc	far	gstate:hptr, gtype:word, gdata:fptr
				uses di, es
	.enter

	mov	ax, gtype
	push	ax
	mov	di, gstate
	call	GrGetInfo
	les	di, gdata
	stosw
	pop	ax
	cmp	ax, GIT_WINDOW
	jz	done
	mov_trash	ax, bx
	stosw
	mov_trash	ax, cx
	stosw
	mov_trash	ax, dx
	stosw

done:
	.leave
	ret

GRGETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTransform

C DECLARATION:	extern void
			_far _pascal GrGetTransform(GStateHandle gstate,
							TransMatrix _far *tm);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETTRANSFORM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	dx, di
	xchg	ax, si
	call	GrGetTransform
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRGETTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetFont

C DECLARATION:	extern FontID
			_far _pascal GrGetFont(GStateHandle gstate,
					    WWFixedAsDWord _far *pointSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETFONT	proc	far
	C_GetThreeWordArgs	ax, cx, bx,  dx	;ax = gs, cx = seg, bx = off

	push	di, ds
	mov	ds, cx
	mov_trash	di, ax
	clr	ax
	call	GrGetFont
	mov	ds:[bx].high, dx
	mov	ds:[bx].low, ax
	mov_trash	ax, cx
	pop	di, ds
	ret

GRGETFONT	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestPointInPolygon

C DECLARATION:	extern Boolean
		    _far _pascal GrTestPointInPolygon(GStateHandle gstate,
						RF_rule rule, Point _far *list,
						word numPoints, sword xCoord,
						sword yCoord);
			Note: "list" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRTESTPOINTINPOLYGON	proc	far	gstate:hptr, rule:word, plist:fptr,
					numPoints:word, xCoord:word,
					yCoord:word
				uses si, di, ds
	.enter

	mov	al, rule.low
	mov	cx, numPoints
	mov	dx, xCoord
	mov	bx, yCoord
	mov	di, gstate
	lds	si, plist
	call	GrTestPointInPolygon

	.leave
	ret

GRTESTPOINTINPOLYGON	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEndGString

C DECLARATION:	extern GStringErrorType
			_far _pascal GrEndGString(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRENDGSTRING	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	push	di
	mov_trash	di, ax
	call	GrEndGString
	pop	di
	ret

GRENDGSTRING	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrComment

C DECLARATION:	extern void
		    _far _pascal GrComment(GStateHandle gstate,
					const void _far *data, word size);

			Note: "data" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCOMMENT	proc	far	gstate:hptr, pdata:fptr, csize:word
				uses si, di, ds
	.enter

	mov	cx, csize
	lds	si, pdata
	mov	di, gstate
	call	GrComment

	.leave
	ret

GRCOMMENT	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrNullOp

C DECLARATION:	extern void
			_far _pascal GrNullOp(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRNULLOP	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrNullOp
	xchg	ax, di
	ret

GRNULLOP	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEscape

C DECLARATION:	extern void
		    _far _pascal GrEscape(GStateHandle gstate, word code,
					const void _far *data, word size);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRESCAPE	proc	far	gstate:hptr, gcode:word, pdata:fptr, csize:word
				uses si, di, ds
	.enter

	mov	ax, gcode
	mov	cx, csize
	lds	si, pdata
	mov	di, gstate
	call	GrEscape

	.leave
	ret

GRESCAPE	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrNewPage

C DECLARATION:	extern void
			_far _pascal GrNewPage(GStateHandle gstate,
					       PageEndCommand pageEndCommand);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRNEWPAGE	proc	far
	C_GetTwoWordArgs	bx,ax, dx,cx	;bx = gstate,ax = pageEndCommand

	xchg	bx, di
	call	GrNewPage
	xchg	bx, di
	ret

GRNEWPAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrApplyRotation

C DECLARATION:	extern void
			_far _pascal GrApplyRotation(GStateHandle gstate,
							WWFixedAsDWord angle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRAPPLYROTATION	proc	far
	C_GetThreeWordArgs	ax, dx, cx,  bx	;ax = gs, dx.cx = rotation

	xchg	ax, di
	call	GrApplyRotation
	xchg	ax, di
	ret

GRAPPLYROTATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrApplyScale

C DECLARATION:	extern void
		    _far _pascal GrApplyScale(GStateHandle gstate,
				WWFixedAsDWord xScale, WWFixedAsDWord yScale);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRAPPLYSCALE	proc	far	gstate:hptr, xScale:sdword, yScale:sdword
				uses di
	.enter

	mov	dx, xScale.high
	mov	cx, xScale.low
	mov	bx, yScale.high
	mov	ax, yScale.low
	mov	di, gstate
	call	GrApplyScale

	.leave
	ret

GRAPPLYSCALE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrApplyTranslation

C DECLARATION:	extern void
		    _far _pascal GrApplyTranslation(GStateHandle gstate,
				WWFixedAsDWord xTrans, WWFixedAsDWord yTrans);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRAPPLYTRANSLATION	proc	far	gstate:hptr, xTrans:sdword,
					yTrans:sdword
				uses di
	clc
CApplyTransCommon	label	far
	.enter

	mov	dx, xTrans.high
	mov	cx, xTrans.low
	mov	bx, yTrans.high
	mov	ax, yTrans.low
	mov	di, gstate
	jc	exttrans
	call	GrApplyTranslation
	jmp	common
exttrans:
	call	GrApplyTranslationDWord
common:

	.leave
	ret

GRAPPLYTRANSLATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrApplyTranslationDWord

C DECLARATION:	extern void
		    _far _pascal GrApplyTranslationDWord(GStateHandle gstate,
				sdword xTrans, sdword yTrans);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRAPPLYTRANSLATIONDWORD	proc	far
	stc
	jmp	CApplyTransCommon

GRAPPLYTRANSLATIONDWORD	endp

if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTransform

C DECLARATION:	extern void
			_far _pascal GrSetTransform(GStateHandle gstate,
						const TransMatrix _far *tm);
			Note: "tm" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTRANSFORM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	dx, di
	xchg	ax, si
	call	GrSetTransform
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRSETTRANSFORM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrApplyTransform

C DECLARATION:	extern void
			_far _pascal GrApplyTransform(GStateHandle gstate,
						const TransMatrix _far *tm);
			Note: "tm" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRAPPLYTRANSFORM	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	dx, di
	xchg	ax, si
	call	GrApplyTransform
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRAPPLYTRANSFORM	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetNullTransform

C DECLARATION:	extern void
			_far _pascal GrSetNullTransform(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETNULLTRANSFORM	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrSetNullTransform
	xchg	ax, di
	ret

GRSETNULLTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRoundRect

C DECLARATION:	extern void
		    _far _pascal GrDrawRoundRect(GStateHandle gstate,
			    sword left, sword top, sword right, sword bottom,
					word ellipseWidth, word ellipseHeight);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWROUNDRECT	proc	far	gstate:hptr, left:sword, top:sword,
				right:sword, bottom:sword, radius:word
			uses si, di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	mov	si, radius
	call	GrDrawRoundRect

	.leave
	ret

GRDRAWROUNDRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRoundRectTo

C DECLARATION:	extern void
			_far _pascal GrDrawRoundRectTo(GStateHandle gstate,
					sword right, sword bottom, word radius);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWROUNDRECTTO	proc	far	gstate:hptr, right:sword,
					bottom:sword, radius:word
				uses si, di
	.enter

	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	mov	si, radius
	call	GrDrawRoundRectTo

	.leave
	ret

GRDRAWROUNDRECTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawPoint

C DECLARATION:	extern void
			_far _pascal GrDrawPoint(GStateHandle gstate,
							sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWPOINT	proc	far
	C_GetThreeWordArgs	dx, ax, bx,  cx	;dx = gstate, ax = x, bx = y

	xchg	dx, di
	call	GrDrawPoint
	mov	di, dx
	ret

GRDRAWPOINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawPointAtCP

C DECLARATION:	extern void
			_far _pascal GrDrawPointAtCP(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWPOINTATCP	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrDrawPointAtCP
	xchg	ax, di
	ret

GRDRAWPOINTATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawChar

C DECLARATION:	extern void
		    _far _pascal GrDrawChar(GStateHandle gstate, sword x,
							sword y, word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWCHAR	proc	far	gstate:hptr, px:sword, py:sword, gchar:word
				uses di
	.enter

	mov	ax, px
	mov	bx, py
	mov	dx, gchar
	mov	di, gstate
	call	GrDrawChar

	.leave
	ret

GRDRAWCHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawCharAtCP

C DECLARATION:	extern void
			_far _pascal GrDrawCharAtCP(GStateHandle gstate,
								word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWCHARATCP	proc	far
	C_GetTwoWordArgs	bx, dx,   cx,ax	;bx = gstate, dx = character

	push	di
	mov	di, bx
	call	GrDrawCharAtCP
	pop	di
	ret

GRDRAWCHARATCP	endp

if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawPolyline

C DECLARATION:	extern void
		    _far _pascal GrDrawPolyline(GStateHandle gstate
				const Point _far *points, word numPoints);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWPOLYLINE	proc	far	gstate:hptr, points:fptr, numPoints:word
				uses si, di, ds
	.enter

	mov	cx, numPoints
	lds	si, points
	mov	di, gstate
	call	GrDrawPolyline

	.leave
	ret

GRDRAWPOLYLINE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrBrushPolyline

C DECLARATION:	extern void
		    _far _pascal GrDrawPolyline(GStateHandle gstate
				const Point _far *points, word numPoints,
				word brushW, word brushH);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/91		Initial version

------------------------------------------------------------------------------@
GRBRUSHPOLYLINE	proc	far	gstate:hptr, points:fptr, numPoints:word,
				brushW:word, brushH:word
				uses si, di, ds
	.enter

	mov	cx, numPoints
	lds	si, points
	mov	di, gstate
	mov	al, brushW.low
	mov	ah, brushH.low
	call	GrBrushPolyline

	.leave
	ret

GRBRUSHPOLYLINE	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawEllipse

C DECLARATION:	extern void
		    _far _pascal GrDrawEllipse(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWELLIPSE	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrDrawEllipse

	.leave
	ret

GRDRAWELLIPSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawArc

C DECLARATION:	extern void
		    _far _pascal GrDrawArc(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom,
				word startAngle, word endAngle,
				ArcCloseType closeType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Don	11/91		Changed parameter passing to GrDrawArc()
	Don	11/93		Fix up stack after call

------------------------------------------------------------------------------@
;
; Exported as a placeholder for the old GRDRAWARC.
;
global GRDRAWARC_OLD:far
GRDRAWARC_OLD	proc	far
	REAL_FALL_THRU	GRDRAWARC
GRDRAWARC_OLD	endp

GRDRAWARC	proc	far	gstate:hptr, left:sword, top:sword,
				right:sword, bottom:sword, startAngle:word,
				endAngle:word, closeType:ArcCloseType
				uses si, di, ds
	.enter

	mov	di, gstate
	push	endAngle, startAngle, bottom, right, top, left, closeType
	mov	si, sp
	segmov	ds, ss				; ArcParams => DS:SI
	call	GrDrawArc
	add	sp, 7 * (size word)		; clean up the stack

	.leave
	ret
GRDRAWARC	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawArc3Point

C DECLARATION:	extern void
		    _far _pascal GrDrawArc3Point (GStateHandle gstate,
				const ThreePointArcParams *params);
			Note: "params" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/91		Initial version
	jim	12/92		rewrote for new API

------------------------------------------------------------------------------@
GRDRAWARC3POINT	proc	far	gstate:hptr, params:fptr
				uses si, di, ds
	.enter

	mov	di, gstate			; GState handle => DI
	lds	si, params
	call	GrDrawArc3Point

	.leave
	ret
GRDRAWARC3POINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawArc3PointTo

C DECLARATION:	extern void
		    _far _pascal GrDrawArc3PointTo (GStateHandle gstate,
				const ThreePointArcToParams *params);
			Note: "params" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/91		Initial version
	jim	12/92		rewrote for new API

------------------------------------------------------------------------------@
GRDRAWARC3POINTTO	proc	far	gstate:hptr, params:fptr
					uses di, si, ds
	.enter

	mov	di, gstate			; GState handle => DI
	lds	si, params
	call	GrDrawArc3PointTo

	.leave
	ret
GRDRAWARC3POINTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawRelArc3PointTo

C DECLARATION:	extern void
		    _far _pascal GrDrawRelArc3PointTo (GStateHandle gstate,
				const ThreePointRelArcToParams *params);
			Note: "params" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/91		Initial version
	jim	12/92		rewrote for new API

------------------------------------------------------------------------------@
GRDRAWRELARC3POINTTO	proc	far	gstate:hptr, params:fptr
					uses di,si, ds
	.enter

	mov	di, gstate			; GState handle => DI
	lds	si, params
	call	GrDrawRelArc3PointTo

	.leave
	ret
GRDRAWRELARC3POINTTO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawSpline

C DECLARATION:	extern void
		    _far _pascal GrDrawSpline(GStateHandle gstate,
						const Point _far *points,
						word numPoints);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWSPLINE	proc	far	gstate:hptr, points:fptr, numPoints:word
				uses si, di, ds
	.enter

	lds	si, points
	mov	cx, numPoints
	mov	di, gstate
	call	GrDrawSpline

	.leave
	ret

GRDRAWSPLINE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawSplineTo

C DECLARATION:	extern void
		    _far _pascal GrDrawSplineTo(GStateHandle gstate,
						const Point _far *points,
						word numPoints);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/4/92		Initial version

------------------------------------------------------------------------------@
GRDRAWSPLINETO	proc	far	gstate:hptr, points:fptr, numPoints:word
				uses si, di, ds
	.enter

	lds	si, points
	mov	cx, numPoints
	mov	di, gstate
	call	GrDrawSplineTo

	.leave
	ret

GRDRAWSPLINETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawCurve

C DECLARATION:	extern void
		    _far _pascal GrDrawCurve(GStateHandle gstate,
						const Point _far *points);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWCURVE	proc	far	gstate:hptr, points:fptr
				uses si, di, ds
	.enter

	lds	si, points
	mov	di, gstate
	call	GrDrawCurve

	.leave
	ret

GRDRAWCURVE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawCurveTo

C DECLARATION:	extern void
		    _far _pascal GrDrawCurveTo(GStateHandle gstate,
						const Point _far *points);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWCURVETO	proc	far	gstate:hptr, points:fptr
				uses si, di, ds
	.enter

	lds	si, points
	mov	di, gstate
	call	GrDrawCurveTo

	.leave
	ret

GRDRAWCURVETO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawPolygon

C DECLARATION:	extern void
		    _far _pascal GrDrawPolygon(GStateHandle gstate,
						const Point _far *points,
						word numPoints);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWPOLYGON	proc	far	gstate:hptr, points:fptr, numPoints:word
				uses si, di, ds
	.enter

	lds	si, points
	mov	cx, numPoints
	mov	di, gstate
	call	GrDrawPolygon

	.leave
	ret

GRDRAWPOLYGON	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillRoundRect

C DECLARATION:	extern void
		    _far _pascal GrFillRoundRect(GStateHandle gstate,
					sword left, sword top,
					sword right, sword bottom, word radius);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLROUNDRECT	proc	far	gstate:hptr, left:sword, top:sword,
				right:sword, bottom:sword, radius:word
				uses di, si
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	mov	si, radius
	call	GrFillRoundRect

	.leave
	ret

GRFILLROUNDRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillRoundRectTo

C DECLARATION:	extern void
			_far _pascal GrFillRoundRectTo(GStateHandle gstate,
					sword right, sword bottom, word radius);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLROUNDRECTTO	proc	far	gstate:hptr, right:sword,
					bottom:sword, radius:word
					uses	di, si
	.enter

	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	mov	si, radius
	call	GrFillRoundRectTo

	.leave
	ret

GRFILLROUNDRECTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillArc

C DECLARATION:	extern void
		    _far _pascal GrFillArc(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom,
				word startAngle, word endAngle,
				ArcCloseType closeType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Don	11/91		Changed parameters to GrFillArc()
	jenny	11/93		Fix up stack after call

------------------------------------------------------------------------------@
;
; Exported as a placeholder for the old GRFILLARC.
;
global GRFILLARC_OLD:far
GRFILLARC_OLD	proc	far
	REAL_FALL_THRU	GRFILLARC
GRFILLARC_OLD	endp

GRFILLARC	proc	far	gstate:hptr, left:sword, top:sword,
				right:sword, bottom:sword, startAngle:word,
				endAngle:word, closeType:ArcCloseType
				uses si, di, ds
	.enter

	mov	di, gstate
	push	endAngle, startAngle, bottom, right, top, left, closeType
	mov	si, sp
	segmov	ds, ss				; ArcParams => DS:SI
	call	GrFillArc
	add	sp, 7 * (size word)		; clean up the stack

	.leave
	ret
GRFILLARC	endp


if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillArc3Point

C DECLARATION:	extern void
		    _far _pascal GrFillArc3Point (GStateHandle gstate,
				const ThreePointArcParams *params);
			Note: "params" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/91		Initial version
	jim	12/92		rewrote for new API

------------------------------------------------------------------------------@
GRFILLARC3POINT	proc	far	gstate:hptr, params:fptr
				uses di, si, ds
	.enter

	mov	di, gstate			; GState handle => DI
	lds	si, params
	call	GrFillArc3Point

	.leave
	ret
GRFILLARC3POINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillArc3PointTo

C DECLARATION:	extern void
		    _far _pascal GrFillArc3PointTo (GStateHandle gstate,
				const ThreePointArcToParams *params);
			Note: "params" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/91		Initial version
	jim	12/92		rewrote for new API

------------------------------------------------------------------------------@
GRFILLARC3POINTTO	proc	far	gstate:hptr, params:fptr
					uses di,si,ds
	.enter

	mov	di, gstate			; GState handle => DI
	lds	si, params
	call	GrFillArc3PointTo

	.leave
	ret
GRFILLARC3POINTTO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillPolygon

C DECLARATION:	extern void
		    _far _pascal GrFillPolygon(GStateHandle gstate
				const Point _far *points, word numPoints);
			Note: "points" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLPOLYGON	proc	far	gstate:hptr, rule:word, points:fptr,
				numPoints:word
				uses si, di, ds
	.enter

	mov	ax, rule
	mov	cx, numPoints
	lds	si, points
	mov	di, gstate
	call	GrFillPolygon

	.leave
	ret

GRFILLPOLYGON	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillEllipse

C DECLARATION:	extern void
		    _far _pascal GrFillEllipse(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFILLELLIPSE	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrFillEllipse

	.leave
	ret

GRFILLELLIPSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetLineAttr

C DECLARATION:	extern void
		    _far _pascal GrSetLineAttr(GStateHandle gstate,
				const LineAttr _far *la);
			Note: "la" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jim	5/92		changed for new ptr version of GrSetLineAttr

------------------------------------------------------------------------------@
GRSETLINEATTR	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx ; dx=gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrSetLineAttr
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRSETLINEATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaAttr

C DECLARATION:	extern void
		    _far _pascal GrSetAreaAttr(GStateHandle gstate,
				const AreaAttr _far *aa);
			Note: "aa" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jim	5/92		changed for new ptr version of GrSetLineAttr

------------------------------------------------------------------------------@
GRSETAREAATTR	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx ; dx=gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrSetAreaAttr
	xchg	dx, di
	xchg	ax, si
	pop	ds
	ret

GRSETAREAATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetGStringBounds

C DECLARATION:	extern void
		    _far _pascal GrSetGStringBounds(GStateHandle gstate,
						sword left, sword top,
						sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETGSTRINGBOUNDS	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrSetGStringBounds

	.leave
	ret

GRSETGSTRINGBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCreatePalette

C DECLARATION:	extern word
			_far _pascal GrCreatePalette(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCREATEPALETTE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrCreatePalette
	xchg	ax, di
	mov_trash	ax, cx
	ret

GRCREATEPALETTE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDestroyPalette

C DECLARATION:	extern void
			_far _pascal GrDestroyPalette(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDESTROYPALETTE	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrDestroyPalette
	xchg	ax, di
	ret

GRDESTROYPALETTE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetPaletteEntry

C DECLARATION:	extern void
		    _far _pascal GrSetPaletteEntry(GStateHandle gstate,
						word index, word red,
						word green, word blue);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETPALETTEENTRY	proc	far	gstate:hptr, index:word, red:word,
					green:word, blue:word
				uses di
	.enter

	mov	ah, index.low
	mov	al, red.low
	mov	bl, green.low
	mov	bh, blue.low
	mov	di, gstate
	call	GrSetPaletteEntry

	.leave
	ret

GRSETPALETTEENTRY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetPalette

C DECLARATION:	extern void
		    _far _pascal GrSetPalette(GStateHandle gstate,
						const RGBValue _far *buffer,
						word index, word numEntries);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETPALETTE	proc	far	gstate:hptr, buffer:fptr,
				index:word, numEntries:word
				uses si, di
	.enter

	mov	ax, index
	mov	cx, numEntries
	mov	dx, buffer.segment
	mov	si, buffer.offset
	mov	di, gstate
	call	GrSetPalette

	.leave
	ret

GRSETPALETTE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTrackKern

C DECLARATION:	extern void
			_far _pascal GrSetTrackKern(GStateHandle gstate,
							word tk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETTRACKKERN	proc	far
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gs, ax = tk

	xchg	dx, di
	call	GrSetTrackKern
	xchg	dx, di
	ret

GRSETTRACKKERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTrackKern

C DECLARATION:	extern word
			_far _pascal GrGetTrackKern(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETTRACKKERN	proc	far
	C_GetOneWordArg		dx,  bx,cx	;dx = GState

	xchg	dx, di
	call	GrGetTrackKern			;ax <- track kerning value
	xchg	dx, di
	ret

GRGETTRACKKERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrInitDefaultTransform

C DECLARATION:	extern void
			_far _pascal GrInitDefaultTransform(
							GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRINITDEFAULTTRANSFORM	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrInitDefaultTransform
	xchg	ax, di
	ret

GRINITDEFAULTTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetDefaultTransform

C DECLARATION:	extern void
			_far _pascal GrSetDefaultTransform(
							GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETDEFAULTTRANSFORM	proc	far
	C_GetOneWordArg	ax,   dx,cx	;ax = gstate

	xchg	ax, di
	call	GrSetDefaultTransform
	xchg	ax, di
	ret

GRSETDEFAULTTRANSFORM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrBeginPath

C DECLARATION:	extern void
			_far _pascal GrBeginPath (GStateHandle gstate,
						  PathCombineType params);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRBEGINPATH	proc	far
	C_GetTwoWordArgs	ax,cx,   bx,dx	; ax = gstate, cx = params

	xchg	ax, di				; GState => DI
	call	GrBeginPath
	xchg	ax, di				; restore AX
	ret

GRBEGINPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEndPath

C DECLARATION:	extern void
			_far _pascal GrEndPath (GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRENDPATH	proc	far
	C_GetOneWordArg	ax,   dx,cx		;ax = gstate

	xchg	ax, di
	call	GrEndPath
	xchg	ax, di
	ret

GRENDPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCloseSubPath

C DECLARATION:	extern void
			_far _pascal GrCloseSubPath (GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRCLOSESUBPATH	proc	far
	C_GetOneWordArg	ax,   dx,cx		;ax = gstate

	xchg	ax, di
	call	GrCloseSubPath
	xchg	ax, di
	ret

GRCLOSESUBPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetClipPath

C DECLARATION:	extern void
			_far _pascal GrSetClipPath (GStateHandle gstate,
				PathCombineType params, RegionFillRule rule);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRSETCLIPPATH	proc	far
	C_GetThreeWordArgs	ax,cx,dx   bx	; ax=gstate, cx=params, dl=rule

	xchg	ax, di
	call	GrSetClipPath
	xchg	ax, di
	ret

GRSETCLIPPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetWinClipPath

C DECLARATION:	extern void
			_far _pascal GrSetWinClipPath (GStateHandle gstate,
				PathCombineType params, RegionFillRule rule);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/91		Initial version

------------------------------------------------------------------------------@
GRSETWINCLIPPATH	proc	far
	C_GetThreeWordArgs	ax,cx,dx   bx	; ax=gstate, cx=params, dl=rule

	xchg	ax, di
	call	GrSetWinClipPath
	xchg	ax, di
	ret

GRSETWINCLIPPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFillPath

C DECLARATION:	extern void
			_far _pascal GrFillPath (GStateHandle gstate,
						 RegionFillRule rule);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRFILLPATH	proc	far
	C_GetTwoWordArgs	ax,cx   bx,dx	;ax = gstate, cl = rule

	xchg	ax, di
	call	GrFillPath
	xchg	ax, di
	ret

GRFILLPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawPath

C DECLARATION:	extern void
			_far _pascal GrDrawPath (GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRDRAWPATH	proc	far
	C_GetOneWordArg	ax,   dx,cx		;ax = gstate

	xchg	ax, di
	call	GrDrawPath
	xchg	ax, di
	ret

GRDRAWPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetStrokePath

C DECLARATION:	extern void
			_far _pascal GrSetStrokePath (GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

------------------------------------------------------------------------------@
GRSETSTROKEPATH	proc	far
	C_GetOneWordArg	ax,   dx,cx		;ax = gstate

	xchg	ax, di
	call	GrSetStrokePath
	xchg	ax, di
	ret

GRSETSTROKEPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrInvalRect

C DECLARATION:	extern void
		    _far _pascal GrInvalRect(GStateHandle gstate, sword left,
				sword top, sword right, sword bottom);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRINVALRECT	proc	far	gstate:hptr, left:sword, top:sword,
						right:sword, bottom:sword
				uses di
	.enter

	mov	ax, left
	mov	bx, top
	mov	cx, right
	mov	dx, bottom
	mov	di, gstate
	call	GrInvalRect

	.leave
	ret

GRINVALRECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrInvalRectDWord

C DECLARATION:	extern void
			_far _pascal GrInvalRectDWord(GStateHandle gstate,
						const RectDWord _far *bounds);
			Note: "bounds" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRINVALRECTDWORD	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrInvalRectDWord
	xchg	dx, di
	xchg	ax, si
	pop	ds

	ret

GRINVALRECTDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetWinBoundsDWord

C DECLARATION:	extern void
			_far _pascal GrGetWinBoundsDWord(GStateHandle gstate,
						    RectDWord _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETWINBOUNDSDWORD	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrGetWinBoundsDWord
	xchg	dx, di
	xchg	ax, si
	pop	ds

	ret

GRGETWINBOUNDSDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetMaskBoundsDWord

C DECLARATION:	extern Boolean
			_far _pascal GrGetMaskBoundsDWord(GStateHandle gstate,
						    RectDWord _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		Returns FALSE if the mask is null. Bounds are not set in
		this case.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	mg	3/00		Adding support for return code

------------------------------------------------------------------------------@
GRGETMASKBOUNDSDWORD	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds
	mov	ds, cx
	xchg	ax, si
	xchg	dx, di
	call	GrGetMaskBoundsDWord
	xchg	dx, di
	xchg	ax, si
	pop	ds
	jc	error
	mov	ax, TRUE
done:
	ret

error:
	mov	ax, FALSE
	jmp	done
GRGETMASKBOUNDSDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetWinBounds

C DECLARATION:	extern Boolean
			_far _pascal GrGetWinBounds(GStateHandle gstate,
						    Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		Returns FALSE if returned coord would overflow 16-bit value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETWINBOUNDS	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds, si, di
	mov	ds, cx
	mov	si, ax
	mov	di, dx
	call	GrGetWinBounds
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	pop	ds, si, di
	jc	error
	mov	ax, TRUE
done:
	ret

error:
	mov	ax, FALSE
	jmp	done
GRGETWINBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetMaskBounds

C DECLARATION:	extern Boolean
			_far _pascal GrGetMaskBounds(GStateHandle gstate,
						    Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		Returns FALSE if returned coord would overflow 16-bit value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETMASKBOUNDS	proc	far
	C_GetThreeWordArgs	dx, cx, ax,  bx	;dx = gs, cx = seg, ax = off

	push	ds, si, di
	mov	ds, cx
	mov	si, ax
	mov	di, dx
	call	GrGetMaskBounds
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	pop	ds, si, di
	jc	error
	mov	ax, TRUE
done:
	ret

error:
	mov	ax, FALSE
	jmp	done
GRGETMASKBOUNDS	endp

if FULL_EXECUTE_IN_PLACE
C_Graphics	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextBounds

C DECLARATION:	extern Boolean
			_far _pascal GrGetTextBounds (GStateHandle gstate,
				word xpos, word ypos, const char _far *str,
				word count, Rectangle *bounds);
			Note: "str" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GRGETTEXTBOUNDS	proc	far	gstate:hptr, pstr:fptr.char, xpos:word,
					ypos:word, ccount:word,
					bounds:fptr.Rectangle
	uses si, ds, di
	.enter

	mov	cx, ccount
	mov	ax, xpos
	mov	bx, ypos
	lds	si, pstr
	mov	di, gstate
	call	GrGetTextBounds
	jc	error
	lds	si, bounds
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	clr	ax
done:
	.leave
	ret

	; invalid font driver, return error
error:
	clr	ax
	dec	ax
	jmp	done
GRGETTEXTBOUNDS	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Graphics	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetWinHandle

C DECLARATION:	extern WindowHandle
			_far _pascal GrGetWinHandle(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/91		Initial version

------------------------------------------------------------------------------@
GRGETWINHANDLE	proc	far
	C_GetOneWordArg	cx,   dx,bx	;cx = gstate

	xchg	di, cx
	call	GrGetWinHandle
	xchg	di, cx
	ret

GRGETWINHANDLE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetGStringHandle

C DECLARATION:	extern GStringHandle
			_far _pascal GrGetGStringHandle(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/91		Initial version

------------------------------------------------------------------------------@
GRGETGSTRINGHANDLE	proc	far
	C_GetOneWordArg	cx,   dx,bx	;cx = gstate

	xchg	di, cx
	call	GrGetGStringHandle
	xchg	di, cx
	ret

GRGETGSTRINGHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestPointInPath

C DECLARATION:	extern boolean
			_far _pascal GrTestPointInPath (GStateHandle gstate,
				word xPos, word yPos, RegionFillRule rule);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/91		Initial version

------------------------------------------------------------------------------@
GRTESTPOINTINPATH	proc	far	gstate:hptr, xPos:word, yPos:word,
					rule:word
	uses	di
	.enter

	mov	cl, rule.low
	mov	ax, xPos
	mov	bx, yPos
	mov	di, gstate
	call	GrTestPointInPath
	mov	ax, 0				; assume TRUE (point in path)
	jc	done
	dec	ax				; else FALSE
done:
	.leave
	ret
GRTESTPOINTINPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPath

C DECLARATION:	extern MemHandle
			_far _pascal GrGetPath (GStateHandle gstate,
						GetPathType ptype);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version
	jim	1/93		added GetPathType

------------------------------------------------------------------------------@
GRGETPATH	proc	far
	.enter

	C_GetTwoWordArgs	ax,bx, cx,dx	; GState => AX, PathType => BX
	xchg	ax, di				; GState => DI, save DI in AX
	call	GrGetPath
	xchg	di, ax				; restore DI
	mov_tr	ax, bx				; handle of Path => AX

	.leave
	ret
GRGETPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrTestPath

C DECLARATION:	extern Boolean
			_far _pascal GrTestPath(GStateHandle gstate,
						      GetPathType type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ian	2/95		Initial version

------------------------------------------------------------------------------@
GRTESTPATH	proc	far

	C_GetTwoWordArgs	bx,ax, cx,dx	; GState => BX, PathType => AX
	xchg	bx, di				; GState => DI, save DI in BX
	call	GrTestPath
	xchg	di, bx				; restore DI
	jnc	region
	mov	ax, FALSE
exit:
	ret
region:
	mov	ax, TRUE
	jmp	exit

GRTESTPATH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPathBounds

C DECLARATION:	extern Boolean
			_far _pascal GrGetPathBounds (GStateHandle gstate,
				  GetPathType ptype,Rectangle _far *bounds);
			Note: "bounds" *can* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version
	Jim	2/93		added ptype, Boolean return value

------------------------------------------------------------------------------@
GRGETPATHBOUNDS	proc	far	gstate:hptr, ptype:word, bounds:fptr
	uses	es, di
	.enter

	mov	di, gstate
	mov	ax, ptype
	call	GrGetPathBounds
	les	di, bounds
	stosw					; store left
	mov	ax, bx
	stosw					; store top
	mov	ax, cx
	stosw					; store right
	mov	ax, dx
	stosw					; store bottom
	jc	error
	mov	ax, FALSE
done:
	.leave
	ret

error:
	mov	ax, TRUE
	jmp	done
GRGETPATHBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPathBoundsDWord

C DECLARATION:	extern Boolean
			_far _pascal GrGetPathBoundsDWord (GStateHandle gstate,
				GetPathType ptype,    Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/93		Initial version

------------------------------------------------------------------------------@
GRGETPATHBOUNDSDWORD	proc	far	gstate:hptr, ptype:word, bounds:fptr
	uses	ds, di
	.enter

	mov	di, gstate
	mov	ax, ptype
	lds	bx, bounds
	call	GrGetPathBoundsDWord
	jc	error
	mov	ax, FALSE
done:
	.leave
	ret

error:
	mov	ax, TRUE
	jmp	done
GRGETPATHBOUNDSDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPathPoints

C DECLARATION:	extern MemHandle
			_far _pascal GrGetPathPoints (GStateHandle gstate,
						      word resolution);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/91		Initial version

------------------------------------------------------------------------------@
GRGETPATHPOINTS	proc	far
	C_GetTwoWordArgs	bx,ax, dx,cx	; GState => BX, resolution => AX
	push	di
	mov	di, bx
	call	GrGetPathPoints
	pop	di
	mov_tr	ax, bx				; move handle to points => AX
	ret
GRGETPATHPOINTS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetPathRegion

C DECLARATION:	extern MemHandle
			_far _pascal GrGetPathRegion (GStateHandle gstate,
						      RegionFillRule rule);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/91		Initial version

------------------------------------------------------------------------------@
GRGETPATHREGION	proc	far
	C_GetTwoWordArgs	ax,cx, bx,dx	; GState => AX, FillRule => CL
	xchg	ax, di				; GState => DI, save DI in AX
	call	GrGetPathRegion
	xchg	di, ax				; restore DI
	mov_tr	ax, bx				; handle of Region => AX
	ret
GRGETPATHREGION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetClipRegion

C DECLARATION:	extern MemHandle
			_far _pascal GrGetClipRegion (GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/91		Initial version

------------------------------------------------------------------------------@
GRGETCLIPREGION	proc	far
	C_GetOneWordArg	ax, cx,dx		; GState => AX
	xchg	ax, di				; GState => DI, save DI in AX
	call	GrGetClipRegion
	xchg	di, ax				; restore DI
	mov_tr	ax, bx				; handle of Region => AX
	ret
GRGETCLIPREGION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetAreaPattern

C DECLARATION:	extern void
			_far _pascal GrSetAreaPattern (GStateHandle gstate,
						       GraphicPattern pattern);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRSETAREAPATTERN	proc	far
	C_GetTwoWordArgs	dx,ax bx,cx	; GState => DX, pattern => AX
	push	di
	mov	di, dx
	call	GrSetAreaPattern		; set the pattern
	pop	di
	ret
GRSETAREAPATTERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetCustomAreaPattern

C DECLARATION:	extern void
			_far _pascal GrSetCustomAreaPattern (
				GStateHandle gstate, GraphicPattern pattern,
				const void *patternData, word patternSize);
			Note: "patternData" *cannot* be pointing to the XIP
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRSETCUSTOMAREAPATTERN	proc	far	gstate:hptr, pattern:word,
					patternData:fptr, patternSize:word
	uses	di, si
	.enter

	mov	ax, pattern
	mov	di, gstate
	movdw	dxsi, patternData
	mov	cx, patternSize
	call	GrSetAreaPattern

	.leave
	ret
GRSETCUSTOMAREAPATTERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetTextPattern

C DECLARATION:	extern void
			_far _pascal GrSetTextPattern (GStateHandle gstate,
						       GraphicPattern pattern);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRSETTEXTPATTERN	proc	far
	C_GetTwoWordArgs	dx,ax bx,cx	; GState => DX, Pattern => AX
	push	di
	mov	di, dx
	call	GrSetTextPattern		; set the pattern
	pop	di
	ret
GRSETTEXTPATTERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetCustomTextPattern

C DECLARATION:	extern void
			_far _pascal GrSetCustomTextPattern (
				GStateHandle gstate, GraphicPattern pattern,
				const void *patternData);
			Note: "patternData" *cannot* be pointing to the XIP
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRSETCUSTOMTEXTPATTERN	proc	far	gstate:hptr, pattern:word,
					patternData:fptr
	uses	di, si
	.enter

	mov	ax, pattern
	mov	di, gstate
	movdw	dxsi, patternData
	call	GrSetTextPattern

	.leave
	ret
GRSETCUSTOMTEXTPATTERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetAreaPattern

C DECLARATION:	extern GraphicPattern
			_far _pascal GrGetAreaPattern (GStateHandle gstate,
				const hptr *customPattern, word *customSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRGETAREAPATTERN	proc	far	gstate:hptr, customPattern:fptr,
					customSize:fptr
	.enter

	ForceRef gstate
	ForceRef customPattern
	ForceRef customSize
	clr	cx				; we want area attributes
	call	GetPatternCommonC		; get the pattern

	.leave
	ret
GRGETAREAPATTERN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetTextPattern

C DECLARATION:	extern GraphicPattern
			_far _pascal GrGetTextPattern (GStateHandle gstate,
				const hptr *customPattern, word *customSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/92		Initial version

------------------------------------------------------------------------------@
GRGETTEXTPATTERN	proc	far	gstate:hptr, customPattern:fptr,
					customSize:fptr
	.enter

	ForceRef gstate
	ForceRef customPattern
	ForceRef customSize
	mov	cx, 1				; we want text attributes
	call	GetPatternCommonC		; get the pattern

	.leave
	ret
GRGETTEXTPATTERN	endp

GetPatternCommonC	proc	near	gstate:hptr, customPattern:fptr,
					customSize:fptr
	uses	di, es
	.enter	inherit	far

	mov	di, gstate
	jcxz	area
	call	GrGetTextPattern		; text Pattern => AX
	jmp	common
area:
	call	GrGetAreaPattern		; area Pattern => AX
common:
	les	di, customPattern
	mov	{word} es:[di], bx		; store custom pattern handle
	les	di, customSize
	mov	{word} es:[di], cx		; store custom pattern size

	.leave
	ret
GetPatternCommonC	endp

C_Graphics	ends


	SetDefaultConvention

