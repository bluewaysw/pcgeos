COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader
FILE:		ini.asm

ROUTINES:
	Name			Description
	----			-----------
	OpenIniFiles		Open geos.ini file, find any geos.ini path
   	GetNumberOfHandles	Get number of handles from .ini file(s)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:

	$Id: ini.asm,v 1.1 97/04/04 17:26:52 newdeal Exp $

------------------------------------------------------------------------------@

MAX_INI_KEY_SIZE	=	40

ifidn	HARDWARE_TYPE, <PC>
  NEED_INITFILE_READ_INTEGER	equ	1
else
    ifndef	NO_SPLASH_SCREEN
      NEED_INITFILE_READ_INTEGER	equ	1
    endif
endif

if HARD_CODED_PATH
 ; Don't use the EC macro because it strips away backslashes
 if ERROR_CHECK
   ecInitFileName	char	INI_PATH,"\\GEOSEC.INI", 0
 endif

 initFileName		char	INI_PATH,"\\GEOS.INI", 0

else
EC <ecInitFileName	char	"geosec.ini", 0				>
initFileName		char	"geos.ini", 0
endif

pathsCategoryString	char	"paths", 0

iniString		char	"ini", 0
			char	MAX_INI_KEY_SIZE-4 dup (?)

initFileBufPos	fptr

catStrAddr	dword
keyStrAddr	dword
catStrLen	word
keyStrLen	word


PC <handlesString		char	"handles", 0			>

nextIniFile	word	(offset loaderVars.KLV_initFileBufHan)

if 0	;DISABLED BECAUSE THIS WILL NOT HELP US... EDS 11/14/92
MAX_DOS_PATH_SIZE	equ	66
specialIniFilePathAndName	char	MAX_DOS_PATH_SIZE+10+1 dup (?)
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	OpenIniFiles

DESCRIPTION:	Open geos.ini file, find any geos.ini path and load other
		.ini files

CALLED BY:	LoadGeos

PASS:
	ds, es - loader segment

RETURN:
	KLV_initFileBufHan - segments of the .ini file(s)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

OpenIniFiles	proc	near


if 0	;DISABLED BECAUSE THIS WILL NOT HELP US... EDS 11/14/92
	;first see if there is a "INIPATH" environment variable. If so,
	;then open the GEOS.INI file in that directory as the primary ini file.

	call	LocateIniUsingPathFromEnvVar
	jc	tryCWD				;skip if cannot find...

	clr	di				;don't close the file
	mov	dx, offset specialIniFilePathAndName
	call	OpenIniFileAndRead
	jnc	fileFound			;skip if found & opened it...

tryCWD:	;No dice. See if GEOSEC.INI or GEOS.INI exist in the current directory.
endif

	clr	di				;don't close the file
EC <	mov	dx, offset cs:[ecInitFileName]				>
EC <	call	OpenIniFileAndRead					>
EC <	jnc	fileFound			;skip if found & opened it... >

	mov	dx, offset cs:[initFileName]
	call	OpenIniFileAndRead
	ERROR_C	LS_INIT_FILE_CANNOT_OPEN_FILE

fileFound::
	mov	ds:[loaderVars].KLV_initFileHan, bx
	mov	ds:[loaderVars].KLV_initFileSize, si
	
	; get the drive on which the ini file was found and save it for
	; the kernel.

	mov	ah, MSDOS_GET_DEFAULT_DRIVE
	int	21h
	mov	ds:[loaderVars].KLV_initFileDrive, al

	;if a /Pxxx argument was passed on the command line to LOADER.EXE,
	;then update our "iniString" variable so that we will search for "xxx"
	;rather than "ini" in the first GEOS.INI file, to find the next file.

	call	GetIniKey

	;Now search the primary GEOS.INI file for the path of the second.

	mov	bx, offset loaderVars.KLV_initFileBufHan
	call	SearchForIniPath
	ret
OpenIniFiles	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetIniKey

DESCRIPTION:	Get the real .ini key (in case /pXXX was passed)

CALLED BY:	OpenIniFiles

