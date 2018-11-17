COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Pen
MODULE:		File
FILE:		fileAccess.asm

AUTHOR:		Andrew Wilson, Feb  4, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 4/92		Initial revision

DESCRIPTION:
	Contains routines for accessing the common Note DB datafile structure.

	$Id: fileAccess.asm,v 1.1 97/04/05 01:27:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCode	segment	resource

if 	ERROR_CHECK
EnsureIsTextObject	proc	near	uses	ax, cx, dx, bp, di
	.enter
	mov	cx, segment VisTextClass
	mov	dx, offset VisTextClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS	
	mov	di, mask MF_CALL
	call	ObjMessage
EC <	ERROR_NC	OBJECT_DOES_NOT_MATCH_NOTE_TYPE			>
	.leave
	ret
EnsureIsTextObject	endp

EnsureIsInkObject	proc	near	uses	ax, cx, dx, bp, di
	.enter
	mov	cx, segment InkClass
	mov	dx, offset InkClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS	
	mov	di, mask MF_CALL
	call	ObjMessage
EC <	ERROR_NC	OBJECT_DOES_NOT_MATCH_NOTE_TYPE			>
	.leave
	ret
EnsureIsInkObject	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDBInit	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
				
SYNOPSIS:	Inits a new DB file.
				
CALLED BY:	GLOBAL		
PASS:		bx - handle of file
RETURN:		nada		
DESTROYED:	nada		
				
PSEUDO CODE/STRATEGY:		
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:	
				
REVISION HISTORY:		
	Name	Date		Description
	----	----		-----------
	atw	2/ 4/92		Initial version
				
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@;
InkDBInit	proc	far	uses	ax, bx, cx, dx, es, di, ds, si
	.enter			
				
;	Create a root-level folder
				
	push	bx			;save the VM file handle
	mov	bx, handle Strings
	call	MemLock		
	mov	ds, ax		

assume ds:Strings		
	mov	si, ds:[defaultRootTitle]
assume ds:dgroup		

	clrdw	axdi			;No parent
	pop	bx			;bx <- VM file handle
	call	InkFolderCreateSubFolder
	call	InkFolderSetTitle
	pushdw	axdi
	push	bx				
	mov	bx, handle Strings
	call	MemUnlock	
				
;	Create hugearray to hold keywords

	pop	bx			;bx <- VM file handle
	mov	cx, size KeywordInfo
	clr	di		
	call	HugeArrayCreate	
				
	push	di

	mov	ax, DB_UNGROUPED
	mov	cx, size InkDataFileMap
	call	DBAlloc
	call	DBSetMap
	call	DBLockDSSI		;Lock map block
	mov	si, ds:[si]		;ds:si <- ptr to InkDataFileMap

	pop	ds:[si].IDFM_keywords
	popdw	dxax
	movdw	ds:[si].IDFM_headFolder, dxax
	movdw	ds:[si].IDFM_curFolder, dxax
	clr	ax
	clrdw	ds:[si].IDFM_curNote, ax
	mov	ds:[si].IDFM_curPage, ax
	mov	ds:[si].IDFM_gstring, ax
	mov	ds:[si].IDFM_customGstring, ax

	call	DBUnlockDirtyDS

	.leave
	ret
InkDBInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDBGetHeadFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the head folder for the file

CALLED BY:	GLOBAL
PASS:		bx - file handle (or override)
RETURN:		AX.DI - folder handle
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDBGetHeadFolder	proc	far	uses	es
	.enter
	call	DBLockMap
	mov	di, es:[di]
	mov	ax, es:[di].IDFM_headFolder.DBGI_group
	mov	di, es:[di].IDFM_headFolder.DBGI_item
	call	DBUnlock
	.leave
	ret
InkDBGetHeadFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDBGetDisplayInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns current display info

CALLED BY:	GLOBAL
PASS:		bx - file handle (or override)
RETURN:		AX.DI - folder handle
		DX.CX - note
		BP - page
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDBGetDisplayInfo	proc	far	uses	es
	.enter
	call	DBLockMap
	mov	di, es:[di]
	movdw	dxcx, es:[di].IDFM_curNote
	mov	bp, es:[di].IDFM_curPage
	mov	ax, es:[di].IDFM_curFolder.DBGI_group
	mov	di, es:[di].IDFM_curFolder.DBGI_item
	call	DBUnlock
	.leave
	ret
InkDBGetDisplayInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDBSetDisplayInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set current display info

CALLED BY:	GLOBAL
PASS:		bx - file handle (or override)
		AX.DI - folder handle
		DX.CX - note
		BP - page
RETURN:		none
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDBSetDisplayInfo	proc	far	uses	es, di
	.enter
	push	di
	call	DBLockMap
	mov	di, es:[di]
	movdw	es:[di].IDFM_curNote, dxcx
	mov	es:[di].IDFM_curPage, bp
	mov	es:[di].IDFM_curFolder.DBGI_group, ax
	pop	es:[di].IDFM_curFolder.DBGI_item
	call	DBDirty
	call	DBUnlock
	.leave
	ret
InkDBSetDisplayInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetDocPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sets the current page info for the file
CALLED BY:	GLOBAL
PASS:		ds:si - pointer to hold the structure PageSizeReport
		bx - Database file handle
RETURN:		ds:si - PageSizeReport structure
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetDocPageInfo	proc	far	uses	cx,si,di,es
	.enter

	call	DBLockMap
	mov	di, es:[di]
	add	di, offset IDFM_pageSizeReport
	mov	cx, size PageSizeReport
	rep movsb	
	call	DBDirty
	call	DBUnlock

	.leave
	ret
InkSetDocPageInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetDocPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Gets the current page info for the file
CALLED BY:	GLOBAL
PASS:		ds:si - pointer to hold the structure PageSizeReport
		bx - Database file handle
RETURN:		ds:si - PageSizeReport structure
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetDocPageInfo	proc	far	uses	ax,bx,cx,si,di,es
	.enter

	call	DBLockMap
	mov	di, es:[di]
	add	di, offset IDFM_pageSizeReport
	
	;swap es:di and ds:si
	xchg	di, si
	mov	ax, ds
	mov	bx, es
	mov	es, ax
	mov	ds, bx

	;copy pageSizeReport into ds:si
	mov	cx, size PageSizeReport
	rep movsb

	;swap back again
	mov	ax, ds
	mov	bx, es
	mov	es, ax
	mov	ds, bx

	call	DBUnlock

	.leave
	ret
InkGetDocPageInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetDocGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the IDFM_gstring field in the InkDataFileMap structure
CALLED BY:	GLOBAL
PASS:		bx - Database file handle
		ax - GString
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetDocGString	proc	far	uses	es, di
	.enter
	push	ax
	call	DBLockMap
	mov	di, es:[di]
	pop	ax
	mov	es:[di].IDFM_gstring, ax
	call	DBDirty
	call	DBUnlock

	.leave
	ret
InkSetDocGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetDocGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the IDFM_gstring field from the InkDataFileMap structure
CALLED BY:	GLOBAL
PASS:		bx - Database file handle
RETURN:		ax - GString
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetDocGString	proc	far	uses	es, di
	.enter

	call	DBLockMap
	mov	di, es:[di]
	mov	ax, es:[di].IDFM_gstring
	call	DBUnlock

	.leave
	ret
InkGetDocGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetDocCustomGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the IDFM_customGstring field from the InkDataFileMap 
		structure
CALLED BY:	GLOBAL
PASS:		bx - Database file handle
RETURN:		ax - GString

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetDocCustomGString	proc	far	uses	es, di
	.enter
	call	DBLockMap
	mov	di, es:[di]
	mov	ax, es:[di].IDFM_customGstring
	call	DBUnlock
	.leave
	ret
InkGetDocCustomGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetDocCustomGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the IDFM_customGstring field in the InkDataFileMap 
		structure
CALLED BY:	GLOBAL
PASS:		bx - Database file handle
		ax - GString
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetDocCustomGString	proc	far	uses	es, di
	.enter
	push	ax
	call	DBLockMap
	pop	ax
	mov	di, es:[di]
	mov	es:[di].IDFM_customGstring, ax
	call	DBDirty
	call	DBUnlock
	.leave
	ret
InkSetDocCustomGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringFromDBBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a string from a db block to a user-supplied buffer.

CALLED BY:	InkGetTitle
PASS:		di.ax - source DB block
		bx - file handle (or override)
		ds:si - dest to store name in
RETURN:		cx - length of name w/null

DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringFromDBBlock	proc	near	uses si, di, es
	.enter
	call	DBLock
	mov	di, es:[di]
	segxchg	es, ds			;ES:DI <- ptr to dest for string,
	xchg	si, di			;DS:SI <- ptr to src 
	ChunkSizePtr	ds, si, cx
	push	cx
	shr	cx, 1
	jnc	10$
	movsb
10$:
	rep	movsw
	segxchg	es, ds
	call	DBUnlock
	pop	cx
	.leave
	ret
CopyStringFromDBBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSizeDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the length of the string in es:di

CALLED BY:	GLOBAL
PASS:		DS:SI <- null term string
RETURN:		cx - length of string w/null
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringSizeDSSI	proc	near	uses	es, di
	.enter
	segmov	es, ds
	mov	di, si
	call	LocalStringSize
	inc	cx
	.leave
	ret
GetStringSizeDSSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyStringIntoDBBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a null-terminated string into a DBBlock

CALLED BY:	GLOBAL
PASS:		ds:si <- source for string
		di.ax - dest db block
RETURN:		cx - length of string
DESTROYED:	si, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyStringIntoDBBlock	proc	near
	.enter
	call	GetStringSizeDSSI		;CX <- size of new name w/null
	push	cx
	call	DBReAlloc			;Resize name block

	push	es
	call	DBLock				;Lock block containing name,
	call	DBDirty
	mov	di, es:[di]			; and copy new name over
	shr	cx, 1
	jnc	10$
	movsb	
10$:
	rep	movsw
	call	DBUnlock
	pop	es
	pop	cx
	.leave
	ret
CopyStringIntoDBBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderGetContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the item/group of the chunk arrays containing the 
		children of the passed folder.

CALLED BY:	GLOBAL
PASS:		bx - file han
		ax.di - folder tag
RETURN:		DI, AX = item/group of chunk array of sub folders
		CX, DX = item/group of chunk array of notes

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderGetContents	proc	far	uses	si, ds
	.enter
	call	DBLockDSSI
	mov	si, ds:[si]
	movdw	dxcx, ds:[si].FI_notes
	movdw	axdi, ds:[si].FI_subFolders
	call	DBUnlockDS
	.leave
	ret
InkFolderGetContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderGetNumChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns the # children of the passed folder

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		BX - file handle
RETURN:		CX - # sub folders
		DX - # notes
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderGetNumChildren	proc	far	uses	ax, ds, si, di
	.enter
	call	InkFolderGetContents

;	Count # subfolders

	push	cx, dx
	call	DBLockDSSI
	call	ChunkArrayGetCount
	call	DBUnlockDS
	pop	di, ax

	push	cx		;Save # sub folders
	call	DBLockDSSI
	call	ChunkArrayGetCount
	call	DBUnlockDS
	pop	dx		;DX <- # sub folders
	xchg	cx, dx		;DX <- # notes
				;CX <- # sub folders
	.leave
	ret
InkFolderGetNumChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderAddInSortOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Add the passed sub-folder or note into chunk array
		in sorted order
CALLED BY:	FolderAddSubFolder / FolderAddNote
PASS:		BX = file handle or override
		AX.DI = group/item of sub folders
		CX.DX = subfolder to add
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderAddInSortOrder	proc	near	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	DBLockDSSI	
	;find the right place for the item to be inserted
	mov_tr	ax, bx			;AX <- file handle

	mov	bx, cs
	mov	di, offset RemoveAndAddCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;dx:cx -- folder handle
					;destroyed -- bx

	;return from the Callback:
	;bp -- offset of the item in the chunk array		
	;carry -- set to end enumerateion

	jnc	append
	mov	di, bp
	call	ChunkArrayInsertAt	;pass: *ds:si - array
					;ds:di - element to insert before
					;ax - element size to insert 
					;	(if variable)
					;return: ds:di - points to new element
					;	(block may move)
	jmp	done

append:
	call	ChunkArrayAppend
done:
	movdw	ds:[di], dxcx
	call	DBUnlockDS

	.leave
	ret
FolderAddInSortOrder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderAddSubFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a subfolder to the passed folder in sorted order

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		DX.CX - subfolder to add
RETURN:		nada
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version
	JT	3/10/92		Modified to add folders in sorted order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderAddSubFolder	proc	near	uses ax, si, di, es, bp
	.enter

	pushdw	dxcx

	call	InkFolderGetContents
	;RETURN from InkFolderGetContents:
	;DI, AX = item/group of chunk array of sub folders
	;	CX, DX = item/group of chunk array of notes

	popdw	dxcx

	;ADD FOLDER IN  SORTED ORDER HERE
	;Pass into FolderAddInSortOrder
	;BX = file handle or override
	;AX.DI = group/item of sub folders
	;CX.DX = subfolder to add

	call	FolderAddInSortOrder

	.leave
	ret
FolderAddSubFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderAddNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a subfolder to the passed folder

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		DX.CX - note to add
		bx - file handle
RETURN:		nada
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version
	JT	3/10/92		Modified to add notes in sorted order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderAddNote	proc	near	uses ax, si, di, es, bp
	.enter

	pushdw	dxcx				;Save note

	call	InkFolderGetContents		;DX.CX <- chunk array of
						; children

	movdw	axdi, dxcx
	popdw	dxcx				;Restore note

	;ADD NOTE IN  SORTED ORDER HERE
	;Pass into FolderAddInSortOrder
	;BX = file handle or override
	;AX.DI = group/item of notes
	;CX.DX = note to add

	call	FolderAddInSortOrder

	.leave
	ret
FolderAddNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateEmptyDBBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates an empty ungrouped DBBlock.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		dx.ax - db item (dx = item, ax = group)
		ds - pointing to same segment as it was on entry
DESTROYED:     	cx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateEmptyDBBlock	proc	near	uses	si
	.enter
	mov	ax, DB_UNGROUPED
	mov	cx, 1
	call	DBAlloc
	mov	dx, di			;DX.AX <- db item

;	Init the single byte in the DBBlock to 0

	push	ds
	call	DBLockDSSI
	mov	si, ds:[si]
	mov	{byte} ds:[si], 0
	call	DBUnlockDirtyDS
	pop	ds
	.leave
	ret
AllocateEmptyDBBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateDBChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a DBBlock

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		ax.dx - chunk array in DBBlock
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateDBChunkArray	proc	near	uses	bx, si, di
	.enter
	mov	ax, DB_UNGROUPED	;Alloc an empty DBBlock
	mov	cx, 1
	call	DBAlloc

	push	ds:[LMBH_handle]

	pushdw	axdi
	call	DBLockDSSI

;	Create a chunk array in this chunk

	mov	bx, size DBGroupAndItem
	clr	cx
	clr	al
	call	ChunkArrayCreate

	call	DBUnlockDirtyDS
	popdw	axdx
	pop	bx
	call	MemDerefDS

	.leave
	ret
AllocateDBChunkArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderCreateSubFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a folder.

CALLED BY:	GLOBAL
PASS:		AX.DI - dword tag of parent folder (or 0:0 if no parent)
		BX - file handle
RETURN:		AX.DI - new child folder
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderCreateSubFolder	proc	far	uses cx, dx, si, ds
	parent		local	DBGroupAndItem
	newFolder	local	DBGroupAndItem
	.enter
	movdw	parent, axdi
	mov	cx, size FolderInfo
	mov	ax, DB_UNGROUPED
	call	DBAlloc
	movdw	newFolder, axdi

	call	DBLockDSSI		;Lock folder structure

	call	AllocateEmptyDBBlock	;Allocate name block (in dx.ax)
	mov	di, ds:[si]
	movdw	ds:[di].CI_title, axdx

	call	AllocateDBChunkArray	;Return item in ax.dx
	mov	di, ds:[si]
	movdw	ds:[di].FI_notes, axdx

	call	AllocateDBChunkArray
	mov	di, ds:[si]
	movdw	ds:[di].FI_subFolders, axdx

	movdw	ds:[di].CI_parentFolder, parent, ax

	clr	ds:[di].CI_flags

	call	DBUnlockDirtyDS

	tstdw	parent
	jz	noParent

;	Add this new folder to the parent's list of children

	mov	ax, parent.DBGI_group
	mov	di, parent.DBGI_item
	mov	dx, newFolder.DBGI_group
	mov	cx, newFolder.DBGI_item
	call	FolderAddSubFolder
	
noParent:
	
	mov	di, newFolder.DBGI_item
	mov	ax, newFolder.DBGI_group
	.leave
	ret
InkFolderCreateSubFolder	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindDBItemCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback that compares the passed DBItem to the DBItem in the
		chunk array.

CALLED BY:	GLOBAL
PASS:		DX.CX - DBGroupAndItem to compare with (CX = item, DX=group)
		DS:DI - array element
RETURN:		BP = ptr to this item
		carry set if match
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindDBItemCallback	proc	far
	.enter
	mov	bp, di
	cmp	cx, ds:[di].DBGI_item
	jne	noMatch
	cmp	dx, ds:[di].DBGI_group
	stc
	je	exit
noMatch:
	clc
exit:
	.leave
	ret
FindDBItemCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRemoveSubFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a subfolder from the passed folder

CALLED BY:	GLOBAL
PASS:		AX.DI - parent folder
		DX.CX - subfolder to remove
RETURN:		nada
DESTROYED:	ax, cx, dx, di, si, es, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRemoveSubFolder	proc	near
	push	cx, dx
	call	InkFolderGetContents
	pop	cx, dx

	GOTO	FindAndRemoveDBChunkArrayItem

FolderRemoveSubFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRemoveNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a subfolder from the passed folder

CALLED BY:	GLOBAL
PASS:		AX.DI - parent folder
		DX.CX - subfolder to remove
RETURN:		nada
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRemoveNote	proc	near	uses ax, cx, di
	.enter

	push	cx, dx
	call	InkFolderGetContents
	movdw	axdi, dxcx
	pop	cx, dx

	call	FindAndRemoveDBChunkArrayItem
	.leave
	ret

FolderRemoveNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAndRemoveDBChunkArrayItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the passed dword in the passed chunk array and deletes it

CALLED BY:	GLOBAL
PASS:		di.ax - DB Chunk Array
		cx.dx - item to find
RETURN:		cx - # items left 
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindAndRemoveDBChunkArrayItem	proc	near	uses	bp, bx, si, di, ds
	.enter

;	Scan through all folders in the chunk array and delete the one we want.

	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset FindDBItemCallback
	call	ChunkArrayEnum
EC <	ERROR_NC	DB_ITEM_NOT_FOUND				>
	mov	di, bp
	call	ChunkArrayDelete
	call	ChunkArrayGetCount
	call	DBUnlockDS
	.leave
	ret
FindAndRemoveDBChunkArrayItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves a folder from one 

CALLED BY:	GLOBAL
PASS:		di.ax - folder to move
		cx.dx - new parent folder
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderMove	proc	far	uses	ax, cx, dx, di, si, ds, bp
	subFolder	local	dword
	.enter
	movdw	subFolder, axdi
	call	DBLockDSSI
	mov	si, ds:[si]
	movdw	axdi, dxcx
	xchg	ax, ds:[si].CI_parentFolder.DBGI_group
	xchg	di, ds:[si].CI_parentFolder.DBGI_item
	call	DBUnlockDirtyDS
	cmpdw	axdi, dxcx		;If new parent is the same as the
	je	exit			; old parent, branch

;	Remove the folder from the old parent (if any)

	tstdw	axdi
	jz	noParent
	push	cx, dx
	movdw	dxcx, subFolder
	call	FolderRemoveSubFolder	
	pop	cx, dx
noParent:

;	Add the folder to the new parent (if any)

	tstdw	cxdx
	jz	exit
	movdw	axdi, subFolder
	xchgdw	dxcx, axdi		;AX.DI <- new parent folder
					;DX.CX <- subfolder
	call	FolderAddSubFolder
exit:
	.leave
	ret
InkFolderMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteDeleteCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine deletes the passed note.

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to DBGroupAndItem structure of note
		ax - db file handle
RETURN:		carry clear
DESTROYED:	ax, di, bx, es
 
PSEUDO CODE/STRATEGY:
	We don't need to have the parent folder get updated, as we are in
	the midst of deleting it, so we clear out the parent folder field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteDeleteCallback	proc	far
	.enter
	mov_tr	bx, ax
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	push	di, ax
	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	clrdw	es:[di].CI_parentFolder
	call	DBUnlock
	pop	di, ax
	call	InkNoteDelete
	mov_tr	ax, bx
	clc
	.leave
	ret
InkNoteDeleteCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This callback routine deletes the passed folder

CALLED BY:	InkFolderDepthFirstTraverse
PASS:		AX.DI - folder to delete
RETURN:		carry clear (continue traversal)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDelete	proc	far	uses si, ds
	.enter
	push	di, ax, bx
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].FI_notes.DBGI_group
	mov	di, es:[di].FI_notes.DBGI_item
	call	DBUnlock

;	Delete all the notes

	call	DBLockDSSI

	mov	ax, bx			;AX <- file handle
	mov	bx, cs
	mov	di, offset InkNoteDeleteCallback ;Delete all the notes
	call	ChunkArrayEnum

	call	DBUnlockDS
	pop	di, ax, bx

;	Free up all the chunkarrays/info for the folder

	push	di, ax
	call	DBLockDSSI
	mov	si, ds:[si]		;DS:SI <- FolderInfo

	mov	di, ds:[si].FI_subFolders.DBGI_item
	mov	ax, ds:[si].FI_subFolders.DBGI_group
	call	DBFree

	mov	di, ds:[si].CI_title.DBGI_item
	mov	ax, ds:[si].CI_title.DBGI_group
	call	DBFree

	mov	di, ds:[si].FI_notes.DBGI_item
	mov	ax, ds:[si].FI_notes.DBGI_group
	call	DBFree

	call	DBUnlockDS

	pop	di, ax
	call	DBFree			;Free up the folder
	.leave
	ret
FolderDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a folder. If there are children, it does a recursive
		delete.

CALLED BY:	GLOBAL
PASS:		AX.DI - folder to delete
		BX - file handle (unless override)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	First, we remove this folder from its parent.
	Then, we do a depth first traversal of the tree, and for each
		folder, we delete all of its notes, then free the folder
		itself and all of its associated DB items.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderDelete	proc	far	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

;	Remove this folder from the parent

	push	di, ax
	movdw	dxcx, axdi
	call	DBLock
	mov	di, es:[di] 
	mov	ax, es:[di].CI_parentFolder.DBGI_group
	mov	di, es:[di].CI_parentFolder.DBGI_item
	call	DBUnlock
	tstdw	axdi
	jz	noRemove
	call	FolderRemoveSubFolder
noRemove:
	pop	di, ax

;	Now, delete all the folders

	mov	cx, cs
	mov	dx, offset FolderDelete
	call	InkFolderDepthFirstTraverse
	.leave
	ret
InkFolderDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DepthFirstChunkArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes params from ChunkArrayEnum and translates them into 
		the params for DepthFirstTraverseLow.

CALLED BY:	GLOBAL
PASS:		DS:DI <- ptr to DBGroupAndItem of folder
		CX.DX <- callback routine
		BP <- extra data
		AX <- file handle
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DepthFirstChunkArrayCallback	proc	far 	uses	ax
	.enter
	mov_tr	bx, ax
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	push	ds:[LMBH_handle]
	call	DepthFirstTraverseLow
	pop	bx
	call	MemDerefDS	
	.leave
	ret
DepthFirstChunkArrayCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DepthFirstTraverseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traverses the folder tree 

CALLED BY:	GLOBAL
PASS:		AX.DI - folder at top of tree
		BX - file handle
		CX:DX - far ptr to callback routine
		BP - extra data to pass to callback routine
RETURN:		nada
DESTROYED:	es, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DepthFirstTraverseLow	proc	far	uses	ax, bx, bp, di, si
	.enter

	push	di, ax			;Save this folder
	call	DBLock
	mov	di, es:[di]		;ES:DI <- ptr to FolderInfo struct
	mov	ax, es:[di].FI_subFolders.DBGI_group
	mov	di, es:[di].FI_subFolders.DBGI_item
	call	DBUnlock

;       Call DepthFirstTraverseLow on all of the subfolders...

	call	DBLock
	segxchg	ds, es
	mov	si, di

	mov_tr	ax, bx			;AX <- file handle
	mov	bx, cs
	mov	di, offset DepthFirstChunkArrayCallback
	call	ChunkArrayEnum
	segxchg	es, ds

	call	DBUnlock		;Maintains flags

	mov_tr	bx, ax			;BX <- file handle
	pop	di, ax			;Restore this folder
	jc	aborted			;If the user aborted, branch

	pushdw	cxdx
	mov	si, sp
	call	{fptr} ss:[si]		;Call the callback routine
	popdw	cxdx
aborted:
	.leave
	ret
DepthFirstTraverseLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderDepthFirstTraverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traverses the folder tree in a depth-first manner.

CALLED BY:	GLOBAL
PASS:		AX.DI - folder at top of tree
		BX - file handle
		CX:DX - far ptr to callback routine
		BP - extra data to pass to callback routine
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderDepthFirstTraverse	proc	far	uses	es, ds
	.enter
	call	DepthFirstTraverseLow
	.leave
	ret
