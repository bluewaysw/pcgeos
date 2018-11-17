COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiEMOM.asm

AUTHOR:		Adam de Boor, Sep 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/14/94		Initial revision


DESCRIPTION:
	Implementation of the MailboxEMOM class, which manages our hooking of
	express menus for placing the inbox/outbox control panel triggers where
	the user can get to them.
		

	$Id: uiEMOM.asm,v 1.1 97/04/05 01:18:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP IF THIS IS FALSE

MailboxClassStructures	segment	resource

MailboxEMOMClass		; declare class record

MailboxPanelTriggerClass	; declare class record

MailboxClassStructures	ends

MailboxEMOMCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMOMEmomInitializeItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a created item

CALLED BY:	MSG_EMOM_INITIALIZE_ITEM
PASS:		*ds:si	= MailboxEMOM object
		ds:di	= MailboxEMOMInstance
		^lcx:dx	= new item
		bp	= MEMOMObjectType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Tell the thing what panel type it is (pass it bp)
		Set it usable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MEMOMEmomInitializeItem method dynamic MailboxEMOMClass, 
			MSG_EMOM_INITIALIZE_ITEM
		.enter
	;
	; Tell it the panel type for which it was created. It will then figure
	; what its moniker should be, add itself to the appropriate GCN lists,
	; define its action descriptor, etc.
	; 
		movdw	bxsi, cxdx
		mov	cx, bp
		mov	ax, MSG_MPT_SET_PANEL_TYPE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set the thing usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MEMOMEmomInitializeItem endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMOMNotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If an express menu is going away, make sure the triggers we
		created are off the mailbox app GCN lists.

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE
PASS:		*ds:si	= MailboxEMOM object
		ds:di	= MailboxEMOMInstance
		^lcx:dx	= affected EMC
		bp	= GCNExpressMenuNotificationType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MEMOMNotifyExpressMenuChange method dynamic MailboxEMOMClass, 
				MSG_NOTIFY_EXPRESS_MENU_CHANGE
		uses	ax, cx, dx, bp, si
		.enter
		cmp	bp, GCNEMNT_DESTROYED
		jne	done
		
		mov	si, ds:[di].EMOMI_expressMenus
		tst	si
		jz	done
		mov	bp, ds:[di].EMOMI_numClasses
		mov	bx, cs
		mov	di, offset MEMOMMenuDeletedCallback
		call	ChunkArrayEnum
done:
		.leave
		mov	di, offset MailboxEMOMClass
		GOTO	ObjCallSuperNoLock
MEMOMNotifyExpressMenuChange endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMOMMenuDeletedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to find an express menu that's going away
		and tell the mailbox app object that the children we created
		in the menu should no longer be on any GCN list

CALLED BY:	(INTERNAL) MEMOMNotifyExpressMenuChange via
			   ChunkArrayEnum
PASS:		ds:di	= EMOMExpressMenu to check
		^lcx:dx	= express menu going away
		bp	= number of objects created in each menu
RETURN:		carry set to stop enumerating
DESTROYED:	ax, bx, si, di allowed
		bp allowed in final iteration
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		It would be better if the MailboxPanelTrigger could deal with
		this shme itself, but the detach mechanism for controllers
		gives no notification to any child, so we have to do the work
		here instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MEMOMMenuDeletedCallback proc	far
		.enter
	;
	; See if this is the menu that's going away.
	; 
		cmpdw	ds:[di].EMOMEM_expressMenu, cxdx
		clc
		jne	done		; => nope, so keep looking
	;
	; Found the menu. Find the first existing child we created in the
	; menu and assume all children are in that same block.
	; 
		push	cx, dx
		add	di, offset EMOMEM_createdObject
objLoop:
		mov	cx, ds:[di].handle
		tst	cx
		jnz	foundBlock

		add	di, size optr	; advance to next possible child
		dec	bp
		jnz	objLoop
		jmp	menuOffLists

foundBlock:
	;
	; Found an existing child. Let our app object know to remove all
	; objects in this block from its GCN lists.
	; 
		mov	ax, MSG_MA_REMOVE_BLOCK_OBJECTS_FROM_ALL_GCN_LISTS
		mov	di, mask MF_FIXUP_DS
		call	UtilCallMailboxApp

menuOffLists:
		pop	cx, dx		; ^lcx:dx <- express menu, again
		stc			; => stop looking
done:
		.leave
		ret
MEMOMMenuDeletedCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPTMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the appropriate GCN list on the UI
		application object

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= MailboxPanelTrigger object
		ds:di	= MailboxPanelTriggerInstance
RETURN:		nothing
DESTROYED:	object
SIDE EFFECTS:	wheee

