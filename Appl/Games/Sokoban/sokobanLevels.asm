COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		sokobanLevels.asm

AUTHOR:		Eric Weber, Feb  4, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT LoadUserLevel		Read the contents of a level file into a
				map

    INT BuildLevelFilename	Turn the level number into a 3 digit
				decimal string and tack it onto the end of
				the standard filename

    INT ParseMap		Parse a level file's contents into a Map

    INT ParseRow		Parse one row of the input

    INT SaveUserLevel		Write a map to a DOS file

    INT SokobanMapToAscii	Convert a Map to its ASCII representation

    INT CreateLevelPath		Create the directory for levels

    INT SokobanLevelError	Put up an error dialog box with the level
				number as its argument.

    INT FillGrass		Force all reachable grass to become floor,
				and all unreachable floor to become grass.

    INT FillGrassLow		Recursive part of FillGrass

    INT ValidateCounts		Update various counters and ensure the
				level is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94   	Initial revision


DESCRIPTION:
	Code for managing user defined levels
		

	$Id: sokobanLevels.asm,v 1.1 97/04/04 15:13:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; the size of the file is the size of a map, with an extra CR+LF on each line
;
MAX_INPUT_SIZE = (MAX_COLUMNS + 2)*MAX_ROWS

;
; FillGrass has a maximum recursive depth of MAX_COLUMNS*MAX_ROWS+1,
; and requires 2 bytes/invocation of stack space.
;
FILLSTACK = (MAX_COLUMNS*MAX_ROWS+1)*2

idata segment

levelsVolume		StandardPath	SP_DOCUMENT
levelsPath		char		"\\Sokoban Levels",0
filenameBuffer		char		"level001.sok",0
levelNumber		char		"001",0

idata	ends
CommonCode	segment resource

;
; error handling macro
;
DoError		macro	name
		mov	si, offset name
		call	SokobanLevelError
		stc
endm

;
; the grass parser assumes it can twiddle the high bit of a
; SokobanSquareType freely
;
CheckHack < SokobanSquareType lt 128 >
VISITED		equ	128


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the contents of a level file into a map

CALLED BY:	
PASS:		es:di	- map to modify
		cx	- level number to load
RETURN:		carry	- set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	open the appropriate file
	read file contents into source buffer
	parse into rows and transfer to temporary buffer
	use ReadMapCommon to translate ASCII and fill in caller's map

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadUserLevel	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		targetPtr	local	fptr	push es,di
		sourceHandle	local	hptr
		temporaryHandle	local	hptr
		.enter
	;
	; goto the directory of user levels
	;
		call	FilePushDir
		GetResourceSegmentNS dgroup, ds
		mov	bx, ds:[levelsVolume]
		mov	dx, offset levelsPath
		call	FileSetCurrentPath
		LONG	jc setPathError
	;
	; try to open the file
	;
		call	BuildLevelFilename
		mov	ax, FILE_DENY_NONE or FILE_ACCESS_R
		mov	dx, offset filenameBuffer
		call	FileOpen		; ax = file handle
		LONG	jc	fileOpenError
		mov	bx,ax
	;
	; allocate a block to hold file data
	;
		push	bx
		mov	ax, MAX_INPUT_SIZE
		clr	cl
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemAlloc		; bx = mem hdl, ax = seg
		mov	ss:[sourceHandle], bx
		mov	ds,ax
		pop	bx
	;
	; read file into buffer then close the file
	; the only possible error is short read, which can be ignored
	;
		clr	dx			; ds:dx = buffer
		mov	ax, MAX_INPUT_SIZE	; bytes to read
		clr	al
		call	FileRead		; cx = bytes read
		mov	al, FILE_NO_ERRORS
		call	FileClose
		jcxz	noData
	;
	; allocate a block to hold the map struct
	;
		push	cx
		mov	ax, size Map
		clr	cl
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemAlloc		; bx = mem hdl, ax = seg
		mov	ss:[temporaryHandle], bx
		mov	es,ax
		clr	di			; es:di = temporary Map
		pop	cx
	;
	; tranform file data into an ASCII map
	;
		call	ParseMap
		jc	parseError
	;
	; transform ASCII map into real map
	;
		segmov	ds,es
		mov	si,di
		segmov	es,ss:[targetPtr].segment, di
		mov	di, ss:[targetPtr].offset
		call	ReadMapCommon
		clc
