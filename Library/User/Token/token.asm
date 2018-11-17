Comment @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Token
FILE:		token.asm

AUTHOR:		Brian Chin,  November 1989

ROUTINES:
	Name			Description
	----			-----------
GLB	TOKENOPENLOCALTOKENDB	Open the local token database file read/write.
GLB	TOKENCLOSELOCALTOKENDB	Close the local token database file.
GLB	TokenDefineToken	add token to database
GLB	TokenGetTokenInfo	get info about token in database
GLB	TokenLookupMoniker	get moniker for token
GLB	TokenLoadMoniker	load moniker for token
GLB	TokenRemoveToken	remove token from database
GLB	TokenGetTokenStats	get stats for token
GLB	TokenLoadToken		load TokenEntry structure for token
GLB	TokenLockTokenMoniker	lock moniker for access
GLB	TokenUnlockTokenMoniker	unlock moniker
GLB	TokenListTokens		make a list of tokens in the token.db

EXT	TokenInitTokenDB	Open the local token database file
				 read/write and, if the path for a
				 globally shared token database appears
				 in the .INI file, open that file 
				 shared-multiple read-only.
EXT	TokenExitTokenDB	Close/update token database

INT	NoTokenDB?		Check value of "noTokenDatabase" key
				 if it's in the .INI file
INT	OpenSharedTokenDB	Open the globally shared token database
				 file, if any, shared-multiple read-only.
INT	GetToken		get TokenEntry from token database
INT	FindToken		find token in token database
INT	FindTokenInLocalOrSharedFile
INT	CloseTokenDBFile	Close token database file
INT	AddTokenEntry		Add token to database
INT	AddMonikers		Add a token's monikers to database
INT	AllocateTokenDBItem	Allocate a DB item for storing passed
				lmem chunk
INT	GetGroup		Get/create group for a moniker or moniker list
INT	CreateMonikerGroupEntry	Add a new MonikerGroupEntry to end of
				map block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial revision
	jenny	1/ 6/92		Rewrote to use local/shared files and
				 map block

DESCRIPTION:
	Routines to manage a database of visual monikers.  The visual
	monikers will be used as icons for applications and datafiles
	in the Desktop Enviroment.
		

	$Id: token.asm,v 1.1 97/04/07 11:46:33 newdeal Exp $

-----------------------------------------------------------------------------@

ALLOW_READERS_AND_WRITERS equ 0
;
; This code was initially written to allow a bunch of clients to
; access the token database read-only, while a single client accesses
; it read/write.  The problem with this approach is that, for each
; read-only client, the entire token database will be loaded into
; memory, hogging gobs of swap space, etc.   In addition, the
; VMGrabExclusive/VMReleaseExclusive mechanism must be used, which
; slows down concurrent access by readers.  I've disabled this code
; for Wizard, but someone might want to reenable it in the future
; -chrisb

 CRUNCH_TOKEN_DB equ 0
;
; This code was written to force the token db to only contain monikers
; of the video type relevant to a specific hardware.  Specifically, it
; was written to keep the token db for Bullet small by only allowing
; only mono MCGA monikers to be added.  
; -martin



Init segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenInitTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the local token database file read/write and, if
		the path for a globally shared token database appears
		in the .INI file, open that file shared-multiple read-only.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		carry set if error:
			dx	= TokenError
				      ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE
				      ERROR_OPENING_LOCAL_TOKEN_DATABASE_FILE
				      BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE
		carry clear if OK
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	12/10/92	Rewrote for shared/local files and map block
	jenny	3/10/93		Amalgamated with OpenSharedAndLocalFiles

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenInitTokenDB	proc	far
		uses	ax, bx, cx, di, si, bp, ds, es
		.enter
	;
	; Zero the stored token database file handles.
	;
		mov	cx, segment dgroup
		mov	ds, cx
		clr	cx
		mov	ds:[localTokenDBFileHandle], cx
		mov	ds:[sharedTokenDBFileHandle], cx
	;
	; Check whether we need a token database at all.
	;
		call	FilePushDir
		call	NoTokenDB?
		jc	onward
		tst	ax
		jnz	scoot
onward:
	;
	; Find the shared file, if any, and open it shared-multiple
	; read-only.
	;
		call	OpenSharedTokenDB
		jnc	openLocal
		tst	dx
		stc
		jnz	scoot
openLocal:
	;
	; Find the local file, if any, and open it read-write. 
	; If there's no local file, the first call to TokenDefineToken
	; will cause one to be created.
	;
		call	TOKENOPENLOCALTOKENDB
		jnc	scoot
		mov	dx, ERROR_OPENING_LOCAL_TOKEN_DATABASE_FILE
scoot:
		call	FilePopDir		; flags preserved
		.leave
		ret

TokenInitTokenDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoTokenDB?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check value of "noTokenDatabase" key if it's in the .INI file

CALLED BY:	TokenInitTokenDB
PASS:		nothing
RETURN:		carry clear if key found
			ax	= TRUE (-1) or FALSE (0)
		carry set if key not found or if key value was neither
			"true" nor "false" 
DESTROYED:	cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoTokenDB?	proc	near
	;
	; Find out if we need a token database.
	; 
		mov	cx, cs			; cx:dx <- .INI file key
		mov	dx, offset cs:[noTokenDBKey]
		mov	ds, cx			; ds:si <- .INI file category
		mov	si, offset cs:[uiCategory]
		call	InitFileReadBoolean

		ret
NoTokenDB?	endp

uiCategory	char	"ui", 0
noTokenDBKey	char	"noTokenDatabase", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenSharedTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the shared token database file, if any, shared-multiple
		read-only.

CALLED BY:	INTERNAL	TokenInitTokenDB
PASS:		nothing
RETURN:		carry clear if successful or if sharedTokenDatabase
				path key not found in .INI file
		carry set if unsuccessful:
			dx	=  TokenError
				       ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE
				       BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE
DESTROYED:	ax, bx, cx, di, si, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenSharedTokenDB	proc	near

iniPathBuffer	local	PATH_BUFFER_SIZE	dup (char)

		.enter

	;
	; Read the absolute path with drive specifier from the .INI file.
	;
		
		segmov	es, ss
		lea	di, ss:[iniPathBuffer]

		mov	cx, cs			; cx:dx <- .INI file key
		mov	dx, offset cs:[sharedTokenDBPathKey]
		mov	ds, cx			; ds:si <- .INI file category
		mov	si, offset cs:[pathsCategory]
		mov_tr	ax, bp
		mov	bp, ((IFCC_INTACT shl offset IFRF_CHAR_CONVERT) \
				or (PATH_BUFFER_SIZE shl offset IFRF_SIZE))
		call	InitFileReadString	
		mov_tr	bp, ax
	;
	; Clear dx as a sign both that we want the disk handle and that
	; TokenInitTokenDB should consider everything ok should we
	; return to it at this point.
	;
		mov	dx, 0		; don't trash carry
		jc	done

	;
	; Set the path.
	;
		lea	dx, ss:[iniPathBuffer]
		segmov	ds, ss
		clr	bx
		call	FileSetCurrentPath
		jc	error
	;
	; Open the file shared-multiple read-only, and deny write.  If
	; we don't force deny write, then we run the risk of reading
	; the entire thing into memory and leaving it there forever.
	;
		
		segmov	ds, cs
		mov	dx, offset cs:[tokenDBName]
if ALLOW_READERS_AND_WRITERS
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_FORCE_SHARED_MULTIPLE or \
				mask VMAF_FORCE_READ_ONLY
else
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_FORCE_SHARED_MULTIPLE or \
				mask VMAF_FORCE_READ_ONLY or \
				mask VMAF_FORCE_DENY_WRITE
endif
		
		call	VMOpen
		jc	error
	;
	; Check the file's protocol number
	;
if FULL_EXECUTE_IN_PLACE
		mov	si, dx			;ds:si = filename
		clr	cx			;cx = terminated str
		call	SysCopyToStackDSSI	;ds:si = filename in stack
		mov	dx, si			;ds:dx = filename in stack
endif		
		call	CheckOrSetProtocol
if FULL_EXECUTE_IN_PLACE
		lahf
		call	SysRemoveFromStack	;restore stack
		sahf
endif
		mov	dx, BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE
		jc	done
	;
	; Store the file handle.
	;
		segmov	ds, dgroup, dx
		mov	ds:[sharedTokenDBFileHandle], bx
done:
		.leave
		ret
error:
		mov	dx, ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE
		jmp	done

OpenSharedTokenDB	endp

