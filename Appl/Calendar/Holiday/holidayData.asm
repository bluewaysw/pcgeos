COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS J
MODULE:		JCalendar/Holiday
FILE:		holidayData.asm

AUTHOR:		TORU TERAUCHI, JUL 28, 1993

ROUTINES:
	NAME			DESCRIPTION
	----			-----------
	GetHolidayDateYear	Get holiday date in a month of a Year
	SetHolidayDateYear	Set holiday date in a month of a year
	DeleteHolidayDateYear	Delete holiday date in a month of a year
	GetHolidayDate		Get holiday date in a month
	SetHolidayDate		Set holiday date in a month
	DeleteHolidayDate	Delete holiday date in a month
	SetMonthDate		Set month and date to a ChunkArray
	SetYearMonthDate	Set year, month and date to a ChunkArray
	GetYearMonthDate	Get year, month and date from a ChunkArray
	DeleteAllHolidayDateYearDelete year, month ChunckArray
	DeleteAllHolidayDate	Delete month ChunckArray
	CheckHolidayDateYear	Error check year, month ChunckArray
	CheckHolidayDate	Error check month ChunckArray

	DumpHolidayDateYear	Dump holiday data for debug
	DumpHolidayDate		Dump holiday data for debug

	
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Tera	6/23/93		INITIAL REVISION


DESCRIPTION:
	Set / Get holiday data from ChunkArray
		

	$Id: holidayData.asm,v 1.1 97/04/04 14:49:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HolidayCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get holiday date in a month of a Year

CALLED BY:	SetHGetHDate ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
		dx	= number of a year
RETURN:		ax	= date low
		cx	= date high
		carry set = if can't search target
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetHolidayDateYear	proc	near
	uses	si, di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	notFind

readLoop:
	; Search data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	word ptr ds:[di].HYC_year, dx
	jna	exitLoop			; data <= dx
	loop	readLoop			; cx : counter
exitLoop:
	je	next				; find out
notFind:
	clrdw	axcx
	stc					; set carry
	jmp	done				; can't search target

next:
	; Get holiday date
	;
	mov	si, ds:[di].HYC_chunk		; set ChunkArray
	call	GetHolidayDate

done:
	.leave
	ret
GetHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set holiday date in a month of a year

CALLED BY:	SetHSetResetH ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
		bh	= number of a date
		dx	= number of a year
RETURN:		ds	= block may move
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If there isn't its year cell, create a new data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/29/93		Dereference year cell

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHolidayDateYear	proc	near
	uses	si, di, bp
	.enter
	push	bx				; save parameter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	appendCell

	; Search data
	;
	clr	bx
readLoop:
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	word ptr ds:[di].HYC_year, dx
	je	setData				; data == dx
	jb	makeCell			; data < dx
	mov	bx, di				; save element
	loop	readLoop			; cx : counter
	jmp	insertCell

	; Create a new year cell
	;
makeCell:
	tst	bx
	je	appendCell
insertCell:
	mov	di, bx				; set element
	clr	ax				; element size
	call	ChunkArrayInsertAt
	jmp	makeMonthArray

appendCell:
	clr	ax				; element size
	call	ChunkArrayAppend
	; jmp	makeMonthArray

	; Now create a month array
	;
makeMonthArray:
	mov	word ptr ds:[di].HYC_year, dx	; set year
	mov	bp, si				; bp <- year array
	push	ds				; save ds : year segment

						; ds : segment ptr for the heap
	mov	bx, size HolidayMonthCell	; element size
	clr	cx				; size for ChunkArrayHeader
	clr	si				; number of alloc ( one )
	clr	al				; ObjChunkFlags no needs ????
	call	ChunkArrayCreate		; *ds:si new array
	pop	ax				; restore year segment <- ds
	segmov	cx, ds
	cmp	ax, cx				; block was moved?
	je	notDeref			; not need dereference

	; Dereference the year cell ( need when block was moved )
	;
	push	si				; save si
	mov	si, bp				; si <- year array
	call	ChunkArrayGetCount		; cx : number of elements
derefLoop:
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	word ptr ds:[di].HYC_year, dx
	je	findCell			; data == dx
	jb	derefError			; data < dx
	loop	derefLoop			; cx : counter
derefError:
EC <	ERROR	-1				; can't find year cell	>
NEC <	pop	si							>
NEC <	pop	bx							>
NEC <	jmp	done							>
findCell:
	pop	si				; restore si
