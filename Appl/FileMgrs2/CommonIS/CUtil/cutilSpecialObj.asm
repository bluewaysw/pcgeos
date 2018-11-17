COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonND/CUtil
FILE:		cutilSpecialObj.asm

ROUTINES:
	NewDeskHandleSpecialObjects

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/18/92		Initial version

DESCRIPTION:
	This file contains desktop utility routines that parse out any
	special objects in a FileQuickTransfer block.

	$Id: cutilSpecialObj.asm,v 1.2 98/06/03 13:17:21 joon Exp $

------------------------------------------------------------------------------@

FileOpLow segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewDeskHandleSpecialObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each item of the FileQuickTranfer, pass a pointer to the
		entry to a hook message that Special NewDesk objects (like the
		printer and wastebasket) and BA folderclasses can subclass.
		If this message returns carry set, mark the item and move on.
		After all entries have been processed, go through and compress
		the FileQuickTransfer by deleting the marked entries.

CALLED BY: 	ProcessDragFilesCommon

PASS:		ds - segment of locked down FileQuickTransfer block
		current directory is the destination directory (dest. object)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	(BA only: if chunk array passed in clipboard file, make a copy into
		  a new lmem block.  Else just use the one in dgroup.
		  Free chunk array block when finished.)

	for all entries:
		point registers to file entry
		pass this into the hook message
		if message returns carry set
			mark entry
	compress block by removing marked entries

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	08/18/92	Initial version
	AY	11/22/92	No more IQTF. Handled quick transfer from
				clipboard and folder itself.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskHandleSpecialObjects	proc	near
	uses	ax, bx, cx, dx, bp, si, di, es, ds
	.enter
	;
	; in this loop, dx:bp points to the current entry (has the file name)
	; and dx:00 is the FQTH from which the common path can be obtained.
	; The MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY message is sent to an object
	; of the same type as the destination object.  This is because it is 
	; not worth the time to figure out which instantiated object the
	; destination is and send it to that object, and the object may not
	; even exist, as a quick transfer may have been dropped on a glyph
	; that has not been instantiated.  The current directory is the 
	; destination object's directory.
	;
BA<	call	IclasDeleteSpecialBatchFile	>

	call	NewDeskGetDummyOrRealObject	; ^lbx:si - dummy or
						; folder, carry set if folder
	jc	pathSet				; folders already have a path

	;
	; Stuff the correct path into the dummy
	;
	push	bx, si, ds
	call	ShellAllocPathBuffer	
	segmov	ds, es
	mov	si, di
	mov	cx, size PathName
	call	FileGetCurrentPath
	mov	bp, bx
	mov	cx, ds
	mov	dx, si
	pop	bx, si, ds

	mov	ax, MSG_FOLDER_SET_PATH
	call	ObjMessageCall
	call	ShellFreePathBuffer

pathSet:
if _NEWDESKBA
	;
	; Clear the transferAbortFlag
	;
	segmov	es, dgroup, ax
	clr	es:[transferAbortFlag]
	;
	; if chunk array in VM file, copy it into lmem block
	;
	mov	ax, ds:[FQTH_nextBlock]
	tst	ax
	jz	notInVMFile
	push	bx
	call	ClipboardGetClipboardFile	; rtn bx = file hptr
	call	CopyCArrayFromVMFile		; rtn ^lbx:ax = carray
	movdw	es:[listTransferCArray], bxax
	pop	bx
notInVMFile:
endif ; if _NEWDESKBA

	;
	; Loop through the transfer items
	;
	mov	cx, ds:[FQTH_numFiles]
	mov	bp, offset FQTH_files

	push	cx
	dec	cx
	jcxz	pastFOIELoop
FOIELoop:					; go to the last item and go
	add	bp, size FileOperationInfoEntry	; through the list backwards
	loop	FOIELoop			; so the list item corresponds
pastFOIELoop:					; to cx, which decrements
	pop	cx

checkLoop:
	mov	dx, ds
	push	bp, cx

	mov	ax, MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY
	call	ObjMessageCall

	pop	bp, cx
	jnc	untouchedDoNotMark

	mov	ds:[bp].FOIE_name, 0		; mark by setting name null

untouchedDoNotMark:
	sub	bp, size FileOperationInfoEntry
	loop	checkLoop

if _NEWDESKBA
	; free carray block if list operation, whether it's from clipboard or
	;   elsewhere.
	test	ds:[FQTH_UIFA].low, mask BATT_LIST_OPERATION
	jz	noCArray
	mov	bx, es:listTransferCArray.handle
	call	MemFree
noCArray:
endif ; if _NEWDESKBA

	call	CompressFileQuickTransfer

	cmp	ds:[FQTH_numFiles], 0
	jne	done

	call	InitForWindowUpdate
	call	UpdateMarkedWindows
done:
if _NEWDESKBA
	mov	ax, MSG_BA_APP_RUN_ICLAS_BATCH_FILE_IF_NEEDED
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

;	call	IclasRunSpecialBatchFileIfNeeded
endif	; if _NEWDESKBA
	.leave
	ret
NewDeskHandleSpecialObjects	endp

if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCArrayFromVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a chunk array in a new lmem block from a chunk in VM file.

CALLED BY:	INTERNAL, NewDeskHandleSpecialObjects
PASS:		bx	= VM file handle containing chunk array
		ax	= VM block handle containing chunk array
