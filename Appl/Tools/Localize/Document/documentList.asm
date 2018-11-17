COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Document	
FILE:		documentList.asm

AUTHOR:		Cassie Hartzog, Oct 14, 1992

ROUTINES:
	Name			Description
	----			-----------
	CreatePosArray		Going to a new resource, rebuild the PosArray 
	DocumentGetResourceName	The ResourceList is updating its monikers and 
				wants to get the name of the selected item. 
	DocumentGetChunkName	The ChunkList is updating its monikers and 
				wants to get the name of the selected item. 
	DocumentChangeResource	The current resource is changing, update the 
				visuals. Reinitialize the ChunkList with proper 
				number of items. 
	SetCurrentResourceInfo	Change the current resource info in the 
				document. 
	DocumentChangeChunk	User has selected a different chunk from the 
				ChunkList. 
	SetCurrentChunkInfo	The current chunk has changed. Update the 
				current chunk info in the document. Replace the 
				instruction text. 
	SetCurrentChunkInfoLow	The current chunk has changed, update the 
				ChunkType, Instruction, Min and Max UI. 
	ValueToAscii		Convert a numeric value to ascii. 
	InitializeEdit		The current chunk has changed, move the text 
				objects into position, change its text, and 
				prepare to be edited. 
	InitializeEditGraphics	New graphics chunk has become the target. Draw 
				it in inverse. 
	InitializeEditText	Initialize the EditText object for editing a 
				new chunk 
	InitializeOrigText	If the current target is the SourceView, 
				initialize the OrigText so it is the current 
				chunk. Give it the target. 
	InitializeTextCommon	Set the text object for editing. 
	InitializeMnemonicList	The current chunk has changed. If the new chunk 
				is text, set the REDI_mnemonicPos and 
				REDI_mnemonicCount fields and initialize the 
				mnemonic list. 
	InitializeKbdShortcut	The current chunk has changed. If the new chunk 
				is text, set the REDI_kbdShortcut field and 
				update the keyboard shortcut UI. 
	FinishEdit		Disables gadgets associated with current chunk. 
	ClearInstructionText	Remove instruction text. 
	FinishEditGraphics	Uninvert the selected graphics. 
	InitializeVisDrawParams	Fill VDP with data from document 
	EditGraphicsCommon	A graphics item is the current chunk. Draw it 
				in reverse mode to show that it is selected. 
	FinishEditText		Remove the selection, take focus and target 
				from text. 
	DocumentClearSelection	Clear any selection from current chunk item, 
				take target and focus from it. 
	DisableEditMenuTriggers	The edit operation is completing, disable 
				appropriate triggers. 
	MakeChunkVisible	Make sure the current chunk is visible. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/92	Initial revision


DESCRIPTION:
	This module contains handlers for the messages related to the
	functioning of the Resource and Chunk GenDynamicLists, as well
	as scrolling of the views.

	$Id: documentList.asm,v 1.1 97/04/04 17:14:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentListCode	segment resource


DocList_ObjMessage_send	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	GOTO	DocList_ObjMessage_common, di
DocList_ObjMessage_send	endp

DocList_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DocList_ObjMessage_common, di
DocList_ObjMessage_call		endp

DocList_ObjMessage_stack		proc	near
	push	di
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DocList_ObjMessage_common, di
DocList_ObjMessage_stack		endp

DocList_ObjMessage_common	proc	near
	call	ObjMessage
	FALL_THRU_POP	di
	ret	
DocList_ObjMessage_common	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePosArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Going to a new resource, rebuild the PosArray

CALLED BY:	(EXTERNAL) SetCurrentResourceInfo, AttachUIToDocument

PASS:		*ds:si 	= document object
		cx	= number of chunks

RETURN:		^hcx	= PosArray 
		carry set if could not allocate memory

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePosArray		proc	far
	uses 	ax,bx,dx,di
	.enter

	; calculate the size of the array
	mov	ax, size PosElement
	mul	cx
EC<	tst	ax						>
EC<	jnz	okay						>
EC<	mov	ax, 10						>
EC<okay:							>
	mov	cx, ALLOC_DYNAMIC
	DerefDoc
	mov	bx, ds:[di].REDI_posArray
	tst	bx
	jz	noHandle

	call	MemReAlloc			; ReAlloc current array

saveHandle:	
	mov	cx, bx
	.leave
	ret

noHandle:
	call	MemAlloc			; no PosArray yet allocated
	jmp	saveHandle

CreatePosArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGetResourceName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The ResourceList is updating its monikers and wants 
		to get the name of the selected item.

CALLED BY:	MSG_RESEDIT_DOCUMENT_GET_RESOURCE_NAME

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		bp - position of item requested
		^lcx:dx - the dynamic list

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGetResourceName		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_GET_RESOURCE_NAME

	; If we're in batch mode, we don't care about updating the UI.

		call	IsBatchMode
		jc	done

	push	ds:[LMBH_handle], si
	call	GetFileHandle
	call	DBLockMap_DS			; *ds:si = ResourceArray
	mov_tr	ax, bp				; ax <- item #
	mov	bp, cx				;^lbp:dx <- OD of list
	call	ChunkArrayElementToPtr
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	; calculate the length of the buffer, rounded up to a word
	; boundary so that swat can print it out correctly
	sub	cx, size ResourceMapElement	; cx = size of name
	mov	bx, cx
	add	bx, 2				; name + null + round
						; DBCS: name + null
SBCS <	andnf	bx, 0xfffe			; round to even value	>
DBCS <	test	bx, 1							>
DBCS <	ERROR_NZ	RESEDIT_IS_ODD					>

	; create a buffer to hold null-terminated name on the stack
	lea	si, ds:[di].RME_data.RMD_name	;ds:si <- source name
	sub	sp, bx
	mov	di, sp
	segmov	es, ss				;es:di <- dest buffer

	push	ax
