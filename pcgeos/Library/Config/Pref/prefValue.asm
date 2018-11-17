COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefValue.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/21/92   	Initial version.

DESCRIPTION:
	

	$Id: prefValue.asm,v 1.1 97/04/04 17:50:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set carry if current value is different than original
		value. 

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= dgroup

RETURN:		carry set if different

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueHasStateChanged	method	dynamic	PrefValueClass, 
					MSG_PREF_HAS_STATE_CHANGED
	.enter

	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock


	DerefPref ds, si, di
	cmp	dx, ds:[di].PVI_originalValue
	je	done
	stc
done:
	.leave
	ret
PrefValueHasStateChanged	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueSetOriginalValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the "original" value of the PrefValue, and the 
		current value of the GenValue.	

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= Segment of PrefValueClass.
		cx	- value to set
		bp	- nonzero to mark indeterminate

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueSetOriginalValue	method	dynamic	PrefValueClass, 
					MSG_PREF_VALUE_SET_ORIGINAL_VALUE
	uses	ax,cx,dx,bp
	.enter

	mov	ax, ATTR_PREF_VALUE_ORIG_IS_INDETERMINATE or \
			mask VDF_SAVE_TO_STATE
	tst	bp
	jz	nukeIndeterminate
	push	cx
	clr	cx		; no extra data
	call	ObjVarAddData
	pop	cx
	jmp	setValue

nukeIndeterminate:
	call	ObjVarDeleteData

setValue:

	;
	; FIRST, send this value to the superclass, as it may decide
	; to constrain it, or whatever.
	;

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjCallInstanceNoLock

	;
	; NOW, fetch it from the superclass, and store it in our
	; "originalValue" field. XXX: We're only storing the INTEGER
	; value -- is this bad???
	;
	
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock

	DerefPref	ds, si, di
	mov	ds:[di].PVI_originalValue, dx


	.leave
	ret
PrefValueSetOriginalValue	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load options from the .INI file or wherever, and save
		the original value.

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= Segment of PrefValueClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueLoadOptions	method	dynamic	PrefValueClass, 
					MSG_META_LOAD_OPTIONS

	mov	di, offset PrefValueClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_GEN_VALUE_IS_INDETERMINATE
	call	ObjCallInstanceNoLock
	jc	isIndeterminate
	
	mov	ax, ATTR_PREF_VALUE_ORIG_IS_INDETERMINATE
	call	ObjVarDeleteData

getValue:
	mov	ax, MSG_PREF_SET_ORIGINAL_STATE
	GOTO	ObjCallInstanceNoLock	


isIndeterminate:
	mov	ax, ATTR_PREF_VALUE_ORIG_IS_INDETERMINATE or \
			mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
	jmp	getValue
PrefValueLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueGenLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load options from the .INI file.

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= Segment of PrefValueClass.

		ss:bp	= GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
PrefValueGenLoadOptions	method	dynamic	PrefValueClass, 
					MSG_GEN_LOAD_OPTIONS
	;
	; load integer value manually
	;
	push	ds, si
	segmov	ds, ss, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileReadInteger
	pop	ds, si
	jc	noSet
	mov	dx, ax			;dx.cx = value
	clr	bp, cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjCallInstanceNoLock
noSet:
	ret
PrefValueGenLoadOptions	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueGenSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options to the .INI file.

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= Segment of PrefValueClass.

		ss:bp	= GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
PrefValueGenSaveOptions	method	dynamic	PrefValueClass, 
					MSG_GEN_SAVE_OPTIONS

EC <	curValue	local	GEN_VALUE_MAX_TEXT_LEN dup (wchar)	>

	mov	di, bp

EC <	.enter								>

if ERROR_CHECK
	mov	cx, ss
	lea	dx, curValue
	push	bp
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	ObjCallInstanceNoLock
	pop	bp
	push	ds, si
	segmov	ds, cx
	mov	si, dx
checkLoop:
	lodsw
	tst	ax
	jz	checkDone
	cmp	ax, '0'
	ERROR_B	NON_INTEGER_PREF_VALUE
	cmp	ax, '9'
	ERROR_A	NON_INTEGER_PREF_VALUE
	jmp	checkLoop
checkDone:
	pop	ds, si
endif

EC <	push	bp							>
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock		;dx.cx = value
	mov	bp, dx				;bp = int value
	;
	; save integer value manually
	;
	segmov	ds, ss, cx
	lea	si, ss:[di].GOP_category
	lea	dx, ss:[di].GOP_key
	call	InitFileWriteInteger
