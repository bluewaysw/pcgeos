COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		socketLoad.asm

AUTHOR:		Eric Weber, Nov 20, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT LoadAttach              Initialize socket loads from init file

    EXT SocketParseLoadString   Parse a load string and call
				SocketAddLoadOnMsgMem

    INT SocketAsciiToHex        Convert a string of hex digits into data

    INT SocketActivateLoadOnMsg Load the geode specified by a LoadRequest

    EXT SocketAddLoadOnMsgMem   Add a load request to socket lib's data
				structures

    INT SocketCreateLoadRequest create a LoadRequest chunk

    INT SocketAddLoadOnMsgFile  Write LoadOnMsg information to init file

    INT SocketRemoveLoadOnMsgFile 
				Remove a LoadOnMsg from the init file

    INT SocketRemoveLoadOnMsgMem 
				Remove a LoadOnMsg from the control block

    INT DeleteLoadRequestString Remove a load string from the .ini file

    INT CompareLoadString       Compare a load string to the passed
				parameters

    INT BuildLoadRequestString  Convert a load request into a string

    INT SocketHexToAscii        Convert a data buffer to hex notation

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94   	Initial revision


DESCRIPTION:
	LoadOnMsg code

	$Id: socketLoad.asm,v 1.1 97/04/07 10:46:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

loadKey		char	"LoadOnMsg",0
deleteSem	Semaphore

idata	ends

UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize socket loads from init file

CALLED BY:	(INTERNAL) SocketEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadAttach	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter
	;
	; process each load request in the init file
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	si, offset ds:[socketCategory]	; ds:si = category
		mov	cx, ds
		mov	dx, offset ds:[loadKey]		; cx:dx = key
		mov	di, vseg SocketParseLoadString
		mov	ax, offset SocketParseLoadString ; di:ax = callback
		mov	bp, mask IFRF_READ_ALL
		call	InitFileEnumStringSection
done::
		.leave
		ret
LoadAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketParseLoadString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a load string and call SocketAddLoadOnMsgMem

CALLED BY:	(EXTERNAL) LoadAttach via InitFileEnumStringSection
PASS:		ds:si	- load string
		cx	- number of chars in section
RETURN:		carry clear
DESTROYED:	evrything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketParseLoadString	proc	far
DBCS <		shl	cx			; number of bytes	>
		stringSize	local	word	push cx
		domainBlock	local	hptr
		pathBlock	local	hptr
		disk		local	hptr
		header		local	LoadStringHeader
		.enter
		clr	ss:[domainBlock]
		clr	ss:[pathBlock]
	;
	; convert 2*(size header) "chars" into the binary header information
	;
		segmov	es,ss
		lea	di, ss:[header]
		mov	cx, 2*(size header)	; # hex digits
		call	SocketAsciiToHex
LONG		jc	invalid
	;
	; verify the size of the string
	;
DBCS <		shl	cx			; # bytes in DBCS	>
		add	cx, ss:[header].LSH_domainSize
LONG		jc	invalid
		add	cx, ss:[header].LSH_diskSize
LONG		jc	invalid
		add	cx, ss:[header].LSH_pathSize
LONG		jc	invalid
		cmp	cx, ss:[stringSize]
LONG		ja	invalid			; corrupt string
	;
	; allocate a buffer for the domain name, if one exists
	;
allocDomain::
		mov	ax, ss:[header].LSH_domainSize
		tst	ax
		jz	allocDisk
		inc	ax			; make room for null
DBCS <		inc	ax						>
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; ax=seg, bx=handle
		jc	allocErr
		mov	es,ax			
		clr	di			; es:di <- dest
		mov	ss:[domainBlock], bx
	;
	; copy domain name
	;
		mov	cx, ss:[header].LSH_domainSize
EC <		call	ECCheckMovsb					>
		rep	movsb
		clr	ax
		LocalPutChar	esdi,ax		; write a null
	;
	; allocate buffer for disk info
	;
allocDisk::
		mov	ax, ss:[header].LSH_diskSize
		shr	ax			; disk info is hex encoded
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; ax=seg, bx=handle
		jc	allocErr
		mov	es,ax
	;
	; copy disk info
	;
		clr	di
		mov	cx, ss:[header].LSH_diskSize
