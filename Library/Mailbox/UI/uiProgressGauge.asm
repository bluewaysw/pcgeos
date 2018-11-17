COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiProgressGauge.asm

AUTHOR:		Adam de Boor, Nov 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/29/94		Initial revision


DESCRIPTION:
	Implementation of the MailboxProgressGauge object and the little
	classes it uses.
		

	$Id: uiProgressGauge.asm,v 1.1 97/04/05 01:19:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment resource

	MailboxProgressGaugeClass
	MailboxPagesClass

MailboxClassStructures	ends

if	MAILBOX_PERSISTENT_PROGRESS_BOXES

UIProgressCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset display to base state.

CALLED BY:	MSG_MPG_RESET
PASS:		*ds:si	= MailboxProgressGauge object
		ds:di	= MailboxProgressGaugeInstance
		cx	= FALSE to keep the same progress indicators
			= TRUE to destroy existing progress indicators
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	text & page objects emptied, percentage object 0'd

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGReset	method dynamic MailboxProgressGaugeClass, MSG_MPG_RESET
		.enter
EC <		jcxz	cxIsOk						>
EC <		Assert	e, cx, TRUE					>
EC <cxIsOk:								>

		mov	bx, cx
		push	ds:[di].MPGI_bytes
		push	ds:[di].MPGI_graphic
		push	ds:[di].MPGI_pages
		push	ds:[di].MPGI_percent
		mov	si, ds:[di].MPGI_text

		jcxz	messWithObjects
	;
	; Zero the pointers to the component objects, since we're about to biff
	; them all.
	;
		clr	ax, ds:[di].MPGI_text, \
			    ds:[di].MPGI_percent, \
			    ds:[di].MPGI_pages, \
			    ds:[di].MPGI_graphic

messWithObjects:
		tst	si
		jz	zeroPercent
		
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	tellObject

zeroPercent:
		pop	si
		tst	si
		jz	nukePages
		clr	cx, bp
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	tellObject

nukePages:
		pop	si
		tst	si
		jz	nukeGraphic
		
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	tellObject

nukeGraphic:
		pop	si
		tst	si
		jz	nukeBytes
		
		clr	cx			; no moniker, please
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		call	tellObject
nukeBytes:
		pop	si
		tst	si
		jz	done
		
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	tellObject

done:
		.leave
		ret

tellObject:
		tst	bx
		jz	usePassedMsg
		mov	ax, MSG_GEN_DESTROY
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bp, mask CCF_MARK_DIRTY
usePassedMsg:
		call	ObjCallInstanceNoLock
		retn
MPGReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or update the object indicated by the progress type

CALLED BY:	MSG_MPG_SET_PROGRESS
PASS:		*ds:si	= MailboxProgressGauge object
		ds:di	= MailboxProgressGaugeInstance
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
setProgressRouts	nptr.near	MPGSetString,
					MPGSetPercentage,
					MPGSetPages,
					MPGSetGraphic,
					MPGSetBytes
MPGSetProgress	method dynamic MailboxProgressGaugeClass, MSG_MPG_SET_PROGRESS
		.enter
		test	ss:[bp].MPBSPA_action, mask MPA_REPLACE
		jz	setNew
	;
	; Nuke all objects but the one we're about to set.
	;
		mov	bx, first MailboxProgressType
resetLoop:
		cmp	bx, ss:[bp].MPBSPA_type
		je	nextType
	;
	; Not the one being set, so see if we have an object in this slot.
	;
		DerefDI	MailboxProgressGauge
		push	si, bp
		clr	si
		xchg	si, ds:[di].MPGI_text[bx]
		tst	si
		jz	popNextType
	;
	; We do. Destroy it, please.
	;
		mov	dl, ss:[bp].MPBSPA_action.low
		andnf	dl, mask MPA_UPDATE_MODE
		mov	bp, mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_DESTROY
		call	ObjCallInstanceNoLock
popNextType:
		pop	si, bp
