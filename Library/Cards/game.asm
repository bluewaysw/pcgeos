COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Solitaire
FILE:		game.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	9/90		Initial Version

DESCRIPTION:
	This file contains method handlers for GameClass.

RCS STAMP:
$Id: game.asm,v 1.1 97/04/04 17:44:41 newdeal Exp $
------------------------------------------------------------------------------@

CardsClassStructures	segment	resource
	GameClass
CardsClassStructures	ends

;---------------------------------------------------

CardsCodeResource segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Game method for MSG_GAME_SAVE_STATE

		Marks the game object dirty, and sends a message to the
		decks telling them to save state.

Called by:	MSG_GAME_SAVE_STATE

Pass:		*ds:si = Game object
		ds:di = Game instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
	PW	March 23, 1993	modified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSaveState	method dynamic	GameClass, MSG_GAME_SAVE_STATE
	.enter

	call	ObjMarkDirty

	mov	ax, MSG_DECK_SAVE_STATE
	call	VisSendToChildren

	.leave
	ret
GameSaveState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Game method for MSG_GAME_RESTORE_STATE

		seeds the random number generator.

Called by:	MSG_GAME_RESTORE_STATE

Pass:		*ds:si = Game object
		ds:di = Game instance

Return:		nothing

Destroyed:	ax, dx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
	PW	March 23, 1993	modified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRestoreState	method dynamic	GameClass, MSG_GAME_RESTORE_STATE
	.enter

	call	TimerGetCount
	mov_trash	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	ObjCallInstanceNoLock

	.leave
	ret
GameRestoreState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameSendToDecksNoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends a message to all the decks, *not* saving
		registers between calls

Pass:		*ds:si - game
		ax,cx,dx,bp - message data

Return:		ax,cx,dx,bp - return values from message

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 18, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0

GameSendToDecksNoSave	proc	near
	uses	bx, di
	.enter

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	bx, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	push	bx
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	call	ObjCompProcessChildren

	.leave
	ret
GameSendToDecksNoSave	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Game method for MSG_GAME_GET_VM_FILE

Called by:	MSG_GAME_GET_VM_FILE

Pass:		*ds:si = Game object
		ds:di = Game instance

Return:		carry set if error, else
		cx - VM file handle of card bitmaps
		ax - map block to bitmaps

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameGetVMFile	method dynamic	GameClass, MSG_GAME_GET_VM_FILE
	.enter

	mov	cx, ds:[di].GI_vmFile
	mov	ax, ds:[di].GI_mapBlock

	.leave
	ret
GameGetVMFile	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameRestoreBitmaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will read in the BitMap's of the cards

CALLED BY:	MSG_GEM_PROCESS_OPEN_APPLICATION handler

PASS:		*ds:si	= GameClass object

RETURN:		nothing

DESTROYED:	di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRestoreBitmaps	method dynamic GameClass, 
					MSG_GAME_RESTORE_BITMAPS
	.enter

	;
	;	find out our display scheme, determine which resolutio
	;	to use for the card deck, and setup our geometry
	;	
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	GenCallApplication

	push	ax				;save DisplayType

	Deref_DI Game_offset
	mov	ds:[di].GI_displayScheme, ah

NOFXIP<	segmov	es, dgroup, bx			;es = dgroup		>
FXIP  <	mov	bx, handle dgroup					>
FXIP  <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:vmFileHandle
	mov	ds:[di].GI_vmFile, bx
	call	ObjMarkDirty

	call	VMGetMapBlock
	call	VMLock

	pop	bx				;bh <- DisplayType

	push	bp				;save handle
	mov	es, ax 				;ds <- segment of
						;map block

	;; now run through the map block and find the set of bitmaps
	;; we want given the DisplayType.

	mov	cx, es:[DDS_arrayLength]
	mov	di, offset DDS_DRS - size DeckResStruct
					; es:[di] -> first DRS minus one DRS
					; to account for how the
					; loop's written

startLoop:
	add	di, size DeckResStruct
	cmp	bh, es:[di].DRS_displayType

	loopne	startLoop

	;es:di = DeckResStruct of resolution map to use. This means we
	;default to the last entry in the array if nothing else matches.


	mov	bp, ds:[si]
	add	bp, ds:[bp].Game_offset
	mov	ax, es:[di].DRS_mapBlock
	mov	ds:[bp].GI_mapBlock, ax
	call	ObjMarkDirty

	pop	bp				;restore mapblock handle

	call	VMUnlock
	
	mov	ax, MSG_GAME_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	bx, cx				;bx <- vm file handle
	call	VMLock
	push	bp				;save block handle for
						;unlocking
	push	ax				;save block segment for later

	mov	di, ds				;di <- game segment

	mov	ds, ax				;ds <- bitmap segment

	push	si
	mov	si, ds:[0].DMS_interior		;*ds:si -> interior region
	call	CopyRegionToChunk
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_interiorReg, ax
	call	ObjMarkDirty

	pop	ax				;restore block segment

	mov	di, ds				;di <- game segment
	mov	ds, ax				;ds <- bitmap segment

	push	si
	mov	si, ds:[DMS_frame]		;*ds:si -> frame reg
	call	CopyRegionToChunk
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_frameReg, ax
	call	ObjMarkDirty

	pop	bp
	call	VMUnlock

	push	si

	mov	al, mask OCF_IGNORE_DIRTY	;fade array don't go to state
	mov	bx, size optr			;each element of the array
						;will hold an optr
	clr	cx, si
	call	ChunkArrayCreate

	mov	bp, si				;bp <- array offset
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_fadeArray, bp

	mov	ax, MSG_GAME_SEND_CARD_BACK_NOTIFICATION
	call	ObjCallInstanceNoLock

	.leave
	ret
GameRestoreBitmaps	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSetupStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SETUP_STUFF handler for GameClass
		Sets up various sizes and defaults necessary when first
		loading the game in.

CALLED BY:	called by MSG_GEN_PROCESS_OPEN_APPLICATION handler

PASS:		*ds:si = game object
		
CHANGES:	initializes some data slots

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		sets size (currently height=width=600)
		tells geometry manager to not manage children
		

KNOWN BUGS/IDEAS:
could be moved to some ui file?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetupStuff	method	GameClass,MSG_GAME_SETUP_STUFF

	call	TimerGetCount
	mov_trash	dx, ax
	mov	ax, MSG_GAME_SEED_RANDOM
	call	ObjCallInstanceNoLock

	;
	;	find out our display scheme, determine which resolutio
	;	to use for the card deck, and setup our geometry
	;	
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	GenCallApplication

	push	ax				;save DisplayType

	Deref_DI Game_offset
	mov	ds:[di].GI_displayScheme, ah

NOFXIP<	segmov	es, dgroup, bx			;es = dgroup		>
FXIP  <	mov	bx, handle dgroup					>
FXIP  <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:vmFileHandle
	mov	ds:[di].GI_vmFile, bx
	call	ObjMarkDirty

	call	VMGetMapBlock
	call	VMLock

	pop	bx				;bh <- DisplayType

	push	bp				;save handle
	mov	es, ax 				;ds <- segment of
						;map block

	;; now run through the map block and find the set of bitmaps
	;; we want given the DisplayType.

	mov	cx, es:[DDS_arrayLength]
	mov	di, offset DDS_DRS - size DeckResStruct
					; es:[di] -> first DRS minus one DRS
					; to account for how the
					; loop's written

