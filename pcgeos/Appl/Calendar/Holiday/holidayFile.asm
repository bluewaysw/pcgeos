COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS J
MODULE:		JCalendar/Holiday
FILE:		holidayFile.asm

AUTHOR:		TORU TERAUCHI, JUL 28, 1993

ROUTINES:
	NAME			DESCRIPTION
	----			-----------
  Basic Utility :
	AsciiToInt		Change data from Ascii to Positive number
	IntToAscii		Change data from Positive number to Ascii char
	GotoHolidayDataDir	Change to the holiday directory
	DataFileOpen		Open a data file
	DataFileClose		Close a data file
	ReadWordData		Read one word data from text file
	WriteWordData		Write one word data to text file
	WriteSpaceData		Write one word ' 'to text file
	WriteTabData		Write one word TAB to text file
	WriteReturnData		Write RETRUN code to text file
	ErasePreviousData	Erase previous data

	DataTestError		Error function for debug

  Specific Utility :
	ReadKeyCodeData		Read key code data data
	WriteKeyCodeData	Write key code data data
	ReadYearData		Read year data
	ReadDateData		Read date data
	WriteDateData		Write date data
	ReadMonthData		Read month data
	WriteMonthData		Write month data
	ReadWeekData		Read week data
	WriteWeekData		Write week data
	SkipNatinalHoliday	Skip natinal holiday data area

	
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Tera	6/16/93		Initial revision
	Tera	7/25/93		add many routines


DESCRIPTION:
	Read / write holiday data from file.
		

	$Id: holidayFile.asm,v 1.1 97/04/04 14:49:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HolidayCode	segment	resource


;
;================= Basic Utility ==============================================
;
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AsciiToInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change data from Ascii to Positive number

CALLED BY:	ReadYearData
		ReadDateData
PASS:		ds	= dgroup
		cl	= char length
		di	= offset char data
RETURN:		ax 	= int
		error 	= carry set
				not number or over flow
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		max 16bit number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AsciiToInt	proc	near
	uses	bx, dx, di, cx, bx
	.enter
	clr	bh
	clr	ch
	clr	ax

	; Check char length
	;
	cmp	cl, 0h
	jna	charError			; length <= 0
	cmp	cl, 5h
	ja	charError			; length > 5

mainLoop:
	; Change char to int (1)
	;
	mov	dx, 000ah			; dx = 10
	mul	dx				; dx:ax = ax * dx
	cmp	dh, 0h
	jne	charError			; over flow

	mov	bl, ds:[di]			; copy one char
		
	; Check char
	;
	cmp	bl, DFF_ZERO
	jb	charError			; char < DFF_ZERO
	cmp	bl, DFF_9
	ja	charError			; char > DFF_9

	; Change char to int (2)
	;
	sub	bl, DFF_ZERO
	add	ax, bx
	jb	charError			; over flow

	inc	di				; next char
	loop	mainLoop			; loop cl times

	clc					; reset carry
	jmp	done

charError:
	stc					; set carry

done:
	.leave	
	ret
AsciiToInt	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change data from Positive number to Ascii char

CALLED BY:	WriteDateData
		GetYearMonthDate
PASS:		ds	= dgroup
		ax	= int
		di	= offset char data
RETURN:		cx	= char length
		ds:[di]	= ascii char
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		max 16bit number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IntToAscii	proc	near
	uses	ax, bx, dx, di
	.enter

	clr	dx
	clr	cx
	mov	bx, 000ah			; bx = 10

mainLoop:
	div	bx				; ax..dx = dx:ax / bx
	push	dx				; save dx
	inc	cx
	tst	ax				; check end
	je	exit
	clr	dx
	jmp	mainLoop
exit:
	; Int to Ascii
	;
	mov	ax, cx				; save length cx->ax
changeLoop:
	pop	dx
	add	dx, DFF_ZERO
	mov	ds:[di], dx			; save one char
	inc	di				; set next char
	loop	changeLoop

	mov	cx, ax				; restore length ax->cx

	.leave	
	ret
IntToAscii	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoHolidayDataDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the directory that contains the holiday data files.

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
		SetHSaveData ( SetHolidayInteractionClass )
PASS:		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/26/93    	Initial version
	Tera	9/24/93    	DBCS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString programDirName <"HOLIDAY",0>	; MS-DOS directry name

GotoHolidayDataDir	proc	near
	uses	ax, bx, dx, ds
	.enter

	mov	ax, SP_USER_DATA
	call	FileSetStandardPath
	segmov	ds, cs
	clr	bx
	mov	dx, offset programDirName
	call	FileSetCurrentPath
	jnc	done
	call	FileCreateDir
