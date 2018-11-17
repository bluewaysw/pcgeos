COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		album
FILE:		album.asm

AUTHOR:		Gene Anderson, Mar 31, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/31/92		Initial revision

DESCRIPTION:
	code for Album specific screen-saver library

	$Id: album.asm,v 1.1 97/04/04 16:44:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include type.def
include geos.def
include geosmacro.def
include errorcheck.def
include library.def
include localmem.def
include graphics.def
include gstring.def
include win.def
include	geode.def
include object.def
include event.def
include metaClass.def
include processClass.def
include	geodeBuild.def
include thread.def
include timer.def
include initfile.def

include vm.def
include	fileEnum.def

UseLib	ui.def
UseLib	options.def
UseLib	saver.def

include	coreBlock.def

include character.def

;==============================================================================
;
;		  PUBLIC DECLARATION OF ENTRY POINTS
;
;==============================================================================

global	AlbumStart:far
global	AlbumStop:far
global	AlbumFetchUI:far
global	AlbumFetchHelp:far
global	AlbumSaveState:far
global	AlbumRestoreState:far
global	AlbumSaveOptions:far

global	AlbumSetPause:far
global	AlbumSetDuration:far
global	AlbumSetDrawMode:far
global	AlbumSetColor:far
global	AlbumEraseAndWait:far
global	AlbumDrawAndWait:far

;
; If you add options, update these
;
FIRST_OPTION_ENTRY	equ	enum AlbumSetPause
LAST_OPTION_ENTRY	equ	enum AlbumSetColor

;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================

ALBUM_PAUSE_MIN	equ	1
ALBUM_PAUSE_MAX	equ	60
ALBUM_PAUSE_DEFAULT	equ	10
ALBUM_PAUSE_STEP	equ	1

ALBUM_DURATION_MIN	equ	1
ALBUM_DURATION_MAX	equ	60
ALBUM_DURATION_DEFAULT	equ	10
ALBUM_DURATION_STEP	equ	1

ALBUM_MAX_BACKGROUNDS	equ	255	;must be < 256

;
; The state we save to our parent's state file on shutdown.
;
AlbumState	struc
    AS_pause		word			;pause between background
    AS_duration		word			;duration of each background
    AS_mode		SaverBitmapMode		;drawing mode
    AS_color		Colors			;background color
AlbumState	ends

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	album.rdef

udata	segment

;
; Current window and gstate to use for drawing.
;
curWindow	hptr.Window
curGState	hptr.GState
winHeight	word
winWidth	word

;
; Timer we started for moving
;
curTimer	hptr.HandleTimer
curTimerID	word

;
; Buffer of background bitmap filenames
;
fileBuffer	hptr				;handle of buffer
fileCount	word				;# of files in buffer

udata	ends

idata	segment

;
; Parameters for the Album, saved and restored to and from our parent's state
; file.
;
astate	AlbumState	<
    ALBUM_PAUSE_DEFAULT*60,
    ALBUM_DURATION_DEFAULT*60,
    SAVER_BITMAP_APPROPRIATE,
    -1
>

idata	ends

;==============================================================================
;
;		   EXTERNAL WELL-DEFINED INTERFACE
;
;==============================================================================
AlbumCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library
PASS:		cx	= window handle
		dx	= window height
		si	= window width
		di	= gstate handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumStart	proc	far
	uses	ax, bx, cx, dx, ds, es
	.enter
	call	SaverInitBlank
	segmov	ds, dgroup, ax
	;
	; Save the window and gstate we were given for later use.
	;
	mov	ds:[curWindow], cx
	mov	ds:[curGState], di
	mov	ds:[winHeight], dx
	mov	ds:[winWidth], si
	;
	; Build a list of the currently available backgrounds
	;
	call	BuildFileList
	jc	done				;branch if error
	;
	; Draw first background
	;
	call	AlbumDrawAndWait		;draw a background and wait
done:

	.leave
	ret
AlbumStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a list of background bitmap file names
CALLED BY:	AlbumStart()