PASS:
	ds, es - loader segment

RETURN:
	iniString - possibly modified

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/ 2/92	Initial version

------------------------------------------------------------------------------@
GetIniKey	proc	near	uses ds, es
	.enter

	mov	es, ds:[loaderVars].KLV_pspSegment
	mov	dx, es:[PSP_endAllocBlk]	; end heap at end of
	mov	di, offset PSP_cmdTail
	mov	cl, es:[di]
	clr	ch				; length of command tail -> cx
	jcxz	done				; if no tail, do nothing
	inc	di				; point past count
	dec	cx				; don't count CR at end
	jcxz	done

	; Now scan for any arguments

	mov	al, '/'				; switch delimiter -> al
next:
	repne	scasb				; scan for delimiter
	jnz	done				; if none, found, we're done
	cmp	{byte} es:[di], 'p'
	je	foundIni
	cmp	{byte} es:[di], 'P'
	jne	next

	; We found the ini switch. Read the value passed

foundIni:
	inc	di				;point past "p"
	segxchg	ds, es
	mov	si, di				; ds:si = source
	lea	di, iniString+3			; es:di = dest
copyLoop:
	lodsb
	stosb
	tst	al
	jz	copyEnd
	cmp	al, ' '
	jnz	copyLoop
copyEnd:
	mov	{char} es:[di-1], 0

done:
	.leave
	ret

GetIniKey	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SearchForIniPath

DESCRIPTION:	Search an opened .ini file for an .ini file path

CALLED BY:	OpenIniFiles, SearchForIniPath

PASS:
	ds - loader segment
	bx - offset to ini file to search
	nextIniFile - offset to put next ini file buffer segment

RETURN:
	ds, es - same

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

INI_PATH_BUFFER_SIZE	=	150

SearchForIniPath	proc	near
	uses ds, es
	.enter

	;search this .INI file for "ini=" statement which points to the
	;next .ini file...

	sub	sp, INI_PATH_BUFFER_SIZE	;set up stack frame
	mov	di, sp
	segmov	es, ss				;es:di = buffer

        LoaderDS
	mov	si, offset cs:[pathsCategoryString]

	mov	cx, cs				;cx:dx = key string
	mov	dx, offset cs:[iniString]

	mov	ax, 1				;search only one file
	mov	bp, INI_PATH_BUFFER_SIZE
	call	LoaderInitFileReadString	;scan the file whose memory
						;handle is cs:[bx]
	jc	done

	;Found another path for .ini. Loop to try each component

	segmov	ds, es				;ds = buffer

pathLoop:
	;ds:di = path string

	cmp	cs:[nextIniFile], (offset loaderVars.KLV_initFileBufHan)+ \
						((size word)*MAX_INI_FILES)
	jz	done				;skip if already have too
						;many .INI files...

	;scan to end of path component, by searching for NULL or SPACE.

	mov	si, di

findEndLoop:
	lodsb
	tst	al
	jz	gotEnd

	cmp	al, ' '
	jnz	findEndLoop