DBCS <	shr	cx				;cx <- length of name	>
	LocalCopyNString
	clr	ax				;ax <- NULL
	LocalPutChar esdi, ax			;NULL terminate the string
	mov	di, bx				;di <- buffer size
	movdw	bxsi, bpdx			;^lbx:si <- OD of list
	pop	bp				;bp <- item #
	mov	cx, ss
	mov	dx, sp				;cx:dx = name string

	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	DocList_ObjMessage_call
	add	sp, di				;kill the string buffer
	call 	DBUnlock_DS

	pop	bx, si
	call	MemDerefDS

done:
	ret
DocumentGetResourceName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGetChunkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The ChunkList is updating its monikers and wants 
		to get the name of the selected item.

CALLED BY:	MSG_RESEDIT_DOCUMENT_GET_CHUNK_NAME

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		bp - position of item requested
		^lcx:dx - the dynamic list

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGetChunkName		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_GET_CHUNK_NAME

	; If no chunks, don't bother doing anything.

		tst	ds:[di].REDI_numChunks
		jz	done

	; If we're in batch mode, we don't care about updating the UI.

		call	IsBatchMode
		jc	done

	cmp	bp, ds:[di].REDI_numChunks			
	jae	done
	push	dx
EC <	cmp	bp, ds:[di].REDI_numChunks			
EC <	ERROR_AE	RESEDIT_OUT_OF_ARRAY_BOUNDS		>
	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter

	call	GetFileHandle
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_resArrayItem
	call	DBLock_DS			; *ds:si = ResourceArray

	mov	ax, bp				; ax <- item #
	mov	bp, cx				; ^lbp:dx = OD of list
	call	ResArrayElementToPtr		; ds:di <- element
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND				>
	pop	dx

	; calculate the length of the buffer, rounded up to a word
	; boundary so that swat can print it out correctly
	sub	cx, size ResourceArrayElement	; cx = size of name
	mov	bx, cx
	add	bx, 2				; name + null + round
						; DBCS: name + null
SBCS <	andnf	bx, 0xfffe			; round to even value	>
DBCS <	test	bx, 1							>
DBCS <	ERROR_NZ	RESEDIT_IS_ODD					>

	; create a buffer to hold null-terminated name on the stack
	lea	si, ds:[di].RAE_data.RAD_name	;ds:si <- source name
	sub	sp, bx
	segmov	es, ss
	mov	di, sp				;es:di <- dest buffer

	push	ax
DBCS <	shr	cx				;cx <- length of name	>
	LocalCopyNString
	clr	ax				;ax <- NULL
	LocalPutChar esdi, ax			;NULL terminate the string
	mov	di, bx				;di <- buffer length
	movdw	bxsi, bpdx			;^lbx:si <- OD of list
	pop	bp				;bp <- item #
	mov	cx, ss
	mov	dx, sp				;cx:dx = name string

	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	DocList_ObjMessage_call
	add	sp, di				;kill the string buffer
	call 	DBUnlock_DS

done:
	ret
DocumentGetChunkName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current resource is changing, update the visuals.
		Reinitialize the ChunkList with proper number of items.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE
	
PASS:		*ds:si - document object
		cx - resource number to change to

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
	Set REDI_curChunk to PA_NULL_ELEMENT, so that it is possible
	to change resources without having a current chunk.
	If and when CHANGE_CHUNK is called, the current chunk will be set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeResource		method  ResEditDocumentClass,	
				MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE

EC<		call	AssertIsResEditDocument				>

	; If we're in batch mode, we don't care about updating the UI.

		call	IsBatchMode
		LONG jc	exit		

		call	MarkBusyAndHoldUpInput

		cmp	cx, PA_NULL_ELEMENT
		LONG	je	done

		DerefDoc			;ds:di <- doc instance data

	; Set the current resource info in the document (calls FinishEdit)
	; and only THEN set curChunk to null.
	
		mov_tr	ax, cx			;ax <- current selection
		call	SetCurrentResourceInfo	
		mov	ds:[di].REDI_curChunk, PA_NULL_ELEMENT

		push	si
		mov	cx, ax
		clr	dx
		mov	bx, ds:[di].GDI_display
		mov	si, offset ResourceList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call 	DocList_ObjMessage_send

	; now initialize the list to have the new number of items,
	; make the first item be the one selected

		mov	cx, ds:[di].REDI_numChunks
		mov	bx, ds:[di].GDI_display
		mov	si, offset ChunkList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call 	DocList_ObjMessage_send

		tst	ds:[di].REDI_numChunks	;if no chunks, don't bother
		jz	noChunks		;  with setting ChunkList
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call 	DocList_ObjMessage_send

noChunks:

	; invalidate the old document so that it is undrawn	

		pop	si
		mov	ax, MSG_VIS_INVALIDATE
		call	SendToContentObjects

	; Calculate chunk positions for this resource, and set new doc size
	
		mov	cx, ds:[di].REDI_viewWidth
		tst	cx
		jz	done

		call	RecalcChunkPositions

	; Invalidate the new document so that it is drawn	

		mov	ax, MSG_VIS_INVALIDATE
		call	SendToContentObjects

	; scroll to the top of the document

		DerefDoc
		push	si
		mov	bx, ds:[di].GDI_display
		mov	si, offset RightView
		mov	ax, MSG_GEN_VIEW_SCROLL_TOP
		call 	DocList_ObjMessage_call
		pop	si

done:
		call	MarkNotBusyAndResumeInput
exit:
		ret

DocumentChangeResource		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentResourceInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the current resource info in the document.