EC <	ERROR_C	-1				; can't create directry	>
	call	FileSetCurrentPath
done:
	.leave
	ret
GotoHolidayDataDir	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataFileOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a data file

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
		SetHSaveData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:		carry set if it can not open file.
		ax	= ZERO     if it creates a new file.
			  NON ZERO other
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If there is not the file, it makes a new file.
	If it can open file, it sets the file handle to ds:[fileHandle].
	If it can not open file, it clears ds:[fileHandle].

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString fileName <"holiday.dat",0>	; MS-DOS file name

DataFileOpen	proc	near
	uses	dx, cx, bx, es, ds
	.enter

	segmov	es, ds				; save ds->es
	clr	ds:[fileHandle]			; clear file handle buffer

	; Open File
	;
	mov	al, FILE_ACCESS_RW or FILE_DENY_RW
	segmov	ds, cs
	mov	dx, offset fileName		; set file name
	call	FileOpen
	jb	createNewfile			; can't open file
	jmp	openFile

	; Create a New File
	;
createNewfile:
	mov	ah, FILE_CREATE_ONLY or mask FCF_NATIVE
	mov	al, FILE_ACCESS_RW or FILE_DENY_RW
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate			; dx:fileName
	jb	createError			; can't create file

	segmov	ds, es				; ds <- dgroup
	mov	ds:[fileHandle], ax		; save PC/GEOS file handle
	mov	bx, 1
	call	WriteKeyCodeData
	mov	bx, 2
	call	WriteKeyCodeData
	mov	bx, 3
	call	WriteKeyCodeData
	mov	bx, 4
	call	WriteKeyCodeData
	clr	ax				; clear ax
	clc					; reset carry
	jmp	done

createError:
	stc					; set carry
	jmp	done

openFile:
	segmov	ds, es				; ds <- dgroup
	mov	ds:[fileHandle], ax		; save PC/GEOS file handle
	clc					; reset carry

done:
	.leave
	ret
DataFileOpen	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataFileClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a data file

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
		SetHSaveData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DataFileClose	proc	near
	uses	ax, bx
	.enter

	; Check handle
	;
	tst	ds:[fileHandle]		; check handle
	jz	done			; not opened

	; Close File
	;
	mov	al, FILE_NO_ERRORS	; set flags
	mov	bx, ds:[fileHandle]	; load PC/GEOS file handle
	call	FileClose
EC <	ERROR_C	-1			; can't close file		>
	clr	ds:[fileHandle]		; clear file handle buffer

done:
	.leave
	ret
DataFileClose	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadWordData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read one word data from text file

CALLED BY:	ReadKeyCodeData
		ReadYearData
		ReadDateData
		ReadMonthData
		ReadWeekData
		SkipNatinalHoliday
PASS:		ds	= dgroup
RETURN:		carry set	= end of file or error  
				  error - over charData max length
				        - can't read data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	To check correct word
			DFF_SZ < dummyData < DFF_ZERO

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadWordData	proc	near
	uses	bx, ax, cx, dx, di, si
	.enter

	; Clear charData, charDataNum
	;
	clr	ds:[charDataNum]

	mov	cx, size charData
	clr	al
	lea	di, ds:[charData]
	rep	stosb				; repeat cx times

	; Read 1 char
	;
	mov	al, FILE_NO_ERRORS		; set flags
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	mov	cx, 1h				; number of bytes to rad
	lea	dx, ds:[dummyData]		; set buffer from which to read
loop0:	
	call	FileRead
	jc	fileReadError			; read error

	cmp	ds:[dummyData], DFF_COMMENT	; check comment
	je	readEndOfLine

	cmp	ds:[dummyData], DFF_ZERO	; check char
	jb	loop0				; dummyData < DFF_ZERO
	cmp	ds:[dummyData], DFF_SZ
	ja	loop0				; dummyData > DFF_SZ

	; Get a word
	;
	mov	dl, ds:[dummyData]		; copy first char
	mov	ds:[charData], dl
	lea	dx, ds:[charData]		; set buffer from which to read
lp01:
	inc	dx				; set next buffer

	inc	ds:[charDataNum]
	cmp	ds:[charDataNum], size charData	; check word size
	jae	charNumberError

	call	FileRead
	jc	fileReadError			; can't read data

	mov	si, dx
	cmp	byte ptr ds:[si], DFF_ZERO	; check char
	jb	lp011				; dummyData < DFF_ZERO
	cmp	byte ptr ds:[si], DFF_SZ
	ja	lp011				; dummyData > DFF_SZ
	jmp	lp01

	; End of a word
	;
