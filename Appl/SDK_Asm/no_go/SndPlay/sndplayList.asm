COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SndPlay (Sample PC GEOS application)
FILE:		sndplayList.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	6/16/93		initial version

DESCRIPTION:

	This file contains the code for manipulating this
	application's data structures.  Currently the data
	structure used for storing song notes is an array.
	The limit on the number of notes is MAX_NUMBER_OF_NOTES
	(currently defined as 5).

	Your task is to write code that creates a simple
	linked-list data structure using the system's Lmem
	functionality, and replace all the existing array
	code with your lmem code.  Your code will be better
	than the existing code in that:

		- it will allow more than five notes

		- it will allow inserting/deleting notes

		- linked lists are just cooler than arrays, darn it.

	Note that there are easier ways to create linked lists
	than the way you'll be doing it, but that would take all
	the fun out of it!

RCS STAMP:

	$Id: sndplayList.asm,v 1.1 97/04/04 16:34:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Initialized global variables
;-----------------------------------------------------------------------------

idata		segment

	;
	;  The currently selected duration value for notes.
	currentDuration		word	DEFAULT_STARTING_DURATION

	;
	;  The current state of the editor
	currentState		SoundCurrentState	SCS_EDITING

	;
	;  The number of notes currently in the list
	currentNumOfNotes	word	MAX_NUMBER_OF_NOTES

idata		ends

;------------------------------------------------------------------------------
;		Uninitialized global variables
;------------------------------------------------------------------------------

udata	segment

	noteListHandle		hptr	; handle to fixed block containing
					; our array of ListNodes

	noteListSegment		word	; segment of block containing
					; our array of ListNodes
	;
	;  The current position in the sound buffer
	currentPosition		word

udata	ends

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------

InitCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayInitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a global memory block to hold our list.

CALLED BY:	SoundPlayGenProcessOpenApplication

PASS:		ds = dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Right now this routine allocates a global block that's
	just big enough to hold five notes.  The only part of
	this routine that you'll probably want to keep is the
	last part, where the handle and segment of the newly-
	allocated block are stored in global variables.

	You will want to use MemAllocLMem to create your block,
	instead of MemAlloc.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayInitializeList	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Allocate a fixed block to store our notes.  ax gets the
	;  size (in bytes), cx gets some flags, and then we call
	;  MemAlloc.
	;
		mov	ax, ListNode * MAX_NUMBER_OF_NOTES
		mov	cx, (mask HAF_ZERO_INIT) shl 8 or mask HF_FIXED
		call	MemAlloc		; ax <- segment
						; bx <- handle
						; cx destroyed

;#############################################################################
;	Temporary code.  Delete when you start making changes.

		push	ax, si, di, ds, es
		
	;
	;  Here we stick a sample song into the array, so that
	;  the first time you hit "Play" it doesn't crash & die.
	;  This shouldn't be a problem when you code the linked-list
	;  version:  the play-song routine will encounter a NULL
	;  pointer right away, and stop.
	;
		mov	es, ax				; es:di <- sample block
		clr	di
		
		segmov	ds, cs, ax			; ds:si <- sample notes
		mov	si, offset sampleNotes
		
		mov	cx, size sampleNotes
		
		rep	movsb				; copy buffer
		
		pop	ax, si, di, ds, es
		
;#############################################################################
;

	;
	;  Store handle and segment so we can use it later in the program.
	;  We can only do this because fixed blocks never move.
	;
		mov	ds:[noteListHandle], bx		; save handle
		mov	ds:[noteListSegment], ax	; save segment

		.leave
		ret

;#############################################################################
;	Temporary code.  Delete when you start making changes

sampleNotes	ListNode	<SNT_E_NOTE, SND_HALF>,
				<SNT_D_NOTE, SND_HALF>,
				<SNT_C_NOTE, SND_QUARTER>,
				<SNT_D_NOTE, SND_QUARTER>,
				<SNT_E_NOTE, SND_HALF>

;#############################################################################
;
		
SoundPlayInitializeList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayDestroyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the global memory block that contains our list.

CALLED BY:	SoundPlayerGenProcessCloseApplication

PASS:		ds = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Free the global memory block.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayDestroyList	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get and then clear the handle to the block
	;  containing our list.
	;
		clr	bx
		xchg	bx, ds:[noteListHandle]
		tst	bx				; is there a handle?
		jz	doneFree
	;
	;  Free up the block
	;
		call	MemFree				; bx destroyed
doneFree:
	;
	;  Clear the segment for the block since it's no longer valid.
	;
		clr	ds:[noteListSegment]

		.leave
		ret
SoundPlayDestroyList	endp