pathsCategory		char	"paths", 0
sharedTokenDBPathKey	char	"sharedTokenDatabase", 0
LocalDefNLString tokenDBName <"Token Database", 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOKENOPENLOCALTOKENDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the local token database file read/write.

CALLED BY:	GLCBAL
PASS:		nothing
RETURN:		carry clear if successful:
			ax	= 0
		carry set if error:
			ax	= VMStatus error code
DESTROYED:	nothing

SIDE EFFECTS:	
		If an existing local token database is out of date or
		corrupted, TOKENOPENLOCALTOKENDB deletes it.

PSEUDO CODE/STRATEGY:
		
	 TOKENOPENLOCALTOKENDB will return carry clear, ax = 0 in three cases:
      		1) if it has successfully opened an existing local
		   token database
		2) if it has detected and deleted an out-dated or
		   corrupted local token database
		3) if no local token database exists
   	It will not attempt to create a local token database if none exists;
   	TokenDefineToken does that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/18/92    	Broke out of TokenInitTokenDB and revised
	jenny	3/10/93		Changed to open file only, not to create it
	jenny	4/14/93		Changed to make it a global routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOKENOPENLOCALTOKENDB	proc	far
		uses	bx, cx, dx, di, ds
		.enter
	;
	; Set the path.
	;
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
	;
	; Open the file.
	;
		segmov	ds, cs
		mov	dx, offset cs:[tokenDBName]
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_FORCE_SHARED_MULTIPLE or \
				mask VMAF_FORCE_READ_WRITE
		call	VMOpen
		jnc	gotIt
	;
	; If the file's not there, leave; if it's bogus, get rid of it
	; and leave. We'll create a new file when TokenDefineToken is
	; first called. If VMOpen failed for some other reason, pass
	; back an error code.
	;
		clr	bx			; bx <- null handle
		cmp	ax, VM_FILE_NOT_FOUND
		je	fine
		cmp	ax, VM_FILE_FORMAT_MISMATCH
		je	deleteBogus
		cmp	ax, VM_OPEN_INVALID_VM_FILE
		stc				; pessimism
		jne	done
deleteBogus:
		call	FileDelete
		jmp	fine
gotIt:
	;
	; Check the file protocol.
	;
if FULL_EXECUTE_IN_PLACE
		push	ds, dx, ax
		xchg	si, dx			;ds:si = filename
		clr	cx			;cx = terminated str
		call	SysCopyToStackDSSI	;ds:si = filename in stack
		xchg	dx, si			;ds:dx = filename in stack
endif		
		call	CheckOrSetProtocol
if FULL_EXECUTE_IN_PLACE
		lahf
		call	SysRemoveFromStack	;restore stack
		sahf
		pop	ds, dx, ax		;ds:dx = filename in code seg
endif
 		jc	deleteBogus
	;
	; Store the file handle.
	;
		mov	dx, segment dgroup
		mov	ds, dx
		mov	ds:[localTokenDBFileHandle], bx
	;
	; Make sure that the file is owned by the ui -- this will
	; prevent death if the thread who called us exits without
	; closing the file first.
	;	dloft 4/26/93
	;
		mov	ax, handle 0
		call	HandleModifyOwner

fine:
		clr	ax			; clears carry too
done:
		.leave
		ret
		
TOKENOPENLOCALTOKENDB	endp

Init	ends

;
;---------------
;
		
Exit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOKENCLOSELOCALTOKENDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes local token database file

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	4/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOKENCLOSELOCALTOKENDB	proc	far
		uses	di
		.enter

		mov	di, offset dgroup:localTokenDBFileHandle
		call	CloseTokenDBFile

		.leave
		ret
TOKENCLOSELOCALTOKENDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenExitTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close token database file

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	4/14/93		Rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenExitTokenDB	proc	far
		uses	di
		.enter

		call	TOKENCLOSELOCALTOKENDB
		mov	di, offset dgroup:sharedTokenDBFileHandle
		call	CloseTokenDBFile

		.leave
		ret
TokenExitTokenDB	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseTokenDBFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the shared or the local token DB file	

CALLED BY:	INTERNAL	TokenExitTokenDB
				TOKENCLOSELOCALTOKENDB
PASS:		di	= offset of appropriate stored file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseTokenDBFile	proc	near
		uses	ax, bx, ds
		.enter
	;
	; Zero the stored handle, and if the file exists, close it.
	;
		mov	bx, segment dgroup
		mov	ds, bx
		clr	bx
		xchg	ds:[di], bx
		tst	bx
		jz	done
		mov	al, FILE_NO_ERRORS
		call	VMClose
done:
		.leave
		ret
CloseTokenDBFile	endp

Exit	ends

;
;---------------
;
		
TokenUncommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenDefineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add/replace token and moniker list in token database

		NOTE:  May be called ONLY by thread capable of locking block
		       that passed Moniker/MonikerList resides in.

CALLED BY:	GLOBAL
PASS:		ax:bx:si= six bytes of token
		cx:dx 	= handle:chunk of moniker list
		bp	= TokenFlags
RETURN:		carry set if there's no local token database
			ax	= VMStatus returned from VMOpen
		carry clear if successful
DESTROYED:	nothing
		WARNING:  This routine may move locked LMem blocks,
		(token database items), invalidating stored segment
		ptrs to them.

PSEUDO CODE/STRATEGY:
		* Remove token from local token database if there.
		* Create local token database if none exists.
		* Allocate a DB item for token's moniker list.
		* Add new token entry to local database map item.
		* Allocate a DB item for each moniker in the moniker list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If TokenDefineToken has succeeded once, it will always
	succeed, since the local token database will be in place.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	12/10/92	Rewrote
	jenny	3/10/93		Changed to create local file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenDefineToken	proc	far
		class	UserClass
		tokenFlags	local	word	push	bp
		tokenChars	local	dword	push	ax, bx
		monListGroup	local	word
		monListItem	local	word
		monListHandle	local	word
		monListSize	local	word
		scratchOffset	local	word

		uses	bx, cx, dx, si, di, bp, ds, es
		ForceRef	tokenFlags
		ForceRef	monListSize
		ForceRef	scratchOffset

		.enter

if CRUNCH_TOKEN_DB		
		call	TokenCrunchMonikerList	
endif

		mov	monListHandle, cx
	;
	; Remove token from local token database file if there. 
	;
		push	bp			; we need our frame...
		call	TokenRemoveToken
		pop	bp
	;
	; Get the handle of the local token database file, creating
	; the file if necessary. 
	;
		push	cx
		mov	cx, LOCAL_FILE
		call	TokenGrabDBFile		; bx <- local file handle
		pop	cx
		jnc	gotIt
		call	CreateLocalTokenDB	; bx <- local file handle
		jc	exit

if ALLOW_READERS_AND_WRITERS
	;
	; Now grab the VM exclusive on this thing, so that the
	; "release" down below doesn't crash.
	;
		push	ax, cx
		mov	ax, VMO_WRITE
		clr	cx
		call	VMGrabExclusive
		pop	ax, cx
endif
		
gotIt:
	;
	; Allocate a DB item to hold the token's moniker list.
	;
		mov	ax, MONIKER_LIST_TYPE
		call	AllocateTokenDBItem
		mov	monListGroup, cx
		mov	monListItem, dx
		movdw	axdi, tokenChars	; ax:di:si <- token
	;
	; Add new token entry to local token database map item.
	; Allocate a DB item for each moniker in moniker list.
	; Write our changes and let go of the file.
	;
		call	AddTokenEntry
		call	AddMonikers
		call	TokenReleaseDBFile
exit:
		.leave
		ret
TokenDefineToken	endp


if CRUNCH_TOKEN_DB

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TokenCrunchMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Takes a moniker list, and converts it to a moniker
		list containing only one BW MGA moniker.

CALLED BY:	INTERNAL - TokenDefineToken

