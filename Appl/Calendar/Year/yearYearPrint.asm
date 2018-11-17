COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Year
FILE:		yearYearPrint.asm

AUTHOR:		Don Reeves, April 5, 1991

ROUTINES:
	Name			Who	Description
	----			---	-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/5/89		Initial revision

DESCRIPTION:
	Printing procedures that operate on the Year Class

	$Id: yearYearPrint.asm,v 1.1 97/04/04 14:48:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start printing a month or a year

CALLED BY:	GLOBAL (MSG_PRINT_START_PRINTING)

PASS:		ES	= DGroup
		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance
		CX:DX	= OD of PrintControl object
		BP	= GState handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearStartPrinting	method dynamic	YearClass, MSG_PRINT_START_PRINTING
	.enter

	; Obtain some crucial information about printing
	;
	pushdw	cxdx				; save PrintControl OD
	push	si, bp, di
	mov	ax, MSG_MY_PRINT_GET_INFO
	GetResourceHandleNS	CalendarPrintOptions, bx
	mov	si, offset CalendarPrintOptions
	call	ObjMessage_print_call		; data => CX, DX & BP
	pop	di				; year instance data => DS:DI
	mov	ds:[di].YI_printYear, bp	; store the year
	mov	ds:[di].YI_printMonth, dh	; store the month
	pop	bp				; GState handle => BP
	push	dx				; store MyPrintAttrs

	; See if we are printing a month or a year
	;
	and	dl, mask MPA_OUTPUT_TYPE	; MyPrintOutputType => DL
	mov	bx, MI_YEAR_TITLE shl 8		; draw year in title
	mov	ax, offset YearPrintOneMonth
	jz	doInit
	xchg	bl, bh				; don't draw year in title
	mov	ax, offset YearPrintOneYear

	; Set the font ID to use
doInit:
	push	ax				; save print routine to call
	mov	ax, MSG_MONTH_SET_FONT
	mov	si, offset Interface:MonthPrintObj
	call	ObjCallInstanceNoLock		; CX, DX, BP are preserved!
	clr	ah				; no fractional point size
	mov	dx, 12				; use dummy point size
	mov	di, bp				; GState => DI
	call	GrSetFont			; set the font & size
	mov	ax, MSG_MONTH_SET_STATE
	mov	cx, bx				; MonthInfoFlags => CL & CH
	call	ObjCallInstanceNoLock

	; Set the inital translation
	;
	mov	di, bp				; GState => DI
	mov	dx, es:[printMarginLeft]
	mov	bx, es:[printMarginTop]
	clr	ax, cx
	call	GrApplyTranslation		; apply to GState in DI

	; Now perform the actual printing
	;
	mov	bp, di				; GState => BP
	mov	cx, es:[printWidth]
	mov	dx, es:[printHeight]
	pop	bx				; routine to call => BX
	pop	ax				; MyPrintAttrs => AL
	pop	si				; YearObject => *DS:SI
	mov	di, ds:[si]
	add	di, ds:[di].Year_offset		; YearInstance => DS:DI
	push	bp				; save the GState
	call	bx				; call the proper print routine
	pop	di				; restore the GState
	popdw	bxsi				; PrintControl OD => BX:SI
	jc	done				; if carry set, do nothing

	; Make sure we end the page before passing this back to the
	; PrintControl object
	;
	push	ax
	mov	al, PEC_FORM_FEED
	call	GrNewPage
	pop	ax
	call	ObjMessage_print_call		; send the method
done:	
	.leave
	ret
YearStartPrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintOneMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the requested graphic output

CALLED BY:	MyPrintPrintNow (MSG_YEAR_PRINT_ONE_MONTH)

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearInstance
		BP	= GString to use
		DX	= Height of printable area
		CX	= Width of printable area
		AL	= MyPrintAttrs

