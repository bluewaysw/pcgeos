COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CD Audio Interface
FILE:		cdplayer.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		Initial version
	Fred	11/91		First Revision

DESCRIPTION:
	This file contains the main code for the Play Audio CD application

RCS STAMP:
	$Id: cdplayer.asm,v 1.1 97/04/04 14:42:41 newdeal Exp $

TO DO

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------



_Application		= 1
ACCESS_FILE_INT		= 1		; get constants for fileInt.def

;Standard include files

include	geos.def
include geode.def
include	library.def

include heap.def
include resource.def
include input.def
include localize.def
include driver.def
include initfile.def

;include text.def
;include object.def
include	graphics.def
include gstring.def
include char.def
include	win.def
include lmem.def
include timer.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include thread.def
include cdplayer.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def
UseLib	Objects/gListC.def
UseLib	cdrom.def


; Structure which contains the active CD information 
CDContent	struc
	CD_firstTrack	  	byte
	CD_lastTrack	  	byte		; set to 1+ last track
	CD_currentTrack	  	byte
	CD_currentTimeTrack	word		; minutes high : seconds low
	CD_nextTrackStart	word		; minutes high : seconds low
	CD_currentTimeDisk	word		; minutes high : seconds low
	CD_remainingTime	word		; minutes high : seconds low
	CD_totalTimeTrack 	word		; length of track
	CD_totalTimeDisk  	word		; length of disk
	CD_volumeLevel	  	word		; loudness of cd
	CD_skipTracks		dword		; set bits to skip tracks
	CD_startSector		dword		; Start sector for loop
	CD_endSector		dword		; End sector for loop play
	CD_volumeSize	  	dword		; volume size (ABSOLUTE SECTOR)
	CD_BCDSize 	  	dword
	CD_UPCcode	  byte	12 dup (?)	; UPC number

CDContent	ends			;end of struc definition

CDTimeModes	etype	byte, 0
    TIME_IN_TRACK		enum	CDTimeModes
    TIME_IN_DISK		enum	CDTimeModes
    TIME_REMAINING_IN_TRACK	enum	CDTimeModes
    TIME_REMAINING_IN_DISK	enum	CDTimeModes



CDStates	etype	byte, 0
    CD_PLAYING		enum	CDStates
    CD_PAUSED		enum	CDStates
    CD_STOPPED		enum	CDStates

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		cdplayer.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;This is the class for CD play's process.

CDProcessClass	class	GenProcessClass

;METHOD DEFINITIONS: these methods are defined for CDProcessClass.

CD_METHOD_STOP_PRESSED			method
CD_METHOD_PLAY_PRESSED			method
CD_METHOD_PAUSE_PRESSED			method
CD_METHOD_NEXT_PRESSED			method
CD_METHOD_PREVIOUS_PRESSED		method
CD_METHOD_FORWARD_PRESSED		method
CD_METHOD_BACK_PRESSED			method
CD_METHOD_EJECT_PRESSED			method
CD_METHOD_TIME_PRESSED			method
CD_METHOD_SHUFFLE_PRESSED		method
CD_METHOD_BUTTON_ITEM_SELECTED		method
CD_METHOD_PLUS_10_SELECTED		method
CD_METHOD_MINUS_10_SELECTED		method
CD_METHOD_TIMER_TICK			method
CD_METHOD_VOLUME_CONTROL		method


CDProcessClass	endc	;end of class definition


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	CDProcessClass	mask CLASSF_NEVER_SAVED

;initialized variables

;SaveStart	label 	word	;START of data saved to state file ---------

;variable1	dw	20	; idata variable

;SaveEnd		label	word

cdUnion		CDStrucs	; data structures to be passed to MSCDEX
cdInput		InputStrucs
cdOutput	OutputStrucs

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment
cdFirstDrive	word
cdNumDrives	word
diskPresent	byte
diskType	byte		; CD_ROM or audio disk

startTrack	byte
runTime		byte
cdInfo		CDContent	; info about current CD Disk
timerHandle 	word		; handle for interrupt timer
tcHandle	word		; handle for Table of Contents block

BCDvolSize	RBStruct
PlayThing	PStruct		; structure for play information


udata	ends

;------------------------------------------------------------------------------
;		Code for CDProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	CDPlayerOpenApplication

DESCRIPTION:	This method is sent to this application as it is attached to
		the system.

PASS:		ds	= segment of DGroup (idata, udata, stack, etc)
		es	= segment of class definition (is in DGroup)
		bp	= handle of block on global heap which contains vars.

RETURN:		ds, si, es = same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
CDPlayerOpenApplication	method	CDProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION
	push	ax, bx, cx, dx, si, ds, es

	mov	di, offset CDProcessClass ;set es:di = class declaration
	call	ObjCallSuperNoLock	; put up UI superclass
					; (UI_Class for default handling)

	call 	Init_CD

	;restore registers 
	pop	ax, bx, cx, dx, si, ds, es
	ret
CDPlayerOpenApplication	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CDPlayerCloseApplication

DESCRIPTION:	This method is sent to this application as it is detached from
		the system.

PASS:		ds	= segment of DGroup (idata, udata, stack, etc)
		es	= segment of class definition (is in DGroup)

RETURN:		ds, si, es = same
		cx	= handle of block on global heap which
				contains variables

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
CDPlayerCloseApplication  method  CDProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
	mov	ax, dgroup
	mov	ds, ax
	call	StopUpdateTimer
	cmp	ds:diskPresent, DISK	; see if disk is there
	jne	91$

	mov	bx, ds:tcHandle		;Discard Table of Contents
	cmp	ds:tcHandle, 0		;see if handle exists
	je	91$
	call	MemFree			;Free mem block
	mov	ds:tcHandle, 0
91$:
	clr	cx			; pass no variable handle
	ret
CDPlayerCloseApplication	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_STOP_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Stop" GenTrigger. Calls StopRoutine to stop CD play.

