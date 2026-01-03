COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainStartEnd.asm

AUTHOR:		Jonathan Magasin, Apr  8, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 8/94   	Initial revision


DESCRIPTION:

	$Id: mainStartEnd.asm,v 1.1 97/04/04 17:49:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	viewSizeChangedDup	byte	BB_FALSE
idata	ends


BookFileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up:  disassemble ContentGenView tree,
			   get rid of vardata
		Call superclass.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		cx 	- caller's ID
		dx:bp 	- callers' OD:  OD which will be sent a MSG_META_ACK

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Note:  Since this ContentGenView is a leaf object,
	       I didn't worry about the ACK.  (Tag MSG_META_
	       DETACH.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewDetach		method dynamic ContentGenViewClass,
					MSG_META_DETACH
	uses	ax, cx, dx, bp, si, es
	.enter
	;
	; Remove ourselves from GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	mov	bx, ds:[LMBH_handle]
	call	MUAddOrRemoveGCNList

	mov	ax, MSG_ABORT_ACTIVE_SEARCH
	call	ObjCallInstanceNoLock

		
	;
	; Destroy the text's run arrays and close the file.
	;
	clr	bx, cx
	call	MFSetFileCloseOld
EC <	ERROR_C		JM_PROBLEM_WITH_CLOSING_FILE	>
	;
	; Now set the gen view's content to null.
	;
	clr	cx, dx				; means null
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call 	ObjCallInstanceNoLock
	;
	; Get and clear the file selector's handle
	;
	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	clr	bx
	xchg	bx, ds:[di].CGVI_fileSelector
	push	bx
	;
	; Now remove and destroy the content block
	;
	mov	bx, ds:[di].GVI_content.handle
	mov	si, offset ContentDocTemplate
	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; Destroy the file selector.
	;
	pop	bx
	mov	si, offset BookFileDialog	
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	;
	; Call the superclass.
	;
	mov	di, offset ContentGenViewClass
	call	ObjCallSuperNoLock
	ret

ContentGenViewDetach		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the attaching of the content library template.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		cx - AppAttachFlags
		dx - handle of AppLaunchBlock (0 if none)
		bp - handle of extra state block (0 if none)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewAttach	method dynamic ContentGenViewClass, 
					MSG_META_ATTACH
	;
	; Call the superclass.
	;
	push	cx,dx,bp
	mov	di, offset ContentGenViewClass
	call	ObjCallSuperNoLock
	;
	; Add ourselves to the GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	; list so we can get MSG_ABORT_ACTIVE_SEARCH.
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	mov	bx, ds:[LMBH_handle]
	call	MUAddOrRemoveGCNList
	;
	; Set our block's output to ourselves...makes it easier for
	; search ContenText to communicate with ContentGenView
	;
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	cx, ds:[LMBH_handle]
	mov	dx, si			; ^lcx:dx = view
	call	ObjCallInstanceNoLock
	pop	cx,dx,bp
	;
	; Create the content tree and attach it to the view.
	;
	mov	ax, MSG_CGV_CREATE_TREE	
	call	ObjCallInstanceNoLock
	;
	; Create a file selector branch.
	;
	mov	ax, MSG_CGV_CREATE_FILE_SELECTOR
	call	ObjCallInstanceNoLock
	;
	; Do we have state because user exited
	; to DOS from the viewer application?
	;
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	restoreFromState
	test	cx, mask AAF_STATE_FILE_PASSED
	jnz	restoreFromState
	;
	; Did user double-click on a book file, 
	; or just start the viewer?
	;
	test	cx, mask AAF_DATA_FILE_PASSED
	jz	queryUserForFile			; User double-clicked.
	;
	; Copy book name, path and disk to ContentTextRequest, then
	; load the book.
	;
	call	LoadBookFromALB			; carry set if error
	jnc	done
		
queryUserForFile:
	;
	; Have the NavControl's file selector query
	; the user for a book.
	;
	mov	ax, MSG_CGV_INIT_FILE_SELECTOR
	call	ObjCallInstanceNoLock
	jmp	exit

restoreFromState:
	call	LoadBookFromState		; carry set if error
	jc	queryUserForFile		; no success, ask user to
						; select a book to open
done:
		
exit:		
	ret
ContentGenViewAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBookFromALB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get Book info out of AppLaunchBlock, then load the book.

