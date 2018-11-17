COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Icon
FILE:		iconMain.asm

AUTHOR:		Martin Turon, October 19, 1992

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/19/92	Initial version

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: iconMain.asm,v 1.1 97/04/07 10:45:28 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellLoadMoniker
----------------------------------------------------------------------------

DESCRIPTION:	Loads the VisMoniker for the given GeodeToken from the
		token database.

CALLED BY:	GLOBAL

PASS:		ax:cx:dx	= GeodeToken

RETURN:		^lcx:dx		= optr to VisMoniker
		CF		= set if error
				  clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The caller is responsible for freeing the block containing the
	returned VisMoniker, this can be done in the following way:
		mov	bx, cx
		call	MemFree

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/21/92	Initial version

---------------------------------------------------------------------------@
ShellLoadMoniker	proc	far
	uses	bx, di, si
	.enter
	push	ax, cx, dx
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	mov	cx, bx				; cx = lmem block handle
	call	UserGetDisplayType
	mov	dh, ah
;---------------------------------------------------------------------------
	;
	; match FileMgr code - brianc 3/28/93
	;
	; keep to DS_STANDARD or smaller (i.e. convert DS_HUGE and DS_LARGE
	; into DS_STANDARD)
	;
	mov	bl, dh
	andnf	bl, mask DT_DISP_SIZE		; cl = DisplaySize
	.assert DS_STANDARD gt DS_TINY
	.assert DS_LARGE gt DS_STANDARD
	.assert DS_HUGE gt DS_LARGE
	cmp	bl, DS_STANDARD shl offset DT_DISP_SIZE
	jbe	20$
	andnf	dh, not mask DT_DISP_SIZE	; clear current size
						; set DS_STANDARD
	ornf	dh, DS_STANDARD shl offset DT_DISP_SIZE
20$:
;---------------------------------------------------------------------------
	pop	ax, bx, si

	push	cx
	mov	di, (VMS_ICON shl offset VMSF_STYLE) or mask VMSF_GSTRING
	push	di
	clr	di
	push	di				; required by TokenLoadMoniker
	call	TokenLoadMoniker		; grab moniker from token.db
						; returns cx = moniker size
	pop	cx
	mov	dx, di
	.leave
	ret
ShellLoadMoniker	endp



COMMENT @-------------------------------------------------------------------
			ShellDefineTokens
----------------------------------------------------------------------------

DESCRIPTION:	Inserts all the given tokens into the token db if they
		do not already exist.

CALLED BY:	GLOBAL

PASS:		es:di	= array of TokenMoniker 
		cx	= ShellDefineTokenFlags
		si	= ManufacturerID
		bp	= TokenFlags

		if SDTF_CALLBACK_PROCESSED and/or SDTF_CALLBACK_DEFINED:
			ax:bx	= fptr to callback
				  (vfptr if XIP'ed)


RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		CALLBACK:
			PASS:		axbxsi	= GeodeToken
					^lcx:dx	= moniker (if defined)

			RETURN:		nothing
			DESTROYED:	ax, bx, cx, dx, bp, di, si, ds, es
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
ShellDefineTokens	proc	far
tokenFlags	local	TokenFlags		push	bp
flags		local	ShellDefineTokenFlags	push	cx
callback	local	fptr			push	ax, bx
		uses	ax, bx, cx, dx, di, si
		.enter

ForceRef	callback

if ERROR_CHECK
	;
	; Validate that the array is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, es							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

setUpLoop:
	;
	; Get the next token.
	;
		movtchr	axbx, es:[di].TM_token
		test	ss:[flags], mask SDTF_FORCE_OVERWRITE
		jnz	defineToken

	;
	; Check if token is in token.db already
	;
		push	bp
		call	TokenGetTokenInfo		; is it there yet?
		pop	bp
		jnc	next				; if so, do next one
	
defineToken:
	;
	; Add/replace token in token.db
	;

		movdw	cxdx, es:[di].TM_moniker
		push	bp
		mov	bp, ss:[tokenFlags]
		call	TokenDefineToken		; add it
		pop	bp

		test	ss:[flags], mask SDTF_CALLBACK_DEFINED
		call	ShellDefineCallCallBackIfFlagSet
next:
		test	ss:[flags], mask SDTF_CALLBACK_PROCESSED
		call	ShellDefineCallCallBackIfFlagSet

		add	di, size TokenMoniker
		cmp	{byte}es:[di], TOKEN_MONIKER_END_OF_LIST
		jne	setUpLoop

		.leave
		ret
ShellDefineTokens	endp




COMMENT @-------------------------------------------------------------------
			ShellDefineCallCallBackIfFlagSet
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	INTERNAL - ShellDefineTokens

PASS:		ZF 	= set if callback should be called
		stack frame of ShellDefineTokens

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/17/92	Initial version

---------------------------------------------------------------------------@
ShellDefineCallCallBackIfFlagSet	proc	near
		.enter inherit ShellDefineTokens
		jz	done
		push	ax, bx, cx, dx, bp, di, si, ds, es
NOFXIP<		call	ss:[callback]					>
FXIP<		mov	ss:[TPD_dataAX], ax				>
FXIP<		mov	ss:[TPD_dataBX], bx				>
FXIP<		movdw	bxax, ss:[callback]				>
FXIP<		call	ProcCallFixedOrMovable				>
		pop	ax, bx, cx, dx, bp, di, si, ds, es
done:
		.leave
		ret
ShellDefineCallCallBackIfFlagSet	endp





