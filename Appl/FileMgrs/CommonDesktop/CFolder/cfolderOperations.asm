COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderOperations.asm
AUTHOR:		Brian Chin

ROUTINES:
		INT	FolderFileOperation - common code for starting file ops
		INT	SendSelectedFiles - send selected filename(s) to
						file operation dialog box
		EXT	CopyOneSelectedFilename - do one filename for above

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/29/89		broken out from folderClass.asm

DESCRIPTION:
	This file contains support routines for file operations for the
	Folder class.

	$Id: cfolderOperations.asm,v 1.2 98/06/03 13:35:32 joon Exp $

------------------------------------------------------------------------------@

FileOperation segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartFileOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code for starting file operation

CALLED BY:	INTERNAL
			FolderStartRename
			FolderStartDelete
			FolderStartCreateDir
			FolderStartMove
			FolderStartCopy
			FolderStartDuplicate

PASS:		*ds:si - instance handle of Folder object
		ax - local chunk handle of current directory Text object
		bx - local chunk handle of source filename(s)
			file operation Text object
		cx - local chunk handle of dialog box
		dx - local chunk handle of status string
			zero for no status string (GetInfo)

RETURN:		carry set if error
		carry clear otherwise

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartFileOperation	proc	near
GM<	class	FolderClass	>
ND<	class	NDFolderClass	>

	push	ax, bx
	call	Folder_GetDiskAndPath		; ax <- disk handle
	mov_tr	bp, ax
	pop	ax, bx
	;
	; set file operation's dialog box's current pathname
	;
	mov	di, ds:[si]			; deref.
	cmp	ax, offset CreateDirCurDir	; create dir?
	je	11$				; yes, ignore selected files
GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	jne	11$				; yes, do nothing	>
GM<	stc					; assume not		>
GM<	je	exit				; no, quit immediately	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	exit							>
11$:
	push	bp				; save disk handle
	push	cx				; save dialog box handle
	push	dx				; save status string handle
	push	bx				; save source filename(s) handle
	push	ds:[si]				; save instance addr.

	push	ax				; save cur. dir. chunk handle
	call	Folder_GetDiskAndPath
	mov	bp, ax				; bp <- disk handle
	mov	cx, ds
	lea	dx, ds:[bx].GFP_path
	pop	si
	mov	bx, handle FileOperationUI	; ^lbx:si <- cur dir text obj
	mov	ax, MSG_GEN_PATH_SET
	call	ObjMessageCallFixup
	pop	si				; restore instance addr.
	;
	; set selected files in file operation dialog box
	;
	pop	di				; get source filename(s) handle
	tst	di
	jz	noSourceNames
	call	SendSelectedFiles		; show selected files
	jnc	noSourceNames
	add	sp, 6		; <-- CLEAN UP STACK
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	call	DesktopOKError
	stc					; indicate error
	jmp	short exit

noSourceNames:
	;
	; clear status string
	;
	mov	bx, handle FileOperationUI	; bx:si = status strign
	pop	si
	tst	si
	jz	noStatusString
NOFXIP<	mov	dx, cs							>
FXIP  <	push	ds
FXIP  <	GetResourceSegmentNS dgroup, ds					>
FXIP  <	mov	dx, ds							>
FXIP  <	pop	ds							>
	mov	bp, offset nullStatusString
	call	CallSetText
noStatusString:
	;
	; send disk handle to dialog box
	;
	pop	si				; get dialog box handle
	mov	ax, MSG_FOB_SET_DISK_HANDLE
	pop	cx				; cx = disk handle
	call	ObjMessageCall
	;
	; make move dialog box visible, unless it is the GetInfo or the
	; ChangeIconBox, which we put up later
	;
	cmp	si, offset FileOperationUI:GetInfoBox
	je	noBoxYet
	cmp	si, offset FileOperationUI:ChangeIconBox
	je	noBoxYet
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageNone
noBoxYet:
	clc					; indicate no error
exit:
	ret
FolderStartFileOperation	endp

if _FXIP
idata	segment
endif

LocalDefNLString nullStatusString <0>

if _FXIP
idata	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSelectedFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the list of selected files to the passed text object

CALLED BY:	INTERNAL
			FolderStartFileOperation

PASS:		ds:si - instance data of Folder object
		di - lmem handle of file operation text object
			to send filenames to

RETURN:		carry clear if successful
		carry set if memory allocation error

DESTROYED:	

