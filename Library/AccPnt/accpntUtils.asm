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

    INT ReloadContents          Load the merged access point list

    INT BuildEntryCategory      Build the category for an type's active entry

    INT BuildEntryCategoryDirect      Build the category for an entry

    INT CheckIfEntryExists      See if an access point is defined

    INT WordToAscii             Convert a word to hex notation

    INT WordToAsciiDBCS         Convert a word to DBCS hex notation

    INT AsciiToWord             Convert 4 hex ASCII digits into a binary
				word

    INT AllocateEntry           Add an access point to the index
    INT FreeEntry               Remove an access point from the index
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
initDisabled	char	"contents.disabled",0

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
	Load the merged list of factory and local access points.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointEntry	proc	far
		ForceRef AccessPointEntry
		cmp	di, LCT_ATTACH
		jne	done
		call	ReloadContents
done:
		clc
		ret
AccessPointEntry	endp

ReloadContents	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds, es
	.enter

		mov	bx, handle AccessPointArray
		call	MemLock
		mov	ds, ax
		mov	si, offset AccessPointArray
		call	ChunkArrayZero
		mov	si, offset AccessTypeArray
		call	ChunkArrayZero
		segmov	es, ds

		mov	cx, cs
		mov	ds, cx
		mov	si, offset initCategory
		mov	dx, offset initContents
		mov	di, cs
		mov	ax, offset AccessPointEnumCallback
		clr	bp
		call	InitFileEnumStringSection
		mov	bx, handle AccessPointArray
		call	MemUnlock

	.leave
		ret
ReloadContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an access point to the chunk array

CALLED BY:	ReloadContents via InitFileEnumStringSection
PASS:		ds:si	- access point id string
		cx	- length of section
		es	- segment of AccessPointArray
RETURN:		carry clear
		es	- segment of AccessPointArray
DESTROYED:	ax, cx, dx, di, si, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	Keep the first valid record for each ID.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointEnumCallback	proc	far
		call	ParseContentsRecord
		jc	done
		call	FindEntry
		jnc	done

	;
	; store the information
	;
		segmov	ds, es
		mov	si, offset AccessPointArray
		call	ChunkArrayAppend		; ds:di = new slot
		mov	ds:[di], ax

		mov	si, offset AccessTypeArray
		call	ChunkArrayAppend		; ds:di = new slot
		mov	ds:[di], dx
		segmov	es, ds				; the block can move
done:
		clc
		ret
AccessPointEnumCallback	endp

; Convert a string section at DS:SI (CX characters). Return AX = ID,
; DX = type, or set carry if the record is invalid.
ParseContentsRecord	proc	near
		cmp	cx, 8
		jne	invalid
		call	AsciiToWord
		jc	invalid
		tst	ax
		jz	invalid
		mov	dx, ax
		call	AsciiToWord
		jc	invalid
		cmp	ax, APT_INTERNET
		jb	invalid
		cmp	ax, APT_CALLING_CARD
		ja	invalid
		xchg	ax, dx
		clc
		ret
invalid:
		stc
		ret
ParseContentsRecord	endp


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
	uses	bx, di, es
	.enter

		push	ax
		mov	bx, handle AccessPointArray
		call	MemLock
		mov	es, ax
		pop	ax
		call	FindEntry
		call	MemUnlock

	.leave
		ret
CheckIfEntryExists	endp

; Test for AX in the locked AccessPointBlock in ES. Set carry if missing.
FindEntry	proc	near
	uses	cx
	.enter

		mov	di, offset AccessPointArray
		mov	di, es:[di]
		mov	cx, es:[di].CAH_count
		jcxz	missing
		add	di, es:[di].CAH_offset
		repne	scasw
		jne	missing
		clc
		jmp	done
missing:
		stc
done:
	.leave
		ret
FindEntry	endp



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

CALLED BY:	AllocateEntry
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

CALLED BY:	ParseContentsRecord
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
DBCS <		lodsw						>
DBCS <		tst	ah			; require an ASCII digit >
DBCS <		jnz	invalid					>
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
		cmp	al, 5
		jbe	doAdd
notUpper::
	;
	; al is neither a digit nor uppercase alpha
	; maybe its lowercase alpha
	;
		sub	al, 'a' - 'A'
		cmp	al, 5
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
		AllocateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append an entry to the local INI list.
CALLED BY:	AccessPointCreateEntry
PASS:		ax - new ID, bx - location ID (0 for none), dx - type
		ds:si - category, cx - key segment
RETURN:		ax - new ID, or 0 with carry set on error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateEntry	proc	near
	uses	dx, di, es
entryText	local	9 dup (TCHAR)
	.enter

		tst	bx
		jz	appendEntry
		xchg	ax, bx
		call	CheckIfEntryExists
		xchg	ax, bx
		jc	failed

appendEntry:
		push	ax
		segmov	es, ss
		lea	di, ss:[entryText]
SBCS <		call	WordToAscii					>
DBCS <		call	WordToAsciiDBCS				>
		mov	ax, dx
SBCS <		call	WordToAscii					>
DBCS <		call	WordToAsciiDBCS				>
		clr	ax
		LocalPutChar esdi, ax
		lea	di, ss:[entryText]
		mov	dx, offset initContents
		call	InitFileWriteStringSection
		call	ReloadContents
		pop	ax
		call	CheckIfEntryExists
		jnc	done
failed:
		clr	ax
		stc
done:
	.leave
		ret
AllocateEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an entry from the merged INI list.
CALLED BY:	AccessPointDestroyEntryDirect, AccessPointDestroyEntryNoNotify
PASS:		ax - ID to remove
RETURN:		dx - entry type, or carry set on error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeEntry	proc	near
	uses	bx, cx, si, di, bp, ds
	.enter

		call	GetTypeLow
		tst	dx
		stc
		jz	done

		push	dx
		mov	cx, cs
		mov	ds, cx
		mov	si, offset initCategory
		mov	dx, offset initContents
		clr	bp
		mov	di, 2
	;
	; A factory deletion can reveal a local copy from an older INI.
	;
findEntry:
		call	FindContentsEntry
		jc	refresh
		tst	di
		jz	refresh
		dec	di
		xchg	ax, bx
		call	InitFileDeleteStringSection
		xchg	ax, bx
		jmp	findEntry

refresh:
		call	ReloadContents
		call	CheckIfEntryExists
		cmc
		pop	dx
done:
	.leave
		ret
FreeEntry	endp

; Find the ID in AX in the requested list. Return its INI index in BX,
; or set carry if it is missing. The index includes records the cache skips.
FindContentsEntry	proc	near
	uses	ax, di, es
	.enter

		mov	bx, ax
		mov	di, cs
		mov	ax, offset MatchEntryID
		call	InitFileEnumStringSection
		cmc

	.leave
		ret
FindContentsEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchEntryID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare string section to desired ID

CALLED BY:	FreeEntryFile via InitFileEnumStringSection
PASS:		bx	- access point ID to match
		ds:si	- string section from init file
		cx	- size of string section
		dx	- current index
RETURN:		if no match
			carry clear
			bx unchanged
		if the ID matches
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
		push	dx
		call	ParseContentsRecord
		pop	dx
		jc	noMatch
		cmp	ax, bx
		jne	noMatch
		mov	bx, dx
		stc
		ret
noMatch:
		clc
		ret
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
