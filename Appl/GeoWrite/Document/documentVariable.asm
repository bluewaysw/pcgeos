COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentVariable.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the track scrolling code

	$Id: documentVariable.asm,v 1.1 97/04/04 15:56:06 newdeal Exp $

------------------------------------------------------------------------------@

DocDrawScroll segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGetVariable -- MSG_GEN_DOCUMENT_GET_VARIABLE
						for WriteDocumentClass

DESCRIPTION:	Get a variable (for a text object)

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	ss:bp - GenDocumentGetVariableParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentGetVariable	method dynamic	WriteDocumentClass,
					MSG_GEN_DOCUMENT_GET_VARIABLE

	; is this a type that we recognize ?

	les	di, ss:[bp].GDGVP_graphic
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_manufacturerID,
						MANUFACTURER_ID_GEOWORKS
	jnz	passOn
	mov	di, es:[di].VTG_data.VTGD_variable.VTGV_type
	cmp	di, VTVT_NUMBER_OF_SECTIONS
	ja	checkDateOrTime

	call	LockMapBlockES
	movdw	dxax, ss:[bp].GDGVP_position.PD_y
	xchg	ax, bp				;dxbp = y pos
	call	FindPageAndSection		;cx = section, dx = abs page
EC <	ERROR_C	FIND_PAGE_RETURNED_ERROR				>
	mov	bp, ax				;restore bp
	mov_tr	ax, dx
	call	MapPageToSectionPage		;ax = section, bx = rel page
	mov	dx, bx				;dx = rel page

	shl	di
	call	cs:[numberRoutines][di]		;return dx = number

formatNumber::
	call	VMUnlockES

	pushdw	ss:[bp].GDGVP_buffer		;pass buffer
	clr	bx				;bxdx = number
	pushdw	bxdx				;pass number
	les	di, ss:[bp].GDGVP_graphic
	push	{word} es:[di].VTG_data.VTGD_variable.VTGV_privateData ;type
	call	VisTextFormatNumber

	ret

checkDateOrTime:
	cmp	di, VTVT_STORED_DATE_TIME
if _INDEX_NUMBERS
	ja	checkContext
else
	ja	passOn
endif	

	shl	di
	call	cs:[dateTimeRoutines][di-(2*VTVT_CREATION_DATE_TIME)]
	ret

if _INDEX_NUMBERS
checkContext:
	cmp	di, VTVT_CONTEXT_SECTION
	ja	passOn
	call	LockMapBlockES
	shl	di
	call	cs:[contextRoutines][di-(2*VTVT_CONTEXT_PAGE)]
	jmp	formatNumber
endif

passOn:
	segmov	es, <segment WriteDocumentClass>, di
	mov	ax, MSG_GEN_DOCUMENT_GET_VARIABLE
	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock

WriteDocumentGetVariable	endm

numberRoutines	nptr	GetPageNumber, GetPageNumberInSection, GetNumberOfPages,
			GetNumberOfPagesInSection, GetSectionNumber,
			GetNumberOfSections

dateTimeRoutines	nptr	\
	GetCreationTime, GetModificationTime, GetCurrentTime, GetStoredTime

if _INDEX_NUMBERS				
contextRoutines	nptr	GetContextPage, GetContextPageInSection,
			GetContextSection
endif

	; pass: ax = section #, bx = dx = relative page, es = map block
	; destroy: all

GetPageNumber	proc	near
	call	GetUserPageNumber		;dx = page number
	ret
GetPageNumber	endp

GetPageNumberInSection	proc	near
	inc	dx
	ret
GetPageNumberInSection	endp

GetNumberOfPages	proc	near
	mov	dx, es:MBH_totalPages
	ret
GetNumberOfPages	endp

GetNumberOfPagesInSection	proc	near
	call	SectionArrayEToP_ES
	mov	dx, es:[di].SAE_numPages
	ret
GetNumberOfPagesInSection	endp

GetSectionNumber	proc	near
	add	ax, es:[MBH_startingSectionNum]	;adjust for starting #
	mov_tr	dx, ax
	ret
GetSectionNumber	endp

GetNumberOfSections	proc	near
	segmov	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayGetCount
	mov	dx, cx
	ret
GetNumberOfSections	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetUserPageNumber

DESCRIPTION:	Convert an internal page number to a user page number

CALLED BY:	INTERNAL

PASS:
	es - map block
	ax - section number
	dx - page number in section

