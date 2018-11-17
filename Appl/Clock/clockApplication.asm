COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clockApplication.asm

AUTHOR:		Adam de Boor, Feb  2, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 2/92		Initial revision


DESCRIPTION:
	Implementation of ClockAppClass
		

	$Id: clockApplication.asm,v 1.1 97/04/04 14:51:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	clock.def

idata	segment

ClockAppClass

idata	ends

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CAAddOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the passed tree of options to the options DB

CALLED BY:	MSG_CAPP_ADD_OPTIONS
PASS:		*ds:si	= ClockApp object
		^lcx:dx	= root of tree to add
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CAAddOptions	method dynamic ClockAppClass, MSG_CAPP_ADD_OPTIONS
		.enter
		GetResourceHandleNS	FaceOptions, bx
		mov	si, offset FaceOptions
		
	;
	; Deal with restoring from state by first seeing if the root is
	; already in the tree...
	; 
		push	cx, dx
		mov	ax, MSG_GEN_FIND_CHILD
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx
		jnc	done			; yup => do nothing

	;
	; Not already in the tree, so add it at the end.
	; 
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	cx, dx
		call	ObjMessage
	;
	; Set the whole tree usable, so it can be...used, that is.
	; 
		pop	bx, si
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
CAAddOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASetFaceOptionsMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A fun routine to take the moniker for the currently-selected
		face list entry in the ModeList and merge it into a template
		moniker and set it as the moniker for the FaceOptions
		interaction.

CALLED BY:	CASetClock
PASS:		*ds:si	= ClockApp object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		Because of localization, we work with a template moniker that
		contains a \1 where the name from the selected face list
		entry should be placed.
		
		We first duplicate the template moniker, then locate the
		selected list entry and find the number of characters in its
		moniker. After inserting that many bytes at the proper
		place in the duplicated template, we set the duplicate as
		the moniker for the FaceOptions box, then free the old
		moniker, if there was one.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CASetFaceOptionsMoniker proc near
		class	ClockAppClass
		uses	si, es
		.enter
		GetResourceHandleNS	FaceOptions, bx
		call	ObjSwapLock
		push	bx		; save app object's block's handle
		
		CheckHack <segment ModeList eq segment FaceOptions>
		mov	si, offset ModeList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax <- identifier
		mov_tr	cx, ax
		mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
		call	ObjCallInstanceNoLock
EC <		cmp	cx, ds:[LMBH_handle]				>
EC <		ERROR_NE MODE_LIST_ENTRY_NOT_IN_SAME_RESOURCE_AS_FACE_OPTIONS>

	;
	; Duplicate the template moniker.
	; 
		mov	si, offset FaceOptionsTemplateMoniker
		ChunkSizeHandle ds, si, cx
		
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		segmov	es, ds
		mov	bx, ax
		mov	di, ds:[bx]
		mov	si, ds:[si]
		rep	movsb
	;
	; Now find the length of the text in the list entry's moniker.
	; 
   		mov	si, dx
		mov	ax, MSG_GEN_GET_VIS_MONIKER
		call	ObjCallInstanceNoLockES
		
		mov	si, ax
		mov	di, ds:[si]
EC <		test	ds:[di].VM_type, mask VMT_GSTRING		>
EC <		ERROR_NZ MODE_LIST_ENTRY_MONIKER_NOT_TEXTUAL		>
		add	di, offset VM_data + offset VMT_text
if DBCS_PCGEOS
		call	LocalStringSize	;cx <- size w/o NULL
else
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx
		dec	cx		; cx <- length w/o null
endif
		push	cx
	;
	; Locate the \1 in the template moniker.
	; 
		mov	di, ds:[bx]
EC <		test	ds:[di].VM_type, mask VMT_GSTRING		>
EC <		ERROR_NZ FACE_OPTIONS_TEMPLATE_MONIKER_NOT_TEXTUAL	>
DBCS <		mov	ax, 1						>
SBCS <		inc	ax		; al <- 1 (1-byte inst)		>
		ChunkSizePtr ds, di, cx
		add	di, offset VM_data + offset VMT_text
		sub	cx, offset VM_data + offset VMT_text
DBCS <		shr	cx, 1						>
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
		pop	cx		; cx <- length of list entry moniker
					;  text
		jne	haveNewMoniker	; => no \1, so nothing to insert

	;
	; Insert enough room there in the moniker for the list entry's moniker
	; 
		dec	di		; point to \1
DBCS <		dec	di						>
		sub	di, ds:[bx]	; figure offset from base of chunk
					;  for insertion
		mov_trash ax, di	; ax <- offset
		xchg	ax, bx		; ax <- chunk, bx <- offset
		dec	cx		; reduce by 1 to account for
DBCS <		dec	cx					 	>
					;  overwriting \1
