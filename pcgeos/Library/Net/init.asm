COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Network Library
FILE:		init.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

DESCRIPTION:

RCS STAMP:
	$Id: init.asm,v 1.1 97/04/05 01:25:04 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetInitCode
;------------------------------------------------------------------------------

NetInitCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetLibraryEntry

DESCRIPTION:	From Adam:

		This routine gets notified on four occasions:

		1) when the library is first loaded. it can perform any sorts
		of initialization here, verifying that the resources it needs
		to run are available. If it returns carry set, the library
		isn't loaded and the geode that's importing it cannot load
		either. The AnsiC library, for example, allocates room in all
		geode's private data (new stuff that Andrew just added)
		at this time.

		2) when a new client of the library is loaded. This should
		probably be done when a new thread of a client is started,
		but at the moment it's just when the geode itself is loaded.
		Any client-specific state can be allocated by the library at
		this point.

		3) when a client of the library exits. client-specific state
		can be freed here.

		4) when the library itself is about to be unloaded.
		Any global resources (such as geode private data slots)
		can/should be freed here.

CALLED BY:	PC/GEOS kernel

PASS:		di	= LibraryCallTypes
			LCT_ATTACH	= library just loaded
			LCT_NEW_CLIENT	= client of the library just loaded
			LCT_CLIENT_EXIT	= client of the library is going away
			LCT_DETACH	= library is about to be unloaded

		cx	= handle of client geode, if LCT_NEW_CLIENT or
			  			     LCT_CLIENT_EXIT

RETURN:		carry set on error

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	Read .INI files for default drivers to load and load them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version (stolen from IM library)

------------------------------------------------------------------------------@
initCategory	char	"Net library",0
initKeyDrivers	char	"InitDrivers",0
initKeyDomain	char	"DomainName",0
NoLoadNetDriver	char	"Net Driver not loaded",0

NetLibraryEntry	proc	far
	segmov	es,dgroup, ax

	cmp	di, LCT_DETACH
	jne	notDetach

;
;	Now, free up all of the dynamically loaded drivers.
;	Since we decremented our reference count when we loaded them in
;	(see NetInitDriverLaunch) we increment it now before freeing
;	them.
;
;	NOTE: We also increment the library reference count one extra
;	time so no LCT_DETACH calls will be generated (since we are
;	already in an LCT_DETACH call, we'll exit even though our count
;	has become non-zero).
;
	mov	bx, handle 0
	call	GeodeAddReference

	mov	bx, es:[lmemBlockHandle]
	call	MemLockExcl
	mov	ds, ax
	mov	si, es:[driverArray]
	mov	bx, cs
	mov	di, offset NukeDriverCallback
	call	ChunkArrayEnum
	mov	bx, es:[lmemBlockHandle]
	call	MemUnlockShared
	clc
	jmp	exit

notDetach:
	cmp	di, LCT_ATTACH
	clc
	LONG jnz exit


; attaching, initialize LMEM block for Network Driver Chunkarrays

	segmov	ds, cs
	mov	si, offset initCategory
	call	LogWriteInitEntry

	mov	ax, 64			;initial block size
	mov	cx, (((mask HAF_LOCK) or (mask HAF_NO_ERR)) shl 8) or \
			mask HF_SWAPABLE or mask HF_SHARABLE
	call	MemAlloc
	mov	ds, ax
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	cx, 3				;3 initial handles
	mov	si, 48				;initial heap size
	call	LMemInitHeap
	call	MemUnlock
	mov	ax, handle 0				; Who owns it?
	call	HandleModifyOwner

EC <	tst	es:[lmemBlockHandle]					>
EC <	ERROR_NZ	NET_LIBRARY_ATTACHED_TWICE			>
	mov	es:[lmemBlockHandle], bx

	call	MemLockExcl				; we need to write
	mov	ds, ax

