COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Message
FILE:		messageMoniker.asm

AUTHOR:		Adam de Boor, May 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/12/94		Initial revision


DESCRIPTION:
	Functions for creating a moniker for a message.
		

	$Id: messageMoniker.asm,v 1.1 97/04/05 01:20:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MessageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCreateMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a moniker for a message & one or more of its addresses

CALLED BY:	(EXTERNAL) MGSetMessageCommon, MLGenDynamicListQueryItemMoniker
PASS:		ds	= locked lmem/object block in which to place the 
			  moniker
		dxax	= MailboxMessage
		cx	= TalID of addresses to include, 0 => all (unsent)
			  addresses. This is ignored if the message is in
			  the inbox
		bx	= MessageMonikerFlags
RETURN:		*ds:ax	= gstring moniker (DC_TEXT)
DESTROYED:	nothing
SIDE EFFECTS:	this may cause the lmem block, or chunks within it, to move

PSEUDO CODE/STRATEGY:
		- if sizes not computed yet:
		    - ask app object for a gstate for computation purposes
		    - first line is 45 chars (subject) + 16 chars (date/time)
		    - subsequent lines begin 3 chars in and extends to end of
		      first line
		    - record rounded GFMI_MAX_ADJUSTED_HEIGHT
		    - destroy gstate
		- create temporary lmem block, create gstring in temp block
		- set first-field clipping rectangle
		- if transport local:
		    - if MMF_ALL_VIEW, draw app name from token as first string
		      at 0,0
		    - else, draw first line of subject as first string
		      (want subroutine that, when given a chunk will return the
		      start & # chars to the EOS or \r)
		- else
		    - if MMF_ALL_VIEW, get string for transport+medium of
		      message and draw that at 0,0, followed by ": " at CP
		    - else move to 0,0
		    - draw 1st line of subject at cp
		- remove clip rect
		- format & draw message date & time in second field of first
		  line
		- if !local:
		    - set cury to line height
		    - foreach marked (if non-z search talID)/non-dup (if z 
		      search talID), unsent address:
			- subroutine:
			    - set clip rect from 3-chars-in, cury to
			      1st-line len, cury+line-height
			    - draw "To: " at 3-chars-in, cury
			    - draw 1st line of user addr at CP
			    - cury += line-height
			- if talID==0:
			    - foreach duplicate:
				- call subroutine for it
		- else if MMF_ALL_VIEW:
		    - set clip rect from 3-chars-in, line-height to
		      1st-line len, 2*line-height
		    - draw 1st line of subject at 3-chars-in, line-height
		    - cury = 2*line-height
		- else
		    - cury = line-height
		- end gstring
		- destroy gstring, preserving data
		- copy gstring data chunk back to passed lmem block, free temp
		  block
		- LMemInsertAt room for VisMoniker+VisMonikerGString at 0
		- set VM_type to VMT_GSTRING + DAR_NORMAL + DC_TEXT
		- set VM_width to 0 so that the width will be calculated
		- set VM_height to cury
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageCreateMoniker proc	far
;
; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
;
; These local variables must be identical to those in
; MessageCreateOutboxControlMoniker.
;
msg		local	MailboxMessage		push dx, ax
destblk		local	hptr.LMemBlockHeader	push ds:[LMBH_handle]
talID		local	TalID			push cx
monFlags	local	MessageMonikerFlags	push bx
cury		local	word
gstr		local	hptr.GState
gstrBlk		local	hptr.LMemBlockHeader
monChunk	local	word
subjectWidth	local	word
lineWidth	local	word
lineHeight	local	word
destIndent	local	word
if	_RESPONDER_OUTBOX_CONTROL
;
; used in MessageCreateOutboxControlMoniker
;
subjRightBorder			local	word
destRightBorder			local	word
transMediumAbbrevRightBorder	local	word
statusRightBorder		local	word
	ForceRef	subjRightBorder
	ForceRef	destRightBorder
	ForceRef	transMediumAbbrevRightBorder
	ForceRef	statusRightBorder
endif	; _RESPONDER_OUTBOX_CONTROL
	ForceRef	talID
	ForceRef	destblk
	ForceRef	destIndent
	ForceRef	lineWidth
;
; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
;
; These local variables must be identical to those in
; MessageCreateOutboxControlMoniker.
;
		uses	bx, cx, dx, si, di, es
		.enter
		Assert	record, bx, MessageMonikerFlags
EC <		test	bx, mask MMF_ALL_VIEW				>
EC <		jz	checkConnecting					>
EC <		test	bx, mask MMF_CONNECTING or mask MMF_PREPARING	>
EC <		ERROR_NZ INVALID_MONIKER_FLAG_COMBINATION		>
EC <		jmp	flagsOK						>
EC <checkConnecting:							>
EC <		test	bx, mask MMF_CONNECTING				>
EC <		jz	checkPreparing
EC <		test	bx, mask MMF_PREPARING or mask MMF_INCLUDE_DUPS or \
			    mask MMF_LOST_CONNECTION			>
EC <		ERROR_NZ INVALID_MONIKER_FLAG_COMBINATION		>
EC <		jmp	flagsOK						>
EC <checkPreparing:							>
EC <		test	bx, mask MMF_PREPARING				>
EC <		jz	checkLostConnection				>
EC <		test	bx, mask MMF_INCLUDE_DUPS or mask MMF_LOST_CONNECTION>
EC <		ERROR_NZ INVALID_MONIKER_FLAG_COMBINATION		>
EC <checkLostConnection:						>
EC <		test	bx, mask MMF_LOST_CONNECTION			>
EC <		jz	flagsOK						>
EC <		test	bx, mask MMF_INCLUDE_DUPS			>
EC <		ERROR_NZ INVALID_MONIKER_FLAG_COMBINATION		>
EC <flagsOK:								>

	;
	; Make sure we've computed the sizes of the various pieces of the
	; moniker based on the system font.
	; 
		call	MMComputeSizes
	;
	; Create temporary lmem block for drawing to gstring
	;
		mov	ax, LMEM_TYPE_GSTRING
		clr	cx
		call	MemAllocLMem
		mov	ss:[gstrBlk], bx
	;
	; Create a chunk-based gstring, storing the chunk & "gstring handle"
	; away for our subroutines and later use.
	; 
			CheckHack <GST_CHUNK eq 0>
		clr	cl
		call	GrCreateGString
		mov	ss:[monChunk], si
		mov	ss:[gstr], di

if _RESPONDER_OUTBOX_CONTROL
	;
	; Set font for outbox
	;
		mov	cx, MM_FONT
		mov	dx, MM_FONT_SIZE
		clr	ah
		call	GrSetFont
endif
	;
	; Set a clipping rectangle for the "Subject" field of the moniker. It
	; starts from (0,0) since playing the gstring translates the origin
	; to the drawing position. It extends for the maximum width of a
	; subject field and the height of a single line of system font text.
	; 
		mov	si, PCT_REPLACE
		clr	ax, bx
		mov	cx, ss:[subjectWidth]
		mov	dx, ss:[lineHeight]
		mov	ss:[cury], dx		; for later stuff (either start
						;  of dest fields, or height
						;  of moniker)
		call	GrSetClipRect
	;
	; Figure if the message is inbox or outbox, as that determines what
	; goes in the subject field (in conjunction with the moniker flags,
	; of course, but that's hidden in subroutines).
	; 
		movdw	dxax, ss:[msg]
		call	MessageLock		; *ds:di <- MailboxMessageDesc
		mov	si, ds:[di]
		test	ss:[monFlags], mask MMF_PREPARING or \
					mask MMF_CONNECTING or \
					mask MMF_LOST_CONNECTION
		jnz	specialSubject

		clr	bx			; assume inbox
		CmpTok	ds:[si].MMD_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL, drawOutboxSubject
	;
	; It's in the inbox. Leave bx zero and go draw the subject for an
	; inbox message.
	; 
		call	MMDrawInboxSubject
		jmp	drawTime

specialSubject:
	;
	; Go put the proper string in the subject field & skip the timestamp.
	; 
	; We pretend the thing's in the inbox if we're preparing, so we get
	; the subject in the destination field. If we're connecting, we
	; pretend the thing's in the outbox, so we get the destination
	; address in the destination field.
	; 
		call	MMDrawSpecialSubject
		test	ss:[monFlags], mask MMF_PREPARING
		jnz	secondInboxLine
		jmp	secondOutboxLine

drawOutboxSubject:
	;
	; The thing's in the outbox. Set bx non-zero to record this, then
	; go to the right routine...
	; 
		dec	bx		; (1-byte inst)
		call	MMDrawOutboxSubject

drawTime:
	;
	; The subject field is taken care of. Draw the timestamp now. It's
	; up to the routine to remove the clip rectangle, as we might want
	; to clip the timestamp too, and it's more efficient to do a PCT_REPLACE
	; setting than a PCT_NULL followed by a PCT_REPLACE...
	; 
	; *ds:di = message
	; ss:[cury] = line height
	; 
		call	MMDrawMessageTime
	;
	; Now need to produce, possibly, second and subsequent lines of the
	; moniker, based on where the message is and what the moniker flags are.
	; 
		tst	bx
		jz	checkInboxSecondLine

secondOutboxLine:
	;
	; In the outbox, so we're always putting out destinations...
	; 
		call	MMDrawOutboxDestinations
		jmp	doneWithGString

checkInboxSecondLine:
	;
	; When the message is in the inbox, it has only a single line in the
	; moniker unless the caller is in "All View" mode, where the subject
	; field holds the destination application instead.
	; 
		test	ss:[monFlags], mask MMF_ALL_VIEW
		jz	doneWithGString

secondInboxLine:		
		call	MMDrawInboxSubjectAsDestination

doneWithGString:
		call	MMDoneWithGString

		.leave
		ret
MessageCreateMoniker endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMComputeSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we've computed all the sizes for the various
		moniker fields, based on the system font, and copy them
		into the stack frame.

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		ss:bp	= inherited frame
RETURN:		ss:[subjectWidth], ss:[lineWidth], ss:[lineHeight],
			ss:[destIndent] = filled in
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMComputeSizes	proc	near
		uses	ds, ax, bx
		.enter	inherit MessageCreateMoniker
		segmov	ds, dgroup, ax
		call	MessageEnsureSizes

		mov	ss:[lineWidth], ax
		mov	ss:[lineHeight], bx
		
		mov	ax, ds:[mmSubjectWidth]
		mov	ss:[subjectWidth], ax
		
		mov	ax, ds:[mmDestinationIndent]
		mov	ss:[destIndent], ax

if	_RESPONDER_OUTBOX_CONTROL
		mov	ax, ds:[mmSubjectRightBorder]
		mov	ss:[subjRightBorder], ax

		mov	ax, ds:[mmDestinationRightBorder]
		mov	ss:[destRightBorder], ax

		mov	ax, ds:[mmTransMediumAbbrevRightBorder]
		mov	ss:[transMediumAbbrevRightBorder], ax

		mov	ax, ds:[mmAddrStateRightBorder]
		mov	ss:[statusRightBorder], ax
endif	; _RESPONDER_OUTBOX_CONTROL

		.leave
		ret
MMComputeSizes	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageEnsureSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we've computed all the sizes for the various
		moniker fields, based on the system font, and copy them
		into the stack frame.

CALLED BY:	(EXTERNAL) MMComputeSizes, MLSpecBuild
PASS:		nothing
RETURN:		ax	= line width
		bx	= line height
DESTROYED:	nothing
SIDE EFFECTS:	mmSubjectWidth, mmTimestampWidth, mmDestinationIndent,
     			mmLineHeight all filled in

PSEUDO CODE/STRATEGY:
		XXX: This should likely check the sizes against the screen
		size to make sure we're not going to overflow the width.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageEnsureSizes	proc	far
		uses	ds, di, si, dx, cx
		.enter
		segmov	ds, dgroup, ax
		tst	ds:[mmSubjectWidth]
		LONG jnz done
	;
	; Ask our application object for a gstate for these calculations.
	; We could use the current thread's application object, but likely
	; the moniker will be used by an object run by our ui thread, which
	; dictates which font & size will be used.
	; 
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		clr	di
		push	bp
		call	UtilCallMailboxApp	; bp <- gstate for calc
		mov	di, bp
		pop	bp
if _RESPONDER_OUTBOX_CONTROL
	;
	; Set font for outbox
	;
		mov	cx, MM_FONT
		mov	dx, MM_FONT_SIZE
		clr	ah
		call	GrSetFont
endif
	;
	; Fetch the average width of a character in the system font. This
	; is what is used in computing the field widths.
	; 
		mov	si, GFMI_AVERAGE_WIDTH
		call	GrFontMetrics
		mov	cx, dx			; cx <- width, as we'll need it
						;  for a while
	;
	; Compute the width of the subject field, using the maximum length we
	; wish to allow.
	; 
		mov	ax, MM_SUBJECT_LENGTH
			CheckHack <DS_TINY eq 0>
		test	ds:[uiDisplayType], mask DT_DISP_SIZE
		jnz	computeSubjWidth
		mov	ax, MM_TINY_SUBJECT_LENGTH
computeSubjWidth:
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmSubjectWidth], ax
	;
	; Likewise for the timestamp field.
	; 
		mov	ax, MM_TIMESTAMP_LENGTH
			CheckHack <DS_TINY eq 0>
		test	ds:[uiDisplayType], mask DT_DISP_SIZE
		jnz	computeTimestampWidth
		mov	ax, MM_TINY_TIMESTAMP_LENGTH
computeTimestampWidth:
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmTimestampWidth], ax
	;
	; And the indentation used for destination fields.
	; 
		mov	ax, MM_DESTINATION_INDENT
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmDestinationIndent], ax