startLoop:
	add	di, size DeckResStruct
	cmp	bh, es:[di].DRS_displayType

	loopne	startLoop

	;es:di = DeckResStruct of resolution map to use. This means we
	;default to the last entry in the array if nothing else matches.


	mov	bp, ds:[si]
	add	bp, ds:[bp].Game_offset
	mov	ax, es:[di].DRS_mapBlock
	mov	ds:[bp].GI_mapBlock, ax
	call	ObjMarkDirty

	mov	cx, es:[di].DRS_upSpreadX
	mov	dx, es:[di].DRS_upSpreadY
	mov	ax, MSG_GAME_SET_UP_SPREADS
	call	ObjCallInstanceNoLock

	mov	cx, es:[di].DRS_downSpreadX
	mov	dx, es:[di].DRS_downSpreadY
	mov	ax, MSG_GAME_SET_DOWN_SPREADS
	call	ObjCallInstanceNoLock

	mov	cx, es:[di].DRS_fontSize
	mov	ax, MSG_GAME_SET_FONT_SIZE
	call	ObjCallInstanceNoLock

	pop	bp				;restore mapblock handle

	push	es:[di].DRS_deckSpreadX
	push	es:[di].DRS_deckSpreadY

	call	VMUnlock
	
	mov	ax, MSG_GAME_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	bx, cx				;bx <- vm file handle
	call	VMLock
	push	bp				;save block handle for
						;unlocking
	push	ax				;save block segment for later

	mov	di, ds				;di <- game segment

	mov	ds, ax				;ds <- bitmap segment

	push	si
	mov	si, ds:[0].DMS_interior		;*ds:si -> interior region
	call	CopyRegionToChunk
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_interiorReg, ax
	call	ObjMarkDirty

	pop	ax				;restore block segment

	mov	di, ds				;di <- game segment
	mov	ds, ax				;ds <- bitmap segment

	push	si
	mov	si, ds:[DMS_frame]		;*ds:si -> frame reg
	call	CopyRegionToChunk
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_frameReg, ax
	call	ObjMarkDirty

	mov	ax, MSG_GAME_SET_CARD_DIMENSIONS
	call	ObjCallInstanceNoLock
	
	pop	bp
	call	VMUnlock

	push	si

	mov	al, mask OCF_IGNORE_DIRTY	;fade array don't go to state
	mov	bx, size optr			;each element of the array
						;will hold an optr
	clr	cx, si
	call	ChunkArrayCreate

	mov	bp, si				;bp <- array offset
	pop	si
	Deref_DI Game_offset
	mov	ds:[di].GI_fadeArray, bp

	pop	dx
	pop	cx
	mov	ax, MSG_GAME_SETUP_GEOMETRY
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GAME_SEND_CARD_BACK_NOTIFICATION
	call	ObjCallInstanceNoLock

	ret
GameSetupStuff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSetCardDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_CARD_DIMENSIONS handler for GameClass

CALLED BY:	

PASS:		*ds:si = game instance
		cx, dx = width, height of a card

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetCardDimensions	method dynamic	GameClass, MSG_GAME_SET_CARD_DIMENSIONS
	uses	cx, dx, bp
	.enter

	mov	ds:[di].GI_cardWidth, cx
	mov	ds:[di].GI_cardHeight, dx
	call	ObjMarkDirty

	mov	ax, MSG_VIS_SET_SIZE
	call	VisSendToChildren

	.leave
	ret
GameSetCardDimensions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameSetUpSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_UP_SPREADS handler for GameClass

CALLED BY:	

PASS:		*ds:si = game instance
		cx, dx = x,y spreads for face up cards

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetUpSpreads	method dynamic	GameClass, MSG_GAME_SET_UP_SPREADS
	.enter

	mov	ds:[di].GI_upSpreadX, cx
	mov	ds:[di].GI_upSpreadY, dx
	call	ObjMarkDirty

	mov	ax, MSG_DECK_SET_UP_SPREADS
	call	VisSendToChildren

	.leave
	ret
GameSetUpSpreads	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameSetDownSpreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_DOWN_SPREADS handler for GameClass

CALLED BY:	

PASS:		*ds:si = game instance
		cx, dx = x,y spreads for face down cards

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 nov 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetDownSpreads	method dynamic	GameClass, MSG_GAME_SET_DOWN_SPREADS
	.enter

	mov	ds:[di].GI_downSpreadX, cx
	mov	ds:[di].GI_downSpreadY, dx
	call	ObjMarkDirty

	mov	ax, MSG_DECK_SET_DOWN_SPREADS
	call	VisSendToChildren

	.leave
	ret
GameSetDownSpreads	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameSendCardBackNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Game method for MSG_GAME_SEND_CARD_BACK_NOTIFICATION

Called by:	MSG_GAME_SEND_CARD_BACK_NOTIFICATION

Pass:		*ds:si = Game object
		ds:di = Game instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSendCardBackNotification	method dynamic	GameClass,
				MSG_GAME_SEND_CARD_BACK_NOTIFICATION
	uses	cx,dx,bp
	.enter

	mov	bx, size NotifyCardBackChange
	call	GameAllocNotifyBlock
	jc	done

	call	MemLock
	mov	es, ax

	mov	ax, MSG_GAME_GET_VM_FILE
	call	ObjCallInstanceNoLock

	mov	es:[NCBC_vmFile], cx
	mov	es:[NCBC_mapBlock], ax

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset
	mov	ax, ds:[di].GI_cardWidth
	mov	es:[NCBC_cardWidth], ax

	mov	ax, ds:[di].GI_cardHeight
	mov	es:[NCBC_cardHeight], ax

	call	MemUnlock

	mov	dx, GWNT_CARD_BACK_CHANGE
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_CARD_BACK_CHANGE
	call	GameUpdateControllerLow

done:
	.leave
	ret
GameSendCardBackNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameAllocNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the block of memory that will be used to
		update the UI.

CALLED BY:

PASS:		bx - size to allocate

RETURN:		bx - block handle
		carry set if unable to allocate

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Initialize to zero 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameAllocNotifyBlock	proc near
	uses	ax, cx
	.enter
	mov	ax, bx			; size
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	done
	mov	ax, 1
	call	MemInitRefCount
	clc
done:
	.leave
	ret
GameAllocNotifyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameUpdateControllerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to update a UI controller

CALLED BY:

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameUpdateControllerLow	proc far
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx <- owner
	clr	si

	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	ret
GameUpdateControllerLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameUpdateFadeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_UPDATE_FADE_ARRAY handler for GameClass
		Manages the chunkarray that keeps track of which
		cards are fading. Cards send this method to the
		game object, along with a request to add or remove it
		from the array. This method also controls the timer
		used to send fade methods (i.e., it starts and stops
		the timer when necessary).
		If a card that already appears in the array asks to be
		added, or if a card not in the array asks to be removed,
		no action is taken.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		^lcx:dx = card requesting an array change
		bp = PLEASE_ADD_ME_TO_THE_ARRAY if card wants its OD
			included in the array,
		     PLEASE_REMOVE_ME_FROM_THE_ARRAY if card wants
			its OD out of the array
		
CHANGES:	If array initially has 0 items, and adds a card to
		itself, then a timer is started (which tells the game
		when to fade cards in) and a gstate is created (to fade
		the cards through).
		If the array has an item to begin with, and removes it,
		then the timer is stopped and the gstate destroyed.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		if (card is already in the array) {
			if (card wants to be removed) {
				remove it;
			}
		}
		else {
			if (card wants to be added) {
				add it;
			}
		}
		if (array was empty to start with) {
			if (array is not empty now) {
				create gstate;
				start timer;
			}
		}
		else if (array had one element to start with) {
			if (array is now empty) {
				stop timer;
				destroy gstate;
			}
		}

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/29/90	Added to implement the
				chunkarray fading mechanism
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLEASE_ADD_ME_TO_THE_ARRAY = 1
PLEASE_REMOVE_ME_FROM_THE_ARRAY = -1
ADDED_TO_THE_ARRAY = 100
REMOVED_FROM_THE_ARRAY = -100

CARD_FADE_PERIOD = 2		;Timer ticks between fades

GameUpdateFadeArray	method	GameClass, MSG_GAME_UPDATE_FADE_ARRAY

	push	si
	mov	si, ds:[di].GI_fadeArray		;*ds:si = array
	push	cx
	call	ChunkArrayGetCount			;get initial array
	pop	ax					;length
	push	cx
	mov	cx, ax
	mov	bx, cs
	mov	di, offset FindElementInFadeArray
	clr	ax
	call	ChunkArrayEnum				;check to see whether
	tst	ax					;the card is already
	jz	didntFindCard				;in the array

	cmp	bp, PLEASE_ADD_ME_TO_THE_ARRAY	;if card wants to fade and is
	je	endGameUpdateFadeArray		;already on the list, then done

	mov	di, ax	
	call	ChunkArrayDelete		;else get it off the list.
	mov	bp, REMOVED_FROM_THE_ARRAY

	CallObjectCXDX	MSG_CARD_CLEAR_FADING, MF_FIXUP_DS

	jmp	endGameUpdateFadeArray
