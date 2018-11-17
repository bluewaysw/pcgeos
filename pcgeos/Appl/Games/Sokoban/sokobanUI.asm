COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokobanUI.asm

AUTHOR:		Steve Yegge, Jul  9, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT EnableUndoTrigger       sets-enabled the undo trigger

    INT EnableRestoreTrigger    Enable the restore-position item in the
				Game menu.

    INT UpdateMovesData         Sends the number to the "moves" field in
				the status bar.

    INT UpdatePushesData        Update the status bar entry for pushes.

    INT UpdateLevelData         Updates the "level" display on the status
				bar.

    INT UpdateSavedData         Updates the "saved" display in the status
				bar.

    INT UpdateBagsData          Updates the "bags" field in the status bar.

    MTD MSG_MAP_SET_BACK_COLOR  set the content background color to
				whatever.

    MTD MSG_SOKOBAN_SET_SOUND   Turn sound on or off for the session.

    INT UpdateViewColor         Make sure the view has the right color on
				opening.

    INT UpdateReplayLevelDialog Sets it usable or not-usable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/ 9/93		Initial revision

DESCRIPTION:
	

	$Id: sokobanUI.asm,v 1.1 97/04/04 15:12:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableUndoTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets-enabled the undo trigger

CALLED BY:	MoveBag, MovePlayer

PASS:		ax = MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableUndoTrigger	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	UndoMoveTrigger, bx
		mov	si, offset	UndoMoveTrigger
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
EnableUndoTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableRestoreTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the restore-position item in the Game menu.

CALLED BY:	MoveBag, MovePlayer, SokobanAttachUIToDocument

PASS:		ax = MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/18/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableRestoreTrigger	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Check to see if they have a saved position, and quit if not.
	;
		test	es:[gameState], mask SGS_SAVED_POS
		jz	done

		GetResourceHandleNS	RestorePositionTrigger, bx
		mov	si, offset	RestorePositionTrigger
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage
done:
		.leave
		ret
EnableRestoreTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMovesData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the number to the "moves" field in the status bar.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMovesData	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	MovesValue, bx
		mov	si, offset	MovesValue
		mov	di, mask MF_CALL
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	dx, es:[moves]
		clr	bp
		call	ObjMessage
		
		.leave
		ret
UpdateMovesData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePushesData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the status bar entry for pushes.

CALLED BY:	everybody
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePushesData	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	PushesValue, bx
		mov	si, offset	PushesValue
		mov	di, mask MF_CALL
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	dx, es:[pushes]
		clr	bp
		call	ObjMessage
		
		.leave
		ret
UpdatePushesData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateLevelData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the "level" display on the status bar.

CALLED BY:	everybody
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateLevelData	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	LevelValue, bx
		mov	si, offset	LevelValue
		mov	di, mask MF_CALL
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	dx, es:[level]
		clr	bp
		call	ObjMessage
		
		.leave
		ret
UpdateLevelData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSavedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the "saved" display in the status bar.

CALLED BY:	everybody
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSavedData	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	SavedValue, bx
		mov	si, offset	SavedValue
		mov	di, mask MF_CALL
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	dh
		mov	dl, es:[currentMap].M_header.MH_saved
		clr	bp
		call	ObjMessage
		
		.leave
		ret
UpdateSavedData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateBagsData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the "bags" field in the status bar.

CALLED BY:	everybody	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateBagsData	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	BagsValue, bx
		mov	si, offset	BagsValue
		mov	di, mask MF_CALL
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	dh
		mov	dl, es:[currentMap].M_header.MH_packets
		clr	bp
		call	ObjMessage
		
		.leave
		ret
UpdateBagsData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapContentSetBackColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the content background color to whatever.

CALLED BY:	MSG_MAP_SET_BACK_COLOR

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		cl	= color index
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SET_BACKGROUND_COLOR

MapContentSetBackColor	method dynamic MapContentClass, 
					MSG_MAP_SET_BACK_COLOR
		uses	ax, cx, dx, bp
		.enter
	;
	;  Save the color.
	;
		clr	ch
		mov	es:[colorOption], cx
	;
	;  Tell the view to change color.
	;
		call	UpdateViewColor

		.leave
		ret
MapContentSetBackColor	endm

endif	;	SET_BACKGROUND_COLOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanSetSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn sound on or off for the session.

CALLED BY:	MSG_SOKOBAN_SET_SOUND

PASS:		*ds:si	= SokobanProcessClass object
		ds:di	= SokobanProcessClass instance data
		es	= dgroup
		cx	= SokobanSoundOptions

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanSetSound	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_SET_SOUND
		.enter

		mov	es:[soundOption], cx

		.leave
		ret
SokobanSetSound	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateViewColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the view has the right color on opening.

CALLED BY:	SokobanAttachUIToDocument

PASS:		es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/12/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateViewColor	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Set the view's background color.
	;
		mov	cx, es:[colorOption]
		mov	ch, CF_INDEX
		GetResourceHandleNS	TheView, bx
		mov	si, offset	TheView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_COLOR
		call	ObjMessage
if LEVEL_EDITOR
	;
	; Do the same for the editor
	;
		mov	cx, es:[colorOption]
		mov	ch, CF_INDEX
		GetResourceHandleNS	EditorView, bx
		mov	si, offset	EditorView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_COLOR
		call	ObjMessage
endif
		.leave
		ret
UpdateViewColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateReplayLevelDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets it usable or not-usable.

CALLED BY:	SokobanAttachUIToDocument

PASS:		es = dgroup, dgroup:gameState initialized

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/25/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateReplayLevelDialog	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  If they're in win-game mode, enable, else disable.
	;
		test	es:[gameState], mask SGS_WON_GAME
		jnz	wonGame
		
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jmp	short	update
wonGame:
		mov	ax, MSG_GEN_SET_USABLE
update:
		GetResourceHandleNS	ReplayLevelDialog, bx
		mov	si, offset	ReplayLevelDialog
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
UpdateReplayLevelDialog	endp

CommonCode	ends