if	_RESPONDER_OUTBOX_CONTROL
	;
	; More sizes for Responder outbox list.  First the right edge of
	; the destination field.
	;
		mov	ax, MM_RESP_SUBJECT_LENGTH
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmSubjectRightBorder], ax

		mov_tr	bx, ax		; remember for computing dest border

		mov	ax, MM_DESTINATION_LENGTH
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		add	bx, ax
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmDestinationRightBorder], bx
	;
	; Then for the transport/medium abbreviation field.
	;
		mov	ax, MM_TRANS_MEDIUM_ABBREV_LENGTH
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		add	bx, ax
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmTransMediumAbbrevRightBorder], bx
	;
	; And the address state.
	;
		mov	ax, MM_ADDR_STATE_LENGTH
		mul	cx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		add	ax, bx
EC <		ERROR_C	MONIKER_FIELD_TOO_WIDE				>
		mov	ds:[mmAddrStateRightBorder], ax
endif	; _RESPONDER_OUTBOX_CONTROL

	;
	; Finally, get the max adjusted height of the system font to use
	; as the line height for things in the moniker.
	; 
		mov	si, GFMI_MAX_ADJUSTED_HEIGHT
		call	GrFontMetrics
		mov	ds:[mmLineHeight], dx
	;
	; All done -- biff the gstate please.
	; 
		call	GrDestroyState
