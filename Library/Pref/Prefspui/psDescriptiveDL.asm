COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Pref
MODULE:		Prefspui
FILE:		psDescriptiveDL.asm

AUTHOR:		David Litwin, Sep 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94   	Initial revision


DESCRIPTION:
	code for the PSDescriptiveDLClass object
		

	$Id: psDescriptiveDL.asm,v 1.1 97/04/05 01:43:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDDLPrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create our chunk array for descriptive text.

CALLED BY:	MSG_PREF_INIT
PASS:		*ds:si	= PSDescriptiveDLClass object
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDDLPrefInit	method dynamic PSDescriptiveDLClass, 
					MSG_PREF_INIT
	uses	ax, cx
	.enter

EC<	mov	ax, ATTR_GEN_PATH_DATA					>
EC<	call	ObjVarFindData						>
EC<	WARNING_NC	WARNING_PSDL_BAD_SEARCH_PATH			>
EC<	cmp	ds:[bx].GFP_disk, SP_TOP				>
EC<	WARNING_NE	WARNING_PSDL_BAD_SEARCH_PATH			>

	;
	; create our chunk array for storing the description text.
	; create it in the PrefSpuiStrings resource.
	;
	push	ds, si
	mov	bx, handle PrefSpuiStrings
	call	MemLock
	mov	ds, ax

	clr	ax				; no flags
	mov	bx, ax				; variable sized elements
	mov	cx, ax				; no header
	mov	si, ax				; give us a chunk
	call	ChunkArrayCreate
EC<	ERROR_C	ERROR_CANT_I_EVEN_ALLOCATE_A_SIMPLE_BLOCK	>
	mov	ax, si				; new chunk in ax
	pop	ds, si

	mov	di, ds:[si]
	add	di, ds:[di].PSDescriptiveDL_offset
	mov	ds:[di].PSDDLI_descTextArray, ax
	mov	bx, handle PrefSpuiStrings
	call	MemUnlock

	;
	; Don't call our superclass until after the chunk array has been
	; allocated, because our superclass init's the list which calls
	; to us and we will assume it has already been created.
	;
	mov	ax, MSG_PREF_INIT
	mov	di, offset PSDescriptiveDLClass
	call	ObjCallSuperNoLock

	.leave
	ret
PSDDLPrefInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDDLInitItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the description text from the demo .ini file and
		stuff it into our ChunkArray.

CALLED BY:	MSG_PSDL_INIT_ITEM
PASS:		*ds:si	= PSDescriptiveDLClass object
		ax	= message #
		ss:bp	inherited stack frame from PSDLGetItemInfo
RETURN:		bp	= same as passed
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDDLInitItem	method dynamic PSDescriptiveDLClass, 
					MSG_PSDL_INIT_ITEM
	.enter	inherit PSDLGetItemInfo

	mov	di, offset PSDescriptiveDLClass
	call	ObjCallSuperNoLock

	mov	es, ss:[iniBufSptr]
	mov	cx, ss:[iniBufNumChars]
	segmov	ds, cs, si
	mov	si, offset demoCategory
	call	PSDLFindCategory
	jc	useDefault

	mov	si, offset descriptionText
	call	PSDLFindKey
	jnc	gotText

	;
	; the descriptionText key wasn't found, so null out the entry,
	; and when setting the text object we will use a default string.
	;
useDefault:
	segmov	es, cs, di
	mov	di, offset nullPtr
SBCS<	mov	bx, size char						>
DBCS<	mov	bx, size wchar						>

gotText:
	mov	cx, bx				; put text length in cx
	lds	si, ss:[objPtr]			; restore our object
	mov	si, ds:[si]
	add	si, ds:[si].PSDescriptiveDL_offset
	mov	si, ds:[si].PSDDLI_descTextArray
	mov	bx, handle PrefSpuiStrings
	call	MemLock
	mov	ds, ax
	mov	bx, di
	mov	ax, cx				; element length
	call	ChunkArrayAppend
	jc	skipCopy

	segxchg	ds, es				; es:di is our chunk element
	mov	si, bx				; ds:si is our data
	LocalCopyNString
	clc

