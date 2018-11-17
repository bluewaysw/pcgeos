COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		utilCode.asm

ROUTINES:
	INT	GetNextFilename - parse filename list
	INT	CompareString - compare null-terminated strings
	INT	CopyNullString - copy null-terminated string
	INT	IndicateBusy - show BUSY ptr to mark long disk access
	INT	IndicateNotBusy - restore ptr
	INT	DesktopMarkActive
	INT	MarkNotActive
	INT	DesktopOKError - error box with OK

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains desktop utility routines.

	$Id: cutilCommon.asm,v 1.1 97/04/04 15:02:03 newdeal Exp $

------------------------------------------------------------------------------@

PseudoResident segment resource

;
; these routines are pretty fast, so leave them in fixed (used to be) code
; so they can be called quickly
;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDosYearToActualYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert DOS year (1980-based) to an actual year that
		can be used in date formats like 6/12/90 (passed to
		localization driver)

CALLED BY:	ShowCurrentGetInfoFile
		DrawFullFileDetail

PASS:		ax - DOS year (from 0-127 (7 bits))

RETURN:		ax - actual year

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertDOSYearToActualYear	proc	far
if 0
	add	ax, 80				; convert to 1900-based year
	cmp	ax, 100				; beyond 2000?
	jb	done				; no, done
	sub	ax, 100				; convert to 2000-based year
	cmp	ax, 100				; beyond 2100?
	jb	done				; no, done
	sub	ax, 100				; convert to 2100-based year
EC <	cmp	ax, 100							>
EC <	ERROR_AE	DESKTOP_FATAL_ERROR				>
done:
else
	add	ax, 1980			; that's it!
endif
	ret
ConvertDOSYearToActualYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare null-terminated strings

CALLED BY:	INTERNAL
			FolderCheckPath
			FindCollapsedPathname

PASS:		ds:si - string 1 (null-terminated)
		es:di - string 2 (null-terminated)

RETURN:		Z set if strings are equal
		Z clear if string are not equal
		can also use unsigned comparison results

DESTROYED:	SBCS: ax, si, di DBCS: none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		An alternate bit of code to do this:
			push	di
			clr	al
			mov	cx, -1
			repne scasb		; find null-term. in string 2
			mov	cx, di
			pop	di		; restore pointer to string 2
			sub	cx, di		; cx = #chars+null in string 2
			repe cmpsb		; compare strings till null
			ret
		While this is smaller and, in some cases, faster, the routine
		used below is more suited to types of comparisons we will
		be doing, namely pathnames that will usually be different
		early on in the path.

		The above no longer works since we want to ignore case.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/9/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS

CompareString	proc	far
	uses	cx
	.enter

	clr	cx				;cx <- names are NULL-terminated
	call	LocalCmpStringsNoCase

	.leave
	ret
CompareString	endp

UpCaseAX	proc	far
	call	LocalUpcaseChar
	ret
UpCaseAX	endp

UpCaseDX	proc	far
	xchg	ax, dx				;ax <- char to upcase
	call	LocalUpcaseChar
	xchg	ax, dx				;dx <- upcased char
	ret
UpCaseDX	endp

else

CompareString	proc	far
	dec	di				; prepare for loop
CS_checkLoop:
	inc	di
	lodsb					; al=next char of string 1
	tst	al				; check if null-terminator
	jz	CS_atNull			; if so, check if string 2 ends
;	cmp	al, es:[di]			; else, check for match
;ignore case:
	call	UpCaseAL			; convert AL to uppercase
	mov	ah, es:[di]
	call	UpCaseAH			; convert AH to uppercase
	cmp	al, ah				; compare 'em
	je	CS_checkLoop			; if match, check next char.
	jmp	short CS_done			; else return not-equal
CS_atNull:
	cmp	al, {byte} es:[di]		; check if new pathname ends
						; if so, returns equal
						; else, returns not-equal
						; (unsigned cmp also valid)
CS_done:
	ret
CompareString	endp

UpCaseAL	proc	far
	uses	bx, di
	.enter
	mov	bh, ah
	clr	ah
	call	LocalUpcaseChar
	mov	ah, bh
	.leave
	ret
UpCaseAL	endp

UpCaseAH	proc	far
	xchg	al, ah
	call	UpCaseAL
	xchg	al, ah
	ret
UpCaseAH	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNullString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy null-terminated string (DOES NOT COPY NULL)

CALLED BY:	INTERNAL

PASS:		ds:si - source string to copy (null-terminated)
		es:di - destination for string