;	Create two chunk arrays in the block - one to hold domain names,
;	one to hold the handles of all the drivers we've loaded.

	mov	bx, size hptr				;BX <-element size
	clr	cx					;Extra space in header
	clr	si					;Create new handle
	clr	al					;no flags
	call	ChunkArrayCreate
	mov	es:[driverArray], si

	clr	bx					; variable size
	clr	cx
	clr	al
	clr	si
	call	ChunkArrayCreate			; *ds:si - array
	mov	es:[domainArray], si
	mov	bx, es:[lmemBlockHandle]
	call	MemUnlockExcl

; go through .INI file and load default domain name
	segmov	ds, cs, si
	mov	si, offset initCategory
	mov	cx, ds
	mov	dx, offset initKeyDomain
	mov	bp, NL_MAX_DOMAIN_NAME_LENGTH+1
	mov	di, offset defaultDomainName	;ES:DI <- place for default
						; domain
	call	InitFileReadString
EC <	WARNING_C	WARNING_NO_DEFAULT_DOMAIN	>

; load default drivers.
	mov	cx, ds
	mov	dx, offset initKeyDrivers
	clr	bp
	mov	di, cs
	mov	ax, offset cs:NetInitDriverLaunch
	call	InitFileEnumStringSection
	jnc	exit
	segmov	ds, cs
	mov	si, offset NoLoadNetDriver
	call	LogWriteEntry
	stc
exit:	
	ret
NetLibraryEntry	endp

ForceRef NetLibraryEntry



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeDriverCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees all the drivers we've loaded.

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to driver handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeDriverCallback	proc	far
	.enter

;	Increment our reference count here, as it'll get decremented when
;	we free the driver

	mov	bx, handle 0
	call	GeodeAddReference

;	Free the net driver

	mov	bx, ds:[di]
	call	GeodeFreeDriver
EC <	ERROR_NC NET_DRIVER_NOT_EXITED					>
	.leave
	ret
NukeDriverCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetInitDriverLaunch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given net driver name, launches it 

CALLED BY:	InitFileEnumStringSection
PASS:		ds:si - null-terminated driver name
		es - dgroup
		cx    - length of name
RETURN:		carry clear

DESTROYED:	?

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
netDriverDirectory	char	"net", 0

NetInitDriverLaunch	proc	far
		.enter
		call	FilePushDir

	;
	; Switch to system directory and try and load the thing. It must
	; be a driver and any thread it spawns will be low-priority.
	; 
		push	ds
		segmov	ds, cs
		mov	dx, offset netDriverDirectory
		mov	bx, SP_SYSTEM
		call	FileSetCurrentPath
		pop	ds
		jc	done
		clr	ax	
		clr	bx	
		call	GeodeUseDriver
EC <		WARNING_C	COULD_NOT_LOAD_NET_DRIVER		>
		jc	done

	; Append the handle of the driver to the array of drivers that we want
	; to free.

		mov	cx, bx			;CX <- handle of driver
		push	ds
		mov	bx, es:[lmemBlockHandle]
		call	MemLockExcl
		mov	ds, ax
		mov	si, es:[driverArray]
		call	ChunkArrayAppend
		mov	ds:[di], cx
		call	MemUnlockShared

	;We want to get a LCT_DETACH call whenever the last client that is
	; not one of our drivers does a GeodeFreeLibrary on us, so decrement
	; the in-use  count here.
	; NOTE: We cannot use GeodeRemoveReference here, as we only have the
	; one reference from the coprocessor library until such time as we
	; return from LCT_ATTACH. If we were to use GeodeRemoveReference, we
	; would unload ourselves, which wouldn't be good.

		mov	bx, handle 0
		call	MemLock
		mov	ds, ax
		dec	ds:[GH_geodeRefCount]
EC <		ERROR_S	NET_DRIVER_DID_NOT_REFERENCE_NET_LIBRARY	>
		call	MemUnlock
		pop	ds
		clc
done:
		call	FilePopDir
		.leave
		ret
NetInitDriverLaunch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetRegisterDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers a Domain name passed from the network driver.