PSEUDO CODE/STRATEGY:
		This routine *cannot* use the GOTO macro to get to 
			ObjGotoSuperTailRecurse, as we may be gone
			by the time ObjCallSuperNoLock returns to us (in the
			EC case)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPTMetaFinalObjFree method dynamic MailboxPanelTriggerClass, 
				MSG_META_FINAL_OBJ_FREE
	;
	; Remove ourselves from the appropriate GCN list.
	;
			CheckHack <MEMOMOT_INBOX_PANEL eq 0>
		mov	ax, MGCNLT_INBOX_CHANGE
		test	ds:[di].MPTI_state, mask MPTS_TYPE
		jz	haveList
		mov	ax, MGCNLT_OUTBOX_CHANGE
haveList:
		call	UtilRemoveFromMailboxGCNList
	;
	; Let our superclass take care of the rest, being careful not to force
	; it to return to our code, since we may be gone by the time it's done.
	;
		mov	ax, MSG_META_FINAL_OBJ_FREE
		mov	di, offset MailboxPanelTriggerClass
		jmp	ObjGotoSuperTailRecurse
MPTMetaFinalObjFree endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPTSetPanelType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup all aspects of this trigger based on the panel type

CALLED BY:	MSG_MPT_SET_PANEL_TYPE
PASS:		*ds:si	= MailboxPanelTrigger object
		ds:di	= MailboxPanelTriggerInstance
		cx	= MEMOMObjectType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	moniker is set, object is added to GCN list to know when the
     			box with which it's concerned has had a message added
			or removed so it can update its moniker appropriately

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPTSetPanelType	method dynamic MailboxPanelTriggerClass, MSG_MPT_SET_PANEL_TYPE
		.enter
		Assert	etype, cx, MEMOMObjectType
	;
	; Remember the box to watch.
	; 
			CheckHack <offset MPTS_TYPE eq 0>
		mov	ds:[di].MPTI_state, cl
	;
	; Add us to the right GCN list in the mailbox app object.
	; 
			CheckHack <MEMOMOT_INBOX_PANEL eq 0>
		mov	ax, MGCNLT_INBOX_CHANGE
		jcxz	addToList
		mov	ax, MGCNLT_OUTBOX_CHANGE
addToList:
		call	UtilAddToMailboxGCNList

	;
	; Act as if the thing just changed state and "recreate" the moniker
	; 
		call	MPTSetMoniker

	;
	; Set our action descriptor appropriately.
	; 
		mov	ax, MSG_MA_DISPLAY_SYSTEM_INBOX_PANEL	; assume inbox
			CheckHack <MEMOMOT_INBOX_PANEL eq 0>
		jcxz	setActionMsg			; yup!

		mov	ax, MSG_MA_DISPLAY_SYSTEM_OUTBOX_PANEL
setActionMsg:
		mov_tr	cx, ax
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		call	ObjCallInstanceNoLock
	    ;
	    ; Message always sent to our application object.
	    ; 
		mov	cx, handle MailboxApp
		mov	dx, offset MailboxApp
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		call	ObjCallInstanceNoLock
	;
	; Mark ourselves as bringing up a window.
	; 
		mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
		clr	cx
		call	ObjVarAddData
		.leave
		ret
MPTSetPanelType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPTSetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the moniker for the trigger, based on the panel type and
		the contents of the box we're watching

CALLED BY:	(INTERNAL) MPSetPanelType
PASS:		*ds:si	= MailboxPanelTrigger object
RETURN:		nothing
DESTROYED:	ax, bx, dx, di
SIDE EFFECTS:	any existing moniker is destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPTSetMoniker	proc	near
		uses	cx, bp, es
		class	MailboxPanelTriggerClass
		.enter
	;
	; Figure out whether the box we're watching is empty or not.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MailboxPanelTrigger_offset
			CheckHack <MEMOMOT_INBOX_PANEL eq 0>
			CheckHack <width MPTS_TYPE eq 1>
		test	ds:[di].MPTI_state, mask MPTS_TYPE
		jz	getInbox
		call	AdminGetOutbox
		mov	bp, offset uiOutboxParts
		jmp	haveDBQ
getInbox:
		call	AdminGetInbox
		mov	bp, offset uiInboxParts

haveDBQ:
	; bxdi = DBQ
	; bp = bitmap chunk if empty (bp+2 = chunk if not empty)
		call	DBQGetCount
		or	dx, ax			; just need zero/non-z
	;
	; Make sure we've got the size & coordinate info we need for drawing
	; this gstring.
	; 
		call	MPTEnsureSizes		; es <- dgroup
		mov	bx, ds:[LMBH_handle]
		push	si			; save object chunk for setting
						;  moniker
		push	bx			; save mem block for fixup
	;
	; Create a chunk-based gstring, storing the chunk & "gstring handle"
	; away for our subroutines and later use.
	; 
			CheckHack <GST_CHUNK eq 0>
		clr	cl
		call	GrCreateGString		; si <- chunk handle
		push	si			; save chunk handle for resize
						;  and moniker set

	;
	; Lock down the block holding the moniker text and the two graphics from
	; which we get to choose.
	; 
		mov	bx, handle ROStrings
		call	MemLock
		mov	ds, ax
	;
	; Figure which graphic to draw and draw it.
	; 
		mov	si, offset BMP_emptyGraphic	; assume empty
		tst	dx
		jz	haveGraphic			; yes
		mov	si, offset BMP_fullGraphic