CALLED BY:	ContentGenViewAttach
PASS:		*ds:si - ContentGenView
		^hdx - handle of AppLaunchBlock
RETURN:		carry set if no book specified or error loading book
DESTROYED:	ax,bx,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Reports error with loading the book.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBookFromALB		proc	near
		uses	bp
		.enter

		sub	sp, size ContentTextRequest
		mov	bp, sp
	;
	; Get the book name
	;
		mov	bx, dx
		call	MemLock
		mov	es, ax
		mov	di, offset ALB_dataFile ;es:di <- Book name
		call	LocalStringSize		;cx <- size of string w/o NULL
		jcxz	unlockMemAndReturnError
		inc	cx			;cx <- size w/NULL
	;
	; Copy the book name
	;
		push	ds, si
		segmov	ds, es, ax
		mov	si, di			;ds:si <- book name from ALB
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_bookname
		rep	movsb			;copy book name to CTR
	;
	; Copy the path name and disk handle
	;
		lea	di, ss:[bp].CTR_pathname
		mov	si, offset ALB_path	
		LocalCopyString

		mov	ax, ds:[ALB_diskHandle]	
		mov	ss:[bp].CTR_diskhandle, ax

		call	MemUnlock
	;
	; Now load the book
	;
		mov	ss:[bp].CTR_flags, mask CTRF_needContext
		pop	ds, si
		mov	ax, MSG_CGV_LOAD_BOOK_LOW
		call	ObjCallInstanceNoLock
		jnc	done
	;
	; Report the error
	;	
		cmp	ax, LFE_NO_ERROR
		je	returnError
		call	ReportLoadFileError

returnError:
		stc				; carry set <- error
done:
		lahf	
		add	sp, size ContentTextRequest
		sahf
		.leave
		ret

unlockMemAndReturnError:
		call	MemUnlock
		jmp	returnError

LoadBookFromALB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBookFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get Book info from vardata, then load the book.

CALLED BY:	ContentGenViewAttach
PASS:		*ds:si - ContentGenView
RETURN:		carry set if error opening book
DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Reports error with loading the book.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBookFromState		proc	near
		uses	bp
		.enter

		sub	sp, size ContentTextRequest
		mov	bp, sp
	;
	; Get the book name
	;
		segmov	es, ss, ax
		mov	ax, CONTENT_BOOKNAME
		lea	di, ss:[bp].CTR_bookname	; es:di <- dest
		call	ContentGetStringVardata
		cmc
		jc	done
	;
	; Send a notification so the controllers can update their
	; tools and features correctly.
	;
		mov	ss:[bp].CTR_flags, mask CTRF_restoreFromState
		call	ContentSendBookNotification
	;
	; Get the file name
	;
		segmov	es, ss, ax				
		mov	ax, CONTENT_FILENAME
		lea	di, ss:[bp].CTR_filename	; es:di <- dest
		call	ContentGetStringVardata
		jnc	loadBook
	;
	; Get the context name
	;
		mov	ax, CONTENT_LINK
		lea	di, ss:[bp].CTR_context		; es:di <- dest
		call	ContentGetStringVardata
		jnc	loadBook
	;
	; We don't need to get the path and disk for the content files,
	; as that is still set in vardata, and CGVDisplayText will look
	; for it there.
	;
	; Now display the text
	;
		mov	ax, MSG_CGV_DISPLAY_TEXT
		call	ObjCallInstanceNoLock		;carry set if error
		jnc	done
	;
	; MSG_CGV_DISPLAY_TEXT reports the error itself, so
	; we won't report it again
	;

returnError:
		stc				; carry set <- error
done:
		lahf
		add	sp, size ContentTextRequest
		sahf
		.leave
		ret

loadBook:
	; we weren't successful in getting a file and context name,
	; so load the book as if it had just been opened

	;
	; Copy the path name and disk handle for the BOOK
	;
		clr	ax
		lea	di, ss:[bp].CTR_pathname
		stosw
		mov	ss:[bp].CTR_diskhandle, SP_DOCUMENT

		mov	ax, MSG_CGV_LOAD_BOOK_LOW
		call	ObjCallInstanceNoLock		;carry set if error
		jnc	done
	;
	; Report the error 
	;	
		cmp	ax, LFE_NO_ERROR
		je	returnError
		call	ReportLoadFileError
		jmp	returnError
		
