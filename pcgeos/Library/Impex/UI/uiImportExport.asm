COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiImportExport.asm

AUTHOR:		Don Reeves, Jun  1, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/ 1/92		Initial revision

DESCRIPTION:
	Contains code implementing the ImportExportClass	

	$Id: uiImportExport.asm,v 1.1 97/04/04 22:34:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Detach stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve the variant superclass for the ImportExport object

CALLED BY:	GLOBAL (MSG_META_RESOLVE_VARIANT_SUPERCLASS)

PASS:		ES	= Segment of ImportExportClass
		*DS:SI	= ImportExportClass object
		DS:DI	= ImportExportClassInstance
		CX	= Master offset
		AX	= Message

RETURN:		CX:DX	= Superclass to use

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportResolveVariantSuperclass	method dynamic	ImportExportClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		; See if this is our level or not. If not, call superclass
		;
		cmp	cx, ImportExport_offset
		je	returnSuper
		mov	di, offset ImportExportClass
		GOTO	ObjCallSuperNoLock

		; Let our superclass handle the request
returnSuper:
		mov	cx, segment GenControlClass
		mov	dx, offset GenControlClass
		ret
ImportExportResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify any import/export threads to exit as soon as possible

CALLED BY:	GLOBAL (MSG_META_DETACH)

PASS:		*DS:SI	= ImportExportClass object
		CX	= Caller's ID
		DX:BP	= Caller's OD

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:
		We need to ensure that the application doesn't go away
		prior to the impex thread(s) getting destroyed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportDetach	method dynamic	ImportExportClass, MSG_META_DETACH
		.enter

		; Remove ourselves from active list (added when threads
		; created -- AND by GenControlClass when UI generated)
		;
		push	cx, dx, bp, si
		sub	sp, size GCNListParams	; create stack frame
		mov	bp, sp
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
		mov	ax, ds:[LMBH_handle]
		mov	ss:[bp].GCNLP_optr.handle, ax
		mov	ss:[bp].GCNLP_optr.chunk, si
		mov	ax, MSG_META_GCN_LIST_REMOVE
		mov	dx, size GCNListParams	; create stack frame
		call	GenCallApplication
		add	sp, size GCNListParams	; fix stack
		pop	cx, dx, bp, si

		; Initialize detach, notify all threads, and boogie
		;		
		mov	ax, MSG_META_DETACH
		call	ObjInitDetach
		call	ImpexThreadListAppExiting
		mov	di, offset ImportExportClass
		call	ObjCallSuperNoLock
		call	ObjEnableDetach

		.leave
		ret
ImportExportDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete killed thread from thread list and acknowledge 
		that it has been killed.

PASS:		ES	= Segment of ImportExportClass
		*DS:SI	= ImportExportClass object
		DS:DI	= ImportExportClassInstance
		CL	= ImpexThreadState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportAck	method	dynamic	ImportExportClass, MSG_META_ACK

		; Send acknowledgment to superclass, unless the thread
		; was exiting all by itself (and the app isn't exiting).
		;
		test	cl, mask ITS_APP_DETACHING
		jz	done
		mov	di, offset ImportExportClass
		GOTO	ObjCallSuperNoLock
done:
		ret
ImportExportAck	endm

ProcessCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** ImportExport methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportUnbuildNormalUIIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't allow Import & Export dialogs to be unbuilt

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE)

PASS:		*DS:SI	= ImportExportClass object
		DS:DI	= ImportExportClassInstance
		CX	= Handle of child block

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Swallow this message, as the current code assumes the
		any options displayed by the specific translation
		library will be available by the time the Impex
		thread is initiated. At some point in the future,
		the underlying problem should be fixed.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/28/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportUnbuildNormalUIIfPossible	method dynamic	ImportExportClass,
			 MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE
		.enter

		.leave
		ret
ImportExportUnbuildNormalUIIfPossible	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportFreeLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the passed library

CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_FREE_LIBRARY)

PASS:		CX	= Library handle

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportFreeLibrary	method ImportExportClass, MSG_IMPORT_EXPORT_FREE_LIBRARY
		mov	bx, cx
		call	GeodeFreeLibrary
		ret
