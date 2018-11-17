COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc
FILE:		miscMonthValue.asm

AUTHOR:		Don Reeves, Oct 19, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/19/92	Initial revision

DESCRIPTION:
	Implements the DateArrowsClass

	$Id: miscMonthValue.asm,v 1.1 97/04/04 14:48:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
		MonthValueClass
idata		ends



PrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthValueGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for this object, which is always NULL

CALLED BY:	GLOBAL (MSG_GEN_VALUE_GET_VALUE_TEXT)

PASS:		*DS:SI	= MonthValueClass object
		DS:DI	= MonthValueClassInstance
		CX:DX	= Buffer to fill
		BP	= GenValueType

RETURN:		CX:DX	= Filled buffer

DESTROYED:	AX, BX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthValueGetValueText	method dynamic	MonthValueClass,
					MSG_GEN_VALUE_GET_VALUE_TEXT
		uses	cx, dx
		.enter

		; Create a month string
		;
		mov	bx, ds:[di].GVLI_value.WWF_int
		mov	es, cx
		mov	di, dx			; buffer => ES:DI
		cmp	bp, GVT_LONG
		je	longestString
		cmp	bp, GVT_VALUE
		jne	nullString
createString:
		call	CreateMonthString
done:
		.leave
		ret

		; Return a NULL string for things we don't support
nullString:
SBCS <		clr	al						>
DBCS <		clr	ax						>
		LocalPutChar esdi, ax
		jmp	done

		; Want to create the longest string possible. Grab
		; all strings, and return the longest.
longestString:
		mov	ds, cx
		mov	si, dx			; buffer => DS:SI
		mov	bp, di
		clr	di			; no Window handle
		call	GrCreateState
		xchg	bp, di			; GState handle => BP
		mov	bx, 0x0c0c		; initialize month stuff
		clr	ax			; largest width => AX
monthLoop:
		push	si
		call	CreateMonthString
		pop	si
		xchg	bp, di
		call	GrTextWidth		; width => DX
		xchg	bp, di
		cmp	dx, ax
		jle	nextMonth
		mov_tr	ax, dx			; update width
		mov	bh, bl			; update month
nextMonth:
		dec	bl			; go to the next month
		jnz	monthLoop
		xchg	bp, di
		call	GrDestroyState
		mov	di, bp			; buffer => ES:DI
		mov	bl, bh			; longest month => BL
		jmp	createString		; return that string
MonthValueGetValueText	endm

CreateMonthString	proc	near
		mov	si, DTF_MONTH
		call	LocalFormatDateTime
		ret
CreateMonthString	endp

PrintCode	ends
