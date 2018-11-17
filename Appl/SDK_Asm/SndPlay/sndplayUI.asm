COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SndPlay (Sample PC GEOS application)
FILE:		sndplayUI.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/16/93		Initial version

DESCRIPTION:

	This file contains routines called by the UI objects.
	For example, if you press the "Play" button, the button
	will send MSG_SND_PLAY_PLAY to your process.  The handler
	for that message is in this file, along with many others.

RCS STAMP:
	$Id: sndplayUI.asm,v 1.1 97/04/04 16:32:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayPressedNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Someone pressed a button.  Do something.

CALLED BY:	MSG_SND_PLAY_PRESSED_NOTE

PASS:		ds = dgroup
		cx = NoteType pressed

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:
		Sends a note event to the Music Stream

		<plus anything YOU do>

PSEUDO CODE/STRATEGY:
		play a note

		See if we are recording new notes, or
			editing existing ones

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayPressedNote	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_PRESSED_NOTE
		uses	ax, cx, dx, bp
		.enter
	;
	;  No matter which mode we are in, we want
	;	to make a beep appropriate to the
	;	current duration and note selection
	;
		mov	bx, cx				; bx = NoteType
		mov	si, ds:[currentDuration]	; si = SoundNoteDuration
		
		call	SoundPlayPlayEvent	; nothing destroyed
	;
	;  If we're recording, then we insert the note into
	;  the list, otherwise we just bail.
	;
		cmp	ds:[currentState], SCS_RECORDING
		jne	done

		mov	dx, ds:[currentDuration]
		call	SoundPlayInsertNote	; nothing destroyed

	;
	; Update current position to reflect new note
	;
		call	SoundPlayUpdateCurrentPosition
						; nothing destroyed

	;
	; Update Scan UI to reflect new note
	;
		call	SoundPlayUpdateScan	; nothing destroyed
		
done:
		.leave
		ret
SoundPlayPressedNote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayUpdateDuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the current duration

CALLED BY:	MSG_SND_PLAY_UPDATE_DURATION

PASS:		ds	= dgroup
		cx	= SoundNoteDuration selected

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:
		Sets currentDuration in idata

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayUpdateDuration	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_UPDATE_DURATION
		.enter

		mov	ds:[currentDuration], cx

		.leave
		ret
SoundPlayUpdateDuration	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the current state

CALLED BY:	MSG_SND_PLAY_STOP

PASS:		ds = dgroup

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:
		Can stop Music stream if playing

PSEUDO CODE/STRATEGY:
		Determine current state

		If recording,
			stop recording

		If playing,
			stop playing

		Enter Edit State

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayStop	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_STOP
		uses	ax, cx, dx, bp
		.enter

		mov	ax, ds:[currentState]
	;
	;  If we are already in edit mode, we don't need
	;  to do anything -- just quit.
	;
		cmp	ax, SCS_EDITING
		je	done

	;
	;  If we are recording, we just return to edit mode,
	;  but if we are playing, we need to stop the Music stream.
	;
		cmp	ax, SCS_RECORDING
		je	returnToEditMode

	;
	;  Turn off all the voices
	;
		call	SoundPlayClearVoice	; nothing destroyed

returnToEditMode:
	;
	;  Set up the UI for editing-mode.
	;
		call	SetupUIForEditing	; nothing destroyed

		mov	ds:[currentState], SCS_EDITING
		call	SoundPlayUpdateCurrentState
done:
	.leave
	ret
SoundPlayStop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIForEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables appropriate UI objects for editing songs.

CALLED BY:	SoundPlayStop

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Enable appropriate UI

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupUIForEditing	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Enable the "record" trigger.
	;
		GetResourceHandleNS	Interface, bx
		mov	si, offset SndPlayRecordTrigger	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
	;
	;  Enable the "play" trigger.
	;
		mov	si, offset SndPlayPlayTrigger	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
	;
	;  Enable the editing controls.
	;
		mov	si, offset SndPlayEditBar	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
	;
	;  Enable all the notes and durations.
	;
		GetResourceHandleNS	Interface, bx	; ^lbx:si <- object
		mov	si, offset SndPlayNoteInteraction

		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
	;
	;  Enable the fast-forward & rewind stuff.
	;
		mov	si, offset SndPlayPositionBar	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
	;
	;  Enable the current-note glyph.
	;
		mov	si, offset SndPlayCurrentNoteGlyph
							; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED		; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp

		.leave
		ret
