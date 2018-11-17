COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosLink.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 6/92   	Initial version.

DESCRIPTION:
	Implementation of links

	$Id: dosLink.asm,v 1.1 97/04/10 11:55:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathOpsRare	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkCreateLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a link

CALLED BY:	DOSPathOp

PASS:		CWD locked
		ds:dx	- filename of link to create
		ss:bx   - FSPathLinkData
		es:si 	- DiskDesc on which to create file

RETURN:		IF link created successfully:
			carry clear
			bx - destroyed
		ELSE
			carry set
			AX - error code (FileError)
			bx - file handle of link data (if link
			encountered along path)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkCreateLink	proc far
		uses	cx,dx,si,di,ds,es

curDisk			local	word			push 	si
fsPathLinkData		local	hptr.FSPathLinkData	push	bx
fileHandle		local	word
linkData		local	DOSLinkData
linkPos			local	dword 	
; File position of this link in the file

		.enter

	;
	; First map the virtual to the native.  If there's no error,
	; then a file already exists, so exit.
	; 
		call	DOSVirtMapFilePath
		jnc	fileExists

	;
	; See if a link was encountered.  If not, go ahead and create
	; the file (should we really be checking for ERROR_FILE_NOT_FOUND?)
	;
		cmp	ax, ERROR_LINK_ENCOUNTERED
		jne	doCreate

	;
	; See if dosFinalComponent was actually at the end of the path
	; being mapped.  If not, then exit, so caller can resolve link
	;

		push	ds, es, di
		call	PathOpsRare_LoadVarSegDS
		les	di, ds:[dosFinalComponent]
		add	di, ds:[dosFinalComponentLength]
DBCS <		add	di, ds:[dosFinalComponentLength]		>
SBCS <		cmp	{byte} es:[di], 0				>
DBCS <		cmp	{wchar} es:[di], 0				>
		pop	ds, es, di
		stc
		jne	doneJMP

	;
	; Link already exists at end of path.  Free the link data
	; block, and exit
	;
		call	MemFree
fileExists:
		mov	ax, ERROR_FILE_EXISTS
		stc
doneJMP:
		jmp	done

doCreate:
	;
	; Open the special directory file.
	;

		mov	al, FILE_ACCESS_RW or FILE_DENY_W
		call	DOSLinkOpenDirectoryFile
		jnc	saveHandle

	;
	; If it doesn't exist, create it -- passing the current
	; DiskDesc.
	;

		cmp	ax, ERROR_FILE_NOT_FOUND
		stc
		jne	doneJMP

		call	PathOpsRare_LoadVarSegDS	
		call	DOSLinkCreateDirectoryFile		
		jc	doneJMP