nextType:
		inc	bx
		inc	bx
		cmp	bx, MailboxProgressType
		jb	resetLoop
setNew:
	;
	; Now set the new value.
	;
		mov	bx, ss:[bp].MPBSPA_type
		Assert	etype, bx, MailboxProgressType
		Assert	bitClear, bx, 1
		call	cs:[setProgressRouts][bx]
		.leave
		ret
MPGSetProgress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the string in the string object.

CALLED BY:	(INTERNAL) MPGSetProgress
PASS:		*ds:si	= MailboxProgressGauge
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGSetString	proc	near
		class	MailboxProgressGaugeClass
		.enter
		mov	bx, offset MPGI_text
		call	MPGEnsureObject
		mov	dx, ss:[bp].MPBSPA_cx
		mov	bp, ss:[bp].MPBSPA_dx
		clr	cx
	;
	; See if the containing block is lmem. If so, we've got an optr
	; and perform the replace on that basis.
	;
		mov	bx, dx
		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
		call	MemGetInfo
		test	ax, mask HF_LMEM
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		jnz	replaceAll
	;
	; Not lmem. The text's in a block. 
	;
		call	MemLock
		mov	dx, ax			; dx:bp <- fptr
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
replaceAll:
		push	ax
		call	ObjCallInstanceNoLock
		pop	ax
	;
	; Unlock the block, if we locked it down.
	;
		cmp	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		jne	done
		call	MemUnlock
done:
		.leave
		ret
MPGSetString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetPercentage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the percentage complete

CALLED BY:	(INTERNAL) MPGSetProgress
PASS:		*ds:si	= MailboxProgressGauge
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGSetPercentage proc	near
		class	MailboxProgressGaugeClass
		.enter
		mov	bx, offset MPGI_percent
		call	MPGEnsureObject
		mov	cx, ss:[bp].MPBSPA_cx
		clr	bp
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjCallInstanceNoLock
		.leave
		ret
MPGSetPercentage endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current page & total pages

CALLED BY:	(INTERNAL) MPGSetProgress
PASS:		*ds:si	= MailboxProgressGauge
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGSetPages	 proc	near
		class	MailboxProgressGaugeClass
		.enter
		mov	bx, offset MPGI_pages
		call	MPGEnsureObject
		mov	cx, ss:[bp].MPBSPA_cx
		mov	dx, ss:[bp].MPBSPA_dx
		mov	ax, MSG_MP_SET_PAGE
		call	ObjCallInstanceNoLock
		.leave
		ret
MPGSetPages 	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the number of bytes

CALLED BY:	(INTERNAL) MPGSetProgress
PASS:		*ds:si	= MailboxProgressGauge
		ss:bp	= MPBSetProgressArgs
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGSetBytes	 proc	near
		class	MailboxProgressGaugeClass
		.enter
		mov	bx, offset MPGI_bytes
		call	MPGEnsureObject
		mov	cx, ss:[bp].MPBSPA_cx
		mov	dx, ss:[bp].MPBSPA_dx
		mov	ax, MSG_MP_SET_BYTES
		call	ObjCallInstanceNoLock
		.leave
		ret
MPGSetBytes 	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGSetGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set what's displayed by the graphic progress indicator

CALLED BY:	(INTERNAL) MPGSetProgress
PASS:		*ds:si	= MailboxProgressGauge
		ss:bp	= MPBSetProgressArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGSetGraphic	proc	near
		class	MailboxProgressGaugeClass
		.enter
		mov	bx, offset MPGI_graphic
		call	MPGEnsureObject
		mov	cx, ss:[bp].MPBSPA_cx
		mov	dx, ss:[bp].MPBSPA_dx
			CheckHack <offset MPA_UPDATE_MODE eq 0>
		mov	bp, ss:[bp].MPBSPA_action
		andnf	bp, mask MPA_UPDATE_MODE
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		call	ObjCallInstanceNoLock
		.leave
		ret
MPGSetGraphic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGEnsureObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch or create an object

