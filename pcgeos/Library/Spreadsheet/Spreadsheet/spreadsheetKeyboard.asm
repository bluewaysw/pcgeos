COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetKeyboard.asm

AUTHOR:		Gene Anderson, Feb 27, 1991

ROUTINES:
	Name			Description
	----			-----------
METHOD	SpreadsheetKbdChar	MSG_META_KBD_CHAR handler

INT	SSKbdEnter		<Enter> handler
INT	SSKbdShiftEnter		<Shift><Enter> handler
INT	SSKbdTab		<Tab> handler
INT	SSKbdShiftTab		<Shift><Tab> handler

INT	SSKbdDown		<down arrow> handler
INT	SSKbdUp			<up arrow> handler
INT	SSKbdRight		<right arrow> handler
INT	SSKbdLeft		<left arrow> handler
INT	SSKbdShiftDown		<Shift><down arrow> handler
INT	SSKbdShiftUp		<Shift><up arrow> handler
INT	SSKbdShiftRight		<Shift><right arrow> handler
INT	SSKbdShiftLeft		<Shift><left arrow> handler

INT	SSKbdCtrlDown		<Ctrl><down arrow> handler
INT	SSKbdCtrlUp		<Ctrl><up arrow> handler
INT	SSKbdCtrlRight		<Ctrl><right arrow> handler
INT	SSKbdCtrlLeft		<Ctrl><left arrow> handler
INT	SSKbdShiftCtrlDown	<Shift><Ctrl><down arrow> handler
INT	SSKbdShiftCtrlUp	<Shift><Ctrl><up arrow> handler
INT	SSKbdShiftCtrlRight	<Shift><Ctrl><right arrow> handler
INT	SSKbdShiftCtrlLeft	<Shift><Ctrl><left arrow> handler

INT	SSKbdHome		<Home> handler
INT	SSKbdShiftHome		<Shift><Home> handler
INT	SSKbdCtrlHome		<Ctrl><Home> handler
INT	SSKbdShiftCtrlHome	<Shift><Ctrl><Home> handler
INT	SSKbdEnd		<End> handler
INT	SSkbdShiftEnd		<Shift><End> handler
INT	SSKbdCtrlEnd		<Ctrl><End> handler
INT	SSKbdShiftCtrlEnd	<Shift><Ctrl><End> handler

UTIL	GetNextColumn		Get next legal column
UTIL	GetPreviousColumn	Get previous legal column
UTIL	GetNextRow		Get next legal row
UTIL	GetPreviousRow		Get previous legal column
UTIL	GetNextSelectedColumn	Get next legal selected column
UTIL	GetPreviousSelectedColumn Get previous legal selected column
UTIL	GetNextSelectedRow	Get next legal selected row
UTIL	GetPreviousSelectedRow	Get previous legal selected column

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/27/91		Initial revision
	witt	11/15/93	DBCS-ized the keyboard

DESCRIPTION:
	

	$Id: spreadsheetKeyboard.asm,v 1.1 97/04/07 11:14:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keyboard handler for spreadsheet.
CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si - ptr to Spreadsheet instance data
		ds:di - ds:*si
		es - seg addr of SpreadsheetClass
		ax - MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetKbdChar	method	SpreadsheetClass, MSG_META_KBD_CHAR
	.enter

	push	si
	mov	si, di				;ds:si <- ptr to instance data
EC <	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE >
	call	SpreadsheetCheckShortcut
	jnc	notShortcut			;branch if not shortcut
	test	dl, mask CF_RELEASE		;release?
	jnz	done				;ignore releases for demo
	call	cs:SSKbdActions[di]		;call handler routine
done:
	pop	si
exit:
	.leave
	ret

	;
	; The keypress wasn't for us -- pass it off.
	;
notShortcut:
	pop	si
	mov	di, offset SpreadsheetClass
	call	ObjCallSuperNoLock
	jmp	exit
SpreadsheetKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCheckShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if keypress is a spreadsheet keyboard shortcut
CALLED BY:	SpreadsheetKbdChar