RETURN:		AX	= Message to return to PrintControl object
		Carry	= Clear
			- or -
		AX	= Nothing
		Carry	= Set

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearPrintOneMonth	proc	near
	.enter

	; Store some size information
	;
	mov	ds:[di].YI_printMonthWidth, cx	; store the width
	mov	ds:[di].YI_printMonthHeight, dx	; store the height
	call	YearPrintCalcFontSize		; calculate the font sizes
	jc	tooSmall			; if too small, display error
	push	ax				; save MyPrintAttributes (AL)

	; Print one month
	;
	clr	ax, cx				; draw at upper-left
	mov	dh, ds:[di].YI_printMonth	; month => DH
	mov	di, si				; Year handle => DI
	mov	si, offset Interface:MonthPrintObj
	call	YearPrintOneMonthLow		; print the desired month

	; Print the events if needed
	;
	pop	ax				; MyPrintAttributes => AH
	test	al, mask MPA_INCLUDE_EVENTS	; print events ?? (carry clear)
	jz	done				; no, so we're done 
	GetResourceHandleNS	DayPlanObject, cx
	mov	dx, offset DayPlanObject	; DayPlanObject OD in CX:DX
	mov	ax, MSG_MONTH_DRAW_EVENTS	
	call	ObjCallInstanceNoLock		; send the method
	stc					; don't send a message back
done:
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
exit:
	.leave
	ret

	; The month is too small, so tell the user & abort
tooSmall:
	call	DisplayTooSmallErrorMessage
	clc					; we're done
	jmp	exit
YearPrintOneMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintOneYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the requested graphic output

CALLED BY:	MyPrintPrintNow (MSG_PRINT_START_PRINTING)

PASS:		DS:*SI	= YearClass object
		DS:DI	= YearInstance
		BP	= GString to use
		DX	= Height of printable area
		CX	= Width of printable area
		AL	= MyPrintAttrs

RETURN:		AX	= Message to return to PrintControl object
		Carry	= Clear
			- or -
		AX	= Nothing
		Carry	= Set

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DIMENSION_12x1	= 8				; mid between 12 & 3
DIMENSION_6x2	= 2				; mid between 1.3333 & 3
DIMENSION_4x3	= 1				; mid between .75 & 1.3333
DIMENSION_3x4	= 0x7000			; mid between .125 & .75
DIMENSION_2x6	= 0x1aaa			; mid between .0833 & .125

YearPrintOneYear	proc	near
	.enter

	; Calculate the font size for the title
	;
	push	cx, dx
	xchg	di, bp				; GState => DI
	call	YearPrintCalcTitleFontSize	; font size => BX
	call	GrGetFont			; get fontID => CX
	mov	dx, bx				; fontsize => DX
	clr	ah				; no fractional point size
	call	GrSetFont			; set the font & size
	xchg	di, bp				; GState => BP
	pop	cx, dx
	sub	dx, bx				; allow room for title

	; Determine the geometry for the printout
	;
	push	cx, cx, dx			; save the width(2) & height
	mov	bx, dx
	clr	ax				; height => BX:AX
	mov	dx, cx
	clr	cx				; width => DX:CX
	call	GrUDivWWFixed			; width/height => DX:CX
	mov	bx, (12 shl 8) or 1
	cmp	dx, DIMENSION_12x1		; check for cutoff value
	jae	setDimension
	mov	bx, (6 shl 8) or 2
	cmp	dx, DIMENSION_6x2		; check for cutoff value
	jae	setDimension
	mov	bx, (4 shl 8) or 3
	cmp	dx, DIMENSION_4x3		; check for cutoff value
	jae	setDimension
	mov	bx, (3 shl 8) or 4
	cmp	cx, DIMENSION_3x4		; check for cutoff value
	jae	setDimension
	mov	bx, (2 shl 8) or 6
	cmp	cx, DIMENSION_2x6		; check for cutoff value
	jae	setDimension
	mov	bx, (1 shl 8) or 12	

	; Calculate width & height of each month (col:row in BX)
setDimension:
	pop	ax				; height => AX
	clr	dx				; operand to DX:AX
	mov	cl, bl				; cols => CX
	clr	ch
	div	cx
	mov	ds:[di].YI_printMonthHeight, ax	; store the month height
	pop	ax				; screen width => AX
	clr	dx				; operand to DX:AX
	mov	cl, bh				; rows => CX
	clr	ch
	div	cx				; perform the division
	mov	ds:[di].YI_printMonthWidth, ax	; store the month width
	pop	cx				; screen width => CX

	; Calculate the font sizes, and then print
	;
	call	YearPrintCalcFontSize		; calculate the font sizes
	jc	tooSmall			; display error & abort
	mov	ax, cx				; screen width => AX
	call	YearPrintOneYearLow		; print the year...
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
done:
	clc					; send the message back

	.leave
	ret

	; The months are too small, so tell the user & abort
