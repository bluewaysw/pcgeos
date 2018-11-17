COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareSecondary.asm

AUTHOR:		Adam de Boor, Apr  6, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/92		Initial revision


DESCRIPTION:
	Secondary-IFS-driver functions to aid the primary to do our bidding.
		

	$Id: netwareSecondary.asm,v 1.1 97/04/10 11:55:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource	; XXX


NWSFIData	struct
    NWSFID_req		NReqBuf_ScanFileInfo
    NWSFID_reply	NRepBuf_ScanFileInfo
NWSFIData	ends

NWGBONData	struct
    NWGBOND_req		NReqBuf_GetBinderyObjectName
    NWGBOND_reply	NRepBuf_GetBinderyObjectName
NWGBONData	ends

NWSDIData	struct
    NWSDID_req		NReqBuf_ScanDirectoryInfo
    NWSDID_reply	NRepBuf_ScanDirectoryInfo
NWSDIData	ends

NWSGOABuffer	union
    NWSGOAB_sfi		NWSFIData
    NWSGOAB_sdi		NWSDIData
    NWSGOAB_gbon	NWGBONData
NWSGOABuffer	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSGOATryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the thing is a file and fetch its owner's object ID

CALLED BY:	(INTERNAL) NWSGetOwnerAttr
PASS:		ds, es	= NWSGOABuffer
		on stack ->	name of file
				FileExtAttrDesc
RETURN:		carry set if file not found
			ax, dx	= destroyed
			ds:[NWSGOAB_sfi.NWSFID_req.NREQBUF_SFI_dirHandle]
				set to handle for current drive
		carry clear if found:
			dxax	= object ID
DESTROYED:	si, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSGOATryFile	proc	near	fileName:fptr.char, 
				attrDesc:fptr.FileExtAttrDesc
	ForceRef attrDesc	; we just kind of inherit it, but don't use it
		.enter

		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_length,
			size NReqBuf_ScanFileInfo-2
		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_subFunc, 
			low NFC_SCAN_FILE_INFORMATION
		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_sequenceNum, -1
		mov	ah, MSDOS_GET_DEFAULT_DRIVE
		call	FileInt21		; al <- drive number (0-origin)
		clr	ah
		mov_tr	dx, ax			; dx <- drive number
		mov	ax, NFC_GET_DIRECTORY_HANDLE
		call	FileInt21		; al <- dir handle
		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_dirHandle, al
		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_searchAttributes,
			mask FA_HIDDEN or mask FA_SYSTEM
		mov	ds:[NWSGOAB_sfi].NWSFID_reply.NREPBUF_SFI_length,
			size NRepBuf_ScanFileInfo - 2
	    ;
	    ; Copy the name into the request buffer, counting the chars as
	    ; we go along.
	    ; 
		lds	si, ss:[fileName]
		clr	cx
		mov	di, offset NWSGOAB_sfi.NWSFID_req.NREQBUF_SFI_filePath
copyNameLoop:
		lodsb
		stosb
		tst	al
		loopne	copyNameLoop
		not	cx		; cx <- # chars w/o null
		segmov	ds, es
		mov	ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_filePathLen, cl
		
		mov	si, offset NWSGOAB_sfi.NWSFID_req
		mov	di, offset NWSGOAB_sfi.NWSFID_reply
		mov	ax, NFC_SCAN_FILE_INFORMATION
		call	FileInt21
		tst	al
		movdw	dxax, \
			ds:[NWSGOAB_sfi].NWSFID_reply.NREPBUF_SFI_ownerObjectID
		jz	done
		stc		; signal not found
done:
		.leave
		ret
NWSGOATryFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSGOATryDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Failed to find a file of the given name, so now iterate
		through all the directories, looking for one of this name.

CALLED BY:	(INTERNAL) NWSGetOwnerAttr
PASS:		ds, es	= NWSGOABuffer
		ds:[NWSGOAB_sfi.NWSFID_req.NREQBUF_SFI_dirHandle]
			set to handle for current drive
		on stack ->	name of file
				FileExtAttrDesc
RETURN:		carry set if file not found
			ax, dx	= destroyed
		carry clear if found:
			dxax	= object ID
DESTROYED:	si, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSGOATryDir	proc	near	fileName:fptr.char,
				attrDesc:fptr.FileExtAttrDesc
	ForceRef attrDesc	; we just kind of inherit it, but don't use it
		.enter
		mov	al, ds:[NWSGOAB_sfi].NWSFID_req.NREQBUF_SFI_dirHandle
		mov	ds:[NWSGOAB_sdi].NWSDID_req.NREQBUF_SDI_dirHandle, al
		
		mov	ds:[NWSGOAB_sdi].NWSDID_req.NREQBUF_SDI_length,
			size NReqBuf_ScanFileInfo-2
		mov	ds:[NWSGOAB_sdi].NWSDID_req.NREQBUF_SDI_subFunc,
			low NFC_SCAN_DIRECTORY_INFORMATION
		mov	ds:[NWSGOAB_sdi].NWSDID_req.NREQBUF_SDI_sequenceNum,
			0
	    ;
	    ; Copy the name into the request buffer, counting the chars as
	    ; we go along.
	    ; 
		lds	si, ss:[fileName]
		clr	cx
		mov	di, offset NWSGOAB_sdi.NWSDID_req.NREQBUF_SDI_dirPath
