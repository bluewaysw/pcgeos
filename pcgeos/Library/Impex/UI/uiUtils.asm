COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiUtils.asm

AUTHOR:		Don Reeves, May 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/26/92		Initial revision

DESCRIPTION:
	Contains utilities used by the UI module (& possibly others)

	$Id: uiUtils.asm,v 1.1 97/04/04 23:14:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** External routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexImportExportCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message back to the Import/ExportControlClass
		object stating that the application has completed it's
		import or export

CALLED BY:	GLOBAL

PASS:		SS:BP	= ImpexTranslationParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 5/92		Initial version
		Don	10/24/00	Hide status dialog box

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexImportExportCompleted	proc	far
		uses	ax, bx, cx, dx, di, si
		.enter
	;
	; If the app is detaching, then do nothing, as the
	; ImpexTranslationParams are likely to contain a thread handle
	; that no longer exists.
	;
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_GET_STATE
		mov	di, mask MF_CALL
		call	ObjMessage
		test	ax, mask AS_DETACHING
		jnz	done
	;
	; The status dialog box, if there is one, is a child of the
	; the ImportExportClass object referenced by ITP_impexOD.
	; It will be the last child, and it will be of class
	; GenInteraction and it will be a dialog box type. So, if
	; we find such a beast, we lower it to the bottom right now
	; to improve the perception for the user (this is especially
	; important when importing bitmaps).
	;
		push	bp
		mov	ax, MSG_GEN_COUNT_CHILDREN
		movdw	bxsi, ss:[bp].ITP_impexOD
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	cx, dx
		jcxz	loweringDone
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		dec	cx			; make zero-based
		mov	di, mask MF_CALL
		call	ObjMessage		; child -> CX:DX
		jc	loweringDone		; no children - abort!
	;
	; Check class
	;
		mov	ax, MSG_META_GET_CLASS
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL
		call	ObjMessage		; class -> CX:DX
		cmp	cx, segment GenInteractionClass
		jne	loweringDone
		cmp	dx, offset GenInteractionClass
		jne	loweringDone
	;
	; Check it is a dialog
	;
		mov	ax, MSG_GEN_INTERACTION_GET_VISIBILITY
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	cl, GIV_DIALOG		; if not a dialog box
		jne	loweringDone		; ...it's not what we want!
	;
	; OK - lower the dialog box below everything else. We tried
	; to use MSG_GEN_LOWER_TO_BOTTOM, but it doesn't work so we'll
	; just dismiss the damn thing.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL
		call	ObjMessage
loweringDone:
		pop	bp

	;	
	; Send a message back to the Import/ExportControl object
	;
		mov	ax, ss:[bp].ITP_returnMsg
		movdw	bxsi, ss:[bp].ITP_impexOD
		mov	dx, size ImpexTranslationParams
		mov	di, mask MF_STACK
		call	ObjMessage
done:
		.leave
		ret
ImpexImportExportCompleted	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexChangeToImpexDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current directory to be that which holds all of
		the Import/Export translation libraries

CALLED BY:	FormatEnum
		ImpexLoadLibrary

PASS:		Nothing
                          
RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* Pushes the current directory first

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexChangeToImpexDir	proc	far
		uses	ax
		.enter
	
		;  where all the libraries are located
		; 
		call	FilePushDir

if ALLOW_FLOPPY_BASED_LIBS and SINGLE_DRIVE_DOCUMENT_DIR
		mov	ax, SP_DOCUMENT
else
		mov	ax, SP_IMPORT_EXPORT_DRIVERS
endif
		call    FileSetStandardPath

		.leave
		ret
ImpexChangeToImpexDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexLoadLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a translation library

CALLED BY:	GLOBAL

PASS:		DS:DI	= ImpexLibraryDescriptor

RETURN:		BX	= Library handle
		Carry	= Clear
			- or -
		AX	= GeodeLoadErrors
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexLoadLibrary	proc	far
		uses	si
		.enter
	
		; Change to the correct directory, and load the sucker
		;
		call	ImpexChangeToImpexDir	; go to Impex directory
		CheckHack <(offset ILD_fileName) eq 0>
		mov	si, di			; library name => DS:SI
		mov	ax, XLATLIB_PROTO_MAJOR	; expected major protocol
		mov	bx, XLATLIB_PROTO_MINOR	; expected minor protocol
		call	GeodeUseLibrary		; error or library loaded
		call	FilePopDir		; restore current directory

		.leave
		ret
ImpexLoadLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Internal UI utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexCopyDefaultMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a large moniker (either import or export) if the
		Import/ExportControl object doesn't already have a moniker.

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControl object
		DS:BX	= Deref'd object chunk handle
		^lDX:CX	= OD of moniker list for default moniker

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	DEFAULT_MONIKER
ImpexCopyDefaultMoniker	proc	near
		class	GenClass
		uses	ax, bp
		.enter
	
		; First see if we need to do anything
		;
		add	bx, ds:[bx].Gen_offset
		tst	ds:[bx].GI_visMoniker
		jnz	done

		; We need to be kinda gross here, as we have a moniker
		; list that needs to be relocated prior to sending
		; REPLACE_VIS_MONIKER, as the handler will attempt to
		; choose the best moniker from the list. We also need
		; be wary of other threads coming in and relocating the
		; block at the same time, so we use the block handle as a
		; semaphore
		;
		push	ds			; save object segment
		mov	bx, dx			; source block handle => BX
		mov	di, cx
		call	MemPLock		; lock & own moniker resource
		mov	ds, ax
		clr	bp			
		call	GenRelocMonikerList	; relocate the moniker list
		mov	bp, ds:[di]		; moniker list => DS:BP
		ChunkSizePtr	ds, bp, cx	; length of moniker list => CX
		mov	dx, bp			; moniker list => AX:DX
		pop	ds			; Import/Export object => *DS:SI

		; Copy the moniker, & set the moniker chunk ignore-dirty
		;
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		movdw	ss:[bp].RVMF_source, axdx
		mov	ss:[bp].RVMF_sourceType, VMST_FPTR
		mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
		mov	ss:[bp].RVMF_length, cx
		mov	ss:[bp].RVMF_updateMode, VUM_DELAYED_VIA_UI_QUEUE
		mov	dx, ReplaceVisMonikerFrame
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	ObjCallInstanceNoLock
		add	sp, size ReplaceVisMonikerFrame
		mov	dx, bx			; source block handle => DX
		mov	bx, mask OCF_IGNORE_DIRTY
		call	ObjSetFlags

		; Un-relocate the moniker list, & unlock the sucker
		;
		push	ds			; save object segment
		mov	bx, dx			; source block handle => BX
		call	MemDerefDS
		mov	cx, di			; moniker list => *DS:CX
		mov	bp, 1
		call	GenRelocMonikerList	; un-relocate the moniker list
		call	MemUnlockV		; unlock & release resource
		pop	ds			; restore object segment
done:
		.leave
		ret
ImpexCopyDefaultMoniker	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexDerefTempData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the TempImportExportInstance data

CALLED BY:	INTERNAL

PASS:		*DS:SI	= ImportExportClass object (or sub-class :)

RETURN:		DS:BX	= TempImportExportInstance

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexDerefTempData	proc	near
		uses	ax
		.enter
	
		; Find the variable data
		;
		mov	ax, TEMP_IMPORT_EXPORT_DATA
		call	ObjVarFindData
		jnc	allocate
done:
		.leave
		ret

		; Allocate the variable data
allocate:
		push	cx
		mov	cx, size TempImportExportData
		call	ObjVarAddData		; add data & initialize to zero
		pop	cx
		jmp	done
ImpexDerefTempData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexAddFormatUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add format UI to the import or export dialog box

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass object
		DI	= Chunk handle of parent for UI in child block
		BP	= Handle of translation library
		CX:DX	= OD of new format UI (needs to be duplicated)
			  (If CX = 0, there is no format UI)
		AX	= TransRoutine to call to get variant superclass
		BX	= TransRoutine to call to initialize UI

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexAddFormatUI	proc	near
		class	ImportExportClass
		uses	di
		.enter
	
		; First, we need to duplicate the UI
		;
		jcxz	done			; if no UI, do nothing
		push	ax, bx			; save TransRoutines
		mov	bx, ds:[LMBH_handle]
		call	MemOwner		; geode owner => BX
		mov_tr	ax, cx			; handle of generic tree => AX
		xchg	ax, bx			; owner => AX, tree => BX
		clr	cx			; have current thread run block
		call	ObjDuplicateResource	; new block handle => BX
		push	bp			; save the library handle
		push	si			; save Import/ExportControl obj

		; Now we need to add the child
		;
		mov	ax, MSG_GEN_ADD_CHILD
		mov	cx, bx			; new UI tree => CX:DX
		mov	bp, CCO_FIRST shl offset CCF_REFERENCE
		call	ObjMessage_child_call

		; Now set the new UI usable
		;
		mov	ax, MSG_GEN_SET_USABLE
		mov	bx, cx
		mov	si, dx
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		; Finally, store this info away
		;
		mov	cx, bx
		mov	dx, si
		pop	si			; Import/ExportControl => *DS:SI
		call	ImpexDerefTempData	; get TempImportExportData
		movdw	ds:[bx].TIED_formatUI, cxdx
		pop	ax			; library handle => AX
		mov	ds:[bx].TIED_formatLibrary, ax

		; Initialize the UI
		;
		mov_tr	bx, ax			; library handle => BX
		pop	ax			; initialize TransRoutine => AX
		push	bx
		call	ImpexCallLibraryEntry	; initialize the UI
		pop	bx

		; Reset the variant class pointer, if necessary
		;
		pop	ax			; variant TransRoutine => AX
		call	ImpexCallLibraryEntry	; ClassStruct => BX:AX
		tst	bx
		jz	done
		mov	di, ds:[si]		; dereference handle => BX
		add	di, ds:[di].ImportExport_offset