InkFolderDepthFirstTraverse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new note

CALLED BY:	GLOBAL
PASS:		AX.DI = dword tag of parent folder
		BX - file or set override
RETURN:		di.ax - new note
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteCreate	proc	far	uses	cx, dx, si, ds
	newNote	local	DBGroupAndItem
	.enter
	pushdw	axdi
	mov	cx, size NoteInfo
	mov	ax, DB_UNGROUPED
	call	DBAlloc
	movdw	newNote, axdi
	call	DBLockDSSI

	mov	di, ds:[si]
	popdw	ds:[di].CI_parentFolder

	call	AllocateEmptyDBBlock
	mov	di, ds:[si]
	movdw	ds:[di].CI_title, axdx

	call	AllocateEmptyDBBlock
	mov	di, ds:[si]
	movdw	ds:[di].NI_keywordItem, axdx
	clr	ax
	mov	ds:[di].CI_flags, ax
	clrdw	ds:[di].NI_extraData, ax

	call	AllocateDBChunkArray
	mov	di, ds:[si]
	movdw	ds:[di].NI_pageArray, axdx

	push	bx
	call	TimerGetDateAndTime
	movdw	ds:[di].NI_creationDate, axbx
	movdw	ds:[di].NI_modDate, axbx
	pop	bx

	clr	ds:[di].NI_typeNote

	mov	ax, ds:[di].CI_parentFolder.DBGI_group
	mov	di, ds:[di].CI_parentFolder.DBGI_item
	call	DBUnlockDirtyDS

	movdw	dxcx, newNote

	call	FolderAddNote

	movdw	axdi, dxcx
	.leave
	ret
InkNoteCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the pages from the passed note

CALLED BY:	GLOBAL
PASS:		AX.DI - note
		bx - file han (or override)
RETURN:		AX.DI - cDB item containing chunk array of pages
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetPages	proc	far	uses si, ds
	.enter
	call	DBLockDSSI
	mov	si, ds:[si]
	movdw	axdi, ds:[si].NI_pageArray
	call	DBUnlockDS
	.leave
	ret
InkNoteGetPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetNumPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get total number of pages in a note
CALLED BY:	GLOBAL
PASS:		AX.DI - DB item containing chunk array of pages
RETURN:		cx = total number of pages in a note
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetNumPages	proc	far	uses	ds,si
	.enter
	call	DBLockDSSI

	call	ChunkArrayGetCount	; pass: *ds:si -- array
					; return cx -- number of elements
	call	DBUnlockDS

	.leave
	ret
InkNoteGetNumPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteCreatePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new page in a note

CALLED BY:	GLOBAL
PASS:		AX.DI - note
		bx - file han (or override)
		cx - page number insert before (-1 to append)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteCreatePage	proc	far	uses ax, si, di, ds
	.enter

	call	InkNoteGetPages
	call	DBLockDSSI

	mov	ax, cx
	cmp	ax, CA_NULL_ELEMENT
	jz	append
	call	ChunkArrayElementToPtr
	call	ChunkArrayInsertAt
	jmp	common
append:
	call	ChunkArrayAppend
common:
	clr	ax
	clrdw	ds:[di], ax

	call	DBUnlockDirtyDS

	.leave
	ret
InkNoteCreatePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLoadSavePageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	InkNoteLoadPage / InkNoteSavePage
PASS:		SI = message
		AX.DI = note
		BX - file han (or override)
		CX = page number to load/save	
		DX:BP = ink object optr
RETURN:		DX = group, CX = item
DESTROYED:	ax,di,si,bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	???	2/6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkLoadSavePageCommon	proc	near
	params	local	InkDBFrame
	.enter

	push	ds:[LMBH_handle]

	push	si
	mov	params.IDBF_VMFile, bx
	mov	params.IDBF_DBExtra, 0
	mov	params.IDBF_bounds.R_left, 0
	mov	params.IDBF_bounds.R_top, 0
	mov	params.IDBF_bounds.R_right, 0xffff
	mov	params.IDBF_bounds.R_bottom, 0xffff

	call	InkNoteGetPages
	call	DBLockDSSI

	mov	ax, cx
	call	ChunkArrayElementToPtr
EC <	ERROR_C	BAD_PAGE_NUMBER						>
	movdw	params.IDBF_DBGroupAndItem, ds:[di], ax
	call	DBUnlockDS

	mov	bx, dx
	pop	ax
	mov	si, ss:[bp]

	push	bp
	lea	bp, params
EC <	call	EnsureIsInkObject				>
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	dxcx, axbp
	pop	bp
	pop	bx
	call	MemDerefDS

	.leave
	ret
InkLoadSavePageCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextLoadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	InkNoteLoadPage / InkNoteSavePage
PASS:		
		AX.DI = note
		BX - file han (or override)
		CX = page number to load/save	
		DX:BP = text object optr
RETURN:		DX = group, CX = item
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextLoadPage	proc	near	uses	ax,di,bx,bp
	.enter

	push	ds:[LMBH_handle]

	push	bx			;BX - file handle

;	Get the array of page information for the passed note.
	call	InkNoteGetPages		;ax.di - DB item containing
					;chunk array of pages

;	Get the DBGroup and Item associated with the desired page out of the
;	page array.

	call	DBLockDSSI		;*ds:si - array
	mov	ax, cx			;ax - element number to find
	call	ChunkArrayElementToPtr	;ds:di - element
EC <	ERROR_C	BAD_PAGE_NUMBER						>
	mov	ax, ds:[di].DBGI_group	;ax.di - group and item
	mov	di, ds:[di].DBGI_item
	call	DBUnlockDS

	movdw	bxsi, dxbp		;bx:si - optr of the text object

	tstdw	axdi
	jnz	nonBlankPage

	;if a page of 0:0, delete all the text in the text object
EC <	call	EnsureIsTextObject				>
	pushdw	axdi
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjMessage
	popdw	axdi
	pop	dx
	movdw	bpcx, axdi		;bp:cx - group:item
	jmp	done

nonBlankPage:
;	Tell the object to load from/save to the desired db item.
	pop	dx			;dx - file handle
	movdw	bpcx, axdi		;bp:cx - group:item

	mov	ax, MSG_VIS_INVALIDATE
	clr	di
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_DB_ITEM
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	mov	dx, bp			;dx:cx - group:item
	pop	bx
	call	MemDerefDS

	.leave
	ret
TextLoadPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSavePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	InkNoteSavePage
PASS:		
		AX.DI = note
		BX - file han (or override)
		CX = page number to load/save	
		DX:BP = text object optr
RETURN:		DX = group, CX = item
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSavePage	proc	near	uses	ax,di,bx,bp
	.enter

	push	ds:[LMBH_handle]

	push	bx			;BX - file handle

;	Get the array of page information for the passed note.
	call	InkNoteGetPages		;ax.di - DB item containing
					;chunk array of pages

;	Get the DBGroup and Item associated with the desired page out of the
;	page array.
	call	DBLockDSSI		;*ds:si - array
	mov	ax, cx			;ax - element number to find
	call	ChunkArrayElementToPtr	;ds:di - element
EC <	ERROR_C	BAD_PAGE_NUMBER						>
	mov	ax, ds:[di].DBGI_group	;ax.di - group and item
	mov	di, ds:[di].DBGI_item
	call	DBUnlockDS

	movdw	bxsi, dxbp		;bx:si - optr of the text object

	clr	cx			;assume it is the first item
	mov	bp, DB_UNGROUPED	
	
	tstdw	axdi
	jz	common

	movdw	bpcx, axdi		;bp:cx - group:item

common:
;	Tell the object to load from/save to the desired db item.
	pop	dx			;dx - file handle

EC <	call	EnsureIsTextObject					>
	mov	ax, MSG_VIS_TEXT_GET_ALL_DB_ITEM
	mov	di, mask MF_CALL
	call	ObjMessage		;bp:cx - group:item

	pushdw	bpcx
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	clr	di
	call	ObjMessage
	popdw	dxcx			;dx:cx - group:item

	pop	bx
	call	MemDerefDS

	.leave
	ret
TextSavePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteLoadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an ink object or text object from a page of a note

CALLED BY:	GLOBAL
PASS:		AX.DI - note
		bx - file han (or override)
		cx - page number
		dx:bp = ink object or text object optr
		si - note type (0: ink, 2: text)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version
	JT	5/12/92		Modified to load text object

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteLoadPage	proc	far	uses ax, bx, cx, dx, si, di, bp	
	.enter

EC <	cmp	si, NoteType					>
EC <	ERROR_AE	BAD_NOTE_TYPE				>
	tst	si
	jz	loadInkNote

	push	dx
	call	TextLoadPage			;DX = group, CX = item
	pop	bx
	jmp	done

loadInkNote:
	mov	si, MSG_INK_LOAD_FROM_DB_ITEM
	call	InkLoadSavePageCommon
done:
	.leave
	ret
InkNoteLoadPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSavePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save ink object or text object from a page of a note

CALLED BY:	GLOBAL
PASS:		AX.DI - note
		bx - file han (or override)
		cx - page number
		dx:bp = ink object or text object optr
		si - note type (0: ink, 2: text)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version
	JT	5/13/92		Modified to save text object

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSavePage	proc	far	uses ax, bx, cx, dx, si, di, bp,ds
	.enter

EC <	cmp	si, NoteType						>
EC <	ERROR_AE	BAD_NOTE_TYPE					>

	push	cx				;cx - page number

	tst	si
	jz	saveInkNote

	push	ax, bx, di
	call	TextSavePage			;dx - group, cx - db item
	pop	ax, bx, di
	jmp	common

saveInkNote:
	push	ax, bx, di
	mov	si, MSG_INK_SAVE_TO_DB_ITEM
	call	InkLoadSavePageCommon		;DX - group, CX - item
	pop	ax, bx, di

common:
	call	InkNoteGetPages
	call	DBLockDSSI

	pop	ax				;ax - page number
	call	ChunkArrayElementToPtr
EC <	ERROR_C	BAD_PAGE_NUMBER					>
	cmpdw	dxcx, ds:[di]
	jz	noChange
	movdw	ds:[di], dxcx
	call	DBDirtyDS
noChange:
	call	DBUnlockDS

	.leave
	ret
InkNoteSavePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveAndAddCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Determines the correct place in the array to store the note/folder.
CALLED BY:	
PASS:	
		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
		dx:cx -- note or folder handle
		ax -- file handle
RETURN:		
		bp -- offset of the item in the chunk array		
		carry -- set to end enumerateion
		ax, cx, dx, bp, es -- data to pass to next

DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveAndAddCallBack	proc	far	uses	ax,cx,dx,ds
	.enter
	mov_tr	bx, ax			;BX <- file handle

	;get the title of the source string

	mov	bp, di

	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item

	call	ChildGetTitleBlock

	call	DBLockDSSI		;ds:*si = ptr to source title string
	mov	si, ds:[si]

	movdw	axdi, dxcx
	;get the title of the dest string

	call	ChildGetTitleBlock

	call	DBLock			;es:*di = ptr to dest title string
	mov	di, es:[di]		;es:di = ptr to dest title string

	clr	cx
	call	LocalCmpStringsNoCase	;ds:si - ptr to source string
					;	 - title of the note/folder
					;es:di - ptr to dest string
					;	 - new title
	cmc

	call	DBUnlock
	call	DBUnlockDS

	.leave
	ret
RemoveAndAddCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveAndAddNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the note from its parent and re-adds it in the 
		correctly sorted place

CALLED BY:	GLOBAL
PASS:		ax.di - note
RETURN:		nada
DESTROYED:	ax, cx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveAndAddNote	proc	near	uses	dx, ds
	.enter

;	First, remove the note from the parent folder

	movdw	dxcx, axdi
	call	InkGetParentFolder
	call	FolderRemoveNote
	call	FolderAddNote

	.leave
	ret
RemoveAndAddNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveAndAddFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the note from its parent and re-adds it in the 
		correctly sorted place

CALLED BY:	GLOBAL
PASS:		ax.di - note
RETURN:		nada
DESTROYED:	ax, cx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveAndAddFolder	proc	near		uses	dx, di, ds
	.enter

;	First, remove the folder from its parent folder

	movdw	dxcx, axdi
	call	InkGetParentFolder

	tstdw	axdi			;If it is the root folder, skip the
	jz	exit			; tedium.
	pushdw	dxcx			;Save folder handle
	pushdw	axdi
	call	FolderRemoveSubFolder
	popdw	axdi
	popdw	dxcx			;Restore folder handle

	call	FolderAddSubFolder
exit:
	.leave
	ret
RemoveAndAddFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChildGetTitleBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the title db group/item from the passed folder or note

CALLED BY:	GLOBAL
PASS:		ax.di - folder or note
		bx - file handle
RETURN:		ax.di - title
DESTROYED:	es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChildGetTitleBlock	proc	near
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].CI_title.DBGI_group
	mov	di, es:[di].CI_title.DBGI_item
	call	DBUnlock
	ret
ChildGetTitleBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTitleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title of the passed folder or note.

CALLED BY:	GLOBAL
PASS:		ax.di - note/foldedr
		bx - file handle
		ds:si - string
RETURN:		cx, si, es
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTitleCommon	proc	near	uses	ax, di
	.enter
	call	ChildGetTitleBlock
	call	CopyStringIntoDBBlock
	.leave
	ret
SetTitleCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTitleFromTextObjectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title of the passed folder or note.

CALLED BY:	GLOBAL
PASS:		ax.di - note/foldedr
		bx - file handle
		ds:si - string
RETURN:		cx, si, es
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTitleFromTextObjectCommon	proc	near	uses	ax, di
	.enter
	call	ChildGetTitleBlock
	call	CopyTextObjectIntoDBBlock
	.leave
	ret
SetTitleFromTextObjectCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title for the passed note...

CALLED BY:	GLOBAL
PASS:		AX.DI - ink note
		bx - file handle or not
		DS:SI - null term string
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetTitle	proc	far	uses	cx, si, es
	.enter
	call	SetTitleCommon
	call	RemoveAndAddNote
	.leave
	ret
InkNoteSetTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderSetTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title for the passed folder...

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		bx - file handle or not
		DS:SI - null term string
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderSetTitle	proc	far	uses	ax, cx, si, es
	.enter
	call	SetTitleCommon
	call	RemoveAndAddFolder
	.leave
	ret
InkFolderSetTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetTitleFromTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title for the passed note...

CALLED BY:	GLOBAL
PASS:		AX.DI - dword handle of folder or note
		BX - file handle or set override
		CX:DX - text object to get title from
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetTitleFromTextObject	proc	far	uses	ax, cx, si, di, es
	.enter
	call	SetTitleFromTextObjectCommon
	call	RemoveAndAddNote
	.leave
	ret
InkNoteSetTitleFromTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderSetTitleFromTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the title for the passed note...

CALLED BY:	GLOBAL
PASS:		AX.DI - ink note
		bx - file handle or not
		DS:SI - null term string
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderSetTitleFromTextObject	proc	far	uses	ax, cx, si, di, es
	.enter
	call	SetTitleFromTextObjectCommon
	call	RemoveAndAddFolder
	.leave
	ret
InkFolderSetTitleFromTextObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the title from the passed note

CALLED BY:	GLOBAL
PASS:		di.ax - note
		bx - file handle or set override
		ds:si - dest for string
RETURN:		cx - length of name w/null
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version
	JT	7/ 6/92		Modified to copy Untitled string
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetTitle	proc	far	uses	ax, es, di, si
	.enter
	call	ChildGetTitleBlock
	call	CopyStringFromDBBlock

	cmp	{char} ds:[si], 0
	jnz	done

	mov	bx, handle Strings
	call	MemLock
	mov	es, ax
	mov	di, offset NoTitleString
	mov	di, es:[di]
	call	MemUnlock
	segxchg	es, ds			;ES:DI <- ptr to dest for string,
	xchg	si, di			;DS:SI <- ptr to src 
	ChunkSizePtr	ds, si, cx
	rep	movsb
	segxchg	es, ds

done:
	.leave
	ret
InkGetTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetParentFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the title from the passed note

CALLED BY:	GLOBAL
PASS:		di.ax - note/folder
		bx - file handle or set override
RETURN:		di.ax - parent folder
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetParentFolder	proc	far	uses	es
	.enter
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].CI_parentFolder.DBGI_group
	mov	di, es:[di].CI_parentFolder.DBGI_item
	call	DBUnlock
	.leave
	ret
InkGetParentFolder	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDBBlockToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the text of the passed DBBlock to the passed text object

CALLED BY:	GLOBAL
PASS:		di.ax - db block
		bx - file handle or set override
		CX:DX - optr of text
		si - offset of chunk if no text (in Strings resource)
RETURN:		nada
DESTROYED:	ax, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDBBlockToTextObject	proc	near		uses	bx, cx, dx, bp, si, ds
	.enter


	push	si

	call	DBLockDSSI		;*ds:si = text
	push	ds:[si]

	movdw	bxsi, cxdx		;bxsi = text object

	pop	di
	cmp	{char} ds:[di], 0
	jz	noText

	pop	cx
	clr	cx
	movdw	dxbp, dsdi
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL 
	call	ObjMessage
	jmp	common

noText:
	pop	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	dx, handle Strings
	clr	cx				;null terminated
	mov	di, mask MF_CALL
	call	ObjMessage

common:
	call	DBUnlockDS

	.leave
	ret
SendDBBlockToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextObjectIntoDBBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies text from the text object into the DBBlock

CALLED BY:	GLOBAL
PASS:		di.ax - db block
		bx - file
		cx:dx - text object
RETURN:		nada
DESTROYED:	di, ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyTextObjectIntoDBBlock	proc	near	uses	bx, cx, dx, bp, si
	.enter
	mov	si, dx
	mov	dx, bx				;DX <- DB file handle
	mov	bx, cx				;^lBX:SI - ptr to text object
	mov_tr	bp, ax
	mov	cx, di
	mov	ax, MSG_VIS_TEXT_GET_ALL_DB_ITEM
	mov	di, mask MF_CALL 
	call	ObjMessage

	.leave
	ret
CopyTextObjectIntoDBBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSendTitleToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the title to the text object.

CALLED BY:	GLOBAL
PASS:		AX.DI - folder/note tag
		bx - override file
		CX:DX <- optr of text object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSendTitleToTextObject	proc	far	uses	ax, ds, di, si
	.enter
	call	DBLockDSSI
	mov	si, ds:[si]
	movdw	axdi, ds:[si].CI_title
	call	DBUnlockDS

	mov	si, offset NoTitleDisplayString
	call	SendDBBlockToTextObject
	.leave
	ret
InkSendTitleToTextObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hash the passed string.

CALLED BY:	GLOBAL
PASS:		DS:SI <- ptr to null-terminated string to hash
RETURN:		cx - hash value
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashString	proc	near	uses	si
	.enter
	clr	cx
	mov	ah, cl
next:
	lodsb
	tst	al			;Funky hash function. This was chosen
	jz	exit			; pretty much off-the-cuff.
	xor	ch, ah
	clr	ah
	call	LocalDowncaseChar
	xor	cl, al
	rol	cx, 1
	mov	ah, al
	jmp	next
exit:
	.leave
	ret
HashString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeywordFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the passed keyword (or returns carry set if not found).

CALLED BY:	GLOBAL
PASS:		DS:SI <- null terminated keyword string
		BX - file handle (or set override)
RETURN:		carry set if not found
		DX.AX - index of KeywordInfo struct in HugeArray
		DI - HugeArray VM block
		
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeywordFind	proc	near	uses	es, ds, si, cx
	curIndex	local	dword
	hashVal		local	word
	strPtr		local	fptr.char
	.enter
	movdw	strPtr, dssi
	call	HashString		;CX <- hash value for the string
	mov	hashVal, cx
	call	DBLockMap
EC <	tst	di							>
EC <	ERROR_Z	NO_MAP_BLOCK						>
	mov	di, es:[di]
	mov	di, es:[di].IDFM_keywords	;
	call	DBUnlock

	call	HugeArrayGetCount
	subdw	dxax, 1
	jc	exit

	movdw	curIndex, dxax

;	Step through the huge array from the end and check each item

lockPrevBlock:
	call	HugeArrayLock		;CX <- # items before (and including)
					; this one
	mov	ax, hashVal
loopTop:
	cmp	ax, ds:[si].KI_hashValue
	jne	next

;	See if the passed string matches this string...

	push	es, di, ds, si, cx
	mov	di, ds:[si].KI_keyword.DBGI_item
	mov	ax, ds:[si].KI_keyword.DBGI_group
	call	DBLock
	mov	di, es:[di]		;ES:DI <- keyword from data file
	lds	si, strPtr		;DS:SI <- this keyword
	clr	cx
	call	LocalCmpStringsNoCase
	call	DBUnlock		;Flags not affected
	pop	es, di, ds, si, cx
	jz	foundCleanup
	mov	ax, hashVal
next:
	sub	si, size KeywordInfo
	subdw	curIndex, 1
	jc	unlockExit
	loop	loopTop
	call	HugeArrayUnlock
	movdw	dxax, curIndex
	jmp	lockPrevBlock
foundCleanup:
	movdw	dxax, curIndex
	clc
unlockExit:
	call	HugeArrayUnlock
exit:
	.leave
	ret
KeywordFind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveNoteFromKeywords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the passed note from the keywords list

CALLED BY:	GLOBAL
PASS:		di.ax - note
		ds:si - keyword string
		bx - file handle (or override set)
		
RETURN:		carry clear
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveNoteFromKeywords	proc	far	uses	ax, bx, ds, di
	noteToRemove	local	dword
	.enter
	movdw	noteToRemove, axdi

	call	KeywordFind		;Returns DX.AX as dword index of
					; KeywordInfo structure, 
					;DI = huge array handle 
	jc	exit			;If it was already deleted, skip 

	push	dx, ax, di

	call	HugeArrayLock
	mov	di, ds:[si].KI_references.DBGI_item
	mov	ax, ds:[si].KI_references.DBGI_group
	call	HugeArrayUnlock
	movdw	dxcx, noteToRemove	
	call	FindAndRemoveDBChunkArrayItem
	pop	dx, ax, di
	jcxz	doDelete		;If no more notes with this keyword, 
					; branch to delete the keyword
exit:
	clc
	.leave
	ret
doDelete:
	mov	cx, 1
	call	HugeArrayDelete
	jmp	exit	
RemoveNoteFromKeywords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateKeywordInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a KeywordInfo structure in the passed huge array.

CALLED BY:	GLOBAL
PASS:		DI - huge array handle
		bx - file handle (or override set)
		DS:SI <- keyword to create entry for
RETURN:		dx.ax - new huge array element number
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateKeywordInfo	proc	near		uses	bx, si
	newKeyword	local	KeywordInfo
	.enter
	push	bp
	push	di
	call	HashString
	mov	newKeyword.KI_hashValue, cx

	call	AllocateEmptyDBBlock
	mov	newKeyword.KI_keyword.DBGI_item, dx
	mov	newKeyword.KI_keyword.DBGI_group, ax
	mov	di, dx
	call	CopyStringIntoDBBlock

	call	AllocateDBChunkArray
	mov	newKeyword.KI_references.DBGI_item, dx
	mov	newKeyword.KI_references.DBGI_group, ax

	clr	newKeyword.KI_flags

	pop	di
	lea	si, newKeyword		;BP:SI <- ptr to new element
	mov	bp, ss
	mov	cx, 1			;
	call	HugeArrayAppend
	pop	bp
	.leave
	ret
CreateKeywordInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNoteToKeywords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed note from the keywords list

CALLED BY:	GLOBAL
PASS:		di.ax - note
		ds:si - keyword string
		bx - file handle (or override set)
		
RETURN:		carry clear
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNoteToKeywords	proc	far	uses	ax, bx, ds, di
	noteToAdd	local	dword
	.enter
	movdw	noteToAdd, axdi

	call	KeywordFind		;Returns DX.AX as dword index of
					; KeywordInfo structure, 
					;DI = huge array handle 
	jnc	found

	call	CreateKeywordInfo
found:
	push	dx, ax, di

	call	HugeArrayLock
	mov	di, ds:[si].KI_references.DBGI_item
	mov	ax, ds:[si].KI_references.DBGI_group
	call	HugeArrayUnlock

;	Make sure that the note is only in the reference table once (ensure
;	that the hoser...er...user hasn't added the same keyword twice to a
;	note).

	call	DBLockDSSI
	movdw	dxcx, noteToAdd
	mov	bx, cs
	mov	di, offset FindDBItemCallback
	push	bp
	call	ChunkArrayEnum
	pop	bp
	jc	exit

	call	ChunkArrayAppend	;Note isn't in the reference list yet,
	mov	ds:[di].DBGI_item, cx	; so add it.
	mov	ds:[di].DBGI_group, dx
exit:
	call	DBUnlockDS
	pop	dx, ax, di
	clc
	.leave
	ret
AddNoteToKeywords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeywordStringEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a routine for each keyword in the passed string

CALLED BY:	GLOBAL
PASS:		DS:SI <- null-terminated keyword string
		CX:DX <- callback routine
		ES, AX, BX, DI <- data

	Callback is passed:
		ES, AX,BX,DI <- passed in values (can be modified)
		DS:SI <- ptr to keyword
	Callback returns:
		carry set to abort enum
	Callback destroys:
		cx, dx, si

RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	skipToNextWord:
		while (IsWordBreak(*strPtr++));

		if (*(strPtr-1) == EOS)
				return ()
		wordStart = strPtr-1;

		while (!IsWordBreak(*strPtr++));

		oldChar = *(strPtr-1)
		*(strPtr-1) = EOS;
		DoCallback(wordStart);
		*(strPtr-1) = oldChar;
		goto skipToNextWord

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeywordStringEnum	proc	far	uses	ds, si
	callback	local	fptr
	dataAX		local	word
	keywordString	local	INK_DB_MAX_NOTE_KEYWORDS_SIZE dup (char)
	.enter
	movdw	callback, cxdx
	mov	dataAX, ax

;	Copy the string into our stack frame

	push	es, di
	segmov	es, ss
	lea	di, keywordString
10$:
	lodsb
	stosb
	tst	al
	jnz	10$
	pop	es, di
	segmov	ds, ss		;DS:SI <- ptr to string in our stack frame
	lea	si, keywordString
	
skipToNextWord:
	lodsb
	tst	al
	jz	exit		;If we encountered EOS while skipping
				; word breaks, branch to exit
	call	CheckIfKeywordDelimiter
	tst	ah
	jz	skipToNextWord
	mov	dx, si		;DS:DX <- start of word
	dec	dx
findWordEnd:
	lodsb
	call	CheckIfKeywordDelimiter
	tst	ah
	jnz	findWordEnd
	mov	{byte} ds:[si][-1], C_NULL	;Null terminate sub-string
	push	ax, si
	mov	ax, dataAX
	mov	si, dx				;DS:SI <- ptr to start of word
	call	callback
	pop	ax, si
	dec	si
	mov	ds:[si], al
	jnc	skipToNextWord		;If no abort, branch to goto next word
exit:
	.leave
	ret
KeywordStringEnum	endp

CheckIfKeywordDelimiter	proc	near
	clr	ah
	cmp	al, C_COMMA	;If the char is a comma
	je	isKeywordDelimiter
	call	LocalIsSpace	; or a space character, then skip it
	jnz	isKeywordDelimiter
	tst	al
	jz	isKeywordDelimiter
	mov	ah, -1
isKeywordDelimiter:
	ret
CheckIfKeywordDelimiter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveNoteKeywordReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the passed note from all of its keyword references.

CALLED BY:	GLOBAL
PASS:		di.ax - keyword
		bx - file handle
RETURN:		nada
DESTROYED:	es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveNoteKeywordReferences	proc	near	uses	di, ax, cx, dx, ds, si
	.enter

;	Lock down the current keyword string

	push	di, ax
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].NI_keywordItem.DBGI_group
	mov	di, es:[di].NI_keywordItem.DBGI_item
	call	DBUnlock

	call	DBLock
	segmov	ds, es
	mov	si, es:[di]		;DS:SI <- ptr to keyword text

	pop	di, ax			;AX.DI <- note

;	For each keyword string, look it up in the keyword array

	mov	cx, cs
	mov	dx, offset RemoveNoteFromKeywords
	call	KeywordStringEnum

	call	DBUnlock
	.leave
	ret
RemoveNoteKeywordReferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNoteKeywordReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed note from all of its keyword references.

CALLED BY:	GLOBAL
PASS:		di.ax - keyword
		bx - file handle
RETURN:		nada
DESTROYED:	cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNoteKeywordReferences	proc	near	uses	di, ax, ds, si
	.enter

;	Lock down the current keyword string

	push	di, ax
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].NI_keywordItem.DBGI_group
	mov	di, es:[di].NI_keywordItem.DBGI_item
	call	DBUnlock

	call	DBLock
	segmov	ds, es
	mov	si, es:[di]		;DS:SI <- ptr to keyword text

	pop	di, ax			;AX.DI <- note

;	For each keyword string, look it up in the keyword array

	mov	cx, cs
	mov	dx, offset AddNoteToKeywords
	call	KeywordStringEnum

	call	DBUnlock
	.leave
	ret
AddNoteKeywordReferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetKeywords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the keyword text in the passed note

CALLED BY:	GLOBAL
PASS:		ds:si - new keyword text
		bx - file han
		di.ax - dword tag of note
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetKeywords	proc	far	uses	ax, cx, dx, di, si, es, ds
	.enter
	call	RemoveNoteKeywordReferences
	push	di, ax
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].NI_keywordItem.DBGI_group
	mov	di, es:[di].NI_keywordItem.DBGI_item
	call	DBUnlock
	call	CopyStringIntoDBBlock
EC <	cmp	cx, INK_DB_MAX_NOTE_KEYWORDS_SIZE+1			>
EC <	ERROR_A	KEYWORDS_TOO_LARGE					>
	pop	di, ax

	call	AddNoteKeywordReferences
	.leave
	ret
InkNoteSetKeywords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetKeywordsFromTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the keyword text in the passed note

CALLED BY:	GLOBAL
PASS:		cx:dx - optr of text object
		bx - file han
		di.ax - dword tag of note
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetKeywordsFromTextObject	proc	far 
	uses ax, cx, dx, di, si, es, ds
	.enter
	call	RemoveNoteKeywordReferences
	push	di, ax
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].NI_keywordItem.DBGI_group
	mov	di, es:[di].NI_keywordItem.DBGI_item
	call	DBUnlock

	call	CopyTextObjectIntoDBBlock

	pop	di, ax

	call	AddNoteKeywordReferences
	.leave
	ret
InkNoteSetKeywordsFromTextObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetKeywords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the keyword string from the passed note

CALLED BY:	GLOBAL
PASS:		di.ax - note
		bx - file handle or set override
		ds:si - dest for string
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version
	JT	7/ 6/92		Modified to copy NoKeywords String

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetKeywords	proc	far	uses	ax, cx, di, si, es
	.enter
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di].NI_keywordItem.DBGI_group
	mov	di, es:[di].NI_keywordItem.DBGI_item
	call	DBUnlock

	call	CopyStringFromDBBlock
EC <	cmp	cx, INK_DB_MAX_NOTE_KEYWORDS_SIZE+1			>
EC <	ERROR_A	KEYWORDS_TOO_LARGE					>

	cmp	{char} ds:[si], 0
	jnz	done

	mov	bx, handle Strings
	call	MemLock
	mov	es, ax
	mov	di, offset NoKeywordsString
	mov	di, es:[di]
	call	MemUnlock
	segxchg	es, ds			;ES:DI <- ptr to dest for string,
	xchg	si, di			;DS:SI <- ptr to src 
	ChunkSizePtr	ds, si, cx
	rep	movsb
	segxchg	es, ds

done:

	.leave
	ret
InkNoteGetKeywords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSendKeywordsToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the keyword string from the passed note

CALLED BY:	GLOBAL
PASS:		di.ax - note
		bx - file handle or set override
		CX:DX - optr
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSendKeywordsToTextObject	proc	far	uses	ax, di, ds, si
	.enter
	call	DBLockDSSI
	mov	si, ds:[si]
	movdw	axdi, ds:[si].NI_keywordItem
	call	DBUnlockDS

	mov	si, offset NoKeywordsDisplayString
	call	SendDBBlockToTextObject
	.leave
	ret
InkNoteSendKeywordsToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed page

CALLED BY:	GLOBAL
PASS:		ds:di <- ptr to DBGroupAndItem structure
		ax - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletePageCallback	proc	far
	.enter
	mov_tr	bx, ax			;BX <- file handle
	movdw	axbp, ds:[di]
	call	VMFreeVMChain
	mov_tr	ax, bx			;AX <- file handle
	.leave
	ret
DeletePageCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed note and all references to it.

CALLED BY:	GLOBAL
PASS:		di.ax - note
		bx - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteDelete	proc	far		uses	ax, bx, cx, dx, di, si, es, ds
	.enter
	call	RemoveNoteKeywordReferences
	push	di, ax

	call	DBLock
	mov	si, di

	mov	si, es:[si]
	mov	ax, es:[si].NI_extraData.DBGI_group
	mov	di, es:[si].NI_extraData.DBGI_item
	tstdw	axdi
	jz	10$
	call	DBFree
10$:

	mov	ax, es:[si].CI_title.DBGI_group
	mov	di, es:[si].CI_title.DBGI_item
	call	DBFree

	mov	ax, es:[si].NI_keywordItem.DBGI_group
	mov	di, es:[si].NI_keywordItem.DBGI_item
	call	DBFree
	
	push	es:[si].CI_parentFolder.DBGI_group
	push	es:[si].CI_parentFolder.DBGI_item

	mov	ax, es:[si].NI_pageArray.DBGI_group
	mov	di, es:[si].NI_pageArray.DBGI_item
	call	DBUnlock

;	Free up the pages in the page array

	push	di, ax
	call	DBLock
	segmov	ds, es			;*DS:SI <- chunk array
	push	bx
	mov	ax, bx	
	mov	si, di
	mov	bx, cs
	mov	di, offset DeletePageCallback
	call	ChunkArrayEnum
	pop	bx
	call	DBUnlock
	pop	di, ax
	call	DBFree			;Free the chunk array itself

	pop	di
	pop	ax
	pop	cx, dx
	tstdw	axdi
	jz	noParent
	call	FolderRemoveNote
noParent:
	.leave
	ret
InkNoteDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves a note from one folder to another.

CALLED BY:	GLOBAL
PASS:		AX.DI <- note to move
		DX.CX <- new parent folder
		BX <- file handle (or override set)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteMove	proc	far	uses	ax, cx, dx, di, si, ds, es
	theNote	local	dword
	.enter
	movdw	theNote, axdi
	call	DBLock			;Get the current parent folder
	call	DBDirty
	mov	si, es:[di]
	movdw	axdi, dxcx
	xchg	ax, es:[si].CI_parentFolder.DBGI_group
	xchg	di, es:[si].CI_parentFolder.DBGI_item
	call	DBUnlock
	cmpdw	axdi, dxcx	;If new parent is the same as the old, branch
	je	exit

;	Remove the note from the current parent (if any)

	tstdw	axdi
	jz	noParent
	push	cx, dx
	movdw	dxcx, theNote
	call	FolderRemoveNote
	pop	cx, dx
noParent:

;	Add the note to the new parent (if any)

	tstdw	dxcx
	jz	exit
	movdw	axdi, theNote
	xchgdw	dxcx, axdi		;AX.DI <- new parent folder
					;DX.CX <- note
	call	FolderAddNote
exit:
	.leave
	ret
InkNoteMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetModificationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the modification date for the passed note.

CALLED BY:	GLOBAL
PASS:		di.ax - note
		bx - file han
		cx,dx - mod date
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetModificationDate	proc	far	uses	es, di
	.enter
	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	movdw	es:[di].NI_modDate, cxdx	
	call	DBUnlock
	.leave
	ret
InkNoteSetModificationDate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetModificationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the modification date from the note

CALLED BY:	GLOBAL
PASS:		di.ax, bx - note and file handle
RETURN:		cx, dx - mod date
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetModificationDate	proc	far	uses	es, di
	.enter
	call	DBLock
	mov	di, es:[di]
	movdw	cxdx, es:[di].NI_modDate
	call	DBUnlock
	.leave
	ret
InkNoteGetModificationDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetCreationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the creation date from the note

CALLED BY:	GLOBAL
PASS:		di.ax, bx - note and file handle
RETURN:		cx, dx - creation date
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetCreationDate	proc	far	uses	es, di
	.enter
	call	DBLock
	mov	di, es:[di]
	movdw	cxdx, es:[di].NI_creationDate
	call	DBUnlock
	.leave
	ret
InkNoteGetCreationDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteGetNoteType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the note type - ink or text
CALLED BY:	GLOBAL
PASS:		di.ax- note handle
		bx - database file handle
RETURN:		cx - note type (0:ink, 2:text)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteGetNoteType	proc	far	uses	ds,si
	.enter

	call	DBLockDSSI
	mov	si, ds:[si]
	mov	cl, ds:[si].NI_typeNote
EC <	cmp	cl, NoteType						>
EC <	ERROR_AE	BAD_NOTE_TYPE					>
	call	DBUnlockDS
	clr	ch
	.leave
	ret
InkNoteGetNoteType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteSetNoteType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the note type - ink or text
CALLED BY:	GLOBAL
PASS:		di.ax- note handle
		bx - database file handle
		cl - note type (0:ink, 2:text)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteSetNoteType	proc	far	uses	ds, si
	.enter
EC <	cmp	cl, NoteType						>
EC <	ERROR_AE	BAD_NOTE_TYPE					>

	call	DBLockDSSI
	mov	si, ds:[si]
	mov	ds:[si].NI_typeNote, cl
	call	DBUnlockDS

	.leave
	ret
