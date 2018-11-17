include geos.def
include heap.def
include geode.def
include ec.def
include file.def

include resource.def
include system.def
include driver.def

include IDialppp.def

UseLib	ui.def
include Objects/gCtrlC.def
UseLib	accpnt.def

udata	segment
	pppStrategy	fptr
	pppDr		word
	libHandle	word
udata	ends

CommonCode	segment resource

LocalDefNLString	socketString, <"socket", 0>
EC <LocalDefNLString	pppName, <"pppec.geo", 0>		>
NEC<LocalDefNLString	pppName, <"ppp.geo", 0>		>

COMMENT @----------------------------------------------------------------

C FUNCTION:	LoadPPPDriver

DESCRIPTION:	

C DECLARATION:	extern void _far
		_pascal LoadPPPDriver ()
STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	11/30/98	initial version
-------------------------------------------------------------------------@
	SetGeosConvention
LOADPPPDRIVER		proc	far	
		uses	bx, ds, si, dx, ax, es, bp, di
		.enter

		call	FilePushDir
		mov	bx, SP_SYSTEM
		segmov	ds, cs, si
		mov	dx, offset socketString
		call	FileSetCurrentPath
		jc	done

		mov	ax, 0
		mov	bx, 0
		segmov	ds, cs, si
		mov	si, offset pppName		; ds:si = driver name
		call	GeodeUseDriver
		jc	done

; In a C routine or C stub, you can't assume ES to be anything.  --- AY
		segmov	es, dgroup, ax
		mov	es:[pppDr], bx
	;
	; Get the strategy routine.
	;
		call	GeodeInfoDriver
		movdw	es:[pppStrategy], ds:[si].DIS_strategy, ax
		clc
done:
		call	FilePopDir
		.leave
		ret

LOADPPPDRIVER		endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UNLOADPPPDRIVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	UnloadPPPDriver

DESCRIPTION:	Unload the PPP driver.

C DECLARATION:	extern void _far
		_pascal UnloadPPPDriver ()

STRATEGY:	Clear pppDr and call GeodeFreeDriver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/11/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
UNLOADPPPDRIVER	proc	far
	uses	bx, es
	.enter

	segmov	es, dgroup, bx
	clr	bx			; bx <- 0
	xchg	es:[pppDr], bx		; bx <- pppDr, pppDr <- 0

	call	GeodeFreeDriver

	.leave
	ret
UNLOADPPPDRIVER	endp
	SetDefaultConvention

CommonCode	ends

IDINFO_TIMER_TEXT	segment public 'CODE'

COMMENT @----------------------------------------------------------------

C FUNCTION:	call ppp driver function

DESCRIPTION:	

C DECLARATION:	extern unsigned long _far
		_pascal CallPPPDriver (int func, word data)
STRATEGY:
		dx = high word
		ax = low word

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	11/30/98	initial version
-------------------------------------------------------------------------@
	SetGeosConvention
CALLPPPDRIVER		proc	far	func:word,
					data:word
		uses	di, cx, bx
		.enter

		mov	di, func
; In a C routine or C stub, you can't assume ES to be anything.  --- AY
		segmov	es, dgroup, ax
		mov	ax, data
		call	es:[pppStrategy]

		.leave
		ret

CALLPPPDRIVER		endp

IDINFO_TIMER_TEXT	ends

PhoneUtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GETPHONESTRINGWITHOPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the phone string with dialing options applied.

DESCRIPTION:	This code was shamelessly stolen from a similar routine
		in the Access Point Library.  That routine unfortunately
		requires an existing access point, while we may be doing
		this prior to actually creating an access point.  The effort
		required to add another entry point to same library just for
		this singlar purpose did not seem worthwhile.  Fine, call me
		lazy, I don't care! :P

CALLED BY:	MSG_IDP_EDIT_OK

C DECLARATION:	extern MemHandle _far
		_pascal GetPhoneStringWithOptions (MemHandle phoneHan,
			AccessPointLocalDialingOptions localDialOptions)

RETURNS:	Handle of block allocated for resultant string

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	5/17/2000	Adapted from accpnt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PREAMBLE_LEN equ 32

GETPHONESTRINGWITHOPTIONS	proc	far	phoneHan:hptr,
			localDialOptions:AccessPointLocalDialingOptions

		uses	dx,si,di,ds,es
		clr	ax
