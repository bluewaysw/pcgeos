COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipDescribe.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetDescribeStyle

	$Id: manipDescribe.asm,v 1.1 97/04/07 11:15:25 newdeal Exp $

------------------------------------------------------------------------------@

if DBCS_PCGEOS
STYLE_DESCRIBE_LOCALS	equ	<\
STYLE_LOCALS\
buffer		local	DESCRIBE_BUFFER_SIZE dup (wchar)\
bufferPtr	local	nptr\
bufferSize	local	word\
styleToken	local	word\
privateData	local	dword\
baseStyleToken	local	word\
attrsFlag	local	word		;if non-zero then attrs passed\
>
else
STYLE_DESCRIBE_LOCALS	equ	<\
STYLE_LOCALS\
buffer		local	DESCRIBE_BUFFER_SIZE dup (char)\
bufferPtr	local	nptr\
bufferSize	local	word\
styleToken	local	word\
privateData	local	dword\
baseStyleToken	local	word\
attrsFlag	local	word		;if non-zero then attrs passed\
>
endif

ManipCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeAttrs

DESCRIPTION:	Return a text description for the set of attributes

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	ss:di - SSCDescribeAttrsParams
	
RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeAttrs	proc	far	uses bx, cx, dx
	.enter

	movdw	cxdx, ss:[di].SSCDAP_textObject
	mov	bx, 1
	call	DescribeCommon

	.leave
	ret

StyleSheetDescribeAttrs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeStyle

DESCRIPTION:	Return a text description for the style

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
		XIP'ed geodes must pass virtual ptr to callbacks. 	

	ss:di - SSCDescribeStyleParams
	
RETURN:
	none

DESTROYED:
	none

	Description callback:
	Pass:
		es:di - buffer
		cx - buffer size left
		ds:si - derived attribute structure
		ds:dx - base attribute structure (dx = 0 for none)
		bp - number of characters already in buffer
		on stack:
			optr of extra UI to update
			privateData
			attrsFlag			
	Return:
		es:di - updated
		cx - updated
	Destroyed:
		ax, bx, dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

A style is conceptually described as the base style plus differences.  Thus
we start with the name of the base style and then callback to add text for
the differences

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@

DESCRIBE_BUFFER_SIZE	=	500

StyleSheetDescribeStyle	proc	far	uses ax, bx
	.enter

	mov	ax, ss:[di].SSCDSP_usedIndex
	movdw	cxdx, ss:[di].SSCDSP_describeTextObject
	clr	bx
	call	DescribeCommon

	.leave
	ret

StyleSheetDescribeStyle	endp

;---

	; bx = non-zero if describing attributes

DescribeCommon	proc	far
STYLE_DESCRIBE_LOCALS
	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:
	.enter

	call	EnterStyleSheet		;*ds:si = style array, ss:di = params

	mov	attrsFlag, bx

	mov	bufferSize, DESCRIBE_BUFFER_SIZE - 1	;-1 for null
	lea	bx, buffer
	mov	bufferPtr, bx
	segmov	es, ss

	mov	styleToken, CA_NULL_ELEMENT
	mov	baseStyleToken, CA_NULL_ELEMENT
	tst	attrsFlag
	jz	notAttrs1
	mov	di, saved_esdi.low		;ss:di = DescribeAttrParams
	mov	bx, ss:[bp]			;ss:di = StyleSheetParams
	lea	bx, ss:[bx].SSP_attrArrays
	call	StyleSheetLockStyleChunk	;*ds:si = array
	pushf
	mov	cx, attrTotal
	mov	dx, {word} ss:[di].SSCDAP_attrTokens
lookForIndeterminateLoop:
	mov	ax, {word} ss:[di].SSCDAP_attrTokens
	cmp	ax, CA_NULL_ELEMENT
	jz	attrsIndeterminate
	add	di, size word
	loop	lookForIndeterminateLoop

	mov_tr	ax, dx
	call	ChunkArrayElementToPtr		;ds:di = attribute element
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	bx, ds:[di].SSEH_style		;bx = base
	popf
	call	StyleSheetUnlockStyleChunk
	mov	ax, CA_NULL_ELEMENT
	jmp	common1

attrsIndeterminate:
	mov	baseStyleToken, CA_NULL_ELEMENT
	popf
	call	StyleSheetUnlockStyleChunk