InkNoteSetNoteType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderDisplayChildInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds/sends a moniker to the passed list.

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		BX - file handle
		CX:DX - OD of output list
		BP - entry # of child we want to display
		SI -  non-zero if we want to display folders
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version
	JT	3/5/92		Modified to show the monikers for note/folder
	JT	5/13/92		Modified to distinguish text note icon and
				ink note icon
	atw	11/2/92		Added "display folders" functionality. I
				was going to clean up the code too, but didn't
				have the stomach for it :(

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderDisplayChildInList	proc	far uses ax, bx, cx, dx, bp, di, si, ds
	.enter

;	Determine whether this child is a note or a subfolder. Get the 
;	appropriate array of children depending upon the result.
	push	cx, dx, bp		;save optr of output list
					;save the entry index

	call	InkFolderGetContents	;AX.DI <- chunk array of sub-folders
					;DX.CX <- chunk array of notes
	tst	si
	jnz	doFolderCheck
	movdw	diax, cxdx
	clr	cx			;Set to "no folders"
	jmp	afterFolderCheck

doFolderCheck:
	push	cx, dx			;Save chunk array of notes
	call	DBLockDSSI
	call	ChunkArrayGetCount
	cmp	bp, cx			;If requested entry is a sub-folder,
	pop	di, ax			; branch...

	mov	dx, -1			;set dx = -1 if it is a folder
	jb	setMoniker		;
	call	DBUnlockDS		;Else, unlock sub-folder chunk array

afterFolderCheck:
	push	ax, di, cx, bp

	call	DBLockDSSI
	sub	bp, cx			; and use note folder
EC <	ERROR_C	-1							>
	mov	ax, bp			;ax - element number to find
	call	ChunkArrayElementToPtr	;ds:di - element
	jc	assumeInkNote
	mov	ax, ds:[di].DBGI_group	;di.ax - note handle
	mov	di, ds:[di].DBGI_item
	call	InkNoteGetNoteType
	clr	ch

	mov	dx, 1			;assume it is a text note
					;set dx = 1
	tst	cx
	jnz	inkTextCommon

assumeInkNote:
	clr	dx			;it is an ink note

inkTextCommon:
	call	DBUnlockDS
	pop	ax, di, cx, bp
	sub	bp, cx			; and use note folder

	call	DBLockDSSI

EC <	call	ChunkArrayGetCount					>
EC <	cmp	bp, cx							>
EC <	ERROR_AE	BAD_CHILD_NUMBER				>

setMoniker:

;	*DS:SI, - ChunkArray of folder children
;	BP - index of child whose name/title we desire

	mov	ax, bp
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	call	DBUnlockDS

	call	ChildGetTitleBlock

	call	DBLockDSSI
	mov	si, ds:[si]		;DS:SI <- name string of child
	movdw	dicx, dssi		;DI:CX <- name string of child

	mov	ax, dx			;set ax = -1 if it is a folder
					;set ax = 0 if it is an ink note
					;set ax = 1 if it is a text note

	clr	dx			;dx=0 if titled

	cmp	{char} ds:[si], 0
	jnz	gotFlags

	push	ds, ax
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
assume ds:Strings		
	mov	cx, ds:[NoTitleString]
assume ds:dgroup		
	mov	di, ds
	mov	dx, bx			;dx = handle to unlock
					;dx <>0 if untitled,need DBUnlockDS
	pop	ds, ax			;restore ax -- note or folder flag

gotFlags:
	pop	bx, si, bp		;bx:si <= optr of output list
					;di:cx <= title of the note or folder
	push	dx
	mov	dx, bp			;dx - entry index
	call	InkNoteCopyMoniker
	pop	bx
	tst	bx
	jz	99$
	call	MemUnlock
99$:
	call	DBUnlockDS

	.leave
	ret
InkFolderDisplayChildInList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteCopyMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy the icon and folder/note name into the vis moniker
CALLED BY:	GLOBAL
PASS:		
		di:cx -- title of the note or folder
		bx:si -- optr of output list
		ax - 1 if text note, 0 if ink note, -1 if folder
		dx - entry index
RETURN:		nothing
DESTROYED:	ax,bx,dx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteCopyMoniker	proc	far		uses	es, bp
	.enter
EC <	call	ECMemVerifyHeap					>
	sub	sp, (size VisMoniker + size VisMonikerGString + \
			ICON_THINGY_SIZE + INK_DB_MAX_TITLE_SIZE + 3)
	mov	bp, sp
	segmov	es, ss			; es:bp <= ptr to where to copy moniker

	;pass:	es:bp -- ptr to where to copy moniker
	;	di:cx -- title of the note or folder
	;	bx:si -- optr of output list
	;	ax - 1 if text note, 0 if ink note, -1 if folder
	call	CopyInNoteFolderIconAndName
EC <	call	ECMemVerifyHeap					>
EC <	call	ECCheckStack					>

	;pass:	es:bp -- ptr to where to copy moniker
	;	bx:si -- optr of output list
	call	CopyInCorrectIconAndName	
EC <	call	ECMemVerifyHeap					>

	mov	di, bp			; es:di <= ptr to where to copy moniker
	mov	cx, dx			; cx <= index entry
	mov	dx, size ReplaceItemMonikerFrame
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].RIMF_source, esdi
	mov	ss:[bp].RIMF_sourceType, VMST_FPTR
	mov	ss:[bp].RIMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].RIMF_length,  (size VisMoniker + size \
		VisMonikerGString +ICON_THINGY_SIZE +INK_DB_MAX_TITLE_SIZE +3)

	mov	ss:[bp].RIMF_item, cx
	clr	ss:[bp].RIMF_itemFlags

	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	add	sp, (size ReplaceItemMonikerFrame + size VisMoniker + \
			size VisMonikerGString + ICON_THINGY_SIZE + \
			INK_DB_MAX_TITLE_SIZE + 3)

	.leave
	ret
InkNoteCopyMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyInNoteFolderIconAndName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy in the icon and name into vismoniker
CALLED BY:	InkFolderDisplayChildInList
PASS:		
		es:bp -- ptr to where to copy moniker
		di:cx -- title of the note or folder
		bx:si <= optr of output list
		ax - 1 if text note, 0 if ink note, -1 if folder
RETURN:		nothing
DESTROYED: 	nothing
	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/ 3/92		Initial version
	JT	5/13/92		Modified to distinguish text note icon and
				ink note icon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyInNoteFolderIconAndName	proc	near
	uses	bx,si,ax,cx,dx,di,bp,ds,es
	.enter

	pushdw	dicx
	segmov	ds, cs

	mov	si, offset inkNoteIconThingy	;assume it is ink note
	tst	ax
	jz	common				

	mov	si, offset folderIconThingy	; assume it is a folder
	cmp	ax, 1
	jne	common

	mov	si, offset textNoteIconThingy	; else, text note

common:
	mov	cx, ICON_THINGY_SIZE
	mov	di, bp
	add	di, size VisMoniker + size VisMonikerGString
	rep movsb
EC <	call	ECMemVerifyHeap					>

	;Copy name of string here
	popdw	dssi
	call	GetStringSizeDSSI

	mov	es:[di-2], cx		;Store length of string
	rep	movsb
EC <	call	ECMemVerifyHeap					>

	;to mark end of GString
;	mov	cx, INK_DB_MAX_TITLE_SIZE
;	rep	movsb
	mov	al, GR_END_GSTRING
	stosb
EC <	call	ECMemVerifyHeap					>

	;to center the GString
	clr	ax
	mov	{word} es:[bp + (size VisMoniker + size VisMonikerGString + \
			ICON_HGT_ADJ_OFFSET)], ax
	mov	{word} es:[bp + (size VisMoniker + size VisMonikerGString + \
			TEXT_HGT_ADJ_OFFSET)], ax

EC <	call	ECMemVerifyHeap					>
EC <	call	ECCheckStack					>
	.leave
	ret

CopyInNoteFolderIconAndName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyInCorrectIconAndName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Modify the Text position in the vismoniker

CALLED BY:	InkFolderDisplayChildInList
PASS:		
		es:bp -- ptr to where to copy moniker
		bx:si -- optr of output list
RETURN:		nothing
DESTROYED: 	nothing
PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyInCorrectIconAndName	proc	near
	uses	bx,si,ax,cx,dx,di,bp,ds,es
	.enter

	push	bp, es
	; fill in icon/name width and height
						; Not actually needed for
						; drawing, just for calculating
						; so we don't care if comes
						; back w/null window reference
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL
	call	ObjMessage			; bp = calc gstate
	mov	di, bp				; di = calc gstate
EC <	call	ECMemVerifyHeap					>

	pop	bp, es
	segmov	ds, es				; ds:si = entry name
	mov	si, bp
	add	si, size VisMoniker + size VisMonikerGString + ICON_THINGY_SIZE
	mov	cx, -1
	call	GrTextWidth			; dx = text width
	add	dx, NTAKER_ICON_SPACING		; add in icon spacing
	mov	es:[bp].VM_width, dx		; store it
	mov	si, GFMI_ROUNDED or GFMI_HEIGHT
	call	GrFontMetrics			; dx = font height
	call	GrDestroyState
	mov	es:[bp].VM_type, mask VMT_GSTRING	
						; mark moniker as gstring

	; center icon w.r.t. text
	;	dx = font height
	mov	({VisMonikerGString} es:[bp].VM_data).VMGS_height, dx	
						; store font height
	cmp	dx, NTAKER_ICON_HEIGHT
	je	done				; same, no adjustment on either
	mov	ax, NTAKER_ICON_HEIGHT
	ja	adjustIcon			; font bigger, adjust icon
	mov	({VisMonikerGString} es:[bp].VM_data).VMGS_height, ax
						; else, store icon height
						;	as total height...
	sub	ax, dx				; ...and adjust font placement
	shr	ax, 1				; ax = font adjustment
	mov	es:[bp+(size VisMoniker + size VisMonikerGString + \
				TEXT_HGT_ADJ_OFFSET)], ax
EC <	call	ECMemVerifyHeap					>
	jmp	short done

adjustIcon:
	sub	dx, ax
	shr	dx, 1				; dx = icon adjustment
	mov	es:[bp + (size VisMoniker + size VisMonikerGString + \
				ICON_HGT_ADJ_OFFSET)], dx
	neg	dx				;make opposite adjustment after
						;	drawing icon
	mov	es:[bp + (size VisMoniker + size VisMonikerGString + \
				TEXT_HGT_ADJ_OFFSET)], dx
done:
	.leave
	ret

CopyInCorrectIconAndName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderGetChildInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get information for a numbered child

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		BX - file handle
		CX - child number
RETURN:		carry - set if folder / clear if item
		AX.DI - folder or note
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderGetChildInfo	proc	far	uses	bx, cx, dx, bp, si, ds
	.enter

;	Determine whether this child is a note or a subfolder. Get the 
;	appropriate array of children depending upon the result.

	mov	bp, cx

	call	InkFolderGetContents	;AX.DI <- chunk array of sub-folders
					;DX.CX <- chunk array of notes
	push	cx, dx			;Save chunk array of notes
	call	DBLockDSSI
	call	ChunkArrayGetCount
	cmp	bp, cx			;If requested entry is a sub-folder,
	pop	di, ax			; branch...
	jb	folder
	call	DBUnlockDS		;Else, unlock sub-folder chunk array
	sub	bp, cx			; and use note folder
	call	DBLockDSSI
EC <	call	ChunkArrayGetCount					>
EC <	cmp	bp, cx							>
EC <	ERROR_AE	BAD_CHILD_NUMBER				>

	clc
	jmp	common

folder:
	stc

common:
	pushf

	mov_tr	ax, bp
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	call	DBUnlockDS

	popf

	.leave
	ret
InkFolderGetChildInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFolderGetChildNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child number given ID

CALLED BY:	GLOBAL
PASS:		AX.DI - folder
		BX - file handle
		DX.CX - note or  subfolder
RETURN:		AX - number
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFolderGetChildNumber	proc	far	uses	bx, cx, dx, bp, si, ds, di
	child		local	dword
	noteArray	local	dword
	.enter

	movdw	child, dxcx
	call	InkFolderGetContents	;AX.DI <- chunk array of sub-folders
					;DX.CX <- chunk array of notes
	movdw	noteArray, dxcx

;	Scan for the passed item in the folder array.

	call	DBLockDSSI
	movdw	dxcx, child
	push	bx, bp
	mov	bx, cs
	mov	di, offset FindDBItemCallback
	call	ChunkArrayEnum
	mov	di, bp
	pop	bx, bp
	mov	cx, 0
	jc	foundItem

	call	ChunkArrayGetCount	;CX <- # folders
	call	DBUnlockDS

	movdw	axdi, noteArray

	push	cx, bp			;Save # folders
	movdw	dxcx, child
	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset FindDBItemCallback
	call	ChunkArrayEnum
EC <	ERROR_NC	DB_ITEM_NOT_FOUND				>

	mov	di, bp
	pop	cx, bp
foundItem:

;	CX <- # items to add to this one to get final number (used if the
;		item was a note, and we want to add the # folders to it).

	call	ChunkArrayPtrToElement
	add	ax, cx

	call	DBUnlockDS
	.leave
	ret
InkFolderGetChildNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteFindByTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a note by its title