LoadBookFromState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGenViewCreateTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and attach a content tree to 
		the ContentGenView instance.

CALLED BY:	MSG_CGV_CREATE_TREE
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use template in content library's UI file.
		Attach duplicate to the view as view's content.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGenViewCreateTree	method dynamic ContentGenViewClass, 
					MSG_CGV_CREATE_TREE
	uses	cx, dx, bp
	.enter

	;
	; Set initial ignore count to 1, because the content receives
	; MSG_META_CONTENT_VIEW_SIZE_CHANGED when the GenView opens,
	; right before we load the first page and send
	; MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS. We'll ignore the first 
	; call to this message (sent from CDMetaContentViewSizeChanged) 
	; and handle the second call after loading the page.
	;
	mov	ax, MSG_CGV_IGNORE_UPDATE_SCROLLBARS
	call	ObjCallInstanceNoLock
	;
	; Create a content tree from the template
	; in the content library's UI file.
	;
	mov	bx, handle ContentTemplate
	clr	ax
	mov	cx, -1
	call	ObjDuplicateResource		; ^hbx <- duplicate block
	;
	; Now attach the duplicate to the view.
	;
	mov	cx, bx
	mov	dx, offset ContentDocTemplate 	; ^lcx:dx = content
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call 	ObjCallInstanceNoLock	
	;
	; Now set the output of this new block 
	; to be the ContentGenView.
	;
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; ^lcx:dx = view
	mov	si, offset ContentDocTemplate
	clr	di
	call	ObjMessage
	;
	; Give target to text. If it doesn't have target and you have
	; scrolled down a bit, when you click on a hotspot or hyperlink,
	; the text object gains the target and makes the origin visible,
	; causing the view to scroll back up to the top of the text.
	;
	mov	si, offset ContentTextTemplate
	mov	ax, MSG_META_GRAB_TARGET_EXCL	; grab target for text
	clr	di
	call	ObjMessage
	;
	; Give focus to text. If it doesn't have the focus, it won't
	; get kbd chars, the arrow keys won't work.  Clicking on the
	; text gives it the focus, but it doesn't initially have the 
	; target...
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL	; grab focus for text
	clr	di
	call	ObjMessage
if 0		
	;
	; I commented out the following code to get rid of the warning
	; about calling MemLock on an object block. To force the lines
	; to be built out, I had to clear the VOF_GEOMETR_INVALID
	; flag from the ContentTextTemplate. When the text object
	; is initialized, if that flag is not set and there are
	; no lines yet, VisTextNotifyGeometryValid is called, and the
	; lines are created. -- cassie 6/3/96
	;
	;
	; Gross hack begins here, just to see if it will work until
	; a better sol'n comes along.  Manually clear the geometry
	; invalid bit, and then call NOTIFY_GEOMETRY_VALID, which
	; creates the VTI_lines chunk array.
	;
	push	bp
	call	MemLock
	mov	ds, ax
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].VI_optFlags, (not (mask VOF_GEOMETRY_INVALID))
	call	ObjMarkDirty
	call	MemUnlock
		
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	clr	di
	call	ObjMessage
	pop	bp
endif
	.leave
	ret
ContentGenViewCreateTree	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVCreateFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a file selector for the view by copying
		BookFileSelectorTemplate.

CALLED BY:	MSG_CGV_CREATE_FILE_SELECTOR
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVCreateFileSelector	method dynamic ContentGenViewClass, 
					MSG_CGV_CREATE_FILE_SELECTOR
	uses	cx, dx, bp
	.enter
	;
	; Copy the template.
	;
	mov	bx, handle BookFileSelectorTemplate
	clr	ax
	mov	cx, -1
	call	ObjDuplicateResource	; bx <- handle of
					;       duplicate block
	;
	; Now set the output of this new block 
	; to be the ContentGenView.
	;
	push	si
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	cx, ds:[LMBH_handle]
	mov	dx, si			; ^lcx:dx = view
	mov	si, offset BookFileDialog
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	;
	; Make view remember its file selector.
	;
	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	mov	ds:[di].CGVI_fileSelector, bx
	;
	; Make file selector interaction a child of the view's
	; parent (the primary) so that it can appear when it 
	; gets initiated.  Then set the file selector interaction
	; usable.
	;
	mov	dx, offset BookFileDialog	;^lbx:dx=selector
	call	addChild

	.leave
	ret

