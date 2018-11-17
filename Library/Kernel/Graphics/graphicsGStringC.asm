COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsGStringC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the font.h routines

	$Id: graphicsGStringC.asm,v 1.1 97/04/05 01:12:26 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention


C_Graphics	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawGString

C DECLARATION:	extern GSRetType
		    _far _pascal GrDrawGString(GStateHandle gstate,
				GStateHandle gstringToDraw, sword x, sword y,
				word flags, word _far *lastElement);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jim	4/92		modified for new GString stuff

------------------------------------------------------------------------------@
GRDRAWGSTRING	proc	far	gstate:hptr, gstring:hptr, px:sword, py:sword,
				flags:word, lastElement:fptr
				uses si, di, ds
	.enter

	mov	ax, px
	mov	bx, py
	mov	si, gstring
	mov	di, gstate
	mov	dx, flags
	call	GrDrawGString
	mov_trash	ax, dx
	lds	si, lastElement
	mov	ds:[si], cx

	.leave
	ret

GRDRAWGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawGStringAtCP

C DECLARATION:	extern GSRetType
		    _far _pascal GrDrawGStringAtCP(GStateHandle gstate,
				GStateHandle gstringToDraw, word flags,
				word _far *lastElement);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDRAWGSTRINGATCP proc	far 	gstate:hptr, gstring:hptr, flags:word, 
				lastElement:fptr
				uses si, di, ds
	.enter

	mov	si, gstring
	mov	di, gstate
	mov	dx, flags
	call	GrDrawGStringAtCP
	mov_trash	ax, dx
	lds	si, lastElement
	mov	ds:[si], cx

	.leave
	ret
GRDRAWGSTRINGATCP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrParseGString

C DECLARATION:	extern void
		    _far _pascal GrDrawGStringAtCP(GStateHandle gstate,
				GStateHandle gstringToDraw, word flags,
				Boolean (*callBack) (void *element));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	9/92		Initial version

------------------------------------------------------------------------------@
GRPARSEGSTRING proc	far 	gstate:hptr, gstring:hptr, flags:word, 
				callback:fptr.far

realDS	local	sptr	
	uses si, di
	.enter

	ForceRef	callback

	mov	realDS, ds
	push	ss:[TPD_error]
	mov	ss:[TPD_error], bp
	mov	si, gstring
	mov	di, gstate
	mov	dx, flags
	mov	bx, cs
	mov	cx, offset _PARSEGSTRING_callback
	call	GrParseGString	

	pop	ss:[TPD_error]
	.leave
	ret
GRPARSEGSTRING	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_PARSEGSTRING_callback

DESCRIPTION:	Callback routine for GRPARSEGSTRING.  Call the real callback
		after pushing args on the stack

		The C callback function should be declared like:

			extern Boolean _far _pascal 
				ParseCallback ((GStringElement) *gs, 
					       GStateHandle gstate)
CALLED BY:	GrParseGString

PASS:	ds:si	- pointer to element.
	bx	- BP passed to GrParseGString
	di 	- GState handle passed to GrParseGString

RETURN:	ax	- TRUE if finished, else
		  FALSE to continue parsing.
	ds	- as passed or segment of another
		  huge array block in vm based
		  gstrings. See Special Processing
		  below.
MAY DESTROY: ax,bx,cx,dx,di,si,bp,es
					
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

			Special Processing:
				In huge array based gstrings the call back 
				routine	may change ds to point to other huge 
				array blocks in the gstring. In this case, 
				upon returning from the call back, 
				GrParseGString will unlock the huge array 
				block now referenced by ds and relock the
				the huge array block originally passed
				to the call back. All gstring elements will
				be processed.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/93		Initial version

------------------------------------------------------------------------------@

_PARSEGSTRING_callback	proc	far	gstate:hptr, gstring:hptr, flags:word, 
					callback:fptr.far
realDS	local	sptr
				uses si, di, bp
	ForceRef	gstate
	ForceRef	gstring
	ForceRef	flags
	.enter inherit far

	mov	bp, ss:[TPD_error]

	pushdw	dssi			; gstring pointer
	push	di			; gstate handle

	mov	ds, realDS
	mov	ax, callback.offset
	mov	bx, callback.segment
	call	ProcCallFixedOrMovable

	; return ax intact, as boolean value

	.leave
	ret

_PARSEGSTRING_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetGStringPos

C DECLARATION:	extern void
			_far _pascal GrSetGStringPos(GStateHandle gstate,
					GStringSetPosType type, word skip);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRSETGSTRINGPOS	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = gs, ax = type, cx = num

	xchg	bx, si
	call	GrSetGStringPos
	xchg	bx, si
	ret

GRSETGSTRINGPOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCopyGString

C DECLARATION:	extern GSRetType
			_far _pascal GrCopyGString(GStateHandle source,
						GStateHandle dest, word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCOPYGSTRING	proc	far
	C_GetThreeWordArgs	bx, ax, dx,  cx	;bx = src, ax = dest, dx = fla

	xchg	bx, si
	xchg	ax, di
	call	GrCopyGString
	xchg	ax, di
	xchg	bx, si
	mov_trash	ax, cx
	ret

GRCOPYGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDestroyGString

C DECLARATION:	extern void
			_far _pascal GrDestroyGString(GStateHandle gstring,
						      GStateHandle gstate,
							GStringKillType type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRDESTROYGSTRING	proc	far
	C_GetThreeWordArgs	ax, bx, dx,  cx	;ax = gstring, bx = gstate
						;dx = kill type
	xchg	ax, si
	xchg	bx, di
	call	GrDestroyGString
	mov	di, bx
	mov_tr	si, ax
	ret

GRDESTROYGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrLoadGString

C DECLARATION:	extern GStateHandle
			_far _pascal GrLoadGString(Handle han,
					GStringType hanType, word vmBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRLOADGSTRING	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = han, cx = type, ax = vm

	xchg	ax, si
	call	GrLoadGString
	xchg	ax, si
	ret

GRLOADGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEditGString

C DECLARATION:	extern GStateHandle
			_far _pascal GrEditGString(Handle vmFile, 
						   word vmBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GREDITGSTRING	proc	far
	C_GetTwoWordArgs	bx, cx,   ax,dx	;bx = vmFile, cx = vmBlock

	xchg	ax, di		; save di
	xchg	cx, si
	call	GrEditGString
	xchg	cx, si
	xchg	ax, di		; return handle in ax, restore di
	ret

GREDITGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDeleteGStringElement

C DECLARATION:	extern void
			_far _pascal GrDeleteGStringElement(GStateHandle gs, 
						   word count);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GRDELETEGSTRINGELEMENT	proc	far
	C_GetTwoWordArgs	bx, cx,   ax,dx	;bx = gs, cx = count

	xchg	bx, di		; save di
	call	GrDeleteGStringElement
	xchg	bx, di		; restore di
	ret

GRDELETEGSTRINGELEMENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCreateGString

C DECLARATION:	extern GStateHandle
			_far _pascal GrCreateGString(Handle han,
					GStringType hanType, word *vmBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Jim	5/92		Modified for API change

------------------------------------------------------------------------------@
GRCREATEGSTRING	proc	far	gsFile:hptr, gsType:word, gsBlock:fptr.word
	
	uses	si, di, ds
	.enter

	mov	bx, gsFile
	mov	cx, gsType
	call	GrCreateGString
	lds	bx, gsBlock
	mov	ds:[bx], si		; stuff return value
	mov	ax, di			; return handle in ax
	.leave
	ret

GRCREATEGSTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetGStringElement

C DECLARATION:	extern GStringElement
		    _far _pascal GrGetGStringElement(GStateHandle gstate,
					GStateHandle gstring, word bufSize,
					void _far *buffer, word _far *elSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETGSTRINGELEMENT	proc	far	gstate:hptr, gstring:hptr,bufSize:word,buffer:fptr, elSize:fptr.word
	uses si, di, ds
	.enter

	mov	cx, bufSize
	lds	bx, buffer
	mov	si, gstring
	mov	di, gstate
	call	GrGetGStringElement
	lds	si, elSize
	mov	ds:[si], cx
	clr	ah

	.leave
	ret

GRGETGSTRINGELEMENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetGStringBounds

C DECLARATION:	extern Boolean 
		    _far _pascal GrGetGStringBounds(GStateHandle gstring,
					GStateHandle gstate, 
					GSControl flags,
					Rectangle _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		returns FALSE if there was some coordinate overflow

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GRGETGSTRINGBOUNDS	proc	far	gstring:hptr, gstate:hptr,flags:word,
					bounds:fptr.Rectangle
	uses si, di, ds
	.enter

	mov	si, gstring
	mov	di, gstate
	mov	dx, flags
	call	GrGetGStringBounds
	lds	si, bounds
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	mov	ax, TRUE
	jnc	done
	mov	ax, FALSE
done:
	.leave
	ret

GRGETGSTRINGBOUNDS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetGStringBoundsDWord

C DECLARATION:	extern void
		    _far _pascal GrGetGStringBounds(GStateHandle gstring,
					GStateHandle gstate, 
					GSControl flags,
					RectDWord _far *bounds);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GRGETGSTRINGBOUNDSDWORD	proc	far	gstring:hptr, gstate:hptr,flags:word,
					bounds:fptr.Rectangle
	uses si, di, ds
	.enter

	mov	si, gstring
	mov	di, gstate
	mov	dx, flags
	lds	bx, bounds
	call	GrGetGStringBoundsDWord

	.leave
	ret

GRGETGSTRINGBOUNDSDWORD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrLabel

C DECLARATION:	extern void 
		    _far _pascal GrLabel(GStateHandle gstring,
					 word label);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92		Initial version

------------------------------------------------------------------------------@
GRLABEL	proc	far	
	C_GetTwoWordArgs	dx, ax,   bx,cx	;dx = gstate, ax = label
	xchg	dx, di
	call	GrLabel
	xchg	dx, di
	ret
GRLABEL	endp

C_Graphics	ends

	SetDefaultConvention