RETURN:		di - next byte in destination

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNullString	proc	far
	uses	ax, si
	.enter

startLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	done
	LocalPutChar esdi, ax
	jmp	startLoop
done:
	.leave
	ret
CopyNullString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNullTermString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string, copying the null-terminator as well

CALLED BY:	EXTERNAL

PASS:		ds:si - source
		es:di - destination

RETURN:		es:di - points AFTER null

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNullTermString	proc	far
	call	CopyNullString
SBCS <	clr	al						>
DBCS <	clr	ax						>
SBCS <	stosb							>
DBCS <	stosw							>
	ret
CopyNullTermString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNullSlashString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string, and ensure it has a trailing backslash

CALLED BY:	EXTERNAL

PASS:		ds:si - source string
		es:di - destination buffer

RETURN:		es:di - pointing AFTER trailing backslash

DESTROYED:	al

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 5/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNullSlashString	proc far

	uses	dx
	.enter
	mov	dx, di				; save orig di for cmp
	call	CopyNullString
	LocalLoadChar ax, '\\'

	; If di hasn't moved in CopyNullString, it is pointing at the
	; beginning of the passed string; therefore: (1) we don't have
	; a slash and (2) the address es:[di]-1 is outside the bounds
	; of the string.
	cmp	di, dx
	je	noSlash
SBCS <	cmp	es:[di]-1, al			; have slash?		>
DBCS <	cmp	es:[di][-2], ax			; have slash?		>
	je	haveSlash			; yes
noSlash:
SBCS <	stosb					; else, store it	>
DBCS <	stosw					; else, store it	>
haveSlash:
	.leave
	ret

CopyNullSlashString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ASCIIizeWordAX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts AX to ASCII string

CALLED BY:	INTERNAL

PASS:		ax - word to print
		es:di - buffer for ASCII string

RETURN:		buffer filled with null-terminated ASCII string
		di = points AT null-terminator

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ASCIIizeWordAX	proc	far
	uses	bx, cx, dx
	.enter
	mov	bx, 10				; print in base ten
	clr	cx
AWA_nextDigit:
	clr	dx
	div	bx
	add	dl, '0'				; convert to ASCII
	push	dx				; save resulting character
	inc	cx				; bump character count
	tst	ax				; check if done
	jnz	AWA_nextDigit			; if not, do next digit
AWA_nextChar:
	pop	ax				; retrieve character (in AL)
SBCS <	stosb					; stuff in buffer	>
DBCS <	stosw					; stuff in buffer	>
	cmp	cx, 4
	jne	skipComma
	call	GetThousandsSeparator		; neaten output
SBCS <	stosb								>
DBCS <	stosw								>
skipComma:
	loop	AWA_nextChar			; loop to stuff all
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	stosb					; null-terminate it	>
DBCS <	stosw					; null-terminate it	>
	dec	di
DBCS <	dec	di							>
	.leave
	ret
ASCIIizeWordAX	endp

;
; pass: nothing
; returns: ax = thousands separator
GetThousandsSeparator	proc	near
	uses	bx, cx, dx
	.enter
	call	LocalGetNumericFormat
	mov	ax, bx				; ax = thousands separator
	.leave
	ret
GetThousandsSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ASCIIizeDWordAXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts AX:DX to ASCII string. This is different from
		UtilHex32ToAscii, as it also puts in thousands-separators

CALLED BY:	INTERNAL

PASS:		ax:dx - dword to print
		es:di - buffer for ASCII string
				(at least 14 chars)

RETURN:		buffer filled with null-terminated ASCII string
		di = points AT null-terminator

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/24/90		clean-up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ASCIIizeDWordAXDX	proc	far
	uses	ax, bx, cx, dx, bp
	.enter
	mov	bx, 10				;print in base ten
	clr	cx				;initialize character count
nextDigit:
	mov	bp, dx				;bp = low word
	clr	dx				;dx:ax = high word
	div	bx
	xchg	ax, bp				;ax = low word, bp = quotient
	div	bx
	xchg	ax, dx				;ax = remainder, dx = quotient

	add	al, '0'				;convert to ASCII
	push	ax				;save character
	inc	cx

	mov	ax, bp				;retrieve quotient of high word
	or	bp, dx				;check if done
	jnz	nextDigit			;if not, do next digit

nextChar:
	pop	ax				;retrieve character
SBCS <	stosb								>
DBCS <	stosw								>
	cmp	cx, 10
	je	storeComma
	cmp	cx, 7
	je	storeComma
	cmp	cx, 4
	jne	afterComma