didntFindCard:
	cmp	bp, PLEASE_REMOVE_ME_FROM_THE_ARRAY	;if card wants to be
	je	endGameUpdateFadeArray			;removed and already
							;is, then done.
	call	ChunkArrayAppend
	mov	bp, ADDED_TO_THE_ARRAY
	mov	ds:[di].handle, cx
	mov	ds:[di].chunk, dx
endGameUpdateFadeArray:

	pop	ax
	pop	si
	cmp	ax, 1
	jg	done
	je	hadOneCardToBeginWith

;didntHaveCardsToBeginWith:
	cmp	bp, ADDED_TO_THE_ARRAY
	jne	done

	;
	;	we had no cards to begin with, and now we've added one,
	;	so we need to start a timer and a gstate
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, CARD_FADE_PERIOD
	mov	dx, MSG_GAME_DISTRIBUTE_FADE
	call	TimerStart

	Deref_DI Game_offset
	mov	ds:[di].GI_gState, bp
	call	ObjMarkDirty

if 0	;;; unnecessary for one shot
	mov	ds:[di].GI_faderHandle, bx
	call	ObjMarkDirty
endif
	jmp	done

hadOneCardToBeginWith:
	cmp	bp, REMOVED_FROM_THE_ARRAY
	jne	done

	;
	;	we had one card at the beginning, and removed it, so
	;	we need to stop our fade timer and destroy our gstate
	;
	Deref_DI Game_offset

if 0	;;;changed to one-shot

	clr	bx
	xchg	bx, ds:[di].GI_faderHandle
	call	ObjMarkDirty
EC<	tst	bx	>
EC<	ERROR_Z	CANT_STOP_TIMER_WITH_NULL_HANDLE	>
	clr	ax		; 0 => continual


	call	TimerStop

endif

	clr	bx
	xchg	bx, ds:[di].GI_gState
	call	ObjMarkDirty
EC<	tst	bx	>
EC<	ERROR_Z CANT_DESTROY_GSTATE_WITH_NULL_HANDLE	>
	mov	di, bx
	call	GrDestroyState
done:
	ret
GameUpdateFadeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FindElementInArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for chunk array to find an OD in the
		array

CALLED BY:	ChunkArrayEnum within GameUpdateFadeArray

PASS:		ds:di = array element
		^lcx:dx = card to check
		
CHANGES:	

RETURN:		if card OD matches this element, then:
			carry set
			ds:ax = element
		if card OD doesn't match this element, then
			carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindElementInFadeArray	proc	far

	cmp	ds:[di].chunk, dx
	jne	noMatch
	cmp	ds:[di].handle, cx
	jne	noMatch
	mov	ax, di
	stc
	jmp	done
noMatch:
	clc
done:
	ret
FindElementInFadeArray	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameRegisterDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_REGISTER_DRAG handler for GameClass
		Stores the OD of the deck dragging cards so that we know
		to pass on MSG_META_EXPOSED to it.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		^lcx:dx = instance of DeckClass
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRegisterDrag	method	GameClass, MSG_GAME_REGISTER_DRAG
	mov	ds:[di].GI_dragger.handle, cx		;^lGI_dragger <- OD
	mov	ds:[di].GI_dragger.chunk, dx		;of dragging deck
	call	ObjMarkDirty
	ret
GameRegisterDrag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameDeckSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DECK_SELECTED handler for GameClass

CALLED BY:	

PASS:		^lcx:dx = selected deck
		bp = # of card in deck's composite that was selected
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		default action is to send deck a MSG_DECK_DRAG_OR_FLIP

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDeckSelected	method	GameClass, MSG_GAME_DECK_SELECTED
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_DECK_DRAG_OR_FLIP
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage
GameDeckSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for GameClass

CALLED BY:	

PASS:		*ds:si = game object
		bp = gstate to draw through
		cl = DrawFlags
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		call super class
		check to see if we have a dragging deck
		if so, and if this MSG_VIS_DRAW is an update, tell
		the deck to draw the dragged cards.

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDraw	method	GameClass, MSG_VIS_DRAW
	push	cx				;save DrawFlags
	push	bp
	mov	di, offset GameClass
	CallSuper	MSG_VIS_DRAW
	pop	bp				;restore gstate

	Deref_DI Game_offset
	mov	bx, ds:[di].GI_dragger.handle	;bx <- dragger handle
	pop	cx				;restore DrawFlags
	tst	bx
	jz	dontDrawDragger			;if no dragger, end

	test	cl, mask DF_EXPOSED		;is it an update?
	jz	dontDrawDragger			;if not, end
;drawDragger:
	;
	;	If we have a dragging deck and the call is an update,
	;	we want to draw the dragged cards in case they went off the
	;	edge of the screen and came back
	;
	mov	si, ds:[di].GI_dragger.chunk
	mov	ax, MSG_DECK_DRAW_DRAGS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
dontDrawDragger:
	ret
GameDraw	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameUpdateScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the score internally and on screen

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		if score is to be zeroed:
			cx = dx = 0
		if score is to be set absolutely but not to 0:
			cx = value to set score to
		if score is to be incremented or decremented:
			cx = 0, dx = amount to add to current score
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		sets up score, time then calls ScoreToTextObject

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameUpdateScore	method	GameClass, MSG_GAME_UPDATE_SCORE
	tst	cx				;set score absolutely?
	jnz	continue			;if so, do it
	tst	dx				;setting score to zero?
	jz	continue			;if so, do it
;addToScore:					;otherwise we're adjusting
	mov	cx, ds:[di].GI_score		;the score relatively
	add	cx, dx
continue:
	mov	ax, MSG_GAME_CHECK_MINIMUM_SCORE
	call	ObjCallInstanceNoLock
	
;setScore:	
	mov	ds:[di].GI_score, cx		;save the score
	call	ObjMarkDirty
	mov	si, ds:[di].GI_scoreOutput.chunk
	mov	di, ds:[di].GI_scoreOutput.handle
;	segmov	es, ss
	call	ScoreToTextObject		;write score out
;endGameUpdateScore:
	ret
GameUpdateScore	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameGetBackBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_GET_BACK_BITMAP handler for GameClass
		Returns a pointer to the bitmap to be drawn as the backside
		of the deck.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	nothing

RETURN:		^lcx:dx = bitmap

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameGetBackBitmap	method	GameClass, MSG_GAME_GET_BACK_BITMAP

	push	ds:[di].GI_whichBack

	mov	ax, MSG_GAME_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov	bx, cx				;bx <- vm file handle

	mov	di, ds:[si]
	add	di, ds:[di].Game_offset

	pop	si				;si <- which back
	call	VMLock
	push	bp


	test	ds:[di].GI_gameAttrs, mask GA_USE_WIN_BACK
	push	ds
	mov	ds, ax
	jz	regularBack
	mov	cx, ds:[DMS_winBack].handle
	mov	dx, ds:[DMS_winBack].chunk
	jmp	unlock
regularBack:
	cmp	si, ds:DMS_numBacks
	jb	haveBack
	
	;
	;  For some reason, the back doesn't exist anymore (most likely,
	;  there's a new deck file with fewer backs), so we'll just use
	;  the first one
	;

	clr	si

haveBack:
	shl	si
	shl	si				;si <- fptr
	mov	cx, ds:DMS_backs[si].handle
	mov	dx, ds:DMS_backs[si].chunk

unlock:
	pop	ds
	pop	bp
	call	VMUnlock
	ret

GameGetBackBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameGetFaceBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_GET_FACE_BITMAP handler for GameClass
		Returns a pointer to the bitmap to be drawn 
		given a set of card attributes (card must be face
		up)

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		bp - CardAttrs
		
CHANGES:	nothing

RETURN:		^lcx:dx = bitmap

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameGetFaceBitmap	method	GameClass, MSG_GAME_GET_FACE_BITMAP
	;;calculate which card we want, ordered as follows:
	;;Ace of Diamonds = 0
	;;2 of Diamonds = 1
	;;...
	;;King of Diamonds = 12
	;;Ace of Hearts = 13
	;;...
	;;Ace of Clubs = 26
	;;...
	;;Ace of Spades = 39
	;;...
	;;King of Spades = 51


	;
	;	ax <- suit * 13
	;	diamonds = 0
	;	hearts = 1
	;	clubs = 2
	;	spades = 3
	;
	mov	ax, bp
	ANDNF	ax, mask CA_SUIT

	rept	offset CA_SUIT
	shr	ax
	endm

	mov	cx, 13
	mul	cx

	;
	;	ax += rank - 1
	;	cx = ax
	;
	mov	dx, bp
	ANDNF	dx, mask CA_RANK
	mov	cl, offset CA_RANK

	shr	dx, cl
	dec	dx

	add	ax, dx
	shl	ax
	shl	ax
	push	ax

	;
	;	now that cx has the card number, get the bitmap
	;

	mov	ax, MSG_GAME_GET_VM_FILE
	call	ObjCallInstanceNoLock
	pop	di
	mov_tr	bx, cx
	call	VMLock
	mov	ds, ax
	mov	cx, ds:DMS_cards[di].handle
	mov	dx, ds:DMS_cards[di].chunk
	call	VMUnlock
	ret
GameGetFaceBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameDroppingDragCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DROPPING_DRAG_CARDS handler for GameClass
		This method is called by the dragging deck when the user
		has released the cards. Game calls children asking
		for a deck to accept the dropped cards.

CALLED BY:	DeckEndSelect

PASS:		*ds:si = game object
		^lcx:dx = dropping deck
		bp = drop card attributes		
CHANGES:	

RETURN:		if cards are accepted elsewhere, carry is set
		else carry clear

DESTROYED:	

PSEUDO CODE/STRATEGY:
		gets deck's drop card attributes, then calls children with
		drop deck OD and attributes

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDroppingDragCards	method	GameClass, MSG_GAME_DROPPING_DRAG_CARDS
	mov	ax, MSG_DECK_TAKE_CARDS_IF_OK
	call	VisSendToChildrenWithTest
	ret
GameDroppingDragCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameBroadCastDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_BROADCAST_DOUBLE_CLICK handler for GameClass
		This method is called by a deck when the user double clicks
		one of its cards. Game calls children asking
		for a deck to accept the double-clicked card.

CALLED BY:	DeckCardDoubleClicked

PASS:		*ds:si = game object
		^lcx:dx = double clicked deck
		bp = attributes of double-clicked card
		
CHANGES:	

RETURN:		if card was accepted elsewhere, carry is set
		else carry clear

DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameBroadcastDoubleClick	method	GameClass,MSG_GAME_BROADCAST_DOUBLE_CLICK
	mov	ax, MSG_DECK_TAKE_DOUBLE_CLICK_IF_OK
	call	VisSendToChildrenWithTest
	ret
GameBroadcastDoubleClick	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameCheckHilites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_CHECK_HILITES handler for GameClass
		Broadcasts to children to hilite themselves if they would
		be the destination if cards were dropped right now.

CALLED BY:	DeckOutlinePtr

PASS:		*ds:si = game object
		^lcx:dx = dragging deck
		bp = card attributes of drop card
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bp, cx, dx

PSEUDO CODE/STRATEGY:
		Broadcast MSG_DECK_CHECK_POTENTIAL_DROP to children, asking
		to abort after first potential drop.  If no potential drop,
		send message to self clearing all hilites.

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameCheckHilites	method	GameClass, MSG_GAME_CHECK_HILITES
	mov	ax, MSG_DECK_CHECK_POTENTIAL_DROP		;see if the current
	call	VisSendToChildrenWithTest			;drag will go anywhere
	jc	endGameCheckHilites			;if so, ok

	clr	cx					;otherwise, clear
	clr	dx					;the hilited slots
	mov	ax, MSG_GAME_REGISTER_HILITED
	call	ObjCallInstanceNoLock
endGameCheckHilites:
	ret
GameCheckHilites	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameInvertAcceptors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_INVERT_ACCEPTORS handler for GameClass
		Asks all decks to hilite themselves if they would accept
		the current drag based on the drop card (not on the current
		position of the drag)

CALLED BY:	DeckDraggableCardSelected, DeckEndSelect

PASS:		*ds:si = game object
		^lcx:dx = dragging deck
		bp = card attributes of drop card
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameInvertAcceptors	method	GameClass, MSG_GAME_INVERT_ACCEPTORS

	cmp	ds:[di].GI_userMode, BEGINNER_MODE
	jne	done

	mov	ax, MSG_DECK_INVERT_IF_ACCEPT
	call	VisSendToChildren
done:
	ret
GameInvertAcceptors	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameMarkAcceptors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_MARK_ACCEPTORS handler for GameClass
		Asks all decks to set their DA_WANTS_DRAG bit if they
		would accept the current drag based on the drop card
		(not on the current position of the drag)

CALLED BY:

PASS:		*ds:si = game object
		^lcx:dx = dragging deck
		bp = card attributes of drop card
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameMarkAcceptors		method	GameClass, MSG_GAME_MARK_ACCEPTORS
	push	cx,dx				;save dragger OD
	mov	ax, MSG_DECK_MARK_IF_ACCEPT	;tell decks to mark themselves
	call	VisSendToChildren

	pop	cx,dx				;restore dragger OD

	;;now we want to unmark any special cases (for example, in
	;;klondike, we want to unmark any 2's if we're dragging an ace)

	mov	ax, MSG_GAME_UNMARK_ACCEPTORS
	call	ObjCallInstanceNoLock

;endGameMarkAcceptors:
	ret
GameMarkAcceptors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameRegisterHilited
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_REGISTER_HILITED handler for GameClass
		Keeps track of the one (if any) deck that is currently
		hilited.  Also issues a MSG_DECK_INVERT to this deck
		if it is just now getting hilited (vs. having been hilited
		for multiple calls already).  Also re-inverts the used-to-be
		hlited deck (if any), to make it unhilited.

CALLED BY:	GameCheckHilites, DeckCheckPotentialDrop, DeckEndSelect

PASS:		ds:di = game instance
		*ds:si = game object
		^lcx:dx = hilited deck
		(cx = dx = 0 for no hilited deck)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		if (old hilited = new hilited) {
			don't do anything
		}
		else {
			if (handle != 0) {
				invert new hilited
			}
			GI_hilited = new hilited
			invert old hilited
		}

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRegisterHilited	method	GameClass, MSG_GAME_REGISTER_HILITED
	cmp	ds:[di].GI_hilited.chunk, dx		;old hilited = new?
	je	endGameRegisterHilited			;if so, done
	jcxz	swap					;new hilited = 0?
							;if so, erase old

	CallObjectCXDX	MSG_DECK_INVERT, MF_FIXUP_DS	;else invert new

swap:
	Deref_DI Game_offset
	xchg	ds:[di].GI_hilited.handle, cx		;GI_hilited <- new
	xchg	ds:[di].GI_hilited.chunk, dx		;^lcx:dx <- old
	call	ObjMarkDirty
	jcxz	endGameRegisterHilited

	;
	;	Forcing this to the queue is a hack that solved
	;	a visual bug in intermediate mode klondike...
	;
	CallObjectCXDX	MSG_DECK_CLEAR_INVERTED, MF_FORCE_QUEUE

endGameRegisterHilited:
	ret