CALLED BY:	GLOBAL
PASS:		DS:SI <- string to match
		AL - SearchOptions
		AH - non-zero if we want to search the body
		BX <- file handle
RETURN:		DX - handle of block containing dward tags of matching notes
			in this format:

		FindNoteHeader<>
		  -dword tag-
		  -dword tag-
		  -dword tag-
			etc...
		Only returns first 20000 or so notes that match
		DX=0 if no item is found

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

FindNoteHeader	struct
	FNH_count	word
	; the # matching notes we've found
	FNH_data	label	dword
FindByNoteHeader	ends

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version
	JT	3/11/92		Modified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteFindByTitle	proc	far	uses	ax,bx,cx,di,si,bp, ds
.warn -unref_local
	targetString	local	dword	\
		push	ds, si
.warn @unref_local
	fileHan		local	word	\
		push	bx
	option		local	byte
	textOption	local	byte
	memBlockHan	local	word
	memBlockSeg	local	word
	noteHandle	local	dword
	dbSeg		local	word
	.enter


	mov	option, al
	mov	textOption, ah
	clr	dbSeg
	clrdw	noteHandle

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	ax, size FindNoteHeader

	call	MemAlloc		;returns block handle in bx
					;returns segment of block in ax

	;place stuff into the mem block
	mov	ds, ax
	mov	si, size FindNoteHeader	
	clr	ds:[FNH_count]

;PASS to InkFolderDepthFirstTraverse
;		AX.DI - folder at top of tree
;		BX - file handle
;		CX:DX - far ptr to callback routine
;		BP - extra data to pass to callback routine

	mov	memBlockSeg, ax
	mov	memBlockHan, bx			;save the block handle
	mov	bx, fileHan
	call	InkDBGetHeadFolder		;ax:di<=folder at top of tree
	mov	cx, cs
	mov	dx, offset TraverseEachNoteFindCallBack
	call	InkFolderDepthFirstTraverse

	mov	ds, memBlockSeg
	mov	dx, memBlockHan			; dx <= block handle
	mov	bx, dx
	tst	ds:[FNH_count]
	jz	noMatch
	call	MemUnlock
done:
	.leave
	ret

noMatch:
	call	MemFree
	clr	dx
	jmp	done
InkNoteFindByTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TraverseEachNoteFindCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Callback to traverse thru each note and find note with
		matched title

CALLED BY:	InkNoteFindByTitle
PASS:		AX.DI - folder at top of tree
		bx - file handle
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TraverseEachNoteFindCallBack	proc	far	uses	ax,di,bp,bx
	.enter inherit InkNoteFindByTitle

	call	InkFolderGetContents	;DX.CX <- chunk array of notes
	movdw	axdi, dxcx

	pushdw	axdi
	call	DBLockDSSI		
	mov	bx, cs
	mov	di, offset FindNoteTitleCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx

	call	DBUnlockDS
	popdw	axdi

	tst	textOption
	jz	done

	mov	bx, fileHan
	call	DBLockDSSI		
	mov	bx, cs
	mov	di, offset FindTextCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx

	call	DBUnlockDS

done:
	.leave
	ret
TraverseEachNoteFindCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNoteTitleCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Check to see if there is any note with matched title.
		If there is a match, add the note handle into the
		search result block

CALLED BY:	TraverseEachNoteFindCallBack
PASS: 
		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
		bx -- file handle

RETURN:		carry set to end enumeration

DESTROYED:	es,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		So far, only match up to 1000 or so entries		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNoteTitleCallBack	proc	far	uses	ax,di,bp,bx,ds
	.enter

	call	FindMatchedStringInNoteTitle
	cmc
	jnc	exit
	call	AddNoteHandleToSearchResultBlock
exit:
	.leave
	ret
FindNoteTitleCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTextCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Check to see if there is any note with matched title.
		If there is a match, add the note handle into the
		search result block

CALLED BY:	TraverseEachNoteFindCallBack
PASS: 
		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
		bx -- file handle

RETURN:		carry set to end enumeration

DESTROYED:	es,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		So far, only match up to 1000 or so entries		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTextCallBack	proc	far	uses	ax,di,bp,bx,ds
	.enter inherit InkNoteFindByTitle

	call	FindMatchedStringInTextNote	
	jc	clcExit

	;find out if there is any overlap of note handle
	mov	es, memBlockSeg
	mov	cx, es:[FNH_count]
	mov	si, size FindNoteHeader
	jcxz	doAdd

compareLoop:
	movdw	axdi, es:[si]
	cmpdw	noteHandle, axdi
	je	exit
	add	si, size noteHandle
	loop	compareLoop
doAdd:
	clc				;clear carry, the note handle
					;has to be added to the result block
	call	AddNoteHandleToSearchResultBlock
exit:
	.leave
	ret
clcExit:
	clc
	jmp	exit
FindTextCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNoteHandleToSearchResultBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		If a matched string is found, add the corresponding note
		handle to the search result block
CALLED BY:	FindNoteTitleCallBack / FindTextCallBack
PASS:		carry set if a matched string is not found
RETURN:		carry set to end enumeration
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNoteHandleToSearchResultBlock	proc	near	uses	ax,bx,si,di,bp
	.enter inherit InkNoteFindByTitle

	mov	es, memBlockSeg
	cmp	es:[FNH_count], MAX_NOTES
	ja	tooManyEntries
	inc	es:[FNH_count]

	;now place note handle into the memory block

	;mem block size = size of Header + count * size of element(which is 4)

	mov	ax, es:[FNH_count]
	shl	ax, 1
	shl	ax, 1
	add	ax, size FindNoteHeader		;size of block header
	clr	ch
	mov	bx, memBlockHan
	mov	si, ax
	call	MemReAlloc	
	mov	memBlockSeg, ax
	mov	es, ax
	
	;add the new data to the block

	sub	si, 4				;position to load new data =
						;newSize - 4
	movdw	es:[si], noteHandle, ax

	clc
	jmp	done

tooManyEntries:
	stc
done:
	.leave
	ret
AddNoteHandleToSearchResultBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMatchedStringInNoteTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		To find out if there is any matched note handle.

CALLED BY:	FindNoteTitleCallBack
PASS:		
		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
		bx -- file handle
RETURN:		carry set if a matched string is not found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMatchedStringInNoteTitle	proc	near	uses	ax,di,bp,bx

	.enter inherit InkNoteFindByTitle

	mov	bx, fileHan
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	movdw	noteHandle, axdi	;axdi <= note handle

	call	ChildGetTitleBlock	;axdi <= title
	call	CallTextSearchInString

	.leave
	ret
FindMatchedStringInNoteTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMatchedStringInTextNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		To find out if there is any matched note handle.

CALLED BY:	FindTextCallBack
PASS:		
		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
		bx -- file handle
RETURN:		carry set if a matched string is not found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMatchedStringInTextNote	proc	near	uses	ax,di,bp,bx

	.enter inherit InkNoteFindByTitle

	mov	bx, fileHan
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	movdw	noteHandle, axdi	;axdi <= note handle
	call	InkNoteGetNoteType
	cmp	cx, NT_TEXT
	stc
	jne	exit
	


	;search for text in each page of the note
	call	InkNoteGetPages		;ax.di-group/item of DB item containing
					;chunk array of page info
	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset SearchTextInPageCallback
	call	ChunkArrayEnum		;pass *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx

	;returns carry set if string found, so invert carry 
	cmc
	mov	bx, fileHan
	call	DBUnlockDS
exit:

	.leave
	ret
FindMatchedStringInTextNote		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTextInPageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Callback routine to search for text in pages
CALLED BY:	
PASS:		*ds:si - array of pages
		ds:di - a ptr to the handle of the current page in the array
RETURN:		carry set to end enumeration
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchTextInPageCallback	proc	far	uses	ax, di, bx
	.enter inherit InkNoteFindByTitle

	mov	bx, fileHan
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	call	CallTextSearchInString

	;Carry is set if string is not found.
	cmc				;Stop only if string found	
	.leave
	ret
SearchTextInPageCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTextSearchInString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set up registers to pass into TextSearchInString and call it.
CALLED BY:	
PASS:		ax:di - DB item:group
		bx - DB file handle
RETURN:		carry set if a matched string is not found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTextSearchInString	proc	near	uses	ds, si
	.enter inherit InkNoteFindByTitle

;Pass to TextSearchInString
;	DS:SI - ptr to string to match
;	AL - SearchOptions
;	ES:BP - ptr to string to search in
;	ES:DI - ptr to char in string to start search
;	ES:BX - pointing to the last character of the note title (right before
;		the null terminator)
;	DX - # characters in the note title (excluding the null)
;	CX = 0 (because the search string is null terminated)

	tstdw	axdi
	jz	noText
	call	DBLock			;pass ax:di=DB group:item
					;bx = DB file handle
					;return es:*di = ptr to DB item
	mov	dbSeg, es
	mov	di, es:[di]		;es:di <= title string

	; find out the length of the title string
	call	LocalStringSize
	stc				;If no chars in string, etc, then exit
	jcxz	unlockBlock
	mov	dx, cx

	mov	bx, di
	add	bx, dx
	dec	bx			;es:bx <= points to last char of the
					;title string (before null terminator)
	lds	si, targetString
	mov	al, option
	clr	cx
	push	bp
	mov	bp, di
	call	TextSearchInString
	pop	bp
unlockBlock:
	mov	bx, fileHan
	call	DBUnlock

;Return from TextSearchInString
;	IF a matched string not found:
;	carry set

done:
	.leave
	ret

noText:
	stc
	jmp	done

CallTextSearchInString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNoteFindByKeywords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a note by its keywords

CALLED BY:	GLOBAL
PASS:		DS:SI <- keywords to match
		AX <- non-zero if you only want notes that contain all passed
		      keywords
		BX <- file handle
RETURN:		DX - handle of block containing dword tags of matching notes
			in this format:

		FindNoteHeader<>
		  -dword tag-
		  -dword tag-
		  -dword tag-
			etc...
		Only returns first 20000 or so notes that match
		DX=0 if no item is found

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/92		Initial version
	JT	3/19/92		Modified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNoteFindByKeywords	proc	far	uses	ax,bx,cx,di,si,bp
.warn -unref_local
	fileHan		local	hptr	\
			push	bx
.warn @unref_local
	option		local	word	\
			push	ax
	targetString	local	dword
	memBlockHan	local	word
	memBlockSeg	local	word
	noteHandle	local	dword
	repeatFound	local	word
	count		local	word

	.enter

	movdw	targetString, dssi
	clr	repeatFound
	clr	noteHandle.high
	clr	noteHandle.low

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	ax, size FindNoteHeader
	call	MemAlloc		;returns block handle in bx
					;pass block handle in bx

	;place stuffs into the mem block
	mov	es, ax
	mov	di, size FindNoteHeader	
	clr	es:[FNH_count]

	mov	memBlockSeg, ax
	mov	memBlockHan, bx		;save the block handle

	cmp	option, 0
	mov	bx, bp
	mov	cx, cs
	jne	matchAllKeywords

	mov	dx, offset FindNotesThatMatchAtLeastOneKeywordCallback
	call	KeywordStringEnum
	jmp	common

matchAllKeywords:
	mov	count, 1
	mov	dx, offset FindNotesThatMatchAllKeywordsCallback
	call	KeywordStringEnum

common:
	mov	dx, memBlockHan			; dx <= block handle
	mov	bx, dx
	mov	es, memBlockSeg
	tst	es:[FNH_count]
	jz	noMatch

	;there is match
	call	MemUnlock
done:
	.leave
	ret

noMatch:
	call	MemFree				;search result
	clr	dx
	jmp	done
InkNoteFindByKeywords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNotesThatMatchAtLeastOneKeywordCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:			
		Callback to determine if the passed keyword string is
		found. If found, build up the search result block
		based on the union of note handles in the passed
		chunk array.

CALLED BY:	InkNoteFindByKeywords
PASS:		ES, AX,BX,DI <- passed in values (can be modified)
		DS:SI <- ptr to keyword
		AX <- TRUE if you only want notes that contain all passed
		      keywords
		BX <- bp to save local variable
RETURN:		carry set to abort enum
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNotesThatMatchAtLeastOneKeywordCallback	proc	far	uses	ax,bx,di,bp,ds,si
	.enter	inherit	InkNoteFindByKeywords

;	KeywordFind PASS:
;		DS:SI <- null terminated keyword string
;		BX - file handle (or set override)
;	RETURN:		
;		carry set if not found
;		DX.AX - index of KeywordInfo struct in HugeArray
;		DI - HugeArray VM block

	mov	bp, bx
	mov	bx, fileHan
	call	KeywordFind		;carry set if keyword is not found
	jc	done

	call	HugeArrayLock
	mov	di, ds:[si].KI_references.DBGI_item
	mov	ax, ds:[si].KI_references.DBGI_group
	call	HugeArrayUnlock

	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset FindUnionCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx

	call	DBUnlockDirtyDS
	clc