PASS:		^lcx:dx	= moniker list (array of VisMonikerListEntry)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenCrunchMonikerList	proc	near
textMoniker	local	VisMonikerListEntry
		uses	ax, bx, cx, dx, di, si, ds, es
 		.enter
	;
	; Lock down moniker list
	;
		mov	bx, cx
		call	ObjLockObjBlock
		mov	es, ax
		mov	es:[LMBH_handle], bx	;HACK! LMF_IN_RESOURCE
						;bit not set correctly
						;by goc, but this
						;work-around allows
						;things this to work
						;for GeoFile until the
						;real fix comes...
		mov	di, dx
		mov	di, es:[di]		; es:di = moniker list

	;
	; If original list only had one or two entries, keep it that way.
	;	
		ChunkSizePtr	es, di, cx
		cmp	cx, (size VisMonikerListEntry)*2
		jle	exit

	;
	; Change the next line to have the token db be exclusive to
	; some other video type. 
	;
		mov	bh, DisplayType <DS_STANDARD,DAR_NORMAL, \
					 DC_COLOR_4>

	;
	; Find text moniker, and copy it onto the stack.
	;
		push	bp
		mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
		call	TokenSearchMonikerList
		pop	bp

		mov	ax, es:[si].VMLE_type
		mov	ss:[textMoniker].VMLE_type, ax
		movdw	ss:[textMoniker].VMLE_moniker, es:[si].VMLE_moniker, ax

	;
	; Find mono MCGA moniker.
	;
		push	bp
		mov	bp, mask VMSF_GSTRING or(VMS_ICON shl offset VMSF_STYLE)
		call	TokenSearchMonikerList
		pop	bp

	;
	; Move it to the top of the chunk, and shrink the chunk to fit
	;
		mov	ax, es:[si].VMLE_type
		mov	es:[di].VMLE_type, ax
		movdw	es:[di].VMLE_moniker, es:[si].VMLE_moniker, ax

		add	di, size VisMonikerListEntry
		mov	ax, ss:[textMoniker].VMLE_type
		mov	es:[di].VMLE_type, ax
		movdw	es:[di].VMLE_moniker, ss:[textMoniker].VMLE_moniker, ax

		segmov	ds, es
		mov	cx, (size VisMonikerListEntry)*2
		mov	ax, dx
		call	LMemReAlloc
exit:	
		mov	bx, es:[LMBH_handle]
		call	MemUnlock

		.leave
		ret
TokenCrunchMonikerList	endp

endif 	; if CRUNCH_TOKEN_DB



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLocalTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the local token database file and open it read/write.

CALLED BY:	TokenDefineToken

PASS:		nothing

RETURN:		carry clear if successful:
			bx	= local token database file handle

		carry set if file could not be created
			ax	= VMStatus returned from VMOpen

DESTROYED:	di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	3/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLocalTokenDB	proc	near
		uses	cx, dx
		.enter
	;
	; Set the path and create the file. We use VMO_CREATE_ONLY since
	; if we had a pre-existing local file it was opened awhile ago at
	; the behest of TokenInitTokenDB.
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		segmov	ds, cs
		mov	dx, offset cs:[localTokenDBName]
		mov	ax, (VMO_CREATE_ONLY shl 8) or \
				mask VMAF_FORCE_SHARED_MULTIPLE or \
				mask VMAF_FORCE_READ_WRITE
		call	VMOpen			; ax <- VMStatus
		call	FilePopDir
		jc	done
	;
	; Set the file's protocol number, map block and map item.
	;
if FULL_EXECUTE_IN_PLACE
		push	ds, dx
		xchg	si, dx			;ds:si = filename
		clr	cx			;cx = terminated str
		call	SysCopyToStackDSSI	;ds:si = filename in stack
		xchg	dx, si			;ds:dx = filename in stack
endif		
		call	InitializeLocalTokenDB
if FULL_EXECUTE_IN_PLACE
		call	SysRemoveFromStack	;restore stack
		pop	ds, dx			;ds:dx = filename in code seg
endif
		
	;
	; The UI must own the token database; we don't want this file
	; being closed when whatever process called TokenDefineToken
	; goes away.
	;
		push	ax			; save VMStatus
		mov	ax, handle 0
		call	HandleModifyOwner
		pop	ax			; restore VMStatus
	;
	; Save the file handle.
	;
		mov	dx, segment dgroup
		mov	ds, dx
		mov	ds:[localTokenDBFileHandle], bx
		clc
done:
		.leave
		ret

CreateLocalTokenDB	endp

LocalDefNLString localTokenDBName <"Token Database", 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeLocalTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the map block and map item of the local token database

CALLED BY:	INTERNAL	CreateLocalTokenDB
PASS:		ds:dx	= token database file name
		(ds:dx *cannot* be pointing to the movable XIP resource.)
		ax	= VMStatus from creating file
		bx	= VM file handle
		file semaphore already grabbed
RETURN:		nothing
DESTROYED:	ax, dx, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeLocalTokenDB	proc	near
		uses	si, bp
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Set the file protocol.
	;
		call	CheckOrSetProtocol
	;
	; Set local file's map block, which will hold an array
	; of MonikerGroupEntry structures, one entry (i.e. one group)
	; for every VisMonikerListEntryType encountered. The first
	; entry is for moniker lists themselves.
  	;
		mov	cx, INITIAL_MAP_BLOCK_SIZE
		call	VMAlloc
		call	VMSetMapBlock
		mov	si, START_OF_ENTRIES_OFFSET
		mov_tr	dx, ax			; dx <- map block
		mov	di, cx			; di <- total space in block
		mov	cx, MONIKER_LIST_TYPE
		call	CreateMonikerGroupEntry ; bp <- locked map block
						;  mem handle
		call	VMUnlock
	;
	; Set local file's map item, which will hold an array of
	; TokenEntry structures. We create a dummy first entry so as
	; not to die on the first call to AddTokenEntry when DBLockMap
	; chokes on the absence of an item block. DBAlloc provides one.
	;
		call	DBGroupAlloc		; allocate group for map
		mov	cx, size TokenEntry
		call	DBAlloc
		call	DBSetMap

		.leave
		ret

InitializeLocalTokenDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddTokenEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add new token entry to token database.	

CALLED BY:	INTERNAL	TokenDefineToken
PASS:		bx	= token DB file handle
		ax:di:si= six bytes of token
		cx	= moniker list group
		dx	= moniker list item
		file semaphore already grabbed
RETURN:		ax	= moniker list group
		di	= moniker list item
DESTROYED:	cx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	* Reallocate map to hold new TokenEntry.
	* Initialize the TokenEntry.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/10/92    	Broke out of TokenDefineToken and revised

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddTokenEntry	proc	near
		uses	bx
		.enter inherit TokenDefineToken
	;
	; Reallocate map to hold new TokenEntry.
	;
		push	cx			; save moniker list group
		push	ax, di, si		; save token
		call	DBLockMap		; es:*di <- map item
		ChunkSizeHandle	es, di, cx	; cx <- current map size
		call	DBUnlock
		push	cx			; save size
		add	cx, size TokenEntry
		call	ReAllocMap		; ax <- group, di <- item
		call	DBLockMap
		call	DBDirty
		mov	di, es:[di]		; deref. map item
		pop	bx			; offset to new TokenEntry
	;
	; Initialize the TokenEntry.
	;
	; Token.
	;
		pop	word ptr es:[di][bx].TE_token.GT_manufID
		pop	word ptr es:[di][bx].TE_token.GT_chars+2
		pop	word ptr es:[di][bx].TE_token.GT_chars
	;
	; Flags.
	;
		mov	ax, ss:[tokenFlags]
		and	ax, not (mask TF_NEED_RELOCATION)
		mov	es:[di][bx].TE_flags, ax
	;
	; Moniker list group and item.
	;
		pop	ax
		mov	es:[di][bx].TE_monikerList.TDBI_group, ax
		mov	es:[di][bx].TE_monikerList.TDBI_item, dx 

		call	DBUnlock		; unlock map item
	;
	; Return ax:di = moniker list group/item.
	;
		mov	di, dx

		.leave
		ret
AddTokenEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a DB item for each moniker in moniker list.

CALLED BY:	INTERNAL	TokenDefineToken
PASS:		bx	= token DB file handle
		ax	= moniker list group
		di	= moniker list item
		file semaphore already grabbed
RETURN:		nothing
DESTROYED	nothing
SIDE EFFECTS:	
     
PSEUDO CODE/STRATEGY:
		* Loop through moniker list, allocating a DB item for
		  each moniker and storing its group and item numbers
		  in the moniker list DB item.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/10/92    	Broke out of TokenDefineToken and revised

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddMonikers	proc	near
		.enter inherit TokenDefineToken
	;
	; Lock the moniker list DB item and get its size.
	;
		mov	si, di			; save item
		call	DBLock
		mov	di, es:[di]		; es:di <- moniker list
EC <		test	es:[di].VM_type, mask VMT_MONIKER_LIST		>
EC <		ERROR_Z	TOKEN_DB_ITEM_IS_NOT_MONIKER_LIST		>
		ChunkSizePtr	es, di, cx	; cx <- moniker list size
		mov	monListSize, cx
		mov	scratchOffset, 0	; initial moniker list offset
