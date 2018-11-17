COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileLink.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
GLB	FileCreateLink		create a link
GLB	FileReadLink		return the link's data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/14/92   	Initial version.

DESCRIPTION:
	

	$Id: fileLink.asm,v 1.1 97/04/05 01:11:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Filemisc	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a link to the passed file in the current
		directory. 

CALLED BY:	GLOBAL

PASS:		ds:dx - link filename
		current directory is the dest. directory of the link

		bx - disk handle or standard path of target file.
			If bx = 0, then no disk handle will be used,
			and the target path is assumed to be an
			absolute path containing a drive name.
			Relative links are NOT permitted.

		es:di - path to target file or directory

		cx - zero
			if the link should get its extended attributes
			from the target file.
				**  or  **
		     non-zero to skip setting the extended attributes
		*** WARNING *** if cx is non-zero, the Link's target
		WILL *NOT* be checked for validity. 

RETURN:		IF ERROR:
			carry set
			ax = FileError
		ELSE
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	On a multiuser system, if one user creates a link to
	SP_APPLICATION, then other users will see that link as
	pointing to THEIR SP_APPLICATION directories, not the one that
	the original user intended.  To overcome this, resolve the
	standard path before calling FileCreateLink (This means, of
	course, that there is no way to look at someone else's
	complete SP_APPLICATION directory)

	No checking of link depth is made here

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/14/92   	Initial version.
	dlitwin	10/13/92	added facility to skip grabbing extended
				 attributes from the target file.
	Todd	5/09/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dot	TCHAR	'.',0

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment	resource
FileCreateLink		proc	far
	mov	ss:[TPD_dataBX], handle FileCreateLinkReal
	mov	ss:[TPD_dataAX], offset FileCreateLinkReal
	GOTO	SysCallMovableXIPWithDSDXAndESDI
FileCreateLink		endp
CopyStackCodeXIP	ends

else

FileCreateLink		proc	far
	FALL_THRU	FileCreateLinkReal
FileCreateLink		endp

endif

FileCreateLinkReal	proc far

linkFilename	local	fptr.char	push	ds, dx
skipAttrsFlag	local	word		push	cx
targetPath	local	fptr
targetDisk	local	word
linkAttrsHan	local	hptr.LinkAttrs
linkAttrsSeg	local	sptr.LinkAttrs
extAttrData	local	FSPathExtAttrData
fpld		local	hptr.FSPathLinkData

	uses	bx, cx, dx, es, di, si

	.enter

; Used by called routine
ForceRef	extAttrData

EC <	call	ECCheckPath			>

	clr	ss:[fpld]
	clr	ss:[linkAttrsHan]


	;
	; If the TARGET disk handle is a standard path, parse it down as far
	; as it'll go.  This also gets rid of any leading slash
	;

	test	bx, DISK_IS_STD_PATH_MASK
	jz	storeTarget

	call	FileParseStandardPath
	cmp	{TCHAR} es:[di], 0
	jne	gotPath
	segmov	es, cs
	lea	di, dot

gotPath:
	mov_tr	bx, ax

storeTarget:

	mov	ss:[targetDisk], bx
	movdw	ss:[targetPath], esdi

	;
	; If creating something in a standard path, make sure all local
	; dirs up to and including the path exist.
	;

	call	FileEnsureLocalPath
	jc	done

	;
	; Save the target disk.  Start by figuring out how much data
	; we need to save
	;

	clr	cx
	mov	bx, ss:[targetDisk]
	tst	bx
	jz	afterGetSize
	call	DiskSave		; cx - # bytes to save

afterGetSize:
	mov	ax, cx			; no mov_tr
	add	ax, size FSPathLinkData
	call	MemAllocSetError	; bx - handle of mem block
	jc	done

	mov	ss:[fpld], bx

	;
	; Now that we've allocated the memory, actually save the
	; thing, unless we found out earlier that there was no disk to
	; save. 
	;
	mov	es, ax
	mov	es:[FPLD_targetSavedDiskSize], cx
	jcxz	afterSave

	mov	bx, ss:[targetDisk]
	mov	di, offset FPLD_targetSavedDisk
	call	DiskSave
	jc	done