RETURN:		^lbx:ax	= chunk array (in a new lmem block)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The chunk in VM block should have the following format
		VMChainLink	(not used here)
		word		(size of chunk array)
		chunk		(chunk array itself)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/22/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCArrayFromVMFile	proc	near
	uses	cx,dx,si,di,bp,ds,es
	.enter

	call	VMLock			; rtn bp = hptr, ax = sptr
	mov	es, ax

	; alloc chunk array
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx			; default size
	call	MemAllocLMem		; rtn bx = hptr
	call	MemLock			; rtn ax = sptr
	mov	ds, ax
	clr	al			; no ObjChunkFlags
	mov	cx, es:[size VMChainLink]	; cx = size of carray
	call	LMemAlloc		; rtn *ds:ax = lptr

	; copy chunk into lmem block
	segxchg	es, ds			; es = carray block, ds = VM chunk
	mov	si, size VMChainLink + size word	; ds:si = chunk src
	mov	di, ax
	mov	di, es:[di]		; es:di = chunk dest
	call	FolderCopyMem

	; unlock blocks
	call	MemUnlock		; unlock lmem block
	call	VMUnlock		; unlock VM block

	.leave
	ret
CopyCArrayFromVMFile	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewDeskGetDummyOrRealObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the type of folder object to use, based on this
		thread's current path.  Return the actual object if it exists
		or a dummy if not.

CALLED BY: 	NewDeskHandleSpecialObjects

PASS:		current directory is the destination directory (dest. object)
		ds - locked down FQT

RETURN:		^lbx:si - object of correct type (according to path)
		carry	set if the object is an already opened folder,
			clear if the object is a dummy object

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	08/19/92	Initial version
	dloft	10/7/92		Removed needless and out-of-date EC code
	dlitwin	11/6/92		Made this return the the real object if it
				exists. (no longer defaults to the dummy)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
getDummyDot	TCHAR	".",0

NewDeskGetDummyOrRealObject	proc	near
	uses	cx, dx, bp, di, es
path	local	PathName
	.enter

	;
	; Get the full name of the CWD, so that we can fetch
	; extended attributes from it, etc.
	;

	push	ds				; preserve FQT segment pointer
	segmov	es, ss, si
	lea	di, ss:[path]
	segmov	ds, cs
	mov	si, offset getDummyDot
	mov	cx, size path
	clr	bx, dx
	call	FileConstructFullPath		; bx - disk handle
	pop	ds				; restore FQT segment pointer

	;
	; Find a folder that matches this path
	;

	push	bp				; save local frame pointer
	mov	dx, ss
	lea	bp, ss:[path]
	mov	cx, bx
	mov	di, mask MF_CALL
	call	FindFolderWindow
	call	ShellFreePathBuffer		;  nuke returned path buffer
	mov	si, FOLDER_OBJECT_OFFSET
	pop	bp				; restore local frame pointer
	jnc	getDummy			; if the object exists, use it

	tst	bx
	jz	getDummy
	stc
	jmp	done

getDummy:

	;
	; Otherwise, lookup the dummy for this path type
	;

	push	ds				; preserve FQT segment pointer
	segmov	ds, ss
	lea	si, ss:[path]
	mov	bx, cx				; bx, ds:si is path
	call	GetFolderTypeFromPathName
	pop	ds				; restore FQT segment pointer

	call	UtilGetDummyFromTable
done:
	.leave
	ret
NewDeskGetDummyOrRealObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFolderTypeFromPathName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at a path and returns the NewDeskObjectType that
		corresponds to it.  This routine assumes a generic Folder
		as the default case, so any non-subdir object that has no
		special path will get WOT_FOLDER returned as its type.

CALLED BY:	CreateFolderWindowCommon, 
		NewDeskGetObjectTypeIntoBX,
		GetNewDeskObjectType,	
		NewDeskBAPrepareForRemoval

PASS:		ds:si	- Pathname
		bx	- diskhandle

RETURN:		si = NewDeskObjectType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFolderTypeFromPathName	proc far
	uses	ax, bx,cx,dx,di,es

desktopInfo	local	DesktopInfo

	.enter

	;
	; Assume normal
	;
	mov	ax, WOT_FOLDER
		CheckHack <WOT_FOLDER eq 0>

	;
	; Change to the passed disk handle, so we can access the
	; passed file. 
	;

	call	ShellPushToRoot
	jc	done

	;
	; Get the file's desktop info. 
	;

	lea	di, ss:[desktopInfo]
	segmov	es, ss
	mov	ax, FEA_DESKTOP_INFO
	mov	cx, size desktopInfo
	mov	dx, si
	call	FileGetPathExtAttributes
	mov	ax, WOT_FOLDER
	jc	popDir

	;
	; Extract DI_objectType from desktopInfo, making sure we
	; return a valid value
	;

	mov	ax, ss:[desktopInfo].DI_objectType
	cmp	ax, NewDeskObjectType

NDONLY<	jae	outOfRange						>
NDONLY<	jmp	popDir							>

BA<	jge	outOfRange						>
BA<	cmp	ax, -OFFSET_FOR_WOT_TABLES				>
BA<	jge	popDir							>

outOfRange:
	mov	ax, WOT_FOLDER				; if out of range,

popDir:
	call	FilePopDir

done:
	mov_tr	si, ax
	.leave
	ret
GetFolderTypeFromPathName	endp

FileOpLow	ends