PASS:		ds - dgroup

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDStopButton	method	CDProcessClass, CD_METHOD_STOP_PRESSED
	cmp	ds:diskPresent, DISK		; CD in drive?
	jne	41$
	call	StopRoutine			; Stop play
41$:
	ret
CDStopButton	endm
 


COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_PREVIOUS_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Reverse" GenTrigger. Rev  plays previous track 

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@

CDPreviousButton	method	CDProcessClass, CD_METHOD_PREVIOUS_PRESSED

	cmp	ds:diskPresent, DISK
	jne	41$
	cmp	ds:diskType, DISK_AUDIO
 	jne	41$
	mov	cl, ds:cdInfo.CD_currentTrack	

	cmp	ds:cdInfo.CD_firstTrack, cl	; is current track 1st track?
	jge	atMin				; if yes, no adjust

	dec	ds:cdInfo.CD_currentTrack	; current track -= 1;
	dec	cl
	cmp	cl, ds:startTrack		; at beginning of list?
	jge	atMin				; no , no list adjust
	sub	ds:startTrack, 10		; get previous page monikers
	call	ChangeMonikers			; change list monikers

atMin:
	call	MakeTracks
	mov	dh, ds:cdInfo.CD_lastTrack	; play to last track
	inc	dh
	mov	dl, ds:cdInfo.CD_currentTrack		; play from current track
	mov	cx, ds:cdFirstDrive
	call	CDPlayTrack
41$:
	ret
CDPreviousButton	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_NEXT_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Next" GenTrigger. Advances play to next track

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDNextButton	method	CDProcessClass, CD_METHOD_NEXT_PRESSED
	cmp	ds:diskPresent, DISK		; test for valid audio disk
	jne	41$
	cmp	ds:diskType, DISK_AUDIO
	jne	41$

	mov	cl, ds:cdInfo.CD_currentTrack		;get current track
	cmp	ds:cdInfo.CD_lastTrack, cl		; = largest track?
	jle	atMax				; if so, don't increment
	inc	ds:cdInfo.CD_currentTrack			;add 1 to current track
	inc	cl
	mov	bl, ds:startTrack		; check to see if 10
	add	bl, 10				; boundary crossed (for display)
	cmp	cl, bl
	jl	atMax
	add	ds:startTrack, 10		; new start point for display
	call	ChangeMonikers			; change list monikers
atMax:
	call	MakeTracks
	mov	dh, ds:cdInfo.CD_lastTrack	; play to last track
	inc	dh
	mov	dl, ds:cdInfo.CD_currentTrack		; play from current track
	mov	cx, ds:cdFirstDrive
	call	CDPlayTrack
41$:
	ret
CDNextButton	endm





COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_EJECT_PRESSED handler.
 
DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Eject" GenTrigger. Ejects CD from drive if function can be 
		supported by drive

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDEjectButton	method	CDProcessClass, CD_METHOD_EJECT_PRESSED
	cmp	ds:diskPresent, DISK
	jnz	40$
	call	StopUpdateTimer
	mov	ds:diskPresent, NO_DISK

	call 	RemoveDiskRoutine
	mov	cx, ds:cdFirstDrive

	push	es, ds
	call	LoadOutputStructures	
	call	CDEjectDisk		;Eject disk
	pop	 es, ds

	call	StartUpdateTimer
40$:
	ret
CDEjectButton	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_VOLUME_CONTROL handler.

DESCRIPTION:	This method is sent by UI thread for volume-altering 
		if CD has this capability

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		ax, cx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDVolumeControl	method	CDProcessClass, CD_METHOD_VOLUME_CONTROL
 	push	ds, es

	GetResourceHandleNS Interface, bx  ;set ^lbx:si = VolRange object
	mov	si, offset VolRange
	clr	bp			;pass bp = flags (none set)

	pop	cx
	push	cx
	mov	ax, MSG_GEN_RANGE_GET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;place method on UI's queue, and rest

	mov	dx, cx			;give 16 increments for volume
	mov	cl, 4
	shl	dx, cl			;volume for left channel
	mov	dh, dl			;volume for right channel

	call	LoadOutputStructures	
	mov	al, CHANNEL0
	mov	ah, CHANNEL1
	mov	cx, ds:cdFirstDrive
	call	CDAudioChannelControl
	pop	ds, es
	ret
CDVolumeControl	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_TIME_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Time" GenTrigger. Toggles displayed time between song time and
		total time

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDTimeButton	method	CDProcessClass, CD_METHOD_TIME_PRESSED
	xor	ds:runTime, 1		; toggle between song time & total time
	ret
CDTimeButton	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_PLAY_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Play" GenTrigger.

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDPlayButton	method	CDProcessClass, CD_METHOD_PLAY_PRESSED
	cmp	ds:diskPresent, DISK
	jne	41$
	cmp	ds:diskType, DISK_AUDIO
	je	40$
	call	DialogNotAudioDisk
	jmp	41$
40$:
	mov	dh, ds:cdInfo.CD_lastTrack		; play to last track
	inc	dh
	mov	dl, ds:cdInfo.CD_currentTrack		; play from current track
	mov	cx, ds:cdFirstDrive
	call	CDPlayTrack
41$:
	ret
CDPlayButton	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_FORWARD_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Forward" GenTrigger. Increments track play by n seconds

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		ax, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDForwardButton	method	CDProcessClass, CD_METHOD_FORWARD_PRESSED
	cmp	ds:diskPresent, DISK
	jne	41$

	clr	cx
	clr	ax
	mov	cl, ds:cdInfo.CD_currentTimeDisk.high
	mov	ah, ds:cdInfo.CD_currentTimeDisk.low

;	cl - minutes, ah - seconds, al - frames

	cmp	ah, 50
	jge	37$
	add	ah, TEN_SECONDS			; add 10 seconds to current 
	jmp	38$				; track
37$:
	sub	ah, 50
	add	cx, 1				; update minutes
