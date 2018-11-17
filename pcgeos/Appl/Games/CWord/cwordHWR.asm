COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		HWR Module
FILE:		cwordHWR.asm

AUTHOR:		Peter Trinh, May  4, 1994

ROUTINES:
	Name			Description
	----			-----------
	HwrCreateTextQueue	Creates a TextQueueBlock
	HwrDestoryTextQueue	Destroys a TextQueueBlock
	HwrAppendInfoToQueue 	Adds another element to end of queue
	HwrGetInfoFromQueue	Gets an element from queue
	HwrCharCallbackFilter	Select a character from list
	HwrGetCenterPoint	Get center of last recognized char
*	HwrGetNthCharBound	Get bound of last recognized char
	HwrZeroOutNegative	Rounds any negative value up to zero
*	HwrTransformPalmToDoc	Transform Palm's coord to doc coord
	HwrFindCenterOfBounds	Calculates center given bound
	HwrDoHWR		Makes call into HWRLibrary to do HWR
	HwrDoPreRecognition	PreRecognize special case characters
	HwrPreRecPeriod		Recognizes a period from raw ink and
				deals with it
	HwrPreRecMinusSign	Recognizes a minus sign from raw ink
				and deals with it
	HwrCountInkStrokes	Counts the strokes of given raw ink
	HwrCheckIfPeriod	Identifies whether ink is a period.
	HwrCheckIfMinusSign	Identifies whether ink is minus sign
	HwrUntransformPoint	Untransform View window transformation
	HwrClipDC		Limits the point to be within the grid
	HwrSetupFilter		Sets up the filter for HWR library	
	HwrCheckIfCwordGesture	Checks to see if the ink is a gesture
	HwrStrokeEnum		Enumerate through the stokes
	HwrCheckIfGesture	Check/handle gesture
	HwrGetGestureBounds	Gets the bounds of the gesture
	HwrGetGestureBoundsFromInkPoints
	HwrGetGestureBoundsFromLibrary

	;;; Gesture handlers for the given GestureReturnTypes
	HwrHandleGestureNull	Place holder for gesture handlers
	HwrHandleGestureDelete		GT_DELETE, GT_BACKSPACE
	HwrHandleGestureChar		GT_CHAR
	HwrHandleGestureModeChar	GT_MODE_CHAR
	HwrHandleGestureReplaceLastChar	GT_REPLACE_LAST_CHAR

	HwrSendCharAndBoundsToBoard	Send the char and its center to Board
	HwrSendGestureActionToBoard  Send the given message

	================================
	CwordGestureResetCode Segment
	================================
	HwrResetMacro		Calls HWRR_RESET_MACRO
	HwrCheckIfCurrentAPI


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 4/94   	Initial revision


DESCRIPTION:
	This file contains the routines for the HWR Module.
		

<<<<<<< 1.1.1.12+mods
	$Id: cwordHWR.asm,v 1.1 97/04/04 15:14:03 newdeal Exp $
=======
	$Id: cwordHWR.asm,v 1.1 97/04/04 15:14:03 newdeal Exp $
>>>>>>> 1.12

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordHWRCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCreateTextQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will create an LMemBlock with one chunk inside of it.
		The chunk will be a ChunkArray, that will initially
		have no elements in it.  We're using a routine
		borrowed from the MemAllocLMem routine which will
		allocate a 128 bytes block with an lmem heap size of
		64 bytes.  So calculations tells us there is enough
		room for 9 elements before having to expand the block.

CALLED BY:	BoardNotifyWithDataBlock

PASS:		nothing

RETURN:		bx	- handle to block allocated
		CF	- SET if error (not enough memory)

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCreateTextQueue	proc	near
	uses	ax,cx,dx,di,si,ds
	.enter

	mov	ax, 128			; initial block size
	mov	cx, ALLOC_DYNAMIC_LOCK
	callerr	MemAlloc
	mov	ds, ax			; segment of allocated block

	; Set the flags
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size TextQueueBlockHeader
	mov	di, mask LMF_RETURN_ERRORS

	mov	cx, 2			; 2 initial handles
	mov	si, 64			; initial heap size
	call	LMemInitHeap

	push	bx			; new block handle

	; Create a ChunkArray inside of the block
	mov	bx, size TextInfo	; size of each element
	clr	cx			; no extra space needed in hdr
	clr	si			; allocate a handle
	clr	ax			; not object chunk
	call	ChunkArrayCreate
	pop	bx			; handle of new block
	jc	err

	mov	ds:[TQBH_textQueueHandle], si	; save chunk handle of
						; TextQueue chunk
	clr	ds:[TQBH_matchCharIndex]	; 0 initialized

;;; Verify return value(s)
	Assert	ChunkArray	dssi
;;;;;;;;

	call	MemUnlock		; done working with the block
	clc

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	mov	di, HWR_LOW_MEM_WARN
	mov	dx, WARN_N_CONT
	call	CwordPopUpDialogBox
	stc
	jmp	exit

HwrCreateTextQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrDestroyTextQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up the TextQueueBlock containing the TextQueue.

CALLED BY:	BoardNotifyWithDataBlock

PASS:		bx	= handle to TextQueueBlock

RETURN:		nothing

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrDestroyTextQueue	proc	near
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	TextQueueBlock	bx
;;;;;;;;

	call	MemFree	

	.leave
	ret
HwrDestroyTextQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrAppendInfoToQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add new element at the end of the TextQueue.

CALLED BY:	HwrCharCallbackFilter, HwrPreRecMinusSign

PASS:		ax	- x-coord of point
		dx	- y-coord of point
		cx	- character
		bx	- handle to a TextQueueBlock

RETURN:		CF	- SET if didn't append (outa memory?)

DESTROYED:	nothing

SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	Will call the ChunkArray routines provided.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrAppendInfoToQueue	proc	near
	uses	ds,si,di
	.enter

;;; Verify argument(s)
	Assert	InGrid	axdx
	Assert	HWRChar	cx
	Assert	TextQueueBlock	bx
;;;;;;;;

	push	ax				; x-coord
	call	MemLock		

	mov	ds, ax				; locked segment
	mov	si, ds:[TQBH_textQueueHandle]	; *ds:si = TextQueue
	call	ChunkArrayAppend
	pop	ax				; x-coord
	jc	err				; couldn't append

	; Initialize new element.
	mov	ds:[di].TI_center.P_x, ax	; Initialize Point
	mov	ds:[di].TI_center.P_y, dx
	mov	ds:[di].TI_character, cx	; Initialize character

	clc

exit:	
	call	MemUnlock

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	push	dx				; y-coord
	mov	di, HWR_TEXT_QUEUE_APPEND_WARN
	mov	dx, WARN_N_CONT
	call	CwordPopUpDialogBox
	pop	dx				; y-coord
	stc
	jmp	exit

HwrAppendInfoToQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetInfoFromQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the first element from the ChunkArray and
		deletes the element from the ChunkArray.

CALLED BY:	BoardNotifyWithDataBlock

PASS:		ss:bp	= ptr to a buffer of size TextInfo
		bx	= handle to TextQueueBlock

RETURN:		cx - number of elements left in queue plus
		     the one being returned
		if cx = 0
			then buffer is empty
		else
			ss:bp = a filled in buffer
		     
DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetInfoFromQueue	proc	near
	uses	ax,dx,si,di,ds,es
	.enter

;;; Verify argument(s)
	Assert	bufferGEsize	ssbp, TextInfo
	Assert	TextQueueBlock	bx
;;;;;;;;

	call	MemLock

	mov	ds, ax				; locked segment
	mov	si, ds:[TQBH_textQueueHandle]	; *ds:si = TextQueue

	call	ChunkArrayGetCount
	push	cx				; number of elements
	jcxz	exit

	; At this point in order to get the buffer filled, we can use
	; ChunkArrayGetElement; however, I feel that there isn't that
	; much extra code written and the execution time would be much
	; shorter than if using the ChunkArrayGetElement implementation.
	clr	ax				; 0th element
	call	ChunkArrayElementToPtr		; ds:di = element,
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	; Copy from the array to the buffer
	push	di, si				; element, TextQueueHandle
	mov	si, di				; ds:si = element
	movdw	esdi, ssbp			; es:di = buffer
	mov	cx, size TextInfo
	shr	cx, 1				; word size, set carry if odd
	rep	movsw
	jnc	notOdd
	movsb
notOdd:

	pop	di, si				; element, TextQueueHandle
	call	ChunkArrayDelete		; delete the element

exit:
	call	MemUnlock
	pop	cx				; number of elements

	.leave
	ret
HwrGetInfoFromQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCharCallbackFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine will be given an array of possible
		characters to choose from.  We will pick the first
		given letter, since it is the one with the highest
		recognition accuracy.  Then it will calculate the
		center of this character's ink bound.  Then it will
		store the chosen letter and center point into a
		TextQueue.  

		Assumes that this routine will never be called for
		spaces between ink characters, ie. we will never
		receive a space as a possible character choice.

CALLED BY:	

PASS:		( on stack ) CallBackParameters struct
		word	number of choices for character
		word	offset of first point in char
		word	offset of last point in char
		fptr	array of 16-bit characters
		optr	callback data; in our case, only the block
				     ; handle will be used, to store a
				     ; handle to the TextQueueBlock

RETURN:		ax	= character chosen; in our case, nothing

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING: This routine MAY cause the TextQueue block to move on
		the heap, thus invalidating stored segment pointers
		and current register or stored offsets to it. 

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
;	Set the code convention to be pascal, by default.
;
	SetGeosConvention

HwrCharCallbackFilter	proc	far	numChoices:word, firstPoint:word, lastPoint:word, charChoices:fptr.word, callbackData:optr
	uses	bx,cx,dx,di,es
	.enter

	ForceRef firstPoint		; unused arguments
	ForceRef lastPoint			

	mov	bx, callbackData.handle	; handle to TextQueueBlock
	tst	numChoices		; exit if no choices
	jz	exit

	les	di, charChoices
	mov     cx, es:[di]		; take the first choice

	;
	; We don't want spaces between our letters.  We get spaces
	; because we're doing multiple character recognitions so the
	; library inserts spaces between characters written too far
	; apart, ie. between non-adjacent cells.
	; 6/29/95 - ptrinh
	;
	cmp	cx, C_SPACE
	je	skipChar

	; If Palm had done things correctly, we wouldn't need to do
	; this check, and could safely assume that only valid
	; characters, besides spaces, would be passed in to this
	; routine.
	call	CheckIfHWRChar
	jc	skipChar		; jmp not a Cword character

	call	UserGetHWRLibraryHandle	; Get the library handle
EC <	tst	ax						>
EC <	ERROR_Z	HWR_NO_HWR_LIBRARY_LOADED			>
	mov_tr	di, ax			; handle to HWRLib

	mov_tr	ax, cx			; target character
	call	LocalUpcaseChar
	mov_tr	cx, ax			; converted character
	push	bx			; handle of TextQueueBlock
	call	HwrGetCenterPoint

	mov	dx, bx			; y-coord of center

	pop	bx			; handle to TextQueueBlock
	call	HwrAppendInfoToQueue

skipChar::
exit:
	clr	ax			; null return-value

	.leave
	ret
HwrCharCallbackFilter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetCenterPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will find the center point of the bound of the last
		recognized ink character.

CALLED BY:	HwrCharCallbackFilter

PASS:		di	= handle of HWR library

RETURN:		ax	- x-coord of center point (doc coordinate)
		bx	- y-coord

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING: ds - should not be pointing an lmem block because it
		 will not be fixed up. 

	NOTE: 	Do not attempt to call HWRR_BEGIN_INTERACTION or else
		deadlock will happen.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetCenterPoint	proc	near
	uses	cx,dx,ds
	.enter

;;; Verify argument(s)
	Assert	TextQueueBlock	bx
	Assert	handle		di
;;;;;;;;

	CallHWRLibrary	HWRR_GET_CHAR_BOUNDS
	mov_tr	bx, ax
	call	MemLock
	mov	ds, ax

	push	bx			; ^h Rectangle (bounds)

	mov	ax, ds:[R_left]
	mov	bx, ds:[R_top]
	mov	cx, ds:[R_right]
	mov	dx, ds:[R_bottom]

	call	HwrFindCenterOfBounds
	call	HwrUntransformPoint
	call	HwrClipDC

	mov	cx, bx			; y-coord
	pop	bx			; ^h Rectangle (bounds)
	call	MemFree			; allowed to free
	mov	bx, cx			; y-coord

;;; Verify return value(s)
	Assert	InGrid	axbx
;;;;;;;;

	.leave
	ret
HwrGetCenterPoint	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetNthCharBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the bound of the Nth recognized ink
		character, excluding spaces.  N starts from 0, ie.
		first element = 0th. 

CALLED BY:	HwrGetCenterPoint

PASS:		bx	- handle to HWR library
		cx	- nth character bound desired

RETURN:		ax	- left		( all in doc coordinates )
		bx	- top
		cx	- right
		dx	- bottom

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetNthCharBound	proc	near

ptBufferHan		local	hptr
strkBufferHan		local	hptr
resultsBufferHan	local	hptr.MatchText
singleCharResult	local	MatchText

	uses	si,ds
	.enter

;;; Verify argument(s)
	Assert	handle	bx
	Assert	urange	cx, HWR_MIN_NUM_TEXT_INFO, HWR_MAX_NUM_TEXT_INFO
