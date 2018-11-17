COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	socket
MODULE:		access point database
FILE:		accpntUtils.asm

AUTHOR:		Eric Weber, Apr 24, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT ParseStandardProperty   Possibly decode a standard property
				reference

    GLB AccessPointEntry        Entry point for library

    INT AccessPointEnumCallback Add an access point to the chunk array

    INT BuildEntryCategory      Build the category for an type's active entry

    INT BuildEntryCategoryDirect      Build the category for an entry

    INT CheckIfEntryExists      See if an access point is defined

    INT WordToAscii             Convert a word to hex notation

    INT WordToAsciiDBCS         Convert a word to DBCS hex notation

    INT AsciiToWord             Convert 4 hex ASCII digits into a binary
				word

    INT UpdateContents          Update the table of contents

    INT UpdateContentsCallback  Write one entry to the contents string
				section

    INT AllocateEntry           Add ax to the list of entry points

    INT FreeEntryMem            Remove ax from the list of access points

    INT FreeEntryFile           Remove an entry from the list in the init
				file

    INT MatchEntryID            Compare string section to desired ID

    INT GetTypeLow
    INT	ValidateEntry

	GenerateCreationNotice
	GenerateDeletionNotice
	GenerateMultiDeletionNotice
	GenerateChangeNotice
	GenerateLockNotice
	GenerateNoticeCommon
	AccessPointAllocNotice
	AccessPointSendNotice

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95   	Initial revision


DESCRIPTION:
	
		

	$Id: accpntUtils.asm,v 1.26 98/02/14 00:56:32 simon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment

categoryBase	char	"accessPoint"
categoryExt	char	"0000",0

apMutex		Semaphore <1,0>

autoPrefix	char	"auto";
autoBuffer	char	32 dup (0);

idata	ends


;*****************************************************************************
;			      LMEM BLOCK
;*****************************************************************************

;
; Chunk array to hold the list of access points
;
AccessPointBlock	segment lmem LMEM_TYPE_GENERAL

AccessPointArray	chunk	ChunkArrayHeader
	ChunkArrayHeader <0, size word, 0, size ChunkArrayHeader>
AccessPointArray	endc

;
; Chunk array to hold the types of the access points
;
CheckHack	<size AccessPointType eq size word>
AccessTypeArray	chunk	ChunkArrayHeader
	ChunkArrayHeader <0, size word, 0, size ChunkArrayHeader>
AccessTypeArray	endc

;
; Chunk array to hold IDs of locked access points.
;
AccessPointLockArray	chunk ChunkArrayHeader
	ChunkArrayHeader <0, size word, 0, size ChunkArrayHeader>
AccessPointLockArray	endc

AccessPointBlock	ends


;*****************************************************************************
;			CODE SEGMENT CONSTANTS
;*****************************************************************************

DefAccessPointStandard	macro	string, cnst
.assert ($-accessPointStandards) eq cnst, <string table is corrupted>
.assert (type string eq char)
                nptr.char        string
endm

ApiCode	segment resource

