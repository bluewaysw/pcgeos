COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainUtils.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

ROUTINES:
	Name			Description
	----			-----------
	MUSetFileFlags		Record ContentFileMapBlockFlags in view's
				instance data.

	MFGetFileFlags		Retrieve ContentFileMapBlockFlags from
				view's instance data.

	MUSetPage		Sets the page of the ContentGenView

	MUGetPage		Gets the page of the ContentGenView

	MUObjMessageSend	Send a message to the ContentText object or
				the search text object

	CGVGetTextOD		MSG_CGV_GET_TEXT_OD
				Gets the ContenText optr.

	ContentGetText		Gets the content's ContentText or
				ContentSearchText.

	MUReportError		Report an error in a suitably annoying
				fashion

	MUPutUpDialog		Put up a dialog.

	MUQueryUser		Query user for direction.

	MUCallView		Calls up the visual tree to the CGView.

	MUGetFeaturesAndTools	Returns the features/tools record stored in
				the CGView's vardata.  If vardata not
				present, returns default features/tools.

	ContentAddStringVardata Adds some string vardata to the
				ContentGenView.

	ContentGetStringVardata Adds some string vardata to the
				ContentGenView.

	AssertIsCGV		Make sure we've got an instance of a
				ContentGenView.

	AssertIsCText		Make sure we've got an instance of a
				ContentTextClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Common routines used by the content library.
		

	$Id: mainUtils.asm,v 1.1 97/04/04 17:49:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUSetFileFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record ContentFileMapBlockFlags in view's
		instance data.

CALLED BY:	INTERNAL
PASS:		*ds:si	= ContentGenViewClass object
		ax	= CFMB_flags
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUSetFileFlags		proc near
		class	ContentGenViewClass
EC <	call	AssertIsCGV				>
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].ContentGenView_offset
		mov	ds:[si].CGVI_fileFlags, ax
		pop	si
		ret
MUSetFileFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFGetFileFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve ContentFileMapBlockFlags from view's
		instance data.

CALLED BY:	UTILITY
PASS:		*ds:si	= ContentGenViewClass object
RETURN:		cx	= CFMB_flags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MFGetFileFlags	proc	near
		class	ContentGenViewClass
EC <	call	AssertIsCGV				>
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].ContentGenView_offset		
		mov	cx, ds:[si].CGVI_fileFlags
		pop	si
		ret
MFGetFileFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUSetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the page of the ContentGenView

CALLED BY:	UTILITY
PASS:		*ds:si	- ContentGenView instance
		cx	- new page
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUSetPage	proc	near
	uses	di
	class	ContentGenViewClass
	.enter
EC <	call	AssertIsCGV			>

	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	mov	ds:[di].CGVI_page, cx
	
	.leave
	ret
MUSetPage	endp

BookFileCode	ends

;---

ContentLibraryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUObjMessageSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the ContentText object or the
		search text object

CALLED BY:	UTILITY
PASS:		*ds:si - ContentGenView
		ds - fixupable segment
		ax - message to send
		di - ContentTextRequestFlags
			CTRF_searchText is set if should send to that object
		values for message (cx, dx, bp)
RETURN:		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUObjMessageSend		proc	far
	uses	bx,cx,dx,bp,si,di
	.enter
EC <	call	AssertIsCGV				>
	;
	; First get the text.
	;
	call	ContentGetText
	;
	; Now send the message.
	;
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
MUObjMessageSend		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVMetaInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_INITIALIZE_VAR_DATA
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentGenViewClass
		ax - the message
		cx - vardata
RETURN:		ax - offset to extra data
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVMetaInitializeVarData		method dynamic ContentGenViewClass,
						MSG_META_INITIALIZE_VAR_DATA
		cmp	cx, TEMP_CONTENT_IGNORE_UPDATE_SCROLLBARS_COUNT
		jne	callSuper
		mov	ax, cx
		mov	cx, size byte
		call	ObjVarAddData
		mov	{byte}ds:[bx], 0
		mov	ax, bx
		ret
callSuper:
		mov	di, offset ContentGenViewClass
		GOTO	ObjCallSuperNoLock
CGVMetaInitializeVarData		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVGetTextOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text object optr.

CALLED BY:	MSG_CGV_GET_TEXT_OD
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		carry set if no text object
		^lcx:dx - the ContentText object
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVGetTextOD	method dynamic ContentGenViewClass, 
					MSG_CGV_GET_TEXT_OD
	clr	di
	call	ContentGetText		; ^lbx:si <- text object
	tst	bx			; also clears carry
	jz	noTextObject
	movdw	cxdx, bxsi
	jmp	done
noTextObject:
	stc				; carry <- no text object
done:	
	ret
CGVGetTextOD	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the content's ContentText.