RETURN:
	dx - user page number

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
GetUserPageNumber	proc	near	uses cx, si, di, ds
	.enter

	segmov	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr

getPageNumBaseLoop:
	test	ds:[di].SAE_flags, mask SF_PAGE_NUMBER_FOLLOWS_LAST_SECTION
	jz	gotPageNumBase
	dec	ax
	call	ChunkArrayElementToPtr
	add	dx, ds:[di].SAE_numPages
	jmp	getPageNumBaseLoop

gotPageNumBase:
	add	dx, ds:[di].SAE_startingPageNum

	.leave
	ret

GetUserPageNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStoredTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and format the timestamp stored with the graphic.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= WriteDocument object
		ss:bp	= GenDocumentGetVariableParams
RETURN:		buffer filled in
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStoredTime	proc	near
	les	di, ss:[bp].GDGVP_graphic
	mov	ax,
		 {word}es:[di].VTG_data.VTGD_variable.VTGV_privateData[2]
	mov	bx,
		 {word}es:[di].VTG_data.VTGD_variable.VTGV_privateData[4]
	GOTO	FormatTimeStamp
GetStoredTime	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCreationTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and format the creation time of the document

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= WriteDocument object
		ss:bp	= GenDocumentGetVariableParams
RETURN:		buffer filled in
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCreationTime	proc	near
	class	WriteDocumentClass
	mov	ax, FEA_CREATION
	;
	; Fetch that attribute from the document file.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle
	
	mov	cx, size FileDateAndTime
	sub	sp, cx
	mov	di, sp
	segmov	es, ss
	call	FileGetHandleExtAttributes
	
		CheckHack <offset FDAT_date eq 0 and offset FDAT_time eq 2>
	pop	ax
	pop	bx
	
	GOTO	FormatTimeStamp
GetCreationTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetModificationTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and format the modification time of the document

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= WriteDocument object
		ss:bp	= GenDocumentGetVariableParams
RETURN:		buffer filled in
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetModificationTime	proc	near
	call	LockMapBlockDS
	mov	ax, ds:[MBH_revisionStamp].FDAT_date
	mov	bx, ds:[MBH_revisionStamp].FDAT_time
	call	VMUnlockDS
	GOTO	FormatTimeStamp
GetModificationTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and format the current time

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= WriteDocument object
		ss:bp	= GenDocumentGetVariableParams
RETURN:		buffer filled in
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentTime	proc	near
	call	GetNowAsTimeStamp
	FALL_THRU	FormatTimeStamp
GetCurrentTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a time stamp (FileDate + FileTime) into something
		readable.

CALLED BY:	(INTERNAL) GetCreationTime, GetModificationTime
PASS:		ax	= FileDate
		bx	= FileTime
		*ds:si	= WriteDocument object
		ss:bp	= GenDocumentGetVariableParams
RETURN:		buffer filled in
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatTimeStamp proc	near
	class	WriteDocumentClass
	les	di, ss:[bp].GDGVP_graphic
	mov	si,
		 {DateTimeFormat}es:[di].VTG_data.VTGD_variable.VTGV_privateData
	les	di, ss:[bp].GDGVP_buffer
	call	LocalFormatFileDateTime
	ret
FormatTimeStamp endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DVFindRegionByOffset

DESCRIPTION:	Find a region given its offset

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dxax - position

RETURN:
	ds:si - region data
	cx - region number

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version
	ardeb	3/30/94		stolen from trLargeInfo and optimized to not
				have to inclue other routines from there...

------------------------------------------------------------------------------@
if _INDEX_NUMBERS
DVFindRegionByOffset	proc	near
	class	VisLargeTextClass
	uses	ax, bx, dx, bp, di
	.enter

	mov	bx, dx				;bx.ax = position

	mov	si, ds:[si]
	add	si, ds:[si].VisLargeText_offset
	mov	si, ds:[si].VLTI_regionArray
	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	mov	dx, ds:[si].CAH_elementSize
	add	si, ds:[si].CAH_offset

	; ds:si = first region
	; cx = region count
	; dx = element size

	clr	bp

