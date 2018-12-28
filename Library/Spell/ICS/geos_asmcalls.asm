COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Spell Check Library
FILE:		geos_calls.asm

AUTHOR:		Andrew Wilson, Mar  8, 1991

ROUTINES:
	Name			Description
	----			-----------
    	GEOSopen  		Generic open() call	for PRIVDATA
    	GEOScreate  		Generic create() call 	for PRIVDATA
    	GEOSclose   		Generic close() call	
    	GEOSread  		Generic read() call
    	GEOSfarread  		Generic farread() call
    	GEOSfarwrite  		Generic farwrite() call
    	GEOStruncate  		Generic truncate() call
    	GEOSlseek   		Generic lseek() call
    	GEOSdelete   		Generic delete() call	for PRIVDATA
    	GEOSrename   		Generic rename() call 	for PRIVDATA
	GEOSMemAlloc		Allocate memory on the global heap
	GEOSMemFree		Free memory on the global heap
	GEOSMemLock		Lock memory on the global heap
	GEOSMemUnlock		Unlock memory on the global heap

    	THESHYPHENopen  	Generic open() 	 call for PUBDATA
    	THESHYPHENcreate  	Generic create() call for PUBDATA
    	THESHYPHENdelete   	Generic delete() call for PUBDATA
    	THESHYPHENrename   	Generic rename() call for PUBDATA

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial revision

DESCRIPTION:
	

	$Id: geos_asmcalls.asm,v 1.1 97/04/07 11:06:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
idata	ends
udata	segment
	currentMode	FilePosMode	(?)
	currentHandle	hptr	(?)
	currentOffset	dword	(?)

	cachedMode	FilePosMode	(?)
	cachedHandle	hptr	(?)
	cachedOffset	dword	(?)

	cacheBlock	hptr	(?)

SPELL_CACHE_SIZE	equ	512
udata	ends

.model	medium, pascal

CODE	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoSpellCheckDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to the spell check directory.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if couldn't go to directory with dictionaries
DESTROYED:	ax, dx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GotoSpellCheckDir	proc	near		uses	ds
	.enter

if not FLOPPY_BASED_USER_DICT

	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	clr	bx
	segmov	ds, cs
	mov	dx, offset dictDirName
	call	FileSetCurrentPath
	jnc	exit

;	Create it if it doesn't exist

	call	FileCreateDir
	jc	exit

	call	FileSetCurrentPath		;Change to that directory

else			

	;
	; In floppy-based-systems, if there's a disk in the doc drive, we'll 
	; use it; otherwise, we'll use SP_TOP to keep things working.  
	; 2/24/94 cbh
	;
	mov	al, DOCUMENT_DRIVE_NUM
	call	DiskRegisterDisk		
	mov	ax, SP_DOCUMENT
	jnc	setPath				
	mov	ax, SP_TOP
setPath:
	call	FileSetStandardPath
endif

exit:
	.leave
	ret
GotoSpellCheckDir	endp
SBCS <dictDirName	char	"DICTS",0				>
DBCS <dictDirName	wchar	"DICTS",0				>

ifdef __BORLANDC__
global	GEOSSETDICTPATH:far
GEOSSETDICTPATH	proc	far
else
global	GEOSsetDictPath:far
GEOSsetDictPath	proc	far
endif
	uses	ds
	.enter
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset dictDirName
	call	FileSetCurrentPath
	mov	ax, 0				;return 0 for failure
	jc	exit
	dec	ax				;return -1 for success
exit:
	.leave
	ret
ifdef __BORLANDC__
GEOSSETDICTPATH	endp
else
GEOSsetDictPath	endp
endif

ifdef __BORLANDC__
global	GEOSFILEOPEN:far
GEOSFILEOPEN	proc	far	fname:fptr,
else
global	GEOSfileOpen:far
GEOSfileOpen	proc	far	fname:fptr,
endif
				flags:word
SBCS <	uses	ds							>
DBCS <	uses	ds, si, es, di						>
	.enter
if DBCS_PCGEOS
	sub	sp, (size FileLongName)
	mov	bx, ss
	mov	es, bx			; es:di = DBCS fname buffer on stack
	mov	di, sp
	mov	bx, sp
	lds	si, fname		; ds:si = passed SBCS fname
	mov	cx, FILE_LONGNAME_LENGTH-1
	push	ax
	clr	ah
copyLoop:
	lodsb
	stosw
	loop	copyLoop
	clr	ax			; ensure null-terminated
	stosw
	pop	ax
	segmov	ds, ss			; ds:dx = DBCS fname on stack
	mov	dx, bx
else
	lds	dx, fname
endif
	mov	ax, flags
	call	FileOpen			; ax = handle
DBCS <	lea	sp, ss:[bx][(size FileLongName)]			>
	jc	error				; return handle
	xchg	bx, ax
	mov	ax, handle 0
	call	HandleModifyOwner
	xchg	bx, ax
	clc
exit:
	.leave
	ret
error:
	mov	ax, 0				;return 0 for failure
	jmp	exit
ifdef __BORLANDC__
GEOSFILEOPEN	endp
else
GEOSfileOpen	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSopen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSOpen

C DECLARATION	extern int GEOSOpen(char *fname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSOPEN:far
GEOSOPEN	proc	far	fname:fptr, flags:word
else
global	GEOSopen:far
GEOSopen	proc	far	fname:fptr, flags:word
endif
	uses	ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, fname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	tst	fname.segment		;If null offset to path, exit (invalid)
	jz	errorExit

	call	FilePushDir
	call	GotoSpellCheckDir	;Go to standard spell check directory
	jc	errorExit

	lds	dx, fname		;*DS:DX <- filename
	mov	ax, flags
	call	CommonSpellOpen		; carry set on error
	jnc	exit

errorExit:
	mov	ax, -1			;Signify an error in opening the file.
exit:
	call	FilePopDir
	.leave
	ret
ifdef __BORLANDC__
GEOSOPEN	endp
else
GEOSopen	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSdelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSDelete

C DECLARATION	extern int GEOSDelete(char *fname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSDELETE:far
GEOSDELETE	proc	far	fname:fptr
else
global	GEOSdelete:far
GEOSdelete	proc	far	fname:fptr
endif
	uses	ds
	.enter
	call	FilePushDir
	call	GotoSpellCheckDir	;Go to standard spell check directory
	jc	errorExit

	lds	dx, fname		;DS:DX <- ptr to filename
	call	CommonSpellDelete	;carry set on error
	jnc	exit			;Exit if no error
errorExit:
	mov	ax, -1			;Signify an error in opening the file.
exit:
	call	FilePopDir
	.leave
	ret
ifdef __BORLANDC__
GEOSDELETE	endp
else
GEOSdelete	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSrename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSRename

C DECLARATION	extern int GEOSRename(char *oldname, char *newname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSRENAME:far
GEOSRENAME	proc	far	oldname:fptr, newname:fptr
else
global	GEOSrename:far
GEOSrename	proc	far	oldname:fptr, newname:fptr
endif
			uses	di, es, ds
	.enter
		
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, oldname
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, newname
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	call	FilePushDir
	call	GotoSpellCheckDir	;Go to standard spell check directory
	mov	ax, -1			;(assume error)
	jc	exit

;	DO SOME SIMPLE CHECKS ON THE FILE NAME

	lds	dx, oldname		;*DS:DX <- filename
	les	di, newname		;*ES:DI <- new filename

;	rename THE FILE

	call	CommonSpellRename
exit:
	call	FilePopDir
	.leave
	ret
ifdef __BORLANDC__
GEOSRENAME	endp
else
GEOSrename	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOScreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSCreate

C DECLARATION	extern int GEOSCreate(char *fname, short flags);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSCREATE:far
GEOSCREATE	proc	far	fname:fptr, flags:word
else
global	GEOScreate:far
GEOScreate	proc	far	fname:fptr, flags:word
endif
	uses	ds
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, fname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	call	FilePushDir
	call	GotoSpellCheckDir	;Go to standard spell check directory
	jc	errorExit

	mov	ax, flags
	lds	dx, fname		;DS:DX <- ptr to filename
	call	CommonSpellCreate	; carry set on error
	jnc	exit
errorExit:
	mov	ax, -1			;Signify an error in opening the file.
exit:
	call	FilePopDir
	.leave
	ret
ifdef __BORLANDC__
GEOSCREATE	endp
else
GEOScreate	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSfarread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSFarRead

C DECLARATION	extern RETCODE GEOSFarRead(HANDLE fileHan, UCHAR NEAR *bufPtr, UINT2B byteCount);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSFARREAD:far
else
global	GEOSfarread:far
endif
	uses	ds
ifdef __BORLANDC__
GEOSFARREAD	proc	far	fileHan:hptr, bufPtr:fptr, byteCount:word
else
GEOSfarread	proc	far	fileHan:hptr, bufPtr:fptr, byteCount:word
endif
	.enter
	mov	bx, fileHan		;BX <- file handle
	mov	cx, byteCount		;CX <- # bytes to read
	lds	dx, bufPtr		;DS:DX <- buffer to read data into
	tst	bufPtr.segment
	jz	errorExit
	
	call	CachedFileRead
	xchg	ax, cx			;AX <- # bytes returned
	jnc	exit
	cmp	cx, ERROR_SHORT_READ_WRITE	;Don't whine about short reads
	je	exit
errorExit:
	mov	ax, -1
exit:
	.leave
	ret
ifdef __BORLANDC__
GEOSFARREAD	endp
else
GEOSfarread	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSlseek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSlseek

C DECLARATION	extern long GEOSlseek(HANDLE fileHan, UINT4B fileOffset, UINT2B where);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSLSEEK:far
GEOSLSEEK	proc	far	fileHan:hptr, fileOffset:dword, where:word
else
global	GEOSlseek:far
GEOSlseek	proc	far	fileHan:hptr, fileOffset:dword, where:word
endif
	.enter
	clr	ax
	mov	bx, fileHan		;BX <- file handle
	mov	ax, where		;AL <- FilePosMode
EC <	cmp	al, FILE_POS_RELATIVE					>
EC <	ERROR_A	BAD_GEOS_LSEEK_FLAGS					>
	mov	cx, fileOffset.high	;CX:DX <- offset into file
	mov	dx, fileOffset.low	;
	call	CachedFilePos		;Returns new position in DX:AX
	.leave
	ret
ifdef __BORLANDC__
GEOSLSEEK	endp
else
GEOSlseek	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEOSnotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GEOSnotify

C DECLARATION	VOID GEOSnotify(CHUNK str1, CHUNK str2);

DESTROYED:	various important but undocumented things
 
VSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	GEOSNOTIFY:far
GEOSNOTIFY	proc	far	str1:lptr, str2:lptr
else
global	GEOSnotify:far
GEOSnotify	proc	far	str1:lptr, str2:lptr
endif
				uses	ds, di, si
	.enter
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
	mov	si, str1		;*DS:SI <- first string
	mov	di, str2		;*DS:DI <- second string
	mov	di, ds:[di]
	mov	si, ds:[si]
	mov	ax, mask SNF_CONTINUE
	call	SysNotify
	call	MemUnlock
	.leave
	ret
ifdef __BORLANDC__
GEOSNOTIFY	endp
else
GEOSnotify	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPtrToCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called to get a cache block to store data in.

CALLED BY:	GLOBAL
PASS:		es - idata
RETURN:		es:di <- ptr to cache
		bx <- handle of cache block
DESTROYED:	ax, bx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPtrToCache	proc	near

EC <	push	ax						>
EC <	mov	ax, es						>
EC <	cmp	ax, dgroup					>
EC <	ERROR_NE			NOT_DGROUP		>
EC <	pop	ax						>

	mov	bx, es:[cacheBlock]		;Get cache block
	tst	bx				;If it isn't set yet, branch
	jnz	allocated
	push	cx
	mov	ax, SPELL_CACHE_SIZE
	mov	cx, ALLOC_STATIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner
	pop	cx
	mov	es:[cacheBlock], bx
	jmp	locked
allocated:
	call	MemLock
	jnc	locked

;	IF BLOCK WAS DISCARDED, RE-ALLOCATE IT

	push	cx
	clr	ax
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemReAlloc
	pop	cx
locked:
	mov	es, ax
	ret
GetPtrToCache	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CachedFilePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current position in the file so we can check to
		see if the data has been cached in memory and so does not 
		need to be saved to disk.

CALLED BY:	GLOBAL
PASS:		same as FilePos:
	al - method code:
		0 - From start of file (FILE_POS_START)
		1 - From current position in file (FILE_POS_RELATIVE)
		2 - From end of file (FILE_POS_END)
	bx - file handle
	cx:dx - offset

RETURN:		same as FilePos
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CachedFilePos	proc	near	uses	es, di
	.enter
	mov	di, segment idata
	mov	es, di
	mov	es:[currentMode],al
	mov	es:[currentHandle], bx
	mov	es:[currentOffset].high, cx
	mov	es:[currentOffset].low, dx
	call	FilePos
	.leave
	ret
CachedFilePos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CachedFileRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine checks to see if it is a sector read, which we
		cache. If it isn't, it just jumps to FileRead. If it is, it 
		first checks to see if the data was cached. If it was cached,
		it copies the data out of the cache. Otherwise, it reads the
		data into the cache.

CALLED BY:	GLOBAL
PASS:		Same as FileRead (except AX)
	bx - file handle
	cx - number of bytes to read
	ds:dx - buffer into which to read


RETURN:		Same as FileRead
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CachedFileRead	proc	near	uses	es, bp, di, si
	.enter
	cmp	cx, SPELL_CACHE_SIZE
	jne	noCache
	mov	di, segment idata
	mov	es, di


;	CHECK OFFSET INTO FILE TO SEE IF IT MATCHES THE CACHE	

	mov	ax, es:[currentOffset].low	;
	cmp	ax, es:[cachedOffset].low
	jnz	noCache
	mov	ax, es:[currentOffset].high
	cmp	ax, es:[cachedOffset].high
	jnz	noCache

;	COMPARE FILE HANDLE TO SEE IF IT MATCHES THE CACHE

	cmp	bx, es:[cachedHandle]		;Is the cached data from this
	jnz	noCache				; file? Branch if not.
	cmp	bx, es:[currentHandle]		;Was the last lseek from this
	jnz	noCache				; file? Branch if not.

;	CHECK OFFSET MODE TO SEE IF IT MATCHES THE CACHE

	mov	al, es:[currentMode]		;
	cmp	al, es:[cachedMode]

	jnz	noCache

;	COPY DATA OUT OF OUR CACHE

	mov	bp, bx				;Save file handle in BP
	mov	bx, es:[cacheBlock]
	call	MemLock
	jc	discarded

;	ADVANCE THE CURRENT OFFSET INTO THE FILE
;
;	THIS IS NECESSARY IF THEY READ IN A SECTOR, THEN DO A FILEPOS TO
;	POSITION TO THAT SECTOR, DO A READ TO GET THE SECTOR (WHICH GETS
;	THE SECTOR FROM THE CACHE), AND THEN GET ANOTHER READ TO GET THE
;	NEXT SECTOR. WE NEED TO UP THE FILE POSITION WHEN READING FROM
;	THE CACHE

	push	ax, bx, cx, dx
	mov	al, es:[currentMode]
	mov	bx, es:[currentHandle]
	mov	dx, es:[currentOffset].low
	mov	cx, es:[currentOffset].high
	add	dx, SPELL_CACHE_SIZE
	adc	cx, 0
	call	CachedFilePos
	pop	ax, bx, cx, dx
	push	ds
	mov	ds, ax				;DS:SI <- ptr to cache block
	clr	si
	pop	es
	mov	di, dx				;ES:DI <- ptr to dest for data
	shr	cx, 1				;Copy data out of cache
	rep	movsw
	segmov	ds, es, ax
	jmp	unlockCacheAndExit		;Unlock cache and get out
discarded:
	mov	bx, bp				;Restore file handle
noCache:
	clr	ax
	call	FileRead
	jc	exit				;Exit if error
	cmp	cx, SPELL_CACHE_SIZE		;
	jnz	noErrorExit			;

;	COPY OVER THE CACHE PARAMETERS

	mov	ax, es:[currentOffset].low
	mov	es:[cachedOffset].low, ax
	mov	ax, es:[currentOffset].high
	mov	es:[cachedOffset].high, ax
	mov	ax, es:[currentHandle]
	mov	es:[cachedHandle], ax
	mov	al, es:[currentMode]
	mov	es:[cachedMode], al

	add	es:[currentOffset].low, SPELL_CACHE_SIZE
	adc	es:[currentOffset].high, 0

;	COPY DATA READ IN INTO OUR CACHE

	mov	si, dx				;DS:SI <- ptr to data read in
	call	GetPtrToCache			;ES <- segment of cache
						;BX <- handle of cache
	clr	di				;ES:DI <- ptr to cache
	shr	cx,1				;
	rep	movsw				;Copy data to cache

unlockCacheAndExit:
	call	MemUnlock			;Unlock the cache block
	mov	cx, SPELL_CACHE_SIZE		;Return # bytes read...
noErrorExit:
	clc					; ...and no error.
exit:
	.leave
	ret
CachedFileRead	endp

CODE	ends

SpellControlCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDictionaryName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the dictionary name into the passed buffer

CALLED BY:	GLOBAL
PASS:		es:di - ptr to space for ICFNAMEMAX chars
		DBCS <ax <> =0 for DBCS string, ax = 0 for SBCS string>
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		Can't fetch DBCS string into passed buffer as it
		might only have room for SBCS string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	textCategory	char	"text",0
	dictionaryKey	char	"dictionary",0
SBCS <	dictName	char	"IENC9123.DAT",0			>
DBCS <	dictName	wchar	"IENC9123.DAT",0			>
SBCS <GetDictionaryName	proc	far	uses	cx, dx, bp, ds, di, si	>
DBCS <GetDictionaryName	proc	far	uses	ax, cx, dx, bp, ds, di, si>
DBCS <dbcsFlag	local	word	push	ax				>
DBCS <dbcsBuf	local	ICFNAMEMAX dup (wchar)					>
	.enter
if DBCS_PCGEOS
	push	es, di			; save incoming buffer
	segmov	es, ss
	lea	di, dbcsBuf
	push	bp
endif
	mov	bp, INITFILE_INTACT_CHARS or ICFNAMEMAX
	mov	cx, cs
	mov	ds, cx
	mov	dx, offset dictionaryKey
	mov	si, offset textCategory	
	call	InitFileReadString
DBCS <	pop	bp							>
	jnc	10$			;If found, branch.

;	ELSE, COPY OVER THE DEFAULT DISK BASED DICTIONARY NAME

	mov	cx, size dictName
	mov	si, offset dictName
	rep	movsb
10$:	
if DBCS_PCGEOS
	pop	es, di			; es:di = passed buffer
	segmov	ds, ss
	lea	si, dbcsBuf
copyLoop:
	lodsw
	stosb				; DBCS-lo or SBCS char
	tst	dbcsFlag
	jz	haveSBCS
	xchg	al, ah			; al = high byte of DBCS char
	stosb
	xchg	al, ah			; restore DBCS char
haveSBCS:
	tst	ax
	jnz	copyLoop
endif
	.leave
	ret
GetDictionaryName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSpellAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the spell check dictionary is around.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - non-zero if dict is around
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <directoryString	char	"DICTS",0				>
DBCS <directoryString	wchar	"DICTS",0				>
CheckIfSpellAvailable	proc	far	uses	bx, cx, dx, di, es, ds
SBCS <	fname	local	ICFNAMEMAX dup (char)				>
DBCS <	fname	local	ICFNAMEMAX dup (wchar)			>
	.enter

;	Get the dictionary name, go to the DICTS directory, and see if the
;	dictionary exists.


	lea	di, fname
	segmov	es, ss			;ES:DI <- ptr for name
DBCS <	mov	ax, -1			;return DBCS string		>
	call	GetDictionaryName
	call	FilePushDir

	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset directoryString
	call	FileSetCurrentPath
	jc	error

	segmov	ds, ss
	lea	dx, fname
	call	FileGetAttributes
error:	
	mov	ax, TRUE		;Return AX = non-zero if no error
	jnc	exit
	clr	ax
exit:
	call	FilePopDir
	.leave
	ret
CheckIfSpellAvailable	endp

SpellControlCommon ends

;---

INIT	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDictionaryInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GetDiskBasedDictionaryName

C DECLARATION:	GetDiskBasedDictionaryName(ICBuff FAR *p);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	languageKey		char	"language",0
	dialectKey		char	"dialect",0
	tCategory		char	"text",0
	
ifdef __BORLANDC__
global GETDICTIONARYINFO:near
GETDICTIONARYINFO	proc	near	destPtr:fptr.ICBuff
else
global GetDictionaryInfo:near
GetDictionaryInfo	proc	near	destPtr:fptr.ICBuff
endif
				uses	es, ds, si, di
	.enter
	les	di, destPtr			;ES:DI <- ptr to store fname
	add	di, offset ICB_masterFname
DBCS <	mov	ax, 0			; get SBCS string (for C)	>
	call	GetDictionaryName


;	GET THE LANGUAGE/DIALECT OUT OF THE INI FILE
;
;	First, set the language/dialect in the ICBuff to the default. Look for
;	each in the .ini file. If they are found in the ini file, replace the
;	default values in the ICBuff.
;

	mov	di, destPtr.offset	;ES:DI <- ptr to ICBuff
					;Set the default language/dialect
	mov	es:[di].ICB_language, SL_DEFAULT
	mov	es:[di].ICB_dialect, mask LD_DEFAULT

	segmov	ds, cs, cx
	mov	si, offset tCategory	;DS:SI <- ptr to text category string
	mov	dx, offset languageKey	;CX:DX <- ptr to key
	call	InitFileReadInteger
	jc	80$			;Branch if key not found in ini file
	mov	es:[di].ICB_language, al
80$:
	mov	dx, offset dialectKey	;CX:DX <- ptr to key
	call	InitFileReadInteger
	jc	90$			;Branch if key not found in ini file
	test	ax, 0x0f		;If low four bits are set, set to 0
	je	85$			; instead so error will be returned
	clr	ax
85$:
	mov	es:[di].ICB_dialect, ax
90$:
	.leave
	ret
ifdef __BORLANDC__
GETDICTIONARYINFO	endp
else
GetDictionaryInfo	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THESHYPHENopen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	THESHYPHENOpen

C DECLARATION	extern int THESHYPHENOpen(char *fname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	THESHYPHENOPEN:far
THESHYPHENOPEN	proc	far	fname:fptr, flags:word
else
global	THESHYPHENopen:far
THESHYPHENopen	proc	far	fname:fptr, flags:word
endif
	uses	ds
	.enter

	tst	fname.segment		;If null offset to path, exit (invalid)
	jz	errorExit

	lds	dx, fname		;DS:DX <- ptr to filename
	mov	ax, flags
	call	CommonSpellOpen		;Carry set on error
	jc	errorExit

exit:
	.leave
	ret
errorExit:
	mov	ax, -1			;Signify an error in opening the file.
	jmp	exit
ifdef __BORLANDC__
THESHYPHENOPEN	endp
else
THESHYPHENopen	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonSpellOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does opening file work common to GEOSopen and THESHYPHENopen

CALLED BY:	GEOSopen, THESHYPHENopen (local)
PASS:		ax - C open flags
		ds:dx -> filename
RETURN:		carry set on error, else carry clear
DESTROYED:	ax, dx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/20/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonSpellOpen	proc	far

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	test	ax, 0x1			;read/write or write-only
	mov	al, FileAccessFlags<FE_EXCLUSIVE, FA_READ_WRITE>
	jnz	gotFlags
	mov	al, FileAccessFlags<FE_DENY_WRITE, FA_READ_ONLY>
gotFlags:

;	DO SOME SIMPLE CHECKS ON THE FILE NAME

	mov	bx, dx
	cmp	{char} ds:[bx], 0	;If the path is bogus (null), exit.
	jz	errorExit

if DBCS_PCGEOS
	push	ds, es, si, di
	sub	sp, (size FileLongName)
	mov	bx, ss
	mov	es, bx			; es:di = DBCS fname buffer on stack
	mov	di, sp
	mov	bx, sp
	mov	si, dx			; ds:si = passed SBCS fname
	push	ax
	mov	cx, FILE_LONGNAME_LENGTH-1
	clr	ah
copyLoop:
	lodsb
	stosw
	loop	copyLoop
	clr	ax			; ensure null-terminated
	stosw
	pop	ax
	segmov	ds, ss			; ds:dx = DBCS fname on stack
	mov	dx, bx
endif

;	open THE FILE

	call	FileOpen
if DBCS_PCGEOS
	lea	sp, ss:[bx][(size FileLongName)]
	pop	ds, es, si, di
endif
	jc	errorExit		;Exit if no error
	xchg	bx, ax			;Change owner of file
	mov	ax, handle 0
	call	HandleModifyOwner
	xchg	ax, bx
	clc
	jmp	exit
errorExit:
	stc
exit:
	ret
CommonSpellOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THESHYPHENdelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	THESHYPHENDelete

C DECLARATION	extern int THESHYPHENDelete(char *fname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	THESHYPHENdelete:far
THESHYPHENdelete	proc	far	fname:fptr
	uses	ds
	.enter

	lds	dx, fname		;DS:DX <- ptr to filename
	call	CommonSpellDelete	; carry set on error
	jnc	exit			;Exit if no error
	mov	ax, -1			;Signify an error in opening the file.
exit:
	.leave
	ret
THESHYPHENdelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonSpellDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does deletion work common to THESHYPHENdelete and GEOSdelete

CALLED BY:	THESHYPHENdelete, GEOSdelete (local)
PASS:		ds:dx -> filename
RETURN:		carry set on error
DESTROYED:	dx, bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/20/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonSpellDelete	proc	far

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	;	DO SOME SIMPLE CHECKS ON THE FILE NAME

	tst	dx			;If null offset to path, exit (invalid)
	jz	errorExit
	mov	bx, dx
	cmp	{char} ds:[bx], 0	;If the path is bogus (null), exit.
	jz	errorExit

if DBCS_PCGEOS
	push	ds, es, si, di
	sub	sp, (size FileLongName)
	mov	bx, ss
	mov	es, bx			; es:di = DBCS fname buffer on stack
	mov	di, sp
	mov	bx, sp
	mov	si, dx			; ds:si = passed SBCS fname
	push	ax
	mov	cx, FILE_LONGNAME_LENGTH-1
	clr	ah
copyLoop:
	lodsb
	stosw
	loop	copyLoop
	clr	ax			; ensure null-terminated
	stosw
	pop	ax
	segmov	ds, ss			; ds:dx = DBCS fname on stack
	mov	dx, bx
endif

;	delete THE FILE

	call	FileDelete
if DBCS_PCGEOS
	add	sp, (size FileLongName)
	pop	ds, es, si, di
endif
	clc	
exit:
	ret
errorExit:
	stc
	jmp exit
CommonSpellDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THESHYPHENcreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	THESHYPHENCreate

C DECLARATION	extern int THESHYPHENCreate(char *fname, short flags);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	THESHYPHENcreate:far
THESHYPHENcreate	proc	far	fname:fptr, flags:word
	uses	ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, fname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, flags		;ax = flags
	lds	dx, fname		;DS:DX <- ptr to filename
	call	CommonSpellCreate
	jnc	exit
	mov	ax, -1			;Signify an error in opening the file.
exit:
	.leave
	ret
THESHYPHENcreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonSpellCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do work common to GEOScreate and THESHYPHENcreate

CALLED BY:	GEOScreate, THESHYPHENcreate (local)
PASS:		ds:dx -> filename
		ax = flags
RETURN:		carry set on error
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/20/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonSpellCreate	proc	far

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

;	DO SOME SIMPLE CHECKS ON THE FILE NAME

	tst	dx			;If null offset to path, exit (invalid)
	jz	errorExit
	mov	bx, dx
	cmp	{char} ds:[bx], 0	;If the path is bogus (null), exit.
	jz	errorExit

;	create THE FILE

	mov	ah, al			;
	mov	al, FileAccessFlags<FE_DENY_WRITE, FA_READ_WRITE>
	mov	cx, FILE_ATTR_NORMAL

if DBCS_PCGEOS
	push	ds, es, si, di
	sub	sp, (size FileLongName)
	mov	bx, ss
	mov	es, bx			; es:di = DBCS fname buffer on stack
	mov	di, sp
	mov	bx, sp
	mov	si, dx			; ds:si = passed SBCS fname
	push	ax, cx
	mov	cx, FILE_LONGNAME_LENGTH-1
	clr	ah
copyLoop:
	lodsb
	stosw
	loop	copyLoop
	clr	ax			; ensure null-terminated
	stosw
	pop	ax, cx
	segmov	ds, ss			; ds:dx = DBCS fname on stack
	mov	dx, bx
endif

	call	FileCreate
if DBCS_PCGEOS
	lea	sp, ss:[bx][(size FileLongName)]
	pop	ds, es, si, di
endif
	jc	errorExit		;Exit if no error
	xchg	bx, ax			;Change owner of file
	mov	ax, handle 0
	call	HandleModifyOwner
	xchg	ax, bx
	clc
	ret
errorExit:
	stc
	ret
CommonSpellCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THESHYPHENrename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	THESHYPHENRename

C DECLARATION	extern int THESHYPHENRename(char *oldname, char *newname);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	THESHYPHENrename:far
THESHYPHENrename	proc	far	oldname:fptr, newname:fptr
			uses	di, es, ds
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, oldname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, newname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

;	DO SOME SIMPLE CHECKS ON THE FILE NAME

	lds	dx, oldname		;*DS:DX <- filename
	les	di, newname

;	rename THE FILE

	call	CommonSpellRename
	.leave
	ret
THESHYPHENrename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonSpellRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do work common to GEOSrename and THESHYPHENrename

CALLED BY:	GEOScreate, THESHYPHENcreate (local)
PASS:		ds:dx -> old filename
		es:di -> new filename
RETURN:		ax = 0 if successful
		ax = -1 if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonSpellRename	proc	far

if DBCS_PCGEOS ;--------------------------------------------------------------

	uses	cx, ds, es, si, di
destPtrSeg	local	word	push es
destPtrOff	local	word	push di
sourceName	local	FILE_LONGNAME_LENGTH dup (wchar)
destName	local	FILE_LONGNAME_LENGTH dup (wchar)
	.enter

	segmov	es, ss			; es:di = DBCS src fname buffer on stack
	lea	di, sourceName
	mov	si, dx			; ds:si = passed SBCS src fname
	mov	cx, FILE_LONGNAME_LENGTH-1
	clr	ah
10$:
	lodsb
	stosw
	loop	10$
	clr	ax			; ensure null-terminated
	stosw

	lea	di, destName		; es:di = DBCS dest name buffer on stack
	mov	ds, destPtrSeg		; ds:si = passed SBCS dest fname
	mov	si, destPtrOff
	mov	cx, FILE_LONGNAME_LENGTH-1
	clr	ah
20$:
	lodsb
	stosw
	loop	20$
	clr	ax			; ensure null-terminated
	stosw

	segmov	ds, ss			; ds:dx = DBCS src fname on stack
	lea	dx, sourceName
	lea	di, destName		; es:di = DBCS dest fname on stack
	call	FileRename
	mov	ax, 0			;assume no error
	jnc	exit			;Exit if no error
	mov	ax, -1
exit:
	.leave

else	;-------------------------------------------------------------------

	call	FileRename
	mov	ax, 0			;assume no error
	jnc	exit			;Exit if no error
	mov	ax, -1
exit:

endif	;-------------------------------------------------------------------
	ret
CommonSpellRename	endp


INIT	ends


ifdef FORCE_SBCS
;
; SBCS string routines grabbed from AnsiC library (which now operates in
; DBCS
;

CODE	segment

if	ERROR_CHECK
ECCheckBoundsESDI	proc	near
	segxchg	es, ds
	xchg	si, di
	call	ECCheckBounds
	xchg	si, di
	segxchg	es, ds
	ret
ECCheckBoundsESDI	endp
ECCheckBoundsESDIMinusOne	proc	near
	pushf	
	push	di
	dec	di
	call	ECCheckBoundsESDI
	pop	di
	popf
	ret
ECCheckBoundsESDIMinusOne	endp
ECCheckBoundsMinusOne		proc	near
	pushf
	push	si
	dec	si
	call	ECCheckBounds
	pop	si
	popf
	ret
ECCheckBoundsMinusOne		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strlen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strlen

C DECLARATION	word strlen(TCHAR far *str);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global  strlenSBCS:far
strlenSBCS  proc    far     strPtr:fptr
				uses	es, di
	.enter
	les	di, strPtr
EC <	call	ECCheckBoundsESDI					>
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx
	dec	cx			;Nuke count of null terminator
	xchg	ax, cx
	.leave
	ret
strlenSBCS  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strchr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strchr

C DECLARATION	TCHAR far * strchr(TCHAR *str1, word c);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strchrSBCS:far
strchrSBCS	proc	far	str1:fptr, theC:word
				uses	es, di
	.enter
	les	di, str1
EC <	call	ECCheckBoundsESDI					>
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx			;CX <- # chars including null
	mov	di, str1.offset
	mov	ax, theC
	repne	scasb			;Look for the character
	jne	notFound		;If not found, branch
	dec	di
	mov	dx, es			;DX:AX <- ptr to char found
	xchg	ax, di
exit:
	.leave
	ret
notFound:
	clr	dx			;If char not found, return NULL
	clr	ax			
	jmp	exit
strchrSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcpy

C DECLARATION	TCHAR far  * strcpy(TCHAR far *dest, TCHAR far *source);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcpySBCS:far
strcpySBCS	proc	far	destPtr:fptr, sourcePtr:fptr
				uses	ds, es, di, si
	.enter
	les	di, sourcePtr	;ES:DI <- ptr to src string
	mov	ds, sourcePtr.segment
	mov	si, di		;DS:SI <- ptr to src string

	mov	cx, -1
	clr	ax
	repne	scasb
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx		;CX <- # chars (+ null) in src string

	les	di, destPtr	;ES:DI <- ptr to dest for string
	mov	dx, es		;DX:AX <- ptr to dest for string
	mov	ax, di

	shr	cx, 1
	jnc	10$
	movsb
10$:
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOne				>
	.leave
	ret
strcpySBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncpy

C DECLARATION	TCHAR far  * strcpy(TCHAR far *dest, TCHAR far *source, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncpySBCS:far
strncpySBCS	proc	far	destPtr:fptr, sourcePtr:fptr, len:word
				uses	ds, es, di, si
	.enter

	lds	si, sourcePtr	;DS:SI <- ptr to src string
	les	di, destPtr	;ES:DI <- ptr to dest string
	mov	cx, len
	jcxz	exit
5$:
	lodsb
	tst	al
	jz	10$
	stosb
	loop	5$
exit:
	.leave
	ret
10$:
	rep	stosb		;Null pad the dest string
EC <	call	ECCheckBoundsMinusOne					>
EC <	call	ECCheckBoundsESDIMinusOne				>
	jmp	exit
strncpySBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcmp

C DECLARATION	word strcmp(word far *str1, word far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcmpSBCS:far
strcmpSBCS	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	lds	si, str2		;DS:SI <- ptr to str 2
	mov	cx, -1
	clr	ax			;
	repne	scasb			;
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars in str 1 (w/null)

	mov	di, str1.offset		;ES:DI <- ptr to str1
	repe	cmpsb
EC <	call	ECCheckBoundsMinusOne					>
	jz	exit			;If match, exit (with ax=0)
	mov	al, es:[di][-1] 	;Else, return difference of chars>
	sub	al, ds:[si][-1] 	;
	cbw				;
exit:
	.leave
	ret
strcmpSBCS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncmp

C DECLARATION	word strncmp(word far *str1, word far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncmpSBCS:far
strncmpSBCS	proc	far	str1:fptr, str2:fptr, len:word
				uses	ds, es, di, si
	.enter
	clr	ax			;
	mov	cx, len			;
	jcxz	exit			;If string is empty, return that they
					; are equal.
	les	di, str1		;ES:DI <- ptr to str1
	repne	scasb			;Get length of string
EC <	call	ECCheckBoundsESDIMinusOne				>
	neg	cx
	add	cx, len			;CX <- min (len, strlen(str1)+1);
	lds	si, str2		;DS:SI <- ptr to str 2	
	mov	di, str1.offset		;ES:DI <- ptr to str1
	repe	cmpsb
EC <	call	ECCheckBoundsMinusOne					>
	mov	al, es:[di][-1]		;Return difference of chars
	sub	al, ds:[si][-1]		;
	cbw				;
exit:
	.leave
	ret
strncmpSBCS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcat

C DECLARATION	VOID * strcat(TCHAR far *str1, TCHAR far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcatSBCS:far
strcatSBCS	proc	far	str1:fptr, str2:fptr
				uses	es, ds, di, si
	.enter
	les	di, str2		;
	lds	si, str2		;

;	GET LENGTH OF SECOND STRING

	clr	ax
	mov	cx, -1
	repne	scasb
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx			;CX <- # chars in second string + null

;	SCAN TO END OF FIRST (DEST) STRING

	mov	dx, cx			;DX <- size of second string
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1			;
	repne	scasb			;ES:DI <- ptr past null
	dec	di			;ES:DI <- ptr to null byte of string
EC <	call	ECCheckBoundsESDI					>
	mov	cx, dx			;CX <- size of second string

;	COPY SECOND STRING ONTO END OF FIRST STRING

	shr	cx, 1
	jnc	10$
	movsb
10$:
	rep	movsw
EC <	call	ECCheckBoundsESDIMinusOne				>
EC <	call	ECCheckBoundsMinusOne				>
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
strcatSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strncat

C DECLARATION	VOID * strncat(TCHAR far *str1, TCHAR far *str2, word len);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		Name is in caps so routine can be published now that it's
		fixed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strncatSBCS:far
strncatSBCS	proc	far	str1:fptr, str2:fptr, len:word
				uses	es, ds, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	mov	cx, -1
	clr	al
	repne	scasb
	dec	di			;ES:DI <- ptr to null-terminator for
					; str1
	mov	cx, len			;
	jcxz	exit			;If string is empty, just exit
	lds	si, str2
loopTop:
	lodsb
	tst	al
	jz	10$
	stosb
	loop	loopTop
	clr	al
10$:
EC <	call	ECCheckBoundsMinusOne					>
EC <	call	ECCheckBoundsESDI					>
	stosb
exit:
	mov	dx, es
	mov	ax, str1.offset
	.leave
	ret
strncatSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcspn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strcspn

C DECLARATION	word strcspn(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strcspnSBCS:far
strcspnSBCS	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	al
	repne	scasb
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	mov	bx, cx
	mov	dx,-1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that aren't in
				; str2
	lodsb			;AL <- next char in str1
	tst	al
	jz	exit
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
	jcxz	loopTop
	repne	scasb
	jnz	loopTop		;If char not found, branch


exit:
EC <	call	ECCheckBoundsMinusOne					>
	xchg	ax, dx		;AX <- # chars at start of str1 that do not lie
				; in str2
	.leave
	ret
strcspnSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strspn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strspn

C DECLARATION	word strspn(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strspnSBCS:far
strspnSBCS	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
	repne	scasb
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	jcxz	exit		;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
	mov	dx, -1
loopTop:
	inc	dx		;DX <- # chars at start of str1 that are in
				; str2
	lodsb			;AL <- next char in str1
	tst	al 		;Exit if at end of str1
	jz	99$		;
	mov	cx, bx		;CX <- # chars in string
	mov	di, str2.offset	;ES:DI <- ptr to str2
	repne	scasb		;
	jz	loopTop		;If char found, branch

99$:
EC <	call	ECCheckBoundsMinusOne				>
	xchg	ax, dx		;AX <- # chars at start of str1 that lie
				; in str2
exit:
	.leave
	ret
strspnSBCS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strpbrk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	strpbrk

C DECLARATION	TCHAR *strpbrk(TCHAR *str1, TCHAR *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	strpbrkSBCS:far
strpbrkSBCS	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str2	;ES:DI <- ptr to str2	
	lds	si, str1	;DS:SI <- ptr to str1
	mov	cx, -1		;CX <- # chars in str2 not counting null
	clr	ax
	repne	scasb
EC <	call	ECCheckBoundsESDIMinusOne				>
	not	cx
	dec	cx
	jcxz	notFound	;Exit if str2 is null

	mov	bx, cx		;BX <- strlen(str2)
loopTop:
	lodsb			;AL <- next char in str1
	tst	al		;Exit if at end of str1
	jz	checkNotFound		;
	mov	cx, bx		;CX <- # chars in str2
	mov	di, str2.offset	;ES:DI <- ptr to str2
	repne	scasb		;
	jnz	loopTop		;If char not found, branch
	dec	si
EC <	call	ECCheckBounds						>
	movdw	dxax, dssi	;DX:AX <- ptr to char in string1 
exit:
	.leave
	ret
checkNotFound:
EC <	call	ECCheckBoundsMinusOne					>
notFound:
	clrdw	dxax
	jmp	exit
strpbrkSBCS	endp

CODE	ends

endif	; FORCE_SBCS
