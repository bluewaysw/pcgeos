COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		folderScan.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/16/92   	Initial version.

DESCRIPTION:
	

	$Id: cfolderScan.asm,v 1.2 98/06/03 13:10:22 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderPathCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderProcessFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Additional processing needed by NewDesk:
			- see if any files are open, so we can draw
			  then with diagonal lines

CALLED BY:	FolderScan

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	bx,di

PSEUDO CODE/STRATEGY:	
	Set the FRSF_OPENED bit for any open files

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	7/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderProcessFiles	proc near

fileID		local	dword
diskHandle	local	word
idAttr		local	FileExtAttrDesc
diskAttr	local	FileExtAttrDesc
folderRecord	local	fptr.FolderRecord

	.enter

ForceRef	folderRecord

	;
	; Set up the local variables
	;

	mov	ss:[idAttr].FEAD_attr, FEA_FILE_ID
	mov	ss:[idAttr].FEAD_value.segment, ss
	lea	ax, ss:[fileID]
	mov	ss:[idAttr].FEAD_value.offset, ax
	mov	ss:[idAttr].FEAD_size, size fileID

	mov	ss:[diskAttr].FEAD_attr, FEA_DISK
	mov	ss:[diskAttr].FEAD_value.segment, ss
	lea	ax, ss:[diskHandle]
	mov	ss:[diskAttr].FEAD_value.offset, ax
	mov	ss:[diskAttr].FEAD_size, size fileID

	mov	ax, cs
	mov	bx, offset NDFolderProcessFilesCB
	call	FolderSendToDisplayList

	.leave
	ret
NDFolderProcessFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderProcessFilesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check this file record against open folders
		to see if we should gray it out

CALLED BY:	NDFolderProcessFiles via FolderSendToDisplayList

PASS:		ds:di - FolderRecord
		ss:bp - inherited local vars