accessPointStandards   label nptr.char
DefAccessPointStandard	standardName		APSP_NAME
DefAccessPointStandard	standardPhone		APSP_PHONE
DefAccessPointStandard	standardUser		APSP_USER
DefAccessPointStandard	standardSecret		APSP_SECRET
DefAccessPointStandard	standardAddress		APSP_ADDRESS
DefAccessPointStandard	standardMask		APSP_MASK
DefAccessPointStandard	standardGateway		APSP_GATEWAY
DefAccessPointStandard	standardDns1		APSP_DNS1
DefAccessPointStandard	standardDns2		APSP_DNS2
DefAccessPointStandard	standardDataBits	APSP_DATA_BITS
DefAccessPointStandard	standardStopBits	APSP_STOP_BITS
DefAccessPointStandard	standardParity		APSP_PARITY
DefAccessPointStandard	standardDuplex		APSP_DUPLEX
DefAccessPointStandard	standardModemInit	APSP_MODEM_INIT
DefAccessPointStandard	standardBackspace	APSP_BS
DefAccessPointStandard	standardHostname	APSP_HOSTNAME
DefAccessPointStandard	standardInternetAccPnt	APSP_INTERNET_ACCPNT
DefAccessPointStandard	standardPromptSecret	APSP_PROMPT_SECRET
DefAccessPointStandard	standardUseLoginApp	APSP_USE_LOGIN_APP
DefAccessPointStandard	standardLoginAppName	APSP_LOGIN_APP_NAME
DefAccessPointStandard	standardScriptName	APSP_SCRIPT_NAME
DefAccessPointStandard	standardCCardName	APSP_CCARD_NAME
DefAccessPointStandard	standardCCardAccess	APSP_CCARD_ACCESS
DefAccessPointStandard	standardCCardID		APSP_CCARD_ID
DefAccessPointStandard	standardCCardPrefix	APSP_CCARD_PREFIX
DefAccessPointStandard	standardCCardSequence	APSP_CCARD_SEQUENCE
DefAccessPointStandard	standardCompression	APSP_COMPRESSION
DefAccessPointStandard	standardBearerCapability APSP_BEARER_CAPABILITY
DefAccessPointStandard	standardLineEnd		APSP_LINE_END
DefAccessPointStandard	standardUseDialOptions	APSP_USE_DIALING_OPTIONS
DefAccessPointStandard	standardLocalDialOptions APSP_LOCAL_DIALING_OPTIONS

; make sure we got them all
.assert ($-accessPointStandards) eq AccessPointStandardProperty, <string table is incomplete>

;
; each of the string constants is preceded by its size, to make
; copying easier
;
DefAccessPointString	macro	name,string
	.assert (size name lt size autoBuffer)
		word	size name
	name	char	string,0
endm
		
DefAccessPointString	standardName		"name"
DefAccessPointString	standardPhone		"phone"
DefAccessPointString	standardUser		"user"
DefAccessPointString	standardSecret		"secret"
DefAccessPointString	standardAddress		"ipaddr"
DefAccessPointString	standardMask		"ipmask"
DefAccessPointString	standardGateway		"ipgate"
DefAccessPointString	standardDns1		"dns1"
DefAccessPointString	standardDns2		"dns2"
DefAccessPointString	standardDataBits	"dataBits"
DefAccessPointString	standardStopBits	"stopBits"
DefAccessPointString	standardParity		"parity"
DefAccessPointString	standardDuplex		"duplex"
DefAccessPointString	standardModemInit	"modemInit"
DefAccessPointString	standardBackspace	"backspace"
DefAccessPointString	standardHostname	"hostname"
DefAccessPointString	standardInternetAccPnt	"internetAccPnt"
DefAccessPointString	standardPromptSecret	"promptSecret"
DefAccessPointString	standardUseLoginApp     "useLoginApp"
DefAccessPointString	standardLoginAppName    "loginApp"
DefAccessPointString	standardScriptName      "script"
DefAccessPointString	standardCCardName	"ccardName"
DefAccessPointString	standardCCardAccess	"ccardAccess"
DefAccessPointString	standardCCardID		"ccardID"
DefAccessPointString	standardCCardPrefix	"ccardPrefix"
DefAccessPointString	standardCCardSequence	"ccardSequence"
DefAccessPointString	standardCompression	"compression"
DefAccessPointString	standardBearerCapability "bearerCapability"
DefAccessPointString	standardLineEnd		"lineEnd"
DefAccessPointString	standardUseDialOptions	"useDialingOptions"
DefAccessPointString	standardLocalDialOptions "localDialingOptions"


initCategory	char	"accpnt",0
initIDKey	char	"prevID",0
initContents	char	"contents",0

;*****************************************************************************
;			       ROUTINES
;*****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseStandardProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly decode a standard property reference

