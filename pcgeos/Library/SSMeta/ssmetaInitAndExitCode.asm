
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ssmetaInitAndExitCode.asm

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	SSMetaInitForStorage
	SSMetaInitForRetrieval
	SSMetaInitForCutCopy
	SSMetaInitForPaste
	SSMetaDoneWithCutCopy
	SSMetaDoneWithPaste
	SSMetaSeeIfScrapPresent
	InitSSMetaStruc
	InitSSMetaHeaderBlock
	InitSSMetaDataArrayRecord
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
		
	$Id: ssmetaInitAndExitCode.asm,v 1.1 97/04/07 10:44:12 newdeal Exp $

-------------------------------------------------------------------------------@


SSMetaCode	segment	resource

;*******************************************************************************
;
;	"INIT FOR" ROUTINES
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaInitForStorage

DESCRIPTION:	If you DO NOT plan to use the clipboard, call this to initialize
		the SSMetaStruc (in preparation for calls to
		SSMetaDataArrayAddEntry and other storage routines).

		If you DO plan to use the clipboard, call SSMetaInitForCutCopy
		instead. It lessens your work by dealing with the clipboard.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - uninitialized SSMetaStruc
		bx - VM file handle in which to create the ssmeta header and
		     data arrays
		ax:cx - CIH_sourceID field

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaInitForStorage	proc	far	uses	ax,cx,es,di
	.enter

	;-----------------------------------------------------------------------
	; init struc, stuff fields

	mov	es, dx				; es:bp <- ssmeta struc
	call	InitSSMetaStruc			; zero init, stuff signature
	mov	es:[bp].SSMDAS_vmFileHan, bx
	mov	es:[bp].SSMDAS_sourceID.high, ax
	mov	es:[bp].SSMDAS_sourceID.low, cx

	;-----------------------------------------------------------------------
	; create the SSMetaHeaderBlock

	call	InitSSMetaHeaderBlock

	.leave
	ret
SSMetaInitForStorage	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaInitForRetrieval

DESCRIPTION:	If you DO NOT plan to use the clipboard, call this to
		initialize the SSMetaStruc (in preparation for
		calls to SSMetaDataGetFirstEntry and other retrieval routines).

		If you DO plan to use the clipboard, call SSMetaInitForPaste
		instead. It lessens your work by dealing with the clipboard.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - uninitialized SSMetaStruc
		bx - VM file handle in which to create the ssmeta header and
		     data arrays
		ax - VM block handle of the SSMetaHeaderBlock

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaInitForRetrieval	proc	far	uses	bx,cx,dx,ds,es
	.enter

	mov	es, dx
	call	InitSSMetaStruc			; es:bp <- ssmeta struc
	mov	es:[bp].SSMDAS_vmFileHan, bx
	mov	es:[bp].SSMDAS_hdrBlkVMHan, ax

	call	LockHeaderBlk			; bx <- mem han, ds <- seg addr
	mov	cx, ds:SSMHB_scrapRows
	mov	dx, ds:SSMHB_scrapCols

	mov	es:[bp].SSMDAS_scrapRows, cx
	mov	es:[bp].SSMDAS_scrapCols, dx

	call	SSMetaVMUnlock

	.leave
	ret
SSMetaInitForRetrieval	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaInitForCutCopy

DESCRIPTION:	If you plan to use the clipboard, call this to initialize the
		SSMetaStruc (in preparation for calls to
		SSMetaDataAddEntry). When done, you will need to call
		SSMetaDoneWithCutCopy.

		If you do not plan to use the clipboard, use SSMetaInitForSSMeta
		instead.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - uninitialized SSMetaStruc
		bx - ClipboardItemFlags
		ax:cx - CIH_sourceID field

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	store sourceID in stack frame
	get transfer file handle
	allocate and initialize the SSMetaHeaderBlock

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaInitForCutCopy	proc	far	uses	ax,bx,cx,es
	.enter

	mov	es, dx
	call	InitSSMetaStruc
	mov	es:[bp].SSMDAS_transferItemFlags, bx
	mov	es:[bp].SSMDAS_sourceID.high, ax
	mov	es:[bp].SSMDAS_sourceID.low, cx

	call	ClipboardGetClipboardFile	; bx <- UI's transfer VM file handle
	mov	es:[bp].SSMDAS_vmFileHan, bx

	;-----------------------------------------------------------------------
	; create the SSMetaHeaderBlock

	call	InitSSMetaHeaderBlock

	.leave
	ret
SSMetaInitForCutCopy	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaInitForPaste

DESCRIPTION:	Retrieve the spreadsheet clipboard item and initialize the
		SSMetaStruc.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - uninitialized SSMetaStruc
		bx - ClipboardItemFlags for ClipboardQueryItem

RETURN:		carry clear if item present
		    SSMetaStruc fields initialized:
			SSMDAS_vmFileHan
			SSMDAS_tferItemHdrVMHan
			SSMDAS_hdrBlkVMHan
			SSMDAS_sourceID
		carry set if no item present

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaInitForPaste	proc	far	uses	bx,cx,dx,di,ds,si
	.enter

	;-----------------------------------------------------------------------
	; get clipboard item

	mov	es, dx			; es:bp <- ssmeta struc
	clr	es:[bp].SSMDAS_hdrBlkVMHan

	push	bp
	mov	bp, bx			; bp <- ClipboardItemFlags
	call	ClipboardQueryItem	; bp <- number of formats
					; cx:dx <- owner
					; bx <- VM file han
					; ax <- TransferItemHeader VM blk han
	mov	di, ax			; di <- TransferItemHeader VM blk han
	mov	si, bp			; si <- num formats
	pop	bp
	call	InitSSMetaStruc		; es:bp <- ssmeta struc
	mov	es:[bp].SSMDAS_vmFileHan, bx


	call	ClipboardGetItemInfo	; cx:dx <- sourceID

	tst	si			; any formats?
	stc
	je	nothing			; done if not

	push	cx,dx,bp		; save sourceID
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET
	call	ClipboardRequestItemFormat	; bx <- VM file handle
					; ax <- SSMetaHeaderBlock han
					; (ax = 0 if none)
	pop	cx,dx,bp		; retrieve sourceID

	tst	ax			; transfer item present?
	stc
	je	nothing			; branch if not

	;-----------------------------------------------------------------------
	; OK, we have the SSMetaHeaderBlock, init info about the scrap

	mov	es:[bp].SSMDAS_tferItemHdrVMHan, di
	mov	es:[bp].SSMDAS_hdrBlkVMHan, ax
	mov	es:[bp].SSMDAS_sourceID.high, cx
	mov	es:[bp].SSMDAS_sourceID.low, dx

	call	LockHeaderBlk			; bx <- mem han, ds <- seg addr
	mov	cx, ds:SSMHB_scrapRows
	mov	dx, ds:SSMHB_scrapCols

	mov	es:[bp].SSMDAS_scrapRows, cx
	mov	es:[bp].SSMDAS_scrapCols, dx

	call	SSMetaVMUnlock
	clc

nothing:

	.leave
	ret
SSMetaInitForPaste	endp


;*******************************************************************************
;
;	"DONE WITH" ROUTINES
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDoneWithCutCopy

DESCRIPTION:	Clean up after a copy operation.
		Allocate and initialize the ClipboardItemHeader and make
		the call to ClipboardRegisterItem.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - SSMetaStruc

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate and lock the ClipboardItemHeader
	initialize the ClipboardItemHeader
	    copy over the source ID from the stack frame
	    initialize the CIH_flags
	    initialize the name of the scrap
	    initialize format count
	point CIH_formats at the SSMetaHeaderBlock
	unlock the ClipboardItemHeader
	register the transfer item

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDoneWithCutCopy	proc	far
	uses	ax,bx,es
	.enter

	call	SSMetaDoneWithCutCopyNoRegister

	mov	es, dx				;es:bp <- ssmeta struc
	mov	bx, es:[bp].SSMDAS_vmFileHan
	mov	ax, es:[bp].SSMDAS_tferItemHdrVMHan
	push	bp
	mov	bp, es:[bp].SSMDAS_transferItemFlags ; ClipboardItemFlags
	call	ClipboardRegisterItem
	pop	bp

	.leave
	ret
SSMetaDoneWithCutCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaDoneWithCutCopyNoRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize the ClipboardItemHeader, but
		do not register the transfer item with the clipboard

CALLED BY:	GLOBAL
PASS:		dx:bp - SSMetaStruc
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 9/93		broke out from SSMetaDoneWithCutCopy()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaDoneWithCutCopyNoRegister		proc	far
	uses	ax, bx, cx, di, si, ds, es
	.enter

	mov	es, dx				; es:bp <- ssmeta struc
EC<	call	ECCheckSSMetaStruc >

	;-----------------------------------------------------------------------
	; allocate and initialize ClipboardItemHeader

	mov	bx, es:[bp].SSMDAS_vmFileHan
	clr	ax				; no id
	mov	cx, size ClipboardItemHeader
	call	VMAlloc				; ax <- vm block handle
	mov	es:[bp].SSMDAS_tferItemHdrVMHan, ax

	call	SSMetaVMLock			; ax <- seg addr, bx <- mem han
	mov	es:[bp].SSMDAS_tferItemMemHan, bx
	mov	ds, ax				; ds <- TIH

