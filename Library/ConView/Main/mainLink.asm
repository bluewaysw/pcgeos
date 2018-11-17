COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainLink.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

MESSAGES:
	MSG_CGV_GET_LINK_NAMES	Return the name of the link.

ROUTINES:
	Name			Description
	----			-----------
    INT MLGetNamesForLink	Convert link tokens to names and store
				names in ContentTextRequest

    INT UpdateStateDataWithLocals 
				Copy the filename and context in
				ContentTextRequest into the
				ContentGenView's state data

    INT MLDisplayText		Display the text for the context -- show
				the text at the current link

    INT MLGetContextElementNumber 
				Common code for getting a pointer to a name
				array elt for a context.  The context is in
				the current file.

    INT MLFindContextCallback	Callback routine for MLGetTokenForContext

    INT MLLoadContentTextRequest 
				Loads the context and filename of the
				passed name array element into the passed
				ContentTextRequest buffer.

    INT MLGetTokenForPage	Returns the name array element whose page
				number is dx.

    INT MLGetTokenForPageCallback 
				Finds name array element with pageNumber
				equal to dx.

    INT MLSetFlagsForSpecialContext 
				Checks if the context we're going to is a
				TOC or the main page for the book.  Adjusts
				ax appropriately.

    GLB LoadOrFreeCompressLib	Loads/frees the compress library, depending
				upon whether or not it is necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Code needed for following hyperlinks.
		

	$Id: mainLink.asm,v 1.1 97/04/04 17:49:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVGetBookFeatureFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_CGV_GET_BOOK_FEATURE_FLAGS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentGenViewClass
		ax - the message
RETURN:		ax - features
		dx - tools
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/14/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVGetBookFeatureFlags		method dynamic ContentGenViewClass,
						MSG_CGV_GET_BOOK_FEATURE_FLAGS
		mov	ax, ds:[di].CGVI_bookFeatures
		mov	dx, ds:[di].CGVI_bookTools
		ret
CGVGetBookFeatureFlags		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewDisplayTOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the main page (TOC).

CALLED BY:	MSG_CGV_DISPLAY_TOC (from nav controller)
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp  (method)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewDisplayTOC	method dynamic ContentGenViewClass, 
					MSG_CGV_DISPLAY_TOC

		sub	sp, (size ContentTextRequest)
		mov	bp, sp
		push	ds:[LMBH_handle], si		;Save CGView
	;
	; Get name of file that has main page.
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_filename	;es:di<- dest
		mov	ax, CONTENT_MAIN_FILE
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	;
	; Record "TOC" as the context.
	;
		mov	bx, handle ContentStrings
		call	MemLock
		mov	ds, ax
		mov	si, offset tocString	
		mov	si, ds:[si]			;ds:si <- ptr to "TOC"
		lea	di, ss:[bp].CTR_context	;es:di <- dest
		ChunkSizePtr	ds, si, cx
		rep	movsb				;copy "TOC"
		call	MemUnlock
	;
	; Nav will need full notification. It will need to be told the
	; context being switched to (since user didn't use history
	; list to cause the switch).
	;
		mov	ss:[bp].CTR_flags, mask CTRF_needContext 
						;Tell nav the new context

		mov	ax, MSG_CGV_DISPLAY_TEXT
		mov	di, mask MF_STACK or mask MF_CALL
		mov	dx, (size ContentTextRequest)
		pop	bx, si
		call	ObjMessage
		add	sp, (size ContentTextRequest)

		call	MemDerefDS
		ret
ContentGenViewDisplayTOC	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewFollowLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow a link in a content file.

CALLED BY:	MSG_CGV_FOLLOW_LINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentGenViewClass
		ax - the message

		cx - token of link name
		dx - token of link file (-1 for same)

RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version
	lester	10/ 4/94  	Broke out MSG_CGV_FOLLOW_LINK_LOW

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewFollowLink		method dynamic ContentGenViewClass,
						MSG_CGV_FOLLOW_LINK

		call	AppMarkBusy

		sub	sp, size ContentTextRequest
		mov	bp, sp
	;
	; Convert the link tokens to names
	;
		call	MLGetNamesForLink
	;
	; Follow the link
	;
		mov	ax, MSG_CGV_FOLLOW_LINK_LOW
		call	ObjCallInstanceNoLock

		add	sp, size ContentTextRequest

		call	AppMarkNotBusy
		ret