CALLED BY:	
PASS:		*ds:si	= MailboxProgressGauge
		bx	= offset of instance variable pointing to object
RETURN:		*ds:si	= object
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
mpgKidClasses	fptr.ClassStruct	GenTextClass,
					GenValueClass,
					MailboxPagesClass,
					GenGlyphClass,
					MailboxPagesClass

mpgKidInitRoutines nptr.near		MPGInitializeText,
					MPGInitializePercentage,
					MPGInitializePages,
					MPGInitializeGraphic,
					MPGInitializePages

MPGEnsureObject	proc	near
		class	MailboxProgressGaugeClass
		.enter
		DerefDI	MailboxProgressGauge
		mov	ax, ds:[di+bx]
		tst	ax
		jz	create
		mov_tr	si, ax
		jmp	done

create:
		push	cx, dx, bp		; save more registers, please
	;
	; Instantiate an object of the proper class.
	;
		push	es, si
		push	bx
		sub	bx, offset MPGI_text
		shl	bx
		les	di, cs:[mpgKidClasses][bx]
		mov	bx, ds:[LMBH_handle]
		call	ObjInstantiate
	;
	; Common initialization:
	; 	- all of these things are read-only
	; 	- they should expand their width to fit their parent
	;
		mov	ax, MSG_GEN_SET_ATTRS
		mov	cx, mask GA_READ_ONLY
		call	ObjCallInstanceNoLock

		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	MPGAddHint
	;
	; Call the right routine to initialize it.
	;
		pop	bx			; bx <- instvar offset
		push	bx
		call	cs:[mpgKidInitRoutines][bx-MPGI_text]
		mov	dx, si
		pop	bx
		pop	es, si
	;
	; Store the thing away.
	;
		DerefDI	MailboxProgressGauge
		mov	ds:[di+bx], dx
	;
	; Add it as our last generic child.
	;
		mov	cx, ds:[LMBH_handle]
		mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
	;
	; Set the thing usable, but update on the queue, so caller has a
	; chance to set its value.
	;
		mov	si, dx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		
		pop	cx, dx, bp		; retrieve saved regs
done:
		
		.leave
		ret
MPGEnsureObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGAddHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a hint with no extra data to an object.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= object
		ax	= hint to add
RETURN:		nothing
DESTROYED:	bx, cx
SIDE EFFECTS:	the usual

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGAddHint	proc	near
		.enter
		clr	cx
		call	ObjVarAddData
		.leave
		ret
MPGAddHint	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGInitializeText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a newly-created text object for use as a progress
		indicator

CALLED BY:	(INTERNAL) MPGEnsureObject
PASS:		*ds:si	= read-only GenText object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We mark the thing as being never-scrollable, but allow it
		to be multiple lines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGInitializeText proc	near
		.enter
		mov	ax, ATTR_GEN_TEXT_NEVER_MAKE_SCROLLABLE
		call	MPGAddHint

		mov	ax, HINT_TEXT_NO_FRAME
		call	MPGAddHint
		.leave
		ret
MPGInitializeText endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGInitializePercentage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a newly-created GenValue for use as a progress
		indicator

CALLED BY:	(INTERNAL) MPGEnsureObject
PASS:		*ds:si	= read-only GenValue object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGInitializePercentage proc	near
		.enter
		mov	ax, HINT_VALUE_ANALOG_DISPLAY
		call	MPGAddHint
		mov	ax, HINT_VALUE_MERGE_ANALOG_AND_DIGITAL_DISPLAYS
		call	MPGAddHint
		mov	cl, GVDF_PERCENTAGE
		mov	ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
		call	ObjCallInstanceNoLock
		mov	dx, 100
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	ObjCallInstanceNoLock
		.leave
		ret
MPGInitializePercentage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGInitializePages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a read-only MailboxPages object for displaying the
		number of pages taken care of.