lp011:
	; Prevent FileRead Error based on the half of EOF code.
	;
	call	FileRead
	mov	dx, 1h
	clr	cx
	mov	al, FILE_POS_RELATIVE		; FilePosMoe
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	negdw	cxdx
	call	FilePos				; rewind 1 byte

	mov	byte ptr ds:[si], 0h		; clear last char
	clc					; reset carry
	jmp	done

	; Read end of line
	;
readEndOfLine:
loop1:
	call	FileRead
	jc	fileReadError			; can't read data
	cmp	ds:[dummyData], DFF_RETURN1	; check return flag
	jne	lp11
	call	FileRead
	jc	fileReadError			; can't read data
	cmp	ds:[dummyData], DFF_RETURN2	; check return flag
	je	loop0
lp11:
	jmp	loop1


	; Check end of file
	;
fileReadError:
	cmp	ax, ERROR_SHORT_READ_WRITE	; check end of file
EC<	ERROR_NZ -1				; not end of file	>
	stc					; set carry
	jmp	done

	; Error
	;
charNumberError:
EC<	ERROR_C	-1				; over max char length	>
	stc					; set carr
	jmp	done

done:
	.leave
	ret
ReadWordData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteWordData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one word data to text file

CALLED BY:	WriteKeyCodeData
		WriteDateData
		WriteMonthData
		WriteWeekData
		GetYearMonthDate
PASS:		ds	= dgroup
		cx	= number of bytes to write
		ds:dx	= buffer from which to write
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteWordData	proc	near
	uses	ax, bx
	.enter

	; Write word data
	;
	mov	al, FILE_NO_ERRORS		; set flags
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	call	FileWrite
EC<	ERROR_C	-1				; can't write data	>

	.leave
	ret
WriteWordData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSpaceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one word ' 'to text file

CALLED BY:	WriteDateData
		WriteWeekData
		GetYearMonthDate
PASS:		ds	= dgroup
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/28/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteSpaceData	proc	near
	uses	ax, bx, cx, dx
	.enter

	; Write word data
	;
	mov	al, FILE_NO_ERRORS		; set flags
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	mov	cx, 1h				; number of bytes to write
	mov	ds:[dummyData], DFF_SPACE	; set data
	lea	dx, ds:[dummyData]		; set buffer
	call	FileWrite
EC<	ERROR_C	-1				; can't write data	>

	.leave
	ret
WriteSpaceData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTabData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one word TAB to text file

CALLED BY:	WriteWeekData
		GetYearMonthDate
PASS:		ds	= dgroup
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/28/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteTabData	proc	near
	uses	ax, bx, cx, dx
	.enter

	; Write word data
	;
	mov	al, FILE_NO_ERRORS		; set flags
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	mov	cx, 1h				; number of bytes to write
	mov	ds:[dummyData], DFF_TAB		; set data
	lea	dx, ds:[dummyData]		; set buffer
	call	FileWrite
EC<	ERROR_C	-1				; can't write data	>

	.leave
	ret
WriteTabData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteReturnData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write RETRUN code to text file

CALLED BY:	WriteKeyCodeData
		WriteWeekData
		GetYearMonthDate
PASS:		ds	= dgroup
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		EC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteReturnData	proc	near
	uses	ax, bx, cx, dx
	.enter

	; Write word data
	;
	mov	al, FILE_NO_ERRORS		; set flags
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	mov	cx, 2h				; number of bytes to write
	mov	ds:[dummyData], DFF_RETURN1	; set Return Code data
	mov	ds:[dummyData]+1, DFF_RETURN2
	lea	dx, ds:[dummyData]		; set buffer
	call	FileWrite
EC<	ERROR_C	-1				; can't write data	>

	.leave
	ret
WriteReturnData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErasePreviousData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase previous data