InitCode		ends

CommonCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayGetNoteValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the settings for the specified note in the list.

CALLED BY:	global

PASS:		ds	= dgroup
		cx	= note # (0 means first note in the list)

RETURN:		carry clear	
		bx	= NoteType
		si	= SoundNoteDuration

		- or -

		carry set if node doesn't exist


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayGetNoteValue	proc	near
		uses	ax, cx, dx, ds
		.enter
		
		call	SoundPlayFindNote	; destroys ax, cx, dx
		jc	done
		
		mov	ds, ds:[noteListSegment]	; ds = segment of array
	;
	;  Get settings from memory
	;
		mov	bx, ds:[si].LN_tone		; bx = NoteType
		mov	si, ds:[si].LN_duration		; si = SoundNoteDuration
		
		clc
done:
		.leave
		ret
SoundPlayGetNoteValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlaySetNoteValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set new tone & duration for the current note.

CALLED BY:	SoundPlayChange

PASS:		ds	= dgroup
		cx	= new note
		dx	= new duration

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is currently coded for arrays -- you will want to
	change it to work with your list code.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlaySetNoteValue	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter

	;######################################################################
	;  ARRAY CODE THAT YOU SHOULD NUKE.

	;
	;  Just stick the new values in the current note.
	;
		push	cx				; save tone
		mov	cx, ds:[currentPosition]
		call	SoundPlayFindNote		; si <- offset
		pop	cx				; restore tone
		
		mov	ax, ds:[noteListSegment]
		mov	es, ax
		mov	es:[si].LN_tone, cx
		mov	es:[si].LN_duration, dx
		
	;######################################################################



	;######################################################################
	;  FILL THIS PART IN FOR LINKED-LISTS.

		

	;######################################################################

		.leave
		ret
SoundPlaySetNoteValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayInsertNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a note after the specified note in the list,
		and give it an initial value.

CALLED BY:	SoundPlayInsert

PASS:		ds	= dgroup
		cx	= SoundNoteType for note
		dx	= SoundNodeDuration for note

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	You can pretty much decide how you want insert to work.
	We coded the array version to insert at the current position,
	then increment the current position.

	In the linked list version, you can insert before the current
	note, or after it -- just make it work somehow.

	However, if you make it insert *before* the current note,
	then you will wind up recording your songs backwards, which
	could get confusing.  We won't hold it against you, though.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayInsertNote	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter

	;######################################################################
	;  NUKE ALL THIS CODE WHEN YOU START
		
	;
	;  Refuse to do anything if we're past the end of the array.
	;
		cmp	ds:[currentPosition], MAX_NUMBER_OF_NOTES
		jg	done
	;
	;  Stick the note into the array.
	;
		push	cx				; save tone
		mov	cx, ds:[currentPosition]
		call	SoundPlayFindNote		; si = note offset
		pop	cx				; restore tone
		jc	done				; some sort of error
		
		mov	ax, ds:[noteListSegment]
		mov	es, ax				; es = list segment
		mov	es:[si].LN_tone, cx
		mov	es:[si].LN_duration, dx		; store the stuff
	;
	;  Increment the current position.
	;
		inc	ds:[currentPosition]

		jmp	short	done
	;
	;######################################################################

	;######################################################################
	; FILL THIS PART IN



		
		
	;######################################################################

done:
		.leave
		ret
SoundPlayInsertNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayDeleteNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the specified note in the list.

CALLED BY:	SoundPlayDelete

PASS:		ds = dgroup
		cx = note number (0 is first in list)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Nothing's been done for the array version -- go to it!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayDeleteNote	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;######################################################################
	;FILL THIS IN




		
		
	;######################################################################

		.leave
		ret
SoundPlayDeleteNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayFindNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locates a note in the list.

CALLED BY:	SoundPlayInsertNote, SoundPlayDeleteNote

PASS:		es = dgroup
		cx = note number (0 means first in list)

RETURN:		si = offset of the specified note, and carry clear

			- or -

		carry set if note not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is currently coded for the array data structure.
	You will need to change it to work with you linked list.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayFindNote	proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter
		
		cmp	cx, es:[currentNumOfNotes]	; did we go off the end?
		jae	error
	;
	;  Calculate offset into array
	;
		mov	ax, size ListNode		; ax <- # of bytes
		mul	cx				; dxax <- offset of node
	;
	; (node # * size of node)
	;
		mov_tr	si, ax				; si <- offset of node
		
		clc					; everything went fine
done:
		.leave
		ret
error:
		stc					; indicate error
		jmp	short done

SoundPlayFindNote	endp


CommonCode	ends