ImportExportFreeLibrary	endm

ImpexUICode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Error stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ErrorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportExportShowError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error dialog box w/o blocking the UI thread

CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_SHOW_ERROR)

PASS:		*DS:SI	= Optr of ImportExportClass object
		BP	= ImpexError
		CX:DX	= Optional argument string (NULL-terminated)

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/28/92		Initial version
		jenny	11/4/92		Moved some code to ShowDialog

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportExportShowError	method	dynamic	ImportExportClass,
				 	MSG_IMPORT_EXPORT_SHOW_ERROR
		uses	cx, dx, bp
		.enter

		; Check to see if we are not supposed to show any errors.
		;
		mov	ax, ATTR_IMPORT_EXPORT_HIDE_ERRORS
		call	ObjVarFindData
		jc	done

		; Check to see if we are operating in transparent mode
		; If so, we need to swap a few error messages. If the
		; list here starts getting too long, then just create
		; a new table of error messages for transparent mode.
		;
		mov	ax, ATTR_IMPORT_EXPORT_TRANSPARENT_MODE
		call	ObjVarFindData
		jnc	showError
		cmp	bp, IE_NO_IDEA_FORMAT
		jne	showError
		mov	bp, IE_TRANSPARENT_NO_IDEA_FORMAT

		; Lock the string down, display the error, and unlock
		; the string.
showError:
		call	LockImpexError

		mov	bx, ds:[LMBH_handle]	; handle owned by app => BX
		call	ShowDialog
		mov	bx, handle Strings
		call	MemUnlock
done:
		.leave
		ret
ImportExportShowError	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockImpexError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an impex error string

CALLED BY:	INTERNAL

PASS:		BP	= ImpexError

RETURN:		AX	= Word value for SDP_customFlags
		BX	= Strings handle
		ES:DI	= Custom string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockImpexError	proc	far
		.enter
	
EC <		cmp	bp, ImpexError		; ensure valid error	>
EC <		ERROR_AE ILLEGAL_IMPEX_ERROR_PASSED			>
EC <		test	bp, 0x3			; we count by 4		>
EC <		ERROR_NZ ILLEGAL_IMPEX_ERROR_PASSED			>
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		assume	es:Strings
		mov	di, es:[ImpexErrorTable]
		mov	ax, es:[di][bp+2]	; flags => AX
		mov	di, es:[di][bp+0]	
		mov	di, es:[di]		; error string => ES:DI
		assume	es:nothing

		.leave
		ret
LockImpexError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a dialog box w/o blocking the UI thread

CALLED BY:	INTERNAL	ImportExportShowError

PASS:		BX:SI	= OD of import or export controller
		BX	= handle owned by the app
		AX	= word value for SDP_customFlags
		ES:DI	= Custom string
		CX:DX	= First optional argument string (NULL-terminated)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jenny	11/4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShowDialog	proc	far
		.enter
	;
	; Set up the structure, and away we go. Note that if this is
	; an import, we need to send off a MSG_IMPORT_CONTROL_CANCEL
	; to the controller once this error message box is down so as
	; to return to the app's New/Open dialog box. If this is an
	; export, well, the message won't hurt anything.
	;
		sub	sp, size GenAppDoDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, ax
		movdw	ss:[bp].SDP_customString, esdi
		movdw	ss:[bp].SDP_stringArg1, cxdx
		movdw	ss:[bp].GADDP_finishOD, bxsi 
		mov	ss:[bp].GADDP_message, MSG_IMPORT_CONTROL_CANCEL
		clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
		tst	bx
		jne	skip
		mov     bx, ds:[LMBH_handle]    ; handle owned by app => BX
skip:
		call	MemOwner
		call	GeodeGetAppObject	; app object OD => BX:SI
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	dx, size GenAppDoDialogParams
		call	ObjMessage		; dialog box OD => CX:DX
		add	sp, size GenAppDoDialogParams
	;
	; Ensure the dialog box appears on top.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE		
		movdw	bxsi, cxdx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
ShowDialog	endp

ErrorCode	ends