CALLED BY:	Internal
PASS:		cx:dx	- far pointer to string, -OR-
			 cx =0, dx = AccessPointStandardProperty
RETURN:		cx:dx	- far pointer to string
		bx	- AccessPointStandardProperty, if one was passed
			  APSP_UNDEFINED if not
DESTROYED:	nothing
SIDE EFFECTS:	may store temporary data in dgroup

PSEUDO CODE/STRATEGY:
	database semaphore must be locked to prevent conflicts over the
	dgroup variable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseStandardProperty	proc	near
		.enter
		jcxz	standard
	;
	; if a string was passed, it can't be in a movable XIP code segment
	; since this library is also movable XIP code
	;
		mov	bx, APSP_UNDEFINED
		Assert	fptrXIP, cxdx
		jmp	done
	;
	; look up the enum in the string pointer table to find the
	; real string to use
	;
standard:
		test	dx, APSP_AUTOMATIC
		pushf
		and	dx, not APSP_AUTOMATIC
		Assert	etype, dx, AccessPointStandardProperty
		mov	bx, dx
		mov	cx, cs
		mov	dx, cs:[accessPointStandards][bx]
		Assert	fptr, cxdx
		popf				; z clear if APSP_AUTOMATIC
		jz	done
	;
	; if the APSP_AUTOMATIC bit is set, append cx:dx to
	; the string "temp" in dgroup and return that instead
	;
temp::
		push	ds,si,es,di
		mov	ds, cx
		mov	si, dx				; ds:si = CS string
		GetDgroup es,bx
		mov	di, offset es:[autoBuffer]	; es:di = buffer
		mov	cx, ds:[si][-(size word)]	; cx = size of ds:si
		rep	movsb
		mov	cx, es
		mov	dx, offset es:[autoPrefix]
		pop	ds,si,es,di
done:
		.leave
		ret
ParseStandardProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for library

CALLED BY:	GLOBAL
PASS:		di	- LibraryCallType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	It is necessary that the table of contents be kept entirely
	in the primary init file.  Some of the problems which would
	have to be addressed if this restriction were removed include:
		* how to selectively write only the RAM based entries
		  in UpdateContents
		* how to maintain the ordering of ROM and RAM entries

	Keeping the access point's data in the secondary init file
	is possible.  The only annoying side effect is that if the 
	user deletes a property, the original value will pop up again.
	If they delete the whole entry, it will disappear, but if
	the ID numbers wrap and that ID is reused, the old data
	will reappear in the new access point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointEntry	proc	far
		ForceRef AccessPointEntry
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		cmp	di, LCT_ATTACH
		jne	done
	;
	; read in all the access point ids
	;
		mov	bx, handle AccessPointArray
		call	MemLock
		mov	bx, ax
		
		mov	cx, cs
		mov	ds, cx
		mov	si, offset initCategory		; ds:si = category
		mov	dx, offset initContents		; cx:dx = key
		mov	di, cs
		mov	ax, offset AccessPointEnumCallback  ; di:ax = callback
		mov	bp, mask IFRF_FIRST_ONLY
		call	InitFileEnumStringSection
		
		mov	bx, handle AccessPointArray
		call	MemUnlock
done:
		clc
		.leave
		ret
AccessPointEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an access point to the chunk array

CALLED BY:	AccessPointEntry via InitFileEnumStringSection
PASS:		ds:si	- access point id string
		cx	- length of section
		bx	- segment of AccessPointArray
RETURN:		carry clear
		bx	- segment of AccessPointArray
