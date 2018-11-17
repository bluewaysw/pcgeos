COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentSetup.asm

AUTHOR:		Gene Anderson, Aug 17, 1992

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/17/92		Initial revision


DESCRIPTION:
	

	$Id: documentSetup.asm,v 1.1 97/04/04 15:48:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentPrint	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentChangePageSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change Page Setup for a GeoCalc document

CALLED BY:	MSG_GEOCALC_DOCUMENT_CHANGE_PAGE_SETUP
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentChangePageSetup		method dynamic GeoCalcDocumentClass,
					MSG_GEOCALC_DOCUMENT_CHANGE_PAGE_SETUP
	;
	; Lock the map block and dirty it for our changes
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di <- gen instance data
	mov	bx, ds:[di].GDI_fileHandle	;bx <- VM file handle
	call	DBLockMap
	call	DBDirty
	mov	di, es:[di]			;es:di <- ptr to map
	;
	; Get the starting page
	;
	push	si
	GetResourceHandleNS	GCPrintStartPage, bx
	mov	si, offset GCPrintStartPage
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	messageCall
	mov	es:[di].CMB_pageSetup.CPSD_startPage, dx
	pop	si
	;
	; Get the print flags
	;
	push	si
	GetResourceHandleNS	GCSetupOptionsGroup, bx
	mov	si, offset GCSetupOptionsGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	messageCall
	mov	es:[di].CMB_pageSetup.CPSD_flags, ax
	pop	si
	;
	; Unlock the map block
	;
	call	DBUnlock
	;
	; Update the UI
	;
	call	UpdateDocumentState
	ret

messageCall:
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	retn
GeoCalcDocumentChangePageSetup		endm

DocumentPrint	ends

Document	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDocumentState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update GeoCalc's idea of the document state

CALLED BY:	GeoCalcDocumentChangePageSetup(),
		GeoCalcDocumentGainedTargetExcl()
PASS:		*ds:si - GeoCalcDocument object
RETURN:		none
DESTROYED:	ax, bx, dx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDocumentState		proc	far
	class	GeoCalcDocumentClass
	.enter

	;
	; Tell the application about any document change
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di <- gen instance data
	mov	bx, ds:[di].GDI_fileHandle	;bx <- VM file handle
	call	DBLockMap
	mov	cx, es
	mov	di, es:[di]			;es:di <- ptr to map block
	lea	dx, es:[di].CMB_pageSetup	;cx:dx <- ptr to page setup
ifdef GPC
	push	es:[di].CMB_flags
	mov	ax, MSG_GEOCALC_APPLICATION_SET_DOCUMENT_STATE
	call	GenCallApplication
	pop	cx
	mov	ax, MSG_GEOCALC_APPLICATION_UPDATE_SPLIT_STATE
	call	GenCallApplication
else
	mov	ax, MSG_GEOCALC_APPLICATION_SET_DOCUMENT_STATE
	call	GenCallApplication
endif
	call	DBUnlock

	.leave
	ret
UpdateDocumentState		endp

Document	ends
