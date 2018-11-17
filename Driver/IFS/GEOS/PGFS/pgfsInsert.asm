COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pgfsInsert.asm

AUTHOR:		Adam de Boor, Sep 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/29/93		Initial revision


DESCRIPTION:
	Functions to cope with card insertion.
		

	$Id: pgfsInsert.asm,v 1.1 97/04/18 11:46:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSIHandleInsertion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the inserted card is one we like.

CALLED BY:	PGFSCardServicesCallback (CSEC_CARD_INSERTION)
PASS:		cx	= socket
		dx	= info
		ds	= dgroup
RETURN:		carry set on error, clear on success
		ax	= CardServicesReturnCode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSIHandleInsertion proc	near
		uses	bx, cx, si, di, ds, es

tupleVars	local	TupleVars

		.enter
		mov	ds:[inserting], TRUE
		push	ds:[curSocketPtr]
EC <		push	ds:[fsMapped]					>
	;
	; In case we don't find any tuples (?), set the FS Address to
	; the start of common memory, so we can check there regardless.
	;
		call	PGFSUDerefSocket
		mov	ds:[curSocketPtr], bx
		clrdw	ds:[bx].PGFSSI_address
		
tupleDataVars equ <tupleVars.TV_common.CSGTU_data>
tupleSearchVars equ <tupleVars.TV_common.CSGTU_search>

	;
	; Look for a format tuple
	;
		mov	ss:[tupleSearchVars].CSGTA_socket, cx
		clr	ss:[tupleSearchVars].CSGTA_attributes
		mov	ss:[tupleSearchVars].CSGTA_desiredTuple, 
				CISTPL_FORMAT
		segmov	es, ss
		lea	bx, ss:[tupleVars]
		mov	cx, CSGetTupleArgs
		CallCS	CSF_GET_FIRST_TUPLE, DONT_LOCK_BIOS
		LONG jc	requestWindow
readFormat:
	;
	; Read the address and size
	;
		mov	ss:[tupleDataVars].CSGTDA_tupleOffset,
				offset TPLFMT_offset 
		mov	ss:[tupleDataVars].CSGTDA_maxData,
				size TPLFMT_offset + size TPLFMT_size

		mov	cx, size CSGetTupleDataArgs + 2 * size dword
		CallCS	CSF_GET_TUPLE_DATA, DONT_LOCK_BIOS
		jc	fail

		push	bx
		mov	bx, ds:[curSocketPtr]
		movdw	ds:[bx].PGFSSI_address, ss:[tupleVars].TV_data, ax
		pop	bx
		
	;
	; Now, look for an "ORG" tuple
	;
		mov	ss:[tupleSearchVars].CSGTA_desiredTuple, 
				CISTPL_ORG
		mov	cx, size CSGetTupleArgs
		CallCS	CSF_GET_NEXT_TUPLE, DONT_LOCK_BIOS
		jc	fail

	;
	; Fetch the type and name
	;
		mov	cx, size CSGetTupleDataArgs + \
				size TPLORG_type + \
				size fsString
		
		mov	ss:[tupleDataVars].CSGTDA_tupleOffset,
				offset TPLORG_type
		mov	ss:[tupleDataVars].CSGTDA_maxData,
				size TPLORG_type + size fsString

		CallCS	CSF_GET_TUPLE_DATA, DONT_LOCK_BIOS
		jc	fail

		cmp	{byte} ss:[tupleVars].TV_data, TPLOT_FS
		jne	nextFormat

		lea	di, ss:[tupleVars].TV_data[1]
		mov	si, offset fsString
		mov	cx, size fsString
		repe	cmpsb
		je	requestWindow
nextFormat:
		mov	ss:[tupleSearchVars].CSGTA_desiredTuple,
				CISTPL_FORMAT
		mov	cx, size CSGetTupleArgs
		CallCS	CSF_GET_NEXT_TUPLE, DONT_LOCK_BIOS
		jnc	readFormat
fail:
		stc
		jmp	done