DESTROYED:	ax, cx, dx, di, si, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointEnumCallback	proc	far
		uses	ds
		.enter
	;
	; verify that we have exactly eight "characters"
	;
		cmp	cx, 8
		ERROR_NE INVALID_ACCESS_POINT_IN_INIT_FILE		
	;
	; convert the hex digits into two words
	;
		call	AsciiToWord		
		ERROR_C INVALID_ACCESS_POINT_IN_INIT_FILE		
		mov	cx, ax				; cx = access id
		call	AsciiToWord			; ax = access type
		ERROR_C INVALID_ACCESS_POINT_IN_INIT_FILE		
	;
	; store the information
	;
		mov	ds, bx
		mov	si, offset AccessPointArray
		call	ChunkArrayAppend		; ds:di = new slot
		mov	ds:[di], cx

		mov	si, offset AccessTypeArray
		call	ChunkArrayAppend		; ds:di = new slot
		mov	ds:[di], ax
		mov	bx, ds
		
		clc
		.leave
		ret
AccessPointEnumCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildEntryCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the category for an entry

CALLED BY:	INTERNAL
PASS:		ax	- entry number
RETURN:		ds:si	- category for init file
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95    	Initial version
	Mzhu    2/2/99		Change to use the active accesspoint

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildEntryCategory	proc	near
		uses	bx,di,es,ax
		.enter

	;
	; convert ax into hex
	;
		GetDgroup es, bx
		mov	di, offset categoryExt
		call	WordToAscii
	;
	; return category
	;
		segmov	ds, es, bx
		mov	si, offset categoryBase

		.leave
		ret
BuildEntryCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfEntryExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if an access point is defined

CALLED BY:	AccessPointCreateEntry
PASS:		ax	- entry number
RETURN:		carry	- set if entry does not exist
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfEntryExists	proc	near
		uses	bx,cx,di,es
		.enter
	;
	; lock the array
	;
		push	ax
		mov	bx, handle AccessPointArray
		call	MemLock
		mov	es, ax
		pop	ax
	;
	; search for the requested key
	;
		mov	di, offset AccessPointArray
		mov	di, es:[di]
		mov	cx, es:[di].CAH_count
		add	di, es:[di].CAH_offset
		repne	scasw
		jz	done				; z => !c
		stc
done:
		call	MemUnlock
		.leave
		ret
CheckIfEntryExists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a word to hex notation

CALLED BY:	BuildLoadRequestString
PASS:		ax	- input buffer
		es:di	- output buffer
RETURN:		es:di	- points past converted data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	swap al and ah
	save al
	al.low = al.high
	al.high = 0
	es:[di]++ = nibbles[al]
	restore al
	al.high = 0
	es:[di]++ = nibbles[al]
	repeat once

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nibbles		db	"0123456789ABCDEF"
WordToAscii	proc	near
		uses	ax,bx,cx
		.enter
EC <		call	validate					>
		mov	bx, offset nibbles
		mov	cx,2
top:
		xchg	al, ah
	;
	; compute first nibble
	;
		push	ax
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		stosb
	;
	; compute second nibble
	;
		pop	ax
		and	al, 0fh
		xlatb	cs:
		stosb
		loop	top
done::
		.leave
		ret
if ERROR_CHECK
validate:
	;
	; Ensure the pointers are valid at the start
	;
		Assert	fptr esdi
	;
	; Ensure that the pointers will be valid when we're done.
	;
		push	di
		add	di, 3
		Assert	fptr esdi
		pop	di
		retn
endif		

WordToAscii	endp

if	DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WordToAsciiDBCS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a word to a DBCS hex string, not including null.

CALLED BY:	UpdateContentsCallback, FreeEntryFile
PASS:		ax	- input buffer
		es:di	- output buffer
RETURN:		es:di	- points past converted data (DBCS)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		call	WordToAscii

		start at end of SBCS string
		change direction flag
start:
		load byte
		store word
		loop start

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WordToAsciiDBCS	proc	near
		uses	ax,cx,si,ds,es
		.enter
	;
	; Convert the word into an SBCS string, then pad the string.
	;
		call	WordToAscii		; es:di - pointing past
	;
	; Setup src ptr to end of SBCS string, and dst ptr to end of
	; buffer.
	;
		movdw	dssi, esdi
		dec	si			; ds:si - src string
		add	di, 2			; es:di - dst string
	;
	; Setup direction flag and loop variables
	;
		mov	cx, 4			; 4 chars
		clr	ah			; 0 paddings
		std				; backward string ops