PASS:		ds - seg addr of dgroup
RETURN:		ds:fileCount - # of files found
		ds:fileBuffer - handle of filename buffer
		carry - set if error
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildFileList	proc	near
	.enter

	mov	ds:fileCount, 0
	mov	ds:fileBuffer, 0
	;
	; Go to the right directory...
	;
	call	GotoBGDirectory
	jc	done				;branch if error
	;
	; Enum me jesus
	;
	sub	sp, size FileEnumParams
	mov	bp, sp

	mov	ss:[bp].FEP_fileTypes, mask FEFT_FILES or mask FEFT_GEOS \
					or mask FEFT_NON_EXECS
	mov	ss:[bp].FEP_searchFlags, mask FESF_TOKEN
	mov	ss:[bp].FEP_returnFlags, mask FERF_CREATE or \
				 FERT_DOS_NAME_ONLY shl (offset FERF_TYPES)
	mov	ss:[bp].FEP_bufSize, ALBUM_MAX_BACKGROUNDS
	mov	ss:[bp].FEP_skipCount, 0
	mov	{word}ss:[bp].FEP_tokenMatch.GFHT_chars+0,'BK'
	mov	{word}ss:[bp].FEP_tokenMatch.GFHT_chars+2,'GD'
	mov	ss:[bp].FEP_tokenMatch.GFHT_manufID,0
	call	FileEnum
	jc	done				;branch if error
	;
	; Save the filename buffer
	;
	mov	ds:fileCount, bx		;save count of files
	mov	ds:fileBuffer, cx		;save buffer handle
done:

	.leave
	ret
BuildFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoBGDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the background bitmap directory
CALLED BY:	BuildFileList()

PASS:		none
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

backgroundDir	char "BACKGRND",0

GotoBGDirectory	proc	near
	uses	ax, bx, dx, ds
	.enter

	;
	; Go to SYSTEM directory
	;
	mov	ax, SP_SYSTEM			;ax <- StandardPath
	call	FileSetStandardPath
	;
	; Go to the BACKGRND directory, which hopefully exists
	;
	clr	bx				;bx <- use current disk handle
	segmov	ds, cs, dx			;ds:dx <- ptr to directory name
	mov	dx, offset backgroundDir
	call	FileSetCurrentPath

	.leave
	ret
GotoBGDirectory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop drawing a Album

CALLED BY:	Parent library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumStop	proc	far
	uses	ds, bx, ax
	.enter
	segmov	ds, dgroup, ax
	
	;
	; Stop any timer we might have going
	;
	mov	bx, ds:[curTimer]
	mov	ax, ds:[curTimerID]
	call	TimerStop
	;
	; And mark the window and gstate as no longer existing.
	;
	clr	ax
	mov	ds:[curWindow], ax
	mov	ds:[curGState], ax
	;
	; Free the buffer of filenames, if it exists
	;
	clr	bx
	xchg	bx, ds:[fileBuffer]
	tst	bx				;any buffer?
	jz	done				;branch if no buffer
	call	MemFree
done:

	.leave
	ret
AlbumStop	endp

AlbumCode		ends

AlbumInitExit	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumFetchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the tree of options that affect how this thing
		performs.

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of option tree to add
		ax	= first entry point stored in OD's in the tree
		bx	= last entry point stored in OD's in the tree
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumFetchUI	proc	far
	uses	bp, si, di, ds
	.enter

	;
	; Duplicate the block -- we have all the items send us methods, so
	; we don't need to save the handle around.
	;
	mov	bx, handle AlbumOptions
	mov	ax, handle saver	; owned by the saver library so it
					;  can get into a state file
	call	ObjDuplicateBlock

	;
	; Return the root in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset AlbumRoot
	mov	ax, FIRST_OPTION_ENTRY	; first entry point used in OD's
	mov	bx, LAST_OPTION_ENTRY	; last entry point used in OD's
	.leave
	ret
AlbumFetchUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumFetchHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the help tree

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of help tree (cx == 0 for none)
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumFetchHelp	proc	far
	.enter

	mov	bx, handle AlbumHelp
	mov	ax, handle saver		;ax <- owned by 'saver'
	call	ObjDuplicateBlock
	;
	; Return in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset HelpBox

	.leave
	ret
AlbumFetchHelp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add our little state block to that saved by the generic
		saver library.

