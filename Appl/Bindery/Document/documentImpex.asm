COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentImpex.asm

ROUTINES:
	Name			Description
	----			-----------
    INT GetFirstArticle		Handle a document being imported

    INT UpdateFromPSI		Update the page setup information for the
				first section from a PageSetupInfo
				structure

METHODS:
	Name			Description
	----			-----------
    StudioDocumentImport		Handle a document being imported

				MSG_GEN_DOCUMENT_IMPORT
				StudioDocumentClass

    StudioDocumentFinishImport	Finish importing

				MSG_STUDIO_DOCUMENT_FINISH_IMPORT
				StudioDocumentClass

    StudioDocumentExport		Export text

				MSG_GEN_DOCUMENT_EXPORT
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the track scrolling code

	$Id: documentImpex.asm,v 1.1 97/04/04 14:39:29 newdeal Exp $

------------------------------------------------------------------------------@

DocMiscFeatures segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentImport -- MSG_GEN_DOCUMENT_IMPORT
						for StudioDocumentClass

DESCRIPTION:	Handle a document being imported

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	ss:bp - ImpexTranslationParams

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/12/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentImport	method dynamic	StudioDocumentClass,
						MSG_GEN_DOCUMENT_IMPORT

	call	IgnoreUndoAndFlush
	call	LockMapBlockES
	call	SuspendDocument
	call	VMUnlockES

	; First we must set the page setup for the section

	push	bp
	mov	bx, ss:[bp].ITP_transferVMFile
	mov	ax, ss:[bp].ITP_transferVMChain.high
	call	VMLock				;lock transfer header
	mov	es, ax
	mov	ax, es:TTBH_pageSetup.high	;get page setup block
	call	VMUnlock

	call	VMLock				;lock page setup info
	mov	es, ax
	clr	di				;es:di = page setup info
	call	UpdateFromPSI
	call	VMUnlock
	pop	bp

	; Next we paste in the text

	push	bp
	push	si
	call	GetFirstArticle			;bxsi = article

	mov	cx, ss:[bp].ITP_transferVMFile
	mov	ax, ss:[bp].ITP_transferVMChain.high
	mov	dx, size CommonTransferParams
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].CTP_range.VTR_start, 0
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	clr	ss:[bp].CTP_pasteFrame
	mov	ss:[bp].CTP_vmFile, cx
	mov	ss:[bp].CTP_vmBlock, ax

	; Send a msg to the text object to import

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	clr	di
	call	ObjMessage

	add	sp, size CommonTransferParams
	
	pop	si
	pop	bp

	; we need to queue our response to avoid latent things on the
	; queue that would force the document dirty after the save

	mov	ax, MSG_STUDIO_DOCUMENT_FINISH_IMPORT
	mov	bx, ds:[LMBH_handle]
	mov	dx, size ImpexTranslationParams
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage

	mov	cx, di
	clr	dx				;np message flags
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	call	LockMapBlockES
	call	UnsuspendDocument
	call	VMUnlockES

	; Set the selection to be the start of the text

	push	si
	call	GetFirstArticle
	mov	ax, MSG_VIS_TEXT_SELECT_START
	clr	di
	call	ObjMessage

	; force the object dirty so that the selection is saved

	push	ds
	call	ObjLockObjBlock
	mov	ds, ax
	call	ObjMarkDirty
	call	MemUnlock
	pop	ds

	pop	si

	call	AcceptUndo

	clc
	ret

StudioDocumentImport	endm

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFirstArticle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		*ds:si - document
RETURN:		^lbx:si - article		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFirstArticle		proc	far
	uses	ax, cx
	.enter

	push	si, ds
	call	LockMapBlockDS
	clr	ax
	mov	si, offset ArticleArray
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].AAE_articleBlock
	call	VMUnlockDS
	pop	si, ds

	call	StudioVMBlockToMemBlock
	mov	bx, ax
	mov	si, offset ArticleText		;bxsi = article

	.leave
	ret
GetFirstArticle		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateFromPSI

DESCRIPTION:	Update the page setup information for the first section
		from a PageSetupInfo structure

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es:di - PageSetupInfo

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
UpdateFromPSI	proc	near	uses ax, bx, cx, dx, si, di, bp, es
	.enter

	; change the page size

	sub	sp, size PageSizeReport
	mov	bp, sp
	clr	ax
	mov	ss:[bp].PSR_width.high, ax
	mov	ss:[bp].PSR_height.high, ax

	mov	ax, es:[di].PSI_pageSize.XYS_width
	call	forcePageDimensionLegal
	mov	ss:[bp].PSR_width.low, ax
	mov	ax, es:[di].PSI_pageSize.XYS_height
	call	forcePageDimensionLegal
	mov	ss:[bp].PSR_height.low, ax

	mov	ax, es:[di].PSI_layout
	mov	ss:[bp].PSR_layout, ax
	mov	ax, MSG_PRINT_REPORT_PAGE_SIZE
	call	ObjCallInstanceNoLock
	add	sp, size PageSizeReport

	mov	bp, di				;es:bp = PageSetupInfo
	push	ds
	push	es
	call	LockMapBlockES
	clr	ax
	call	SectionArrayEToP_ES		;es:di = section array
	pop	ds				;ds = page setup block

	mov	ax, ds:[bp].PSI_numColumns
	tst	ax
	jnz	10$
	inc	ax
10$:
	cmp	ax, MAXIMUM_NUMBER_OF_COLUMNS
	jbe	20$
	mov	ax, MAXIMUM_NUMBER_OF_COLUMNS