padLoop:
		lodsb				; al <- char
		stosw
		loop	padLoop

		cld				; restore direction
		add	di, 10			; past end of string

		.leave
		ret
WordToAsciiDBCS	endp
endif	; DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AsciiToWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 4 hex ASCII digits into a binary word

CALLED BY:	AccessPointEnumCallback
PASS:		ds:si	- 4 hex digits
RETURN:		ax	- binary value
		ds:si	- points past converted data
		carry set if invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AsciiToWord	proc	near
		uses	bx,cx,di
		.enter
		mov	cx,4
top:
	;
	; shift over the existing value by 4 bits (one hex digit)
	;
		shl	bx
		shl	bx
		shl	bx
		shl	bx
	;
	; read the next "byte" and try to convert it as a numeric
	;
SBCS <		lodsb			; get next byte from ds:si >
DBCS <		lodsw			; ignore ah		>
		sub	al, '0'
		js	invalid
		cmp	al, 9
		jbe	bottom
notDigit::
	;
	; al is not a digit, so try analyzing it as an uppercase alpha
	;
		sub	al, 'A' - '0'
		js	invalid
		cmp	al, 6
		jbe	doAdd
notUpper::
	;
	; al is neither a digit nor uppercase alpha
	; maybe its lowercase alpha
	;
		sub	al, 'a' - 'A'
		cmp	al,6
		ja	invalid
doAdd:
		add	al,10
bottom:
	;
	; we've successfully converted al
	; store it and go to next byte
	;
		or	bl, al
		loop	top
		mov	ax, bx
		clc
done:
		.leave
		ret
invalid:
		stc
		jmp	done

AsciiToWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the table of contents

CALLED BY:	AllocateEntry
PASS:		ds	- segment of AccessPointBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateContents	proc	near
		uses	ax,bx,cx,dx,di,bp,es
		.enter
	;
	; remove old contents
	;
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	si, offset initCategory		; ds:si = category
		mov	dx, offset initContents		; cx:dx = key
		call	InitFileDeleteEntry
		pop	ds
	;
	; make sure both arrays are the same size
	; initialize si in both EC and non-EC
	;
EC <		mov	si, offset AccessTypeArray			>
EC <		call	ChunkArrayGetCount		; cx = count	>
EC <		mov	ax, cx						>
		mov	si, offset AccessPointArray
EC <		call	ChunkArrayGetCount				>
EC <		cmp	ax, cx						>
EC <		ERROR_NE CORRUPT_ACCESS_POINT_INDEX			>
	;
	; write out array
	;
		mov	bx, cs
		mov	di, offset UpdateContentsCallback
		
		call	ChunkArrayEnum
		AccpntCommit
done::
		.leave
		ret
UpdateContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateContentsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one entry to the contents string section

CALLED BY:	UpdateContents (via ChunkArrayEnum)
PASS:		ds:di	- access point ID
		*ds:si	- AccessPointArray
RETURN:		carry clear
DESTROYED:	ax,cx,dx,si,di,es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/30/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateContentsCallback	proc	far
		uses	ds
		.enter
        ;
        ; fetch both array values
        ;
		mov	ax, ds:[di]			; ax = ID
		sub	di, ds:[si]
		mov	si, offset AccessTypeArray
		add	di, ds:[si]
		mov	dx, ds:[di]			; dx = type
	;
	; convert them into a single ASCII string
	;
SBCS <		sub     sp, 10			>	; 2*size word + null
DBCS <		sub	sp, 18			>	; 4*size word + null
                segmov  es, ss
                mov     di, sp
SBCS <		call    WordToAscii		>	; convert ID / move di
DBCS <		call	WordToAsciiDBCS		>
		mov	ax, dx