DBCS <		shr	cx			; #bytes -> #hex digits	>
		call	SocketAsciiToHex
		jc	invalid
	;
	; convert disk info into disk handle
	;
		push	ds,si
		segmov	ds,es
		mov	si,di
		call	UserDiskRestore		; ax = disk handle
		pop	ds,si
	;
	; save disk handle and discard the buffer
	;
		pushf
		call	MemFree
		popf
		mov	ss:[disk], ax
		jc	invalid
	;
	; allocate a buffer for the path
	;
allocPath::
		mov	ax, ss:[header].LSH_pathSize
		inc	ax			; leave room for null
DBCS <		inc	ax						>
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		jc	allocErr
		mov	ss:[pathBlock], bx
		mov	es,ax
	;
	; copy path info
	; di = 0 from call to SocketAsciiToHex for disk data
	;
		mov	cx, ss:[header].LSH_pathSize
EC <		call	ECCheckMovsb					>
		rep	movsb
		clr	ax
		LocalPutChar	esdi, ax	; write a NULL
	;
	; get pointers to domain and path
	;
getSegs::
		segmov	ds,es
		clr	si,di			; ds:si = path
		clr	dx
		mov	bx, ss:[domainBlock]
		tst	bx
		jz	addMem
		call	MemDerefES
		mov	dx,es			; dx:di = domain
	;
	; call SocketAddLoadOnMsgMem
	;
addMem:
		movdw	axbx, ss:[header].LSH_port
		mov	cx, ss:[header].LSH_loadType
		push	bp
		mov	bp, ss:[disk]
		call	SocketAddLoadOnMsgMem
		pop	bp
		jnc	cleanup
	;
	; something went wrong
	;
	; if any non-EC code is added here, check the jmp statement
	;
allocErr:
EC <		WARNING IGNORING_LOAD_STRING_DUE_TO_ALLOC_FAILURE	>
EC <		jmp	cleanup						>
invalid:
EC <		WARNING	INVALID_LOAD_STRING				>
	;
	; free the temporary blocks
	;
cleanup:
		mov	bx, ss:[pathBlock]
		tst	bx
		jz	noPath
		call	MemFree
noPath:
		mov	bx, ss:[domainBlock]
		tst	bx
		jz	done
		call	MemFree
	;
	; always exit with carry clear
	; even if this string was bad, the next may be fine
	;
done:
		clc
		.leave
		ret
		
SocketParseLoadString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAsciiToHex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string of hex digits into data

CALLED BY:	(INTERNAL) SocketParseLoadString
PASS:		ds:si	- input buffer
		cx	- number of hex digits in input buffer
		es:di	- output buffer
		(at least half as large as input buffer)
RETURN:		si	- pointing past converted data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAsciiToHex	proc	near
		uses	ax,cx,dx,di
		.enter
		jcxz	done
EC <		call	validate					>
		shr	cx
top:
	;
	; read and convert high nibble
	;
SBCS <		lodsb							>
DBCS <		lodsw							>
		call	convertNibble
		jc	done
	;
	; multiply by 8 and store it in ah (or dh for DBCS)
	;
		shl	al
		shl	al
		shl	al
		shl	al
SBCS <		mov_tr	ah,al						>
DBCS <		mov_tr	dh,al						>
SBCS <		lodsb							>
DBCS <		lodsw							>
	;
	; now read and convert low nibble
	;
		call	convertNibble
		jc	done
	;
	; merge the two nibbles and output the byte
	;
SBCS <		or	al,ah						>
DBCS <		or	al,dh						>
		stosb
		loop	top
done:
		.leave
		ret
	;
	; Internal routine to convert a hex digit in ASCII to its binary
	; equivalent while ensuring the digit itself is a valid hex digit.
	;
	; Pass:		al	= ASCII hex digit
	; Return:	carry set if digit invalid
	; 		carry clear if digit is fine:
	; 			al	= 0-15