gotEnd:
	dec	si				;ds:si  = end
	push	ds:[si]
	mov	{char} ds:[si], 0		;null terminate

	;try to open the file at ds:di

	mov	dx, di
	push	si
	mov	di, 1			;don't keep file open
	push	cs:[nextIniFile]	;save the offset which will later be
					;used to save the handle of this .ini
					;file, because OpenIniFileAndRead will
					;bump it.
	call	OpenIniFileAndRead
	pop	bx			;bx = offset into KLV_initFileBufHan
	jc	noSearch

	;search this .ini file (get handle from cs:[bx], which points into
	;KLV_initFileBufHan.

	call	SearchForIniPath

noSearch:
	pop	si

	pop	ds:[si]
	cmp	{char} ds:[si], 0
	jz	done

	mov	di, si
	inc	di
	jmp	pathLoop

done:
	add	sp, INI_PATH_BUFFER_SIZE

	.leave
	ret

SearchForIniPath	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	OpenIniFileAndRead

DESCRIPTION:	Open the given .ini file and read it into a buffer

CALLED BY:	INTERNAL (InitGeos)

PASS:
	ds, es - loader segment
	ds:dx - filename
	di - non-zero to close file (and to open read-only)
	di - if di is zero:
		try to open read-write.  if access denied,
		open read-only.  don't close file.
	     if di is non-zero:
		open read-only.  close file.
	nextIniFile - offset to store handle when heap is init'ed

RETURN:
	carry - set if error
	ax - segment of buffer containing .ini file
	bx - file handle (if file still open).
	     If the .ini file was opened read-only, then the .ini file
	     is closed, and returns bx=0.
	si - size of .ini file
	nextIniFile - upped by 2

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

OpenIniFileAndRead	proc	near
	uses cx, dx, ds
	.enter

	;-----------------------------------------------------------------------
	;open the init file
	;figure whether to use sharing modes, so ini file can actually be
	;copied under systems that enforce such things.

tryAgain:	
	mov	ah, MSDOS_GET_VERSION
	int	21h			; al <- major; trashes bx&cx
	cmp	al, 2
	mov	ax, (MSDOS_OPEN_FILE shl 8) or FA_READ_ONLY ; assume 2.x
	jbe	figureReadWrite
	mov	ax, (MSDOS_OPEN_FILE shl 8) or \
			FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
figureReadWrite:
	
	clr	bx				;unset read-write mode flag

	tst	di
	jnz	doOpen

	inc	bx				;set read-write mode flag
		CheckHack <FA_READ_ONLY eq 0>
	ornf	ax, FA_READ_WRITE

doOpen:
	int	21h
	
	jnc 	openOK

	;
	; if open file failed because of ERROR_ACCESS_DENIED, that is
	; because the .ini file is read-only, but we tried opening it
	; in read-write mode.  Try again in read-only mode.  If it fails
	; again, then give up.
	;

	cmp	ax, ERROR_ACCESS_DENIED
	jne	openFail

	tst	bx				;try again only if first
	
	;
	; bx = 0: we tried opening in r/o mode
	; bx = 1: tried r/w mode
	;
	jz	openFail			;time was read-write

	mov	di, -1				;make read-only	
	jmp	tryAgain

openFail:
	stc
	jmp	done
	
openOK:	
	mov_trash	bx, ax			; bx = file

	;-----------------------------------------------------------------------
	; get file size and allocate space

	mov	al, FILE_POS_END
	mov	ah, MSDOS_POS_FILE
	clr	cx
	clr	dx
	int	21h				;dx:ax = file size
	ERROR_C	LS_INIT_FILE_CANNOT_READ_FILE
	tst	dx				;if (size > MAX_INI_SIZE)
	ERROR_NZ	LS_INIT_FILE_TOO_LARGE	; then error
	cmp	ax, MAX_INI_SIZE-1
	ERROR_A	LS_INIT_FILE_TOO_LARGE
	inc	ax
	push	ax				;save size
	push	bx
	mov	bx, cs:[nextIniFile]
        push    ds
        LoaderDS
	add	ds:[nextIniFile], 2
        pop     ds
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
	inc	ax				; in case we need to add final
	inc	ax				;  CR-LF...
	call	LoaderSimpleAlloc		;ax = segment
	pop	bx
	mov	ds, ax

	;-----------------------------------------------------------------------
	;read init file into buffer

	mov	al, FILE_POS_START		;seek to start of file
	mov	ah, MSDOS_POS_FILE
	clr	cx
	clr	dx
	int	21h				;dx:ax = file size
	pop	cx				;cx = size
	ERROR_C	LS_INIT_FILE_CANNOT_READ_FILE

	mov	ah, MSDOS_READ_FILE
	clr	dx
	int	21h				;ax = size
	ERROR_C	LS_INIT_FILE_CANNOT_READ_FILE

	mov_trash	si, ax			;si = size
	;
	; Make sure the thing ends in a CR-LF, as things in the kernel get
	; hosed if there's not one there. Since this is the only interface
	; between user-made changes and the more-orderly alterations
	; performed by the kernel, this seems to me the best place to make
	; the modifications -- ardeb 5/27/92
	; 
	cmp	si, 2
	jb	addCRLF				; => can't possibly end in CR-LF
	cmp	{word}ds:[si-2], '\r' or ('\n' shl 8)
	je	storeEOF
addCRLF:
	mov	{word}ds:[si], '\r' or ('\n' shl 8)
	inc	si
	inc	si
storeEOF:
	mov	{byte} ds:[si], MSDOS_TEXT_FILE_EOF
	inc	si

	;-----------------------------------------------------------------------
	;close the init file

	tst	di
	jz	noClose
	mov	ah, MSDOS_CLOSE_FILE
	int	21h
	ERROR_C	LS_INIT_FILE_CANNOT_READ_FILE
	clr	bx				;return bx=0 if .ini is r/o.
noClose:
	mov	ax, ds				;return segment
	clc
done:
	.leave
	ret

OpenIniFileAndRead	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetNumberOfHandles

DESCRIPTION:	Find the number of handles from the .ini file

CALLED BY:	INTERNAL (InitGeos)

PASS:
	ds, es - loader segment
	KLV_initFileBufHan - segments of .ini files loaded

RETURN:
	KLV_handleFreeCount - number of handles to allocate

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@
ifdef	NEED_INITFILE_READ_INTEGER
systemCategoryString	char	"system", 0
endif

ifidn	HARDWARE_TYPE, <PC>

GetNumberOfHandles	proc	near

	mov	si, offset cs:[systemCategoryString]
	mov	cx, cs
	mov	dx, offset cs:[handlesString]
	call	LoaderInitFileReadInteger
	jnc	found
	mov	ax, DEFAULT_NUMBER_OF_HANDLES
found:		
	mov	ds:[loaderVars].KLV_handleFreeCount, ax
	ret
GetNumberOfHandles	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoaderInitFileReadInteger

DESCRIPTION:	Locates the given key in the geos.ini file
		and returns the binary value of the ASCII body.

CALLED BY:	GetNumberOfHandles

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

RETURN:		carry clear if successful
		     ax - value
		else carry set

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@
ifdef	NEED_INITFILE_READ_INTEGER
LoaderInitFileReadInteger	proc	near	uses bx, dx, es
	.enter

	mov	bx, offset loaderVars.KLV_initFileBufHan
	mov	ax, MAX_INI_FILES
	call	StoreParamsAndFindKey
	jc	exit

	call	AsciiToHex	;dx,al <- func(es)
	clc
	mov	ax, dx
exit:
	.leave
	ret
LoaderInitFileReadInteger	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	StoreParamsAndFindKey

DESCRIPTION:	Call StoreParams, then find the given category and key in
		any .ini file along the path.

CALLED BY:	InitFileGet, ...

PASS:
	ax - max number of .ini files to search
	bx - offset to first ini file to search
	ds:si - category ASCIIZ string
	cx:dx - key ASCIIZ string

RETURN:
	carry - set if error (category or key not found)
	all parameters stored away in variables
	es - dgroup
	if no error:
		[initFileBufPos] - offset from BufAddr to body

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@


StoreParamsAndFindKey	proc	near	uses ax, bx
	.enter

	call	StoreParams		;locks first .ini file

	mov	cx, ax			;cx = count

searchLoop:
	mov	ax, cs:[bx]
        push    ds
        LoaderDS
	mov	ds:[initFileBufPos].segment, ax
	mov	ds:[initFileBufPos].offset, 0
        pop     ds
	call	FindCategory
	jc	notFound

	call	FindKey
	jnc	done

notFound:
	;category or key not found in .ini file, progress down the path

	add	bx, size word
	cmp	bx, (offset loaderVars.KLV_initFileBufHan)+ \
						((size word)*MAX_INI_FILES)
	jz	error

	cmp	{word} cs:[bx], 0
	jz	error

	loop	searchLoop

error:
	stc

done:
	.leave
	ret
StoreParamsAndFindKey	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StoreParams

DESCRIPTION:	Store the parameters in local variables.

CALLED BY:	INTERNAL (LibInitFileWriteData, LibInitFileWriteString)

PASS:		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string

RETURN:		all parameters stored away in variables

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

StoreParams	proc	near	uses ax, bx, cx, di, es
	.enter

        push    ds
        LoaderDS
	mov	ds:[catStrAddr].offset, si
	mov	ds:[catStrAddr].segment, ds
	mov	ds:[keyStrAddr].offset, dx
	mov	ds:[keyStrAddr].segment, cx
        pop     ds

	les	di, cs:[catStrAddr]
	call	GetStringLength
        push    ds
        LoaderDS
	mov	ds:[catStrLen], cx
        pop     ds

	les	di, cs:[keyStrAddr]
	call	GetStringLength
        push    ds
        LoaderDS
	mov	ds:[keyStrLen], cx
        pop     ds

	.leave
	ret
StoreParams	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindCategory

DESCRIPTION:	Locates the given category.

CALLED BY:	INTERNAL (InitFileWrite, LibInitFileGet, LibInitFileReadInteger)

PASS:		cs
		cs:[catStrAddr] - category ASCIIZ string
		cs:[catStrLen]
		cs:[initFileBufPos] - position to look for string

RETURN:		carry clear if category found
		    cs:[initFileBufPos] - offset from BufAddr to char past ]
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