SBCS <		call	WordToAscii		>	; convert type
DBCS <		call	WordToAsciiDBCS		>
		clr	ax
		stosw					; add a NULL
		mov	di, sp
        ;
        ; add the entry point to the init file
        ;
                mov     cx, cs
                mov     ds, cx
                mov     si, offset initCategory         ; ds:si = category
                mov     dx, offset initContents         ; cx:dx = key
                call    InitFileWriteStringSection
SBCS <		add     sp, 10			>	; free stack buffer
DBCS <		add	sp, 18			>
	;
	; continue the enumeration
	;
		clc
		.leave
		ret
UpdateContentsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ax to the list of entry points

CALLED BY:	AccessPointCreateEntry
PASS:		ax	- entry id
		bx	- id to place before
		dx	- type of entry
RETURN:		carry	- set if bx not in array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateEntry	proc	near
		uses	bx,cx,dx,si,di,ds,es
		.enter
	;
	; lock down the contents array
	;
		push	ax, bx
		mov	bx, handle AccessPointArray
		call	MemLock
		mov	ds, ax
		mov	es, ax
		mov	si, offset AccessPointArray
		pop	bx, ax				; swap ax and bx
	;
	; make room in the ID array for a new entry
	;
		tst	ax
		jnz	search
		call	ChunkArrayAppend		; ds:di = new slot
		jmp	foundIt
search:
		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count
		add	di, ds:[di].CAH_offset
		repne	scasw
		jne	notFound
		dec	di
		dec	di
		call	ChunkArrayInsertAt		; ds:di = new slot
foundIt:
		mov	ds:[di], bx
	;
	; now insert at exactly the same spot in the type array
	;
		sub	di, ds:[si]		; offset from top of CAH
		mov	si, offset AccessTypeArray
		add	di, ds:[si]		; position in other array
		call	ChunkArrayInsertAt	; ds:di = new slot
		mov	ds:[di], dx		; store type
	;
	; write out both arrays to the init file
	;
		call	UpdateContents
		mov	ax, bx
		clc
notFound:
		mov	bx, handle AccessPointArray
		call	MemUnlock
		.leave
		ret
AllocateEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeEntryMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ax from the list of access points

CALLED BY:	AccessPointDestroyEntry
PASS:		ax	- access point id
RETURN:		dx	- access point type
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeEntryMem	proc	near
		uses	bx,cx,si,di,ds,es
		.enter
	;
	; lock the array
	;
		push	ax
		mov	bx, handle AccessPointArray
		call	MemLock
		mov	es, ax
		mov	ds, ax
		pop	ax
	;
	; search for the requested key in cache
	;
		mov	si, offset AccessPointArray
		mov	di, es:[si]
		mov	cx, es:[di].CAH_count
		mov	dx, cx
		add	di, es:[di].CAH_offset
		repne	scasw
		jne	done
	;
	; remove it from the chunk array
	;
		dec	di
		dec	di
		push	di
		call	ChunkArrayDelete
		pop	di
	;
	; remove it from the other chunk array
	;
		sub	di, ds:[si]
		mov	si, offset AccessTypeArray
		add	di, ds:[si]
		mov	dx, ds:[di]			; remember type
		call	ChunkArrayDelete
done:
		mov	bx, handle AccessPointArray
		call	MemUnlock
		.leave
		ret
FreeEntryMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeEntryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an entry from the list in the init file

CALLED BY:	AccessPointDestroyEntry
PASS:		ax	- entry to be freed
RETURN:		carry set if entry not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeEntryFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; build string form of id number
	;
SBCS <		sub	sp, 4				; size word	>
DBCS <		sub	sp, 8						>
		segmov	es, ss
		mov	di, sp
SBCS <		call	WordToAscii					>
DBCS <		call	WordToAsciiDBCS					>
		mov	bx, sp				; es:bx = string
	;	
	; enumerate the entries to locate the one of interest
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset initCategory 	; ds:si = category
		mov	dx, offset initContents 	; cx:dx = key
		mov	di, cs
		mov	ax, offset MatchEntryID
		mov	bp, mask IFRF_FIRST_ONLY
		call	InitFileEnumStringSection
		cmc
		jc	done
	;
	; delete the entry we found
	;
		mov	ax, bx
		call	InitFileDeleteStringSection