GameRegisterHilited	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameCollectAllCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_COLLECT_ALL_CARDS handler for GameClass
		Takes all the cards from all the decks and gives them to
		the hand.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		tell all decks to give their cards to the hand object
		redraw the screen

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameCollectAllCards	method	GameClass, MSG_GAME_COLLECT_ALL_CARDS
	mov	cx, ds:[di].GI_hand.handle	;^lcx:dx <- hand
	mov	dx, ds:[di].GI_hand.chunk

	mov	ax, MSG_DECK_GET_RID_OF_CARDS	;tell all decks to return
						;cards to hand

	call	VisSendToChildren

	mov	ax, MSG_VIS_INVALIDATE		;redraw the screen
	call	ObjCallInstanceNoLock
	ret
GameCollectAllCards	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisSendToChildrenWithTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls children in order with a given method and data, and
		stops after the first one that returns carry set.
		(Just like VisSendToChildren, except tests abort on carry)

CALLED BY:	GameDroppingDragCards, GameBroadcastDoubleClick, GameCheckHilites

PASS:		*ds:si = game object
		ax = method to call children with
		cx, dx, bp = other data (if any)
		
CHANGES:	

RETURN:		if any child returned carry set, carry is returned set
		if no child returned carry set, carry is returned clear

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisSendToChildrenWithTest	proc	far
	class	GameClass		; Indicate function is a friend
					; of GameClass so it can play with
					; instance data.
	
	clr	bx			; initial child (first
	push	bx			; child of composite)
	push	bx

	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	di, OCCT_SAVE_PARAMS_TEST_ABORT
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack

	ret

VisSendToChildrenWithTest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScoreToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a score string and sets the Text Object to display
		this string.

CALLED BY:	GameUpdateScore

PASS:		
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		CX	= Score

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCORE_BUFFER_SIZE	= 14

ScoreToTextObject	proc	far
	uses	di, es
	.enter

	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, dx			; SS to ES and DX!
	sub	sp, SCORE_BUFFER_SIZE		; allocate room on the stack
	mov	di, sp				; ES:DI => buffer to fill
	mov	bp, di				; buffer also in DX:BP
	call	CreateScoreString		; create the string
	clr	cx				; string is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; send the method
	add	sp, SCORE_BUFFER_SIZE		; restore the stack

	.leave
	ret
ScoreToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateScoreString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the score text string

CALLED BY:	ScoreToTextObject

PASS:		cx	= score
		ES:DI	= String buffer to fill

RETURN:		ES:DI	= Points to end of string (NULL termination)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateScoreString	proc	near
	uses	ax, bx, cx, dx
	.enter
	
	; Create the score
	;
	mov	ax, cx
	call	WriteNum
;Done:
SBCS <	mov	{char}es:[di], 0			; NULL terminated >
DBCS <	mov	{wchar}es:[di], 0			; NULL terminated >
	.leave
	ret
CreateScoreString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a number to ASCII, and writes it into a buffer

CALLED BY:	CreateScoreString, WriteTime

PASS:		ES:DI	= Start of string buffer
		AX	= Value to write

RETURN:		ES:DI	= Updated to next string position

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteNum	proc	far
	push	ax, bx, cx, dx			;save regs. necessary?
	clr	bx				;# digits so far
	tst	ax				;negative or positive?
	jge	readValue
;negative:
SBCS <	mov	{byte} es:[di],'-'		;if negative, add a '-' >
DBCS <	mov	{wchar} es:[di],'-'		;if negative, add a '-' >
	LocalNextChar esdi			;advance pointer
	neg	ax				;turn value positive
readValue:
	mov	cx, 10				; put divisor in DL
startReadLoop:
	clr	dx				;we're dividing dx:ax,
						;so we need to clear dx
	div	cx				; do the division
	push	dx				;here's our remainder
	inc	bx				;one more digit...
	cmp	ax, 0				; check the quotient
	jg	startReadLoop
;endReadLoop:
	mov	cx, bx				;cx <- total # of digits
DBCS <	shl	cx, 1				;cx <- total # of bytes	>
	clr	bx				;bx <- # digits printed so far
startWriteLoop:
	pop	dx				;pop digit
	add	dl, '0'				;make it a char
SBCS <	mov	{byte} es:[di][bx], dl		;write it to string	>
DBCS <	mov	{wchar} es:[di][bx], dx		;write it to string	>
	LocalNextChar esbx			;note we've written another
	cmp	bx, cx				;done yet?
	jl	startWriteLoop
;endWriteLoop:
	add	di, cx				;point di after string
	pop	ax, bx, cx, dx			;restore regs
	ret
WriteNum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				WriteTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a time to ASCII, and writes it into a buffer

CALLED BY:	CreatetTimeString

PASS:		ES:BP	= Start of string buffer
		AX	= # of seconds

RETURN:		nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTime	proc	far
	uses	ax, bx, cx, dx, si, di
	.enter

	;
	;	ch <- hours
	;	dl <- minutes
	;	dh <- seconds
	mov	cx, 3600
	clr	dx
	div	cx				;ax <- hours, dx <- seconds

	mov	ch, al
	mov	ax, dx
	clr	dx
	mov	bx, 60
	div	bx				;ax <- minutes; dx <- seconds
	mov	dh, dl
	mov	dl, al

	mov	si, DTF_HMS_24HOUR
	tst	ch
	jnz	callLocal
	mov	si, DTF_MS
callLocal:
	mov	di, bp
	call	LocalFormatDateTime

	.leave
	ret
WriteTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSetDonor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_DONOR handler for GameClass.
		Stores OD of the deck giving cards to another so
		we can undo if need be.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		^lcx:dx = donating deck
		
CHANGES:	GI_lastDonor <- ^lcx:dx
		Undo trigger is enabled

RETURN:		nothing

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:
		store away info and enable undo button

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetDonor method	GameClass, MSG_GAME_SET_DONOR
	mov	ds:[di].GI_lastDonor.handle, cx
	mov	ds:[di].GI_lastDonor.chunk, dx
	mov	bp, ds:[di].GI_score		;preserve the score so
	mov	ds:[di].GI_lastScore, bp	;we can undo that, too.
	call	ObjMarkDirty

	mov	ax, MSG_GAME_ENABLE_UNDO	;since we have the info
	call	ObjCallInstanceNoLock		;to do an undo, let's
						;allow it
	ret
GameSetDonor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameEnableUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_ENABLE_UNDO handler for GameClass
		Sends a MSG_GEN_SET_ENABLED to the undo trigger

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameEnableUndo	method	GameClass, MSG_GAME_ENABLE_UNDO
	mov	dl, VUM_NOW
	mov	bx, ds:[di].GI_undoTrigger.handle
	mov	si, ds:[di].GI_undoTrigger.chunk
	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage
GameEnableUndo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameDisableUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DISABLE_UNDO handler for GameClass
		Sends a MSG_GEN_SET_NOT_ENABLED to the undo trigger

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, dx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDisableUndo	method	GameClass, MSG_GAME_DISABLE_UNDO
	mov	dl, VUM_NOW
	mov	bx, ds:[di].GI_undoTrigger.handle
	mov	si, ds:[di].GI_undoTrigger.chunk
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

GameDisableUndo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameQueryDragCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_QUERY_DRAG_CARD handler for GameClass
		This is the method that a deck calls when one of
		its cards is selected. This method determines whether
		a given card should be included in the drag or not,
		depending on the deck's attributes. For example, in the
		following scenario:


			+--------------------+
			!                    !
			! 6 Hearts           !
			!                    !
			+--------------------+
			!                    !
			! 5 Clubs            !
			!                    !
			+--------------------+
			!                    !
			! 4 Diamonds         !
			!                    !
			+--------------------+
			!                    !
			! 3 Clubs            !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			!                    !
			+--------------------+

		if the 4 is selected, and we are playing klondike
		with the windows-type extension, we want to drag
		the 3 and the 4; we would make three calls to this method;
		calls concering the 3 and 4 would indicate that the
		cards should be draggedf, whereas the 5 would be
		rejected.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		ch = # of selected card		;(the 4 in the above example)
		cl = attrs of selected card	;(the 4 in the above example)

		dh = # of query card
		dl = attrs of query card

		bp = deck attrs
		