done:
if _RESPONDER_OUTBOX_CONTROL
		mov	ax, ds:[mmAddrStateRightBorder]
		add	ax, MM_RIGHT_GUTTER
else
		mov	ax, ds:[mmSubjectWidth]
		add	ax, MM_SUBJECT_SEPARATION
		add	ax, ds:[mmTimestampWidth]
endif
		mov	bx, ds:[mmLineHeight]
		.leave
		ret
MessageEnsureSizes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOutboxSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the subject field for an outbox message.

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		*ds:di	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	chunks within the dest block may move around...

PSEUDO CODE/STRATEGY:
		- if MMF_ALL_VIEW, get string for transport+medium of
		  message and draw that at 0,0, followed by ": " at CP
		- else move to 0,0
		- draw 1st line of subject at cp
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawOutboxSubject proc near
		uses	bx, si, di, ax, cx, dx
		.enter	inherit	MessageCreateMoniker
		mov	si, ds:[di]
		mov	di, ss:[gstr]
		test	ss:[monFlags], mask MMF_ALL_VIEW
		jz	noTransportString
	;
	; When we're in "all" view, we need to place the transport string 
	; before the subject (e.g. "Fax: Random Note"). This means we need
	; to get the transport string, but we'd rather not be holding the 
	; message locked while we go fetch it (keep lock interactions to 
	; a minimum, ya know), so fetch the transport & medium token out 
	; and unlock the message.
	; 
		movdw	cxdx, ds:[si].MMD_transport
		push	ds:[si].MMD_transOption
		call	MMGetMedium
		call	UtilVMUnlockDS
	;
	; Call the outbox module to fetch the string into the same block
	; that's holding our moniker.
	; 
		mov	bx, ss:[destblk]
		call	MemDerefDS
		pop	bx			;bx = transport option
		call	OutboxMediaGetTransportString
	;
	; Draw that string @ 0,0 (the upper-left of the moniker), then free it
	; 
		mov	si, ax
		mov	si, ds:[si]
		push	ax			; save for freeing
		clr	ax, bx, cx		; ax, bx <- (0, 0)
						; cx <- null-terminated
		call	GrDrawText
		pop	ax			; ax <- chunk
		call	LMemFree
	;
	; Now we need to put up the separator string (": ", usually...). This
	; gets drawn at the current point, which was updated to be just after
	; the transport string by GrDrawText...
	; 
		mov	bx, handle uiTransportSeparatorString
		call	MemLock
		mov	ds, ax
		assume	ds:segment uiTransportSeparatorString
		mov	si, ds:[uiTransportSeparatorString]
		call	GrDrawTextAtCP
		call	MemUnlock
		assume	ds:nothing
	;
	; Lock down the message again and go draw the subject itself.
	; 
		movdw	dxax, ss:[msg]
		push	di			; preserve the gstate handle...
		call	MessageLock
		mov	si, ds:[di]
		pop	di			; di <- gstring's gstate
		jmp	drawSubject
		
noTransportString:
	;
	; Not in "all" view, so we just need to draw the subject's first line.
	; Of course, the common code expects the current point to be set
	; appropriately, so do a GrMoveTo to get to 0,0...
	; 
		clr	ax, bx
		call	GrMoveTo

drawSubject:
	; ds:si = MailboxMessageDesc
		mov	si, ds:[si].MMD_subject
		mov	si, ds:[si]
		call	MMSetupToDrawOneLine
		jcxz	done			; => nothing to draw (might be
						;  b/c of initial CR; passing 0
						;  would cause chars up to null
						;  to be drawn, which we don't
						;  want)
		call	GrDrawTextAtCP
done:
		.leave
		ret

MMDrawOutboxSubject endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMGetMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the medium token to use.

CALLED BY:	(INTERNAL) MMDrawOutboxSubject
PASS:		ds:si	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		ax	= medium token
DESTROYED:	si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMGetMedium	proc	near
		uses	cx, di
		.enter	inherit	MessageCreateMoniker
		Assert	stackFrame, bp
		
		mov	si, ds:[si].MMD_transAddrs
		mov	ax, ss:[talID]
		test	ax, mask TID_ADDR_INDEX
		jz	enumToFindMedium
		andnf	ax, mask TID_NUMBER
		call	ChunkArrayElementToPtr
		mov	ax, ds:[di].MITA_medium
		jmp	done

enumToFindMedium:
		mov_tr	cx, ax
		mov	bx, cs
		mov	di, offset findMediumCallback
		call	ChunkArrayEnum
EC <		ERROR_NC NO_MESSAGE_ADDRESS_MARKED_WITH_GIVEN_ID	>
done:
		.leave
		ret

	;--------------------
	; callback for ChunkArrayEnum to find an address with the given mark
	; and return its medium token.
	; 
	; Pass:	ds:di	= MailboxInternalTransAddr to check
	;	cx	= TalID being sought
	; Return:	carry set if found unsent addr w/talID:
	; 			ax	= OutboxMedia token
	; 		carry clear if not found
findMediumCallback:
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	findMediumCallbackDone

		cmp	ds:[di].MITA_addrList, cx
		clc
		jne	findMediumCallbackDone
		mov	ax, ds:[di].MITA_medium
		stc