done:
		lahf
SBCS <		add	sp, 4						>
DBCS <		add	sp, 8						>
		sahf
		.leave
		ret
FreeEntryFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchEntryID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare string section to desired ID

CALLED BY:	FreeEntryFile via InitFileEnumStringSection
PASS:		es:bx	- string to match
		ds:si	- string section from init file
		cx	- size of string section
		dx	- current index
RETURN:		if no match
			carry clear
			bx unchanged
		if string matches
			carry set
			bx = index
DESTROYED:	ax,cx,dx,di,si,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchEntryID	proc	far
		.enter
	;
	; verify that we have exactly eight characters
	;
EC <		cmp	cx, 8						>
EC <		ERROR_NE INVALID_ACCESS_POINT_IN_INIT_FILE		>
	;
	; compare the first four bytes
	;
		mov	di, bx
		cmpsw
		jne	noMatch
		cmpsw
		je	match
noMatch:
		clc
done:
		.leave
		ret
	;
	; it matches, return this index
	;
match:
		mov	bx, dx
		stc
		jmp	done
MatchEntryID	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

SYNOPSIS:	Get the access point type

CALLED BY:	INTERNAL
PASS:		ax	- access point ID
RETURN:		dx	- AccessPointType (0 if not found)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeLow	proc	near
		uses	ax,bx,cx,si,di,bp,es
		.enter
	;
	; lock the index array
	;
		mov	bx, handle AccessPointArray
		push	ax
		call	MemLock
		mov	es, ax
		pop	ax
	;
	; search for the desired ID
	;
		clr	dx
		mov	si, offset AccessPointArray
		mov	di, es:[si]
		mov	cx, es:[di].CAH_count
		add	di, es:[di].CAH_offset
		repne	scasw
		jne	cleanup
	;
	; get the type of the entry
	;
		dec	di
		dec	di
		sub	di, es:[si]
		mov	si, offset AccessTypeArray
		add	di, es:[si]
		mov	dx, es:[di]
	;
	; clean up and exit
	;
cleanup:
		mov	bx, handle AccessPointArray
		call	MemUnlock
		.leave
		ret
GetTypeLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify an entry exists

CALLED BY:	INTERNAL
PASS:		ax	- access point ID
RETURN:		carry set if not defined
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This is called from EC code for operations which would fail
	anyway if the access point does not exist, and from both EC
	and NEC for AccessPointSet*Property, which would otherwise
	create a category/key for the invalid access point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateEntry	proc	near
		uses	dx
		.enter
		call	GetTypeLow
		tst_clc	dx
		jnz	done
		WARNING	INVALID_ACCESS_POINT_ID
		stc
done:
		.leave
		ret
ValidateEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateCreationNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify interested parties of a new access point

CALLED BY:	AccessPointCreateEntry
PASS:		ax	- new entry ID
		dx	- new entry type
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateCreationNotice	proc	near
		uses	cx,bp
		.enter
		mov	bp, APCT_CREATE
		clr	cx
		call	GenerateNoticeCommon
		.leave
		ret
GenerateCreationNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateDeletionNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify interested parties that an access point was deleted

CALLED BY:	AccessPointDestroyEntry
PASS:		ax	- entry ID
		dx	- entry type
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateDeletionNotice	proc	near
		uses	cx,bp
		.enter
		mov	bp, APCT_DESTROY
		clr	cx
		call	GenerateNoticeCommon
		.leave
		ret
GenerateDeletionNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateMultiDeletionNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify interested parties that a group of access points
		was deleted.

CALLED BY:	AccessPointMultiDestroyDone