CHANGES:	

RETURN:		carry set if accept
		carry clear if no accept

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	9/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameQueryDragCard	method	GameClass, MSG_GAME_QUERY_DRAG_CARD
	ANDNF	bp, mask DA_DDWC			;filter through
							;the info on which
							;cards to drag

	cmp	bp, DDWC_NONE shl offset DA_DDWC	;check if this deck
							;drags cards at all
	jne	notNone
;none:
	clc						;if the deck doesn't
	jmp	endGameQueryDragCard			;drag cards, then
							;clear the carry and
							;return
notNone:
	cmp	bp, DDWC_TOP_ONLY shl offset DA_DDWC
	jne	notTopOnly
;topOnly:
	tst	ch			;if we can only drag the top card, see
	jz	selectedIsTop		;if the selected card is the top
	clc
	jmp	endGameQueryDragCard
selectedIsTop:
	tst	dh		;if selected = query = top card, then accept
	jz	nIsTop
	clc
	jmp	endGameQueryDragCard
nIsTop:
	stc
	jmp	endGameQueryDragCard
notTopOnly:
	cmp	bp, DDWC_UNTIL_SELECTED shl offset DA_DDWC
	jne	notUntilSelected
;untilSelected:			;if we're dragging all cards above and
	cmp	dh, ch		;including the selected card, see if
	jg	queryGreater	;query card is <= selected card
;queryNotGreater:
	stc
	jmp	endGameQueryDragCard
queryGreater:
	clc
	jmp	endGameQueryDragCard
notUntilSelected:			;must be DDWC_TOP_OR_UPS
	tst	ch			;selected = top card?
	jnz	ups			;if not, drag all up cards
;top:
	tst	dh			;if so, see if query = top
	jnz	topSelectedAndQueryNotTop
	stc
	jmp	endGameQueryDragCard
topSelectedAndQueryNotTop:
	clc
	jmp	endGameQueryDragCard
ups:
	test	dl, mask CA_FACE_UP	;we want all up cards, so see
	jnz	cardIsUp		;if query card is face up.
	clc
	jmp	endGameQueryDragCard
cardIsUp:
	stc
endGameQueryDragCard:
	ret
GameQueryDragCard	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameDistributeFade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DISTRIBUTE_FADE handler for GameClass
		Sends a MSG_CARD_FADE_DRAW to every card in the fade array.

CALLED BY:	A timer

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	any fading cards fade in one more step

RETURN:		nothing

DESTROYED:	ax, bx, cx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDistributeFade	method	GameClass, MSG_GAME_DISTRIBUTE_FADE
	push	ds:[LMBH_handle], si
	mov	bp, ds:[di].GI_gState
	mov	cl, ds:[di].GI_incrementalFadeMask
	mov	si, ds:[di].GI_fadeArray
	mov	bx, cs
	mov	di, offset SendCardMethodFade
	call	ChunkArrayEnum

	;
	;  If there're still cards in the array, we need to start another timer
	;
	call	ChunkArrayGetCount			;get initial array
	pop	bx, si
	jcxz	done

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, CARD_FADE_PERIOD
	mov	dx, MSG_GAME_DISTRIBUTE_FADE
	call	TimerStart

done:
	ret
GameDistributeFade	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				SendCardMethodFade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for fading that sends a MSG_CARD_FADE_DRAW
		to a card

CALLED BY:	ChunkArrayEnum in GameDistributeFade

PASS:		ds:di = array element
		bp = gstate to draw through
		cl = incremental fade mask
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/29/90	This callback routine was added when
				the fade mechanism was rewritten to
				incorporate the chunkarray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCardMethodFade	proc	far
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CARD_FADE_DRAW
	call	ObjMessage
	clc					;continue the enumeration
	ret
SendCardMethodFade	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameZeroFadeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_ZERO_FADE_ARRAY handler for GameClass
		Informs all the cards in the fade array that
		they are done fading (like it or not), then
		clears the array and stops the timer (if any) and
		destroys the gstate (if any).

CALLED BY:	

PASS:		ds:di = game instance
		
CHANGES:	clears the fade array, tells any cards that were there
		that they're done fading, kills the timer and gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/29/90	Added to implement chunkarray fading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameZeroFadeArray	method	GameClass, MSG_GAME_ZERO_FADE_ARRAY
	push	si					;save offset
	mov	si, ds:[di].GI_fadeArray
	call	ChunkArrayGetCount
	jcxz	done

if 0	;;;unnecessary for one shot timer
	clr	bx
	xchg	bx, ds:[di].GI_faderHandle
EC<	tst	bx	>
EC<	ERROR_Z	CANT_STOP_TIMER_WITH_NULL_HANDLE	>
	clr	ax		; 0 => continual
	call	TimerStop
endif

	clr	bx
	xchg	bx, ds:[di].GI_gState
EC<	tst	bx	>
EC<	ERROR_Z	CANT_DESTROY_GSTATE_WITH_NULL_HANDLE	>
	mov	di, bx
	call	GrDestroyState

	mov	bx, cs
	mov	di, offset SendCardMethodClearFading
	call	ChunkArrayEnum
	call	ChunkArrayZero
done:
	pop	si					;restore offset
	call	ObjMarkDirty

	ret
GameZeroFadeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SendCardMethodClearFading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that sends a card a method informing
		it that it should mark itself as done fading,

CALLED BY:	ChunkArrayEnum in GameZeroFadeArray

PASS:		ds:di = array element
		
CHANGES:	card in array element gets its CA_FADING bit cleared

RETURN:		nothing

DESTROYED:	ax, bx, di, si

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/29/90	Added to implement chunkarray fading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCardMethodClearFading	proc	far
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CARD_CLEAR_FADING
	call	ObjMessage
	clc
	ret
SendCardMethodClearFading	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSeedRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SEED_RANDOM

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		dx = seed
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSeedRandom	method	GameClass, MSG_GAME_SEED_RANDOM
	mov	ds:[di].GI_randomSeed, dx
	call	ObjMarkDirty
	ret
GameSeedRandom	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a random number between 0 and DL

CALLED BY:	
PASS:		ds:di = game instance
		*ds:si = game object
		DL	= max for returned number
RETURN:		DX	= number between 0 and DL
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This random number generator is not a very good one; it is sufficient
	for a wide range of tasks requiring random numbers (it will work
	fine for shuffling, etc.), but if either the "randomness" or the
	distribution of the random numbers is crucial, you may want to look
	elsewhere.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/11/89		Initial version
	jon	10/90		Customized for GameClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRandom	method	GameClass, MSG_GAME_RANDOM

		mov	cx, dx
		mov	ax, ds:[di].GI_randomSeed
		mov	dx, 4e6dh
		mul	dx
		mov	ds:[di].GI_randomSeed, ax
		call	ObjMarkDirty
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		push	ax
		mov	al, 255
		mul	cl
		mov	dx, ax
		pop	ax
Random2:
		sub	ax, dx
		ja	Random2
		add	ax, dx
		div	cl
		clr	dx
		mov	dl, ah

		ret

GameRandom	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameDrawBlankCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_DRAW_BLANK_CARD handler for GameClass

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		bp = gstate to draw through
		cx,dx = left,top of card
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDrawBlankCard	method	GameClass, MSG_GAME_DRAW_BLANK_CARD
	push	ds:[di].GI_frameReg
	mov	si, ds:[di].GI_interiorReg
	mov	si, ds:[si]
	mov	di, bp

	mov	ax, cx
	mov	bx, dx

	call	GrDrawRegion

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	pop	si
	mov	si, ds:[si]

	call	GrDrawRegion
	ret
GameDrawBlankCard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameDrawFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		
CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameDrawFrame	method	GameClass, MSG_GAME_DRAW_FRAME
	push	ds:[di].GI_frameReg
	mov	di, bp
	mov	ax, C_BLACK
	call	GrSetAreaColor
	
	mov	ax, cx
	mov	bx, dx

	pop	si
	mov	si, ds:[si]
	call	GrDrawRegion
	ret