CALLED BY:	SetHWriteData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/28/93		Bug fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ErasePreviousData	proc	near
	uses	ax, bx, cx, dx
	.enter

	; Get the current file position
	;
	mov	al, FILE_POS_RELATIVE		; FilePosMoe
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	clrdw	cxdx				; set offset to zero
	call	FilePos				; dx:ax <- current position
	push	dx, ax				; save current position (dx:ax)

	; Set the file position to the end of the file
	;
	mov	al, FILE_POS_END		; FilePosMoe
						; bx : file handle
	clrdw	cxdx				; set offset to zero
	call	FilePos				; dx:ax <- new file position
	mov	cx, dx
	mov	bx, ax				; move end position to cx:bx

	; Check file position
	;
	pop	dx, ax				; restore current position
	cmpdw	cxbx, dxax
	je	done				; end == current position

	; Count the byte to reset
	;
	subdw	cxbx, dxax			; end - current position
	jc	done				; end < current position
	mov	dx, bx
	push	cx, dx				; save count (cx:dx)

	; Reset the file position to the current position
	;
	mov	al, FILE_POS_RELATIVE		; FilePosMoe
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	negdw	cxdx
	call	FilePos
	pop	cx, dx				; restore count (cx:dx)
	
	; Write Space
	;
	subdw	cxdx, 2h			; 2h : end of file code size??
	mov	al, FILE_NO_ERRORS		; set flags
	mov	ds:[dummyData], DFF_SPACE	; set dummy data
writeLoop:
	cmpdw	cxdx, 0h			; chech count <= 0
	jng	done
	decdw	cxdx				; dec count
	push	cx, dx				; save count
	mov	cx, 1h				; number of bytes to write
	lea	dx, ds:[dummyData]		; set buffer
	call	FileWrite
	pop	cx, dx				; restore count
	jc	done				; can't write data
	jmp	writeLoop

done:
	.leave
	ret
ErasePreviousData	endp


;
;================= Specific Utility ===========================================
;
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadKeyCodeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read key code data data

CALLED BY:	SetHReadData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:		bx	= 0 : file end or read error
			  1 : National Holiday
			  2 : Repeat Holiday
			  3 : Personal Holiday
			  4 : Personal Weekday
			  5 : not key code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		Error check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadKeyCodeData	proc	near
	uses	ax, di, cx, si, es
	.enter

	mov	ax, offset charData	; *ds:ax - charData
	segmov	es, ds			; cmpsb use es
	clr	bx

;mainLoop:
	; Read one word data
	;
	call	ReadWordData
	jc	done			; end of file or error


	; Check the word
	;
	mov	di, ax			; set charData
	mov	cx, size HF_nation
	mov	si, offset HF_nation
lp1:	cmpsb				; cmp 'nation'
	jne	endlp1
	loop	lp1
	mov	bx, 1h			; set data
	jmp	done
endlp1:

	mov	di, ax			; set charData
	mov	cx, size HF_repeat
	mov	si, offset HF_repeat
lp2:	cmpsb				; cmp 'repeat'
	jne	endlp2
	loop	lp2
	mov	bx, 2h			; set data
	jmp	done
endlp2:

	mov	di, ax			; set charData
	mov	cx, size HF_holiday
	mov	si, offset HF_holiday
lp3:	cmpsb				; cmp 'holiday'
	jne	endlp3
	loop	lp3
	mov	bx, 3h			; set data
	jmp	done
endlp3:

	mov	di, ax			; set charData
	mov	cx, size HF_weekday
	mov	si, offset HF_weekday
lp4:	cmpsb				; cmp 'weekday'
	jne	endlp4
	loop	lp4
	mov	bx, 4h			; set data
	jmp	done
endlp4:

	; Not key code data
	;
	mov	bx, 5h			; set data
;	jmp	mainLoop

done:
	.leave
	ret
ReadKeyCodeData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteKeyCodeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write key code data data

CALLED BY:	DataFileOpen
		SetHWriteData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
		bx	= 0 : -
			  1 : National Holiday
			  2 : Repeat Holiday
			  3 : Personal Holiday
			  4 : Personal Weekday
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteKeyCodeData	proc	near
	uses	cx, dx
	.enter

	cmp	bx, 1
	jne	next2
	mov	cx, size HF_nation
	lea	dx, ds:[HF_nation]
	jmp	write
next2:
	cmp	bx, 2
	jne	next3
	mov	cx, size HF_repeat
	lea	dx, ds:[HF_repeat]
	jmp	write
next3:
	cmp	bx, 3
	jne	next4
	mov	cx, size HF_holiday
	lea	dx, ds:[HF_holiday]
	jmp	write
next4:
	cmp	bx, 4
	jne	next5
	mov	cx, size HF_weekday
	lea	dx, ds:[HF_weekday]
	jmp	write
next5:
	jmp	done			; other
write:
	call	WriteWordData
	call	WriteReturnData
done:
	.leave
	ret
WriteKeyCodeData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadYearData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read year data