FindCategory	proc	near
	push	ax,cx,si,ds
	lds	si, cs:[catStrAddr]

findLoop:
	;-----------------------------------------------------------------------
	;skip to next category

	mov	al, '['
	call	FindChar
	jc	exit

	call	CmpString
	jc	findLoop

	call	SkipWhiteSpace
	call	GetChar

	cmp	al, ']'
	jne	findLoop

	clc
exit:
	pop	ax,cx,si,ds
	ret
FindCategory	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindKey

DESCRIPTION:	Sets the file position at the first body position if the key
		exists.  Search halts when an EOF is encountered or when a
		new category is started.

CALLED BY:	INTERNAL (InitFileWrite)

PASS:		es - cs
		cs:[ketStrAddr] - key ASCIIZ string

RETURN:		carry clear if successful
		cs:[initFileBufPos] - offset from BufAddr to body

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	done <- false
	repeat
	    skip white space
	    if first char = ';' then
		line <- line + 1
	    else if key found then
		done <- true
	    else
		locate '='
		skip white space
		if char <> '{' then
		    line <- line + 1
		else
		    skip blob
		endif
	    endif
	until done


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

FindKey		proc	near
	push	ax,cx,si,ds
findLoop:
	call	SkipWhiteSpace
	jc	exit
	call	GetChar
	jc	exit

	cmp	al, INIT_FILE_COMMENT
	je	processComment

        push    ds
        LoaderDS
	dec	ds:[initFileBufPos].offset
        pop     ds
	cmp	al, '['
	stc
	je	exit