CALLED BY:	(INTERNAL) MPGEnsureObject
PASS:		*ds:si	= MailboxPages object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGInitializePages proc	near
		.enter
	;
	; Do same as for string display...
	; 
		call	MPGInitializeText
	;
	; But make it center-justified.
	;
		mov	ax, ATTR_GEN_TEXT_DEFAULT_PARA_ATTR
		mov	cx, size VisTextDefaultParaAttr
		call	ObjVarAddData
		mov	{VisTextDefaultParaAttr}ds:[bx],
			(VIS_TEXT_INITIAL_PARA_ATTR and \
			 not (mask VTDPA_JUSTIFICATION)) or \
			 (J_CENTER shl offset VTDPA_JUSTIFICATION)
		.leave
		ret
MPGInitializePages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGInitializeGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a newly-created GenGlyph for use as a progress
		indicator

CALLED BY:	(INTERNAL) MPGEnsureObject
PASS:		*ds:si	= read-only GenGlyph object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGInitializeGraphic proc	near
		.enter
		mov	ax, HINT_CENTER_MONIKER
		call	MPGAddHint
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	MPGAddHint
		.leave
		ret
MPGInitializeGraphic endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPSetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the contents of the page progress indicator from the
		passed page numbers.

CALLED BY:	MSG_MP_SET_PAGE
PASS:		*ds:si	= MailboxPages object
		ds:di	= MailboxPagesInstance
		cx	= current page
		dx	= total pages (0 if none)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPSetPage	method dynamic MailboxPagesClass, MSG_MP_SET_PAGE
curPageStr	local	word
totPageStr	local	word
		.enter
	;
	; Convert the numbers to strings, please.
	;
		call	MPConvertPage
		mov	ss:[curPageStr], ax
		mov	cx, dx
		call	MPConvertPage
		mov	ss:[totPageStr], ax
	;
	; Now copy in the proper template, based on whether we have a total
	; number of pages.
	;
		mov	bx, offset uiPageNTemplate
		tst	dx
		jz	copyTemplate
		mov	bx, offset uiPageNOfMTemplate
copyTemplate:
		call	MPMangleTemplate
		.leave
		ret
MPSetPage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPMangleTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mangle the passed template string, replacing \1 with
		the string whose handle is in string1 and \2 with the
		string whose handle is in string2, then set the result
		as the entire text of the object

CALLED BY:	(INTERNAL) MPSetPage, MPSetBytes
PASS:		*ds:si	= object
		bx	= chunk handle of template string in ROStrings
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPMangleTemplate proc	near
string1		local	word
string2		local	word
		.enter	inherit
		push	si
		mov	si, bx
		mov	bx, handle uiPageNTemplate
		call	UtilCopyChunk		; *ds:si <- chunk
	;
	; Run through the characters of the template, looking for \1 or \2
	; and replacing them with the appropriate string when we find them.
	;
		segmov	es, ds

		mov	di, si			; save chunk handle
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
DBCS <		shr	cx						>
copyLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '\1'
		je	insertOne
		LocalCmpChar	ax, '\2'
		je	insertTwo
nextChar:
		loop	copyLoop
	;
	; Call our superclass to use the newly-constructed string as the
	; text.
	;
		pop	si			; *ds:si <- MP
		push	bp
		mov	bp, di
		mov	dx, ds:[LMBH_handle]
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Free the three chunks we used to do all this.
	;
		mov_tr	ax, di
		call	LMemFree
		mov	ax, ss:[string1]
		tst	ax
		jz	freeTwo
		call	LMemFree
freeTwo:
		mov	ax, ss:[string2]
		tst	ax
		jz	done
		call	LMemFree
done:
		.leave
		ret

insertOne:
		mov	bx, ss:[string1]
		jmp	insertCommon
insertTwo:
		mov	bx, ss:[string2]

