
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
		
	$Id: documentImpex.asm,v 1.1 97/04/04 15:48:03 newdeal Exp $

------------------------------------------------------------------------------@

if _USE_IMPEX

ImpexCode	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ImpexImportFromTransferItem

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ss:bp	- ptr to ImpexTranslationParams

RETURN:		carry	- set if error

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

GeoCalcDocumentImport	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_IMPORT
	.enter

	mov	ax, MSG_SSHEET_PASTE_FROM_DATA_FILE
	mov	cx, ss:[bp].ITP_transferVMFile
	mov	dx, ss:[bp].ITP_transferVMChain.high	; dx<-SSMDAS_hdrBlkVMHan
	push	bp
	mov	bp, ss:[bp].ITP_transferVMChain.low
	mov	di, mask MF_CALL
	call	SendToDocSpreadsheet
	pop	bp

	.leave
	ret
GeoCalcDocumentImport	endm


GeoCalcDocumentExport	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_EXPORT
	push	ax, ds:[LMBH_handle], si, es

if	_SPLIT_VIEWS
	;
	; If we support split views, then we need to offer the user
	; a choice - either export the unlocked area or the entire
	; spreadsheet. If it is the entire area, then we will unlock
	; the cells.
	;
	test	ds:[di].GCDI_flags, mask GCDF_SPLIT
	jz	continue			; if not split, don't bother
	clr	ax
	pushdw	axax				; SDOP_helpContext
	pushdw	axax				; SDOP_customTriggers
	pushdw	axax				; SDOP_stringArg2
	pushdw	axax				; SDOP_stringArg1
	mov	bx, handle unsplitForExport
	mov	ax, offset unsplitForExport
	pushdw	bxax				; SDOP_customString
	mov	ax, mask CDBF_SYSTEM_MODAL or \
		    CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
		    GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
	push	ax				; SDOP_customFlags
	call	UserStandardDialogOptr
	cmp	ax, IC_YES
	jne	continue
	push	bp
	mov	ax, MSG_GEOCALC_DOCUMENT_UNSPLIT_VIEWS
	call	ObjCallInstanceNoLock
	pop	bp
continue:
endif

	;
	; Now export the data
	;
	mov	ax, MSG_SSHEET_EXPORT_FROM_DATA_FILE
	mov	cx, ss:[bp].ITP_transferVMFile
	mov	dx, ss:[bp].ITP_transferVMChain.high
	push	bp
	mov	bp, ss:[bp].ITP_transferVMChain.low
	mov	di, mask MF_CALL
	call	SendToDocSpreadsheet	; dx <- transferHdrVMHan
	pop	bp

	mov	ss:[bp].ITP_transferVMChain.high, dx
	clr	ss:[bp].ITP_transferVMChain.low

	mov	ss:[bp].ITP_clipboardFormat, CIF_SPREADSHEET
	mov	ss:[bp].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS

	;
	; Send notification back to ExportControl that we're done
	;
	call	ImpexImportExportCompleted

	pop	ax, bx, si, es
	call	MemDerefDS
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock

GeoCalcDocumentExport	endm

ImpexCode	ends

endif