saveHandle:

		mov	ss:[fileHandle], bx
		jc	closeFile		; if error from LOCK

	;
	; Move to the end of the file
	;

		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_END
		clr	cx, dx
		call	DOSUtilInt21
		LONG jc	closeFile
		movdw	ss:[linkPos], dxax

	;
	; Initialize the link's attributes
	;
		call	DOSLinkInitHeader
		LONG jc	errorDeleteLink

	;
	; Store the size of the saved disk
	;
		mov	bx, ss:[fsPathLinkData]
		call	MemDerefDS
		mov	ax, ds:[FPLD_targetSavedDiskSize]
		mov	ss:[linkData].DLD_diskSize, ax

	;
	; Get length of path not including NULL (no need to store NULL
	; in file, since we're storing the length)
	;

		les	di, ds:[FPLD_targetPath]
		mov	cx, -1 
		LocalLoadChar	ax, C_NULL
		LocalFindChar
		not	cx
		dec	cx
DBCS <		shl	cx, 1						>
		mov	ss:[linkData].DLD_pathSize, cx

	;
	; Write the header of the link data.  Store 0 in the extra
	; data size, 'cause there is none at first.
	;

		push	ds		; segment of FSPathLinkData
		clr	ss:[linkData].DLD_extraDataSize
		segmov	ds, ss
		lea	dx, ss:[linkData]
		mov	cx, size linkData
		mov	ah, MSDOS_WRITE_FILE
		mov	bx, ss:[fileHandle]
		call	DOSUtilInt21
		pop	ds		; segment of FSPathLinkData
		jc	errorDeleteLink

	;
	; Write the saved disk data
	;
		mov	cx, ss:[linkData].DLD_diskSize
		jcxz	afterWriteDisk

		mov	dx, offset FPLD_targetSavedDisk
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		jc	errorDeleteLink

afterWriteDisk:

	;
	; Now, write the pathname
	;

		lds	dx, ds:[FPLD_targetPath]
		mov	cx, ss:[linkData].DLD_pathSize
		mov	ah, MSDOS_WRITE_FILE
		mov	bx, ss:[fileHandle]
		call	DOSUtilInt21
		jc	errorDeleteLink

closeFile:

	;
	; Close the file
	;

		mov	bx, ss:[fileHandle]
		call	DOSLinkCloseDirectoryFile
		
	;
	; Generate notification if link was created.
	; 
		jc	done
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterNotif
endif	; SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeGetCurPathID	; cx:dx - ID
		mov	ax, FCNT_CREATE
		call	PathOpsRare_LoadVarSegDS
		lds	bx, ds:[dosFinalComponent]
		mov	si, ss:[curDisk]
		call	FSDGenerateNotify
afterNotif::
		clc		
done:
		.leave
		ret

errorDeleteLink:
	;
	; Move to the start of the link, and truncate the file there
	;

		push	ax			; error code
		movdw	cxdx, ss:[linkPos]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		pop	ax
		stc
		jmp	closeFile

DOSLinkCreateLink	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkInitHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the link header

CALLED BY:	DOSLinkCreateLink

PASS:		dosLinkHeader - buffer to be filled in
		dosFinalComponent - longname of link file
		bx - file handle of DirName file

RETURN:		carry set if error (disk full ?)

DESTROYED:	es,di,si,cx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkInitHeader	proc near
		uses	ds

		.enter

		call	PathOpsRare_LoadVarSegDS
	;
	; Copy the longname into the standard header.
	; 
		segmov	es, ds
		mov	di, offset dosLinkHeader.DLH_longName
		lds	si, es:[dosFinalComponent]
		mov	cx, (size DLH_longName)/2
		rep	movsw
	;
	; Now actually write the beast out. This of course positions the file
	; after the header, which is where we need it.
	; 
		segmov	ds, es
		mov	dx, offset dosLinkHeader
		mov	cx, size dosLinkHeader
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21

		.leave
		ret
DOSLinkInitHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkRenameLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a link

CALLED BY:	DOSPathOp

PASS:		dosFinalComponent -- old name
		si - disk on which link resides
		bx:cx - new name

RETURN:		if link renamed OK:
			carry clear
		else
			carry set
			ax = FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	All we need to do is set the longname, which can be done
	elsewhere. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkRenameLink	proc far
		uses	bx, cx

extAttrData	local	FSPathExtAttrData

		.enter

		mov	ss:[extAttrData].FPEAD_attr, FEA_NAME
		movdw	ss:[extAttrData].FPEAD_buffer, bxcx
		lea	bx, ss:[extAttrData]
		mov	cx, size DLH_longName 
		call	DOSLinkSetExtAttrs

		.leave
		ret
DOSLinkRenameLink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkDeleteLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a link

CALLED BY:	DOSPathOp

PASS:		dosFinalComponent -- name of link to nuke

RETURN:		if deleted OK:
			carry clear

		else
			carry set
			AX = FileError

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkDeleteLink	proc far

		uses	es,cx,dx,di

header		local	DOSLink
		.enter

		mov	al, FILE_ACCESS_RW or FILE_DENY_W
		call	DOSLinkOpenDirectoryFile
		jc 	done

		segmov	es, ss
		lea	di, ss:[header]
		call	DOSLinkFindFinalComponent
		jc	closeFile

		mov	cx, ss:[header].DL_data.DLD_pathSize
		add	cx, ss:[header].DL_data.DLD_diskSize
		add	cx, ss:[header].DL_data.DLD_extraDataSize
		add	cx, size DOSLink

	;
	; Move back to the start of the link, and delete the space
	;

		call	DOSLinkRewind
		call	DOSLinkDeleteSpace
		jc	closeFile

	;
	; Generate notification on successful delete.
	; 
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterNotif
endif	; SEND_DOCUMENT_FCN_ONLY
		push	bx			; save file handle
		call	DOSLinkCalculateLinkID
		mov	ax, FCNT_DELETE
		call	FSDGenerateNotify
		pop	bx
afterNotif::
		clc

closeFile:
		call	DOSLinkCloseDirectoryFile
done:
		.leave
		ret
DOSLinkDeleteLink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkDeleteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete some # of bytes in the file

CALLED BY:	DOSLinkDeleteLink, DOSLinkInsertSpace

PASS:		bx - file handle, positioned at place to delete space
		cx - # bytes to delete

RETURN:		if deleted OK:
			carry clear
			bx - new file handle
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
DOSLinkDeleteSpace	proc near
		uses	bx, cx, dx, si, ds, di, es


fileHandle	local	word	push	bx
dest		local	dword
source		local	dword
memHandle	local	hptr

		.enter

	;
	; Set up the source and destination pointers for moving file data
	;

		call	DOSLinkGetFilePosition 
		movdw	ss:[dest], dxax
		add	ax, cx
		adc	dx, 0
		movdw	ss:[source], dxax

	;
	; Allocate a buffer to hold parts of the file as we read &
	; write consecutive blocks
	;

		mov	ax, DOS_LINK_BUFFER_SIZE
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jnc	memOK

		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

memOK:
		mov	ds, ax
		mov	ss:[memHandle], bx

		mov	bx, ss:[fileHandle]
startLoop:
		movdw	cxdx, ss:[source]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		clr	dx
		mov	ah, MSDOS_READ_FILE
		mov	cx, DOS_LINK_BUFFER_SIZE
		call	DOSUtilInt21
		jc	freeMemHandle	; some sort of disk error

		push	ax		; # of bytes read
		movdw	cxdx, ss:[dest]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
		pop	cx		; # of bytes to write

		jcxz	truncate

		clr	dx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21

		adddw	ss:[source], DOS_LINK_BUFFER_SIZE
		adddw	ss:[dest], DOS_LINK_BUFFER_SIZE

	;
	; If we didn't read/write a full record, then we must be at
	; the end of the file, so exit, truncating the file after the
	; last byte written.
	;
		cmp	cx, DOS_LINK_BUFFER_SIZE
		je	startLoop

	;
	; Truncate the file at the current position, by writing 0 bytes.
	;
truncate:
		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21

	;
	; Clean up
	;
freeMemHandle:
		pushf
		mov	bx, ss:[memHandle]
		call	MemFree
		popf
done:
		.leave
		ret
DOSLinkDeleteSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkMoveToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move this link to the end of the DIRNAME file, so we
		can append data to it.

CALLED BY:	DOSLinkSetExtraData

PASS:		bx - links file handle -- positioned at START of link
		header

		cx - size of link

RETURN:		carry set on error:
			ax	= FileError
		carry clear on success:
			ax	= destroyed

DESTROYED:	cx,dx,si,di 

PSEUDO CODE/STRATEGY:	
	Assume the space to be inserted is at the end of the link for
	now. 
	Copy the entire link out to a buffer
	delete the link
	append the link at the end

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkMoveToEnd	proc near

		uses	ds 

fileHandle		local	word	push	bx
linkSize		local	word	push	cx
position		local	dword
bufferHandle		local	hptr
endOfFile		local	dword

		.enter


	;
	; Save current file position
	;

		call	DOSLinkGetFilePosition
		movdw	ss:[position], dxax

	;
	; Allocate a memory buffer, and read the link into it
	;

		mov_tr	ax, cx			; size of link
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jnc	memOK
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		mov	bx, ss:[fileHandle]
		jmp	done
memOK:
		mov	ss:[bufferHandle], bx
		mov	ds, ax
		clr	dx
		mov	cx, ss:[linkSize]
		mov	ah, MSDOS_READ_FILE
		mov	bx, ss:[fileHandle]
		call	DOSUtilInt21
		jc	done

	;
	; Go to end of file, and store the current end position
	;

		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_END
		clr	cx, dx
		call	DOSUtilInt21
		jc	done
		movdw	ss:[endOfFile], dxax

	;
	; Write data.  If we have any problems writing whatsoever,
	; make sure we truncate the file at the old end.
	;

		mov	cx, ss:[linkSize]
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		jc	undoWrite
		cmp	ax, cx
		stc
		mov	ax, ERROR_SHORT_READ_WRITE
		jne	undoWrite
		

	;
	; Commit the file, because there was a case once where we
	; wrote the data successfully, and were unable to read it
	; back.  Doing a commit seems to solve that problem
	;
		mov	ah, MSDOS_COMMIT
		call	DOSUtilInt21
		jc	done

	;
	; Free the buffer, 'cause we're about to allocate another one,
	; and we don't want to be greedy 
	;
		mov	bx, ss:[bufferHandle]
		call	MemFree

	;
	; Restore the file position, and delete the # of bytes that
	; was the original link
	;

		movdw	cxdx, ss:[position]
		mov	bx, ss:[fileHandle]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		mov	cx, ss:[linkSize]
		call	DOSLinkDeleteSpace
		jc	done

	;
	; Position ourselves at the start of the final link -- this is
	; FILE_END - linkSize
	;

		mov	dx, ss:[linkSize]
		clr	cx
		negdw	cxdx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_END
		call	DOSUtilInt21
done:

		.leave
		ret
undoWrite:
	;
	; Truncate the file at the position where we started writing
	; data 
	;

		push	ax			; error code
		movdw	cxdx, ss:[endOfFile]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		pop	ax			; original error code
		stc
		jmp	done

DOSLinkMoveToEnd	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkCalculateLinkID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the FileID for the link on which we're operating.

CALLED BY:	(INTERNAL) DOSLinkSetExtAttrs, DOSLinkDeleteLink
PASS:		dosFinalComponent	= name of link
RETURN:		cxdx	= FileID
DESTROYED:	ax
SIDE EFFECTS:	dosPathBuffer = current dir


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkCalculateLinkID proc	far
		uses	ds, si
		.enter
	;
	; Compute the ID for the current directory.
	; 
		call	DOSFileChangeGetCurPathID
	;
	; Augment it with the stuff in the final component. For a normal file
	; we'd use the DOS name, but links have no DOS name, so...
	; 
		call	PathOpsRare_LoadVarSegDS
		lds	si, ds:[dosFinalComponent]
		call	DOSFileChangeCalculateIDLow
		.leave
		ret
DOSLinkCalculateLinkID endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkSetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store "extra data" in the link

CALLED BY:	DOSPathOp

PASS:		dosFinalComponent - points to link filename
		ss:bx - FSPathLinkExtraDataParams
		cx - size of FPLEDP_buffer
		si - disk on which link resides

RETURN:		if no error:
			carry clear
		else
			carry set
			ax = FileError  

DESTROYED:	ds, dx (preserved by DOSPathOp), di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkSetExtraData	proc far

		uses	bx,cx,si,es

		clr	ax

passedParams	local	word	push	bx
bufferSize	local	word	push	cx
header		local	DOSLink
position	local	dword
sizeWithoutED	local	word

		.enter

		mov	al, FILE_ACCESS_RW or FILE_DENY_W
		call	DOSLinkGetSetExtraDataSetup
		LONG jc	done
	;
	; Figure out the size without the extra data, as we'll use it
	; below. 
	;

		mov	dx, size DOSLink
		add	dx, ss:[header].DL_data.DLD_diskSize
		add	dx, ss:[header].DL_data.DLD_pathSize
		mov	ss:[sizeWithoutED], dx

	;
	; See if we need to insert or delete space
	;

		mov	cx, ss:[bufferSize]
		sub	cx, ss:[header].DL_data.DLD_extraDataSize
		je	afterInsertDelete
		ja	insertSpace

	;
	; Delete space -- move to the "extra data" portion, and delete
	; the desired number -(CX) of bytes
	;

		call	DOSLinkGetFilePosition
		movdw	ss:[position], dxax

		push	cx		
		mov	dx, ss:[sizeWithoutED]
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		call	DOSUtilInt21		; dx:ax - position
		pop	cx

		neg	cx
		call	DOSLinkDeleteSpace
		jc	closeFile

		movdw	cxdx, ss:[position]
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21		; dx:ax - position
		
		jmp	afterInsertDelete

insertSpace:

	;
	; Move this link to the end, so we can append space
	;

		mov	cx, ss:[sizeWithoutED]
		add	cx, ss:[header].DL_data.DLD_extraDataSize
		call	DOSLinkMoveToEnd
		jc	closeFile

afterInsertDelete:

	;
	; Save the current file position (start of the link)
	;

		call	DOSLinkGetFilePosition
		movdw	ss:[position], dxax

	;
	; Move to the start of the extra data, as it's now the right
	; size. 
	;
		mov	dx, ss:[sizeWithoutED]
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		call	DOSUtilInt21		; dx:ax - position

	;
	; Write the buffer out.  Don't abort on error, because we still
	; need to write the extra data size, even if the extra data
	; itself wasn't written correctly -- otherwise the file will
	; be corrupted.   
	; 
	; Don't write if CX is zero, because that will truncate the file.
	;
		mov	cx, ss:[bufferSize]
		jcxz	afterWrite
		mov	di, ss:[passedParams]
		lds	dx, ss:[di].FPLEDP_buffer
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
afterWrite:

	;
	; Store the new size in the header.
	;
		movdw	cxdx, ss:[position]
		add	dx, offset DL_data.DLD_extraDataSize
		adc	cx, 0
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		mov	ah, MSDOS_WRITE_FILE
		segmov	ds, ss
		lea	dx, ss:[bufferSize]
		mov	cx, size bufferSize
		call	DOSUtilInt21

	;
	; Send out FCNT_CONTENTS notification for the link.
	; 
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterNotif
endif	; SEND_DOCUMENT_FCN_ONLY
		push	bx
		call	DOSLinkCalculateLinkID
		mov	ax, FCNT_CONTENTS
		call	FSDGenerateNotify
		pop	bx
afterNotif::
		clc

closeFile:
		call	DOSLinkCloseDirectoryFile

done:
		.leave
		ret
DOSLinkSetExtraData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetSetExtraDataSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for getting or setting the extra data.

CALLED BY:	(INTERNAL) DOSLinkSetExtraData, DOSLinkGetExtraData
PASS:		ss:bp	= inherited stack frame
		al	= FileAccess to employ
RETURN:		carry set on error:
			ax	= FileError
		carry clear if ok:
			ss:[header]	= link header
			bx	= directory file
DESTROYED:	es, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetSetExtraDataSetup proc	near
		.enter	inherit DOSLinkSetExtraData
	;
	; Open the directory file with the proper access.
	; 
		call	DOSLinkOpenDirectoryFile
		jc	done
	;
	; Locate the link in the file, keeping our position at the
	; start of it, if its there...
	; 
		segmov	es, ss
		lea	di, ss:[header]
		call	DOSLinkFindFinalComponent
		jc	closeFile

		call	DOSLinkRewind

done:
		.leave
		ret
closeFile:
	;
	; Close the directory file on error.
	; 
		call	DOSLinkCloseDirectoryFile
		jmp	done
DOSLinkGetSetExtraDataSetup endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetExtraData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the extra data for a link

CALLED BY:	DOSPathOp

PASS:		ss:bx - FSPathLinkExtraDataParams
		cx - size of ss:[bx].FPLEDP_buffer, or zero

RETURN:		if data fetched OK:
			cx - # bytes read
			carry clear
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
DOSLinkGetExtraData	proc far
		uses	bx,si,es


passedParams	local	word	push	bx
bufferSize	local	word	push	cx
header		local	DOSLink

		.enter

		mov	al, FILE_ACCESS_R or FILE_DENY_W
		call	DOSLinkGetSetExtraDataSetup
		jc	done

	;
	; Position the file at the start of the extra data.
	;
	
		mov	dx, ss:[header].DL_data.DLD_diskSize
		add	dx, ss:[header].DL_data.DLD_pathSize
		add	dx, size DOSLink
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		call	DOSUtilInt21

	;
	; See how many bytes of extra data there are.  If user just
	; wanted size, then exit
	;
		mov	ax, ss:[bufferSize]
		mov	cx, ss:[header].DL_data.DLD_extraDataSize
		tst	ax
		jz	closeFile

	;
	; If buffer is large enough, then read all the data,
	; otherwise, just read the buffer's size (XXX: Maybe we should
	; return an error if the buffer is too small)
	;

		cmp	ax, cx
		ja	readData
		mov_tr	cx, ax