CALLED BY:	SetYearMonthDate
PASS:		ds	= dgroup
RETURN:		ax	= number of a year
			     0 : not year
		carry set = end of file or read error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadYearData	proc	near
	uses	di, bx, cx, dx
	.enter


	; Read one word data
	;
	call	ReadWordData
	jc	readError		; end of file or error

	; Check the word length
	;
	mov	cx, ds:[charDataNum]	; set char length
	cmp	cx, 4h			; year char length == 4
	jne	notYear

	; Change year char to int
	;
					; cx : char length
	lea	di, ds:[charData]	; set char data address
	call	AsciiToInt		; ax : int data
	jb	notYear			; not number
	cmp	ax, 1900		; year >= 1900
	jb	notYear
	; jmp	findYear

	; Find year data
	;
;findYear:
	clc				; reset carry
	jmp	done

	; File read error
	;
readError:
	clr	ax			; clear ax
	stc				; set carry
	jmp	done

	; Not year number
	;
notYear:
	; Reset a file's read position
	;
	mov	al, FILE_POS_RELATIVE	; FilePosMoe
	mov	bx, ds:[fileHandle]	; load PC/GEOS file handle
	clr	cx
	mov	dx, ds:[charDataNum]	; cx:dx offset
	incdw	cxdx
	negdw	cxdx
	call	FilePos			; set a file's read position

	clr	ax			; clear ax
	clc				; reset carry
	; jmp	done

done:
	.leave
	ret
ReadYearData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadDateData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read date data

CALLED BY:	SetMonthDate
PASS:		ds	= dgroup
RETURN:		cx	= date low
		dx	= date high
		carry set = end of file or read error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadDateData	proc	near
	uses	di, ax, bx
	.enter

	lea	di, ds:[charData]	; set char data address
	clrdw	dxcx

mainLoop:
	push	cx			; save cx

	; Read one word data
	;
	call	ReadWordData
	jb	readError		; end of file or error

	; Check the word length
	;
	mov	cx, ds:[charDataNum]	; set char length
	cmp	cx, 2h			; date char <= 2 length
	ja	notDate

	; Change date char to int
	;
					; cx : char length
					; di : char data address
	call	AsciiToInt		; ax : int data
	jb	notDate			; not number
	cmp	ax, 31			; date <= 31
	ja	notDate

	; Make date mask
	;
	mov	cx, ax			; set counter
	movdw	bxax, 1h		; set 1 bit
bitShift:
	shldw	bxax
	loop	bitShift
	pop	cx			; restore cx
					; bxax : mask data
	or	dx, bx			; dxcx : total data
	or	cx, ax

	jmp	mainLoop		; next date


	; File read error
	;
readError:
	pop	cx			; restore cx
	stc				; set carry
	jmp	done

	; Not date number
	;
notDate:
	push	dx			; save dx

	; Reset a file's read position
	;
	mov	al, FILE_POS_RELATIVE	; FilePosMoe
	mov	bx, ds:[fileHandle]	; load PC/GEOS file handle
	clr	cx
	mov	dx, ds:[charDataNum]	; cx:dx offset
	incdw	cxdx
	negdw	cxdx
	call	FilePos			; set a file's read position

	pop	cx, dx			; restore cx, dx
	clc				; reset carry
	; jmp	done

done:
	.leave
	ret
ReadDateData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDateData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write date data

CALLED BY:	GetYearMonthDate
PASS:		ds	= dgroup
		cx	= date low
		dx	= date high
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteDateData	proc	near
	uses	di, ax, bx, cx, dx
	.enter

	lea	di, ds:[charData]	; set char data address
	mov	bx, cx			; mov date low -> bx
	clr	ax			; clear date

	shrdw	dxbx
	mov	cx, 31			; set counter
bitShift:
	inc	ax
	shrdw	dxbx
	jnb	next

	; Write date
	;
	push	cx, dx			; save cx, dx
					; ds:di - char data
					; ax - int
	call	IntToAscii		; cx - char length
	mov	dx, di			; ds:dx - char data
	call	WriteWordData
	call	WriteSpaceData
	pop	cx, dx			; restore cx, dx

next:	loop	bitShift

	.leave
	ret
WriteDateData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadMonthData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read month data

CALLED BY:	SetMonthDate
PASS:		ds	= dgroup
RETURN:		bx	= number for a munth
			     0 : not month data
		carry set = end of file or read error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadMonthData	proc	near
	uses	di, cx, si, ax, cx, dx, es
	.enter

	mov	ax, offset charData
	segmov	es, ds			; cmpsb use es

	; Read one word data
	;
	call	ReadWordData
	jb	readError		; end of file or error

	; Check the word length
	;
	mov	cx, ds:[charDataNum]	; set char length
	cmp	cx, 3h			; month char length == 3
	jne	notMonth

	; Check the word
	;
	mov	di, ax			; set charData
	mov	cx, size HF_january
	mov	si, offset HF_january
