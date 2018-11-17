COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textMethodType.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	JM	3/18/94		Made NameToToken, FileNameToToken,
				and ContextFileNameToToken return
				zero flag so that caller must do
				error checking				

DESCRIPTION:
	This file contains method handlers for type methods

	$Id: taType.asm,v 1.1 97/04/07 11:18:55 newdeal Exp $

------------------------------------------------------------------------------@

TextNameType	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a hyperlink for the selected area

CALLED BY:	MSG_VIS_TEXT_SET_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - VisTextSetHyperlinkParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	gene	9/ 4/92		updated
	JM	9/18/94		added error checking for
				calls to NameToToken and
				ContextFileNameToToken
	jenny	8/15/94		Added range hunt and broke out common code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetHyperlink	proc	far	; MSG_VIS_TEXT_SET_HYPERLINK
					; MSG_META_TEXT_SET_HYPERLINK
	;
	; Get the range over which to operate.
	;
	call	FindRangeForHyperlink
	jc	done
	;
	; Now get the tokens/indices.
	;
	mov	dx, ss:[bp].VTSHLP_file
	mov	ax, ss:[bp].VTSHLP_context
	test	ss:[bp].VTSHLP_flags, mask VTCF_TOKEN
	jnz	gotTokens
	;
	; Are we clearing the hyperlink?
	;
	cmp	dx, GIGS_NONE
	je	clearingHyperlink
	;
	; Convert the list entries into tokens
	;
	call	FileAndContextNamesToTokens	; ax <- context token
						; dx <- file token
gotTokens:
	;
	; dx = file, ax = context
	;
	call	SetHyperlink
done:
	ret

clearingHyperlink:
	mov	ax, dx				;ax <- no context

CheckHack <GIGS_NONE eq -1 and \
	   VIS_TEXT_CURRENT_FILE_TOKEN eq -1 and \
	   VIS_TEXT_NIL_CONTEXT_TOKEN eq -1>

	jmp	gotTokens
VisTextSetHyperlink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRangeForHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the range over which to set or clear a hyperlink.

CALLED BY:	INTERNAL	VisTextSetHyperlink

PASS:		*ds:si	= instance data for text object
		ss:bp	= VisTextSetHyperlinkParams

RETURN:		carry	= set if no range
			OR
		carry	= clear if all well
		ss:bp = VisTextSetHyperlinkParams with range modified
		
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRangeForHyperlink	proc	near
		uses	ds, si
		.enter
	;
	; First convert virtual coords to physical and check whether
	; the start and end of the range differ. If so, all is well.
	; Note that the carry is clear if we take the jump.
	;
		clr	bx
		call	TA_GetTextRange		; virtual -> physical
		movdw	dxax, ss:[bp].VTSHLP_range.VTR_end
		cmpdw	dxax, ss:[bp].VTSHLP_range.VTR_start
		ja	done
	;
	; They're the same. We may be clearing a hyperlink after
	; just positioning the cursor on it rather than selecting it.
	; If not, we may want swat to put out a warning.
	; 
		test	ss:[bp].VTSHLP_flags, mask VTCF_TOKEN
		jnz	checkContext
		cmp	ss:[bp].VTSHLP_file, GIGS_NONE
		jne	warn
findRange:
	;
	; Yes, we're clearing a hyperlink. Figure out the range of the
	; hyperlink to be cleared and substitute that in the passed parameters.
	;
	CheckHack <(offset VTSHLP_range) eq 0>
		segmov	es, ss			; es:bp <- VTSHLP_range
		mov	bx, OFFSET_FOR_TYPE_RUNS
		call	TA_GetRunBounds
		clc
done:
		.leave
		ret
checkContext:
		cmp	ss:[bp].VTSHLP_context, VIS_TEXT_NIL_CONTEXT_TOKEN
		je	findRange
warn:
if ERROR_CHECK
	;
	; We're setting a new hyperlink but our range start and end
	; are equal. This is legitimate only if the text object got
	; the set hyperlink MetaTextMessage because it was automatically
	; forwarded here as well as being sent to its specified
	; destination. In that case, the start and end of the range
	; should be zero. No need to die if they're not, though.
	;
		tstdw	dxax
		WARNING_NZ WARNING_CANNOT_SET_HYPERLINK_ON_NIL_TEXT_RANGE
endif
		stc
		jmp	done


FindRangeForHyperlink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/clear and show/hide a hyperlink for the passed range.

CALLED BY:	INTERNAL	VisTextSetHyperlink

PASS:		*ds:si	= instance data for text object
		ss:bp	= VisTextSetHyperlinkParams
		ax	= context token
		dx	= file token
RETURN:		nothing
DESTROYED:	cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlink	proc	near
	;
	; Use our own undo chain so the setting and showing actions
	; are grouped together.
	;
		mov_tr	cx, ax		
		mov	ax, offset FormattingString
		call	TU_StartChainIfUndoable
		mov_tr	ax, cx
	;
	; Are hyperlinks currently being shown?
	;
		test	ss:[bp].VTSHLP_flags, mask VTCF_SHOWING_HYPERLINKS
		jz	setIt
	;
	; Yes, they are. If we're clearing a hyperlink, then we want
	; to stop showing it first.
	;
		cmp	ax, VIS_TEXT_NIL_CONTEXT_TOKEN
		pushf
		je	showIt
		call	SetHyperlinkLow
showIt:
		call	ShowHyperlink
	;
	; If we're clearing a hyperlink, we have to go clear it now
	; that we've removed its text style. Else, we're done.
	;
		popf
		jne	done
setIt:
		call	SetHyperlinkLow
done:
	;
	; Set-and-show-hyperlink undo chain finished.
	;
		call	TU_EndChainIfUndoable
		ret
SetHyperlink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlinkLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange for a callback to set a hyperlink on the passed range.

CALLED BY:	INTERNAL	SetHyperlink
PASS:		ss:bp	= VisTextRange
		dx	= file token
		ax	= context token
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlinkLow	proc	near
		mov	di, offset SetHyperlinkCallback
		call	TypeChangeCommon
		ret
SetHyperlinkLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets or clears the VTES_BOXED style on a range of text.

CALLED BY:	INTERNAL	VisTextSetHyperlink

PASS:		*ds:si	= instance data for text object
		ss:bp	= VisTextRange
		ax	= context token
RETURN:		nothing
DESTROYED:	cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowHyperlink	proc	near
		uses	ax, dx, bp
		.enter
	;
	; We want to set the passed range to appear either boxed and
	; unboxed. Start setting up the stack.
	;
		mov_tr	cx, ax			; cx <- context
		mov	bx, bp			; ss:bx <- VisTextRange
		sub	sp, (size VisTextSetTextStyleParams)
		mov	bp, sp			; ss:bp <- params
		movdw	axdi, ss:[bx].VTR_start
		movdw	ss:[bp].VTSTSP_range.VTR_start, axdi
		movdw	axdi, ss:[bx].VTR_end
		movdw	ss:[bp].VTSTSP_range.VTR_end, axdi
	;
	; Leave the TextStyle alone, whatever it may be. We're
	; interested in the extended style only.
	;
		clr	ax
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, ax
	;
	; Assume we're going to show the hyperlink; then check if
	; that's true. If the context token is VIS_TEXT_NIL_CONTEXT_TOKEN,
	; we've just cleared a hyperlink, so we'll be clearing its text style.
	;
		mov	ss:[bp].VTSTSP_extendedBitsToSet, mask VTES_BOXED 
		mov	ss:[bp].VTSTSP_extendedBitsToClear, ax
		cmp	cx, VIS_TEXT_NIL_CONTEXT_TOKEN
		jne	showHyperlinks
		mov	ss:[bp].VTSTSP_extendedBitsToSet, ax
		mov	ss:[bp].VTSTSP_extendedBitsToClear, mask VTES_BOXED
showHyperlinks:
	;
	; Now we set the style.
	;
		mov	ax, MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
		call	ObjCallInstanceNoLock
		add	sp, (size VisTextSetTextStyleParams)
		.leave
		ret
ShowHyperlink	endp

TextNameType	ends

TextAttributes	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetHyperlinkTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set or clear a style on all hyperlinks in a range of text.

CALLED BY:	MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #

		ss:bp 	= VisTextSetTextStyleParams
			  (with VisTextRange holding virtual bounds)
		
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHyperlinkTextStyleCallbackParams	struct
	SHTSCP_params		VisTextSetTextStyleParams
	SHTSCP_wholeRange	VisTextRange
SetHyperlinkTextStyleCallbackParams	ends

VisTextSetHyperlinkTextStyle	proc	far	; MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
	;
	; Convert the virtual coords passed on the stack to physical coords.
	;
		clr	bx			; clear VisTextRangeFlags
						;  - no special treatment needed
		call	TA_GetTextRange		; virtual -> physical
	;
	; Suspend recalculation till we're done.
	;
		call	TextSuspend
		push	ds:[LMBH_handle]	; save for later deref
	;
	; Set up the data for our callback.
	; First copy the VisTextSetTextStyleParams into a new stack
	; frame. The callback needs to know the original range but
	; will change VTSTSP_range every time it's called, so we'll
	; tack on an extra copy of the range after the params.
	;
		movdw	axdx, dssi		; save text object
		sub	sp, (size SetHyperlinkTextStyleCallbackParams)
		mov	cx, (size VisTextSetTextStyleParams)/2
		segmov	es, ss
		mov	di, sp			; es:di <- destination
		segmov	ds, ss
		mov	si, bp			; ds:si <- source
		rep	movsw
	;
	; Now add our extra copy of the range. Note that es:di is
	; currently pointing into the stack just past the newly copied
	; VisTextSetTextStyleParams.
	;
		mov	cx, (size VisTextRange)/2
		mov	si, bp			; ds:si <- VTSTSP_range
		rep	movsw
	;
	; Restore pointer to text object and set up arguments for
	; callback.
	;
		movdw	dssi, axdx		; restore text object
		mov	cx, si			; *ax:cx <- text object
		mov	di, sp			; ss:di <- stack frame
	;
	; Off we go, calling our callback on every type run. Note that
	; said callback may invalidate ds.
	;
		mov	bx, OFFSET_FOR_TYPE_RUNS
		mov	dx, offset SetHyperlinkTextStyleCallback
		call	EnumRunsInRange
		add	sp, (size SetHyperlinkTextStyleCallbackParams)
	;
	; Now recalculate the text object.
	;
		pop	bx			; bx <- handle for
						;  controller block
		call	MemDerefDS
		call	TextUnsuspend
		ret
VisTextSetHyperlinkTextStyle	endp

;
; NOTE: SetHyperlinkTextStyleCallback() *must* be in the same resource as
; EnumRunsInRange(), as it does a near callback.
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlinkTextStyleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a style on a hyperlink.

CALLED BY:	VisTextSetHyperlinkTextStyle (via EnumRunsInRange)
PASS:		*ds:si	= run
		ss:bp	= element
		*ax:cx	= instance data of text object
		ss:di	= SetHyperlinkTextStyleCallbackParams

RETURN:		nothing
DESTROYED:	bx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlinkTextStyleCallback	proc	near
	;
	; Check whether the current type element is a hyperlink.
	;
		cmp	ss:[bp].VTT_hyperlinkName, VIS_TEXT_NIL_CONTEXT_TOKEN
		je	vamoose
		pushdw	axcx			; save text object
	;
	; Figure out the range over which to set the style and stuff
	; it in the VisTextSetTextStyleParams passed as part of the
	; SetHyperlinkTextStyleCallbackParams.
	;
		call	FindRangeForHyperlinkTextStyle
	;
	; Entrust our mission to the text object.
	;
		mov	bp, di			; ss:bp <- 
						;  VisTextSetTextStyleParams
		popdw	dssi			; *ds:si <- text object	
		push	si, di			; save passed args
						;  (dssi was axcx)
		mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
		call	ObjCallInstanceNoLock	; ds possibly changed
		pop	cx, di			; restore passed args
		mov	ax, ds			; *ax:cx <- text object
vamoose:
		ret
SetHyperlinkTextStyleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRangeForHyperlinkTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the range over which to set the style.

CALLED BY:	INTERNAL	SetHyperlinkTextStyleCallback
PASS:		*ds:si	= run
		ss:di	= SetHyperlinkTextStyleCallbackParams
RETURN:		ss:di	= SetHyperlinkTextStyleCallbackParams with
			  range filled in

DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRangeForHyperlinkTextStyle	proc	near
	;
	; Get the start of the current run into dxax.
	;
		clr	dx
		mov	dl, ds:[si].TRAE_position.WAAH_high
		mov	ax, ds:[si].TRAE_position.WAAH_low
	;
	; Now check whether the start and end of the range over which
	; VisTextSetHyperlinkTextStyle is operating are the same. If
	; so, we are clearing a single hyperlink on which the cursor
	; is resting. In that case, we'll be (un)setting the style
	; over exactly the range of the current run.
	;
		movdw	bxcx, ss:[di].SHTSCP_wholeRange.VTR_start
		cmpdw	bxcx, ss:[di].SHTSCP_wholeRange.VTR_end
		pushf
		je	haveStart
	;
	; We want to modify the text style of the current run only
	; insofar as the run overlaps with the whole range of operation.
	;
		cmpdw	bxcx, dxax
		jbe	haveStart
		movdw	dxax, bxcx
