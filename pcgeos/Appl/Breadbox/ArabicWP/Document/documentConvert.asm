COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentConvert.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the document conversion code for WriteDocumentClass

	$Id: documentConvert.asm,v 1.1 97/04/04 15:56:22 newdeal Exp $

------------------------------------------------------------------------------@

DocMiscFeatures segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentUpdateEarlierIncompatibleDocument --
		MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
						for WriteDocumentClass

DESCRIPTION:	Convert a 1.X document to 2.0

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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

if not DBCS_PCGEOS

convertLibDir	char	CONVERT_LIB_DIR
convertLibPath	char	CONVERT_LIB_PATH

endif

WriteDocumentUpdateEarlierIncompatibleDocument	method dynamic	\
						WriteDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
if not DBCS_PCGEOS

psetup			local	PageSetupInfo
blockList		local	word
mapBlock		local	word
convertLibHandle	local	hptr
fileHandle		local	hptr
convertParams		local	ConvertOldGWParams
transferParams		local	CommonTransferParams
oldProtocol		local	ProtocolNumber

endif
	.enter

if DBCS_PCGEOS

	stc		;don't want to load conversion lib; error instead. 
else

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

	cmp	oldProtocol.PN_major, 1
	jz	oldDocument

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
	jmp	unsuspendCommon

oldDocument:

	;  Load the conversion library

	push	ds, si
	segmov	ds, cs
	mov	bx, CONVERT_LIB_DISK_HANDLE
	mov	dx, offset convertLibDir
	call	FileSetCurrentPath
	jc	popAndDone

	mov	si, offset convertLibPath
	mov	ax, CONVERT_PROTO_MAJOR
	mov	bx, CONVERT_PROTO_MINOR
	call	GeodeUseLibrary				;bx = library

popAndDone:
	pop	ds, si
	LONG jc	done
	mov	convertLibHandle, bx

	; save a list of the blocks in the file

	mov	ax, enum ConvertGetVMBlockList
	call	callConvertRoutine
	mov	blockList, ax

	; create a new file

	call	createLockSuspendGetParams

	mov	cx, mapBlock
	lea	di, psetup
	push	si
	lea	si, convertParams
	mov	ax, enum ConvertOldGeoWriteDocument
	call	callConvertRoutine
	pop	si

	mov	cx, blockList
	mov	ax, enum ConvertDeleteViaBlockList
	call	callConvertRoutine

	mov	ax, VMA_OBJECT_ATTRS
	mov	bx, fileHandle
	call	VMSetAttributes

	push	es
	segmov	es, ss
	lea	di, psetup				;es:di = page setup
	call	UpdateFromPSI
	pop	es

	mov	bx, convertLibHandle
	call	GeodeFreeLibrary

unsuspendCommon:
	call	UnsuspendDocument
	call	VMUnlockES

	clc
	mov	ax, TRUE			;update protocol

done:
	call	AcceptUndo

endif

	.leave
	ret

if not DBCS_PCGEOS

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
	mov	ax, MSG_WRITE_ARTICLE_SET_VIS_PARENT
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
	call	WriteVMBlockToMemBlock			;ax = mem block
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
	mov	convertParams.COGWP_headerStyle, TEXT_STYLE_HEADER
	mov	convertParams.COGWP_footerStyle, TEXT_STYLE_FOOTER

	retn

;---

	; ax = enum, si = value for bp

callConvertRoutine:
	push	bx, si, bp
	push	fileHandle
	mov	bx, convertLibHandle
	mov	bp, si
	pop	si				;si = file handle
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx, si, bp
	retn

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

endif
WriteDocumentUpdateEarlierIncompatibleDocument	endm

DocMiscFeatures ends