GameDrawFrame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameFakeBlankCard	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_FAKE_BLANK_CARD handler for GameClass
		Draws a faked blank card (a black-bordered write rectangle
		the size of a card) at the specified place

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		cx,dx = left,top of fake blank card
		bp = gstate to draw through
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameFakeBlankCard	method	GameClass, MSG_GAME_FAKE_BLANK_CARD
	mov	ax, cx
	mov	bx, dx

	mov	cx, ds:[di].GI_cardWidth
	mov	dx, ds:[di].GI_cardHeight
	dec	cx
	dec	dx
	add	cx, ax
	add	dx, bx
	mov	di, bp
	call	GrFillRect

	push	ax

	mov	ax, C_BLACK
	call	GrSetAreaColor

	pop	ax
	call	GrDrawRect
	ret
GameFakeBlankCard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SHUTDOWN handler for GameClass
		Takes care of things that need to be taken care of before
		exiting the application (e.g., turn off the fade timer, etc.)

CALLED BY:	

PASS:		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameShutdown	method	GameClass, MSG_GAME_SHUTDOWN
	;
	;	Stop any fading
	;
	mov	ax, MSG_GAME_ZERO_FADE_ARRAY
	call	ObjCallInstanceNoLock

	ret
GameShutdown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CopyRegionToChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a passed region into a passed lmem chunk

CALLED BY:	GameSetupStuff

PASS:		ds:si = region
		di = object block segment
		
CHANGES:	

RETURN:		*di:ax = newly copied region (suitable for drawing)
		cx = region width
		dx = region height

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyRegionToChunk	proc	near
	push	si

	call	GrGetPtrRegBounds		;si <- end reg,
						;ax,bx <- left, top
						;cx,dx <- right, bottom

	sub	cx, ax
	inc	cx				;cx <- width
	sub	dx, bx
	inc	dx				;dx <- height

	pop	bx

	push	ds
	mov	ds, di				;di <- bitmap segment
	pop	di				;ds <- game segment

	push	cx, dx				;save width, height

	mov	cx, bx
	xchg	cx, si				;cx <- end, si <- start
	sub	cx, si				;cx <- size of region
	add	cx, size Rectangle
	
	mov	al, mask OCF_IGNORE_DIRTY	; ObjChunkFlags for new
						; chunk
	call	LMemAlloc			;get space to store our
						;region
	push	es				;save dgroup
	segmov	es, ds				;es <- game segment
	mov	ds, di				;ds <- bitmap segment
	mov	di, ax
	mov	di, es:[di]			; *es:di = clear space

	push	ax, cx, si
	call	GrGetPtrRegBounds

	stosw
	mov	ax, bx
	stosw
	mov	ax, cx
	stosw
	mov	ax, dx
	stosw
	pop	ax, cx, si
	sub	cx, size Rectangle

	;;at this point, cx = size of region,
	;;		 *ds:si = original region
	;;		 *es:di = empty space for us to copy region into
			 
	rep	movsb				; copy region in

	segmov	ds, es
	pop	es				; restore dgroup

	pop	cx, dx				;region width, height
	ret
CopyRegionToChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameVupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_VUP_QUERY handler for GameClass.

CALLED BY:	

PASS:		*ds:si = game object
		cx = VisUpwardQueryType
		
CHANGES:	

RETURN:		depends on a lot of things...

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameVupQuery	method	GameClass, MSG_VIS_VUP_QUERY

	cmp	cx, VUQ_GAME_OD
	jne	checkAttrs
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	jmp	markQueryHandled

checkAttrs:
	cmp	cx, VUQ_GAME_ATTRIBUTES
	jne	checkFadeMask
	mov	cl, ds:[di].GI_gameAttrs
	jmp	markQueryHandled
checkFadeMask:

	cmp	cx, VUQ_INITIAL_FADE_MASK
	jne	checkBitmaps

	mov	cl, ds:[di].GI_initialFadeMask
	jmp	markQueryHandled

checkBitmaps:
	cmp	cx, VUQ_CARD_BITMAP
	jne	checkDimensionQuery

	mov	ax, MSG_GAME_GET_BACK_BITMAP
	test	bp, mask CA_FACE_UP		;see if card is face down
	jz	getBitmap
	mov	ax, MSG_GAME_GET_FACE_BITMAP
getBitmap:
	call	ObjCallInstanceNoLock
	jmp	markQueryHandled

checkDimensionQuery:
	cmp	cx, VUQ_CARD_DIMENSIONS
	jne	passItOnUp

	mov	cx, ds:[di].GI_cardWidth
	mov	dx, ds:[di].GI_cardHeight
markQueryHandled:
	stc
	jmp	endGameVupQuery

passItOnUp:
	clc
endGameVupQuery:
	ret
GameVupQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_OPEN handler for GameClass
		game marks itself as visually open, then calls superclass

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameVisOpen	method	GameClass, MSG_VIS_OPEN
	RESET	ds:[di].GI_gameAttrs, GA_ICONIFIED
	call	ObjMarkDirty

	mov	di, offset GameClass
	CallSuper	MSG_VIS_OPEN
	ret
GameVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_CLOSE handler for GameClass
		Makes sure that all fading cards are stopped here, then
		calls superclass

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameVisClose	method	GameClass, MSG_VIS_CLOSE
	SET	ds:[di].GI_gameAttrs, GA_ICONIFIED
	call	ObjMarkDirty
	;
	;	Stop any fading
	;
	mov	ax, MSG_GAME_ZERO_FADE_ARRAY
	call	ObjCallInstanceNoLock

	mov	di, offset GameClass
	mov	ax, MSG_VIS_CLOSE
	CallSuper	MSG_VIS_CLOSE
	ret
GameVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear out the optr of the cardback-selection summons when
		we're first brought in from the resource or state.

CALLED BY:	MSG_META_RELOCATE/MSG_META_UNRELOCATE
PASS:		*ds:si = game object
		ds:di	= GameInstance
		ax	= MSG_META_RELOCATE/MSG_META_UNRELOCATE
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
c		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameReloc	method	GameClass, reloc
		.enter
		cmp	ax, MSG_META_RELOCATE
		jne	done

		mov	ds:[di].GI_faderHandle, 0
		mov	ds:[di].GI_gState, 0
		mov	ds:[di].GI_vmFile, 0
		call	ObjMarkDirty

done:
		clc
		.leave
		mov	di, offset GameClass
		call	ObjRelocOrUnRelocSuper
		ret
GameReloc	endp

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameChangeBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives user a summons through which she can select
		among possible card backs

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameChangeBack	method	GameClass, MSG_GAME_CHANGE_BACK
	mov	cx, ds:[di].GI_backSummons.handle
	mov	dx, ds:[di].GI_backSummons.chunk
	jcxz	createSummons

haveSummons:
	CallObjectCXDX	MSG_GEN_INTERACTION_INITIATE, MF_FIXUP_DS

	ret

createSummons:
	mov	ax, MSG_GAME_CREATE_BACK_SUMMONS
	call	ObjCallInstanceNoLock

	Deref_DI Game_offset
	mov	ds:[di].GI_backSummons.handle, cx
	mov	ds:[di].GI_backSummons.chunk, dx
	call	ObjMarkDirty
	jmp	haveSummons
GameChangeBack	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameChooseBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the backs of all the cards to match the one
		the user has chosen.

CALLED BY:	MSG_GAME_CHOOSE_BACK
PASS:		ds:di = game instance
		*ds:si = game object
		cx - which back

RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/ 1/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameChooseBack	method	GameClass, MSG_GAME_CHOOSE_BACK

	;;	user has the right to get rid of the win back, if
	;;	he so chooses...

	RESET	ds:[di].GI_gameAttrs, GA_USE_WIN_BACK
	mov	ds:[di].GI_whichBack, cx
	call	ObjMarkDirty

	mov	ax, MSG_DECK_CHANGE_KIDS_BACKS
	call	VisSendToChildren

	mov	ax, MSG_DECK_REDRAW
	call	VisSendToChildren
	ret

