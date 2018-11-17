COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentCtrl.asm

AUTHOR:		Don Reeves, Feb 21, 1999

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/21/99		Initial revision


DESCRIPTION:
	Methods for GeoCalcDocCtrlClass
		
	$Id: $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include fileEnum.def

idata	segment
	GeoCalcDocCtrlClass
idata	ends


if	_SUPER_IMPEX
CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlConfigureFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the file selector of the open dialog in the document
		control.  This is done to get it to display the keyboard map
		files which are .geo files.

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR

PASS:		*ds:si	= GeoCalcDocCtrlClass object
		ds:di	= GeoCalcDocCtrlClass instance data
		ds:bx	= GeoCalcDocCtrlClass object (same as *ds:si)
		es 	= segment of GeoCalcDocCtrlClass or dgroup, 
			  if this is a method defined for process class.
		ax	= message #
		cx:dx	= File selector

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/24/98   	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlConfigureFileSelector	method	GeoCalcDocCtrlClass, 
			MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR
		uses	ax, cx, dx, bp
		.enter
	;
	; FileEnum evidently can't handle having to match a geode
	; token *and* having to return native files in the same call.
	; So we tell it to return all files and filter them ourselves.
	;
		push	ax, si			; save message, object chunk
		movdw	bxsi, cxdx		; ^lbx:si= file selector
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		or	cx, mask FSFC_NON_GEOS_FILES or \
			    mask FSFC_FILE_FILTER
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it not to look for a specific geode token.
	;
		push	ds:[LMBH_handle]
		call	ObjLockObjBlock

		mov	ds, ax
		mov	ax, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
		call	ObjVarDeleteData
	;
	; Set callback filter routine to filter out the ones we don't want.
	;
		push	bx
		mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_ENUM_FILTER
		mov	cx, size fptr
		call	ObjVarAddData		; ds:bx = extra data
		mov	ds:[bx].segment, vseg GCDCFileEnumFilterRoutine
		mov	ds:[bx].offset, offset GCDCFileEnumFilterRoutine
		pop	bx
	;
	; Clean up and call superclass.
	;
		call	MemUnlock
		pop	bx
		call	MemDerefDS

		pop	ax, si
		mov	di, offset es:[GeoCalcDocCtrlClass]
		call	ObjCallSuperNoLock

		.leave
		ret
GeoCalcDocCtrlConfigureFileSelector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDCFileEnumFilterRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Filters out files we don't want to show.

CALLED BY:	FileEnum (via OLFSBuildFileList)

Pass:		es	= segment of FileEnumCallbackData containing the
			  attributes for the file
		*ds:si	= file selector object
		bp	= inherited stack frame to pass to any FileEnum
			  helper routines.

Return:		carry	= set to reject the file
			- or -
		carry	= clear to accept the file

Destroy:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
(from gFSelC.def)
; The callback routine whose address you return is passed the
; FileEnumCallbackData block that contains all the attributes requested for
; the file. You can examine them by calling FileEnumLocateAttr to find the
; one you need, and taking it from there.

	- take GeoCalc document files
	- take other DOS files as specified later

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/29/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCDCFileEnumFilterRoutine	proc	far
		uses	si,di,bp,ds
		.enter

		segmov	ds, es, si
		clr	si			; ds:si = FileEnumCallbackData
	;
	; Verify that we received a *file* in this callback. If we
	; don't have a file, we'll take it and continue. But, we
	; allow directories to be displayed.
	;
		mov	ax, FEA_FILE_ATTR
		call	FileEnumLocateAttr
		jc	doneDOS
		mov	cx, es:[di].FEAD_value.segment
		mov	di, es:[di].FEAD_value.offset
		jcxz	doneDOS
		mov	es, cx
		test	{byte} es:[di], mask FA_SUBDIR
		jnz	done			; directory, C clear to accept
	;
	; See if the DOS name ends with one of our known extensions.
	;
		mov	ax, FEA_DOS_NAME
		call	FileEnumLocateAttr
		jc	doneDOS
		mov	cx, es:[di].FEAD_value.segment
		mov	dx, es:[di].FEAD_value.offset
		jcxz	doneDOS			; if file doesn't have value,
						; then it can't be a DOS file
	;
	; Compare extension to valid extensions.
	;
		call	CompareExtensions
		jnc	done			; carry clear => RTF or TXT
doneDOS:
	;
	; OK, now see if it's a GeoCalc document file.
	;
		mov	ax, FEA_TOKEN
		call	FileEnumLocateAttr
		jc	reject
		mov	cx, es:[di].FEAD_value.segment
		mov	dx, es:[di].FEAD_value.offset
		jcxz	reject
		call	CompareTokens
		jmp	done
	;
	; By default, we don't know what the file is.
	;