20$:
	mov	es:[di].SAE_numColumns, ax

	mov	ax, ds:[bp].PSI_columnSpacing
	cmp	ax, MINIMUM_COLUMN_SPACING
	jae	30$
	mov	ax, MINIMUM_COLUMN_SPACING
30$:
	cmp	ax, MAXIMUM_COLUMN_SPACING
	jbe	40$
	mov	ax, MAXIMUM_COLUMN_SPACING
40$:
	mov	es:[di].SAE_columnSpacing, ax

	mov	ax, ds:[bp].PSI_leftMargin
	call	forceMarginLegal
	mov	es:[di].SAE_leftMargin, ax

	mov	ax, ds:[bp].PSI_topMargin
	call	forceMarginLegal
	mov	es:[di].SAE_topMargin, ax

	mov	ax, ds:[bp].PSI_rightMargin
	call	forceMarginLegal
	mov	es:[di].SAE_rightMargin, ax

	mov	ax, ds:[bp].PSI_bottomMargin
	call	forceMarginLegal
	mov	es:[di].SAE_bottomMargin, ax
	pop	ds

	call	RecalculateSection
	call	VMDirtyES
	call	VMUnlockES			;unlock map block

	.leave
	ret

;---

forceMarginLegal:
	cmp	ax, MINIMUM_MARGIN_SIZE
	jae	1000$

	mov	ax, MINIMUM_MARGIN_SIZE
1000$:
	cmp	ax, MAXIMUM_MARGIN_SIZE
	jbe	2000$
	mov	ax, MAXIMUM_MARGIN_SIZE
2000$:
	retn

;---

forcePageDimensionLegal:
	cmp	ax, MINIMUM_PAGE_WIDTH_VALUE
	jae	3000$
	mov	ax, MINIMUM_PAGE_WIDTH_VALUE
3000$:
	cmp	ax, MAXIMUM_PAGE_WIDTH_VALUE
	jbe	4000$
	mov	ax, MAXIMUM_PAGE_WIDTH_VALUE
4000$:
	retn

UpdateFromPSI	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentFinishImport -- MSG_STUDIO_DOCUMENT_FINISH_IMPORT
							for StudioDocumentClass

DESCRIPTION:	Finish importing

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	bp - ImpexTranslationParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/25/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentFinishImport	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_FINISH_IMPORT

	mov	di, offset StudioDocumentClass
	mov	ax, MSG_GEN_DOCUMENT_IMPORT
	GOTO	ObjCallSuperNoLock

StudioDocumentFinishImport	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentExport -- MSG_GEN_DOCUMENT_EXPORT
						for StudioDocumentClass

DESCRIPTION:	Export text

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	ss:bp - ImpexTranslationParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/12/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentExport	method dynamic	StudioDocumentClass,
						MSG_GEN_DOCUMENT_EXPORT

	push	ax, ds:[LMBH_handle], si, es

	push	bp
	mov	bx, ss:[bp].ITP_transferVMFile
	push	bx
	push	si
	mov	dx, size CommonTransferParams
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].CTP_range.VTR_start, 0
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	clr	ss:[bp].CTP_pasteFrame
	mov	ss:[bp].CTP_vmFile, bx
	clr	ss:[bp].CTP_vmBlock

	; Send a msg to the text object to export

	call	GetFirstArticle		;bxsi = article
	mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage			;ax = vm block
	add	sp, size CommonTransferParams
	pop	si
	pop	bx				;bx = file

	; Lock down the TextTransferBlockHeader, and add a block that contains
	; the page setup information.

	push	ax
	call	VMLock
	mov	es, ax

	; Allocate a block to hold the PageSetupInfo structure

	clr	ax
	mov	cx, size PageSetupInfo
	call	VMAlloc
	mov	es:[TTBH_pageSetup].high, ax
	clr	es:[TTBH_pageSetup].low
	call	VMDirty
	call	VMUnlock

	; Initialize the PageSetupInfo structure to reflect the first section

	call	VMLock
	push	bp
	mov	es, ax				;es = PageSetupInfo to set
	clr	es:PSI_meta.VMCL_next

	call	LockMapBlockDS
	mov	si, offset SectionArray
	clr	ax
	call	ChunkArrayElementToPtr		;ds:di = section data

	movdw	dxax, ds:MBH_pageSize
	movdw	es:PSI_pageSize, dxax

	mov	ax, ds:MBH_pageInfo
	mov	es:PSI_layout, ax

	mov	ax, ds:[di].SAE_numColumns
	mov	es:PSI_numColumns, ax

	mov	ax, ds:[di].SAE_columnSpacing
	mov	es:PSI_columnSpacing, ax

	mov	ax, ds:[di].SAE_leftMargin
	mov	es:PSI_leftMargin, ax

	mov	ax, ds:[di].SAE_topMargin
	mov	es:PSI_topMargin, ax

	mov	ax, ds:[di].SAE_rightMargin
	mov	es:PSI_rightMargin, ax

	mov	ax, ds:[di].SAE_bottomMargin
	mov	es:PSI_bottomMargin, ax

	call	VMUnlockDS

	pop	bp
	call	VMDirty
	call	VMUnlock

	; Send message back to export control, notifying it that we're done

	pop	ax	;ax <- VMChain of newly created text transfer format
	pop	bp			; SS:BP <- ImpexTranslationParams
	mov	ss:[bp].ITP_transferVMChain.high, ax
	clr	ss:[bp].ITP_transferVMChain.low

	mov	ss:[bp].ITP_clipboardFormat, CIF_TEXT
	mov	ss:[bp].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS

	call	ImpexImportExportCompleted

	pop	ax, bx, si, es
	call	MemDerefDS
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentExport	endm

DocMiscFeatures ends