copyNameLoop:
		lodsb
		stosb
		tst	al
		loopne	copyNameLoop
		not	cx		; cx <- # chars w/o null

		segmov	ds, es
		mov	ds:[NWSGOAB_sdi].NWSDID_req.NREQBUF_SDI_dirPathLength,
				cl
		mov	ds:[NWSGOAB_sdi].NWSDID_reply.NREPBUF_SDI_length,
				size NRepBuf_ScanDirectoryInfo - 2
		mov	si, offset NWSGOAB_sdi.NWSDID_req
		mov	di, offset NWSGOAB_sdi.NWSDID_reply
		mov	ax, NFC_SCAN_DIRECTORY_INFORMATION
		call	FileInt21
		tst	al
		movdw	dxax, \
			ds:[NWSGOAB_sdi].NWSDID_reply.NREPBUF_SDI_ownerObjectID
		jz	done
		stc		; signal not found
done:
		.leave
		ret
NWSGOATryDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSGetOwnerAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the FEA_OWNER attribute for the passed file/dir

CALLED BY:	NWGetExtAttribute
PASS:		ds:si	= FileExtAttrDesc
		ax:dx	= file name/file handle
RETURN:		carry set if error:
			ax	= FileError
		carry clear if ok:
			ax	= destroyed
DESTROYED:	dx, di, ds, si

PSEUDO CODE/STRATEGY:
		No need to set the preferred server here, as NetWare sets
		that to the server for the drive when caller called
		MSDOS_SET_DEFAULT_DRIVE...or so it appears.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSGetOwnerAttr proc	near
		uses	es, cx, bx
		.enter
		tst	ax		; handle?
		LONG jz	notSupported	; yes -- Novell no help here.
		
	;
	; Allocate a block of memory to hold the request/reply buffers for the
	; two calls we have to make.
	; 
		push	ds, si, ax, dx
		mov	ax, size NWSGOABuffer
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		LONG jc	insufficientMemory
	;
	; First get the owner object ID of the thing.
	; 
		mov	es, ax
		mov	ds, ax
		
		call	NWSGOATryFile
		jnc	translateID
		
		call	NWSGOATryDir
		jnc	translateID
		
		pop	ds, si, ax, dx
		jmp	attrNotFound

translateID:
		add	sp, 4		; discard pointer to file name
	;
	; Now translate that owner ID into a name.
	; 
		movdw	ds:[NWSGOAB_gbon].NWGBOND_req.NREQBUF_GBON_objectID, \
				dxax
		mov	ds:[NWSGOAB_gbon].NWGBOND_req.NREQBUF_GBON_length,
				size NReqBuf_GetBinderyObjectName-2
		mov	ds:[NWSGOAB_gbon].NWGBOND_req.NREQBUF_GBON_subFunc,
				low NFC_GET_BINDERY_OBJECT_NAME

		mov	ds:[NWSGOAB_gbon].NWGBOND_reply.NREPBUF_GBON_length,
				size NRepBuf_GetBinderyObjectName-2
		mov	ax, NFC_GET_BINDERY_OBJECT_NAME
		mov	si, offset NWSGOAB_gbon.NWGBOND_req
		mov	di, offset NWSGOAB_gbon.NWGBOND_reply
		call	FileInt21
		pop	es, di
		tst	al
		jnz	attrNotFound
	;
	; Copy the owner name into the value space.
	; 
		mov	cx, es:[di].FEAD_size
		dec	cx		; leave room for null
		les	di, es:[di].FEAD_value
		mov	si, offset NWSGOAB_gbon.NWGBOND_reply.NREPBUF_GBON_objectName
		push	bx
		mov	bx, '?'
copyOwnerNameLoop:
		lodsb
		clr	ah		; not DBCS
		call	LocalDosToGeosChar
		stosb
		tst	al
		loopne	copyOwnerNameLoop
		pop	bx
		clr	al
		stosb
		clc
	;
	; Free the block we allocated.
	; 
freeBlock:
		pushf
		call	MemFree
		popf
done:
		.leave
		ret

notSupported:
		mov	ax, ERROR_ATTR_NOT_SUPPORTED
errorCommon:
		stc
		jmp	done

insufficientMemory:
		pop	ds, si, ax, dx
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	errorCommon

attrNotFound:
		mov	ax, ERROR_ATTR_NOT_FOUND
		stc
		jmp	freeBlock
NWSGetOwnerAttr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWGetExtAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch an extended attribute for a file that's not supported
		by the primary FSD

CALLED BY:	DR_DSFS_GET_EXT_ATTRIBUTE
PASS:		ds:si	= FileExtAttrDesc
		ax:dx	= far pointer. If segment non-zero, points to the
			  name of the file being messed with, in the current
			  directory (native name). If segment is 0, the offset
			  is the DOS file handle.
RETURN:		carry set if attribute also not supported by secondary or
		    isn't present for the file:
			ax	= ERROR_ATTR_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED
		carry clear if attribute fetched.
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWGetExtAttribute proc	far
		uses	dx, ds, si
		.enter
		cmp	ds:[si].FEAD_attr, FEA_OWNER
		jne	notSupported	; for now

		call	NWSGetOwnerAttr
done:		
		.leave
		ret

notSupported:
		mov	ax, ERROR_ATTR_NOT_SUPPORTED
		stc
		jmp	done
NWGetExtAttribute endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSetExtAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a particular extended attribute the primary IFS driver
		can't handle.

CALLED BY:	DR_SFS_SET_EXT_ATTRIBUTE
PASS:		ds:si	= FileExtAttrDesc
		ax:dx	= far pointer. If segment non-zero, points to the
			  name of the file being messed with, in the current
			  directory. If segment is 0, the offset is the DOS
			  file handle.
RETURN:		carry set if attribute also not supported by secondary or
		    isn't present for the file:
			ax	= ERROR_ATTR_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED
		carry clear if attribute fetched.
DESTROYED:	di, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSetExtAttribute proc	far
		.enter
		mov	ax, ERROR_ATTR_CANNOT_BE_SET
		stc
		.leave
		ret
NWSetExtAttribute endp

Resident	ends