afterSave:

	;
	; Fetch the target attributes, unless we were told not to.
	;

	tst	ss:[skipAttrsFlag]
	jnz	createLink

	call	FileLinkFetchTargetAttrs
	jc	done

createLink:

	;
	; Call the fs driver to create the link.
	;

	mov	bx, ss:[fpld]
	movdw	es:[FPLD_targetPath], ss:[targetPath], ax
	lds	dx, ss:[linkFilename]
	mov	ax, FSPOF_CREATE_LINK shl 8
	call	FileWPathOpOnPath
	jc	done

	tst	ss:[skipAttrsFlag]
	jnz	done			; no attributes to set

	mov	es, ss:[linkAttrsSeg]
	mov	di, offset LA_attrs
	mov	cx, LINK_NUM_ATTRS
	mov	ax, FEA_MULTIPLE
	call	FileSetPathExtAttributes
	jnc	done

	;
	; There was an error setting the attributes.  Delete the link
	; file & keep the original error condition
	;

	push	ax
	lds	dx, ss:[linkFilename]
	call	FileDelete
	pop	ax
	stc

done:

	;
	; Free up our buffers.  Each value is either a valid handle or
	; zero, our utility routine will do the right thing.
	;

	mov	bx, ss:[fpld]
	call	FileMiscMemFree

	mov	bx, ss:[linkAttrsHan]
	call	FileMiscMemFree

	.leave
	ret
FileCreateLinkReal	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLinkFetchTargetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the attributes from the target into a buffer
		that we allocate

CALLED BY:	FileCreateLink

PASS:		ss:bp - inherited local vars

RETURN:		if error
			carry set
		else
			carry clear

DESTROYED:	ax,cx,dx,si,di,ds 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
linkAttrs	FileExtAttrDesc \
    <FEA_FILE_ID,	LA_fileID,	size LA_fileID>,
    <FEA_FILE_TYPE,	LA_type,	size LA_type>,
    <FEA_FLAGS,		LA_flags,	size LA_flags>,
    <FEA_RELEASE,	LA_release,	size LA_release>,
    <FEA_PROTOCOL,	LA_protocol,	size LA_protocol>,
    <FEA_TOKEN,		LA_token,	size LA_token>,
    <FEA_CREATOR,	LA_creator,	size LA_creator>,
    <FEA_DESKTOP_INFO,	LA_desktop,	size LA_desktop>,
    <FEA_FILE_ATTR,	LA_fileAttr,	size LA_fileAttr>,
    <FEA_GEODE_ATTR,	LA_geodeAttr,	size LA_geodeAttr>

LINK_NUM_ATTRS	equ	length linkAttrs

LinkAttrs	struct
    LA_attrs		FileExtAttrDesc	LINK_NUM_ATTRS dup(<>)
    LA_type		GeosFileType
    LA_flags		GeosFileHeaderFlags
    LA_release		ReleaseNumber
    LA_protocol		ProtocolNumber
    LA_token		GeodeToken
    LA_creator		GeodeToken
    LA_desktop		FileDesktopInfo
    LA_fileAttr		FileAttrs
    LA_geodeAttr	GeodeAttrs
    LA_fileID		FileID
LinkAttrs	ends

FileLinkFetchTargetAttrs	proc near

	uses	ds,es,bx

	.enter	inherit	FileCreateLinkReal

	clr	ss:[linkAttrsHan]

	;
	; Get the attributes from the target file.
	;

	mov	ax, size LinkAttrs
	call	MemAllocSetError
	jc	done

	mov	ss:[linkAttrsHan], bx
	mov	ss:[linkAttrsSeg], ax
	mov	ss:[extAttrData].FPEAD_attr, FEA_MULTIPLE
	mov	ss:[extAttrData].FPEAD_buffer.segment, ax
	mov	ss:[extAttrData].FPEAD_buffer.offset, offset LA_attrs

	;
	; Copy in the array of attributes to get and set. 
	; 

	mov	es, ax
	mov	di, offset LA_attrs
	segmov	ds, cs
	mov	si, offset linkAttrs
	mov	cx, size linkAttrs/2
		CheckHack <(size linkAttrs and 1) eq 0>
	rep	movsw
		
	;
	; Now point all the FEAD_value.segments to the block.  The
	; .offset fields are already set correctly
	; 

	mov	di, offset LA_attrs
	mov	cx, length LA_attrs

