COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		Book Reader
FILE:		reader.asm

AUTHOR:		Jonathan Magasin, Apr  8, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/ 8/94   	Initial revision


DESCRIPTION:
	Code for Book Reader.
		

	$Id: reader.asm,v 1.1 97/04/04 16:29:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE Stuff
;------------------------------------------------------------------------------
include geos.def
include	heap.def
include geode.def
include	resource.def
include ec.def
include object.def
include Internal/prodFeatures.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
UseLib ui.def
UseLib library.def
UseLib conview.def

UseLib text.def				;
include Objects/vTextC.def		;
include gstring.def			;for icon monikers

include reader.def
include	reader.rdef



;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------


ProcessCode segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReaderProcessInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let superclass install the app token, then install the
		Book file token.

CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentViewProcessClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReaderProcessInstallToken		method dynamic ReaderProcessClass,
					MSG_GEN_PROCESS_INSTALL_TOKEN

	mov	di, offset ReaderProcessClass
	call	ObjCallSuperNoLock

	mov	ax, ('c') or ('n' shl 8)	; ax:bx:si = token used for
	mov	bx, ('t') or ('b' shl 8)	;	Book datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; list is in data resource, so
						;  it's already relocated
	call	TokenDefineToken		; add icon to token database
done:
		ret
ReaderProcessInstallToken		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReaderProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ReaderProcessClass object
		ds:di	- ReaderProcessClass instance data
		es	- segment of ReaderProcessClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/13/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReaderProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interception so that we can get the
		extra state block handle from the
		navigation controller, and determine
		whether any "cleaning up" is necessary.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si	= ContentViewProcessClass object
		ds:di	= ContentViewProcessClass instance data
		ds:bx	= ContentViewProcessClass object (same as *ds:si)
		es 	= segment of ContentViewProcessClass
		ax	= message #
RETURN:		cx 	=  handle of block to save (or 0 for none)
			  (*must* be unlocked, and *must* be swappable)

DESTROYED:	ax,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReaderProcessCloseApplication		method dynamic ReaderProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	;
	; Need to determine nature of application's closing:
	; with or without state.
	;
	clr	bx				;current process
	call	GeodeGetAppObject		;^lbx:si<-app object
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	mov	di, mask MF_CALL
	call	ObjMessage			;ax=ApplicationStates

	GetResourceHandleNS	ContentViewInterface, bx
	mov	si, offset ContentNav		;^lbx:si <- ContentNavControl
	test	ax, mask AS_QUITTING
	jnz	cleanUp				;no state
	;
	; Get MemHandle of history list for saving to state.
	;
	mov	ax, MSG_CNC_GET_STATE_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage			;cx<-handle
	jmp	done

cleanUp:
	;
	; Regular shutdown, so clean up the NavControl
	;
	mov	ax, MSG_CNC_FREE_HISTORY_LIST
	clr	di
	call	ObjMessage
	clr	cx				;no state

done:
	ret
ReaderProcessCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReaderProcessSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This was added to support the special hyperlinks which
		implement the NavControl features.  ContentView must be
		able to send messages to NavControl, and it does so by
		sending a classed event here, to the process.  The process
		then sends it on to the NavControl (or calls its superclass
		if the event's class is not NavControlClass).

CALLED BY:	MSG_META_SEND_CLASSED_EVENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ReaderProcessClass
		ax - the message
		^hcx - ClassedEvent
		dx - TravelOption
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReaderProcessSendClassedEvent		method dynamic ReaderProcessClass,
						MSG_META_SEND_CLASSED_EVENT

		push	cx, si
		mov	bx, cx
		call	ObjGetMessageInfo
		cmp	cx, segment ContentNavControlClass
		jne	callSuper
		cmp	si, offset ContentNavControlClass
		je	sendToNavControl
		mov	di, offset ReaderProcessClass
callSuper:
		pop	cx, si
		GOTO	ObjCallSuperNoLock
		
sendToNavControl:
		pop	cx, si
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_SELF
		GetResourceHandleNS	ContentViewInterface, bx
		mov	si, offset ContentNav
		clr	di
		GOTO	ObjMessage
ReaderProcessSendClassedEvent		endm



if 	_FULL_SCREEN


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSCVUpdateScrollbars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't update the scrollbars, please.

CALLED BY:	MSG_CGV_UPDATE_SCROLLBARS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of FullScreenContentViewClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 2/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSCVUpdateScrollbars		method dynamic FullScreenContentViewClass,
						MSG_CGV_UPDATE_SCROLLBARS
	;
	; Don't callsuper, just make the thing drawable again.
	;
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_IMAGE_INVALID
		mov	dl, VUM_MANUAL
		call	VisCallFirstChild

		mov	ax, MSG_VIS_SET_ATTRS
		clr	cx
		or	ch, mask VA_DRAWABLE
		mov	dl, VUM_NOW
		call	VisCallFirstChild
		ret
FSCVUpdateScrollbars		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSCVCreateFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_CGV_CREATE_FILE_SELECTOR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of FullScreenContentViewClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSCVCreateFileSelector		method dynamic FullScreenContentViewClass,
						MSG_CGV_CREATE_FILE_SELECTOR

	;
	; First, let superclass create the file selector
	;
		mov	di, offset FullScreenContentViewClass
		call 	ObjCallSuperNoLock

	;
	; Now get the file selector's optr so we can change its
	; token for the full-screen version.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].CGVI_fileSelector
	;
	; MAJOR HACK!  I can't think of any other easy way to get the offset
	; offset of the file selector, so I'm hard-coding it. Maybe later
	; when I have more time I'll do it right.  -cassie 
	;
		mov	si, 26h

	; change the token to "fscr"
		
		mov	cl, 'f' 	
		mov	ch, 's' 	
		mov	dl, 'c' 	
		mov	dh, 'r' 	
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_TOKEN
		clr	di
		call	ObjMessage

		ret
FSCVCreateFileSelector		endm

endif

ProcessCode	ends