addChild:
	push	si
	push	dx	
	mov	cx, bx				;^lcx:dx <- child
	mov	ax, MSG_GEN_ADD_CHILD
	clr	bp
	call	GenCallParent
	pop	si				;^lbx:si <- child

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	retn
CGVCreateFileSelector	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This next section has routines belonging to the ContentDoc.  Will
pull this code out and put it in its own .asm file later.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDMetaContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make ContentDoc and ContentText sizes same 
		as ContentGenView size.

CALLED BY:	MSG_META_CONTENT_VIEW_SIZE_CHANGED
PASS:		*ds:si	= ContentDocClass object
		ds:di	= ContentDocClass instance data
		ds:bx	= ContentDocClass object (same as *ds:si)
		es 	= segment of ContentDocClass
		ax	= message #
		bp - handle of pane window
		cx - new window width, in document coords (you will have to
		     call WinGetWinScreenBounds to get the true size of the 
		     window area in screen coordinates, for doing things like
		     scale to fit.)
		dx - new window height, in document coords

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDMetaContentViewSizeChanged	method dynamic ContentDocClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED
	;
	; First call the superclass.
	;
		mov	di, offset ContentDocClass
		call	ObjCallSuperNoLock
	;
	; If there are duplicate messages on the queue, increment the
	; ignore count, so that MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS will
	; not try to update the scrollbars this time around.
	;
		call	CheckForViewSizeChangedMessages
	;
	; Tell text to tell view to update scrollbars.
	;
		mov	ax, MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
		mov	bx, ds:[LMBH_handle]
		mov	si, offset ContentTextTemplate
		GOTO	ObjCallInstanceNoLock
CDMetaContentViewSizeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForViewSizeChangedMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether a hyperlink is already being followed,
		by checking for certain messages on the queue.

CALLED BY:	CDMetaContentViewSizeChanged
PASS:		*ds:si - ContentGenView object
RETURN:		nothing
DESTROYED:	ax, bx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForViewSizeChangedMessages		proc	near
		.enter

		mov	ax, cs
		push	ax
		mov	ax, offset CheckViewSizeChangeCallback
		push	ax
		mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
		mov	di, mask MF_CUSTOM or mask MF_CHECK_DUPLICATE or \
			mask MF_DISCARD_IF_NO_MATCH or mask MF_FORCE_QUEUE
		mov	bx, ds:[LMBH_handle]
		call	ObjMessage

NOFXIP	<	segmov	es, dgroup, ax					>
FXIP	<	mov	bx, handle dgroup				>
FXIP 	<	call	MemDerefES					>

	;
	; Are there duplicates on the queue?
	;
		cmp	es:viewSizeChangedDup, BB_TRUE	
		jne	done
		
		mov	es:viewSizeChangedDup, BB_FALSE	; reset flag
	;
	; inc the ignore count so that this view size change is ignored
	;	
		;mov	ax, MSG_CGV_IGNORE_UPDATE_SCROLLBARS
		;call	MUCallView
done:	
		.leave
		ret
CheckForViewSizeChangedMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckViewSizeChangeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether another 
		MSG_META_CONTENT_VIEW_SIZE_CHANGED message is 
		on the queue

CALLED BY:	CheckForViewSizeChangedMessages, via ObjMessage
PASS:		ds:bx	= HandleEvent of an event already on queue
		ds:si	= HandleEvent of new event
RETURN:		di = PROC_SE_EXIT, means that a match was found
		di = PROC_SE_CONTINUE, no match so continue looking
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckViewSizeChangeCallback		proc	far

		mov	ax, ds:[bx].HE_method	
		cmp	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
		je	found
		mov	di, PROC_SE_CONTINUE		; no match, continue
		ret
found:
		push	es
NOFXIP	<	segmov	es, dgroup, ax					>
FXIP 	<	mov	bx, handle dgroup				>
FXIP 	<	call	MemDerefES					>
		mov	es:viewSizeChangedDup, BB_TRUE
		mov	di, PROC_SE_EXIT		; we're done checking
		pop	es
		ret
CheckViewSizeChangeCallback		endp

BookFileCode	ends