lloop:
	subdw	bxax, ds:[si].VLTRAE_charCount
	
	tst	bx				; Check for edge conditions
	js	gotRegion			; Branch if negative
	jnz	checkNext			; Branch if more to do
	
	tst	ax
	jnz	checkNext			; Branch if there's more to do

	;
	; The offset falls at the end of this region. Check to see if this
	; is the last region.
	;
	cmp	cx, 1
	je	gotRegion			; => no more regions, so
						;  must be last in last sect
	push	ax, si
	mov	ax, ds:[si].VLTRAE_section
	add	si, dx
	cmp	ax, ds:[si].VLTRAE_section	; is next region in different
						;  section?
	je	useNext				; no, so use it
	
	; it's the last region but not in the last section, so use the first
	; region of the next section, if it has any text...
	tstdw	ds:[si].VLTRAE_lineCount
	jz	notLast				; (carry clear)

useNext:
	pop	ax				; discard saved region
	push	si				; and use this one
	inc	bp				; don't forget region #
	stc
notLast:
	pop	ax, si
	jmp	gotRegion

checkNext:
	inc	bp
	add	si, dx
	loop	lloop

	dec	bp
	sub	si, dx

gotRegion:
	mov	cx, bp

	.leave
	ret
DVFindRegionByOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextInfoCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given element is for the token we're after

CALLED BY:	(INTERNAL) GetContextInfo via HugeArrayEnum
			sometimes called by ChunkArrayEnum
PASS:		ds:di	= TextRunArrayElement
		*es:bp	= VisTextType element array
		cx	= context token for which we seek
RETURN:		carry set to stop (found the run):
			dxax	= text position of start of run
		carry clear to keep going
			ax, dx	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextInfoCallback proc	far
		uses	di, si, bx
		.enter
		clr	dx		; zero-extend position...
		mov	dl, ds:[di].TRAE_position.WAAH_high
		mov	bx, ds:[di].TRAE_token
		mov	di, ds:[di].TRAE_position.WAAH_low
	;
	; Hacked optimization of ChunkArrayElementToPtr for type run...
	; bx	= element #
	; dxdi	= text position
	; 
		mov	si, es:[bp]	; es:si <- VisTextType array

EC <		cmp	es:[si].CAH_elementSize, 10			>
EC <		ERROR_NE	TYPE_ELEMENTS_NOT_10_BYTES_LONG		>
		shl	bx		; *2
		mov	ax, bx
		shl	bx		; *4
		shl	bx		; *8
		add	bx, ax		; *10
		add	bx, es:[si].CAH_offset	; bx <- offset from base of
						;  chunk array
		cmp	cx, es:[si][bx].VTT_context
		clc
		jne	done
		mov_tr	ax, di		; dxax <- text pos
		stc			; stop enumerating
done:
		.leave
		ret
GetContextInfoCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the section & page number for the context referred to
		by the graphic.

CALLED BY:	(INTERNAL) GetContextPageInSection,
			    GetContextPage,
			   GetContextSection
PASS:		ss:bp	= GenDocumentGetVariableParams
		es	= map block
		*ds:si	= WriteDocument object
RETURN:		ax	= section #
		dx	= page w/in section
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		lock the article block down
		find the type run whose context is that stored in the graphic
		find the region that contains that run
		use the spatial position of the region to find the section &
			absolute page
		use that to get the relative page

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextInfo	proc	near
		class	VisTextClass
		uses	ds, si, bx, cx, bp, di
		.enter
	;
	; First look for the type run in the object doing the query.
	; 
		push	si
		movdw	bxsi, ss:[bp].GDGVP_object
		call	ObjSwapLock

		call	FindContextRun
		call	ObjSwapUnlock
		pop	si
		jc	foundIt
	;
	; Not there. Walk through the articles for the document.
	; 
		segmov	ds, es
		mov	si, offset ArticleArray
		mov	bx, cs
		mov	di, offset GetContextInfoArticleCallback
		call	ChunkArrayEnum
foundIt:
		.leave
		ret
GetContextInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextInfoArticleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check in the next article for a type run
		for the given context.
		
		XXX: DO ARTICLES SHARE THE SAME NAME ARRAY?

CALLED BY:	(INTERNAL) GetContextInfo via ChunkArrayEnum
PASS:		ds:di	= ArticleArrayEntry
		ss:bp	= GenDocumentGetVariableParams
		es	= ds
RETURN:		carry set if found run:
			ax	= section #
			dx	= page w/in section