EC<	call	ECCheckSSMetaStruc >
	mov	ax, es:[bp].SSMDAS_sourceID.high
	mov	ds:CIH_owner.segment, ax
	mov	ds:CIH_sourceID.segment, ax
	mov	ax, es:[bp].SSMDAS_sourceID.low
	mov	ds:CIH_sourceID.offset, ax
	clr	ax
	mov	ds:CIH_flags, ax		; specify normal transfer item
	mov	ds:CIH_reserved.high, ax
	mov	ds:CIH_reserved.low, ax
	mov	ds:CIH_formatCount, 1
	;
	; specify spreadsheet scrap
	;
	mov	ds:CIH_formats.CIFI_format.CIFID_manufacturer, \
		MANUFACTURER_ID_GEOWORKS
	mov	ds:CIH_formats.CIFI_format.CIFID_type, CIF_SPREADSHEET
	mov	ax, es:[bp].SSMDAS_hdrBlkVMHan
	mov	ds:CIH_formats.CIFI_vmChain.high, ax
	clr	ds:CIH_formats.CIFI_vmChain.low
	;
	; copy name of scrap
	;
	push	es
	segmov	es, ds				;es <- seg addr of CIH
	mov	bx, handle StringsResource	;bx <- handle of strings
	call	MemLock
	mov	ds, ax
	mov	si, offset scrapName
	mov	si, ds:[si]			;ds:si <- ptr to name
	ChunkSizePtr ds, si, cx			;cx <- # of bytes
DBCS< EC< cmp	cx, (size ClipboardItemNameBuffer)	; covers NULL	>  >
DBCS< EC< ERROR_A	SSMETA_CLIPNAME_TOO_LONG			>  >

	mov	di, offset CIH_name		;es:di <- ptr to dest
	rep	movsb				;copy me jesus
	call	MemUnlock
	pop	es

EC<	call	ECCheckSSMetaStruc >
	mov	bx, es:[bp].SSMDAS_tferItemMemHan
	call	SSMetaVMUnlock

	.leave
	ret
SSMetaDoneWithCutCopyNoRegister		endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDoneWithPaste

DESCRIPTION:	Call this routine when done using the clipboard item.

CALLED BY:	EXTERNAL ()

PASS:		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan
		    SSMDAS_tferItemHdrVMHan
		    (initilization done by SSMetaInitForPaste)

RETURN:		nothing

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDoneWithPaste	proc	far	uses	ax,bx,es
	.enter
	pushf
	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	mov	bx, es:[bp].SSMDAS_vmFileHan
	mov	ax, es:[bp].SSMDAS_tferItemHdrVMHan
	call	ClipboardDoneWithItem

EC<	mov	es:[bp].SSMDAS_vmFileHan, 0 >	; ensure no subsequent use
EC<	mov	es:[bp].SSMDAS_tferItemHdrVMHan, 0 >
EC<	mov	es:[bp].SSMDAS_hdrBlkVMHan, 0 >	; ensure no subsequent use

	popf
	.leave
	ret
SSMetaDoneWithPaste	endp


;*******************************************************************************
;
;	OTHER EXTERNAL ROUTINES
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaSeeIfScrapPresent

DESCRIPTION:	Check to see if a scrap of the Spreadsheet Meta Format is
		present. Ie. see if an ssmeta scrap is available for pasting.
		You can use this to enable/disable your UI.

CALLED BY:	EXTERNAL ()

PASS:		ax - ClipboardItemFlags for ClipboardQueryItem

RETURN:		carry clear if scrap present
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaSeeIfScrapPresent	proc	far	uses	ax,bx,cx,dx,bp
	.enter

	mov	bp, ax
	call	ClipboardQueryItem		; bx:ax <- header block
						; bp <- format count
	tst	bp				; any item?
	stc					; assume not
	jz	done				; done if assumption correct

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET
	call	ClipboardTestItemFormat		; bx:ax <- ClipboardItemHeader
						; cx:dx fmt manuf, fmt type
						; sets carry correctly
done:
	pushf
	call	ClipboardDoneWithItem
	popf

	.leave
	ret
SSMetaSeeIfScrapPresent	endp


;*******************************************************************************
;
;	INTERNAL ROUTINES
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitSSMetaStruc

DESCRIPTION:	Initialize the given SSMetaStruc.

CALLED BY:	INTERNAL ("InitFor" routines)

PASS:		es:bp - SSMetaStruc