CALLED BY:	INTERNAL

PASS:		ax	= element number of resource
		*ds:si 	= document
		ds:di 	= document 

RETURN:		cx	= number of chunks in this resource which
			  meet the filter criteria

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the resource changes, set the current chunk to 0.

	If we're being called, REDI_resourceGroup may be invalid.
	This happens just after an update.  FinishEdit might try
	to use REDI_resGroup to draw bitmaps or gstrings, so I added
	a flag to tell it not to		-- pld 11/8/94

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrentResourceInfo	proc	far
	uses	ax,bx,dx,di
	.enter

	; Save the changes, then mark state as changing resource so 
	; that subsequent calls to FinishEdit won't do it again.
	;
	push	ax
	mov	ax, 1		; don't try to use REDI_resourceGroup
	call	FinishEdit				;save any changes
	pop	ax
	ornf	ds:[di].REDI_state, mask DS_CHANGING_RESOURCE

	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter

	push	ds, si
	call	GetFileHandle
	call	DBLockMap_DS				;*ds:si = map block

	call	ChunkArrayElementToPtr			;ds:di <- ResMapElement
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	call	ResMapGetArrayCount			;cx <- # elements which
							; match current filters

	mov	bx, ds:[di].RME_data.RMD_group
	mov	dx, ds:[di].RME_data.RMD_item
	call	DBUnlock_DS

	pop	ds, si
	DerefDoc				;ds:di <- doc instance data
	mov	ds:[di].REDI_curResource, ax
	mov	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	mov	ds:[di].REDI_resourceGroup, bx
	mov	ds:[di].REDI_resArrayItem, dx
	mov	ds:[di].REDI_numChunks, cx

	call	ObjMarkDirty
	
 	tst	cx						
	jz	done

	; allocate and populate a new PosArray for this resource
	;
	call	CreatePosArray
	DerefDoc				;ds:di <- doc instance data
	mov	ds:[di].REDI_posArray, cx
	mov	cx, ds:[di].REDI_numChunks

done:	
	.leave
	ret

SetCurrentResourceInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has selected a different chunk from the ChunkList.

CALLED BY:	(EXTERNAL) MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK

PASS:		*ds:si - document object
		ds:di - instance data
		es - seg addr of ResEditDocumentClassClass
		ax - the message
		cx - chunk to go to 

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,es,ds,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeChunk		method  ResEditDocumentClass,	
				MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK

	; If we're in batch mode, don't do anything.

		call	IsBatchMode
		jc	noChunks
	
	; save any changes, end the editing operation
	
	clr	ax		; OK to use REDI_currentGroup
	call	FinishEdit
	tst	ds:[di].REDI_numChunks
	jz	noChunks

	;
	; set the new current chunk's information, make sure it
	; is visible and highlighted
	;
	mov	dx, ds:[di].REDI_curChunk	;dx <- old curChunk
	mov	ax, cx				;ax,cx <- new curChunk
	call	SetCurrentChunkInfo
	call	MakeChunkVisible		;make this chunk visible
	call	DocumentChangeHighlight
	push	si
	mov	cx, ds:[di].REDI_curChunk
	clr	dx
	mov	bx, ds:[di].GDI_display
	mov	si, offset ChunkList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call 	DocList_ObjMessage_send
	pop	si

	;
	; update the extra UI stuff (instruction, chunk type)
	; enable EditText.  Also initialize the mnemonic list.
	;
	mov	dl, ds:[di].REDI_curTarget
	call	InitializeEdit
	call	InitializeMnemonicList
	call	InitializeKbdShortcut

	ret

noChunks:
	mov	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	ret

DocumentChangeChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentChunkInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has changed.  Update the current chunk 
		info in the document.  Replace the instruction text.

CALLED BY:	INTERNAL - DocumentChangeChunk

PASS:		ax	= element number of chunk
		*ds:si	= document object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrentChunkInfo		proc	near
	uses 	ax,bx,cx,dx,ds,si,di,bp

	.enter

	DerefDoc				;ds:di <- doc instance data

	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter

	call	GetFileHandle
	mov	ds:[di].REDI_curChunk, ax
	cmp	ax, PA_NULL_ELEMENT
	LONG	je	noChunk

	;
	; get the chunk's information from the ResourceArray
	;
	push	ds, si
	push	ax
	mov	si, di
	mov	ax, ds:[si].REDI_resourceGroup
	mov	di, ds:[si].REDI_resArrayItem
	call	DBLock_DS			;*ds:si = ResourceArray
	pop	ax

	call	ResArrayElementToPtr		;ds:di = element
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	mov	ax, ds:[di].RAE_data.RAD_instItem
	mov	bx, ds:[di].RAE_data.RAD_transItem
	mov	bp, ds:[di].RAE_data.RAD_origItem
SBCS <	mov	dl, ds:[di].RAE_data.RAD_chunkType			>
DBCS <	mov	ch, ds:[di].RAE_data.RAD_chunkType	;use dx for char>
	mov	cl, ds:[di].RAE_data.RAD_mnemonicType
SBCS <	mov	ch, ds:[di].RAE_data.RAD_mnemonicChar			>
DBCS <	mov	dx, ds:[di].RAE_data.RAD_mnemonicChar			>
	mov	di, ds:[di].RAE_data.RAD_kbdShortcut
	
	call	DBUnlock_DS

	pop	ds, si
	push	di
	DerefDoc

setInfo:
	mov	ds:[di].REDI_transItem, bx
	mov	ds:[di].REDI_origItem, bp
SBCS <	mov	ds:[di].REDI_chunkType, dl				>
DBCS <	mov	ds:[di].REDI_chunkType, ch				>
	mov	ds:[di].REDI_mnemonicType, cl	;original mnemonic type