storeComma:
	call	GetThousandsSeparator
SBCS <	stosb								>
DBCS <	stosw								>
afterComma:
	loop	nextChar			;loop to print all

SBCS <	clr	al				; null-terminate	>
DBCS <	clr	ax							>
SBCS <	stosb								>
DBCS <	stosw								>
	dec	di				; point at null-terminator
DBCS <	dec	di							>

	.leave
	ret
ASCIIizeDWordAXDX	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTailComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return tail component of path

CALLED BY:	DesktopYesNoWarning
		CheckParameters
		CheckAssociation

PASS:		ds:dx = pathname

RETURN:		ds:dx = tail component

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/?/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTailComponent	proc	far
	uses	ax, bx, si
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, dsdx					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif

	mov	si, dx

saveBSPosition:
	mov	dx, si
findBSLoop:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, '\\'
	je	saveBSPosition
	LocalIsNull	ax
	jnz	findBSLoop

	.leave
	ret
GetTailComponent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildCompletePathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	builds complete pathname from partial pathname

CALLED BY:	INTERNAL
			MarkWindowForUpdate

PASS:		ax:bx = partial/complete path
		cx:dx = buffer for complete pathname

RETURN:		cx:dx = filled with complete pathname w/o drive
		si = offset to position for delimiter marking off
			pathname tail

DESTROYED:	ax, cx
		preserves bx, dx, ds, es, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/8/89		Initial version
	brianc	9/21/89		call GeodeGetCurrentPath to get current
					drive and path (protected mode
					support)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildCompletePathname	proc	far
	uses	bx, ds, di, es, bp, dx
	.enter
	
	mov	ds, ax				; ds:si = partial/complete path
	mov	si, bx

	mov	es, cx				; es:di = buffer for path
	mov	di, dx

	clr	bx				; use current path
	mov	cx, PATH_BUFFER_SIZE		; cx <- presumed buffer size
	mov	dx, FALSE			; add drive specifier
	call	FileConstructFullPath

	LocalLoadChar ax, C_BACKSLASH
	std
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
EC <	ERROR_NE	DESKTOP_FATAL_ERROR	; => no separator, not possible>
	cld
SBCS <	lea	si, es:[di+1]			; point to separator	>
DBCS <	lea	si, es:[di+2]			; point to separator	>
	.leave
	ret
BuildCompletePathname	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Indicate{Busy,NotBusy}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show watch pointer to indicate time-consuming activity

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		BUSY indicator set/cleared