EC <		pushdw	esdi						>
EC <		movdw	esdi, bxax		; ClassStruct => ES:DI	>
EC <		call	ECCheckClass		; verify class		>
EC <		popdw	esdi						>
		movdw	ds:[di].ImportExport_metaInstance, bxax
done:	
		.leave
		ret
ImpexAddFormatUI	endp

ImpexCallLibraryEntry	proc	near
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; initialize the UI
		ret
ImpexCallLibraryEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexRemoveFormatUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the current format UI (if it exists) from the import
		or export dialog box.

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass object
		DI	= Chunk handle of parent for UI in child block

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexRemoveFormatUI	proc	near
		class	ImportExportClass
		uses	cx, dx, bp, di, si
		.enter
	
		; Get the current format UI
		;
		call	ImpexDerefTempData	; get ImportExportTempInstance
		clr	ax
		clrdw	cxdx
		xchgdw	cxdx, ds:[bx].TIED_formatUI
		xchg	ax, ds:[bx].TIED_formatLibrary
		tst	ax			; any format UI ??
		jz	done			; nope, so we're done

		; Reset the variant class pointer
		;
		mov	bx, ds:[si]		; dereference handle => BX
		add	bx, ds:[bx].ImportExport_offset
		mov	ds:[bx].ImportExport_metaInstance.segment, \
			segment GenControlClass
		mov	ds:[bx].ImportExport_metaInstance.offset, \
			offset GenControlClass

		; Remove the format UI
		;
		push	ax			; save the library handle
		call	RemoveUICommon		; remove UI form generic tree

		; Tell the parent to resize itself downward
		;
		pushdw	cxdx			; save format UI OD
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock

		; Free the duplicated UI
		;
		mov	ax, MSG_META_BLOCK_FREE
		popdw	bxdi			
		push	si
		mov	si, di			; format UI OD => BX:DI
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; free the block

		; Finally, stop using the library. Send a message to do
		; this, so that the common libraries are repeatedly unloaded
		; and re-loaded.
		;
		mov	ax, MSG_IMPORT_EXPORT_FREE_LIBRARY
		mov	bx, ds:[LMBH_handle]
		pop	si			; ImportExport OD => BX:SI
		pop	cx			; library handle => CX
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		.leave
		ret
ImpexRemoveFormatUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexAddAppUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add application UI to an import or export dialog box

CALLED BY:	ImportControlGenerateUI, ExportControlGenerateUI

PASS:		*DS:SI	= Import/ExportClass object
		DS:BX	= Pointer to OD of UI to add
		DI	= Chunk handle of parent for application UI

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexAddAppUI	proc	near
		uses	si
		.enter
	
		; Add the UI to the generic tree
		;
		mov	cx, ds:[bx].handle
		mov	dx, ds:[bx].chunk	; application OD => CX
		mov	ax, MSG_GEN_ADD_CHILD
		clr	bp			; CompChildFlags => BP
		call	ObjMessage_child_call	; add the child to the parent
		call	ImpexGetChildBlockAndFeatures

		; Now set the child usable
		;
		mov	ax, MSG_GEN_SET_USABLE
		mov	bx, cx
		mov	si, dx			; new UI OD => BX:SI
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		.leave
		ret
ImpexAddAppUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexRemoveAppUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove application UI from an Import/Export dialog box

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass object
		DS:BX	= Pointer to OD of UI to remove
		DI	= Chunk handle of parent for application UI

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexRemoveAppUI	proc	near
		uses	si
		.enter
	
		; Set the child not usable
		;
		mov	cx, ds:[bx].handle
		mov	dx, ds:[bx].chunk	; application OD => CX:DX
		call	RemoveUICommon		; remove the UI from the tree

		.leave
		ret
ImpexRemoveAppUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveUICommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove UI for a generic tree

CALLED BY:	INTNERAL

PASS:		*DS:SI	= ImportExportControl class object
		DI	= Chunk handle of generic parent in child block
		CX:DX	= OD of generic UI tree to remove

RETURN:		Nothing

DESTROYED:	AX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveUICommon	proc	
		.enter
	
		; First set the format UI not usable
		;
		push	di, si
		mov	ax, MSG_GEN_SET_NOT_USABLE
		movdw	bxsi, cxdx		; UI tree => BX:SI
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		; Now we remove the child
		;
		mov	ax, MSG_GEN_REMOVE_CHILD
		movdw	cxdx, bxsi
		clr	bp			; don't mark dirty
		pop	di, si			; restore parent, controller
		call	ObjMessage_child_call	; send message to child

		.leave
		ret
RemoveUICommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexFreeLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a library

CALLED BY:	UTILITY

PASS:		BX	= Library handle (may be zero)

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexFreeLibrary	proc	near
		tst	bx
		jz	done
		call	GeodeFreeLibrary