CALLED BY:	SF_SAVE_STATE
PASS:		cx	= handle of block to which to append our state
		dx	= first available byte in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumSaveState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Enlarge the block to hold our state information.
	;
		mov	bx, cx
		mov	ax, dx
		add	ax, size AlbumState + size word
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
		jc	done
	;
	; Copy our state block to the passed offset within the block.
	;
		mov	es, ax
		mov	di, dx
		segmov	ds, dgroup, si
		mov	si, offset astate
		mov	ax, size astate
		stosw		; save the size of the saved state first
		xchg	cx, ax
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
		call	MemUnlock
done:
		.leave
		ret
AlbumSaveState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our little state block from that saved by the generic
		saver library.

CALLED BY:	SF_RESTORE_STATE
PASS:		cx	= handle of block from which to retrieve our state
		dx	= start of our data in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumRestoreState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Lock down the block that holds our state information.
	;
		mov	bx, cx
		call	MemLock
		jc	done
		mov	ds, ax
	;
	; Copy our state block from the passed offset within the block.
	;
		segmov	es, dgroup, di
		mov	di, offset astate
		mov	cx, size astate
		mov	si, dx

		lodsw			; make sure the state is the right
					;  size.
		cmp	ax, cx
		jne	unlock		; if not, abort the restore
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
unlock:
		call	MemUnlock
done:
		.leave
		ret
AlbumRestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any extra options that need saving.

CALLED BY:	Generic saver library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumSaveOptions	proc	far
		.enter
		clc
		.leave
		ret
AlbumSaveOptions	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing entry point for the kernel's benefit

CALLED BY:	kernel
PASS:		di	= LibraryCallTypes
		cx	= handle of client, if LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlbumEntry	proc	far
	clc		; no errors
	ret
AlbumEntry	endp

ForceRef AlbumEntry

AlbumInitExit	ends

;==============================================================================
;
;		    DRAWING ROUTINES/ENTRY POINTS
;
;==============================================================================

AlbumCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumEraseAndWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the current background and pause for next background

CALLED BY:	AlbumDrawAndWait()
PASS:		none
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumEraseAndWait	proc	far
	.enter

	call	AlbumErase			;erase the current background

	segmov	ds, dgroup, ax

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[astate].AS_pause
	mov	dx, enum AlbumDrawAndWait

	call	SaverStartTimer
	mov	ds:[curTimer], bx
	mov	ds:[curTimerID], ax

	.leave
	ret
AlbumEraseAndWait	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumDrawAndWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a new background and hold it on screen for a while
CALLED BY:	AlbumEraseAndWait()

PASS:		none
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumDrawAndWait	proc	far
	.enter

	call	AlbumDraw			;draw a new background

	segmov	ds, dgroup, ax

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[astate].AS_duration
	mov	dx, enum AlbumEraseAndWait

	call	SaverStartTimer
	mov	ds:[curTimer], bx
	mov	ds:[curTimerID], ax

	.leave
	ret
AlbumDrawAndWait	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver
CALLED BY:	timer

PASS:		none
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumDraw	proc	near
	.enter

	segmov	ds, dgroup, ax
	;
	; Make sure there is a GState to draw with
	;		
	mov	di, ds:[curGState]
	tst	di
	jz	quit
	;
	; Open a BG bitmap file
	;
	call	OpenRandomBGFile		;open me jesus
	;
	; Fill the background with the requested color
	;
	pushf					;save any error from open
	push	bx				;save VM file handle
	mov	al, ds:[astate].AS_color
	cmp	al, -1				;random color?
	jne	gotColor			;branch if not random
	mov	dx, Colors
	call	SaverRandom
	mov	al, dl				;al <- Colors value
