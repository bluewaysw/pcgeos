COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentVariable.asm

ROUTINES:
	Name				Description
	----				-----------
    INT GetPageNumber		Get a variable (for a text object)

    INT GetPageNumberInSection	Get a variable (for a text object)

    INT GetNumberOfPages	Get a variable (for a text object)

    INT GetNumberOfPagesInSection 
				Get a variable (for a text object)

    INT GetSectionNumber	Get a variable (for a text object)

    INT GetNumberOfSections	Get a variable (for a text object)

    INT GetUserPageNumber	Convert an internal page number to a user
				page number

    INT GetStoredTime		Fetch and format the timestamp stored with
				the graphic.

    INT GetCreationTime		Fetch and format the creation time of the
				document

    INT GetModificationTime	Fetch and format the modification time of
				the document

    INT GetCurrentTime		Fetch and format the current time

    INT FormatTimeStamp		Format a time stamp (FileDate + FileTime)
				into something readable.

METHODS:
	Name			Description
	----			-----------
    StudioDocumentGetVariable	Get a variable (for a text object)

				MSG_GEN_DOCUMENT_GET_VARIABLE
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the track scrolling code

	$Id: documentVariable.asm,v 1.1 97/04/04 14:39:31 newdeal Exp $

------------------------------------------------------------------------------@

DocDrawScroll segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGetVariable -- MSG_GEN_DOCUMENT_GET_VARIABLE
						for StudioDocumentClass

DESCRIPTION:	Get a variable (for a text object)

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentGetVariable	method dynamic	StudioDocumentClass,
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

formatNumber:
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
	ja	checkContext
	
	shl	di
	call	cs:[dateTimeRoutines][di-(2*VTVT_CREATION_DATE_TIME)]
	ret

checkContext:
	cmp	di, VTVT_CONTEXT_NAME
	ja	passOn
	call	LockMapBlockES
	shl	di
	call	cs:[contextRoutines][di-(2*VTVT_CONTEXT_PAGE)]
	;
	; there is no number to format if this is a context name
	;
	cmp	di, (2*VTVT_CONTEXT_NAME)	;*2 because di was left shifted
	jne	formatNumber
	call	VMUnlockES
	ret

passOn:
	call	StudioGetDGroupES
	mov	ax, MSG_GEN_DOCUMENT_GET_VARIABLE
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentGetVariable	endm

numberRoutines	nptr	GetPageNumber, GetPageNumberInSection, GetNumberOfPages,
			GetNumberOfPagesInSection, GetSectionNumber,
			GetNumberOfSections

dateTimeRoutines	nptr	\
	GetCreationTime, GetModificationTime, GetCurrentTime, GetStoredTime

contextRoutines	nptr	GetContextPage, GetContextPageInSection,
			GetContextSection, GetContextName
				
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
	inc	ax
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
PASS:		*ds:si	= StudioDocument object
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
PASS:		*ds:si	= StudioDocument object
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
	class	StudioDocumentClass
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
PASS:		*ds:si	= StudioDocument object
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
PASS:		*ds:si	= StudioDocument object
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
		*ds:si	= StudioDocument object
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
	class	StudioDocumentClass
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
PASS:		ds:di	= TextRunArrayElement
		es	= segment of element array block
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
		uses	di, ds, si, bx
		.enter
		clr	dx
		mov	dl, ds:[di].TRAE_position.WAAH_high
		mov	bx, ds:[di].TRAE_token
		mov	di, ds:[di].TRAE_position.WAAH_low
		
	;
	; Hacked optimization of ChunkArrayElementToPtr for type run...
	; bx	= element #
	; dxdi	= text position
	; 
		segmov	ds, es
		mov	si, ds:[LMBH_offset]
		mov	si, ds:[si]