tooSmall:
	call	DisplayTooSmallErrorMessage
	jmp	done
YearPrintOneYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTooSmallErrorMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error message that the month or year is too small
		to be printed (according to the user-defined page size)

CALLED BY:	YearPrintOneMonth(), YearPrintOneYear()

PASS:		Nothing

RETURN:		AX	= MSG_PRINT_CONTROL_PRINTING_CANCELLED

DESTROYED:	BX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayTooSmallErrorMessage	proc	near
	.enter
	
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	call	GeodeGetProcessHandle		; my process handle => BX
	mov	bp, CAL_ERROR_YEAR_TOO_SMALL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage			; send the method
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED

	.leave
	ret
DisplayTooSmallErrorMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintCalcTitleFontSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the font size to be used for the year's title

CALLED BY:	YearPrintOneYear
	
PASS:		DX	= Document height (in points)

RETURN:		BX	= PointSize to use for title

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearPrintCalcTitleFontSize	proc	near
	.enter

	; Else calculate the font size
	;
	mov	cl, 5				; shift amount => CL
	shr	dx, cl				; divide by 32
	mov	bx, dx
	shr	dx, 1
	add	bx, dx				; font size => BX

	.leave
	ret
YearPrintCalcTitleFontSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintCalcFontSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the font sizes to be used for printing

CALLED BY:	YearPrintCommonBegin
	
PASS:		DS:DI	= YearClass specific instance data

RETURN:		Carry	= Set if month size too small

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MIN_PRINTABLE_DIMMENSION = 90 			; 1.125 inches

YearPrintCalcFontSize	proc	near
	class	YearClass
	uses	ax, bx, cx, dx
	.enter

	; Are we in graphics or text mode ?
	;
	mov	cx, ds:[di].YI_printMonthWidth	; month width => CX
	mov	dx, dS:[di].YI_printMonthHeight	; month height => DX

	; Find the smallest dimmension - convert to inches
	;
	mov	ax, cx				; width => AX
	cmp	cx, dx
	jbe	checkLandscape
	mov	ax, dx				; else length => AX
checkLandscape:
	jz	convert				; if not landscape, continue
	cmp	ax, 6 * 72			; compare with 6-inch minimum
	jle	convert
	sub	ax, 2 * 72			; else subtract two inches
convert:
	cmp	ax, MIN_PRINTABLE_DIMMENSION	; too small ?
	jl	done				; carry is set
	clr	dx				; operand => DX:AX
	mov	bx, 24				; convert to 1/3 inches
	div	bx				; result =>AX, remainder =>DX
	shr	dx, 1				; divide remainder by 2
	cmp	bx, dx				; check for rounding
	jb	getSizes
	inc	ax				; else round up

	; Now get the actual sizes (from inches!)
	; 1.5 x 1.5 => 9, 12
	; 2.5 x 2.5 => 12, 18
	; 3.5 x  => 15, 24
getSizes:
	mov	ah, al				; title size => AH
	shl	ah, 1				; double
	add	ah, 2				; title font size => AH
	add	al, 4				; digit font size => AL
	mov	ds:[di].YI_printFontSizes, ax	; store the font sizes
done:
	.leave
	ret
YearPrintCalcFontSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintOneYearLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print twelve months in a row, in the desired configuration

CALLED BY:	GLOBAL
	
PASS:		DS:DI	= YearClass specific instance data
		DS:*SI	= YearClass instance data
		BP	= GState
		BH	= Columns
		BL	= Rows
		AX	= Width of the screen

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <YEAR_BUFFER_SIZE	equ	6					>
DBCS <YEAR_BUFFER_SIZE	equ	6*(size wchar)				>