indeterminate:
	mov	di, bufferPtr
	mov	cx, bufferSize
	mov	bx, handle IndeterminateString
	mov	si, offset IndeterminateString
	call	StyleSheetAddNameFromChunk
	mov	bufferPtr, di
	jmp	afterLoop

notAttrs1:
	cmp	ax, CA_NULL_ELEMENT
	jz	indeterminate
	movdw	dssi, styleArray
	clr	bx
	call	ElementArrayUsedIndexToToken
	call	ChunkArrayElementToPtr		;ds:di = style element
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	bx, ds:[di].SEH_baseStyle	;bx = base style
common1:
	mov	styleToken, ax
	mov	baseStyleToken, bx

	; start with the name of the base style (if any)

	movdw	dssi, styleArray
	mov_tr	ax, bx				;ax = base token
	cmp	ax, CA_NULL_ELEMENT
	jz	noBS
	call	ChunkArrayElementToPtr		;ds:di = base style, cx = size
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	movdw	privateData, ds:[di].SEH_privateData, ax
	sub	cx, offset SEH_attrTokens
	lea	si, ds:[di].SEH_attrTokens	;ds:si = tokens
	mov	ax, attrTotal
	shl	ax
	sub	cx, ax				;cx = name size (# bytes)
DBCS <	shr	cx, 1				; # bytes -> # chars	>
	add	si, ax				;ds:si = name
	mov	di, bufferPtr			;es:di = buffer
	sub	bufferSize, cx
	jns	nameFits
	clr	ax
	xchg	ax, bufferSize			;size left = 0
						;ax = bufSize - stringSize
	add	cx, ax				;cx = bufSize
nameFits:
	LocalCopyNString
	mov	bufferPtr, di
noBS:

	; if there is a special application specified description routine
	; then call it.  This allows apps to put any special description
	; info out

	movdw	dssi, styleArray
	mov	ax, styleToken
	cmp	ax, CA_NULL_ELEMENT
	jnz	20$
	mov	ax, baseStyleToken
20$:
	clrdw	privateData			;assume no base style
	call	ElementToPtrCheckNull		;ds:di = style element
	jnc	noSpecial
	push	di
	movdw	privateData, ds:[di].SEH_privateData, ax
	mov	ax, ds:[di].SEH_baseStyle	;ax = base style
	clr	dx				;assume no base style
	cmp	ax, CA_NULL_ELEMENT
	jz	noBaseStyle1
	call	ChunkArrayElementToPtr		;ds:di = base style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	dx, di
noBaseStyle1:
	pop	si

	; ds:si = style, ds:dx = base style

	mov	bx, ss:[bp]			;ss:bx = StyleSheetParams
	mov	ax, ss:[bx].SSP_specialDescriptionCallback.offset
	mov	bx, ss:[bx].SSP_specialDescriptionCallback.segment
	tst	bx
	jz	noSpecial
	call	CallDescCallback
noSpecial:

	; loop through each attribute calling the description callback for
	; each
	;	ss:bp = locals

attrLoop:

	; lock appropriate attribute array

	movdw	dssi, styleArray
	mov	ax, baseStyleToken		;ax = base style
	call	ElementToPtrCheckNull
	jnc	noStyle
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = attr token
noStyle:
	call	LockLoopAttrArray
	mov	dx, di

	; dx = offset of base attr structure

	; get the appropriate attribute token

	mov	ax, styleToken
	cmp	ax, CA_NULL_ELEMENT
	jnz	notAttrArray2

	; use style token as base, passed attr token as thing to describe

	mov	di, saved_esdi.low		;ss:di = describe attr params
	add	di, attrCounter2
	mov	ax, ss:[di].SSCDAP_attrTokens[0] ;ax = derived attribute
	jmp	common2

notAttrArray2:
	movdw	dssi, styleArray
	call	ChunkArrayElementToPtr		;ds:di = style element
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = derived attribute

	; ax = derived attr token

common2:
	movdw	dssi, attrArray
	call	ChunkArrayElementToPtr		;ds:di = derived attr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	si, di

	; call callback to add description

	mov	bx, ss:[bp]			;ss:bx = StyleSheetParams
	add	bx, attrCounter4	;ss:bx = routine
	mov	ax, ss:[bx].SSP_descriptionCallbacks[0].offset
	mov	bx, ss:[bx].SSP_descriptionCallbacks[0].segment

	call	CallDescCallback

	; unlock attribute array

	call	UnlockLoopAttrArray
	jnz	attrLoop

	; null terminate string and set text object

afterLoop:
	mov	di, bufferPtr
SBCS <	mov	{char} es:[di], 0					>
DBCS <	mov	{wchar} es:[di], 0					>

	push	bp
	movdw	bxsi, saved_cxdx
	mov	dx, ss
	lea	bp, buffer
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	; if describing an attr list then set the attrs list

	push	bp
	movdw	dssi, styleArray
	clr	cx

	tst	attrsFlag
	jz	noAttrList
	mov	ax, baseStyleToken
	call	ElementToPtrCheckNull		;ds:di = style element
	jnc	noBaseStyle2
	mov	cx, ds:[di].SEH_flags
	and	cx, not mask SEF_PROTECTED	;this bit is not displayed
noBaseStyle2:
	clr	dx
	mov	di, saved_esdi.low
	movdw	bxsi, ss:[di].SSCDAP_attrList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage
	jmp	afterSpecial

	; if describing a style then update the delete triggers

noAttrList:
	mov	ax, styleToken
	call	ElementToPtrCheckNull		;ds:di = style element
	mov	ax, MSG_GEN_SET_ENABLED
	test	ds:[di].SEH_flags, mask SEF_PROTECTED
	jz	40$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
40$:
	mov	di, saved_esdi.low
	movdw	bxsi, ss:[di].SSCDSP_describeDeleteTrigger
	mov	dl, VUM_NOW
	push	di
	clr	di
	call	ObjMessage
	pop	di
	movdw	bxsi, ss:[di].SSCDSP_describeDeleteRevertTrigger
	clr	di
	call	ObjMessage

afterSpecial:
	pop	bp

	call	LeaveStyleSheet

	.leave
	ret

DescribeCommon	endp

;---

	; bx:ax = routine

CallDescCallback	proc	near
STYLE_DESCRIBE_LOCALS
	.enter inherit far

	push	bp, ds

	push	attrsFlag

	pushdw	privateData

	clrdw	dicx
	tst	attrsFlag
	jz	10$
	mov	di, saved_esdi.low
	mov	cx, ss:[di].SSCDAP_extraUI.chunk
	mov	di, ss:[di].SSCDAP_extraUI.handle
10$:
	pushdw	dicx

	mov	di, bufferPtr
	mov	cx, bufferSize
	mov	bp, DESCRIBE_BUFFER_SIZE - 1
	sub	bp, cx				;bp = chars in buffer
	call	ProcCallFixedOrMovable
	pop	bp, ds
	mov	bufferPtr, di
	mov	bufferSize, cx

	.leave
	ret

CallDescCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeExclusiveWord

DESCRIPTION:	Generate a text description for an exclusive (as opposed
		to non-exclusive) word
		(See StyleSheetDescribeExclusiveWordXIP if geode XIP'ed)

CALLED BY:	INTERNAL

PASS:
	ax - word
	bx - block in which all strings reside
	ds:si - table of SSDescribeWordEntry structures
	dx - table length
	es:di - buffer
	cx - length
	bp - chunk of default string (if any)

RETURN:
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeExclusiveWord	proc	far	uses ax, dx, si
	.enter

searchLoop:
	cmp	ax, ds:[si].SSDWE_value
	jz	found
	add	si, size SSDescribeWordEntry
	dec	dx
	jnz	searchLoop

	; not found -- use default string and print word

	mov	si, bp
	tst	si				;any default string?
	jz	10$
	call	StyleSheetAddNameFromChunk	;add default string
10$:
	call	StyleSheetAddWord		;add number
	jmp	done

	; entry found -- print the string

found:
	mov	si, ds:[si].SSDWE_name
	call	StyleSheetAddNameFromChunk

done:
	.leave
	ret

StyleSheetDescribeExclusiveWord	endp

if FULL_EXECUTE_IN_PLACE

ManipCode	ends
StylesXIPCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeExclusiveWordXIP

DESCRIPTION:	Generate a text description for an exclusive (as opposed
		to non-exclusive) word

CALLED BY:	INTERNAL

PASS:
 	ax - word
	bx - block in which all strings reside
	ds:si - fptr to table of SSDescribeWordEntry structures
	dx - table length
	es:di - buffer
	cx - length
	bp - chunk of default string (if any)

RETURN:
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	4/24/94		Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeExclusiveWordXIP	proc	far	
		uses si, ds
		.enter
	;
	; Copy the table of SSDescribeWordEntry structures to the stack
	;
		xchg	cx, dx			; cx <- size of table
		call	SysCopyToStackDSSI	; ds:si <- table on stack
		xchg	cx, dx
	;
	; Will the real StyleSheetDescribeExclusiveWord please stand up
	;
		call	StyleSheetDescribeExclusiveWord
	;
	; Clear the stack
	;	
		call	SysRemoveFromStack

		.leave
		ret
StyleSheetDescribeExclusiveWordXIP	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeNonExclusiveWordXIP

DESCRIPTION:	Generate a text description for an non-exclusive (as opposed
		to exclusive) word

CALLED BY:	INTERNAL

PASS:
	ax - word
	bx - block in which all strings reside
	ds:si - fptr to table of SSDescribeWordEntry structures
	dx - table length
	es:di - buffer
	cx - length

RETURN:
	ax - number of entrries printed
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	04/24/94	Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeNonExclusiveWordXIP	proc	far	
		uses	ds, si
		.enter
	;
	; Copy the table of SSDescribeWordEntry structures to the stack
	;
		xchg	cx, dx			; cx <- size of table
		call	SysCopyToStackDSSI	; ds:si <- table on stack
		xchg	cx, dx
	;
	; Will the real StyleSheetDescribeExclusiveWord please stand up
	;
		call	StyleSheetDescribeNonExclusiveWord
	;
	; Clear the stack
	;	
		call	SysRemoveFromStack

		.leave
		ret
StyleSheetDescribeNonExclusiveWordXIP	endp

StylesXIPCode	ends
ManipCode	segment resource

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeNonExclusiveWord

DESCRIPTION:	Generate a text description for an non-exclusive (as opposed
		to exclusive) word.  
		(See StyleSheetDescribeNonExclusiveWordXIP if geode XIP'ed)


CALLED BY:	INTERNAL

PASS:
	ax - word
	bx - block in which all strings reside
	ds:si - table of SSDescribeWordEntry structures
	dx - table length
	es:di - buffer
	cx - length

RETURN:
	ax - number of entrries printed
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeNonExclusiveWord	proc	far	uses si, bp
	.enter

	clr	bp				;"have printed one" flag

searchLoop:
	test	ax, ds:[si].SSDWE_value
	jz	next

	tst	bp
	jz	firstone
	call	AddSpace
firstone:
	inc	bp

	push	si
	mov	si, ds:[si].SSDWE_name
	call	StyleSheetAddNameFromChunk
	pop	si

next:
	add	si, size SSDescribeWordEntry
	dec	dx
	jnz	searchLoop

	mov_tr	ax, bp

	.leave
	ret

StyleSheetDescribeNonExclusiveWord	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeWWFixed

DESCRIPTION:	Generate a text description for a WWFixed

CALLED BY:	INTERNAL

PASS:
	dx.ax - value
	bp - number of fractional digits to display
	^lbx:si - name (to put at beginning)
	es:di - buffer
	cx - length

RETURN:
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
StyleSheetDescribeWWFixed	proc	far

	cmp	cx, 10
	jbe	done

	tst	bx
	jz	10$
	call	StyleSheetAddNameFromChunk
	call	AddSpace
10$:

	push	cx
	mov	cx, bp
	call	LocalFixedToAscii
	pop	cx

	call	FindEndOfString
done:
	ret

StyleSheetDescribeWWFixed	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDescribeDistance

DESCRIPTION:	Generate a text description for a distance

CALLED BY:	INTERNAL

PASS:
	al - DistanceUnit to use
	dx - value (points * 8)
	bp - relative flag
	^lbx:si - name to put at beginning
	es:di - buffer
	cx - length

RETURN:
	di, cx - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91	Initial version

------------------------------------------------------------------------------@
SSDD_LARGER	=	0x1
SSDD_SMALLER	=	0x8000

StyleSheetDescribeDistance	proc	far	uses ax, bx, si
	.enter

	; if this is the default value then bail

	tst	dx
	jnz	1$
	test	bp, mask SSDDF_RELATIVE
	jnz	done
1$:

	tst	bx
	jz	5$
	call	StyleSheetAddNameFromChunk
	call	AddSpace
5$:

	cmp	cx, 10
	jbe	done

	; test for relative mode

	push	dx
	test	bp, mask SSDDF_RELATIVE
	jz	10$
	ornf	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	tst	dx
	jns	10$
	neg	dx
10$:

	push	cx
	mov_tr	bx, ax				;al = units
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication		;al = MeasurementType
	mov	ah, al
	mov	al, bl
	mov_tr	cx, ax				;cl = DistanceUnits
						;ch = MearurementType
	mov	bx, mask LDF_FULL_NAMES or mask LDF_PRINT_PLURAL_IF_NEEDED
	test	bp, mask SSDDF_PLURAL_FOR_NON_RELATIVE_IF_NEEDED
	jnz	20$
	mov	bx, mask LDF_FULL_NAMES
20$:
	clr	ax				;make 13.3 value into WWFixed
	shr	dx, 1				;
	rcr	ax, 1
	shr	dx, 1
	rcr	ax, 1
	shr	dx, 1
	rcr	ax, 1

	call	LocalDistanceToAscii
	pop	cx
	call	FindEndOfString

	pop	dx
	test	bp, mask SSDDF_RELATIVE
	jz	done
	mov	si, offset DistanceLargerString
	tst	dx
	jns	gotString
	mov	si, offset DistanceSmallerString
gotString:
	mov	bx, handle DistanceSmallerString
	call	AddSpace
	call	StyleSheetAddNameFromChunk

done:
	.leave
	ret

StyleSheetDescribeDistance	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetAddAttributeHeader

DESCRIPTION:	Add an attribute header

CALLED BY:	INTERNAL

PASS:
	ax - non-zero to add separator
	^lbx:si - name
	es:di - description buffer
	cx - buffer size

RETURN:
	cx, di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
StyleSheetAddAttributeHeader	proc	far	uses ax
	.enter

	tst	ax
	jz	noSeperator
	call	AddSpace
	LocalLoadChar ax, '+'
	call	StyleSheetAddCharToDescription
	call	AddSpace
noSeperator:

	call	StyleSheetAddNameFromChunk
	call	AddSpace

	.leave
	ret

StyleSheetAddAttributeHeader	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetAddNameFromChunk

DESCRIPTION:	Add a name to a description string from a chunk

CALLED BY:	INTERNAL

PASS:
	^lbx:si - name
	es:di - description buffer
	cx - buffer size

RETURN:
	cx, di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
StyleSheetAddNameFromChunk	proc	far	uses ax, si, ds
	.enter

	call	MemLock
	mov	ds, ax				;*ds:si = name
	mov	si, ds:[si]

	call	StyleSheetAddNameFromPtr

	call	MemUnlock

	.leave
	ret

StyleSheetAddNameFromChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleSheetAddNameFromPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a description string from a pointer
CALLED BY:	GLOBAL, StyleSheetAddNameFromChunk()

PASS:		ds:si - ptr to name
		es:di - ptr to dest buffer
		cx - buffer size
RETURN:		es:di - updated
		cx - updated
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StyleSheetAddNameFromPtr	proc	far
	uses	si
	.enter

copyLoop:
	jcxz	done				;buffer full?
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	dec	cx
	LocalIsNull	ax			;NULL?
	jnz	copyLoop			;branch while not NULL

	LocalPrevChar esdi
	inc	cx
done:
	.leave
	ret
StyleSheetAddNameFromPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleSheetAddWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a word in decimal to a description string
CALLED BY:	GLOBAL

PASS:		ax - word to add
		es:di - ptr to buffer
		cx - size of buffer
RETURN:		es:di - updated
		cx - updated
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StyleSheetAddWord	proc	far
	.enter

	cmp	cx, 6				;if no buffer space then bail
	jbe	done
	push	cx				;save buffer size
	mov	cx, mask UHTAF_NULL_TERMINATE
	clr	dx				;dx:ax = number
	call	UtilHex32ToAscii
	pop	cx				;cx <- buffer size

	call	FindEndOfString
done:

	.leave
	ret
StyleSheetAddWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetAddCharToDescription

DESCRIPTION:	Add a character to a description string

CALLED BY:	INTERNAL

PASS:
	al - character
	es:di - description buffer
	cx - buffer size

RETURN:
	cx, di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
if FULL_EXECUTE_IN_PLACE
AddSpace	proc	far
else
AddSpace	proc	near
endif
	push	ax
	LocalLoadChar ax, ' '
	call	StyleSheetAddCharToDescription
	pop	ax
	ret

AddSpace	endp

;---

StyleSheetAddCharToDescription	proc	far
	jcxz	done
	LocalPutChar esdi, ax
	dec	cx
done:
	ret

StyleSheetAddCharToDescription	endp


if FULL_EXECUTE_IN_PLACE

ManipCode	ends
StylesXIPCode	segment resource

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetCallDescribeRoutines

DESCRIPTION:	Given a table of SSDiffEntry structures, call the routines

CALLED BY:	INTERNAL

PASS:
	ss:bp - diff structure
	es:di - buffer
	cx - buffer size
	ds:si - "new" attribute structure
	ds:bx - "old" attribute structure
	ax - number of entries in table
	dx - word to pass to callbacks
	on stack:
		dword - fptr to table of SSDiffEntry structures 
			(routines must be in the same segment)
			

RETURN:
	di, cx - updated

DESTROYED:
	ax, bx, dx

	Desc routines:
	Pass:
		ds:si - attribute structure
		ds:bx - "old" attribute structure
		es:di - buffer for text description
		cx - buffer size
		ss:ax - diffs
		dx - word to pass to callbacks
	Return:
		di, cx - updated
	Destroy:
		ax, bx, dx, si, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91	Initial version

------------------------------------------------------------------------------@

CallDescFlags	record
    CDF_ADDED_ANYTHING:1
    CDF_ADDED_ANYTHING_TO_CATEGORY:1
    CDF_NEEDS_SEPERATOR:1
    :5
CallDescFlags	end

StyleSheetCallDescribeRoutines	proc	far	table:fptr
routine		local	fptr
flags		local	CallDescFlags
	.enter

	clr	flags

descLoop:
	push	ax, bx, dx, si, bp, ds

	push	di, bp, es
	movdw	esdi, table

	; is this is a new cateogry ?

	test	es:[di].SSDE_flags, mask SSDF_NEW_CATEGORY
	jz	afterCategory

	; if something was added to the last category then set the needs
	; seperator flag

	test	flags, mask CDF_ADDED_ANYTHING_TO_CATEGORY
	jz	afterCategory

	andnf	flags, not mask CDF_ADDED_ANYTHING_TO_CATEGORY
	ornf	flags, mask CDF_NEEDS_SEPERATOR
afterCategory:

	; test the field

	mov	ax, es:[di].SSDE_routine
	mov	routine.offset, ax
	mov	routine.segment, es
	clr	ax
	mov	al, es:[di].SSDE_offset		;ax = offset
	mov	bp, ss:[bp]
	add	bp, ax
	mov	ax, es:[di].SSDE_mask
	test	ax, ss:[bp]
	pop	di, bp, es
	jz	next

	test	flags, mask CDF_NEEDS_SEPERATOR
	jz	afterSeperator
	andnf	flags, not mask CDF_NEEDS_SEPERATOR
SBCS <	mov	{char} es:[di-1], ','					>
DBCS <	mov	{wchar} es:[di-2], ','					>
	call	AddSpace
afterSeperator:
	or	flags, mask CDF_ADDED_ANYTHING or \
			mask CDF_ADDED_ANYTHING_TO_CATEGORY

	; diff bit set -- call the routine

	mov	ax, ss:[bp]
	call	routine
	call	AddSpace

next:
	pop	ax, bx, dx, si, bp, ds
	add	table.offset, size SSDiffEntry
	dec	ax
	jnz	descLoop

	test	flags, mask CDF_ADDED_ANYTHING
	jz	done
	LocalPrevChar esdi
	inc	cx
done:

	.leave
	ret	@ArgSize

StyleSheetCallDescribeRoutines	endp

if FULL_EXECUTE_IN_PLACE

StylesXIPCode	ends
ManipCode	segment resource

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindEndOfString

DESCRIPTION:	Find the end of a string

CALLED BY:	INTERNAL

PASS:
	es:di - string
	cx - size

RETURN:
	es:di - end of string
	cx - adjusted

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91		Initial version

------------------------------------------------------------------------------@
FindEndOfString	proc	near	uses ax
	.enter

	; find string end

	clr	ax
	LocalFindChar				;repne scasb/scasw
	LocalPrevChar esdi			;back up to NULL
	inc	cx

	.leave
	ret

FindEndOfString	endp

ManipCode	ends