EC <	pop	bp							>
EC <	.leave								>
	ret
PrefValueGenSaveOptions	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reset the range to its original value

PASS:		*ds:si	= PrefValueClass object
		ds:di	= PrefValueClass instance data
		es	= Segment of PrefValueClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueReset	method	dynamic	PrefValueClass, 
					MSG_GEN_RESET
	.enter

	clr	bp			; assume determinate
	mov	ax, ATTR_PREF_VALUE_ORIG_IS_INDETERMINATE
	call	ObjVarFindData
	jnc	setValue
	dec	bp			; indeterminate

setValue:
	mov	cx, ds:[di].PVI_originalValue
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefValueReset	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Round off the value before passing it up

PASS:		*ds:si	- PrefValueClass object
		ds:di	- PrefValueClass instance data
		es	- dgroup
		dx.cx	- value to set

RETURN:		dx.cx  - rounded appropriately, passed to superclass

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueSetValue	method	dynamic	PrefValueClass, 
					MSG_GEN_VALUE_SET_VALUE
	uses	ax
	.enter
	mov	ax, ATTR_PREF_VALUE_ROUND
	call	ObjVarFindData
	jnc	done
	mov	cx, dx
	call	RoundCX
	clr	dx
	xchg	dx, cx			; dx - rounded integer value
	clr	cx
done:
	.leave
	mov	di, offset PrefValueClass
	GOTO	ObjCallSuperNoLock


PrefValueSetValue	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueSetIntegerValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Round the value before passing it up.

PASS:		*ds:si	- PrefValueClass object
		ds:di	- PrefValueClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

z%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueSetIntegerValue	method	dynamic	PrefValueClass, 
					MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	RoundCX
	mov	di, offset PrefValueClass
	GOTO	ObjCallSuperNoLock
PrefValueSetIntegerValue	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundCX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the attribute exists, round the passed number up or
		down. 

CALLED BY:	PrefValueSetIntegerValue, PrefValueSetValue

PASS:		cx - value to round
		*ds:si - PrefValue

RETURN:		cx - rounded value

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundCX	proc near
	uses	ax,bx,dx
	.enter

	mov	ax, ATTR_PREF_VALUE_ROUND
	call	ObjVarFindData
	jnc	done
	mov	ax, ds:[bx]
	mov	bx, ax

	;
	; NEW = (OLD + R/2)/R * R
	; the rounding 
	;

	shr	ax			; R/2
	add	ax, cx
	clr	dx
	div	bx			; divide dx:ax by R
	mul	bx
	mov_tr	cx, ax			; rounded result

done:
	.leave
	ret
RoundCX	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueSetOriginalState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the state of this object, in case we get a RESET

PASS:		*ds:si	- PrefValueClass object
		ds:di	- PrefValueClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueSetOriginalState	method	dynamic	PrefValueClass, 
					MSG_PREF_SET_ORIGINAL_STATE
		uses	ax,cx,dx,bp
		.enter
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjCallInstanceNoLock

		DerefPref	ds, si, di
		mov	ds:[di].PVI_originalValue, dx

		.leave
		ret
PrefValueSetOriginalState	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefValueIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefValueClass object
		ds:di	- PrefValueClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefValueIncrement	method	dynamic	PrefValueClass, 
					MSG_GEN_VALUE_INCREMENT

		mov	di, offset PrefValueClass
		call	ObjCallSuperNoLock
		jc	done

		mov	cx, MSG_GEN_VALUE_GET_MINIMUM
		call	CheckWrap
done:
		ret
PrefValueIncrement	endm


PrefValueDecrement	method	dynamic	PrefValueClass, 
					MSG_GEN_VALUE_DECREMENT

		mov	di, offset PrefValueClass
		call	ObjCallSuperNoLock
		jc	done

		mov	cx, MSG_GEN_VALUE_GET_MAXIMUM
		call	CheckWrap
done:
		ret
PrefValueDecrement	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's a "wrap" attribute

CALLED BY:	PrefValueIncrement, PrefValueDecrement

PASS:		*ds:si - PrefvalueClass object
		cx - message to send to get new value

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWrap	proc near

		mov	ax, ATTR_PREF_VALUE_WRAP
		call	ObjVarFindData
		jnc	done

		mov_tr	ax, cx		; message to send
		call	ObjCallInstanceNoLock

		clr	bp
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallInstanceNoLock
done:
		ret