RETURN:		SSMetaStruc with all fields zeroed out
		signature field will contain signature

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

InitSSMetaStruc	proc	near	uses	ax,cx,di
	.enter

	mov	di, bp
	clr	al
	mov	cx, size SSMetaStruc
	rep	stosb

	mov	es:[bp].SSMDAS_signature, SSMETA_STRUC_SIG

	.leave
	ret
InitSSMetaStruc	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitSSMetaHeaderBlock

DESCRIPTION:	Allocate and initialize the SSMetaHeaderBlock block in
		the given VM file.

CALLED BY:	INTERNAL (SSMetaInitForStorage, SSMetaInitForCutCopy)

PASS:		es:bp - SSMetaStruc
		bx - VM file handle in which to create the header block

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

InitSSMetaHeaderBlock	proc	far	uses	ax,bx,cx,di,ds
	.enter
EC<	call	ECCheckSSMetaStruc >

	;-----------------------------------------------------------------------
	; allocate the header block

	mov	cx, size SSMetaHeaderBlock
	call	VMAlloc				; ax <- VM blk handle
	mov	es:[bp].SSMDAS_hdrBlkVMHan, ax
	call	SSMetaVMLock			; ax <- seg, bx <- mem han
	mov	ds, ax

	mov	ds:SSMHB_vmChainTree.VMCT_meta.VMCL_next, -1
	mov	ds:SSMHB_vmChainTree.VMCT_offset, offset SSMHB_links
	mov	ds:SSMHB_vmChainTree.VMCT_count, SSMETA_NUM_SPECIFIERS

	;-----------------------------------------------------------------------
	; initialize the data arrays

	mov	al, DAS_CELL
	mov	cx, offset SSMHB_cellLink
	call	InitSSMetaDataArrayRecord
	clr	ds:SSMHB_cellLink.low
	mov	ds:SSMHB_cellLink.high, di

	mov	al, DAS_STYLE
	mov	cx, offset SSMHB_styleLink
	call	InitSSMetaDataArrayRecord
	clr	ds:SSMHB_styleLink.low
	mov	ds:SSMHB_styleLink.high, di

	mov	al, DAS_FORMAT
	mov	cx, offset SSMHB_formatLink
	call	InitSSMetaDataArrayRecord
	clr	ds:SSMHB_formatLink.low
	mov	ds:SSMHB_formatLink.high, di

	mov	al, DAS_NAME
	mov	cx, offset SSMHB_nameLink
	call	InitSSMetaDataArrayRecord
	clr	ds:SSMHB_nameLink.low
	mov	ds:SSMHB_nameLink.high, di

	mov	al, DAS_FIELD
	mov	cx, offset SSMHB_fieldLink
	call	InitSSMetaDataArrayRecord
	clr	ds:SSMHB_fieldLink.low
	mov	ds:SSMHB_fieldLink.high, di

	call	SSMetaVMUnlock

	.leave
	ret
InitSSMetaHeaderBlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitSSMetaDataArrayRecord

DESCRIPTION:	Initialize the SSMetaDataArrayRecord specified.

CALLED BY:	INTERNAL (InitSSMetaHeaderBlock)

PASS:		al - DataArraySpecifier
		offset to chain link in VMChainTree structure
		es:bp - SSMetaStruc

RETURN:		SSMetaDataArrayRecord initialized
		di - huge array block handle

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

InitSSMetaDataArrayRecord	proc	near	uses	bx,si,ds
	.enter
EC<	call	ECCheckSSMetaStruc >

	;-----------------------------------------------------------------------
	; lock header block and get pointer to the SSMetaDataArrayRecord

	mov	es:[bp].SSMDAS_dataArraySpecifier, al
	call	GetDataArrayRecord	; ds:si <- SSMetaDataArrayRecord
					; bx <- locked hdr blk mem han

	;-----------------------------------------------------------------------
	; init SSMetaDataArrayRecord fields

	push	bx
	mov	ds:[si].SSMDAR_signature, SSMETA_DATA_ARRAY_RECORD_SIG
	mov	ds:[si].SSMDAR_numEntries, 0

	mov	bx, es:[bp].SSMDAS_vmFileHan
	push	cx				; save offset
	clr	cx,di				; variable sized elements
						; no additional space needed
	call	HugeArrayCreate			; di <- huge array handle
	pop	ds:[si].SSMDAR_dataArrayLinkOffset

	;-----------------------------------------------------------------------
	; unlock header block

	pop	bx
	call	SSMetaVMUnlock			; unlock the header block

	.leave
	ret
InitSSMetaDataArrayRecord	endp

SSMetaCode	ends