PASS:		ax - MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		carry - set if shortcut
		di - offset of shortcut in table
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetCheckShortcut	proc	far
	uses	ax, ds, si
	.enter

	mov	ax, (length SSKbdShortcuts)	;ax <- # shortcuts
	segmov	ds, cs
	mov	si, offset SSKbdShortcuts	;ds:si <- ptr to shortcut table
	call	FlowCheckKbdShortcut
	mov	di, si				;di <- offset of shortcut

	.leave
	ret
SpreadsheetCheckShortcut	endp

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
if DBCS_PCGEOS
SSKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0,  C_SYS_ENTER and mask KS_CHAR>,	;<Enter>
	<0, 0, 0, 1,  C_SYS_ENTER and mask KS_CHAR>,	;<Shift><Enter>
	<0, 0, 0, 0,  C_SYS_TAB and mask KS_CHAR>,	;<Tab>
	<0, 0, 0, 1,  C_SYS_TAB and mask KS_CHAR>,	;<Shift><Tab>
	<1, 0, 0, 0,  C_SYS_HOME and mask KS_CHAR>,	;<Home>
	<1, 0, 0, 1,  C_SYS_HOME and mask KS_CHAR>,	;<Shift><Home>
	<1, 0, 1, 0,  C_SYS_HOME and mask KS_CHAR>,	;<Ctrl><Home>
	<1, 0, 1, 1,  C_SYS_HOME and mask KS_CHAR>,	;<Shift><Ctrl><Home>
	<1, 0, 0, 0,  C_SYS_END and mask KS_CHAR>,	;<End>
	<1, 0, 0, 1,  C_SYS_END and mask KS_CHAR>,	;<Shift><End>
	<1, 0, 1, 0,  C_SYS_END and mask KS_CHAR>,	;<Ctrl><End>
	<1, 0, 1, 1,  C_SYS_END and mask KS_CHAR>,	;<Shift><Ctrl><End>
	<1, 0, 0, 0,  C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0,  C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 0, 0,  C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0,  C_SYS_LEFT and mask KS_CHAR>,	;<left arrow>
	<1, 0, 0, 1,  C_SYS_DOWN and mask KS_CHAR>,	;<Shift><down arrow>
	<1, 0, 0, 1,  C_SYS_UP and mask KS_CHAR>,	;<Shift><up arrow>
	<1, 0, 0, 1,  C_SYS_RIGHT and mask KS_CHAR>,	;<Shift><right arrow>
	<1, 0, 0, 1,  C_SYS_LEFT and mask KS_CHAR>,	;<Shift><left arrow>
	<1, 0, 1, 0,  C_SYS_DOWN and mask KS_CHAR>,	;<Ctrl><down arrow>
	<1, 0, 1, 0,  C_SYS_UP and mask KS_CHAR>,	;<Ctrl><up arrow>
	<1, 0, 1, 0,  C_SYS_RIGHT and mask KS_CHAR>,	;<Ctrl><right arrow>
	<1, 0, 1, 0,  C_SYS_LEFT and mask KS_CHAR>,	;<Ctrl><left arrow>
	<1, 0, 1, 1,  C_SYS_DOWN and mask KS_CHAR>,	;<Shift><Ctrl><down arrow>
	<1, 0, 1, 1,  C_SYS_UP and mask KS_CHAR>,	;<Shift><Ctrl><up arrow>
	<1, 0, 1, 1,  C_SYS_RIGHT and mask KS_CHAR>,	;<Shift><Ctrl><right arrow>
	<1, 0, 1, 1,  C_SYS_LEFT and mask KS_CHAR>,	;<Shift><Ctrl><left arrow>
	<1, 0, 0, 0,  C_SYS_DELETE and mask KS_CHAR>,	;<Delete>
	<1, 0, 1, 1,  C_SLASH>				;<Shift><Ctrl></>