CALLED BY:	Utility
PASS:		*ds:si - ContentGenView	
		di - ContentTextRequestFlags
		 	if CTRF_searchText is set, use CSD_searchObject
RETURN:		^lbx:si - the ContentText object
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGetText	proc	near
		class	ContentGenViewClass
		.enter
EC <		call	AssertIsCGV					>

		test	di, mask CTRF_searchText
		jnz	getSearchFile

		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	bx, ds:[di].GVI_content.handle
		mov	si, offset ContentTextTemplate
done:
		.leave
		ret
		
getSearchFile:
		push	ax
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC	-1					>
		mov	si, ds:[bx].CSD_searchObject.chunk
		mov	bx, ds:[bx].CSD_searchObject.handle
EC <		call	AssertIsCText					>
		pop	ax
		jmp	done
ContentGetText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report an error in a suitably annoying fashion

CALLED BY:	UTILITY - MLDisplayText
PASS:		ss:bp - ContentTextRequest
		di - chunk of custom string
		ax - custom flags
		*ds:si - ContentGenView
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	NOTE: argument 1 (if any) is replaced with the filename
	NOTE: argument 2 (if any) is replaced with the context name
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Multiple errors in the same file are not reported
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUReportError		proc	far
	uses	ax
	.enter
	mov	ax, 	(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or\
			mask CDBF_SYSTEM_MODAL
	call	MUPutUpDialog

	.leave
	ret
MUReportError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUPutUpDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a custom dialog.

CALLED BY:	UTILITY 
PASS:		ss:bp - ContentTextRequest
		di - chunk of custom string
		ax - custom flags
		*ds:si - ContentGenView
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	NOTE: argument 1 (if any) is replaced with the filename
	NOTE: argument 2 (if any) is replaced with the context name
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Multiple errors in the same file are not reported
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUPutUpDialog		proc	far
	uses	di, si, bx, cx
	class	ContentGenViewClass
	.enter
	push	ds:[LMBH_handle]		
	mov	si, di				;si <- chunk of error

	sub	sp, (size StandardDialogParams)
	mov	di, sp				;ss:di <- params
	mov	ss:[di].SDP_customFlags, ax

	mov	bx, handle ContentStrings
	call	MemLock
	mov	ds, ax

	lea	ax, ss:[bp].CTR_filename	;ss:ax <- filename
	movdw	ss:[di].SDP_stringArg1, ssax
	lea	ax, ss:[bp].CTR_context		;ss:ax <- context
	movdw	ss:[di].SDP_stringArg2, ssax
	mov	ax, ds:[si]			;ds:ax <- ptr to error message
	movdw	ss:[di].SDP_customString, dsax
	clr	ss:[di].SDP_helpContext.segment
	call	UserStandardDialog

	call	MemUnlock
	pop	bx
	call	MemDerefDS		
	.leave
EC <		call	AssertIsCGV			>
	ret
MUPutUpDialog		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUQueryUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query user for direction.

CALLED BY:	UTILITY - 
PASS:		di - chunk of error
		*ds:si - ContentGenView
		ss:ax - first string arg
		ss:dx - second string arg
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Multiple errors in the same file are not reported
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUQueryUser		proc	far
	uses	ds, di, si, bx, cx
	class	ContentGenViewClass
	.enter	

	mov	cx, ax
	mov	si, di				;si <- chunk of custom string
	mov	bx, handle ContentStrings
	call	MemLock
	mov	ds, ax				;*ds:si <- custom string

	sub	sp, (size StandardDialogParams)
	mov	di, sp				;ss:di <- params
	mov	ss:[di].SDP_customFlags,
			(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE) or\
			mask CDBF_SYSTEM_MODAL
	movdw	ss:[di].SDP_stringArg1, sscx
	movdw	ss:[di].SDP_stringArg2, ssdx
	mov	ax, ds:[si]			;ds:ax <- ptr to error message
	movdw	ss:[di].SDP_customString, dsax
	clr	ss:[di].SDP_helpContext.segment
	call	UserStandardDialog

	call	MemUnlock

	.leave
EC <		call	AssertIsCGV			>
	ret
MUQueryUser		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCallView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls up the visual tree to the CGView.

CALLED BY:	utility
PASS:		ax	- message
		*ds:si - ContentText
RETURN:		ax,cx,dx,bp can be set by view
		ds fixed up
DESTROYED:	nothing
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCallView	proc	far
		uses	bx, si, di, es
		.enter

		push	ax, cx, dx, bp
		mov	cx, segment ContentGenViewClass
		mov	dx, offset ContentGenViewClass
		mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
EC <		ERROR_NC -1						>
		movdw	bxsi, cxdx
		pop	ax, cx, dx, bp

		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
MUCallView	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCallView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls up the visual tree to the CGView.

CALLED BY:	utility
PASS:		ax	- message
		*ds:si 	- ContentText
		ss:bp  	- stack data
		cx 	- size of stack data
RETURN:		ax,cx,dx,bp can be set by view

DESTROYED:	nothing
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCallViewStack	proc	far
		uses	bx, si, di, es
		.enter

		push	ax, cx, bp
		mov	cx, segment ContentGenViewClass
		mov	dx, offset ContentGenViewClass
		mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
EC <		ERROR_NC -1						>
		movdw	bxsi, cxdx
		pop	ax, cx, bp

		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
MUCallViewStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUGetFeaturesAndTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the features/tools record stored in the
		CGView's vardata.  If vardata not present, returns
		default features/tools.

CALLED BY:	utility
PASS:		*ds:si	- ContentGenView instance
RETURN:		cx	- BookFeatures record for features
		dx	- BookFeatures record for tools
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUGetFeaturesAndTools	proc	far
	class	ContentGenViewClass
	uses	di
	.enter
EC <	call	AssertIsCGV			>

	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset	
	mov	cx, ds:[di].CGVI_bookFeatures	;Get specified features.
	mov	dx, ds:[di].CGVI_bookTools

	.leave
	ret
MUGetFeaturesAndTools	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUAddOrRemoveGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an object to or remove it from a gcn list.

CALLED BY:	UTILITY
PASS:		ax - MSG_META_GCN_LIST_ADD/REMOVE
		dx - list type
		^lbx:si - object to add to GCN list
RETURN:		nothing
DESTROYED:	ax, dx,

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUAddOrRemoveGCNList		proc	far
		uses bx, cx, bp, si
		.enter

		sub	sp, size GCNListParams
		mov	bp, sp
		movdw	ss:[bp].GCNLP_optr, bxsi
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS 
		mov	ss:[bp].GCNLP_ID.GCNLT_type, dx
		mov	dx, size GCNListParams
		call	UserCallApplication
		add	sp, size GCNListParams

		.leave
		ret
MUAddOrRemoveGCNList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentAddStringVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds some string vardata to the ContentGenView.

CALLED BY:	UTILITY
PASS:		*ds:si	- ContentGenView
		ax	- vardata name and 
			  storage flags
		bx:dx	- source string (null term.)

RETURN:		nothing
		 vardata added to ContentGenView
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentAddStringVardata	proc	far
		uses	bx,cx,si,di,es
		.enter
EC <		call	AssertIsCGV					>
	;
	; Get length of the source string.
	;
		movdw	esdi, bxdx
		call	LocalStringSize			; size w/o null
		inc	cx				; size w/ null
	;
	; Add it as our vardata
	;
		call	ObjVarAddData			;ds:bx <- dest
		mov	di, bx	
		segxchg	es, ds, ax			;es:di <- dest
		mov	si, dx				;ds:si <- source
		rep	movsb				; copy!
		segmov	ds, es, ax
		.leave
		ret
ContentAddStringVardata	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGetStringVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds some string vardata to the ContentGenView.

CALLED BY:	UTILITY
PASS:		*ds:si	- ContentGenView
		ax	- vardata type
		es:di   - buffer to copy data to

RETURN:		carry set if data found
			data copied to buffer
		carry clear if data not found
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGetStringVardata	proc	far
		uses	bx,cx,si
		.enter
EC <		call	AssertIsCGV				>

		call	ObjVarFindData			;ds:bx <- data
		jnc	done
	;
	; Get length of the source string.
	;
		mov	si, bx
		VarDataSizePtr	ds, si, cx
	;
	; Copy it to the passed buffer
	;
		rep	movsb				; copy!
		stc
done:		
		.leave
		ret
ContentGetStringVardata	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsCGV

DESCRIPTION:	Make sure we've got an instance of
		a ContentGenView.

CALLED BY:	INTERNAL

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
if	ERROR_CHECK

AssertIsCGV	proc	far	uses di, es
	.enter
	pushf

	mov	di, segment ContentGenViewClass
	mov	es, di
	mov	di, offset ContentGenViewClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_IS_NOT_A_CONTENT_GEN_VIEW

	popf
	.leave
	ret

AssertIsCGV	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsCText

DESCRIPTION:	Make sure we've got an instance of
		a ContentTextClass

CALLED BY:	INTERNAL

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/91		Initial version

------------------------------------------------------------------------------@
if	ERROR_CHECK

AssertIsCText	proc	far	uses di, es
	.enter
	pushf

	mov	di, segment ContentTextClass
	mov	es, di
	mov	di, offset ContentTextClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_IS_NOT_A_CONTENT_TEXT

	popf
	.leave
	ret

AssertIsCText	endp

endif

ContentLibraryCode	ends