gotColor:
	mov	ah, COLOR_INDEX
	call	GrSetAreaColor
	clr	ax
	clr	bx
	mov	cx, ds:[winWidth]
	mov	dx, ds:[winHeight]		;(cx,dx) <- window width, height
	call	GrFillRect
	pop	bx				;bx <- VM file handle
	popf					;flags from VMOpen
	jc	quit				;branch if error opening
	;
	; Make sure the color attributes are correct for drawing
	;
	mov	ax, BLACK or (COLOR_INDEX shl 8)
	call	GrSetAreaColor
	call	GrSetTextColor
	;
	; Draw it...
	;
	mov	ax, ds:[astate].AS_mode	;ax <- SaverBitmapMode
	call	SaverDrawBGBitmap		;draw me jesus

	mov	al, FILE_NO_ERRORS
	call	VMClose				;close me jesus

quit:

	.leave
	ret
AlbumDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenRandomBGFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a random BG bitmap file
CALLED BY:	AlbumDraw()

PASS:		ds:fileBuffer - handle of filename buffer
		ds:fileCount - # of files in buffer
RETURN:		bx - handle of BG file
		carry - set if error
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenRandomBGFile	proc	near
	.enter

	;
	; Switch to the BACKGRND directory
	;
	call	GotoBGDirectory
	jc	quit				;branch if error
	;
	; Lock the buffer of filenames and pick a random file
	;
	mov	dx, ds:fileCount		;dx <- # of files
	tst	dx				;any files?
	jz	noFilesError			;branch if no files
	mov	bx, ds:fileBuffer		;bx <- handle of buffer
	call	MemLock				;lock me jesus
	jc	quit				;branch if error
	mov	ds, ax				;ds <- seg addr of buffer
	call	SaverRandom
	mov	al, DFIS_NAME_BUFFER_SIZE	;al <- size of each name
	mul	dl
	mov	dx, ax				;ds:dx <- ptr to file name
	;
	; Try to open the file
	;
	mov	ax, (VMO_OPEN shl 8) or (FILE_ACCESS_R or FILE_DENY_W)
	clr	cx
	call	VMOpen				;open says me
	;
	; Unlock the filename buffer
	;
	push	bx				;save VM file handle
	segmov	ds, dgroup, ax
	mov	bx, ds:fileBuffer		;bx <- handle of buffer
	call	MemUnlock
	pop	bx				;bx <- VM file handle
quit:
	.leave
	ret

noFilesError:
	stc					;carry <- error
	jmp	quit
OpenRandomBGFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumErase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the screen
CALLED BY:	

PASS:		none
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumErase	proc	near
	.enter

	segmov	ds, dgroup, ax
	;
	; Make sure there is a GState to draw with
	;		
	mov	di, ds:[curGState]
	tst	di
	jz	quit
	;
	; Set area color for erasure
	;
	mov	ax, BLACK or (COLOR_INDEX shl 8)
	call	GrSetAreaColor
	;
	; Erase the screen
	;
	clr	ax
	clr	bx
	mov	cx, ds:[winWidth]
	mov	dx, ds:[winHeight]		;(ax,bx,cx,dx) <- window bounds
	mov	si, SAVER_FADE_FAST_SPEED
	call	SaverFadePatternFade		;paint it black...

quit:
	.leave
	ret
AlbumErase	endp

AlbumCode	ends

AlbumInitExit	segment	resource
;==============================================================================
;
;		    UI ACTION HANDLER ENTRY POINTS
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSetPause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set pause between backgrounds
CALLED BY:	AlbumPauseRange

PASS:		cx - pause between backgrounds (seconds)
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumSetPause	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	ax, 60
	mul	cx
	mov	ds:[astate].AS_pause, ax

	.leave
	ret
AlbumSetPause	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSetDuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set duration of each background
CALLED BY:	AlbumDurationRange

PASS:		cx - duration of each background (seconds)
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumSetDuration	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	ax, 60
	mul	cx
	mov	ds:[astate].AS_duration, ax

	.leave
	ret
AlbumSetDuration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSetDrawMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set draw mode for bitmap drawing
CALLED BY:	AlbumDrawOptions list

PASS:		cx - SaverBitmapMode
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumSetDrawMode	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	ds:[astate].AS_mode, cx

	.leave
	ret
AlbumSetDrawMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlbumSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set color for bitmap drawing
CALLED BY:	AlbumColor list

PASS:		cl - Colors
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlbumSetColor	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	ds:[astate].AS_color, cl

	.leave
	ret
AlbumSetColor	endp

AlbumInitExit	ends