findMediumCallbackDone:
		retf
MMGetMedium	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawSpecialSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw either the Preparing or Connecting string in the
		subject field, based on the monFlags...

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		*ds:di	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	moniker block & its chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawSpecialSubject proc near
		uses	ds, di, bx, si, cx, ax
		.enter	inherit	MessageCreateMoniker
	;
	; Lock down our strings block
	; 
	CheckHack <segment uiConnectingString eq segment uiPreparingString>
	CheckHack <segment uiConnectingString eq segment uiLostConnectionString>
		mov	bx, handle uiConnectingString
		call	MemLock
		mov	ds, ax
	;
	; Figure which string to use.
	; 
		mov	si, offset uiConnectingString
		test	ss:[monFlags], mask MMF_CONNECTING
		jnz	haveString
		mov	si, offset uiPreparingString
		test	ss:[monFlags], mask MMF_PREPARING
		jnz	haveString
		mov	si, offset uiLostConnectionString
haveString:
	;
	; Deref the string and draw it (null-terminated) at 0,0
	; 
		mov	si, ds:[si]
		push	bx
		clr	ax, bx, cx
		mov	di, ss:[gstr]
		call	GrDrawText
	;
	; Unlock the strings block, with our thanks.
	; 
		pop	bx
		call	MemUnlock
		.leave
		ret
MMDrawSpecialSubject endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawInboxSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the subject field for an inbox message

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- if MMF_ALL_VIEW, draw app name from token as first string
		  at 0,0
		- else, draw first line of subject as first string
		  (want subroutine that, when given a chunk will return the
		  start & # chars to the EOS or \r)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawInboxSubject proc	near
		uses	ax,bx,cx,dx,si,di
		.enter	inherit	MessageCreateMoniker
	;
	; Deref the message and fetch the gstring's gstate, for use in both
	; cases.
	; 
		mov	si, ds:[di]
		mov	di, ss:[gstr]
		test	ss:[monFlags], mask MMF_ALL_VIEW
		jz	drawSubject
	;
	; Caller is displaying all messages, so we need to put the application
	; name for the destination app in the subject field. We fetch the
	; app name into the moniker block, as a convenient place, after loading
	; the token into bxcxdx, as usual.
	;
	; Also as usual, we release the message before going to get the name, to
	; avoid nasty lock interactions.
	; 
		mov	ax, {word}ds:[si].MMD_destApp.GT_chars[0]
		mov	cx, {word}ds:[si].MMD_destApp.GT_chars[2]
		mov	dx, ds:[si].MMD_destApp.GT_manufID
		call	UtilVMUnlockDS
		mov	bx, ss:[destblk]
		call	MemDerefDS
		mov_tr	bx, ax
		call	InboxGetAppName		; *ds:ax <- app name
	;
	; Draw the name at 0,0 and free the chunk
	; 
		push	ax
		mov_tr	si, ax
		mov	si, ds:[si]
		clr	ax, bx, cx		; ax, bx <- 0, 0
						; cx <- null-terminated
		call	GrDrawText
		pop	ax
		call	LMemFree
	;
	; Lock the message down again, for return.
	; 
		movdw	dxax, ss:[msg]
		call	MessageLock
		jmp	done

drawSubject:
	;
	; The subject is going into the subject field, as appropriate.
	; 
		mov	si, ds:[si].MMD_subject
		mov	si, ds:[si]
		call	MMSetupToDrawOneLine	; cx <- # chars
		jcxz	done			; => nothing to draw (might be
						;  b/c of initial CR; passing 0
						;  would cause chars up to null
						;  to be drawn, which we don't
						;  want)
		clr	ax, bx
		call	GrDrawText
done:
		.leave
		ret
MMDrawInboxSubject endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMSetupToDrawOneLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of characters to draw from the passed
		string, ensuring only one line of text is drawn. Length
		limitations are ignored, as we assume the appropriate clip
		rectangle has been set...

CALLED BY:	(INTERNAL) MMDrawInboxSubject, MMDrawOutboxSubject
PASS:		ds:si	= string
RETURN:		cx	= # chars to draw (DO NOT DRAW IF CX=0 -- might just
			  have hit a leading CR, not an initial null, and
			  drawing will cause all chars to be drawn)
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Loop through the characters, stopping when we hit a null or
		a carriage return.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMSetupToDrawOneLine proc	near
		uses	si
		.enter
		clr	cx
charLoop:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	done
		LocalCmpChar	ax, '\r'
		loopne	charLoop
		inc	cx		; don't count CR, please
done:
		neg	cx		; cx <- # real chars to draw
		.leave
		ret
MMSetupToDrawOneLine endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawMessageTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the message's arrival date & time into that field

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
		ss:[cury] = line height
		gstate has clipping rectangle set
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawMessageTime proc	near
		uses	ax, bx, cx, dx, si, di, ds, es
		.enter	inherit MessageCreateMoniker
	;
	; Fetch the registration date & time into some spare registers.
	; 
		mov	di, ds:[di]
			CheckHack <FDAT_date eq 0>
		movdw	dxax, ds:[di].MMD_registered
	;
	; Allocate a buffer large enough to hold a date & a time. We do it in
	; the destination block, as we do so many other things.
	; 
		mov	bx, ss:[destblk]
		call	MemDerefDS
		mov	bx, dx			; bxax <- FileDateAndTime
		mov	cx, UFDTF_SHORT_FORM
		call	UtilFormatDateTime	; *ds:ax <- result
	;
	; Remove the clipping rectangle from previous field.
	; XXX: we might want to set our own clip rectangle here instead.
	; 
		mov	di, ss:[gstr]
		mov	si, PCT_NULL
		call	GrSetClipRect
	;
	; Get to the start of the buffer again and draw the text at the right
	; edge of the subject field, y = 0.
	; 
		mov_tr	si, ax			; *ds:si <- formatted timestamp
		push	si
		mov	si, ds:[si]
		mov	ax, ss:[subjectWidth]
		add	ax, MM_SUBJECT_SEPARATION
		clr	bx
		call	GrDrawText
	;
	; Free up the timestamp buffer.
	; 
		pop	ax
		call	LMemFree
		.leave
		ret
MMDrawMessageTime endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOutboxDestinations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the one or more destination addresses for an outbox
		message, as selected by the talID and the moniker flags.

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
		ss:[cury] = line height
