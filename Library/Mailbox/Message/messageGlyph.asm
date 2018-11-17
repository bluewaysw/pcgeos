COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageGlyph.asm

AUTHOR:		Adam de Boor, May 24, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/24/94		Initial revision


DESCRIPTION:
	Implementation of the MessageGlyphClass
		

	$Id: messageGlyph.asm,v 1.1 97/04/05 01:20:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	MessageGlyphClass
MailboxClassStructures	ends

MessageGlyph	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display

CALLED BY:	MSG_MG_SET_MESSAGE
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessage	method dynamic MessageGlyphClass, MSG_MG_SET_MESSAGE
		mov	bx, mask MMF_INCLUDE_DUPS	; don't show transport
		GOTO_ECN	MGSetMessageCommon
MGSetMessage	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessageNoDups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display, but don't include duplicate
		addresses unless marked.

CALLED BY:	MSG_MG_SET_MESSAGE_NO_DUPS
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessageNoDups method dynamic MessageGlyphClass, MSG_MG_SET_MESSAGE_NO_DUPS
		clr	bx	; don't show dups unless marked, don't show
				;  transport
		GOTO_ECN	MGSetMessageCommon
MGSetMessageNoDups endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessageAllView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display, showing the transport and
		including duplicate addresses even if not marked.

CALLED BY:	MSG_MG_SET_MESSAGE_ALL_VIEW
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessageAllView method dynamic MessageGlyphClass, MSG_MG_SET_MESSAGE_ALL_VIEW
		mov	bx, mask MMF_ALL_VIEW or mask MMF_INCLUDE_DUPS
		GOTO_ECN	MGSetMessageCommon
MGSetMessageAllView endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessagePreparing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display, indicating we're preparing it

CALLED BY:	MSG_MG_SET_MESSAGE_PREPARING
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessagePreparing method dynamic MessageGlyphClass, 
					MSG_MG_SET_MESSAGE_PREPARING
		mov	bx, mask MMF_PREPARING	; don't show dups unless marked,
						;  indicate msg being prepared
		GOTO_ECN	MGSetMessageCommon
MGSetMessagePreparing endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessageConnecting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display, indicating we're connecting to
		the address.

CALLED BY:	MSG_MG_SET_MESSAGE_CONNECTING
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessageConnecting method dynamic MessageGlyphClass, 
				MSG_MG_SET_MESSAGE_CONNECTING
		mov	bx, mask MMF_CONNECTING	; don't show dups unless marked,
						;  indicating connecting
		GOTO_ECN	MGSetMessageCommon
MGSetMessageConnecting endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessageLostConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message we display, indicating we lost connection to
		the address.

CALLED BY:	MSG_MG_SET_MESSAGE_LOST_CONNECTION
PASS:		*ds:si	= MessageGlyph
		cxdx	= MailboxMessage with extra reference
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessageLostConnection method dynamic MessageGlyphClass, 
				MSG_MG_SET_MESSAGE_LOST_CONNECTION
		mov	bx, mask MMF_LOST_CONNECTION
		GOTO_ECN	MGSetMessageCommon
MGSetMessageLostConnection endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSetMessageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the moniker for the glyph to one generated from
		the passed message

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MessageGlyph object
		cxdx	= MailboxMessage
		bp	= TalID
		bx	= MessageMonikerFlags
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	block & chunks may move
     		percentage gauge set to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSetMessageCommon proc	ecnear
		uses	cx, dx, bp
		class	MessageGlyphClass
		.enter
	;
	; Arrange registers properly and create a moniker for the message
	; 
		mov_tr	ax, cx			; (another 2-byte seq.)
		xchg	dx, ax			; dxax <- message
		mov	cx, bp			; cx <- TalID
		push	ax
		call	MessageCreateMoniker	; *ds:ax <- moniker
	;
	; Preserve the moniker chunk and remove the reference to the message,
	; now that we have the moniker.
	; 
		pop	bx			; bx <- message.low
		push	ax
		mov_tr	ax, bx			; dxax <- message
		call	MailboxGetAdminFile		; bx <- admin file
		call	DBQDelRef
		pop	cx			; *ds:cx <- new moniker
	;
	; Fetch the existing moniker from the message glyph, so we can free
	; it after setting the new one.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	ds:[di].GI_visMoniker
	;
	; Set the new moniker, performing an immediate visual update.
	; 
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	ax			; *ds:ax <- old moniker
	;
	; Free the old moniker, if any.
	; 
		tst	ax
		jz	done
		call	LMemFree
done:
		.leave
		ret
MGSetMessageCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MGSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust our minimum size to be appropriate to the sizes used
		to create the monikers we use.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= MessageGlyph object
		ds:di	= MessageGlyphInstance
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	HINT_MINIMUM_SIZE is added before we call our superclass

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Stolen from MLSpecBuild

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MGSpecBuild	method dynamic MessageGlyphClass, MSG_SPEC_BUILD
	;
	; Fetch the width & line-height of the monikers.
	; 
		call	MessageEnsureSizes	; ax <- width, bx <- line height
	;
	; Set HINT_MINIMUM_SIZE on ourselves to match.
	; 
		push	bp
			CheckHack <SSA_updateMode eq SetSizeArgs-2>
		mov	di, VUM_NOW
		push	di
			CheckHack <SSA_count eq SetSizeArgs-4>
		mov	di, 1
		push	di
			CheckHack <SSA_height eq SetSizeArgs-6>
		push	bx
			CheckHack <SSA_width eq SetSizeArgs-8>
		push	ax
			CheckHack <SetSizeArgs eq 8>
		mov	bp, sp
		mov	dx, size SetSizeArgs
		mov	ax, MSG_GEN_SET_MINIMUM_SIZE
		call	ObjCallInstanceNoLock
		add	sp, size SetSizeArgs

		pop	bp
		mov	ax, MSG_SPEC_BUILD
		mov	di, offset MessageGlyphClass
		GOTO	ObjCallSuperNoLock
MGSpecBuild	endm

MessageGlyph	ends