YearPrintOneYearLow	proc	near
	class	YearClass
	uses	si, bp
	.enter

	; We must draw the year, centered
	;
	mov	dx, bp				; GState => DX
	push	ds, si, bx
	mov	bp, ds:[di].YI_printYear	; year to print => BP
	segmov	es, ss				; coreblock segment => ES
	sub	sp, YEAR_BUFFER_SIZE		; allocate buffer on stack
	mov	di, sp				; buffer => ES:DI
	mov	si, sp				; also => ES:SI
	mov	cx, DTF_YEAR
	call	CreateDateString
	segmov	ds, es				; string => DS:SI
	mov	di, dx				; GState => DI
	call	GrTextWidth			; get length of string
	sub	ax, dx				; subtract length of string
	sar	ax, 1				; divide it by 2
	clr	bx				; draw at the top of the page
	clr	cx				; string is null terminated
	call	GrDrawText			; write it!!

	; Move the reset of the year down
	;
	call	GrGetFont			; font size => DX
	mov	bx, dx				; Y translation => BX:AX
	clr	ax
	clr	cx				; X translation => DX:CX
	clr	dx
	call	GrApplyTranslation
	mov	bp, di				; GState => BP
	add	sp, YEAR_BUFFER_SIZE		; restore the stack
	pop	ds, si, bx

	; Some set-up work
	;
	mov	dh, 1				; start with January
	mov	dl, bh				; #columns => DL
	mov	di, si				; Year handle => DI
	clr	ax, cx				; start in upper-left corner
	
	; Now loop for twelve months
yearLoop:
	mov	si, offset Interface:MonthPrintObj
	call	YearPrintOneMonthLow
	inc	dh				; go to the next month
	cmp	dh, 12				; are we done yet ?
	jg	done				; yes, exit
	mov	si, ds:[di]			; dereference the year handle
	add	si, ds:[si].Year_offset		; access the specific data
	add	cx, ds:[si].YI_printMonthWidth	; move over by one month
	dec	bh				; subtract one column
	jnz	yearLoop			; loop if not zero
	dec	bl				; else decrement one row
	clr	cx				; start at left border...
	add	ax, ds:[si].YI_printMonthHeight	; ...one row below
	mov	bh, dl				; column count => BH
	jmp	yearLoop			; loop again
done:
	.leave
	ret
YearPrintOneYearLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPrintOneMonthLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles the printing of of one month

CALLED BY:	GLOBAL
	
PASS:		DS:*DI	= YearClass specific instance data
		DS:*SI	= Month object to print
		BP	= GState
		DH	= Month (year assumed to be YI_printYear)
		CX	= Left boundary
		AX	= Top boundary

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearPrintOneMonthLow	proc	near
	class	YearClass
	uses	ax, bx, cx, dx, di, si
	.enter

	; First set the year & month
	;
	push	di				; save the year handle
	mov	bx, bp				; GState => BX
	push	cx, ax				; save the position data
	mov	di, ds:[di]			; dereference the handle
	add	di, ds:[di].Year_offset		; add in the specific offset
	mov	bp, ds:[di].YI_printYear	; year => BP
	mov	cx, ds:[di].YI_printFontSizes
	mov	ax, MSG_MONTH_SET_MONTH
	call	ObjCallInstanceNoLock

	; Now set the position stuff
	;
	pop	cx, dx				; left => CX, top => DX
	mov	ax, MSG_VIS_POSITION_BRANCH
	call	ObjCallInstanceNoLock
	pop	di				; year handle => DI
	mov	di, ds:[di]			; dereference the handle
	add	di, ds:[di].Year_offset		; add in the specific offset
	mov	cx, ds:[di].YI_printMonthWidth
	mov	dx, ds:[di].YI_printMonthHeight
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	; Tell the month to re-calculate its cached size data
	;
	mov	ax, MSG_MONTH_SET_STATE
	mov	cx, MI_NEW_SIZE shl 8		; set this flag	
	call	ObjCallInstanceNoLock

	; Finally draw this month
	;
	mov	ax, MSG_VIS_DRAW		; send the draw method
	mov	bp, bx				; GString => BP
	mov	cl, mask DF_PRINT		; the print flag
	call	ObjCallInstanceNoLock

	.leave
	ret
YearPrintOneMonthLow	endp

PrintCode	ends