RETURN:		ss:[cury] = Y coordinate after last destination field (i.e.
			    the height of the moniker)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		- foreach marked (if non-z search-talID) /
		  non-dup (if z search-talID || MMF_INCLUDE_DUPS), unsent
		  address:
		    - subroutine:
			- set clip rect from 3-chars-in, cury to
			  1st-line len, cury+line-height
			- draw "To: " at 3-chars-in, cury
			- draw 1st line of user addr at CP
			- cury += line-height
		    - if talID==0 || MMF_INCLUDE_DUPS:
			- foreach duplicate:
			    - call subroutine for it
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawOutboxDestinations proc	near
		uses	si, bx, di, dx, cx, ax
		.enter	inherit	MessageCreateMoniker
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	bx, cs
		mov	di, offset MMDrawOutboxDestinationsCallback
		clr	dx		; index of first address
		mov	cx, ss:[talID]
		call	ChunkArrayEnum
		.leave
		ret
MMDrawOutboxDestinations endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOutboxDestinationsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single destination address (and possibly its unsent
		duplicates) if it's selected by the stuff in the inherited
		stack frame

CALLED BY:	(INTERNAL) MMDrawOutboxDestinations via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= MMD_transAddrs
		ss:bp	= inherited stack frame
		dx	= index of this address
		cx	= talID
		ax	= element size (ignored)
RETURN:		carry set to stop enumerating (always clear)
		dx	= index of next address
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	ss:[cury] advanced if drew anything
		clipping rectangle left in gstate if drew anything

PSEUDO CODE/STRATEGY:
		if talID is 0:
			- draw address
		else if MITA_addrList == talID

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawOutboxDestinationsCallback proc	far
		uses	dx, cx
		.enter	inherit	MessageCreateMoniker
	;
	; If the address is a duplicate, and MMF_INCLUDE_DUPS, then
	; don't draw, because the address will be drawn as the duplicate 
	; of some other address.
	;
		test	ds:[di].MITA_flags, mask MTF_DUP
		jz	checkIfSent		; not duplicate, so proceed.
		
		test	ss:[monFlags], mask MMF_INCLUDE_DUPS
		jnz	done		
		
checkIfSent:
	;
	; If the address has been sent to, we never draw it.
	; 
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done
	;
	; If talID is 0, it means to draw all addresses...
	; 
		jcxz	drawIt
	;
	; Get the talID to compare against CX into DX. If CX is an address
	; index, then we've already got the value (the index of this address)
	; in DX. If not, we have to fetch the address's talID.
	; 
		test	cx, mask TID_ADDR_INDEX
		jnz	compareID
		mov	dx, ds:[di].MITA_addrList
compareID:
		andnf	cx, mask TID_NUMBER	; cx <- talID
		cmp	dx, cx
		jne	done			; no match => no draw

