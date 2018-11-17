COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		kinsokuChars.asm

AUTHOR:		Gene Anderson, Jan 21, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/21/94		Initial revision


DESCRIPTION:
	Code for dealing with kinsoku shori, or "prohibited [character]
	processing", which define how word-wrapping is done in Japanese.

	$Id: kinsokuChars.asm,v 1.1 97/04/05 01:16:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment	resource

if PZ_PCGEOS

kinsokuDisableKey	char "kinsokuDisabled", 0
kinsokuStartKey		char "kinsokuStart", 0
kinsokuEndKey		char "kinsokuEnd", 0

KinsokuBufferInfo struct
    KBI_key		nptr.char
    KBI_buffer		nptr.wchar
KinsokuBufferInfo ends

kinsokuStartInfo KinsokuBufferInfo <
	offset kinsokuStartKey,
	offset kinsokuStartChars
>

kinsokuEndInfo KinsokuBufferInfo <
	offset kinsokuEndKey,
	offset kinsokuEndChars
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KinsokuCharsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the kinsoku characters

CALLED BY:	LocalInit()
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KinsokuCharsInit		proc	near
		uses	ax, bx, cx, dx, bp, di, es, ds, si
		.enter

		call	GetKinsokuDisabled	;read enab/disab to dgroup

		mov	al, KCT_START_CHARS	;al <- KinsokuCharType
		call	commonInit
		mov	al, KCT_END_CHARS	;al <- KinsokuCharType
		call	commonInit

		.leave
		ret

commonInit:
	;
	; Get the buffer to use
	;
		call	KCGetInfo
		LoadVarSeg es
		mov	di, cs:[bx].KBI_buffer	;es:di <- buffer
	;
	; Read from the GEOS.INI file
	;
		mov	cx, cs
		mov	dx, cs:[bx].KBI_key	;cx:dx <- key
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, MAX_KINSOKU_CHARS>
		call	InitFileReadString
		jcxz	useDefault		;branch if no such section
		mov	es:[di][-2], cx		;store string length
useDefault:
		retn
KinsokuCharsInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to get the info to use for kinsoku chars

CALLED BY:	KinsokuCharsInit(), LocalSetKinsoku(), LocalGetKinsoku()
PASS:		al - KinsokuCharType
RETURN:		bx - ptr to KinsokuBufferInfo to use
		ds:si - ptr to localizationCategory
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KCGetInfo		proc	near
		.enter
	;
	; Figure out which chars we're setting/getting/initing
	;
		mov	bx, offset kinsokuStartInfo
	CheckHack <KCT_START_CHARS eq 0>
		tst	al
		jz	gotInfo
		mov	bx, offset kinsokuEndInfo
gotInfo:
	;
	; Load up some common values
	;
		segmov	ds, cs
		mov	si, offset localizationCategory	;ds:si <- ptr to cat
	CheckHack <segment localizationCategory eq @CurSeg>

		.leave
		ret
KCGetInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetKinsokuDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the kinsoku enabled/disabled value

CALLED BY:	UTILITY
PASS:		cl - KinsokuState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetKinsokuDisabled	proc	near
	uses	ax,cx,dx,si,di,ds,es
		.enter

		clr	ch
		and	cl, mask KS_DISABLED		;get disabled bit

		LoadVarSeg	es
		mov	es:kinsokuDisabled, cl		;dis if non-zero
		mov	ax, cx

		segmov	ds, cs
		mov	si, offset localizationCategory	;ds:si - category
	CheckHack <segment localizationCategory eq @CurSeg>
		segmov	cx, cs
		mov	dx, offset kinsokuDisableKey	;cx:dx - key
		call	InitFileWriteBoolean

		.leave
		ret
SetKinsokuDisabled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetKinsokuDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the kinsoku enabled/disabled value

CALLED BY:	UTILITY
PASS:		nothing
RETURN:		al - KinsokuState with KS_DISABLED set from .ini
DESTROYED:	ah
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetKinsokuDisabled	proc	near
	uses	cx,dx,si,ds,es
		.enter

	;
	; Get the buffer to use
	;
		segmov	ds, cs
		mov	si, offset localizationCategory	;ds:si <- category
	CheckHack <segment localizationCategory eq @CurSeg>
	;
	; Read from the GEOS.INI file
	;
		mov	cx, cs
		mov	dx, offset kinsokuDisableKey	;cx:dx <- key
		clr	al				;initially enabled
		call	InitFileReadBoolean
		jc	dontDisable
		and	al, mask KS_DISABLED
dontDisable:
		LoadVarSeg	es
		mov	es:kinsokuDisabled, al

		.leave
		ret
GetKinsokuDisabled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetKinsoku
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the kinsoku characters

CALLED BY:	GLOBAL
PASS:		es:di - ptr to NULL-terminated text (MAX_KINSOKU_CHARS)
		al - KinsokuState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalSetKinsoku		proc	far
		uses	bx, cx, dx, si, di, ds, es
		.enter

		mov	cl, al
		call	SetKinsokuDisabled

		and	al, mask KS_CHARS	;we don't need enabled field
		call	KCGetInfo
	;
	; Figure out how long the string is
	;
		call	LocalStringLength
EC <		cmp	cx, MAX_KINSOKU_CHARS				>
EC <		ERROR_A LOCAL_TOO_MANY_KINSOKU_CHARS			>
		push	cx
	;
	; Write the beasty to the GEOS.INI file
	;
		mov	cx, cs
		mov	dx, cs:[bx].KBI_key	;cx:dx <- ptr to key
		call	InitFileWriteString
	;
	; Write the beasty to our buffer in idata
	;
		pop	cx			;cx <- length
		segmov	ds, es
		mov	si, di			;ds:si <- source
		LoadVarSeg es
		mov	di, cs:[bx].KBI_buffer	;es:di <- dest
		mov	es:[di][-2], cx		;store length
		call	CopyAndNullTerminate

		.leave
		ret
LocalSetKinsoku		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetKinsoku
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the kinsoku chars

CALLED BY:	GLOBAL
PASS:		es:di - ptr to buffer (MAX_KINSOKU_CHARS+1)
		al - KinsokuCharType
RETURN:		es:di - buffer filled, NULL-terminated
		ah - version # of kinsoku chars
		al - KinsokuState w/ KS_DISABLED set from .ini
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently always returns 0 for the version #.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetKinsoku		proc	far
		uses	bx, cx, ds, si, di
		.enter
	;
	; Get the pointer to the correct buffer
	;
		call	KCGetInfo
		LoadVarSeg ds
		mov	si, cs:[bx].KBI_buffer	;ds:si <- ptr to source
		mov	cx, ds:[si][-2]		;cx <- length
	;
	; Copy the beasty to the passed buffer
	;
		call	CopyAndNullTerminate
	;
	; Return the version #
	;
		clr	ah			;ah <- version #

		call	GetKinsokuDisabled	;al <- KinsokuState

		.leave
		ret
LocalGetKinsoku		endp

CopyAndNullTerminate	proc	near
		uses	ax
		.enter
	
		LocalCopyNString		;copy me jesus
		clr	ax
		LocalPutChar	esdi, ax	;NULL-terminate

		.leave
		ret
CopyAndNullTerminate	endp

else

LocalSetKinsoku	proc	far
	ret
LocalSetKinsoku	endp

LocalGetKinsoku	proc	far
	ret
LocalGetKinsoku	endp

endif

ObscureInitExit	ends