lp1:	cmpsb				; cmp 'january'
	jne	endlp1
	loop	lp1
	mov	bx, 1h			; set data
	jmp	findMonth
endlp1:

	mov	di, ax			; set charData
	mov	cx, size HF_february
	mov	si, offset HF_february
lp2:	cmpsb				; cmp 'february'
	jne	endlp2
	loop	lp2
	mov	bx, 2h			; set data
	jmp	findMonth
endlp2:

	mov	di, ax			; set charData
	mov	cx, size HF_march
	mov	si, offset HF_march
lp3:	cmpsb				; cmp 'march'
	jne	endlp3
	loop	lp3
	mov	bx, 3h			; set data
	jmp	findMonth
endlp3:

	mov	di, ax			; set charData
	mov	cx, size HF_april
	mov	si, offset HF_april
lp4:	cmpsb				; cmp 'HF_april'
	jne	endlp4
	loop	lp4
	mov	bx, 4h			; set data
	jmp	findMonth
endlp4:

	mov	di, ax			; set charData
	mov	cx, size HF_may
	mov	si, offset HF_may
lp5:	cmpsb				; cmp 'may'
	jne	endlp5
	loop	lp5
	mov	bx, 5h			; set data
	jmp	findMonth
endlp5:

	mov	di, ax			; set charData
	mov	cx, size HF_june
	mov	si, offset HF_june
lp6:	cmpsb				; cmp 'june'
	jne	endlp6
	loop	lp6
	mov	bx, 6h			; set data
	jmp	findMonth
endlp6:

	mov	di, ax			; set charData
	mov	cx, size HF_july
	mov	si, offset HF_july
lp7:	cmpsb				; cmp 'july'
	jne	endlp7
	loop	lp7
	mov	bx, 7h			; set data
	jmp	findMonth
endlp7:

	mov	di, ax			; set charData
	mov	cx, size HF_august
	mov	si, offset HF_august
lp8:	cmpsb				; cmp 'august'
	jne	endlp8
	loop	lp8
	mov	bx, 8h			; set data
	jmp	findMonth
endlp8:

	mov	di, ax			; set charData
	mov	cx, size HF_september
	mov	si, offset HF_september
lp9:	cmpsb				; cmp 'september'
	jne	endlp9
	loop	lp9
	mov	bx, 9h			; set data
	jmp	findMonth
endlp9:

	mov	di, ax			; set charData
	mov	cx, size HF_october
	mov	si, offset HF_october
lp10:	cmpsb				; cmp 'october'
	jne	endlp10
	loop	lp10
	mov	bx, 10			; set data
	jmp	findMonth
endlp10:

	mov	di, ax			; set charData
	mov	cx, size HF_november
	mov	si, offset HF_november
lp11:	cmpsb				; cmp 'november'
	jne	endlp11
	loop	lp11
	mov	bx, 11			; set data
	jmp	findMonth
endlp11:

	mov	di, ax			; set charData
	mov	cx, size HF_december
	mov	si, offset HF_december
lp12:	cmpsb				; cmp 'december'
	jne	endlp12
	loop	lp12
	mov	bx, 12			; set data
	jmp	findMonth
endlp12:
	; jmp	notMonth

	; Not january - december
	;
notMonth:

	; Reset a file's read position
	;
	mov	al, FILE_POS_RELATIVE	; FilePosMoe
	mov	bx, ds:[fileHandle]	; load PC/GEOS file handle
	clr	cx
	mov	dx, ds:[charDataNum]	; cx:dx offset
	incdw	cxdx
	negdw	cxdx
	call	FilePos			; set a file's read position

	clr	bx			; clear data
	clc				; reset carry
	jmp	done

	; Read file error
	;
readError:
	clr	bx			; clear data
	stc				; set carry
	jmp	done

	; Find month
	;
findMonth:
	clc				; reset carry	
	;jmp	done	

done:
	.leave
	ret
ReadMonthData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMonthData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write month data

CALLED BY:	GetYearMonthDate
PASS:		ds	= dgroup
		bl	= number of a month ( 1-12 )
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteMonthData	proc	near
	uses	cx, dx
	.enter

	cmp	bl, 1
	jne	next2
	mov	cx, size HF_january
	lea	dx, ds:[HF_january]
	jmp	write