GameChooseBack	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSetFadeParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_FADE_PARAMETERS handler for GameClass
		Sets the value of the initial and incremental area masks
		to use while fading cards in.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		dl = initial area mask (e.g., SDM_0 for full-fledged fading,
				SDM_100 for no fading).
		cl = incremental area mask (e.g., SDM_25 - SDM_0)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetFadeParameters	method	GameClass, MSG_GAME_SET_FADE_PARAMETERS
	mov	ds:[di].GI_incrementalFadeMask, cl
	mov	ds:[di].GI_initialFadeMask, dl
	call	ObjMarkDirty
	ret
GameSetFadeParameters	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameGetDragType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_GET_DRAG_TYPE handler for GameClass
		Returns the drag mode we're in (i.e., full or outline drag)

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	nothing

RETURN:		cl = DragType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameGetDragType	method	GameClass, MSG_GAME_GET_DRAG_TYPE
	mov	cl, ds:[di].GI_dragType
	ret
GameGetDragType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameSetDragType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_DRAG_TYPE handler for GameClass
		Sets the drag mode to the passed value

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		cl = DragType
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetDragType	method	GameClass, MSG_GAME_SET_DRAG_TYPE
	mov	ds:[di].GI_dragType, cl
	call	ObjMarkDirty
	ret
GameSetDragType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameGetUserMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_GET_USER_MODE handler for GameClass
		Returns UserMode (Beginner, Intermediate, Advanced)

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		cl = UserMode

DESTROYED:	cl

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameGetUserMode	method	GameClass, MSG_GAME_GET_USER_MODE
	mov	cl, ds:[di].GI_userMode
	ret
GameGetUserMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameSetUserMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_SET_USER_MODE handler for GameClass
		Sets the user mode to the passed value

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		cl = desired UserMode
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSetUserMode	method	GameClass, MSG_GAME_SET_USER_MODE
	mov	ds:[di].GI_userMode, cl
	call	ObjMarkDirty
	ret
GameSetUserMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				GameHandSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_HAND_SELECTED handler for GameClass
		This is actually a method that will be widely subclassed,
		but I'm putting in this default handler 'cause I get
		off on these things.

CALLED BY:	

PASS:		ds:di = game instance
		*ds:si = game object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		default is to send self MSG_GAME_DECK_SELECTED with
		the deck = the hand and the selected card = the top card

KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameHandSelected	method	GameClass, MSG_GAME_HAND_SELECTED
	mov	cx, ds:[di].GI_hand.handle
	mov	dx, ds:[di].GI_hand.offset
	clr	bp
	mov	ax, MSG_GAME_DECK_SELECTED
	call	ObjCallInstanceNoLock
	ret
GameHandSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBLESetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a CardBackListEntry object

CALLED BY:	MSG_CBLE_SETUP
PASS:		ds:di = game instance
		*ds:si	= CardBackListEntry object
		ds:di	= CardBackListEntryInstance
		cx:dx	= VM handle and offset of bitmap to show
		bp	= VM File handle of deck
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
CBLESetup	method	CardBackListEntryClass, MSG_CBLE_SETUP
		.enter
	;
	; Record the handle and offset of our color-with-bitmap thingummy
	; 
		mov	ds:[di].CBLE_bitmap.handle, cx
		mov	ds:[di].CBLE_bitmap.offset, dx
		mov	ds:[di].CBLE_file, bp
		
		push	cx
		
		mov	cx, size VisMoniker + size OpEndString
		mov	ax, mask OCF_IGNORE_DIRTY
		call	LMemAlloc
		mov	di, ax
		mov	di, ds:[di]

	;
	; Initialize the visual moniker we're going to give ourselves. The
	; thing is an empty string with the height and width of the bitmap
	; we're displaying (so our entry is the right size on-screen).
	;
		mov	ds:[di].VM_type, VisMonikerType <
			0,		; not a list
			1,		; is a gstring
			VMAR_NORMAL,	; regular aspect
			DC_COLOR_4	; color type (no one cares)
		>

		pop	cx
		push	ax
		xchg	ax, cx
		mov	bx, bp
		call	VMLock
		mov	es, ax
		mov	bx, dx
		mov	cx, es:[bx+2].B_width
		mov	dx, es:[bx+2].B_height
		call	VMUnlock		

		mov	ds:[di].VM_size.XYS_width, cx
		mov	ds:[di].VM_size.XYS_height, dx
		mov	({OpEndString}ds:[di].VM_data).OES_opcode, GR_END_STRING
		
	;
	; Now set the chunk as our moniker.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		pop	ds:[di].GI_visMoniker
		call	ObjMarkDirty
		.leave
		ret
CBLESetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBLEDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a CardBackListEntry properly

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= CardBackListEntry object
		bp	= gstate to use
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CBLEDraw	method	CardBackListEntryClass, MSG_VIS_DRAW
		.enter
	;
	; Let our superclass do its list-entry thing.
	;
		push	bp
		mov	di, offset CardBackListEntryClass
		CallSuper	MSG_VIS_DRAW
		pop	di

	;
	; Now figure our actual width and height and save our origin.
	; 
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset
		push	ds:[bx].VI_bounds.R_left
		push	ds:[bx].VI_bounds.R_top

		mov	cx, ds:[bx].VI_bounds.R_right
		sub	cx, ds:[bx].VI_bounds.R_left
		inc	cx

		mov	dx, ds:[bx].VI_bounds.R_bottom
		sub	dx, ds:[bx].VI_bounds.R_top
		inc	dx

	;
	; Lock down our bitmap.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Gen_offset
		mov	ax, ds:[bx].CBLE_bitmap.handle
		mov	si, ds:[bx].CBLE_bitmap.offset
		mov	bx, ds:[bx].CBLE_file

		call	VMLock
		mov	ds, ax
		
	;
	; Set the area color properly.
	;
		lodsw
		call	GrSetAreaColor
		
	;
	; Figure where to position the bitmap by taking the difference of our
	; actual width/height and the bitmap's width/height, dividing it by
	; two and adding it to our origin.
	; 
		sub	cx, ds:[si].B_width
		sub	dx, ds:[si].B_height
		shr	cx
		shr	dx
		pop	ax
		add	ax, dx
		xchg	bx, ax
		pop	ax
		add	ax, cx
	;
	; Draw the bitmap itself.
	; 
		clr	dx		; no callback...
		call	GrDrawBitmap
	;
	; Unlock the bitmap.
	;
		call	VMUnlock
	;
	; Return gstate in bp, in case it's needed there...
	; 
		mov	bp, di
		.leave
		ret
CBLEDraw	endp
endif
GameGetWhichBack	method	GameClass, MSG_GAME_GET_WHICH_BACK
	mov	cx, ds:[di].GI_whichBack
	ret
GameGetWhichBack	endm

GameSetWhichBack	method	GameClass, MSG_GAME_SET_WHICH_BACK
	mov	ds:[di].GI_whichBack, cx
	call	ObjMarkDirty
	ret
GameSetWhichBack	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameTransferringCards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_TRANSFERRING_CARDS handler for GameClass
                This is called by the donor deck when cards are dropped and
                transferred to another deck. Makes a good message to 
                intercept for generating sound.

CALLED BY:	Donor deck object

PASS:		ds:di = game instance
		*ds:si = game object
                ^lcx:dx = deck to which cards will be transferred
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameTransferringCards   method	GameClass, MSG_GAME_TRANSFERRING_CARDS
	ret
GameTransferringCards	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameTransferFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GAME_TRANSFER_FAILED handler for GameClass
                This is called by the source deck when cards are dropped and 
                no deck accepts them, just prior to animating the failed 
                transfer. Makes a good message to  intercept for generating 
                sound.

CALLED BY:	Source deck object

PASS:		ds:di = game instance
		*ds:si = game object
                ^lcx:dx = source deck
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameTransferFailed      method	GameClass, MSG_GAME_TRANSFER_FAILED
	ret
GameTransferFailed	endm

CardsCodeResource ends