skipCopy:
	mov	bx, handle PrefSpuiStrings
	call	MemUnlock

	.leave
	ret
PSDDLInitItem	endm

LocalDefNLString	descriptionText	<'descriptionText', 0>
LocalDefNLString	nullPtr		<0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDDLItemSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An item was selected, so fill our text object with the
		description text in our ChunkArray.

CALLED BY:	MSG_PSDDL_ITEM_SELECTED
PASS:		*ds:si	= PSDescriptiveDLClass object
		ds:di	= PSDescriptiveDLClass instance data
		cx	= current selection
		dl	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDDLItemSelected	method dynamic PSDescriptiveDLClass, 
					MSG_PSDDL_ITEM_SELECTED
	.enter

	cmp	cx, GIGS_NONE
	je	exit

	pushdw	ds:[di].PSDDLI_descTextObj	; save for later message send

	mov	si, ds:[di].PSDDLI_descTextArray
	mov	bx, handle PrefSpuiStrings
	call	MemLock				; lock down chunk array's block
	mov	ds, ax

	mov	ax, cx				; element #
	call	ChunkArrayElementToPtr		; returns cx as size
	jc	unlock

	;
	; if the text is null, then we should use the default
	; text, cleverly in the same resource...
	;
	LocalIsNull	ds:[di]
	jnz	gotText

	mov	di, offset PrefSpuiDefaultDescriptionText
	mov	di, ds:[di]
	ChunkSizePtr	ds, di, cx
	dec	cx				; don't include null

gotText:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	popdw	bxsi				; bx:si is our text obj
	movdw	dxbp, dsdi			; dx:bp is our desc. text
	clr	di
	call	ObjMessage

unlock:
	mov	bx, handle PrefSpuiStrings
	call	MemUnlock			; unlock text's block

exit:
	.leave
	ret
PSDDLItemSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDDLApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the correct ini string and reboot.

CALLED BY:	MSG_PSDDL_APPLY
PASS:		*ds:si	= PSDescriptiveDLClass object
		ds:di	= PSDescriptiveDLClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	The GenPathData of this object is assumed to have SP_TOP as its
	diskhandle, and will issue a SWAT warning if it doesn't.  On this
	assumption, we just copy the relative path and add the .ini file
	name to the end when constructing the ini file to link to.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDDLApply	method dynamic PSDescriptiveDLClass, 
					MSG_PSDDL_APPLY
pathBuf	local	PathName
	.enter

	;
	; build object's path into buffer
	;
	push	si
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
EC<	WARNING_NC	WARNING_PSDL_BAD_SEARCH_PATH	>
	jnc	errorExit

	lea	si, ds:[bx].GFP_path		; ds:si is our relative path
	segmov	es, ss, di
	lea	di, ss:[pathBuf]		; es:di is our buffer

	LocalCopyString
	LocalPrevChar	esdi			; back up over null
	LocalLoadChar	ax, C_BACKSLASH
	LocalPutChar	esdi, ax
	pop	si

	;
	; Append on the .ini file name
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	mov	dx, ds:[bx].GIGI_selection
	mov	al, size NameAndLabel
	mul	dl			; assume selection <= 255
CheckHack< (offset NAL_filename) eq 0 >
	mov	dx, ax			; dx = our nptr to the selected filename

	mov	bx, ds:[si]
	add	bx, ds:[bx].PSDescriptiveDL_offset
	mov	bx, ds:[bx].PSDLI_nameArray
	push	ds
	call	MemLock
	mov	ds, ax
	mov	si, dx			; ds:di is our filename
	LocalCopyString			; append it to our path
	call	MemUnlock
	pop	ds
	lea	di, ss:[pathBuf]

	call	PSDSetIni

errorExit:
	.leave
	ret
PSDDLApply	endm