PASS:		ax	= block of IDs
		dx	= entry type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateMultiDeletionNotice	proc	near
		uses	ax, bx, cx, bp, si, ds
		.enter

		mov	bx, ax
		call	MemLock
		mov	ds, ax
		mov	ax, ds:0		; number of IDs
		mov	cx, ax
		shl	cx			; size of ID array
		mov	si, size word		; pointer to IDs
		
		mov	bp, APCT_MULTI_DESTROY
		call	GenerateNoticeCommon

		call	MemFree
		.leave
		ret
GenerateMultiDeletionNotice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateChangeNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify interested parties of a property change

CALLED BY:	AccessPointSetIntegerProperty,
		AccessPointSetStringProperty,
		AccessPointDestroyProperty

PASS:		ax	- access ID
		cx:dx	- property name
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateChangeNotice	proc	near
		uses	cx,bp,si,di,ds,es
		.enter
		movdw	dssi, cxdx
		movdw	esdi, cxdx
	;
	; get the access point type
	;
		call	GetTypeLow		; dx = type
		mov	bp, APCT_PROPERTY
	;
	; compute size of property, including null
	;
		push	ax
		LocalStrSize includeNull
		pop	ax
	;
	; call common routine
	;
		call	GenerateNoticeCommon
		.leave
		ret
GenerateChangeNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateLockNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify interested parties that an access point has
		become locked/unlocked.

CALLED BY:	AccessPointLock
		AccessPointUnlock

PASS:		ax	= access ID
		dx	= entry type (AccessPointType)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/18/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateLockNotice	proc	near
		uses	cx, bp
		.enter

		mov	bp, APCT_LOCK
		clr	cx
		call	GenerateNoticeCommon

		.leave
		ret
GenerateLockNotice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateNoticeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a GWNT_ACCESS_POINT_CHANGE

CALLED BY:	GenerateCreationNotice,
		GenerateDeletionNotice,
		GenerateChangeNotice

PASS:		ax	- access ID
		dx	- AccessPointType
		bx	- AccessPointStandardProperty
		bp	- AccessPointChangeType
		cx	- property name or id list size (including null)
		ds:si	- property name or id list
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateNoticeCommon	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; allocate a block
	;
		push	bx
		call	AccessPointAllocNotice	; es = sptr of block
						; bx = hptr of block
	;
	; initialize the block
	;
		mov	es:[APCD_changeType], bp
		mov	es:[APCD_id], ax
		mov	es:[APCD_accessType], dx
		pop	es:[APCD_stdProperty]
		jcxz	send
	;
	; copy the property name or ID array
	;
		mov	di, offset APCD_property
		rep	movsb			
	;
	; send it off
	;
send:
		call	AccessPointSendNotice
		.leave
		ret
GenerateNoticeCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointAllocNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate a block for a notification

CALLED BY:	GenerateNoticeCommon
PASS:		cx = size of property name
		
RETURN:		es = segment of block
		bx = handle of block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointAllocNotice	proc	near
		uses	ax,cx
		.enter
	;
	; allocate a shared block
	;
		mov	ax, cx
		add	ax, size AccessPointChangeDescription
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	es, ax
	;
	; set the refcount to 1
	;
		mov	ax,1
		call	MemInitRefCount
		.leave
		ret
AccessPointAllocNotice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSendNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification

CALLED BY:	GenerateNoticeCommon
PASS:		bx	- locked notification block
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,di
SIDE EFFECTS:	destroys any segment pointing to block

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSendNotice	proc	near
		.enter
		call	MemUnlock
	;
	; record an event
	;
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_ACCESS_POINT_CHANGE
		mov	bp, bx
		mov	di, mask MF_RECORD
		call	ObjMessage	; di = event handle
	;
	; dispatch the event
	;
		mov	cx, di
		mov	dx, bx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_ACCESS_POINT_CHANGE
		mov	bp, mask GCNLSF_FORCE_QUEUE
		call	GCNListSend
		.leave
		ret
AccessPointSendNotice	endp

ApiCode	ends