;;;;;;;;

	push	cx			; save index

	; Make call to HWRR_GET_BUFFER_PTRS
	lea	ax, ss:[ptBufferHan]
	pushdw	ssax
	lea	ax, ss:[strkBufferHan]
	pushdw	ssax
	lea	ax, ss:[resultsBufferHan]
	pushdw	ssax
	lea	ax, ss:[singleCharResult]
	pushdw	ssax
	CallHWRLibraryHandle	bx, HWRR_GET_BUFFER_PTRS

	; Get ptr to buffer of recognized characters
	mov	bx, ss:[resultsBufferHan]
EC <	pushf							>
EC <	tst	bx						>
EC <	ERROR_Z	HWR_CANT_CALL_GET_BUFFER_PTRS_IN_THIS_SITUATION	>
EC <	popf							>
	call	MemLock

	mov	ds, ax			; Palm's data block
	mov	si, MT_chInfo		; array of MatchCharInfo  

	; Now get the character bound that this callback corresponds
	; to.
	pop	cx			; index into array
	mov	ax, size MatchCharInfo
	mul	cx			; get correct array offset
	add	si, ax			; ptr to initial target

	Assert	HWRChar	ds:[si].MCI_ch.MC_chValue
	; We should never encounter a non-Cword character, since this
	; would have been detected in the CharCallback routine and the
	; index would have been incremented appropriately.  This
	; assertion is based on the assumption that Palm calls our
	; callback routine for each of its MatchCharInfo array
	; element. 

	; get the bound
	mov	ax, ds:[si].MCI_chRect.AR_left
	mov	bx, ds:[si].MCI_chRect.AR_top
	mov	cx, ds:[si].MCI_chRect.AR_right
	mov	dx, ds:[si].MCI_chRect.AR_bottom

	; Since we can get negative coordinates, we'll need to
	; zero-out any negative coordinates, ie. raise it to 0.
	call	HwrZeroOutNegative

	; Since Palm uses a higher resolution in their coordinate
	; system, we have to convert it back to document coordinate.
	call	HwrTransformPalmToDoc

	; Unlock the block.
	push	bx
	mov	bx, ss:[resultsBufferHan]
	call	MemUnlock
	pop	bx

;;; Verify return value(s)
	Assert	InDoc	axbx
	Assert	InDoc	cxdx
;;;;;;;;

	.leave
	ret
HwrGetNthCharBound	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrZeroOutNegative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rounds any negative value up to zero.

CALLED BY:	Global

PASS:		ax	= left
		bx	= top
		cx	= right
		dx	= bottom

RETURN:		ax	= left		; Non negative values
		bx	= top
		cx	= right
		dx	= bottom

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrZeroOutNegative	proc	near
	.enter

;;; Verify argument(s)
	Assert	ge	cx, ax
	Assert	ge	dx, bx
;;;;;;;;

	; Check the left side
	tst	ax		; Make sure non-negative
	jge	top
	clr	ax		; Zero out if negative
	tst	cx		; cx could be equal to ax, like a Point
	jge	top
	clr	cx

top:	; Check the top side
	tst	bx
	jge	exit
	clr	bx
	tst	dx
	jge	exit
	clr	dx

exit:
	.leave
	ret
HwrZeroOutNegative	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrTransformPalmToDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since Palm uses a higher resolution for their
		coordinate systems, we must transform it to our
		document coordinate system.  This routine will take a
		Palm bound (two coordinates) and transform it to a
		document bound.

		I believe that Palm applies a WinUntransform to the
		raw Ink data points passed in to them.  Thus when
		we transform from their coordinates system to our
		document coordinates system, we don't have to worry
		about applying the View's transformation.

		NOPE!  Palm does not apply any sort of transformation
		at all.  They just multiply the screen coordinates by
		four to get their coordinates.

CALLED BY:	HwrGetNthCharBound
PASS:		ax	= left		; Palm coordinates
		bx	= top
		cx	= right
		dx	= bottom

RETURN:		ax	= left		; document coordinates
		bx	= top
		cx	= right
		dx	= bottom

DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Divide each register by 4.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrTransformPalmToDoc	proc	near
	.enter

	; Divide each coordinate by 4
	sar	ax, 1
	sar	ax, 1

	sar	bx, 1
	sar	bx, 1

	sar	cx, 1
	sar	cx, 1

	sar	dx, 1
	sar	dx, 1

	xchg	ax, cx			; right, left
	xchg	bx, dx			; bottom, top
	call	HwrUntransformPoint	; transform right and bottom
	xchg	ax, cx			; left, right(transformed)
	xchg	bx, dx			; top, bottom(transformed)
	call	HwrUntransformPoint	; transform left and top
	
;;; Bound check the transformation
	Assert	InDoc	axbx
	Assert	InDoc	cxdx
;Apparently, in the zoomer demo version, points can be outside of the
;application's document coordinate.  Probably because the points were
;taken as raw ink and converted into Palm's coordinate system directly.
;;;;;;;;

	.leave
	ret
HwrTransformPalmToDoc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrFindCenterOfBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the center of a given rectangular bound.  The
		bound must be within the current document.

CALLED BY:	HwrGetCenterPoint, HwrPreRecMinusSign
PASS:		ax	= left
		bx	= top
		cx	= right
		dx	= bottom

RETURN:		ax	= center-x
		bx	= center-y

DESTROYED:	nothing

SIDE EFFECTS:	
	WARNING: ds - should not be pointing an lmem block because it
		 will not be fixed up. 

PSEUDO CODE/STRATEGY:
	Finds the mean of the x coordinate, then the y coordinate.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrFindCenterOfBounds	proc	near
	.enter

	add	ax, cx
	sar	ax, 1			; divide by two
	add	bx, dx
	sar	bx, 1			; divide by two

	.leave
	ret
HwrFindCenterOfBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrDoHWR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine handles all aspect of doing handwriting
		recognition.  It will be passed the handle to the raw
		Ink data block to send to the HWR library, and also a
		TextQueueBlock handle to store results in.

CALLED BY:	BoardNotifyWithDataBlock

PASS:		bp	- handle of raw Ink data points
		bx	- handle of TextQueueBlock

RETURN:		bx	- modified TextQueueBlock
		CF	- SET if no recognition done

DESTROYED:	nothing

SIDE EFFECTS:	
	WARNING: This routine MAY cause the TextQueue block to move on
		the heap, thus invalidating stored segment pointers
		and current register or stored offsets to it. 