SetupUIForEditing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayPlay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play buffer to voice

CALLED BY:	MSG_SND_PLAY_PLAY

PASS:		es = ds = dgroup

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:
		Disables the following GenObjects:
			SndPlayNoteInteraction
			SndPlayPositionBar
			SndPlayPlayTigger
			SndPlayRecordTrigger
			SndPlayEditBar

		Enters play state

		Plays currently defined buffer to Music stream

PSEUDO CODE/STRATEGY:
		enter playing state

		disable appropriate Gen objects

		Send first message to ourselves to play next note

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayPlay	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_PLAY
		.enter
	;
	;  First disable all the UI, so the user can't do anything
	;  while the song is playing.
	;
		call	SetupUIForPlaying

	;
	;  Update the status moniker to read "Playing".
	;
		mov	ds:[currentState], SCS_PLAYING
		call	SoundPlayUpdateCurrentState

	;
	;  Now actually start playing the notes.
	;
		call	GeodeGetProcessHandle		; bx <- process handle
		mov	ax, MSG_SND_PLAY_PLAY_NEXT_NOTE	; ax <- message
		mov	cx, ds:[currentPosition]	; cx <- starting note
		mov	di, mask MF_FORCE_QUEUE		; di <- MessageFlags
		call	ObjMessage		; di <- MessageError

		.leave
		ret
SoundPlayPlay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIForPlaying
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the necessary UI objects when we start playing
		a song.

CALLED BY:	SoundPlayPlay

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		disable all the appropriate UI

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupUIForPlaying	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Disable everything except the Stop button and the
	;  Status glyph.
	;
		GetResourceHandleNS	Interface, bx	; ^lbx:si <- object
		mov	si, offset SndPlayNoteInteraction
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp

		mov	si, offset SndPlayPositionBar	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
		
		mov	si, offset SndPlayPlayTrigger	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
		
		mov	si, offset SndPlayRecordTrigger	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp
		
		mov	si, offset SndPlayEditBar	; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp

		mov	si, offset SndPlayCurrentNoteGlyph
							; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_NOT_ENABLED	; ax <- message
		mov	di, mask MF_CALL		; di <- MessageFlags
		mov	dl, VUM_NOW			; dl <- VisUpdateMode
		call	ObjMessage		; di <- MessageError
							; nukes ax, cx, dx, bp

		.leave
		ret
SetupUIForPlaying	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start recording notes from current position.

CALLED BY:	MSG_SND_PLAY_RECORD

PASS:		es = ds = dgroup
	
RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:
		disables the following GenObjects:
			SndPlayPlayTrigger
			SndPlayRecordTrigger
			SndPlayEditBar

		enters record-mode

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayRecord	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_RECORD
		uses	ax, cx, dx, bp
		.enter
	;
	;  Enable/disable the appropriate UI objects onscreen.
	;
		call	SetupUIForRecording

	;
	;  Set the status moniker to read "Recording".
	;
		mov	ds:[currentState], SCS_RECORDING
		call	SoundPlayUpdateCurrentState
		
		.leave
		ret
SoundPlayRecord	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIForRecording
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the UI objects appropriate for record-mode.

CALLED BY:	SoundPlayRecord

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupUIForRecording	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Diable the play & record triggers
	;
		GetResourceHandleNS	Interface, bx
		mov	si, offset SndPlayPlayTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage
		
		mov	si, offset SndPlayRecordTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage		

	;
	;  Disable the editing controls (insert, delete, etc).
	;
		mov	si, offset SndPlayEditBar
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage

		.leave
		ret
SetupUIForRecording	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayRewind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rewind to the beginning of the song.

CALLED BY:	MSG_SND_PLAY_REWIND

PASS:		es = ds = dgroup
		
RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	sets currentPosition to zero