readData:		

	;
	; Read the data into the buffer
	;

		mov	di, ss:[passedParams]
		lds	dx, ss:[di].FPLEDP_buffer
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		mov	cx, ax		; # bytes read (no mov_tr)

closeFile:
		call	DOSLinkCloseDirectoryFile

done:

		.leave
		ret
DOSLinkGetExtraData	endp



PathOpsRare	ends

PathOps		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkOpenDirectoryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the directory file, and return its DOS file handle

CALLED BY:	INTERNAL

PASS:		al - FileAccess mode to open file

RETURN:		if file exists:
			bx = DOS file handle
			carry clear
		else
			carry set
			ax = FileError
			bx = destroyed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	This procedure will NOT create the file if it doesn't exist --
	the only routine that does that is DOSLinkCreateLink.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkOpenDirectoryFile	proc far

		uses	ds,es,di,si,cx,dx


		.enter

	;
	; See if the file exists, because %^$&#^ NetWare allows us to
	; open files that aren't in the current directory on the
	; current default drive!
	;
		mov_tr	bx, ax
		call	PathOps_LoadVarSegDS
		mov	dx, offset dirNameFile
		CheckHack <segment dirNameFile eq idata>
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 0
		call	DOSUtilInt21
		jc	done

		mov_tr	ax, bx
		mov	bx, NIL
		call	DOSAllocDosHandleFar	; allocate a JFT slot

	;
	; Try and open the file.  If we can't open it, then free the
	; DOS handle
	; 
		call	DOSUtilOpenFar

		mov	bx, ax		; DOS file handle
		jc	freeHandle

done:
		.leave
		ret
freeHandle:
	;
	; We didn't allocate a DOS handle, so release the slot.
	;

		mov	bx, NIL
		call	DOSFreeDosHandleFar
		jmp	done

DOSLinkOpenDirectoryFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkCloseDirectoryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close the file and free the handle

CALLED BY:	DOSFileEnum

PASS:		bx - DOS handle of directory file

RETURN:		nothing -- flags preserved

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkCloseDirectoryFile	proc far
		uses	ax, bx
		.enter

		pushf

		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21

		mov	bx, NIL
		call	DOSFreeDosHandleFar

		popf

		.leave
		ret
DOSLinkCloseDirectoryFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the link data into a memory buffer

CALLED BY:	DOSLinkCheckLink

PASS:		es:si - points 1 past end of link filename
		mapLink, ds:dx - DOSLink structure filled in.

		bx    - DOS file handle of directory file
			links file positioned after DOSLink structure
			for this link

RETURN:		if data read successfully:
			carry clear
			ax - handle of locked block containing
				 FSPathLinkData
		else
			carry set
			ax - error code

DESTROYED:	cx,dx
		File position in links file

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	cdb	7/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetData	proc near
		uses	di, ds, es

trail		local	fptr		push	es, si
fileHandle	local	hptr		push	bx
bufferHandle	local	hptr
trailingSize	local	word
fileSize	local	word

		.enter
		assume ds:dgroup, es:nothing


	;
	; Determine the size of the data, not including the header, or
	; the extra data.
	;
		mov	ax, ds:[mapLink].DL_data.DLD_diskSize
		add	ax, ds:[mapLink].DL_data.DLD_pathSize
		mov	ss:[fileSize], ax

	;
	; Add the size of the trailing component(s), plus NULL.
	;

		mov	di, si

		mov	cx, -1
		LocalLoadChar	ax, C_NULL
		LocalFindChar
		not	cx

DBCS <		shl	cx, 1						>
		mov	ss:[trailingSize], cx

	;
	; Allocate the memory block to be returned to the caller.
	; Memory size is header size + file size + trailing component
	; size. 
	;
		mov	ax, ss:[fileSize]
		add	ax, size FSPathLinkData
		add	ax, cx			; size of trailing
						; component 

		mov	cx, ALLOC_DYNAMIC_LOCK		
		call	MemAlloc
		jnc	gotMem
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