PSEUDO CODE/STRATEGY:
	1) Initialize the HWR library
		a) call HWRR_BEGIN_INTERACTION to notify the HWR
		   library that we're ready
		b) call HWRR_RESET to reset any current
		   filters/context and internal buffers.
		c) call HwrSetupFilter to setup new filter
		d) call HWRR_ADD_POINTS register new Ink points
	2) Call HWRR_DO_MULTIPLE_CHAR_RECOGNITION to do recognition
	3) Call HWRR_END_INTERACITON to tell the HWR library that
	   we're done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrDoHWR	proc	near
	uses	ax,cx,dx,di,si,es
	.enter

;;; Verify argument(s)
	Assert	handle	bp
	Assert	TextQueueBlock	bx
;;;;;;;;

	; Get the handle of the currently loaded HWR library.  ax = 0
	; if there is no library loaded (we are not running in pen mode.
	call	UserGetHWRLibraryHandle
	tst	ax
	LONG jz	exit

	; Make sure to keep the HWRLib handle in di
	mov_tr	di, ax			; handle to HWRLib
	mov	si, bx			; handle to TextQueueBlock

	; Pre-recognize the ink, if successful, then exit.
	call	HwrDoPreRecognition
	LONG jnc	exit

	; Call HWRR_BEGIN_INTERACTION to ensure exclusive access to
	; the library
	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax			; check if error
	LONG jnz exit			; don't call END_INTERACTION
					; on error

	; Call HWRR_RESET to reset any current filters/context, and to
	; clear any buffers the HWR library may be keeping.
	CallHWRLibrary	HWRR_RESET

	; Setup the filter and filter callback routine
	mov	bx, si			; handle to TextQueueBlock
	call	HwrSetupFilter
	jc	exit
	
	; Lock down the ink data, and send the points to the
	; recognizer.
	mov	bx, bp			; handle to Ink data block
	call	MemLock
	mov	es, ax			; segment of data block

	; Parameters to HWRR_ADD_POINTS
	push	es:[IH_count]
	mov	bx, offset IH_data
	pushdw	esbx			; es:bx ptr to Ink data block

	CallHWRLibrary	HWRR_ADD_POINTS
	mov	bx, bp			; handle to Ink data block
	call	MemUnlock

	; Recognize the ink data
	CallHWRLibrary	HWRR_DO_MULTIPLE_CHAR_RECOGNITION
	tst	ax			; handle of returned data
	jz	noHandle
	mov_tr	bx, ax			; handle of returned data
	call	MemFree			; don't need the data
noHandle:

	; Detach from the HWR library
	CallHWRLibrary	HWRR_END_INTERACTION

	mov	bx, si			; handle to TextQueueBlock
	clc				; did recognition
exit:
	.leave
	ret
HwrDoHWR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrDoPreRecognition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will analyze the ink points in the given data block,
		and determine if the points composes a special
		gesture/character, eg. a sloping minus sign.  If so,
		then handle it.  Note: All coordinates in the data
		block are screen coordinates.

		(This routine is necessary to pick up any gestures
		 that HWR library does not support.)

CALLED BY:	HwrDoHWR

PASS:		^hbp	- InkHeader and data
		^hdi	- HWR library

RETURN:		CF	- SET if did NOT do PreRecognition
DESTROYED:	nothing
SIDE EFFECTS:	

	Information added to the TextQueueBlock if CF is CLEARED

PSEUDO CODE/STRATEGY:

	NOTE: Current version does not support Graffiti.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version
	PT	8/1/94		Part of gesture mechanism
	PT	8/15/94		Part of ink recognition

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrDoPreRecognition	proc	near

;;; Verify argument(s)
	Assert	handle		bp
	Assert	handle		di
;;;;;;;

	uses	ax,bx,es
	.enter

	mov	bx, bp			; ^h InkHeader 
	call	MemLock
	mov	es, ax			; segment of Ink data

	call	HwrCountInkStrokes
EC <	tst	bx						>
EC <	ERROR_Z	HWR_NO_STROKES_DETECTED_IN_INK_DATABLOCK	>
	cmp	bx, 1
	jg	notGesture

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	mov	cx, es:[IH_bounds].R_right
	mov	dx, es:[IH_bounds].R_bottom

	call	HwrPreRecPeriod
	jnc	exit			; jmp if detected a period
	call	HwrPreRecMinusSign
	;
	; Carry flag should be preserved through the completion of
	; this routine.
	;
	
exit:
	mov	bx, bp			; ^h InkHeader
	call	MemUnlock

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
notGesture:
	stc
	jmp	exit

HwrDoPreRecognition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrPreRecPeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a set of points, will determine if the points
		constitute a period.  If it doesn the send the period
		along with its bounds to the Board to be handled.

CALLED BY:	HwrDoPreRecognition

PASS:		ax	- left	(gesture bounds in screen coord)
		bx	- top
		cx	- right
 		dx	- bottom

RETURN:		CF	- SET if did NOT process as minus sign

DESTROYED:	nothing
SIDE EFFECTS:	none


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrPreRecPeriod	proc	near
	uses	si,bp
	.enter	

	; Will not deal with any negative values
	call	HwrZeroOutNegative	

	call	HwrCheckIfPeriod
 	jc	exit

	mov	si, MSG_CWORD_BOARD_GESTURE_CHAR
	mov	bp, C_PERIOD
	call	HwrSendPreRecCharAndBoundsToBoard

	clc
exit:

	.leave
	ret
HwrPreRecPeriod	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrPreRecMinusSign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a set of points, will determine if the points
		make up a minus sign.  If it is, then send the minus
		sign with it's bounds to the Board.

CALLED BY:	HwrDoPreRecognition

PASS:		ax	- left	(gesture bounds in screen coord)
		bx	- top
		cx	- right
 		dx	- bottom

RETURN:		CF	- SET if did NOT process as minus sign

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version
	PT	8/1/94		Part of gesture mechanism now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrPreRecMinusSign	proc	near
	uses	si,bp
	.enter

	; Will not deal with any negative values
	call	HwrZeroOutNegative	

	call	HwrCheckIfMinusSign
 	jc	exit

	mov	si, MSG_CWORD_BOARD_GESTURE_CHAR
	mov	bp, C_MINUS
	call	HwrSendPreRecCharAndBoundsToBoard

	clc
exit:
	.leave
	ret
HwrPreRecMinusSign	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCountInkStrokes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Counts the number of strokes for a given block of ink
		points. 

CALLED BY:	HwrPreRecMinusSign

PASS:		es	= segment of InkHeader

RETURN:		bx	= number of strokes

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCountInkStrokes	proc	near
	uses	ax,cx,si
	.enter

	mov	cx, es:[IH_count]	; number of points
	mov	si, offset IH_data	; ptr to Point
	clr	bx			; stroke counts

nextPoint:
	lodsw	es:
	test	ax, mask IXC_TERMINATE_STROKE
	jz	notStroke
	inc	bx			; inc count only if is stroke
notStroke:

	inc	si			; skip y-coord
	; stroke bit set only at x-coord
	inc	si			; word-sized coord
	loop	nextPoint

	.leave
	ret
HwrCountInkStrokes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCheckIfPeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will determine whether the given screen bounds
		constitutes a period.

CALLED BY:	HwrDoPrecPeriod

PASS:		ax	= left		(Screen coordinates)
		bx	= top
		cx	= right
		dx	= bottom

RETURN:		CF	- SET if not a period

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Criteria to be a period
		1) bound width <= HWR_PERIOD_SIZE
		2) bound height <= HWR_PERIOD_SIZE

	NOTE: Assumes right>left and bottom>top


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCheckIfPeriod	proc	near
	uses	cx,dx
	.enter