done:
		ret
ImpexFreeLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block handle and the Import/ExportControlFeatures
		for the children of the	controller, 


CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControl object

RETURN:		AX	= Import/ExportControlFeatures
		BX	= Block handle
		Carry	= Clear
			- or -
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexGetChildBlockAndFeatures	proc	near
		.enter
	
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData		; TempGenControlInstance=>DS:BX
		cmc				; invert the carry
		jc	done			; if not found, abort
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock
		tst	bx
		jnz	done
		stc				; set carry for no children
done:
		.leave
		ret
ImpexGetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_child_send, ObjMessage_child_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message (or call) to a child of a controller

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass
		AX	= Message to send
		DI	= Chunk handle of child

RETURN:		see message declaration

DESTROYED:	see message declaration (BX, DI, SI preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_child_send	proc	near
		push	bx
		mov	bx, mask MF_FIXUP_DS	; MessageFlags => BX
		jmp	omcCommon
ObjMessage_child_send	endp

ObjMessage_child_call	proc	near
		push	bx
		mov	bx, mask MF_FIXUP_DS or mask MF_CALL
omcCommon	label	near
		push	di, si
		push	ax, bx			; save message, flags
		call	ImpexGetChildBlockAndFeatures
		pop	ax, si			; restore message, flags
		jc	done
		xchg	di, si			; child's OD => BX:SI
		call	ObjMessage
done:
		pop	bx, di, si
		ret
ObjMessage_child_call	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexGetChildOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of one of the children of the controller

CALLED BY:	EXTERNAL	
PASS:		ax	= message to pass
		*ds:di	= Import/ExportControl object
		es:di	= Import/ExportControl class
RETURN:		di	= offset of feature (0 if none)
		zero flag set if feature does not exist
DESTROYED:	nothing
SIDE EFFECTS:	
		None of the children may have an offset of zero.

PSEUDO CODE/STRATEGY:
		Get the features mask and call the class.

		The Import/ExportControlFeature corresponding to the
		child may be turned off by the app, in which case the
		app may intercept the message and return the offset
		of its own substitute child.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexGetChildOffset	proc	near
		uses	bx, cx, dx
		.enter
	;
	; Get the features mask and clear cx, which the message
	; handler will not touch if the child does not exist.
	;
		push	ax			; save message
		call	ImpexGetChildBlockAndFeatures
		pop	dx
		xchg	ax, dx			; dx <- features mask
						; ax <- message
		clr	cx
		call	ObjCallClassNoLock
		mov	di, cx			; di <- offset or 0
		tst	di
		jnz	done
		stc
done:
		.leave
		ret
ImpexGetChildOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a string in the Strings resource

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle of string

RETURN:		DS:SI	= Pointer to string
		BX	= Strings resource handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockString	proc	far
		uses	ax
		.enter
	
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]

		.leave
		ret
LockString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpcaseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upper-case a null-terminated string

CALLED BY:	FormatListSetFileSpec

PASS:		CX:DX	= Null-terminated string

RETURN:		CX:DX	= Null-terminated upper case string

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpcaseString	proc	near
		uses	ds, si
		.enter

		; Setup for call to localization routine
		;
		mov	ds, cx
		mov	si, dx
		clr	cx			; NULL-terminated
		call	LocalUpcaseString
		mov	cx, ds			; string back to CX:DX

		.leave
		ret
UpcaseString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFileSelectionInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a MSG_IMPORT_EXPORT_FILE_SELECTION_INFO to ourselves

CALLED BY:	INTERNAL

PASS:		ES	= Segment of Import/ExportControlClass
		*DS:SI	= Import/ExportControl object
		DI	= Chunk handle of GenFileSelector child

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendFileSelectionInfo	proc	near
		uses	ax, bx, cx, dx, di, bp
		.enter
	
		; Set up ImpexFileSelectionData
		;
		sub	sp, size ImpexFileSelectionData
		mov	bx, sp			; base of frame => SS:BX
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		mov	cx, ss
		mov	dx, bx			; selection buffer => CX:DX
		CheckHack <offset IFSD_selection eq 0>
		call	ObjMessage_child_call
		mov	ss:[bx].IFSD_type, bp
		mov	ax, MSG_GEN_PATH_GET
		mov	bp, bx
		add	bp, offset IFSD_path
		mov	dx, cx
		mov	cx, size IFSD_path
		call	ObjMessage_child_call
		mov	ss:[bx].IFSD_disk, cx	; store disk handle/ID

		; Now send message to ourselves (our superclass, really)
		;
		mov	ax, MSG_IMPORT_EXPORT_FILE_SELECTION_INFO
		mov	dx, ss
		mov	bp, bx			; params => DX:BP
		mov	di, offset ImportExportClass
		call	ObjCallSuperNoLock
		add	sp, size ImpexFileSelectionData
		
		.leave
		ret
SendFileSelectionInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Impex Import/Export utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitThreadInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the ImpexThreadInfo block

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass object
		CX	= ImpexAttrs
		DX	= message to send to GenFileSelector
		BP	= Chunk handle for FormatList
		DI	= Chunk handle for GenFileSelector
				ImportFileSelector
				ExportFileSelector

RETURN:		ES	= Segment of locked ImpexThreadInfo
		BX	= ImpexThreadInfo block, w/ fields initialized:
				ITI_handle
				ITI_state
				ITI_ignoreInput
				ITI_libraryDesc
				ITI_formatUI
				ITI_formatDesc
				ITI_appObject
				ITI_impexOD
				ITI_pathBuffer
				ITI_pathDisk
				ITI_formatName
			  Leaving the following to be initialized:
				ITI_notifySource
				ITI_appDest
				ITI_appMessage
				ITI_srcDestName
		Carry	= Set if error occurred

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/28/92		Initial version
		jenny	12/14/92	Save format name info for No Idea
		jenny	2/03/93		Changes for error handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitThreadInfoBlock	proc	near
		uses	di, si, ds
formatListChunk	local	word	push bp
impexError	local	word
libraryName	local	fptr
		.enter
	;
	; Allocate the ImpexThreadInfoBlock.
	;
		push	bp
		push	cx
		mov	ax, size ImpexThreadInfo
		mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
			    ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8))
		call	MemAlloc
		pop	cx
		LONG	jc	allocError
		push	di			; chunk handle FileSelector
		push	cx			; ImpexAttrs
		mov	es, ax
		mov	es:[ITI_handle], bx	; store handle away
	;
	; Initialize a whole bunch of data.
	;
		clr	{byte}es:[ITI_state]
		mov	ax, ATTR_IMPORT_EXPORT_TRANSPARENT_MODE
		call	ObjVarFindData
		jnc	continueInit
		or	es:[ITI_state], mask ITS_TRANSPARENT_IMPORT_EXPORT
continueInit:
		mov	bx, ds:[LMBH_handle]
		movdw	es:[ITI_impexOD], bxsi
		push	si
		call	MemOwner		; application process => BX
		call	GeodeGetAppObject	; application OD => BX:SI
		movdw	es:[ITI_appObject], bxsi
		pop	si
		pop	cx			; ImpexAttrs => CX
		mov	es:[ITI_ignoreInput], BB_TRUE
	;
	; Get the path for the source or destination file from the
	; ImportFileSelector or ExportFileSelector.
	;
		mov	ax, dx			; ax <- message to send 
		mov	cx, (size ITI_pathBuffer)
		mov	dx, es
		push	bp
		mov	bp, offset ITI_pathBuffer	; dx:bp <- buffer
		call	ObjMessage_child_call
		pop	bp
		mov	es:[ITI_pathDisk], cx
	;
	; Get the currently displayed format UI block handle.
	;
		call	ImpexDerefTempData
		mov	ax, ds:[bx].TIED_formatUI.handle
		mov	es:[ITI_formatUI], ax
	;
	; Now get the library & format descriptors.
	;
		mov	di, ss:[formatListChunk]
		mov	ax, MSG_FORMAT_LIST_GET_FORMAT_INFO
		call	ObjMessage_child_call	; data => CX & DX
		mov	bx, dx
		pop	di			; FileSelector chunk handle
		tst	ax			; any formats available ??
		LONG	jz	noFormats	; nope, so tell user
		cmp	cx, NO_IDEA_FORMAT	; undetermined file format
		je	noIdea
getDescr:
	;
	; Copy the format descriptor into the ITI block.
	;
		call	LockFormatDescriptor	; ImpexFormatDescriptor DS:DI
		mov	si, di
		mov	dx, di
		mov	di, offset ITI_formatDesc
		mov	cx, size ImpexFormatDescriptor
		rep	movsb
	;
	; If HandleNoIdeaFormat figured out the format for us, we save
	; the format name to tell the user later. Must copy the format
	; name separately from the rest of the descriptor since it's a label.
	;
		test	es:[ITI_state], mask ITS_IMPORTING_NO_IDEA
		jz	copyLibraryDescr
		mov	si, dx
		mov	di, ds:[si].IFD_formatNameLen
DBCS <		shl	di, 1						>
		mov	ax, size ImpexThreadInfo
		add	ax, di
		push	bx
		mov	bx, es:[ITI_handle]
		mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
			    ((mask HAF_ZERO_INIT) shl 8))
		call	MemReAlloc
		pop	bx
		jc	reAllocError
		mov	es, ax
		mov	cx, di			; cx <- format name size
		mov	di, offset ITI_formatName
		add	si, offset IFD_formatName		
		rep	movsb
