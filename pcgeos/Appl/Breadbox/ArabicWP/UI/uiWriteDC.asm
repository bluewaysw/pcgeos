COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		GeoWrite
FILE:		uiWriteDC.asm

AUTHOR:		Steve Yegge, Oct 16, 1998

ROUTINES:
	Name			Description
	----			-----------
  INT WriteDCFileEnumFilterRoutine
				Filters out files we don't want to show.

  INT CompareExtensions		Checks DOS name to see if it's a known
				extension.

  INT CompareTokens		Checks the document to see if it's a Write
				document.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/16/98   	Initial revision


DESCRIPTION:
		
	GenDocumentControl subclass for GeoWrite.  It displays
	non-geos document files (*.HTM, *.RTF) along with GeoWrite docs.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include fileEnum.def

idata	segment
	WriteDocumentCtrlClass
idata	ends


if	_SUPER_IMPEX
CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCConfigureFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the file selector of the open dialog in the document
		control.  This is done to get it to display the keyboard map
		files which are .geo files.

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR

PASS:		*ds:si	= WriteDocumentCtrlClass object
		ds:di	= WriteDocumentCtrlClass instance data
		ds:bx	= WriteDocumentCtrlClass object (same as *ds:si)
		es 	= segment of WriteDocumentCtrlClass or dgroup, 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
helpEditorPath		char	"Help\\Source", 0    ; default pathname for Help Editor

GeoWriteDCConfigureFileSelector	method	WriteDocumentCtrlClass, 
			MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR
		uses	ax, cx, dx, bp
		.enter	
		
	;
	; FileEnum evidently can't handle having to match a geode
	; token *and* having to return native files in the same call.
	; So we tell it to return all files and filter them ourselves.
	;
		push	cx, dx			; save file selector object
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
		mov	ds:[bx].segment, vseg WriteDCFileEnumFilterRoutine
		mov	ds:[bx].offset, offset WriteDCFileEnumFilterRoutine
		pop	bx
	;
	; Clean up and call superclass.
	;
		call	MemUnlock
		pop	bx
		call	MemDerefDS

		pop	ax, si
		mov	di, offset es:[WriteDocumentCtrlClass]
		call	ObjCallSuperNoLock


	;
	; Determine whether Writer is in Help Editor Mode.  If it is,
	; we want to change our default directory to USERDATA/Help/Source.
	;

		mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
		GetResourceHandleNS WriteApp, bx
		mov	si, offset WriteApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage                 ; ax = Booleans selected
		pop	bx, si			   ; bx:si = file selector object
ifndef PRODUCT_NDO2000
		test	ax, mask WF_HELP_EDITOR    ; is Help Editor selected?
		jz	ensureVirtualRootOn

	;
	; We're in Help Editor Mode.  Set the path.
	;
		mov	ax, MSG_GEN_PATH_SET
		mov	bp, SP_USER_DATA
		mov	cx, cs
		mov	dx, offset helpEditorPath
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			

	;
	; Turn off the virtual root
	;
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	ax, not mask FSA_USE_VIRTUAL_ROOT
		and	cx, ax
		jmp	setVirtualRoot
endif
ensureVirtualRootOn:

	;
	; Make sure the virtual root attr is ON
	;
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		or	cx, mask FSA_USE_VIRTUAL_ROOT

setVirtualRoot:
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
GeoWriteDCConfigureFileSelector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDCFileEnumFilterRoutine
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

	- take GeoWrite document files
	- take *.htm files
	- take *.rtf files
	- take *.txt files

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/29/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDCFileEnumFilterRoutine	proc	far
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
	; OK, now see if it's a GeoWrite document file.
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
WriteDCFileEnumFilterRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareExtensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks DOS name to see if it's a known extension.

CALLED BY:	WriteDCFileEnumFilterRoutine
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
	Don	2/21/99		Cleaned up, removed HTML support
	dhunter	8/7/2000	Added DOC import support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fileTypeNative	char	0			; need non-NULL string