PSEUDO CODE/STRATEGY:
		if (selectList != NULL) {
			MemLock(folder buffer);
			MemAlloc(filename buffer);
			add filename to filename buffer;
			while (selectList != NULL) {
				if (not enough room for filename) {
					MemReAlloc(filename buffer);
				}
				add filename to filename buffer;
			}
			send filename buffer to file op. text object;
			MemFree(filename buffer);
			MemUnlock(tree buffer);
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version
	brianc	1/17/90		support of 8.3 and 32 names

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSelectedFiles	proc	near
	class	FolderClass

GM<	cmp	ds:[si].FOI_selectList, NIL	; (carry cleared by ==	>
GM<	je	SSF_exit			;  comparison)		>

if _NEWDESK
	mov	bx, si							
	call	NDCheckForNoSelection					
	jnc	continue						
	clc					; remove carry flag	
	jmp	SSF_exit			; exit			
continue:								
endif		; if _NEWDESK
	push	di				; save file list object

	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	call	CreateFileListBufferReturnError
	pop	si
	jc	SSF_exit

	;
	; selected filename buffer built out, now send it to file operation
	; file list text object
	;	bx = buffer handle
	;
	mov	dx, bx				; dx = buffer
	mov	ax, MSG_SET_FILE_LIST
	mov	bx, handle FileOperationUI	; bx:si = file op. text object
	call	ObjMessageCall			; send filenames
	clc					; indicate no error

SSF_exit:
	ret
SendSelectedFiles	endp


FileOperation ends



FolderAction	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFolderBufferNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go through folder buffer and copy a FileOperationInfoEntry
		for each selected file

CALLED BY:	INTERNAL
			SendSelectedFiles (for file operation dialog boxes)
				(from diff. resource - FileOperation)
			BuildDragFileList (for direct manipulation)
				(from same resource - FolderCode)

PASS:		ds:bp - first file in select list
			(ds - segment of locked folder buffer)
		es:di - start filling FileOperationInfoEntry's here
		bx - handle of es:di buffer
		dx - size of buffer

RETURN:		carry clear if successful
			cx - number of files
			dx - remote flag
		carry set if MemReAlloc error

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/18/90	broken out for BuildDragFileList
	dlitwin	01/12/93	returns remote flag for new QuickTransfer
				move/copy behavior

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFolderBufferNames	proc	far
	uses	si
	.enter

	clr	cx				; cx = number of files
	clr	si				; si is the remote flag

haveRoom:
	push	si				; save remote flag
	call	CopyOneSelectedFilename		; copy over successive filenames
	pop	si				; restore remote flag
	test	ds:[bp].FR_pathInfo, mask DPI_EXISTS_LOCALLY
	jnz	localFile
	mov	si, -1				; set remote flag
localFile:
	inc	cx				; one more file
	mov	bp, ds:[bp].FR_selectNext	; get next file

	cmp	bp, NIL				; check if any more files
	je	done				; if not, done (carry is clear)
	;
	; check filename buffer size
	;
	cmp	di, dx				; check if room for this name
	jne	haveRoom			; if so, continue
						; else, increase the space
	add	dx, INC_NUM_SELECTED_FILES * size FileOperationInfoEntry
	jc	done				; buffer too large, we're done
	push	cx				; save counter
	mov	ax, dx				; ax = new size
	clr	ch				; no special flags
	call	MemReAlloc			; realloc bx = filename buffer
	mov	es, ax				; in case block moved
	pop	cx				; retrieve counter
	jnc	haveRoom			; if no error, loop

done:
	mov	dx, si				; return remote flag in dx
	.leave
	ret
GetFolderBufferNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyOneSelectedFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the necessary FolderRecord fields into the
		specified FileOperationInfoEntry structure

CALLED BY:	INTERNAL
			GetFolderBufferFileNames

PASS:		ds:bp = FolderRecord (source)
		es:di = FileOperationInfoEntry (destination)

RETURN:		filename added to buffer
		es:di = pointer to next FileOperationInfoEntry

DESTROYED:	si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine is just one big hack!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyOneSelectedFilename	proc	far
	uses	cx
	.enter

        mov	si, bp

	CheckHack <offset FR_name eq offset FOIE_name>
	CheckHack <size FR_name + size FR_fileType + \
			size FR_fileAttrs + size FR_fileFlags + \
			size FR_creator + size FR_desktopInfo + \
			size FR_pathInfo \
				eq size FileOperationInfoEntry>
	CheckHack <offset FR_fileType eq offset FOIE_type>
	CheckHack <offset FR_fileAttrs eq offset FOIE_attrs>
	CheckHack <offset FR_fileFlags eq offset FOIE_flags>
	CheckHack <offset FR_creator eq offset FOIE_creator>
	CheckHack <offset FR_desktopInfo eq offset FOIE_info>
	CheckHack <offset FR_pathInfo eq offset FOIE_pathInfo>


        mov     cx, size FileOperationInfoEntry/2
        rep movsw
if (size FileOperationInfoEntry and 1) eq 1
	movsb
endif

	.leave
	ret
CopyOneSelectedFilename	endp

FolderAction ends