else
SSKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_ENTER>,		;<Enter>
	<0, 0, 0, 1, 0xf, VC_ENTER>,		;<Shift><Enter>
	<0, 0, 0, 0, 0xf, VC_TAB>,		;<Tab>
	<0, 0, 0, 1, 0xf, VC_TAB>,		;<Shift><Tab>
	<1, 0, 0, 0, 0xf, VC_HOME>,		;<Home>
	<1, 0, 0, 1, 0xf, VC_HOME>,		;<Shift><Home>
	<1, 0, 1, 0, 0xf, VC_HOME>,		;<Ctrl><Home>
	<1, 0, 1, 1, 0xf, VC_HOME>,		;<Shift><Ctrl><Home>
	<1, 0, 0, 0, 0xf, VC_END>,		;<End>
	<1, 0, 0, 1, 0xf, VC_END>,		;<Shift><End>
	<1, 0, 1, 0, 0xf, VC_END>,		;<Ctrl><End>
	<1, 0, 1, 1, 0xf, VC_END>,		;<Shift><Ctrl><End>
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<1, 0, 0, 1, 0xf, VC_DOWN>,		;<Shift><down arrow>
	<1, 0, 0, 1, 0xf, VC_UP>,		;<Shift><up arrow>
	<1, 0, 0, 1, 0xf, VC_RIGHT>,		;<Shift><right arrow>
	<1, 0, 0, 1, 0xf, VC_LEFT>,		;<Shift><left arrow>
	<1, 0, 1, 0, 0xf, VC_DOWN>,		;<Ctrl><down arrow>
	<1, 0, 1, 0, 0xf, VC_UP>,		;<Ctrl><up arrow>
	<1, 0, 1, 0, 0xf, VC_RIGHT>,		;<Ctrl><right arrow>
	<1, 0, 1, 0, 0xf, VC_LEFT>,		;<Ctrl><left arrow>
	<1, 0, 1, 1, 0xf, VC_DOWN>,		;<Shift><Ctrl><down arrow>
	<1, 0, 1, 1, 0xf, VC_UP>,		;<Shift><Ctrl><up arrow>
	<1, 0, 1, 1, 0xf, VC_RIGHT>,		;<Shift><Ctrl><right arrow>
	<1, 0, 1, 1, 0xf, VC_LEFT>,		;<Shift><Ctrl><left arrow>
	<1, 0, 0, 0, 0xf, VC_DEL>,		;<Delete>
	<1, 0, 1, 1, 0x0, C_SLASH>		;<Shift><Ctrl></>
endif


SSKbdActions nptr \
	offset SSKbdEnter,
	offset SSKbdShiftEnter,
	offset SSKbdTab,
	offset SSKbdShiftTab,
	offset SSKbdHome,
	offset SSKbdShiftHome,
	offset SSKbdCtrlHome,
	offset SSKbdShiftCtrlHome,
	offset SSKbdEnd,
	offset SSKbdShiftEnd,
	offset SSKbdCtrlEnd,
	offset SSKbdShiftCtrlEnd,
	offset SSKbdDown,
	offset SSKbdUp,
	offset SSKbdRight,
	offset SSKbdLeft,
	offset SSKbdShiftDown,
	offset SSKbdShiftUp,
	offset SSKbdShiftRight,
	offset SSKbdShiftLeft,
	offset SSKbdCtrlDown,
	offset SSKbdCtrlUp,
	offset SSKbdCtrlRight,
	offset SSKbdCtrlLeft,
	offset SSKbdShiftCtrlDown,
	offset SSKbdShiftCtrlUp,
	offset SSKbdShiftCtrlRight,
	offset SSKbdShiftCtrlLeft,
	offset SSKbdDelete,
	offset SSKbdSelectData
CheckHack <length SSKbdShortcuts eq length SSKbdActions>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextSelectedColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a selected column, get the next selected column
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - row
		cx - column
RETURN:		ax - row
		cx - previous selected column
		carry - set if already at right
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNextSelectedColumn	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckSelectedCell		;>
	;
	; If single cell or not at right of selection,
	; just return next column.
	;
	call	SingleCell?
	jc	nextColumn
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	jb	nextColumn
	;
	; If at the right side, wrap to the left side
	; and go to the next selected row.
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	inc	ax				;ax <- next row
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	jbe	done
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row	;ax <- top row
done:
	clc					;carry <- not at right
	ret

nextColumn:
	FALL_THRU	GetNextColumn
GetNextSelectedColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a column, get the next legal column
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		cx - column
RETURN:		cx - next column
		carry - set if already at right
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNextColumn	proc	near
	class	SpreadsheetClass
	uses	dx

	.enter
EC <	call	ECCheckInstancePtr		;>
tryAgain:
	cmp	cx, ds:[si].SSI_maxCol		;at right?
	stc
	je	atRight				;branch if at right
	inc	cx				;cx <- right one column
	call	ColumnGetWidth			;dx <- width of column
	je	tryAgain			;branch if column hidden
	clc					;carry <- indicate not right
atRight:
	.leave
	ret
GetNextColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviousSelectedColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a selected column, get the previous selected column
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - row
		cx - column
RETURN:		ax - row
		cx - previous selected column
		carry - set if already at left
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPreviousSelectedColumn	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckSelectedCell		;>
	;
	; If single cell or not at left of selection,
	; just return the previous column.
	;
	call	SingleCell?
	jc	previousColumn
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	ja	previousColumn
	;
	; If at the left side, wrap to the right side
	; and go to the previous selected row.
	;
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column

	push	dx			; current row
	call	SSGetMinRow
	cmp	ax, dx
	pop	dx

	je	wrap				;branch if at top
	dec	ax				;ax <- previous row
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row	;beyond top of selection?
	jae	done				;branch if not beyond top
wrap:
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
done:
	clc					;carry <- not at left
	ret

previousColumn:
	FALL_THRU	GetPreviousColumn
GetPreviousSelectedColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviousColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a column, get the previous legal column
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		cx - column
RETURN:		cx - previous column
		carry - set if already at left
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPreviousColumn	proc	near
	class	SpreadsheetClass
	uses	dx

	.enter
EC <	call	ECCheckInstancePtr		;>
tryAgain:
	call	SSGetMinColumn
	cmp	cx, dx				;at left?
	stc
	je	atLeft				;branch if at left
	dec	cx				;cx <- one row left
	call	ColumnGetWidth			;dx <- width of column
	jz	tryAgain			;branch if column hidden
	clc					;carry <- indicate not left
atLeft:
	.leave
	ret
GetPreviousColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextSelectedRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a selected row, get next selected row
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - row
		cx - column
RETURN:		ax - next selected row
		cx - column
		carry - set if already at bottom
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNextSelectedRow	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckSelectedCell		;>
	;
	; If single cell or not at bottom of selection,
	; just return the next row
	;
	call	SingleCell?
	jc	nextRow
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	jb	nextRow
	;
	; If at the bottom, wrap to the top and
	; go to the next selected column.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	inc	cx				;ax <- next column
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	jbe	done
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
done:
	clc					;carry <- not at bottom
	ret

nextRow:
	FALL_THRU	GetNextRow
GetNextSelectedRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a row, get the next legal row.
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - row
RETURN:		ax - next row
		carry - set if already at bottom
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNextRow	proc	near
	class	SpreadsheetClass
	uses	dx

	.enter
EC <	call	ECCheckInstancePtr		;>
tryAgain:
	cmp	ax, ds:[si].SSI_maxRow		;at bottom?
	stc
	je	atBottom			;branch if at bottom
	inc	ax				;ax <- down one row
	call	RowGetHeight			;dx <- row height
	je	tryAgain			;branch if row hidden
	clc					;carry <- indicate not bottom
atBottom:
	.leave
	ret
GetNextRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviousSelectedRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a selected row, find previous selected row
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - row
		cx - column
RETURN:		ax - next row
		cx - column
		carry - set if already at top
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPreviousSelectedRow	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckSelectedCell		;>
	;
	; If single cell or not at top of selection,
	; just return the previous row.
	;
	call	SingleCell?
	jc	previousRow
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	ja	previousRow
	;
	; If at the top, wrap to the bottom
	; and go to the previous selected column.
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	push	dx
	call	SSGetMinColumn
	cmp	cx, dx				;at left of spreadsheet?
	pop	dx
	je	wrap				;branch if at left
	dec	cx				;cx <- previous column
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column	;beyond left of selection?
	jae	done				;branch if not beyond left
wrap:
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
done:
	clc					;carry <- not at top
	ret