;checkKey:
	lds	si, cs:[keyStrAddr]
	call	CmpString
	jc	noMatch

	call	SkipWhiteSpace
	ERROR_C	LS_INIT_FILE_CORRUPT
	call	GetChar
	ERROR_C	LS_INIT_FILE_CORRUPT
	cmp	al, '='
	jne	noMatch
	jmp	short keyFound

noMatch:
	mov	al, '='
	call	FindChar
	ERROR_C	LS_INIT_FILE_CORRUPT

	call	SkipWhiteSpace
	ERROR_C	LS_INIT_FILE_CORRUPT

	call	GetChar
	cmp	al, '{'			;blob?
	je	blobFound
	call	SkipToEndOfLine
	jmp	short findLoop

blobFound:
	;-----------------------------------------------------------------------
	;skip blob

	mov	al, '}'
	call	FindChar
	ERROR_C	LS_INIT_FILE_CORRUPT
	jmp	short findLoop

processComment:
	call	SkipToEndOfLine
	jmp	short findLoop

keyFound:
	call	SkipWhiteSpace
	clc
exit:
	pop	ax,cx,si,ds
	ret
FindKey		endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SkipWhiteSpace

DESCRIPTION:	Return the next relevant character. White space and
		carraige returns are skipped.

CALLED BY:	INTERNAL (FindKey)