returnHan		local	hptr		push ax
preamble		local	PREAMBLE_LEN dup (TCHAR)
areaCode		local	3 dup (TCHAR)
prefix			local	3 dup (TCHAR)
extension		local	4 dup (TCHAR)
dialOptions		local	AccessPointDialingOptions
if DBCS_PCGEOS
areaCodeLen		local	byte
endif
		.enter

		mov	ax, 112*(size TCHAR)		; big enuf!
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
	   LONG	jc	done
		mov	ss:[returnHan], bx

		mov	bx, ss:[phoneHan]
		call	MemLock
	   LONG	jc	done				; may leak memory
		mov	ds, ax
		clr	si

		mov	bx, ss:[returnHan]
		call	MemLock
	   LONG	jc	unlockPropHan			; may leak memory
		mov	es, ax
		clr	di

	; ds:si = original phone number
	; es:di = return phone number
	;
	; bl = numDigits
	; bh = garbageInString
	; cl = firstDigitIs1
	; ch = preambleLen
		clr	bx, cx

	; First time through, figure out how many actual digits we have
	; and some things about it.  Store a preamble, valid dial chars
	; before the first digits, just in case.
loop1:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	doneLoop1

		inc	bh			; assume garbage, but digit
		LocalCmpChar	ax, '#'		; (which means # or *)
		je	haveDigit1
		LocalCmpChar	ax, '*'
		je	haveDigit1
		dec	bh			; unassume garbage
		LocalCmpChar	ax, '0'
		jb	noDigit1
		LocalCmpChar	ax, '9'
		ja	noDigit1

haveDigit1:
		tst	bl			; numDigits == 0
		jnz	alreadyHaveOneDigit1
		LocalCmpChar	ax, '1'		; first digit == 1
		jne	alreadyHaveOneDigit1
		inc	cl			; first digit is a 1.. note it

alreadyHaveOneDigit1:
		inc	bl			; inc count of digits
		jmp	loop1

noDigit1:
		LocalCmpChar	ax, '-'		; check for useless (,),- chars
		je	loop1			; they aren't garbage, fluff
		LocalCmpChar	ax, '('
		je	loop1
		LocalCmpChar	ax, ')'
		je	loop1
		tst	bl			; numDigits ==0 ?
		jnz	garbageLoop1		; nope - no preamble, garbage
		cmp	ch, PREAMBLE_LEN	; preambleLen < PREAMBLE_LEN
		jae	garbageLoop1		; nope - garbage
		push	bx			; stuff in preamble
		lea	bx, ss:[preamble]
		add	bl, ch
DBCS <		adc	bh, 0						>
DBCS <		add	bl, ch						>
		adc	bh, 0
		LocalPutChar	ssbx, ax
		pop	bx
		inc	ch			; preambleLen++
		jmp	loop1			; no garbage

garbageLoop1:
		inc	bh			; yup, garbage
		jmp	loop1

doneLoop1:
	; Get the dialing options (in local variable).. we need to, no matter
	; what, stuff the 'T' or 'P' in the output string.   (We may bail below
	; by stuffing the input string to the output string; however, we still
	; would like the T or P present.)
	;
		push	cx
		mov	cx, ss
		lea	dx, ss:[dialOptions]	; dx unused so far
		call	AccessPointGetDialingOptions
		pop	cx

	; Write dial method ('T' or 'P') out first.
	;
		mov	al, ss:[dialOptions].APDO_dialMethod
DBCS <		clr	ah						>
		LocalPutChar	esdi, ax

	; At this point, we can figure out if we are going to just stuff the
	; string out as it came in because we have garbage or unparse-able
	; stuff.
		tst	bh			; garbageInString
		jnz	stuffIt
		tst	cl			; first digit is 1 ?
		jnz	stuffItFDI1
		cmp	bl, 7			; first dig not 1.. 7 or 10 digs
		je	pressOn			; get to pass GO.
		cmp	bl, 10
		je	pressOn
stuffIt:
		mov	cx, si			; cx=si = num chars in string
		clr	si			; since ds:0 is byte 0
		LocalCopyNString		; includes null terminator
		jmp	doneSuccess

stuffItFDI1:
		cmp	bl, 11			; first dig is 1.. do we have
		jne	stuffIt			; 11 digits? If not, garbage!

pressOn:
	; ds:si = original phone number
	; es:di = return phone number
	; bl = numDigits
	; bh = numDigits2 (for second loop)  (was garbage counter.. must be 0)
	; cl = firstDigitIs1
	; ch = preambleLen
	; ah = areaCodeLen
	; dl = prefixLen
	; dh = extLen
EC <		tst	bh						>
EC <		ERROR_NZ -1						>
		clr	dx, si
SBCS <		clr	ah						>
DBCS <		clr	ss:[areaCodeLen]				>

	; This time through, we parse out area code, prefix, and extension.
	; Oh, this is fun in ASM!
loop2:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	doneLoop2

		LocalCmpChar	ax, '0'			; isdigit?
		jb	loop2
		LocalCmpChar	ax, '9'
		ja	loop2

		tst	bh			; first digit this loop?
		jnz	notFirst2
		tst	cl			; first digit should be 1?
		jz	notFirst2
EC <		LocalCmpChar	ax, '1'					>
EC <		ERROR_NE -1						>
		clr	cl			; clear firstDigit and
						; don't count this digit
		jmp	loop2

notFirst2:
		cmp	bl, 10			; do we have 10 digits?
		jb	tryPrefix2
SBCS <		cmp	ah, 2			; are seeing the first 3 still?>
DBCS <		cmp	ss:[areaCodeLen], 2	; are seeing the first 3 still?>
		ja	tryPrefix2
		push	bx			; yes.. write area code.
		lea	bx, ss:[areaCode]
SBCS <		add	bl, ah						>
DBCS <		add	bl, ss:[areaCodeLen]				>
DBCS <		adc	bh, 0						>
DBCS <		add	bl, ss:[areaCodeLen]				>
		adc	bh, 0
		LocalPutChar	ssbx, ax
		pop	bx
SBCS <		inc	ah			; ++areaCodeLen		>
DBCS <		inc	ss:[areaCodeLen]	; ++areaCodeLen		>
incloop2:
		inc	bh			; ++numDigits2
		jmp	loop2

tryPrefix2:
		cmp	dl, 2			; do we have 3 prefix yet?
		ja	tryExt2
		push	bx			; no.. write in prefix.
		lea	bx, ss:[prefix]
		add	bl, dl
DBCS <		adc	bh, 0						>
DBCS <		add	bl, dl						>
		adc	bh, 0
		LocalPutChar	ssbx, ax
		pop	bx
		inc	dl			; ++prefixLen
		jmp	incloop2

tryExt2:
		cmp	dh, 3			; have we filled ext yet?
EC <		ERROR_A -1			; BAD BAD		>
NEC <		ja	doneLoop2		; don't count anymore!	>
		push	bx			; no.. write in extension.
		lea	bx, ss:[extension]
		add	bl, dh
DBCS <		adc	bh, 0						>
DBCS <		add	bl, dh						>
		adc	bh, 0
		LocalPutChar	ssbx, ax
		pop	bx
		inc	dh			; ++extensionLen
		jmp	incloop2

doneLoop2:
if	ERROR_CHECK
		cmp	di, 1*(size TCHAR)	; di should be 1 ('T' or 'P')
		ERROR_NZ -1
		cmp	dl, 3			; prefixLen == 3
		ERROR_NE	-1
		cmp	dh, 4			; && extensionLen == 4
		ERROR_NE	-1
		cmp	bh, 7			; numDigits2 == 7
		je	ecOK			; cool
		cmp	bh, 10			; numDigits == 10
		ERROR_NE -1			; MUST BE!
SBCS <		cmp	ah, 3			; areaCodeLen == 3	>
DBCS <		cmp	ss:[areaCodeLen], 3	; areaCodeLen == 3	>
		ERROR_NE	-1		
ecOK:
endif
	; Let's build the return value now!
	;
	; es:di = return phone number
	; bl = <DONT CARE>
	; bh = numDigits2 (for second loop)  (was garbage counter.. must be 0)
	; cl = <DONT CARE>
	; ch = preambleLen
	; ah = areaCodeLen
	; dl = prefixLen
	;

	; All our source data comes from the stack now, daddy-o.
	;
		segmov	ds, ss

	; Copy out the preamble, if any.
	;
		tst	ch			; preamble?
		jz	noPreamble
		lea	si, ss:[preamble]
		push	ax
		clr	cl
		xchg	ch, cl
		LocalCopyNString
		pop	ax

	; cx = <DONT CARE>

	; Check the outside line action.
	;
noPreamble:
		tst	ss:[dialOptions].APDO_outsideLine
		jz	noOutsideLine
		lea	si, ss:[dialOptions].APDO_outsideLine
		clr	bl			; pause counter
olCopy:
		LocalGetChar	ax, dssi	; 0-terminated
		LocalIsNull	ax
		jz	olCopyDone
		LocalPutChar	esdi, ax
		LocalCmpChar	ax, ','
		jne	olCopy
		inc	bl
		jmp	olCopy

olCopyDone:	; Append pause ',' if none already.
		LocalLoadChar	ax, ','
		tst	bl
		jnz	noOutsideLine
		LocalPutChar	esdi, ax

	; Check the call waiting action.
	;
noOutsideLine:
		tst	ss:[dialOptions].APDO_callWaiting
		jz	noCallWaiting
		lea	si, ss:[dialOptions].APDO_callWaiting
		clr	bl			; pause counter
cwCopy:
		LocalGetChar	ax, dssi	; 0-terminated
		LocalIsNull	ax
		jz	cwCopyDone
		LocalPutChar	esdi, ax
		LocalCmpChar	ax, ','
		jne	cwCopy
		inc	bl
		jmp	cwCopy

cwCopyDone:	; Append pause ',' if none already.
		LocalLoadChar	ax, ','
		tst	bl
		jnz	noCallWaiting
		LocalPutChar	esdi, ax

	; Do we stick out an area code?
	;   cx = offset to which area code to use
noCallWaiting:
		clr	cx			; no area code at first
		test	ss:[localDialOptions], mask APLDO_ALWAYS_ADD_AREA_CODE
		jnz	forced
		tst	ss:[dialOptions].APDO_tenDigit
		jz	notForced
forced:
		cmp	bh, 10			; numDigits2
		jne	forcedNot10
useSupplied:
		lea	cx, ss:[areaCode]
		jmp	haveArea
forcedNot10:
	; Need 10 digits, don't have 10.. use default area code
		tst	ss:[dialOptions].APDO_areaCode
		jz	noAreaCode		; no default.. oh well
		lea	cx, ss:[dialOptions].APDO_areaCode
		jmp	haveArea

notForced:
	; Not forced to.  Do we have 10 digits? If not, no need for
	; an area code.
		cmp	bh, 10			; numDigits2
		jne	noAreaCode		; nope! done.
		tst	ss:[dialOptions].APDO_areaCode	; no default to cmp?
		jz	useSupplied		; use one supplied
	; We have 10 digits and we have a default area code.  We need
	; to compare them to see if we have to dial it.
		push	es,ds,si,di,cx
		segmov	ds, ss, si
		mov	es, si
		lea	si, ss:[dialOptions].APDO_areaCode
		lea	di, ss:[areaCode]
		mov	cx, 3
SBCS <		repe cmpsb						>
DBCS <		repe cmpsw						>
		pop	es,ds,si,di,cx
		je	noAreaCode		; EQUAL.. no area code needed
		jmp	useSupplied		; otherwise, use supplied code

haveArea:
	; Area code required.. Write out a "1-<area code>-"
	; If APLDO_OMIT_ONE_FOR_LONG_DISTANCE, skip the "1-".
		test	ss:[localDialOptions], mask APLDO_OMIT_ONE_FOR_LONG_DISTANCE
		jnz	skipOne
		LocalLoadChar	ax, '1'
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax
skipOne:
		mov	si, cx			; copy 3 byte area code.
		mov	cx, 3
		LocalCopyNString
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax

noAreaCode:
	; Finally, the rest of the damn thing.
		lea	si, ss:[prefix]
		mov	cx, 3
		LocalCopyNString
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax

		lea	si, ss:[extension]
		mov	cx, 4
		LocalCopyNString
		LocalClrChar	ax
		LocalPutChar	esdi, ax	; 0 terminate it

doneSuccess:
		mov	bx, ss:[returnHan]
		call	MemUnlock		; flags preserved

unlockPropHan:
		mov	bx, ss:[phoneHan]
		call	MemUnlock		; flags preserved

	; Return the return handle in AX.
	;
		mov	ax, ss:[returnHan]

done:
		.leave
		ret
GETPHONESTRINGWITHOPTIONS	endp

	SetDefaultConvention

PhoneUtilCode	ends