copyLibraryDescr:
	;
	; Copy the library descriptor.
	;
		mov	si, dx
		mov	si, ds:[si].IFD_library
		mov	si, ds:[si]		; get ImpexLibraryDescriptor
		mov	di, offset ITI_libraryDesc
		mov	cx, size ImpexLibraryDescriptor
		rep	movsb
	;
	; Unlock the descriptor and return the ITI block handle.
	;
		mov	ax, es:[ITI_handle]	; ImpexThreadInfo handle => AX
		call	MemUnlock
		mov_tr	bx, ax			; ImpexThreadInfo handle => BX
		clc				; no errors
exit:
		pop	bp
		.leave
		ret
noIdea:
	;
	; Handle a "No Idea" format selection.
	;
		call	HandleNoIdeaFormat		
		or	es:[ITI_state], mask ITS_IMPORTING_NO_IDEA
		cmp	cx, NO_IDEA_FORMAT	; still no idea?
		jne	getDescr
	;
	; We have some sort of error. Ensure we set up the arguments
	; for the error message properly. Assume we want to show the
	; filename, unless we got some sort of translation library
	; loading error.
	;
		clr	ax			; free memory
		movdw	cxdx, ss:[libraryName]
		mov	bp, ss:[impexError]	; ImpexError => BP
		cmp	bp, IE_ERROR_INVALID_XLIB
		jbe	displayError
		mov	cx, es
		mov	dx, offset ITI_srcDestName
displayError:
		push	ax
		mov	ax, MSG_IMPORT_EXPORT_SHOW_ERROR
		call 	ObjCallInstanceNoLock
		pop	ax
		tst	ax
		je	returnError
		mov	bx, es:[ITI_handle]
		call	MemFree
returnError:
		stc
		jmp	exit
	;
	; Handle various error conditions
	;
reAllocError:
		mov	bp, IE_INSUFFICIENT_MEMORY
		clr	ax			; free memory
		jmp	displayError
allocError:
		mov	bp, IE_INSUFFICIENT_MEMORY
		mov	ax, 1			; skip memory free
		jmp	displayError
noFormats:
		mov	bp, IE_NO_FORMATS_AVAILABLE
		clr	ax			; free memory
		jmp	displayError
InitThreadInfoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNoIdeaFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to determine the format of the source file

CALLED BY:	InitThreadInfoBlock
		
PASS:		BX	- FormatInfoBlock
		*DS:SI	- ImportControlClass
		DI	- Chunk Handle for ImportFileSelector
		ES:0	- ImpexThreadInfo

RETURN:		CX 	- Format, NO_IDEA_FORMAT if an error has occurred

DESTROYED:	AX, DI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		MS	7/ 2/92		Initial version
		jenny	10/16/92	Changes for error handling
		jenny	2/03/93		Ditto

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandleNoIdeaFormat	proc	near
		uses	bx, dx, si, ds, es
		.enter inherit InitThreadInfoBlock
	;
	; Get the file.
	;
		call	GetSelectedFile		; ax <- opened file
						; dx <- error if carry set
		mov	ss:[impexError], dx
		mov	cx, NO_IDEA_FORMAT
		jc	exit
		mov_tr	cx, ax			; save file handle
		call	MemLock			; lock down FormatInfo block
		mov	ds, ax
	;		
	; Call each library to check if it supports this file format.
	;
		push	bx			; save FormatInfo Block
		mov_tr	ax, cx			; file to import
		mov	ss:[impexError], IE_NO_IDEA_FORMAT	; default
		call	ImportCheckFormat
		cmp	cx, NO_IDEA_FORMAT
		je	unlockFormatInfo
	;		
	; Get the element number of the appropriate format
	; descriptor in the chunk array of descriptors.
	;		
		mov	si, ds:[FI_formats]
		segmov	bx, cs			; callback routine
		mov	di, offset ImportGetFormatCallback
		call	ChunkArrayEnum		; ax <- element
		mov	cx, ax
EC <		cmp	cx, NO_IDEA_FORMAT				>
EC <		ERROR_Z TRANSLATION_LIB_RETURNED_BOGUS_FORMAT_NUMBER	>

unlockFormatInfo:
		pop	bx
		call	MemUnlock					
exit:
		.leave
		ret

HandleNoIdeaFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query the file selector for path and filename of the 
		selected File. Opens the file and returns the handle.	

CALLED BY:	HandleNoIdeaFormat
PASS:		DI	- Chunk Handle for ImportFileSelector
		DS:SI	- ImportControlClass
		ES:0	- ImpexThreadInfo
RETURN:		AX	- FileHandle
		DX	- Error if carry set
		carry set on error
DESTROYED:	CX, DX, DI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		MS	7/ 6/92		Initial version
		jenny	2/02/93		Changed to call GetAndSetPath

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSelectedFile	proc	near
		uses	bx, ds
		.enter
	;
	; Get the file path.
	;
		push	ds
		segmov	ds, es
		call	GetAndSetPath
		pop	ds
		jc	exit
	;
	; Get the file name.
	;
		push	bp
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		segmov	cx, es
		mov	dx, offset ITI_srcDestName
		call	ObjMessage_child_call
		pop	bp
	;
	; Open the file.
	;
		mov	ds, cx			; ds:dx <- fileName 
		mov	al, FILE_ACCESS_R or FILE_DENY_NONE
		call	FileOpen
		call	FilePopDir
		jc	fileOpenError