CheckWrap	endp



ifdef DO_DOVE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVZPGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text from a PrefValueZeroPadClass object.  It is
		presumed that we're dealing with a 2-digit integer and that
		any value less than 10 will be represented with a leading
		'0'.

CALLED BY:	MSG_GEN_VALUE_GET_VALUE_TEXT
PASS:		*ds:si	= PrefValueZeroPadClass object
		ds:di	= PrefValueZeroPadClass instance data
		ds:bx	= PrefValueZeroPadClass object (same as *ds:si)
		cx:dx	= buffer to hold text
		es 	= segment of PrefValueZeroPadClass
		ax	= message #
		bp	= GenValueType

RETURN:		cx:dx	= buffer, filled in
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	11/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVZPHourCustom12Hour	TCHAR	"|AP| |ZH|", 0
PVZPHourCustom24Hour	TCHAR	"|Zh|", 0

PVZPGetValueText	method dynamic PrefValueZeroPadClass, 
					MSG_GEN_VALUE_GET_VALUE_TEXT
	uses	ax, cx, dx, bp
	.enter

	;
	; Make sure the fptr (cx:dx) passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>


	; insert "AM ", "PM ", or nothing, depending on the time24Hour mode
	; and whether this is an hour value.
	mov	ax, ds:[di].PVZPI_isHour

	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset

	movdw	esdi, cxdx			;es:di <- buffer

	cmp	bp, GVT_LONG			; want longest string?
	jne	generateText
	cmp	ax, BW_TRUE			; is this an hour field?
	jne	generateText
	mov	dx, 60000			; up to 5 chars
	clr	ax, cx
	call	LocalFixedToAscii
	jmp	short done
generateText:

	mov	dx, ds:[bx].GVLI_value.WWF_int

	cmp	ax, BW_TRUE	; Is this an Hour or some other thing?
	jne	notHour

	mov	ch, dl		; hour value

	call	TimerCheckIfMilitaryTime
	push	ds
	segmov	ds, cs, si
	jc	use24Hour

; 12-hour representation:
	mov	si, offset PVZPHourCustom12Hour
	call	LocalCustomFormatDateTime
	pop	ds
	jmp	short done

use24Hour:
	mov	si, offset PVZPHourCustom24Hour
	call	LocalCustomFormatDateTime
	pop	ds
	jmp	short done

notHour:
	cmp	dx, 9
	jg	greaterThanNine
	mov	ax, '0'				; pad the string
SBCS <	stosb								>
DBCS <	stosw								>
greaterThanNine:	
	clr	ax, cx
	call	LocalFixedToAscii		;convert it

done:
	.leave
	ret
PVZPGetValueText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVZPSetValueFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
PASS:		*ds:si	= PrefValueZeroPadClass object
		ds:di	= PrefValueZeroPadClass instance data
		ds:bx	= PrefValueZeroPadClass object (same as *ds:si)
		es 	= segment of PrefValueZeroPadClass
		ax	= message #
		cx:dx	= null-terminated text
		bp	= GenValueType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Reads text in cx:dx and sets the value of the corresponding
		PrefValueZeroPad object.  Special parsing is done for hour
		values (which have PVZPI_isHour set to BW_TRUE).

PSEUDO CODE/STRATEGY:
		For Hour values, successful strings must be of the following
		forms, where X is any numeral:
		"AM XX"
		"AMXX"
		"AMX"
		"PM XX"
		"PMXX"
		"PMX"
		" XX"	(one leading space allowed)
		" X"	(one leading space allowed)
		"XX"
		"X"
		Invalid strings result in "00" or "AM 12" depending on the
		current display mode.

		All others (days, minutes, etc.) are just handled by
		LocalAsciiToFixed, which deals with the leading 0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	11/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVZPSetValueFromText	method dynamic PrefValueZeroPadClass, 
					MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
	uses	ax, cx, dx, bp
	.enter
	
	;
	; Make sure the fptr (cx:dx) passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, cxdx					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
   
	; Save the PVZPI_isHour field to check in a moment
	mov	ax, ds:[di].PVZPI_isHour

	pushdw	dsdi

   	movdw	dsdi, cxdx

	; If this is an hour field we have to do some extra checking.
	; Otherwise it's very simple.
	cmp	ax, BW_TRUE
	jne	notAnHour

	;
	; Check out the string for good chars.
	;
	push	es
	segmov	es, ds, ax
	call	LocalStringLength		; cx <- strlen
	pop	es

