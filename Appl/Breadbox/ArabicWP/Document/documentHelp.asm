COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		GeoWrite
FILE:		documentHelp.asm

AUTHOR:		Gene Anderson, Sep 20, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/20/92		Initial revision


DESCRIPTION:
	Code for creating help files.

	$Id: documentHelp.asm,v 1.1 97/04/04 15:56:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpEditCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadCompressLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the compress library. 
		
CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if couldn't load library
		ELSE:
			bx - handle of library
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
NEC <LocalDefNLString compressLibName <"PKware Lib",0>>
EC <LocalDefNLString compressLibName <"EC PKware Lib",0>>
else
NEC <LocalDefNLString compressLibName <"PKware Compression Library",0>>
EC <LocalDefNLString compressLibName <"EC PKware Compression Library",0>>
endif
LoadCompressLibrary	proc	near	uses	ax, bp, ds, si
	.enter
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	segmov	ds, cs
	mov	si, offset compressLibName
	mov	ax, COMPRESS_PROTO_MAJOR
	mov	bx, COMPRESS_PROTO_MINOR
	call	GeodeUseLibrary
	call	FilePopDir
	jnc	exit
	mov	ax, 	(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset NoCompressLibraryString
	call	PutupHelpBox
	stc
exit:
	.leave
	ret
LoadCompressLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHelpOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the help options.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - HelpOptions
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHelpOptions	proc	near	uses	bx, cx, dx, bp, si, di
	.enter
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	GetResourceHandleNS	HelpOptionsList, bx
	mov	si, offset HelpOptionsList
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
GetHelpOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentGenerateHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a help file from a GeoWrite document

CALLED BY:	MSG_WRITE_DOCUMENT_GENERATE_HELP_FILE
PASS:		*ds:si - instance data
		es - seg addr of WriteDocumentClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros 10/30/00	Deletes help file if error condition.
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentGenerateHelpFile		method dynamic WriteDocumentClass,
					MSG_WRITE_DOCUMENT_GENERATE_HELP_FILE

.warn -unref_local

documentObj	local	optr		;document object
articleObj	local	optr		;associated article object
pageCallback	local	fptr		;callback routine for each page
charCount	local	dword		;characters seen so far
nameArrayVM	local	word		;VM handle of name array
writeFile	local	hptr		;handle of GeoWrite file
helpFile	local	hptr		;handle of help file
tempText	local	optr		;OD of temporary text object
compressLib	local	hptr
compressType	local	HelpCompressType
filename	local	FileLongName
.warn @unref_local

	.enter
	mov	ss:compressType, HCT_NONE
	clr	bx
	call	GetHelpOptions
	test	ax, mask HO_COMPRESS
	jz	noCompressLib
	call	LoadCompressLibrary
	LONG jc	afterFree
	mov	ss:compressType, HCT_PKZIP
noCompressLib:
	mov	ss:compressLib, bx

	;
	; Setup for stuff we need to do...
	;
	mov	bx, ds:[LMBH_handle]		;^lbx:si <- document object
	movdw	ss:documentObj, bxsi
	;
	; Make sure the names are reasonable, and attempt to fix them
	; if they are not.
	;
	call	CheckFixHelpNames
	;
	; Create the help file, if possible
	;
	call	CreateHelpFile
	LONG jc	quit				;branch if error
	mov	ss:helpFile, dx
	;
	; Get the map block of the GeoWrite file
	;
	call	GetFileHandle			;bx <- handle of GeoWrite file
	mov	ss:writeFile, bx
	call	LockMapBlockDS			;ds <- seg addr of GeoWrite map
	;
	; For the character, paragraph, graphic and type elements,
	; we can simply copy them from the GeoWrite document to the
	; help file
	;
	mov	ax, ds:MBH_charAttrElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_charAttrs, ax
	call	NukeStyleSheetRefs
	mov	ax, ds:MBH_paraAttrElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_paraAttrs, ax
	call	NukeStyleSheetRefs
	mov	ax, ds:MBH_graphicElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_graphics, ax
	;
	; For graphics, we need to copy the graphic data, too,
	; which are VM chains associated with each element.
	;
	call	CopyGraphicData

	mov	ax, ds:MBH_typeElements		;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_types, ax
	mov	ax, ds:MBH_nameElements		;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_names, ax
	mov	es:[di].HFMB_protocolMajor, HELP_FILE_PROTO_MAJOR
	mov	es:[di].HFMB_protocolMinor, HELP_FILE_PROTO_MINOR
	mov	bl, compressType
	mov	es:[di].HFMB_compressType, bl
	mov	ss:nameArrayVM, ax
	mov	bx, dx				;bx <- handle of help file
	;
	; Create a temporary text object to use for copying
	; help text from GeoWrite to the help file.
	;
	mov	ax, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or \
			mask VTSF_TYPES or \
			mask VTSF_GRAPHICS	;ah <- no regions
	call	AllocTempText
	movdw	ss:tempText, bxsi
	;
	; Unlock the help file map block
	;
	call	DBUnlock
	;
	; For the text, we run through each article (although
	; currently there is only one) and for each page of
	; the article, we copy the text to the help file.
	;
	mov	ss:pageCallback.segment, cs
	mov	ss:pageCallback.offset, offset CopyOneHelpPage
	call	EnumArticlesForDocumentPages
	pushf		; save carry state (error condition)
	;
	; Free the temporary text object we used for copying
	;
	movdw	bxsi, ss:tempText
	call	FreeTempText	

	;
	; Add extra space the help object needs in the name array
	;
	call	AddSpaceToNameArray
	;
	; Close the help document
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	al, FILE_NO_ERRORS
	call	VMClose
	;
	; Unlock the GeoWrite file map block
	;
	call	VMUnlockDS
	;
	; If there was an error condition generating the help file,
	; delete it.
	;
	popf
	jc	errorDeleteHelpFile

quit:
	mov	bx, ss:compressLib
	tst	bx
	jz	afterFree
	call	GeodeFreeLibrary
afterFree:
	.leave
	ret

errorDeleteHelpFile:
	;
	; Save the current directory
	;
	call	FilePushDir
	;
	; Change to the help file directory
	;
	mov	ax, SP_HELP_FILES		;ax <- StandardPath
	call	FileSetStandardPath
	;
	; Get the filename so we can delete it
	;
	mov	cx, ss
	lea	dx, ss:filename			;cx:dx <- buffer
	movdw	bxsi, documentObj		; bx:si = document object
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; Delete it
	;
	mov	ds, cx
	call	FileDelete
	call	FilePopDir		
	jmp	quit
WriteDocumentGenerateHelpFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the help file

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		*ds:si - WriteDocumentClass object
		es - seg addr of WriteDocumentClass
RETURN:		carry - set if error
		dx - file handle of help file
		es:di - ptr to map item
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Creates the help file and initializes the map block
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
helpFileToken GeodeToken <
	"hlpf",
	MANUFACTURER_ID_GEOWORKS>

helpFileCreator GeodeToken <
	"hlpv",
	MANUFACTURER_ID_GEOWORKS>

CreateHelpFile		proc	near
	uses	bx, cx
filename	local	FileLongName
	.enter

	;
	; Save the current directory
	;
	call	FilePushDir
	;
	; Change to the help file directory
	;
	mov	ax, SP_HELP_FILES		;ax <- StandardPath
	call	FileSetStandardPath
	;
	; Get the name of GeoWrite document
	;
	mov	cx, ss
	lea	dx, ss:filename			;cx:dx <- buffer
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock
	;
	; Create the help file
	;
	push	ds
	mov	al, mask VMAF_FORCE_DENY_WRITE
	mov	ah, VMO_CREATE_TRUNCATE
	mov	ds, cx				;ds:dx <- ptr to filename
	clr	cx				;cx <- compression threshold
	call	VMOpen
	pop	ds
	jc	quit				;branch if error
	;
	; Set the token & creator to something nice
	;
	segmov	es, cs
	mov	di, offset helpFileToken	;es:di <- ptr to buffer
	mov	cx, (size GeodeToken)		;cx <- size of buffer
	mov	ax, FEA_TOKEN			;ax <- FileExtendedAttribute
	call	FileSetHandleExtAttributes
	jc	quit				;branch if error
	mov	di, offset helpFileCreator	;es:di <- ptr to buffer
	mov	ax, FEA_CREATOR			;ax <- FileExtendedAttribute
	call	FileSetHandleExtAttributes
	jc	quit				;branch if error
	;
	; Allocate and initialize the map block
	;
	mov	ax, DB_UNGROUPED		;allocate ungrouped
	mov	cx, (size HelpFileMapBlock)	;cx <- size of the block
	call	DBAlloc				;allocate a map item
	call	DBSetMap			;make it the map item
	call	DBLockMap
	call	DBDirty
	mov	di, es:[di]			;es:di <- ptr to map
	push	di
	clr	al				;al <- byte to store
	rep	stosb				;zero me jesus
	pop	di
	mov	dx, bx				;dx <- handle of file
	;
	; Return to the original directory
	;
	clc					;carry <- no error
quit:
	call	FilePopDir			;preserves flags

	.leave
	ret
CreateHelpFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumArticlesForDocumentPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the articles in a document to enumerate the page

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		ds - seg addr of article array
		ss:bp - inherited locals
RETURN:		carry set if enum aborted
DESTROYED:	ax, bx, di, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumArticlesForDocumentPages		proc	near
	.enter	inherit	WriteDocumentGenerateHelpFile

	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset EnumPagesForArticle
	clrdw	ss:charCount
	call	ChunkArrayEnum

	.leave
	ret
EnumArticlesForDocumentPages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumPagesForArticle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to enumerate pages for one article

CALLED BY:	WriteDocumentGenerateHelpFile() via ChunkArrayEnum()
PASS:		ds:di - ArticleArrayElement
		ss:bp - inherited locals
		    pageCallback - callback routine for each page
RETURN:		carry - set to abort
DESTROYED:	ax, bx, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumPagesForArticle		proc	far
	uses	di
	.enter	inherit	WriteDocumentGenerateHelpFile

	push	ds:[LMBH_handle]
	segmov	es, ds				;es <- map block

	mov	bx, ss:writeFile		;bx <- handle of VM file
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax				;ds <- article block
	mov	bx, ds:[LMBH_handle]
	mov	ss:articleObj.handle, bx
	mov	ss:articleObj.offset, offset ArticleText
	;
	; Callback for each region / page in the article to copy it
	;
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:pageCallback				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	movdw	bxdi, ss:pageCallback		;bx:di <- callback routine
	mov	si, offset ArticleRegionArray	;*ds:si <- region array
	call	ChunkArrayEnum
	
	;
	; Unlock the region array
	;
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	;
	; Redereference the article array block in case it moved
	;
	pop	bx				;bx <- handle of map block
	call	MemDerefDS
	.leave
	ret
EnumPagesForArticle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses the passed data

CALLED BY:	GLOBAL
PASS:		ds:si - source
		es:di - dest for compacted data
		cx - # bytes in source
		bx - handle of compress library
RETURN:		cx - # bytes in compacted data (0 if error)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressData	proc	near	uses	ax
	.enter
	push	bx
	mov	ax, CL_COMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
	push	ax
	push	ax			;sourceFileHan (not used)
	pushdw	dssi			;sourceBuff
	push	cx			;sourceBuffSize
	push	ax			;destFileHan (not used)
	pushdw	esdi			;destBuffer

	mov	ax, enum CompressDecompress
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx
	tst	ax
	jz	error

EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>

;	Make sure that the data uncompacts OK

	push	ax, bx, cx, dx, bp, di, si, es, ds
	push	bx, ax
	mov_tr	ax, cx			;AX <- # bytes to load
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ds, ax
	pop	ax, cx
	push	bx			;Save handle of block
	mov_tr	bx, ax			;BX <- compress lib handle

	mov	ax, CL_DECOMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
	push	ax
	clr	ax
	push	ax		;sourceFileHan (not used)
	pushdw	esdi		;sourceBuff
	push	cx		;sourceBuffSize
	push	ax		;destFileHan (unused)
	pushdw	dsax		;destBuffer

	mov	ax, enum CompressDecompress
	call	ProcGetLibraryEntry	
	call	ProcCallFixedOrMovable
	pop	bx
	call	MemFree
	tst	ax
	pop	ax, bx, cx, dx, bp, di, si, es, ds
	jz	uncompressError

	mov_tr	cx, ax
exit:
	.leave
	ret
uncompressError:
	mov	ax, offset BadDecompressErrorString
	jmp	errorCommon
error:
	mov	ax, offset CompressMemoryErrorString
errorCommon:
	push	bx
	mov_tr	bx, ax
	mov	ax, 	(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	PutupHelpBox
	pop	bx
	clr	cx
	jmp	exit
CompressData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses the passed DBItem

CALLED BY:	GLOBAL
PASS:		bx - file
		ax - handle of compression library
		cx:dx - DBItem to compress
RETURN:		cx:dx - DBItem (0 if error)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressDBItem	proc	near		uses	ax, bx, bp, di, si, es, ds
	oldItem		local	dword	\
			push	cx, dx
	compressLib	local	hptr	\
			push	ax
	.enter
	movdw	axdi, cxdx
	call	DBLock			;
	segmov	ds, es			;*DS:SI <- data
EC <  	call	ECLMemValidateHeap					>
	mov	si, di
	mov	di, es:[si]
	ChunkSizePtr	es, di, cx
	push	cx
	mov	ax, cx
	shr	ax
	add	cx, ax			;We assume that the result will be no
					; larger than 1.5 times the original

;	Allocate an item to hold the compressed data (I don't believe that
;	the compaction code can handle compacting in place).

	mov	ax, DB_UNGROUPED
	call	DBAlloc
	pop	cx
	pushdw	axdi

	call	DBLock
EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>
	mov	di, es:[di]			;ES:DI <- dest for compression
	mov	es:[di], cx
	add	di, size word
	mov	si, ds:[si]			;DS:SI <- uncompressed data
						;CX has size of uncmprsd data

;	Compress the data 

	push	bx				;Save file handle
	mov	bx, compressLib
	call	CompressData			;CX <- size of compacted data
	pop	bx				;Restore file handle

EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>

	add	cx, size word			;Add the size word we put
						; at the start
;	Now that we've made a compacted copy of the data, free the old
;	DBItem.

	call	DBUnlock
	segmov	es, ds
	call	DBUnlock			;Unlock/free old item
	movdw	axdi, oldItem
	call	DBFree

;	Re-allocate the DBItem to be exactly as large as the compressed data.

	popdw	axdi				;
	cmp	cx, size word			;If error returned from 
						; CompressData, branch
	je	compressError					
	call	DBReAlloc			;
	movdw	cxdx, axdi			;CX.DX <- DB Item
exit:
	.leave
	ret
compressError:
	call	DBFree
	clrdw	cxdx
	jmp	exit
CompressDBItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyOneHelpPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one page of help to the help file

CALLED BY:	EnumPagesForArticle() via ChunkArrayEnum()

PASS:		ds:di - ptr to VisLargeTextRegionArrayElement
		ss:bp - inherited locals
RETURN:		carry - set to abort
DESTROYED:	ax, bx, cx, si, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: pages that do not have a context name at the start will
	be ignored and will not be copied into the help document.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTypeParams	struct
    GTP_params	VisTextGetAttrParams
    GTP_attrs	VisTextType
    GTP_diffs	VisTextTypeDiffs
GetTypeParams	ends

CopyOneHelpPage		proc	far
	uses	dx
	.enter	inherit	EnumPagesForArticle

	movdw	dxcx, ss:charCount		;dx:cx <- current pos in text
	adddw	ss:charCount, ds:[di].VLTRAE_charCount, ax
	mov	bx, ds:[di].VLTRAE_flags	;bx <- VisLargeTextRegionFlags
	test	bx, mask VLTRF_EMPTY		;empty page?
	LONG jnz	quit			;branch if empty page
	;
	; Get the type at the start of the page
	;
	sub	sp, (size GetTypeParams)
	mov	di, sp				;ss:di <- ptr to params
	clr	ss:[di].VTGAP_flags
	mov	ss:[di].VTGAP_attr.segment, ss
	lea	ax, ss:[di].GTP_attrs
	mov	ss:[di].VTGAP_attr.offset, ax
	mov	ss:[di].VTGAP_return.segment, ss
	lea	ax, ss:[di].GTP_diffs
	mov	ss:[di].VTGAP_return.offset, ax
	movdw	ss:[di].VTGAP_range.VTR_start, dxcx
	movdw	ss:[di].VTGAP_range.VTR_end, dxcx
	mov	ax, MSG_VIS_TEXT_GET_TYPE
	call	callArticle
	mov	ax, ss:[di].GTP_attrs.VTT_context
	add	sp, (size GetTypeParams)
	;
	; If there is no context for the start of the page, quit
	;
	cmp	ax, -1				;any context?
	LONG jz	quit				;branch if no type
	push	ax				;save type token
	;
	; Copy the text for the page
	;
	sub	sp, (size CommonTransferParams)
	mov	di, sp				;ss:di <- ptr to params
	movdw	ss:[di].CTP_range.VTR_start, dxcx
	movdw	ss:[di].CTP_range.VTR_end, ss:charCount, ax
	;
	; See if the page ends in a column break -- if so adjust the range
	; by one so we don't try to copy the column break.
	;
	test	bx, mask VLTRF_ENDED_BY_COLUMN_BREAK
	jz	noBreak				;branch if no break
	decdw	ss:[di].CTP_range.VTR_end
noBreak:
	mov	ax, ss:helpFile
	mov	ss:[di].CTP_vmFile, ax		;pass VM file
	clr	ss:[di].CTP_pasteFrame		;not quick paste
	mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
	call	callArticle
	;
	; Paste it into the temporary text object
	;
	push	bp
	movdw	bxsi, ss:tempText		;^lbx:si <- OD of temp text
	mov	bp, di				;ss:bp <- ptr to params
	mov	ss:[bp].CTP_vmBlock, ax
	clrdw	ss:[bp].CTP_range.VTR_start
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	call	callObjMessage
	;
	; Free the transfer item, lest the file fill with cruft...
	;
	push	bx
	mov	bx, ss:[bp].CTP_vmFile		;bx <- help file handle
	mov	ax, ss:[bp].CTP_vmBlock
	clr	bp				;ax:bp <- VM chain for transfer
	call	VMFreeVMChain
	pop	bx
	;
	; Store the text and runs into the help file
	;
	clrdw	cxdx				;cx:dx <- alloc DBItem
	mov	bp, mask VTSDBF_TEXT or \
			(VTST_RUNS_ONLY shl offset VTSDBF_CHAR_ATTR) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_PARA_ATTR) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_TYPE) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_GRAPHIC)
	mov	ax, MSG_VIS_TEXT_SAVE_TO_DB_ITEM
	call	callObjMessage
	pop	bp
	add	sp, (size CommonTransferParams)
	
	mov	bx, ss:helpFile
	mov	ax, ss:compressLib
	tst	ax
	jz	noCompress
	call	CompressDBItem
	jcxz	popExit			;If error compressing, exit