convertNibble:
	sub	al, '0'
	jb	cNDone			; => below '0', so err
	cmp	al, 9
	jbe	cNDoneOK		; => must be '0'-'9'

	sub	al, 'A'-'0'		; convert 'A'-'F' to 0-5
	jb	cNDone			; => between '9' and 'A', so err
	cmp	al, 5			; 'A'-'F' ?
	jbe	cNDoneAdd10		; yes -- happiness

	sub	al, 'a'-'A'		; assume lower-case 'a'-'f'
	jb	cNDone			; between 'F' and 'a', so err
	cmp	al, 6			; 'a'-'f'?
	cmc				; invert sense so carry set if not
	jb	cNDone			; not
cNDoneAdd10:
	add	al, 10			; convert 0-5 to 10-15
cNDoneOK:
	clc
cNDone:
	retn

if ERROR_CHECK
validate:
	;
	; Ensure the pointers are valid at the start
	;
		Assert	fptr dssi
		Assert	fptr esdi
	;
	; Ensure that the pointers will be valid when we're done.
	;
		push	si, di, cx

DBCS <		shl	cx			; num bytes		>
		add	si, cx
DBCS <		shr	cx			; num hex digits	>
		dec	si
DBCS <		dec	si						>
		Assert	fptr dssi

		shr	cx
		add	di, cx
		dec	di
DBCS <		dec	di						>
		Assert	fptr esdi

		pop	si, di, cx
		retn
endif		
SocketAsciiToHex	endp

UtilCode	ends

StrategyCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketActivateLoadOnMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the geode specified by a LoadRequest

CALLED BY:	(INTERNAL) ConnectionOpen, SocketConnectRequest
PASS:		*ds:si	- PortInfo
RETURN:		carry set if unable to load
		ds - fixed up (might have moved while control block was
		     relinquished)
DESTROYED:	nothing
SIDE EFFECTS:	The SocketControl block is released during the load, to allow
     			the loaded geode to make calls to this library. The
			block is grabbed on return, however.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketActivateLoadOnMsg	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
		Assert	writeControl, ds
	;
	; copy LoadRequest so we can release the control block
	;
		mov	si, ds:[si]
		mov	si, ds:[si].PI_loadInfo
		mov	di, ds:[si]
		ChunkSizePtr	ds, di, ax
		mov	cx, ALLOC_FIXED
		push	ax
		call	MemAlloc
		pop	cx		; cx <- size of LoadRequest
		WARNING_C	CANT_ALLOCATE_LOADREQUEST_BLOCK
		jc	exit

		push	bx		; save handle for freeing

		mov	es, ax
		mov	si, di
		clr	di
		shr	cx
		rep	movsw
		jnc	10$
		movsb
10$:
	;
	; Release the control block, so the thing we load can make requests of
	; the library.
	;
		call	SocketControlEndWrite
		mov	ds, ax
	;
	; check load type
	;
		cmp	ds:[LR_loadType], SLT_GEODE_LOAD
		je	loadGeode
	;
	; invoke UserLoadApplication
	;
		clr	ah
		clr	cx
		clr	dx
		mov	bx, ds:[LR_disk]
		lea	si, ds:[LR_path]
		call	UserLoadApplication
		WARNING_C CANT_LOAD_APPLICATION
		jmp	done
	;
	; before invoking GeodeLoad, we need to switch to the directory
	; containing the geode
	;
loadGeode:
	;
	; Push to the root of the disk containing the thing to load.
	;
		call	FilePushDir
		
		push	ds
		mov	bx, ds:[LR_disk]
		segmov	ds, cs
		mov	dx, offset rootPath
		call	FileSetCurrentPath
		pop	ds
		jc	cleanup
	;
	; load the geode
	;
loadit::
		mov	si,offset LR_path	; ds:si = filename
		mov	al, PRIORITY_STANDARD
		clr	ah			; no flags
		clr	cx,dx,di,bp		; no attributes or parameters
		call	GeodeLoad
	;
	; restore working directory
	;
cleanup:
		call	FilePopDir
done:
		pop	bx			; bx <- LoadRequest block
		pushf				; save error flag
		call	MemFree
		call	SocketControlStartWrite
		popf
exit:
		.leave
		ret

rootPath	TCHAR	C_BACKSLASH, 0
SocketActivateLoadOnMsg	endp