loopTop:
	LocalGetChar ax, dsdi
	dec	cx
	call	LocalIsTimeChar			; is ax in [[0-9]aAmMpP ]?
	jz	badChar
	tst	cx
	jnz	loopTop
	
	; We have not encountered any problem so let's continue.  At this
	; point however, we need to advance DI to the first numeric
	; character in the string and also look for "PM".
	mov	di, dx				; restore head of string
	
	clr	bx				; assume "AM"
	LocalGetChar ax, dsdi, NO_ADVANCE
	
	LocalCmpChar ax, C_SPACE
	jne	notSpace
	; At this point we saw a leading space, which we will accept as
	; neutral, and we skip it.
	LocalNextChar dsdi
	LocalGetChar ax, dsdi, NO_ADVANCE
notSpace:
	call	LocalIsNumChar
	jnz	convertNumber			; and convert (no AM or PM)

	LocalCmpChar ax, C_LATIN_CAPITAL_LETTER_P
	jne	probablyMorning
	mov	bx, 12				; initial 'P' implies afternoon
	jmp	short lookForMChar

probablyMorning:
	; char wasn't a 'P' so it should be 'A', otherwise there's a problem.
	LocalCmpChar ax, C_LATIN_CAPITAL_LETTER_A
	jne	badChar
	; set this flag for later (signifying we have seen the 'A')
	mov	bp, BW_TRUE

lookForMChar:	
	LocalNextChar dsdi
	LocalGetChar ax, dsdi
	LocalCmpChar ax, C_LATIN_CAPITAL_LETTER_M
	jne	badChar
	
	LocalGetChar ax, dsdi, NO_ADVANCE	; could be space or numeral
	LocalCmpChar ax, C_SPACE
	je	skipSpace

	jmp	short convertNumber
skipSpace:
	LocalNextChar dsdi
	jmp	short convertNumber
badChar:
	;
	; At this point we have encountered a bad char. in the string; so
	; rather than try to parse it out we will return a 0-value.
	;
	clr	ax, dx
	jmp	short gotNumber

convertNumber:
	call	LocalAsciiToFixed		; convert to fixed, in dx.ax
	cmp	dx, 12				; E.g., "PM 16" -> "PM 04"...
	jge	gotNumber			; definitely do not add 12
	add	dx, bx				; ... add 0 or 12 from before

gotNumber:
	;
	; One special case: change "AM 12" to 0.
	; This is true iff (bx==0 AND dx==12 AND bp==BW_TRUE)
	;
	tst	bx
	jnz	setValue
	cmp	dx, 12
	jne	setValue
	cmp	bp, BW_TRUE
	jne	setValue
	clr	dx
setValue:	

	popdw	dsdi

	mov	cx, ax				;now in dx.cx

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp				;set determinate
	call	ObjCallInstanceNoLock

	.leave
	ret

notAnHour:
	call	LocalAsciiToFixed
	jmp	short setValue

PVZPSetValueFromText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVZPGenValueGetTextFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_VALUE_GET_TEXT_FILTER
PASS:		*ds:si	= PrefValueZeroPadClass object
		ds:di	= PrefValueZeroPadClass instance data
		ds:bx	= PrefValueZeroPadClass object (same as *ds:si)
		es 	= segment of PrefValueZeroPadClass
		ax	= message #
RETURN:		al	= VisTextFilters
DESTROYED:	ah, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		Check whether this is an hour field, and if so, allow
		Alphabetic chars as well as numerics.

		Otherwise call the superclass to get the text filter.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	12/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVZPGenValueGetTextFilter	method dynamic PrefValueZeroPadClass, 
					MSG_GEN_VALUE_GET_TEXT_FILTER
	.enter
	
	cmp	ds:[di].PVZPI_isHour, BW_TRUE
	jne	callSuper	

	;
	; This is an Hour field.  Do not accept tabs, so they can be used
	; to navigate to the next field.  Upcase alphabetic chars as they
	; are entered.
	; 
	clr	ax
	mov	al, VTFC_ALPHA_NUMERIC	or mask VTF_NO_TABS \
					or mask VTF_UPCASE_CHARS
	jmp	short done

callSuper:
	mov	di, offset PrefValueClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret
PVZPGenValueGetTextFilter	endm

endif	; DO_DOVE