SBCS <	mov	ds:[di].REDI_mnemonicChar, ch				>
DBCS <	mov	ds:[di].REDI_mnemonicChar, dx				>
	clr	ds:[di].REDI_mnemonicPos
	clr	ds:[di].REDI_mnemonicCount
	clr	ds:[di].REDI_mnemonicCount
	pop	ds:[di].REDI_kbdShortcut

	call	SetCurrentChunkInfoLow

	mov	al, ds:[di].REDI_newTarget
	mov	ds:[di].REDI_curTarget, al

	call	ObjMarkDirty
	
	.leave
	ret

noChunk:
	;
	; there is no ChunkType, origItem, transItem, or instItem
	;
	clr	ax,bx,cx,dx,bp
	push	ax				; push kbdShortcut on stack
	jmp 	setInfo

SetCurrentChunkInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentChunkInfoLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has changed, update the ChunkType,
		Instruction, Min and Max UI.

CALLED BY:	SetCurrentChunkInfo

PASS:		*ds:si	- document instance data
		ds:di	-  "
		ax	- instruction item number

RETURN:		nothing

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	NoText,	<' ',0>

SetCurrentChunkInfoLow		proc	near
	uses	dx,si,di,bp
	.enter

EC <	call	AssertIsResEditDocument				>
	call	GetFileHandle
	mov	dx, bx				;^hdx = file handle
	push	bx

	;
	; First, replace the instruction.
	;
	mov	bx, ds:[di].GDI_display
	mov	si, offset InstructionText	;^lbx:si = InstructionText

	mov	cx, ax
	tst	ax
	jz	noInstruction

	mov	bp, ds:[di].REDI_resourceGroup
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_DB_ITEM
	jmp	replaceInst

noInstruction:
	mov	dx, cs
	mov	bp, offset NoText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
replaceInst:
	call	DocList_ObjMessage_call
	pop	bx

	;
	; Second, replace the minimum and maximum size strings.
	;
	call	GetMinMaxValues			;cl <- min, dl <- max
	mov	bx, ds:[di].GDI_display
	mov	ax, cx
	or	ax, dx
	jz	noMinMax

SBCS <	sub	sp, 4							>
DBCS <	sub	sp, 8							>
	mov	bp, sp
	push	dx	
	mov	dx, ss
	call	ValueToAscii			;dx:bp <- min value
	clr	cx
	mov	si, offset MinText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocList_ObjMessage_call
	pop	cx

	mov	dx, ss
	mov	bp, sp
	call	ValueToAscii			;dx:bp <- max value
	clr	cx
	mov	si, offset MaxText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocList_ObjMessage_call

SBCS <	add	sp, 4							>
DBCS <	add	sp, 8							>
	jmp	chunkType

noMinMax:
	mov	dx, cs
	mov	bp, offset NoText
	mov	si, offset MinText
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocList_ObjMessage_call

	mov	dx, cs
	mov	bp, offset NoText
	mov	si, offset MaxText
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DocList_ObjMessage_call

chunkType:
	;
	;  Thirdly, update the chunk type.
	;
	mov	cl, ds:[di].REDI_chunkType

	;
	; if no current chunk, delete the chunk type text
	;
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	je	deleteChunkType

	;
	; replace the chunk type text, based on al
	;
	GetResourceHandleNS	StringsUI, dx

	mov	bp, offset TypeUnparseable
	test	cl, mask CT_NOT_EDITABLE
	jnz	replace

	test	cl, mask CT_MONIKER
	jz	checkText
	test	cl, mask CT_TEXT
	jz	checkGStringMoniker
	mov	bp, offset TypeTextMoniker		;^ldx:bp <- string
	jmp	replace

checkGStringMoniker:
EC<	test	cl, mask CT_GSTRING			>
EC<	ERROR_Z	BAD_CHUNK_TYPE			>
	mov	bp, offset TypeGStringMoniker		;^ldx:bp <- string
	jmp	replace

checkText:
	test	cl, mask CT_TEXT
	jz	checkGString
	mov	bp, offset TypeText			;^ldx:bp <- string
	jmp	replace

checkGString:
	test	cl, mask CT_GSTRING
	jz	checkBitmap
	mov	bp, offset TypeGString			;^ldx:bp <- string
	jmp	replace

checkBitmap:
	test	cl, mask CT_BITMAP
	jz	checkObject
	mov	bp, offset TypeBitmap			;^ldx:bp <- string
	jmp	replace

checkObject:
EC<	test	cl, mask CT_OBJECT				>
EC<	ERROR_Z	BAD_CHUNK_TYPE				>
	mov	bp, offset TypeObject			;^ldx:bp <- string

replace:
	clr	cx					;null-terminated string
	mov	si, offset ChunkTypeText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	call	DocList_ObjMessage_call
done:
	.leave
	ret

deleteChunkType:
	mov	dx, cs
	mov	bp, offset NoText
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, ds:[di].GDI_display
	mov	si, offset ChunkTypeText
	call	DocList_ObjMessage_call
	jmp	done

SetCurrentChunkInfoLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a numeric value to ascii.

CALLED BY:	SetCurrentInfo
PASS:		dx:bp	- buffer to put ascii in
		cl	- value to convert
RETURN:		dx:bp	- unchanged
DESTROYED:	ax,cx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValueToAscii		proc	near
	uses	dx,di
	.enter

	mov	es, dx
	mov	di, bp
	mov	dl, cl
	clr	dh
	clr	ax, cx				;no fraction part
	call	LocalFixedToAscii

	.leave
	ret
ValueToAscii		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InitializeEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has changed, move the text 
		objects into position, change its text, and
		prepare to be edited.