previousRow:
	FALL_THRU	GetPreviousRow
GetPreviousSelectedRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviousRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a row, get the previous legal row
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - row
RETURN:		ax - previous row
		carry - set if already at top
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPreviousRow	proc	near
	class	SpreadsheetClass
	uses	dx

	.enter
EC <	call	ECCheckInstancePtr		;>
tryAgain:
	call	SSGetMinRow
	cmp	ax, dx				;at top?
	stc
	je	atTop				;branch if at top
	dec	ax				;ax <- one row up
	call	RowGetHeight			;dx <- height of row
	je	tryAgain			;branch if row hidden
	clc					;carry <- indicate not top
atTop:
	.leave
	ret
GetPreviousRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Enter> press in the spreadsheet
		:: move active cell one row down
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdDown	proc	near
EC <	call	ECCheckInstancePtr		;>
	call	DeselectRange
	FALL_THRU	SSKbdEnter
SSKbdDown	endp

SSKbdEnter	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current row
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	call	GetNextSelectedRow		;ax <- next row
	jc	done				;branch if at bottom
	call	MoveActiveCellFar
done:

	.leave
	ret
SSKbdEnter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Enter> press in the spreadsheet
		:: move active cell one row up
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdUp	proc	near
EC <	call	ECCheckInstancePtr		;>
	call	DeselectRange
	FALL_THRU	SSKbdShiftEnter
SSKbdUp	endp

SSKbdShiftEnter	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current row
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	call	GetPreviousSelectedRow		;ax <- previous row
	jc	done				;branch if at top
	call	MoveActiveCellFar
done:

	.leave
	ret
SSKbdShiftEnter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Tab> press in the spreadsheet
		:: move active cell one column right
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdRight	proc	near
EC <	call	ECCheckInstancePtr		;>
	call	DeselectRange
	FALL_THRU	SSKbdTab
SSKbdRight	endp

SSKbdTab	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current column
	call	GetNextSelectedColumn		;cx <- next column
	jc	done				;branch if at right side
	call	MoveActiveCellFar
done:

	.leave
	ret
SSKbdTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Tab> press in the spreadsheet
		:: move active cell one column left
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdLeft	proc	near
EC <	call	ECCheckInstancePtr		;>
	call	DeselectRange
	FALL_THRU	SSKbdShiftTab
SSKbdLeft	endp

SSKbdShiftTab	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row		;ax <- current column
	mov	cx, ds:[si].SSI_active.CR_column		;cx <- current column
	call	GetPreviousSelectedColumn	;cx <- previous column
	jc	done				;branch if at left
	call	MoveActiveCellFar
done:

	.leave
	ret
SSKbdShiftTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><down arrow> press in the spreadsheet
		:: change selection one row down
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftDown	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	cmp	ax, ds:[si].SSI_active.CR_row
	jne	selectDown			;branch if anchored
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	je	selectDown			;branch if single row

	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	inc	ax
	call	ContractSelectionDown
	GOTO	FinishSelectExtendCommon

selectDown:
	call	GetNextRow			;ax <- next row
	jc	done
	call	ExtendSelectionDown
	GOTO	FinishSelectExtendCommon

done:
	ret
SSKbdShiftDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><up arrow> press in the Spreadsheet
		:: change selection one row up
CALLED BY:	SSKbdChar()

PASS:		ds:si - Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftUp	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	cmp	ax, ds:[si].SSI_active.CR_row
	jne	selectUp			;branch if anchored
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	je	selectUp			;branch if single row

	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	dec	ax
	call	ContractSelectionUp
	GOTO	FinishSelectExtendCommon

selectUp:
	call	GetPreviousRow
	jc	done
	call	ExtendSelectionUp
	GOTO	FinishSelectExtendCommon

done:
	ret
SSKbdShiftUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><right arrow> press in the Spreadsheet
		:: change selection one column right
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftRight	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
	cmp	cx, ds:[si].SSI_active.CR_column
	jne	selectRight			;branch if anchored
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	je	selectRight			;branch if single column

	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	inc	cx
	call	ContractSelectionRight
	GOTO	FinishSelectExtendCommon