drawIt:
		call	MMDrawOneOutboxDestination
	;
	; We've drawn the address, now decide whether to draw its duplicates
	; as well. If drawing all addresses (cx == 0), we leave the drawing to
	; be handled on future callbacks. If cx is non-zero, we draw the dups
	; only if MMF_INCLUDE_DUPS is set in monFlags (usually the dups will be
	; marked with the same talID; MMF_INCLUDE_DUPS is normally used only
	; in control panels, where the messages are broken up by address and
	; we don't want to mark the addresses just for displaying them)
	; 
		jcxz	done		; => dups will be handled on future
					;  iterations
		test	ss:[monFlags], mask MMF_INCLUDE_DUPS
		jz	done

dupLoop:
	;
	; We're drawing duplicates. Fetch the next duplicate and make sure we're
	; not at the end of the list.
	; 
		mov	ax, ds:[di].MITA_next
			CheckHack <MITA_NIL eq -1>
		inc	ax
		jz	done
	;
	; Point to the duplicate address and draw it if it's not been sent to
	; already.
	; 
		dec	ax
		call	ChunkArrayElementToPtr
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	dupLoop
		call	MMDrawOneOutboxDestination
		jmp	dupLoop

done:
		.leave
	;
	; Return carry clear to keep enumerating, after incrementing the
	; index counter for the next callback.
	; 
		inc	dx
		clc
		ret
MMDrawOutboxDestinationsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMEstablishDestClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish a clipping rectangle for the current destination-
		address line

CALLED BY:	(INTERNAL) MMDrawOneOutboxDestination,
			   MMDrawInboxSubjectAsDestination
PASS:		ss:bp	= inherited frame
RETURN:		ax, bx	= upper-left corner of rectangle
		di	= gstate
DESTROYED:	cx, dx, si
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMEstablishDestClipRect proc	near
		.enter	inherit	MessageCreateMoniker
		mov	di, ss:[gstr]
		mov	ax, ss:[destIndent]
		mov	bx, ss:[cury]
		mov	cx, ss:[lineWidth]
		mov	dx, bx
		add	dx, ss:[lineHeight]
		mov	si, PCT_REPLACE
		call	GrSetClipRect
		.leave
		ret
MMEstablishDestClipRect endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOneOutboxDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the first line of the user address for a single address
		at the current place in the moniker, properly indented and
		clipped.

CALLED BY:	(INTERNAL) MMDrawOutboxDestinationsCallback
PASS:		ds:di	= MailboxInternalTransAddr
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ss:[cury] is advanced
     		clip rectangle is set in the gstate

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawOneOutboxDestination proc	near
		uses	si, di, ax, bx, cx, dx
		.enter	inherit	MessageCreateMoniker
	;
	; Establish a clipping rectangle for the bounds of the current line.
	; 
		push	di
		call	MMEstablishDestClipRect
	;
	; Put out the "To: " at the start of the line.
	; 
		test	ss:[monFlags], mask MMF_LOST_CONNECTION
		jnz	noToDestinationStr

		push	ds
		mov	bx, handle uiToDestinationStr
		call	MemLock
		mov	ds, ax
		assume	ds:segment uiToDestinationStr
		mov	si, ds:[uiToDestinationStr]
		mov	ax, ss:[destIndent]
		mov	bx, ss:[cury]
		clr	cx			; cx <- null-terminated
		call	GrDrawText
		mov	bx, handle uiToDestinationStr
		call	MemUnlock
		assume	ds:nothing
		pop	ds
drawAddress:
	;
	; Put out the first line of the user-readable address.
	; 
		pop	si
		mov	cx, ds:[si].MITA_opaqueLen
		add	cx, offset MITA_opaque
		add	si, cx			; ds:si <- string
		call	MMSetupToDrawOneLine
		jcxz	drawDone
		
		call	GrDrawTextAtCP
drawDone:
	;
	; Advance cury by the line height.
	; 
		mov	ax, ss:[lineHeight]
		add	ss:[cury], ax
		.leave
		ret

noToDestinationStr:
	;
	; Move to the upper-left corner of the field, since we won't be drawing
	; anything.
	; 
		mov	ax, ss:[destIndent]
		mov	bx, ss:[cury]
		call	GrMoveTo
		jmp	drawAddress
MMDrawOneOutboxDestination endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawInboxSubjectAsDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the first line of the subject of the message in the
		destination address field of the message

CALLED BY:	(INTERNAL) MessageCreateMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ss:[cury] advanced by a line
     		clip rectangle established

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDrawInboxSubjectAsDestination proc	near
		uses	ax, bx, cx, dx, si, di
		.enter	inherit	MessageCreateMoniker
		push	di
		call	MMEstablishDestClipRect
		pop	si			; *ds:si <- MMD

		mov	si, ds:[si]
		mov	si, ds:[si].MMD_subject
		mov	si, ds:[si]		; ds:si <- subject text
		mov_tr	dx, ax			; dx <- left
		call	MMSetupToDrawOneLine	; cx <- # chars in first line
		jcxz	done			; => none, so don't draw

		mov_tr	ax, dx			; ax <- left
		call	GrDrawText		; draw subject in upper-left
						;  of clip rect
done:
	;
	; Advance cury to account for the line (so caller knows the height
	; of the moniker)
	; 
		mov	ax, ss:[lineHeight]
		add	ss:[cury], ax
		.leave
		ret
MMDrawInboxSubjectAsDestination endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDoneWithGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup and construct the VisMoniker in the desired block
		after we are done drawing to the gstring.

CALLED BY:	(INTERNAL) MessageCreateMoniker,
			   MessageCreateOutboxControlMoniker
PASS:		ds	= segment of MailboxMessageDesc to be unlocked
		ss:bp	= inherited frame
RETURN:		*ds:ax	= gstring moniker (DC_TEXT)
DESTROYED:	bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 6/95    	Initial version (pulled out from
				MessageCreateMoniker)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MMDoneWithGString	proc	near
		.enter inherit MessageCreateMoniker

		Assert	stackFrame, bp
	;
	; Unlock the message.
	;
		call	UtilVMUnlockDS
	;
	; Everything's drawn, so terminate the gstring properly.
	; 
		mov	di, ss:[gstr]
		call	GrEndGString
	;
	; Destroy the gstring administrative structures, but leave the data
	; in the chunk.
	; 
		mov	si, di			; si <- handle from create
		clr	di			; di <- no other gstate to biff
		mov	dl, GSKT_LEAVE_DATA	; dl <- leave the data in the
						;  chunk, please
		call	GrDestroyGString
	;
	; Get size of chunk of gstring data
	;
		mov	bx, ss:[gstrBlk]
		call	MemLock
		mov	ds, ax
		mov	si, ss:[monChunk]
		mov	si, ds:[si]		; ds:si = data source
		ChunkSizePtr	ds, si, cx
	;
	; Create chunk in passed block to copy data. Enlarge it by the
	; vis moniker header, and copy the data past the header.
	;
		push	ds
		mov	bx, ss:[destblk]
		call	MemDerefDS
		mov	al, mask OCF_DIRTY
		mov	bx, size VisMoniker + size VisMonikerGString
		add	cx, bx
		call	LMemAlloc		; ax = moniker lptr
		movdw	esdi, dsax
		mov	di, es:[di]		; es:di = data target
		add	di, bx			;  ...past moniker header
		sub	cx, bx
		pop	ds			; ds:si = data source
		rep	movsb			; copy
	;
	; Free temporary block used for drawing
	;
		mov	bx, ss:[gstrBlk]
		call	MemFree
	;
	; The gstring is now complete. Now we need to prepend the requisite
	; VisMoniker cruft. First get DS pointing back at the destination
	; block, please.
	; 
		segmov	ds, es			; *ds:ax = gstring data
	;
	; Initialize the VisMoniker stuff:
	; 	- it's a normal-aspect gstring moniker that is appropriate for
	;	  all displays, regardless of color type.
	;	- its width is the combined size of the subject & timestamp
	;	  fields, since any other lines are indented and clipped to
	;	  that edge.
	;	- the height is left in cury by the destination-drawing
	;	  routines.
	; I see no benefit to leaving the width & height 0 and forcing the
	; bounds to be computed, when they're so simple for us to compute.
	; 
		mov	si, ax
		mov	si, ds:[si]
		mov	ds:[si].VM_type, mask VMT_GSTRING or \
				(DAR_NORMAL shl offset VMT_GS_ASPECT_RATIO) or \
				(DC_TEXT shl offset VMT_GS_COLOR)
		clr	ds:[si].VM_width	; so that it will be calculated
		mov	bx, ss:[cury]
		mov	({VisMonikerGString}ds:[si].VM_data).VMGS_height, bx

		.leave
		ret
MMDoneWithGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCreateOutboxControlMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a moniker for a message and its address, in the
		OutboxControlMessageList format.

CALLED BY:	(EXTERNAL) OCMLMlGenerateMoniker
PASS:		ds	= locked lmem/object block in which to place the 
			  moniker
		dxax	= MailboxMessage
		cx	= TalID (with TID_ADDR_INDEX set)
RETURN:		*ds:ax	= gstring moniker (DC_TEXT)
DESTROYED:	nothing
SIDE EFFECTS:	this may cause the lmem block, or chunks within it, to move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MessageCreateOutboxControlMoniker	proc	far

;
; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
;
; These local variables must be identical to those in MessageCreateMoniker.
;
msg		local	MailboxMessage		push dx, ax
destblk		local	hptr.LMemBlockHeader	push ds:[LMBH_handle]
talID		local	TalID 			push cx
monFlags	local	MessageMonikerFlags	; not actually used, thus no
						;  need to push-init as in
						;  MessageCreateMoniker
cury		local	word
gstr		local	hptr.GState
gstrBlk		local	hptr.LMemBlockHeader
monChunk	local	word
subjectWidth	local	word
lineWidth	local	word
lineHeight	local	word
destIndent	local	word

subjRightBorder			local	word
destRightBorder			local	word
transMediumAbbrevRightBorder	local	word
statusRightBorder		local	word
	ForceRef	subjRightBorder
	ForceRef	destRightBorder
	ForceRef	transMediumAbbrevRightBorder
	ForceRef	statusRightBorder

	ForceRef	talID
	ForceRef	destblk
	ForceRef	destIndent
	ForceRef	lineWidth
	ForceRef	subjectWidth
;
; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
;
; These local variables must be identical to those in MessageCreateMoniker.
;
	uses	bx,cx,dx,si,di,es
	.enter

if ERROR_CHECK
	;
	; Make sure we barf if our own code or our subroutines expects
	; MessageMonikerFlags to be passed in bx because of our own
	; bugs.  (This is a parameter used by MessageCreateMoniker.)
	;
	mov	bx, 0xcccc
	mov	ss:[monFlags], bx
endif

	;
	; Make sure we've computed the sizes of the various pieces of the
	; moniker based on the system font.
	; 
	call	MMComputeSizes
	mov	ax, ss:[lineHeight]
	mov	ss:[cury], ax

	;
	; Create temporary lmem block for drawing to gstring
	;
	mov	ax, LMEM_TYPE_GSTRING
	clr	cx
	call	MemAllocLMem
	mov	ss:[gstrBlk], bx

	;
	; Create a chunk-based gstring, storing the chunk & "gstring handle"
	; away for our subroutines and later use.
	; 
		CheckHack <GST_CHUNK eq 0>
	clr	cl			; cl = GST_CHUNK
	call	GrCreateGString		; di = gstr, si = chunk
	mov	ss:[monChunk], si
	mov	ss:[gstr], di

	;
	; Set font for outbox
	;
	mov	cx, MM_FONT
	mov	dx, MM_FONT_SIZE
	clr	ah
	call	GrSetFont

	;
	; Lock the message.
	;
	movdw	dxax, ss:[msg]
	call	MessageLock		; *ds:di = MailboxMessageDesc

	call	MMDrawOutboxControlSubject
	call	MMDrawMediaTransportAbbrev
	call	MMDrawOutboxControlDestination
					; ds:si = MailboxInternalTransAddr
	call	MMDrawStatus

	;
	; Remove any clip rectangle that might have been set.
	;
	mov	di, ss:[gstr]
	mov	si, PCT_NULL
	call	GrSetClipRect
	;
	; Unlock the message and do the rest.
	;
	call	MMDoneWithGString	; *ds:ax = gstring moniker

	.leave
	ret
MessageCreateOutboxControlMoniker	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMClipToField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clip the output of the moniker to lie within the bounds
		of this field.

CALLED BY:	(INTERNAL) MMDrawOutboxControlSubject,
			   MMDrawOutboxControlDestination
PASS:		ax	= left edge
		cx	= right edge
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	clip rectangle is set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMClipToField	proc	near
		uses	bx, dx, si, di
		.enter	inherit	MessageCreateOutboxControlMoniker
		
		clr	bx
		mov	dx, ss:[lineHeight]
		mov	di, ss:[gstr]
		mov	si, PCT_REPLACE
		call	GrSetClipRect
		
		.leave
		ret
MMClipToField	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawRightJustifiedClippedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the text for an outbox-control moniker right-justified
		within its field, unless it's too big, in which case it gets
		left-justified within the field and clipped on the right.

CALLED BY:	(INTERNAL)
PASS:		ds:si	= text to draw
		dx	= # chars to draw (0 => null-term)
		ax	= left edge of field
		cx	= right edge of field
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	clipping rectangle added or removed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMDrawRightJustifiedClippedText proc	near
		uses	di
		.enter	inherit	MessageCreateOutboxControlMoniker
	;
	; Compute the width of the string being drawn.
	;
		push	dx
		push	cx
		mov	di, ss:[gstr]
		mov	cx, dx			; cx <- # chars
		call	GrTextWidth		; dx = width
		pop	cx
	;
	; Compute the X position that many pixels from the right edge of the
	; field.
	;
		mov	bx, cx
		sub	bx, dx
		sub	bx, MM_RESP_EDGE_SEPARATION
						; extra pixels for padding
						;  between the edge marker and
						;  the right edge of the text
	;
	; If that goes beyond the left edge of the field, clip to the field
	; and use the left edge as the drawing position.
	;
		cmp	bx, ax
		jge	drawIt
		sub	cx, MM_RESP_EDGE_SEPARATION
		call	MMClipToField
		add	cx, MM_RESP_EDGE_SEPARATION
		mov_tr	bx, ax
drawIt:
	;
	; Draw the text appropriately.
	;
		mov	dx, cx		; save right edge for vline
		mov_tr	ax, bx		; ax <- X pos
		clr	bx		; bx <- y pos (0),
		pop	cx		; cx <- # chars to draw
		call	GrDrawText
	;
	; Draw a vertical line at the right edge of the field.
	;
		mov	si, PCT_NULL
		call	GrSetClipRect
		mov_tr	ax, dx		; ax <- X pos
		mov	dx, ss:[lineHeight]	; dx <- Y of endpoint
		inc	dx
		call	GrDrawVLine
		.leave
		ret
MMDrawRightJustifiedClippedText endp
endif	; _RESPONDER_OUTBOX_CONTROL

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOutboxControlSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the subject in the OutboxControlMessageList format.

CALLED BY:	(INTERNAL) MessageCreateOutboxControlMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	chunks within the dest block may move around...

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMDrawOutboxControlSubject	proc	near
	uses	di
	.enter	inherit	MessageCreateOutboxControlMoniker

	Assert	stackFrame, bp

	;
	; Draw the subject.
	;
	mov	si, ds:[di]
	mov	si, ds:[si].MMD_subject
	mov	si, ds:[si]
	call	MMSetupToDrawOneLine	; cx = # chars to draw

	mov	dx, cx
	clr	ax
	mov	cx, ss:[subjRightBorder]
	call	MMDrawRightJustifiedClippedText

	.leave
	ret
MMDrawOutboxControlSubject	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawOutboxControlDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the destination in the OutboxControlMessageList format.

CALLED BY:	(INTERNAL) MessageCreateOutboxControlMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		ds:si	= first (and the only) MailboxInternalTransAddr of
			  the message
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	There should only be one address.  Draw the user-readable part.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMDrawOutboxControlDestination	proc	near
	uses	di
	.enter	inherit MessageCreateOutboxControlMoniker

	Assert	stackFrame, bp

	;
	; Get the user-readable address.
	;
	mov	si, ds:[di]		; ds:si = MMD
	mov	si, ds:[si].MMD_transAddrs	; *ds:si = MITA array
	mov	ax, ss:[talID]
	Assert	bitSet, ax, TID_ADDR_INDEX
	andnf	ax, mask TID_NUMBER	; ax <- addr #
	call	ChunkArrayElementToPtr	; ds:di = MailboxInternalTransAddr
	lea	si, ds:[di].MITA_opaque
	add	si, ds:[di].MITA_opaqueLen	; ds:si = user-readable addr

	;
	; Draw it, right-justified.
	;
	mov	ax, ss:[subjRightBorder]; ax <- right edge of subject
	mov	cx, ss:[destRightBorder]
	clr	dx			; dx <- null-term
	call	MMDrawRightJustifiedClippedText
	mov	si, di			; ds:si <- MITA

	.leave
	ret
MMDrawOutboxControlDestination	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawMediaTransportAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the transport+medium abbreviation.

CALLED BY:	(INTERNAL) MessageCreateOutboxControlMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		*ds:di	= fixed up (block and chunk may have moved)
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMDrawMediaTransportAbbrev	proc	near
	.enter	inherit MessageCreateOutboxControlMoniker

	Assert	stackFrame, bp

	;
	; Get the transport and unlock the message, because we don't want to
	; keep the message locked while fetching the transport abbrev string.
	;
	mov	si, ds:[di]
	movdw	cxdx, ds:[si].MMD_transport
	push	ds:[si].MMD_transOption
	call	MMGetMedium		; ax = medium token
	call	UtilVMUnlockDS

	;
	; Call the outbox module to fetch the string into the same block
	; that's holding our moniker.
	; 
	mov	bx, ss:[destblk]
	call	MemDerefDS
	pop	bx			;bx = transport option
	call	OutboxMediaGetTransportAbbrev	; *ds:ax = abbrev string

	;
	; Draw the string, then free it.
	;
	push	ax			; save abbrev string lptr
	mov_tr	si, ax
	mov	si, ds:[si]		; ds:si = abbrev
	mov	ax, ss:[destRightBorder]
	mov	cx, ss:[transMediumAbbrevRightBorder]
	clr	dx
	call	MMDrawRightJustifiedClippedText
	pop	ax			; *ds:ax = abbrev
	call	LMemFree

	;
	; Lock the message again
	;
	movdw	dxax, ss:[msg]
	call	MessageLock		; *ds:di = MMD

	.leave
	ret
MMDrawMediaTransportAbbrev	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMDrawStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the message address status

CALLED BY:	(INTERNAL) MessageCreateOutboxControlMoniker
PASS:		*ds:di	= MailboxMessageDesc
		ds:si	= MailboxInternalTransAddr
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMDrawStatus	proc	near
	uses	ds, es
	.enter inherit MessageCreateMoniker

	Assert	stackFrame, bp

	;
	; Get the MTF_STATE 
	;
	mov	al, ds:[si].MITA_flags
	and	al, mask MTF_STATE	; al = MailboxAddressState shifted

	;
	; Find the string to use.
	;
		CheckHack <MAS_SENT eq 0>
	jz	done			; do nothing if message is sent
	cmp	al, MAS_EXISTS shl offset MTF_STATE
	je	getRetryOrSendTime

	cmp	al, MAS_SENDING shl offset MTF_STATE
	je	getSendingString

useStandardStrings::
	mov	cl, offset MTF_STATE - 1
	shr	al, cl			; al = MailboxAddressState * size lptr
		CheckHack <MailboxAddressState lt 0x40>
	cbw				; ax = MailboxAddressState * size lptr
	add	ax, (offset uiQueuedString) - MAS_QUEUED * size lptr
	mov_tr	si, ax

	mov	bx, handle ROStrings	; bx = hptr to unlock later
	call	MemLock
	mov	ds, ax			; *ds:si = status string
	jmp	draw

getSendingString:
	;
	; Use "Sending" or "xx% sent" or "Sending x/y" or "some custom string"
	;
	; Look at the MailboxProgressType that might be at the end of the
	; MailboxInternalTransAddr and do whatever we are supposed to do
	;
		segmov	es, ds, ax
		mov	di, si

		;es:di is MailboxInternalTransAddr
		;bp is inherited frame
		call	MMGetSendingString	; carry set if no string set
						; *ds:si = string
		mov	bx, 0			; preserve flags!
		jnc	draw
		mov	al, MAS_SENDING shl offset MTF_STATE
		jmp	useStandardStrings

getRetryOrSendTime:
	;
	; Create a string for the send/retry time.
	;
	mov	di, ds:[di]		; ds:di = MMD
	movdw	bxax, ds:[di].MMD_autoRetryTime

	mov	cx, UFDTF_RETRY

	CheckHack <MAILBOX_NOW eq 0>
	tstdw	ds:[di].MMD_transWinOpen
	jz	haveUFDTF

	cmpdw	ds:[di].MMD_transWinOpen, bxax
	jne	haveUFDTF

	mov	cx, UFDTF_SEND

haveUFDTF:

	push	ss:[destblk]
	call	MemDerefStackDS
	call	UtilFormatDateTime	; *ds:ax = retry time string
	mov_tr	si, ax			; *ds:si = string
	clr	bx			; nothing to unlock

draw:
	;
	; Draw the string.
	;
	push	bx
	push	si			; save (possibly) retry time str lptr
	mov	si, ds:[si]		; ds:si = status string
	clr	dx			; dx <- null-term
	mov	cx, ss:[statusRightBorder]
	mov	ax, ss:[transMediumAbbrevRightBorder]
	call	MMDrawRightJustifiedClippedText

	;
	; Either unlock status string, or free retry time/sending string.
	;
	pop	ax			; *ds:ax = string
	pop	bx			; bx = (if non-zero) block to unlock
	tst	bx
	jnz	unlock

	call	LMemFree		; free retry time or sending string
	jmp	done

unlock:
	call	MemUnlock		; unlock status string

done:
	.leave
	ret
MMDrawStatus	endp
endif	; _RESPONDER_OUTBOX_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MMGetSendingString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MMDrawStatus

PASS:		ss:bp = stack frame from MMDrawStatus/MessageCreateMoniker
		es:di = MailboxInternalTransAddr

RETURN:		*ds:si = status string to use

DESTROYED:	all

NOTES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_RESPONDER_OUTBOX_CONTROL
MMGetSendingString	proc	near
	.enter inherit MessageCreateMoniker
	;
	; see if there is some extra status stuff at the end of the MITA
	;
	; first we need to get to the end of the opaque data
	;
		lea	ax, es:[di].MITA_opaque
		add	ax, es:[di].MITA_opaqueLen ; es:ax = user-readable addr
		mov_tr	di, ax
	; now skip over the user-readable address
	;
		LocalStrSize			; es:di is past null
						; cx trahsed
	;
	; (es:[di] should be a MailboxProgressType)
	;
	; for now we do not use a MailboxProgressType, just stick the string
	; at the end...
	;
	; get size of the string
	;
		;esdi is status string
		call	LocalStringSize			; cx = size w/o null
		jcxz	useDefaultSendingString
		inc	cx				; include the null
if DBCS_PCGEOS
		inc	cx
endif
	;
	; ok, use the string stored there: allocate room for the string
	;
		push	ss:[destblk]
		call	MemDerefStackDS
		Assert	lmem, ds:[LMBH_handle]
		clr	ax
		;cx is size of chunk to allocate
		call	LMemAlloc		; ax <- chunk handle
		mov_tr	si, ax
		push	si			; save chunk handle
		mov	si, ds:[si]		; ds:si is buffer to use
	;
	; copy status string into new buffer, put buffer pointers into
	; correct places
	;
		segxchg	es, ds
		xchg	di, si
		;cx is still size (including null)
		rep movsb

		segmov	ds, es, ax
		pop	si			; *ds:si is new string

		clc
done:
	.leave
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;; below the ret line ;;;;;;;;;;;;;;;;;;;;;;;;
useDefaultSendingString:
		stc
		jmp	done

MMGetSendingString	endp

endif	; _RESPONDER_OUTBOX_CONTROL

MessageCode	ends