CALLED BY:	DocumentChangeChunk, VisDrawCommon

PASS:		*ds:si	- document
		dl - SourceType of view to be initialized

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeEdit		proc	far
	uses 	cx,dx,si,di,bp
	.enter

	; If there is no current chunk (as when displaying a 
	; resource that has none), don't do anything
	
		DerefDoc
		cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
		LONG	je	done

	; If current chunk is an object, it can't be edited.  Do nothing.

		test	ds:[di].REDI_chunkType, mask CT_OBJECT
		LONG	jnz	done

	; If chunk is not visible, do nothing.

		mov	ax, ds:[di].REDI_curChunk
		call	IsChunkVisible
		cmp	cl, VT_NOT_VISIBLE
		LONG	je	done
EC <		call	AssertIsResEditDocument				>

	; Set up the VisDrawParams 
	
		sub	sp, VisDrawParams
		mov	bp, sp
		call	InitializeVisDrawParams
EC <		call	AssertIsResEditDocument				>

	; Use the passed SourceType instead of the value set in 
	; InitializeVisDrawParams.
	
		mov	ss:[bp].VDP_data.SDP_sourceType, dl
 
	; If this is graphics, skip all this text stuff
	
		test	ds:[di].REDI_chunkType, CT_GRAPHICS
		jnz	initializeGraphics

	; Copy the maximum length to the VisDrawParams.

		mov	bx, ss:[bp].VDP_data.SDP_file
		call	GetMinMaxValues			; dx <- max length
		mov	ss:[bp].VDP_data.SDP_maxLength, dx
EC <		call	AssertIsResEditDocument				>

	; Store the mnemonic information
	
		mov	al, ds:[di].REDI_mnemonicType
		mov	ss:[bp].VDP_data.SDP_mnemonicType, al

SBCS <		mov	al, ds:[di].REDI_mnemonicChar			>
DBCS <		mov	ax, ds:[di].REDI_mnemonicChar			>
SBCS <		mov	ss:[bp].VDP_data.SDP_mnemonicChar, al		>
DBCS <		mov	ss:[bp].VDP_data.SDP_mnemonicChar, ax		>

	; Ignore height changes caused by setting up OrigText/EditText

		ornf	ds:[di].REDI_state, mask DS_IGNORE_HEIGHT_CHANGES

	; Set up OrigText and EditText.

		call	InitializeEditText
EC <		call	AssertIsResEditDocument				>
		call	InitializeOrigText
EC <		call	AssertIsResEditDocument				>

	; Want to receive subsequent height changes (caused by editing).

		andnf	ds:[di].REDI_state, \
			not (mask DS_IGNORE_HEIGHT_CHANGES)

	; Get the source type.

		mov	al, ss:[bp].VDP_data.SDP_sourceType

	; Deallocate the VisDrawParams off the stack.

		add	sp, VisDrawParams

	; If the correct object already has the target, don't bother
	; grabbing it.

		push	si
		cmp	al, ds:[di].REDI_curTarget
		jne	noGrab

	; Get the object that should get the focus.

		movdw	bxsi, ds:[di].REDI_editText
		cmp	al, ST_TRANSLATION
		je	haveObject
		mov	si, offset OrigText

haveObject:

	; Give the text object the target and focus.

		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		call	DocList_ObjMessage_send

		mov	ax, MSG_META_GRAB_TARGET_EXCL
		call	DocList_ObjMessage_send

noGrab:
	pop	si
EC <	call	AssertIsResEditDocument				>

done:
	call	SetEditMenuState

	.leave
	ret

initializeGraphics:
	;
	; If not in current target, don't draw it
	;
	cmp	dl, ds:[di].REDI_curTarget
	jne	noInvert
	mov	al, MM_INVERT
	call	EditGraphicsCommon
EC <	call	AssertIsResEditDocument				>
noInvert:
	add	sp, VisDrawParams
	jmp	done

InitializeEdit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeEditGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	New graphics chunk has become the target. 
		Draw it in inverse.

CALLED BY:	EXTERNAL - 
PASS:		*ds:si - document
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeEditGraphics		proc	far
	.enter
	;
	; set up the VisDrawParams for DrawGraphics call
	;
	sub	sp, size VisDrawParams
	mov	bp, sp

	call	InitializeVisDrawParams

	mov	al, MM_INVERT
	call	EditGraphicsCommon
	add	sp, size VisDrawParams

	.leave
	ret
InitializeEditGraphics		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeEditText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the EditText object for editing a new chunk

CALLED BY: 	InitializeEdit
PASS:		*ds:si	- document instance data
		ss:bp	- SetDataParams

RETURN:		^lbx:cx - EditText
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Put the text from the current chunk in EditText, make it
	both editable and selectable, and give it the focus so it
	will receive keyboard events.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Must be called before InitializeMnemonicList.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeEditText	proc	near
	uses	si, bp
	.enter

	add	bp, offset VDP_data

	DerefDoc
	mov	ax, ds:[di].REDI_transItem	
	tst	ax				;is there a translation?
	jnz	haveItem			;no, so use original
	mov	ax, ds:[di].REDI_origItem	
	
haveItem:
	mov	ss:[bp].SDP_item, ax
	
	movdw	bxcx, ds:[di].REDI_editText
	call	InitializeTextCommon

	.leave
	ret
InitializeEditText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeOrigText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the current target is the SourceView, initialize
		the OrigText so it is the current chunk.  Give it the
		target.
	
CALLED BY: 	InitializeEdit

PASS:		*ds:si	- document instance data
		ss:bp	- SetDataParams