ContentGenViewFollowLink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewFollowLinkLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow the link specified in the ContentTextRequest.

CALLED BY:	MSG_CGV_FOLLOW_LINK_LOW
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		ss:bp	- ContentTextRequest
			  CTR_filename - file we're going to
			  CTR_context  - page we're going to in that file

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es (method handler)

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/ 4/94   	Initial version
	lester	10/ 4/94  	Broke out of MSG_CGV_FOLLOW_LINK so it can
				be intercepted to change the context or 
				filename.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewFollowLinkLow	method dynamic ContentGenViewClass, 
					MSG_CGV_FOLLOW_LINK_LOW
		.enter
	;
	; Check for special hyperlinks
	;
		call	MSLHandleSpecialLink
		jz	done
	;
	; Display the new text
	;
		clr	ss:[bp].CTR_flags
		call	MLDisplayText
		jc	openError			;branch if error

		clr	dx
		call	UpdateStateDataWithLocals
	;
	; Update various things for history
	;
		segmov	es, ss
		lea	di, ss:[bp].CTR_context
		call	MNGetPrevNextStatusGivenName	;ax<-prev/next status
							;cx<-page
		call	MLSetFlagsForSpecialContext
		call	MUSetPage
		BitSet	ax, NNCCF_updateHistory		;DO update history list
		call	ContentSendNotification
		
done:
		.leave
		ret
openError:
		BitClr	ss:[bp].CTR_flags, CTRF_needContext ;don't update 
		call	MLRedisplayCurrentPage		    ; history list
		jmp	done

ContentGenViewFollowLinkLow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLRedisplayCurrentPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called if unsuccessful loading a new page, and want to
		redisplay the current page.

CALLED BY:	ContentGenViewFollowLinkLow, CGVDisplayText
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
			CTR_flags CTRF_needContext - 1 to update history list
RETURN:		
DESTROYED:	ax, bx, cx, dx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLRedisplayCurrentPage		proc	near
		.enter
	;
	; The desired context could not be displayed.  Redisplay the
	; previous context. Must first set the file and link names in
	; ContentTextRequest buffer.
	;
		lea	di, ss:[bp].CTR_filename		
		segmov	es, ss, ax			; es:di <- dest
		mov	ax, CONTENT_FILENAME
		call	ContentGetStringVardata
		jnc	sendNull

		lea	di, ss:[bp].CTR_context
		mov	ax, CONTENT_LINK
		call	ContentGetStringVardata
		jnc	sendNull
	;
	; Delete the filename vardata, so that MLDisplayText will
	; not think that this file is already open (it was closed
	; in MLDisplayText before trying to open the new file).
	;
	; Free text storage and close old file, if any
	;
		clr	cx, bx
		call	MFSetFileCloseOld
		mov	ax, CONTENT_FILENAME
		call	ObjVarDeleteData

		call	MLDisplayText
		jc	sendNull
		clr	dx		; update filename
		call	UpdateStateDataWithLocals
	;	
	; Send out a Context notification
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_context		
		call	MNGetPrevNextStatusGivenName	;ax<-status, cx<-page		

		mov	dx, ss:[bp].CTR_flags
		test	dx, mask CTRF_needContext		
		jz	checkForRestore
		BitSet	ax, NNCCF_updateHistory		; Do update history.

checkForRestore:
		test	dx, mask CTRF_restoreFromState
		jz	noRestore
		BitClr	ax, NNCCF_updateHistory		;don't update history
		BitSet	ax, NNCCF_retnWithState		; if restoring fr state

noRestore:
		call	MUSetPage
		call	MLSetFlagsForSpecialContext
		call	ContentSendNotification
		jmp	done
sendNull:
	;
	; For some reason, we couldn't restore to previous context.
	; Send out a null notification, so that controllers disable
	; all tools and features.
	;
		call	ContentSendNullNotification