reject:
		stc
done:
		.leave
		ret
GCDCFileEnumFilterRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareExtensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks DOS name to see if it's a known extension.

CALLED BY:	GCDCFileEnumFilterRoutine
PASS:		cx:dx = fptr to DOS name

RETURN:		carry	= clear if it's a known extension
			- or -
		carry	= set (unknown)

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/29/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fileTypeNative	char	0			; need non-NULL string
fileTypeLotus	char	".wks", 0
fileTypeCSV	char	".csv", 0

; The following table contains the list of *all* extensions for files
; that can be displayed in the Open file selector, besides native files.
; The table is in no particular order.

supportedDOSTypes	nptr \
			offset fileTypeLotus,
			offset fileTypeCSV

; Following table *must* match order of GeoCalcDocumentFileType. This
; table is used to create default filenames for the user when switching
; between different file types

extensionTable		nptr \
			offset fileTypeNative,
			offset fileTypeLotus,
			offset fileTypeCSV

CompareExtensions	proc	near
		uses	ax,bx,cx,dx,si,di,es,ds
		.enter
ifdef	DOS_LONG_NAME_SUPPORT
	;
	; Get to offset of extension in name.  Need to search backward since
	; DOS long names can contain multiple dots.
	;
		movdw	esdi, cxdx
		LocalStrLength		; cx = len w/o null, es:di = after null
		LocalPrevChar	esdi	; es:di = null
		LocalPrevChar	esdi	; es:di = last char
		LocalLoadChar	ax, C_PERIOD
		LocalFindCharBackward	; es:di = before '.' if found
		jne	noMatch
		LocalNextChar	esdi	; es:di = '.'
else
	;
	; Get to offset of extension in name.  (If not 8.3, skip it).
	;
		movdw	esdi, cxdx
		mov	cx, DOS_FILE_NAME_CORE_LENGTH + 1
		LocalLoadChar	ax, C_PERIOD
		LocalFindChar
		jnz	noMatch
		LocalPrevChar	esdi			; include '.'
endif	; DOS_LONG_NAME_SUPPORT
	;
	; Loop through our list of understood extensions
	;
		segmov	ds, cs, ax
		mov	bx, offset supportedDOSTypes
		mov	cx, length supportedDOSTypes
extensionLoop:
		push	cx
		mov	si, ds:[bx]
		clr	cx				; null-term
		call	LocalCmpStringsNoCase
		pop	cx
		clc					; assume match
		je	done
		add	bx, 2
		loop	extensionLoop
noMatch:
		stc					; no match!
done:
		.leave
		ret
CompareExtensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the document to see if it's a GeoCalc document.

CALLED BY:	GCDCFileEnumFilterRoutine

PASS:		cx:dx = GeodeToken
RETURN:		carry clear if it's a GeoCalc document, else set
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/27/98    	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fileToken	GeodeToken <"GCDa", MANUFACTURER_ID_GEOWORKS>

CompareTokens	proc	near
		uses	cx,si,di,es,ds
		.enter
	;
	; Here we need an exact match, so we'll just use the ol' cmps
	;
		movdw	dssi, cxdx
		segmov	es, cs, di
		mov	di, offset fileToken
		mov	cx, size GeodeToken
		repe	cmpsb
		clc
		jz	calcDoc
		stc
calcDoc:
		.leave
		ret
CompareTokens	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlImportInProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_GEOCALC_DOC_CTRL_IMPORT_IN_PROGRESS

PASS:		*ds:si	= GeoCalcDocCtrlClass object
		es 	= segment of GeoCalcDocCtrlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/28/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlImportInProgress	method dynamic GeoCalcDocCtrlClass, 
				MSG_GEOCALC_DOC_CTRL_IMPORT_IN_PROGRESS
		.enter
	;
	; Save this fact away for later use
	;
		mov	ds:[di].GCDCI_importInProgress, BB_TRUE

		.leave
		ret
GeoCalcDocCtrlImportInProgress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlDisplayDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG

PASS:		es 	= segment of GeoCalcDocCtrlClass
		*ds:si	= GeoCalcDocCtrlClass object
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/28/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlDisplayDialog	method	GeoCalcDocCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	;
	; If we're in the middle of an import, do nothing
	;
		cmp	ds:[di].GCDCI_importInProgress, BB_TRUE
		jne	callSuper
		ret
	;
	; Call our superclass
	;
callSuper:
		mov	di, offset GeoCalcDocCtrlClass
		GOTO	ObjCallSuperNoLock

GeoCalcDocCtrlDisplayDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlImportCancelled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED

PASS:		es 	= segment of GeoCalcDocCtrlClass
		*ds:si	= GeoCalcDocCtrlClass object
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/28/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlImportCancelled	method	GeoCalcDocCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED
	;
	; Note that we're no longer importing, and let our superclass
	; do all of the real work.
	;
		mov	ds:[di].GCDCI_importInProgress, BB_FALSE
		mov	di, offset GeoCalcDocCtrlClass
		GOTO	ObjCallSuperNoLock

GeoCalcDocCtrlImportCancelled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlOpenImportSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED

PASS:		es 	= segment of GeoCalcDocCtrlClass
		*ds:si	= GeoCalcDocCtrlClass object
		ss:bp	= ImpexTranslationParams
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/28/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlOpenImportSelected	method	GeoCalcDocCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED
	;
	; Note that we're done importing, and let our superclass
	; do all of the real work.
	;
		mov	ds:[di].GCDCI_importInProgress, BB_FALSE
		mov	di, offset GeoCalcDocCtrlClass
		GOTO	ObjCallSuperNoLock

GeoCalcDocCtrlOpenImportSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlInitiateSaveAsDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the "Save As" DB, by resetting the format list

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC

PASS:		es 	= segment of GeoCalcDocCtrlClass
		*ds:si	= GeoCalcDocCtrlClass object
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/24/98   	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlInitiateSaveAsDoc	method	GeoCalcDocCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	;
	; Reset the format selector to 
	;
		push	ax, si
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, GCDFT_CALC
		clr	dx
		mov	bx, ds:[di].GDCI_saveAsGroup.handle
		mov	si, offset GCFileTypeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Call our superclass
	;
		pop	ax, si
		mov	di, offset GeoCalcDocCtrlClass
		GOTO	ObjCallSuperNoLock

GeoCalcDocCtrlInitiateSaveAsDoc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlGetSelectedFileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_GEOCALC_DOC_CTRL_GET_SELECTED_FILE_TYPE

PASS:		*ds:si	= GeoCalcDocCtrlClass object
		ds:di	= GeoCalcDocCtrlClass instance data
		ds:bx	= GeoCalcDocCtrlClass object (same as *ds:si)
		es 	= segment of GeoCalcDocCtrlClass
		ax	= message #

RETURN:		cx	= GeoCalcDocumentFileType
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/12/98   	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocCtrlGetSelectedFileType	method dynamic GeoCalcDocCtrlClass, 
				MSG_GEOCALC_DOC_CTRL_GET_SELECTED_FILE_TYPE
		uses	ax, dx, bp
		.enter
	;
	; Get the item group.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDCI_saveAsGroup.handle
		mov	si, offset GCFileTypeSelector
	;
	; Get the selection (default to GeoCalc).
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov_tr	cx, ax
		jnc	done
		mov	cx, GCDFT_CALC
done:
		.leave
		ret
GeoCalcDocCtrlGetSelectedFileType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocCtrlFileTypeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_WRITE_DC_GET_SELECTED_FILE_TYPE

PASS:		*ds:si	= GeoCalcDocCtrlClass object
		cx	= GeoCalcDocumentFileType

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don 	2/21/99   	Initial version
	Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocCtrlFileTypeChanged	method dynamic GeoCalcDocCtrlClass, 
				MSG_GEOCALC_DOC_CTRL_FILE_TYPE_CHANGED
		.enter
	;
	; Get the current file name text and append an appropriate
	; extension onto it. Obtaining the text object is a bit
	; of a trick...it is the format list's parent's first
	; child.
	;
		push	cx
		mov	ax, MSG_GEN_FIND_PARENT
		GetResourceHandleNS GCFileTypeInteraction, bx
		mov	si, offset GCFileTypeInteraction
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; parent => CX:DX

		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		movdw	bxsi, cxdx
		clr	cx			; get first child
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; text object => CX:DX
	;
	; Just to make sure, verify this object is a descendant of VisText
	;
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		movdw	bxsi, cxdx
		mov	cx, segment VisTextClass
		mov	dx, offset VisTextClass
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; carry = set if class is OK
		pop	cx			; file type => CX
		jnc	done
	;
	; OK - now muck with the file name
	;
		mov	di, bx
		mov	bx, cx
		mov	cx, cs
		mov	dx, cs:[extensionTable][bx]
		call	GCDCEditDefaultName		
done:
		.leave
		ret
GeoCalcDocCtrlFileTypeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDCEditDefaultName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edit the default name for the file to be exported, based
		upon the file mask for the format & the text the user has
		already entered.

CALLED BY:	ConstructDefaultName