requestWindow:

	;
	; Request a window through which we can look at the file system
	;
		mov	ax, ss:[tupleSearchVars].CSGTA_socket
		mov	bx, ds:[curSocketPtr]
		call	PGFSRequestWindow
		jc	done		

		ornf	ds:[bx].PGFSSI_flags, mask PSF_PRESENT
	;
	; clear the REMOVE conflict indicating that the card has been
	; reinserted and that it is a file system card.
	;
		andnf	ds:[bx].PGFSSI_conflict, not mask PGFSCI_REMOVED
	;
	; Wakeup everyone blocked on the conflict queue for the socket.
	; Don't allow any of them to run, though, until we're done, as we need
	; to reliably set Sem_value back to 0 at the end....
	; 
		call	SysEnterCritical
		VAllSem	ds, [bx].PGFSSI_conflictSem
		mov	ds:[bx].PGFSSI_conflictSem.Sem_value, 0 
		call	SysExitCritical

		mov	ax, CSRC_SUCCESS
		clc
done:
	;
	; Restore curSocketPtr in case someone else was using it
	;
EC <		pop	ds:[fsMapped]					>
		pop	ds:[curSocketPtr]
		mov	ds:[inserting], FALSE
		.leave
		ret
		
PGFSIHandleInsertion endp

Resident	ends

Init	segment	resource

pcmciaCatStr	char	'pcmcia', 0
gfsKeyString	char	"gfs",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSICheckSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the passed socket to see if we support it, and do
		all the other fun things we have to do when we do support
		it.

CALLED BY:	DR_PCMCIA_CHECK_SOCKET
PASS:		cx	= socket number
		ds	= dgroup
RETURN:		carry set if card supported
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if fixed data says we don't support it, we don't support it

		fetch the drive letters for the card type.
		for each possible drive, attempt to read the boot sector

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VersionAndSize	struct
    VAS_versionMajor	word
    VAS_versionMinor	word
    VAS_size		dword
VersionAndSize	ends

CheckHack <offset GFSFH_versionMajor + size GFSFH_versionMajor eq \
		offset GFSFH_versionMinor>
CheckHack <offset GFSFH_versionMinor + size GFSFH_versionMinor eq \
		offset GFSFH_totalSize>

PGFSICheckSocket proc	far
socket		local	word	push cx
driveName	local	hptr
socketPtr	local	nptr.PGFSSocketInfo
versionAndSize	local	VersionAndSize
		
		uses	ax, bx, cx, dx, si
		.enter

waitForRegistrationLoop:
		tst	ds:[amRegistered]
		jz	waitForRegistrationLoop

		call	PGFSUDerefSocket
		mov	ss:[socketPtr], bx
		test	ds:[bx].PGFSSI_flags, mask PSF_PRESENT
		jnz	processIt
fail:
		clc		; we don't support it.
done:
		.leave
		ret

processIt:
	;
	; Read (and verify) the file header's version (we already
	; verified the signature in PGFSRequestWindow)
	; and copy the size into the socket info.
	;
		clr	al
		call	GFSDevLock
		mov	ds:[curSocketPtr], bx
		mov	ax, offset GFSFH_versionMajor
		cwd
		segmov	es, ss
		lea	di, ss:[versionAndSize]
		mov	cx, size versionAndSize
		call	GFSDevRead
		call	GFSDevUnlock
		jc	fail

		cmp	ss:[versionAndSize].VAS_versionMajor, GFS_PROTO_MAJOR
		jne	fail
		cmp	ss:[versionAndSize].VAS_versionMinor, GFS_PROTO_MINOR
		jne	fail

		movdw	ds:[bx].PGFSSI_size, ss:[versionAndSize].VAS_size, ax

	;
	; Now get le key from the ini file.
	; 
		mov	ax, ss:[socket]
		mov	cx, cs
		mov	ds, cx
		mov	si, offset pcmciaCatStr
		mov	dx, offset gfsKeyString
		push	bp
		mov	bp, (IFCC_UPCASE shl offset IFRF_CHAR_CONVERT) or \
				(0 shl offset IFRF_SIZE)
		call	InitFileReadStringSection
		pop	bp
		jc	fail

		mov	ss:[driveName], bx
		call	PGFSIDefineDrive
		pushf
		call	MemFree
		popf
		jc	fail
		
	;
	; Register with the library
	; bx	<- geode handle
	; cx	<- socket
	; dx	<- cs handle
	; es:di	<- CSRegisterClientArgs
	; ax:si <- cs callback
	; 
		mov	bx, vseg regArgList
		call	MemLockFixedOrMovable
		mov	es, ax
		mov	di, offset regArgList

		mov	bx, handle 0

		mov	cx, ss:[socket]

		segmov	ds, dgroup, ax
		mov	dx, ds:[csHandle]

		mov	ax, segment PGFSCardServicesCallback
		mov	si, offset PGFSCardServicesCallback
		call	PCMCIARegisterDriver

		mov	bx, vseg regArgList
		call	MemUnlockFixedOrMovable
		stc
		jmp	done