selectRight:
	call	GetNextColumn
	jc	done
	call	ExtendSelectionRight
	GOTO	FinishSelectExtendCommon

done:
	ret
SSKbdShiftRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><left arrow> press in Spreadsheet
		:: change selection one column left
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftLeft	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	cmp	cx, ds:[si].SSI_active.CR_column
	jne	selectLeft			;branch if anchored
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	je	selectLeft			;branch if single column

	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
	dec	cx
	call	ContractSelectionLeft
	GOTO	FinishSelectExtendCommon

selectLeft:
	call	GetPreviousColumn
	jc	done
	call	ExtendSelectionLeft
	GOTO	FinishSelectExtendCommon

done:
	ret
SSKbdShiftLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdHome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Home> keypress
		:: move to start of row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSKbdHome	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row
	call	SSGetMinColumn
	mov	cx, dx				;(ax,cx) <- start of row
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdHome	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftHome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Home> keypress
		:: select to start of row(s)
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftHome	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	call	SSGetMinColumn
	mov	cx, dx
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	mov	bp, ds:[si].SSI_active.CR_column		;(dx,bp) <- current column
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Home>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify

	.leave
	ret
SSKbdShiftHome	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlHome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><Home> press
		:: select to start of spreadsheet ($A$1)
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlHome	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	SSGetMinRow
	mov_tr	ax, dx
	call	SSGetMinColumn
	mov	cx, dx				; (ax,cx) = top left

	mov	dx, ds:[si].SSI_active.CR_row
	mov	bp, ds:[si].SSI_active.CR_column
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><Home>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify

	.leave
	ret
SSKbdShiftCtrlHome	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <End> keypress
		:: move to end of data, same row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSKbdEnd	proc	near
	class	SpreadsheetClass
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_NO_EMPTY_CELLS		;di <- SpreadsheetEnumType
	call	CallRangeExtentWholeSheet
	.leave

	je	SSKbdCtrlHome			;branch if no data
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, bx				;(ax,cx) <- (r,c) to go to
	call	MoveActiveCellDeselectFar
	ret
SSKbdEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><End> keypress
		:: select to end of data, same row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftEnd	proc	near
	class	SpreadsheetClass
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_NO_EMPTY_CELLS		;di <- SpreadsheetEnumType
	call	CallRangeExtentWholeSheet
	.leave

	je	SSKbdCtrlHome			;branch if no data
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	mov	bp, bx				;bp <- last column with data
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><End>
	; *may* move the active cell
	;
	call	SetSelectedRangeNotify
	ret
SSKbdShiftEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlHome
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><Home> press
		:: move to start of spreadsheet ($A$1)
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlHome	proc	near
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	SSGetMinRow
	mov_tr	ax, dx
	call	SSGetMinColumn
	mov	cx, dx				; (ax,cx) - upper left
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdCtrlHome	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><End> keypress
		:: move to end of data
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlEnd	proc	near
	class	SpreadsheetClass

	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_NO_EMPTY_CELLS		;di <- SpreadsheetEnumType
	call	CallRangeExtentWholeSheet
	.leave

	je	SSKbdCtrlHome			;branch if no data
	mov	ax, dx
	mov	cx, bx				;(ax,cx) <- (r,c) to go to
	call	MoveActiveCellDeselectFar
	ret
SSKbdCtrlEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><End> keypress
		:: select to end of data, same column
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlEnd	proc	near
	class	SpreadsheetClass

	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, SET_NO_EMPTY_CELLS		;di <- SpreadsheetEnumType
	call	CallRangeExtentWholeSheet
	.leave

	je	SSKbdCtrlHome			;branch if no data
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	mov	bp, bx
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><End>
	; *may* move the active cell
	;
	call	SetSelectedRangeNotify
	ret
SSKbdShiftCtrlEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><down arrow> press
		:: go to next data/no data transition in column
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlDown	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row
	mov	dx, ds:[si].SSI_maxRow
	call	ExtentNextTransitionCellCurCol
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdCtrlDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><down arrow> press
		:: select to next data/no data transition in column
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlDown	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; If a single row is selected, or the selection is not anchored
	; at the bottom, then select down.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ds:[si].SSI_selected.CR_start.CR_row, ax
	je	selectDown
	cmp	ds:[si].SSI_selected.CR_end.CR_row, ax
	je	contractDown