38$:
	mov	ds:PlayThing.startSector.low, ax
 	mov	ds:PlayThing.startSector.high, cx
	call	ConvertRedBookToAbsolute
	mov	bx, ds:cdInfo.CD_volumeSize.low
	mov	dx, ds:cdInfo.CD_volumeSize.high
	sub	bx, ax
	sbb	dx, cx
	mov	ds:PlayThing.trackLen.low, bx
	mov	ds:PlayThing.trackLen.high, dx
	call	PlayAudio
41$:
	ret
CDForwardButton	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_BACK_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Back" GenTrigger. Moves current play position back by 10
		seconds.

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		ax, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDBackButton	method	CDProcessClass, CD_METHOD_BACK_PRESSED
	cmp	ds:diskPresent, DISK
	jne	19$

	clr	cx
	clr	ax
	mov	cl, ds:cdInfo.CD_currentTimeDisk.high
	mov	ah, ds:cdInfo.CD_currentTimeDisk.low

	cmp	ah, 10				; check to see if <=10 seconds
	jge	17$
	cmp	cx, 0			; First ten seconds of CD
	jle	19$			; No correction if first 10 seconds
	add	ah, 50

	dec 	cx
	jmp	18$
17$:
	sub	ah, TEN_SECONDS			; - 10 seconds
18$:
	mov	ds:PlayThing.startSector.low, ax
	mov	ds:PlayThing.startSector.high, cx	; get starting sector
 	call	ConvertRedBookToAbsolute
	mov	bx, ds:cdInfo.CD_volumeSize.low
	mov	dx, ds:cdInfo.CD_volumeSize.high
 	sub	bx, ax
	sbb	dx, cx
	mov	ds:PlayThing.trackLen.low, bx
	mov	ds:PlayThing.trackLen.high, dx

	call	PlayAudio
19$:
	ret
CDBackButton	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	CD_METHOD_PAUSE_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Pause" GenTrigger. When pushed while CD is playing, pauses
		play at that spot. Pressing Pause again will start play
		from the paused position

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDPauseButton	method CDProcessClass, CD_METHOD_PAUSE_PRESSED
	cmp	ds:diskPresent, DISK
	jne	91$

	mov	cx, ds:cdFirstDrive
	push	es, ds
	call	LoadInputStructures
	call	CDAudioStatus
	pop	es, ds

	test	ds:cdInput.inputName.StatStruct.AudStatus, 1
	jnz	89$

	call	StopAudio		;send stop command to drive
	jmp	91$
89$:
	call 	CDResumeAudio		;resume play
91$:
	ret
CDPauseButton	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	DoStatus - CD_METHOD_TIMER_TICK handler.

DESCRIPTION:	This method is sent by UI thread when the timer tick occurs.
		
PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		ax, cx