setSegmentLoop:
	mov	es:[di].FEAD_value.segment, es
	add	di, size FileExtAttrDesc
	loop	setSegmentLoop

	;
	; Get 'em
	;

getAttrs::
	mov	cx, ss:[targetDisk]
	call	PushToRoot
	jc	done

	lds	dx, ss:[targetPath]
	lea	bx, ss:[extAttrData]
	mov	cx, LINK_NUM_ATTRS
	mov	ax, FSPOF_GET_EXT_ATTRIBUTES shl 8
	call	FileRPathOpOnPath
	call	FilePopDir

	;
	; Take the FILE_ID of the target and change it to the
	; TARGET_FILE_ID attribute
	;

EC <	pushf						>
EC <	cmp	es:[LA_attrs].FEAD_attr, FEA_FILE_ID	>
EC <	ERROR_NE -1					>
EC <	popf						>

	mov	es:[LA_attrs].FEAD_attr, FEA_TARGET_FILE_ID
	jnc	done


	;
	; Allow ERROR_ATTR_NOT_FOUND to go through.  All attributes
	; will have their default values anyway...
	;

	cmp	ax, ERROR_ATTR_NOT_FOUND
	je	done
	stc

done:
	.leave
	ret

FileLinkFetchTargetAttrs	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileReadLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a link

CALLED BY:	GLOBAL

PASS:		ds:dx - link filename
		es:di - buffer to contain target path
		cx - size of buffer 

RETURN:		If link was read successfully
			carry clear
			bx - disk handle
			es:di - filled in

		ELSE
			carry set
			ax - FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment	resource
FileReadLink		proc	far
	mov	ss:[TPD_dataBX], handle FileReadLinkReal
	mov	ss:[TPD_dataAX], offset FileReadLinkReal
	GOTO	SysCallMovableXIPWithDSDX
FileReadLink		endp
CopyStackCodeXIP	ends

else

FileReadLink			proc	far
	FALL_THRU	FileReadLinkReal
FileReadLink			endp

endif

FileReadLinkReal	proc far
	uses	ds, si, cx, dx di

pathBuffer	local	fptr	push	es, di
pathBufferSize	local	word	push	cx
bufferHandle	local	word

	.enter

	mov	ax, FSPOF_READ_LINK shl 8
	call	FileRPathOpOnPath
	jc	done

	mov	bx, cx			; handle of link data
	mov	ss:[bufferHandle], bx
	call	FileGetLinkDataCommon
	jc	freeBlock

	;
	; Copy the path into the caller's buffer
	;

	mov	si, dx
	les	di, ss:[pathBuffer]
	mov	cx, ss:[pathBufferSize]
10$:
SBCS <	lodsb							>
DBCS <	lodsw							>
SBCS <	stosb							>
DBCS <	stosw							>
	LocalIsNull	ax
	loopne	10$

freeBlock:
	push	bx
	mov	bx, ss:[bufferHandle]
	call	FileMiscMemFree
	pop	bx
done:	
	.leave
	ret
FileReadLinkReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetLinkExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set extra data for a link file

CALLED BY:	GLOBAL

PASS:		ds:dx - filename of link file
		es:di - buffer of data
		cx - size of buffer

RETURN:		if no error:
			carry clear
		else
			carry set
			ax - FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileSetLinkExtraData	proc	far
	call	SysCopyToStackESDI
	mov	ss:[TPD_dataBX], handle	FileSetLinkExtraDataReal
	mov	ss:[TPD_dataAX], offset	FileSetLinkExtraDataReal
	call	SysCallMovableXIPWithDSDX
	call	SysRemoveFromStack
	ret
FileSetLinkExtraData	endp

CopyStackCodeXIP	ends
else