fileTypeRtf	char	".rtf", 0
fileTypeTxt	char	".txt", 0
fileTypeDoc	char	".doc", 0

; The following table contains the list of *all* extensions for files
; that can be displayed in the Open file selector, besides native files.
; The table is in no particular order.

supportedDOSTypes	nptr \
			offset fileTypeRtf,
			offset fileTypeTxt,
			offset fileTypeDoc

; Following table *must* match order of WriteDocumentFileType. This
; table is used to create default filenames for the user when switching
; between different file types

extensionTable		nptr \
			offset fileTypeNative,
			offset fileTypeRtf,
			offset fileTypeTxt

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

SYNOPSIS:	Checks the document to see if it's a Write document.

CALLED BY:	WriteDCFileEnumFilterRoutine

PASS:		cx:dx = GeodeToken
RETURN:		carry clear if it's a Write document, else set
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/27/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fileToken	GeodeToken <"WDAT", MANUFACTURER_ID_GEOWORKS>

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
		jz	writeDoc
		stc
writeDoc:
		.leave
		ret
CompareTokens	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCImportInProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_GEOCALC_DOC_CTRL_IMPORT_IN_PROGRESS

PASS:		*ds:si	= WriteDocumentCtrlClass object
		es 	= segment of WriteDocumentCtrlClass
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
GeoWriteDCImportInProgress	method dynamic WriteDocumentCtrlClass, 
				MSG_WRITE_DC_IMPORT_IN_PROGRESS
		.enter
	;
	; Save this fact away for later use
	;
		mov	ds:[di].WDCI_importInProgress, BB_TRUE

		.leave
		ret
GeoWriteDCImportInProgress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCDisplayDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG

PASS:		es 	= segment of WriteDocumentCtrlClass
		*ds:si	= WriteDocumentCtrlClass object
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
GeoWriteDCDisplayDialog	method	WriteDocumentCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	;
	; If we're in the middle of an import, do nothing
	;
		cmp	ds:[di].WDCI_importInProgress, BB_TRUE
		jne	callSuper
		ret
	;
	; Call our superclass
	;
callSuper:
		mov	di, offset WriteDocumentCtrlClass
		GOTO	ObjCallSuperNoLock

GeoWriteDCDisplayDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCImportCancelled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED

PASS:		es 	= segment of WriteDocumentCtrlClass
		*ds:si	= WriteDocumentCtrlClass object
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
GeoWriteDCImportCancelled	method	WriteDocumentCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED
	;
	; Note that we're no longer importing, and let our superclass
	; do all of the real work.
	;
		mov	ds:[di].WDCI_importInProgress, BB_FALSE
		mov	di, offset WriteDocumentCtrlClass
		GOTO	ObjCallSuperNoLock

GeoWriteDCImportCancelled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCOpenImportSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the New/Open DB, unless we are in the middle of
		importing a file, in which case we do nothing and wait

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED

PASS:		es 	= segment of WriteDocumentCtrlClass
		*ds:si	= WriteDocumentCtrlClass object
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
GeoWriteDCOpenImportSelected	method	WriteDocumentCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED
	;
	; if we are exiting, just cancel
	;
		push	ax, bp
		mov	ax, MSG_GEN_APPLICATION_GET_STATE
		call	UserCallApplication
		test	ax, mask AS_QUITTING
		pop	ax, bp
		jz	continue
		mov	ax, MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED
		GOTO	ObjCallInstanceNoLock

continue:
	;
	; Note that we're done importing, and let our superclass
	; do all of the real work.
	;
		mov	ds:[di].WDCI_importInProgress, BB_FALSE
		mov	di, offset WriteDocumentCtrlClass
		GOTO	ObjCallSuperNoLock

GeoWriteDCOpenImportSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoWriteDCInitiateSaveAsDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the "Save As" DB, by resetting the format list
		to 
		con
		fil

CALLED BY:	via MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC

PASS:		es 	= segment of WriteDocumentCtrlClass
		*ds:si	= WriteDocumentCtrlClass object
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/24/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoWriteDCInitiateSaveAsDoc	method	WriteDocumentCtrlClass, 
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	;
	; Reset the format selector to 
	;
		push	ax, si
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, WDFT_WRITE
		clr	dx
		mov	bx, ds:[di].GDCI_saveAsGroup.handle
		mov	si, offset WriteFileTypeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Call our superclass
	;
		pop	ax, si
		mov	di, offset WriteDocumentCtrlClass
		GOTO	ObjCallSuperNoLock

GeoWriteDCInitiateSaveAsDoc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDCGetSelectedFileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_WRITE_DC_GET_SELECTED_FILE_TYPE

PASS:		*ds:si	= WriteDocumentCtrlClass object
		ds:di	= WriteDocumentCtrlClass instance data
		ds:bx	= WriteDocumentCtrlClass object (same as *ds:si)
		es 	= segment of WriteDocumentCtrlClass
		ax	= message #

RETURN:		cx	= WriteDocumentFileType
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDCGetSelectedFileType	method dynamic WriteDocumentCtrlClass, 
				MSG_WRITE_DC_GET_SELECTED_FILE_TYPE
		uses	ax, dx, bp
		.enter
	;
	; Get the item group.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDCI_saveAsGroup.handle
		mov	si, offset WriteFileTypeSelector
	;
	; Get the selection (default to GeoWrite).
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov_tr	cx, ax
		jnc	done
		mov	cx, WDFT_WRITE
done:
		.leave
		ret
WriteDCGetSelectedFileType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDCFileTypeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the selection from the file selector.

CALLED BY:	MSG_WRITE_DC_GET_SELECTED_FILE_TYPE

PASS:		*ds:si	= WriteDocumentCtrlClass object
		cx	= WriteDocumentFileType

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don 	2/21/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteDCFileTypeChanged	method dynamic WriteDocumentCtrlClass, 
				MSG_WRITE_DC_FILE_TYPE_CHANGED
		.enter
	;
	; Get the current file name text and append an appropriate
	; extension onto it. Obtaining the text object is a bit
	; of a trick...it is the format list's parent's first
	; child.
	;
		push	cx
		mov	ax, MSG_GEN_FIND_PARENT
		GetResourceHandleNS WriteFileTypeInteraction, bx
		mov	si, offset WriteFileTypeInteraction
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
		call	WDCEditDefaultName		
done:
		.leave
		ret
WriteDCFileTypeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDCEditDefaultName
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WDCEditDefaultName	proc	near
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
		call	ObjMessage_wdc_call	; length of text => CX
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
		call	WDCDefaultNameSetText
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
WDCEditDefaultName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDCDefaultNameSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text in the default name text object

CALLED BY:	WDCEditDefaultName

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WDCDefaultNameSetText	proc	near
		.enter
	
		clr	cx			; it is NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage_wdc_call
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		clr	cx			; start selection => CX
		mov	dx, bx			; end selection => DX
		call	ObjMessage_wdc_call

		.leave
		ret
WDCDefaultNameSetText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_wdc_call
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_wdc_call	proc	near
		uses	bx, di
		.enter

		mov	bx, di
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		.leave
		ret
ObjMessage_wdc_call	endp


WriteDocumentControlInitiate	method dynamic WriteDocumentCtrlClass,
					MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC
	;
	; Call our superclass to create the GState
	;
	mov	di, offset WriteDocumentCtrlClass
	call	ObjCallSuperNoLock
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	{byte}ds:[di].WDCI_DALaunched, 1

	ret
WriteDocumentControlInitiate		endm
WriteDocumentControlLaunched	method dynamic WriteDocumentCtrlClass,
					MSG_WRITE_DOCUMENT_CONTROL_LAUNCHED_DA
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	cx
	mov	cl, ds:[di].WDCI_DALaunched
	pop	di
	ret
WriteDocumentControlLaunched		endm

CommonCode	ends
endif	; if _SUPER_IMPEX