next2:
	cmp	bl, 2
	jne	next3
	mov	cx, size HF_february
	lea	dx, ds:[HF_february]
	jmp	write
next3:
	cmp	bl, 3
	jne	next4
	mov	cx, size HF_march
	lea	dx, ds:[HF_march]
	jmp	write
next4:
	cmp	bl, 4
	jne	next5
	mov	cx, size HF_april
	lea	dx, ds:[HF_april]
	jmp	write
next5:
	cmp	bl, 5
	jne	next6
	mov	cx, size HF_may
	lea	dx, ds:[HF_may]
	jmp	write
next6:
	cmp	bl, 6
	jne	next7
	mov	cx, size HF_june
	lea	dx, ds:[HF_june]
	jmp	write
next7:
	cmp	bl, 7
	jne	next8
	mov	cx, size HF_july
	lea	dx, ds:[HF_july]
	jmp	write
next8:
	cmp	bl, 8
	jne	next9
	mov	cx, size HF_august
	lea	dx, ds:[HF_august]
	jmp	write
next9:
	cmp	bl, 9
	jne	next10
	mov	cx, size HF_september
	lea	dx, ds:[HF_september]
	jmp	write
next10:
	cmp	bl, 10
	jne	next11
	mov	cx, size HF_october
	lea	dx, ds:[HF_october]
	jmp	write
next11:
	cmp	bl, 11
	jne	next12
	mov	cx, size HF_november
	lea	dx, ds:[HF_november]
	jmp	write
next12:
	cmp	bl, 12
	jne	next13
	mov	cx, size HF_december
	lea	dx, ds:[HF_december]
	jmp	write
next13:
	jmp	done			; Not january - december

write:
	call	WriteWordData
done:
	.leave
	ret
WriteMonthData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadWeekData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read week data

CALLED BY:	SetHReadData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:		bx	= week bit mask
		carry set = end of file or read error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadWeekData	proc	near
	uses	ax, cx, dx, si, di, es
	.enter

	mov	ax, offset charData
	segmov	es, ds			; cmpsb use es
	clr	bx

mainLoop:
	; Read one word data
	;
	call	ReadWordData
	jb	readError		; end of file or error

	; Check the word
	;
	mov	di, ax			; set charData
	mov	cx, size HF_sunday
	mov	si, offset HF_sunday
lp1:	cmpsb				; cmp 'sunday'
	jne	endlp1
	loop	lp1
	or	bx, RHF_SUNDAY		; set sunday
	jmp	mainLoop
endlp1:

	mov	di, ax			; set charData
	mov	cx, size HF_monday
	mov	si, offset HF_monday
lp2:	cmpsb				; cmp 'monday'
	jne	endlp2
	loop	lp2
	or	bx, RHF_MONDAY		; set monday
	jmp	mainLoop
endlp2:

	mov	di, ax			; set charData
	mov	cx, size HF_tuesday
	mov	si, offset HF_tuesday
lp3:	cmpsb				; cmp 'tuesday'
	jne	endlp3
	loop	lp3
	or	bx, RHF_TUESDAY		; set tuesday
	jmp	mainLoop
endlp3:

	mov	di, ax			; set charData
	mov	cx, size HF_wednesday
	mov	si, offset HF_wednesday
lp4:	cmpsb				; cmp 'wednesday'
	jne	endlp4
	loop	lp4
	or	bx, RHF_WEDNESDAY	; set wednesday
	jmp	mainLoop
endlp4:

	mov	di, ax			; set charData
	mov	cx, size HF_thursday
	mov	si, offset HF_thursday
lp5:	cmpsb				; cmp 'thursday'
	jne	endlp5
	loop	lp5
	or	bx, RHF_THURSDAY	; set thursday
	jmp	mainLoop
endlp5:

	mov	di, ax			; set charData
	mov	cx, size HF_friday
	mov	si, offset HF_friday
lp6:	cmpsb				; cmp 'friday'
	jne	endlp6
	loop	lp6
	or	bx, RHF_FRIDAY		; set friday
	jmp	mainLoop
endlp6:

	mov	di, ax			; set charData
	mov	cx, size HF_saturday
	mov	si, offset HF_saturday
lp7:	cmpsb				; cmp 'saturday'
	jne	endlp7
	loop	lp7
	or	bx, RHF_SATURDAY	; set saturday
	jmp	mainLoop