EC <		cmp	ds:[si].CAH_elementSize, 10			>
EC <		ERROR_NE	TYPE_ELEMENTS_NOT_10_BYTES_LONG		>
		shl	bx		; *2
		mov	ax, bx
		shl	bx		; *4
		shl	bx		; *8
		add	bx, ax		; *10
		add	bx, ds:[si].CAH_offset	; bx <- offset from base of
						;  chunk array
		cmp	cx, ds:[si][bx].VTT_context
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
		uses	ds, si, bx, cx, bp, di
		.enter
		push	es		; save map block
		call	GetFileHandle
		push	bx		; and save it...
	;
	; Lock down the object doing the query.
	; 
		movdw	bxsi, ss:[bp].GDGVP_object
		call	ObjLockObjBlock
		mov	ds, ax
	;
	; Find the type run array.
	; 
		mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
		call	ObjVarFindData
EC <		ERROR_NC	MUST_HAVE_TYPE_RUNS_TO_USE_CONTEXT_VARS	>
   		mov	ax, ds:[bx]	; ax <- run array, for getting elt
		mov	dx, ax		; dx <- run array, for passing to HAE
	;
	; Lock down the run array so we can get to the element block
	; 
		pop	bx
		push	bp
		call	VMLock
		mov	es, ax
		mov	ax, es:[TLRAH_elementVMBlock]
		call	VMUnlock

		call	VMLock		; lock down the element block
		mov	es, ax
		pop	bp
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

		push	es		; fetch context token into CX for
					;  callback to use
		les	di, ss:[bp].GDGVP_graphic
		mov	cx, 		; cx <- context token
			{word}es:[di].VTG_data.VTGD_variable.VTGV_privateData[2]
		pop	es
		call	HugeArrayEnum	; dxax <- position
		call	VMUnlockES	; won't need the actual element for
					;  this...
		pop	es		; es <- map block
		jc	haveTypePos
		clr	ax, dx		; if can't find, use section 0, page 0
		jmp	done

haveTypePos:
		call	DVFindRegionByOffset ; ds:si <- region data
		mov	cx, ds:[si].VLTRAE_spatialPosition.PD_x.low
		movdw	dxbp, ds:[si].VLTRAE_spatialPosition.PD_y
		call	FindPageAndSectionAbs
		mov_tr	ax, dx
		call	MapPageToSectionPage	;ax <- section, bx <- rel page
		mov	dx, bx			;dx = rel page
done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		.leave
		ret
GetContextInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name for the context referred to
		by the graphic.

CALLED BY:	(INTERNAL) GetContextPageInSection,
			    GetContextPage,
			   GetContextSection
PASS:		ss:bp	= GenDocumentGetVariableParams
		es	= map block
		*ds:si	= WriteDocument object
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextName	proc	near
		uses	ax, bx, cx, dx, si, ds, di, es
		.enter

	;
	; Lock down the object doing the query.
	; 
		movdw	bxsi, ss:[bp].GDGVP_object
		call	ObjLockObjBlock
		mov	ds, ax

		sub	sp, size NameArrayMaxElement 
		movdw	cxdx, sssp		; buffer for name element

		push	bp
		les	di, ss:[bp].GDGVP_graphic
		mov	bp, 			; bp <- context token
		     {word}es:[di].VTG_data.VTGD_variable.VTGV_privateData[2]
		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
		call	ObjCallInstanceNoLock	; ax <- element size
		pop	bp
	;
	; copy up to (buffer size - 1) chars of the name to buffer
	;
		movdw	dssi, cxdx
		add	si, size VisTextNameArrayElement
		les	di, ss:[bp].GDGVP_buffer
		mov	cx, ax
		sub	cx, size VisTextNameArrayElement
		cmp	cx, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
		jb	moveIt
		mov	cx, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE - 1
moveIt:
		rep	movsb
		mov	{byte}es:[di], 0
		
		add	sp, size NameArrayMaxElement 

		mov	bx, ss:[bp].GDGVP_object.handle
		call	MemUnlock

		.leave
		ret
GetContextName	endp


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

DocDrawScroll ends

