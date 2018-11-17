COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS Sound system
FILE:		soundCommon.asm

AUTHOR:		Todd Stumpf, Aug 3, 1992

ROUTINES:
	Name				Description
	----				-----------
global	SoundEntry			Sets up library
intern	SoundAttachLibrary		Load library into system
intern	SoundDetachLibrary		Remove Library from system
intern	SoundNewClient			A new process uses the library
intern	SoundNewClientThread		A new thread of a process was created
intern	SoundThreadExit			A thread using the library has exited
intern	SoundExit			A process using the library has exited

global	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 3/92		Initial revision
	TS	9/23/92		Changed for simplified interface

DESCRIPTION:
	These are the library routines for sound library for PC/GEOS.

	$Id: soundCommon.asm,v 1.1 97/04/07 10:46:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include product.def

udata	segment
	;  All driver routines invoked by the library are done so by
	;  loading the driver function you wish to execute in di and then
	;  calling the strategy routine of the driver.  The strategy
	;  routine is the first element in the DriverInfo struct.
	;
	soundSynthStrategy	fptr		; sound driver strategy fptr

	soundSynthHandle	hptr		; handle for synth driver

	streamStrategy		fptr		; stream driver strategy fptr

	;  Each driver will require stream-specific information (what
	;  the current controller values are, what instruments are
	;  assigned to which channel, etc.  This storage space is
	;  appended to the end of the SoundStreamStatus structure.
	;  To keep from querying the driver constantly, we query it
	;  at start up and store it here.
	driverVoices		word		; # of voice on device
	driverDACs		word		; # of dacs on device

	driverVoiceFormat	SupportedInstrumentFormat
	driverCapability	SoundDriverCapability
	driverDACCapability	SoundDriverDACCapability

	;  We can't let an application grab excusive access
	;  until all the threads are out of the library routines.
	libraryAccess		word
	exclusiveAccess		word

	;
	;  Inorder to use the UI, and not get into a problem where
	;	the UI needs the sound library to loaded first,
	;	and the sound library needs the UI to be loaded
	;	first, we load the UI ourselves, after we have
	;	been loaded, but before anyone else can do anything...
	userInterfaceHandle	word


udata	ends

idata		segment
	exclusiveSemaphore	Semaphore <1,>	; mutEx for get excluisve code
	librarySemaphore	Semaphore <1,>	; mutEx for library
idata		ends


InitCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call driver to initialize the sound board

CALLED BY:	global

PASS:		di	-> LibraryCallType
		cx	-> handle of client geode if LCT_NEW_CLIENT or
						     LCT_CLIENT_EXIT
		ds	-> dgroup
RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call appropriate routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundEntry	proc	far
	uses	di
	.enter
	shl	di,1				; index words (nptr actually..)
	call	cs:LibraryCallJumpTable[di]
	.leave
	ret
SoundEntry	endp


LibraryCallJumpTable	nptr	SoundAttachLibrary,
				SoundDetachLibrary,
				SoundNewClient,
				SoundNewClientThread,
				SoundThreadExit,
				SoundExit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundAttachLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the driver and set up the system stream

CALLED BY:	SoundEntry

PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		loads the standard sound driver and creates
		a system stream.

PSEUDO CODE/STRATEGY:
		When we first get set up, we need to contact the
		driver and see what its capabilities are and how much
		information it has.

		We also need to set up the exclusive access semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundAttachLibrary	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;  Now, we need to load the selected sound drivers.
	;  The current selections are probably stored in the
	;  .ini file.  If they are not, we use the standard
	;  PC/Speaker driver, and don't load any DAC driver.
	call	SoundGetDrivers				; load driver
	jc	chokeChokeChoke				; damn. an error.

	;
	;  With that, we need to query the drivers as to their
	;	capabilities so we know how many voices
	;	and DACs they support, as well as the quality
	;	of the sound they produces.
	;  To help support different types of DACs (like
	;	DMA vs FIFO), we also let the drivers
	;	specify a particular stream driver to
	;	use.  This allows the Sound Blaster to
	;	customize its stream driver for the
	;	utmost speed, while letting others
	;	use the regular stream driver.
	mov	di, DRE_SOUND_QUERY_DEVICE_CAPABILITY
	call	ds:[soundSynthStrategy]
	mov	ds:[driverVoices], ax			; store # of voices
	mov	ds:[driverVoiceFormat], bx
	mov	ds:[driverCapability], cx		; store capabilities
	mov	ds:[driverDACs], dx			; store # of DACs
	mov	ds:[driverDACCapability], di		; store DAC capability

	cmpdw	bpsi, 0
	jnz	storeSampleStreamStrategy

	mov	bp, segment StreamStrategy		; bp:si <- default
	mov	si, offset StreamStrategy

storeSampleStreamStrategy:
	movdw	ds:[streamStrategy], bpsi		; store stream strat

	;
	;  The voice allocation depends upon the # of
	;  voices the driver supports.  Thus, we need to
	;  set it up, now that we know how many voices there
	;  are.
	call	SoundVoiceInitialize			; set up voice nodes
	jc	chokeChokeChoke
ifdef GPC_VERSION
	;	mov	ax, (10h shl 8) or 10h			; set volume to medium
	call	ReadInitFileForSettingMasterVolume
endif
done:
	clc
	.leave
	ret
chokeChokeChoke:
	;
	;  Ok.  We have had an error loading the sound driver.
	;  What we want to do is make sure no one tries to get
	;	ahold of the non-existant driver.
	;  To do this, we just P the mutEx semaphore for the
	;	driver and return.
	PSem    ds, exclusiveSemaphore, TRASH_AX_BX
	mov	ds:[exclusiveAccess], 1
	stc
	jmp	short done

SoundAttachLibrary	endp

ifdef GPC_VERSION

;
;  Read from the ini file for the volume and balance setting, then
;  set the sound mixer master volume.
;  Pass:   none
;  Return: none
;
soundCat	char "sound",0
volume		char "volume", 0
balance		char "balance", 0
ReadInitFileForSettingMasterVolume	proc	near
	uses	ds,ax,bx,cx,dx,si,di,bp
	.enter

	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset volume
	call	InitFileReadInteger ; ax
	jnc	ok
	; No key found.
	; So set default volume: MIXER_LVL_MAX / 2
	mov	ax, MIXER_LVL_MAX / 2
ok:
	push	ax
	mov	dx, offset balance
	call	InitFileReadInteger ; ax
	jnc	ok2
	; No balance found.
	; set default balance: SOUND_BALANCE_MAX / 2
	mov	ax, SOUND_BALANCE_MAX / 2
ok2:
	; ax - balance
	pop	dx              ; dx - volume
	mov	cx, dx		; cx - volume

	; Fixing channel volume strategy:
	;  Multiply the "other" channel volume by the balance value that
	;  the user selected in the balance UI gadget, divide by MAX/2.
	;  The selected value is between 0 and MAX/2.
	;  Don't bother rounding off.
	cmp	ax, SOUND_BALANCE_MAX / 2
	ja	fixLeftChannel

fixRightChannel::
	mul	dl			; ax = vol * bal
	mov	cl, SOUND_BALANCE_MAX / 2
	div	cl			; al = vol * (bal / (MAX/2))
	mov	ah, al
	mov	al, dl
	jmp	done
fixLeftChannel:
	sub	al, SOUND_BALANCE_MAX
	neg	al			; al = bal
	mul	dl			; ax = vol * bal
	mov	cl, SOUND_BALANCE_MAX / 2
	div	cl			; al = vol * (bal / (MAX/2))
	mov	ah, dl

done:
	; al - left channel volume,
	; ah - right channel volume.
	call	SoundMixerSetMasterVolume

	.leave
	ret
ReadInitFileForSettingMasterVolume	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundGetDrivers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examine the .ini file and get the current sound drivers

CALLED BY:	SoundAttachLibrary
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	
		sets driverStrategys in dgroup

PSEUDO CODE/STRATEGY:
		look in .ini file
		create category if not there
		if there, read current driver
		load driver
		save routine
		return		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
soundDriverCategory	char	"sound",0
soundSynthDriverKey	char	"synthDriver",0
if DBCS_PCGEOS
soundDriverDir		wchar	"sound",0
endif
LocalDefNLString soundDefaultDriver <"standard.geo",0>

SoundGetDrivers	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es, bp
driverNameBuffer	local	FileLongName
	.enter
	push	bp				; save bp for later
	call	FILEPUSHDIR			; save current dir

	;
	;  Move dir to ../SYSTEM/SOUND
	segmov	ds, cs, si			; ds:dx <- path name
	mov	bx, SP_SYSTEM			; start in system dir
SBCS <	mov	dx, offset soundDriverCategory	; move to SYSTEM/SOUND >
DBCS <	mov	dx, offset soundDriverDir	; move to SYSTEM/SOUND >
	call	FileSetCurrentPath
NOFXIP <LONG jc	done				; error moving to directory

	;
	;  Attempt to load the Driver for Synthesized sound
	;

	;
	;  Set es:di to point to base of driverNameBuffer
	mov	di, ss				; es:di <- driverNameBuffer
	mov	es, di
	mov	di, bp				; di <- base of frame
	add	di, offset driverNameBuffer	; di <- offset to buffer

	;
	;  Read Category/Key value for driver

	push	bp

	mov	si, offset soundDriverCategory	; ds:si <- category asciiz
	mov	cx, cs				; cx:dx <- key asciiz
	mov	dx, offset soundSynthDriverKey
	mov	bp, InitFileReadFlags <IFCC_INTACT,,,size driverNameBuffer>
	call	InitFileReadString		; read driver name

	pop	bp
	LONG jc	loadStandardSynthDriver

	;
	;  Load in the given sound driver and
	;  determine its strategy routine.
	;  Save a fptr to the routine in dgroup
	segmov	ds, es, si			; ds:si <- driver name
	mov	si, di				; ds:si <- name of driver
	clr	ax				; who cares what ver.
	clr	bx
	call	GeodeUseDriver			; get it

	jc	loadStandardSynthDriver		; pass carry back
						; if error loading
readStrategyRoutine:
	call	GeodeInfoDriver			; ds:si <- DriverInfoStruct

	mov	ax, segment dgroup		; es <- dgroup of library
	mov	es, ax
						; copy the far pointer
	movdw	es:[soundSynthStrategy],ds:[si].DIS_strategy, ax	
	mov	es:[soundSynthHandle], bx
	clc					; everything ok
done:
	;  flags preserved across popdir
	call	FILEPOPDIR			; return to old dir

	pop	bp				; restore bp
	.leave
	ret

loadStandardSynthDriver:
	;
	;  Either there was not category, or the category was corrupted,
	;  or the file specified in the catagory did not exists.
	;  In any event, we want to load the standard.geo driver
	;  for PC-SPEAKER.  Hopefully that's here.
	segmov	ds, cs, si			; ds:si <- driver name
	mov	si, offset soundDefaultDriver
	mov	ax, SOUND_PROTO_MAJOR		; get latest version
	mov	bx, SOUND_PROTO_MINOR
	call	GeodeUseDriver
	jc	done				; was there an error?
	jmp	readStrategyRoutine

SoundGetDrivers	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDetachLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up the voices we previously allocated

CALLED BY:	SoundEntry
PASS:		ds	-> dgroup of library
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		frees up fixed memory

PSEUDO CODE/STRATEGY:
		let voice manager clean itself up.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundDetachLibrary	proc	near
	.enter
	;
	;  Remove voice list
call	SoundVoiceDetach		; free up voice nodes

if 0
;  Because the sound library doesn't get unloaded until GEOS gets
; unloaded, and GEOS unloads with a very heavy hand, it is possible
; that the kernel has already unloaded the sound drivers "for us",
; and if we try to do so as well, we die with HANDLE_FREE.
;  This is somewhat related to the UI death below.
;			-- todd 05/20/93

	;
	;  Free up synth driver
	mov	bx, ds:[soundSynthHandle]
	tst	bx
	jz	UI
	call	GeodeFreeDriver

freeUI:
	;
	;  Free up UI
	mov	bx, ds:[userInterfaceHandle]
	tst	bx
	jz	done
	call	GeodeFreeLibrary
endif

done::
	.leave
	ret
SoundDetachLibrary	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundNewClient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a new client is created.  Deal with it.

CALLED BY:	SoundEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundNewClient	proc	near
	.enter
	clc
	.leave
	ret
SoundNewClient	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundNewClientThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a new thread is created. Deal with it.

CALLED BY:	SoundEntry
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		calls GeodeUseLib on UI

PSEUDO CODE/STRATEGY:
		We need to be able to send a message to the UI,
		so we need to get at its process thread.  The
		trick is, we can't actually put a library clause
		in our .gp file becuase the UI has a library sound
		clause in its .gp file and that causes a circular
		recursion problem that kills the system.

		So, what we do is wait until the UI has been loaded,
		and we have been notified alla SoundNewClient, and
		such.

		Then, when it tires to create the first UI thread,
		it calls this routine and we "load" the UI and
		gets its handle.

		Armed with this and a call to ProcInfo, we can
		get the the UI's thread ID and send it messages.

		Believe me, it wasn't easy.	-- todd

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString userName <"uiec.geo",0>			>
NEC <LocalDefNLString userName <"ui.geo",0>			>
SoundNewClientThread	proc	near
	.enter
	tst	ds:[userInterfaceHandle]
	jnz	done

	push	ax, bx, si

	push	ds

	segmov	ds, cs, ax
	mov	si, offset userName

	clr	ax
	clr	bx

	call	GeodeUseLibrary
	jc	error

	pop	ds
	mov	ds:[userInterfaceHandle], bx

doneError:
	pop	ax, bx, si
done:	
	.leave
	ret
error:
	;
	;  We had an error loading the UI.  This is bad.
	;  mark the thread as unsupported.
	stc
EC<	ERROR	-1						>
NEC <	pop	ds						>
NEC<	jmp	doneError					>
SoundNewClientThread	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundThreadExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a thread is done.	Deal with it.

CALLED BY:	SoundEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundThreadExit	proc	near
	.enter
	clc
	.leave
	ret
SoundThreadExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A Client Process has exited.  Deal with it.

CALLED BY:	SoundEntry

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundExit	proc	near
	.enter
	clc
	.leave
	ret
SoundExit	endp
InitCode	ends

CommonCode	segment	resource

;-----------------------------------------------------------------------------
;
;		SIMPLE FM ROUTINES
;
;-----------------------------------------------------------------------------
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundAllocMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a SoundControl block to play FM sounds

CALLED BY:	GLOBAL

PASS:		bx:si	-> far ptr to buffer
		cx	-> # of voices used by buffer
				(Use SoundPlayMusic to play)

				- or -

		^lbx:si	-> handle:chunk for buffer if in lmem heap
		cx	-> # of voices used by buffer
				(Use SoundPlayMusicLMem to play)

RETURN:		carry clear
		bx	<- handle to SoundControl (owned by calling thread)
		ax destroyed

				- or -

		carry set
		ax	<- SOUND_ERROR reason for refusal
		bx destroyed

DESTROYED:	see above

SIDE EFFECTS:
		possible errors and causes include:

		SOUND_ERROR_OUT_OF_MEMORY
			The library tried to do a memory allocation,
			but failed.

PSEUDO CODE/STRATEGY:
		call driver routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundAllocMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_ALLOC_MUSIC
	call	SoundLibDriverStrategy

	.leave
	ret
SoundAllocMusic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundAllocMusicStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a stream to play FM sounds on

CALLED BY:	GLOBAL
PASS:		ax	-> SoundStreamSize
		bx	-> starting priority for sound
		cx	-> # of voices for sound
		dx	-> starting tempo for sound

RETURN:		carry clear
		bx	<- handle to SoundControl (owned by calling thread)
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	see above

SIDE EFFECTS:	
		allocates space on global heap
		allocates stream

PSEUDO CODE/STRATEGY:
		call driver		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundAllocMusicStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_ALLOC_MUSIC_STREAM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundAllocMusicStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundAllocMusicNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a note and return its handle

CALLED BY:	GLOBAL
PASS:		bx	-> instrument table seg. (zero for system default)
		si	-> instrument # for note
		ax	-> frequency
		cx	-> volume
		dx	-> SoundStreamDeltaTimeType
		di	-> duration (in DeltaTimerType units)

RETURN:		carry clear
		bx	<- token for sound (owned by calling thread)
		ax destroyed

			- or -

		ax 	<- SOUND_ERROR reason for failure
		bx destroyed		

DESTROYED:	nothing

SIDE EFFECTS:	
		could allocate space on the global heap

PSEUDO CODE/STRATEGY:
		call driver routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundAllocMusicNote	proc	far
	uses	di, bp
	.enter
	mov	bp, di					; bp <- timer interval

	mov	di, DR_SOUND_ALLOC_MUSIC_NOTE
	call	SoundCallLibraryDriverRoutine

	.leave
	ret

SoundAllocMusicNote	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a simple FM sound

CALLED BY:	GLOBAL

PASS:		bx	-> handle for SoundControl
		ax	-> starting priority for sound
		cx	-> starting tempo setting for sound
		dl	-> EndOfSongFlags for sound		

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:	
		If the simple sound is currently playing, it will
		be re-started at the beginning of the song with the
		new tempo and priority.

PSEUDO CODE/STRATEGY:
		check the mutEx semaphore
		call the driver routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_PLAY_MUSIC
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundPlayMusic	endp

if _FXIP
CommonCode	ends
ResidentCode	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayToMusicStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play an FM Sound to a Stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl
		dx:si	-> start of event buffer to write to sound stream
		cx	-> bytes in buffer (zero if unknown)

		NOTE:  Every buffer written to the stream must
			be made of whole events.  It is not possible
			to break events between two writes to the
			stream, but it is ok to have a buffer end
			with an event and begin with a deltaEvent.

		       Similarly, you can end with a deltaEvent and
			start with a soundEvent.

		       Also, if the size of the buffer is unknown,
			all the events up to the first GE_END_OF_SONG
			event will be written to the stream.  Any
			remaining data will be ignored.

		       A stream of unknown size must have a GE_END_OF_SONG.
		       A stream of known size need not end in GE_END_OF_SONG.

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		check exclusive lock
		call driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayToMusicStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_PLAY_TO_MUSIC_STREAM
	call	SoundLibDriverStrategy

	.leave
	ret
SoundPlayToMusicStream	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayToMusicStreamNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play an FM Sound to a Stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl
		dx:si	-> start of event buffer to write to sound stream
		cx	-> bytes in buffer (zero if unknown)

		NOTE:  Every buffer written to the stream must
			be made of whole events.  It is not possible
			to break events between two writes to the
			stream, but it is ok to have a buffer end
			with an event and begin with a deltaEvent.

		       Similarly, you can end with a deltaEvent and
			start with a soundEvent.

		       Also, if the size of the buffer is unknown,
			all the events up to the first GE_END_OF_SONG
			event will be written to the stream.  Any
			remaining data will be ignored.

		       A stream of unknown size must have a GE_END_OF_SONG.
		       A stream of known size need not end in GE_END_OF_SONG.

RETURN:		cx <- # of bytes written

		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SoundWriteStreamStatus

DESTROYED:	ax

SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		check exclusive lock
		call driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayToMusicStreamNB	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_PLAY_TO_MUSIC_STREAM_NB
	call	SoundLibDriverStrategy

	.leave
	ret
SoundPlayToMusicStreamNB	endp

if _FXIP
ResidentCode	ends
CommonCode	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStopMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop a simple stream

CALLED BY:	GLOBAL

PASS:		bx	-> handle of SoundControl

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	see above

SIDE EFFECTS:	
		Stops the simple piece.  All voices are turned off.
		Triggers EndOfSongFlags

PSEUDO CODE/STRATEGY:
		check mutEx semaphore
		call driver routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStopMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_STOP_MUSIC
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundStopMusic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStopMusicStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop an FM stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	see above

SIDE EFFECTS:	
		Stops the stream.
		All sounds are flushed from stream

PSEUDO CODE/STRATEGY:
		check exclusive access
		call driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStopMusicStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_STOP_MUSIC_STREAM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret

SoundStopMusicStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundReallocMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the song setting for a simple stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl
		ds:si	-> new sound buffer

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:
		Re-starts a simple stream playing on a new sound buffer,
		but leaves the voices in the state they were at the end
		of the last song.  Thus, this allows someone to play a
		very long song by breaking it up into smaller buffers.

		NOTE:  Each buffer section must still end with and
		END_OF_SONG

PSEUDO CODE/STRATEGY:
		check mutEx
		call driver function

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundReallocMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_REALLOC_MUSIC
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundReallocMusic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundReallocMusicLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the song setting for a simple stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl
		^ldx:si	-> new sound buffer

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:
		Re-starts a simple stream playing on a new sound buffer,
		but leaves the voices in the state they were at the end
		of the last song.  Thus, this allows someone to play a
		very long song by breaking it up into smaller buffers.

		NOTE:  Each buffer section must still end with and
		END_OF_SONG

PSEUDO CODE/STRATEGY:
		check mutEx
		call driver function

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundReallocMusicLMem	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_REALLOC_MUSIC_LMEM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundReallocMusicLMem	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundReallocMusicNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the settings for a note

CALLED BY:	GLOBAL

PASS:		bx	-> handle for SoundControl
		ax	-> frequnecy for note
		cx	-> volume for note
		dx	-> timer type
		di	-> timer value
		ds:si	-> new instrument setting

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	see above

SIDE EFFECTS:	
		locks and unlocks block on global heap

PSEUDO CODE/STRATEGY:
		* You must stop the note before reallocating *

		check mutEx semaphore

		lock down block
		make changes
		unlock block		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundReallocMusicNote	proc	far
	uses	bp, di
	.enter
	mov	bp, di					; bp <- timer value

	mov	di, DR_SOUND_REALLOC_MUSIC_NOTE
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundReallocMusicNote	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundFreeMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up a simple FM sound stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		frees up a block on the global heap

PSEUDO CODE/STRATEGY:
		call driver routine		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundFreeMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_FREE_SIMPLE
	call	SoundLibDriverStrategy

	.leave
	ret
SoundFreeMusic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundFreeMusicStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an FM sound stream

CALLED BY:	GLOBAL

PASS:		bx	-> handle for SoundControl

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		flushes the stream, frees up the stream
		frees up the block on the global heap

PSEUDO CODE/STRATEGY:
		call driver		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundFreeMusicStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_FREE_STREAM
	call	SoundLibDriverStrategy

	.leave
	ret
SoundFreeMusicStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundInitMusic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a pre-defined simple FM sound structure

CALLED BY:	GLOBAL

PASS:		bx	-> handle to block with empty SoundControl

		cx	-> # of voices for sound

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		initialize the sound structure
		initialize the voices
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundInitMusic	proc	far
	uses	ax, cx, dx, si, di
	.enter
	;
	;  Calculate offset to song in block
	mov	ax, size SoundVoiceStatus		; al <- size of 1 voice
	mul	cx					; ax <- size of voices
	add	ax, size SoundControl			; ax <- offset to song
	mov	si, ax					; si <- offset to song

	;
	;  SoundLibDriverInitSimple expects the block to
	;  be locked when it recieves it.
	call	MemLock			; ax <- segment, bx <- handle
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	clr	dx					; mark as in block

	mov	di, DR_SOUND_INIT_MUSIC
	call	SoundLibDriverStrategy			; init the sound

	call	MemUnlock		; free up the block

done::
	.leave
	ret
SoundInitMusic	endp

;-----------------------------------------------------------------------------
;
;	SOUND MAINTENANCE AND ADMINISTRATION ROUTINES
;
;-----------------------------------------------------------------------------
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundChangeOwnerSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the owner of a sound

CALLED BY:	GLOBAL

PASS:		bx	-> handle of SoundControl
		ax	-> handle of new owner for sound

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		alters ownership of the block itself as well
		as any semaphores.

PSEUDO CODE/STRATEGY:
		call the driver routine		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundChangeOwnerMusic	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_CHANGE_OWNER_SIMPLE
	call	SoundLibDriverStrategy

	.leave
	ret
SoundChangeOwnerMusic	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundChangeOwnerStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the Owner of a sound Stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle of SoundControl
		ax	-> handle of new owner for sound

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		alters ownership of the block itself as well
		as any semaphores.

PSEUDO CODE/STRATEGY:
		call the driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundChangeOwnerStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_CHANGE_OWNER_STREAM
	call	SoundLibDriverStrategy

	.leave
	ret
SoundChangeOwnerStream	endp
;-----------------------------------------------------------------------------
;
;		DAC Sound Routines
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundAllocSampleStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a sound handle for the sound

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry clear
		bx	<- handle of SoundControl
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	see above

SIDE EFFECTS:
		check mutEx
		allocates a handle for Sound
		allocates semaphores

PSEUDO CODE/STRATEGY:
		call driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundAllocSampleStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_ALLOC_SAMPLE_STREAM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundAllocSampleStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundEnableSampleStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Associate a real DAC to Sound

CALLED BY:	GLOBAL
PASS:		bx	-> handle of SoundControl
		ax	-> priority for DAC (SoundPriority)

		cx	-> rate for sample
		dx	-> ManufacturerID of sample
		si	-> SampleFormat of sample

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:	
		allocates stream
		contacts device driver and a attach DAC to stream

PSEUDO CODE/STRATEGY:
		check exclusive access to driver
		call driver		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundEnableSampleStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_ENABLE_SAMPLE_STREAM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundEnableSampleStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDisableSampleStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes association of DAC and Sound

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl

RETURN:		nothing

DESTROYED:	nothing
SIDE EFFECTS:	
		contacts device driver and dettaches DAC from stream
		frees stream

PSEUDO CODE/STRATEGY:
		call driver		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundDisableSampleStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_DISABLE_SAMPLE_STREAM
	call	SoundLibDriverStrategy

	.leave
	ret
SoundDisableSampleStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundFreeSampleStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up the Sound structure of the sound

CALLED BY:	GLOBAL
PASS:		bx	-> handle of SoundControl

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		frees up a block
		frees up semaphore handles

PSEUDO CODE/STRATEGY:
		We can't check for exclusives as an application
			may be trying to exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundFreeSampleStream	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_FREE_SAMPLE_STREAM
	call	SoundLibDriverStrategy

	.leave
	ret
SoundFreeSampleStream	endp

if _FXIP

CommonCode	ends
ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayToSampleStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Play a given piece of DAC data to the DAC

CALLED BY:	GLOBAL

PASS:		bx	= handle of SoundControl
		dx:si	= buffer of DAX data to put on stream
		cx	= length of buffer (in bytes)
		ax:bp	= SampleFormatDescription of buffer

RETURN:		carry clear
		ax destroyed
		
			- or -

		carry set
		ax	= SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:	
		gives the DAC something to play
		blocks on writing to stream
PSEUDO CODE/STRATEGY:
		call driver		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/92    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayToSampleStream	proc	far
		uses	bx, dx, di, si, ds
		.enter

		mov	di, bx			; di = SoundControl

		mov	ds, dx			; ds:si = event buffer
		call	SysCopyToBlock		; ^hbx = block
						; ds:si = copied event buffer
		jc	outOfMemory

		mov	dx, ds			; dx:si = copied event buffer
		push	bx			; save block handle

		mov	bx, di			; ^hbx = SoundControl
		call	SoundPlayToSampleStreamReal

		pop	bx
		call	MemFree
exit:
		.leave
		ret
outOfMemory:
		mov	ax, SOUND_ERROR_OUT_OF_MEMORY
		jmp	short exit

SoundPlayToSampleStream	endp

ResidentCode	ends
CommonCode	segment resource

else

SoundPlayToSampleStream	proc	far
	FALL_THRU	SoundPlayToSampleStreamReal
SoundPlayToSampleStream	endp
endif

SoundPlayToSampleStreamReal	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_PLAY_TO_SAMPLE_STREAM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundPlayToSampleStreamReal	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundCallLibraryDriverRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call library driver routine

CALLED BY:	Everything.  Almost.
;PASS:		di	-> driver routine to call
		others	-> see specific routine

RETURN:		carry clear
		ax destroyed
		bx,cx,dx,si,di,bp,es,ds as routine

			- or -
		carry set
		di destroyed
		ax	<- SOUND_ERROR reason for failure


DESTROYED:	see above

SIDE EFFECTS:
		calls driver

PSEUDO CODE/STRATEGY:
		try to enter library
		  if fails return error

		try to call routine
		  if fails propgate error

		exit library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundCallLibraryDriverRoutine	proc	near
	.enter
	push	di					; save routine

	mov	di, DR_SOUND_ENTER_LIBRARY_ROUTINE
	call	SoundLibDriverStrategy
	jc	error					; set error?

	pop	di					; restore routine

	call	SoundLibDriverStrategy
	jc	routineFailure

	push	di					; save result

	mov	di, DR_SOUND_EXIT_LIBRARY_ROUTINE
	call	SoundLibDriverStrategy

	clc
error:
	pop	di					; clean up stack

	mov	ax, SOUND_ERROR_EXCLUSIVE_ACCESS_GRANTED

done:
	.leave
	ret

routineFailure:
	;
	;  We failed somewhere in the SoundLibDriver routine.
	;  Propogate error after exiting the library routine
	mov	di, DR_SOUND_EXIT_LIBRARY_ROUTINE	; exit library
	call	SoundLibDriverStrategy

	stc						; propogate error
	jmp	short done

SoundCallLibraryDriverRoutine	endp

;-----------------------------------------------------------------------------
;
;	EXCLUSIVE DRIVER ACCESS ROUTINES
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundGetExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get exclusive access to the lower level routines

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax:si	<- fptr to Synth sound driver strategy routine
		bx:di	<- fptr to DAC sound driver strategy routine
		cx:dx	<- fptr to sound library's Driver strategy routine

DESTROYED:	nothing

SIDE EFFECTS:	
		Causes thread to block until get exclusive

PSEUDO CODE/STRATEGY:
		Do a P on the semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundGetExclusive	proc	far
	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	PSem	ds, exclusiveSemaphore, TRASH_AX_BX

	;
	;  We are now the only thread in this section
	;	of code.  We need only wait for all the
	;	threads to clear out, then we have
	;	exclusive access
	inc	ds:[exclusiveAccess]

	PSem	ds, librarySemaphore, TRASH_AX_BX

	;
	;  Load up pointers to the strategy routines.
	mov	ax, ds:[soundSynthStrategy].segment
	mov	si, ds:[soundSynthStrategy].offset

	mov	bx, ax
	mov	di, si

	mov	cx, segment SoundLibDriverStrategy
	mov	dx, offset SoundLibDriverStrategy
	.leave
	ret
SoundGetExclusive	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundGetExclusiveNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get exclusive access to lower level routines

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry clear if exclusive access granted:

		ax:si	<- fptr to Synth sound driver strategy routine
		bx:di	<- fptr to DAC sound driver strategy routine
		cx:dx	<- fptr to sound library's Driver strategy routine

		carry set someone already has exclusive access.

DESTROYED:	nothing

SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		TimedP on the semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundGetExclusiveNB		proc	far
	uses	cx,ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	clr	cx
	PTimedSem ds,exclusiveSemaphore,cx,TRASH_AX_BX_CX
	jc	done

	inc	ds:[exclusiveAccess]

	clr	cx
	PTimedSem ds,librarySemaphore,cx,TRASH_AX_BX_CX
	jc	error

	;
	;  Load up pointers to the strategy routines.
	mov	ax, ds:[soundSynthStrategy].segment
	mov	si, ds:[soundSynthStrategy].offset

	mov	bx, ax
	mov	di, si

	mov	cx, segment SoundLibDriverStrategy
	mov	dx, offset SoundLibDriverStrategy
done:
	.leave
	ret
error:
	;
	;  We got the 1st semaphore, but not the 2nd.
	;  V the first handle.
	dec	ds:[exclusiveAccess]
	VSem	ds, exclusiveSemaphore, TRASH_AX_BX
	jmp	short done
SoundGetExclusiveNB		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundReleaseExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give up exclusive access to lower level routines

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		frees up the semaphore
PSEUDO CODE/STRATEGY:
		V the semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundReleaseExclusive	proc	far
	uses	ax,bx,ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	VSem	ds,librarySemaphore,TRASH_AX_BX

	dec	ds:[exclusiveAccess]

	VSem	ds,exclusiveSemaphore,TRASH_AX_BX
	.leave
	ret
SoundReleaseExclusive	endp


;-----------------------------------------------------------------------------
;
;	Driver Manipulation/Query routines
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundSynthDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information on Synth Driver

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	<- # of Voices
		bx	<- SupportedInstrumentFormat
		cx	<- SoundDriverCapability
		
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		load up existing data and return		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundSynthDriverInfo	proc	far
	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	mov	ax, ds:[driverVoices]
	mov	bx, ds:[driverVoiceFormat]
	mov	cx, ds:[driverCapability]
	.leave
	ret
SoundSynthDriverInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundSampleDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information on Sample Driver

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	<- # of DACs
		bx	<- SoundDriverDACCapability

DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundSampleDriverInfo	proc	far
	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	mov	ax, ds:[driverDACs]
	mov	bx, ds:[driverDACCapability]
	.leave
	ret
SoundSampleDriverInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundPlayMusicLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a simple FM sound in an LMem chunk

CALLED BY:	GLOBAL

PASS:		bx	-> handle for SoundControl
		ax	-> starting priority for sound
		cx	-> starting tempo setting for sound
		dl	-> EndOfSongFlags for sound		

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	nothing

SIDE EFFECTS:	
		If the simple sound is currently playing, it will
		be re-started at the beginning of the song with the
		new tempo and priority.

PSEUDO CODE/STRATEGY:
		call the driver routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	3/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundPlayMusicLMem	proc	far
	uses	di
	.enter

	mov	di, DR_SOUND_PLAY_MUSIC_LMEM
	call	SoundCallLibraryDriverRoutine

	.leave
	ret
SoundPlayMusicLMem	endp

CommonCode	ends