haveStart:
	;
	; Note that we can use the passed VTSTSP_range field freely
	; because our caller, EnumRunsInRange, is done with it.
	;
		movdw	ss:[di].SHTSCP_params.VTSTSP_range.VTR_start, dxax
	;
	; Use the end of the run (the start of the next run) if the flags from
	; checking if [wholeRange start] = [wholeRange end] so indicate.
	;
		call	RunArrayNext		; dxax <- end of run
		popf
		je	haveEnd
	;
	; Otherwise, the style should be set only on the overlap of
	; the run with the whole range passed.
	;
		cmpdw	dxax, ss:[di].SHTSCP_wholeRange.VTR_end
		jbe	haveEnd
		movdw	dxax, ss:[di].SHTSCP_wholeRange.VTR_end
haveEnd:
		movdw	ss:[di].SHTSCP_params.VTSTSP_range.VTR_end, dxax
		ret
FindRangeForHyperlinkTextStyle	endp

TextAttributes	ends

TextNameType	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDeleteAllHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes all the hyperlinks of a VisText.

CALLED BY:	MSG_VIS_TEXT_DELETE_ALL_HYPERLINKS
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #

		ss:bp - VisTextSetHyperlinkParams
			(with VisTextRange holding virtual bounds)
		
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDeleteAllHyperlinks	proc	far	; MSG_VIS_TEXT_DELETE_ALL_HYPERLINKS
	;
	; First convert virtual coords to physical.
	;
	clr	bx			; Is this right?
	call	TA_GetTextRange		; virtual -> physical
	;
	; Now clear all hyperlinks for that physical range. Assume
	; that the hyperlinks are being shown so as to make sure that
	; they are hidden before being removed.
	;
	mov	ss:[bp].VTSHLP_file, GIGS_NONE
	mov	ss:[bp].VTSHLP_context, GIGS_NONE
	mov	ss:[bp].VTSHLP_flags, mask VTCF_SHOWING_HYPERLINKS
	mov	ax, MSG_VIS_TEXT_SET_HYPERLINK
	call	ObjCallInstanceNoLock
	ret
VisTextDeleteAllHyperlinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetContextGivenNameText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a context on the passed range of text using a
		context name obtained from the passed object.

CALLED BY:	MSG_VIS_TEXT_SET_CONTEXT_GIVEN_NAME_TEXT
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #

		ss:bp	= VisTextSetContextParams

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetContextGivenNameText	proc	far
					;MSG_VIS_TEXT_SET_CONTEXT_GIVEN_NAME_TEXT
	;
	; Get name and check whether it differs from all names
	; presently in the name array. If so, off to define it.
	;
		movdw	bxdi, ss:[bp].VTSCXP_object
		call	GetNameFromObject	; es:di <- ptr to name
		call	NameStringToToken
		cmp	ax, CA_NULL_ELEMENT	; needs defining?
		stc				; assume yes
		je	defineName
	;
	; It's already present in the name array. See if it's a
	; context name for the current file. If not, we'll attempt to
	; define it, which will fail and give the user the regulation
	; error message. Otherwise, we just set the context.
	;
		push	ds, si, es, di
		call	LockNameArray
		call	ChunkArrayElementToPtr
		mov	cl, ds:[di].VTNAE_data.VTND_type
		mov	dx, ds:[di].VTNAE_data.VTND_file
		call	UnlockNameArray
		pop	ds, si, es, di
		cmp	cl, VTNT_CONTEXT		
		clc				; name is in name array
		jne	defineName
		cmp	dx, VIS_TEXT_CURRENT_FILE_TOKEN
		clc				; name is in name array
		je	setContext
defineName:
	;
	; Save carry to show whether name was already in name array.
	;
		pushf
	;
	; Try to define the name. This will show the user a lovely
	; error message if s/he shouldn't be trying to add this name.
	;
		movdw	dxax, ss:[bp].VTSCXP_object
		push	es, di, cx, bp
		sub     sp, (size VisTextNameCommonParams)
		mov     bp, sp                          ;ss:bp <- params
		mov	ss:[bp].VTNCP_data.VTND_type, VTNT_CONTEXT
		mov	ss:[bp].VTNCP_data.VTND_contextType, VTCT_TEXT
		clr	ss:[bp].VTNCP_data.VTND_file	; current file
		movdw	ss:[bp].VTNCP_object, dxax
		mov	ax, MSG_VIS_TEXT_DEFINE_NAME
		call	ObjCallInstanceNoLock
		add     sp, (size VisTextNameCommonParams)
		pop	es, di, cx, bp
	;
	; We're finished if the name was already in the name array.
	;
		popf
		jnc	done
	;
	; Find the token for the name we just defined. If the name
	; was illegal, there won't be one and we're done.
	;
		call	NameStringToToken
		cmp	ax, CA_NULL_ELEMENT		;didn't find name?
		je	done
setContext:
	;
	; Set the context on the currently selected text range.
	;
		mov     ss:[bp].VTSCXP_context, ax 
		or	ss:[bp].VTSCXP_flags, mask VTCF_TOKEN
		mov	ax, MSG_VIS_TEXT_SET_CONTEXT
		call	ObjCallInstanceNoLock
done:
		ret
VisTextSetContextGivenNameText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRedirectHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redirects hyperlinks to point to a new destination.

CALLED BY:	MSG_VIS_TEXT_REDIRECT_HYPERLINKS
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #

		ss:bp	= VisTextRedirectHyperlinksParams

RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextRedirectHyperlinks	proc	far
					;MSG_VIS_TEXT_REDIRECT_HYPERLINKS
	;
	; If the old file and context are the same as the new, we're
	; off the hook.
	;
		mov	dx, ss:[bp].VTRHP_oldFile
		mov	ax, ss:[bp].VTRHP_oldContext
		cmp	dx, ss:[bp].VTRHP_newFile
		jne	checkFlags
		cmp	ax, ss:[bp].VTRHP_newContext
		je	done
checkFlags:
	;
	; If we've been passed tokens, we needn't fool around with
	; conversion.
	;
		test	ss:[bp].VTRHP_flags, mask VTCF_TOKEN
		jnz	gotTokens
	;
	; Convert the old file and old context indices to tokens.
	;
		call	FileAndContextNamesToTokens
		mov	ss:[bp].VTRHP_oldContext, ax
		mov	ss:[bp].VTRHP_oldFile, dx
	;
	; Prepare to do the same for the new.
	;
		mov	ax, ss:[bp].VTRHP_newContext
		mov	dx, ss:[bp].VTRHP_newFile
	;
	; Just in case people take it into their heads to clear
	; hyperlinks with this message...
	;
		cmp	dx, GIGS_NONE
		je	clearingHyperlinks
	;
	; Now convert the new file and new context indices to tokens.
	;
		call	FileAndContextNamesToTokens
newTokens:
		mov	ss:[bp].VTRHP_newContext, ax
		mov	ss:[bp].VTRHP_newFile, dx
gotTokens:
	;
	; Arrange for our parameters to be passed to our callback and
	; all is spiffy.
	;
		mov	dx, bp
		mov	di, offset RedirectHyperlinksCallback
		call	TypeChangeCommon
done:
		ret

clearingHyperlinks:
		mov	ax, VIS_TEXT_NIL_CONTEXT_TOKEN

CheckHack <GIGS_NONE eq -1 and \
	   VIS_TEXT_CURRENT_FILE_TOKEN eq -1 and \
	   VIS_TEXT_NIL_CONTEXT_TOKEN eq -1>

		jmp	newTokens

VisTextRedirectHyperlinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedirectHyperlinksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redirect hyperlinks to point to a new destination.

CALLED BY:	INTERNAL	VisTextRedirectHyperlinks (via TypeChangeCommon)
PASS:		ss:bp	= VisTextType
		ss:dx	= VisTextRedirectHyperlinksParams
RETURN:		nothing
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedirectHyperlinksCallback	proc	far
	;
	; If the current type element isn't a hyperlink to the file
	; and context for which we're redirecting hyperlinks, scoot.
	;
		mov	di, dx
		mov	ax, ss:[di].VTRHP_oldFile
		cmp	ax, ss:[bp].VTT_hyperlinkFile
		jne	done
		mov	ax, ss:[di].VTRHP_oldContext
		cmp	ax, ss:[bp].VTT_hyperlinkName
		jne	done
	;
	; Substitute the new destination for the old.
	;
		mov	ax, ss:[di].VTRHP_newFile
		mov	ss:[bp].VTT_hyperlinkFile, ax
		mov	ax, ss:[di].VTRHP_newContext
		mov	ss:[bp].VTT_hyperlinkName, ax
done:
		ret
RedirectHyperlinksCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockTypeRunArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the type run array

CALLED BY:	UTILITY
PASS:		*ds:si	= text object
RETURN:		ds:si	= first run array element
		di	= token to pass to various run array routines
		cx	= # of elements at ds:si
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarLockTypeRunArray	proc	far
		call	LockTypeRunArray
		ret
FarLockTypeRunArray	endp

LockTypeRunArray	proc	near
		class	VisTextClass
EC <		call	T_AssertIsVisText			>

		mov	bx, OFFSET_FOR_TYPE_RUNS
		call	FarRunArrayLock
		ret
LockTypeRunArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the context for the passed area

CALLED BY:	MSG_VIS_TEXT_SET_CONTEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - VisTextSetContextParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	gene	9/ 4/92		updated
	JM	7/18/94		added error checking after NameToToken call
	jenny	8/31/94		Now handles redirecting hyperlinks
	jenny	9/19/94		...and ignores undo actions
	jenny	11/ 3/94	Added VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetContext	proc	far	; MSG_VIS_TEXT_SET_CONTEXT
	;
	; If we have the context token we needn't hunt it up.
	; Likewise if we're clearing the context.
	;		
		mov	ax, ss:[bp].VTSCXP_context
		test	ss:[bp].VTSCXP_flags, mask VTCF_TOKEN
		jnz	gotToken
		cmp	ax, GIGS_NONE		; clearing context?
		je	setContext

CheckHack <GIGS_NONE eq -1 and VIS_TEXT_NIL_CONTEXT_TOKEN eq -1>
	;
	; Convert the context list entry into a token. It's actually
	; more efficient to get the file token too since we don't
	; care that it trashes dx. Saves us locking/unlocking the name
	; array ourselves.
	;
		mov	dx, 0			; dx <- current file index
		call	FileAndContextNamesToTokens	; ax <- context token
gotToken:
	;
	; If we're supposed to allow the context to be set on only one
	; range of text, make sure that it's not already set somewhere.
	;
		test	ss:[bp].VTSCXP_flags,
				mask VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET
		jz	ignoreUndo
		mov	dx, ax			; dx <- context token
		clr	bx			; bx <- current file index
		call	FindTypeForContext
		jc	alreadySet
ignoreUndo:
	;
	; If we were to allow an undo chain to be recorded for this
	; type change, it would prevent the reference count on the
	; old type element from falling to zero and causing the
	; element to be deleted. Then, if we're presently replacing
	; an old context set on the passed range, future calls to
	; FindTypeForContext would still be able to find a type for
	; that old context until a new undo chain was created. This
	; would annoy us no end. 
	;
	; It's also important to get rid of the current chain, as that
	; may contain an action, such as inserting a graphic
	; character, which the application regards as part of setting
	; a context; undoing such an action without undoing this
	; context-setting would stymie those controllers which depend for
	; proper UI updates on the type change notification here
	; induced.
	;
		mov	cx, TRUE		; flush current chain
		call	TU_IgnoreUndoActions
	;
	; Check whether we should persuade any hyperlinks pointing to a
	; context currently set on this range to point to the context now
	; being set.
	;
		test	ss:[bp].VTSCXP_flags, mask VTCF_REDIRECT_HYPERLINKS
		jz	setContext
		call	RedirectHyperlinksWhileSettingContext
setContext:
	;
	; Set the context and then resume accepting undo actions.
	;
	; ax = context
	;
		mov	di, offset SetContextCallback
		call	TypeChangeCommon
		call	TU_AcceptUndoActions
done:
		ret
alreadySet:
		call	DoContextAlreadySetDialog
		jmp	done

VisTextSetContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoContextAlreadySetDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user s/he can't set the same context twice.	

CALLED BY:	INTERNAL	VisTextSetContext

PASS:		*ds:si	= text object
		ax	= context token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoContextAlreadySetDialog	proc	near
nameEltBuf	local	MAX_VIS_TEXT_NAME_ARRAY_ELT_SIZE dup(TCHAR)
		.enter
	;
	; Get the name array element for the context.
	;
		push	bp
		mov	cx, ss
		lea	dx, ss:[nameEltBuf]
		mov	bp, ax			; bp <- context token
		mov	ax, MSG_VIS_TEXT_FIND_NAME_BY_TOKEN
		call	ObjCallInstanceNoLock	; ax <- element size
	;
	;  NULL terminate the name string.
	;
		mov	es, cx
		mov	di, dx
		add	di, ax			; es:di <- end of string
		mov	{TCHAR}es:[di], 0		
	;
	; Tell the user this context is already set somewhere.
	;
		mov	di, dx
		add	di, size VisTextNameArrayElement
						; es:di <- name string
		mov	dx, offset contextAlreadySetString
		clr	ax
		mov	cx, ax			;ax:cx <- null help context
		call	DoNameErrorDialog
		pop	bp

		.leave
		ret
DoContextAlreadySetDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedirectHyperlinksWhileSettingContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See routine name :)

