COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentConvert.asm

ROUTINES:
	Name			Description
	----			-----------
METHODS:
	Name			Description
	----			-----------
    StudioDocumentUpdateEarlierIncompatibleDocument  
				Convert a 1.X document to 2.0

				MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the document conversion code for StudioDocumentClass

	$Id: documentConvert.asm,v 1.1 97/04/04 14:38:38 newdeal Exp $

------------------------------------------------------------------------------@

DocMiscFeatures segment resource
if 0
COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentUpdateEarlierIncompatibleDocument --
		MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
						for StudioDocumentClass

DESCRIPTION:	Convert a 1.X document to 2.0

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentUpdateEarlierIncompatibleDocument	method dynamic	\
						StudioDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
mapBlock		local	word
convertLibHandle	local	hptr
fileHandle		local	hptr
convertParams		local	ConvertOldGWParams
transferParams		local	CommonTransferParams
oldProtocol		local	ProtocolNumber
	.enter

	call	IgnoreUndoAndFlush

	mov	bx, ds:[di].GDI_fileHandle
	mov	fileHandle, bx

	call	VMGetMapBlock				;ax = map block
	mov	mapBlock, ax

	; get the old protocol and check for transfer format files

	segmov	es, ss
	lea	di, oldProtocol
	mov	ax, FEA_PROTOCOL
	mov	cx, size oldProtocol
	call	FileGetHandleExtAttributes
	LONG jc	done

	cmp	oldProtocol.PN_major, 4
	jb	oldDocument

	; this is a transfer item in the map block

	call	createLockSuspendGetParams

	movdw	transferParams.CTP_range.VTR_start, 0
	movdw	transferParams.CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, mapBlock
	mov	transferParams.CTP_vmBlock, ax
	mov	ax, fileHandle
	mov	transferParams.CTP_vmFile, ax
	mov	transferParams.CTP_pasteFrame, 0
	movdw	bxsi, convertParams.COGWP_mainObj
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	clr	di
	call	ObjMessage
	mov	bx, fileHandle
	mov	ax, mapBlock
	clr	bp
	call	VMFreeVMChain

	call	UnsuspendDocument
	call	VMUnlockES
success:
	clc
	mov	ax, TRUE			;update protocol

done:
	call	AcceptUndo

	.leave
	ret

oldDocument:
	push	bp
	mov	dx, ss:oldProtocol.PN_major
	mov	cx, ss:oldProtocol.PN_major
	mov	bp, ss:fileHandle
	call	LockMapBlockDS
	mov	bx, cs
	mov	di, offset UpdateHotSpotArrayCallback
	call	EnumAllArticles
	call	VMUnlockDS			;unlock map block
	pop	bp
	jc	done				;no success?
	jmp	success
		
;---
		

createLockSuspendGetParams:
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	call	ObjCallInstanceNoLock
	pop	bp

	call	LockMapBlockES
	call	SuspendDocument

	; for this to work at all we need upward linkage from the article
	; to the document

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cxdx = document
	mov	ax, MSG_STUDIO_ARTICLE_SET_VIS_PARENT
	mov	di, mask MF_RECORD
	call	SendToAllArticles

	; get the OD of the first article

	push	si, ds
	segmov	ds, es
	mov	si, offset ArticleArray
	clr	ax
	call	ChunkArrayElementToPtr			;es:di = first article
	pop	si, ds

	mov	ax, es:[di].AAE_articleBlock
	call	StudioVMBlockToMemBlock			;ax = mem block
	mov	convertParams.COGWP_mainObj.handle, ax
	mov	convertParams.COGWP_mainObj.offset, offset ArticleText

	push	si, ds
	clr	ax
	call	SectionArrayEToP_ES		;es:di = SectionArrayEl
	mov	ax, es:[di].SAE_masterPages[0]	;ax = master page block
	mov	bx, fileHandle
	push	bp
	call	VMLock
	pop	bp
	mov	ds, ax				;ds = master page
	movdw	axsi, ds:[MPBH_header]
	call	getHdrFtr
	movdw	convertParams.COGWP_headerObj, axsi
	movdw	axsi, ds:[MPBH_footer]
	call	getHdrFtr
	movdw	convertParams.COGWP_footerObj, axsi
	call	VMUnlockDS
	pop	si, ds

	mov	convertParams.COGWP_mainStyle, TEXT_STYLE_NORMAL
	mov	convertParams.COGWP_headerStyle, TEXT_STYLE_NORMAL
	mov	convertParams.COGWP_footerStyle, TEXT_STYLE_NORMAL

	retn

;---

	; bx = file, ax = vm block, si = chunk

getHdrFtr:
	push	bx
	call	VMVMBlockToMemBlock		;axsi = header
	mov_tr	bx, ax				;bxsi = header
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL
	call	ObjMessage			;cxdx = text object
	movdw	axsi, cxdx
	pop	bx
	retn

StudioDocumentUpdateEarlierIncompatibleDocument	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentUpdateIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A document with an earlier protocol has been opened and
		must be updated for use with this version of the code.
				
CALLED BY:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		carry clear if upgrade successful
		ax - non-zero to up the protocol
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentUpdateIncompatibleDocument method dynamic StudioDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

	;
	; first, get the document's protocol number
	;
	call	GetFileHandle			; ^hbx <- file handle
	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss, ax
	mov	cx, size ProtocolNumber
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
		CheckHack <offset PN_major eq 0 and offset PN_minor eq 2>
	pop	dx		; dx <- major #
	pop	cx		; cx <- minor #
	jc	done				; => file w/o extended attrs
	;
	; Anything below 4.0 has HotSpotText objects which need
	; to update their HotSpotArray block.
	;
	cmp	dx, 4
	jae	accept

	mov	bp, bx		
	call	LockMapBlockDS
	mov	bx, cs
	mov	di, offset UpdateHotSpotArrayCallback
	call	EnumAllArticles
	call	VMUnlockDS			;unlock map block
	jc	done				;no success?
	mov	ax, TRUE			;success: up the protocol
		
done:
	ret

accept:
	mov	ax, FALSE			;don't up the protocol
	clc					;upgrade was successful
	jmp	done
StudioDocumentUpdateIncompatibleDocument		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateHotSpotArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each article, call MSG_HSTEXT_UPDATE_HOTSPOT_ARRAY

CALLED BY:	StudioDocumentUpdateIncompatibleDocument (via EnumArticles)
PASS:		ds:di - ArticleArrayElement
		dx - major protocol of document
		cx - minor protocol of document
		bp - file handle
RETURN:		carry flag set by MSG_HSTEXT_UPDATE_HOTSPOT_ARRAY
DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateHotSpotArrayCallback		proc	far
		uses	cx, dx, bp, ds
		.enter
		
		mov	bx, bp
		mov	ax, ds:[di].AAE_articleBlock
		call	VMVMBlockToMemBlock
		mov_tr	bx, ax		
		call	ObjLockObjBlock	
		mov	si, offset ArticleText		;*ds:si <- Article obj

		push	bx				;save Article handle
		
		push	bx
		push	si				;push optr
		push	dx
		push	cx				;push Protocol number
		call	HotSpotTextUpdateHotSpotArray		

		pop	bx
		call	MemUnlock			;unlock ObjBlock
		.leave
		ret
UpdateHotSpotArrayCallback		endp

DocMiscFeatures ends