gotMem:

	;
	; Put dgroup into ES and the block to be returned into DS
	;
		segmov	es, ds
		mov	ds, ax
		assume	es:dgroup, ds:nothing
		mov	ss:[bufferHandle], bx

	;
	; Store the size of the saved disk in the memory block
	;
		mov	ax, es:[mapLink].DL_data.DLD_diskSize		
		mov	ds:[FPLD_targetSavedDiskSize], ax 

	;
	; Read the link data from the file into the buffer. (XXX:
	; should I return an error on short read?).  We read the saved
	; disk, followed by the target path, but not the extra data.
	;
		mov	dx, offset FPLD_targetSavedDisk
		mov	bx, ss:[fileHandle]
		mov	cx, ss:[fileSize]
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		jc	freeBlock

	;
	; Point ds:FPLD_targetPath at the beginning of the path (XXX:
	; This block must remain locked throughout its lifetime for
	; this to work.  A similar situation occurs in
	; DOSVirtGetAllExtAttrs, so I don't think it's a problem (it's
	; actually faster, 'cause it doesn't have to be locked a
	; second time by the kernel).
	;
		mov	ds:[FPLD_targetPath].segment, ds
		mov	ax, es:[mapLink].DL_data.DLD_diskSize
		add	ax, size FSPathLinkData
		mov	ds:[FPLD_targetPath].offset, ax
	
	;
	; Append trailing component.  CX will always be at least 1.
	;

		mov	di, ss:[fileSize]
		add	di, size FSPathLinkData
		segmov	es, ds
		lds	si, ss:[trail]
		mov	cx, ss:[trailingSize]
DBCS <		shr	cx, 1						>
SBCS <		cmp	{char}es:[di-1], C_BACKSLASH			>
DBCS <		cmp	{wchar}es:[di-2], C_BACKSLASH			>
		jne	copyTail
SBCS <		tst	{char}ds:[si]					>
DBCS <		tst	{wchar}ds:[si]					>
		jz	copyTail
		LocalNextChar	dssi	; skip leading backslash in tail,
		dec	cx		;  allowing trailing backslashes in
					;  link...
copyTail:
		assume	es:nothing, ds:nothing
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>
		
	;
	; Return buffer handle to caller
	;
		mov	ax, ss:[bufferHandle]
		clc			; indicate happiness
done:

		.leave
		ret

freeBlock:

	;
	; An error occurred, so free the block
	;
		push	bx
		mov	bx, ss:[bufferHandle]
		call	MemFree
		stc
		pop	bx
		jmp	done


DOSLinkGetData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkCheckLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current component is a link

CALLED BY:	DOSVirtCheckGeosName

PASS:		ss:bp	= inherited stack frame
		ds = es	= dgroup

RETURN:		carry set if it's a link or some other error:
			ax	= ERROR_LINK_ENCOUNTERED:
				  ss:[passedBX] = handle of link data
				= FileError
		carry clear if not a link:
			ax	= destroyed
DESTROYED:	es, di, si, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkCheckLink proc	near
		uses	es
		.enter	inherit	DOSVirtMapCheckGeosName

EC <		call	ECCheckStack			>

	;
	; Open the links file.  If it's not found or can't be opened,
	; then just go ahead and start the third pass.
	;
		mov	al, FILE_ACCESS_R or FILE_DENY_W 
		call	DOSLinkOpenDirectoryFile
		jc	notFound

		mov	di, offset mapLink
		call	DOSLinkFindFinalComponent
		jc	closeDirFile
	
	;
	; It's a link, so read the data, and signal an error, as the
	; caller will need to take special steps to handle this.
	;

		mov	dx, di		; ds:dx <- DOSLink
		les	di, ss:[componentStart]
		mov	si, ss:[nextComponent]
		LocalPrevChar	essi
		call	DOSLinkGetData
		mov	ss:[passedBX], ax	; mem handle of link data

		mov	ax, ERROR_LINK_ENCOUNTERED	; assume ok (CF=0)
closeDirFile:
		call	DOSLinkCloseDirectoryFile	; preserves carry
notFound:
		cmc		; set carry if link found and read
				;  ok, else clear carry

		assume	ds:nothing, es:nothing
		.leave
		ret
DOSLinkCheckLink endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkFindDosName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a link whose DOS name matches the name stored in
		dosNativeFFD.FFD_name 

CALLED BY:	DOSLinkFindFinalComponent

PASS:		es:di - buffer of size DOSLink into which to read data

RETURN:		if error
			carry set
			ax - FileError
			bx - file handle (may have changed)
		else
			carry clear
			es:di - buffer filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkFindDosName	proc near
		uses	cx,dx,di,si,es,ds

destBuffer	local	fptr.DOSLink	push	es, di
convertedLinkName	local	DosDotFileName

		.enter

EC <		call	ECCheckStack					>

		call	DOSLinkFindFirst
		jc	done

findLinkLoop:
	;
	; Convert this link's name to a DOS name
	;
		segmov	ds, es
		lea	di, es:[di].DL_header.DLH_longName
		mov	si, di		
		mov	dx, di

		LocalStrSize
		
		add	dx, cx		; ds:dx - points after link name

		segmov	es, ss
		lea	di, ss:[convertedLinkName]
		push	cx, di
		call	DOSVirtMapCheckComponentIsValidDosName
		pop	cx, di

		jc	next
		

	;
	; Compare the converted name with dosNativeFFD.FFD_name.  CX
	; is the length of the name stored in the file, WITHOUT null
	;
		call	PathOps_LoadVarSegDS		
		mov	si, offset dosNativeFFD.FFD_name
DBCS <		shr	cx, 1		; size to length		>
		repe	cmpsb
		
		jne	next		; carry is clear
	;
	; Make sure the next character is NULL in FFD_name 
	;
SBCS <		cmp	{byte} ds:[si], 0				>
DBCS <		cmp	{wchar} ds:[si], 0				>
		je	done
		
next:
		les	di, ss:[destBuffer]
		call	DOSLinkFindNext
		jnc	findLinkLoop
done:
		.leave
		ret

DOSLinkFindDosName	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkRewind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move backwards in the file by the size of a DOSLink data
		structure 

CALLED BY:	DOSLinkSetExtAttrs, DOSLinkCheckLink, DOSLinkDeleteLink

PASS:		bx - file handle

RETURN:		if error
			carry set
		else
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkRewind	proc far
	uses	ax,cx,dx
	.enter
	mov	cx, -1
	mov	dx, -(size DOSLink)
	mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
	call	DOSUtilInt21

	.leave
	ret
DOSLinkRewind	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkFindFinalComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the link whose name is stored at
		*(dosFinalComponent) in the links file

CALLED BY:	INTERNAL

PASS:		bx - DOS handle of links file
		es:di - buffer of size DOSLink in which to read the data

RETURN:		if found:
			carry clear
			file positioned to start of link data
		else
			carry set
			ax = ERROR_FILE_NOT_FOUND
			bx - DOS file handle of DIRNAME file (may have
			changed, believe it or not).

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkFindFinalComponent	proc far
		uses	ds, si, es, di, cx

 		.enter

EC <		call	ECCheckStack					>

	;
	; If the thing being searched for has a valid DOS name, then
	; use that instead
	;
		call	PathOps_LoadVarSegDS

		cmp	{byte} ds:[dosNativeFFD].FFD_name, 0
		je	notValidDosName

		call	DOSLinkFindDosName
		jc	notFound
		jmp	done

notValidDosName:		
		
		mov	dx, di		; es:dx - destination
		mov	cx, ds:[dosFinalComponentLength]
		lds	si, ds:[dosFinalComponent]

		call	DOSLinkFindFirst
		jc	notFound
findLinkLoop:

	;
	; Compare the strings, up to dosFinalComponentLength.  
	;
		push	si, cx
		lea	di, es:[di].DLH_longName
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		pop	si, cx
		jne	next

	;
	; They match up to dosFinalComponentLength, so make sure the
	; filename in the file is null-terminated
	;

SBCS <		cmp	{byte} es:[di], 0				>
DBCS <		cmp	{wchar} es:[di], 0				>
		je	done
next:
		mov	di, dx			; es:di - destination
		call	DOSLinkFindNext
		jnc	findLinkLoop
notFound:
		mov	ax, ERROR_FILE_NOT_FOUND
done:
		.leave
		ret

DOSLinkFindFinalComponent	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkFindFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the links file at the first link

CALLED BY:	DOSLinkFindFinalComponent, DOSLinkEnum

PASS:		bx - DOS handle of links file
		es:di - pointer to a DOSLink structure to be filled in.

RETURN:		if error
			carry set
			bx - handle of links file, if changed
		else
			carry clear 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkFindFirstFar proc	far
		call	DOSLinkFindFirst
		ret
DOSLinkFindFirstFar endp

DOSLinkFindFirst	proc near
		uses	cx,dx

		.enter

	;
	; Go past the GeosFileHeader which begins this file.
	;

		clr	cx
		mov	dx, size GeosFileHeader
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21
	
		call	DOSLinkReadLinkHeader
	
		.leave
		ret
DOSLinkFindFirst	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkFindNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using the data in the current link, find the next one.

CALLED BY:	DOSLinkFindLink, DOSLinkEnum

PASS:		bx - DOS file handle of link file
		es:di - DOSLink data structure containing the current
			link.   Will be filled in with the next one.

RETURN:		if link found:
			carry clear
		else
			carry set

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkFindNext	proc near

		uses	cx, dx
		.enter
	;
	; Position the file at the next link
	;

		mov	dx, es:[di].DL_data.DLD_diskSize
		add	dx, es:[di].DL_data.DLD_pathSize
		add	dx, es:[di].DL_data.DLD_extraDataSize
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		call	DOSUtilInt21
		jc	done

	;
	; Read the next link
	;

		call	DOSLinkReadLinkHeader

done:
		.leave
		ret
DOSLinkFindNext	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkReadLinkHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the header, returning an error if it doesn't seem
		right. 

CALLED BY:	DOSLinkFindFirst, DOSLinkFindNext

PASS:		bx - links file handle
		es:di - pointer to a DOSLink structure to be filled in

RETURN:		if valid link header
			carry clear
			file positioned after DOSLink data structure.
		else
			carry set
			ax - FileError
			bx - file handle (may have changed)

DESTROYED:	dx

PSEUDO CODE/STRATEGY:
	If an error is encountered reading the link, then the file
	will be truncated to 256 bytes.  In order to do this, we may
	need to reopen the file read/write, since it may currently be
	opened read-only.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkReadLinkHeader	proc near

		uses	es, di, cx, ds

		.enter

		mov	cx, size DOSLink
		segmov	ds, es
		mov	dx, di
		mov	ah, MSDOS_READ_FILE
		call	DOSUtilInt21
		jc	done
	;
	; Check short read, return error if so.
	;
		cmp	ax, cx
		je	checkSignature	
		mov	ax, ERROR_SHORT_READ_WRITE
		stc
		jmp	done

checkSignature:
	;
	; Make sure the signature matches, in case I get the urge to
	; change the data format again...
	;

		cmp	({dword} es:[di].DLH_signature).low, DLH_SIG_1_2
		jne	error
		cmp	({dword} es:[di].DLH_signature).high, DLH_SIG_3_4
		jne	error
	
	;
	; Carry is clear here
	;

done:
		.leave
		ret
error:

EC <	WARNING INVALID_DIRNAME_FILE	>

	;
	; Close the file, reopen it read-write (if possible), and
	; truncate it at byte #256.  Keep the file open, because the
	; caller expects a valid file handle in BX
	;
		call	DOSLinkCloseDirectoryFile
		mov	al, FA_READ_WRITE
		call	DOSLinkOpenDirectoryFile
		jc	tryOpenReadOnlyAndBail

		clr	cx
		mov	dx, size GeosFileHeader
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21

setError:
		mov	ax, ERROR_FILE_NOT_FOUND
		stc
		jmp	done


tryOpenReadOnlyAndBail:

	;
	; Well, we're on a read-only FS, or some nonsense, so reopen
	; the file read-only, since our caller expects the file to be open.
	;
		mov	al, FA_READ_ONLY
		call	DOSLinkOpenDirectoryFile
		jmp	setError

DOSLinkReadLinkHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all the links in the current directory, calling
		a callback routine for each.

CALLED BY:	DOSFileEnum

PASS:		ds - segment of FileGetExtAttrData
		(on stack:  callback -- routine to call for each link)
		(			vfptr if XIP`ed		     )

RETURN:		nothing 

DESTROYED:	nothing 

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkEnum	proc	far	callback:fptr.far

		.enter

		mov	al, FILE_ACCESS_R or FILE_DENY_W 
		call	DOSLinkOpenDirectoryFile
		cmc
		jnc	done

	;
	; Read the entire link into the FileGetExtAttrData buffer, and
	; set the flag that specifies that we've read the data.
	;

		segmov	es, ds
		mov	di, offset FGEAD_link
		mov	ax, offset DOSLinkFindFirst
		ornf	ds:[FGEAD_flags], mask FGEAF_HAVE_HEADER

enumLinksLoop:
		call	ax
		jc	endLinksNoError
FXIP<		mov	ss:[TPD_dataBX], bx				>
FXIP<		movdw	bxax, ss:[callback]				>
FXIP<		call	ProcCallFixedOrMovable				>
NOFXIP<		call	ss:[callback]					>
		jc	endLinks
		
		mov	ax, offset DOSLinkFindNext
		jmp	enumLinksLoop

endLinksNoError:
		clc
endLinks:
		call	DOSLinkCloseDirectoryFile
done:
		.leave
		ret	@ArgSize
DOSLinkEnum	endp




PathOps		ends

PathOpsRare	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkCreateDirectoryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the special directory file

CALLED BY:	DOSLinkCreateLink, DOSVirtCreateDirectoryFile

PASS:		es:si - DiskDesc
		ds - dgroup

RETURN:		if created ok:
			carry clear
			bx = DOS file handle
		else
			carry set
			ax = FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
		Create the special directory file.  Store the DOS name
		of the current directory therein, so that dosEnum
		believes that this file is for real.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkCreateDirectoryFile	proc far
		uses	cx,dx,di,si,ds

if _MSLF
pathBuf		local	MSDOS7_MAX_PATH_SIZE dup(char)
else
pathBuf		local	DOS_STD_PATH_LENGTH+2 dup(char)
endif
longName	local	FileLongName

		.enter

	;
	; Create the file
	;
		call	DOSPathCreateDirectoryFileCommon
		jc	done

		push	ax		; SFN
if _MSLF
	;
	; Fetch the long-name current path on the default (current) drive.
	; No need to prepend a leading backslash as one will be returned
	; by DOS7.
	;
		push	'.' or (0 shl 8)	; ss:sp = "."
		movdw	dssi, sssp		; ds:si = "."
		segmov	es, ss
		mov	cx, (0x80 shl 8) or MGCPNF_LONG_PATH_NAME
getPathName:
		lea	di, ss:[pathBuf]	; es:di = pathBuf
		mov	ax, MSDOS7F_GET_COMPLETE_PATH_NAME
		call	DOSUtilInt21
	;
	; Move to the end of the string, and then search backwards for
	; the \.  We know there's at least one there, 'cause DOS7 returns
	; the leading backslash.
	; 
else
	;
	; Fetch the current path on the default (current) drive. Make
	; life easy on ourselves by putting a backslash in the buffer
	; so we can search for it later.
	; 
		lea	si, ss:[pathBuf]
		segmov	ds, ss
		mov	{byte} ds:[si], '\\'
		inc	si
		mov	ah, MSDOS_GET_CURRENT_DIR
		clr	dl		; fetch from default drive
		call	DOSUtilInt21
	;
	; Move to the end of the string, and then search backwards for
	; the \.  We know there's at least one there, 'cause we put it
	; there! 
	; 
		segmov	es, ds
		mov	di, si
endif	; _MSLF
		clr	al
		mov	cx, length pathBuf
		repne	scasb
MSLF <		mov	dx, di			; dx = char after null	>
		std
		mov	al, '\\'
		repne	scasb
		cld

if _MSLF
	;
	; In GEOS, we only support DOS long name that are as long as
	; FILE_LONGNAME_LENGTH chars.  If the DOS long name is longer than
	; that, we always fall back and use the short alias name instead.
	;
		sub	dx, di			; dx = length of '\' + name +
						;  null + 1
		cmp	dx, FILE_LONGNAME_LENGTH + 3
		mov	cl, MGCPNF_SHORT_PATH_NAME
		ja	getPathName

		pop	ax			; clean up "." 
endif	; _MSLF

	;
	; Now map the DOS name to a GEOS name in our character set.
	; 
		lea	si, [di+2]		; ds:si - directory name
		lea	di, ss:[longName]
		mov	cx, size longName
		push	di
		call	DOSVirtMapDosToGeosName
		pop	di
	;
	; Set up the GEOS file, with the longname set appropriately.
	;
		
		pop	ax			; SFN
		mov	dx, GFT_DIRECTORY
		call	PathOpsRare_LoadVarSegDS
		call	DOSInitGeosFile
		jc	done

	;
	; Return a DOS handle to the caller
	;

		mov_tr	bx, ax			; SFN 
		call	DOSAllocDosHandleFar


done:
		.leave
		ret
DOSLinkCreateDirectoryFile	endp

PathOpsRare	ends

ExtAttrs	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetLinkAttrsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the FileExtAttributes of the current link into
		the passed data structure.

CALLED BY:	DOSLinkEnum, DOSLinkGetExtAttrs

PASS:		ds - FileGetExtAttrData segment

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear

DESTROYED:	es,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetExtAttrsLow	proc near

		uses	bx,cx,dx

		.enter

	;
	; We expect the caller to have already read in the header, so
	; make sure this is the case...
	;

EC <		test	ds:[FGEAD_flags], mask FGEAF_HAVE_HEADER	>
EC <		ERROR_Z HEADER_HASNT_BEEN_READ_YET			>


	;
	; Set the FA_LINK bit in the header
	;

		ornf	ds:[FGEAD_link].DL_header.DLH_fileAttr, mask FA_LINK

	;
	; HACK! Clear the (old) GFHF_LINK field, so that it doesn't
	; get returned to any callers.  If we ever go through and nuke
	; all existing links, then we can get rid of this line.
	;
		andnf	ds:[FGEAD_link].DL_header.DLH_flags, 
					GeosFileHeaderFlags

	;
	; Set up for the attribute loop.
	; 

		mov	cx, ds:[FGEAD_numAttrs]
		les	si, ds:[FGEAD_attrs]

		mov	ds:[FGEAD_sizeTable], offset getAttrLinkSizeTable
		CheckHack <segment getAttrLinkSizeTable eq @CurSeg>
		mov	ds:[FGEAD_routTable], offset getAttrLinkRoutTable
		CheckHack <segment getAttrLinkRoutTable eq @CurSeg>

		call	DOSVirtGetExtAttrsProcessLoop

		.leave
		ret

DOSLinkGetExtAttrsLow	endp

;-----------------------------------------------------------------------------
;	Attribute tables for links
;-----------------------------------------------------------------------------

; Zero means any size is OK
getAttrLinkSizeTable byte	0,		; FEA_MODIFIED
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
			0,			; FEA_CREATED
			0,			; FEA_PASSWORD
			0,			; FEA_CUSTOM
			size FileLongName,	; FEA_NAME
			size GeodeAttrs,	; FEA_GEODE_ATTR
			size DirPathInfo,	; FEA_PATH_INFO
			0,			; FEA_FILE_ID
			0,			; FEA_DESKTOP_INFO
			0,			; FEA_DRIVE_STATUS
			0,			; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			size FileID		; FEA_TARGET_FILE_ID

.assert (length getAttrLinkSizeTable) eq (FEA_LAST_VALID+1)

getAttrLinkRoutTable	nptr	DOSVirtGetAttrUnsupported,; FEA_MODIFICATION
			DOSLinkGetExtAttr,		; FEA_FILE_ATTR
			DOSLinkGetLinkSize,		; FEA_SIZE
			DOSLinkGetExtAttr,		; FEA_FILE_TYPE
			DOSLinkGetExtAttr,		; FEA_FLAGS
			DOSLinkGetExtAttr,		; FEA_RELEASE
			DOSLinkGetExtAttr,		; FEA_PROTOCOL
			DOSLinkGetExtAttr,		; FEA_TOKEN
			DOSLinkGetExtAttr,		; FEA_CREATOR
			DOSVirtGetAttrUnsupported,	; FEA_USER_NOTES
			DOSVirtGetAttrUnsupported,	; FEA_NOTICE
			DOSVirtGetAttrUnsupported,	; FEA_CREATION
			DOSVirtGetAttrUnsupported,	; FEA_PASSWORD
			DOSVirtGetAttrUnsupported,	; FEA_CUSTOM
			DOSLinkGetExtAttr,		; FEA_NAME
			DOSLinkGetExtAttr,		; FEA_GEODE_ATTR
			DOSVirtGetAttrPathInfo,		; FEA_PATH_INFO
			DOSLinkGetAttrFileID,		; FEA_FILE_ID
			DOSLinkGetExtAttr,		; FEA_DESKTOP_INFO
			DOSVirtGetAttrDriveStatus,	; FEA_DRIVE_STATUS
			DOSVirtGetAttrDisk,		; FEA_DISK
			DOSVirtGetAttrUnsupported,	; FEA_DOS_NAME
			DOSVirtGetAttrUnsupported,	; FEA_OWNER
			DOSVirtGetAttrUnsupported,	; FEA_RIGHTS
			DOSLinkGetExtAttr		; FEA_TARGET_FILE_ID

CheckHack <length getAttrLinkRoutTable eq FEA_LAST_VALID+1>


;
; Offsets of link extended attributes within the link header
; 
linkAttrOffsetTable word \
	0,					; FEA_MODIFICATION (not used)
	DLH_fileAttr,				; FEA_FILE_ATTR
	0,					; FEA_SIZE
	DLH_type,				; FEA_FILE_TYPE
	DLH_flags,				; FEA_FLAGS
	DLH_release,				; FEA_RELEASE
	DLH_protocol,				; FEA_PROTOCOL
	DLH_token,				; FEA_TOKEN
	DLH_creator,				; FEA_CREATOR
	0,					; FEA_USER_NOTES n.u
	0,					; FEA_NOTICE n.u
	0,					; FEA_CREATION n.u
	0,					; FEA_PASSWORD nuu
	0,					; FEA_CUSTOM (n.u.)
	DLH_longName,				; FEA_NAME
	DLH_geodeAttr,				; FEA_GEODE_ATTR
	0,					; FEA_PATH_INFO
	0,					; FEA_FILE_ID (n.u.)
	DLH_desktop,				; FEA_DESKTOP_INFO
	0,					; FEA_DRIVE_STATUS (n.u.)
	0,					; FEA_DISK (n.u.)
	0,					; FEA_DOS_NAME (n.u.)
	0,					; FEA_OWNER (n.u.)
	0,					; FEA_RIGHTS (n.u.)
	DLH_targetFileID			; FEA_TARGET_FILE_ID
CheckHack <length linkAttrOffsetTable eq FEA_LAST_VALID+1>






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetLinkSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of the current link

CALLED BY:	DOSLinkGetExtAttrsLow via DOSVirtGetExtAttrsProcessLoop

PASS:		es:di - buffer to store result
		ds - FileGetExtAttrData

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetLinkSize	proc near
		.enter

		mov	cx, ds:[FGEAD_link].DL_data.DLD_diskSize
		add	cx, ds:[FGEAD_link].DL_data.DLD_pathSize
		add	cx, ds:[FGEAD_link].DL_data.DLD_extraDataSize
		add	cx, size DOSLink

		
		mov	{word} es:[di], cx
		mov	{word} es:[di][2], 0	

		.leave
		ret
DOSLinkGetLinkSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetExtAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a single extended attribute from the link file

CALLED BY:	DOSVirtProcessAttrLoop

PASS:		es:di - attribute to fill in
		si - FileExtAttrDesc offset
		cx - size of data to store
		bx - attribute * 2
		ds - segment of FileGetExtAttrData

RETURN:		carry set if error

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetExtAttr	proc near

		.enter

		push	si
		mov	si, offset FGEAD_link
		add	si, cs:[linkAttrOffsetTable][bx]
		rep	movsb
		pop	si

		.leave
		ret
DOSLinkGetExtAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetAttrFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the FEA_FILE_ID for a link

CALLED BY:	DOSLinkGetExtAttrs

PASS:		es:di	= place to store result
		si	= FileExtAttrDesc offset
		bx	= attr * 2
		al	= FileGetExtAttrFlags
RETURN:		nothing
DESTROYED:	cx, di, ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetAttrFileID proc	near
		uses	dx, si, ds
		.enter
		test	al, mask FGEAF_HAVE_BASE_ID
		jz	getCurPathID

		movdw	cxdx, ds:[FGEAD_spec].FGEASD_enum.FED_baseID
addLinkID:
	;
	; Augment the ID by the longname
	; 
		mov	si, offset FGEAD_link.DL_header.DLH_longName
		call	DOSFileChangeCalculateIDLow
		mov	({FileID}es:[di]).low, dx
		mov	({FileID}es:[di]).high, cx
		.leave
		ret


getCurPathID:
	;
	; Get the ID for the current dir first, since caller wasn't kind
	; enough to pass it to us.
	; 
		call	DOSFileChangeGetCurPathID
		movdw	ds:[FGEAD_spec].FGEASD_enum.FED_baseID, cxdx
		ornf	ds:[FGEAD_flags], mask FGEAF_HAVE_BASE_ID
		jmp	addLinkID
DOSLinkGetAttrFileID endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Extended attributes for this link file

CALLED BY:	DOSPathOp, DOSLinkGetAttrs

PASS:		dosFinalComponent - filename of link in current
		directory. 

		ss:bx - FSPathExtAttrData

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetExtAttrs	proc far

singleAttr	local	FileExtAttrDesc

		uses	es, di, ds, bx, cx

		.enter

		mov	ax, ss:[bx].FPEAD_attr
		les	di, ss:[bx].FPEAD_buffer


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

		call	DOSAllocFileGetExtAttrData
		jc	exit

	;
	; Initialize the various pieces that always get the same things,
	; regardless of who called us.
	; 

		mov	ds:[FGEAD_disk], si
		mov	ds:[FGEAD_numAttrs], cx

		mov	ds:[FGEAD_attrs].offset, di
		mov	ds:[FGEAD_attrs].segment, es

	;
	; Open the special directory file
	;

		mov	al, FILE_ACCESS_R or FILE_DENY_W 
		call	DOSLinkOpenDirectoryFile
		jc	freeBlock

		mov	ds:[FGEAD_flags], mask FGEAF_HAVE_HEADER

	;
	; Find the link and read in its header in one fell swoop
	;
		segmov	es, ds
		mov	di, offset FGEAD_link
		call	DOSLinkFindFinalComponent
		jc	closeFile

	;
	; Call common routine to do the real work.
	; 
		call	DOSLinkGetExtAttrsLow
	;
	; Free the workspace without biffing the carry.
	; 
closeFile:
		call	DOSLinkCloseDirectoryFile
freeBlock:
		pushf
		mov	bx, ds:[FGEAD_block]
		call	MemFree
		popf
exit:
		.leave
		ret
DOSLinkGetExtAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkSetExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the extended attributes for this link 

CALLED BY:	DOSPathOp

PASS:		ss:bx - FSPathExtAttrData
		si - disk on which operation is being performed
		cx - size of FPEAD_buffer, or # attrs if FPEAD_attr =
		FEA_MULTIPLE 

		dosFinalComponent -- link filename

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	copied from DOSVirtSetExtAttrs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkSetExtAttrs	proc far

paramBX		local	nptr	push	bx
disk		local	word	push	si

if SEND_DOCUMENT_FCN_ONLY
likelyHasDoc	local	BooleanWord	push	BW_FALSE
endif	; SEND_DOCUMENT_FCN_ONLY
		
newHeader	local	DOSLink
singleAttr	local	FileExtAttrDesc
errorCode	local	FileError
fileHandle	local	word
linkID		local	FileID		; ID of link, for generating
					;  notification
notifyType	local	FileChangeNotificationType

		uses	es, di, ds, si, bx, cx

		.enter

		mov	ss:[errorCode], 0	; assume all is peachy
		mov	ss:[notifyType], FCNT_ATTRIBUTES ; and that this is a
							 ; straight attr-set
							 ; operation, not a
							 ; rename

	;
	; Open the file for read-write.  
	;

		mov	al, FILE_ACCESS_RW or FILE_DENY_W
		call	DOSLinkOpenDirectoryFile
		LONG jc	exit

		mov	ss:[fileHandle], bx
	;
	; Calculate the link's 32-bit ID 
	; 
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterLinkId
		dec	ss:[likelyHasDoc]	; likelyHasDoc = BW_TRUE
endif	; SEND_DOCUMENT_FCN_ONLY
		push	cx
		call	DOSLinkCalculateLinkID
		movdw	ss:[linkID], cxdx
		pop	cx
afterLinkId::
		
	;
	; Point to the named link. (XXX: Could optimize by storing
	; file position of link during DOSVirtMapComponent).
	;

		segmov	es, ss
		lea	di, ss:[newHeader]
		call	DOSLinkFindFinalComponent
	LONG	jc	closeFile

gotHeader::
	;
	;
	; Set up the array
	;
		mov	bx, ss:[paramBX]
		mov	ax, ss:[bx].FPEAD_attr
		les	di, ss:[bx].FPEAD_buffer


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
		cmp	ax, FEA_NAME
		jne	haveAttrArray
		mov	ss:[notifyType], FCNT_RENAME
haveAttrArray:
		push	es, di, cx
		mov	bx, es:[di].FEAD_attr
EC <		cmp	bx, FEA_LAST_VALID				>
EC <		ERROR_A	ILLEGAL_EXTENDED_ATTRIBUTE			>
		mov	cx, es:[di].FEAD_size
		tst	ch
		jnz	sizeError
		cmp	cl, cs:[setAttrLinkSizeTable][bx]
		ja	sizeError
sizeOK::
		shl	bx
		lds	si, es:[di].FEAD_value
		; pass:
		; 	ds:si	= FEAD_value
		; 	cx	= FEAD_size
		; 	bx	= FEAD_attr * 2
		; 	es:di	= FileExtAttrDesc
		; return:
		; 	nothing
		; nuke:
		; 	ds, si, cx, bx, ax, dx, es, di
		call	cs:[setAttrLinkRoutTable][bx]
nextAttr:
		pop	es, di, cx
		add	di, size FileExtAttrDesc
		loop	haveAttrArray
		
writeHeader:: 
	;
	; Write out the header.  We're currently positioned AFTER the
	; header, so back up first
	;

		mov	bx, ss:[fileHandle]
		call	DOSLinkRewind

	;
	; Make sure the FA_LINK bit is set in the FileAttrs always
	;
		ornf	ss:[newHeader].DL_header.DLH_fileAttr, mask FA_LINK

		mov	ah, MSDOS_WRITE_FILE
		segmov	ds, ss
		lea	dx, ss:[newHeader]
		mov	cx, size newHeader
		call	DOSUtilInt21

closeFile:
		call	DOSLinkCloseDirectoryFile

		jc	done
	;
	; Fetch any error we're to return, and set carry if there is one...
	; 
		mov	ax, ss:[errorCode]
		tst	ax
		jz	done
		stc
done:
		jc	exit
if SEND_DOCUMENT_FCN_ONLY
		tst_clc	ss:[likelyHasDoc]
		jz	exit
endif
	;
	; Generate notification.
	; 
		mov	ax, ss:[notifyType]
		cmp	ax, FCNT_ATTRIBUTES
		je	generateNotify
		lds	bx, ss:[singleAttr].FEAD_value
generateNotify:
		mov	si, ss:[disk]
		movdw	cxdx, ss:[linkID]
		call	FSDGenerateNotify
		clc
exit:
		.leave
		ret

sizeError:

	;
	; If an attr can't be set, don't return an error, just ignore
	; it. 
	;

		mov	ax, ERROR_ATTR_SIZE_MISMATCH
		cmp	cs:[setAttrLinkSizeTable][bx], 0
		jne	setSizeError
		clr	ax		; just ignore the error.
setSizeError:
		mov	ss:[errorCode], ax
		jmp	nextAttr

; 0 => attribute cannot be set
setAttrLinkSizeTable byte	\
			0,			; FEA_MODIFIED
			size FileAttrs,		; FEA_FILE_ATTR
			0,			; FEA_SIZE
			size GeosFileType,	; FEA_FILE_TYPE
			size GeosFileHeaderFlags,; FEA_FLAGS
			size ReleaseNumber,	; FEA_RELEASE
			size ProtocolNumber,	; FEA_PROTOCOL
			size GeodeToken,	; FEA_TOKEN
			size GeodeToken,	; FEA_CREATOR
			0,			; FEA_USER_NOTES
			0,			; FEA_NOTICE
			0,			; FEA_CREATED
			0,			; FEA_PASSWORD
			0,			; FEA_CUSTOM
			size FileLongName,	; FEA_NAME
			size GeodeAttrs,		; FEA_GEODE_ATTR
			0,			; FEA_PATH_INFO
			0,			; FEA_FILE_ID
			size FileDesktopInfo,	; FEA_DESKTOP_INFO
			0,			; FEA_DRIVE_STATUS
			0,			; FEA_DISK
			0,			; FEA_DOS_NAME
			0,			; FEA_OWNER
			0,			; FEA_RIGHTS
			size FileID		; FEA_TARGET_FILE_ID

.assert (length setAttrLinkSizeTable) eq (FEA_LAST_VALID+1)

setAttrLinkRoutTable	nptr	\
			eaCannotSet,		; FEA_MODIFICATION
			eaFileAttr,		; FEA_FILE_ATTR
			eaCannotSet,		; FEA_SIZE
			eaVirtual,		; FEA_FILE_TYPE
			eaVirtual,		; FEA_FLAGS
			eaVirtual,		; FEA_RELEASE
			eaVirtual,		; FEA_PROTOCOL
			eaVirtual,		; FEA_TOKEN
			eaVirtual,		; FEA_CREATOR
			eaCannotSet,		; FEA_USER_NOTES
			eaCannotSet,		; FEA_NOTICE
			eaCannotSet,		; FEA_CREATION
			eaCannotSet,		; FEA_PASSWORD
			eaCannotSet,		; FEA_CUSTOM
			eaVirtual,		; FEA_NAME
			eaVirtual,		; FEA_GEODE_ATTR
			eaCannotSet,		; FEA_PATH_INFO
			eaCannotSet,		; FEA_FILE_ID
			eaVirtual,		; FEA_DESKTOP_INFO
			eaCannotSet,		; FEA_DRIVE_STATUS
			eaCannotSet,		; FEA_DISK
			eaCannotSet,		; FEA_DOS_NAME
			eaCannotSet,		; FEA_OWNER
			eaCannotSet,		; FEA_RIGHTS
			eaVirtual		; FEA_TARGET_FILE_ID
CheckHack <length setAttrLinkRoutTable eq FEA_LAST_VALID+1>

	;--------------------
eaCannotSet:
		mov	ss:[errorCode], ERROR_ATTR_CANNOT_BE_SET
		retn

	;--------------------
eaVirtual:
		push	es, di
		segmov	es, ss
		lea	di, ss:[newHeader]
		add	di, cs:[linkAttrOffsetTable][bx]
		rep	movsb
		pop	es, di
		retn

eaFileAttr:

	;
	; Mask out everything but FA_SUBDIR, and or-in FA_LINK
	;
		lodsb		; al = FileAttrs
		andnf	al, DOS_LINK_FILE_ATTRS_ALLOWED
		ornf	al, mask FA_LINK
		mov	ss:[newHeader].DL_header.DLH_fileAttr, al
		retn

DOSLinkSetExtAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetFilePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current file position

CALLED BY:

PASS:		bx - DOS file handle of links file

RETURN:		dx:ax - file position

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetFilePosition	proc far
		uses	cx
		.enter
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
		clr	cx, dx
		call	DOSUtilInt21	
		.leave
		ret
DOSLinkGetFilePosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the FileAttrs fake value stored in the link
		header

CALLED BY:	DOSPathOp

PASS:		es:di - place to store FileAttrs record

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkGetAttrs	proc far
		.enter
		on_stack	retf
		mov	ax, offset DOSLinkGetExtAttrs
linkGetSetAttrCommon label near

	;
	; Set up data to pass to DOSLinkGetExtAttrs or DOSLinkSetExtAttrs.
	; 
		sub	sp, size FSPathExtAttrData
		mov	bx, sp
		push	cx		; make room/push value
		mov	ss:[bx].FPEAD_attr, FEA_FILE_ATTR
		mov	ss:[bx].FPEAD_buffer.segment, ss
		mov	ss:[bx].FPEAD_buffer.offset, sp
		mov	cx, size FileAttrs
		on_stack	cx ax ax ax retf
		push	cs
		call	ax	; call appropriate routine
		pop	cx		; value has been filled in/recover
					;  previous value
		lea	sp, ss:[bx][FSPathExtAttrData]
		on_stack	retf
		.leave
		ret
DOSLinkGetAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the FileAttrs for this link

CALLED BY:	DOSPathErrorCheckLink

PASS:		dosFinalComponent -- link filename
		cx	= FileAttrs to set
		si	= disk on which link resides

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	
	Convert this over to a SetExtAttrs call

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSLinkSetAttrs	proc far
		mov	ax, offset DOSLinkSetExtAttrs
		jmp	linkGetSetAttrCommon
DOSLinkSetAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSLinkGetAllExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return all the attributes in the link

CALLED BY:	DOSPathOpGetAllExtAttrs

PASS:		dosFinalComponent -- link filename

RETURN:		if attrs fetched OK:
			carry clear
			ax - handle of attributes block (fixed)
			cx - # of attributes 
		else
			carry set
			ax - FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dosLinkAttrs	FileExtAttrDesc \
    <FEA_FILE_TYPE,	DOSLAA_header.DLH_type,		size DLH_type>,
    <FEA_FLAGS,		DOSLAA_header.DLH_flags,	size DLH_flags>,
    <FEA_RELEASE,	DOSLAA_header.DLH_release,	size DLH_release>,
    <FEA_PROTOCOL,	DOSLAA_header.DLH_protocol,	size DLH_protocol>,
    <FEA_TOKEN,		DOSLAA_header.DLH_token,	size DLH_token>,
    <FEA_CREATOR,	DOSLAA_header.DLH_creator,	size DLH_creator>,
    <FEA_DESKTOP_INFO,	DOSLAA_header.DLH_desktop,	size DLH_desktop>,
    <FEA_FILE_ATTR,	DOSLAA_header.DLH_fileAttr,	size DLH_fileAttr>,
    <FEA_GEODE_ATTR,	DOSLAA_header.DLH_geodeAttr,	size DLH_geodeAttr>,
    <FEA_TARGET_FILE_ID,DOSLAA_header.DLH_targetFileID,	size DLH_targetFileID>

DOS_LINK_NUM_ATTRS	equ	length dosLinkAttrs

DOSLinkAllAttrs	struct
    DOSLAA_attrs	FileExtAttrDesc	DOS_LINK_NUM_ATTRS dup(<>)
    DOSLAA_header	DOSLinkHeader
DOSLinkAllAttrs	ends

DOSLinkGetAllExtAttrs	proc far
		uses	bx, es, di
		.enter
	;
	; Allocate a buffer to hold all the attributes.
	; 
		mov	ax, size DOSLinkAllAttrs
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jnc	haveBuffer
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

haveBuffer:
	;
	; Copy in the array of attributes to get and set. Since we need the
	; array for setting things anyway, it's easiest just to set it up
	; and use our internal routine to fetch all the attributes, rather
	; than reading the header etc. ourselves.
	; 
		mov	es, ax
		mov	di, offset DOSLAA_attrs
		segmov	ds, cs
		mov	si, offset dosLinkAttrs
		mov	cx, size dosLinkAttrs/2
			CheckHack <(size dosLinkAttrs and 1) eq 0>
		rep	movsw
		
	;
	; Now point all the FEAD_value.segments to the block (the .offsets
	; are set properly in the dosvceaAllAttrs array)
	; 
		mov	di, offset DOSLAA_attrs
		mov	cx, length DOSLAA_attrs
setSegmentLoop:
		mov	es:[di].FEAD_value.segment, es
		add	di, size FileExtAttrDesc
		loop	setSegmentLoop
	;
	; Get 'em
	;
getAttrs::
		push	bx		; attrs handle
		sub	sp, size FSPathExtAttrData
		mov	bx, sp
		mov	ss:[bx].FPEAD_attr, FEA_MULTIPLE
		mov	ss:[bx].FPEAD_buffer.segment, es
		mov	ss:[bx].FPEAD_buffer.offset, offset DOSLAA_attrs
		mov	cx, DOS_LINK_NUM_ATTRS
		call	DOSLinkGetExtAttrs
		mov	bx, sp
		lea	sp, ss:[bx][size FSPathExtAttrData]
		pop	ax		; attrs handle
		mov	cx, DOS_LINK_NUM_ATTRS
		
done:
		.leave
		ret

DOSLinkGetAllExtAttrs	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocFileGetExtAttrData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a FileGetExtAttrData segment and initialize
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
DOSAllocFileGetExtAttrData	proc near
		uses	bx, cx
		.enter
	;
	; Allocate the necessary workspace. We allocate it fixed as we'd
	; otherwise keep it locked for its entire lifetime, so why bother
	; with that?
	; 
		mov	ax, size FileGetExtAttrData
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	error
		mov	ds, ax
		mov	ds:[FGEAD_block], bx
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
		mov	ds:[FGEAD_pathInfo], ax
done:
		.leave
		ret
error:

		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

DOSAllocFileGetExtAttrData	endp


ExtAttrs	ends