RETURN:		^lbx:cx - EditText
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Put the text from the current original item in OrigText.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeOrigText		proc	near
	uses	si, bp
	.enter

	add	bp, offset VDP_data

	; if there is no transItem, the mnemonic info stored in 
	; SetDataParams is from the original item
	;
	DerefDoc
	tst	ds:[di].REDI_transItem
	jz	haveMnemonic

	; get the current filters, lock the resource array and 
	; get a pointer to the current element
	;
	push	si, ds:[LMBH_handle]
	push	ds:[di].REDI_curChunk
	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_resArrayItem
	mov	bx, ss:[bp].SDP_file
	call	DBLock_DS
	pop	ax
	call	ResArrayElementToPtr		; ds:di <- element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND		>

	; 
	; get the mnemonic for the item
	; pass ss:bp - SetDataParams, bx - original item number
	;
	mov	bx, ds:[di].RAE_data.RAD_origItem
	mov	ss:[bp].SDP_item, bx
	call	GetMnemonicFromOriginalItem	;cl <-mnemType, ch <- mnemChar
						;in DBCS:	dx <- mnemChar 
	call	DBUnlock_DS
	mov	ss:[bp].SDP_mnemonicType, cl
SBCS <	mov	ss:[bp].SDP_mnemonicChar, ch				>
DBCS <	mov	ss:[bp].SDP_mnemonicChar, dx				>

	pop	si, bx
	call	MemDerefDS
	DerefDoc				; ds:di <- doc instance data

haveMnemonic:
	;
	; make the text object not drawable while setting the new text
	;
	mov	bx, ds:[di].REDI_editText.handle
	mov	cx, offset OrigText
	call	InitializeTextCommon

	.leave
	ret
InitializeOrigText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text object for editing.

CALLED BY:	InitializeEditText, InitializeOrigText
PASS:		ds:di	- document
		^lbx:cx	- text object to initialize
		ss:bp	- SetDataParams
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeTextCommon		proc	far
	uses	bx,cx,si,bp
	.enter

	mov	si, cx
	clr	cl	
	mov	ch, mask VA_DRAWABLE		;clear the drawable bit
	mov	ax, MSG_RESEDIT_TEXT_SET_ATTRS
	call	DocList_ObjMessage_call

	; put the new text in the object
	;
	mov	dx, size SetDataParams
	mov	ax, MSG_RESEDIT_TEXT_SET_TEXT
	call	DocList_ObjMessage_stack

	; set the mnemonic underline 
	;
	mov	ax, MSG_RESEDIT_TEXT_SET_MNEMONIC_UNDERLINE
	call	DocList_ObjMessage_stack

	mov	cl, mask VA_DRAWABLE		;set the drawable bit
	clr	ch
	mov	ax, MSG_RESEDIT_TEXT_SET_ATTRS
	call	DocList_ObjMessage_call

	sub	bp, offset VDP_data
	mov	dl, ss:[bp].VDP_data.SDP_sourceType
	cmp	dl, ds:[di].REDI_curTarget
	jne	skipThisDraw
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	DocList_ObjMessage_call
skipThisDraw:
		
	.leave
	ret
InitializeTextCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeMnemonicList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has changed.  If the new chunk is
		text, set the REDI_mnemonicPos and REDI_mnemonicCount
		fields and initialize the mnemonic list.

CALLED BY:	(EXTERNAL) DocumentChangeChunk, VisDrawCommon

PASS:		*ds:si	- document

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Let the ENABLE_MNEMONIC_LIST save the new mnemonic position
	in the document's instance data.  Doing it here is a bad idea,
	because it throws the list and internal document state out of sync.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeMnemonicList		proc	far
	uses	ax,bx,cx,dx
	.enter

	DerefDoc
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	je	done
	tst	ds:[di].REDI_numChunks
	jz	done

	; if this is a moniker, set the mnemonicPos correctly
	;
	mov	al, 0
	cmp	ds:[di].REDI_chunkType, mask CT_MONIKER or mask CT_TEXT
	jne	done

	;
	; get the number of mnemonic chars and calculate the position
	; of this mnemonic in the list
	;
	call	GetMnemonicCount
	mov	ds:[di].REDI_mnemonicCount, cl

	mov	al, ds:[di].REDI_mnemonicType
	call	GetMnemonicPosition
	mov	ds:[di].REDI_mnemonicPos, al

	; 
	; enable and initialize the mnemonic list
	;
	mov	ax, MSG_RESEDIT_DOCUMENT_ENABLE_MNEMONIC_LIST
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

InitializeMnemonicList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has changed.  If the new chunk is
		text, set the REDI_kbdShortcut field and update the
		keyboard shortcut UI.

CALLED BY:	EXTERNAL (DocumentChangeChunk, DocumentRevertToOriginalItem)

PASS:		*ds:si	- document

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeKbdShortcut		proc	far
	uses	ax,bx,cx
	.enter

	DerefDoc
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	je	done
	tst	ds:[di].REDI_numChunks
	jz	done

	; if this is not an object chunk, we're done
	;
	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	jz	done

	; 
	; enable and initialize the keyboard shortcut UI
	;
	mov	ax, MSG_RESEDIT_DOCUMENT_ENABLE_KBD_SHORTCUT
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
InitializeKbdShortcut		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables gadgets associated with current chunk.

CALLED BY:	(INT) SetCurrentResourceInfo, SetCurrentChunkInfo