endlp7:

	; Not sunday - saturday
	;
	push	bx			; save bx

	; Reset a file's read position
	;
	mov	al, FILE_POS_RELATIVE	; FilePosMoe
	mov	bx, ds:[fileHandle]	; load PC/GEOS file handle
	clr	cx
	mov	dx, ds:[charDataNum]	; cx:dx offset
	incdw	cxdx
	negdw	cxdx
	call	FilePos			; set a file's read position

	pop	bx			; restor bx
	clc				; reset carry
	jmp	done

	; Read file data
	;
readError:
	stc				; set carry
	jmp	done

done:
	.leave
	ret
ReadWeekData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteWeekData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write week data

CALLED BY:	SetHWriteData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
		bx	= holiday data
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/28/93

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteWeekData	proc	near
	uses	cx, dx
	.enter

	call	WriteTabData

	test	bx, RHF_SUNDAY
	jz	next1
	mov	cx, size HF_sunday	; number of bytes to write
	lea	dx, ds:[HF_sunday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next1:
	test	bx, RHF_MONDAY
	jz	next2
	mov	cx, size HF_monday	; number of bytes to write
	lea	dx, ds:[HF_monday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next2:
	test	bx, RHF_TUESDAY
	jz	next3
	mov	cx, size HF_tuesday	; number of bytes to write
	lea	dx, ds:[HF_tuesday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next3:
	test	bx, RHF_WEDNESDAY
	jz	next4
	mov	cx, size HF_wednesday	; number of bytes to write
	lea	dx, ds:[HF_wednesday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next4:
	test	bx, RHF_THURSDAY
	jz	next5
	mov	cx, size HF_thursday	; number of bytes to write
	lea	dx, ds:[HF_thursday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next5:
	test	bx, RHF_FRIDAY
	jz	next6
	mov	cx, size HF_friday	; number of bytes to write
	lea	dx, ds:[HF_friday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next6:
	test	bx, RHF_SATURDAY
	jz	next7
	mov	cx, size HF_saturday	; number of bytes to write
	lea	dx, ds:[HF_saturday]	; set buffer from which to write
	call	WriteWordData
	call	WriteSpaceData
next7:
	call	WriteReturnData

	.leave
	ret
WriteWeekData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipNatinalHoliday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip natinal holiday data area of file

CALLED BY:	SetHWriteData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
RETURN:		carry set = if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/28/93		Error check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SkipNatinalHoliday	proc	near
	uses	es, di, si, ax, bx, cx, dx
	.enter

	clr	bx				; clear flag
	segmov	es, ds				; cmpsb use es
	mov	ax, offset charData

	; Read one word data till end of National Holiday section.
	; National holiday section must be the top of the data file.
	;
	; Read the first one word data
	;
	call	ReadWordData
	jc	fileError			; end of file or error

	; Check the word with 'nation' key code
	;
	mov	di, ax				; set charData
	mov	cx, size HF_nation
	mov	si, offset HF_nation
lp1:	cmpsb					; cmp 'nation'
	jne	fileError			; key code error
	loop	lp1

	; Now read data till the other key code.
	;
mainLoop:
	; Read one word data
	;
	call	ReadWordData
	jc	fileError			; end of file or error

	mov	di, ax				; set charData
	mov	cx, size HF_repeat
	mov	si, offset HF_repeat
lp2:	cmpsb					; cmp 'repeat'
	jne	endlp2
	loop	lp2
	jmp	anotherFlag
endlp2:

	mov	di, ax				; set charData
	mov	cx, size HF_holiday
	mov	si, offset HF_holiday
lp3:	cmpsb					; cmp 'holiday'
	jne	endlp3
	loop	lp3
	jmp	anotherFlag
endlp3:

	mov	di, ax				; set charData
	mov	cx, size HF_weekday
lp4:	mov	si, offset HF_weekday
	cmpsb					; cmp 'weekday'
	jne	endlp4
	loop	lp4
	jmp	anotherFlag
endlp4:
	jmp	mainLoop

anotherFlag:
	; Another key code
	;
	; Reset a file's write position
	;
	mov	al, FILE_POS_RELATIVE		; FilePosMoe
	mov	bx, ds:[fileHandle]		; load PC/GEOS file handle
	clrdw	cxdx
	mov	dx, ds:[charDataNum]		; cx:dx offset
	inc	dx
	not	cx
	neg	dx
	call	FilePos				; set a file's write position

	clc					; reset carry
	jmp	done

	; File format error
	;
fileError:
	stc					; set carry

done:
	.leave
	ret
SkipNatinalHoliday	endp


HolidayCode	ends
