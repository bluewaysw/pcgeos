COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsEnum.asm

AUTHOR:		Tony Requist, 5/8/92

ROUTINES:
	Name			Description
	----			-----------
	EnumTextReference	Enumerate a text reference

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/20/91	Initial revision

DESCRIPTION:
	Code for accessing and manipulating text references.

	$Id: tsEnum.asm,v 1.1 97/04/07 11:22:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFilter	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	EnumDSSI_CX

DESCRIPTION:	Enumerate characters at ds:si

CALLED BY:	INTERNAL

PASS:
	ds:si - characters to enumerate
	cx - count
	di - callback
	dxbp - object

RETURN:
	carry - set to end

DESTROYED:
	si - updated

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 8/92		Initial version
	Chris	10/12/92	Changed to save any changes in cl.  
				Don't hurt me!

------------------------------------------------------------------------------@
EnumDSSI_CX	proc	near	uses ax, cx, bp, ds, es
	.enter

	segmov	es, ds
	xchg	si, bp				;es:bp = data
	mov	ds, dx				;ds:si = object
	mov_tr	ax, cx				;ax = count

enumLoop:
SBCS <	clr	cx							>
SBCS <	mov	cl, es:[bp]						>
DBCS <	mov	cx, es:[bp]						>
	inc	bp
DBCS <	inc	bp							>
	jcxz	doneGood			;a hack for the null-terminator
	call	di
SBCS <	mov	es:[bp-1], cl			;save new version in cl, in >
DBCS <	mov	es:[bp-2], cx			;save new version in cl, in >
						;  case changed (cbh 10/12/92)
	jc	done
	dec	ax
	jnz	enumLoop
doneGood:
	clc
done:
	mov	si, bp

	.leave
	ret

EnumDSSI_CX	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumTextFromPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a pointer into a buffer.

CALLED BY:	EnumTextReference
PASS:		es:di	= Destination for text
		cx	= # of bytes to copy
		ss:bp	= TextReferencePointer
		cs:di	= callback
RETURN:		carry	= set if callback aborted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumTextFromPointer	proc	near
	pushdw	dssi
	movdw	dssi, ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer
	mov	cx, ss:[bp].VTRP_insCount.low
	popdw	dxbp
	call	EnumDSSI_CX
	movdw	dssi, dxbp
	ret

EnumTextFromPointer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumTextFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a huge-array into a buffer.

CALLED BY:	EnumTextReference
		ss:bp	= TextReferenceHugeArray
		dxax	= Number of bytes to enum
		cs:di	= callback for filter
RETURN:		carry	= set if callback aborted
DESTROYED:	ax, bx, cx, dx, bp, es

PSEUDO CODE/STRATEGY:
	Lock first element of huge-array
    copyLoop:
	Copy as many bytes as we can (up to cx)
	If we aren't done yet
	    Release the huge-array and lock the next block of data
	    jmp copy loop

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumTextFromHugeArray	proc	near

	pushdw	dssi
	push	di				; Save callback
	mov	bx, ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_file
	mov	di, ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_array
	clrdw	dxax
	call	HugeArrayLock			; ds:si <- data to copy
	pop	di				; Restore callback
	popdw	dxbp				; dxbp = object

enumLoop:
	mov_tr	cx, ax				; cx <- # of valid bytes
	;
	; Override file = huge array file
	; ds:si = data
	; di	= callback
	; cx	= Number of bytes available
	;
	call	EnumDSSI_CX
	jc	done

	LocalPrevChar dssi
	push	dx
	call	HugeArrayNext
	pop	dx
	tst_clc	ax
	jnz	enumLoop

done:
	pushf
	call	HugeArrayUnlock
	popf

	movdw	dssi, dxbp			; restore object

	ret

EnumTextFromHugeArray	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_EnumTextReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy bytes referenced by a text-reference into a buffer.

CALLED BY:	EXTERNAL
PASS:		di	= callback
		ss:bp	= VisTextReplaaceParams
RETURN:		carry - from enum routine
DESTROYED:	bx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_EnumTextReference	proc	near	uses ax, bx, cx, dx, di, bp, es
	.enter

	tstdw	ss:[bp].VTRP_insCount
	clc
	jz	common

	mov	ax, ss:[bp].VTRP_textReference.TR_type
	cmp	ax, TRT_POINTER
	jnz	notPointer
	call	EnumTextFromPointer
	jmp	common
notPointer:
EC <	cmp	ax, TRT_HUGE_ARRAY					>
EC <	ERROR_NZ	VIS_TEXT_BAD_TEXT_REFERENCE_TYPE		>
	call	EnumTextFromHugeArray
common:
	.leave
	ret

TS_EnumTextReference	endp

TextFilter ends