;;; Verify argument(s)
	Assert	ge	cx, ax
	Assert	ge	dx, bx
;;;;;;;;

	sub	cx, ax			; width = right - left
	sub	dx, bx			; height = bottom - top

	cmp	cx, HWR_PERIOD_SIZE
	jg	isNot

	cmp	dx, HWR_PERIOD_SIZE
	jg	isNot

	clc				; met criteria, so is a period

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isNot:
	stc
	jmp	exit

HwrCheckIfPeriod	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCheckIfMinusSign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will determine whether the given screen bounds
		constitutes a minus sign.

CALLED BY:	HwrPreRecMinusSign

PASS:		ax	= left		(Screen coordinates)
		bx	= top
		cx	= right
		dx	= bottom

RETURN:		CF	- SET if not minus sign

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Criteria to be a minus sign:
		1) bound width >= HWR_SLOPE_FACTOR * the bound height 
		2) bound width >= HWR_MIN_WIDTH
		3) bound height <= HWR_MAX_HEIGHT

	NOTE: Assumes right>left and bottom>top

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCheckIfMinusSign	proc	near
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	ge	cx, ax
	Assert	ge	dx, bx
;;;;;;;;

	sub	cx, ax			; width = right - left
	sub	dx, bx			; height = bottom - top

	cmp	cx, HWR_MIN_WIDTH
	jl	exit			; carry SET if jump

	cmp	dx, HWR_MAX_HEIGHT
	jg	invertCarry		; carry CLEAR if jump

	mov	ax, HWR_SLOPE_FACTOR
	mul	dx
	cmp	ax, cx
	
	; carry SET if width > HWR_SLOPE_FACTOR*height 

invertCarry:
	cmc
exit:

	.leave
	ret
HwrCheckIfMinusSign	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrUntransformPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applies to a Point a reverse transformation from
		screen coordinate to document coordinate.

		Note: will not make any assertions about the points
		passed in and passed in the Zoomer2 Demo, because
		we'll get points that's outside of the Board's bound.
		This might be just because of the GET_BUFFER_PTR hack
		we're using right now.  Maybe once we get the
		GET_BOUNDS api, then we'll get valid points and then
		we'll make our assertions. 

CALLED BY:	HwrPreRecMinusSign, HwrTransformPalmToDoc

PASS:		ax	= x 
		bx	= y 

		NOTE! ds - should not be pointing an lmem block
		because it will not be fixed up.

RETURN:		(untransformed non-negative values)
		ax	= x 
		bx	= y 

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING: ds - should not be pointing an lmem block because it
		 will not be fixed up. 

PSEUDO CODE/STRATEGY:
	Query the Board for the GState.
	Call WinUntransform.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrUntransformPoint	proc	near
	uses	cx,dx,si,di,bp
	.enter

	push	ax, bx			; save Point

	; Query for GState handle
	mov	bx, handle Board	; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjMessage

	mov	di, bp			; GState
	pop	ax, bx			; (x,y) = screen coord
	call	GrUntransform		; (x,y) = doc coord
EC <	ERROR_C	HWR_UNTRANSFORMATION_OVERFLOW			>

	movdw	cxdx, axbx		; dummy values
	call	HwrZeroOutNegative
	call	HwrClipDC
	call	GrDestroyState		; destroy GState

;;; Verify return value(s)
	Assert	InGrid	axbx
;;;;;;;;

	.leave
	ret
HwrUntransformPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrClipDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Limits the point's coordinates to be within the grid.

CALLED BY:	HwrUntransformPoint

PASS:		ax,bx	= Point	(non-negative values)

RETURN:		ax,bx	= Clipped Point

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING: ds - should not be pointing an lmem block because it
		 will not be fixed up. 

PSEUDO CODE/STRATEGY:
	Send MSG_CWORD_BOARD_CLIP_DC to the Board.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrClipDC	proc	near
	uses	cx,dx,si,di
	.enter

;;; Verify argument(s)
	Assert	ge	ax, 0
	Assert	ge	bx, 0
;;;;;;;;

	movdw	cxdx, axbx		; center point

	; Limit the point only to values within the Board.
	mov	bx, handle Board	; single-launchable
	mov	si, offset Board
	mov	di, mask MF_CALL
	mov	ax, MSG_CWORD_BOARD_CLIP_DC
	call	ObjMessage

	movdw	axbx, cxdx		; clipped center point

;;; Verify return value(s)
	Assert	InGrid	axbx
;;;;;;;;

	.leave
	ret
HwrClipDC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrSetupFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine makes calls into the HWR library to set
		up the specific filter necessary for our Crossword
		project, ie. filter out everything but the Cword
		Alphabet.  It also sets up the callback routine to be
		used.

CALLED BY:	HwrDoHWR

PASS:		di	- handle to HWR library
		bx	- handle to TextQueueBlock

RETURN:		CF	- SET if error

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Disable all of the character set.  Then, selectively enable
	particular ranges and characters.		

	WARNING: This version does not support DBCS.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrSetupFilter	proc	near
	uses	ax,bx,cx,dx,es,di,si
	.enter

;;; Verify argument(s)
	Assert	handle	di
	Assert	TextQueueBlock	bx
;;;;;;;;

	; Setup character callback routine
	mov	ax, offset HwrCharCallbackFilter
	pushdw	csax		; fptr to HwrCharCallbackFilter
	pushdw	bxbx		; 'optr' to callback data, 
				; HACK! second handle is not used 
	CallHWRLibrary HWRR_SET_CHAR_FILTER_CALLBACK


	; Set up filter to allow only characters of the Cword Alphabet.

	HwrDisableCharRangeImmed di, 0, 0xffff	; Disable all

	; Enable '?', '-', '.'
	HwrEnableCharRangeImmed	di, C_QUESTION_MARK, C_QUESTION_MARK
	HwrEnableCharRangeImmed	di, C_MINUS, C_MINUS
	HwrEnableCharRangeImmed	di, C_PERIOD, C_PERIOD
	HwrEnableCharRangeImmed	di, C_SPACE, C_SPACE

	; Get the character set from the .UI file
	mov	bx, handle CwordStrings		; single-launchable
	call	MemLock				; lock down char set
	push	bx				; handle CwordCharSet
	mov	es, ax				; segment CwordCharSet
	mov	si, offset HWREnabledChars

	push	di				; ^h HWRLib
	call	GetCharacterSetString
	pop	si				; ^h HWRLib
	jc	exit				; jump on error

	; Enable character set