CALLED BY:	INTERNAL	VisTextSetContext
PASS:		*ds:si	= text object
		ss:bp	= VisTextSetContextParams
		ax	= new context token
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/19/94    	Broke out of VisTextSetContext

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedirectHyperlinksWhileSettingContext	proc	near
	;
	; Get the token for the context presently set on the current
	; range. If no context is set, forget it.
	;
		push	ax
		movdw	dxax, ss:[bp].VTSCXP_range.VTR_start
		movdw	cxdi, ss:[bp].VTSCXP_range.VTR_end
		call	GetTypeForPos		; cx <- present context
		cmp	cx, VIS_TEXT_NIL_CONTEXT_TOKEN
		pop	ax			; ax <- new context
		je	done
	;
	; We have a current context. Redirect all its hyperlinks.
	;
		sub	sp, (size VisTextRange)
		mov	di, sp
		movdw	ss:[di].VTR_start, 0
		movdw	ss:[di].VTR_end, TEXT_ADDRESS_PAST_END
		mov	bx, VIS_TEXT_CURRENT_FILE_TOKEN
		mov	dx, bx
		call	RedirectHyperlinks
		add	sp, (size VisTextRange)
done:
		ret
RedirectHyperlinksWhileSettingContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeForPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type element for the passed range.

CALLED BY:	INTERNAL	VisTextSetContext

PASS:		*ds:si	= text object
		dx:ax	= start of range
		cx:di	= end of range

RETURN:		ax	= token of hyperlink name
		dx	= token of hyperlink file
		cx	= token of context

DESTROYED:	di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeParams	struct
	GTP_params	VisTextGetAttrParams
	GTP_attrs	VisTextType
	GTP_diffs	VisTextTypeDiffs
GetTypeParams	ends

GetTypeForPos	proc	near
		uses	bp
		.enter
		class	VisTextClass
	;
	; Get the type element into a buffer on the stack.
	;
		sub	sp, (size GetTypeParams)
		mov	bp, sp
		movdw	ss:[bp].VTGAP_range.VTR_start, dxax
		movdw	ss:[bp].VTGAP_range.VTR_end, cxdi
		clr	ss:[bp].VTGAP_flags
		mov	ss:[bp].VTGAP_attr.segment, ss
		lea	ax, ss:[bp].GTP_attrs
		mov	ss:[bp].VTGAP_attr.offset, ax
		mov	ss:[bp].VTGAP_return.segment, ss
		lea	ax, ss:[bp].GTP_diffs
		mov	ss:[bp].VTGAP_return.offset, ax
		mov	ax, MSG_VIS_TEXT_GET_TYPE
		call	ObjCallInstanceNoLock
	;
	; Load return values and emancipate buffer.
	;
		mov	ax, ss:[bp].GTP_attrs.VTT_hyperlinkName
		mov	dx, ss:[bp].GTP_attrs.VTT_hyperlinkFile
		mov	cx, ss:[bp].GTP_attrs.VTT_context
		add	sp, (size GetTypeParams)

		.leave
		ret
GetTypeForPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedirectHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redirect hyperlinks in the passed range which point to
		the old file and context to point to the new instead.

CALLED BY:	INTERNAL	VisTextSetContext

PASS:		*ds:si	= text object
		ss:di	= VisTextRange
		bx	= old file token
		cx	= old context token
		dx	= new file token
		ax	= new context token
		
RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedirectHyperlinks	proc	near
		uses	ax, bp
		.enter
		class	VisTextClass

		sub	sp, (size VisTextRedirectHyperlinksParams)
		mov	bp, sp
		mov	ss:[bp].VTRHP_oldFile, bx
		mov	ss:[bp].VTRHP_oldContext, cx
		mov	ss:[bp].VTRHP_newFile, dx
		mov	ss:[bp].VTRHP_newContext, ax
		movdw	dxax, ss:[di].VTR_start
		movdw	ss:[bp].VTRHP_range.VTR_start, dxax
		movdw	dxax, ss:[di].VTR_end
		movdw	ss:[bp].VTRHP_range.VTR_end, dxax
		mov	ss:[bp].VTRHP_flags, mask VTCF_TOKEN
		mov	ax, MSG_VIS_TEXT_REDIRECT_HYPERLINKS
		call	ObjCallInstanceNoLock
		add	sp, (size VisTextRedirectHyperlinksParams)
		.leave
		ret
RedirectHyperlinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextUnsetAllContexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsets all contexts in the passed range text.

CALLED BY:	MSG_VIS_TEXT_UNSET_ALL_CONTEXTS
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #

		ss:bp - VisTextSetContextParams
			(with VisTextRange holding virtual bounds)
		
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextUnsetAllContexts	proc	far	; MSG_VIS_TEXT_UNSET_ALL_CONTEXTS
	;
	; First convert virtual coords to physical.
	;
	clr	bx			; Is this right?
	call	TA_GetTextRange		; virtual -> physical
	;
	; Now clear all contexts for that physical range.
	;
	mov	ss:[bp].VTSCXP_context, GIGS_NONE
	clr	ss:[bp].VTSCXP_flags
	mov	ax, MSG_VIS_TEXT_SET_CONTEXT
	call	ObjCallInstanceNoLock
	ret
VisTextUnsetAllContexts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextFollowHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow a hyperlink

CALLED BY:	MSG_VIS_TEXT_FOLLOW_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextFollowHyperlinkParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextFollowHyperlink	proc	far	; MSG_VIS_TEXT_FOLLOW_HYPERLINK
	;
	; Adjust the range params to the selection, if necessary
	;
	clr	bx				;bx <- no context
	call	TA_GetTextRange
CheckHack <(offset VTFHLP_range) eq 0>
	;
	; Get the type run at the start of the selection -- the link
	;
	push	ds, si
	mov	bx, OFFSET_FOR_TYPE_RUNS
	movdw	dxax, ss:[bp].VTFHLP_range.VTR_start ;dxax <- selection start
	;
	; Mimic VisTextGetType here, as that routine is used when
	; sending a type change notification, which updates the
	; follow hyperlink trigger enabled state.  (This is not quite the
	; same - it ignores insertion elements)
	;
	call	TSL_IsParagraphStart
	jc	getRight
	cmpdw	dxax, ss:[bp].VTFHLP_range.VTR_end	
	jnz	getRight			;don't use run to the left
	call	FarGetRunForPositionLeft
	jmp	getContext		
getRight:		
	call	FarGetRunForPosition

getContext:
	;
	; Figure out the context the link refers to
	;
	sub	sp, (size VisTextType)
	mov	bp, sp				;ss:bp <- ptr to 
						; VisTextType
	call	GetElement
	mov	dx, ss:[bp].VTT_hyperlinkName
	mov	ax, ss:[bp].VTT_hyperlinkFile
	add	sp, (size VisTextType)
	cmp	ax, VIS_TEXT_CURRENT_FILE_TOKEN	;same file?
	jne	quitUnlock			;branch if not same file
	cmp	dx, VIS_TEXT_NIL_CONTEXT_TOKEN	;any link?
	je	quitUnlock			;branch if no link
	;
	; Figure out the type token of the context
	;
	call	FindTypeForContextNoLock	;dx <- type run token
	call	FarRunArrayUnlock
	pop	ds, si				;*ds:si <- text object
	jnc	quit				;branch if no range
						; found
	;
	; Find the range of the type run(s) that the context covers
	;
	push	dx				;pass token
	sub	sp, (size VisTextRange)
	mov	bp, sp				;ss:bp <- ptr to
						; VisTextRange
	call	FindRangeForContext
	;
	; Set the selection to the extent of the runs
	;
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	add	sp, (size VisTextRange)+(size word)
quit:
	ret

quitUnlock:
	call	FarRunArrayUnlock
	pop	ds, si
	jmp	quit
	
VisTextFollowHyperlink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRangeForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the range that a context token covers

CALLED BY:	VisTextFollowHyperlink()
PASS:		*ds:si - 
		ss:bp - VisTextRange to fill in
		+ word -- context token to find
RETURN:		ss:bp - VisTextRange that context covers
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRangeForContext		proc	near
	uses	ds, si, di, ax, bx, cx, dx
	.enter
	;
	; Initialize the range to nothing
	;
	movdw	ss:[bp].VTR_start, -1
	movdw	ss:[bp].VTR_end, 0
	;
	; Lock the type run array and load the initial run
	;
	call	LockTypeRunArray		;ds:si <- ptr to 1st elemnt
						;cx <- #elements at ds:si
	mov	bx, ds:[si].TRAE_token
	mov	ax, ds:[si].TRAE_position.WAAH_low
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	clr	di				;di <- no range found
	;
	; For each run array element, see if it matches
	;
runArrayLoop:
	cmp	bx, ss:[bp][(size VisTextRange)] ;same context?
	jne	differentContext
	;
	; See if the run is before our current start
	;
	cmpdw	dxax, ss:[bp].VTR_start		;before current start?
	jae	afterStart			;branch if after
						; current start
	movdw	ss:[bp].VTR_start, dxax		;set new start
afterStart:
	cmpdw	dxax, TEXT_ADDRESS_PAST_END	;last element?
	je	setEnd				;branch if last element
	dec	di				;di <- range found
	jmp	nextRun
	;
	; See if the start of this run (ie. the end of the previous)
	; is after our current end if it was the right context
	;
differentContext:
	tst	di				;was previous context?
	jz	nextRun				;branch if not
	cmpdw	dxax, ss:[bp].VTR_end		;after current end?
	jbe	beforeEnd			;branch if before
						; current end
setEnd:
	movdw	ss:[bp].VTR_end, dxax		;set new end
beforeEnd:
	clr	di				;di <- no range found
	;
	; Advance to the next run
	;
nextRun:
;;	cmp	cx, 1				;last element?
;;	je	endArrayLoop			;branch if no
						; more elements
	call	FarRunArrayNext			;cx <- #elts at ds:si
	;
	; If there are more elements, and this element is not the last,
	; continue looping.
	;
	jcxz	checkEnd
	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	jne	runArrayLoop
checkEnd:
	;
	; We've finished the search. If, at this point, the start is
	; past the end, then the context run must be the last run -
	; i.e. the context range stretches from its start all the way
	; to the end of the text. -jenny 8/24/94
	;
	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end
	jbe	endArrayLoop
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
endArrayLoop:
	;
	; Unlock the run array
	;
	call	FarRunArrayUnlock
	.leave
	ret
FindRangeForContext		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDefineName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a new context
CALLED BY:	MSG_VIS_TEXT_DEFINE_NAME

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/22/92		Initial version
	JM	3/18/94		added error checking after
				call to ContextFileNameToToken

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisTextDefineName	proc	far	; MSG_VIS_TEXT_DEFINE_NAME
	;
	; Get the name and make sure it is unique
	;
	call	GetNameCheckUnique
	jnc	quit				;branch if name in use
	;
	; Initial set up
	;
	push	ds, si, bx, cx
	call	LockNameArray
	call	GetNameParams
	call	ContextFileNameToToken		;dx <- token for file,
						;if any
EC <	ERROR_Z VIS_TEXT_NAME_NOT_FOUND_FOR_INDEX	;>
	call	UnlockNameArray
	pop	ds, si, bx, cx

	push	bp
	clr	ax
	push	ax				;pass VTND_helpText
	push	ax
	push	dx				;pass file name token
	push	{word}ss:[bp].VTNCP_data.VTND_type ;pass type
CheckHack <(size VTNCP_data) eq 8>
	;
	; Define the name
	;
	sub	sp, (size VisTextAddNameParams)-(size VisTextNameData)
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTANP_name.segment, es	;pass ptr to string
	mov	ss:[bp].VTANP_name.offset, di
	mov	ss:[bp].VTANP_flags, 0		;pass NameArrayAddFlags
	mov	ss:[bp].VTANP_size, cx		;pass size of string
	mov	ax, MSG_VIS_TEXT_ADD_NAME	;ax <- name token
	call	ObjCallInstanceNoLock		;call ourselves
	add	sp, (size VisTextAddNameParams)
	pop	bp 
	;
	; Done with the passed string
	;
	call	MemFree
	;
	; Send a notification out that stuff has changed
	;
	push	ax
	call	GetNameParams		; cl <- VisTextNameType
					; dx <- file index 
					;  (if VTNT_CONTEXT)
	pop	ax
	call	TokenToName		; ax <- name index
	mov	ch, VTNCT_ADD
	call	SendNameNotification
	;
	; Mark the object as dirty
	;
	call	TextMarkUserModified
quit:
	ret

VisTextDefineName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextUpdateNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a name list
CALLED BY:	MSG_VIS_TEXT_UPDATE_NAME_LIST

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		dx - size of VisTextNameCommonParams (if called remotely)
		ss:bp - VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/28/92		Initial version
	JM	3/18/94		added noTokenFound
				to avoid synchronization
				related crashes (bug 6007 related)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisTextUpdateNameList	proc	far ; MSG_VIS_TEXT_UPDATE_NAME_LIST
	;
	; Get the name array
	;
	call	LockNameArray
	push	bx
	;
	; Figure out how many contexts/files we have
	;
	call	GetNameParams
	call	ContextFileNameToToken			;dx <- token
							;of file
	jz	noTokenFound				; Item was
							; probably
							; deleted
							; already.
	mov	bx, SEGMENT_CS
	mov	di, offset VTCountNamesCallback		;bx:di <-
							; callback
	call	ElementArrayGetUsedCount
	;
	; If we are showing files, add a fake name for the current file.
	;
	cmp	cl, VTNT_FILE			;showing files?
	jne	notFiles			;branch if not files
	inc	ax				;ax <- one more file