PSEUDO CODE/STRATEGY:

	- set current position to zero
	- update the "current note" glyph

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayRewind	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_REWIND
		uses	ax, cx, dx, bp
		.enter
	;
	;  Set position to beginning of list.
	;
		clr	ds:[currentPosition]

	;
	;  Update Display To Reflect Changes.
	;
		call	SoundPlayUpdateCurrentPosition

	;
	;  Update the "Scan" GenValue.
	;
		call	SoundPlayUpdateScan
		.leave
		ret
SoundPlayRewind	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manually set the current position.

CALLED BY:	MSG_SND_PLAY_SCAN

PASS:		es = ds = dgroup
		dx	= new current position

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	updates currentPosition in dgroup

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayScan	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_SCAN
		uses	ax, cx, dx, bp
		.enter
		
		mov	ds:[currentPosition], dx

	;
	;  Update "Current Note" glyph to show the new position.
	;
		call	SoundPlayUpdateCurrentPosition
		
		.leave
		ret
SoundPlayScan	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayAdvance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the end of the song.  Why?  So you can add
		notes on the end!

CALLED BY:	MSG_SND_PLAY_ADVANCE

PASS:		es = ds = dgroup

RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	updates currentPosition in dgroup

PSEUDO CODE/STRATEGY:

	You probably don't have to mess with this code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayAdvance	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_ADVANCE
		uses	ax, cx, dx, bp
		.enter
%out TODD - this has a hard coded length!  
		mov	ax, ds:[listLength]
		mov	ds:[currentPosition], ax

	;
	;  Update current-note glyph to show new note.
	;
		call	SoundPlayUpdateCurrentPosition

	;
	;  Update the "Scan" GenValue.
	;
		call	SoundPlayUpdateScan
		
		.leave
		ret
SoundPlayAdvance	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a note into the list.

CALLED BY:	MSG_SND_PLAY_INSERT

PASS:		es = ds = dgroup
		
RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	This message is sent when you hit the "OK" trigger in
	the "Insert Note" dialog.  We've already written the code
	for getting the note and duration from that dialog.  This
	routine then calls the one *you* should write:  namely,
	SoundPlayInsertNote, in sndplayList.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayInsert	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_INSERT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Find out the frequency and duration of the new note.
	;
		GetResourceHandleNS	InsertNoteFrequencyList, bx
		mov	si, offset	InsertNoteFrequencyList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; ax = selection
		push	ax				; save note

		GetResourceHandleNS	InsertNoteDurationList, bx
		mov	si, offset	InsertNoteDurationList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; ax = selection

		mov_tr	dx, ax				; dx <- duration
		pop	cx				; cx <- note
	;
	;  Call the data-structure insert routine (it's blank right
	;  now).  The routine should be in sndplayList.asm.
	;
		call	SoundPlayInsertNote
	;
	;  Update Display To Reflect Changes
	;
		call	SoundPlayUpdateCurrentPosition

		.leave
		ret
SoundPlayInsert	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the current note from the piece

CALLED BY:	MSG_SND_PLAY_DELETE

PASS:		es = ds = dgroup
		
RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayDelete	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_DELETE
		uses	ax, cx, dx, bp
		.enter
	;
	;  Call the data structure routine for deleting a note.
	;
		call	SoundPlayDeleteNote
	;
	;  Update current-note glyph to show the new current note.
	;
		call	SoundPlayUpdateCurrentPosition

		.leave
		ret
SoundPlayDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the values of the current note

CALLED BY:	MSG_SND_PLAY_CHANGE

PASS:		ds = es = dgroup
		
RETURN:		nothing

DESTROYED:	nothing
		(bx, si, di, es, ds allowed)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayChange	method dynamic SndPlayGenProcessClass, 
					MSG_SND_PLAY_CHANGE
		uses	ax, cx, dx, bp
		.enter
	;
	;  First get the new note & duration.
	;
		GetResourceHandleNS	ChangeNoteFrequencyList, bx
		mov	si, offset	ChangeNoteFrequencyList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; ax = selection
		push	ax				; save note

		GetResourceHandleNS	ChangeNoteDurationList, bx
		mov	si, offset	ChangeNoteDurationList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; ax = selection

		mov_tr	dx, ax				; dx <- duration
		pop	cx				; cx <- note
	;
	;  Now call the data-structure routine for setting
	;  the new values for the current note.
	;
		call	SoundPlaySetNoteValue
	;
	;  Update Display To Reflect Changes
	;
		call	SoundPlayUpdateCurrentPosition
		
	.leave
	ret
SoundPlayChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayUpdateCurrentState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust display to reflect current state

CALLED BY:	INTERNAL

PASS:		ds = dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Modifies GenGlyph

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayUpdateCurrentState	proc	near
		uses	ax, cx, dx, si, bp
		.enter
	;
	;  Get current state from dgroup and use as offset
	;  into table of offsets to retrieve the
	;  text moniker appropriate to the status
	;
		mov	si, ds:[currentState]		; si = SoundCurrentState
		
		mov	cx, cs				; cx:dx <- text,0
		mov	dx, cs:stateVisMonikerOffsetTable[si]
	;
	;  Update the GenGlyph displaying the state.
	;
		GetResourceHandleNS	SndPlayCurrentStatusGlyph, bx
		mov	si, offset	SndPlayCurrentStatusGlyph
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bp, VUM_NOW
		call	ObjMessage		; ax, cx, dx, bp destroyed
		
		.leave
		ret

stateVisMonikerOffsetTable	nptr	recordingStatusText,
					editingStatusText,
					playingStatusText

recordingStatusText	byte	"Recording",0
editingStatusText	byte	"Editing",0
playingStatusText	byte	"Playing",0
		
SoundPlayUpdateCurrentState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayUpdateCurrentPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust display to reflect current note

CALLED BY:	INTERNAL

PASS:		ds = dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Modifies GenGlyph

PSEUDO CODE/STRATEGY:
		Allocate buffer on stack

		Call Kernel routine to convert reg to text

		Change Moniker in GenObject

		Free up buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayUpdateCurrentPosition	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Get the tone out of the note at the current position.
	;
		mov	cx, ds:[currentPosition]
		call	SoundPlayFindNote		; si = offset
		jc	done

		call	SoundPlayGetNoteValue		; bx = SoundNoteType
		mov_tr	ax, bx
	;
	;  Convert the SoundNoteType into a character.
	;
		clr	dx				; high word of dividend
		mov	bx, (LENGTH_OF_EVENT * 4)	; bl = divisor
		div	bx				; ax = table offset
		mov	bx, ax				; bx is index register
		mov	bl, cs:[NoteToAsciiTable][bx]	; bl <- character
	;
	;  Make the char into a string on the stack.
	;
		sub	sp, 2			; one char & one null
		mov	bp, sp
		movdw	cxdx, ssbp
		mov	{byte} ss:[bp], bl	; the character
		mov	{byte} ss:[bp+1], 0	; null-terminator

	;
	;  Update SndPlayCurrentNoteGlyph.
	;
		GetResourceHandleNS	SndPlayCurrentNoteGlyph, bx
		mov	si, offset	SndPlayCurrentNoteGlyph
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	di, mask MF_CALL		
		mov	bp, VUM_NOW
		call	ObjMessage		; destroys ax, cx, dx, bp
	;
	;  Clean up the stack.
	;
		add	sp, 2
done:
		.leave
		ret

NoteToAsciiTable	byte "R","C","D","E","F","G","A","B","C"
		
SoundPlayUpdateCurrentPosition	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayUpdateScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the GenValue's value to currentPosition

CALLED BY:	GLOBAL

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Get the curentPosition

		Adjust the GenValue

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayUpdateScan	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	;  Get the current position in the song from dgroup
	;
		mov	cx, ds:[currentPosition]
	;
	;  Tell the GenValue which value to display
	;
		clr	bp				; not indeterminate
		GetResourceHandleNS	SndPlayScan, bx
		mov	si, offset	SndPlayScan
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjMessage

		.leave
		ret
SoundPlayUpdateScan	endp

CommonCode	ends			;end of CommonCode resource