notDeref:
	mov	word ptr ds:[di].HYC_chunk, si	; set ChunkArray
	; jmp	setData

setData:
	; Set a holiday date
	;
	pop	bx				; restore parameter
	mov	si, word ptr ds:[di].HYC_chunk	; set ChunkArray
	call	SetHolidayDate

done::
	.leave
	ret
SetHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete holiday date in a month of a year

CALLED BY:	SetHSetResetH ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
		bh	= number of a date
		dx	= number of a year
RETURN:		carry set = if can't search target
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		( If there is't month cell in the year, delete year cell )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteHolidayDateYear	proc	near
	uses	si, di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	notFind

readLoop:
	; Search data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	word ptr ds:[di].HYC_year, dx
	jna	exitLoop			; data <= bl
	loop	readLoop			; cx : counter
exitLoop:
	je	next				; find out
notFind:
	stc					; set carry
	jmp	done

next:
	; Delete a date
	;
	mov	si, ds:[di].HYC_chunk		; set ChunkArray
	call	DeleteHolidayDate
	jb	notFind
	jmp	resetFlag

;;	; Count month cell
;;	;
;;	call	ChunkArrayGetCount
;;	tst	cx				; number of elements
;;	jne	resetFlag
;;
;;	; Search data to delete again
;;	;
;;	mov	ax, cx				; element number to find
;;	call	ChunkArrayElementToPtr
;;	; free or delete ds:[di].HYC_chunk ???
;;	call	ChunkArrayDelete

resetFlag:
	clc					; reset carry

done:
	.leave
	ret
DeleteHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get holiday date in a month

CALLED BY:	GetHolidayDateYear
		SetHGetHDate ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
RETURN:		ax	= date low
		cx	= date high
		carry set = if can't search target (cx:ax = ZERO)
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetHolidayDate	proc	near
	uses	di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	notFind

readLoop:
	; Search data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	byte ptr ds:[di].HMC_month, bl
	jna	exitLoop			; data <= bl
	loop	readLoop			; cx : counter
exitLoop:
	je	next				; find out
notFind:
	clrdw	axcx
	stc					; set carry
	jmp	done				; can't search target

next:
	mov	ax, word ptr ds:[di].HMC_date_low
	mov	cx, word ptr ds:[di].HMC_date_high
	clc					; reset carry

done:
	.leave
	ret
GetHolidayDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set holiday date in a month

CALLED BY:	SetHolidayDateYear
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
		bh	= number of a date
RETURN:		ds	= block may move
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If there is't its month date, create a new data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHolidayDate	proc	near
	uses	di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	appendCell

	; Search data
	;
	clr	dx
readLoop:
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	byte ptr ds:[di].HMC_month, bl
	je	setData				; data == bl
	jb	makeCell			; data < bl
	mov	dx, di				; save element
	loop	readLoop			; cx : counter
	jmp	insertCell

	; Create a new month data
	;
makeCell:
	tst	dx
	je	appendCell
insertCell:
	mov	di, dx				; set element
	clr	ax				; element size
	call	ChunkArrayInsertAt
	jmp	setData

appendCell:
	clr	ax				; element size
	call	ChunkArrayAppend
	; jmp	setData

setData:
	; Set a date
	;
	mov	byte ptr ds:[di].HMC_month, bl
	movdw	dxax, 1h			; set 1 bit
	clr	ch
	mov	cl, bh				; set counter
bitShift:
	shldw	dxax
	loop	bitShift
	or	word ptr ds:[di].HMC_date_low, ax
	or	word ptr ds:[di].HMC_date_high, dx

	.leave
	ret
SetHolidayDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete holiday date in a month

CALLED BY:	DeleteHolidayDateYear
PASS:		*ds:si	= ChunkArray
		bl	= number of a month
		bh	= number of a date
RETURN:		carry set = if can't search target
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If there is't holiday in the month, delete data cell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteHolidayDate	proc	near
	uses	di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	notFind

readLoop:
	; Search data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	cmp	byte ptr ds:[di].HMC_month, bl
	jna	exitLoop			; data <= bl
	mov	dx, di				; save element
	loop	readLoop			; cx : counter
exitLoop:
	je	next				; find out
	jmp	notFind

next:
	; Delete a date
	;
	movdw	dxax, 1h			; set 1 bit
	clr	ch
	mov	cl, bh				; set counter
bitShift:
	shldw	dxax
	loop	bitShift
	mov	bx, word ptr ds:[di].HMC_date_low
	mov	cx, word ptr ds:[di].HMC_date_high
						; dxax : a date to delete
						; cxbx : holidays
	test	ax, bx
	jnz	deleteDate
	test	dx, cx
	jz	notFind
deleteDate:
	xor	bx, ax
	xor	cx, dx				; delete a date
	mov	word ptr ds:[di].HMC_date_low, bx
	mov	word ptr ds:[di].HMC_date_high, cx
	tstdw	cxbx				; if null holiday
	; clc					; reset carry
	jnz	done				;  then delete data cell

	; Delete a data cell
	;
	call	ChunkArrayDelete
	clc					; reset carry
	jmp	done

	; Not find out data
	;
notFind:
	stc					; set carry

done:
	.leave
	ret
DeleteHolidayDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMonthDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set month and date to a ChunkArray

CALLED BY:	SetYearMonthDate
		SetHReadData ( SetHolidayInteractionClass )
PASS:		ds 	= if MemHandle == 0 then *ds:cx month array
		es 	= dgroup segment
		bx	= MemHandle
		cx	= ChunkHandle for ChunkArray
RETURN:		carry set = end of file or read error
		ds 	= block may move
DESTROYED:	ds	= if MemHandle != 0
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetMonthDate	proc	near
	uses	bx, ax, si, cx, dx, di
	.enter

	; MemLock
	;
	tst	bx			; bx : MemHandle
	je	next0			; if bx == 0 then pass MemLock
	call	MemLock
	mov	ds, ax			; segment pointer for the heap
next0:
	push	bx			; save bx
	mov	si, cx			; set ChunkHandle

mainLoop:
	clr	ax			; clear EOF flag

	; Read a month data
	;
	push	ds			; save ds
	segmov	ds, es			; set dgroup
	call	ReadMonthData		; bx : number of month
	pop	ds			; restore ds
	jnb	next1			; not end of file
	mov	ax, 1h			; set EOF flag
	jmp	exitLoop
next1:
	tst	bx			; if bx == 0
	je	exitLoop

	; Read a date data
	;
	push	ds			; save ds
	segmov	ds, es			; set dgroup
	call	ReadDateData		; cx - date low
					; dx - date high
	pop	ds			; restore ds
	jnb	next2			; not end of file
	mov	ax, 1h			; set EOF flag
next2:
	tstdw	dxcx			; if dxcx == 0
	je	mainLoop

	; Creat a new month cell
	;
	push	ax			; save EOF flag
					; *ds:si array
	clr	ax			; no need ?
	call	ChunkArrayAppend	; ds:di new element
	mov	byte ptr ds:[di].HMC_month, bl
	mov	word ptr ds:[di].HMC_date_low, cx
	mov	word ptr ds:[di].HMC_date_high, dx
	pop	ax			; restore EOF flag

	; Check end of file
	;
	tst	ax			; if ax != 0
	jne	exitLoop

	jmp	mainLoop
exitLoop:

	; MemUnLock
	;
	pop	bx			; restore bx
	tst	bx			; bx : MemHandle
	je	next3			; if bx == 0 then pass MemUnLock
	call	MemUnlock
next3:

	; Set / Reset carry
	;
	tst	ax			; if ax == 0
	je	done			; CF cleared
	stc				; set carry

done:
	.leave
	ret
SetMonthDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetYearMonthDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set year, month and date to a ChunkArray

CALLED BY:	SetHReadData ( SetHolidayInteractionClass )
PASS:		ds 	= dgroup
		ax	= ChunkHandle for ChunkArray
		bx	= MemHandle
RETURN:		carry set = end of file or read error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	10/5/93		Bug fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetYearMonthDate	proc	near
	uses	bx, ax, ds, si, cx, dx, di, es
	.enter

	segmov	es, ds				; save dgroup ds->es
	mov	si, ax				; set ChunkHandle

	; MemLock
	;
	call	MemLock				; bx : MemHandle
	mov	ds, ax				; segment pointer for the heap
	push	bx				; save MemHandle

mainLoop:
	; Read a year data
	;
	push	ds				; save ds
	segmov	ds, es				; set dgroup
	call	ReadYearData			; ax : number of year
	pop	ds				; restore ds
	jc	endFile				; end of file
	tst	ax				; if ax == 0
	je	exitLoop

	; Now create a new month array
	;
	push	ax				; save ax: number of year
	push	si				; save si: year chunck array
						; ds : bloack of new array
	mov	bx, size HolidayMonthCell	; element size
	clr	cx				; size for ChunkArrayHeader
	clr	si				; number of alloc ( one )
	clr	al				; ObjChunkFlags no needs ????
	call	ChunkArrayCreate		; *ds:si array
						; ( block possibly moved )

	; Now set a month and date
	;
	clr	bx				; reset handle
	mov	cx, si				; set a month chunk array
	pop	si				; restore si: year chunk array
	pop	ax				; restore ax: number of year
						; es : dgroup segment
	call	SetMonthDate
	pushf					; save flag

	; Creat a new year cell
	;
	mov	bx, ax				; save number of year
						; *ds:si array
	clr	ax				; no need ?
	call	ChunkArrayAppend		; ds:di new element
						; ( block possibly moved )
	mov	word ptr ds:[di].HYC_year, bx
	mov	word ptr ds:[di].HYC_chunk, cx

	popf					; restore flag
	jc	endFile				; end of file
	jmp	mainLoop

endFile:
	mov	ax, 1h				; set EOF flag
	jmp	memUnLock

exitLoop:
	clr	ax				; reset EOF flag
	; jmp	memUnLock

	; MemUnLock
	;
memUnLock:
	pop	bx				; restore MemHandle
	call	MemUnlock

	; Set / Reset carry
	;
	tst	ax				; if ax == 0
	je	done				; CF cleared
	stc					; set carry

done:
	.leave
	ret
SetYearMonthDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetYearMonthDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get year, month and date from a ChunkArray.
		Then write data to the holiday data file.

CALLED BY:	SetHWriteData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
		bx	= MemHandle
		ax	= ChunkHandle for ChunkArray
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetYearMonthDate	proc	near
	uses	es, ds, si, ax, bx, cx, dx, di
	.enter

	segmov	es, ds				; save dgroup ds->es
	mov	si, ax				; set ChunkHandle
	push	bx				; save bx

	; MemLock
	;
						; bx:MemHandle
	call	MemLock
	mov	ds, ax				; segment pointer for the heap

	; Get year arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	memUnLock

	; Year data
	;
	clr	ax				; clear counter
yearLoop:
						; *ds:si - array
	call	ChunkArrayElementToPtr
	mov	bx, word ptr ds:[di].HYC_year	; get year

	push	si, cx, ax			; save si, cx, ax
	mov	si, ds:[di].HYC_chunk		; get month chunk array
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	noElement

	push	ds, cx				; save ds, cx
	segmov	ds, es				; set dgroup
	lea	di, ds:[charData]		; ds:di - char data
	mov	ax, bx				; set year
	call	IntToAscii			; cx - char length
	mov	dx, di				; ds:dx - char data
	call	WriteSpaceData
	call	WriteSpaceData
	call	WriteWordData
	call	WriteReturnData
	pop	ds, cx				; restore ds, cx

	; Month data
	;  ds:si-array, cx-number, es-dgroup
	;
	clr	ax				; clear counter
monthLoop:
	push	cx				; save cx
						; *ds:si - array
	call	ChunkArrayElementToPtr

	mov	bl, byte ptr ds:[di].HMC_month		; get month
	mov	cx, word ptr ds:[di].HMC_date_low	; get date low
	mov	dx, word ptr ds:[di].HMC_date_high	; get date high

	push	ds				; asve ds
	segmov	ds, es				; set dgroup
	call	WriteTabData
	call	WriteMonthData
	call	WriteSpaceData
	call	WriteSpaceData
	call	WriteDateData
	call	WriteReturnData
	pop	ds				; restore ds
	pop	cx				; restore cx
	inc	ax
	cmp	ax, cx
	jb	monthLoop			; ax < cx
	;
	; End Month data

noElement:
	pop	si, cx, ax			; restore si, cx, ax
	inc	ax
	cmp	ax, cx
	jb	yearLoop			; ax < cx
	;
	; End Year data

	; MemUnLock
	;
memUnLock:
	pop	bx				; restore MemHandle
	call	MemUnlock

	.leave
	ret
GetYearMonthDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAllHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delte all year and month ChunckArray

CALLED BY:	SetHReset ( SetHolidayInteractionClass )
PASS:		*ds:si	= year ChunkArray
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteAllHolidayDateYear	proc	near
	uses	si, cx, ax, di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	done

yearLoop:
	; Delete month data
	;
	push	si				; save si
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	mov	si, ds:[di].HYC_chunk		; si : HYC_chunk
	call	DeleteAllHolidayDate		; delete month
	pop	si				; restore si
	loop	yearLoop			; cx : counter

	; Now delte year cell
	;
	clr	ax, cx
	dec	cx				; cx <- -1 delete all data
	call	ChunkArrayDeleteRange

done:
	.leave
	ret
DeleteAllHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAllHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete  all month ChunkArray

CALLED BY:	DeleteAllHolidayDateYear
		SetHReset ( SetHolidayInteractionClass )
PASS:		*ds:si	= month ChunkArray
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteAllHolidayDate	proc	near
	uses	ax, cx
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	done

	; Now delte month cell
	;
	clr	ax, cx
	dec	cx				; cx <- -1 delete all data
	call	ChunkArrayDeleteRange

done:
	.leave
	ret
DeleteAllHolidayDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error check all year and month ChunkArray

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
		SetHSaveData ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/6/93    	Initial version
	Tera	12/26/93	Bug fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHolidayDateYear	proc	near
	uses	si, cx, ax, di, bx
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	cmp	cx, 1h				; if cx < 1
	jb	good

	clr	bx				; clear year buffer

readLoop:
	; Dump year data
	;
	push	si				; save si
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	mov	ax, word ptr ds:[di].HYC_year	; ### ax : HYC_year ####
	mov	si, ds:[di].HYC_chunk		; ### si : HYC_chunk ###
	call	CheckHolidayDate
	pop	si				; restore si
	jc	errorMonth

	; Check year array
	;
	tst	bx
	jz	next				; pass at first time
	cmp	bx, ax
	jna	errorYear			; if bx <= ax then error
next:	mov	bx, ax				; save year

	loop	readLoop			; cx : counter
good:
	clc					; reset carry
	jmp	done

errorYear:
errorMonth:
	stc					; set carry
done:
	.leave
	ret
CheckHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error check all month array

CALLED BY:	CheckHolidayDateYear
		SetHLoadData ( SetHolidayInteractionClass )
		SetHSaveData ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHolidayDate	proc	near
	uses	ax, bx, cx, dx, di
	.enter

	clr	dh

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	cmp	cx, 1h				; if cx <= 1
	jna	good

	clr	bx				; clear month buffer

readLoop:
	; Dump month and date data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	mov	dl, byte ptr ds:[di].HMC_month	  ; ### dl : HMC_month ######

	; Check month array
	;
	tst	bx
	jz	next				; pass at first time
	cmp	bx, dx
	jna	errorMonth			; if bx <= dx then error
next:	mov	bx, dx				; save month

	loop	readLoop			; cx : counter
good:
	clc					; reset carry
	jmp	done

errorMonth:
	stc					; set carry
done:
	.leave
	ret
CheckHolidayDate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpHolidayDateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump holiday date in a month of a Year for debug

CALLED BY:	SetHDataDump ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DumpHolidayDateYear	proc	near
	uses	si, cx, ax, di
	.enter

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	done

readLoop:
	; Dump year data
	;
	push	si				; save si
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	mov	ax, word ptr ds:[di].HYC_year	; ### ax : HYC_year ####
	mov	si, ds:[di].HYC_chunk		; ### si : HYC_chunk ###
	call	DumpHolidayDate
	pop	si				; restore si
	loop	readLoop			; cx : counter

done:
	.leave
	ret
DumpHolidayDateYear	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpHolidayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump holiday date in a month for debug

CALLED BY:	DumpHolidayDateYear
		SetHDataDump ( SetHolidayInteractionClass )
PASS:		*ds:si	= ChunkArray
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DumpHolidayDate	proc	near
	uses	ax, bx, cx, dx, di
	.enter

	clr	dh

	; Get arrray count
	;
	call	ChunkArrayGetCount		; cx : number of elements
	tst	cx				; if cx == 0
	je	done

readLoop:
	; Dump month and date data
	;
						; *ds:si - array
	mov	ax, cx				; element number to find
	dec	ax				; fit for ZERO origin
	call	ChunkArrayElementToPtr
	mov	dl, byte ptr ds:[di].HMC_month	  ; ### dl : HMC_month ######
	mov	bx, word ptr ds:[di].HMC_date_low ; ### bx : HMC_date_low ###
	mov	ax, word ptr ds:[di].HMC_date_high; ### ax : HMC_date_high ##
	loop	readLoop			; cx : counter

done:
	.leave
	ret
DumpHolidayDate	endp


HolidayCode	ends