PSEUDO CODE/STRATEGY:
	For every timer tick, test to see if disk is in drive. This
	handles case where user ejects disk manually. If disk is in
	drive, check to see if disk is playing. If so, update time

	status = CheckForDisk();
	switch (status)  {
		case NODISK:
			if (diskPresent)   {
				RemoveDiskRoutine();
				diskPresent = FALSE;
				break;
			}
		case DISK:
			status = DiskPlaying();
			if (status == PLAY)
				UpdateTimeAndTrack();
			break;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
DoStatus	method  CDProcessClass, CD_METHOD_TIMER_TICK
	mov	cx, ds:cdFirstDrive		; test for drive in disk
	push	es, ds
	call	LoadInputStructures
	call	CDDeviceStatus			; LMS disk does not respond
	pop	es, ds
	test 	{word}cdInput.inputName.DevStruct.Parameters.low, mask DTS_DISK_ABSENT
	jne	nodisk

	cmp	ds:diskPresent, NO_DISK
	jne	diskthere
	mov	ds:cdInfo.CD_currentTrack, 1
	call	MakeTableofContents		; disk just inserted
	mov	ds:diskPresent, DISK
	jmp	12$

diskthere:
	push	es, ds
	call	LoadInputStructures		; set up struct for library call
	mov	cx, ds:cdFirstDrive
	call	CDQChannelInfo			; test for CD playing
	pop	es, ds
	test	ah, mask CDS_ERROR shr 8	; QChannel not implemented?
	jnz	noQChan
	test	ax, mask CDS_BUSY		; return error code
	jz	12$				; CD not playing?
	call	UpdateTimeAndTrack		; CD playing, update info
	jmp	12$
noQChan:						
	call	NoQUpdateTimeAndTrack		; for drives with no Q channel
	jmp	12$
nodisk:
	cmp	ds:diskPresent, DISK		; see if disk just removed
	jne	12$
	call 	RemoveDiskRoutine
	mov	ds:diskPresent, NO_DISK
12$:
	ret
DoStatus	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveDiskRoutine

DESCRIPTION:	Handles tasks when CD is removed, purges Table of 
		Contents, frees memory, and zeros track and time display

PASS: 		nothing

RETURN:		nothing

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:
		Discard table of contents
		Set time display to 0:00
		Set track display to 0
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
RemoveDiskRoutine	proc	near
	mov	bx, ds:tcHandle		;Discard Table of Contents
	cmp	ds:tcHandle, 0		;see if handle exists
	je	10$
	call	MemFree			;Free mem block
	mov	ds:tcHandle, 0
10$:
	clr	dx			;Clear time display
	call	MakeTime
	
	mov	al, 1
	mov	ds:cdInfo.CD_lastTrack, al		;Clear list
	mov	ds:startTrack, al	;Clear track display
	mov	ds:cdInfo.CD_currentTrack, al	;Clear track display
 
	call	ChangeMonikers
	call	MakeTracks

 	ret
RemoveDiskRoutine	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	UpdateTimeAndTrack 	

DESCRIPTION:	Update the time and track display when requested by the
		timer tick. Uses Q channel call.

PASS: 		nothing

RETURN:		nothing
	
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		trackNum = CDQChannelInfo(drive);
		if (trackNum != cdInfo.CD_currentTrack)  {
			cdInfo.CD_currentTrack = trackNum;
			MakeTracks(cdInfo.CD_currentTrack)
		}

		if (runTime == TOTAL_CD_TIME)
			MakeTime(totalTime);
		else
			MakeTime(trackTime);
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@

UpdateTimeAndTrack	proc	near
	push	bp

	mov	dl, RED_BOOK_MODE
	mov	cx, ds:cdFirstDrive
	push	es, ds
	call	LoadInputStructures
	call	CDHeadLocation			; get present position of head
	mov	ax, ds:cdInput.inputName.HeadStruct.HeadPosition.low
	mov	dx, ds:cdInput.inputName.HeadStruct.HeadPosition.high
	mov	dh, ah

	call	CDQChannelInfo			;get track num + running time
					;cl - minutes, ah- seconds, al - frames
 	pop	es, ds
	mov	dh, ds:cdInput.inputName.QStruct.Q_amin	;running time
	mov	dl, ds:cdInput.inputName.QStruct.Q_asec
	mov	ds:cdInfo.CD_currentTimeDisk, dx
	mov	cl, ds:cdInput.inputName.QStruct.Q_trackNum
	call	BCDtoBinary
	clr	ch
	cmp	cl, 0
	jne	running
	pop	bp
	ret
running:
 	cmp	ds:cdInfo.CD_currentTrack, cl
	jz	sameTrack
	mov	ds:cdInfo.CD_currentTrack, cl			; see if buttons need
	mov	bl, ds:startTrack			; updating
	add	bl, 10
	cmp	cl, bl
	jl	noUpdate
	add	ds:startTrack, 10
	call	ChangeMonikers				; add 10 to monikers
noUpdate:
 	call	MakeTracks
sameTrack:
	mov	cl, ds:BCDvolSize.Minute
	mov	ch, ds:BCDvolSize.Second
	mov	dl, ds:cdInput.inputName.QStruct.Q_amin	;running time
	mov	dh, ds:cdInput.inputName.QStruct.Q_asec
	cmp	cx, dx
	jne	noStop
	call	StopRoutine
	pop	bp
	ret
noStop:
	cmp	ds:runTime, 1
	jnz	72$
	mov	dl, ds:cdInput.inputName.QStruct.Q_minutes	;time in track
	mov	dh, ds:cdInput.inputName.QStruct.Q_seconds
72$:
	cmp	ds:cdInfo.CD_currentTimeTrack, dx
	jz	sameTime				;time has not changed

	mov	ds:cdInfo.CD_currentTimeTrack, dx
	call	MakeTime
sameTime:
	pop	bp
	ret
UpdateTimeAndTrack	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NoQUpdateTimeAndTrack 	(TIME DISPLAY FOR CD PLAYERS THAT DON'T
						 RESPOND TO Q-CHANNEL CALLS)

DESCRIPTION:	Update the time and track display when requested by the
		timer tick. For CD players that don't support Q-channel

PASS: 		Nothing

RETURN:		ds, es = same

DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		trackNum = CDQChannelInfo(drive);
		if (trackNum != cdInfo.CD_currentTrack)  {
			cdInfo.CD_currentTrack = trackNum;
			MakeTracks(cdInfo.CD_currentTrack)
		}


		if (runTime == TOTAL_CD_TIME)
			MakeTime(totalTime);
		else
			MakeTime(trackTime);
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
NoQUpdateTimeAndTrack	proc	near
	mov	dl, RED_BOOK_MODE
	push	es, ds
	call	LoadInputStructures
	call	CDHeadLocation
	pop	es, ds
	test	ax, mask CDS_BUSY			; test error code
	jnz	10$				; disk not playing
	ret

10$:
	mov	ax, ds:cdInput.inputName.HeadStruct.HeadPosition.low
	mov	dx, ds:cdInput.inputName.HeadStruct.HeadPosition.high
	mov	dh, ah

	cmp	ds:cdInfo.CD_currentTimeTrack, dx
	jnz	11$				;time has not changed
	ret
11$:

	mov	bx, ds:tcHandle			; get handle to TOC
	cmp	bx, 0
	jne	12$
	ret
12$:
	call	MemLock			; lock  down Table of Contents

	push	es
	segmov	es, ax

	clr	si
	clr	ch
	clr	di
	mov	cl, ds:cdInfo.CD_lastTrack
tLoop:
	inc	di
	add	si, size TableofContStruct	; set pointer to next entry
	mov	ax, es:[si].RBStartSec.low
	mov	bx, es:[si].RBStartSec.high
	mov	bh, ah				; ch is second of next track
						; cl is minute of next track
	cmp	dl, bl				; dl is present minute
	jl	59$
	jg	58$		
	cmp	dh, bh				; dh is present second
	jl	59$
58$:
	loop	tLoop

59$:
	mov	bx, di				; di has current track
	cmp	bl, ds:cdInfo.CD_lastTrack
	jle	60$
	mov	bl, ds:cdInfo.CD_lastTrack			; set upper track limit
60$:
	cmp	ds:cdInfo.CD_currentTrack, bl		; don't update track if same
	je	79$

	mov	ds:cdInfo.CD_currentTrack, bl
	mov	al, ds:cdInfo.CD_lastTrack
	cmp	al, bl
	je 	79$

	cmp	bl, ds:startTrack		; monikers need updating
	jge	61$
	sub	ds:startTrack, 10		; subtract 10 from monikers
	call	ChangeMonikers
	jmp	69$
61$:
	mov	cl, ds:startTrack		; monikers need updating
	add	cl, 10
	cmp	bl, cl			        ; bl has current track
	jl	69$
	add	ds:startTrack, 10
	call	StopUpdateTimer
	call	ChangeMonikers			; add 10 to monikers
	call	StartUpdateTimer
69$:
	call	MakeTracks
79$:
	sub	si, size TableofContStruct
	mov	ax, es:[si].RBStartSec.low
	mov	cx, es:[si].RBStartSec.high
	mov	ch, ah				; ch is second of present track
						; cl is minute of present track
	sub	dh, ch				; see if seconds need updating
	jae	75$
	add	dh, 60
75$:
	sbb	dl, cl				; update minutes
	mov	ds:cdInfo.CD_currentTimeTrack, dx
						; dl - minute, dh - second
	call	MakeTime
	mov	bx, ds:tcHandle			; unlock table of contents
	call	MemUnlock

	pop	es
	ret
NoQUpdateTimeAndTrack	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	StartUpdateTimer

DESCRIPTION:	Timer for updating time and track information while CD is
		playing. Set for .75 seconds.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		
------------------------------------------------------------------------------@
StartUpdateTimer	proc	far
	push	ds, es, bp
	mov	al, TIMER_EVENT_CONTINUAL	;set continuous timer
	clr	cx

	call	GeodeGetProcessHandle		;BX:SI
	clr	si				;SI

	mov	di, 50				;DI <- interval between ticks
	mov	dx, CD_METHOD_TIMER_TICK	;DX <- method sent out by timer
	mov	cx, 50				;CX <- time until first tick

	call	TimerStart
	mov	ds:timerHandle, bx		;save timer handle returned
						;by TimerStart
	pop	ds, es, bp	
	ret
StartUpdateTimer	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	StopUpdateTimer

DESCRIPTION:	Stops update timer

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91
------------------------------------------------------------------------------@

StopUpdateTimer	proc	far
	push	ds, es, bp
	mov	bx, ds:timerHandle		;BX - handle of timer
	clr	ax				;ax set to 0 for cont

	call	TimerStop

	pop	ds, es, bp
	ret
StopUpdateTimer	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetButtonItem

DESCRIPTION:	This method gets list entries from button list

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es
		bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	6/91		initial version

------------------------------------------------------------------------------@

GetButtonItem	method	CDProcessClass, CD_METHOD_BUTTON_ITEM_SELECTED
	cmp	ds:[diskPresent], DISK
	jne	41$ 
	cmp	ds:[diskType], DISK_AUDIO
	jne	41$

	push	ax, cx
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = SongList object
	mov	si, offset NumberList

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage		;place method on UI's queue, and

	add	cl, ds:startTrack	; cdInfo.CD_currentTrack = list position + 1
	cmp	cl, ds:cdInfo.CD_lastTrack
	jle	44$
	mov	cl, ds:cdInfo.CD_lastTrack

44$:
	mov	ds:cdInfo.CD_currentTrack, cl		; save current track
	call	MakeTracks
	mov	dh, ds:cdInfo.CD_lastTrack			; play to last track
	inc	dh
	mov	dl, ds:[cdInfo.CD_currentTrack]		; play from current track
	mov	cx, ds:[cdFirstDrive]
	call	CDPlayTrack

	pop	ax, cx
41$:
	ret
GetButtonItem	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetMinus10List

DESCRIPTION:	This method processes the single-entry -10 list

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	6/91		initial version

------------------------------------------------------------------------------@

GetMinus10List	method	CDProcessClass, CD_METHOD_MINUS_10_SELECTED
	cmp	ds:[diskPresent], DISK
	jne	41$
	cmp	ds:diskType, DISK_AUDIO
	jne	41$

	push	ax, cx
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = Minus10List object
	mov	si, offset Minus10List
;	mov	ax, MSG_GEN_LIST_DESELECT_ALL
;	mov	di, mask MF_CALL
;	call	ObjMessage

	mov	cl, ds:cdInfo.CD_currentTrack
	cmp	cl, 10
	jle	42$				; no action
	sub	cl, 10
	sub	ds:startTrack, 10

	mov	ds:cdInfo.CD_currentTrack, cl
	call	ChangeMonikers			; cl is preserved
	call	MakeTracks

	mov	dh, ds:cdInfo.CD_lastTrack			; play to last track
	inc	dh
	mov	dl, ds:cdInfo.CD_currentTrack		; play from current track
	mov	cx, ds:cdFirstDrive
	call	CDPlayTrack
42$:
	pop	ax, cx
41$:
	ret
GetMinus10List	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetPlus10List

DESCRIPTION:	This method processes the single-entry +10 list

PASS: 		ds - segment address of CDProcessClass

RETURN:		nothing

DESTROYED:	allowed to destroy - bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	6/91		initial version

------------------------------------------------------------------------------@

GetPlus10List	method	CDProcessClass, CD_METHOD_PLUS_10_SELECTED
	cmp	ds:diskPresent, DISK
	jne	41$
	cmp	ds:diskType, DISK_AUDIO
	jne	41$

; this code debounces +10 button

	push	ax, cx
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = Plus10List object
	mov	si, offset Plus10List
;	mov	ax, MSG_GEN_LIST_DESELECT_ALL
;	mov	di, mask MF_CALL
;	call	ObjMessage		

	mov	cl, ds:startTrack
	mov	dl, ds:cdInfo.CD_lastTrack
	sub	dl, cl
	cmp	dl, 9			; don't bother if  <= 10 tracks to go
	jle	45$			; put test here so button is
					; momentary
	mov	cl, 10
	add	cl, ds:cdInfo.CD_currentTrack	; cdInfo.CD_currentTrack = list position + 1
	add	ds:startTrack, 10
	cmp	cl, ds:cdInfo.CD_lastTrack
	jle	44$
	mov	cl, ds:cdInfo.CD_lastTrack
	cmp	cl, ds:startTrack 
	jge	44$
	sub	ds:startTrack, 10
44$:
	mov	ds:cdInfo.CD_currentTrack, cl
	call	ChangeMonikers
	call	MakeTracks
	mov	dh, ds:cdInfo.CD_lastTrack			; play to last track	
	inc	dh
	mov	dl, ds:cdInfo.CD_currentTrack		; play from current track
	mov	cx, ds:cdFirstDrive
	call	CDPlayTrack
45$:
	pop	ax, cx
41$:
	ret
GetPlus10List	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	MakeTableofContents

DESCRIPTION:	Reads table of contents from CD disk and creates copy in
		memory

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
MakeTableofContents	proc	near
	mov	ax, dgroup
	mov	ds, ax
	mov	cx, ds:cdFirstDrive
	push	es, ds
	call	LoadInputStructures
	call	CDAudioDiskInfo			;see if disk is playing
	pop	es, ds
	test	ax, mask CDS_BUSY
	jz	12$
;	call	StopAudio
12$:
	mov	ah, ds:cdInput.inputName.DiskStruct.HiTrackNum	;get high track
	mov	al, ds:cdInput.inputName.DiskStruct.LowTrackNum	;get low track
	cmp	ah, 1					;see if audio disk
	jg	14$
	call	DialogNotAudioDisk
	mov	ds:diskType, DISK_NOT_AUDIO	;set not audio disk flag
	mov	ds:tcHandle, 0			;no memory handle
	ret
14$:
	mov	ds:diskType, DISK_AUDIO		;
	mov	ds:cdInfo.CD_lastTrack, ah
	mov	ds:cdInfo.CD_firstTrack, al

	mov	ds:cdInfo.CD_currentTrack, al			;set current
							;track to loTrack
	mov	ax, ds:cdInput.inputName.DiskStruct.LeadOut.low
	mov	cx, ds:cdInput.inputName.DiskStruct.LeadOut.high
	mov	ds:BCDvolSize.low, ax
	mov	ds:BCDvolSize.high, cx

	call	ConvertRedBookToAbsolute
	mov	ds:cdInfo.CD_volumeSize.low, ax
	mov	ds:cdInfo.CD_volumeSize.high, cx

	call	ChangeMonikers
	mov	ds:cdInfo.CD_currentTrack, 1
	clr	cx
	call	MakeTracks
	ret
MakeTableofContents	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	StopRoutine

DESCRIPTION:	Stop CD from playing. Reset time and track information on
		UI.

PASS:		nothing

RETURN:		nothing

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
StopRoutine	proc	near
	call	StopAudio		;send stop command to drive

	mov	dl, ds:BCDvolSize.Minute
	mov	dh, ds:BCDvolSize.Second
	call	MakeTime		; display length of CD

	mov	cl, ds:cdInfo.CD_lastTrack		; display maximum number of tracks
	call	MakeTracks
	mov	al, ds:cdInfo.CD_firstTrack
	mov	ds:startTrack, al
	mov	ds:cdInfo.CD_currentTrack, al	; reset current track to first track
	call	ChangeMonikers
	clr	cx			; first track
	call	UpdateNumberList
	ret
StopRoutine	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	BCDtoBinary

DESCRIPTION:	Converts BCD pair to binary

PASS:		cx - BCD pair

RETURN:		cx - binary value of BCD pair

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
BCDtoBinary	proc	near
	mov	al, cl
	and	cl, 0fh
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	mov	bl, 10
	mul	bl
	add	cl, al
	ret
BCDtoBinary	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	MakeTime

DESCRIPTION:	Creates time string and displays it.

PASS: 		dl - Minute
		dh - Second

RETURN:

DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
MakeTime	proc	near
	displayBuf	local	8 dup (char)
	.enter
	push	ds, es, bp, cx

; the following code works for version 1.2 
	segmov	es, ss
	lea	bp, displayBuf		;ES:bp <- ptr to dest string buf
;	mov	si, DTF_MS
;	mov	di, DR_LOCAL_FORMAT_DATE_TIME
;	call	SysLocalInfo	TimeFormat

; DISPLAY THE TIME
	mov	dx, es			; DX:BP <- ptr to string
	mov	bp, di			; for 2.0
	clr	cx			; null-terminated

	GetResourceHandleNS  Interface, bx
	mov	si, offset TimeDisplay		;^lBX:SI <- OD of object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	ds, es, bp, cx
	.leave
	ret
MakeTime	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	MakeTracks

DESCRIPTION:	Displays current track number on UI.

PASS:		Nothing

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
 	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
MakeTracks	proc	near
	dispBuf	local	8 dup (char)
	.enter

	push	ds, es, bp, cx, dx, si
	clr	ah
	mov	al, ds:cdInfo.CD_currentTrack
	call	ConvertBinaryToASCII
	mov	dispBuf, ah		; tens digit
	mov	dispBuf+1, al		; ones digit
	mov	dispBuf+2, '-'		; string separator

	mov	al, ds:cdInfo.CD_lastTrack		; 	
	clr	ah			; 
	call	ConvertBinaryToASCII
	mov	dispBuf+3, ah		; tens digit
	mov	dispBuf+4, al		; ones digit
	mov	dispBuf+5, 0		; string terminator

	segmov	es, ss
	lea	bp, dispBuf		;ES:bp <- ptr to dest string buf

; DISPLAY THE TRACK NUMBER
	mov	dx, ss			;DX:BP <- ptr to string
	clr	cx			; null-term 

	GetResourceHandleNS  Interface, bx
	mov	si, offset TrackDisplay		;^lBX:SI <- OD of object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	clr	cx
	mov	cl, ds:cdInfo.CD_currentTrack	; calculate active list entry 
	mov	bl, ds:startTrack
	sub	cl, bl
	call	UpdateNumberList
	pop	ds, es, bp, cx, dx, si
	.leave
	ret
MakeTracks	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateNumberList

DESCRIPTION:	This method updates list entries when song changes

PASS: 		cx - position to set exclusive

RETURN:

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@

UpdateNumberList	proc	near
	push	bp, si, di, ds
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = NumberList object
	mov	si, offset NumberList

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
;	mov	bp, LET_POSITION shl offset LF_ENTRY_TYPE or \
;		mask LF_REFERENCE_USER_EXCL or mask LF_OVERRIDE_DISABLED \
;		or mask LF_FORCE_VISIBLE or mask LF_SUPPRESS_APPLY
	mov	di, mask MF_CALL
	call	ObjMessage		;place method on UI's queue, and

	pop	bp, si, di, ds
	ret
UpdateNumberList	endp




COMMENT @---------------------------------------------------------------------

FUNCTION:	EnableButtonList

DESCRIPTION:    Enable button entries to select track from list.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di

PSEUDOCODE STRATEGY
		for (i=0; i< cdInfo.CD_lastTrack; i++)
			EnableButton();
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
Table	word	Button1, Button2, Button3, Button4, Button5, Button6, Button7, Button8, Button9, Button10, Button10

MakeButtonList	proc	near
	mov	cx, 10
	clr	bx
34$:
 	mov	si, cs:Table[bx]		; get offset to Button object
	push	cx
	push	bx
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = Button object

	mov	ax, MSG_GEN_SET_ENABLED; enable buttons
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage		;place method on UI's queue, and
	pop	bx
	add	bl, size word		; get next entry in table (word)
	pop	cx
	loop	34$

	ret
MakeButtonList	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	ChangeMonikers

DESCRIPTION: 	Changes monikers on Track List

PASS:		Nothing

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDOCODE STRATEGY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
ChangeMonikers	proc	near
	vmonBuf	local	4 dup (char)
	.enter

	push	ds, es, bp, cx, dx, si

	clr	ax
	mov	al, ds:startTrack

	call	ConvertBinaryToASCII
	clr	dx
	mov	dl, ds:startTrack
	clr	bx			; Table entry pointer
	mov	cx, 9			; 10 entries
bigLoop$:
	push	cx
	push	ax
	push	bx
	push	dx

	mov	vmonBuf, ah		; tens digit
	mov	vmonBuf+1, al		; ones digit
	mov	vmonBuf+2, 0		; t-t-terminator
	lea	dx, vmonBuf
	mov	cx, ss			; 

 	mov	si, cs:Table[bx]	; get offset to Button object
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = NumberList object
	call	ChangeMonikerToNumber	; cx:dx points to vmonBuf
	
	pop	dx
	push	dx			; si is preserved
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = ButtonList object
	cmp	dl, ds:cdInfo.CD_lastTrack
	jle	26$
	call	GreyOutListEntry
	jmp	27$
26$:
	call	TurnOnListEntry
27$:
	pop	dx
	pop	bx
	
	pop	ax
	inc	al
	add	bl, 2			; get next entry in table (word)	
	inc	dl
		
	pop	cx
	loop	bigLoop$

; special case for tenth entry
	push	dx
					
	cmp	ah, ' '
	jne	25$
	mov	ah, '0'
25$:
	inc	ah			; always equals digit
	mov	vmonBuf, ah
	mov	vmonBuf+1, '0'		; ones digit
	mov	vmonBuf+2, 0		; terminator
	lea	dx, vmonBuf
	mov	cx, ss

 	mov	si, cs:Table[bx]	; get offset to Button object
	GetResourceHandleNS Interface, bx  ;set ^lbx:si = NumberList object
	call	ChangeMonikerToNumber	; cx:dx points to vmonBuf

	GetResourceHandleNS Interface, bx  ;set ^lbx:si = ButtonList object
	pop	dx
	cmp	dl, ds:cdInfo.CD_lastTrack
	jle	28$
	call	GreyOutListEntry
	jmp	29$
28$:
	call	TurnOnListEntry
29$:
;	now check to see if we grey out -10 button

	GetResourceHandleNS Interface, bx  ;set ^lbx:si = ButtonList object
	mov	si, offset Minus10List
	cmp	ds:startTrack, 1
	jne	30$
	call	GreyOutListEntry
	jmp	31$
30$:
	call	TurnOnListEntry
31$:
;	now check to see if we grey out +10 button

	GetResourceHandleNS Interface, bx  ;set ^lbx:si = ButtonList object
	mov	si, offset Plus10List
	mov	ch, ds:cdInfo.CD_lastTrack
	mov	cl, ds:startTrack
	sub	ch, cl
	cmp	ch, 10
	jge	32$
	call	GreyOutListEntry
	jmp	33$
32$:
	call	TurnOnListEntry
33$:
	pop	ds, es, bp, cx, dx, si
	.leave
	ret
ChangeMonikers	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DialogNoExtensions

DESCRIPTION:	This dialog is displayed whenever the MSCDEX extensions are
		not present

PASS: 		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx,di, es, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
DialogNoExtensions	proc near

	GetResourceHandleNS	CustomNoCDString, bx

	call	MemLock
	mov	di, ax
	mov	es, ax
	mov	bp, offset CustomNoExString
	mov	bp, es:[bp]
	mov	cx, es
	mov	si, offset CustomNoExArg
	mov	dx, es:[si]
	mov	al, SDBT_CUSTOM
	mov	ah, CustomDialogBoxFlags <FALSE, CDT_ERROR, GIT_NOTIFICATION>

	call	UserStandardDialog
	call	MemUnlock
 	ret
DialogNoExtensions	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DialogNotAudioDisk

DESCRIPTION:	This dialog is displayed whenever non-audio disk is detected 
		in drive

PASS: 		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx,di, es, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
DialogNotAudioDisk	proc near

	GetResourceHandleNS	CustomNotAudioString, bx
	call	MemLock
	mov	di, ax
	mov	es, ax
	mov	bp, offset CustomNotAudioString
	mov	bp, es:[bp]
	mov	cx, es
	mov	si, offset CustomNotAudioArg
	mov	dx, es:[si]
	mov	al, SDBT_CUSTOM
	mov	ah, CustomDialogBoxFlags <FALSE, CDT_ERROR, GIT_NOTIFICATION>

	call	UserStandardDialog
	call	MemUnlock
	ret
DialogNotAudioDisk	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DialogWrongCDExtension

DESCRIPTION:	This dialog is displayed when an inadequate version of MSCDEX
		is detected on the system. Must have at least version 2.2 of 
		MSCDEX to run this application.

PASS: 		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx,di, es, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
DialogWrongCDExtension	proc near

	GetResourceHandleNS	CustomWrongExtensions, bx
	call	MemLock
	mov	di, ax
	mov	es, ax
	mov	bp, offset CustomWrongExtensions
	mov	bp, es:[bp]
	mov	cx, es
	mov	si, offset CustomWrongArg
	mov	dx, es:[si]
	mov	al, SDBT_CUSTOM
	mov	ah, CustomDialogBoxFlags <FALSE, CDT_ERROR, GIT_NOTIFICATION>

	call	UserStandardDialog
	call	MemUnlock
	ret
DialogWrongCDExtension	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	Init_CD

DESCRIPTION:	System initialization

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	Get CD drive configuration
	Check to see if CD Extensions are loaded
	Check to see if MSCDEX Version 2.2 or greater is loaded
	If all is well, start status timer

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	Fred	5/91		initial version

------------------------------------------------------------------------------@
Init_CD	proc	near
	; system initialization

	call	CDGetDriveNumbers
	cmp	bx, 0			; see if MSCDEX is installed
	jnz	11$
	call	DialogNoExtensions	; MSCDEX not installed
	ret
11$:
	mov	ds:cdNumDrives, bx
 	mov	ds:cdFirstDrive, cx
	mov	ds:runTime, 1
	mov	ds:cdInfo.CD_currentTrack, 1
	mov	ds:cdInfo.CD_currentTimeDisk, 0
	mov	ds:startTrack, 1
	mov	ds:cdInfo.CD_lastTrack, 1
	mov	ds:diskPresent, NO_DISK
	mov	ds:diskType, DISK_NOT_AUDIO
	mov	ds:tcHandle, 0		; zero handle

	clr	bx
	call	CDGetExtenVersion	; check to see if 2.2 is loaded
	cmp	bh,2			;
	jl	wrongVer
	cmp	bl, 2
	jge	rightVer
wrongVer:
	call	DialogWrongCDExtension	;
	ret
rightVer:				; initialize CD-ROM system
	clr	dx			; initialize display
	call	MakeTime
	call	StartUpdateTimer	
	call	MakeButtonList
	call	ChangeMonikers
	call	MakeTracks
	ret
Init_CD	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	ChangeMonikerToNumber

DESCRIPTION:	Change list moniker to number

CALLED BY:	(METHOD_LIST_REQUEST_ENTRY_MONIKER)

PASS:		ss:di - CopyVisMonikerFrame

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
ChangeMonikerToNumber	proc	near
	ret
	ret
ChangeMonikerToNumber	endp




COMMENT @---------------------------------------------------------------------

FUNCTION:	ConvertBinaryToASCII

DESCRIPTION:	Converts binary value less than 100 to ASCII

PASS:		ax - binary value to be converted (to 99)

RETURN:
		ah - tens ASCII value
		al - ones ASCII value

DESTROYED:	nothing

REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
ConvertBinaryToASCII	proc	near
	mov	ah, ' '
	cmp	al, 9			; less than 10?
	jle	43$
	clr	ah
42$:
	sub	al, 10
	inc	ah			; calculate tens place
	cmp	al, 10
	jge	42$
	add	ah, '0'			; convert digit to ASCII
43$:
	add	al, '0'
	ret
ConvertBinaryToASCII	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	PlayAudio

DESCRIPTION:	Plays audio CD from specified sector. Sectors passed in 
		CD structures cdUnion and playThing.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
PlayAudio	proc	near
	call	StopAudio			; es:[bx] preserved in this call
	push	ds, es
	mov	ax, segment cdUnion
	mov	es, ax
	mov	bx, offset cdUnion	
	mov	ax, segment PlayThing			; make ds:[di]
	mov	ds, ax
	mov	di, offset PlayThing

	mov	al, RED_BOOK_MODE
	mov	cx, ds:cdFirstDrive
	call	CDPlayAudio
	pop	ds, es
	ret
PlayAudio	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	StopAudio

DESCRIPTION:	Stops audio CD from playing.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, di

REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
StopAudio	proc	near
	push	es
	mov	ax, segment cdUnion
	mov	es, ax
	mov	bx, offset cdUnion
	mov	cx, ds:cdFirstDrive
	call	CDStopAudio			; es:[bx] preserved in this call
	pop	es
	ret
StopAudio	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	LoadInputStructures

DESCRIPTION:	Sets up input structures used for MSCDEX calls

PASS:		nothing

RETURN:		es:bx - seg and offset of primary MSCDEX structure
		ds:di - seg and offset of MSCDEX input structure

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
LoadInputStructures  proc	near
	mov	ax, segment cdUnion
	mov	es, ax
	mov	bx, offset cdUnion
	mov	ax, segment cdInput
	mov	ds, ax
	mov	di, offset cdInput
	ret
LoadInputStructures	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	LoadOutputStructures

DESCRIPTION:	Set up output structures for CD Library calls

CALLED BY:	Before calling any output routine in CD Library that requires
		a data structure

PASS:		nothing

RETURN:		es:bx - seg and offset of primary MSCDEX structure
		ds:di - seg and offset of MSCDEX output structure

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
LoadOutputStructures  proc	near
	mov	ax, segment cdUnion
	mov	es, ax
	mov	bx, offset cdUnion
	mov	ax, segment cdOutput
	mov	ds, ax
	mov	di, offset cdOutput
	ret
LoadOutputStructures	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	GreyOutListEntry

DESCRIPTION:	Greys out nonvalid list entries.

CALLED BY:

PASS:		bx:si - pointer to list entry

RETURN:		nothing

DESTROYED:	ax, dx, di

REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
GreyOutListEntry	proc	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; turn off button
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage		;

	ret
GreyOutListEntry	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	TurnOnListEntry

DESCRIPTION:	Enables UI list entry

CALLED BY:

PASS:		bx:si - pointer to list entry

RETURN:		nothing

DESTROYED:	ax, bx, dx, si, di, ds, es
	
REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

-----------------------------------------------------------------------------@
TurnOnListEntry	proc	near
	mov	ax, MSG_GEN_SET_ENABLED	; enable button
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage			;

	ret
TurnOnListEntry	endp


CommonCode	ends		;end of CommonCode resource