StrategyCode	ends

ExtraApiCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddLoadOnMsgMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a load request to socket lib's data structures

CALLED BY:	(EXTERNAL) SocketAddLoadOnMsg, SocketAddLoadOnMsgInDomain,
		SocketParseLoadString
PASS:		ds:si	- path to geode
		bp	- disk handle
		dx:di	- domain (dx = 0 if none)
		axbx	- SocketPort
		cx	- SocketLoadType

RETURN:		carry	- set if error
		ax	- SocketError if carry set
			  preserved otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddLoadOnMsgMem	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		domain	local	fptr.char	push dx,di
		portNum	local	SocketPort	push ax,bx
		.enter
	;
	; lock control block
	;
		push	ds,si
		call	SocketControlStartWrite
		pop	es,di
	;
	; Create the load request
	;
		mov	dx, ss:[bp]			; dx = disk handle
		call	SocketCreateLoadRequest		; dx = load request
		jc	noRequest
	;
	; Locate the port
	;
		push	dx
		movdw	axbx, ss:[portNum]
		movdw	dxdi, ss:[domain]
		call	SocketFindOrCreatePort		; bx = port
		pop	dx
		jc	noPort
	;
	; create a listen queue, if one doesn't exist
	;
checkQueue::
		mov	si, ds:[bx]			; ds:si = PortInfo
		tst	ds:[si].PI_listenQueue
		jnz	insert
		mov	si,bx				; *ds:si = PortInfo
		mov	cx, LOM_LISTEN_QUEUE_SIZE
		call	SocketCreateListenQueue
		jc	noQueue
	;
	; record LoadRequest into port
	; dx = chunk handle of request
	; free any previous LoadRequest for this port
	;
insert:
		mov	si, ds:[bx]		; ds:si = PortInfo
		xchg	ds:[si].PI_loadInfo, dx
		tst	dx
		jz	normal
		mov	ax, dx
		call	LMemFree
	;
	; normal exit
	;
normal:
		mov	ax, ss:[portNum].SP_manuf
		clc
done:
		call	SocketControlEndWrite
		.leave
		ret
	;
	; we couldn't allocate a listen queue - free port and request
	; 
noQueue:
		mov	si,bx			; *ds:si = PortInfo
		call	SocketFreePort
	;
	; we couldn't allocate the port - free request
	;
noPort:
		mov	ax,dx			; chunk handle of request
		call	LMemFree
	;
	; we couldn't allocate a LoadRequest
	;		
noRequest:
		stc
		mov	ax, SE_OUT_OF_MEMORY
		jmp	done
SocketAddLoadOnMsgMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketCreateLoadRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a LoadRequest chunk

CALLED BY:	(INTERNAL) SocketAddLoadOnMsgMem
PASS:		ds	- control segment
		es:di	- pathname
		dx	- disk handle
		cx	- SocketLoadType
RETURN:		dx	- chunk handle of LoadRequest
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketCreateLoadRequest	proc	near
		uses	ax,bx,cx,si,di
		.enter
	;
	; save load type
	;
		mov	bx,cx
	;
	; compute size of path
	;
		call	LocalStringSize		; cx = size excluding null
DBCS <		inc	cx						>
		inc	cx			; cx = size including null
		add	cx, size LoadRequest	; cx = size of entire chunk
		call	LMemAlloc		; *ds:ax = LoadRequest
		jc	done
	;
	; initialize LoadRequest
	;
init::
		segxchg	ds,es
		mov	si,di			; ds:si = path
		mov	di,ax
		mov	di,es:[di]		; es:di = LoadRequest
		mov	es:[di].LR_type, CCT_LOAD_REQUEST
		mov	es:[di].LR_loadType, bx
		mov	es:[di].LR_disk, dx
	;
	; copy the path
	;
		push	di
		add	di, offset LR_path
		sub	cx, size LoadRequest	; size of path with null
EC <		call	ECCheckMovsb					>
		rep	movsb
		pop	di
	;
	; set return value and exit
	;
		segxchg	ds,es
		mov	dx,ax
done:
		.leave
		ret
SocketCreateLoadRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddLoadOnMsgFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write LoadOnMsg information to init file