PGFSICheckSocket endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSIDefineDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a drive in GEOS.

CALLED BY:	(INTERNAL) PGFSICheckSocket

PASS:		ss:bp	= inherited frame

RETURN:		carry set if couldn't define the drive

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSIDefineDrive proc	near
		uses	ax, bx, cx, dx, si, ds, es
		.enter	inherit PGFSICheckSocket
	;
	; Lock the FSInfoResource exclusive and allocate a chunk for our
	; private data, which we then initialize.
	; 
		call	FSDLockInfoExcl
		mov	ds, ax
		mov	cx, size PGFSPrivateData
		call	LMemAlloc
		mov_tr	si, ax

		mov	cx, ss:[socket]
		mov	ds:[si].PGFSPD_common.PCMDPD_socket, cx
		mov	ax, ss:[socketPtr]
		mov	ds:[si].PGFSPD_socketPtr, ax
		call	FSDUnlockInfoExcl
	;
	; Now define the drive, passing the pointer to the private
	; date chunk we allocated
	;
		segmov	ds, dgroup, ax
		mov	dx, ds:[gfsFSD]
		mov	bx, ss:[driveName]
		call	MemLock
		mov	ds, ax
		mov	bx, si			; private date chunk
		clr	si

		mov	ax, -1 or (MEDIA_FIXED_DISK shl 8)
		mov	cx, mask DES_LOCAL_ONLY or \
			   (mask DS_PRESENT or mask DS_MEDIA_REMOVABLE or \
			   (DRIVE_PCMCIA shl offset DS_TYPE)) shl \
				 offset DES_EXTERNAL
		call	FSDInitDrive	; dx - pointer to DriveStatusEntry
		call	FSDLockInfoShared
		mov	ds, ax
		mov	di, dx
		mov	al, ds:[di].DSE_number
		call	FSDUnlockInfoShared

		segmov	ds, dgroup, bx
		mov	bx, ss:[socketPtr]
		mov	ds:[bx].PGFSSI_drive, al

		call	PGFSIAddStdPathIfPresent
		call	PGFSIAddFontsIfPresent
		clc
		.leave
		ret
PGFSIDefineDrive endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSIAddStdPathIfPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a GEOWORKS directory in the root of the drive and
		add it as another directory for SP_TOP if it's there.

CALLED BY:	(INTERNAL) PGFSICheckDrive
PASS:		al	= drive number
		ds:bx	= PGFSSocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSIAddStdPathIfPresent proc	near
		uses	ax
		.enter
	;
	; Call library to check & do the hard work for us.
	; 
		call	PCMCIAAddStdPathIfPresent
		jc	done		; => no std path
	;
	; Set the HAS_SP_TOP flag so we know to
	; nuke it when the card is removed.
	; 
		ornf	ds:[bx].PGFSSI_flags, mask PSF_HAS_SP_TOP
done:
		.leave
		ret
PGFSIAddStdPathIfPresent endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSIAddFontsIfPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a GEOWORKS directory in the root of each partition and
		check to see if there is a font path and if any fonts are
		in it, if they are add the fonts. 

CALLED BY:	(INTERNAL) PGFSICheckDrive
PASS:		al	= drive number
		ds:bx	= PGFSSocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	03/30/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSIAddFontsIfPresent proc	near
		uses	ax
		.enter
	;
	; Call library to check & do the hard work for us.
	; 
		call	PCMCIAAddFontsIfPresent
		jc	done		; => no fonts
	;
	; Set the HAS_FONTS flag so we know to
	; nuke it when the card is removed.
	; 
		ornf	ds:[bx].PGFSSI_flags, mask PSF_HAS_FONTS
done:
		.leave
		ret
PGFSIAddFontsIfPresent endp

Init	ends