done:		
		.leave
		ret
MLRedisplayCurrentPage		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetNamesForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert link tokens to names and store names
		in ContentTextRequest

CALLED BY:	ContentGenViewFollowLink
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
		cx - token of link name
		dx - token of link file (-1 for same)
RETURN:		filename and context filled in
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetNamesForLink		proc	near
		uses	si,di,ds,es
		.enter	
EC <		call	AssertIsCGV				>	

	;
	; First get the filename from the ContentGenView's
	; vardata if our link is to the same file (token is -1).
	;
		cmp	dx, -1
		jne	notSameFile

		lea	di, ss:[bp].CTR_filename		
		segmov	es, ss, ax			; es:di <- dest
		mov	ax, CONTENT_FILENAME
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_FILE_IN_VARDATA		>

notSameFile:
	;
	; Convert the tokens to names
	;
		segmov	es, ss, ax
		clr	ax				; don't get searchText
		call	MNLockNameArray			;*ds:si <- name array
		cmp	dx, -1				;same file?
		je	afterFile			;branch if same file
		lea	di, ss:[bp].CTR_filename	;es:di <- dest buffer
		mov	ax, dx				;ax <- file token
		call	MNGetName

afterFile:
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_context		;es:di <- dest buffer
		mov	ax, cx				;ax <- link name token
		call	MNGetName
	;
	; Finished with the name array
	;
		call	MNUnlockNameArray

		.leave
		ret
MLGetNamesForLink		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVGetLinkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of the link.

CALLED BY:	MSG_CGV_GET_LINK_NAMES
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		ss:bp	= CGVGetLinkNameParams
			  linkToken - token of link name
			  fileToken - token of file name (-1 for same)
			
RETURN:		ss:bp	= filled in CGVGetLinkNameParams
			  linkName and fileName filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVGetLinkName				method dynamic ContentGenViewClass, 
					MSG_CGV_GET_LINK_NAME

	;
	; First get the filename from the ContentGenView's
	; vardata if our link is to the same file (token is -1).
	;
	mov	dx, ss:[bp].CGVGLNP_fileToken		; dx <- file token
	cmp	dx, -1
	jne	notSameFile

	segmov	es, ss, ax			
	lea	di, ss:[bp].CGVGLNP_fileName		; es:di <- dest
	mov	ax, CONTENT_FILENAME
	call	ContentGetStringVardata
EC <	ERROR_NC CONTENT_COULDNT_FIND_FILE_IN_VARDATA	>

notSameFile:
	;
	; Convert the tokens to names
	;
	push	ds, si
	segmov	es, ss, ax
	clr	ax				;clr CTRF_searchText
	call	MNLockNameArray			;*ds:si <- name array

	cmp	dx, -1				;same file?
	je	afterFile			;branch if same file

	lea	di, ss:[bp].CGVGLNP_fileName	;es:di <- dest buffer
	mov_tr	ax, dx				;ax <- file token
	call	MNGetName

afterFile:
	mov	ax, ss:[bp].CGVGLNP_linkToken	;ax <- token of link name
	segmov	es, ss, cx
	lea	di, ss:[bp].CGVGLNP_linkName	;es:di <- dest buffer
	call	MNGetName
	;
	; Finished with the name array
	;
	call	MNUnlockNameArray
	pop	ds, si

	.leave
	ret
CGVGetLinkName		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateStateDataWithLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the filename and context in ContentTextRequest
		into the ContentGenView's state data

CALLED BY:	ContentGenViewFollowLink
PASS:		*ds:si	- ContentGenView instance
		ss:bp - ContentTextRequest
		dx - token of filename being linked to
		     (-1 for same file)