CALLED BY:	(INTERNAL) SocketAddLoadOnMsg, SocketAddLoadOnMsgInDomain
PASS:		ds:si	- path to geode
		bp	- disk handle
		dx:di	- domain (es = SEGMENT_NULL if none)
		axbx	- SocketPort
		cx	- SocketLoadType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddLoadOnMsgFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; build the new information string
	;
		push	bx
		call	BuildLoadRequestString	; es = string, bx = handle
		mov	bp,bx
		pop	bx
	;
	; locate and nuke any previous string
	;
		call	DeleteLoadRequestString
	;
	; insert the new string
	;
		clr	di
		call	InitFileWriteStringSection
		call	InitFileCommit
	;
	; discard string
	;
		mov	bx,bp
		call	MemFree
		.leave
		ret
SocketAddLoadOnMsgFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveLoadOnMsgFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a LoadOnMsg from the init file

CALLED BY:	(INTERNAL) SocketRemoveLoadOnMsg,
		SocketRemoveLoadOnMsgInDomain
PASS:		axbx	- port
		dx:di	- domain (dx = 0 if none)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveLoadOnMsgFile	proc	near
		uses	cx,dx,si,ds
		.enter
		call	DeleteLoadRequestString
		.leave
		ret
SocketRemoveLoadOnMsgFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketRemoveLoadOnMsgMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a LoadOnMsg from the control block

CALLED BY:	(INTERNAL) SocketRemoveLoadOnMsg,
		SocketRemoveLoadOnMsgInDomain
PASS:		axbx	- port
		dx:di	- domain
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketRemoveLoadOnMsgMem	proc	near
		uses	ax,cx,dx,si,di,bp,ds
		.enter
		call	SocketControlStartWrite
	;
	; locate the domain
	;
		tst	dx
		jz	getPort
		push	bx
		mov	bp,di
		call	SocketFindDomainLow	; bx = domain
		mov	dx,bx
		pop	bx
		jc	done			; no such domain
	;
	; locate the port
	;
	; if we find a restricted port on an unrestricted search, or
	; vice versa, just ignore it
	;
getPort:
		call	SocketFindPort		; ds:di = PortArrayEntry
		jc	done			; no such port
		mov	si, ds:[di].PAE_info
		mov	di, ds:[si]
		cmp	dx, ds:[di].PI_restriction
		jne	done
		clr	ax
		xchg	ax, ds:[di].PI_loadInfo
		tst	ax
		jz	done			; no load request pending
	;
	; free the LoadRequest
	;
		call	LMemFree
	;
	; if nobody is listening, clear out the listen queue now
	;
		tst	ds:[di].PI_listener
		jnz	queueOK
		mov	di,si			; *ds:di = PortInfo
		call	FreePortListenQueue
queueOK:
	;
	; free the port if needed
	;
		call	SocketFreePort
done:
		call	SocketControlEndWrite
		.leave
		ret
SocketRemoveLoadOnMsgMem	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteLoadRequestString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a load string from the .ini file

CALLED BY:	(INTERNAL) SocketAddLoadOnMsgFile,
		SocketRemoveLoadOnMsgFile
PASS:		axbx	- port
		dx:di	- domain
RETURN:		ds:si	- "socket" category
		cx:dx	- "LoadOnMsg" key
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteLoadRequestString	proc	near
		uses	ax,bx,di,es
		port	local	SocketPort	push ax,bx
		domain	local	fptr.char	push dx,di
		index	local	word
		domSize	local	word
		buffer	local	PortDomainBuffer
		ForceRef domain
		.enter
	;
	; compute size of domain in ASCII
	;
		clr	cx
		tst	dx
		jz	gotSize
		mov	es,dx
		call	LocalStringSize		; cx = size excluding null
gotSize:
		mov	ss:[domSize], cx
		segmov	ds,ss
		segmov	es,ss
		lea	si, ss:[domSize]
		lea	di, ss:[buffer].PDB_domainSize
		mov	cx, size word
		call	SocketHexToAscii	; convert size to ascii
	;
	; compute port number in ASCII
	;