PASS:		DS	= Relocatable segment
		DI:SI	= Optr of VisTextClass object holding file name
		CX:DX	= Fptr to default extension

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version
		Don	2/21/99		Clean-up after port from Impex library
		Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCDCEditDefaultName	proc	near
		.enter
	;
	; Get the current text
	;
		mov_tr	ax, cx
		mov	cx, PATH_BUFFER_SIZE
		sub	sp, cx
		mov	bp, sp
		push	ax, dx			; save default file mask
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage_gcdc_call	; length of text => CX
	;
	; Scan for a period, as that will mark the place where we
	; will add the extension.
	;
		push	di			; save text object chunk
		mov	es, dx
		mov	di, bp
		jcxz	noText			; if no text, get some!
haveText:
		mov	dx, di			; save start of text
SBCS <		mov	al, '.'						>
SBCS <		repne	scasb						>
DBCS <		mov	ax, '.'						>
DBCS <		repne	scasw						>
		mov	bp, di			; start of extension => BP
		pop	di			; restore text object chunk
		pop	es, bx			; default file mask => ES:BX
		jz	findDefaultExt		; if match, then continue
		LocalPutChar	ssbp, ax
	;
	; We've found the source extension. Find the extension of
	; of the default file mask. If none is found, then terminate
	; the string (removing the extension).
	;
findDefaultExt:
		push	bp			; save extension offset
scanNextChar:
		LocalGetChar	ax, esbx
		LocalCmpChar	ax, '.'
		je	copyNextChar
		LocalIsNull	ax
		jnz	scanNextChar
		dec	bp			; nuke trailing period
DBCS <		dec	bp			; nuke rest of it	>
		jmp	terminate		; terminate the string
	;
	; Copy the new extension onto the old. If any wildcards are
	; found in the extension, ignore them (there should generally
	; not be any).
copyNextChar:
		LocalGetChar	ax, esbx
		LocalCmpChar	ax, '?'
		je	terminate
		LocalCmpChar	ax, '*'
		je	terminate
		LocalPutChar	ssbp, ax
		LocalIsNull	ax
		jne	copyNextChar
terminate:
SBCS <		mov	{byte} ss:[bp], 0				>
DBCS <		mov	{wchar} ss:[bp], 0				>
		pop	bx
		sub	bx, dx
		dec	bx			; string length => BX
	;
	; Replace the text, and re-select everything up until
	; the start of the extension
	;
		mov	bp, dx
		mov	dx, ss			; text => DX:BP
		call	GCDCDefaultNameSetText
		add	sp, PATH_BUFFER_SIZE	; clean up the stack

		.leave
		ret
	;
	; Handle the case of no initial text being present
	;	Pass:
	;	  ES:DI	= Buffer for text
	;	Return:
	;	  ES:DI	= Buffer filled with default text
	;	  CX	= # of characters
	;
noText:
		push	bx, di, si, ds
		mov	bx, handle StringsUI
		call	MemLock
		mov	ds, ax
		mov	si, offset StringsUI:DefaultSaveAsNameString
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx	; string length (w/NULL) => CX
DBCS <		shr	cx, 1			; cx <- string length	>
		push	cx
		mov	bp, cx			; base-name length => BP
		LocalCopyNString		; rep movsb/movsw
		call	MemUnlock		; unlock strings resource
		pop	cx			; string length => CX
		dec	cx			; don't include NULL
		pop	bx, di, si, ds
		jmp	haveText
GCDCEditDefaultName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDCDefaultNameSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text in the default name text object

CALLED BY:	GCDCEditDefaultName

PASS:		DS	= Relocatable segment
		DI:SI	= Optr of VisTextClass object
		DX:BP	= Default text
		BX	= End of "base" of file name

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/24/94		Initial version
		Don	2/21/99		Clean-up after port from Impex library
		Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCDCDefaultNameSetText	proc	near
		.enter
	
		clr	cx			; it is NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage_gcdc_call
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		clr	cx			; start selection => CX
		mov	dx, bx			; end selection => DX
		call	ObjMessage_gcdc_call

		.leave
		ret
GCDCDefaultNameSetText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_gcdc_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message (or call) to a child of a controller

CALLED BY:	INTERNAL

PASS:		DS	= Relocatable segment
		DI:SI	= Optr of object to which to send message
		AX	= Message to send

RETURN:		see message declaration

DESTROYED:	see message declaration (BX, DI, SI preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version
		Don	2/21/99		Clean-up after port from Impex library
		Don	2/21/99		Ported over from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_gcdc_call	proc	near
		uses	bx, di
		.enter

		mov	bx, di
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		.leave
		ret
ObjMessage_gcdc_call	endp

CommonCode	ends
endif	; if _SUPER_IMPEX