RETURN:		vardata of ContentGenView updated
		no registers changed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Notice that we check for same file to save
		time.  We don't check for same context since
		we would not link from the old context to a
		new context of the same name!  (...unless the 
		context of the same name appears in a different
		file.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateStateDataWithLocals	proc	near
	uses	bx,ax,dx
	.enter	
EC <	call	AssertIsCGV				>	

	cmp	dx, -1				; If same file, only update
						; context name.
	mov	bx, ss
	je	contextOnly
	;
	; Update filename.
	;
	mov	ax, CONTENT_FILENAME or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_filename
	call	ContentAddStringVardata
	;
	; Update context.
	;
contextOnly:
	mov	ax, CONTENT_LINK or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_context
	call	ContentAddStringVardata

	.leave
EC <	call	AssertIsCGV				>	
	ret
UpdateStateDataWithLocals	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLDisplayText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the text for the context -- show the text at the
		current link

CALLED BY:	ContentGenViewFollowLink,
		ContentGenViewDisplayTextForNav
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
			CTR_context - name of context
			CTR_filename - name of help file
			CTR_flags - 
				CTRF_searchMatch - set if we don't want
					to delete search state data
RETURN:		carry - set if error occurred
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLDisplayText		proc	far
	uses	si
	class	ContentGenViewClass
	.enter	
EC <	call	AssertIsCGV				>	

	test	ss:[bp].CTR_flags, mask CTRF_searchMatch
	jnz	noAbort		
	mov	ax, MSG_ABORT_ACTIVE_SEARCH
	call	ObjCallInstanceNoLock	
noAbort:
	;
	; Is this the same file we've already got open?
	;
	call	SameFile?			;same file?
	je	afterOpen			;branch if same file
	;
	; Free text storage, close old file, save new file handle for later
	;
	clr	cx, bx
	call	MFSetFileCloseOld
	;
	; Open the help file
	;
	call	MFOpenFile			;bx <- handle of help file
	jc	reportError			;branch if error opening file
	call	MUSetFileFlags			;save CFMB_flags in instance
	;
	; Free text storage, close old file, save new file handle for later
	;
	clr	cx
	call	MFSetFileCloseOld
	;
	; Connect various text object attributes, including the
	; ever-important name array
	;
	clr	ax				;clear CTRF_searchText flag
	call	MTConnectTextAttributes		;ax <- VM handle of name array
	clr	di				;clear CTRF_searchText flag
	call	MNSetNameArray
	;
	; Get the text and stuff it in the text object
	;
afterOpen:
	clr	ax				;clear CTRF_searchText flag
	call	LoadOrFreeCompressLib		;Load/free the compress lib,
	jc	errorNoCompress			; depending upon whether or
						; not it is needed. Exit if
						; we couldn't load it.	
	call	MTGetTextForContext
	jc	errorNoContext			;branch if error
done:
	.leave
EC <	call	AssertIsCGV				>	
	ret

errorNoCompress:
	;
	; We couldn't load the compress/decompress library
	;
	mov	di, offset noCompressLibrary
	jmp	reportError

errorNoContext:
	;
	; The file was found, but the context wasn't -- report an error
	;
	mov	di, offset contextNotFound	;di <- chunk of error message
reportError:
	call	MUReportError
	;
	; Free text storage, close old file, save new file handle for later
	;
	clr	cx, bx
	call	MFSetFileCloseOld
	stc
	jmp	done

MLDisplayText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the box is brought off-screen, we free the compress
		library, on the assumption that the user won't be changing
		contexts for awhile.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewVisClose		method	dynamic ContentGenViewClass,
				MSG_VIS_CLOSE
		clr	bx
		xchg	bx, ds:[di].CGVI_compressLib
		tst	bx
		jz	exit
		call	GeodeFreeLibrary
exit:
		mov	di, offset ContentGenViewClass
		GOTO	ObjCallSuperNoLock
ContentGenViewVisClose		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVDisplayText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle request to display a particular context.

CALLED BY:	MSG_CGV_DISPLAY_TEXT
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		ss:bp	= ContentTextRequest params
		 CTR_flags
		    CTRF_restoreFromState
			= 1 if restoring from state, so don't need to
			  do anything with tools, features or history list.
			= 0 if not restoring from state, so do need to
			  do all that stuff.
		    CTRF_needContext
			= 1 if NavControl needs to know context name
			  when this routine sends out notification so
			  that NavControl can update its history list
			= 0 if NavControl already knows the context and
			  only needs to know the status of prev/next
		    CTRF_searchMatch
			= 1 if this message was sent after a match was
			  found, and we don't want to abort the current search.
			= 0 if not displaying a search match, rather user has
			  navigated to a new page, so do abort active search.
			  
RETURN:		carry set if error
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVDisplayText	method dynamic ContentGenViewClass, 
					MSG_CGV_DISPLAY_TEXT
	.enter

	;
	; Before displaying passed page, check if it is already open
	;
	call	CompareContexts
	je 	update
	call	MLDisplayText
	jc	openError
	clr	dx
	call	UpdateStateDataWithLocals
		
update:
	;
	; Update the nav controller's prev/next triggers, page,
	; and history list if necessary.  Also update our own 
	; CONTENT_BOOK_FEATURES vardata if we are displaying 
	; a new content file.
	;
	segmov	es, ss, ax
	lea	di, ss:[bp].CTR_context		
	call	MNGetPrevNextStatusGivenName		;ax<-status, cx<-page

	mov	dx, ss:[bp].CTR_flags
	test	dx, mask CTRF_needContext		
	jz	checkForRestore
	or	ax, mask NNCCF_updateHistory		; Do update history.

checkForRestore:
	test	dx, mask CTRF_restoreFromState
	jz	noRestore
	and	ax, not (mask NNCCF_updateHistory)	;don't update history
	or	ax, mask NNCCF_retnWithState		; if restoring fr state

noRestore:
	call	MUSetPage
	call	MLSetFlagsForSpecialContext
	call	ContentSendNotification
	clc						; carry clr <- no error
done:
	.leave
	ret

openError:
	BitSet	ss:[bp].CTR_flags, CTRF_needContext ;do update nav history list
	call	MLRedisplayCurrentPage
	stc
	jmp	done
CGVDisplayText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareContexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if passed context is already being displayed

CALLED BY:	CGVDisplayText
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
RETURN:		Z - set if current and requested context are
			the same,
		    clear if need to load passed context
		
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 7/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareContexts		proc	near
	;
	; If restoring form state, we always want to display the context
	;
		test	ss:[bp].CTR_flags, mask CTRF_restoreFromState
		jnz	done
		call	SameFile?			;same file?
		jne	done
	;
	; Get the context name stored in vardata.
	;
		mov	ax, CONTENT_LINK
		call	ObjVarFindData			; ds:bx <- filename
		jnc	fail
	;
	; See if it's the same filename
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_context		;es:di <- ptr to name
		push	si
		mov	si, bx				;ds:si <- name
		clr	cx				;cx <- NULL-terminated
		call	LocalCmpStrings			;set Z flag if equal
		pop	si
		
done:
		ret
fail:
		mov	ax, 1
		or	ax, ax				;clears Z flag
		jmp	done
CompareContexts		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewGotoPageForNav
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to a page, as directed by the nav
		controller.  The page is either specified
		by number or relative to the current page.
		Note: Prev and next only work within a
		      single file, i.e., for a single name
		      array.

CALLED BY:	MSG_CGV_GOTO_PAGE_FOR_NAV
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		cx 	= CNCGPT_PREVIOUS_PAGE,
		   	  CNCGPT_NEXT_PAGE, or
		   	  CNCGPT_SPECIFIC_PAGE
	     	dx  	= specific page to 
		   	  go to if cx is
		   	  CNCGPT_SPECIFIC_PAGE

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Figure out the name array element corresponding
	to the currently displayed context.
	Then, using cx and data in the name array element
	just found, figure out the filename/context of the 
	text that is to be displayed.
	Call MSG_CGV_DISPLAY_TEXT.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewGotoPageForNav	method dynamic ContentGenViewClass, 
					MSG_CGV_GOTO_PAGE_FOR_NAV

cgvOptr	local	optr	push ds:[LMBH_handle], si
		.enter
		
		cmp	cx, CNCGPT_SPECIFIC_PAGE
		LONG	je	gotoSpecificPage
	;
	; Need to figure out the token of the context we're
	; at right now by matching the context and filename stored
	; in state data to their name array element.  Although
	; it would be sufficient to match just the context since
	; contexts are unique within a name array (GeoWrite help
	; editor as of 5/27/94), we'll match the filename too
	; to allow for multiple occurences of a context, a 
	; future feature.  Also, matching the filename only
	; requires checking that the file token is -1, i.e.,
	; "same file," since the the context we're at is in
	; the currently displayed file.
	;
		mov	ax, CONTENT_LINK
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		mov_tr	di, bx
		segmov	es, ds, ax			;es:di<-context
	;
	; Now figure out whether we're going forward or backward.
	;
		push	cx
		clr	ax				;clr CTRF_searchText
		call	MNLockNameArray			;*ds:si <- name array
		call	MLGetContextElementNumber	;ax<-context elt #
EC <		ERROR_NC CONTEXT_NAME_ELEMENT_NOT_FOUND 		>
		call	ChunkArrayElementToPtr		;ds:di <- name elt
EC <		ERROR_C ILLEGAL_CONTEXT_ELEMENT_NUMBER			>
		pop	cx
		
		mov	ax, ds:[di].PNAE_nextPage
		cmp	cx, CNCGPT_NEXT_PAGE
		je	sendDisplayRequest
		mov	ax, ds:[di].PNAE_prevPage
EC <		cmp	cx, CNCGPT_PREVIOUS_PAGE			>
EC <		ERROR_NE JM_SEE_BACKTRACE				>

sendDisplayRequest:
		cmp	ax, -1				; See if we're at the
							; first or last page.
		je	doneAbort			; Yes, so don't change
							; context.
		movdw	cxdx, ss:cgvOptr
		push	bp
		sub	sp, (size ContentTextRequest)
		mov	bp, sp
		call	MLLoadContentTextRequest
		mov	ss:[bp].CTR_flags, mask CTRF_needContext
							;Tell nav the new
							;context.
		call	MNUnlockNameArray

		movdw	bxsi, cxdx
		call	MemDerefDS		
		mov	ax, MSG_CGV_DISPLAY_TEXT
		call	ObjCallInstanceNoLock
		add	sp, (size ContentTextRequest)
		pop	bp

done:
		.leave
		ret

gotoSpecificPage:
		clr	ax				;clr CTRF_searchText
		call	MNLockNameArray
		call	MLGetTokenForPage		;ax <- number of name
							;array elt with dx in 
							;its PNAE_pageNumber
		jc	sendDisplayRequest
doneAbort:		
		call	MNUnlockNameArray
		jmp	done
		
ContentGenViewGotoPageForNav	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetContextElementNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for getting a pointer to
		a name array elt for a context.  The 
		context is in the current file.

CALLED BY:	MLGetContextElementNumber, 
		MNGetPrevNextStatusGivenName
PASS:		*ds:si	- name array
		es:di	- string = context
RETURN:		carry set if context found
			ax - element number of context
		carry clear if context not found
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetContextElementNumber	proc	far
	uses	bx, cx, dx
	.enter

	call	LocalStringSize			;cx = string length

	mov	dx, di				;es:dx = name
	mov	bx, cs
	mov	di, offset MLFindContextCallback ; bx:di - FindNameCallBack
	call	ChunkArrayEnum			; find it

	.leave
	ret
MLGetContextElementNumber	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MLFindContextCallback

DESCRIPTION:	Callback routine for MLGetTokenForContext

CALLED BY:	ChunkArrayEnum

PASS:  *ds:si - array
	ds:di - array element being processed
	ax - size of element
	es:dx - name to search for
	cx - length of name

RETURN: carry set if match found:
		ax - context's name array element number
	carry clear if context not found

DESTROYED: ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/16/91		Initial version

------------------------------------------------------------------------------@
MLFindContextCallback	proc	far
	uses	cx
	.enter

	; Check to see if the length of the strings are the same

	sub	ax, (size NameArrayElement) ; ax - length of element's name
	mov	bx, ds:[si]
	mov	bx, ds:[bx].NAH_dataSize
	sub	ax, bx			;ax = name length

	cmp	ax, cx			; length is the same?
	clc
	jnz	done			; jmp to end if not
	;
	; Check if we're at a context.
	;
	cmp	ds:[di].VTNAE_data.VTND_type, VTNT_CONTEXT
	clc
	jne	done
	;
	; Check if the context is is this file.
	;
	cmp	ds:[di].VTNAE_data.VTND_file, -1
	clc
	jne	done

	call	ChunkArrayPtrToElement	;ax <- element number

	; Now compare the strings themselves

	lea	si, ds:[di][bx].NAE_data ; ds:si = name
	mov	di, dx			; es:di = name to search for
	repe 	cmpsb			; cmp strings
	clc				; assume not the same
	jnz	done			; jmp if not equal

	stc
done:
	.leave
	ret
MLFindContextCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLLoadContentTextRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the context and filename of the passed name array
		element into the passed ContentTextRequest buffer.

CALLED BY:	ContentGenViewGotoPageForNav
PASS:		*ds:si	- name array
		ax	- token of context we're loading
		^lcx:dx	- ContentGenView instance
		ss:bp	- ContentTextRequest params

RETURN:		ss:bp	- filled
DESTROYED:	ax,bx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLLoadContentTextRequest	proc	near
		uses	cx,dx,ds
		.enter
	;
	; Copy context into CTR
	;
		segmov	es, ss, bx
		lea	di, ss:[bp].CTR_context		;es:di = dest.
		call	MNGetName			;es:di<-context
	;
	; Get the current file's filename.  This must be the
	; one we want since going to pages by number can only
	; occur within a single file.  Hyperlinks, on the other
	; hand, can span across files.
	;
		movdw	bxsi, cxdx
		call	MemDerefDS			;*ds:si=ContentGenView
EC <		call	AssertIsCGV				>	
		mov	ax, CONTENT_FILENAME
		lea	di, ss:[bp].CTR_filename	;es:di = dest.
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>

		.leave
		ret
MLLoadContentTextRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetTokenForPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the name array element whose page number
		is dx.

CALLED BY:	ContentGenViewGotoPageForNav
PASS:		*ds:si	= name array
		    dx	= page to find
RETURN:		carry set - dx was ok
		   ax	= number of name array 
			  element with page dx
		carry clear - page was out of
		     bounds
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetTokenForPage	proc	near
	uses	bx, di
	.enter

	mov	bx, cs
	mov	di, offset MLGetTokenForPageCallback
	call	ChunkArrayEnum
	jnc	done
	mov_tr	di, ax
	call	ChunkArrayPtrToElement		;ax<- elt. number
	stc

done:
	.leave
	ret
MLGetTokenForPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetTokenForPageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds name array element with pageNumber
		equal to dx.

CALLED BY:	MLGetPointerForPage
PASS:		*ds:si	= name array
		ds:di	= current element
		dx	= page number to find

RETURN:		carry set - match found
			    ds:ax is element
		carry clear - no match found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetTokenForPageCallback	proc	far

	cmp	ds:[di].PNAE_pageNumber, dx
	je	foundPage

	clc				; No match yet.
	ret

foundPage:
	mov	ax, di
	stc
	ret
MLGetTokenForPageCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSetFlagsForSpecialContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the context we're going to is a TOC
		or the main page for the book.  Adjusts ax
		appropriately.

CALLED BY:	
PASS:		*ds:si	- ContentGenView instance
		ax	- NotifyNavContextChangeFlags record
			  with some/none fields already set
		ss:bp	- ContentTextRequest
			CTR_filename - file we're going to
			CTR_context - page we're going to in that file

RETURN:		ax	- NNCCF_displayMain set if we're going
			  to Book's main page (not it's cover page, but
			  the first page of the book)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSetFlagsForSpecialContext	proc	near
		uses	bx,cx,si,di,ds
		.enter inherit
	;
	; Are we going to the main file?
	;
		push	ax
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_filename	;es:di <- filename
		mov	ax, CONTENT_MAIN_FILE
		call	ObjVarFindData
		pop	ax
		jnc	done				;No main file
		mov	si, bx				;ds:si<- main file name
		clr	cx				;null terminated strings
		call	LocalCmpStrings
		jnz	done				;filenames don't match
	;
	; Are we going to the main file's TOC?
	;
		push	ax
		mov	bx, handle ContentStrings
		call	MemLock
		mov	ds, ax
		mov	si, offset tocString	
		mov	si, ds:[si]			;ds:si <- ptr to "TOC"
		lea	di, ss:[bp].CTR_context		;es:di <- ptr to page
				; cx=0 from above
		call	LocalCmpStrings
		call	MemUnlock		; flags preserved
		pop	ax
		jnz	done				;contexts don't match
		or	ax, mask NNCCF_displayMain