DocMiscFeatures	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentGetTOCContextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_STUDIO_DOCUMENT_GET_TOC_CONTEXT_MONIKER
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
StudioDocumentGetTOCContextMoniker method dynamic StudioDocumentClass, MSG_STUDIO_DOCUMENT_GET_TOC_CONTEXT_MONIKER
		.enter
		mov	di, MSG_VIS_TEXT_GET_NAME_LIST_MONIKER
		call	StudioDocumentTOCListCommon
		.leave
		ret
StudioDocumentGetTOCContextMoniker		endm

StudioDocumentTOCListCommon proc near
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
StudioDocumentTOCListCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentTOCContextListVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_STUDIO_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
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
StudioDocumentTOCContextListVisible	method dynamic StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
		.enter
		mov	di, MSG_VIS_TEXT_UPDATE_NAME_LIST
		call	StudioDocumentTOCListCommon
		.leave
		ret
StudioDocumentTOCContextListVisible		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentInsertContextNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_STUDIO_DOCUMENT_INSERT_CONTEXT_NUMBER
PASS:		*ds:si - document

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentInsertContextNumber	method dynamic StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_INSERT_CONTEXT_NUMBER

	push	si
	GetResourceHandleNS	InsertContextNumberNumberList, bx
	mov	si, offset InsertContextNumberNumberList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = VisTextVariableType
EC <	cmp	ax, VTVT_CONTEXT_PAGE					>
EC <	ERROR_B -1							>
EC <	cmp	ax, VTVT_CONTEXT_SECTION				>
EC <	ERROR_A -1							>

	push	ax
	mov	si, offset InsertContextNumberFormatList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = format
	mov_tr	bp, ax				;bp = format
	pop	dx				;dx = VisTextVariableType

	mov	si, offset InsertContextNumberContextList
	push	dx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = name index
	pop	dx, bp
	pop	si

	call	StudioDocumentListIndexToNameToken	;ax = name token
	call	StudioDocumentInsertVariableGraphic
	ret
StudioDocumentInsertContextNumber		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentListIndexToNameToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a context list index to a name token

CALLED BY:	StudioDocumentInsertContextNumber
PASS:		ax - name index
		*ds:si -document
RETURN:		ax - name token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentListIndexToNameToken		proc	near
		uses	bx, dx, bp, si
		.enter

		mov	cx, ax
		call	LockMapBlockES
		call	LockArticleBeingEdited	;*ds:si = article
		mov	ax, MSG_STUDIO_ARTICLE_PAGE_NAME_INDEX_TO_TOKEN
		call	ObjCallInstanceNoLock	; ax = name token
		call	VMUnlockDS
		call	VMUnlockES
		
		.leave
		ret
StudioDocumentListIndexToNameToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentInsertVariableGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a variable graphic char

CALLED BY:	StudioDocumentInsertContextNumber
PASS:		dx - VisTextVariableType
		bp - format
		ax - name token
RETURN:		nothing
DESTROYED:	everything but ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentInsertVariableGraphic		proc	near
	uses	ax
	.enter

	mov	bx, bp				;bx = data

	sub	sp, size ReplaceWithGraphicParams
	mov	bp, sp

	; zero out the structure

	push	ax
	segmov	es, ss, ax
	mov	di, bp
	mov	cx, size ReplaceWithGraphicParams
	clr	ax
	rep	stosb
	pop	ax
		
	mov	ss:[bp].RWGP_graphic.VTG_type, VTGT_VARIABLE
	mov	ss:[bp].RWGP_graphic.VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_manufacturerID,		MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_type, dx
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData, bx
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[2],
			ax	; name token

	mov	ax, VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].RWGP_range.VTR_start.high, ax
	mov	ss:[bp].RWGP_range.VTR_start.high, ax

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	mov	dx, size ReplaceWithGraphicParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	EncapsulateToTargetVisText

	add	sp, size ReplaceWithGraphicParams

	.leave
	ret
StudioDocumentInsertVariableGraphic		endp

DocMiscFeatures	ends