freeTemporary:
	;
	; free the temporary buffer
	;
		pushf
		mov	bx, ss:[temporaryHandle]
		call	MemFree
		popf
freeSource:
	;
	; free the source buffer
	;
		pushf
		mov	bx,ss:[sourceHandle]	; bx = mem hdl of buffer
		call	MemFree
		popf
done:
		call	FilePopDir
		.leave
		ret
	;
	; below this point are all the error conditions
	;
setPathError:
		DoError PathErrorMessage
		jmp	done
fileOpenError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		je	notFoundError
		DoError ReadErrorMessage
		jmp	done
notFoundError:
		DoError	NoLevelMessage
		jmp	done
noData:
		DoError InvalidLevelMessage
		jmp	freeSource
parseError:
		DoError InvalidLevelMessage
		jmp	freeTemporary
LoadUserLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildLevelFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn the level number into a 3 digit decimal string and
		tack it onto the end of the standard filename

CALLED BY:	LoadUserLevel
PASS:		ds	- dgroup
		cx	- level number
RETURN:		carry	- set on error
DESTROYED:	nothing
SIDE EFFECTS:	ds:[filenameBuffer] updated

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildLevelFilename	proc	near
		uses	ax,bx,cx
		.enter
	;
	; numbers over 999 are forbidden because they won't fit in a
	; DOS extension
	;
		cmp	cx, 999
		ja	illegalLevel
		jcxz	illegalLevel
	;
	; find the 1s
	;
		mov	ax, cx
		mov	bx, 10
		div	bl		; al = quotient, ah = remainder
		add	ah, C_ZERO
		mov	ds:[filenameBuffer][size filenameBuffer - 6], ah
		mov	ds:[levelNumber][2], ah
		clr	ah
	;
	; find the 10s
	;
		div	bl
		add	ah, C_ZERO
		mov	ds:[filenameBuffer][size filenameBuffer - 7], ah
		mov	ds:[levelNumber][1], ah
		clr	ah
	;
	; find the 100s
	;
		div	bl
		add	ah, C_ZERO
		mov	ds:[filenameBuffer][size filenameBuffer - 8], ah
		mov	ds:[levelNumber], ah
	;
	; no errors happened
	;
		clc
done:
		.leave
		ret
illegalLevel:
		stc
		jmp	done
BuildLevelFilename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a level file's contents into a Map

CALLED BY:	LoadUserLevel
PASS:		ds	- level file contents
		cx	- length of buffer
		es:di	- Map
RETURN:		carry	- set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	copy the input chars into a Map structure
	call ReadMapCommon to build the SST version and validate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseMap	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; initialize the map with grass
	;
		push	cx,di
		mov	cx, size Map
		mov	al, S_GRASS
		rep	stosb
		pop	cx,di
	;
	; parse rows until we run out of data
	;
		push	di
		clr	si
		add	di, offset M_data
		mov	bp,1
		clr	ax
	;
	; es:di = next row to fill
	; bp    = index of row
	; ax    = max row size
	;
doRow:
		cmp	bp, MAX_ROWS		; too many rows?
		ja	excessRows
		call	ParseRow
		jc	parseError
		cmp	dx, MAX_COLUMNS		; too many columns?
		ja	longRow
		cmp	dx,ax			; longest row?
		jbe	shortRow
		mov	ax,dx			; new longest row found
shortRow:
		inc	bp			; advance row count
		add	di, MAX_COLUMNS		; advance row pointer
		tst	cx			; more bytes to read?
		jnz	doRow			; if yes, loop
		pop	di			; otherwise, restore ptr
	;
	; use size of longest row for column count
	;
		mov	es:[di].MH_columns, al	; al = size of longest row
		dec	bp			; remove loop slop
		mov	ax,bp
		mov	es:[di].MH_rows, al	; al = number of rows
		clc
done:
		.leave
		ret
	;
	; something went wrong during parsing - bail out
	; 