DESTROYED:	bx, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextInfoArticleCallback proc	far
		uses	ds
		.enter
	;
	; Get the od of the article and lock it down.
	; 
		mov	bx, ds:[di].AAE_articleBlock
		call	VMBlockToMemBlockRefDS
		call	ObjLockObjBlock
		mov	ds, ax
		mov	si, offset ArticleText
	;
	; Call common code to search for the run.
	; 
		call	FindContextRun
	;
	; Unlock the article block, preserving what we need to return.
	; 
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		.leave
		ret
GetContextInfoArticleCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindContextRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a type run for the graphic's context in the passed
		text object.

CALLED BY:	(INTERNAL) GetContextInfo, GetContextInfoArticleCallback
PASS:		*ds:si	= text object
		es	= locked map block
		ss:bp	= GenDocumentGetVariableParams
RETURN:		carry set if run found:
			ax	= section
			dx	= relative page
DESTROYED:	cx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindContextRun	proc	near
		uses	ds, si, bx, bp
		class	VisLargeTextClass
		.enter
	;
	; Find the type run array.
	; 
		mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
		call	ObjVarFindData
		jnc	done	; => no type runs for the object, so nowhere
				;  to look

   		mov	dx, ds:[bx]	; dx <- run array
	;
	; Make sure the text object is large, as otherwise it can't have a
	; section and page number, making it useless for our purposes.
	; 
		mov	bx, ds:[si]
		add	bx, ds:[bx].VisText_offset
		test	ds:[bx].VTI_storageFlags, mask VTSF_LARGE
		jz	done
	;
	; Extract the context for which we'll be searching from the graphic
	; data, as we'll need it in all three of the cases described below.
	; 
		push	es			; save map block
		les	di,ss:[bp].GDGVP_graphic
		mov	cx,				; cx <- context token
			{word}es:[di].VTG_data.VTGD_variable.VTGV_privateData[2]

	;
	; Lock down the element array's block and huge-array enum over the run
	; array.
	; 
		push	bp
		mov	bx, ds:[LMBH_handle]
		mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
		call	MemGetInfo
		mov_tr	bx, ax

		mov	ax, dx			; ax <- run array, for locking
						;  (still need dx for passing
						;  to HAE)
		call	VMLock			; lock the run array directory
		mov	es, ax			;  block down so we can find the
		mov	ax, es:[TLRAH_elementVMBlock]	; handle of the element
		call	VMUnlock			;  array

		call	VMLock		; lock down the element block
		mov	es, ax				; *es:bp <- elt array
		mov	bp, es:[LMBH_offset]		; VTT element array is
							;  first chunk in the
							;  block
	    ;
	    ; Now set up the args for HugeArrayEnum to find the run with the
	    ; graphic's context token.
	    ; 
		push	bx		; file handle
   		push	dx		; run array handle
		push	cs
		mov	ax, offset GetContextInfoCallback
		push	ax		; callback
		clr	ax		; start w/first element
		push	ax, ax
		dec	ax		; and process all of them
		push	ax, ax

		call	HugeArrayEnum	; dxax <- position
		pop	bp

		call	VMUnlockES	; won't need the actual element for
					;  this...
		pop	es		; es <- document map block
		jc	haveTypePos	; => found
		clr	ax, dx		; if can't find, use section 0, page 0
		jmp	done

haveTypePos:
	;
	; Great. We've now got the position of the run and have to convert that
	; to the spatial position of the region that contains it so we can
	; convert that into the page and section number....
	; 
	; dxax = position of type run
	; *ds:si = text object
	; 
		call	DVFindRegionByOffset ; ds:si <- region data
		mov	cx, ds:[si].VLTRAE_spatialPosition.PD_x.low
		movdw	dxbp, ds:[si].VLTRAE_spatialPosition.PD_y
		call	FindPageAndSectionAbs
	;
	; Ok, now convert the page and section to the proper page number.
	; 
		mov_tr	ax, dx
		call	MapPageToSectionPage	;ax <- section, bx <- rel page
		mov	dx, bx			;dx = rel page
		stc
done:
		.leave
		ret
FindContextRun	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the absolute page number for a context

CALLED BY:	(INTERNAL) WriteDocumentGetVariable
PASS:		ss:bp	= GenDocumentGetVariableParams
		es	= map block
RETURN:		dx	= # to format
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextPage	proc	near
		uses	ax
		.enter
		call	GetContextInfo	; ax <- sect #, dx <- rel page
		call	GetUserPageNumber
		.leave
		ret
GetContextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextPageInSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the page number for a context within its section

CALLED BY:	(INTERNAL) WriteDocumentGetVariable
PASS:		ss:bp	= GenDocumentGetVariableParams
		es	= map block
