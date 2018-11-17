COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsExtAttrs.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Code for abusing extended attributes.
		

	$Id: gfsExtAttrs.asm,v 1.1 97/04/18 11:46:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource
;
; Offsets of virtual extended attributes within the file header.
; 
eaAttrOffsetTable word \
	GEA_modified,				; FEA_MODIFICATION
	GEA_attrs,				; FEA_FILE_ATTR
	GDE_size,				; FEA_SIZE
	GDE_fileType,				; FEA_FILE_TYPE
	GEA_flags,				; FEA_FLAGS
	GEA_release,				; FEA_RELEASE
	GEA_protocol,				; FEA_PROTOCOL
	GEA_token,				; FEA_TOKEN
	GEA_creator,				; FEA_CREATOR
	GEA_userNotes,				; FEA_USER_NOTES
	GEA_notice,				; FEA_NOTICE
	GEA_created,				; FEA_CREATION
	0,					; FEA_PASSWORD
	0,					; FEA_CUSTOM (n.u.)
	GEA_longName,				; FEA_NAME
	GEA_geodeAttrs,				; FEA_GEODE_ATTR
	0,					; FEA_PATH_INFO (n.u.)
	0,					; FEA_FILE_ID (n.u.)
	GEA_desktop,				; FEA_DESKTOP_INFO
	0,					; FEA_DRIVE_STATUS (n.u.)
	0,					; FEA_DISK (n.u.)
	GEA_dosName,				; FEA_DOS_NAME
	0,					; FEA_OWNER (n.u.)
	0,					; FEA_RIGHTS (n.u.)
	GEA_targetID				; FEA_TARGET_FILE_ID
CheckHack <length eaAttrOffsetTable eq FEA_LAST_VALID+1>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetHandleExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch extended attributes from an open file.

CALLED BY:	GFSHandleOp
PASS:		es:bx	= GFSFileEntry
		ss:dx	= FSHandleExtAttrData
		cx	= size of FHEAD_buffer or # entries in same if multiple
RETURN:		carry/ax
		filesystem locked
DESTROYED:	bx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetHandleExtAttrs proc	far
		uses	dx
		.enter
if _PCMCIA
		mov	al, mask GDLF_FILE
else
		clr	al