EC <		ERROR_S	MODE_LIST_ENTRY_HAS_NO_TEXT_IN_ITS_MONIKER	>
		call	LMemInsertAt
	;
	; Now copy the text from the list entry's moniker into the new moniker
	; 
		mov	di, bx
		mov_trash	bx, ax
		add	di, ds:[bx]	; es:di <- insertion point

		mov	si, ds:[si]	
		add	si, offset VM_data + offset VMT_text
		inc	cx		; account for previous reduction
		rep	movsb

	; 
	; The length of the moniker has changed, so clear the old
	; moniker's cached width.
	;
		mov	di, ds:[bx]	; ds:di <- VisMoniker
		mov	ds:[di].VM_width, 0

haveNewMoniker:
	;
	; Fetch the current moniker so we can free it once we've set
	; the new one.
	; 
		mov	si, offset FaceOptions
		mov	ax, MSG_GEN_GET_VIS_MONIKER
		call	ObjCallInstanceNoLockES
		push	ax		; save for freeing after set
	;
	; And set the new one as the vis moniker for the beast.
	; 
		mov	cx, bx
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		call	ObjCallInstanceNoLockES
	;
	; Now free the old moniker.
	; 
		pop	ax
		tst	ax
		jz	oldMonikerFreed
		call	LMemFree
oldMonikerFreed:
	;
	; Switch back to app's block
	; 
		pop	bx
		call	ObjSwapUnlock
		.leave
		ret
CASetFaceOptionsMoniker endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASetClock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the clock to be displayed.

CALLED BY:	MSG_CAPP_SET_CLOCK
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		cx	= index into CAI_clockOptrs (ClockFaces) of new clock
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CASetClock	method dynamic ClockAppClass, MSG_CAPP_SET_CLOCK
		.enter
	;
	; Find the clock that's to become the new one.
	; 
		shl	cx		; * 4 to index optrs
		shl	cx
		mov	bx, ds:[di].CAI_clockOptrs
EC <		ChunkSizeHandle	ds, bx, ax				>
EC <		cmp	cx, ax						>
EC <		ERROR_AE	CAPP_CLOCK_NUMBER_TOO_LARGE		>
   		mov	bx, ds:[bx]
		add	bx, cx
		mov	cx, ds:[bx].handle
		mov	dx, ds:[bx].chunk
		mov	bx, ds:[LMBH_handle]
		mov	al, RELOC_HANDLE
		call	ObjDoRelocation
	;
	; See if it's the same as our current clock.
	; 
		cmp	ds:[di].CAI_curClock.handle, cx
		jne	switchClocks
		cmp	ds:[di].CAI_curClock.chunk, dx
		je	done			; yes => do nothing

switchClocks:
	;
	; Mark ourselves dirty so the clock change makes it to state.
	; 
		call	ObjMarkDirty
	;
	; Save The Clock That Is To Be
	; 
		push	si			; save ourselves, too :)
		push	cx, dx
	;
	; Tell the current clock to detach itself and remove its options.
	;
		mov	bx, ds:[di].CAI_curClock.handle	; ^lbx:si <- current
		mov	si, ds:[di].CAI_curClock.offset	;  clock
		mov	ax, MSG_VC_DISCONNECT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now attach the new clock.
	;
		pop	bx, si
		mov	ax, MSG_META_ATTACH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Store its optr in our pointer for restarting from state and detaching
	; &c. ...
	; 
		mov	cx, bx
		mov	dx, si
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].ClockApp_offset
		mov	ds:[di].CAI_curClock.handle, cx
		mov	ds:[di].CAI_curClock.chunk, dx
	;
	; Change the moniker for the FaceOptions box to match that of the
	; selected clock face.
	; 
		call	CASetFaceOptionsMoniker
done:
		.leave
		ret
CASetClock	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CAAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we have a current clock face during attachment.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= ClockApp object
		^hdx	= AppLaunchBlock
		bp	= extra state block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CAAttach	method dynamic ClockAppClass, MSG_META_ATTACH
		.enter
		mov	di, offset ClockAppClass
		call	ObjCallSuperNoLock
	;
	; See if we've got a clock face.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].ClockApp_offset
		tst	ds:[di].CAI_curClock.handle
		jnz	done
	;
	; No. Get the default face from the list and set it as the current
	; clock.
	; 
		push	si
		GetResourceHandleNS	ModeList, bx
		mov	si, offset ModeList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		jc	done
		
		mov_tr	cx, ax			; cx <- clock #
		mov	ax, MSG_CAPP_SET_CLOCK
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
CAAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forward interval-change request on to the current clock and
		record it ourselves, for the next clock to use.