PASS:		*ds:si	- document
		ax	- set if REDI_currentGroup is invalid

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishEdit	proc 	near
	uses	ax,cx,dx,si,di
	.enter

	; if there is no current chunk (as when displaying a 
	;  resource that has none), don't do anything
	;
	DerefDoc
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	je	done

	; if this is set, FinishEdit has been called, no need to save again
	;
	test	ds:[di].REDI_state, mask DS_CHANGING_RESOURCE
	jnz	done

	; disable the appropriate edit menu triggers
	;
	call	DisableEditMenuTriggers

	push	ax
	call	ClearInstructionText
	pop	ax

	DerefDoc
	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	jnz	graphics
	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	jnz	object
	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	done

	call	FinishEditText

	; empty and disble the Mnemonic list, if this is a moniker
	;
	cmp	ds:[di].REDI_chunkType, mask CT_MONIKER
	jz	done
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_RESEDIT_DOCUMENT_DISABLE_MNEMONIC_LIST
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

object:
	mov	ax, MSG_RESEDIT_DOCUMENT_DISABLE_KBD_SHORTCUT
	call	ObjCallInstanceNoLock
	jmp	done

graphics:
	call	FinishEditGraphics
	jmp	done

FinishEdit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearInstructionText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove instruction text.

CALLED BY:	FinishEdit
PASS:		*ds:si - document
		ds:di - document
RETURN:		nothing
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearInstructionText		proc	near
	uses	si
	.enter

	call	GetDisplayHandle
	mov	si, offset InstructionText
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	clr	di
	call	ObjMessage

	.leave
	ret
ClearInstructionText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishEditGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uninvert the selected graphics.