selectDown:
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_maxRow		 ;(ax,dx) <- rows to search
	call	ExtentNextTransitionCellCurCol
	mov	dx, ds:[si].SSI_selected.CR_start.CR_row
setSelection:
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_column
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><Down>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify

	.leave
	ret

	;
	; The selection is anchored at the bottom, so contract the
	; selection downward to the next transition cell.
	;
contractDown:
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_active.CR_row		;(ax,dx) <- rows to search
	call	ExtentNextTransitionCellCurCol
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	jmp	setSelection
SSKbdShiftCtrlDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><up arrow> press
		:: go to previous data/no data transition in column
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlUp	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	SSGetMinRow			; dx <- min row
	mov	ax, ds:[si].SSI_active.CR_row	;(dx,ax) <- rows to search
	call	ExtentPrevTransitionCellCurCol
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdCtrlUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><up arrow> press
		:: select to next data/no data transition in column
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlUp	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; If a single row is selected, or the selection is not anchored
	; at the top, then select up.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ds:[si].SSI_selected.CR_end.CR_row, ax
	je	selectUp
	cmp	ds:[si].SSI_selected.CR_start.CR_row, ax
	je	contractUp
selectUp:
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	call	SSGetMinRow			;(ax,dx) <- rows to search
	call	ExtentPrevTransitionCellCurCol
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
setSelection:
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_column
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><Up>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify

	.leave
	ret

	;
	; The selection is anchored at the top, so contract the
	; selection upward to the next transition cell.
	;
contractUp:
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_active.CR_row		;(ax,dx) <- rows to search
	call	ExtentPrevTransitionCellCurCol
	mov	dx, ds:[si].SSI_selected.CR_start.CR_row
	jmp	setSelection
SSKbdShiftCtrlUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><right arrow> press
		:: go to next data/no data transition in row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlRight	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_active.CR_column
	mov	bx, ds:[si].SSI_maxCol
	call	ExtentNextTransitionCellCurRow
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdCtrlRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><right arrow> press
		:: select to next data/no data transition in row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlRight	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; If a single column is selected, or the selection is not anchored
	; at the right, then select to the right.
	;
	mov	cx, ds:[si].SSI_active.CR_column
	cmp	ds:[si].SSI_selected.CR_start.CR_column, cx
	je	selectRight
	cmp	ds:[si].SSI_selected.CR_end.CR_column, cx
	je	contractRight
selectRight:
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
	mov	bx, ds:[si].SSI_maxCol		 ;(cx,bx) <- cols to search
	call	ExtentNextTransitionCellCurRow
	mov	bp, ds:[si].SSI_selected.CR_start.CR_column
setSelection:
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><Right>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify
	
	.leave
	ret

	;
	; The selection is anchored at the right, so contract the
	; selection to the next transition cell to the right.
	;
contractRight:
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_active.CR_column		;(cx,bx) <- cols to search
	call	ExtentNextTransitionCellCurRow
	mov	bp, ds:[si].SSI_selected.CR_end.CR_column
	jmp	setSelection
SSKbdShiftCtrlRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdCtrlLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Ctrl><left arrow> press
		:: go to previous data/no data transition in row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdCtrlLeft	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	SSGetMinRow
	mov	bx, dx
	mov	cx, ds:[si].SSI_active.CR_column
	call	ExtentPrevTransitionCellCurRow
	call	MoveActiveCellDeselectFar

	.leave
	ret
SSKbdCtrlLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdShiftCtrlLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl><left arrow> press
		:: select to previous data/no data transition in row
CALLED BY:	SSKbdChar()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSKbdShiftCtrlLeft	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; If a single column is selected, or the selection is not anchored
	; at the left, then select left.
	;
	mov	cx, ds:[si].SSI_active.CR_column
	cmp	ds:[si].SSI_selected.CR_end.CR_column, cx
	je	selectLeft
	cmp	ds:[si].SSI_selected.CR_start.CR_column, cx
	je	contractLeft