PASS:		cs

RETURN:		cs:[initFileBufPos] updated, next call to GetChar
			will retrieve non white space character

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

SkipWhiteSpace	proc	near
skipLoop:
	call	GetChar
	jc	exit			;branch if eof encountered

	cmp	al, C_SPACE
	je	skipLoop		;next if blank
	cmp	al, C_TAB
	je	skipLoop		;next if tab
	cmp	al, C_CR
	je	skipLoop		;next if carraige return
	cmp	al, C_LF
	je	skipLoop		;next if line feed

        push    ds
        LoaderDS
	dec	ds:[initFileBufPos].offset	;unget char
        pop     ds
	clc
exit:
	ret
SkipWhiteSpace	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SkipToEndOfLine

DESCRIPTION:	Skip to end of line.

CALLED BY:	INTERNAL (FindKey)

PASS:		es - cs

RETURN:		carry clear if ok

DESTROYED:	al

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

SkipToEndOfLine	proc	near
	push	ax
	mov	al, C_LF		;locate a carraige return
	call	FindChar
	pop	ax
	ret

SkipToEndOfLine	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindChar

DESCRIPTION:	Searches the file buffer for the given unescaped,
		uncommented character.

CALLED BY:	INTERNAL (SkipToNextCategory, FindKey, SkipToEndOfLine)

PASS:		es - cs
		al - character to locate

RETURN:		carry clear if found
		cs:[initFileBufPos] updated to byte past char
		ie. a call to GetChar will fetch the next char

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	unfortunately, the speed of the 8086 scas instructions cannot 
	be taken advantage of

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

FindChar	proc	near
	push	ax
	mov	ah, al
findCharLoop:
	call	GetChar
	jc	exit

	cmp	al, '\\'
	jne	charNotEscaped
	call	GetChar
	jmp	short findCharLoop

charNotEscaped:
	cmp	al, INIT_FILE_COMMENT
	jne	charNotComment

	;can't make a recursive call to SkipToEndOfLine because another
	; semi-colon may be encountered which would trigger another
	; search for an end-of-line character
skipComment:
	call	GetChar
	cmp	al, C_LF
	jne	skipComment

charNotComment:
	cmp	ah, al
	jne	findCharLoop

	clc
exit:
	pop	ax
	ret
FindChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetChar

DESCRIPTION:	Fetch the next character from the file buffer.

CALLED BY:	INTERNAL (SkipWhiteSpace)

PASS:		cs

RETURN:		carry clear if successful
		    al - next character
		    cs:[initFileBufPos] updated
		carry set if end of file encountered
		    al - EOF 

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	buffer position is post incremented, ie. current value is offset
	to the next character

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

GetChar	proc	near
	push	si, ds
	lds	si, cs:[initFileBufPos]		;get cur pos
	lodsb
	cmp	al, MSDOS_TEXT_FILE_EOF
	clc					;assume not end
	jne	exit
	dec	si				; don't advance pointer
	stc
exit:
        LoaderDS
	mov	ds:[initFileBufPos].offset, si
	pop	si, ds
	ret
GetChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CmpString

DESCRIPTION:	Compares the given string with the string at the
		current init file buffer location. The comparison is
		case-insensitive and white space is ignored.
		

CALLED BY:	INTERNAL ()

PASS:		ds:si - ASCIIZ string
		dgroup:[initFileBufPos] - current buffer position

RETURN:		carry clear if strings 'match'
		set otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

CmpString	proc	near	uses ax, bx, si
	.enter

	mov	bx, cs:[initFileBufPos].offset

fetchStr1:
	lodsb
	tst	al
	je	exit		; carry cleared by "or" in tst

	call	LegalCmpChar	;can this char be used for comparison?
	jc	fetchStr1	;loop if not
	mov	ah, al		;save it in ah