notFiles:	
	;
	; Done with name array
	;
	pop	bx
	call	UnlockNameArray
	;
	; Tell the list how many contexts/files we have.
	; This will force it to update the monikers.
	;
	mov	cx, ax				;cx <- # of items
	mov	si, ss:[bp].VTNCP_object.chunk
	mov	bx, ss:[bp].VTNCP_object.handle
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	GOTO	ObjMessage

noTokenFound:
	pop	bx
	call	UnlockNameArray
	ret
VisTextUpdateNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetNameListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get/set the moniker for a name list
CALLED BY:	MSG_VIS_TEXT_GET_NAME_LIST_MONIKER

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/92		Initial version
	JM	3/18/94		added "jz	done" to
				help with synchronization
				related crashes
	jenny	7/11/94		Changed to break out Lock/UnlockNameArrayString

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetNameListMoniker	proc far ; MSG_VIS_TEXT_GET_NAME_LIST_MONIKER
	;
	; Save ptr to passed params before we mess up bp.
	;
		mov	di, bp		; ss:di <- VisTextNameCommonParams

		uses	cx, dx, bp
.warn -unref_local
nameEltBuf	local	MAX_VIS_TEXT_NAME_ARRAY_ELT_SIZE dup(TCHAR)
.warn @unref_local
		.enter
	;
	; Lock name array and get pointer to string for passed name index.
	;
		call	LockNameArrayString	; cx:dx <- ptr to string
		jz	done
	;
	; Set the Nth moniker
	;
		push	bx, bp, di
		movdw	bxsi, ss:[di].VTNCP_object
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		mov	bp, ss:[di].VTNCP_index
		mov	di, mask MF_CALL
		call	ObjMessage
		or	bx, 1			; clear zero flag
		pop	bx, bp, di
done:
	;
	; Clean up.
	;
		call	UnlockNameArrayString
		.leave
		ret
VisTextGetNameListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetNameListMonikerFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get/set the moniker for a name list in color
CALLED BY:	MSG_VIS_TEXT_GET_NAME_LIST_MONIKER_FRAME

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetNameListMonikerFrame	proc far 
				 ;MSG_VIS_TEXT_GET_NAME_LIST_MONIKER_FRAME
	;
	; Save ptr to passed params before we mess up bp.
	;
		mov	di, bp		; ss:di <- VisTextNameCommonParams

		uses	cx, dx, bp

.warn -unref_local
nameEltBuf	local	MAX_VIS_TEXT_NAME_ARRAY_ELT_SIZE dup(TCHAR)
.warn @unref_local
		.enter
	;
	; Lock name array and get pointer to string for passed name index.
	;
		call	LockNameArrayString	; cx:dx <- string
						; ax <- token
						; bx <- value for unlock
		jz	done			; no string?
	;
	; Set up the data to create either a text or a gstring
	; moniker, whose characteristics depend on whether the token
	; appertains to a file or a context, and on which
	; VisTextNameCommonFlags were passed.
	; 
		push	bx, bp			; save unlock value and locals
		call	ChooseMonikerType	; al <- VisMonikerDataType
						; ah <- enable/disable flag

		call	SetUpMonikerData	; bx:si <- ptr to string
						;  OR
						;  ^lbx:si <- gstring data
						;  cx <- gstring width
						;  dx <- gstring height
	;
	; Send the moniker off to the passed object using the passed message.
	;
		call	SendMoniker
		pop	bx, bp		; bx <- value for unlock
					; bp <- locals
done:
	;
	; Clean up.
	;
		call	UnlockNameArrayString
		.leave
		ret
VisTextGetNameListMonikerFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNameArrayString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a name string.

CALLED BY:	INTERNAL	VisTextGetNameListMoniker
				VisTextGetNameListMonikerFrame

PASS:		*ds:si	= VisText instance data
		ss:di	= ptr to VisTextNameCommonParams
		ss:bp	= ptr to inherited stack frame

RETURN:		zero flag set if no string found
		ax	= name token
		bx	= value to pass to UnlockNameArray
		cx:dx	= string

DESTROYED:	nothing
SIDE EFFECTS:
	Locks name array and either puts string on stack or, if dealing
	with current file, locks the TextTypeStrings resource. Caller
	must clean up when done with string by calling UnlockNameArrayString.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockNameArrayString	proc	near
		uses	ds,si

nameEltBuf	local	MAX_VIS_TEXT_NAME_ARRAY_ELT_SIZE dup(TCHAR)
		.enter inherit near
	;
	; Set up to find our data on the stack.
	;
		lea	dx, ss:[nameEltBuf]
		xchg	bp, di		; ss:bp <- VisTextNameCommonParams
					; di <- saved bp
	;
	; Get the name array.
	;
		call	LockNameArray		; *ds:si <- name array
						; bx <- val for unlock
		push	bx
	;
	; Map the Nth index to the appropriate name token. If there's
	; no mapping, the name has probably been deleted from the name
	; array, in which case the list will be updated later - the
	; passed index was just out of date.
	;
		push	dx			; save buffer offset
		call	GetNameParams
		call	NameToToken		; ax <- token
		pop	dx
		jz	done			; no mapping?
	;
	; Find the name string in the name array. The string for the
	; current file is not in the array and must be handled separately.
	;							
		jnc	isCurFile
		push	ax			; save token
		mov	cx, ss			; cx:dx <- ptr to buffer
		call	ChunkArrayGetElement	; get the name
	;
	; NULL terminate the name.
	;
		movdw	dssi, cxdx		; ds:si <- ptr to buffer
		add	si, ax			; ds:si <- ptr to end of buffer
		mov	{TCHAR}ds:[si], 0
		add	dx, (size VisTextNameArrayElement)
						; cx:dx <- ptr to string
						;  zero flag clear
		pop	ax			; ax <- token
done:
		pop	bx			; bx <- val for unlock
		xchg	bp, di			; restore regs
		.leave
		ret
isCurFile:
	;
	; Lock the current file string.
	;
		mov	dx, offset currentFileString	; dx <- string to lock
		call	LockNameMessage
		or	bx, 1				; clear zero flag
		jmp	done

LockNameArrayString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockNameArrayString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after done with name array string.

CALLED BY:	INTERNAL	VisTextGetNameListMoniker
				VisTextGetNameListMonikerFrame

PASS:		zero flag set if LockNameArrayString found no string
		bx	= value to pass to UnlockNameArray
		ss:di	= ptr to VisTextNameCommonParams
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockNameArrayString	proc	near
	;
	; If we found no string, there's nothing to clean up.
	;
		jz	done
	;
	; If we've been dealing with the current file name, we have to
	; unlock its string specially.
	;
		cmp	ss:[di].VTNCP_data.VTND_type, VTNT_FILE
		jne	done
		cmp	ss:[di].VTNCP_index, 0
		je	isCurFile
done:
		call	UnlockNameArray
		ret
isCurFile:
	;
	; Unlock the current file string.
	;
		call	UnlockNameMessage
		jmp	done
UnlockNameArrayString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseMonikerType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker type based on whether passed context has been
		associated with a text range.

CALLED BY:	INTERNAL	VisTextGetNameListMonikerFrame
PASS:		*ds:si	= VisText instance data
		ss:di	= ptr to VisTextNameCommonParams
		ax	= name token