enableCharRange:
	push	cx				; loop count
	mov	ax, {word}es:[di]		; al - 1st of pair
	mov	dl, ah				; 2nd of pair
	clr	ah, dh
	HwrEnableCharRange	si, ax, dx
	pop	cx				; loop count
	add	di, 2
	loop	enableCharRange

exit:
	pop	bx				; handle CwordCharSet
	call	MemUnlock			; release char set

	.leave
	ret
HwrSetupFilter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCheckIfCwordGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed data is a gesture.

CALLED BY:	Global

PASS:		points, numPoints, numStrokes

RETURN:		ax	- total number of points recognized as part of
			  a gesture

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	NOTE!! Copied from CheckIfTextGesture in penCode.asm.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
HwrCheckIfCwordGesture	proc	far	points:fptr,
					numPoints:word,
					numStrokes:word

	uses	cx, di, es
	.enter

;	If this is not the first call to the gesture callback routine, just
;	exit, because if it wasn't a gesture before, it sure won't be one
;	now...
	clr	ax

	test	numStrokes,  mask GCF_FIRST_CALL
	jnz	cont
	
	cmp	numStrokes, 1
	jne	exit

cont:
	les	di, points
	mov	cx, numPoints
	call	HwrStrokeEnum
	mov	ax, bx

exit:

	.leave
	ret
HwrCheckIfCwordGesture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrStrokeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate through the strokes

CALLED BY:	CheckIfTextGesture

PASS:		es:di 	- ptr to buffer of points
		cx	- num points total

RETURN:		bx	- total number of points recognized as part of
			- a gesture

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    while all strokes not checked
	while not the last point in a stroke 
		inc the number of points in this stroke
		goto the next point
	call routine to deal with this stroke and check to see if it
		is a gesture
	If it is not a gesture then quit
	If it is a gesture add the number of points in this stroke to
		the total of all points that are part of a stroke

    return the total of all points that were part of a stroke 		

    NOTE!!  Copied this from StrokeEnum in penCode.asm.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrStrokeEnum	proc	near
	uses	ax,cx,dx,si,di
	.enter
	
	mov	si, di			
	sub	si, size Point		; es:si - ptr to ink Points
	clr	bx			; total number of points recognized

loopStrokes:
	clr	dx			; # of points in stroke

	jcxz	exit
loopPoints:
	inc	dx			; # of points in stroke
	add	si, size Point
	test	es:[si], mask IXC_TERMINATE_STROKE
	loopz	loopPoints
	
endLoopPoints::
	; found end of stroke, call function
	xchg	cx, dx			; # points in stroke, loop count
	call	HwrCheckIfGesture
	xchg	cx, dx			; loop count, # points in stroke
	jc	endLoopStrokes		; leave if not a gesture

	add	bx, dx			; total num points thus far.
	mov	di, si
	add	di, size Point
	jmp 	loopStrokes

endLoopStrokes:
exit:

	.leave
	ret
HwrStrokeEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCheckIfGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed ink is any sort of
		gesture.  If it is a gesture, calls the routine
		associated with that gesture. 

CALLED BY:	HwrStrokeEnum

PASS:		es:di - ptr to stroke
		cx - # points in the stroke

RETURN:		CF	- CLEAR if a gesture (AX = GestureType)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	NOTE!! 	Copied code from CheckIfGesture in cmainHWRGrid.asm.
		Modified a little bit to work with our code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCheckIfGesture	proc	near

numPoints	local	word	push	cx	
points		local	fptr
gestureBounds	local	Rectangle

	uses	ax,bx,cx,dx,di
	.enter

	ForceRef	gestureBounds

	movdw	ss:[points], esdi
	call	UserGetHWRLibraryHandle
	tst	ax				; Exit if no HWR library
	LONG jz	error
	mov_tr	di, ax				; ^h hwrLib

	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	LONG jnz 	error			; If error, exit

	CallHWRLibrary	HWRR_RESET

	; Send the ink points to the HWR recognizer

	push	ss:[numPoints]
	pushdw	ss:[points]
	CallHWRLibrary	HWRR_ADD_POINTS

	CallHWRLibrary	HWRR_DO_GESTURE_RECOGNITION
	;Returns AX = GestureType
	;Returns dx = extra gesture info (only in Griffiti aka P3)

	call	HwrGetGestureBounds

	push	ax, dx				; GestureType, gesture info
	CallHWRLibrary	HWRR_END_INTERACTION
	pop	ax, dx				; GestureType, gesture info

	; Map the gesture to its routine
	mov	bx, ax					; GestureType

EC <	pushf						>
EC <	cmp	bx, GestureType				>
EC <	ERROR_A	HWR_INVALID_GESTURE			>
EC <	popf						>

	shl	bx, 1			; index into our nptr table
	call	cs:[handleGestureTable][bx]
	jmp	exit

error:
	stc
exit:
	.leave
	ret
HwrCheckIfGesture	endp


; These routines ...
; Pass:		ax 	- GestureType
;		dx 	- extra gesture information (only in P3)
;		bp 	- inherited stack frame
;		^hdi	- HWR library
; Return:	CF	- SET if is not a gesture or in the case of
; 		 	  GT_NO_GESTURE, if it wasn't handled.
; Destroys:	nothing
; Side Effects:	none

handleGestureTable	nptr	\
	HwrHandleGestureNull,		; GT_NO_GESTURE
	HwrHandleGestureDelete,		; GT_DELETE_CHARS
	HwrHandleGestureNull,		; GT_SELECT_CHARS
	HwrHandleGestureNull,		; GT_V_CROSSOUT
	HwrHandleGestureNull,		; GT_H_CROSSOUT
	HwrHandleGestureDelete,		; GT_BACKSPACE
	HwrHandleGestureChar,		; GT_CHAR
	HwrHandleGestureNull,		; GT_STRING_MACRO
	HwrHandleGestureIgnoreGesture,	; GT_IGNORE_GESTURE
	HwrHandleGestureNull,		; GT_COPY
	HwrHandleGestureNull,		; GT_PASTE
	HwrHandleGestureNull,		; GT_CUT
	HwrHandleGestureModeChar,	; GT_MODE_CHAR
	HwrHandleGestureReplaceLastChar	; GT_REPLACE_LAST_CHAR

.assert( (length handleGestureTable) eq GestureType )



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetGestureBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the gesture of the bounds.

CALLED BY:	HwrCheckIfGesture