RETURN:		dx	= # to format
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextPageInSection proc	near
		.enter
		call	GetContextInfo	; ax <- sect #, dx <- rel page #
		inc	dx
		.leave
		ret
GetContextPageInSection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the section number for a context

CALLED BY:	(INTERNAL) WriteDocumentGetVariable
PASS:		ss:bp	= GenDocumentGetVariableParams
		es	= map block
RETURN:		dx	= # to format
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextSection proc	near
		.enter
		call	GetContextInfo	; ax <- sect #, dx <- rel page #
		add	ax, es:[MBH_startingSectionNum]
		mov_tr	dx, ax
		.leave
		ret
GetContextSection endp

endif		; if _INDEX_NUMBERS

DocDrawScroll ends

if _INDEX_NUMBERS

DocMiscFeatures	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentGetTOCContextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_DOCUMENT_GET_TOC_CONTEXT_MONIKER
PASS:		bp	= index of needed moniker
		^lcx:dx	= list requesting it
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentGetTOCContextMoniker method dynamic WriteDocumentClass, MSG_WRITE_DOCUMENT_GET_TOC_CONTEXT_MONIKER
		.enter
		mov	di, MSG_VIS_TEXT_GET_NAME_LIST_MONIKER
		call	WriteDocumentTOCListCommon
		.leave
		ret
WriteDocumentGetTOCContextMoniker		endm

WriteDocumentTOCListCommon proc near
		call	LockMapBlockES
		call	LockArticleBeingEdited
		mov_tr	ax, bp
		sub	sp, size VisTextNameCommonParams
		mov	bp, sp
		movdw	ss:[bp].VTNCP_object, cxdx
		mov	ss:[bp].VTNCP_index, ax
		mov	ss:[bp].VTNCP_data.VTND_type, VTNT_CONTEXT
		mov	ss:[bp].VTNCP_data.VTND_file, 0	; current file
		mov_tr	ax, di
		call	ObjCallInstanceNoLock
		add	sp, size VisTextNameCommonParams
		call	VMUnlockDS
		call	VMUnlockES
		ret
WriteDocumentTOCListCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentTOCContextListVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentTOCContextListVisible		method dynamic WriteDocumentClass, MSG_WRITE_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
		.enter
		mov	di, MSG_VIS_TEXT_UPDATE_NAME_LIST
		call	WriteDocumentTOCListCommon
		.leave
		ret
WriteDocumentTOCContextListVisible		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentGetTokenForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map from a context index to an actual context token, as is
		stored in a type run element, for the current article.

CALLED BY:	MSG_WRITE_DOCUMENT_GET_TOKEN_FOR_CONTEXT
PASS:		*ds:si	= WriteDocument object
		ds:di	= WriteDocumentInstance
		cx	= context index for current article
RETURN:		cx	= context token (CA_NULL_ELEMENT if invalid)
DESTROYED:	ax (si, di, ds, es)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentGetTokenForContext method dynamic WriteDocumentClass, 
					MSG_WRITE_DOCUMENT_GET_TOKEN_FOR_CONTEXT
		uses	dx, bp
		.enter
		call	LockMapBlockES
		call	LockArticleBeingEdited	; *ds:si <- article
	;
	; Map the context list index to the context name token for permanence
	; and so we can find the appropriate type range later. The size
	; of the buffer on the stack is increased by 1 to make it an even
	; number, which makes swat happier.
	; 
		sub	sp, size VisTextFindNameIndexParams + \
				size NameArrayMaxElement + 1
		mov	bp, sp
		mov	ss:[bp].VTFNIP_index, cx
		mov	ss:[bp].VTFNIP_type, VTNT_CONTEXT
		mov	ss:[bp].VTFNIP_file, 0 	; current file list index
		lea	ax, ss:[bp+size VisTextFindNameIndexParams]
		movdw	ss:[bp].VTFNIP_name, ssax

		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_INDEX
		mov	dx, size VisTextFindNameIndexParams
		call	ObjCallInstanceNoLock
		add	sp, size VisTextFindNameIndexParams + \
				size NameArrayMaxElement + 1
		call	VMUnlockDS
		call	VMUnlockES
		mov_tr	cx, ax
		.leave
		ret
WriteDocumentGetTokenForContext		endm

DocMiscFeatures	ends

endif		; if _INDEX_NUMBERS