exit:
		.leave
		ret
fileOpenError:
		mov	dx, IE_FILE_ALREADY_OPEN
		cmp	ax, ERROR_SHARING_VIOLATION
		je	error
		mov	dx, IE_TOO_MANY_OPEN_FILES
		cmp	ax, ERROR_TOO_MANY_OPEN_FILES
		je	error
		mov	dx, IE_FILE_MISC_ERROR
error:
		stc
		jmp	exit
GetSelectedFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportCheckFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call Translation Libraries to try to determine what format
		the file is.

CALLED BY:	HandleNoIdeaFormat	

PASS:		AX	- file handle
		DS:0	- FormatInfo
		ES:0	- ImpexThreadInfo

RETURN:		SS:BP	- inherited variables set by ImportCheckFormatCallback
		CX	- format number - NO_IDEA_FORMAT if undetermined
		DX  	- chunk handle of library descriptor if format found

DESTROYED:	BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		MS	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportCheckFormat	proc	near
	;
	; Call all the translation libraries until one recognizes the
	; format or we've called them all.
	;
		mov	si, ds:[FI_libraries] 	; ImpexLibraryDescriptors
		segmov	bx, cs			; bx:di = callback routine
		mov	di, offset ImportCheckFormatCallback
		mov	cx, NO_IDEA_FORMAT	; assume no libraries
		clr	dx			; no previously loaded library
		call	ChunkArrayEnum
                mov	bx, ax			; bx = file handle
		call	FileClose
	;
	; If the format is undetermined, there may still be a
	; library loaded; if there is, DX is its handle.
	;
		cmp	cx, NO_IDEA_FORMAT
		jne	done
		mov	bx, dx
		call	ImpexFreeLibrary
done:
		ret
ImportCheckFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportCheckFormatCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the Library TransGetFormat routine to check if 
		the given file is of that library's format.

CALLED BY:	Callback routine supplied to ChunkArrayEnum	

PASS:		SS:BP	= inherited variables on stack
		DS:SI	= chunk array of ImpexLibraryDescriptors
		DS:DI   = current element in the array
		DX	= handle of previously loaded library (if any)
		AX	= file handle to pass to TransGetFormat routine
		
RETURN:		SS:BP	= inherited variables set if error
		CX	= format number - NO_IDEA_FORMAT if undetermined
		DX  	= chunk handle of library descriptor if format found
		set carry to end enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		MS	7/ 6/92		Initial version
		jenny	10/16/92	Handles errors returned from trans lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportCheckFormatCallback	proc	far

		uses	ax, bx, si, di, bp
		.enter	inherit	InitThreadInfoBlock
	;
	; Load the current translation library and call its TransGetFormat
	; routine to see if it recognizes the file format.
	;
		push	di, si			; save chunk array
		mov_tr	si, ax			; si = file handle
		mov	di, ds:[di]
		mov	di, ds:[di]
		mov	cx, NO_IDEA_FORMAT	; set to NO_IDEA_FORMAT
		call	ImpexLoadLibrary	; bx = handle
		jc	loadError		; couldn't load library	
		push	bx, dx			; save library handles
		mov	ax, TR_GET_FORMAT
		call	ProcGetLibraryEntry	; call translation library
		call	ProcCallFixedOrMovable
		push	ax, cx			; save returned values
	;
	; Reset file back to the beginning.
	;
		mov	al, FILE_POS_START
		clr	cx, dx			; offset
		mov	bx, si			; FileHandle
		call	FilePos			; reposition file pointer
	;
	; Check values returned from TransGetFormat.
	;
		pop	ax, cx			; restore returned values
		pop	dx, bx			; restore library handles
		pop	di, si			; restore chunk array	
		tst	ax			; ax = TransError or 0
		jnz	libError
		cmp	cx, NO_IDEA_FORMAT		
		jne	foundFormat
freeLastLib:
	;
	; Free any previously loaded library.
	;
		call	ImpexFreeLibrary
		clc				; indicates format not found
		jmp	done
foundFormat:
	;
	; Free any libraries still captive and depart, library
	; descriptor chunk handle in hand.
	;
		call	ImpexFreeLibrary	
		mov	bx, dx			
		call	ImpexFreeLibrary	; free current Library
		mov	dx, ds:[di]		; return chunk handle
		stc				; indicates done
done:		
		.leave
		ret
loadError:
		add	sp, 4			; fix up stack
		clr	dx			; no library to free

		mov	ss:[impexError], IE_COULD_NOT_LOAD_XLIB
		CheckHack <(offset ILD_fileName) eq 0>
		movdw	ss:[libraryName], dsdi
		jmp	done