done:
		.leave
		ret
MLSetFlagsForSpecialContext	endp


BookFileCode	ends


ContentLibraryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadOrFreeCompressLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads/frees the compress library, depending upon whether or
		not it is necessary.

CALLED BY:	GLOBAL
PASS:		*ds:si - ContentGenView
		ax - CTRF_searchText set if should use search text object
RETURN:		carry set if we couldn't load the compress library
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEC <compressLibName		char	"PKware Compression Library",0 >
EC <compressLibName		char	"EC PKware Compression Library",0 >

LoadOrFreeCompressLib	proc	far	uses	ax, bx, es, di
	class	ContentGenViewClass
	.enter
EC <	call	AssertIsCGV				>	

	mov	cx, ax
	call	MFGetFile
EC <	tst	bx							>
EC <	ERROR_Z	-1							>

;	Get the compress type for the currently displayed file, and ensure
;	that the compress library is loaded/freed appropriately.

	call	DBLockMap
	mov	di, es:[di]
	mov	al, es:[di].CFMB_compressType
	call	DBUnlock

	call	getCompressLib			; bx <- compress Lib or 0
		
	cmp	al, HCT_NONE
	je	freeLib
EC <	cmp	al, HCT_PKZIP						>
EC <	ERROR_NZ	BAD_CONTENT_COMPACT_TYPE			>

	tst_clc	bx
	jnz	exit