haveGraphic:
		mov	si, ds:[bp][si]		; *ds:si <- bitmap to draw
		mov	si, ds:[si]
		clr	dx			; dx <- no callback		

		clr	ax			; x <- 0
		mov	bx, es:[uiMPTGraphicY]	; y <- graphic y
		call	GrFillBitmap
	;
	; Draw the text at the appropriate Y offset just to the right of the
	; graphic.
	; 
		mov	ax, BOX_GRAPHIC_WIDTH+BOX_TRIGGER_GUTTER
						; x <- text start
		mov	bx, es:[uiMPTTextY]	; y <- text y
		mov	si, ds:[bp].BMP_string	; *ds:si <- string
		mov	si, ds:[si]
		clr	cx
		call	GrDrawText
	;
	; Release the string block and finish out the gstring.
	; 
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		call	GrEndGString

		mov	si, di			; si <- handle from create
		clr	di			; di <- no other gstate to biff
		mov	dl, GSKT_LEAVE_DATA	; dl <- leave the data in the
						;  chunk, please
		call	GrDestroyGString
	;
	; The gstring is now complete. Now we need to prepend the requisite
	; VisMoniker cruft. First get DS pointing back at the destination
	; block, please.
	; 
		pop	ax			; ax <- new moniker chunk
		pop	bx			; bx <- object block
		call	MemDerefDS		; *ds:ax = gstring data
		clr	bx			; bx <- insert at start
		mov	cx, size VisMoniker + size VisMonikerGString
		call	LMemInsertAt
	;
	; Initialize the VisMoniker stuff:
	; 	- it's a normal-aspect gstring moniker that is appropriate for
	;	  all displays, regardless of color type.
	;	- its width and height are unknown
	; 
		mov	si, ax
		mov	si, ds:[si]
		mov	ds:[si].VM_type, mask VMT_GSTRING or \
				(DAR_NORMAL shl offset VMT_GS_ASPECT_RATIO) or \
				(DC_TEXT shl offset VMT_GS_COLOR)
		mov	ds:[si].VM_width, 0
		mov	({VisMonikerGString}ds:[si].VM_data).VMGS_height, 0
	;
	; Call the method to make use of this moniker, saving the old chunk for
	; freeing.
	; 
		mov_tr	cx, ax
		pop	si		; *ds:si <- object
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	ds:[di].GI_visMoniker	; save chunk for save
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Free the old moniker if it existed.
	; 
		pop	ax
		tst	ax
		jz	done
		call	LMemFree
done:
		.leave
		ret
MPTSetMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPTEnsureSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our global variables hold the values needed for
		creating our moniker.

CALLED BY:	(INTERNAL) MPTSetMoniker
PASS:		nothing
RETURN:		es	= dgroup
		uiSystemFontHeight definitely set
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPTEnsureSizes	proc	near
		uses	cx, dx, bp, si
		.enter
		segmov	es, dgroup, ax
		tst	es:[uiSystemFontHeight]
		jnz	done
	;
	; Ask ourselves for a gstate for these calculations.
	; 
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock	; bp <- gstate for calc
		mov	di, bp
	;
	; Get the max adjusted height of the system font to use
	; as the line height for things in the moniker.
	; 
		mov	si, GFMI_MAX_ADJUSTED_HEIGHT
		call	GrFontMetrics
		mov	es:[uiSystemFontHeight], dx
	;
	; Nuke the gstate again.
	; 
		call	GrDestroyState
	;
	; We want to draw the graphic and text vertically centered within
	; the moniker, so figure out which is bigger, the text or the graphic,
	; and divide the difference by 2 to figure where the thing should go.
	; 
		clr	ax
		sub	dx, BOX_GRAPHIC_HEIGHT
		sar	dx
		jg	haveYOffsets
		neg	dx		; make the difference positive
		xchg	ax, dx		; and set it as the text Y, with 0
					;  as the graphic Y, since the text is
					;  shorter than the graphic
haveYOffsets:
		mov	es:[uiMPTGraphicY], dx
		mov	es:[uiMPTTextY], ax
done:
		.leave
		ret
MPTEnsureSizes	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPTReactToBoxChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	React to any change in our box contents by adjusting our
		moniker.

CALLED BY:	MSG_MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= MailboxPanelTrigger object
		ds:di	= MailboxPanelTriggerInstance
		cxdx	= MailboxMessage affected
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPTReactToBoxChange method dynamic MailboxPanelTriggerClass, 
		    	MSG_MB_NOTIFY_BOX_CHANGE
		.enter
		call	MPTSetMoniker
		.leave
		ret
MPTReactToBoxChange endm

MailboxEMOMCode	ends

endif	; _CONTROL_PANELS