endif
		call	GFSDevLock
	;
	; Set up the necessary fields in gfsLastFound*
	; 
		push	ds
		segmov	ds, dgroup, ax
		movdw	ds:[gfsLastFoundEA], es:[bx].GFE_extAttrs, ax
		movdw	ds:[gfsLastFound].GDE_size, es:[bx].GFE_size, ax
		mov	al, es:[bx].GFE_fileType
		mov	ds:[gfsLastFound].GDE_fileType, al
		pop	ds
	;
	; Set up the registers for GFSEAGetExtAttrs (dx must be non-zero since
	; it's stuff on the stack passed to us...)
	; 
		mov	bx, dx
		les	di, ss:[bx].FHEAD_buffer
		mov	ax, ss:[bx].FHEAD_attr
		call	GFSEAGetExtAttrs
		.leave
		ret
GFSEAGetHandleExtAttrs endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the indicated extended attribute(s) from the
		passed open file.

CALLED BY:	GFSHandleOp, GFSPathOp
PASS:		gfsLastFoundEA	= address of extended attributes
		gfsLastFound	= directory entry (GDE_size, GDE_fileType
				  must be filled in)
		device locked

		ax	= FileExtendedAttribute
		es:di	= buffer in which to place results, or array of
			  FileExtAttrDesc structures, if ax is FEA_MULTIPLE
		cx	= size of said buffer, or # of entries in buffer if
			  ax is FEA_MULTIPLE
		si	= disk on which file/name is located
		dx	= non-zero if getting attrs for open file

RETURN:		carry set on error:
			ax	= error code
		carry clear on success
			ax	= destroyed
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetExtAttrs	proc	near

singleAttr	local	FileExtAttrDesc
		uses	es, di, ds, bx, cx
		.enter
		cmp	ax, FEA_MULTIPLE
		je	haveAttrArray
	;
	; It's easiest to work with an array of descriptors always, so if
	; a single attribute is being asked for, stuff it into our local frame
	; and point ds:si at that one attribute...
	; 
EC <		cmp	ax, FEA_CUSTOM					>
EC <		ERROR_E	CUSTOM_ATTRIBUTES_MUST_BE_PASSED_AS_FEA_MULTIPLE>
		mov	ss:[singleAttr].FEAD_attr, ax
		mov	ss:[singleAttr].FEAD_value.segment, es
		mov	ss:[singleAttr].FEAD_value.offset, di
		mov	ss:[singleAttr].FEAD_size, cx
		segmov	es, ss
		lea	di, ss:[singleAttr]
		mov	cx, 1
haveAttrArray:
	;
	; Allocate the necessary workspace. We allocate it fixed as we'd
	; otherwise keep it locked for its entire lifetime, so why bother
	; with that?
	; 
		call	GFSEAAllocGFSGetExtAttrData
		jc	exit
	;
	; Initialize the various pieces that always get the same things,
	; regardless of who called us.
	; 
		mov	ds:[GGEAD_disk], si
		mov	ds:[GGEAD_numAttrs], cx

		mov	ds:[GGEAD_attrs].offset, di
		mov	ds:[GGEAD_attrs].segment, es
	;
	; Flag we don't have the header, yet...
	; 
		mov	ds:[GGEAD_header].segment, 0

	;
	; Set GGEAD_flags. Assume file not open (as there's nothing else to
	; set up...)
	; 
		tst	dx
		jz	goIt

	    ;
	    ; DirPathInfo unknown.
	    ; 
		mov	ds:[GGEAD_pathInfo], 0

	;
	; Call common routine to do the real work.
	; 
goIt:
		call	GFSEAGetExtAttrsLow
	;
	; Free the workspace without biffing the carry.
	; 
		pushf
		mov	bx, ds:[GGEAD_block]
		call	MemFree
		popf
exit:
		.leave
		ret
GFSEAGetExtAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetExtAttrsEnsureHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make certain we've got the header for the file or we know
		it ain't there.

CALLED BY:	GFSEAGetExtAttrsLow, GFSFileEnum
PASS:		ds	= GFSGetExtAttrData
RETURN:		carry set if file not a geos file.
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetExtAttrsEnsureHeader proc	near
		uses	es, di
		.enter
		tst	ds:[GGEAD_header].segment
		jnz	done
		
		segmov	es, dgroup, ax
		movdw	dxax, es:[gfsLastFoundEA]
		
		call	GFSDevMapEA
		movdw	ds:[GGEAD_header], esdi
done:
		.leave
		ret
GFSEAGetExtAttrsEnsureHeader	endp


;-----------------------------------------------------------------------------
;	Attribute tables for normal files (not links)
;-----------------------------------------------------------------------------

; If the size is zero, then any size is OK

getAttrSizeTable byte	size FileDateAndTime,	; FEA_MODIFIED
			size FileAttrs,		; FEA_FILE_ATTR
			size dword,		; FEA_SIZE
			size GeosFileType,	; FEA_FILE_TYPE
			size GeosFileHeaderFlags,; FEA_FLAGS
			size ReleaseNumber,	; FEA_RELEASE
			size ProtocolNumber,	; FEA_PROTOCOL
			size GeodeToken,	; FEA_TOKEN
			size GeodeToken,	; FEA_CREATOR
			0,			; FEA_USER_NOTES
			0,			; FEA_NOTICE
			size FileDateAndTime,	; FEA_CREATED
			0,			; FEA_PASSWORD
			0,			; FEA_CUSTOM
			0,			; FEA_NAME
			size GeodeAttrs,	; FEA_GEODE_ATTR
			size DirPathInfo,	; FEA_PATH_INFO
			size FileID,		; FEA_FILE_ID
			0,			; FEA_DESKTOP_INFO
			size DriveExtendedStatus,; FEA_DRIVE_STATUS
			size word,		; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			size FileID		; FEA_TARGET_FILE_ID

.assert (length getAttrSizeTable) eq (FEA_LAST_VALID+1)

getAttrRoutTable	nptr	\
			GFSEAGetAttrVirtual,		; FEA_MODIFICATION
			GFSEAGetAttrVirtual,		; FEA_FILE_ATTR
			GFSEAGetAttrDirEntry,		; FEA_SIZE
			GFSEAGetAttrDirEntry,		; FEA_FILE_TYPE
			GFSEAGetAttrVirtual,		; FEA_FLAGS
			GFSEAGetAttrVirtual,		; FEA_RELEASE
			GFSEAGetAttrVirtual,		; FEA_PROTOCOL
			GFSEAGetAttrVirtual,		; FEA_TOKEN
			GFSEAGetAttrVirtual,		; FEA_CREATOR
			GFSEAGetAttrVirtual,		; FEA_USER_NOTES
			GFSEAGetAttrVirtual,		; FEA_NOTICE
			GFSEAGetAttrVirtual,		; FEA_CREATION
			GFSEAGetAttrUnsupported,	; FEA_PASSWORD
			GFSEAGetAttrUnsupported,	; FEA_CUSTOM
			GFSEAGetAttrName,		; FEA_NAME
			GFSEAGetAttrVirtual,		; FEA_GEODE_ATTR
			GFSEAGetAttrPathInfo,		; FEA_PATH_INFO
			GFSEAGetAttrFileID,		; FEA_FILE_ID
			GFSEAGetAttrVirtual,		; FEA_DESKTOP_INFO
			GFSEAGetAttrDriveStatus,	; FEA_DRIVE_STATUS
			GFSEAGetAttrDisk,		; FEA_DISK
			GFSEAGetAttrDosName,		; FEA_DOS_NAME
			GFSEAGetAttrUnsupported,	; FEA_OWNER
			GFSEAGetAttrUnsupported,	; FEA_RIGHTS
			GFSEAGetAttrVirtual		; FEA_TARGET_FILE_ID
CheckHack <length getAttrRoutTable eq FEA_LAST_VALID+1>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetExtAttrsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the indicated extended attributes for the given file.

CALLED BY:	GFSEAGetExtAttrs, GFSEnum
PASS:		ds	= segment of GFSGetExtAttrData block with
			  appropriate fields filled in appropriately.
RETURN:		carry set if error:
			ax	= error code
		carry clear if ok:
			ax	= destroyed
DESTROYED:	es, cx, di, bx, si, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetExtAttrsLow proc	near
		uses	bx, bp

		.enter

	;
	; If pathInfo given and indicates the thing is local, set the
	; DPI_EXISTS_LOCALLY bit to make life in the app world a bit easier.
	; 
		mov	ax, ds:[GGEAD_pathInfo]
		tst	ax
		jz	processAttrs	; => not known
		test	ax, mask DPI_ENTRY_NUMBER_IN_PATH
		jnz	processAttrs	; => not local
		ornf	ds:[GGEAD_pathInfo], mask DPI_EXISTS_LOCALLY
processAttrs:
	;
	; Set up for the attribute loop.
	; 

		mov	cx, ds:[GGEAD_numAttrs]
		les	si, ds:[GGEAD_attrs]


		mov	ds:[GGEAD_error], 0	; no error, yet

attrLoop:
	;
	; Fetch the next attribute desired from the array and make sure the
	; destination buffer is big enough to hold the value.
	; 
		push	cx
		mov	bx, es:[si].FEAD_attr
EC <		cmp	bx, FEA_LAST_VALID				>
EC <		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE			>
		mov	cx, es:[si].FEAD_size
		tst	ch
		jnz	sizeOK
		cmp	cl, cs:[getAttrSizeTable][bx]
		jb	sizeError
sizeOK:
	;
	; Load the rest of the attribute descriptor into appropriate
	; registers and call the handler for it.
	; 
		shl	bx
		push	es
		les	di, es:[si].FEAD_value
		;
		; pass:
		; 	es:di	= FEAD_value
		;	si   	= offset of FileExtAttrDesc
		; 	cx	= FEAD_size
		; 	bx	= FEAD_attr * 2
		; 	al	= GFSGetExtAttrFlags
		; return:
		; 	nothing
		;
		; destroy:
		; 	es, di, cx, bx, ax, dx
		;
		mov	al, ds:[GGEAD_flags]
		call	cs:[getAttrRoutTable][bx]
		pop	es
nextAttr:
	;
	; Advance to the next descriptor in the array.
	; 
		pop	cx
		add	si, size FileExtAttrDesc
		loop	attrLoop
	;
	; Unmap any extended attributes we mapped.
	; 
		tst	ds:[GGEAD_header].segment
		jz	fetchError
		call	GFSDevUnmapEA
fetchError:
	;
	; Fetch any error we're to return, and set carry if there is one...
	; 
		mov	ax, ds:[GGEAD_error]
		tst	ax
		jz	done
		stc
done:					
		.leave
		ret

sizeError:
		mov	ds:[GGEAD_error], ERROR_ATTR_SIZE_MISMATCH
		jmp	nextAttr

GFSEAGetExtAttrsLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrDirEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an attribute from the gfsLastFound directory entry

CALLED BY:	GFSEAGetExtAttrsLow
PASS:		
		es:di = place to store result
		si = FileExtAttrDesc offset
		cx	= # bytes to copy
		bx 	= attr * 2
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrDirEntry proc	near
		.enter
		push	si, ds
		segmov	ds, dgroup, si
		mov	si, offset gfsLastFound
		add	si, cs:[eaAttrOffsetTable][bx]
		rep	movsb
		pop	si, ds
		.leave
		ret
GFSEAGetAttrDirEntry endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrVirtual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch any of the virtual attributes

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		
		es:di = place to store result
		si = FileExtAttrDesc offset
		bx 	= attr * 2

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrVirtual	proc near
 
		call	GFSEAGetExtAttrsEnsureHeader
		jc	GFSEAGetAttrSetError
	;
	; Copy from the proper offset in the header to the destination,
	; however many bytes the destination will hold.
	; 
		push	si, ds
		lds	si, ds:[GGEAD_header]
		add	si, cs:[eaAttrOffsetTable][bx]
		rep	movsb
		pop	si, ds
		
	;
	; XXX: if attribute is FILE_ATTR, be sure the FA_GEOS bit is clear.
	; 
		cmp	bx, FEA_FILE_ATTR shl 1
		jne	done
		andnf	{byte}es:[di-1], not FA_GEOS
done:
		ret
GFSEAGetAttrVirtual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the FEA_NAME attribute, making sure it's null-terminated

CALLED BY:	GFSEAGetExtAttrsLow
PASS:		es:di	= place to store the result
		si	= FileExtAttrDesc offset
		ds	= GFSGetExtAttrData
		bx	= attr * 2
		cx	= space in destination
RETURN:		nothing
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrName proc	near
		call	GFSEAGetExtAttrsEnsureHeader
		jc	GFSEAGetAttrSetError

if not DBCS_PCGEOS		; just use GEA_longName for DOS files as well
				; since GFS tool puts DBCS version of the DOS
				; name in that field
		push	ds, si
		lds	si, ds:[GGEAD_header]
		cmp	ds:[si].GEA_type, GFT_NOT_GEOS_FILE 
		pop	ds, si
		jne	isGeosFile
		jmp	GFSEAGetAttrDosName	; else, fetch DOS name

isGeosFile:
endif
		
		push	dx
DBCS <		shr	cx			; size -> length	>
		mov	dx, cx			; save original size

		cmp	cx, length GEA_longName
		jbe	moveIt
		mov	cx, length GEA_longName
moveIt:
		push	ds, si
		lds	si, ds:[GGEAD_header]
		CheckHack <GEA_longName eq 0>
copyName:
		LocalGetChar	ax, dssi
		LocalPutChar	esdi, ax
		LocalIsNull	ax
		loopne	copyName
		pop	ds, si
		mov	cx, dx
		pop	dx
		je	done		; hit null in time -- happy
		mov	ax, ERROR_ATTR_SIZE_MISMATCH
		cmp	cx, length GEA_longName
		jbe	GFSEAGetAttrSetError
		mov	{TCHAR}es:[di], 0
done:
		ret
GFSEAGetAttrName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the error condition.  JUMPED TO by various other
		"ea" routines

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		ax - error code
		si - offset to FileExtAttrDesc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrSetError	proc near

		.enter

		mov	ds:[GGEAD_error], ax
	    ;
	    ; Zero out the return buffer. (CX must still be dest size...)
	    ; 
	    	clr	al
		rep	stosb
	;
	; If desired, zero the segment of the attribute descriptor.
	; 
		test	ds:[GGEAD_flags], mask GGEAF_CLEAR_VALUE_SEG_IF_ABSENT
		jz	eaSetErrorDone
		mov	es, ds:[GGEAD_attrs].segment
		mov	es:[si].FEAD_value.segment, 0
eaSetErrorDone:

		.leave
		ret

GFSEAGetAttrSetError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the FEA_DOS_NAME attribute, making sure it's null-
		terminated

CALLED BY:	GFSEAGetExtAttrsLow
PASS:		es:di	= place to store the result
		si	= FileExtAttrDesc offset
		ds	= GFSGetExtAttrData
		bx	= attr * 2
		cx	= space in destination
RETURN:		nothing
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrDosName proc	near
		call	GFSEAGetExtAttrsEnsureHeader
		jc	GFSEAGetAttrSetError
		
		push	dx
		mov	dx, cx			; save original size

	;
	; Convert the thing to 8.3, not 8/3
	;
		sub	sp, (DOS_DOT_FILE_NAME_LENGTH_ZT+1) and not 1
		mov	bx, sp
		push	ds, si, bp, es, di
		mov	di, bx
		segmov	es, ss		; es:di <- buffer on stack
		lds	si, ds:[GGEAD_header]
		add	si, offset GEA_dosName	; ds:si <- start

		mov	cx, DOS_FILE_NAME_CORE_LENGTH
		call	copyNameWithoutTrailingSpaces

		mov	{char}es:[di], '.'
		inc	di

		mov	cx, DOS_FILE_NAME_EXT_LENGTH
		call	copyNameWithoutTrailingSpaces
	;
	; If no extension, don't leave dot.
	; 
		cmp	{char}es:[di-1], '.'
		jne	nullTerm
		dec	di
nullTerm:
		mov	{char}es:[di], 0
	;
	; Now have the name in the form everyone else expects. Copy it into
	; the destination buffer, if it fits.
	; 
		pop	es, di
		segmov	ds, ss		; ds:si <- normal form
		mov	si, bx
		mov	cx, dx		; cx <- dest size
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH_ZT
		jbe	copyName
		mov	cx, DOS_DOT_FILE_NAME_LENGTH_ZT
copyName:
		lodsb
		stosb
		tst	al
		loopne	copyName
		pop	ds, si, bp
		lea	sp, ss:[bx+((DOS_DOT_FILE_NAME_LENGTH_ZT+1) and not 1)]
		mov	cx, dx		; cx <- dest size, again
		pop	dx
		je	done		; hit null in time -- happy

		mov	ax, ERROR_ATTR_SIZE_MISMATCH
		cmp	cx, DOS_DOT_FILE_NAME_LENGTH_ZT
		jbe	GFSEAGetAttrSetError
done:
		ret

	;--------------------
copyNameWithoutTrailingSpaces:
		lodsb
		cmp	al, ' '
		je	copySpaces
		stosb
		loop	copyNameWithoutTrailingSpaces
copyDone:		
		retn

copySpaces:
		mov	bp, di		; remember where first space went
		dec	si		; back up to space so loops are
					;  parallel
spaceLoop:
		lodsb
		stosb
		cmp	al, ' '
		loope	spaceLoop	; keep going until end of ext or hit
					;  non-space
		jne	csDone		; hit end of ext
		mov	di, bp		; point back to first trailing space
csDone:
		jcxz	copyDone
		jmp	copyNameWithoutTrailingSpaces

GFSEAGetAttrDosName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to call the secondary driver

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		es:di = place to store result
		si = FileExtAttrDesc offset
		cx = dest buffer size

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrUnsupported	proc near
		mov	ax,ERROR_ATTR_NOT_SUPPORTED
		jmp	GFSEAGetAttrSetError
GFSEAGetAttrUnsupported	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the File ID

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		; es:di = place to store result
		; si = FileExtAttrDesc offset
		; bx 	= attr * 2
		; al	= GFSGetExtAttrFlags


RETURN:		nothing 

DESTROYED:	cx, di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrFileID	proc near
		.enter
		push	ds
		segmov	ds, dgroup, ax
		movdw	es:[di], ds:[gfsLastFoundEA], ax
		pop	ds
		.leave
		ret
GFSEAGetAttrFileID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrDriveStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch drive status

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		DS - GFSGetExtAttrData segment
		es:di - buffer to store data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrDriveStatus	proc near

		.enter
		mov	bx, ds:[GGEAD_disk]
		call	DiskGetDrive
		call	DriveGetExtStatus
		stosw

		.leave
		ret
GFSEAGetAttrDriveStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch disk status

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		DS - GFSGetExtAttrData segment
		es:di - buffer to store data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92   	Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrDisk proc near
		.enter
		mov	ax, ds:[GGEAD_disk]
		stosw
		.leave
		ret
GFSEAGetAttrDisk endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAttrPathInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the DirPathInfo

CALLED BY:	GFSEAGetExtAttrsLow

PASS:		es:di = place to store result
		ds:si = FileExtAttrDesc
		bx 	= attr * 2
		al	= GFSGetExtAttrFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAttrPathInfo	proc near
		mov	ax, ds:[GGEAD_pathInfo]
		tst	ax
		jnz	eaPIStore
		mov	ax, ERROR_ATTR_NOT_FOUND
		jmp	GFSEAGetAttrSetError
eaPIStore:
		stosw

		ret
GFSEAGetAttrPathInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAllHandleExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch all the extended attributes an open file has to offer

CALLED BY:	GFSHandleOp
PASS:		es:bx - GFSFileEntry for file
RETURN:		carry set if error:
			ax	= error code
		carry clear if ok
			ax	= handle of locked block holding array
				  of FileExtAttrDesc structures at its
				  beginning
			cx	= number entries in the array
		filesystem locked
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAGetAllHandleExtAttrs proc	far
		uses	dx
		.enter
if _PCMCIA
		mov	al, mask GDLF_FILE
else
		clr	al
endif
		call	GFSDevLock

		movdw	dxax, es:[bx].GFE_extAttrs
		call	GFSEAGetAllExtAttrs
		.leave
		ret
GFSEAGetAllHandleExtAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEAGetAllExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load all the attributes that we know about into a buffer

CALLED BY:	GFSHandleOp, GFSPathOp
PASS:		dxax	= address of extended attributes

RETURN:		carry set if error:
			ax	= error code
		carry clear if ok
			ax	= handle of locked block holding array
				  of FileExtAttrDesc structures at its
				  beginning
			cx	= number entries in the array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
gfsAllAttrs	FileExtAttrDesc \
    <FEA_MODIFICATION,	GFSAA_ea.GEA_modified,	size GEA_modified>,
    <FEA_FILE_ATTR, 	GFSAA_ea.GEA_attrs,	size GEA_attrs>,
    <FEA_FILE_TYPE,	GFSAA_ea.GEA_type,	size GEA_type>,
    <FEA_FLAGS,		GFSAA_ea.GEA_flags,	size GEA_flags>,
    <FEA_RELEASE,	GFSAA_ea.GEA_release,	size GEA_release>,
    <FEA_PROTOCOL,	GFSAA_ea.GEA_protocol,	size GEA_protocol>,
    <FEA_TOKEN,		GFSAA_ea.GEA_token,	size GEA_token>,
    <FEA_CREATOR,	GFSAA_ea.GEA_creator,	size GEA_creator>,
    <FEA_USER_NOTES,	GFSAA_ea.GEA_userNotes,	size GEA_userNotes>,
    <FEA_NOTICE,	GFSAA_ea.GEA_notice,	size GEA_notice>,
    <FEA_CREATION,	GFSAA_ea.GEA_created,	size GEA_created>,
    <FEA_DESKTOP_INFO,	GFSAA_ea.GEA_desktop,	size GEA_desktop>

GFS_NUM_ATTRS	equ	length gfsAllAttrs

GFSAllAttrs	struct
    GFSAA_attrs		FileExtAttrDesc	GFS_NUM_ATTRS dup(<>)
    GFSAA_ea		GFSExtAttrs
GFSAllAttrs	ends

GFSEAGetAllExtAttrs proc near
		uses	bx, es, di, ds, si
		.enter
		
	;
	; Allocate a buffer to hold the GFSExtAttrs structure and the
	; array of descriptors.
	; 
		push	ax
		mov	ax, size GFSAllAttrs
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	allocErr

	;
	; Read the whole structure from the filesystem.
	; 
		mov	es, ax
		pop	ax
		mov	di, offset GFSAA_ea
		mov	cx, size GFSAA_ea
		call	GFSDevRead
		jc	readErr
	;
	; Now copy in the attribute descriptors.
	; 
			CheckHack <GFSAA_attrs eq 0>
		clr	di
		segmov	ds, cs
		mov	si, offset gfsAllAttrs
		mov	cx, size gfsAllAttrs/2
		rep	movsw
		
	;
	; Fix up the segments.
	; 
		clr	di
fixupLoop:
		mov	es:[di].FEAD_value.segment, es
		add	di, size FileExtAttrDesc
		cmp	di, offset GFSAA_ea
		jb	fixupLoop
		
	;
	; Clear illegal attribute bits.
	; 
		andnf	es:[GFSAA_ea].GEA_attrs, not FA_GEOS
	;
	; Return the block handle and the number of attributes.
	; (carry clear)
	; 
		mov_tr	ax, bx
		mov	cx, GFS_NUM_ATTRS
exit:
		.leave
		ret

allocErr:
	;
	; Couldn't allocate memory, so return the appropriate error code.
	; 
		pop	ax
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	exit

readErr:
	;
	; Couldn't read the attributes, so free the now-superfluous block and
	; return whatever error we got.
	; 
		call	MemFree
		stc
		jmp	exit

GFSEAGetAllExtAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocGFSGetExtAttrData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a GFSGetExtAttrData segment and initialize
		it. 

CALLED BY:	DOSLinkGetExtAttrs

PASS:		nothing 

RETURN:		if allocated
			ds - segment of FIXED block
			ax - destroyed
		else
			carry set
			ax - ERROR_INSUFFICIENT_MEMORY

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEAAllocGFSGetExtAttrData	proc near
		uses	bx, cx
		.enter
	;
	; Allocate the necessary workspace. We allocate it fixed as we'd
	; otherwise keep it locked for its entire lifetime, so why bother
	; with that?
	; 
		mov	ax, size GFSGetExtAttrData
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	error
		mov	ds, ax
		mov	ds:[GGEAD_block], bx
	;
	; Fetch the pathInfo from our current path, in case the caller wants it
	; 
		push	es
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	es, ax
		mov	ax, es:[FP_pathInfo]
		call	MemUnlock
		pop	es
		mov	ds:[GGEAD_pathInfo], ax
done:
		.leave
		ret
error:

		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

GFSEAAllocGFSGetExtAttrData	endp

Movable	ends