CALLED BY:	FinishEdit, GrabTargetAndFocus
PASS:		*ds:si - document
		ds:di - document
		ax	- set if REDI_currentGroup is invalid
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ax is a hack to keep things from being drawn after an update has
	taken place -- REDI_resourceGroup will be pointing to an invalid
	group, because it has not yet been updated (it will be updated 
	once we return to 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishEditGraphics		proc	far
	uses	ax
	.enter

	tst	ax
	jnz	done		; don't try to draw, because
				; REDI_currentGroup is invalid
	mov	ax, ds:[di].REDI_curChunk
	call	IsChunkVisible
	cmp	cl, VT_NOT_VISIBLE
	je	done

	;
	; set up the VisDrawParams for DrawGraphics call
	;
	sub	sp, VisDrawParams
	mov	bp, sp

	mov	al, ds:[di].REDI_curTarget
	
	call	InitializeVisDrawParams

	mov	al, MM_COPY
	call	EditGraphicsCommon
	add	sp, size VisDrawParams

done:
	.leave
	ret
FinishEditGraphics		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeVisDrawParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill VDP with data from document

CALLED BY:	FinishEditGraphics, InitializeEdit
PASS:		*ds:si - document
		ss:bp - VisDrawParams
RETURN:		
DESTROYED:	ax,bx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeVisDrawParams		proc	near
	uses	si,dx
	.enter
	call	GetFileHandle
	mov	ss:[bp].VDP_data.SDP_file, bx

	; save resource & chunk information
	;
	mov	ax, ds:[di].REDI_resourceGroup
	mov	ss:[bp].VDP_data.SDP_group, ax
	mov	al, ds:[di].REDI_chunkType
	mov	ss:[bp].VDP_data.SDP_chunkType, al
	mov	al, ds:[di].REDI_curTarget
	mov	ss:[bp].VDP_data.SDP_sourceType, al

getPosition::
	; lock PosArray, get pointer to this chunk's PosElement
	;
	mov	bx, ds:[di].REDI_posArray
	mov	ax, ds:[di].REDI_curChunk
	mov	dl, size PosElement
	mul	dl
	mov	si, ax
	call	MemLock
	mov	es, ax					;es:si <- PosElement

	; store chunk positioning information
	;
	mov	ss:[bp].VDP_data.SDP_left, SINGLE_BORDER_SIZE	
	mov	ss:[bp].VDP_data.SDP_border, SINGLE_BORDER_SIZE	
	mov	ax, es:[si].PE_top		
	mov	ss:[bp].VDP_data.SDP_top, ax		;top position of 
	mov	ax, es:[si].PE_height	
	mov	ss:[bp].VDP_data.SDP_height, ax		;height of chunk
	mov	ax, ds:[di].REDI_viewWidth
	sub	ax, TOTAL_BORDER_SIZE
	mov	ss:[bp].VDP_data.SDP_width, ax		;width of view
	call	MemUnlock

	.leave
	ret
InitializeVisDrawParams		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditGraphicsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A graphics item is the current chunk.  Draw it in
		reverse mode to show that it is selected.

CALLED BY:	InitializeEditGraphics, FinishEditGraphics
PASS:		ss:bp - VisDrawParams
		*ds:si - document
		ds:di - document
		al - MM_COPY if called by FinishEditGraphics,
		   - MM_INVERT if called by InitializeEditGraphics
			
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditGraphicsCommon		proc	near
	uses	si
	.enter

	push	ds:[LMBH_handle], si		; Save document.
	push	ax				; save the MixMode
	DerefDoc

	;
	; Get the object who should create the gstate, and get
	; the item which will be drawn.
	;
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- document
	mov	ax, ds:[di].REDI_transItem	
	tst	ax
	jnz	haveItem
	mov	ax, ds:[di].REDI_origItem	
haveItem:
	cmp	ss:[bp].VDP_data.SDP_sourceType, ST_TRANSLATION
	je	getGState
	mov	ax, ds:[di].REDI_origItem	
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset OrigContent		; ^lbx:si <- OrigContent

getGState:
	mov	ss:[bp].VDP_data.SDP_item, ax

	push	bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	di, bp
	pop	bp

	mov	ss:[bp].VDP_gstate, di
	pop	ax				; al <- MixMode
	call	GrSetMixMode

	;
	; If this was called by FinishEdit (MixMode is COPY, not INVERT)
	; we first need to clear the rectangle before drawing the graphic
	;
	push	ax
	cmp	al, MM_COPY
	jne	notWhite
	mov	ah, CF_INDEX
	mov	al, C_WHITE			;draw a white rectangle
	call	GrSetAreaColor

notWhite:
	mov	ax, ss:[bp].VDP_data.SDP_left	;x position
	mov	cx, ax
	add	cx, ss:[bp].VDP_data.SDP_width
	sub	cx, SELECT_LINE_WIDTH

	mov	bx, ss:[bp].VDP_data.SDP_top	;y position
	mov	dx, bx
	add	dx, ss:[bp].VDP_data.SDP_height
	inc	dx
	add	bx, SELECT_LINE_WIDTH
	mov	di, ss:[bp].VDP_gstate
	call	GrFillRect

	mov	ah, CF_INDEX
	mov	al, C_BLACK			;return to black area color
	call	GrSetAreaColor
	pop	ax

	;
	; If called by InitializeEdit, don't need to redraw the graphic
	;
	cmp	al, MM_INVERT
	je	destroyGState
	call	DrawGraphics

destroyGState:
	call	GrDestroyState

	; Restore document.
	;
	pop	bx, si
	call	MemDerefDS
	DerefDoc

	.leave
	ret
EditGraphicsCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishEditText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the selection, take focus and target from text.

CALLED BY:	(EXT) FinishEdit, GrabTargetAndFocus

PASS:		*ds:si	- document instance data

RETURN:		nothing

DESTROYED:	cx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishEditText		proc	far
	uses	ax,bx,bp,si
	.enter

	; if current chunk is not visible, don't bother
	; clearing selection, because it can't be seen anyways
	;
	DerefDoc
	mov	ax, ds:[di].REDI_curChunk
	cmp	ax, PA_NULL_ELEMENT
	je	done
	call	IsChunkVisible
	cmp	cl, VT_NOT_VISIBLE
	je	takeTarget

	; unselect everything by moving cursor to end of selected text
	; 
	push	si
	movdw	bxsi, ds:[di].REDI_editText
	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	je	haveChunk
	mov	si, offset OrigText
haveChunk:
	mov	ax, MSG_VIS_TEXT_SELECT_END
	call	DocList_ObjMessage_send
	pop	si

takeTarget:
	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	jne	original

	; take the target and focus away from EditText 
	;
	movdw	cxdx, ds:[di].REDI_editText
	mov	bp, mask MAEF_FOCUS or mask MAEF_TARGET
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	jmp	done

original:
	; take target and focus away from OrigText
	;
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset OrigText
	mov	ax, MSG_META_RELEASE_FT_EXCL
	call	DocList_ObjMessage_call

done:
	.leave
	ret
FinishEditText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentClearSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear any selection from current chunk item, take
		target and focus from it.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CLEAR_SELECTION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		nothing
DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentClearSelection		method ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_CLEAR_SELECTION
	uses	cx, dx
	.enter

	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	notText
	call	FinishEditText

done:
	.leave
	ret

notText:
	call	FinishEditGraphics
	jmp	done
DocumentClearSelection		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableEditMenuTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The edit operation is completing, disable appropriate
		triggers.

CALLED BY:	FinishEdit
PASS:		*ds:si	- document
		ds:di	- document

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableEditMenuTriggers		proc	near
	uses	ax,bx,dx,si,di
	.enter

	mov	al, BB_FALSE
	mov	bl, al
	mov	bh, al
	mov	cx, SDT_TEXT
	call	DocumentNotifySelectStateChange

	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	.leave
	ret
DisableEditMenuTriggers		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeChunkVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the current chunk is visible.

CALLED BY:	MSG_RESEDIT_DOCUMENT_MAKE_CHUNK_VISIBLE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - chunk number

RETURN:		nothing
		carry set if scroll took place

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeChunkVisible		method ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_MAKE_CHUNK_VISIBLE
		uses	cx, dx, si
		.enter

	; Don't do anything if we're in batch mode.

		call	IsBatchMode
		cmc
		jnc	done


	; if the entire chunk is visible, don't need to scroll

		mov	ax, cx
		call	IsChunkVisible
		cmp	cl, VT_ALL_VISIBLE
		clc
		je	done
		call	GetChunkBounds		;cx <-top, dx <-bottom

		push	bp
		sub	sp, size MakeRectVisibleParams
		mov	bp, sp

	; clear the high part of the bounds dwords
		clr	ss:[bp].MRVP_bounds.RD_top.high
		clr	ss:[bp].MRVP_bounds.RD_left.high
		clr	ss:[bp].MRVP_bounds.RD_bottom.high
		clr	ss:[bp].MRVP_bounds.RD_right.high

	; stuff the rectangle bounds
		mov	ss:[bp].MRVP_bounds.RD_top.low, cx
		clr	ss:[bp].MRVP_bounds.RD_left.low
		mov	ss:[bp].MRVP_bounds.RD_bottom.low, dx
		mov	ax, ds:[di].REDI_viewWidth
		mov	ss:[bp].MRVP_bounds.RD_right.low, ax

	; scroll and center the rectangle
		mov	ss:[bp].MRVP_xMargin, MRVM_50_PERCENT
		mov	ss:[bp].MRVP_yMargin, MRVM_50_PERCENT
		clr	ss:[bp].MRVP_xFlags
		clr	ss:[bp].MRVP_yFlags

		mov	bx, ds:[di].GDI_display
		mov	si, offset RightView
		mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
		mov	dx, size MakeRectVisibleParams
		call	DocList_ObjMessage_stack
		add	sp, size MakeRectVisibleParams
		pop	bp	
		stc
done:
		.leave
		ret
MakeChunkVisible		endm

DocumentListCode		ends