getPort::
		lea	si, ss:[port]
		lea	di, ss:[buffer].PDB_port
		mov	cx, size SocketPort
		call	SocketHexToAscii
	;
	; prevent anyone else from deleting to make sure the index
	; stays valid between the time we find it and when we delete it
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		PSem	ds, deleteSem
	;
	; locate the string to delete
	;
locate::
		push	bp
		mov	bx,bp				; ss:bx = port
		mov	si, offset socketCategory
		mov	cx, ds
		mov	dx, offset loadKey
		mov	bp, InitFileReadFlags <IFCC_INTACT,0,1,0>
		mov	di, vseg CompareLoadString
		mov	ax, offset CompareLoadString
		call	InitFileEnumStringSection	; bx = index
		pop	bp
		cmc
		jc	done
	;
	; delete it
	;
delete::
		mov	ax, ss:[index]
		mov	si, offset socketCategory
		mov	cx, ds
		mov	dx, offset loadKey
		call	InitFileDeleteStringSection
done:
		VSem	ds, deleteSem
		.leave
		ret
DeleteLoadRequestString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareLoadString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a load string to the passed parameters

CALLED BY:	(INTERNAL) DeleteLoadRequestString
			via InitFileEnumStringSection
PASS:		ds:si	- load string
		dx	- section #
		cx	- length of section
		ss:bx	- inherited stack frame
RETURN:		carry	- set if located
		ss:[index] - section #
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version
	PT	7/24/96		Fixed DBCS bug

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareLoadString	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter inherit DeleteLoadRequestString
		mov	bp,bx			; bp = stack frame
DBCS <		shl	cx			; cx = size		>
	;
	; check to be sure the string section is long enough
	;
		mov	ax, 2*(size LoadStringHeader)
		add	ax, ss:[domSize]
		cmp	cx, ax
		cmc				; invert sense of jump
		jnb	done			; string is too short
	;
	; the first 12 "bytes" should match the ASCII port number and
	; domain size we've already computed
	;
		mov	cx, size PortDomainBuffer
		segmov	es, ss
		lea	di, ss:[buffer]
		repe	cmpsb
		clc
		jne	done
	;
	; skip forward in string section to the domain name
	;
		movdw	esdi, ss:[domain]
		mov	cx, ss:[domSize]
SBCS <		add	si, 2*(size LoadStringHeader) - size PortDomainBuffer>
DBCS <		add	si, 4*(size LoadStringHeader) - size PortDomainBuffer>
	;
	; compare domain names
	;
		jcxz	match
		repe	cmpsb
		clc
		jne	done
	;
	; we found a match
	;
match:
		mov	ss:[index], dx
		stc
done:		
		.leave
		ret
CompareLoadString	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildLoadRequestString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a load request into a string

CALLED BY:	(INTERNAL) SocketAddLoadOnMsgFile
PASS:		ds:si	- path to geode
		bp	- disk handle
		dx:di	- domain (dx = 0 if none)
		axbx	- SocketPort
		cx	- SocketLoadType
RETURN:		es	- string to use
		bx	- handle of es
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	string contains, in order:
	port		dword - hex encoded (8 bytes)
	domain size	word  - hex encoded (4 bytes)
	disk size	word  - hex encoded (4 bytes)
			(this is size of the encoded disk data, not the bytes)
	path size	word  - hex encoded (4 bytes)
	load type	word - hex encoded (4 bytes)
	domain		unterminated string
	saved disk	hex encoded
	path		unterminated string

	(Double each bytes for DBCS encoding)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildLoadRequestString	proc	near
		uses	ax,cx,dx,si,di,bp
		pathPtr		local	fptr.char	push ds,si
		domainPtr	local	fptr.char	push dx,di
		header		local	LoadStringHeader
		diskBuf		local	hptr
		outputBuf	local	hptr
		.enter
	;
	; save port number
	;
		movdw	ss:[header].LSH_port, axbx
		mov	ss:[header].LSH_loadType, cx
	;
	; compute sizes of strings
	;
stringSize::
		clr	cx
		tst	dx
		jz	noDomain
		call	LocalStringSize		; cx = size in bytes w/o null