FileSetLinkExtraData	proc	far
	FALL_THRU	FileSetLinkExtraDataReal
FileSetLinkExtraData	endp

endif

FileSetLinkExtraDataReal	proc far
	uses	bx
	.enter
	CheckHack <(size FSPathLinkExtraDataParams eq 4)>
	push	es, di
	mov	bx, sp
	mov	ah, FSPOF_SET_LINK_EXTRA_DATA
	call	FileWPathOpOnPath
	lea	sp, ss:[bx+(size FSPathLinkExtraDataParams)]
	.leave
	ret
FileSetLinkExtraDataReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetLinkExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the extra data associated with a link

CALLED BY:	GLOBAL

PASS:		ds:dx - filename of link file
		es:di - buffer of data
		cx - size of buffer, or zero to get extra data size.

RETURN:		if data fetched OK:
			carry clear
			cx - # of bytes read, or size of extra data
			if CX was passed in as zero.
		else
			carry set
			ax = FileError 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
FileGetLinkExtraData	proc	far
	mov	ss:[TPD_dataBX], handle FileGetLinkExtraDataReal
	mov	ss:[TPD_dataAX], offset FileGetLinkExtraDataReal
	GOTO	SysCallMovableXIPWithDSDX
FileGetLinkExtraData	endp
CopyStackCodeXIP	ends

else

FileGetLinkExtraData	proc	far
	FALL_THRU	FileGetLinkExtraDataReal
FileGetLinkExtraData	endp
endif

FileGetLinkExtraDataReal	proc far
	uses	bx
	.enter
	CheckHack <(size FSPathLinkExtraDataParams eq 4)>
	push	es, di
	mov	bx, sp
	mov	ah, FSPOF_GET_LINK_EXTRA_DATA
	call	FileRPathOpOnPath
	lea	sp, ss:[bx+(size FSPathLinkExtraDataParams)]
	.leave
	ret
FileGetLinkExtraDataReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileConstructActualPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct the actual path of the TARGET of the passed
		file, if it's a link, or the path to the file if it's
		not.  If the file is known not to be a link,
		FileResolveStandardPath should be used, as it's faster.

CALLED BY:	GLOBAL

PASS: 		dx - nonzero  to add drive name

		bx - disk handle:
			0 		-> prepend current path, using disk
					   handle from there.
			StandardPath	-> prepend logical path for the
					   standard path, returning top-level
					   disk handle
			disk handle	-> ds:si is absolute; disk handle used
					   only if dx is non-zero
		ds:si - tail of path being constructed (must be absolute if
			bx is non-zero and not a StandardPath constant)
 		es:di - buffer for path
		cx - size of buffer

RETURN:		carry set if error:
			ax - FileError
						
		carry clear if OK:
			es:di - unchanged
			bx - disk handle
			al - FileAttrs of final target

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <rootDirAP	char	C_BACKSLASH,0					>
DBCS <rootDirAP	wchar	C_BACKSLASH,0					>

; This buffer is allocated on the heap to minimize stack usage.