;	Load up the compress library

	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	push	ds, si, cx
	segmov	ds, cs
	mov	si, offset compressLibName
	mov	ax, COMPRESS_PROTO_MAJOR
	mov	bx, COMPRESS_PROTO_MINOR
	call	GeodeUseLibrary
	pop	ds, si, cx
	call	FilePopDir
	jc	exit
	call	saveCompressLib
	clc
exit:
	.leave
EC <	call	AssertIsCGV				>	
	ret
freeLib:

;	Free up the library if one was loaded

		clr	bx				; store NULL
		call	saveCompressLib			; ax <- old library
		tst_clc	ax
		jz	exit
		mov	bx, ax
		call	GeodeFreeLibrary
		clc
		jmp	exit

getCompressLib:
		test	cx, mask CTRF_searchText
		jnz	10$
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	bx, ds:[di].CGVI_compressLib	
		retn
10$:
		call	MSGetSearchData
		mov	bx, ds:[bx].CSD_compressLib
		retn

saveCompressLib:
		mov	ax, bx
		test	cx, mask CTRF_searchText
		jnz	20$
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		xchg	ax, ds:[di].CGVI_compressLib
		retn
20$:
		call	MSGetSearchData
		xchg	ax, ds:[bx].CSD_compressLib
		retn

LoadOrFreeCompressLib	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppMarkBusy, AppMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the app object to mark itself busy or not busy

CALLED BY:	UTILITY
PASS:		ds - segment of an object block
RETURN:		ds - fixed-up
DESTROYED:	ax, es, di 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppMarkBusy		proc	far
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	callApp
		ret
AppMarkBusy		endp

AppMarkNotBusy		proc	far
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		FALL_THRU	callApp
AppMarkNotBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		callApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the application object

CALLED BY:	AppMarkBusy, AppMarkNotBusy
PASS:		ax - message
		ds - pointing to object block
RETURN:		ds - possibly fixed up
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
callApp		proc	far
		uses	bx, cx, dx, si, bp
		.enter

		clr	bx
		call	GeodeGetAppObject
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret	
callApp		endp

ContentLibraryCode	ends