longRow:
excessRows:
parseError:
		pop	di
		stc
		jmp	done
ParseMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse one row of the input

CALLED BY:	ParseMap
PASS:		ds:si	- data to parse
		cx	- size of data
		es:di	- next row of map
RETURN:		dx 	- size of row (excluding CR+LF)
		cx	- decremented by bytes consumed (dx + 2)
		si	- incremented by bytes consumed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseRow	proc	near
		uses	ax,bx,di
		.enter
		push	cx		; remember input size
		push	es,di		; remember map row
	;
	; find carriage return
	;
		segmov	es,ds
		mov	di,si		; es:di = buffer
		mov	al, C_CR	; search for CR
		repne	scasb		; es:di = C_CR+1 if zero set
		jne	noCR
		cmp	{byte} es:[di], C_LF	; next char should be LF
		jne	noCR
		dec	di		; es:di = C_CR
		sub	di,si		; di = length of row
	;
	; copy line to map
	;
		mov	cx,di		; cx = length of row
		pop	es,di		; es:di = map row
		push	cx		; remember length
		rep	movsb		; copy data, ds:si = C_CR
	;
	; adjust counts
	;
		pop	dx		; dx = size of row
		pop	cx		; cx = size of input
		sub	cx,dx		; account for row size
		dec	cx		; account for CR
		dec	cx		; account for LF
		inc	si		; skip CR
		inc	si		; skip LF
		clc
done:
		.leave
		ret
noCR:
		pop	es,di
		pop	cx
		stc
		jmp	done
ParseRow	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanFindEmptyLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of first unused level

CALLED BY:	SokobanCreateLevel
PASS:		nothing
RETURN:		cx = level number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanFindEmptyLevel	proc	near
		uses	ax,bx,dx,si,di,bp,ds
		.enter
	;
	; set level to 1
	;
		mov	cx,1
	;
	; goto the directory of user levels
	; if it doesn't exist, return level 1
	;
		call	FilePushDir
		GetResourceSegmentNS dgroup, ds
		mov	bx, ds:[levelsVolume]
		mov	dx, offset levelsPath
		call	FileSetCurrentPath
		jc	searchDone
	;
	; reset level to zero since it is incremented at top of loop
	;
		clr	cx
		jmp	searchLoop
	;
	; try next level
	;
closeContinue:
		mov	bx,ax
		call	FileClose
searchLoop:
		cmp	cx, 999
		je	searchDone		; use 999 if nothing else works
		inc	cx
	;
	; build filename for this level and try to open it
	;
		call	BuildLevelFilename
		mov	ax, FILE_DENY_NONE or FILE_ACCESS_R
		mov	dx, offset filenameBuffer
		call	FileOpen		; ax = file handle
	;
	; if it's there, keep searching
	;
		jnc	closeContinue
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	searchLoop
searchDone:
		call	FilePopDir
		.leave
		ret
		
SokobanFindEmptyLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a map to a DOS file

CALLED BY:	EditContentSaveLevel
PASS:		ds:si	- Map to write
		cx	- level number
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	updates grass and ground in the passed map

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveUserLevel	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		call	FilePushDir
	;
	; verify various counts
	;
		call	ValidateCounts
		jc	done
	;
	; attempt to normalize the ground and grass
	;
		call	FillGrass
		jc	fillError
	;
	; goto the directory of user levels
	;
		push	ds
		GetResourceSegmentNS dgroup, ds
		mov	bx, ds:[levelsVolume]
		mov	dx, offset levelsPath
		call	FileSetCurrentPath
		jc	setPathError