DESTROYED:	nothing (even flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/?/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IndicateBusy	proc	far
	pushf
	push	ax
EC <	push	ds, bx							>
EC <	mov	ax, ss							>
EC <	GetResourceSegmentNS dgroup, ds					>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ds, bx							>
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	tst	ss:[fileDragging]
	jz	okay
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
okay:
	call	IndicateCommon
	pop	ax
	popf
	ret
IndicateBusy	endp

IndicateNotBusy	proc	far
	pushf
	push	ax
EC <	push	ds, bx							>
EC <	mov	ax, ss							>
EC <	GetResourceSegmentNS dgroup, ds					>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	DESKTOP_FATAL_ERROR				>
EC <	pop	ds, bx							>
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	tst	ss:[fileDragging]
	jz	okay
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
okay:
	call	IndicateCommon
	pop	ax
	popf
	ret
IndicateNotBusy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to send a message to the application.
		Don't send it MF_CALL, as there's no point in waiting
		around until this message is handled.

CALLED BY:	IndicateBusy, IndicateNotBusy, ShowHourglass, HideHourglass

PASS:		ax - message to send

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 8/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IndicateCommon	proc	near
		uses	bx, si, di
		.enter
		mov	bx, handle GenAppInterface
		mov	si, offset GenAppInterface:Desktop
		call	ObjMessageNone
		.leave
		ret
IndicateCommon	endp

ShowHourglass	proc	far
		uses	ax
		.enter
		pushf
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	IndicateCommon
		popf
		.leave
		ret
ShowHourglass	endp

HideHourglass	proc	far
		uses	ax
		.enter
		pushf
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	IndicateCommon
		popf
		.leave
		ret
HideHourglass	endp

ForceShowHourglass	proc	far
		uses	ax
		.enter
		pushf
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		call	IndicateCommon
		mov	ax, MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE
		call	IndicateCommon
		popf
		.leave
		ret
ForceShowHourglass	endp

ForceHideHourglass	proc	far
		uses	ax
		.enter
		pushf
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		call	IndicateCommon
		mov	ax, MSG_GEN_APPLICATION_SET_USER_INTERACTABLE
		call	IndicateCommon
		popf
		.leave
		ret
ForceHideHourglass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopMarkActive, MarkNotActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	indicate application is active

CALLED BY:	INTERNAL

PASS:		ax - ActiveType (DesktopMarkActive)

RETURN:		Z clear if detaching already, Z set otherwise (DesktopMarkActive)
		nothing (MarkNotActive)

DESTROYED:	nothing
		flags preserved (MarkNotActive)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopMarkActive	proc	far
EC <	cmp	ax, ActiveType						>
EC <	ERROR_AE	DESK_BAD_PARAMS					>
	push	ax, si, es
NOFXIP<	segmov	es, <segment dgroup>, si				>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	es:[detachActiveHandling], FALSE	; not yet...
	mov	es:[activeType], ax		; save active type
	mov	si, ax
	movdw	es:[activeBox], cs:[ActiveBox][si], ax
	movdw	es:[activeText], cs:[ActiveText][si], ax
	movdw	es:[activeNoAttn], cs:[ActiveNoAttn][si], ax
	movdw	es:[activeAttn], cs:[ActiveAttn][si], ax
	mov	ax, MSG_APP_MARK_ACTIVE
	call	DesktopMarkActiveCommon
	pop	ax, si, es
	ret
DesktopMarkActive	endp

MarkNotActive	proc	far
	push	ax
	pushf
	mov	ax, MSG_APP_MARK_NOT_ACTIVE
	call	DesktopMarkActiveCommon
	popf
	pop	ax
	ret
MarkNotActive	endp

DesktopMarkActiveCommon	proc	near
	uses	bx, cx, dx, si, di, bp
	.enter
	mov	bx, handle Desktop
	mov	si, offset Desktop
	call	ObjMessageCall
	cmp	cx, TRUE			; set Z for DesktopMarkActive
	.leave
	ret
DesktopMarkActiveCommon	endp

;
; these must match ActiveTypes enum
;
ActiveBox	optr	\
	ActiveFormatBox,
	ActiveCopyBox,
	ActiveFileOpBox

ActiveText	optr	\
	ActiveFormatText,
	ActiveCopyText,
	ActiveFileOpText

ActiveNoAttn	optr	\
	ActiveFormatNoAttentionText,
	ActiveCopyNoAttentionText,
	ActiveFileOpNoAttentionText

ActiveAttn	optr	\
	ActiveFormatAttentionText,
	ActiveCopyAttentionText,
	ActiveFileOpAttentionText


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		space saving routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load up flags and call ObjMessage

CALLED BY:	INTERNAL

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/20/90	Initial version
	AY	11/25/92	Changed call's to GOTO's (60 vs 15 cycles in
				non-EC)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageNone	proc	far
	clr	di
	GOTO	ObjMessage
ObjMessageNone	endp

ObjMessageCall	proc	far
	mov	di, mask MF_CALL
	GOTO	ObjMessage
ObjMessageCall	endp

ObjMessageFixup	proc	far
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage
ObjMessageFixup	endp

ObjMessageCallFixup	proc	far
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
ObjMessageCallFixup	endp

ObjMessageForce	proc	far
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
ObjMessageForce	endp

CallSetText	proc	far
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null-terminated text
	GOTO	ObjMessageCall
CallSetText	endp

CallAppendText	proc	far
	mov	ax, MSG_VIS_TEXT_APPEND
	clr	cx
	GOTO	ObjMessageCall
CallAppendText	endp

CallFixupSetText	proc	far
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null-terminated text
	GOTO	ObjMessageCallFixup
CallFixupSetText	endp

LockString	proc	far
	push	bx
	mov	bx, handle DeskStringsCommon
	call	MemLock		; ax = segment
	mov	dx, ax
	pop	bx
	ret
LockString	endp

DerefDXBPString	proc	far
	push	ax, si, ds
	mov	ds, dx				; ds:*si = string
	mov	si, bp
	lodsw					; ds:ax = string
	mov	bp, ax				; ds:bp = string
	pop	ax, si, ds
	ret
DerefDXBPString	endp

UnlockString	proc	far
	push	bx
	mov	bx, handle DeskStringsCommon
	call	MemUnlock
	pop	bx
	ret
UnlockString	endp

PseudoResident ends