CALLED BY:	EXTERNAL and NetRegisterDomainXIP

PASS:		ds:si	- domain name (null terminated)
		cx:dx	- strategy routine
		bx	- handle of driver
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetRegisterDomain	proc	far
	uses	ax,bx,cx,dx,si,di,bp, ds, es
	.enter

;	Extract domain from the domain string

	segmov	es, ss
	sub	sp, NL_MAX_DOMAIN_NAME_LENGTH+2
	mov	di, sp
	pushdw	cxdx
	movdw	cxdx, dssi
	call	GetDomainFromDomainString
	popdw	cxdx
	segmov	ds, ss
	mov	si, sp
	

	push	si
	push	cx
	call	strlen	
	segmov	es, dgroup, ax
	mov	bp, bx
	mov	bx, es:[lmemBlockHandle]
	mov	si, es:[domainArray]
	segmov	es, ds, ax
	call	MemLockExcl
	mov	ds, ax				; *ds:si - chunkarray
	mov	ax, cx				;  size
	add	ax, size DomainStruct		
	call	ChunkArrayAppend
	pop	ds:[di].DS_strategy.segment
	mov	ds:[di].DS_strategy.offset, dx
	mov	ds:[di].DS_driverHandle, bp
	segxchg	es,ds
	pop	si				; ds:si - domain name
	add	di, offset DS_domainName
	call	strncpy
	call	MemUnlockShared

	add	sp, NL_MAX_DOMAIN_NAME_LENGTH+2
	.leave
	ret
NetRegisterDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetUnregisterDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters a Domain.

CALLED BY:	EXTERNAL and NetUnregisterDomainXIP
PASS:		ds:si 	- domain name (null terminated)
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetUnregisterDomain	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	call	FindDomain
	mov	bp, ax
	jc 	exit
	segmov	es, dgroup, ax
	mov	bx, es:[lmemBlockHandle]
	mov	si, es:[domainArray]
	call	MemLockExcl
	mov	ds, ax				; *ds:si - chunkarray
	mov	ax, bp
	call	ChunkArrayElementToPtr
	call	ChunkArrayDelete
	call	MemUnlockShared	
	clc
exit:
	.leave
	ret
NetUnregisterDomain	endp

NetInitCode	ends

if FULL_EXECUTE_IN_PLACE

NetXIPCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetRegisterDomainXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers a Domain name passed from the network driver.

PASS:		ds:si	- fptr domain name (null terminated)
		cx:dx	- strategy routine
		bx	- handle of driver
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	4/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetRegisterDomainXIP	proc	far
		uses	ax	
		.enter
	;
	; Copy the string to fixed memory
	;
		mov_tr	ax, cx
		clr	cx			; null terminated
		call	SysCopyToStackDSSI	; ds:si <- domain name on stack
		mov_tr	cx, ax			; cx:dx <- strategy routine
	;
	; Call the NetRegisterDomain proc which resides in movable memory
	; passing it the strings on the stack.
	;
		call	NetRegisterDomain
	;
	; Restore the stack
	;
		call	SysRemoveFromStack

		.leave
		ret
NetRegisterDomainXIP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetUnregisterDomainXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters a Domain.

CALLED BY:	EXTERNAL
PASS:		ds:si 	- fptr to domain name (null terminated)
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	4/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetUnregisterDomainXIP	proc	far
		uses	ax
		.enter
	;
	; Copy the string to fixed memory
	;
		mov_tr	ax, cx
		clr	cx			; null terminated
		call	SysCopyToStackDSSI	; ds:si <- domain name on stack
		mov_tr	cx, ax			; cx:dx <- strategy routine
	;
	; Call the NetUnregisterDomain proc which resides in movable memory
	; passing it the strings on the stack.
	;
		call	NetUnregisterDomain
	;
	; Restore the stack
	;
		call	SysRemoveFromStack

		.leave
		ret
NetUnregisterDomainXIP	endp

NetXIPCode	ends

endif