insertCommon:
	;
	; Insert one of the strings at the current location.
	; *ds:bx	= string to insert
	; ds:si		= beyond the placeholder that got us here
	; cx		= # chars remaining in template, including placeholder
	;
	; Point back to the \1 or \2 and compute its offset from the start
	; of the string.
	;
		LocalPrevChar	dssi
		sub	si, ds:[di]		; si <- offset from start

		push	cx			; save # remaining chars
	;
	; Compute the size of the string to insert. The string is *not* null-
	; terminated.
	;
		ChunkSizeHandle ds, bx, cx
	;
	; Reduce the number of chars to insert by 1 to account for the place-
	; holder we're overwriting.
	;
DBCS <		dec	cx						>
		dec	cx
	;
	; Insert that much space.
	; 
		xchg	bx, si			; bx <- offset, *ds:si <- src
		mov	ax, di			; *ds:ax <- affected chunk
		call	LMemInsertAt
	;
	; Now copy the source chunk into the space just created.
	;
		push	di
		add	bx, ds:[di]
		mov	di, bx			; es:di <- dest for copy

		mov	si, ds:[si]
DBCS <		inc	cx			; add back in the char	>
		inc	cx			;  we removed before the insert
		rep	movsb
		mov	si, di			; ds:si <- char after place-
						;  holder
		pop	di			; *ds:di <- dest chunk
		pop	cx			; cx <- # chars left
		jmp	nextChar
MPMangleTemplate endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPConvertPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an integer to a non-null-terminated string in a chunk

CALLED BY:	(INTERNAL) MPSetPage
PASS:		ds	= lmem block in which to store the result
		cx	= number to convert
RETURN:		*ds:ax	= chunk
DESTROYED:	es, if pointing to ds on entry
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPConvertPage	proc	near
		uses	dx, cx
		.enter
		mov	dx, cx
		clr	cx
		call	MPConvertNum
		.leave
		ret
MPConvertPage 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPConvertNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a 32-bit number into a string in an lmem chunk

CALLED BY:	(INTERNAL) MPSetBytes, MPConvertPage
PASS:		ds	= lmem block in which to store the result
		cxdx	= 32-bit unsigned number to convert
RETURN:		*ds:ax	= chunk
DESTROYED:	cx, dx
		es, if pointing to ds on entry
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPConvertNum	proc	near
		uses	es, di, bx
		.enter
	;
	; Allocate a max-sized buffer.
	;
		push	cx
		mov	cx, UHTA_NO_NULL_TERM_BUFFER_SIZE
		clr	al
		call	LMemAlloc
	;
	; Point to the buffer and format the number into it.
	;
		mov_tr	bx, ax
		mov	di, ds:[bx]
		segmov	es, ds
		pop	ax
		xchg	ax, dx		; dxax <- num to format
		clr	cx		; cx <- flags (don't terminate, and
					;  don't add leading zeroes)
		call	UtilHex32ToAscii
DBCS <		shl	cx, 1		; cx = size in bytes		>
	;
	; Shrink the buffer to fit.
	;
		mov	ax, bx
		call	LMemReAlloc
		.leave
		ret
MPConvertNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPSetBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_MP_SET_BYTES
PASS:		*ds:si	= MailboxPages object
		ds:di	= MailboxPagesInstance
		cxdx	= # bytes
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPSetBytes	method dynamic MailboxPagesClass, MSG_MP_SET_BYTES
numBytes	local	word
junk		local	word
		.enter
	;
	; Initialize the string vars to 0, in case none needed.
	;
		clr	ax
		mov	ss:[numBytes], ax
		mov	ss:[junk], ax
	;
	; If there's only 1 byte, use a special "template"
	;
		mov	bx, offset uiOneByteTemplate
		cmpdw	cxdx, 1
		je	haveTemplate
	;
	; Else convert the number of bytes to a string and use the other
	; template.
	; 
		call	MPConvertNum
		mov	ss:[numBytes], ax
		mov	bx, offset uiBytesTemplate
haveTemplate:
	;
	; Mangle the template and adjust our text.
	;
		call	MPMangleTemplate
		.leave
		ret
MPSetBytes	endm


UIProgressCode	ends

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