done:
	.leave
	ret
FindNotesThatMatchAtLeastOneKeywordCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindUnionCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Enumerate all the chunk array element (note handle) and
		compare with all the handles in the search result block
		to see if there is any repeated note handle.
		If there is repeated handle, ignore it and continue to
		enumerate next chunk array element.
		If there is no repeated handle, add the note handle to
		the search result block.

CALLED BY:	FindNotesThatMatchAtLeastOneKeywordCallback

PASS:		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.

RETURN:		carry set if there is too many entries (over 1000)
		carry clear to continue enumeration
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindUnionCallBack	proc	far	uses	ax,di,bp,bx
	.enter inherit InkNoteFindByKeywords

	call	FindMatchedNoteHandle

	cmp	repeatFound, 1
	je	done				; there is matched note handle

	mov	es, memBlockSeg
	cmp	es:[FNH_count], MAX_NOTES
	ja	tooManyEntries

	;append note handle into the memory block
	call	SearchBlockAppend
	jmp	done

tooManyEntries:
	stc
done:
	.leave
	ret
FindUnionCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNotesThatMatchAllKeywordsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Callback to determine if the passed keyword string is
		found. If found, build up the search result block
		based on the intersection of note handles in the passed
		chunk array.

CALLED BY:	InkNoteFindByKeywords

PASS:		DS:SI <- null terminated keyword string
		bx - local variables

RETURN:		carry set to end enumeration
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNotesThatMatchAllKeywordsCallback	proc	far	
	uses	ax,di,bp,bx,ds,si
	.enter inherit InkNoteFindByKeywords

;	KeywordFind PASS:
;		DS:SI <- null terminated keyword string
;		BX - file handle (or set override)
;	RETURN:		
;		carry set if not found
;		DX.AX - index of KeywordInfo struct in HugeArray
;		DI - HugeArray VM block


	mov	bp, bx
	mov	bx, fileHan
	call	KeywordFind
	jc	noMatch

	call	HugeArrayLock
	mov	di, ds:[si].KI_references.DBGI_item
	mov	ax, ds:[si].KI_references.DBGI_group
	call	HugeArrayUnlock

	call	DBLockDSSI
	mov	bx, cs
	mov	di, offset FindIntersectionCallBack
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx

	inc	count
	call	DBUnlockDS
	clc
	jmp	done

noMatch:
	;If there is no match, set carry to end enumeration
	;and set the Block Header, count = 0
	;so that when the routine returns to its caller, the caller can
	;look at the information in the header and determine that 
	;there is no keyword found
	mov	es, memBlockSeg
	clr	es:[FNH_count]
	stc
done:
	.leave
	ret
FindNotesThatMatchAllKeywordsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindIntersectionCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out intersection of note handles in the chunk array
		and only the intersections are left in the search result
		block

CALLED BY:	FindNotesThatMatchAllKeywordsCallback

PASS:		*ds:si -- huge array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (count == 1)
		add the note handle to the search result block
	else
		call	FindRepeatedHandle
		(check to see each element in the search result block
		if it is found in the huge array.
		If it is not found, remove it from the search result block)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindIntersectionCallBack	proc	far	uses	ax,di,bp,bx,si,ds
	.enter inherit InkNoteFindByKeywords

	cmp	count, 1			;first element in the array
	jne	afterFirstElement

	;deal with the first element in the array
	;everything put into memBlockSeg

	call	FindMatchedNoteHandle
	cmp	repeatFound, 1
	je	done				;no matched note handle

	mov	es, memBlockSeg
	cmp	es:[FNH_count], MAX_NOTES
	ja	tooManyEntries

	;append note handle into the memory block
	call	SearchBlockAppend
	jmp	done

afterFirstElement:
	call	FindRepeatedNoteHandle
	jmp	done

tooManyEntries:
	stc
done:
	.leave
	ret

FindIntersectionCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRepeatedNoteHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Check to see each element in the search result block
		if it is found in the huge array.
		If it is not found, remove it from the search result block

CALLED BY:	FindIntersectionCallBack

PASS:		*ds:si -- array of notes associated with a keyword
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRepeatedNoteHandle	proc	near	uses	ax,di,bp,bx
	.enter inherit InkNoteFindByKeywords

	mov	es, memBlockSeg
	mov	cx, es:[FNH_count]
	mov	di, size FindNoteHeader

compareLoop:
	jcxz	done
	push	cx
	movdw	dxcx, es:[di]

;FindDBItemCallback
;PASS:		DX.CX - DBGroupAndItem to compare with (CX = item, DX=group)
;		DS:DI - array element
;RETURN:	BP = ptr to this item
;		carry set if match

	push	bp,di
	mov	bx, cs
	mov	di, offset FindDBItemCallback
	call	ChunkArrayEnum		;pass: *ds:si -- array
					;bx:di -- offset of callback routine
					;destroyed -- bx
	pop	bp,di
	jc	found			

	;item not find in the array
	;delete the note handle in the block

	push	ds,si,di
	segmov	ds, es
	mov	si, di
	add	si, 4
	dec	es:[FNH_count]
	mov	cx, es:[FNH_count]
	call	FindOutBytesToShift	;cx <= # bytes to be shifted
	shr	cx, 1	
	rep	movsw

	pop	ds,si,di
	pop	cx
	loop	compareLoop
done:
	.leave
	ret

found:	
	add	di, 4
	pop	cx
	loop	compareLoop
	jmp	done
FindRepeatedNoteHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMatchedNoteHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		compare passed note handle with all the note handles in
		the search result block. If there is any match, set the
		local variable repeatFound to be 1.

CALLED BY:	FindUnionCallBack / FindInsectionCallBack

PASS:		*ds:si -- array
		ds:di - a ptr to the handle of the current note/folder 
			in the array.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMatchedNoteHandle	proc	near	uses	ax,di,bp,bx

	.enter inherit InkNoteFindByKeywords

	clr	repeatFound
	mov	ax, ds:[di].DBGI_group
	mov	di, ds:[di].DBGI_item
	movdw	noteHandle, axdi	;axdi <= note handle

	mov	es, memBlockSeg
	mov	cx, es:[FNH_count]
	mov	si, size FindNoteHeader

compareLoop:
	jcxz	done
	movdw	axdi, es:[si]
	cmpdw	noteHandle, axdi
	je	found
	add	si, 4
	loop	compareLoop

done:
	.leave
	ret

found:
	mov	repeatFound, 1
	jmp	done

FindMatchedNoteHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchBlockAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Append note handle into the search block

CALLED BY:	FindUnionCallBack / FindIntersectionCallBack
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchBlockAppend	proc	near	uses	ax,cx,di,bp,bx,si,dx

	.enter inherit InkNoteFindByKeywords
	;now place note handle into the memory block
	;mem block size = size of Header + count * size of element(which is 4)

	mov	es, memBlockSeg
	inc	es:[FNH_count]
	mov	ax, es:[FNH_count]
	shl	ax, 1
	shl	ax, 1
	add	ax, size FindNoteHeader		;size of block header
	clr	ch
	mov	bx, memBlockHan
	mov	si, ax
	call	MemReAlloc	
	mov	memBlockSeg, ax
	mov	es, ax
	;add the new data to the block
	sub	si, 4				;position to load new data =
						; newSize - 4
	movdw	es:[si], noteHandle, ax

	.leave
	ret
SearchBlockAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindOutBytesToShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out number of bytes in the search result block
		to be shifted.

CALLED BY:	FindRepeatedNoteHandle
PASS:		di - offset in the memory block
		cx - number of elements left in the array after removing
		     one element
RETURN:		cx = # bytes to be shifted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindOutBytesToShift	proc	near	uses	bx,di
	.enter

	; (**)
	;= #elements from the beginning of segment to where es:di points to
	;= (di - size of header)/element size which is 4
	sub	di, size FindNoteHeader
	mov	bx, di
	shr	bx, 1
	shr	bx, 1

	;#bytes to be shifted = (orinigal # elements - 1 - (**)) x element size
	sub	cx, bx
	shl	cx, 1
	shl	cx, 1
	.leave
	ret
FindOutBytesToShift	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Utilities

------------------------------------------------------------------------------@
DBLockDSSI	proc	near	uses di, es
	.enter
	call	DBLock
	segmov	ds, es
	mov	si, di
	.leave
	ret
DBLockDSSI	endp

;---

DBUnlockDS	proc	near
	segxchg	ds, es
	call	DBUnlock
	segxchg	ds, es
	ret
DBUnlockDS	endp

;---

DBDirtyDS	proc	near
	segxchg	ds, es
	call	DBDirty
	segxchg	ds, es
	ret
DBDirtyDS	endp

;---

DBUnlockDirtyDS	proc	near
	call	DBDirtyDS
	call	DBUnlockDS
	ret
DBUnlockDirtyDS	endp

;;;;;------------------------------------------------------------------
;;;;;	Draw bitmaps for the icon and name of the note and folder
;;;;;------------------------------------------------------------------


.warn -inline_data

NTAKER_ICON_HEIGHT = 11
NTAKER_ICON_WIDTH = 16
NTAKER_ICON_SPACING = 18

textNoteIconThingy	label	byte
	byte	GR_REL_MOVE_TO
	word	0, 0
	word	0
ICON_HGT_ADJ_OFFSET = ($-textNoteIconThingy)
	word	0

	byte	GR_FILL_BITMAP_CP
	word	(textNoteEnd - textNoteStart)
	textNoteStart	label	byte
	Bitmap <NTAKER_ICON_WIDTH, NTAKER_ICON_HEIGHT, 0, BMF_MONO>
	byte	00011111b, 11110000b
        byte    00010000b, 00010000b
        byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00010111b, 11010000b
	byte    00010000b, 00010000b
	byte    00011111b, 11110000b
	textNoteEnd	label	byte

ICON_THINGY_SUB_SIZE equ ($-textNoteIconThingy)

	byte	GR_REL_MOVE_TO
	word	0
	word	NTAKER_ICON_SPACING
	word	0
TEXT_HGT_ADJ_OFFSET = ($-textNoteIconThingy)
	word	0

	byte	GR_DRAW_TEXT_CP
	word	INK_DB_MAX_TITLE_SIZE

ICON_THINGY_SIZE equ ($ - textNoteIconThingy)

inkNoteIconThingy	label	byte
	byte	GR_REL_MOVE_TO
	word	0, 0
	word	0
ICON_HGT_ADJ_OFFSET = ($-inkNoteIconThingy)
	word	0

	byte	GR_FILL_BITMAP_CP
	word	(inkNoteEnd - inkNoteStart)
	inkNoteStart	label	byte
	Bitmap <NTAKER_ICON_WIDTH, NTAKER_ICON_HEIGHT, 0, BMF_MONO>
	byte	00011111b, 11110000b
        byte    00010110b, 00010000b
        byte    00011000b, 00010000b
	byte    00010110b, 00010000b
	byte    00010001b, 11010000b
	byte    00010110b, 00010000b
	byte    00010100b, 00010000b
	byte    00010110b, 00010000b
	byte    00010011b, 10010000b
	byte    00011000b, 00010000b
	byte    00011111b, 11110000b
	inkNoteEnd	label	byte

INK_ICON_THINGY_SUB_SIZE equ ($-inkNoteIconThingy)

	byte	GR_REL_MOVE_TO
	word	0
	word	NTAKER_ICON_SPACING
	word	0
TEXT_HGT_ADJ_OFFSET = ($-inkNoteIconThingy)
	word	0

	byte	GR_DRAW_TEXT_CP
	word	INK_DB_MAX_TITLE_SIZE

INK_ICON_THINGY_SIZE equ ($ - inkNoteIconThingy)

folderIconThingy	label	byte
	byte	GR_REL_MOVE_TO
	word	0, 0
	word	0, 0

	byte	GR_FILL_BITMAP_CP
	word	(folderEnd - folderStart)
	folderStart	label	byte
	Bitmap <NTAKER_ICON_WIDTH, NTAKER_ICON_HEIGHT, 0, BMF_MONO>
        byte    00000000b, 00000000b
	byte    00000000b, 00000000b
	byte    00000000b, 00000000b
	byte    00000001b, 10000000b
	byte    00000111b, 11100000b
	byte    00000111b, 11100000b
	byte    00000111b, 11100000b
	byte    00000111b, 11100000b
	byte    00000001b, 10000000b
	byte    00000000b, 00000000b
	byte    00000000b, 00000000b
	folderEnd       label	byte

	byte	GR_REL_MOVE_TO
	word	0, NTAKER_ICON_SPACING
	word	0, 0

	byte	GR_DRAW_TEXT_CP
	word	NTAKER_ICON_SPACING

FOLDER_ICON_THINGY_SIZE equ ($ - folderIconThingy)
.assert FOLDER_ICON_THINGY_SIZE eq ICON_THINGY_SIZE

.warn @inline_data

FileCode	ends
