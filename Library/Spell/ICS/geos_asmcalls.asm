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

;
; Report detailed personal-dictionary failures with the existing GEOS strings.
; The C caller has already released its memory locks and spell semaphore.
;
global	OPENUSERNOTIFY:far
OPENUSERNOTIFY	proc	far	errorCode:word
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter
		mov	si, offset no_save_user_error
		mov	di, offset no_save_user_error2
		cmp	errorCode, 11
		je	notify
		mov	si, offset no_load_user_error
		mov	di, offset no_load_user_error2
		cmp	errorCode, 12
		je	notify
		mov	si, offset load_user_proto_error
		mov	di, offset load_user_proto_error2
		cmp	errorCode, 13
		je	notify
		mov	si, offset load_user_mem_error
		mov	di, offset load_user_mem_error2
		cmp	errorCode, 14
		jne	exit
notify:
		push	si		; Pascal arguments: first string, then second.
		push	di
ifdef __BORLANDC__
		call	GEOSNOTIFY
else
		call	GEOSnotify
endif
exit:
	.leave
		ret
OPENUSERNOTIFY	endp

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