noCompress:	
	;
	; Save the DB item of this page into the appropriate name entry
	; cx:dx - DBGroupAndItem
	; ax - name token for page
	;
	pop	ax				;ax <- name token for page
	call	StoreDBItemForPage
	jc	exit				; carry set = error
quit:
	clc					;carry <- don't abort
exit:
	.leave
	ret
popExit:
	pop	ax
	stc
	jmp	exit

callArticle:
	push	bx, si, cx, dx, bp, di
	movdw	bxsi, ss:articleObj
	mov	bp, di				;di <- ptr to message params
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bx, si, cx, dx, bp, di
	retn

callObjMessage:
	push	di
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	di
	retn
CopyOneHelpPage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a temporary text object for copying text

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS: 		al - VisTextStorageFlags for object
		ah - non-zero to create regions for object
		bx - help file to associate object with
		es:di - ptr to map block of help file

RETURN: 	^lbx:si - VisTextObject to use

DESTROYED: 	none

PSEUDO CODE/STRATEGY:

	NOTE: A *very* important step here is attaching the the
	element arrays in the help file to the text object.
	Without this, the tokens used in the run arrays for the text
	as it is copied would be adjusted to be relative to the
	transfer item.  This means they wouldn't match the element
	arrays we had copied to the help file, which would be bad.

	NOTE: Related to the above is another important item.
	There are two copies of each of the element arrays, one in
	the GeoWrite document, and one if the help file.  We attach
	the temporary text object to the ones in the help file, not
	the GeoWrite document, because the act of pasting into it
	will be incrementing the reference counts on the various elements.
	We could correct this by deleting the text from the temporary
	text object when we are done, but this has the negatives of
	(a) wasting a bit of time (b) dirtying the GeoWrite file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocTempText		proc	near
	uses	ax, cx, dx, bp
	.enter

	push	ax				;save storage flags
	push	bx				;save passed file
	;
	; allocate object in a new block
	;
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo			;ax <- current thread
	mov_tr	bx, ax
	call	UserAllocObjBlock		;bx <- block

	push	es, di
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset VisTextClass
	call	ObjInstantiate			;bx:si <- object
	pop	es, di
	;
	; associate the object with the passed file
	;
	pop	cx				;cx <- passed file
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	call	objMessageSend
	;
	; make appropriate structures
	;
	pop	cx				;cl, ch <- VisTextStorageFlags
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	call	objMessageSend
	;
	; Connect the various attribute arrays
	; NOTE: the order is important -- the names must be done first
	; NOTE: see vTextC.def for details
	;
	mov	ch, TRUE			;ch <- handles are VM
	clr	bp				;bp <- use 1st element
	mov	ax, MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY

	mov	dx, es:[di].HFMB_names		;dx <- VM handle of names
	mov	cl, VTSF_NAMES
	call	objMessageSend
	mov	dx, es:[di].HFMB_charAttrs	;dx <- VM handle of char attrs
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	call	objMessageSend
	mov	dx, es:[di].HFMB_paraAttrs	;dx <- VM handle of para attrs
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	call	objMessageSend
	mov	dx, es:[di].HFMB_graphics	;dx <- VM handle of graphics
	mov	cl, mask VTSF_GRAPHICS
	call	objMessageSend
	mov	dx, es:[di].HFMB_types		;dx <- VM handle of types
	mov	cl, mask VTSF_TYPES
	call	objMessageSend

	.leave
	ret

