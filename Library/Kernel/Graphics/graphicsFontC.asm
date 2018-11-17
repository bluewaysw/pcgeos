COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsFontC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the font.h routines

	$Id: graphicsFontC.asm,v 1.1 97/04/05 01:13:32 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention


C_Graphics	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrEnumFonts

C DECLARATION:	extern word
		    _far _pascal GrEnumFonts(FontEnumStruct _far *buffer,
					word size, word flags, word family);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRENUMFONTS	proc	far	buffer:fptr.FontEnumStruct, bsize:word,
				flags:word, family:word
				uses di, es
	.enter

	les	di, buffer
	mov	cx, bsize
	mov	dl, flags.low
	mov	dh, family.low
	call	GrEnumFonts
	mov_trash	ax, cx

	.leave
	ret

GRENUMFONTS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCheckFontAvailID

C DECLARATION:	extern FontID
			_far _pascal GrCheckFontAvailID(word flags, word family,
								FontID id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCHECKFONTAVAILID	proc	far
	C_GetThreeWordArgs	dx, ax, cx,  bx	;dx = flags, ax = fam, cx = id

	mov	dh, al
	call	GrCheckFontAvail
	mov_trash	ax, cx
	ret

GRCHECKFONTAVAILID	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCheckFontAvailName

C DECLARATION:	extern FontID
		    _far _pascal GrCheckFontAvailName(word flags, word family,
						const char _far *name);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCHECKFONTAVAILNAME	proc	far	flags:word, family:word,
					fname:fptr.char
				uses si, ds
	.enter

	lds	si, fname
	mov	dl, flags.low
	mov	dh, family.low
	call	GrCheckFontAvail
	mov_trash	ax, cx

	.leave
	ret

GRCHECKFONTAVAILNAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFindNearestPointsize

C DECLARATION:	extern Boolean
		    _far _pascal GrFindNearestPointsize(FontID id,
						dword sizeSHL16, word styles,
						word _far *styleFound,
						dword _far *sizeFoundSHL16);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFINTNEARESTPOINTSIZE	proc	far	id:word, sizeSHL16:dword, styles:word,
					styleFound:fptr, sizeFoundSHL16:fptr
				uses si, ds
	.enter

	mov	cx, id
	mov	dx, sizeSHL16.high
	mov	ah, (sizeSHL16.low).high
	mov	al, styles.low
	call	GrFindNearestPointsize
	lds	si, styleFound
	mov	ds:[si], al
	lds	si, sizeFoundSHL16
	mov	ds:[si].high, dx
	clr	al
	mov	ds:[si].low, ax
	clr	ax
	cmp	cx, FID_INVALID
	jz	done
	dec	ax
done:
	.leave
	ret

GRFINTNEARESTPOINTSIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetDefFontID

C DECLARATION:	extern FontID
			_far _pascal GrGetDefFontID(dword _far *sizeSHL16);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRGETDEFFONTID	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	di, es
	mov	es, cx
	mov_trash	di, ax
	call	GrGetDefFontID
	clr	al
	stosw
	mov_trash	ax, dx
	stosw
	pop	di, es
	mov_trash	ax, cx

	ret

GRGETDEFFONTID	endp

C_Graphics	ends

;---

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrCharMetrics

C DECLARATION:	extern dword
			_far _pascal GrCharMetrics(GStateHandle gstate,
						GCM_info info, word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRCHARMETRICS	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = gstate, cx = info, ax=ch

	push	si, di
	mov	di, bx
	mov	si, cx
	call	GrCharMetrics
	tst	al
	jz	return0

CMetricsCommon	label	far
	test	si, GFMI_ROUNDED
	jnz	rounded

	clr	al
done:
	pop	si, di
	ret

rounded:
	clr	ax
	xchg	ax, dx			;ax = result, dx = 0
	tst	ax
	jns	done
	dec	dx			;sign extend
	jmp	done

return0:
	clr	ax
	clr	dx
	jmp	done

GRCHARMETRICS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrFontMetrics

C DECLARATION:	extern dword
			_far _pascal GrFontMetrics(GStateHandle gstate,
								GCM_info info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
GRFONTMETRICS	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = gstate, ax = info

	push	si, di
	mov	di, bx
	mov_trash	si, ax
	call	GrFontMetrics
	jmp	CMetricsCommon

GRFONTMETRICS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetFontName

C DECLARATION:	extern word
			_pascal GrGetFontName(FontID id,
					      char *name);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETFONTNAME	proc	far	id:word, fname:fptr.char

	uses	ds, si
	.enter
	lds	si, ss:fname
	mov	cx, ss:id
	call	GrGetFontName
	mov_trash	ax, cx

	.leave
	ret
GRGETFONTNAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetFontWeight

C DECLARATION:	extern void
			_far _pascal GrSetFontWeight(GStateHandle gstate,
						FontWeight weight);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRSETFONTWEIGHT	proc	far
	C_GetTwoWordArgs	bx, ax, cx,dx	;ax <- FontWeight
	xchg	bx, di				;di <- handle of GState
	call	GrSetFontWeight
	xchg	bx, di				;bx <- saved bx
	ret
GRSETFONTWEIGHT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetFontWidth

C DECLARATION:	extern void
			_far _pascal GrSetFontWidth(GStateHandle gstate,
						FontWidth width);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRSETFONTWIDTH	proc	far
	C_GetTwoWordArgs	bx, ax, cx,dx	;ax <- FontWidth
	xchg	bx, di				;di <- handle of GState
	call	GrSetFontWidth
	xchg	bx, di				;bx <- saved bx
	ret
GRSETFONTWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetSuperscriptAttr

C DECLARATION:	extern void
			_far _pascal GrSetSuperscriptAttr(GStateHandle gstate,
						SuperscriptAttrs attrs);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRSETSUPERSCRIPTATTR	proc	far
	C_GetTwoWordArgs	bx, ax, cx,dx	;al <- position, ah <- size
	xchg	bx, di				;di <- handle of GState
	call	GrSetSuperscriptAttr
	xchg	bx, di				;bx <- saved bx
	ret
GRSETSUPERSCRIPTATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrSetSubscriptAttr

C DECLARATION:	extern void
			_far _pascal GrSetSubscriptAttr(GStateHandle gstate,
						SubscriptAttrs attrs);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRSETSUBSCRIPTATTR	proc	far
	C_GetTwoWordArgs	bx, ax, cx,dx	;al <- position, ah <- size
	xchg	bx, di				;di <- handle of GState
	call	GrSetSubscriptAttr
	xchg	bx, di				;bx <- saved bx
	ret
GRSETSUBSCRIPTATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetFontWeight

C DECLARATION:	extern FontWeight
			_far _pascal GrGetFontWeight(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETFONTWEIGHT	proc	far
	C_GetOneWordArg	bx, cx,dx		;bx <- handle of GState
	xchg	bx, di				;di <- handle of GState
	call	GrGetFontWeight
	xchg	bx, di				;bx <- saved bx
	ret
GRGETFONTWEIGHT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetFontWidth

C DECLARATION:	extern FontWidth
			_far _pascal GrGetFontWidth(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETFONTWIDTH	proc	far
	C_GetOneWordArg	bx, cx,dx		;bx <- handle of GState
	xchg	bx, di				;di <- handle of GState
	call	GrGetFontWeight
	xchg	bx, di				;bx <- saved bx
	ret
GRGETFONTWIDTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetSuperscriptAttr

C DECLARATION:	extern ScriptAttrAsWord
			_far _pascal GrGetSuperscriptAttr(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETSUPERSCRIPTATTR	proc	far
	C_GetOneWordArg	bx, cx,dx		;bx <- handle of GState
	xchg	bx, di				;di <- handle of GState
	call	GrGetSuperscriptAttr
	xchg	bx, di				;bx <- saved bx
	ret
GRGETSUPERSCRIPTATTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrGetSubscriptAttr

C DECLARATION:	extern ScriptAttrAsWord
			_far _pascal GrGetSubscriptAttr(GStateHandle gstate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/92		Initial version

------------------------------------------------------------------------------@
GRGETSUBSCRIPTATTR	proc	far
	C_GetOneWordArg	bx, cx,dx		;bx <- handle of GState
	xchg	bx, di				;di <- handle of GState
	call	GrGetSubscriptAttr
	xchg	bx, di				;bx <- saved bx
	ret
GRGETSUBSCRIPTATTR	endp

C_Common	ends

	SetDefaultConvention
