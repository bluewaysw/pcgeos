COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatUtils.asm

AUTHOR:		Don Reeves, Dec 20, 1989

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial revision


DESCRIPTION:
		
	$Id: repeatUtils.asm,v 1.1 97/04/04 14:48:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterRepeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets some important global variables, and determines if
		repeat events need to be generated for this year.

CALLED BY:	GenerateRepeat

PASS:		BP	= Year
		DS	= DGroup

RETURN: 	Carry	= Clear if map already existed
			  Set if not

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Sets the all-important tableGroup & tableItewm variables
		to the correct value for the given year

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version
	Don	4/7/90		Changed to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnterRepeat	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter

	; See if our year exists
	;
EC <	tst	bp				; check for bad year	>
EC <	ERROR_Z	ENTER_REPEAT_BAD_YEAR		; display the error	>
	mov	si, offset repeatTableHeader	; DS:SI is the table header
	mov	ds:[newYear], 0			; set the flag
	mov	bx, size RepeatTableHeader	; BX is the initial offset
	mov	cx, NUM_REPEAT_TABLES		; count => CX
CheckLoop:
	cmp	bp, ds:[si][bx].RTS_yearYear	; compare the years
	je	Found				; if found, jump
	add	bx, size RepeatTableStruct	; else try the next structure
	loop	CheckLoop			; loop MAX_TABLE_SIZE times

	; Re-use a current table
	;
	mov	ds:[newYear], 1			; yes, we have a new year
	mov	bx, ds:[si].RTH_lastSwap	; get last swap position
	add	bx, size RepeatTableStruct	; go to next table location
	cmp	bx, TOTAL_REPEAT_TABLE_SIZE
	jl	SwapNow	
	mov	bx, size RepeatTableHeader	; else go to first table struct

	; Now clean the table
	;
SwapNow:
	mov	ds:[si].RTH_lastSwap, bx	; store the new swap position
	mov	ds:[si][bx].RTS_yearYear, bp	; store the year
	mov	cx, ds:[si][bx].RTS_tableOD.handle
	mov	dx, ds:[si][bx].RTS_tableOD.chunk
	tst	cx				; was there a previous table
	je	NewTable			; if not, create the table
	call	ClearRepeatYearTable		; clear the table
	jmp	Found
NewTable:
	call	CreateRepeatYearTable
	mov	ds:[si][bx].RTS_tableOD.handle, cx
	mov	ds:[si][bx].RTS_tableOD.chunk, dx

	; Store the RepeatTable's group & item #'s
	;
Found:	
	mov	ax, ds:[si][bx].RTS_tableOD.handle
	mov	ds:[tableHandle], ax
	mov	ax, ds:[si][bx].RTS_tableOD.chunk
	mov	ds:[tableChunk], ax

	; Now the return value
	;
	test	ds:[newYear], 1			; clears the carry !!
	je	Done				; jump if not a new year
	stc					; else set the carry
Done:
	.leave
	ret
EnterRepeat	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateToTablePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a table position based on the month & day

CALLED BY:	GLOBAL

PASS:		DH	= Month (1-12)
		DL	= Day (1-31)

RETURN:		BX	= Table offset (0 -> 12x64-1)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Input	0000MMMM:000DDDDD
		Output	000000MM:MMDDDDD0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateToTablePos	proc	near
		
EC <	call	CheckValidDayMonth		; check validity	>
	mov	bx, dx
	dec	bh				; change to zero-based
	shl	bl, 1
	shl	bl, 1
	shl	bl, 1
	sar	bx, 1
	sar	bx, 1
	ret
DateToTablePos	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TablePosToDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Table position to the date

CALLED BY:	GLOBAL

PASS:		BX	= Table offset (0 -> 12x64-1)

RETURN:		DH	= Month (1-31)
		DL	= Day (1-12)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Input	000000MM:MMDDDDD0
		Output	0000MMMM:000DDDDD
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	GCM
TablePosToDateFar	proc	far
	call	TablePosToDate
	ret
TablePosToDateFar	endp
endif

TablePosToDate	proc	near
EC <	cmp	bx, YearMapSize			; valid size		>
EC <	ERROR_A	TABLE_POS_TO_DATE_OFFSET_TOO_BIG			>
	mov	dx, bx
	shl	dx, 1
	shl	dx, 1				; move month to high byte
	inc	dh				; change month to 1-based
	sar	dl, 1				; days to low bits
	sar	dl, 1
	sar	dl, 1
	and	dl, 01fh			; ensure top three bits clear
	ret
TablePosToDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearSomeBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear some bytes

CALLED BY:	GLOBAL

PASS:		ES:SI	= start of buffer to clear
		CX	= Size in bytes (multiple of two)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/29/89	Initial version
	Don	4/7/90		Simplified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClearSomeBytes	proc	far
	uses	ax, cx, di
	.enter

	sar	cx, 1				; # of words => CX
	clr	ax				; value to store
	mov	di, si				; ES:DI is the buffer to clear
	rep	stosw				; zero-out the buffer

	.leave
	ret
ClearSomeBytes	endp

CommonCode	ends