monikerLoop:
	;
	; Get the handle of the next VisMoniker in the list and
	; relocate it if necessary.
	;
		push	ax			; save moniker list group
		mov	cx, es:[di].VMLE_moniker.handle
		mov	ax, tokenFlags
		test	ax, mask TF_NEED_RELOCATION
		jz	noRelocation
		mov	al, RELOC_HANDLE
		push	bx			; save file handle
		mov	bx, monListHandle
		call	ObjDoRelocation
		pop	bx			; bx <- file handle
noRelocation:
		mov	dx, es:[di].VMLE_moniker.chunk
		mov	ax, es:[di].VMLE_type
		call	DBUnlock		; unlock moniker list
	;
	; Allocate a DB item for the current moniker and store the group
	; and item numbers in the moniker list DB item.
	;
		call	AllocateTokenDBItem		; cx, dx <- new group & item
		pop	ax			; ax <- moniker list group 
		mov	di, si			; di <- moniker list item
		call	DBLock
		call	DBDirty
		mov	di, es:[di]		; es:di <- moniker list entry
		add	di, scratchOffset	; es:di <- position in list
		mov	{word} es:[di].VMLE_moniker+0, cx
		mov	{word} es:[di].VMLE_moniker+2, dx
	;
	; Loop if we're not at the end of the moniker list.
	;
		add	di, size VisMonikerListEntry
		add	scratchOffset, size VisMonikerListEntry
		mov	cx, monListSize
		cmp	cx, scratchOffset
		jne	monikerLoop

		call	DBUnlock		; unlock moniker list

		.leave
		ret
AddMonikers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateTokenDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a DB item in the local token database file
		for storing the passed lmem chunk

CALLED BY:	INTERNAL	TokenDefineToken
				AddMonikers
PASS:		bx	= local token DB file handle
		cx:dx	= lmem chunk to allocate DB item for
		ax	= VisMonikerListEntryType or MONIKER_LIST_TYPE
		file semaphore already grabbed
RETURN:		cx:dx	= group/item of DB item
		WARNING: This routine potentially moves locked lmem
		blocks (token database items).  Stored segments and
		handles to such blocks may be invalid after this call.
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/8/89		Initial version
	jenny	11/19/92    	Changed to call GetGroup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateTokenDBItem	proc	near
		uses	bx, si, bp, ds, es
		.enter
	;
	; Lock down LMem block and get chunk.
	;
		push	ax, bx			; save VMLE_type & file han
		mov	bx, cx			; bx <- lmem block
		mov	bp, bx			; save it
		call	ObjLockObjBlock
		mov	ds, ax
		mov	si, dx			; ds:*si <- lmem chunk
EC <		mov	ax, si						>
EC <		call	ECLMemExists		; make sure chunk exists>
EC <		ERROR_C	ALLOCATE_TOKEN_DB_ITEM_PASSED_BAD_CHUNK_HANDLE	>
		mov	si, ds:[si]		; ds:si <- lmem chunk
	;
	; Allocate the new DB item and copy the chunk into it.
	;
		pop	ax, bx			; restore VMLE_type
						;  & file handle
		call	GetGroup		; ax <- group
		ChunkSizePtr	ds, si, cx	; cx <- lmem chunk size
		call	DBAlloc			; di <- item
		push	ax, di			; save group/item
		call	DBLock			; es:*di <- locked item
		call	DBDirty
		mov	di, es:[di]
		rep movsb			; copy in lmem chunk
		call	DBUnlock

		mov	bx, bp
		call	MemUnlock		; unlock lmem block
		pop	cx, dx			; return group/item

		.leave
		ret
AllocateTokenDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get/create group for a moniker or moniker list

CALLED BY:	INTERNAL	AllocateTokenDBItem
PASS:		ax	= VisMonikerListEntryType or MONIKER_LIST_TYPE
		bx	= token database file handle
		file semaphore already grabbed
RETURN:		ax	= group number
DESTROYED:	cx, dx, di, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/19/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGroup	proc	near
		uses	si, bp
		.enter
	;
	; Lock map block.
	;
		mov_tr	si, ax			; save VMLE_type
		call	VMGetMapBlock
		mov	dx, ax			; dx <- block handle
		call	VMLock
		mov	es, ax
	;
	; Get the block size and then loop through the block, checking the
	; type of each entry against the type of the desired group.
	;
		mov_tr	ax, si			; ax <- VMLE_type
		clr	di
		mov	cx, es:[di]		; cx <- total space
		mov	si, es:[di]+2		; si <- space used so far
		mov	di, START_OF_ENTRIES_OFFSET
typeMatchLoop:
		
		cmp	ax, es:[di].MGE_type
		je	found
		add	di, size MonikerGroupEntry
		cmp	di, si			; at end of entries?
		jb	typeMatchLoop
	;
	; No entry exists for this VisMonikerListEntryType, so we
	; create one. First allocate more space in the block if there's
	; not enough.
	;
		push	ax, bx			; save VMLE_type, file handle
		mov	di, cx			; di <- total space
		cmp	di, si			; at end of block?
		ja	newGroup		; if jumping, carry is clear
		mov_tr	ax, cx			; ax <- total space
		add	ax, MAP_BLOCK_SIZE_INCREMENT
		mov	di, ax			; di <- new total space
		mov	cx, ALLOC_DYNAMIC_NO_ERR
		mov	bx, bp
		call	MemReAlloc
newGroup:
	;
	; Now create the entry.
	;
		pop	cx, bx			; bx <- file handle
						; cx <- VMLE_type
		call	VMUnlock
		call	CreateMonikerGroupEntry
found:	
		mov	ax, es:[di].MGE_group
		call	VMUnlock

		.leave
		ret

GetGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMonikerGroupEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new MonikerGroupEntry to the end of the map block.

CALLED BY:	INTERNAL	InitializeLocalTokenDB
				GetGroup
PASS:		bx	= token DB file handle
		cx	= VMLE_type
		dx	= token DB map block handle
		di	= total space available in map block
		si	= offset to entry being created
		file semaphore already grabbed

RETURN:		es	= segment of locked map block
		bp	= memory handle of locked map block
		di	= offset to entry created
DESTROYED:	ax, dx, si

SIDE EFFECTS:	

PSEUDO CODE/STRATEG:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/15/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMonikerGroupEntry	proc	far
	;
	; Allocate group for moniker lists.
	;
		push	di			; save total space
		call	DBGroupAlloc
	;
	; Lock map block and initialize the new entry.
	;
		mov	di, si			; di <- offset to new entry
		xchg	ax, dx			; ax <- map block
						; dx <- group num
		call	VMLock
		call	VMDirty
		mov	es, ax
		mov	es:[di].MGE_type, cx
		mov	es:[di].MGE_group, dx
	;
	; At the beginning of the block, store the size of the block
	; and the amount of space used in it so far.
	;
		clr	di
		pop	es:[di]				; store total space
		push	si				; save offset
		add	si, size MonikerGroupEntry
		mov	es:[di]+2, si			; store space used
		pop	di				; di <- offset

		ret

CreateMonikerGroupEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenRemoveToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove token and moniker list from local token database

CALLED BY:	GLOBAL
PASS:		ax:bx:si - six bytes of token
RETURN:		carry clear if token deleted
		carry set if token was not in local file
DESTROYED:	nothing
		WARNING:  This routine legally may move locked LMem
			  blocks (token database items), invalidating
			  stored segment ptrs to them.