pathOK:
	;
	; try to open the file
	;

		call	BuildLevelFilename
		mov	dx, offset filenameBuffer

		mov	ax, (FILE_DENY_RW or FILE_ACCESS_W) or \
			    ((mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8)
		clr	cx			; no attributes
		call	FileCreate		; ax = file handle
		jc	fileCreateError
		mov	bx,ax			; bx = file handle
	;
	; create a temporary block to hold the char version
	; of the map
	;
		push	bx
		mov	ax, MAX_INPUT_SIZE
		mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8
		call	MemAlloc		; bx = mem hdl, ax = seg
		mov	bp, bx
		mov	es,ax
		pop	bx
	;
	; convert map to ASCII and write it out
	;
		pop	ds			; ds:si = source map
		call	SokobanMapToAscii	; cx = size of output
		segmov	ds, es
		mov	dx, di			; ds:dx = buffer
		mov	al, FILE_NO_ERRORS
		call	FileWrite
	;
	; close the file and free temporary block
	;
		mov	al, FILE_NO_ERRORS
		call	FileClose
		mov	bx, bp
		call	MemFree
		clc
done:
		call	FilePopDir
		.leave
		ret
	;
	; ERROR CONDITIONS
	;
fillError:
		DoError UnboundedErrorMessage
		jmp	done
setPathError:
		cmp	ax, ERROR_PATH_NOT_FOUND
		je	createPath
		DoError PathErrorMessage
		pop	ax		; discard junk on stack
		jmp	done
createPath:
		call	CreateLevelPath
		jnc	pathOK
		DoError	CreateErrorMessage
		pop	ax		; discard junk on stack
		jmp	done
fileCreateError:
		DoError	WriteErrorMessage
		pop	ax		; discard junk on stack
		jmp	done
SaveUserLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanMapToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a Map to its ASCII representation

CALLED BY:	SaveUserLevel
PASS:		ds:si	- Map
		es:di	- buffer of at least MAX_INPUT_SIZE bytes
RETURN:		cx	- number of bytes written to es:di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanMapToAscii	proc	near
		uses	ax,bx,dx,dx,bp,si
		.enter
		push	di
	;
	; convert source map to ASCII form and discard unused bytes
	;
		mov	bx, offset cs:[convertString]	; xlat table
		mov	cl, ds:[si].MH_columns		; column loop counter
		clr	ch
		mov	bp,cx				; used to restore cx
		mov	ah, ds:[si].MH_rows		; row loop counter
		add	si, offset M_data		; ds:si = source data
		clr	di				; es:di = buffer
		mov	dx, MAX_COLUMNS
		sub	dx, cx				; dx = unused bytes/row
	;
	; copy one row
	;
top:
		lodsb			; read SokobanSquareType
		xlat	cs:[bx]		; convert to ASCII
		stosb			; write to temporary buffer
		loop	top		; next column
	;
	; write EOL and go to next row
	;
		mov	al, C_CR
		stosb
		mov	al, C_LF
		stosb
		add	si,dx		; skip unused bytes in map row
		mov	cx,bp		; reset column counter
		dec	ah		; next row
		jnz	top
	;
	; determine count
	;
		mov	cx,di		; es:cx = 1 past end of buffer
		pop	di		; es:di = start of buffer
		sub	cx,di		; cx    = size of buffer
		
		.leave
		ret
		
\
convertString		char		SOKOBAN_SQUARE_TYPE_CHARS

SokobanMapToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLevelPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the directory for levels

CALLED BY:	SaveUserLevel
PASS:		ds	- dgroup
RETURN:		carry	- set if error
DESTROYED:	nothing
SIDE EFFECTS:	changes current path to new directory

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rootPath	char	"\\",0

CreateLevelPath	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; switch to root of volume
	;
		push	ds
		mov	bx, ds:[levelsVolume]
		segmov	ds,cs
		mov	dx, offset cs:[rootPath]
		call	FileSetCurrentPath
		pop	ds
		jc	done
	;
	; create the path
	;
		mov	dx, offset ds:[levelsPath]
		call	FileCreateDir
		jc	done
	;
	; swith to new directory
	;
		call	FileSetCurrentPath
done:
		.leave
		ret
CreateLevelPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanLevelError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an error dialog box with the level number as
		its argument.
CALLED BY:	UTILITY
PASS:		si	- chunk of error message (in SokobanStrings)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanLevelError	proc	near
		uses	ax,bx,cx,si,di,bp,ds
		.enter
	;
	; get the segments set up
	;
		mov	bx, handle SokobanStrings
		call	MemLock
		mov	ds,ax
		mov	di, ds:[si]			; ax:di = err string
		GetResourceSegmentNS dgroup, ds
		mov	cx,ds
		mov	si, offset levelNumber	; cx:si = filename
	;
	; skip leading zeros
	;
		cmp	{char}ds:[si], C_ZERO
		jne	alloc
		inc	si
		cmp	{char}ds:[si], C_ZERO
		jne	alloc
		inc	si
	;
	; allocate the parameters
	;
alloc:
		sub	sp, size StandardDialogParams
		mov	bp,sp
		mov	ss:[bp].SDP_customFlags,
			CustomDialogBoxFlags <0,CDT_ERROR,GIT_NOTIFICATION,0>
		movdw	ss:[bp].SDP_customString, axdi
		movdw	ss:[bp].SDP_stringArg1, cxsi
		clrdw	ss:[bp].SDP_stringArg2
		clrdw	ss:[bp].SDP_customTriggers
		clrdw	ss:[bp].SDP_helpContext
	;
	; put up the dialog
	;
		call	UserStandardDialog
	;
	; release the strings
	;
		call	MemUnlock
		.leave
		ret
SokobanLevelError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillGrass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force all reachable grass to become floor, and all
		unreachable floor to become grass.
CALLED BY:	
PASS:		ds:si	- Map to update
RETURN:		carry	- set if map not closed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	recursively scan map
	update all map elements

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillGrass	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; get position of player
	;
		mov	cx, ds:[si].MH_position.P_x
		mov	dx, ds:[si].MH_position.P_y
		movdw	bxax, cxdx
		call	ConvertArrayCoordinates		; bx <- offset
		mov	bp,si
		add	si,bx				; ds:si = player
		add	si, offset M_data
	;
	; get bounds
	;
		clr	ah
		mov	al, ds:[bp].MH_rows
		clr	bh
		mov	bl, ds:[bp].MH_columns
	;
	; do the actual computation, borrowing stack if needed
	;
recurse::
		mov	di, FILLSTACK
		call	ThreadBorrowStackSpace		; di = token
		call	FillGrassLow
		call	ThreadReturnStackSpace		; preserves flags
		jc	open
	;
	; setup to scan map
	;
		mov	si,bp				; ds:si = map header
		add	si, offset M_data		; ds:si = map data
		mov	di,si
		segmov	es,ds				; es:di = map data
		mov	cx, MAX_ROWS*MAX_COLUMNS	; size of data
	;
	; update the grass/ground status of each square, and clear all
	; the visited bits
	;
top:
		lodsb				; al = ds:si++
		cmp	al, SST_GROUND		; unvisited ground?
		jne	notGround
		mov	al, SST_GRASS
		jmp	notGrass
notGround:
		cmp	al, SST_GRASS or VISITED
		jne	notGrass
		mov	al, SST_GROUND
notGrass:
		andnf	al, not VISITED
		stosb
		loop	top			; es:di++ = al
		clc
done::
		.leave
		ret
	;
	; the map is not properly enclosed
	; start by cleaning up the visited bits
	;
open:
		mov	si, bp
		add	si, offset M_data
		mov	cx, MAX_ROWS*MAX_COLUMNS
clean:
		andnf	ds:[si], not VISITED
		inc	si
		loop	clean
		stc
		jmp	done
		
FillGrass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillGrassLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recursive part of FillGrass

CALLED BY:	FillGrass
PASS:		ax	- number of rows
		bx	- number of columns
		cx,dx	- x,y coordinate of square to update
		ds:[si]	- address of square to update
RETURN:		if level properly bounded:
			carry clear
		if level not properly bounded;
			carry set
			cx,dx,si destroyed

SIDE EFFECTS:	
	uses up to FILLSTACK bytes of stack space

PSEUDO CODE/STRATEGY:
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillGrassLow	proc	near
	;
	; check bounds
	;
		tst	cx
		js	error
		tst	dx
		js	error
		cmp	cx, bx
		jae	error
		cmp	dx, ax
		jae	error
	;
	; if we've already been here, no need to continue
	;
		test	ds:[si], VISITED
		jnz	done
	;
	; if its a wall, again no need to continue
	;
		cmp	{byte} ds:[si], SST_WALL_NSEW
		jbe	done
	;
	; mark the square
	;
		ornf	ds:[si], VISITED
	;
	; visit the neighbors in order (W, E, N, S)
	;
		dec	si
		dec	cx				; (x-1, y)
		call	FillGrassLow
		jc	abort
		
		inc	si
		inc	si
		inc	cx
		inc	cx				; (x+1, y)
		call	FillGrassLow
		jc	abort

		sub	si, MAX_COLUMNS+1
		dec	cx
		dec	dx				; (x, y-1)
		call	FillGrassLow
		jc	abort

		add	si, 2*MAX_COLUMNS
		inc	dx
		inc	dx				; (x, y+1)
		call	FillGrassLow
		jc	abort

		sub	si, MAX_COLUMNS
		dec	dx
done:
		clc
abort:
		ret
error:
		stc
		jmp	abort
FillGrassLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update various counters and ensure the level is valid

CALLED BY:	SaveUserLevel
PASS:		ds:si - map to search
RETURN:		carry - set on error
DESTROYED:	nothing
SIDE EFFECTS:	changes MH_position, MH_packets, MH_saved

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateCounts	proc	near
		uses	ax, bx, cx, bp, si
		.enter
	;
	; set up pointers
	;
		mov	bp,si				; ds:bp = header
		add	si, offset M_data		; ds:si = data
		mov	cx, size MapArray		; cx = size of data
	;
	; initialize header
	;
		movdw	ds:[bp].MH_position, -1
		clr	ds:[bp].MH_packets
		clr	ds:[bp].MH_saved
		clr	dx				; dx = # of safe spots
top:
	;
	; search for PLAYER or SAFE_PLAYER
	;
		lodsb
		cmp	al, SST_PLAYER
		je	found_player
		cmp	al, SST_SAFE_PLAYER
		jne	not_player
found_player:
		cmpdw	ds:[bp].MH_position, -1
		jne	multiplayer
	;
	; convert si to x,y coordinates
	;
		push	ax
		mov	bx, si		
		dec	bx			; ds:[bx] = player
		sub	bx,bp			; bx = offset from map
		sub	bx, offset M_data	; bx = offset from data
		mov	ax,bx
		mov	bl, MAX_ROWS
		div	bl			; al = row, ah = column
		mov	bl,ah
		clr	ah			; ax = row
		clr	bh			; bx = column
		mov	ds:[bp].MH_position.P_x, bx
		mov	ds:[bp].MH_position.P_y, ax
		pop	ax
not_player:
	;
	; check for SST_BAG
	;
		cmp	al, SST_BAG
		jne	not_bag
		inc	ds:[bp].MH_packets	; one more bag
not_bag:
	;
	; check for SST_SAFE
	;
		cmp	al, SST_SAFE
		jne	not_safe
		inc	dx			; one more safe spot
not_safe:
	;
	; check for SST_SAFE_PLAYER
	;
		cmp	al, SST_SAFE_PLAYER
		jne	not_safe_player
		inc	dx			; one more safe spot
not_safe_player:
	;
	; check for SST_SAFE_BAG
	;
		cmp	al, SST_SAFE_BAG
		jne	not_safe_bag
		inc	dx			; one more safe spot
		inc	ds:[bp].MH_packets	; also one more bag
		inc	ds:[bp].MH_saved	; and one more saved bag
not_safe_bag:
		loop	top
	;
	; check for no player
	;
		cmpdw	ds:[bp].MH_position, -1
		mov	si, offset NoPlayerErrorMessage
		je	error
	;
	; check for more safe spots then bags
	;
		cmp	dl, ds:[bp].MH_packets
		mov	si, offset TooFewBagsErrorMessage
		ja	error
	;
	; check for more bags then safe spots
	;
		mov	si, offset TooManyBagsErrorMessage
		jb	error
	;
	; check for zero bags and zero safe spots
	;
		tst	dx
		mov	si, offset ZeroBagsErrorMessage
		jz	error
	;
	; no errors
	;
		clc
done:
		.leave
		ret
multiplayer:
		mov	si, offset MultiplePlayerErrorMessage
error:
		call	SokobanLevelError
		stc
		jmp	done
ValidateCounts	endp

CommonCode	ends