fetchStr2:
	call	GetChar
	jc	exit
	call	LegalCmpChar	;can this char be used for comparison?
	jc	fetchStr2

	cmp	ah, al
	je	fetchStr1
	stc			;signal chokage
        push    ds
        LoaderDS
	mov	ds:[initFileBufPos].offset, bx
        pop     ds
exit:
	.leave
	ret
CmpString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LegalCmpChar

DESCRIPTION:	Sets the carry flag based on whether or not the given
		character can be used for comparison.  Since we are
		ignoring white space, the carry bit is set if the
		character is a space or tab. The routine has the side
		effect of transforming all alphabet chars into upper case
		since comparison is case-insensitive.

CALLED BY:	INTERNAL (CmpString)

PASS:		al - char

RETURN:		carry clear if character is cmp-able
			al - made uppercase if passed al was a lowercase letter
		carry set if character is white space

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

LegalCmpChar	proc	near
	cmp	al, C_SPACE
	je	illegal

	cmp	al, C_TAB
	je	illegal
	
	cmp	al, 'a'
	jb	legal

	cmp	al, 'z'
	ja	legal

	sub	al, 'a'-'A'
legal:
	clc
	ret
illegal:
	stc
	ret
LegalCmpChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetStringLength

DESCRIPTION:	Return the length of the given string.

CALLED BY:	INTERNAL (BuildEntryFromString)

PASS:		es:di - ASCIIZ string

RETURN:		cx - number of bytes in string (excluding null terminator)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

GetStringLength	proc	near
	push	ax, di

	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	dec	cx

	pop	ax, di
	ret
GetStringLength	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AsciiToHex

DESCRIPTION:	Converts the ASCII number at the current init file buffer
		position to its binary equivalent.

CALLED BY:	INTERNAL (ReconstructData, LibInitFileReadInteger)

PASS:		es - cs
		cs:[initFileBufPos] - offset to numeric entry

RETURN:		dx - binary equivalent
		al - terminating char

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	ASCII number must be less than 65536

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

ifdef	NEED_INITFILE_READ_INTEGER
AsciiToHex	proc	near
	push	bx,cx
	mov	bx, 10
	clr	cx

convLoop:
	call	GetChar
	call	IsNumeric
	jc	done

	clr	ah
	sub	ax, '0'		;convert to digit
	xchg	ax, cx
	mul	bx		;dx:ax <- digit * 10
	add	ax, cx
	mov	cx, ax
	jmp	short convLoop	;loop till done
done:
	mov	dx, cx
	pop	bx,cx
	ret
AsciiToHex	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsNumeric

DESCRIPTION:	Boolean routine that tells if argument is a numeric
		ASCII character.

CALLED BY:	INTERNAL (AsciiToHex)

PASS:		al - ASCII char

RETURN:		carry clear if numeric
		set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@

ifdef	NEED_INITFILE_READ_INTEGER
IsNumeric	proc	near
	cmp	al, '0'
	jb	notNum		;carry set correctly

	cmp	al, '9'
	ja	notNum

	clc
	ret
notNum:
	stc
	ret
IsNumeric	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoaderInitFileReadString

DESCRIPTION:	Locates the given identifier in the geos.ini file
		and returns a pointer to the body of the associated string.

CALLED BY:	OpenIniFiles

PASS:		ax - max number of .ini files to search
		bx - offset to first ini file to search
		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - buffer to fill
		bp - size of buffer