RETURN:		carry clear

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
	if OPEN_CLOSE_NOTIFICATION is on (which it isn't), then we
	want to look for ALL open folders, documents, and links to
	applications.  Otherwise, we only care about open folders.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderProcessFilesCB	proc far
		uses	si,bp

		.enter  inherit NDFolderProcessFiles

	;
	; If this is a GEOS file, add 256 to its file size.  How dumb.
	;
		cmp	ds:[di].FR_fileType, GFT_NOT_GEOS_FILE
		je	afterSize
		adddw	ds:[di].FR_size, 256
afterSize:

		mov	ss:[folderRecord].segment, ds
		mov	ss:[folderRecord].offset, di

	;
	; See if subdir
	;

		test	ds:[di].FR_fileAttrs, mask FA_SUBDIR
if OPEN_CLOSE_NOTIFICATION
		jz	notFolder
else
		jz	done
endif
		

	;
	; See if this window is open, by comparing the FolderRecord's
	; file ID against those of the open folders.
	;

		call	FindFolderByFileID
		jc	isOpen
		jmp	done

if OPEN_CLOSE_NOTIFICATION
		
notFolder:

	;
	; Look thru the kernel's open file list to find an open file
	; with this ID
	;

	clr	bx
	mov	di, cs
	mov	si, offset CheckFileListCB
	call	FileForEach
	jnc	done

endif

isOpen:
		
	lds	di, ss:[folderRecord]
	ornf	ds:[di].FR_state, mask FRSF_OPENED
done:
	clc
	.leave
	ret
NDFolderProcessFilesCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFolderByFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's a folder open whose file ID matches the
		one in this folder record, or its target.

CALLED BY:	NDFolderProcessFilesCB

PASS:		ds:di - FolderRecord

RETURN:		carry SET if found, carry clear otherwise

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFolderByFileID	proc near
	uses	di,si,bp
	.enter

	movdw	cxdx, ds:[di].FR_id
	mov	bp, ds:[di].FR_disk
	mov	ax, MSG_FOLDER_CHECK_FILE_ID
	call	FolderEnum

if 0		
; nuked - 3/93

	jc	done

	;
	; Check this folder record's TARGET, if its a link
	;
	test	ds:[di].FR_fileAttrs, mask FA_LINK
	jz	done			; carry clear

	movdw	cxdx, ds:[di].FR_targetFileID
	clr	bp
	mov	ax, MSG_FOLDER_CHECK_FILE_ID
	call	FolderEnum
	jnc	done

	;
	; There was a match, but only with the file ID, not the disk
	; handle.  Get this FolderRecord's target's disk handle, to make
	; absolutely sure.
	;

	segmov	es, ds
	call	FolderGetFolderRecordTargetDisk
	cmc
	jnc	done			; some error -- bail

	mov	bp, bx			; target disk handle
	movdw	bxsi, cxdx		; folder object
	movdw	cxdx, ds:[di].FR_targetFileID
	mov	ax, MSG_FOLDER_CHECK_FILE_ID
	mov	di, mask MF_CALL
	call	ObjMessage		; carry SET or CLEAR,
					; depending on match.
done:
endif
		
	.leave
	ret
FindFolderByFileID	endp

if OPEN_CLOSE_NOTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileListCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine for checking the kernel's file list
		for open files

CALLED BY:	NDFolderProcessFilesCB via FileForEach

PASS:		bx - file handle
		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	es, di, si

PSEUDO CODE/STRATEGY:
	Check for either:
		this file being open
		this file being a LINK to an open file	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileListCB	proc far
	
	uses	bx, ds

	.enter	inherit	NDFolderProcessFiles

	;
	; Fetch the attrs for this file.  If there's an error, just
	; skip it.
	;

	segmov	es, ss
	lea	di, ss:[diskAttr]
	mov	cx, 2
	mov	ax, FEA_MULTIPLE
	call	FileGetHandleExtAttributes
	jc	doneCLC

	;
	; See if the attrs match the folder record
	;

	lds	di, ss:[folderRecord]

	;
	; First see if this file has the same disk handle / attributes
	;

	mov	ax, ds:[di].FR_disk
	cmp	ax, ss:[diskHandle]
	jne	checkLink
	cmpdw	ds:[di].FR_id, ss:[fileID], ax
	stc
	je	done

checkLink:
	test	ds:[di].FR_fileAttrs, mask FA_LINK
	jz	done
	
	;
	; Next, see if the folder record might be a LINK to this file
	;
	cmpdw	ds:[di].FR_targetFileID, ss:[fileID], ax
	clc
	jne	done
	

	;
	; The link is almost certainly a link to this file, but just
	; to be sure, fetch the target disk handle (an expensive
	; operation), and compare it agains the file's
	;
	call	FolderGetFolderRecordTargetDisk
	cmc
	jnc	done			; some error -- bail

	cmp	bx, ss:[diskHandle]
	stc
	je	done
doneCLC:
	clc
done:
	.leave
	ret
CheckFileListCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetFolderRecordTargetDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the disk handle of the target of the link
		pointed to by this folder record

CALLED BY:	CheckFileListCB, FolderCheckIDIsKidsTarget

PASS:		ds:di - FolderRecord of link
		CWD set to folder's dir

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			bx - target disk handle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetFolderRecordTargetDisk	proc near

	uses	ax,cx,dx,si,bp,es

	.enter

EC <	call	ECCheckFolderRecordDSDI		>

	mov	bx, ds:[di].FR_trueDH
	tst	bx
	jnz	done

	push	di			; FolderRecord
	lea	si, ds:[di].FR_name

	call	ShellAllocPathBuffer	; es:di - target
	mov	cx, size PathName
	clr	dx, bx
	call	FileConstructActualPath	; bx, es:di - actual path
	call	ShellFreePathBuffer

	pop	di			; FolderRecord
	jc	done

	;
	; Store the disk handle, in case we ever need it again
	;

	mov	ds:[di].FR_trueDH, bx
done:
	.leave
	ret
FolderGetFolderRecordTargetDisk	endp

endif ;	OPEN_CLOSE_NOTIFICATION

FolderPathCode	ends