RETURN:		al	= VisMonikerDataType (VMDT_TEXT or VMDT_GSTRING)
		ah	= BooleanByte (true to enable moniker)

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94    	Initial version
	jenny	10/14/94	Moved flag check in here and added disable flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseMonikerType	proc	near
		uses	cx,dx
		.enter	inherit	VisTextGetNameListMonikerFrame
	;
	; If we needn't do anything special, just use an enabled text moniker.
	;		
		mov_tr	bx, ax				; bx <- saved token
		mov	al, VMDT_TEXT
		mov	ah, BB_TRUE			; ah <- enabled
		test	ss:[di].VTNCP_flags, 
			 mask VTNCF_COLOR_MONIKERS_FOR_UNSET_CONTEXTS or \
			 mask VTNCF_DISABLE_MONIKERS_FOR_SET_CONTEXTS
		jz	done
	;
	; If the name is a file name, use an enabled text moniker.
	;
		push	bx			; save token
		mov_tr	bx, ax			; bl, bh <- text, enabled
		mov	bp, di
		call	GetNameParams		; cl <- VisTextNameType
						; dx <- file index
						;  if cl = VTNT_CONTEXT
		mov_tr	ax, bx			; al, ah <- text, enabled
		cmp	cl, VTNT_FILE
		mov	bx, dx			; bx <- file index
		pop	dx			; dx <- token
		je	done
	;
	; It's a context name. Either we want to color it if it's
	; unset, or we want to disable it if it's set, or both.
	; (Otherwise we wouldn't have reached this code). Current
	; potential return values: al = VMDT_TEXT, ah = BB_TRUE (enabled).
	;
		test	ss:[di].VTNCP_flags, 
				mask VTNCF_COLOR_MONIKERS_FOR_UNSET_CONTEXTS
		jz	findType
		mov	al, VMDT_GSTRING
		tst	bx
		jnz	done
findType:
		call	FindTypeForContext	; carry <- set if context set
		jnc	done
	;
	; The context is set, so we'll use a text moniker. Do we want
	; to disable it?
	;
		mov	al, VMDT_TEXT
		test	ss:[di].VTNCP_flags,
				mask VTNCF_DISABLE_MONIKERS_FOR_SET_CONTEXTS
		jz	done
		mov	ah, BB_FALSE		; ah <- disable
done:
		.leave
		ret
ChooseMonikerType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTypeForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock/unlock type run array around check for whether
		context is set.

CALLED BY:	INTERNAL	ChooseMonikerType

PASS:		*ds:si	= VisText instance data
		bx	= file index
		dx	= context token

RETURN:		carry set if context has been set
			dx = run token for context
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/27/94    	Broke out of ChooseMonikerType

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTypeForContext	proc	near
		uses	ds, si, di
		.enter
	;
	; Only if the context is in the current file can we check whether
	; it's set.
	;
		tst	bx
		jnz	done
	;
	; It's in the current file. Has it been applied to any text?
	;
		call	LockTypeRunArray
		call	FindTypeForContextNoLock
		call	FarRunArrayUnlock
done:
		.leave
		ret
FindTypeForContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTypeForContextNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find type run token for passed context.

CALLED BY:	INTERNAL	FindTypeForContext
				VisTextFollowHyperlink

PASS:		ds:si	= ptr to first element in locked type run array
		dx	= name token for context
RETURN:		carry set if context has been set
			dx = run token for context
DESTROYED:	di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94    	Broke out of ChooseMonikerType

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTypeForContextNoLock	proc	near
		uses	ds
		.enter
	;
	; The type run array is already locked. Lock element array and
	; find type, if any, for context.
	;
		call	FarElementArrayLock
		push	bx
		mov	bx, cs
		mov	di, offset FindTypeForContextCallback
		call	ChunkArrayEnum
	;
	; Unlock element array.
	;
		pop	bx
		call	FarElementArrayUnlock
		.leave
		ret
FindTypeForContextNoLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTypeForContextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the type run for a context

CALLED BY:	INTERNAL	FindTypeForContextNoLock via ChunkArrayEnum()

PASS:		ds:di	= current element (VisTextType)
		dx	= name token of context to match

RETURN:		carry	= set to abort if type run found for context
		    dx 	= run token of found type run

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/14/92		Initial version
	jenny	10/04/94	Make sure element isn't free

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTypeForContextCallback	proc	far
	uses	ax
	.enter
	;
	; See if this type element contains a matching context.
	;
		cmp	dx, ds:[di].VTT_context
		clc				; carry <- don't abort
		jne	done
	;
	; It does. But is it a current type element or a defunct one hanging
	; around the free list waiting to be recycled?
	;
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		clc				; carry <- don't abort
		je	done
	;
	; Got it.
	;
		call	ChunkArrayPtrToElement
		mov	dx, ax			; dx <- element #
		stc				; carry <- abort
done:
		.leave
		ret
FindTypeForContextCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpMonikerData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a gstring from a text string and a color for the text.

CALLED BY:	INTERNAL	VisTextGetNameListMonikerFrame

PASS:		cx:dx	= text string
		al	= VisMonikerDataType (VMDT_TEXT or VMDT_GSTRING)

RETURN:		if passed al = VMDT_TEXT
			bx:si	= text string
		else
			^lbx:si	= gstring data
			cx	= gstring width
			dx	= gstring height
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpMonikerData	proc	near
		uses	ax, di
		.enter
	;
	; If we're using text, all we have to do is set up the string
	; pointer right.
	;
		movdw	bxsi, cxdx		; bx:si <- string
		cmp	al, VMDT_TEXT
		je	done
	;
	; We want a gstring. Allocate a chunk and create one.
	;
		push	ax, cx			; save passed args
		mov	ax, LMEM_TYPE_GENERAL 
		mov	cx, (size LMemBlockHeader)
		call	MemAllocLMem		; bx <- handle
		mov	cl, GST_CHUNK
		call	GrCreateGString		; di <- gstate handle
						; si <- chunk
		pop	ax, cx			; restore args
		pushdw	bxsi			; save gstring data
	;
	; Fill it up with our moniker text. 
	;
		call	DrawMonikerTextToGString
	;
	; Find out the height and width of the gstring.
	;
		mov	cx, NAME_ARRAY_MAX_NAME_SIZE
		call	GrTextWidth		; dx <- width
		push	dx
		mov	si, GFMI_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics		; dx <- height
		push	dx
	;
	; End the gstring and get rid of it, leaving the data in the
	; lmem chunk.
	;
		call	GrEndGString
		mov_tr	si, di			; si <- gstate handle
		clr	di
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		pop	dx			; dx <- height
		pop	cx			; cx <- width
		popdw	bxsi			; ^lbx:si <- data
done:
		.leave
		ret
SetUpMonikerData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMonikerTextToGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set some characteristics for a gstring and draw text to it.

CALLED BY:	INTERNAL	SetUpMonikerData

PASS:		cx:dx	= text string
		di	= gstate handle
RETURN:		nothing
DESTROYED:	ax, bx, cx, ds, si
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMonikerTextToGString	proc	near
	;
	; Put the string ptr where we want it before trashing cx and dx.
	;
		movdw	dssi, cxdx		; ds:si <- string
	;
	; We're using a gstring for this moniker in order to make it
	; stand out from text monikers in the same list. What we do
	; to make this moniker conspicuous depends on the display.
	;
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	GenCallApplication	; ah <- DisplayType
		andnf	ah, mask DT_DISP_CLASS
	;
	; If the display can show light green, that's what we use.
	;
		cmp	ah, DC_COLOR_4
		jb	blackAndWhite
		mov	ah, CF_INDEX
		mov	al, C_LIGHT_GREEN
		call	GrSetTextColor
drawText:
	;
	; Draw the passed text string.
	;
		clr	ax			; x and y positions
		mov	bx, ax			;  are 0
		mov	cx, ax			; string is null-terminated
		call	GrDrawText
		ret

blackAndWhite:
	;
	; For black and white displays, we make the draw mode XOR so
	; the moniker will be visible when selected.
	;
		mov	al, MM_XOR
		call	GrSetMixMode
	;
	; Also, we want italics, since we can't use color, to
	; distinguish this moniker from those that are just plain text. 
	; The default font doesn't allow italics, so we set the font first.
	;
		clr	ax
		mov	dx, 12			; dx.ah <- point size 12
		mov	cx, FID_DTC_URW_ROMAN
		call	GrSetFont
		mov	ax, mask TS_ITALIC	; al <- set italic
						; ah <- reset nothing
		call	GrSetTextStyle
		
		jmp	drawText

DrawMonikerTextToGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a moniker to the passed object.

CALLED BY:	INTERNAL	VisTextGetNameListMonikerFrame

PASS:		ss:di	= ptr to VisTextNameCommonParams
		ah	= BooleanByte (true to enable moniker)
		al	= VisMonikerDataType (VMDT_TEXT or VMDT_GSTRING)
		if al = VMDT_TEXT
			bx:si	= ptr to text string
		else
			^lbx:si	= gstring data for moniker
			cx	= width of gstring
			dx	= height of gstring

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si, bp
SIDE EFFECTS:	
	Frees gstring data block when done with data.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMoniker	proc	near
		uses	di
		.enter
	;
	; Save the data type and the gstring block handle, if such it is.
	;
		push	ax, bx
	;
	; Set up the stack frame for replacing the moniker.
	; Start with the information dependent on whether the data is
	; a gstring or a text string.
	;
		sub	sp, (size ReplaceItemMonikerFrame)
		mov	bp, sp
		mov	ss:[bp].RIMF_sourceType, VMST_FPTR
		cmp	al, VMDT_TEXT
		je	finishUp
		mov	ss:[bp].RIMF_sourceType, VMST_OPTR
		mov	ss:[bp].RIMF_width, cx
		mov	ss:[bp].RIMF_height, dx
finishUp:
	;
	; Add the information not dependent on the data type.
	;
		movdw	ss:[bp].RIMF_source, bxsi
		mov	ss:[bp].RIMF_dataType, al
		mov_tr	bx, ax			; bh <- enable/disable flag
		clr	ax
		mov	ss:[bp].RIMF_length, ax
		cmp	bh, BB_TRUE		; enabled?
		je	gotFlags		; pass clear flags if so
		mov	ax, mask RIMF_NOT_ENABLED
gotFlags:
		mov	ss:[bp].RIMF_itemFlags, ax
		mov	ax, ss:[di].VTNCP_index
		mov	ss:[bp].RIMF_item, ax
	;
	; Send the message to replace the thing.
	;
		movdw	bxsi, ss:[di].VTNCP_object
		mov	ax, ss:[di].VTNCP_message
		mov	di, mask MF_CALL or mask MF_STACK
		mov	dx, (size ReplaceItemMonikerFrame)
		call	ObjMessage
		add	sp, (size ReplaceItemMonikerFrame)
	;
	; If we used a gstring, free its data block.
	;
		pop	ax, bx
		cmp	al, VMDT_GSTRING
		jne	done
		call	MemFree
done:
		.leave
		ret
SendMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetNameListNameType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type for a name in a context list
CALLED BY:	MSG_VIS_TEXT_GET_NAME_LIST_NAME_TYPE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - ptr to VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/92		Initial version
	JM	3/18/94		added error checking after
				NameToToken
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisTextGetNameListNameType	proc far ; MSG_VIS_TEXT_GET_NAME_LIST_NAME_TYPE
	uses	cx, dx, bp
	.enter
	;
	; Get the name array
	;
	call	LockNameArray
	push	bx
	;
	; Map the Nth index to the appropriate name & get its context type
	;
	call	GetNameParams
	call	NameToToken			;ax <- token
EC <	ERROR_Z VIS_TEXT_NAME_NOT_FOUND_FOR_INDEX	;>
	mov	cl, VTCT_TEXT			;cl <- default to text
	jnc	gotType				;branch if no match
	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
	mov	cl, ds:[di].VTNAE_data.VTND_contextType
gotType:
	clr	ch				;cx <- VisTextContextType
	;
	; Set the context type in the list
	;
	push	bp
	movdw	bxsi, ss:[bp].VTNCP_object	;^lbx:si <- OD of list
	clr	dx				;dx <- no indeterminates
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	;
	; Done with name array
	;
	pop	bx
	call	UnlockNameArray

	.leave
	ret
VisTextGetNameListNameType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a name list entry to its corresponding name array token

CALLED BY:	UTILITY
PASS:		*ds:si - name array
		ax - list index
		cl - VisTextNameType
		dx - file list index (if VTNT_CONTEXT)
RETURN:		carry - set if real name
		    ax - token of matching name
		zero flag - set if token was not found
		    for the list index in ax
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		zero flag returned for
				caller to do error checking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameToToken		proc	near
	uses	bx, di, cx, dx
	.enter

	cmp	cl, VTNT_FILE			;file or context?
	je	isFile				;branch if file
	call	FileAndContextNamesToTokensNoLock
	jmp	done

doneAndTokenFound:
	or	bx, 1			; Clear zero flag.
	stc				; (Re)set the carry flag.
done:
	.leave
	ret

	;
	; If the list entry is a file, just convert the index to a token
	;
isFile:
	call	FileNameToToken
	jz	done			; If ZF set, then file name
					; not found.  (CF clear if ZF set)
	jc	doneAndTokenFound
	or	bx, 1			; Clear zero flag and carry flag.
	jmp	done
NameToToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAndContextNamesToTokensNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a pair of file and context indices into their
		corresponding tokens.

CALLED BY:	INTERNAL	NameToToken
				FileAndContextNamesToTokens

PASS:		*ds:si	= locked name array
		ax	= index of context
		dx	= index of file

RETURN:		ax	= token of context
		dx	= token of file
		zero flag = set if token was not found
		    for the list index in ax

DESTROYED:	bx, cx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Broke out of NameToToken

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAndContextNamesToTokensNoLock	proc	near
		uses	bx, cx, di
		.enter
	;
	; Must get file token first. Error if file token not found
	; (which means that the file was deleted) but context token
	; still exists, since a file's contexts are deleted before the file.
	;
		mov	cl, VTNT_CONTEXT
		call	ContextFileNameToToken		; dx <- file token

EC <		ERROR_Z VIS_TEXT_NAME_NOT_FOUND_FOR_INDEX	;>

	;
	; Now convert the context list entry to a token.
	;
		mov	bx, SEGMENT_CS
		mov	di, offset VTCountNamesCallback	; bx:di <- callback
		call	ElementArrayUsedIndexToToken	; ax <- token
		jnc	notFound
		or	bx, 1				; clear zero flag
		stc
done:
		.leave
		ret
notFound:
	;
	; No token found for list index, so set zero flag and clear
	; carry flag (no borrow).
	;
		sub	bx, bx
		jmp	done

FileAndContextNamesToTokensNoLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAndContextNamesToTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a pair of file and context indices into their
		corresponding tokens. Includes locking/unlocking name array.

CALLED BY:	INTERNAL	VisTextSetHyperlink
				VisTextRedirectHyperlinks

PASS:		ax	= index of context
		dx	= index of file

RETURN:		ax	= token of context
		dx	= token of file
		zero flag = set if token was not found
		    for the list index in ax

DESTROYED:	bx, cx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAndContextNamesToTokens	proc	near
		uses	ds, si
		.enter
		class	VisTextClass
	;
	; Lock/unlock the name array around the conversion of indices
	; to tokens.
	;
		call	LockNameArray
		call	FileAndContextNamesToTokensNoLock

EC <		ERROR_Z VIS_TEXT_NAME_NOT_FOUND_FOR_INDEX	;>

		call	UnlockNameArray
		.leave
		ret
FileAndContextNamesToTokens	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContextFileNameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a context's file list entry to its corresponding token

CALLED BY:	NameToToken(), VisTextDefineName()
PASS:		*ds:si - name array
		cl - VisTextNameType
		dx - file list index
RETURN:		zero flag - set if no token was found
		dx - name token for associated file if this was a
		     context
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 4/92		Initial version
	JM	3/18/94		zero flag returned for
				caller to do error checking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContextFileNameToToken		proc	near
	uses	ax

	.enter

	mov	ax, dx				;ax <- index of file
	cmp	cl, VTNT_CONTEXT		;context?
	jne	done
	;
	; Convert the associated file list entry to a token
	;
	call	FileNameToToken
	jz	completelyDone
done:
	mov	dx, ax				;dx <- file token
completelyDone:
	.leave
	ret
ContextFileNameToToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileNameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a file list entry to its corresponding name array token

CALLED BY:	NameToToken(), VisTextDefineName()
PASS:		*ds:si - name array
		ax - list entry
RETURN:		carry - set if real name
		    ax - token of matching file name
		zero flag - set if token was not found
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 3/92		Initial version
	JM	3/18/94		zero flag returned so caller
				can do error checking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileNameToToken		proc	near
	uses	bx, cx, di

	dec	ax				;ax <- 0th entry is current file
	clc					;carry <- assume current
	js	quit				;branch if current file

	.enter

	mov	cl, VTNT_FILE			;cl <- VisTextNameType to match
	mov	bx, SEGMENT_CS
	mov	di, offset VTCountNamesCallback	;bx:di <- callback
	call	ElementArrayUsedIndexToToken
	jnc	nameNotFound
	or	bx, 1				; Clear ZF
	stc
	
almostDone:
	.leave
quit:
	ret

nameNotFound:
	sub	bx, bx				; Set ZF and clear CF.
	jmp	almostDone	

FileNameToToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTCountNamesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count matching names in a text object
CALLED BY:	ElementArrayGetUsedCount() via callback

PASS:		ds:di - ptr to VisTextNameArrayElement
		cl - VisTextNameType to match
		if VTNT_CONTEXT:
			dx - file token to match
RETURN:		carry - set if match
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VTCountNamesCallback	proc	far
	;
	; Is this the correct type of name?
	;
	cmp	ds:[di].VTNAE_data.VTND_type, cl
	jne	noMatch				;branch if not right type
	;
	; If counting files, we just need to check the type
	;
	cmp	cl, VTNT_FILE			;files or contexts?
	je	match				;branch if files
	;
	; If counting contexts, we need to make sure the file matches, too.
	;
	cmp	ds:[di].VTNAE_data.VTND_file, dx
	jne	noMatch				;branch if different file

match:
	stc					;carry <- element matches
	ret

noMatch:
	clc					;carry <- no match
	ret
VTCountNamesCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNameMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a name messge or string

CALLED BY:	UTILITY
PASS:		dx - chunk of message
RETURN:		cx:dx - ptr to string
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockNameMessage		proc	near
	uses	ax, bx, ds, si
	.enter

	mov	bx, handle TextTypeStrings
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, dx				;*ds:si <- string
	mov	dx, ds:[si]			;cx:dx <- ptr to string

	.leave
	ret
LockNameMessage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockNameMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a name message or string

CALLED BY:	UTILITY
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockNameMessage		proc	near
	uses	bx
	.enter

	mov	bx, handle TextTypeStrings
	call	MemUnlock

	.leave
	ret
UnlockNameMessage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNameNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification that the context/file name array changed

CALLED BY:	UTILITY
PASS:		*ds:si - text object
		ax - name token
		cl - VisTextNameType
		ch - VisTextNameChangeType
		dx - file index, if VTNT_CONTEXT
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNameNotification		proc	far
	uses	bx, bp		
	.enter	
	class	VisTextClass

	;
	; allocate a block to hold the notification data
	;
	push	ax, cx
	mov	ax, size VisTextNotifyNameChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	ax, 1
	call	MemInitRefCount
	call	MemLock
	mov	es, ax
	;
	; store the name type and token in the notification block
	;
	pop	{word}es:[VTNNC_type]
	pop	es:[VTNNC_index]
	mov	es:[VTNNC_fileIndex], dx	
	;
	; get and increment the name count variable, so that the
	; notification is unique
	;
	push	es
	mov	ax, segment idata
	mov	es, ax
	inc	es:nameCount
	mov	ax, es:nameCount
	pop	es	
	mov	es:[VTNNC_count], ax
	call	MemUnlock
		
;;; adapted from TA_SendNotification
		
	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes, mask VTNF_NAME
	mov	ax, 15-offset VTNF_NAME		; ax <- offset of name flag
						;  from high bit
	shl	ax				; ax <- offset of name block
	add	bp, ax	
	mov	ss:[bp].VTGNP_notificationBlocks, bx
	sub	bp, ax

	; make sure that we need to send the method -- set flags for
	; destination

EC <	call	T_AssertIsVisText					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	dx
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jz	notSuspended

	; object is suspended -- add flags

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
	or	ds:[bx].VTSD_notifications, mask VTNF_NAME

notSuspended:
	;;;
	;;; Controllers need to know whenever the name array changes,
	;;; regardless of whether the text object happens to be the
	;;; target at the time; e.g. when we, say, add a name in the
	;;; course of setting a hyperlink on a hotspot, the hyperlink
	;;; controller lists must be updated with the new name.
	;;;	-jenny 7/18/94
	;;;
;;;	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
;;;	jz	noTarget
	ornf	dx, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS

;;;noTarget:
	; set the flags so that the passed structure is used instead
	; of the one that would be created by GenNameNotify
	;
	ornf	dx, mask VTNSF_STRUCTURE_INITIALIZED or mask VTNSF_SEND_ONLY
	mov	ss:[bp].VTGNP_sendFlags, dx

	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	call	ObjCallInstanceNoLock
	add	sp, size VisTextGenerateNotifyParams

	.leave
	ret
SendNameNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDeleteName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a file or context name

CALLED BY:	MSG_VIS_TEXT_DELETE_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		- If deleting a file, then delete
				  associated contexts from name array.
				- Update the type run array.
				- FORCE_QUEUE the REMOVE_NAME msg. to
				  partially fix bug 6007

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDeleteName		proc	far	; MSG_VIS_TEXT_DELETE_NAME
	;
	; Suspend recalculation till we're done.
	;
	call	TextSuspend
	;
	; Convert the index to a name token
	;
	push	ds, si
	call	LockNameArray
	call	GetNameParams
	call	NameToToken			;ax <- name token
	LONG jz	couldntDelete			; Don't crash -- dynam
						; list and name array
						; might be out of synch.
EC <	ERROR_NC VIS_TEXT_NAME_CANT_MODIFY_CURRENT_FILE >
	cmp	cl, VTNT_FILE	
	je	dontNeedComputeFileToken	;already have file
						;token in ax
	call	ContextFileNameToToken		; dx <- file token

dontNeedComputeFileToken:
	call	UnlockNameArray
	mov	bx, ax				; bx <- file token
	cmp	cl, VTNT_FILE
	je	fileTokenInAX
	mov	bx, dx				; bx <- file token
fileTokenInAX:
	pop	ds, si

	cmp	cl, VTNT_FILE
	je	continueFileDeletion
	;
	; Delete the context and hyperlinks to it from the type
	; run array.
	;
	push	cx
	clr	cx				; flag for CHTDeleter
	call	ContextHyperlinkTypeDeleter	; Fix the type run and
						; element arrays for
						; deletion of a
						; context.
	pop	cx

continueFileDeletion:
	push	ax				; save name token

	;
	; If we're deleting a file, first delete any associated
	; contexts.
	;
	cmp	cl, VTNT_CONTEXT
	je	isContext
	;
	; Delete the hyperlinks to the file from the type run.
	; Note that we don't have to worry about deleting contexts
	; from the type run when we're deleting a file because
	; contexts are only defined in "*same file*," which cannot
	; be deleted.
	mov	cx, 1
	call	ContextHyperlinkTypeDeleter

	mov	cx, ax			;cx <- name token
	push	ds,si,es,bp		; Save text obj ptr
					; (A..C..D..Callback will not
					; cause the lmem heap to grow,
					; so it's ok to save ds:si -
					; jm)

	mov	dx, ds:[LMBH_handle]	; ^ldx:bp holds VisText 
	mov	bp, si			; for use by A..C..D..Callback
	call	LockNameArray
	push	bx
	mov	bx, cs			; assume same segment
	mov	di, offset AssociatedContextDeleteCallback
	call	ChunkArrayEnum
	pop	bx
	call	UnlockNameArray
	pop	ds,si,es,bp

	;
	; Delete the name
	;
isContext:
	pop	ax				; get name token
	mov	cx, ax				;cx <- token of name
	mov	ax, MSG_VIS_TEXT_REMOVE_NAME

	; Changed ObjCallInstanceNoLock to ObjMessage so that
	; I could use MF_FORCE_QUEUE.  This change attempts to
	; fix bug 6007 by ensuring that the NameArray doesn't
	; get an entry deleted before THelpControlDeleteFile's
	; call to change the currently selected file (which
	; causes THDCFileList to be updated) is processed.  Ask
	; J. Magasin about this fix.

	mov	bx, ds:[LMBH_handle]		; ^lbx:si = text object
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Send a notification out that stuff has changed
	;
	call	GetNameParams		; cl <- name type
					; dx <- file list index
	mov	ax, GIGS_NONE		; no list index for name
	mov	ch, VTNCT_REMOVE	; ch <- change type 
	call	SendNameNotification  	;*ds:si must point to text object

	;
	; Mark the object as dirty
	;
	call	TextMarkUserModified  ;*ds:si points to text instance
done:
	;
	; Put the unsuspend message on the queue so we won't redraw
	; till after all the hyperlink-deleting messages we've put on
	; the queue have been processed.
	;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_UNSUSPEND
	call	ObjMessage
	ret

couldntDelete:
	call	UnlockNameArray
	pop	ds, si
	jmp	done
VisTextDeleteName		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssociatedContextDeleteCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine used to delete associated contexts
		of a file that is being deleted.

CALLED BY:	ChunkArrayEnum via VisTextDeleteName
PASS:		*ds:si - name array of the VisText object
		ds:di  - array element being enumerated
		ax     - element size
		cx     - token of the file to be deleted
		^ldx:bp - VisText object
RETURN:		carry set to false
		messages sent to the text object to delete
		the associated contexts of the file (of list index dx)
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	2/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssociatedContextDeleteCallback	proc	far
	uses	cx
	.enter

	cmp	ds:[di].VTNAE_data.VTND_file, cx
	jne	done
	cmp	ds:[di].VTNAE_data.VTND_type, VTNT_CONTEXT
	jne	done

	call	ChunkArrayPtrToElement		;ax <- token of context
	mov	cx, ax				;cx <- token of name
	mov	bx, dx
	mov	si, bp				; ^lbx:si = VisText object
	mov	ax, MSG_VIS_TEXT_REMOVE_NAME	
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage

done:
	clc
	.leave
	ret
AssociatedContextDeleteCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContextHyperlinkTypeDeleter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a context and all hyperlinks associated with
		that context from the type run array and type element
		array of the current text object ("*same file*).

CALLED BY:	
PASS:		*ds:si	- text object
		cx	- 0 if the user is deleting one specific
			  context
			  1 if the user is deleting an entire file
			  (and hence all contexts for that file)
		ax	- token of the context that is being deleted
		bx	- token of the file for which this context
			  is defined

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	    EA(r) denotes the element array element corresponding to
            run array element r.  

    for each element r in the text object's type run array
        If EA(r).hyperlinkName = ax and EA(r).hyperlinkFile = bx
         then delete the hyperlink for r's range
        If EA(r).context = ax and bx = -1 ("-same file-")
         then delete the context for r's range


		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContextHyperlinkTypeDeleter	proc	near
	uses	ax,bx,cx,dx,si,di,ds

textObj		local	dword
contextToken	local	word
fileToken	local	word
contextOrFile	local	word
runArray	local	dword
raConsecElts	local	word
eltArray	local	dword
eltArrayVM	local	word
eltArrayElt	local	VisTextType
hyperlinkParams	local	VisTextSetHyperlinkParams
contextParams	local	VisTextSetContextParams

	.enter

	movdw	textObj, dssi		; Save text object.
	mov	contextToken, ax	;      context token
	mov	fileToken, bx		;      file token
	mov	contextOrFile, cx	;      flag

	call	LockTypeRunArray	; ds:si - first run array elt
					; cx - number of consecutive
					; elments
					; (-1 if all of them)
					; di - token for run array
					; routines
	mov	raConsecElts, cx
	movdw	runArray, dssi		; Save run array location.

	call	FarElementArrayLock	; *ds:si - elt array
					; bx - value to pass to EAUnlock
					;    0 if runs in same block
					;   !0 - VM mem handle
	movdw	eltArray, dssi		; Save element array location.
	mov	eltArrayVM, bx		; Save for unlocking

	movdw	dssi, runArray		; Load first run array element.
scan:
	mov	ax, ds:[si].TRAE_token	; Get element number for current
					; run from the run array.
	cmp	ax, CA_NULL_ELEMENT
	je	continue		; If EA(r) does not exist for
					; this r, then we're at the last	
					; run.
	movdw	dssi, eltArray
	mov	cx, ss
	lea	dx, eltArrayElt		; cx:dx stack space for CAGElt
	call	ChunkArrayGetElement	; Get elt corresponding to 
					; current run.  (GetElement is
					; slower because it locks the
					; array on every access.)
	;
	; See if current run is a hyperlink we should delete.
	;
	mov	dx, eltArrayElt.VTT_hyperlinkFile
	cmp	dx, fileToken
	jne	notLink
	cmp	contextOrFile, 1
	je	deleteHyperlink		; If deleting entire file,
					; then delete all links to
					; that file without checking
					; for context match.
	mov	dx, eltArrayElt.VTT_hyperlinkName
	cmp	dx, contextToken
	jne	notLink

deleteHyperlink:
	lea	cx, ss:hyperlinkParams.VTSHLP_range
	mov	ax, MSG_VIS_TEXT_SET_HYPERLINK
	mov	dx, (size VisTextSetHyperlinkParams)
	mov	ss:hyperlinkParams.VTSHLP_file, VIS_TEXT_CURRENT_FILE_TOKEN
	mov	ss:hyperlinkParams.VTSHLP_context, VIS_TEXT_NIL_CONTEXT_TOKEN
	mov	ss:hyperlinkParams.VTSHLP_flags, 
			(mask VTCF_TOKEN or mask VTCF_SHOWING_HYPERLINKS)
	push	di
	call	ContextHyperlinkTypeDeleterHelperCommon
	pop	di

	jmp	continue
notLink:
	;
	; See if current run is a context we should delete.
	;
	mov	dx, eltArrayElt.VTT_context
	cmp	dx, contextToken
	jne	continue
	cmp	fileToken, VIS_TEXT_CURRENT_FILE_TOKEN
	jne	continue

	lea	cx, ss:contextParams.VTSCXP_range
	mov	ax, MSG_VIS_TEXT_SET_CONTEXT
	mov	dx, (size VisTextSetContextParams)
	mov	ss:contextParams.VTSCXP_context, VIS_TEXT_NIL_CONTEXT_TOKEN
	mov	ss:contextParams.VTSCXP_flags, mask VTCF_TOKEN
	call	ContextHyperlinkTypeDeleterHelperCommon

continue:
	movdw	dssi, runArray		; Reload present run array
					; element.
	cmp	ds:[si].TRAE_position.WAAH_high, \
		TEXT_ADDRESS_PAST_END_HIGH
	je	done			; Check for last run.
	mov	cx, raConsecElts
	call	FarRunArrayNext		; Get next run array elt. 
	movdw	runArray, dssi		; Store new current run array elt.
	mov	raConsecElts, cx	; Store new number of consecutive elts.
	jmp	scan			

done:
	call	FarRunArrayUnlock	; Unlock the run array.	
	movdw	dssi, eltArray		
	mov	bx, eltArrayVM
	call	FarElementArrayUnlock	; Unlock the element array.

	.leave
	ret
ContextHyperlinkTypeDeleter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContextHyperlinkTypeDeleterHelperCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for deleting a context or
		its hyperlink from the type run array.

CALLED BY:	ContextHyperlinkTypeDeleter only
PASS:		cx	- offset of contextParams 
			  or hyperlinkParams depending
			  on di
		ax	- MSG_VIS_TEXT_SET_HYPERLINK or
			- MSG_VIS_TEXT_SET_CONTEXT
		dx	- size of VisTextSetContextParams or
			- size of VisTextSetHyperlinkParams
		inherits local variables of ContextHyperlinkTypeDeleter
RETURN:		range (local variable) modified
DESTROYED:	ds,si,ax,bx,cx,dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContextHyperlinkTypeDeleterHelperCommon	proc	near
	.enter	inherit	ContextHyperlinkTypeDeleter

	push	ax			; Save message.
	push	dx			; Save param size.
	;
	; Need start of this run.
	;
	movdw	dssi, runArray		; Point to current run.
	mov	ax, ds:[si].TRAE_position.WAAH_low
	clr	dx
	mov	dl, ds:[si].TRAE_position.WAAH_high
	push	bp
	mov	bp, cx
	movdw	ss:[bp].VTR_start, dxax
	pop	bp
	;
	; Figure out end of this run.
	;
EC <	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH >
EC <	ERROR_Z	VIS_TEXT_CANNOT_GO_BEYOND_LAST_ELEMENT			>
	push	cx
	mov	cx, raConsecElts
	call	FarRunArrayNext		; dx:ax <- start of next run
					;	 = end of this run
	pop	cx
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	je	lastRun			; Check if last run.
lastRun:
	push	bp
	mov	bp, cx
	movdw	ss:[bp].VTR_end, dxax	
	pop	bp
	;
	; Now delete the context or link for the range.
	;
	clr	bx			; for TA_GetTextRange
	movdw	dssi, textObj
	pop	dx			; Get size of params.
	pop	ax			; Get our message.
	push	bp
	mov	bp, cx			; NOTE: ss:bp should point
					;   to hyperlinkParams or
					;   contextParams by default,
					;   even though it was set
					;   to point just to the range
	call	TA_GetTextRange
	;
	; Tell the text obj to unset the hlink/context using 
	; MF_FORCE_QUEUE.  If no MF_F_Q, the type run array
	; gets mangled too soon, and our scan through it gets
	; all messed up.
	;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp

	.leave
	ret
ContextHyperlinkTypeDeleterHelperCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRenameName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a name (file or context)

CALLED BY:	MSG_VIS_TEXT_RENAME_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - VisTextNameCommonParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 3/92		Initial version
	JM	3/18/94		Added error checking after
				NameToToken call.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextRenameName		proc	far	; MSG_VIS_TEXT_RENAME_NAME
	;
	; Get the name and make sure it is unique
	;
	call	GetNameCheckUnique
	jnc	quit				;branch if name in use
	push	ds, si
	push	bx
	call	LockNameArray			;*ds:si <- name array
	;
	; Find the existing name and change it
	;
	push	cx
	call	GetNameParams
	call	NameToToken			;ax <- name token
EC <	ERROR_Z VIS_TEXT_NAME_NOT_FOUND_FOR_INDEX	;>
	pop	cx
EC <	ERROR_NC VIS_TEXT_NAME_CANT_MODIFY_CURRENT_FILE >
	call	NameArrayChangeName
	;
	; Free the text block we got earlier
	;
	call	UnlockNameArray
	pop	bx
	call	MemFree
	pop	ds, si
	;
	; Send a notification out that stuff has changed
	;
	call	GetNameParams		; cl <- VisTextNameType
					; ax <- name index
					; dx <- file index (if VTNT_CONTEXT)
	mov	ch, VTNCT_RENAME	; ch <- change type 
	call	SendNameNotification
	;
	; Mark the object as dirty
	;
	call	TextMarkUserModified
quit:
	ret
VisTextRenameName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameCheckUnique
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for a name and check for uniqueness

CALLED BY:	VisTextRenameName(), VisTextDefineName()
PASS:		*ds:si	= instance data for text object
		ss:bp	= VisTextNameCommonParams
RETURN:		carry	= set if not in use
		   es:di = ptr to name
		   cx = length of name
		   bx = handle of text block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Puts up an annoying DB informing the user that the name isn't
	unique, if necessary.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 3/92		Initial version
	jenny	8/17/94		Added check for empty/whitespace name
	jenny	8/28/94		Broke out GetNameFromObject, NameStringToToken
	jenny	11/ 2/94	Broke out DoNameErrorDialog
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameCheckUnique		proc	near
	uses	ax, dx, bp
	.enter
	;
	; Get a block holding the new name and make sure it's not an
	; empty string.
	;
	push	si
	movdw	bxdi, ss:[bp].VTNCP_object
	call	GetNameFromObject		; es:di <- ptr to string
	tst	cx
	jz	noName
	;
	; Make sure name consists of more than just whitespace and/or
	; punctuation.
	;
	push	ds
	segmov	ds, cs
	mov	si, offset cs:[emptyString]
	call	LocalCmpStringsNoSpace
	pop	ds
	je	whiteSpaceName
	pop	si
	;
	; See if the name is already defined
	;
	push	cx				;save string length
	call	NameStringToToken			;ax <- token
	pop	cx				;cx <- length of string
	cmp	ax, CA_NULL_ELEMENT		;new name?
	jne	nameDefined			;branch if not new name
	stc					;carry <- name not in use
done:
	.leave
	ret

	;
	; Put up annoying error message if name is empty, illegal, or
	; already defined.
	;    es:di - ptr to name
	;
whiteSpaceName:
	mov	dx, offset illegalNameString	;dx <- message to lock
	jmp	clearStack
noName:
	mov	dx, offset noNameString		;dx <- message to lock
clearStack:
	pop	si
	jmp	doDialog
nameDefined:
	mov	dx, offset nameDefinedString	;dx <- message to lock
doDialog:
	mov	ax, cs
	mov	cx, offset illegalNameContext
	call	DoNameErrorDialog
	;
	; Free the text block.
	;
	call	MemFree
	clc					;carry <- name in use
	jmp	done
GetNameCheckUnique		endp

LocalDefNLString	emptyString		<0>

LocalDefNLString	illegalNameContext	<"dbBadName",0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoNameErrorDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog box holding one of the TextTypeStrings

CALLED BY:	INTERNAL	GetNameCheckUnique

PASS:		es:di	= ptr to name
		dx	= offset of string
		ax:cx	= ptr to help context
		
RETURN:		nothing
DESTROYED:	bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 2/94    	Broke out of GetNameCheckUnique

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoNameErrorDialog	proc	near
	;
	; Just complain.
	;
		sub	sp, (size StandardDialogParams)
		mov	bp, sp			;ss:bp <- ptr to params
		mov	ss:[bp].SDP_customFlags, CDT_ERROR shl (offset CDBF_DIALOG_TYPE) or GIT_NOTIFICATION shl (offset CDBF_INTERACTION_TYPE)
		mov	ss:[bp].SDP_stringArg1.segment, es
		mov	ss:[bp].SDP_stringArg1.offset, di
		mov	ss:[bp].SDP_helpContext.segment, ax
		mov	ss:[bp].SDP_helpContext.offset, cx
		call	LockNameMessage
		movdw	ss:[bp].SDP_customString, cxdx
		call	UserStandardDialog
		call	UnlockNameMessage
		ret
DoNameErrorDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameFromObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text from the passed text object and lock it down.

CALLED BY:	INTERNAL	VisTextSetContextGivenNameText
				GetNameCheckUnique
	
PASS:		^lbx:di	= object holding name

RETURN:		es:di	= ptr to name string
		bx	= handle of locked block
		cx	= string length
DESTROYED:	ax
SIDE EFFECTS:
	Caller must unlock block when done with it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94    	Broke out of GetNameCheckUnique

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameFromObject	proc	near
		uses	si
		.enter
	;
	; Send off to get the text from the object into a freshly
	; allocated block.
	;
		mov	si, di			; ^lbx:si <- object
		clr	dx			; dx <- alloc new block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	bx, cx			; bx <- handle of block
		mov	cx, ax			; cx <- length of string
	;
	; Lock down the name.
	;
		call	MemLock
		mov	es, ax
		clr	di			; es:di <- ptr to new name
		.leave
		ret
GetNameFromObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameStringToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name array token for a name string.

CALLED BY:	INTERNAL	VisTextSetContextGivenNameText
				GetNameCheckUnique

PASS:		*ds:si	= VisText instance data
		es:di	= ptr to name string
		cx	= length of name string
RETURN:		ax	= token for name
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/28/94    	Broke out of GetNameCheckUnique

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameStringToToken	proc	near
		uses	bp
		.enter
		class	VisTextClass

		sub	sp, (size VisTextFindNameParams)
		mov	bp, sp				;ss:bp <- ptr to params
		mov	ss:[bp].VTFNP_size, cx		;pass string length
		mov	ss:[bp].VTFNP_name.segment, es
		mov	ss:[bp].VTFNP_name.offset, di	;pass ptr to string
		clr	ss:[bp].VTFNP_data.segment	;pass no buffer
		mov	ax, MSG_VIS_TEXT_FIND_NAME
		call	ObjCallInstanceNoLock
		add	sp, (size VisTextFindNameParams)
		.leave
		ret
NameStringToToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get common name parameters

CALLED BY:	UTILITY
PASS:		ss:bp - VisTextNameCommonParams
RETURN:		ax - list index
		cl - VisTextNameType
		dx - file index (if cl==VTNT_CONTEXT)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameParams		proc	near
	.enter

	mov	ax, ss:[bp].VTNCP_index
	mov	cl, ss:[bp].VTNCP_data.VTND_type
	mov	dx, ss:[bp].VTNCP_data.VTND_file

	.leave
	ret
GetNameParams		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextNameTokensToListIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert type name tokens to their list indices

CALLED BY:	MSG_VIS_TEXT_NAME_TOKENS_TO_LIST_INDICES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - VisTextNotifyTypeChange

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextNameTokensToListIndices	proc	far
				; MSG_VIS_TEXT_NAME_TOKENS_TO_LIST_INDICES

		segmov	es, ss, ax
		FALL_THRU TokensToNames
VisTextNameTokensToListIndices	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokensToNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert context/file tokens to the equivalent name list indices

CALLED BY:	GenTypeNotify()
PASS:		*ds:si - text object
		es:bp - VisTextNotifyTypeChange
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokensToNames		proc	far	
	uses	ax, bx, cx, dx, di, ds, si
	.enter

	call	LockNameArray
	push	bx
	mov	bx, SEGMENT_CS
	mov	di, offset VTCountNamesCallback	;bx:di <- callback routine
	;
	; Convert the hyperlink file, if any
	;
	mov	ax, es:[bp].VTNTC_type.VTT_hyperlinkFile
	mov	dx, ax				;dx <- file list token
	cmp	ax, CA_NULL_ELEMENT
	je	gotHFile
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	call	ElementArrayTokenToUsedIndex
gotHFile:
	inc	ax
	mov	es:[bp].VTNTC_index.VTT_hyperlinkFile, ax
	;
	; Convert the hyperlink context, if any
	;
	mov	ax, es:[bp].VTNTC_type.VTT_hyperlinkName
	cmp	ax, CA_NULL_ELEMENT
	je	gotHContext
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	ElementArrayTokenToUsedIndex
gotHContext:
	mov	es:[bp].VTNTC_index.VTT_hyperlinkName, ax
	;
	; Convert the context, if any
	;
	mov	ax, es:[bp].VTNTC_type.VTT_context
	cmp	ax, CA_NULL_ELEMENT
	je	gotContext
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	mov	dx, VIS_TEXT_CURRENT_FILE_TOKEN
	call	ElementArrayTokenToUsedIndex
gotContext:
	mov	es:[bp].VTNTC_index.VTT_context, ax

	pop	bx
	call	UnlockNameArray

	.leave
	ret

TokensToNames		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenToName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a context or file token to the equivalent
		name list index.

CALLED BY:	VisTextDefineName()
PASS:		*ds:si - text object
		ax - token to convert
		cl - VisTextNameType of token in ax
		if cl = VTNT_CONTEXT
			dx - file index for context token
RETURN:		ax - list index of token
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenToName		proc	far
	uses	bx, cx, dx, di, ds, si
	.enter

	call	LockNameArray
	push	bx
	mov	bx, SEGMENT_CS
	mov	di, offset VTCountNamesCallback	;bx:di <- callback routine
	;
	; If we're converting a context token, we must first map
	; its associated file index to a file token.
	;
	cmp	cl, VTNT_CONTEXT
	jne	notContext
	push	ax, cx
	mov	ax, dx				;ax <- file list index
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	call	FileNameToToken
	mov	dx, ax				;dx <- file token
	pop	ax, cx
notContext:
	;
	; Now convert our passed context or file token to an index.
	;
	cmp	ax, CA_NULL_ELEMENT
	je	gotToken
	call	ElementArrayTokenToUsedIndex
	;
	; If we're dealing with a file list index, we up it by one to
	; take account of the initial "same file" list entry.
	;
	cmp	cl, VTNT_FILE
	jne	gotToken
	inc	ax
gotToken:
	pop	bx
	call	UnlockNameArray

	.leave
	ret

TokenToName		endp

if FULL_EXECUTE_IN_PLACE
TextNameType ends
TextAttributes	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyperlinkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a hyperlink change

CALLED BY:	TypeChangeCommon() via ModifyRun()
PASS:		ss:bp - VisTextStype
		dx - token of file
		ax - token of context
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 9/92		updated, added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyperlinkCallback		proc	far
	mov	ss:[bp].VTT_hyperlinkFile, dx
	mov	ss:[bp].VTT_hyperlinkName, ax
	ret
SetHyperlinkCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetContextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a context change

CALLED BY:	TypeChangeCommon() via ModifyRun()
PASS:		ss:bp - VisTextType structure
		ax - token of context
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 9/92		updated, added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetContextCallback		proc	far
	mov	ss:[bp].VTT_context, ax
	ret
SetContextCallback		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TypeChangeCommon

DESCRIPTION:	Do a change for a type routine

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data (VisTextInstance)
	ss:bp - VisTextRange
	ax, dx - callback data
	di - offset of callback

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
TypeChangeCommon	proc	far

	call	UnHiliteAndFixupCharAttrRange
	push	bx				;save vm file

	push	ax
	mov	ax, offset FormattingString
	call	TU_StartChainIfUndoable
	pop	ax

	mov	cx, cs				;segment of callback
	;
	; modify the type run
	;
	mov	bx, OFFSET_FOR_TYPE_RUNS
EC <	call	ECCheckRun			;>
	call	ModifyRun
EC <	call	ECCheckRun			;>

	call	UpdateLastRunPositionByRunOffset
	call	TU_EndChainIfUndoable
	pop	bx
	call	ReflectChangeUpdateGeneric
	ret

TypeChangeCommon	endp

if FULL_EXECUTE_IN_PLACE
TextAttributes	ends
TextNameType segment resource
endif

TextAttributes	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetType -- MSG_VIS_TEXT_GET_TYPE
					    for VisTextClass

DESCRIPTION:	Return the type structure for the selected area.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size VisTextGetAttrParams (if called remotely)
	ss:bp - VisTextGetAttrParams structure
RETURN:
	ax - type token (0 if multiple)
	buffer - filled
	dx - VisTextTypeDiffs

DESTROYED:
	dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VTGT_Frame	struct
    VTGT_element	VisTextType <>

    VTGT_diffs		VisTextTypeDiffs

	; the following fields are pushed on the stack

    VTGT_passedFrame	word		;frame passed
VTGT_Frame	ends

VisTextGetType	proc	far	; MSG_VIS_TEXT_GET_TYPE
	class	VisTextClass

	push	si, ds

	; zero out return values

	test	ss:[bp].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	jnz	skipZero
	les	di, ss:[bp].VTGAP_return
	clr	ax
	stosw
CheckHack <(size VisTextTypeDiffs) eq 2>
skipZero:

	; allocate stack space and save vars

	movdw	dxax, ss:[bp].VTR_start
	mov	di, bp

	push	bp				;passed frame
	sub	sp, (size VTGT_Frame)-2
	mov	bp, sp

	; if no types then bail

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_TYPES
	LONG jz	noTypes

	; init locals

	clr	ss:[bp].VTGT_diffs		;no differences

	; multiple types

	xchg	di, bp
	call	FixupCharAttrRange
	clr	bx
	call	TA_GetTextRange

	; first fill the buffer with the first run

	push	si, ds
	movdw	dxax, ss:[bp].VTR_start
	cmpdw	dxax, ss:[bp].VTR_end		;if area selected then
	xchg	bp, di
	mov	bx, OFFSET_FOR_TYPE_RUNS
	jnz	getRight			;don't use run to the left

	; no area selected -- check for insertion element

	call	GetInsertionElement
	cmp	bx, CA_NULL_ELEMENT
	jz	noInsertionElement

	; insertion element exists - return it

	push	bx
	call	FarLockTypeRunArray
	pop	bx
	call	GetElement
	call	FarRunArrayUnlock
	pop	si, ds
	mov	di, ss:[bp].VTGT_passedFrame
	mov_tr	ax, bx				;ax = token
	jmp	oneRun

noInsertionElement:
	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	TSL_IsParagraphStart
	jc	getRight
	call	FarGetRunForPositionLeft	;returns bx = token
	jmp	common
getRight:
	call	FarGetRunForPosition		;returns bx = token
common:
	push	di
	mov	di, ss:[bp].VTGT_passedFrame
	test	ss:[di].VTGAP_flags, mask VTGAF_MERGE_WITH_PASSED
	pop	di
	jnz	skipGet2
	call	GetElement
skipGet2:

	; if (selectionEnd >= run.end) {
	;	selection in one run, return token
	; } else {
	;	selection in more than one run, return 0
	; }

	push	bx
	call	FarRunArrayNext		;dxax = next run position
	pop	bx
	call	FarRunArrayUnlock

	pop	si, ds
	mov	di, ss:[bp].VTGT_passedFrame
	cmpdw	dxax, ss:[di].VTR_end
	mov_tr	ax, bx				;ax = token
	jae	oneRun

	; use enumeration function to scan all runs

	mov	dx, offset GetTypeCallback
	xchg	di, bp
	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	EnumRunsInRange
	xchg	di, bp
	clr	ax				;return multiple tokens
oneRun:

	; fill the destination buffer

	segmov	ds, ss				;ds:si = source
	mov	si, bp
	les	di, ss:[di].VTGAP_attr		;es:di = dest
	mov	cx, (size VisTextType)/2
	rep	movsw

	mov	dx, ss:[bp].VTGT_diffs		;dx <- VisTextTypeDiffs

	; recover local space

done:
	add	sp, (size VTGT_Frame)-2
	pop	bp

	pop	si, ds

	ret

	;
	; This text object has no types -- return no links no contexts
	;
noTypes:
	les	di, ss:[di].VTGAP_attr
	add	di, (offset VTT_hyperlinkName)	;es:di <- ptr to return buffer
	mov	ax, -1
	stosw
	stosw
	stosw
CheckHack <(size VTT_hyperlinkName)+(size VTT_hyperlinkFile)+(size VTT_context) eq 6>
	jmp	done

VisTextGetType	endp

;
; NOTE: GetTypeCallback() *must* be in the same resource as EnumRunsInRange(),
; as it does a near callback.
;
COMMENT @----------------------------------------------------------------------

FUNCTION:	GetTypeCallback

DESCRIPTION:	Mark the differences between the given type and the base
		type

CALLED BY:	INTERNAL -- Callback from EnumRunsInRange
				(from VisTextGetType)

PASS:
	ss:bp - element from run
	ss:di - VTGT_Frame

RETURN:
	cx - updated

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
GetTypeCallback	proc	near

	mov	cx, ss:[di].VTGT_diffs		;cx <- VisTextTypeDiffs

	; compare hyperlinks

	mov	ax, ss:[bp].VTT_hyperlinkFile
	cmp	ax, ss:[di].VTT_hyperlinkFile
	jnz	linkDifferent
	mov	ax, ss:[bp].VTT_hyperlinkName
	cmp	ax, ss:[di].VTT_hyperlinkName
	jz	linkSame
linkDifferent:
	ornf	cx, mask VTTD_MULTIPLE_HYPERLINKS
linkSame:

	; compare contexts

	mov	ax, ss:[bp].VTT_context
	cmp	ax, ss:[di].VTT_context
	jz	contextSame
	ornf	cx, mask VTTD_MULTIPLE_CONTEXTS
contextSame:
	mov	ss:[di].VTGT_diffs, cx		;save new diffs

;---

	ret

GetTypeCallback	endp

TextAttributes	ends

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextTypeAdd -- MSG_VIS_TEXT_ADD_TYPE for VisTextClass

DESCRIPTION:	Add a given type to the type array and initialize its
		reference count to one.

	*** Note: Calling this method on a text object that does not have
	***	  multiple types will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size VisTextType (if callem remotely)
	ss:bp - VisTextType

RETURN:
	ax - type token

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextTypeAdd	proc	far	; MSG_VIS_TEXT_ADD_TYPE
	class	VisTextClass

	call	LockTypeRunArray

EC <	call	ECCheckType						>

	call	AddElement

	call	FarRunArrayUnlock

	ret

VisTextTypeAdd	endp

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextTypeRemove -- MSG_VIS_TEXT_ADD_TYPE for VisTextClass

DESCRIPTION:	Remove a given type from the type array.

	*** Note: Calling this method on a text object that does not have
	***	  multiple types will result in a fatal error.

PASS:
	*ds:si - instance data (VisTextInstance)

	cx - token to remove

RETURN:
	ax - type token

DESTROYED:
	dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextTypeRemove	proc	far	; MSG_VIS_TEXT_REMOVE_TYPE
	class	VisTextClass

	call	LockTypeRunArray

	call	RemoveElement

	call	FarRunArrayUnlock

	ret

VisTextTypeRemove	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TypeRunCopynames

DESCRIPTION:	Copy names referenced by element

CALLED BY:	TA_CopyRunToTransfer

PASS:
	ss:bp - blah...

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
if 0
TA_CopyRunToTransfer	proc	near

	; if type then copy all name names within

	mov	ax, ss:[bp].TCF_testRunOffset
	cmp	ax, offset VTI_types
	jnz	notTypes

	mov	ax, ss:[bp].VTT_hyperlinkName
	call	CopyName
	mov	ss:[bp].VTT_hyperlinkName, ax
	mov	ax, ss:[bp].VTT_hyperlinkFile
	call	CopyName
	mov	ss:[bp].VTT_hyperlinkFile, ax
	mov	ax, ss:[bp].VTT_context
	call	CopyName
	mov	ss:[bp].VTT_context, ax
	ret
notTypes:

	; if charAttr then copy name and special case if name already exists

	cmp	ax, offset VTI_charAttrs
	jnz	notCharAttrs

	mov	bx, ss:[bp].VTS_name
	call	CopyCharAttrSheet
	mov	ss:[bp].VTS_name, bx
	call	CopyName
	ret
notCharAttrs:

	; if paraAttr then copy name and special case if name already exists

	cmp	ax, offset VTI_graphics
	jnz	notParaAttrs

	mov	bx, ss:[bp].VTR_name
	call	CopyName
	mov	ss:[bp].VTR_name, ax
notParaAttrs:
	ret

TA_CopyRunToTransfer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyName

DESCRIPTION:	Copy a name from one element array to another

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - name (in source)
	ss:bp - TransCommonFrame

RETURN:
	ax - name (in destination)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
CopyName	proc	near

	lea	dx, ss:[bp].TCF_name
	call	LoadNameInSource

	; see if the name exists in the destination

	lea	dx, ss:[bp].TCF_name
	call	FindNameInDest
	jc	done

	lea	dx, ss:[bp].TCF_name
	call	AddNameInDest
done:
	ret

CopyName	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadNameInSource

DESCRIPTION:	Find a name in the source names

CALLED BY:	INTERNAL

PASS:
	ss:bp - TransCommonFrame
	ss:dx - buffer for name
	ax - name token

RETURN:
	ss:[bp].TCF_name - set

DESTROYED:
	ax, bx, cx, dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
LoadNameInSource	proc	near
	call	ss:[bp].TCF_loadSourceNames
	mov	cx, ss
	push	bp
	mov_tr	bp, ax
	call	FindNameByTokenCommon
	pop	bp
	ret

LoadNameInSource	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindNameInDest

DESCRIPTION:	Find a name in the destination name array

CALLED BY:	INTERNAL

PASS:
	ss:bp - TransCommonFrame
	ss:dx - name

RETURN:
	buffer - filled in found
	carry - set if found
	ax - token in dest if found (or 0 if types differ)

DESTROYED:
	bx, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
FindNameInDest	proc	near
	mov	bx, dx
	push	ss:[bx].VTN_type
	mov	ss:[bp].TCF_findNameParams.VTFNP_name.segment, ss
	add	dx, offset VTN_string
	mov	ss:[bp].TCF_findNameParams.VTFNP_name.offset, dx
	mov	ss:[bp].TCF_findNameParams.VTFNP_size, 0
	mov	ss:[bp].TCF_findNameParams.VTFNP_return.segment, ss
	lea	ax, ss:[bp].TCF_findNameReturn
	mov	ss:[bp].TCF_findNameParams.VTFNP_return.offset, ax

	call	ss:[bp].TCF_loadDestNames
	push	bp
	lea	bp, ss:[bp].TCF_findNameParams
	call	FindNameCommon
	pop	bp
	pop	ax			;ax = type passed
	jnc	done

	; found name -- test type

	cmp	ax, ss:[bp].TCF_findNameReturn.VTFNR_type
	mov	ax, 0
	jnz	doneGood
	mov	ax, ss:[bp].TCF_findNameReturn.VTFNR_token
doneGood:
	stc
done:
	ret

FindNameInDest	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddNameInDest

DESCRIPTION:	Add a name in the destination name array

CALLED BY:	INTERNAL

PASS:
	ss:bp - TransCommonFrame
	ss:dx - name

RETURN:
	ax - name token

DESTROYED:
	bx, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
AddNameInDest	proc	near

	; set up parameters to AddNameCommon

	mov	bx, dx
	mov	ax, ss:[bx].VTN_type
	mov	ss:[bp].TCF_addNameParams.VTANP_type, ax
	mov	ss:[bp].TCF_addNameParams.VTANP_flags, 0
	mov	ax, ss:[bx].VTN_data[0]
	mov	ss:[bp].TCF_addNameParams.VTANP_data[0], ax
	mov	ax, ss:[bx].VTN_data[1]
	mov	ss:[bp].TCF_addNameParams.VTANP_data[1], ax
	mov	ax, ss:[bx].VTN_data[2]
	mov	ss:[bp].TCF_addNameParams.VTANP_data[2], ax
	mov	ax, ss:[bx].VTN_data[3]
	mov	ss:[bp].TCF_addNameParams.VTANP_data[3], ax
	mov	ss:[bp].TCF_addNameParams.VTANP_name.segment, ss
	add	dx, offset VTN_string
	mov	ss:[bp].TCF_addNameParams.VTANP_name.offset, dx
	mov	ss:[bp].TCF_addNameParams.VTANP_size, 0

	call	ss:[bp].TCF_loadDestNames
	push	bp
	lea	bp, ss:[bp].TCF_addNameParams
	call	AddNameCommon
	pop	bp
EC <	ERROR_NC	NAME_SHOULD_NOT_HAVE_EXISTED			>

	ret

AddNameInDest	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckType

DESCRIPTION:	Make sure that a VisTextType structure is legal

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance
	ss:bp - VisTextType

RETURN:
	none

DESTROYED:
	none -- FLAGS PRESERVED

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckType	proc	near		uses ax, bx, cx, di, es
	.enter
	pushf

	; reference count -- must be <= 10000

	tst	ss:[bp].VTT_meta.REH_refCount.WAAH_high
	ERROR_NZ	VIS_TEXT_TYPE_HAS_REF_COUNT_OVER_10000
	cmp	ss:[bp].VTT_meta.REH_refCount.WAAH_low, 10000
	ERROR_A	VIS_TEXT_TYPE_HAS_REF_COUNT_OVER_10000

	popf
	.leave
	ret

ECCheckType	endp

endif

TextNameType ends