RETURN:		carry clear if successful 
		retrieved string will be null terminated
		cx - number of bytes retrieved (excluding null terminator
		es:di - buffer filled

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@
LoaderInitFileReadString	proc	near 	uses ax, bx, di, si, bp, ds
	.enter
	call	StoreParamsAndFindKey
	jc	exit

	mov	cx, bp
	call	ReconstructString
	clc
exit:
	.leave
	ret

LoaderInitFileReadString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReconstructString

DESCRIPTION:	Reconstruct the original string entry by removing any
		enclosing braces and escape characters.

CALLED BY:	INTERNAL (LoaderInitFileReadString)

PASS:		dgroup:[initFileBufPos] - offset from BufAddr to start of data
		es:di - buffer to place data in
		cx - size of buffer

RETURN:		es:di - buffer containing string
		cx - size of buffer used

DESTROYED:	ax, bx

REGISTER/STACK USAGE:
	ds:si - buffer
	bp - blob flag (0 = false)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial version

-------------------------------------------------------------------------------@


ReconstructString	proc	near	uses di
	.enter

	push	cx			;save size of buffer

	call	SkipWhiteSpace		;func(es)

	mov	bx, -1
	call	GetChar
	cmp	al, '{'			;blob?
	je	blob

	inc	bx			;bx <- 0
	jmp	charGotten

blob:
	;-----------------------------------------------------------------------
	;ignore blob initiation chars - ie. '}', CR, LF

	call	GetChar
	cmp	al, C_CR
	jne	charGotten

	call	GetChar
	cmp	al, C_LF
	jne	charGotten
	
copyLoop:
	call	GetChar			;fetch char

charGotten:
	tst	bx			;processing blob?
	jne	processingBlob		;branch if so

	cmp	al, C_CR		;else CR?
	je	copyDone		;done if so
	cmp	al, C_LF		;LF?
	je	copyDone		;done if so
	cmp	al, MSDOS_TEXT_FILE_EOF	;EOF?
	je	copyDone		;done if so

doStore:
	stosb				;store char in buffer
	loop	copyLoop		;loop if space still exists

	dec	di			;make space for null terminator
	jmp	copyDone		;go store terminator

processingBlob:
	cmp	al, '\\'		;escape char?
	je	checkEscape		;branch if so

	;not '\'
	cmp	al,'}'			;blob terminator?
	jne	doStore

	;-----------------------------------------------------------------------
	;unescaped blob terminator found, ignore trailing CR, LF if they exist

	sub	di, 2
	cmp	{char} es:[di], C_CR
	jne	copyDone
	

	add	cx, 2			;reduce byte count by CR, LF
	clr	ax
	jmp	short storeStrTerm

checkEscape:
	;'\'
	call	GetChar			;fetch char
EC<	ERROR_C	INIT_FILE_BAD_BLOB					>
	cmp	al, '}'			;escaping blob terminator?
	je	doStore			;branch if so

        push    ds
        LoaderDS
	dec	ds:[initFileBufPos]	;else unget char
        pop     ds
	mov	al, '\\'		;store '\'
	jmp	short doStore

copyDone:
	clr	ax
storeStrTerm:
	stosb				;store char in buffer

	pop	ax			;retrieve size of buffer
	sub	ax, cx
	mov	cx, ax

	.leave
	ret
ReconstructString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoaderInitFileReadBoolean

DESCRIPTION:	Locates the given identifier in the geos.ini file and checks
		if it is TRUE or FALSE.

CALLED BY:	utility

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string

RETURN:		carry set if is FALSE or cannot find key in GEOS.INI file
		carry clear if is TRUE

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Yes, this is very simple. That's the idea.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/93		Initial version

-------------------------------------------------------------------------------@

ifndef	IMAGE_TO_BE_DISPLAYED
ifndef	NO_SPLASH_SCREEN

LoaderInitFileReadBoolean	proc	near
	uses ax, bx, di, si, bp, ds, es

tempString	local	2 dup (char)

	.enter

	push	bp
	segmov	es, ss, di
	lea	di, ss:[tempString]	;es:di = temporary 2-byte buffer
	mov	bp, size tempString	;bp = size of buffer

	;start with the first .INI file, and read them all

	mov	bx, offset loaderVars.KLV_initFileBufHan
	mov	ax, MAX_INI_FILES
	call	LoaderInitFileReadString
	pop	bp
	jc	done			;skip to end if cannot find it
					;			(is false)...

	cmp	tempString, 'T'
	je	isTrue

	cmp	tempString, 't'
	stc
	jne	done			;skip if not true...

isTrue:
	;indicate that it is TRUE

	clc
done:
	.leave
	ret
LoaderInitFileReadBoolean	endp
endif
endif