CALLED BY:	MSG_CAPP_SET_INTERVAL
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		cx	= new interval (seconds)
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CASetInterval	method dynamic ClockAppClass, MSG_CAPP_SET_INTERVAL
		.enter
		
		mov	ds:[di].CAI_interval, cx

		mov	bx, ds:[di].CAI_curClock.handle
		mov	si, ds:[di].CAI_curClock.chunk
		mov	ax, MSG_VC_SET_INTERVAL
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
CASetInterval	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASetFixedPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current clock to a fixed position on the screen.

CALLED BY:	MSG_CAPP_SET_FIXED_POSITION
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		es	= dgroup
		cx	= ClockFixedPosition
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CASetFixedPosition method dynamic ClockAppClass, MSG_CAPP_SET_FIXED_POSITION
		.enter
	;
	; Get the dimensions of the field window. Don't do this via a VUP_QUERY
	; to the primary, as it may not be visible (might have been iconified
	; or something).
	;
		push	cx, si
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_FIELD
		call	ObjCallInstanceNoLock
		
		mov	bx, cx
		mov	si, dx
		mov	ax, MSG_VIS_GET_SIZE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx, dx <- width, height
		pop	ax, si
	
	;
	; Deal with the X position. When setting the fixed point, we prefer to
	; use 0 or VC_RIGHT_EDGE (or VC_BOTTOM_EDGE), as that's display-
	; independent. When asked to center on the screen, though, we have to
	; use the screen's dimensions instead.
	; 
		shr	cx		; assume center
		cmp	al, J_CENTER
		je	haveX
		mov	cx, 0		; assume left
		cmp	al, J_LEFT
		je	haveX
		mov	cx, VC_RIGHT_EDGE
haveX:
		shr	dx		; assume center
		cmp	ah, J_CENTER
		je	haveY
		mov	dx, 0		; assume top
		cmp	ah, J_LEFT
		je	haveY
		mov	dx, VC_BOTTOM_EDGE
haveY:
	;
	; Send the results to the current clock after saving them away
	; internally.
	; 
		mov_trash	bp, ax
		mov	ax, MSG_VC_SET_FIXED_POSITION
		mov	di, ds:[si]
		add	di, ds:[di].ClockApp_offset

		mov	ds:[di].CAI_fixedPosition.P_x, cx
		mov	ds:[di].CAI_fixedPosition.P_y, dx
		mov	{word}ds:[di].CAI_horizJust, bp
		call	ObjMarkDirty

		mov	bx, ds:[di].CAI_curClock.handle
		mov	si, ds:[di].CAI_curClock.offset
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CASetFixedPosition endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CAUpdateFixedPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the current fixed position of the current clock.

CALLED BY:	MSG_CAPP_UPDATE_FIXED_POSITION
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		cx	= fixed X position
		dx	= fixed Y position
		bp.low	= horizontal justification
		bp.high	= vertical justification
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CAUpdateFixedPosition method dynamic ClockAppClass,
		      		MSG_CAPP_UPDATE_FIXED_POSITION
		.enter
	;
	; Store that position away.
	; 
		mov	ds:[di].CAI_fixedPosition.P_x, cx
		mov	ds:[di].CAI_fixedPosition.P_y, dx
		mov	{word}ds:[di].CAI_horizJust, bp
		call	ObjMarkDirty
	;
	; For now, don't bother to figure if it's one of the cardinal points,
	; just set the location list indeterminate.
	; 
		GetResourceHandleNS LocationList, bx
		mov	si, offset LocationList
		mov	cx, bp
		mov	dx, TRUE	; indeterminate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CAUpdateFixedPosition endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CAGetInitialInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a query from a newly-attached clock to obtain the
		current settings for it.

CALLED BY:	MSG_CAPP_GET_INITIAL_INFO
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
RETURN:		ax	= interval (seconds)
		cx	= fixed X position
		dx	= fixed Y position
		bp.low	= horizontal justification
		bp.high = vertical justification
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CAGetInitialInfo method dynamic ClockAppClass, MSG_CAPP_GET_INITIAL_INFO
		.enter
		mov	ax, ds:[di].CAI_interval
		mov	cx, ds:[di].CAI_fixedPosition.P_x
		mov	dx, ds:[di].CAI_fixedPosition.P_y
		mov	bp, {word}ds:[di].CAI_horizJust
		.leave
		ret
CAGetInitialInfo endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CABringToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with unbanishing ourselves when the user has asked
		us to come to the top, via the express menu usually.