PSEUDO CODE/STRATEGY:
		if (token exists in local token DB) {
			shift map item contents to remove TokenEntry;
			realloc map;
			for each moniker in moniker list {
				free DB item for moniker;
			}
			free DB item for moniker list;
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/17/89	Initial version
	jenny	5/ 1/93		Rewrote for shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenRemoveToken	proc	far
		uses	ax, bx, cx, dx, di, si, bp, ds, es
		.enter
	;
	; Get the TokenEntry from the local token database file if it's there
	;
		mov	cx, LOCAL_FILE
		call	TokenDBLockMap
		jc	exit			; no local file
		push	di			; save map item offset
		call	FindToken		; es:di <- TokenEntry	
		jc	unlockMapItem		; not there
	;
	; Mark map item dirty and save pointer to the start of it.
	;
		mov_tr	ax, di			; es:ax = TokenEntry
		pop	di			; *es:di = map item
		call	DBDirty
		mov	bp, es:[di]		; es:bp <- map item start
		mov_tr	di, ax			; es:di <- TokenEntry again
	;
	; Save the group and item of TokenEntry's moniker list.
	;
		mov	bx, es:[di].TE_monikerList.TDBI_group
		mov	dx, es:[di].TE_monikerList.TDBI_item
	;
	; Now find the start of the TokenEntry immediately after the
	; one we're removing.
	;
		segmov	ds, es, si
		mov	si, di
		add	si, size TokenEntry	; ds:si <- next TokenEntry
	;
	; Use the position of the TokenEntry to remove as the point
	; at which to start copying over all the TokenEntries that come
	; after it.
	;
		ChunkSizePtr	es, bp, cx	; cx <- size of map item
		push	cx
		add	bp, cx			; bp <- end of map item
		sub	bp, si			; bp <- # bytes to copy
						; carry <- clear since
						;  bp > or = si
		mov	cx, bp
		rep movsb			; remove TokenEntry
	;
	; Unlock and resize the map item.
	;
		call	DBUnlock
		pop	cx			; cx <- map item size 
		push	bx			; save moniker list group
       		push	cx
		mov	cx, LOCAL_FILE
		call	TokenGetDBFile		; bx <- local token DB file han
		pop	cx
		sub	cx, size TokenEntry	; cx <- new map item size
		call	ReAllocMap
	;
	; Free DB item for each moniker in moniker list.
	;
		pop	ax			; ax:di <- group and item
		mov	di, dx			;  of moniker list
		call	FreeMonikers

		call	TokenReleaseDBFile
		
exit:
		.leave
		ret

unlockMapItem:
		mov	cx, LOCAL_FILE
		call	TokenDBUnlock
		pop	cx
		jmp	exit

TokenRemoveToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free local token DB item for each moniker in moniker list

CALLED BY:	INTERNAL	TokenRemoveToken
PASS:		ax	= DB group of moniker list
		di	= DB item of moniker list
		bx	= handle of local token DB file
		file semaphore already grabbed
RETURN:		nothing
DESTROYED:	cx, si
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/16/92    	Broke out of TokenRemoveToken and revised

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeMonikers	proc	near
	;
	; Lock the local token DB item for the moniker list; mark it
	; dirty; find the end of it.
	;
		push	ax, di
		call	DBLock			; es:*di <- moniker list
		call	DBDirty
		mov	si, es:[di]		; es:si <- moniker list
		ChunkSizePtr	es, si, cx	; cx <- moniker list size
		add	cx, si			; cx <- end of list
monikerLoop:
	;
	; For each moniker in list, get its group and item and free it.
	;
		mov	ax, {word} es:[si].VMLE_moniker+0
		mov	di, {word} es:[si].VMLE_moniker+2
		call	DBFree
		add	si, size VisMonikerListEntry
		cmp	si, cx			; at end?
		jne	short monikerLoop
	;
	; Unlock the moniker list DB item and free it.
	;
		call	DBUnlock
		pop	ax, di			; ax:di <- group/item
		call	DBFree

		ret
FreeMonikers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenListTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a list of the tokens in the token.db file and return
		it in a memory block as an array of GeodeToken structures.
		Along with the list, the number of items in the list is
		returned.

CALLED BY:	GLOBAL
PASS:		ax	= TokenRangeFlags
		bx	= number of bytes to reserve for header
		     	  if 0, token list begins at top of returned block
		cx	= ManufacturerID of tokens for list, if the 
				TRF_ONLY_PASSED_MANUFID is set in ax
RETURN:		bx	= handle of memory block containing list
		ax	= number of items in list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/13/92		Initial version
	martin	10/29/92	Added ability to add header to returned list
	jenny	12/15/92	Rewrote: shared/local DB + no TokenGroupEntry
	dlitwin 4/15/93		Passing TokenRangeFlags allows filtering
				only icons of a certain manufID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenListTokens	proc	far
		uses	cx, dx, bp, si, di, ds, es
		
nextToken		local	word		push	bx
rangeFlags		local	TokenRangeFlags	push	ax
passedManufID		local	word		push	cx
mapItemSize		local	word
endOfLocalTokens	local	word

ForceRef	rangeFlags
ForceRef	passedManufID

		.enter
	;
	; On the first cycle through useNextFile, list the tokens in
	; the local file; on the second cycle, add those tokens in the
	; shared file which aren't in the local file. 
	;
		clr	bx, dx
		mov	cx, LOCAL_FILE
useNextFile:
	;
	; Lock map item.  
	;
		call	TokenDBLockMap		; es:*di <- map item
		jc	maybeDone		; no file?
		segmov	ds, es
		mov	si, ds:[di]		; ds:si <- map item
		mov	di, ss:[nextToken]	; di <- add tokens here
	;
	; First allocate a buffer of size <map item size + header size>.
	; If both local and shared files exist, then on the second
	; time through, when using shared file, reallocate buffer to be
	; <map item size> bigger.
	;
		ChunkSizePtr	ds, si, ax
		sub	ax, size TokenEntry	; ignore dummy first entry
		tst	ax
		jz	unlockMap
		add	si, size TokenEntry	; ditto
		mov	ss:[mapItemSize], ax
		add	ax, di			; ax <- size to allocate
		push	cx			; save shared/local flag
		tst	bx
		jz	firstAllocation
		mov	cx, ALLOC_DYNAMIC_NO_ERR
		call	MemReAlloc
		jmp	makeList
firstAllocation:
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
makeList:
		pop	cx			; cx <- shared/local flag
		mov	es, ax			; es:di <- list position
						;  to start adding tokens
		mov	ss:[endOfLocalTokens], di
		call	ConstructTokenList
		mov	ss:[nextToken], di	; save offset to next position
unlockMap:
	;
	; Unlock map item, release file semaphore, and see if we're 
	; through with both files.
	;
		segmov	es, ds
		call	TokenDBUnlock
maybeDone:
		jcxz	done
		clr	cx
		jmp	useNextFile
done:
	;
	; Unlock list block and return list size in ax.
	;
EC <		tst	bx						>
EC <		ERROR_Z	NO_TOKEN_DATABASE_FILE_HANDLE			>
		call	MemUnlock
		mov_tr	ax, dx

		.leave
		ret
TokenListTokens	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConstructTokenList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct list of tokens

CALLED BY:	INTERNAL	TokenListTokens
PASS:		ds:si	= first TokenEntry in locked map item
		es:di	= point in list at which to add tokens
		bx	= handle of locked list block
		cx	= 0 if using shared token DB file
			  -OR- LOCAL_FILE if using local token DB file
		dx	= number of tokens in list so far
		file semaphore already grabbed
RETURN:		es:di	= end of list
		dx	= number of tokens in list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConstructTokenList	proc	near
		uses	cx
		.enter inherit TokenListTokens

		push	bx			; save list block handle
		mov	bx, ss:[mapItemSize]
		mov	ax, ss:[rangeFlags]
constructListLoop:
	;
	; Make our list, including only those tokens with a manufacturerID
	; equal to ss:[passedManufID] if the TRF_ONLY_PASSED_MANUFID
	; flag is set, and only GString monikers if the TRF_ONLY_GSTRING
	; flag is set. We ignore any tokens which already appear in the list,
	; as may happen when we add tokens from the shared file to the
	; list of tokens from the local file.
	;
		test	ax, mask TRF_ONLY_PASSED_MANUFID
		jz	skipManufIDFilter
		push	ax
		mov	ax, ss:[passedManufID]
		cmp	ax, ds:[si].TE_token.GT_manufID
		pop	ax
		je	skipManufIDFilter
		add	si, size TokenEntry
		jmp	skipWriting

skipManufIDFilter:
		test	ax, mask TRF_ONLY_GSTRING
		jz	skipGStringFilter
		call	TokenFilterGString	; si <- next token if
						;  will skip this one
		jnc	skipWriting
skipGStringFilter:
		call	CheckIfDuplicateToken	; si <- next token if
						;  will skip this one
		jc	skipWriting

		CheckHack <offset TE_token eq 0>
		CheckHack <size GeodeToken eq 6>

		movsw				; copy chars 1 & 2
		movsw				; copy chars 3 & 4
		movsw				; copy manufacturers ID
		add	si, size TokenEntry \
				- offset TE_token - size GeodeToken
		inc	dx			; increment count
skipWriting:
	;
	; Loop if we're not at the end of the map item.
	;
		sub	bx, size TokenEntry
		jnz	constructListLoop
	;
	; Shrink list block to fit list in case we did filter tokens.
	;
		pop	bx			; bx <- list block handle
		mov	ax, di			; ax <- how far we wrote
		mov	cx, ALLOC_DYNAMIC_NO_ERR
		call	MemReAlloc

		.leave
		ret
ConstructTokenList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenFilterGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the token has any GString monikers

CALLED BY:	INTERNAL	ConstructTokenList
PASS: 		ds:si	= TokenEntry
		(ds:si *cannot* be pointing into the movable XIP code segment.)
		cx	= 0 if using shared token DB file
			  -OR- LOCAL_FILE if using local token DB file
		file semaphore already grabbed
RETURN:		carry clear if token has no GString moniker:
			ds:si	= TokenEntry which follows the one passed in
		carry set if token has at least one GString moniker
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenFilterGString	proc	near
		uses	ax, bx, di, es
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	;
	; Lock moniker list and find its end. Note that we grabbed the
	; file's semaphore locking the map item back in TokenListTokens,
	; so we don't call TokenDBLock now, as that would try to grab
	; it again. Also, we know the file exists if we've gotten this
	; far, so we needn't check.
	;
		mov	ax, ds:[si].TE_monikerList.TDBI_group
		mov	di, ds:[si].TE_monikerList.TDBI_item
		call	TokenGetDBFile
		call	DBLock
		mov	di, es:[di]		; moniker list => DS:DI
		ChunkSizePtr	es, di, bx
		add	bx, di			; end of moniker list => BX
	;
	; Check if at least one moniker in the list is a GString. 
	;
monikerListLoop:
		test	es:[di].VMLE_type, mask VMLET_GSTRING
		jnz	itsAGString		; carry is clear
		add	di, size VisMonikerListEntry
		cmp	di, bx			; are we at the end?
		jl	monikerListLoop
		add	si, size TokenEntry
		stc
itsAGString:
		cmc
		call	DBUnlock		; preserves flags

		.leave
		ret
TokenFilterGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfDuplicateToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether a TokenEntry appears in a list of tokens

CALLED BY:	INTERNAL	ConstructTokenList
PASS:		ds:si	= token
		(ds:si *cannot* be pointing in the movable XIP code segment.)
		es	= segment of block containing list
		file semaphore already grabbed
RETURN:		carry set if TokenEntry appears in list
			ds:si	= TokenEntry which follows the one passed in
		carry clear if it doesn't		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If we are still adding tokens from the local file to the
	list, then we can assume that the current token does not yet
	appear; in this case, ss:[nextToken] = ss:[endOfLocalTokens]
	and so we return immediately.

	Otherwise, we check this token against all those already in
	the list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfDuplicateToken	proc	near
		uses	ax, cx, di
		.enter inherit TokenListTokens
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
		mov	di, ss:[nextToken]		; es:di <- list
		mov	cx, ss:[endOfLocalTokens]
		sub	di, size GeodeToken
checkNext:
	;
	; Check the token against all those already in the list until
	; we find a match or reach the end.
	;
		add	di, size GeodeToken
		cmp	di, cx			; at end ?
		je	depart			; if jumping, carry is clear
		cmptok	es:[di], ds:[si], ax
		jne	checkNext
		add	si, size TokenEntry
		stc				; it's a duplicate
depart:
		.leave
		ret
CheckIfDuplicateToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenGetTokenStats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get stats for a token

CALLED BY:	GLOBAL
PASS:		ax:bx:si - six bytes of token
RETURN:		???
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenGetTokenStats	proc	far
	ret
TokenGetTokenStats	endp

TokenUncommon	ends

;
;---------------
;
		
TokenCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckOrSetProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If file was just created, set its protocol number;
		otherwise, make sure that the protocol is valid.

CALLED BY:	InitializeLocalTokenDB, TOKENOPENLOCALTOKENDB

PASS:		ds:dx	= file name (file is in current directory)
		(ds:dx *cannot* be pointing into the movable XIP code resource.)
		ax	= VMStatus from opening file

RETURN:		si	= VMStatus from opening file
		carry clear if protocol matches
		carry set if protocol doesn't match		

DESTROYED:	ax, cx, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckOrSetProtocol	proc	far
protocol	local	ProtocolNumber
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Set up to fetch or set the protocol number.
	;
		mov_tr	si, ax			; si <- VMStatus from open
		mov	cx, size ProtocolNumber
		segmov	es, ss
		lea	di, ss:[protocol]
		mov	ax, FEA_PROTOCOL
	;
	; If we just created the file, we set the protocol. Otherwise,
	; we check it.
	;
		cmp	si, VM_CREATE_OK
		je	setProtocol
		call	FileGetHandleExtAttributes
	;
	; Check it.
	;
		cmp	es:[di].PN_major, TOKEN_DATABASE_PROTO_MAJOR
		jne	bad
		cmp	es:[di].PN_minor, TOKEN_DATABASE_PROTO_MINOR
		jbe	ok
bad:
	;
	; Close the file if it's bad.
	;
		mov	al, FILE_NO_ERRORS
		call	VMClose
		stc
		jmp	done
setProtocol:
	;
	; Set it.
	;
		mov	es:[di].PN_major, TOKEN_DATABASE_PROTO_MAJOR
		mov	es:[di].PN_minor, TOKEN_DATABASE_PROTO_MINOR
		call	FileSetHandleExtAttributes
ok:
		clc
done:
		.leave
		ret

CheckOrSetProtocol	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenGetTokenInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a token

CALLED BY:	GLOBAL
PASS:		ax:bx:si - six bytes of token
RETURN:		carry clear if token exists in database
			bp - flags for the token
		carry set otherwise
		(INTERNAL) tokenEntryBuffer - TokenEntry for token

DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenGetTokenInfo	proc	far
		uses	cx, dx, ds
		.enter

		mov	cx, segment dgroup
		mov	dx, offset dgroup:tokenEntryBuffer
		mov	ds, cx
		call	GetToken
		jc	done			; if not found, done
		mov	bp, ds:[tokenEntryBuffer].TE_flags
done:
		.leave
		ret
TokenGetTokenInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenLookupMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the specific moniker for a token, given display type
		and other attributes

CALLED BY:	GLOBAL
PASS:		ax:bx:si = six bytes of token
		dh	= DisplayType
		bp	= VisMonikerSearchFlags
			  (VMSF_COPY_CHUNK, VMSF_REPLACE_LIST ignored)
RETURN:		carry clear if token exists in database:
			cx:dx	= group/item of moniker
			ax	= 0 if token is in shared token DB file
			ax	= LOCAL_FILE if token is in local token DB file
		carry set otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/89	Initial version
	jenny	1/3/93		Changed to handle shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenLookupMoniker	proc	far
	uses	bx, si, di, bp, ds, es
	.enter
	;
	; Get TokenEntry for the desired token and lock its moniker list.
	;
		push	dx			; save DisplayType (dh)
		mov	cx, segment dgroup	; cx:dx - buffer for token
		mov	dx, offset dgroup:tokenEntryBuffer
		mov	ds, cx
		call	GetToken
		pop	bx			; retrieve DisplayType (bh)
		jc	done			; if not found, done
		push	cx			; save shared/local flag

		mov	ax, ds:[tokenEntryBuffer].TE_monikerList.TDBI_group
		mov	di, ds:[tokenEntryBuffer].TE_monikerList.TDBI_item
		call	TokenDBLock		; es:*di = moniker list
EC <		ERROR_C	NO_TOKEN_DATABASE_FILE_HANDLE			>
		mov	di, es:[di]		; es:di = moniker list

		call	TokenSearchMonikerList
	;
	; found best moniker
	;	es:si = VisMonikerListEntry for best moniker
	; return its group and item, plus a flag showing which
	; token DB file contains it.
	;
		mov	ax, word ptr es:[si].VMLE_moniker+0
		mov	dx, word ptr es:[si].VMLE_moniker+2
		pop	cx			; cx <- shared/local flag
		call	TokenDBUnlock		; unlock moniker list
		xchg	ax, cx			; ax <- shared/local flag
						; cx <- group for moniker
		clc				; indicate success
done:
		.leave
		ret
TokenLookupMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TokenSearchMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns the VisMonikerListEntry from the given moniker
		list that best suits the given DisplayType and
		VisMonikerSearchFlags.

CALLED BY:	INTERNAL - TokenLookupMoniker

PASS:		es:di	= pointer to moniker list 
			  (array of VisMonikerListEntry)
		bh 	= DisplayType
		bp 	= VisMonikerSearchFlags

RETURN:		es:si	= best VisMonikerListEntry

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/28/93		Pulled out of TokenLookupMoniker

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenSearchMonikerList	proc	far
		uses	ax, bx, cx, dx, di
		.enter
	;
	; everything set up for finding correct moniker in list
	;	es:di = moniker list
	;	bh = DisplayType
	;	bp = VisMonikerSearchFlags
	;
		call	VisUpdateSearchSpec	; modify bp using bh
		ChunkSizePtr	es, di, cx	; cx = size of chunk
		mov	bh, 0x80		; init best score to "none"
						;	(no need for low byte)
monikerLoop:
	;
	; for each moniker in list:
	;	es:di = pointer into VisMonikerList
	;	cx = size of MonikerList chunk remaining (6 bytes per entry)
	;	bp = VisMonikerSearchFlags (updated with DisplayType)
	;	bx = "score" of best moniker found so far
	;	si = offset from start of MonikerList to MonikerListEntry
	;		for "Best Moniker" so far
	;
		mov	dx, es:[di].VMLE_type	; type for moniker
		push	bx
		CallMod	VisTestMoniker		; ax = score for this one
		pop	bx
		tst	bx			; do we have current best?
		js	saveBest		; if so, save it
		cmp	ax, bx			; do we have new best?
		jle	next			; if not, check next
saveBest:
		mov	si, di			; save offset to this entry
		mov	bx, ax			; save new Best Score
next:
		add	di, size VisMonikerListEntry
		sub	cx, size VisMonikerListEntry
		jnz	monikerLoop

		.leave
		ret
TokenSearchMonikerList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenLoadMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load specific token into buffer

CALLED BY:	GLOBAL

PASS:		ax:bx:si - six bytes of token
		dh - DisplayType
		cx:di - moniker destination
			if (cx = 0) -> new global memory chunk allocated
						for moniker
			elif (di = 0) -> cx = handle of lmem block in which
						to allocate lmem chunk for
						moniker (see WARNING)
			elif (di != 0) -> cx:di = address to copy moniker to

		pass on stack (pushed in this order):

			- VisMonikerSearchFlags

			- size of buffer (only used if cx:di = address to copy
				moniker to, but must ALWAYS be passed)

		(these will be removed from stack by this routine)

		WARNING:  If creating the new chunk in an lmem block and
			  ds or es is pointing to that lmem block, you must
			  fixup ds or es yourself.  Ie. something like:

				push	ds:[LMBH_handle] ; save lmem blk handle
				(set up params)
				call	TokenLoadMoniker
				pop	bx
				call	MemDerefDS

RETURN:		carry clear if token exists in database
			cx - number of bytes in moniker
			di - global memory block handle
				OR
			di - lmem chunk handle in cx block
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/89	Initial version
	brianc	11/20/89	changed to use UserCopyChunkOut

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenLoadMoniker	proc	far	bufferSize:word, searchFlags:word
		uses	ax, bx, dx, ds
copyDestHigh	local	word	push	cx
copyDestLow	local	word	push	di
		.enter
	;
	; Look up the moniker.
	;
		push	bp			; save stack frame
		mov	bp, searchFlags
		call	TokenLookupMoniker	; cx:dx <- moniker group/item
						; ax <- shared/local flag
		pop	bp			; retrieve stack frame
		jc	error
		push	ax
	;
	; Lock it and copy it.
	;
		call	TokenLockTokenMoniker	; *ds:bx <- moniker
		mov	cx, copyDestHigh	; cx:dx <- copy destination
		mov	dx, copyDestLow
		clr	ax			; copy from beginning
		mov	di, bufferSize		; copy passed # of bytes
		push	bp			; save stack frame
		mov	bp, bx			; *ds:bp <- moniker chunk
		clr	bx			; do not add null-terminator
		call	UserCopyChunkOut
		pop	bp			; retrieve stack frame
		mov	di, ax			; set return value
	;
	; Unlock it.
	;
		pop	ax			; ax <- shared/local flag
		call	TokenUnlockTokenMoniker
		clc				; indicate success
error:
		.leave
		ret	@ArgSize
TokenLoadMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenLoadToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load TokenEntry structure for a token into a buffer

CALLED BY:	GLOBAL

PASS:		ax:bx:si - six bytes of token
		cx:di - moniker destination
			if (cx = 0) -> new global memory chunk allocated
						for moniker
			elif (di = 0) -> cx = handle of lmem block in which
						to allocate lmem chunk for
						moniker (see WARNING)
			elif (di != 0) -> cx:di = address to copy moniker to
				buffer must contain "size TokenEntry" bytes

		WARNING:  If creating the new chunk in an lmem block and
			  ds or es is pointing to that lmem block, you must
			  fixup ds or es yourself.  Ie. something like:

				push	ds:[0]	; save lmem block handle
				call	TokenLoadToken
				pop	bx
				call	MemDerefDS

RETURN:		carry clear if token exists in token database
			cx - number of bytes in TokenEntry
			di - global memory block handle
				OR
			di - lmem chunk handle in cx block
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	brianc	11/20/89	changed to use UserCopyChunkOut
	jenny	12/28/92	Changed to use shared and local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenLoadToken	proc	far
		uses	ax, bx, dx, bp, ds, es
		.enter
	;
	; Put passed destination in cx:dx.
	;
		mov	dx, di
	;
	; Find token.
	;
		call	FindTokenInLocalOrSharedFile
						; ds:di <- TokenEntry
						; *ds:bp <- locked map item
						; ax <- shared/local flag
		jc	exit
		push	ax
	;
	; Copy it to destination.
	;
		sub	di, ds:[bp]		; di <- offset to TokenEntry
						;  from start of map item
		mov	ax, di			; ax <- start copying here
		add	di, size TokenEntry	; di <- stop copying here
		clr	bx			; do not add null-terminator
		call	UserCopyChunkOut
		mov	di, ax			; di <- chunk
		pop	ax
		xchg	cx, ax			; cx <- shared/local flag
						; ax <- # bytes
		call	TokenDBUnlock		; unlock map item
		mov_tr	cx, ax			; cx <- # bytes
exit:
		.leave
		ret
TokenLoadToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenLockTokenMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock moniker for drawing. ***Note warning below.***

CALLED BY:	GLOBAL
PASS:		cx:dx	= group/item of a specific moniker
		ax	= 0 if token is in shared token DB file
			-OR- LOCAL_FILE if token is in local token DB file
RETURN:		*ds:bx	= moniker (ds = segment, bx = chunk)
		token database file semaphore grabbed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	WARNING: No token database call may be made between a call
	to TokenLockTokenMoniker and the corresponding call to
	TokenUnlockTokenMoniker. TokenLockTokenMoniker grabs the
	semaphore for the token database file containing the moniker;
	TokenUnlockTokenMoniker releases it. Calling any token
	database routine before the semaphore is released will hang
	the system.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/7/89		Initial version
	jenny	1/3/93		Changed to handle shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenLockTokenMoniker	proc	far
		uses	di, es
		.enter

		xchg	ax, cx			; cx <- shared/local flag
						; ax <- group
		mov	di, dx			; di <- item
		call	TokenDBLock		; lock moniker
EC <		ERROR_C	NO_TOKEN_DATABASE_FILE_HANDLE			>
		segmov	ds, es, bx		; return segment in ds
		mov	bx, di			; return chunk in bx
		xchg	ax, cx			; restore passed values

		.leave
		ret
TokenLockTokenMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenUnlockTokenMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock moniker after drawing and release semaphore for
		token database file containing moniker.

CALLED BY:	GLOBAL
PASS:		ds	= segment of moniker
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenUnlockTokenMoniker	proc	far
		uses	ax, bx, es
		.enter
	;
	; Get the handle of the file containing the moniker.
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
		call	MemGetInfo		; ax <- token db file handle
	;
	; Unlock the moniker.
	;
		segmov	es, ds
		call	DBUnlock

if ALLOW_READERS_AND_WRITERS
		
	;
	; Let go of the file's semaphore.
	;
		mov_tr	bx, ax			; bx <- token db file handle
		call	VMReleaseExclusive
endif

		.leave
		ret
TokenUnlockTokenMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy TokenEntry for token into passed buffer

CALLED BY:	INTERNAL	TokenGetTokenInfo
				TokenLookupMoniker
PASS:		ax:bx:si = six bytes of token
		cx:dx	 = segment:offset of buffer for TokenEntry
RETURN:		carry clear if found:
			cx	= 0 if found in shared file
			cx	= LOCAL_FILE if found in local file
			buffer filled with TokenEntry
		carry set if not found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	12/17/92	Changed to use shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetToken	proc	near
		uses	ax, di, si, bp, ds, es
		.enter
	;
	; Look first in the local file and then in the shared.
	;
		call	FindTokenInLocalOrSharedFile
						; ax <- shared/local flag
		jc	exit			; done if not found
	;
	; Copy TokenEntry into buffer.
	;
		mov	si, di			; ds:si <- TokenEntry
		mov	es, cx
		mov	di, dx			; es:di <- buffer
		mov	cx, size TokenEntry
		rep movsb			; carry still clear
	;
	; Unlock map item and release file semaphore.
	;
		segmov	es, ds, bp
		mov_tr	cx, ax			; cx <- shared/local flag
		call	TokenDBUnlock
exit:
		.leave
		ret
GetToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTokenInLocalOrSharedFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a token first in first the local and then the
		shared file

CALLED BY:	INTERNAL	TokenLoadToken
				GetToken
PASS:		ax:bx:si = six bytes of token
RETURN:		carry clear if found:
			ds:*bp	= locked map item
			ds:di	= TokenEntry
			ax	= 0 if token found in shared file
			ax	= LOCAL_FILE if token found in local file
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTokenInLocalOrSharedFile	proc	near
		uses	cx
		.enter

		mov	cx, LOCAL_FILE
findIt:
		call	TokenDBLockMap		; es:*di <- map item
		jc	tryShared
		segmov	ds, es, bp
		mov	bp, di			; ds:*bp <- map item
		call	FindToken		; es:di <- TokenEntry
		jnc	found
		call	TokenDBUnlock
	;
	; Done if we've looked in both local and shared files - else
	; look in the shared file now.
	;
tryShared:
		jcxz	exit
		clr	cx			; shared file this time
		jmp	findIt
found:
		mov_tr	ax, cx
exit:
		.leave
		ret
FindTokenInLocalOrSharedFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return pointer to token entry within map item

CALLED BY:	INTERNAL	TokenRemoveToken
				FindTokenInLocalOrSharedFile
PASS:		ax:bx:si= six bytes of token
		es:*di	= locked map item
		file semaphore already grabbed
RETURN:		carry clear if found
			es:di - TokenEntry
		carry set otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/17/89	broken out
	atw	10/4/89		optimized/probably broken
	jenny	12/15/92	Axed TokenGroupEntry stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindToken	proc	far
		uses	cx
		.enter

		mov	di, es:[di]		; deref. map item
		ChunkSizePtr	es, di, cx	; cx <- size of map item
		add	cx, di			; cx <- end of map item
	;
	; Search the map item, skipping the dummy first entry.
	;
next:
		add	di, size TokenEntry
		cmp	di, cx			; at end ?
		je	depart			; if jumping, carry is clear
		cmp	ax, word ptr es:[di].TE_token.GT_chars
		jne	next
		cmp	bx, word ptr es:[di].TE_token.GT_chars+2
		jne	next
		cmp	si, word ptr es:[di].TE_token.GT_manufID
		jne	next
		stc				; success
depart:
		cmc				; toggle carry

		.leave
		ret
FindToken	endp

;---------------------------------------------------------------------------
;
; 		Utility routines
;
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenGetDBFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file handle of the shared or local token DB file

CALLED BY:	TokenGrabDBFile

PASS:		cx	= 0 if shared file wanted
			  -OR- LOCAL_FILE if local file wanted

RETURN:		carry clear if stored file handle is non-zero
			bx	= file handle
		carry set if stored file handle is zero

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	1/ 5/93    	Changed for shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenGetDBFile	proc	far

		push	ds
		mov	bx, segment dgroup
		mov	ds, bx
	;
	; Get requested file handle.
	;
		jcxz	getSharedFile
EC <		cmp	cx, LOCAL_FILE					>
EC <		ERROR_NZ	INVALID_TOKEN_DB_FLAG			>
		mov	bx, ds:[localTokenDBFileHandle]
		jmp	testIt
getSharedFile:
		mov	bx, ds:[sharedTokenDBFileHandle]
testIt:
	;
	; Report whether that file exists.
	;
		tst	bx
		jnz	done
		stc
done:
		pop	ds

		ret
TokenGetDBFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenGrabDBFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get token database file handle and grab semaphore

CALLED BY:	TokenDefineToken, TokenDBLockMap, TokenDBLock

PASS:		cx	= 0 if shared file wanted
			  -OR- LOCAL_FILE if local file wanted
RETURN:		carry clear if stored file handle is non-zero
			bx	= file handle
		carry set if stored file handle is zero
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ALLOW_READERS_AND_WRITERS

TokenGrabDBFile	proc	far
		uses	ax, cx
		.enter
	;
	; Get the file handle.
	;
		call	TokenGetDBFile		; bx <- handle

		jc	done
	;
	; We want exclusive access. If this is the shared file (cx = 0),
	; then clearly we'll only be reading. If it's the local file,
	; we might do either.
	;
		mov	ax, VMO_READ
		jcxz	grabExclusive
		mov	ax, VMO_WRITE
		clr	cx			; no time-out on grab
grabExclusive:
		call	VMGrabExclusive
		clc
done:
		
		.leave
		ret
TokenGrabDBFile	endp
else

TokenGrabDBFile	equ	TokenGetDBFile

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenDBLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the file semaphore and lock the map item for the
		shared or local token database

CALLED BY:	INTERNAL	TokenRemoveToken
				TokenListTokens
				FindTokenInLocalOrSharedFile
PASS:		cx	= 0 if item in shared file
			  -OR- LOCAL_FILE if item in local file
RETURN:		carry clear if relevant token DB file handle is non-zero
			es:*di	= ptr to map item
		carry set if file handle is zero		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	1/ 5/93    	Changed for shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenDBLockMap	proc	far
		uses	bx
		.enter

		call	TokenGrabDBFile
		jc	done			; done if no file
		call	DBLockMap
		clc				; success
done:
		.leave
		ret
TokenDBLockMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenDBLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the file semaphore and lock an item in the shared
		or local token database

CALLED BY:	INTERNAL	TokenLookupMoniker
				TokenLockTokenMoniker
PASS:		ax:di	= group and item of database item to lock 
PASS:		cx	= 0 if item in shared file
			  -OR- LOCAL_FILE if item in local file
RETURN:		carry clear if relevant token DB file handle is non-zero
			es:*di	= ptr to token database item
		carry set if file handle is zero
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/89		Initial version
	jenny	1/ 5/93    	Changed for shared/local files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenDBLock	proc	far
		uses	bx
		.enter

		call	TokenGrabDBFile
		jc	done			; done if no file
		call	DBLock
		clc				; success
done:
		.leave
		ret
TokenDBLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenDBUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock an item in the token database

CALLED BY:	INTERNAL	everything that calls TokenDBLock,
				TokenDBLockMap, FindTokenInLocalOrSharedFile

PASS:		es	= segment of item
		cx	= 0 if item in shared file
			  -OR- LOCAL_FILE if item in local file
		file semaphore has been grabbed earlier
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ALLOW_READERS_AND_WRITERS

TokenDBUnlock	proc	far
		uses	bx
		.enter

		pushf
		call	DBUnlock
		call	TokenGetDBFile
		call	VMReleaseExclusive
		popf

		.leave
		ret
TokenDBUnlock	endp

else

TokenDBUnlock	equ	DBUnlock

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReAllocMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the local token DB map item

CALLED BY:	INTERNAL	TokenRemoveToken
				AddTokenEntry
PASS:		bx	= local token DB file handle
		file semaphore grabbed earlier
RETURN:		ax:di	= map item group and item
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReAllocMap	proc	far

		call	DBGetMap
		call	DBReAlloc

		ret
ReAllocMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenReleaseDBFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update and commit the local token DB file, and release
		the semaphore.

CALLED BY:	INTERNAL	TokenDefineToken
				TokenRemoveToken
PASS:		bx	= local token DB file handle
RETURN:		carry clear
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	1/ 5/93    	Initial version
	dlitwin 11/16/93	changed FileCommit to VMUpdate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenReleaseDBFile	proc	far
	;
	; This previously called FileCommit with the FILE_NO_ERRORS
	; flag, and VMReleaseExclusive preserves flags, so callers
	; of this routine don't expect it to return a carry (and doing so
	; could cause problems).  Since we don't want to deal with errors
	; here, we clear the carry after VMUpdate just in case there was
	; one that set it.
	;

	 	call	VMUpdate
		clc
if ALLOW_READERS_AND_WRITERS
		call	VMReleaseExclusive
endif
		ret
TokenReleaseDBFile	endp

TokenCommon	ends