selectLeft:
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	push	dx
	call	SSGetMinColumn			;(cx,bx) <- cols to search
	mov	bx, dx
	pop	dx
	call	ExtentPrevTransitionCellCurRow
	mov	bp, ds:[si].SSI_selected.CR_end.CR_column
setSelection:
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	;
	; NOTE: this is called under the assumption that:
	;	<Shift><Ctrl><Left>
	; will not move the active cell
	;
	call	ExtendSelectedRangeNotify

	.leave
	ret

	;
	; The selection is anchored at the left, so contract the
	; selection to the next transition cell to the left.
	;
contractLeft:
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
	mov	bx, ds:[si].SSI_active.CR_column		;(cx,bx) <- cols to search
	call	ExtentPrevTransitionCellCurRow
	mov	bp, ds:[si].SSI_selected.CR_start.CR_column
	jmp	setSelection
SSKbdShiftCtrlLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Delete> press

CALLED BY:	SSKbdChar()
PASS:		ds:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSKbdDelete		proc	near
	uses	si
	class	SpreadsheetClass
	.enter

	mov	si, ds:[si].SSI_chunk		;*ds:si <- spreadsheet object
	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	.leave
	ret
SSKbdDelete		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSKbdSelectData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle <Shift><Ctrl>+</> -- select data range

CALLED BY:	SSKbdChar()
PASS:		ds:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSKbdSelectData		proc	near
	uses	si, es
	class	SpreadsheetClass
	.enter

	sub	sp, (size SpreadsheetRangeParams)
	mov	bp, sp				;ss:bp <- params
	segmov	es, ss
	mov	di, bp
	mov	ax, SPREADSHEET_ADDRESS_DATA_AREA
	stosw
	stosw
	stosw
	stosw
	mov	ax, SPREADSHEET_ADDRESS_IN_SELECTION
	stosw
	stosw
CheckHack <(size SpreadsheetRangeParams) eq 6*(size word)>
	mov	si, ds:[si].SSI_chunk		;*ds:si <- spreadsheet object
	mov	ax, MSG_SPREADSHEET_SET_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, (size SpreadsheetRangeParams)

	.leave
	ret
SSKbdSelectData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSGetMinRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the minimum row for keyboard navigation

CALLED BY:	

PASS:		ds:si - spreadsheet instance data

RETURN:		dx - minimum row

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/15/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSGetMinRow	proc near
		class	SpreadsheetClass
		.enter
EC <		call	ECCheckInstancePtr				>

		clr	dx
		test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
		jnz	getVarData
done:
		.leave
		ret

getVarData:
		push	bx
		call	getVarDataCommon
		mov	dx, ds:[bx].SDO_rowCol.CR_row
		pop	bx
		jmp	done

getVarDataCommon label near
		push	ax, si
		mov	si, ds:[si].SSI_chunk
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		call	ObjVarFindData
EC <		ERROR_NC SPREADSHEET_ORIGIN_NOT_FOUND			>
		pop	ax, si
		retn

SSGetMinRow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSGetMinColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the minimum column for keyboard navigation

CALLED BY:	keyboard navigation functions

PASS:		ds:si - spreadsheet instance data

RETURN:		dx - minimum column

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/15/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSGetMinColumn	proc near
		class	SpreadsheetClass
		.enter
EC <		call	ECCheckInstancePtr				>

		clr	dx
		test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
		jnz	getVarData
done:
		.leave
		ret
getVarData:
		push	bx
		call	getVarDataCommon
		mov	dx, ds:[bx].SDO_rowCol.CR_column
		pop	bx
		jmp	done

SSGetMinColumn	endp



GetNextRowFar	proc	far
	call	GetNextRow
	ret
GetNextRowFar	endp

GetPreviousRowFar	proc	far
	call	GetPreviousRow
	ret
GetPreviousRowFar	endp

GetNextColumnFar	proc	far
	call	GetNextColumn
	ret
GetNextColumnFar	endp

GetPreviousColumnFar	proc	far
	call	GetPreviousColumn
	ret
GetPreviousColumnFar	endp

DrawCode	ends