CALLED BY:	MSG_META_NOTIFY_TASK_SELECTED
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CABringToTop	method dynamic ClockAppClass, MSG_META_NOTIFY_TASK_SELECTED
		.enter
		test	ds:[di].GI_states, mask GS_USABLE
		jz	passItUp
		push	ax, cx, dx, bp, si
	;
	; If we're usable, make sure our primary is usable too, and on-screen.
	; 
		mov	si, offset ClockPrimary
		GetResourceHandleNS ClockPrimary, bx
		mov	ax, MSG_GEN_GET_USABLE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jc	done

		mov	ax, MSG_GEN_SET_USABLE
		mov	dx, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Make ourselves focusable and targetable again.
	; 
		pop	si
		push	si
		mov	cx, mask GA_TARGETABLE
		mov	ax, MSG_GEN_SET_ATTRS
		call	ObjCallInstanceNoLock
		
		mov	cx, mask AS_FOCUSABLE or mask AS_MODELABLE
		clr	dx
		mov	ax, MSG_GEN_APPLICATION_SET_STATE
		call	ObjCallInstanceNoLock
	;
	; Raise our geode up, now that we're focusable. This can have the effect
	; of bring ourselves up from out of nowhere, but c'est la vie.
	; 
		call	GeodeGetProcessHandle
		mov	cx, bx
		clr	dx, bp
		mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
		call	UserCallSystem
done:
		pop	ax, cx, dx, bp, si
passItUp:
		mov	di, offset ClockAppClass
		CallSuper	MSG_META_NOTIFY_TASK_SELECTED
		.leave
		ret
CABringToTop	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save whatever options we put in the .ini file

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		ss:bp	= GenOptionsParams (only category used)
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		The only option we save is our fixedPosition and
		justifications

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fixedXString	char	"fixed x", 0
fixedYString	char	"fixed y", 0
justString	char	"justification", 0

CASaveOptions 	method dynamic ClockAppClass, MSG_GEN_SAVE_OPTIONS
		.enter
	;
	; Push the other things we save while we've still got ds:di
	; pointing to our instance data.
	; 
		push	{word}ds:[di].CAI_horizJust,
			ds:[di].CAI_fixedPosition.P_y
		lea	si, ss:[bp].GOP_category
		mov	bp, ds:[di].CAI_fixedPosition.P_x
		segmov	ds, ss			; ds:si <- category
		mov	cx, cs			; cx <- cs
		mov	dx, offset fixedXString	; cx:dx <- key
		call	InitFileWriteInteger
		
		mov	dx, offset fixedYString
		pop	bp
		call	InitFileWriteInteger
		
		mov	dx, offset justString
		pop	bp
		call	InitFileWriteInteger
		.leave
		ret
CASaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CARestoreOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our options from the INI file.

CALLED BY:	MSG_GEN_LOAD_OPTIONS
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CARestoreOptions method dynamic ClockAppClass, MSG_GEN_LOAD_OPTIONS
		.enter
		segmov	es, ds
		segmov	ds, ss
		lea	si, ss:[bp].GOP_category; ds:si <- category
		mov	cx, cs
		mov	dx, offset fixedXString	; cx:dx <- key
		call	InitFileReadInteger
		jc	fetchYPosition
		mov	es:[di].CAI_fixedPosition.P_x, ax
fetchYPosition:
		mov	dx, offset fixedYString	; cx:dx <- key
		call	InitFileReadInteger
		jc	fetchJustification
		mov	es:[di].CAI_fixedPosition.P_y, ax
fetchJustification:
		mov	dx, offset justString	; cx:dx <- key
		call	InitFileReadInteger
		jc	done
		mov	{word}es:[di].CAI_horizJust, ax
done:
		.leave
		ret
CARestoreOptions endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CASendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event down a hierarchy. 

CALLED BY:	MSG_META_SEND_CLASSED_EVENT
PASS:		*ds:si	= ClockApp object
		ds:di	= ClockAppInstance
		dx	= TravelOption
		cx	= handle of classed event
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CASendClassedEvent method dynamic ClockAppClass, MSG_META_SEND_CLASSED_EVENT
	;
	; See if it's a travel option we handle
	; 
		cmp	dx, TO_CUR_CLOCK
		jne	passItUp
	;
	; It is. Send it on its way, or biff the message, if no current
	; clock.
	; 
		mov	bx, ds:[di].CAI_curClock.handle
		mov	si, ds:[di].CAI_curClock.chunk
		tst	bx
		jz	destroyIt
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage
destroyIt:
	;
	; No clock face, so biff the message.
	; 
		mov	bx, cx
		call	ObjFreeMessage
		ret

passItUp:
	;
	; Not our travel option, so let superclass cope.
	; 
		mov	di, offset ClockAppClass
		GOTO	ObjCallSuperNoLock
CASendClassedEvent endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockAppMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore Exit(F3) key when the user use this key to exit
		Clock application. Instead the Clock will be turned
		off by Dates&Time application in Preferences.  

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= ClockAppClass object
		ds:di	= ClockAppClass instance data
		ds:bx	= ClockAppClass object (same as *ds:si)
		es 	= segment of ClockAppClass
		ax	= message #
RETURN:		Nothing
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonCode	ends