PASS:		points, numPoints, gestureBounds all on the stack
		bp 	- inherited stack frame
		^hdi	- HWR library

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	If using current HWR library, will call into the library to
	get the bounds, else calculate the bounds from the ink points.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetGestureBounds	proc	near
	uses	ax,bx,es
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
;;;;;;;;

	; If we should have problem with the HWR library call
	; HWRR_GET_GESTURE_BOUNDS, then we'll resort to the brute
	; force way, which is to calculate it from the points. 

	call	HwrGetGestureBoundsFromLibrary
	jnc	exit				; jmp if got bounds
	call	HwrGetGestureBoundsFromInkPoints

exit:
	.leave
	ret
HwrGetGestureBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetGestureBoundsFromInkPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since we're not using the most current HWR library,
		ie. probably still using PalmPrint, will need to get 
		the bounds of the points passed to us. 

CALLED BY:	HwrGetGestureBounds

PASS:		points, numPoints, gestureBounds all on the stack
		bp 	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	initialize left, top, right, bottom with first point

	loop through the remaining points {
		if point.x < left
			left = point.x
		if point.x > right
			right = point.x
		if point.y < top
			top = point.y
		if point.y > bottom
			bottom = point.y
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetGestureBoundsFromInkPoints	proc	near
	uses	ax,cx,di,es
	.enter	inherit	HwrGetGestureBounds

	mov	cx, ss:[numPoints]
	movdw	esdi, ss:[points]

	; Set the initial bounds for this stroke.
	mov	ax, mask IXC_X_COORD
	and	ax, es:[di].P_x
	mov	ss:[gestureBounds].R_left, ax
	mov_tr	ss:[gestureBounds].R_right, ax
	mov	ax, es:[di].P_y
	mov	ss:[gestureBounds].R_top, ax
	mov_tr	ss:[gestureBounds].R_bottom, ax
	dec	cx					; for initial point
	tst	cx
	jz	gotBounds				; exit if no 
							; more points

loopPoints:
	add	di, size Point
	mov	ax, mask IXC_X_COORD
	and	ax, es:[di].P_x
	; Set left bound to lesser of two values
	cmp	ax, ss:[gestureBounds].R_left
	jge	cont1
	mov	ss:[gestureBounds].R_left, ax
cont1:
	; Set right bound to greater of two values
	cmp	ax, ss:[gestureBounds].R_right
	jle	cont2
	mov	ss:[gestureBounds].R_right, ax
cont2:
	; Set top bound to lesser of two values
	mov	ax, es:[di].P_y
	cmp	ax, ss:[gestureBounds].R_top
	jge	cont3
	mov	ss:[gestureBounds].R_top, ax
cont3:
	; Set bottom bound to greater of two values
	cmp	ax, ss:[gestureBounds].R_bottom
	jle	cont4
	mov	ss:[gestureBounds].R_bottom, ax
cont4:
	loop	loopPoints

gotBounds:
	clc

	.leave
	ret
HwrGetGestureBoundsFromInkPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrGetGestureBoundsFromLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will get the bounds of the gesture by calling
		HWRR_GET_GESTURE_BOUND in the HWR library.

CALLED BY:	HwrGetGestureBounds
PASS:		points, numPoints, gestureBounds all on the stack
		bp 	- inherited stack frame
		^hdi	- HWR library

RETURN:		CF	- SET if error and didn't get gestureBounds 
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrGetGestureBoundsFromLibrary	proc	near
	uses	ax,bx,cx,dx,es
	.enter	inherit HwrGetGestureBounds

;;; Verify argument(s)
	Assert	handle	di
;;;;;;;;

	call	HwrCheckIfCurrentAPI
	jc	exit

	CallHWRLibrary	HWRR_GET_GESTURE_BOUNDS
	tst	ax
	jz	err

	mov_tr	bx, ax			; handle to Rectangle
	call	MemLock
	mov	es, ax			; ptr to Rectangle

	mov_tr	ax, es:[R_left]
	mov_tr	ss:[gestureBounds].R_left, ax
	mov_tr	ax, es:[R_top]
	mov_tr	ss:[gestureBounds].R_top, ax
	mov_tr	ax, es:[R_right]
	mov_tr	ss:[gestureBounds].R_right, ax
	mov_tr	ax, es:[R_bottom]
	mov_tr	ss:[gestureBounds].R_bottom, ax

	call	MemFree			; no need for handle anymore
	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	stc
	jmp	exit
HwrGetGestureBoundsFromLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place holder for gesture handlers not yet implemented.

CALLED BY:	HwrCheckIfGesture
PASS:		nothing
RETURN:		CF	- SET (not handled so do HWR on ink)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureNull	proc	near
	.enter

	stc

	.leave
	ret
HwrHandleGestureNull	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the "delete" gesture.  Basically send to the
		Board a MINUS character with its bounds.

CALLED BY:	HwrCheckIfGesture

PASS:		^hdi	- HWR library
		ax	- GestureType
		dx	- nothing (only in Graffiti)
		bp	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureDelete	proc	near
	uses	ax,dx
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
if ERROR_CHECK
	cmp	ax, GT_DELETE_CHARS
	je	doneEC
	Assert	e ax, GT_BACKSPACE
doneEC:
endif
;;;;;;;;

	mov	ax, MSG_CWORD_BOARD_GESTURE_CHAR
	mov	dx, C_MINUS
	call	HwrSendCharAndBoundsToBoard
	
	clc

	.leave
	ret
HwrHandleGestureDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the gesture GT_CHAR.  Basically send to the
		Board the character with its bounds.

CALLED BY:	HwrCheckIfGesture

PASS:		^hdi	- HWR library
		ax	- GestureType
		dx	- character (only in Graffiti)
		bp	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureChar	proc	near
	uses	ax
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
	Assert	e	ax, GT_CHAR
;;;;;;;;

	mov	ax, MSG_CWORD_BOARD_GESTURE_CHAR
	call	HwrSendCharAndBoundsToBoard
	
	clc
	
	.leave
	ret
HwrHandleGestureChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureModeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the gesture GT_MODE_CHAR.  Basically send
		to the Board the Mode Character with its bounds.

CALLED BY:	HwrCheckIfGesture

PASS:		^hdi	- HWR library
		ax	- GestureType
		dx	- Mode Character (only in Graffiti)
		bp	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureModeChar	proc	near
	uses	ax
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
	Assert	e	ax, GT_MODE_CHAR
;;;;;;;;

	mov	ax, MSG_CWORD_BOARD_GESTURE_SET_MODE_CHAR
	call	HwrSendCharAndBoundsToBoard
	
	clc

	.leave
	ret
HwrHandleGestureModeChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureReplaceLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the gesture GT_REPLACE_LAST_CHAR.
		Basically send to the Board the new charater with its
		bounds.

CALLED BY:	HwrCheckIfGesture

PASS:		^hdi	- HWR library
		ax	- GestureType
		dx	- new character (only in Graffiti)
		bp	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureReplaceLastChar	proc	near
	uses	ax
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
	Assert	e	ax, GT_REPLACE_LAST_CHAR
;;;;;;;;

	mov	ax, MSG_CWORD_BOARD_GESTURE_REPLACE_LAST_CHAR
	call	HwrSendCharAndBoundsToBoard
	
	clc

	.leave
	ret
HwrHandleGestureReplaceLastChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrHandleGestureIgnoreGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the gesture GT_IGNORE_GESTURE.  Send a
		GESTURE_RESET_MACRO message to the Board.

CALLED BY:	HwrCheckIfGesture

PASS:		^hdi	- HWR library
		ax	- GestureType
		dx	- new character (only in Graffiti)
		bp	- inherited stack frame

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrHandleGestureIgnoreGesture	proc	near
	uses	ax
	.enter	inherit	HwrCheckIfGesture

;;; Verify argument(s)
	Assert	handle	di
	Assert	e	ax, GT_IGNORE_GESTURE
;;;;;;;;

	mov	ax, MSG_CWORD_BOARD_GESTURE_RESET_MACRO
	call	HwrSendCharAndBoundsToBoard
	
	clc

	.leave
	ret
HwrHandleGestureIgnoreGesture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrSendCharAndBoundsToBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the given character and its bounds position to
		the Board to handle.  Note: bounds are in screen
		coordinates.

CALLED BY:	HwrPreRecMinusSign, HwrPreRecPeriod,
		HwrHandleGesture routines

PASS:		ax	- Message # to send to board
		bp	- inherited stack frame
		dx	- character

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrSendCharAndBoundsToBoard	proc	near
	uses	ax,cx,bx,si
	.enter	inherit	HwrCheckIfGesture

	sub	sp, size Rectangle		; allocate buffer
	mov	bx, sp				; ss:bx - ptr to Rectangle

	; Extract the coordinates
	mov_tr	si, ax				; message #
	mov	ax, ss:[gestureBounds].R_left
	mov_tr	ss:[bx].R_left, ax
	mov	ax, ss:[gestureBounds].R_top
	mov_tr	ss:[bx].R_top, ax
	mov	ax, ss:[gestureBounds].R_right
	mov_tr	ss:[bx].R_right, ax
	mov	ax, ss:[gestureBounds].R_bottom
	mov_tr	ss:[bx].R_bottom, ax

	push	bp

	mov_tr	ax, si				; message #
	mov	bp, bx				; ptr Rectangle
	mov	cx, dx				; character
	call	HwrSendGestureActionToBoard

	pop	bp				; stack frame ptr

	add	sp, size Rectangle		; deallocte buffer

	.leave
	ret
HwrSendCharAndBoundsToBoard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrSendPreRecCharAndBoundsToBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the pre-recognized character and it's bounds to
		the Board to handle.  Note: bounds are in screen
		coordinates.

CALLED BY:	HwrPreRecPeriod, HwrPreRecMinusSign

PASS:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom
		si	- msg #
		bp	- character

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrSendPreRecCharAndBoundsToBoard	proc	near
	uses	ax,cx,di
	.enter

	mov	di, bp			; character
	BoardAllocStructOnStack		Rectangle
	mov	ss:[bp].R_left, ax
	mov	ss:[bp].R_top, bx
	mov	ss:[bp].R_right, cx
	mov	ss:[bp].R_bottom, dx

	mov	ax, si			; Message #
	mov	cx, di			; character
	call	HwrSendGestureActionToBoard
	BoardDeAllocStructOnStack	Rectangle
	mov	bp, di			; character (restore register)

	.leave
	ret
HwrSendPreRecCharAndBoundsToBoard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrSendGestureActionToBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the Board.  These messages are usually
		actions that needs to be taken upon recognition of a
		gesture. 

CALLED BY:	HwrSendCharAndBoundsToBoard

PASS:		ax	- Message #
		ss:[bp] - Rectangle (gesture bounds)
		cx	- other parameters to pass along with

RETURN:		nothing

DESTROYED:	whatever the method handler for the message stored in
		ax does

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrSendGestureActionToBoard	proc	near
	uses	bx,dx,si,di
	.enter

	mov	dx, size Rectangle
	mov	bx, handle Board
	mov	si, offset Board
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage	

	.leave
	ret
HwrSendGestureActionToBoard	endp


CwordHWRCode	ends




CwordCode	segment	resource

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	This segment should be the same as the one in board.asm.  I
;	moved these routines from the board.asm because functionally
;	it belongs in this file; but, there a many calls from the
;	CwordCode segment, so I kept these routines in the same segment. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrResetMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls HWRR_RESET_MACRO and returns dx.

CALLED BY:	BoardGestureResetMacroProc

PASS:		nothing

RETURN:		dx	- value return from HWRR_RESET_MACRO
		CF	- SET if error

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrResetMacro	proc	near
	uses	ax,bx,cx,di
	.enter

	call	UserGetHWRLibraryHandle
	tst	ax				; exit if no HWR library
	jz	err
	mov_tr	di, ax				; ^h HWRLib

	call	HwrCheckIfCurrentAPI
	jc	exit
	
	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	jnz	err

	CallHWRLibrary	HWRR_RESET_MACRO

	push	dx				; return value
	CallHWRLibrary	HWRR_END_INTERACTION
	pop	dx				; return value

	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	stc
	jmp	exit

HwrResetMacro	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HwrCheckIfCurrentAPI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check to see if the HWR API is current enough to
		support the calls.

CALLED BY:	HwrGetGestureBoundsFromLibrary, HwrResetMacro

PASS:		^hdi	- HWR geode

RETURN:		CF	- SET if not current enough
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HwrCheckIfCurrentAPI	proc	far
	uses	ax,bx,di,es
	.enter

	; call into library to get the bounds if this is a current
	; version of the hwr lib 
	mov	bx, di			; ^h HWR geode
	mov	ax, GGIT_GEODE_PROTOCOL
	segmov	es, ss
	sub	sp, size ProtocolNumber
	mov	di, sp			; es:di buffer
	call	GeodeGetInfo
	mov	ax, offset HwrGetGestureBoundsFromLibrary
	add	sp, size ProtocolNumber
	;
	; Since es:bx is still on the stack, don't push or pop
	; until after the cmp is made.
	;
	xchg	bx, di			; buffer ptr, ^h HWR geode
	cmp	es:[bx].PN_major, HWRLIB_PROTO_MAJOR_FOR_2_1
	jl	err			; if jmp: curr API doesn't support
					; HWRR_GET_GESTURE_BOUNDS 
	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	stc
	jmp	exit

HwrCheckIfCurrentAPI	endp


CwordCode	ends