libError:
EC <		cmp	cx, NO_IDEA_FORMAT				>
EC <		ERROR_NE IMPEX_IF_TRANS_ERROR_THEN_ALSO_NO_IDEA_FORMAT	>
	;
	; Save an ImpexError corresponding to the TransError, and go
	; on to check whether the file format is supported by some
	; other library. We don't want to let, say, a memory allocation
	; error in one library's format checking routine prevent us
	; from discovering that the file format is supported by some
	; other library which doesn't have to allocate memory to run
	; its format check.
	;
		cmp	ax, TE_OUT_OF_MEMORY	; probably a memory error
		mov	ss:[impexError], IE_INSUFFICIENT_MEMORY
		je	freeLastLib
		mov	ss:[impexError], IE_FILE_MISC_ERROR
		jmp	freeLastLib

ImportCheckFormatCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFormatCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Matches up the ImpexLibraryDescriptor chunk handle from
		the Library chunk array to the corresponding chunk handle in
		the ImpexFormatDescriptor in order to extract the correct
		element number for that format

CALLED BY:	Callback routine to ChunkArrayEnum

PASS:		*DS:SI	= FormatList ChunkArray
		DS:DI	= Chunk Array Element
		CX	= Library Format Number
		DX	= ImpexFormatDescriptor Chunk Handle	

RETURN:		AX	= Element Number of Format Descriptor
		carry set if successful

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		MS	7/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportGetFormatCallback	proc	far
		uses	bx
		.enter
	
		mov	ax, NO_IDEA_FORMAT	; default to unsuccessful
		mov	bx, ds:[di]		; dereference element
		mov	bx, ds:[bx]
		cmp	ds:[bx].IFD_library, dx	; does Library chunk matche?
		clc				; clear carry if no match
		jne	exit	
		cmp	ds:[bx].IFD_formatNumber, cx
		clc				; check if format num correct
		jne	exit
	;
	; found a match for library and format
	;
		call	ChunkArrayPtrToElement	; returns ax = element number
		stc				
exit:
		.leave
		ret
ImportGetFormatCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexLoadAndCloseImpexLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the executable file for a loaded geode to make sure
		it no longer references a floppy that's going to be removed.

		NOTE: This code should be getting the geode lock to make sure
		the thing being mangled isn't loaded or unloaded. we assume,
		however, that the thing in question is a library that
		will only be loaded or unloaded by us, so this should be safe.

CALLED BY:	GLOBAL
PASS:		bx	= handle of geode in question
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	All resources for the geode are loaded into memory and marked
     		non-discardable.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 1/94    	Copied verbatim from PCMCIACloseGeodeFile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ALLOW_FLOPPY_BASED_LIBS	;----------------------------------------------

ImpexLoadAndCloseImpexLibrary	proc	near
		uses	ax, cx, si, ds, es
		.enter
	;
	; Lock down the core block, as we'll be abusing it in a moment.
	; 
		call	MemLock
		mov	ds, ax
	;
	; If the geode doesn't actually have its geode file open, do nothing.
	; 
		test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
		jz	done
	;
	; We'll be needing the kernel's dgroup, too.
	; 
		mov	ax, SGIT_HANDLE_TABLE_SEGMENT
		call	SysGetInfo
		mov	es, ax
	;
	; We can only cope with single-launchable geodes, else we'd have to
	; have code here to locate the other instances and aprise them of the
	; change in state, bring in their non-shared resources, etc.
	; 
EC <		test	ds:[GH_geodeAttr], mask GA_MULTI_LAUNCHABLE	>
EC <		ERROR_NZ -1						>
	;
	; Make sure all resources are marked non-discardable, then bring into
	; memory any that are currently discarded.
	;
	; NOTE: IF ANYTHING IS AN OBJECT RESOURCE IT WILL *NOT* BE RELOCATED.
	; 
		mov	cx, ds:[GH_resCount]
		mov	si, ds:[GH_resHandleOff]
resourceLoop:
		lodsw			; ax <- handle of next
		mov_tr	bx, ax
		andnf	es:[bx].HM_flags, not mask HF_DISCARDABLE

		test	es:[bx].HM_flags, mask HF_DISCARDED
		loope	resourceLoop
		jz	doneCloseFile

		call	MemLock		; force it into memory
		call	MemUnlock	; then let it go
		jcxz	doneCloseFile	; => that was the last one...
		jmp	resourceLoop	; else go process the next

doneCloseFile:
	;
	; Now mark the file as being gone, fetch its handle, and close it.
	; 
		andnf	ds:[GH_geodeAttr], not mask GA_KEEP_FILE_OPEN
		clr	bx
		xchg	ds:[GH_geoHandle], bx
		clr	al
		call	FileClose
done:
	;
	; Release the core block and return.
	; 
		mov	bx, ds:[GH_geodeHandle]
		call	MemUnlock
		.leave
		ret
ImpexLoadAndCloseImpexLibrary	endp

endif	; if ALLOW_FLOPPY_BASED_LIBS ------------------------------------------

ImpexUICode	ends