objMessageSend:
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	retn
AllocTempText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the temporary text object

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		^lbx:si - OD of temp
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeTempText		proc	near
	.enter

	call	MemFree

	.leave
	ret
FreeTempText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreDBItemForPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the DB item for a page's help text

CALLED BY:	CopyOneHelpPage()
PASS:		ss:bp - inherited locals
		cx:dx - DBGroupAndItem for text
		ax - name token for page
RETURN:		carry set -- error setting item (duplicate context)
DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros 10/30/00	Added checking for multiple contexts.
	gene	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreDBItemForPage		proc	near
	uses	ds, bp
	.enter	inherit CopyOneHelpPage

	push	ax				;save name token
	;
	; Lock the name array
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	ax, ss:nameArrayVM		;ax <- VM handle of names
	call	LockElementArray
	pop	ax				;ax <- name token
	;
	; Get a pointer to the name entry and stuff the DB item and group.
	;
	push	cx
	call	ChunkArrayElementToPtr		;ds:di <- ptr to element
	;
	; Ensure that a DB item is not already set for this context.  If there is,
	; then throw an error. (we can't have multiple contexts)
	; I AM TEMPORARILY DISABLING THIS CHECK DUE TO BUG 6091, WHICH STILL NEEDS TO
	; BE FIXED.
	;
	;tst	ds:[di].VTNAE_data.VTND_helpText.DBGI_group
	;jnz	errorDupContext
	pop	cx
	mov	ds:[di].VTNAE_data.VTND_helpText.DBGI_group, cx
	mov	ds:[di].VTNAE_data.VTND_helpText.DBGI_item, dx
	;
	; Mark the name array as dirty and unlock it
	;
	call	VMDirty
	clc					; no error

done:
	call	VMUnlock

	.leave
	ret

errorDupContext:
	; allocate memory for the offending context name
	sub	cx, size VisTextNameArrayElement	
	mov	ax, cx				; ax <- context name size
	inc	ax				; +1 for NULL
	push	cx
	mov	cx, mask HF_FIXED
	call	MemAlloc			; bx <- block handle
						; ax <- segment of block
	pop	cx
	; copy and NULL terminate the string
	mov	es, ax
	push	bx

	lea	si, ds:[di].VTNAE_meta.NAE_data+size VisTextNameData	; ds:si <- source
	push	di
	clr	di				; es:di <- dest
	rep	movsb				; copy
	clr	ax
	mov	es:[di], al			; NULL terminate
	pop	di

	;
	; Display error message with the offending context name
	;
	push	bp
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, \
		CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0> 
	GetResourceHandleNS	StringsUI, bx	
	call	ObjLockObjBlock
	push	es
	mov	es, ax
	mov	si, offset duplicateContextNameErrorText
	mov	si, es:[si]		; es:si = fptr to duplicateContextNameErrorText string
	movdw	ss:[bp].SDP_customString, essi
	pop	es

	clr	ax
	mov	ss:[bp].SDP_stringArg1.segment, es
	mov	ss:[bp].SDP_stringArg1.offset, ax	; SDP_stringArg1 -> context name

	movdw	ss:[bp].SDP_stringArg2, axax
	movdw	ss:[bp].SDP_customTriggers, axax
	movdw	ss:[bp].SDP_helpContext, axax	
	call	UserStandardDialog	
	call	MemUnlock
	pop	bp
	pop	bx
	call	MemFree		; free context name block
	stc
	pop	cx
	jmp	done

StoreDBItemForPage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockElementArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the name array for a file (either GeoWrite doc or help)

CALLED BY:	UTILITY
PASS:		bx - handle of file
		ax - VM handle of name array
RETURN:		*ds:si - name array
		bp - memory handle of VM block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockElementArray		proc	near
	uses	ax
	.enter

	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si <- name array

	.leave
	ret
LockElementArray		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutupHelpBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays an error box.

CALLED BY:	GLOBAL
PASS:		ax - CustomDialogBoxFlags
		bx - chunk handle of string in StringsUI
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutupHelpBox	proc	near	uses	bp
	.enter
	sub	sp, (size StandardDialogOptrParams)
	mov	bp, sp				;ss:bp <- params
	mov	ss:[bp].SDOP_customString.chunk, bx
	mov	ss:[bp].SDOP_customFlags, ax
	clr	ax
	mov	ss:[bp].SDOP_helpContext.segment, ax
	mov	ss:[bp].SDOP_customTriggers.segment, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_customString.handle, handle StringsUI
	call	UserStandardDialogOptr
	.leave
	ret
PutupHelpBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFixHelpNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check (and fix if necessary) the names for help.

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		*ds:si - instance of WriteDocument object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFixHelpNames		proc	near
	uses	ax, bx, cx, dx, ds, si, di, bp
	.enter

	;
	; Get the names array
	;
	call	GetFileHandle			;bx <- handle of file
	call	LockMapBlockDS
	mov	ax, ds:MBH_nameElements		;ax <- VM block of names
	call	VMUnlockDS
	call	LockElementArray		;*ds:si <- name array
	;
	; For each name, see if is too long.
	;
	mov	bx, cs
	mov	di, offset CheckOneHelpName	;bx:di <- callback
	call	ChunkArrayEnum
	jnc	done				;branch if names OK
	;
	; Put up an annoying box telling AndrewC the problem and
	; giving him the option to try to correct the names.
	;
	mov	ax,	(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset HelpNamesTooLongString
	call	PutupHelpBox

	cmp	ax, IC_YES			;update names?
	jne	done				;branch if not updating
	;
	; For each name, truncate it to the legal maximum
	;
	mov	bx, cs
	mov	di, offset FixOneHelpName	;bx:di <- callback
	call	ChunkArrayEnum
	;
	; Finally, mark the name array as dirty to record our changes
	;
	call	VMDirtyDS
done:
	call	VMUnlockDS

	.leave
	ret
CheckFixHelpNames		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckOneHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a help name to see if it is short enough

CALLED BY:	CheckFixHelpNames() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
RETURN:		carry - set if name is too long
		    ax - element # that is too large
		    cx - length of name (w/o NULL)
		    dx - legal maximum for element
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckOneHelpName		proc	far
	.enter

	;
	; Make sure this element is in use
	;
	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	emptyElement
	;
	; Figure out what the maximum is based on the type
	;
	mov	dx, FILE_LONGNAME_LENGTH	;dx <- assume filename
	cmp	ds:[di].VTNAE_data.VTND_type, VTNT_FILE
	je	isFile
	mov	dx, MAX_CONTEXT_NAME_LENGTH	;dx <- context name
isFile:
	;
	; See how long the name actually is
	;
	call	ChunkArrayPtrToElement		;ax <- element #
	call	ChunkArrayElementToPtr		;cx <- size of element
	sub	cx, (size VisTextNameArrayElement)
DBCS <	shr	cx, 1				;cx <- length>
	cmp	cx, dx				;name too large?
	ja	nameTooLarge			;branch if too large
emptyElement:
	clc					;carry <- name OK
done:

	.leave
	ret

nameTooLarge:
	stc					;carry <- name too large
	jmp	done
CheckOneHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixOneHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix one help name by shortening it if necessary

CALLED BY:	CheckFixHelpNames() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
RETURN:		carry - set to abort
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixOneHelpName		proc	far
	uses	es
SBCS <nameBuffer	local	NAME_ARRAY_MAX_NAME_SIZE dup (char)	>
DBCS <nameBuffer	local	NAME_ARRAY_MAX_NAME_SIZE/2 dup (wchar)	>
	.enter

	;
	; See if the name is OK
	;
	call	CheckOneHelpName		;name OK?
	jnc	done				;branch if name OK
	;
	; Copy the name to a local variable for ease of use
	;
	push	si, di, cx
	lea	si, ds:[di][(size VisTextNameArrayElement)]
	segmov	es, ss
	lea	di, ss:nameBuffer		;es:di <- dest
	LocalCopyNString			;copy cx chars
	clr	cx
	LocalPutChar esdi, cx, NO_ADVANCE	;NULL terminate me jesus
	pop	si, di, cx
	;
	; The name is too long -- see if the truncated version
	; will conflict with another name.
	;
	mov	cx, ax				;cx <- element # for nameBuffer
	mov	bx, cs
	mov	di, offset CheckTruncatedHelpName
	call	ChunkArrayEnum
	jc	nameNoTruncate
	;
	; Whee!  Truncating the name won't cause a problem, so do it!
	;	cx = token of current name
	;	dx = maximum length allowed for current name
	;	*ds:si = name array
	;
	lea	di, ss:nameBuffer		;es:di <- new name
	mov	ax, cx				;ax <- token for name
	mov	cx, dx				;cx <- length of name
	call	NameArrayChangeName
done:
	clc					;carry <- don't abort
	.leave
	ret

	;
	; The name could not be truncated because it would
	; conflict with another name.  Put up an annoying box
	; telling AndrewC which name couldn't be truncated.
	;
nameNoTruncate:
	push	ds, si, di, bp
	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax
	mov	si, offset NameCannotTruncateString
	mov	si, ds:[si]			;ds:si <- ptr to error string
	lea	di, ss:nameBuffer		;ss:di <- ptr to name
	clr	ax
	sub	sp, (size StandardDialogParams)
	mov	bp, sp				;ss:bp <- params
	mov	ss:[bp].SDOP_helpContext.segment, ax
	mov	ss:[bp].SDOP_customTriggers.segment, ax
	mov	ss:[bp].SDOP_stringArg2.segment, ax
	mov	ss:[bp].SDOP_stringArg1.segment, ss
	mov	ss:[bp].SDOP_stringArg1.offset, di
	mov	ss:[bp].SDOP_customString.segment, ds
	mov	ss:[bp].SDOP_customString.offset, si
	mov	ss:[bp].SDOP_customFlags, \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	UserStandardDialog
	call	MemUnlock
	pop	ds, si, di, bp
	jmp	done
FixOneHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTruncatedHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a name in the name array conflicts with the passed name

CALLED BY:	FixOneHelpName() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
		ss:bp - inherited locals
			nameBuffer - name to check against
		cx - element # that nameBuffer represents
		dx - maximum length nameBuffer can be
RETURN:		carry - set if name conflicts
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTruncatedHelpName		proc	far
	uses	ax, cx, dx
	.enter	inherit	FixOneHelpName

	;
	; Make sure this element is in use.  If not, this element
	; obviously doesn't conflict...
	;
	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nameOK
	;
	; Make sure the name we're looking at isn't our original name
	;
	call	ChunkArrayPtrToElement		;ax <- current element #
	cmp	ax, cx				;same element?
	je	nameOK				;branch if same element
	;
	; See if the name would conflict -- use the length of the
	; current name as the maximum to compare.  The name in nameBuffer
	; is NULL terminated, so LocalCmpStrings() will do the right thing
	; when comparing it...
	;
	call	ChunkArrayElementToPtr
	sub	cx, (size VisTextNameArrayElement)
DBCS <	shr	cx, 1				;cx <- length>
	cmp	cx, dx				;names different length?
	jb	nameOK				;OK if current name shorter
	lea	si, ds:[di][(size VisTextNameArrayElement)]
	segmov	es, ss
	lea	di, ss:nameBuffer		;es:di <- name #2
	call	LocalCmpStrings
	stc					;carry <- assume conflict
	je	done				;branch if conflict
nameOK:
	clc					;carry <- no conflict
done:
	.leave
	ret
CheckTruncatedHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyGraphicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy graphic data associated with each graphic element

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		bx - handle of GeoWrite file
		dx - handle of help file
		ds - seg addr of MapBlockHeader for GeoWrite document
		es:di - ptr to HelpFileMapBlock
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyGraphicData		proc	near
	uses	cx, si, di, ds, es, bp
	.enter

	;
	; Lock the graphic elements in the help file
	;
	push	bx
	mov	bx, dx				;bx <- handle of help file
	mov	ax, es:[di].HFMB_graphics
	call	VMLock
	mov	es, ax
	mov	di, es:[VM_ELEMENT_ARRAY_CHUNK]
EC <	cmp	es:[di].CAH_elementSize, (size VisTextGraphic) >
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE >
	tst	es:[di].CAH_count		;any graphics?
	pop	bx
	jz	unlockExit			;branch if no graphics
	;
	; Lock the graphic elements in the GeoWrite document
	;
	mov	ax, ds:MBH_graphicElements	;ax <- VM handle of graphics
	call	LockElementArray
	mov	si, ds:[si]			;ds:si <- graphic elements
	mov	cx, ds:[si].CAH_count
EC <	cmp	cx, es:[di].CAH_count		;>
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE >
EC <	cmp	ds:[si].CAH_elementSize, (size VisTextGraphic) >
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE >
	;
	; For each graphics element, copy the graphic data chain
	;
	add	di, es:[di].CAH_offset		;es:di <- ptr to 1st element
	add	si, ds:[si].CAH_offset		;ds:si <- ptr to 1st element
copyGraphicsLoop:
	cmp	ds:[si].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nextElement			;branch if unused element
	movdw	axbp, ds:[si].VTG_vmChain	;ax:bp <- VM chain
	tst	ax				;any chain?
	jz	nextElement			;branch if no chain
	call	VMCopyVMChain
	movdw	es:[di].VTG_vmChain, axbp	;store copied chain
nextElement:
	add	si, (size VisTextGraphic)
	add	di, (size VisTextGraphic)
	loop	copyGraphicsLoop		;loop while more elements
	;
	; Done with the graphic elements in the GeoWrite file
	;
	mov	bp, ds:LMBH_handle		;bp <- mem handle of graphics
	call	VMUnlock
	;
	; Dirty and unlock the graphic elements in the help file
	;
	mov	bp, es:LMBH_handle		;bp <- mem handle of graphics
	call	VMDirty
unlockExit:
	call	VMUnlock

	.leave
	ret
CopyGraphicData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSpaceToNameArray()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update an older name array to have additional space
		in it for help that we should have allowed for earlier
		but in a fit of something or another, didn't.

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		ss:bp - inherited locals
			helpFile - handle of help file
			nameArrayVM - VM handle of names
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSpaceToNameArray		proc	near
	uses	ax, bx, cx, dx, bp, si, di, ds
	.enter	inherit	WriteDocumentGenerateHelpFile

	;
	; Lock the name array
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	ax, ss:nameArrayVM		;ax <- VM block of names
	call	LockElementArray		;*ds:si <- name array
	;
	; Figure out how big the change is
	;
	mov	di, ds:[si]			;ds:di <- ptr to name array
	mov	dx, (size HelpFileNameArrayElement)-(size NameArrayElement)
	sub	dx, ds:[di].NAH_dataSize	;dx <- change in size
	add	ds:[di].NAH_dataSize, dx	;update header size
	mov	cx, ds:[di].CAH_count		;cx <- # of names
	jcxz	noNames				;branch if no names
	;
	; For each element in the name array, insert some additional space.
	;
	clr	ax				;ax <- start with 0th element
nameLoop:
	;
	; Calculate the pointer to the current name.  This is a little
	; tricky since we've updated any elements before this point,
	; so they are the new size not the old.  This is why we don't
	; use ChunkArrayEnum() for this -- it gets confused, and doesn't
	; like us using LMemInsertAt() anyway.
	;
	push	ax, cx
	call	ChunkArrayElementToPtr
	call	AddSpaceToOneName
	pop	ax, cx
	je	nextElement			;branch if empty element
	;
	; Fix up the chunk array size table
	;
	call	FixChunkArraySizes
	;
	; Go to next name, if any
	;
nextElement:
	inc	ax				;ax <- next name
	loop	nameLoop			;loop while more names
noNames:
	;
	; Mark the names as dirty and unlock them
	;
	call	VMDirty
	call	VMUnlock

	.leave
	ret
AddSpaceToNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSpaceToOneName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update one name to have extra space for help

CALLED BY:	AddSpaceToNameArray()
PASS:		*ds:si - chunk array
		ds:di - current element
		dx - change in size
RETURN:		ds - updated
		z flag - set (jz) if element is empty
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSpaceToOneName		proc	near
	uses	si
	.enter

	;
	; Insert additional space -- NOTE: LMemInsertAt() zeros
	; the new space, which is what we want.
	;
	mov	ax, si				;ax <- chunk
	mov	cx, dx				;cx <- # of bytes to insert
	mov	si, ds:[si]			;ds:si <- ptr to chunk array
	mov	bx, di				;ds:bx <- ptr to current element
	cmp	ds:[bx].NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done				;branch if empty
	add	bx, ds:[si].NAH_dataSize
	sub	bx, dx
	add	bx, (size NameArrayElement)	;ds:bx <- past existing data
	sub	bx, si				;bx <- offset from chunk
	call	LMemInsertAt
	cmp	ax, 0				;clear z flag
done:

	.leave
	ret
AddSpaceToOneName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixChunkArraySizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the sizes in a chunk array

CALLED BY:	AddSpaceToNameArray()
PASS:		*ds:si - 
		ax - element that has changed size
		dx - amount of change
RETURN:		none
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixChunkArraySizes		proc	near
	uses	ax
	.enter

	mov	di, ds:[si]			;ds:di <- ptr to header
	mov	bx, ax				;bx <- element #
	shl	bx
	add	bx, ds:[di].CAH_offset		;ds:bx <- offset to element
	add	bx, di				;ds:bx <- ptr to element
elementLoop:
	inc	ax				;next element
	cmp	ax, ds:[di].CAH_count		;at last element?
	je	lastElement			;branch if last element
	add	bx, (size word)
	add	ds:[bx], dx			;adjust offset
	jmp	elementLoop

lastElement:

	.leave
	ret
FixChunkArraySizes		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeStyleSheetRefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke any references to style sheets in an element array

CALLED BY:	WriteDocumentGenerateHelpFile()
PASS:		dx - VM file handle of help file
		ax - VM handle of element array
RETURN:		none
DESTROYED:	nnone

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeStyleSheetRefs		proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	mov	bx, dx				;bx <- VM file handle
	call	LockElementArray		;*ds:si <- element array
	;
	; Enum the elements to nuke the refs from the Kansas vs. Cal game
	;
	mov	bx, cs
	mov	di, offset NukeOneStyleSheetRef	;bx:di <- callback
	call	ChunkArrayEnum
	;
	; Mark the element array dirty and unlock it
	;
	call	VMDirty
	call	VMUnlock

	.leave
	ret
NukeStyleSheetRefs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeOneStyleSheetRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke one style sheet reference

CALLED BY:	NukeStyleSheetRefs() via ChunkArrayEnum()
PASS:		ds:di - ptr to element (StyleSheetElementHeader)
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeOneStyleSheetRef		proc	far
	.enter

	cmp	ds:[di].SSEH_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done				;skip if free element
	;
	; Nuke the style sheet reference
	;
	mov	ds:[di].SSEH_style, CA_NULL_ELEMENT
	;
	; NOTE: The following is a hack. Look away if you're the
	; squeamish sort...OK, I warned you.
	;
	; The problem is that MSG_VIS_TEXT_LOAD_FROM_DB_ITEM doesn't
	; deal quite properly with reference counts.  For help, this
	; is fine until we go to destroy the storage for our text
	; object in preparation for connecting it to a new file's
	; element arrays.  It does deal with the reference counts,
	; meaning that they get decremented as the runs that refer to
	; them are deleted.  Do this enough times, and you get zero,
	; and the element is deleted.  This would be fine, except for
	; a transitory moment where the text and structures are deleted
	; and the text object goes to redraw.  It tries to use a paragraph
	; attribute that has -- you guessed it -- been deleted.  Meaning
	; it draws in very lovely random colors and patterns.  So
	; we set it a nice big number.
	;
	clr	ds:[di].SSEH_meta.REH_refCount.WAAH_high
	mov	ds:[di].SSEH_meta.REH_refCount.WAAH_low, 0xeca
done:
	clc					;carry <- don't abort

	.leave
	ret
NukeOneStyleSheetRef		endp

HelpEditCode	ends