ConstructActualPathData	struct
	CAPD_handle		hptr.ConstructActualPathData

	CAPD_buffer1		PathName		<>
	CAPD_buffer2		PathName		<>
	; We need 2 buffers, since we'll be doing a lot of path
	; copying.  We don't refer to them by name, we just keep
	; swapping the "source" and "dest" pointers to point to them
	; in alternating fasion

	CAPD_source		nptr.char
	CAPD_dest		nptr.char

	CAPD_diskHandle		word
	; Current (working) disk handle

	CAPD_callerDest		fptr.char
	; Destination buffer that caller passed in

	CAPD_destSize		word
	; Size of caller's buffer

	CAPD_frspFlags	FRSPFlags			<>
	; Whether caller wants us to return disk name (passed in DX to
	; FileConstructFullPath.

	CAPD_fileAttrs	FileAttrs			<>
	; Attributes of the thing at the end of the trail

	CAPD_linkCount	byte	0
	; keep us from going into an infinite loop.  Initialized to
	; zero by MemAllocSetError
	
ConstructActualPathData	ends

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP		segment	resource
FileConstructActualPath		proc	far
	mov	ss:[TPD_dataBX], handle FileConstructActualPathReal
	mov	ss:[TPD_dataAX], offset FileConstructActualPathReal
	GOTO	SysCallMovableXIPWithDSSI
FileConstructActualPath		endp
CopyStackCodeXIP		ends

else

FileConstructActualPath		proc	far
	FALL_THRU	FileConstructActualPathReal
FileConstructActualPath		endp

endif

FileConstructActualPathReal	proc far
	uses	cx,dx,di,si,ds,es,bp
	.enter

	mov	bp, bx			; passed disk handle

	;
	; Allocate a working directory
	;

	call	FilePushDir

	;
	; Create our temporary data block
	;

	mov	ax, size ConstructActualPathData
	call	MemAllocSetError
	LONG	jc	done

	;
	; Initialize the data fields
	;

	push	es
	mov	es, ax
	pop	es:[CAPD_callerDest].segment
	mov	es:[CAPD_callerDest].offset, di

	mov	es:[CAPD_destSize], cx
	mov	es:[CAPD_handle], bx
	clr	ax
	tst	dx
	jz	gotFlags
	ornf	ax, mask FRSPF_ADD_DRIVE_NAME
gotFlags:
	mov	es:[CAPD_frspFlags], ax

	mov	bx, bp			; passed disk handle	

	;
	; Initialize the SOURCE and DEST pointers.  Actual values 
	; are unimportant, as long as they remain opposites.
	;

	mov	es:[CAPD_source], offset CAPD_buffer1
	mov	di, offset CAPD_buffer2
	mov	es:[CAPD_dest], di

	;
	; If the passed path is relative to the current directory then
	; we should construct the full path, so that we uncover links
	; that we're already in.   DX is set correctly
	;

	tst	bx
	jz	constructFull

	;
	; Should also construct the full path if we were passed a NULL
	; path, or a path that only contains a backslash.
	;
SBCS <	cmp	{byte} ds:[si], 0					>
DBCS <	cmp	{wchar} ds:[si], 0					>
	je	constructFull

	cmp	{word} ds:[si], '\\'
	jne	setCurrentPathToDiskHandle
DBCS <	cmp	{wchar} ds:[si][2], 0					>
DBCS <	jne	setCurrentPathToDiskHandle				>

		
constructFull:

	mov	cx, size PathName
	call	FileConstructFullPath
	segmov	ds, es

	;
	; Now, set our SOURCE pointer to point to the full path.  If
	; DX was nonzero, then the path contains a drive spec, so
	; clear BX so that we don't waste time setting the disk
	; handle. 
	;

	call	swapSourceDest
	tst	dx
	jz	startLoop
	clr	bx

startLoop:

	;
	; Set the disk handle as our current path, so that we can access
	; the various components.  Set the path BEFORE calling resolve
	; std path, because we might jump to here after reading a link
	; to a different disk or standard path.
	;
	;	bx - disk handle (or zero)

	tst	bx
	jz	resolveStandardPath

setCurrentPathToDiskHandle:

	call	setCurPath
	jc	freeBufferES


resolveStandardPath:

	;
	; Use FileResolveStandardPath to get the actual path of
	; the file we're looking at.  This will resolve any links
	; except for the final component, which we have to do
	; ourselves.
	;
	; 	ds:si - source path
	;	es:di - dest buffer

	mov	di, es:[CAPD_dest]
	mov	cx, size PathName	; buffer always same size
	mov	ax, es:[CAPD_frspFlags]
	mov	dx, si
	call	FileResolveStandardPath
	jnc	pathOK

freeBufferES:
	mov	bx, es:[LMBH_handle]
	call	FileMiscMemFree
	jmp	done

pathOK:
	;
	; From now on, both segment registers will point to
	; ConstructActualPathData 
	;

	segmov	ds, es
	mov	ds:[CAPD_fileAttrs], al
	mov	ds:[CAPD_diskHandle], bx

	;
	; We've just copied data into the DEST buffer, but now we want
	; to make it the SOURCE -- FileReadLink will read data into
	; the DEST buffer.
	;

	call	swapSourceDest

	;
	; Make sure the thing is a link -- if not, then we're done.
	;

	test	al, mask FA_LINK
	jz	returnResults

	;
	; FileResolveStandardPath may have returned us a different
	; disk handle, so set the current path to that disk handle
	; again. 
	;

	call	setCurPath
	jc	freeBufferES
		
	;
	; Read the link's target into the dest buffer
	;

	mov	dx, ds:[CAPD_source]
	mov	di, ds:[CAPD_dest]
	mov	cx, size PathName
	call	FileReadLink
	jc	freeBuffer

	;
	; Make sure things aren't getting out of hand...
	;
	inc	ds:[CAPD_linkCount]
	cmp	ds:[CAPD_linkCount], MAX_LINK_COUNT
	jne	linkCountOK

	mov	ax, ERROR_TOO_MANY_LINKS
	stc
	jmp	freeBuffer

linkCountOK:

	;
	; We've found a link.  Change into the disk handle returned to
	; us, and start again
	;

	call	swapSourceDest
	jmp	startLoop
	
returnResults:
	mov	si, ds:[CAPD_source]
	les	di, ds:[CAPD_callerDest]
	LocalCopyString
	mov	al, ds:[CAPD_fileAttrs]

freeBuffer:

	push	bx
	mov	bx, ds:[CAPD_handle]
	call	FileMiscMemFree
	pop	bx

done:
	call	FilePopDir

	.leave
	ret

swapSourceDest:

	;
	; Exchange the SOURCE and DEST pointers.  Return SI pointing
	; to SOURCE, and DI pointing to DEST
	;

	mov	si, ds:[CAPD_source]
	mov	di, ds:[CAPD_dest]
	xchg	si, di
	mov	ds:[CAPD_source], si
	mov	ds:[CAPD_dest], di
	retn

setCurPath:

	push	ds
	segmov	ds, cs
	mov	dx, offset rootDirAP
			CheckHack <segment rootDirAP eq @CurSeg>
			
	call	FileSetCurrentPath
	pop	ds
	retn

FileConstructActualPathReal	endp




if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error-check a path

CALLED BY:	FileCreateLink

PASS:		es:di - path tail
		bx - disk handle

RETURN:		nothing 

DESTROYED:	nothing (even preserves flags)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPath	proc near
	uses	ax,cx,di,si

	.enter

	pushf

	;
	; If the disk handle is zero, then make sure a drive specifier
	; is given.  We don't support relative links
	;

	tst	bx
	jnz	gotDisk

	mov	si, di
findColon:
SBCS <	lodsb	es:						>
DBCS <	lodsw	es:						>
	LocalIsNull	ax
	ERROR_Z	MALFORMED_PATH
	LocalCmpChar	ax, ':'
	jne	findColon
gotDisk:
	;
	; Make sure path doesn't end in a backslash, since when the
	; link is evaluated, we might tack data on at the end.
	;


	;
	; Scan to the end of the string
	;

	LocalLoadChar	ax, C_NULL
SBCS <	mov	cx, size PathName				>
DBCS <	mov	cx, (size PathName)/2				>
	LocalFindChar
	tst	cx
	ERROR_Z	PATH_BUFFER_OVERFLOW

SBCS <	cmp	{byte} es:[di-2], C_BACKSLASH			>
DBCS <	cmp	{wchar} es:[di-4], C_BACKSLASH			>
	ERROR_E	MALFORMED_PATH

	popf
	.leave
	ret
ECCheckPath	endp

endif		; if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMiscMemFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	byte-saving near proc to free mem and preserve carry

CALLED BY:	FileCreateLink, 
		FileConstructActualPath

PASS:		bx - handle to free, or zero	

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMiscMemFree	proc near
	pushf
	tst	bx
	jz	done
	call	MemFree
done:
	popf
	ret
FileMiscMemFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MemAllocSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block of memory with ALLOC_DYNAMIC_LOCK,
		and HAF_ZERO_INIT, setting 
		AX = ERROR_INSUFFICIENT_MEMORY on error

CALLED BY:	FileCreateLink, FileCopyAttributesFromTargetToLink, 
		FileConstructActualPath

PASS:		ax - size to allocate

RETURN:		if error
			carry set
			ax - FileError (ERROR_INSUFFICIENT_MEMORY)
		else
			carry clear
			ax - address of locked block
			bx - mem handle


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MemAllocSetError	proc near
	uses	cx
	.enter
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocFar
	jc	setError		; almost never taken.
done:
	.leave
	ret

setError:
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	done

MemAllocSetError	endp



Filemisc	ends

;------------------------------------------------------

FileSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileComparePaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two paths

CALLED BY:	EXTERNAL

PASS:		cx - disk handle of path 1
		ds:si - pathname #1 (DS = 0 if null path)

		dx - disk handle of path #2
		es:di - pathname #2 (ES = 0 if null path)

RETURN:		al - PathCompareType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	- assumes neither path contains a trailing backslash

	- does NOT deal with links.  Call FileConstructActualPath on
	each path before calling this routine if you suspect that
	links are involved.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/16/92   	Initial version.
	Todd	04/28/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <nullPath	char	0						>
DBCS <nullPath	wchar	0						>

if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileComparePaths	proc	far
	mov	ss:[TPD_dataBX], handle FileComparePathsReal
	mov	ss:[TPD_dataAX], offset FileComparePathsReal
	GOTO	SysCallMovableXIPWithDSSIAndESDI
FileComparePaths	endp
CopyStackCodeXIP		ends

else

FileComparePaths	proc	far
	FALL_THRU	FileComparePathsReal
FileComparePaths	endp
endif

FileComparePathsReal	proc far

	uses	bx,cx,dx,di,si,ds,es

if	ERROR_CHECK
	;
	; In the case here where we have big local variables, We want to
	; check stack space before .enter ourselves.  Otherwise if we use
	; ECCheckStack after .enter, it won't give a valid backtrace when
	; sp has wrapped around.  --- AY 2/19/97
	;
	push	ax
	mov	ax, ss:[TPD_stackBot]
	add	ax, STACK_RESERVED_FOR_INTERRUPTS - offset pathBuf2
					; offset of bottom-most local variable
	cmp	ax, sp
	ERROR_AE STACK_OVERFLOW
	pop	ax
endif	; ERROR_CHECK

diskHandle1	local	word	push	cx
diskHandle2	local	word	push	dx
path1		local	fptr.char	push	ds, si
path2		local	fptr.char	push	es, di
pathBuf1	local	PathName
pathBuf2	local	PathName

	.enter

	;
	; If either segment is zero, then point that tail to the
	; nullPath 
	;

	mov	ax, ds
	tst	ax
	jnz	gotPath1
	mov	ss:[path1].segment, cs
	mov	ss:[path1].offset, offset nullPath
gotPath1:

	mov	ax, es
	tst	ax
	jnz	gotPath2
	mov	ss:[path2].segment, cs
	mov	ss:[path2].offset, offset nullPath
gotPath2:


	;
	; Construct the full path for path 1  (XXX: Do we really need
	; to call FileConstructFullPath before calling
	; FileParseStandardPath? )
	;

	lds	si, ss:[path1]
	segmov	es, ss
	lea	di, ss:[pathBuf1]
	mov	bx, cx
	mov	cx, size pathBuf1
	clr	dx				; no drive spec
	push	di
	call	FileConstructFullPath
	pop	di
	LONG jc	error

	;
	; Parse it down to a standard path.  Make ss:[path1] point to
	; the correct path tail
	;

	call	FileParseStandardPath
	test	ax, DISK_IS_STD_PATH_MASK
	jz	notStandardPath1
	mov	ss:[diskHandle1], ax
notStandardPath1:
	mov	ss:[path1].segment, ss
	mov	ss:[path1].offset, di

	;
	; Now, do the same for the 2nd path (ES and DX are still set
	; correctly) 
	;

	lea	di, ss:[pathBuf2]
	lds	si, ss:[path2]
	mov	bx, ss:[diskHandle2]
	mov	cx, size pathBuf2
	push	di
	call	FileConstructFullPath
	pop	di
	jc	error

	call	FileParseStandardPath
	test	ax, DISK_IS_STD_PATH_MASK
	jz	notStandardPath2
	mov	ss:[diskHandle2], ax
notStandardPath2:
	mov	ss:[path2].segment, ss
	mov	ss:[path2].offset, di

	;
	; If the 2 disk handles are the same, then we just need to
	; compare the path tails
	;

	mov	ax, ss:[diskHandle1]
	mov	bx, ss:[diskHandle2]
	cmp	ax, bx
	je	compareTails

	;
	; If one disk handle is a std path, and the other one isn't
	; then the 2 must be unrelated.
	; (HACK:  Add them -- if the sum is ODD, then there's a mismatch)
	;
	CheckHack <DISK_IS_STD_PATH_MASK eq 1>
	
	push	ax
	add	ax, bx
	test	ax, DISK_IS_STD_PATH_MASK
	pop	ax
	jnz	unrelated

	;
	; If the disk handles aren't std paths, (and they're not the
	; same, because of the test above), then they're unrelated
	;

	test	ax, DISK_IS_STD_PATH_MASK
	jz	unrelated

	;
	; They ARE standard paths, so see if path 2 is a subdir of
	; path 1 (we don't check the opposite case -- that's up to the
	; caller). 
	;

	les	di, ss:[path1]
SBCS <	tst	<{byte} es:[di]>					>
DBCS <	tst	{wchar}es:[di]						>
	je	checkStdPaths
SBCS <	cmp	{word} es:[di], C_BACKSLASH or (0 shl 8)		>
DBCS <	cmp	{wchar}es:[di], C_BACKSLASH				>
	jne	unrelated
DBCS <	tst	{wchar}es:[di][2]					>
DBCS <	jnz	unrelated						>

checkStdPaths:
	push	bp
	mov	bp, ax
	call	FileStdPathCheckIfSubDir
	pop	bp
	tst	ax
	jnz	unrelated
subdir:
	mov	al, PCT_SUBDIR

done:
	.leave				; <---- exit here
	ret
equal:
	mov	al, PCT_EQUAL
	jmp	done
error:
	mov	al, PCT_ERROR
	jmp	done

unrelated:
	mov	al, PCT_UNRELATED
	jmp	done


compareTails:

	;
	; Compare the 2 path tails.  If we find a difference before
	; the end of path 1, then we know the two paths are unrelated.
	;

	lds	si, ss:[path1]
	les	di, ss:[path2]
startLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	endOfPath1
SBCS <	scasb								>
DBCS <	scasw								>
	je	startLoop

	;
	; The 2 paths aren't the same -- so either path 1 is a subdir
	; of path 2 (which we don't care about), or else they're
	; unrelated, so bail.
	;
	jmp	unrelated


endOfPath1:

	;
	; We've reached the end of path 1.  Read the next byte from
	; path 2.  If it's NULL, then the 2 paths are equal.

	mov	ax, es:[di]
	LocalIsNull ax
	jz	equal

	;
	; Also check for a trailing backslash on path 2
	;
SBCS <	cmp	ax, C_BACKSLASH or (0 shl 8)				>
DBCS <	cmp	ax, C_BACKSLASH						>
DBCS <	jne	notEqual						>
DBCS <	tst	{wchar}es:[di][2]					>
	je	equal
DBCS <notEqual:								>


	;
	; If it's a backslash, then path 2 is a subdir of path 1.  Otherwise,
	; the 2 are unrelated.
	;
	
SBCS <	cmp	al, C_BACKSLASH						>
DBCS <	cmp	ax, C_BACKSLASH						>
	je	subdir

	;
	; another possibility -- if path 1 is actually only a null, then
	; path two is a subdir of path 1 -- brianc 12/29/98
	;
	LocalPrevChar	dssi
	cmp	si, ss:[path1].offset
	je	subdir

	jmp	unrelated
FileComparePathsReal	endp

FileSemiCommon ends