noDomain:
		mov	ss:[header].LSH_domainSize, cx
		movdw	esdi, ss:[pathPtr]
		mov	dx,cx			; dx = cumulative size
		call	LocalStringSize
		mov	ss:[header].LSH_pathSize, cx
		add	dx,cx
	;
	; compute size of disk handle
	;
getDiskSize::
		mov	bx, ss:[bp]		; disk handle
		clr	cx
		call	DiskSave		; cx = size of data
	;
	; allocate a buffer for the disk
	;
diskAlloc::
		mov	ax, cx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		push	ax, bx			; buffer size, disk handle
		call	MemAlloc
		mov	ss:[diskBuf], bx
		pop	cx, bx			; buffer size, disk handle
		mov	es, ax
		clr	di
		call	DiskSave		; cx = size
	;
	; save final size
	;
		shl	cx			; allow for hex encoding
DBCS <		shl	cx			; double-byte encoding	>
		mov	ss:[header].LSH_diskSize, cx
		add	dx,cx			; dx = total size
		inc	dx			; leave room for NULL
DBCS <		inc	dx						>
	;
	; allocate a buffer to hold string
	;
alloc::
SBCS <		add	dx, 2*(size LoadStringHeader)			>
DBCS <		add	dx, 4*(size LoadStringHeader)			>
		mov	ax, dx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	ss:[outputBuf], bx
	;
	; write out encoded header
	;
doHeader::
		mov	es,ax
		clr	di			; es:di = output buffer
		segmov	ds,ss
		lea	si, ss:[header]		; ds:si = input buffer
		mov	cx, size LoadStringHeader
		call	SocketHexToAscii
	;
	; copy domain
	;
domain::
		mov	cx, ss:[header].LSH_domainSize
		jcxz	disk
		movdw	dssi, ss:[domainPtr]
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; write out disk
	;
disk:
		mov	bx, ss:[diskBuf]
		call	MemDerefDS
		clr	si
		mov	cx, ss:[header].LSH_diskSize
		shr	cx			; get pre-converted size
DBCS <		shr	cx			; number of bytes	>
		call	SocketHexToAscii
		call	MemFree			; discard temporary buffer
	;
	; copy the path
	;
		mov	cx, ss:[header].LSH_pathSize
		movdw	dssi, ss:[pathPtr]
EC <		call	ECCheckMovsb					>
		rep	movsb
	;
	; append a NULL
	;
		mov	ax, C_NULL
		LocalPutChar	esdi, ax
		mov	bx, ss:[outputBuf]
		.leave
		ret

BuildLoadRequestString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketHexToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a data buffer to hex notation

CALLED BY:	(INTERNAL) BuildLoadRequestString, DeleteLoadRequestString
PASS:		ds:si	- input buffer
		cx	- size of input buffer
		es:di	- output buffer
		(at least twice as large as input buffer)
		(at least 4X as large for DBCS environment)

RETURN:		si,di	- pointing past converted data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/22/94    	Initial version
	PT	7/24/96		DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nibbles		db	"0123456789ABCDEF"
SocketHexToAscii	proc	near
		uses	ax,bx,cx
		.enter
		jcxz	done
EC <		call	validate					>
		mov	bx, offset nibbles
top:
	;
	; read one byte
	;
		lodsb
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
SBCS <		stosb							>
DBCS <		clr	ah						>
DBCS <		stosw							>
	;
	; compute second nibble
	;
		pop	ax
		and	al, 0fh
		xlatb	cs:
SBCS <		stosb							>
DBCS <		clr	ah						>
DBCS <		stosw							>
	;
	; back for more
	;
		loop	top
done:
		.leave
		ret
if ERROR_CHECK
validate:
	;
	; Ensure the pointers are valid at the start
	;
		Assert	fptr dssi
		Assert	fptr esdi
	;
	; Ensure that the pointers will be valid when we're done.
	;
		push	si, di, cx

		add	si, cx
		dec	si
		Assert	fptr dssi

		shl	cx			; # hex digits
DBCS <		shl	cx			; # of bytes		>
		add	di, cx
		dec	di
DBCS <		dec	di						>
		Assert	fptr esdi

		pop	si, di, cx
		retn
endif		

SocketHexToAscii	endp

ExtraApiCode	ends

