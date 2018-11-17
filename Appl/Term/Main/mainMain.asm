COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		mainMain.asm

AUTHOR:		Dennis Chow, September 6, 1989

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
				Intercepted to ensure that no state file is
				created.

 ?? INT SetUpCodePage		Set up the code page variables

 ?? INT SetCodePageListEntry	Set up the code page variables

 ?? INT SetUpInputOutputMaps	initialize input/output maps

 ?? INT CreateInputOutputMap	Create inputMap or outputMap

 ?? INT ParseMapFile		parse a map file

 ?? INT PMFSkipWhiteSpace	skip white space

 ?? INT PMFConvertDecNumber	convert decimal number

 ?? INT ProtocolReset		

 ?? INT TerminalReset		

 ?? INT ModemDBReset		

 ?? INT SetNoGenItem		

 ?? INT SetGenItem		

 ?? INT SetGenBoolean		

 ?? INT TermSetPort		Tell term program to set ANSI termtype

 ?? INT ProcessTermcap		Return an FSM to use to handle current
				terminal type

    MTD MSG_FILE_RECV_STOP_CHECK_DISKSPACE
				Save the recv file contents and check disk
				space

 ?? INT SerialErrorRoutine	Handle error in data stream

 ?? INT TermAdjustFormat1	Adjust the serial format

 ?? INT TermAdjustFormat2	Adjust the serial format

 ?? INT TermAdjustFormat3	Adjust the serial format

 ?? INT SetOneBits		Adjust the serial format

 ?? INT TermSetDuplex		Set full duplex

 ?? INT TermSpeakerOn		choose pulse or tone dialing

 ?? INT TermSpeakerOff		choose pulse or tone dialing

 ?? INT TermSpeakerDialing	choose pulse or tone dialing

 ?? INT TermSpeakerCarrier	choose pulse or tone dialing

 ?? INT TermVolLow		Set modem speaker volume

 ?? INT TermVolMed		Set modem speaker volume

 ?? INT TermVolHi		Set modem speaker volume

 ?? INT SetTrigger		Set OpenMacTrigger to be ENABLE or DISABLE

 ?? INT SetScreenInput		Send input to screen object

 ?? INT SetFileSendInput	Send input to screen object

 ?? INT SetFileRecvInput	Send input to screen object

 ?? INT ;SetScriptInput		Send input to screen object

 ?? INT SetNullInput		Send input to null and void

 ?? INT CallHardwareHandshake	Turn on/off software flow control

 ?? INT DeselectFlowListEntry	Turn on/off software flow control

 ?? INT SetStopRemoteListEntry	ensure correct settings for
				stop-remote-signal field of
				hardware-handshaking entry

    MTD MSG_TERM_HANG_UP_DONE	Clean up after really hanging up

 ?? INT HangUpCommon		Clean up after really hanging up

 ?? INT DismissHangingUpBox	Clean up after really hanging up

 ?? INT BitBucket		dummy routine that ignores buffer of
				characters sent to it

    MTD MSG_TERM_DISPLAY_SPECIAL_KEYS_LIST
				Display an entry in the Special Key list

    MTD MSG_TERM_FILE_SEND_FILE_OPEN_CONTROL_OPEN_FILE
				Sending the text file

    MTD MSG_TERM_AUTO_SAVE	Save the recv file contents.

    MTD MSG_TERM_APPLICATION_CANCEL_CONNECTION
				User cancels connection when system is
				establishing connection

    MTD MSG_TERM_APPLICATION_CONNECTION_TIMEOUT
				Handle telnet connection timeout

    MTD MSG_META_NOTIFY		Handle various kinds of notifications

 ?? INT RespHandleFoamAutoSave	Handles Responder auto save notification

    MTD MSG_META_KBD_CHAR	Keyboard input handler for application
				object

    MTD MSG_META_GAINED_FULL_SCREEN_EXCL
				Record the fact that we have the exclusive

    MTD MSG_META_LOST_FULL_SCREEN_EXCL
				Handle losing the full-screen exclusive

 ?? INT TermDisplayProtocolWarningBoxIfNeeded
				Display a warning if they select 7 N 1 as a
				protocl

    INT TermAllowSerialToBlock	Sends a message to the serial thread giving
				it permission to block.

    INT TermSerialStopBlocking	Sends a message to the serial thread
				telling it to stop blocking.  Process
				thread must wait for receipt of
				MSG_TERM_SERIAL_NOT_BLOCKING before it can
				start blocking on the serial thread again.

    MTD MSG_TERM_SERIAL_NOT_BLOCKING
				Informs process that it is safe to call
				serial thread again.

 ?? INT EnableTransparentDetach	Clear AS_AVOID_TRANSPARENT_DETACH

 ?? INT DisableTransparentDetach
				Set AS_AVOID_TRANSPARENT_DETACH

    MTD MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
				Brings the applicatino to the top _after_
				the terminal window becomes visible.

 ?? INT SwitchToLoginUI		Change the UI to be appropriate for login
				mode

 ?? INT SwitchFromLoginUI	Change the UI back to normal after login
				mode is done.

    INT SetUsability		Set an object usable/not usable, delayed
				via app queue

 ?? INT DisplayLoginGreeting	Put the manual login greeting text on the
				terminal screen

 ?? INT HandleLoginNotifications
				Handles login server notifications

    MTD MSG_TERM_LOGIN_INIT	invokes terminal emulator on a port already
				opened by an external communications
				protocol, like PPP.

    MTD MSG_TERM_ATTACH_TO_PORT	invokes terminal emulator on a port already
				opened by an external communications
				protocol, like PPP.

    MTD MSG_TERM_DETACH_FROM_PORT
				Ends session started with ATTACH_TO_PORT.
				Does any cleanup necessry for the current
				login phase.

 ?? INT LoginDetachNone		Ends session started with ATTACH_TO_PORT.
				Does any cleanup necessry for the current
				login phase.

 ?? INT LoginDetachWaiting	Ends session started with ATTACH_TO_PORT.
				Does any cleanup necessry for the current
				login phase.

 ?? INT LoginDetachActive	Ends session started with ATTACH_TO_PORT.
				Does any cleanup necessry for the current
				login phase.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 6/89        Initial revision.

DESCRIPTION:


	$Id: mainMain.asm,v 1.1 97/04/04 16:55:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermOpenAppl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the term process

CALLED BY:	kernel
PASS:		ds	- dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		create term process
		init and open com ports 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		screen object instantiated in termui.ui file	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
bbsCodePageCategory	char	'geoComm',0
bbsCodePageKey		char	'hostCodePage',0
if INPUT_OUTPUT_MAPPING
inputMapKey		char	'inputMap',0
outputMapKey		char	'outputMap',0
endif	; INPUT_OUTPUT_MAPPING

if USE_FEP
LocalDefNLString fepDir	<"FEP",0>
fepCategory	char	"fep",0
fepDriverKey	char	"driver",0
endif	; USE_FEP

TermOpenAppl	method	TermClass, 	MSG_GEN_PROCESS_OPEN_APPLICATION

	call	SetUpCodePage			; do code page stuff,
						;	destroys nothing

	;all our superclass (the UI) to get stuff started
	mov     di, offset TermClass
	;	call    MSG_GEN_PROCESS_OPEN_APPLICATION, super TermClass
	call	ObjCallSuperNoLock
if USE_FEP
	push	ds
	segmov	ds, cs, cx
	mov	si, offset fepCategory
	mov	dx, offset fepDriverKey
	clr	bp				; get heap block
	call	InitFileReadString		; carry set if none
	mov	ax, 0				; in case no FEP
	jc	noFEP
	push	bx
	call	FilePushDir
	mov	bx, SP_SYSTEM
	segmov	ds, cs
	mov	dx, offset fepDir
	call	FileSetCurrentPath
	jc	noFEPPop
	pop	bx
	push	bx
	call	MemLock
	mov	ds, ax
	clr	si, ax, bx
	call	GeodeUseDriver
	call	FilePopDir
	mov	ax, 0				; in case no FEP
	jc	noFEPPop
	mov	dx, bx				; dx = fep driver handle
	call	GeodeInfoDriver			; ds:si = driver info
	mov	ax, ds:[si].DIS_strategy.segment
	mov	si, ds:[si].DIS_strategy.offset
noFEPPop:
	pop	bx
	call	MemFree
noFEP:
	pop	ds				; ds = dgroup
	mov	ds:[fepStrategy].segment, ax
	mov	ds:[fepStrategy].offset, si
	mov	ds:[fepDriverHandle], dx
endif

if not PZ_PCGEOS
	
	;
	; Read default font size from .INI file
	;
	mov	ax, MSG_META_LOAD_OPTIONS
	GetResourceHandleNS	FontList, bx
	mov	si, offset FontList
	clr	di
	call	ObjMessage
	
endif

	call	DismissHangingUpBox		; in case of hanging-up problem
						;	last time around

	call	InitHandleVars

if INPUT_OUTPUT_MAPPING
	call	SetUpInputOutputMaps		; setup input/output maps
endif

	mov	ds:[canPaste], TRUE	; allow pasting
if	not _TELNET
	call	EnableScripts		; scripts always available
endif

if	_TELNET
	jmp	noSerialErr
else
	;
	; load serial driver, will return error if no serial card available
	;
	clr	ds:[serialHandle]		; in case of error
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	push	ds, si
	segmov	ds, cs				; ds:si = driver file. name
	mov	si, offset serialDriverName
	mov	ax, SERIAL_PROTO_MAJOR
	mov	bx, SERIAL_PROTO_MINOR
	call	GeodeUseDriver
	pop	ds, si
	call	FilePopDir
	jnc	noSerialErr			; serial driver loaded OK
	mov	bp, ERR_USE_SERIAL_DR
endif	; !_TELNET
	
reportErrorAndExit:
	call	DisplayErrorMessage
	jmp	short error
		
noSerialErr:
	mov	ds:[serialHandle], bx		; save driver handle

	call	InitTerm
	jnc	noThreadError			; thread created OK
	mov	bp, ERR_NO_MEM_ABORT		; report memory error
	jmp	short reportErrorAndExit

noThreadError:	
	mov	ax, MSG_META_INITIALIZE
	mov	bx, ds:[termuiHandle]
	CallScreenObj				;if can't initialize screen
	jc	error				;  object, then exit appl

;if not _DOVE
if 	_TELNET or (not _TELNET and not _LOGIN_SERVER)
	call	RestoreState			;check if need to restore term
						;	state
else
	call	RestoreTermType			; set up emulation
endif	; _TELNET or (not _TELNET and not _RESPONDER)
;endif	; !_DOVE

if	not _TELNET
; Be sure to uncomment the dialog box code when setting for dove!
	;
	; after restoring state, state settings for "reset" functionality
	;
	GetResourceHandleNS	ProtocolBox, bx
	mov	si, offset ProtocolBox
	mov	ax, MSG_PROTOCOL_INTERACTION_STORE_SETTINGS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
endif	; !_TELNET
		

	jmp	short exit


error:
	mov	ds:[termStatus], DORKED
	mov	ax, MSG_TERM_DORKED		;send DETACH to application
	mov	bx, ds:[termProcHandle]		;get geode process handle
	mov	di, mask MF_FORCE_QUEUE		;send a detach to ourselves
	call	ObjMessage
exit:
	ret
TermOpenAppl	endm

if	_VSER

EC <		serialDriverName	TCHAR	"vserec.geo", 0		>
NEC <		serialDriverName	TCHAR	"vser.geo", 0		>

else
		
if DBCS_PCGEOS
EC <serialDriverName	wchar	"serialec.geo", 0			>
NEC <serialDriverName	wchar	"serial.geo", 0				>
else
EC <serialDriverName	byte	"serialec.geo", 0			>
NEC <serialDriverName	char	"serial.geo", 0				>
endif

endif	; if _VSER
		
TermAttach	method	TermClass, MSG_META_ATTACH
	clr	ds:[restoreFromState]		; set to false
	mov	di, offset TermClass
	call	ObjCallSuperNoLock
	ret
TermAttach	endm

TermRestoreFromState	method	TermClass, MSG_GEN_PROCESS_RESTORE_FROM_STATE
NRSP <	mov	ds:[restoreFromState], -1	; set to true 	>
	mov	di, offset TermClass
	call	ObjCallSuperNoLock
	ret
TermRestoreFromState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the code page variables

CALLED BY:	TermOpenAppl
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	dosCP and bbsCP are initialized.

	if DBCS, bbsSendCP and bbsRecvCP are also initialized.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpCodePage	proc	near
	
	uses	ax, bx, cx, dx, bp, di, si
	.enter
DBCS <	clr	dx							>
	call	LocalGetCodePage	; bx = current DOS code page
	mov	ds:[dosCP], bx
	cmp	ds:[restoreFromState], TRUE
	jne	useIniCodePage		; if not, use geos.ini code page
	;
	; get BBS code page from state file
	;
	GetResourceHandleNS	CodePageList, bx
	mov	si, offset CodePageList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax = code page
	mov	ds:[bbsCP], ax		; store it
	jmp	short done

useIniCodePage:
	;
	; grab BBS code page from geos.ini file
	;
	push	ds			; save dgroup
	segmov	ds, cs, cx
	mov	si, offset bbsCodePageCategory
	mov	dx, offset bbsCodePageKey
	call	InitFileReadInteger	; ax = .ini file value
	pop	ds			; restore dgroup
	jc	useDefault		; use DOS code page as default
	mov	bx, ax			; else, use .ini entry
					; (a garbage entry will passed to
					;  localization driver which then
					;  uses default CP)
useDefault:
	mov	ds:[bbsCP], bx
	;
	; set code page list entry
	;
	mov	cx, bx			; cx = code page
	call	SetCodePageListEntry
done:
if DBCS_PCGEOS
	mov	ax, ds:[bbsCP]
	mov	ds:[bbsSendCP], ax
	mov	ds:[bbsRecvCP], ax
endif

	.leave
	ret
SetUpCodePage	endp

SetCodePageListEntry	proc	near
	GetResourceHandleNS	CodePageList, bx
	mov	si, offset CodePageList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;ignore error, leave list w/o excl
	ret
SetCodePageListEntry	endp

if INPUT_OUTPUT_MAPPING
;----------------------------------------------------------------------------
;
; Routines for input and output mapping
;
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpInputOutputMaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize input/output maps

CALLED BY:	TermOpenAppl (after calling superclass)

PASS:		ds - dgroup

RETURN:		input/output initialized

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpInputOutputMaps	proc	near
	uses	ax, bx, cx, dx, bp, si, di
	.enter
	;
	; Now, set up the input and output mapping buffers
	;	ds - dgroup
	;
	call	FilePushDir
	push	ds
	mov	cx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset termcapDir
	call	GotoTermDir			;go to Term's system directory
	pop	ds
	mov	di, offset inputMap		; table for input map
	mov	dx, offset inputMapKey		; 'inputMap'
	call	CreateInputOutputMap
	mov	di, offset outputMap		; table for output map
	mov	dx, offset outputMapKey		; 'outputMap'
	call	CreateInputOutputMap
	call	FilePopDir
	.leave
	ret
SetUpInputOutputMaps	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateInputOutputMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create inputMap or outputMap

CALLED BY:	SetUpCodePage

PASS:		di - offset of map (in dgroup)
		dx - offset of geos.ini file key for map file (in code seg)
		ds - dgroup
		current directory is SYSTEM\TERMCAP

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		initialize default map;
		if (geos.ini has map) {
			parse map
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateInputOutputMap	proc	near
	uses	es
	.enter

	segmov	es, ds				; es:di = map
	mov	cx, 256
	mov	al, 0
initLoop:					; initialize default mapping
	stosb
	inc	al
	loop	initLoop
	sub	di, 256				; restore map offset

	push	ds
	segmov	ds, cs, cx			; cx:dx='inputMap','outputMap'
	mov	si, offset bbsCodePageCategory	; ds:si = 'geoComm'
	mov	bp, INITFILE_INTACT_CHARS	; gives us buffer
	call	InitFileReadString		; bx = buf han, cx = # chars
	pop	ds
	jc	done				; no map, done
	call	MemLock
	mov	bp, ax				; bp:dx = filename
	clr	dx
	push	di				; save map offset
	call	LoadFile			; ax = seg, bx = han, cx = size
	pop	di				; restore map offset
	jc	mapFileError			; error loading map file
	call	ParseMapFile
	pushf					; save results
	call	MemFree				; free map file buffer
	popf					; retreive results
	jnc	done				; if no error, done
						; else, report error
mapFileError:
	mov	bp, ERR_INPUT_OUTPUT_MAP_ERROR
	call	DisplayErrorMessage		; report error and continue
						;	with default or
						;	paritial map
done:
	.leave
	ret
CreateInputOutputMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseMapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	parse a map file

CALLED BY:	CreateInputOutputMap

PASS:		ax - segment of map file
		bx - handle of map file
		cx - size of map file
		es:di - map (dgroup)
		es - dgroup

RETURN:		carry clear if everything ok
		carry set if error parsing
		map updated

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:
		fill in map table entries from map file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseMapFile	proc	near
	uses	ds, bx
	.enter
	mov	ds, ax				; ds:si = map file
	clr	si
parseLoop:
	call	PMFSkipWhiteSpace
	jcxz	done				; EOF okay
	call	PMFConvertDecNumber		; ax = value
	jc	error				; missing 1st num.
	jcxz	error				; EOF not okay after 1st num.
	clr	bx
	mov	bl, al				; bx = 1st num. (ignore high)
	call	PMFSkipWhiteSpace
	jcxz	error				; EOF not okay after 1st num.
	cmp	{byte} ds:[si], '='		; must be this
	jne	error
	inc	si
	dec	cx
	jcxz	error
	call	PMFSkipWhiteSpace
	jcxz	error				; EOF not okay after '='
	call	PMFConvertDecNumber		; al = 2nd num. (ignore high)
	jc	error				; missing 2nd num.
	jcxz	done				; EOF okay after 2nd num.
	mov	es:[di][bx], al			; store map value
	jmp	short parseLoop

error:
	stc
	jmp	short exit

done:
	clc
exit:
	.leave
	ret
ParseMapFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PMFSkipWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	skip white space

CALLED BY:	ParseMapFile

PASS:		ds:si - remaining map file
		cx - remaining size of map file

RETURN:		ds:si - remaining map file (non-white-space)
		cx - remaining size of map file (updated)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		skip space, tab, CR, LF

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PMFSkipWhiteSpace	proc	near
	cmp	{byte} ds:[si], CHAR_SPACE
	je	skip
	cmp	{byte} ds:[si], CHAR_TAB
	je	skip
	cmp	{byte} ds:[si], CHAR_CR
	je	skip
	cmp	{byte} ds:[si], CHAR_LF
	jne	done
skip:
	inc	si
	dec	cx
	jcxz	done				; end of file
	jmp	short PMFSkipWhiteSpace
done:
	ret
PMFSkipWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PMFConvertDecNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert decimal number

CALLED BY:	ParseMapFile

PASS:		ds:si = potential number
		cx = remaining size of map file

RETURN:		carry set if not a number
		carry clear if okay
			ax = value of number
		ds:si = remaining map file (after valid digits)
		cx = remaining size of map file (updated)

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		take all consecutive digits

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PMFConvertDecNumber	proc	far	
	uses	bx, dx, bp
	.enter
	;
	; must have a number
	;
	mov	dl, ds:[si]			; cl = digit to convert  
	cmp	dl, '0'
	jb	exit				; not a number (carry set)
	cmp	dl, '9'+1			; C set if dl < '9'+1
	cmc					; C set if dl >= '9'+1
	jc	exit				; not a number (carry set)
	;
	; get number value
	;
	clr	ax				; clear out the number
	clr	dx
	mov	bx, DECIMAL_BASE
digitLoop:
	mov	dl, ds:[si]			; cl = digit to convert  
	cmp	dl, '0'
	jb	done				; end of number
	cmp	dl, '9'
	ja	done				; end of number
	push	dx				; save digit
	mul	bx
	pop	dx				; restore digit (ignore word
						;	overflow)
	sub	dl, '0'
	add	ax, dx				; ax = number
	inc	si				; move to next digit
	dec	cx
	jcxz	done				; end of file
	jmp	short digitLoop

done:
	clc
exit:
	.leave
	ret
PMFConvertDecNumber	endp

;----------------------------------------------------------------------------
;
; End of routines for input and output mapping
;
;----------------------------------------------------------------------------
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermCloseAppl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the term program

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds 	- dgroup
		ax 	- MSG_GEN_PROCESS_CLOSE_APPLICATION

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermCloseAppl	method	TermClass,	MSG_GEN_PROCESS_CLOSE_APPLICATION


	push	cx, dx, bp
	cmp	ds:[termStatus], DORKED		;if exiting cauz no memory
	je	20$				;don't bother closing anything	
if	_TELNET
	call	TelnetCloseConnection		; carry set if connection
						; already closed 
else
	mov	ax, MSG_NUKE_FSM		;destroy the FSMs
	SendSerialThread			;then nuke the
	CallMod	EndComUse			;  input thread

	cmp	ds:[serialPort], NO_PORT	;if serial port open
	je	10$
;	CallMod	SerialDropCarrier		;drop carrier detect 
	CallMod	CloseComPort			;then close port
	call	SetNullInput			;  ignore any remaining input
endif	; _TELNET
		
	mov	ds:[termuiHandle], 0		; stop sending stuff to
						;	screenObject
10$:
	mov	ds:[termStatus], OFF_LINE
20$:
	mov	cx, ds:[termProcHandle]		;geoComm doesn't care about
	clr	dx				;  items added to clipboard	
	call	ClipboardRemoveFromNotificationList	;  anymore
						; (okay if not found - DORKED)
if	not _TELNET
	;
	; done with serial driver
	;
	mov	bx, ds:[serialHandle]
	tst	bx
	jz	noSerial
	call	GeodeFreeLibrary
noSerial:
	mov	ds:[serialDriver].high, 0	; indicate that serial driver
						;	is gone
endif	; !_TELNET
	
if USE_FEP
	;
	; done with FEP driver
	;
	mov	ax, 0
	xchg	ds:[fepStrategy].segment, ax
	tst	ax
	jz	noFep
	mov	bx, ds:[fepDriverHandle]
	call	GeodeFreeLibrary
noFep:
endif	; USE_FEP

	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	mov	di, offset TermClass
	pop	cx, dx, bp 			;restore registers we got
	;	call	MSG_GEN_PROCESS_CLOSE_APPLICATION, super TermClass
	call	ObjCallSuperNoLock
	ret
TermCloseAppl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_DETACH

PASS:		ds 	- dgroup
		ax 	- MSG_META_DETACH

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermDetach	method	TermClass,	MSG_META_DETACH
	uses	ax, cx, dx, bp
	.enter

if	not _TELNET
NRSP <	call	ProtocolReset						>
endif
	
NRSP <	call	TerminalReset						>
	
if	not _TELNET
NRSP <	call	ModemDBReset						>
endif

NRSP <	CallMod FileReset						>

if	not _TELNET
	CallMod ScriptReset
endif
	mov	ds:[termLazarusing], -1		; if we startup and this
						;   is true we never quite
						;   exited.

	.leave
	mov	di, offset TermClass
	;	call	MSG_META_DETACH,	super TermClass
	call	ObjCallSuperNoLock
	ret
TermDetach	endm

if	not _TELNET
	; need to restore Protocol, Terminal, and Modem dialog boxes
	; to the previously "Applied" settings before exiting to DOS
	; so that when restarted, one will see these settings with
	; both "Apply" and "Reset" triggers disabled. - ted 1/20/93

ProtocolReset	proc	near
	GetResourceHandleNS	ComList, bx
	mov	si, offset ComList
	mov	cx, ds:[serialPort]
	cmp	cx, NO_PORT
	je	skip
	inc	cx
	call	SetGenItem
	jmp	common
skip:
	call	SetNoGenItem
common:
	mov	cx, ds:[serialBaud]
	GetResourceHandleNS	BaudList, bx
	mov	si, offset BaudList
	call	SetGenItem

	mov	cx, ds:[dataBits]
	GetResourceHandleNS	DataList, bx
	mov	si, offset DataList
	push	cx
	call	SetGenItem
	pop	cx
	cmp	cx, (SL_5BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
	je	fiveBits

	; disable 1.5 bits

	mov	ax, MSG_GEN_SET_NOT_ENABLED	
	GetResourceHandleNS	OneHalfBits, bx
	mov	si, offset OneHalfBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; enable 2 bits

	mov	ax, MSG_GEN_SET_ENABLED	
	GetResourceHandleNS	TwoBits, bx
	mov	si, offset TwoBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done
fiveBits:
	; disable 2 bits
	
	mov	ax, MSG_GEN_SET_NOT_ENABLED	
	GetResourceHandleNS	TwoBits, bx
	mov	si, offset TwoBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; enable 1.5 bits

	mov	ax, MSG_GEN_SET_ENABLED	
	GetResourceHandleNS	OneHalfBits, bx
	mov	si, offset OneHalfBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	mov	cx, ds:[parity]
	GetResourceHandleNS	ParityList, bx
	mov	si, offset ParityList
	call	SetGenItem

	mov	cx, ds:[stopBits]
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList
	call	SetGenItem

	mov	cx, ds:[handshake]
	push	cx
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList
	call	SetGenBoolean
	pop	cx
	test	cx, mask SFC_HARDWARE
	jne	notDisable
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	CallHardwareHandshake
notDisable:
	mov	cx, ds:[stopRemote]
	GetResourceHandleNS	StopRemoteList, bx
	mov	si, offset StopRemoteList
	call	SetGenBoolean

	mov	cx, ds:[stopLocal]
	GetResourceHandleNS	StopLocalList, bx
	mov	si, offset StopLocalList
	call	SetGenBoolean
	ret
ProtocolReset	endp
endif	; !_TELNET

TerminalReset	proc	near
	clr	ch
	mov	cl, ds:[termType]
	GetResourceHandleNS	TermList, bx
	mov	si, offset TermList
	call	SetGenItem
	mov	cl, ds:[halfDuplex]
	mov	ch, cl
	GetResourceHandleNS	EchoList, bx
	mov	si, offset EchoList
	call	SetGenItem
	mov	cx, ds:[termOptions]
	GetResourceHandleNS	VideoList, bx
	mov	si, offset VideoList
	call	SetGenBoolean
	ret
TerminalReset	endp

if	not _TELNET
ModemDBReset	proc	near
	mov	cl, ds:[toneDial]
	mov	ch, cl
	GetResourceHandleNS	ModemDial, bx
	mov	si, offset ModemDial
	call	SetGenItem
	mov	cx, ds:[modemSpeaker]
	GetResourceHandleNS	ModemSpeaker, bx
	mov	si, offset ModemSpeaker
	call	SetGenItem
	mov	cx, ds:[modemVolume]
	GetResourceHandleNS	ModemVolume, bx
	mov	si, offset ModemVolume
	call	SetGenItem
	ret
ModemDBReset	endp
endif	; !_TELNET

SetNoGenItem	proc	near
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; ax = selection
	ret
SetNoGenItem	endp

SetGenItem	proc	near
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; ax = selection
	ret
SetGenItem	endp

SetGenBoolean	proc	near
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
SetGenBoolean	endp

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the port baud rate.

CALLED BY:	MSG_TERM_SET_BAUD

PASS:		ds - dgroup
		cx - baud rate to use	

RETURN:		nothing

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSetBaud	method	TermClass, 	MSG_TERM_SET_BAUD
	cmp	ds:[serialBaud], cx
	je	exit
	mov	ds:[serialBaud], cx
	CallMod	SetSerialFormat
exit:
	ret
TermSetBaud	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set com port for term program

CALLED BY:	MSG_TERM_SET_PORT

PASS:		ds	- dgroup
		cx	- port to use

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SERIAL_COM1 ne 0
        ErrMessage <Somebody changed the value for serial ports>
endif

TermSetComPort	method	TermClass, 	MSG_TERM_SET_PORT
	tst	cx
	js	exit			;if cx = -1, then no port selected
	dec	cx			;else adjust the my com port values
	call	TermSetPort		;to match system serial SERIAL_COM
exit:					;settings
	ret
TermSetComPort	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell term program to set ANSI termtype

CALLED BY:	TermSetComPort, DoComm

PASS:		ds	- dgroup
		cx	- com port to use (SERIAL_COM[1-4])	

RETURN:		cx	- 0 if no port opened

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		If no com port open	
			create input thread
			open port
		If com port already open don't open again
		If another com port open 
			close it before opening new com port

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/08/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSetPort	proc	far
	cmp	ds:[serialPort], NO_PORT	;are any ports already open?
	je	openCom				;no, go open this port
	cmp	ds:[serialPort], cx		;is port already open 
	je	portOpened			;yes, exit
	push	cx				;save port to open
	CallMod	CloseComPort			;no,  close other port
	pop	cx
openCom:
	call	OpenPort
	jcxz	exit				; exit if no port opened

	;
	; if software flow control is enabled then send an XON
	; when we open the port.  Just in case an XOFF was sent
	; by another port some time.
	;
	push	cx				; save port-opened flag
	test    ds:[serialFlowCtrl], mask SFC_SOFTWARE
	jz      90$
	mov     bx, ds:[serialPort]             ;set  port #
	mov     cl,  CHAR_XON			;send an xoff
	mov     ax, STREAM_BLOCK
	CallSer DR_STREAM_WRITE_BYTE
90$:
	pop	cx				; retrieve port-opened flag
	jmp	short exit

portOpened:
	inc	cx				;flag that port opened
exit:
	ret
TermSetPort	endp
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set code page for host

CALLED BY:	MSG_TERM_SET_CODE_PAGE

PASS:		ds	- dgroup
		cx	- code page for host

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	 1/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSetCodePage	method	TermClass, 	MSG_TERM_SET_CODE_PAGE
	mov	ds:[bbsCP], cx		; store new BBS code page
if DBCS_PCGEOS
	mov	ds:[bbsSendCP], cx
	mov	ds:[bbsRecvCP], cx
endif
	mov	bp, cx			; bp = new code page
	segmov	ds, cs, cx
	mov	si, offset bbsCodePageCategory
	mov	dx, offset bbsCodePageKey
	call	InitFileWriteInteger
	ret
TermSetCodePage	endm

TermBringUpCodePageBox	method	TermClass,
					MSG_TERM_BRING_UP_CODE_PAGE_BOX
	mov	cx, ds:[bbsCP]
	call	SetCodePageListEntry
	GetResourceHandleNS	CodePageBox, bx
	mov	si, offset CodePageBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
TermBringUpCodePageBox	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetTerminal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set terminal type to emulate

CALLED BY:	MSG_TERM_SET_TERMINAL

PASS:		ds	- dgroup
		cl	- terminal type to use	

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/08/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSetTerminal	method	TermClass, 	MSG_TERM_SET_TERMINAL
	;
	; To avoid synchronization problem, we force process thread to
	; process termcap file itself because when we check modem status, we
	; have to wait on a serial thread's condition. By the time we
	; need to wait on that condition at connection, the serial thread may
	; still process termcap file through process thread. Since the
	; process thread is also responsible for making connection, that will
	; create a deadlock situation.		-Simon 7/2/95
	;
if	not _MODEM_STATUS and (not _TELNET)
	mov	bx, ds:[threadHandle]
	tst	bx
	jnz	forwardThatPuppy
endif	; if !_MODEM_STATUS && !_TELNET
	
	call	ProcessTermcap
exit::
	ret

if	not _MODEM_STATUS	
forwardThatPuppy:
	mov	ax, MSG_READ_SET_TERMINAL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit
endif
TermSetTerminal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessTermcap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an FSM to use to handle current terminal type

CALLED BY:	TermSetTerminal, SerialSetTerminal

PASS:		ds	- dgroup
		es	- dgroup
		cl	- terminal type to set

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Bogus hack here to set screen object flags based on the terminal
	type.  This information should be stored with the FSM header.
	See doc/termStatus for description of hack.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/03/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessTermcap	proc	far
	mov	ch, ds:[termType] 		;save old terminal type
	mov	ds:[prevTermType], ch		;
	mov	ds:[termType], cl		;set terminal type
	
	call	SearchTermTable			;if terminal FSM 
	jnc	makeIt				;  already created 
	cmp	ds:[termType], VT52		;  then check if FLAGS
	je	xnTrue
	cmp	ds:[termType], VT100		;  have to be set	
	je	xnTrue				;  (this is a hack) 
	cmp	ds:[termType], TVI950		;
	je	xnTrue
	mov	dh, FALSE
	jmp	short sendXN
xnTrue:
	mov	dh, TRUE
sendXN:
	mov	ax, MSG_SCR_SET_XN
	mov	bx, ds:[termuiHandle]
	CallScreenObj
	jmp	PT_ret				;  exit

makeIt:
	CallMod	FSMCreate			;else create an FSM
	jnc	10$
	jmp	error
10$:
	mov	ds:[fsmBlockSeg], ax		;	
	mov	ds:[fsmBlockHandle], bx		;

	mov	cx, SP_PUBLIC_DATA
	push	ds
	segmov	ds, cs
	mov	dx, offset termcapDir
	CallMod GotoTermDir			;go to Term's system directory
	pop	ds

	mov	bl, ds:[termType]
	clr	bh
	shl	bl, 1				; bx = offset to term type
	push	ds
	mov	bp, cs				;get termcap file table segment
	mov	ds, bp
	add	bx, offset termcapTable
	mov	dx, ds:[bx]			;bp:dx-> termcap file
	CallMod	LoadFile			;ax - buffer segment
						;cx - file size
	pop	ds
RSP <	WARNING_C TERM_CANNOT_LOAD_TERMCAP_FILE				>
	jc	PT_error			; error loading termcap	
	tst	ax							
	jnz	PT_ok				;is the segment okay?	
	
PT_error:
	push	ds	
	mov	bp, ERR_TERMCAP_NOT_FOUND	;nope, use default buffer
	CallMod	DisplayErrorMessage		;
	pop	ds
	mov	ds:[termSeg], cs		; default termcap in CS
	mov	ds:[termHandle], DEF_HANDLE	;flag no handle allocated
	mov	ds:[termType], VT100		;set default term type
	mov	cx, defTermEnd-defTermBuf	;get default term table size	
	segmov	ds, cs				; ds:si = def. termcap table
	mov	si, offset defTermBuf
	jmp	PT_call
PT_ok:
	mov	ds:[termHandle], bx		;handle of buffer segment
	mov	ds:[termSeg], ax		;save term buffer segment
	mov	ds, ax
	clr	si				;ds:si -> termcap buffer
PT_call:
	CallMod	FSMParseDesc
	segmov	ds, es, dx			;make ds point to dgroup
	call	SearchTermTable			;is the "default" terminal
	jc	PT_ret				;already here?
	call	UpdateTermTable			;nope, add new FSM to table
	mov	bx, es:[termHandle]
	cmp	bx, DEF_HANDLE			;if didn't alloc buffer for
	je	PT_ret				;termcap, exit
	call	MemFree				;else free buffer
	jmp	short PT_ret
error:
	mov	bp, ERR_NO_MEM_FSM		;not enough memory to create
	CallMod	DisplayErrorMessage		;  terminal FSM
	mov	cl, ds:[prevTermType]		;restore term types
;	CallMod	SetTermList
;done below
	jmp	short exit
PT_ret:
;;do this once when starting up - brianc 9/26/90
;;	call	InitFileSelectPath
exit:
	;
	; write out current type type to geos.ini file
	;
	mov	al, ds:[termType]
	clr	ah
	push	ax
	mov	bp, ax
	push	ds
	segmov	ds, cs
	mov	si, offset commCategory
	mov	cx, cs
	mov	dx, offset termTypeKey
	call	InitFileWriteInteger		; ax = terminal type (if C clr)
	pop	ds
	pop	cx
	call	SetTermList			; also, update term list
	ret
ProcessTermcap	endp	

SBCS <termcapDir	byte	"TERMCAP", 0		;dir for termcaps>
DBCS <termcapDir	wchar	"TERMCAP", 0		;dir for termcaps>



if DBCS_PCGEOS
ttyTC		wchar	"tty.tc",0		;tty  		termcap file	
vt52TC		wchar	"vt52.tc",0		;vt52  		termcap file	
vt100TC		wchar	"vt100.tc",0		;vt100  	termcap file	
wyse50TC	wchar	"wyse50.tc",0		;wyse50 	termcap file
ansiTC		wchar	"ansi.tc",0		;ansi 		termcap file
ibm3101TC	wchar	"ibm3101.tc",0		;ibm 3101	termcap file
tvi950TC	wchar	"tvi950.tc",0		;teleVideo 950 	termcap file
else
ttyTC		db	"tty.tc",0		;tty  		termcap file	
vt52TC		db	"vt52.tc",0		;vt52  		termcap file	
vt100TC		db	"vt100.tc",0		;vt100  	termcap file	
wyse50TC	db	"wyse50.tc",0		;wyse50 	termcap file
ansiTC		db	"ansi.tc",0		;ansi 		termcap file
ibm3101TC	db	"ibm3101.tc",0		;ibm 3101	termcap file
tvi950TC	db	"tvi950.tc",0		;teleVideo 950 	termcap file
endif

;
; This list must match up with TermEntries (Utils/utilsMain.asm),
;	TermTable (Script/scriptLocal.asm), Terminals (termConstant.def)
;
termcapTable	label	word
	dw	offset ttyTC
	dw	offset vt52TC
	dw	offset vt100TC
	dw	offset wyse50TC
	dw	offset ansiTC
	dw	offset ibm3101TC
	dw	offset tvi950TC

defTermBuf	label	byte
	db	":xn", 0dh, 0ah
	db	"^G		0", 0dh,0ah
	db	"^H		1", 0dh,0ah
	db	"^I		2", 0dh,0ah
	db	"^J		3", 0dh,0ah
	db	"^M		4", 0dh,0ah
	db	"\\EM		5", 0dh,0ah
	db	"\\EOA		6", 0dh,0ah
	db	"\\EOB		7", 0dh,0ah
	db	"\\EOC		8", 0dh,0ah
	db	"\\EOD		9", 0dh,0ah
	db	"\\EOP		10",0dh,0ah
	db	"\\EOQ		11",0dh,0ah
	db	"\\EOR		12",0dh,0ah
	db	"\\EOS		13",0dh,0ah
	db	"\\E[;H\\E[2J	14",0dh,0ah
	db	"\\E[?1h\\E=	15",0dh,0ah
	db	"\\E[?1l\\E>	16",0dh,0ah
	db	"\\E[A		17",0dh,0ah
	db	"\\E[C		18",0dh,0ah
	db	"\\E[H		19",0dh,0ah
	db	"\\E[J		20",0dh,0ah
	db	"\\E[K		21",0dh,0ah
	db	"\\E[m		22",0dh,0ah
	db	"\\E7		23",0dh,0ah
	db	"\\E8		24",0dh,0ah
	db	"\\E[%i%d;%i%dr	25",0dh,0ah
	db	"\\E[%i%d;%i%dH	26",0dh,0ah
	db	"\\E[L		31",0dh,0ah
	db	"\\E[M		33",0dh,0ah
	db	"\\E[P		34",0dh,0ah
	db	"\\E[4h		37",0dh,0ah
	db	"\\E[4l		38",0dh,0ah
	db	"\\ED		39",0dh,0ah
	db	"\\E[%dm	42",0dh,0ah
	db	"\\E[%i%dH	43",0dh,0ah
	db	"\\E[;%i%dH	44",0dh,0ah
	db	"\\Evb		49",0dh,0ah
	db	"\\E[%dB	50",0dh,0ah
	db	"\\E[%dD	51",0dh,0ah
	db	"\\E[%dC	52",0dh,0ah
	db	"\\E[%dA	53",0dh,0ah
	db	"\\E[1;7m	30",0dh,0ah
defTermEnd	label	byte


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermFileSendStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop sending a file 

CALLED BY:	MSG_FILE_SEND_STOP

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermFileSendStop method	TermClass, 		MSG_FILE_SEND_STOP
	mov	ds:[fileTransferCancelled], TRUE	; set flag
	;
	; If we are doing an XMODEM transfer, all we need to do is set
	; the flag.  We don't want do to any abort stuff because this
	; routine is run by term:0 while all the file transfer stuff is
	; being run by term:1.  Many possibilities for synchronization
	; problems if we do.  The abort stuff will be handled in term:1
	; when data comes in or when the next timeout occurs.
	;
	cmp	ds:[sendProtocol], XMODEM	; xmodem transfer?
	je	done				; yes
	CallMod	FileSendAbort
done:
	ret
TermFileSendStop	endm

TermFileRecvStop method	TermClass, 		MSG_FILE_RECV_STOP
	;
	; tell the user we're stopping
	;
	;
	; really stop
	;
		CallMod	FileRecvAbort
	;
	; Allow the notification to close.
	;
		ret
TermFileRecvStop	endm

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAsciiSendSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle selecting a file to send
	
CALLED BY:	

PASS:		ds	- dgroup
		bp	- GenFileSelectorEntryFlags 
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
	check if selection is due to a opening a file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	-------		-----------
	dennis	03/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermAsciiSendSelect method	TermClass,	MSG_ASCII_SEND_SELECT
	mov	ds:[sendProtocol], NONE	
	cmp	ds:[termStatus], ON_LINE	;
	jne	exit				;
	mov	si, offset TextSendFileSelector
	mov	bx, ds:[transferUIHandle]
	call	CheckFileSelect		; preserves
					;	bp = GenFileSelectorEntryFlags
	jc	exit	
	CallMod	SendFile		; pass bp = GenFileSelectorEntryFlags
exit:
	ret
TermAsciiSendSelect	endm

TermXmodemSendSelect method	TermClass,	MSG_XMODEM_SEND_SELECT
	mov	ds:[sendProtocol], XMODEM	
	cmp	ds:[termStatus], ON_LINE	;
	jne	exit				;
	mov	si, offset SendFileSelector
	mov	bx, ds:[transferUIHandle]
	call	CheckFileSelect		; preserves
					;	bp = GenFileSelectorEntryFlags
	jc	exit	
	CallMod	SendFile		; pass bp = GenFileSelectorEntryFlags
exit:
	ret
TermXmodemSendSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle timeout event

CALLED BY:	MSG_TIMEOUT

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Instead of checking termStatus could have a timeoutRoutine 
	similar to inputRoutine used in serial thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermTimeout method	TermClass, 	MSG_TIMEOUT
	mov	dx, TIMER_EVENT
	cmp	ds:[termStatus], IN_SCRIPT
	je	inScript

	cmp	ds:[termStatus], FILE_SEND
	je	send

	cmp	ds:[termStatus], FILE_RECV		;if not in file recv
	jne	exit					;then this is bogus

	CallMod	FileRecvData
	jmp	short exit

inScript:
if	not _TELNET
	CallMod	ScriptTimeout
endif
	jmp	short exit	

send:
	CallMod	FileSendData

exit:
	ret
TermTimeout endm


if 	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermUpdateSerialError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update Line Status box

CALLED BY:	MSG_UPDATE_SERIAL_ERRORS

PASS:		nothing

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermUpdateSerialError method	TermClass, 	MSG_UPDATE_SERIAL_ERRORS
	call	DisplayReadErr
	call	DisplayWriteErr
	call	DisplayParityErr
	call	DisplayFrameErr
	ret
TermUpdateSerialError	endm



Fixed segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialErrorRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle error in data stream

CALLED BY:	Serial driver on error

PASS:		cx - SerialError record
			SE_OVERRUN	; char overwritten before being read
			SE_PARITY	; bad parity
			SE_FRAME	; no valid stop bit
			SE_BREAK       	; data input held in spacing state for
					; longer than full-word transmit time
					; usually an alert of some sort
		ax - term:dgroup

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Don't have serial driver call serial segment Error routine
		directly because serial segment not in FIXED memory.

		Put code here rather than in serial segment, because wanted
		to avoid ObjMessage overhead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialErrorRoutine 	proc	far
	uses	ax, bx, cx, dx, di, ds
	.enter
	mov	ds, ax
	test	cx, mask SE_OVERRUN		;check for read errors
	jz	checkWrite
	inc	ds:[numReadErr]
checkWrite:
	test	cx, mask SE_BREAK		;check for write errors
	jz	checkParity
	inc	ds:[numWriteErr]
checkParity:
	test	cx, mask SE_PARITY		;check for parity errors
	jz	checkFrame
	inc	ds:[numParityErr]
checkFrame:
	test	cx, mask SE_FRAME		;check for frame errors
	jz	exit
	inc	ds:[numFrameErr]
exit:
	call	TimerGetCount
	mov	cx, ax
	mov	dx, bx
	sub	ax, ds:[lastUpdatedSerialErrors].low
	sbb	bx, ds:[lastUpdatedSerialErrors].high
	jnz	sendEm
	cmp	ax, UPDATE_SERIAL_ERRORS_THRESHOLD_TICKS
	jb	noSend
sendEm:
	mov	ds:[lastUpdatedSerialErrors].low, cx	; store new time
	mov	ds:[lastUpdatedSerialErrors].high, dx
	mov	ax, MSG_UPDATE_SERIAL_ERRORS
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
			mask MF_CAN_DISCARD_IF_DESPERATE
	call	ObjMessage
noSend:
	.leave
	ret
SerialErrorRoutine	endp

Fixed ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSerialReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset serial error varibles

CALLED BY:	MSG_SERIAL_RESET

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


TermSerialReset method	TermClass, 	MSG_SERIAL_RESET
;	tst	ds:[numFrameErr]			;reset framing errors
;	jz	checkParity
	clr	ds:[numFrameErr]
	call	DisplayFrameErr
;checkParity:						;reset parity errors
;	tst	ds:[numParityErr]
;	jz	checkRead
	clr	ds:[numParityErr]
	call	DisplayParityErr
;checkRead:						;reset read errors
;	tst	ds:[numReadErr]
;	jz	checkWrite
	clr	ds:[numReadErr]
	call	DisplayReadErr
;checkWrite:						;reset write errors
;	tst	ds:[numWriteErr]
;	jz	exit
	clr	ds:[numWriteErr]
	call	DisplayWriteErr
exit:	
	ret
TermSerialReset endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSerialStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up serial status box

CALLED BY:	MSG_SERIAL_STATUS

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 06/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSerialStatus method	TermClass, 	MSG_SERIAL_STATUS
	GetResourceHandleNS	SerialBox, bx
	mov	si, offset SerialBox		;bring up dialog box	
	mov     ax, MSG_GEN_INTERACTION_INITIATE
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
						;return focus to screen obj
	mov	ax, MSG_GEN_MAKE_FOCUS		;
	GetResourceHandleNS	TermView, bx
	mov     si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
TermSerialStatus endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAbortScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May want to add a trigger to allow user to abort the script file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermAbortScript method	TermClass, MSG_TERM_SCRIPT_ABORTED
	CallMod	ScriptAbort
	ret
TermAbortScript endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermScriptNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	execute next line in macro script

CALLED BY:	MSG_TERM_SCRIPT_EXECUTE_NEXT_LINE

PASS:		nothing	

RETURN:		nothing	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermScriptNext method	TermClass, MSG_TERM_SCRIPT_EXECUTE_NEXT_LINE
	;IMPORTANT: if you change this routine, change
	;ScriptFoundMatchContinueScript also.

	CallMod	ScriptNextLine
	ret
TermScriptNext endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAdjustFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the serial format

CALLED BY:	MSG_TERM_ADJUST_FORMAT

PASS:		ds 	- dgroup	
		cx	- bits to adjust

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermAdjustFormat1 method	TermClass, 	MSG_TERM_ADJUST_FORMAT1
	mov	ds:[dataBits], cx
	CallMod	AdjustSerialFormat
	ret
TermAdjustFormat1 endm

TermAdjustFormat2 method	TermClass, 	MSG_TERM_ADJUST_FORMAT2
	mov	ds:[stopBits], cx
	mov	dx, (0 shl offset SF_EXTRA_STOP) or (mask SF_EXTRA_STOP shl 8)
	cmp	cx, SBO_ONE
	je	one
	mov	dx, (1 shl offset SF_EXTRA_STOP) or (mask SF_EXTRA_STOP shl 8)
one:
	mov	cx, dx
	CallMod	AdjustSerialFormat
	ret
TermAdjustFormat2 endm

TermAdjustFormat3 method	TermClass, 	MSG_TERM_ADJUST_FORMAT3
	mov	ds:[parity], cx
	CallMod	AdjustSerialFormat
	ret
TermAdjustFormat3 endm

TermAdjustUserFormat method	TermClass, 	MSG_TERM_ADJUST_USER_FORMAT
	test	cx, (mask SF_LENGTH shl 8)	; changing word length?
	jz	exit				; nope
	push	cx				; save new word len. setting
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = current exclusive
	mov	dx, ax				; dx = current exclusive
	pop	di				; di = new word length
						; 5 bits?
	cmp	di, (SL_5BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
	je	fiveBits			; yes
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; else, not 5 bits
	mov	bx, MSG_GEN_SET_ENABLED	; disable 1.5, enable 2
	cmp	dx, SBO_ONEANDHALF		; currently 1.5?
	jne	bitsCommon			; nope, continue
	call	SetOneBits			; else, reset to 1
	jmp	short bitsCommon
fiveBits:
	mov	ax, MSG_GEN_SET_ENABLED	; 5 bits
	mov	bx, MSG_GEN_SET_NOT_ENABLED	; enable 1.5, disable 2
	cmp	dx, SBO_TWO			; currently 2?
	jne	bitsCommon			; nope, continue
	call	SetOneBits			; else, reset to 1
bitsCommon:
	push	bx				; save TwoBits state
	GetResourceHandleNS	OneHalfBits, bx
	mov	si, offset OneHalfBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax				; ax = TwoBits state
	GetResourceHandleNS	TwoBits, bx
	mov	si, offset TwoBits
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
TermAdjustUserFormat endm

SetOneBits	proc	near
	uses	ax, bx
	.enter
	GetResourceHandleNS	StopList, bx
	mov	si, offset StopList
	mov	cx, SBO_ONE
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SetOneBits	endp
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDuplexFull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set full duplex

CALLED BY:	MSG_TERM_SET_DUPLEX, RestoreDuplex

PASS:		cx	- TRUE/half duplex	
			  FALSE/full duplex
		bp	- ListUpdateFlags

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		If program in half duplex then characters sent out the
		com port are echoed back to the screen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


TermSetDuplex method	TermClass, 	MSG_TERM_SET_DUPLEX
	mov	es:[halfDuplex], cl
	ret
TermSetDuplex endm


TermTerminalReset	method	TermClass, MSG_TERM_TERM_RESET

	; reset the "Select Terminal" setting

	clr	dx			; not indeterminate
	clr	ch
	mov	cl, ds:[termType]	; cx - identifier
	GetResourceHandleNS	TermList, bx
	mov	si, offset TermList	; bx:si - OD of GenItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; reset the "Duplex" setting

	clr	dx			; not indeterminate
	mov	cl, ds:[halfDuplex]	; cx - identifier
	mov	ch, cl
	GetResourceHandleNS	EchoList, bx
	mov	si, offset EchoList	; bx:si - OD of GenItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; reset the "Wrap Lines & Autofeed" setting

	clr	dx		
	mov	cx, ds:[termOptions]	; cx - Boolean items to set
	GetResourceHandleNS	VideoList, bx
	mov	si, offset VideoList	; bx:si - OD of GenBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; disable Apply/Reset
	
	GetResourceHandleNS	TermBox, bx
	mov	si, offset TermBox
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
TermTerminalReset	endm

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	choose pulse or tone dialing

CALLED BY:	MSG_TONE_DIAL

PASS:		cx		- TRUE 	(if tone set)
				  FALSE	(if pulse set)

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		If program in half duplex then characters sent out the
		com port are echoed back to the screen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSetDial method	TermClass, 	MSG_TERM_SET_DIAL
	mov	ds:[toneDial], cl
	ret
TermSetDial endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSpeaker[On, Off, Carrier, Dialing]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	choose pulse or tone dialing

CALLED BY:	MSG_SPEAKER_[ON, OFF, CARRIER, DIALING]

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
speakerOff	db	"ATM",CHAR_CR
speakerOn	db	"ATM2",CHAR_CR
speakerCarr	db	"ATM1",CHAR_CR
speakerDial	db	"ATM3",CHAR_CR

TermModemSpeaker	method	TermClass, MSG_MODEM_SPEAKER
	mov	ds:[modemSpeaker], cx
	cmp	cx, MODEM_SPEAKER_ON
	jne	10$
	call	TermSpeakerOn
	jmp	short exit
10$:
	cmp	cx, MODEM_SPEAKER_OFF
	jne	20$
	call	TermSpeakerOff
	jmp	short exit
20$:
	cmp	cx, MODEM_SPEAKER_DIALING
	jne	30$
	call	TermSpeakerDialing
	jmp	short exit
30$:
	call	TermSpeakerCarrier
exit:
	ret
TermModemSpeaker	endm

TermSpeakerOn 	proc	near
	mov	si, offset speakerOn		;ds:si->buffer to send
	mov	cx, SPK_ON_LEN			;cx   ->#chars to write
	call	SendModemCommand
	ret
TermSpeakerOn 		endp

TermSpeakerOff 	proc	near
	mov	si, offset speakerOff		;ds:si->buffer to send
	mov	cx, SPK_OFF_LEN			;cx   ->#chars to write
	call	SendModemCommand
	ret
TermSpeakerOff 		endp

TermSpeakerDialing 	proc	near
	mov	si, offset speakerDial		;ds:si->buffer to send
	mov	cx, SPK_DIAL_LEN		;cx   ->#chars to write
	call	SendModemCommand
	ret
TermSpeakerDialing 	endp

TermSpeakerCarrier 	proc	near
	mov	si, offset speakerCarr		;ds:si->buffer to send
	mov	cx, SPK_CARR_LEN		;cx   ->#chars to write
	call	SendModemCommand
	ret
TermSpeakerCarrier 	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermVol[Low, Med, Hi]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set modem speaker volume

CALLED BY:	MSG_VOL[LOW, MED, HI]

PASS:		

RETURN:		

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

speakerLow	db	"ATL" ,CHAR_CR
speakerMed	db	"ATL2",CHAR_CR
speakerHi	db	"ATL3",CHAR_CR

TermModemVolume	method	TermClass, MSG_MODEM_VOLUME
	mov	ds:[modemVolume], cx
	cmp	cx, MODEM_VOLUME_LO
	jne	10$
	call	TermVolLow
	jmp	short exit
10$:
	cmp	cx, MODEM_VOLUME_MED
	jne	20$
	call	TermVolMed
	jmp	short exit
20$:
	call	TermVolHi
exit:
	ret
TermModemVolume	endm

TermVolLow 	proc	near
	mov	si, offset speakerLow	;ds:si->buffer to send
	mov	cx, LOW_VOL_LEN		;cx   ->#chars to write
	call	SendModemCommand
	ret
TermVolLow 	endp

TermVolMed 	proc	near
	mov	si, offset speakerMed	;ds:si->buffer to send
	mov	cx, MED_VOL_LEN		;cx   ->#chars to write
	call	SendModemCommand
	ret
TermVolMed	endp

TermVolHi 	proc	near
	mov	si, offset speakerHi	;cs:si->buffer to send
	mov	cx, HI_VOL_LEN		;cx   ->#chars to write
	call	SendModemCommand
	ret
TermVolHi 	endp

TermModemReset	method	TermClass, MSG_TERM_MODEM_RESET

	; reset the "Phone Type" setting

	clr	dx			; not indeterminate
	mov	cl, ds:[toneDial]	; cx - identifier
	mov	ch, cl
	GetResourceHandleNS	ModemDial, bx
	mov	si, offset ModemDial	; bx:si - OD of GenItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; reset the "Modem Speaker" setting

	clr	dx			; not indeterminate
	mov	cx, ds:[modemSpeaker]	; cx - identifier
	GetResourceHandleNS	ModemSpeaker, bx
	mov	si, offset ModemSpeaker	; bx:si - OD of GenItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; reset the "Speaker Volume" setting

	clr	dx			; not indeterminate
	mov	cx, ds:[modemVolume]	; cx - identifier
	GetResourceHandleNS	ModemVolume, bx
	mov	si, offset ModemVolume	; bx:si - OD of GenItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; revert back to the original setting

	; disable Apply/Reset
	
	GetResourceHandleNS	ModemBox, bx
	mov	si, offset ModemBox
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
TermModemReset	endm
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set OpenMacTrigger to be ENABLE or DISABLE	

CALLED BY:	TermMacroSelect
PASS:		ax = Message number
RETURN:		Nothing
DESTROYED:	bx, dl, si, di, 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMacroSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle selecting a macro file
	
CALLED BY:	

PASS:		ds	- dgroup
		bp	- GenFileSelectorEntryFlags 
		
RETURN:		Nothing

DESTROYED:	ax, bx, dx, si

PSEUDO CODE/STRATEGY:
	check if selection is due to a opening a file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	-------		-----------
	dennis	03/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermMacroSelect method	TermClass, MSG_TERM_SCRIPT_FILE_SELECTED

	.enter
	cmp	ds:[termStatus], IN_SCRIPT		;if already in a script
	je	exit					;  don't start another

	GetResourceHandleNS	MacroFiles, bx
	mov	si, offset MacroFiles
	call	CheckFileSelect
	jc	exit

	call	RunScriptFile						
exit:
	.leave
	ret
TermMacroSelect endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMacroOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle running a macro file or opening a directory
	
CALLED BY:	MSG_MACRO_OPEN	

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	-------		-----------
	dennis	03/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermMacroOpen 	method	TermClass, 	MSG_TERM_SCRIPT_RUN
	GetResourceHandleNS	MacroFiles, dx	; dx:si = file selector
	mov	si, offset MacroFiles
	CallMod	GetFileSelection
	jc	exit
	push	cx, dx
	GetResourceHandleNS	MacroFiles, dx	; dx:si = file selector
	mov	si, offset MacroFiles
	CallMod	SetFilePath
	pop	cx, dx
	call	RunScriptFile
exit:
	ret
TermMacroOpen 	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermCloseScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closing text display used to print macro messages
	
CALLED BY:	MSG_CLOSE_SCRIPT	

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	-------		-----------
	dennis	03/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermCloseScript	method	TermClass, 	MSG_TERM_SCRIPT_DISPLAY_CLOSED
	GetResourceHandleNS	ScriptSummons, bx
	mov	si, offset ScriptSummons
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
TermCloseScript	endm
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetScreenInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send input to screen object 
	
CALLED BY:	

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetScreenInput		proc	far
EC <	call	ECCheckDS_dgroup					>

	mov	ax, offset FSMParseString
	mov	bx, ds:[fsmResHandle]

	PSem	ds, inputDirectionSem	;block if Thread 1 is in the middle
					;of dorking with variables

	mov	ds:[termStatus], ON_LINE
	mov	ds:[routineOffset], ax
	mov	ds:[routineHandle], bx
	VSem	ds, inputDirectionSem

	ret
SetScreenInput		endp

SetFileSendInput	proc	far
EC <	call	ECCheckDS_dgroup					>

	mov	ax, offset FileSendData
	mov	bx, ds:[fileResHandle]

	PSem	ds, inputDirectionSem	;block if Thread 1 is in the middle
					;of dorking with variables
	mov	ds:[termStatus], FILE_SEND
	mov	ds:[routineOffset], ax
	mov	ds:[routineHandle], bx
	VSem	ds, inputDirectionSem
	ret
SetFileSendInput	endp

SetFileRecvInput	proc	far
EC <	call	ECCheckDS_dgroup					>
NRSP <	cmp	ds:[recvProtocol], XMODEM				>
NRSP <	mov	ax, offset FileRecvData					>
NRSP <	je	setRecvInput						>

	mov	ax, offset AsciiRecvData		;  to ascii recv routine

setRecvInput:
	mov	bx, ds:[fileResHandle]

	PSem	ds, inputDirectionSem	;block if Thread 1 is in the middle
					;of dorking with variables
	mov	ds:[termStatus], FILE_RECV
	mov	ds:[routineOffset], ax
	mov	ds:[routineHandle], bx
	VSem	ds, inputDirectionSem
exit:
	ret
SetFileRecvInput	endp

;SetScriptInput		proc	far
;EC <	call	ECCheckDS_dgroup					>
;	mov	ds:[termStatus], IN_SCRIPT
;
;	mov	ax, offset ScriptInput
;	GetResourceHandleNS Serial, bx
;
;	inc	ds:[routineSem]
;	mov	ds:[routineOffset], ax
;	mov	ds:[routineHandle], bx
;	dec	ds:[routineSem]
;	ret
;SetScriptInput		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNullInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send input to null and void
	
CALLED BY:	TermCloseAppl

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetNullInput		proc	far
	mov	ax, offset BitBucket
	mov	ds:[routineOffset], ax
	mov	ax, ds:[mainResHandle]
	mov	ds:[routineHandle], ax
	ret
SetNullInput		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSendChat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send contents of chat box
	
CALLED BY:	MSG_SEND_CHAT

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSendChat	method	TermClass, 	MSG_SEND_CHAT
	mov	bx, ds:[interfaceHandle]	;get text from chat box
	mov	si, offset ChatText		;
	mov	di, mask MF_CALL		;
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK	;
	call	ObjMessage			;
	mov	bx, cx				;bx = block
	tst	ax
	jz	exit				;if box empty forget it
	mov	cx, ax				;cx = text length w/o NULL
	call	MemLock				;lock the text block
	clr	si				;
	mov	es, ax				;es:si ->buffer to write from
	call	BufferedSendBuffer
	call	MemFree

	mov	ax, MSG_META_GRAB_FOCUS_EXCL	;give the chat box the focus
	mov     si, offset ChatText		;
	CallInterface

	mov     dx, ds:[interfaceHandle]	;select the text in the chat
	mov     si, offset ChatText		; 	box
	CallMod SelectAllText			;
	ret
exit:
	call	MemFree
	ret
TermSendChat		endm

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSetFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on/off software flow control 
	
CALLED BY:	MSG_TERM_SET_FLOW

PASS:		ds	- dgroup
		cx	- flow control to use SFC_HARDWARE and/or SFC_SOFTWARE
				or none
				(only needed for MSG_TERM_SET_USER_FLOW)
		bp	- modified ones
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSetFlow	method	TermClass, 	MSG_TERM_SET_FLOW
	mov	ds:[handshake], cx
	call	GetFlowSettings		; dx = actual flow settings
	mov	cx, dx			; cx = flow settings
	CallMod	SerialSetFlowControl
	ret
TermSetFlow		endm

TermSetUserFlow	method	TermClass, MSG_TERM_SET_USER_FLOW
	push	cx, bp			; save user, modified flow settings
	call	GetFlowSettings		; dx = actual flow settings
	pop	cx, bp			; restore user, modified flow settings
	test	bp, cx			; is modified bit off (ie. turned off)?
	jz	userTurnedOff		; yes, handle
	test	bp, mask FFB_NONE	; "none" turned on?
	jnz	flowNone		; yes, deselect "H" and "S"
	;
	; "hardware" or "software" turned on, make sure "none" is deselected
	;
	push	cx, dx
	mov	cx, mask FFB_NONE
	call	DeselectFlowListEntry
	pop	cx, dx
	;
	; set correct state of hardware handshake group
	;
	mov	ax, MSG_GEN_SET_ENABLED	; assume "hardware"
	test	cx, mask SFC_HARDWARE		; "hardware"?
	jnz	haveHHState			; yes, enable it
	test	dx, mask SFC_HARDWARE		; was "hardware" on before?
	jnz	haveHHState			; yes, keep it enabled
	jmp	short disableHH			; else, disable it
	;
	; hit "none", make sure "hardware" or "software" are deselected
	; also disable hardware handshake group, since "hardware" is not
	; selected
	;
flowNone:
	mov	cx, mask SFC_HARDWARE
	call	DeselectFlowListEntry
	mov	cx, mask SFC_SOFTWARE
	call	DeselectFlowListEntry
disableHH:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveHHState:
	call	CallHardwareHandshake
	jmp	short exit

	;
	; user turned option off
	;	bp = option turned off
	;
userTurnedOff:
	test	bp, mask FFB_NONE	; "none" turned off?
	jnz	noneTurnedOff		; yes
	test	bp, mask SFC_HARDWARE	; hardware turned off?
	jz	softwareTurnedOff	; no, software turned off
	;
	; "hardware" turned off, disable hardware handshaking group
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	push	dx
	call	CallHardwareHandshake
	pop	dx
	test	dx, mask SFC_SOFTWARE	; was "software" off?
	jmp	short noneTest

	;
	; "software" turned off, if "hardware" was off, select "none"
	;
softwareTurnedOff:
	test	dx, mask SFC_HARDWARE	; was "hardware" off?
noneTest:
	jnz	exit			; nope, done
	jmp	short selectNone	; else, select "none"

	;
	; "none" turned off, if nothing else is selected, reselect "none"
	;
noneTurnedOff:
	test	dx, (mask SFC_SOFTWARE or mask SFC_HARDWARE)
	jnz	exit			; something else selected, done
selectNone:
	mov	cx, mask FFB_NONE	; else, reselect "none"
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	dx, -1			; select
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
TermSetUserFlow		endm

CallHardwareHandshake	proc	near
	GetResourceHandleNS	HardwareHandshakeGroup, bx
	mov	si, offset HardwareHandshakeGroup
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
CallHardwareHandshake	endp

DeselectFlowListEntry	proc	near
	GetResourceHandleNS	FlowList, bx
	mov	si, offset FlowList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	dx, 0			; deselect
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
DeselectFlowListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermStopRemoteSignal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure correct settings for stop-remote-signal
		field of hardware-handshaking entry

CALLED BY:	MSG_TERM_STOP_REMOTE_SIGNAL
		(clicking on "Stop Remote" list)

PASS:		cx = selected stop-remote signal
		bp = modified ones

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermStopRemoteSignal	method	TermClass, MSG_TERM_STOP_REMOTE_SIGNAL
	mov	ds:[stopRemote], cx

	;redo flow control stuff
	;(cx not needed for TermSetFlow)

	call	GetFlowSettings		; dx = actual flow settings
	mov	cx, dx			; cx = flow settings
	CallMod	SerialSetFlowControl
	ret
TermStopRemoteSignal	endm

TermUserStopRemoteSignal	method	TermClass,
					MSG_TERM_USER_STOP_REMOTE_SIGNAL
	test	cx, mask SMC_DTR		; DTR off?
	jz	DTRoff				; yes, make sure RTS on
	test	cx, mask SMC_RTS		; RTS off?
	jnz	exit				; no, done
	;
	; "DTR" and "RTS" off make sure DTR is on
	;
	mov	cx, mask SMC_DTR
	call	SetStopRemoteListEntry
	jmp	short exit
	;
	; turned off "DTR", make sure RTS is on
	;
DTRoff:
	mov	cx, mask SMC_RTS
	call	SetStopRemoteListEntry
exit:
	ret
TermUserStopRemoteSignal	endm

SetStopRemoteListEntry	proc	near
	push	ax, cx, bp
	GetResourceHandleNS	StopRemoteList, bx
	mov	si, offset StopRemoteList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	dx, -1			; select
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, bp
	ret
SetStopRemoteListEntry	endp

TermStopLocalSignal	method	TermClass, MSG_TERM_STOP_LOCAL_SIGNAL
	mov	ds:[stopLocal], cx

	;redo flow control stuff
	;(cx not needed for TermSetFlow)

	call	GetFlowSettings		; dx = actual flow settings
	mov	cx, dx			; cx = flow settings
	CallMod	SerialSetFlowControl
	ret
TermStopLocalSignal	endm
endif	; !_TELNET

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermQuickDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	dial a phone number
	
CALLED BY:	MSG_TERM_QUICK_DIAL

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dialPrefix	db	"ATD"
TermQuickDial	method	TermClass, 	MSG_TERM_QUICK_DIAL

	mov	bx, ds:[interfaceHandle]
	mov	si, offset PhoneNum
	call	CheckPhoneNumber		;first check if number legit
	LONG jz	exit				; exit if no number to dial

	segmov  es, cs, cx
	mov     si, offset dialPrefix           ;es:si->string to send
	mov	cx, DIAL_PREFIX_LEN		;get #chars to dial
	mov	ds:[systemErr], FALSE		; catch error in SendBuffer
	CallMod	SendBuffer			;
	jc	error				; check for send buf error
;SendBuffer returns carry if error, don't need to check this - brianc 9/14/90
;	tst	ds:[systemErr]
;	jnz	error
	tst	ds:[toneDial]	
	jz      pulse
	mov     cl, CHAR_TONE
	jmp     20$
pulse:
	mov     cl, CHAR_PULSE
20$:
	CallMod SendChar

	mov	bx, ds:[interfaceHandle]
	mov	si, offset PhoneNum
	
	clr	dx				;flag give me a buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage
	xchg	ax, cx			;ax = block, cx = size
	jcxz	freeAndExit		;exit if no phone #
	mov	bx, ax
	push	bx
	call	MemLock


if DBCS_PCGEOS
	push	ds, cx
	mov	ds, ax
	mov	es, ax
	clr	si, di
convLoop:
	lodsw
	stosb
	loop	convLoop
	pop	ds, cx
	clr	si			; es:si = phone number
	CallMod	SendBuffer
else
	mov	es, ax
	clr	si			; XXX: THESE CHARS ARE SUPPOSED TO
					; BE IN THE BBS CHAR SET BUT ARE NOT.
	CallMod	SendBuffer			;are we dorked?

endif ; DBCS_PCGEOS

	lahf
	pop	bx			; free the darn buffer before we
	call	MemFree			;  leave so we don't leave little
					;  blocks locked on the heap every
					;  time we quick-dial -- ardeb 11/14/91
	sahf
	jc	error
	mov	cl, CHAR_CR
	CallMod	SendChar
	jmp	short exit
error:
        mov     ds:[systemErr], FALSE
exit:
	ret
freeAndExit:
	call	MemFree
	ret
TermQuickDial		endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermHangUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hang up phone
	
CALLED BY:	MSG_HANG_UP

PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermHangUp	method	TermClass, MSG_HANG_UP
	GetResourceHandleNS	hangUpVerifyStr, bx
	mov	bp, offset hangUpVerifyStr
	call	HangUpCommon
		

if _VSER and not _TELNET
	;
	; possibly send terminal to the back so whatever app
	; was active before will be visible
	;
EC <	Assert_dgroup ds						>
	cmp	ds:[buryOnDisconnect], BB_TRUE	
	jne	noBury

	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	GetResourceHandleNS	MyApp, bx
	mov	si, offset MyApp
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
noBury:
endif	; _VSER and ! _TELNET
done::
	ret
TermHangUp	endm

if	_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermHangUpDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after really hanging up

CALLED BY:	MSG_TERM_HANG_UP_DONE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermHangUpDone	method dynamic TermClass, MSG_TERM_HANG_UP_DONE
	.enter
if	_DYNAMIC_BUF
	;
	; Clean up recv buffer
	;
	call	TelnetBufferEnd
endif
	
if	_CLEAR_SCR_BUF
	;
	; Clear screen after each connection
	;
	mov	ax, MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
EC <	Assert_dgroup	ds						>
	mov	bx, ds:[termuiHandle]
	SendScreenObj
endif	; _CLEAR_SCR_BUF
	
	;
	; Dismiss the MainDialog (terminal buffer)
	;
	GetResourceHandleNS	MainDialog, bx
	mov	si, offset MainDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; Dismiss the Special Keys dialog no matter if it is up.
	;
	GetResourceHandleNS	SpecialKeyDialog, bx
	mov	si, offset SpecialKeyDialog
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; Check if FileOpenControl has opened a sub-directory. 
	;
	GetResourceHandleNS	TextSendFileOpen, bx
	mov	si, offset TextSendFileOpen
	mov	ax, MSG_FILE_OPEN_CONTROL_GET_DIRECTORY
	mov	di, mask MF_CALL
	call	ObjMessage			; cx <- FDocumentDir
	;
	; If it is, send MSG_FOC_CLOSE to tell it to close out sub-directory
	;
	cmp	cx, FDD_DOCUMENT		; exit if in top dir 
	je	closeTextSendDialog
	cmp	cx, FDD_NONE
	je	closeTextSendDialog
	;
	; Sending MSG_FOC_CLOSE when FileOpenControl is not in sub-directory
	; will crash!
	;
	mov	ax, MSG_FOC_CLOSE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

closeTextSendDialog:
	;
	; Dismiss the Text send dialog no matter if it is up.
	;
	GetResourceHandleNS	TextSendDialog, bx
	mov	si, offset TextSendDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; Dismiss the DisconnectionIndicatorDialog
	;
	GetResourceHandleNS	DisconnectionIndicatorDialog, bx
	mov	si, offset DisconnectionIndicatorDialog
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; -- Do the followings at the background --
	;
	; Make sure we don't show "Send text" and "capture text" by sending
	; back trigger action if we are doing Text Transfers.
	;
	GetResourceHandleNS	TransferBackTrigger, bx
	mov	si, offset TransferBackTrigger
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
	clr	cl				; do regular action
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	; Re-enable transparent detach and autolock
	;
	call	EnableTransparentDetach
	call	SecurityResumeAutoLock
	call	TelnetCleanupIfLaunchedViaIACP
	
	.leave
	ret
TermHangUpDone	endm
endif	; _TELNET

;
; pass:
;	bx:bp = string
;
HangUpCommon	proc	near
if	not _TELNET
	cmp	ds:[serialPort], NO_PORT
	jne	hangEmHigh
	clr     cx                              ; flag that cx should be stuffed
	mov     dx, offset sendBufErr           ;       with Strings resource
	mov     bp, ERR_NO_COM
	CallMod DisplayErrorMessage
	jmp     exit
endif	; !_TELNET

hangEmHigh:
	push	bx
	call	MemLock
	mov	es, ax
	mov	di, ax
	mov	bp, es:[bp]			; di:bp = string
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
	call	TermUserStandardDialog
	cmp	ax, IC_YES			; confirm hang-up?
	jne	done				; nope
	;
	; put up modal box informing user of hang-up and disallowing
	;	further input
	;
	GetResourceHandleNS	HangingUpNotice, bx
	mov	si, offset HangingUpNotice
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage
	
	;
	; flag hang-up okay, just in case
	;
	mov	ds:[allowHangUp], TRUE

if	not _TELNET
	;
	; make sure serial-out stream is flushed before trying hang-up
	; (when stream is empty, we'll be notified via MSG_REALLY_HANG_UP)
	;
	mov	ax, StreamNotifyType <0,SNE_DATA,SNM_MESSAGE>
	mov	bx, ds:[serialPort]
	mov	cx, ds:[termProcHandle]		; send method on
	clr	dx 				;	event
	mov	bp, MSG_REALLY_HANG_UP
	CallSer	DR_STREAM_SET_NOTIFY
	mov	ax, STREAM_WRITE		; check for write-stream all
	mov	cx, SERIAL_OUT_SIZE		;	clear
	CallSer	DR_STREAM_SET_THRESHOLD
	mov	ax, STREAM_WRITE		; in case stream is already
	mov	bx, ds:[serialPort]		;	clear
	CallSer	DR_STREAM_QUERY			; ax = number of bytes avail.
	cmp	ax, SERIAL_OUT_SIZE		; empty?
	jne	done				; nope, let notification do
						;	it's work
endif	; !_TELNET
	mov	ax, MSG_REALLY_HANG_UP	; else, send it ourselves
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
	call	ObjMessage
done:
	pop	bx
	call	MemUnlock
exit:
	ret
HangUpCommon	endp

ReallyHangUp	method	TermClass, MSG_REALLY_HANG_UP
if	not _TELNET
	;
	; first, clear flushing notification
	;
	mov	ax, StreamNotifyType <0,SNE_DATA,SNM_NONE>
	mov	bx, ds:[serialPort]
	mov	cx, ds:[termProcHandle]		; send notificiation to
	clr	dx				;	process
	mov	bp, MSG_REALLY_HANG_UP
	CallSer	DR_STREAM_SET_NOTIFY
		
	;
	; ensure that we only hang-up once
	;
	mov	al, FALSE
	xchg	al, ds:[allowHangUp]
	cmp	al, TRUE
	jne	done
	;
	; then, hang up
	;
	CallMod	SerialDropCarrier
	;
	; bring down hang-up box
	;
	call	DismissHangingUpBox
endif	; !_TELNET

done:
	ret
ReallyHangUp	endm

DismissHangingUpBox	proc	near
	GetResourceHandleNS	HangingUpNotice, bx
	mov	si, offset HangingUpNotice
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	clr	di
	call	ObjMessage
	ret
DismissHangingUpBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermQuickAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort dialing phone number
	
CALLED BY:	MSG_TERM_QUICK_ABORT


PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermQuickAbort	method	TermClass, 	MSG_TERM_QUICK_ABORT
	;
	; dismiss quick dial dialog
	;
	GetResourceHandleNS	QuickDialBox, bx
	mov	si, offset QuickDialBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL
	call	ObjMessage

;don't hang-up on quick-dial cancel - brianc 9/10/90
if 0
	GetResourceHandleNS	hangUpQuesStr, bx
	mov	bp, offset hangUpQuesStr
	call	HangUpCommon		; hang up if user wants to
endif
	ret
TermQuickAbort		endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDorked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send method to detach term application
	
CALLED BY:	MSG_TERM_DORKED


PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermDorked	method	TermClass, 	MSG_TERM_DORKED
	clr	cx				;pass detach parameters
	mov	dx, QL_BEFORE_UI		;	
	mov	ax, MSG_META_QUIT			;send DETACH to application
	mov	bx, ds:[applUIHandle]		;	object
	mov	si, offset MyApp		;
	mov	di, mask MF_FORCE_QUEUE		;send a detach to ourselves
	call	ObjMessage
exit:
	ret
TermDorked		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSendAsciiPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable box with options for ascii or xmodem file receive 
	
CALLED BY:	MSG_FILE_RECV_OPTIONS


PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSendAsciiPacket	method	TermClass, 	MSG_SEND_ASCII_PACKET
	CallMod		FileSendAsciiPacket
	ret
TermSendAsciiPacket		endm

TermBufferedSend	method	TermClass,	MSG_BUFFERED_SEND
	call	BufferedSend
	ret
TermBufferedSend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermFileSendAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable box with options for ascii or xmodem file receive 
	
CALLED BY:	MSG_FILE_RECV_OPTIONS


PASS:		ds	- dgroup
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermAsciiSendStart	method	TermClass, 	MSG_ASCII_SEND_START
	mov	ds:[sendProtocol], NONE	
	cmp	ds:[termStatus], ON_LINE	;
	jne	exit				;
	CallMod	FileSendStart			;	resource
exit:
	ret
TermAsciiSendStart		endm

TermXmodemSendStart	method	TermClass, 	MSG_XMODEM_SEND_START
	mov	ds:[sendProtocol], XMODEM	
	cmp	ds:[termStatus], ON_LINE	;
	jne	exit				;
	CallMod	FileSendStart			;	resource
exit:
	ret
TermXmodemSendStart		endm

	;
	; Define Custom Trigger.
	;
captureOKCancelResponse	StandardDialogResponseTriggerTable <2>
	StandardDialogResponseTriggerEntry <
		Capture_OK,
		IC_OK
	>
	StandardDialogResponseTriggerEntry <
		CaptureCancel,
		IC_DISMISS
	>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAsciiRecvStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up for receiving ASCII

CALLED BY:	MSG_ASCII_RECV_START
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
RETURN:		carry set if error (Responder only)
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermAsciiRecvStart	method	TermClass, 	MSG_ASCII_RECV_START
	uses	ax, bx, si, di
	.enter

if	not _TELNET
	;
	; Check for the selected protocol
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS	 	
	push	bx
	GetResourceHandleNS FlowList, bx
	mov	si, offset FlowList
	mov	di, mask MF_CALL
	call	ObjMessage	; return ax <-- selected protocol
	pop	bx
	test	ax, mask SFC_SOFTWARE
	jnz	continueCapture	; handshaking software is selected.
endif	; !_TELNET

	;
	; Notify user that data may be lost.
	;
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
	CustomDialogBoxFlags <1, CDT_NOTIFICATION, GIT_MULTIPLE_RESPONSE, 1>
	mov	ss:[bp].SDOP_customString.handle, handle Strings
	mov	ss:[bp].SDOP_customString.chunk, \
				offset Strings:CaptureNotifyString
	clr	ss:[bp].SDOP_stringArg1.handle
	clr	ss:[bp].SDOP_stringArg2.handle
	mov	ss:[bp].SDOP_customTriggers.segment, cs
	mov	ss:[bp].SDOP_customTriggers.offset, \
				offset captureOKCancelResponse
	clr	ss:[bp].SDOP_helpContext.segment
	call	UserStandardDialogOptr	; ax = InteractionCommand 

	cmp	ax, IC_OK	; if the user clicked OK button, continue
	jnz	exitCapture	; capture. Otherwise, exit capture.

continueCapture:
	mov	ds:[recvProtocol], NONE
	call	TermFileRecvStart; carry set if error (Responder only)

exitCapture:
	.leave
	ret
TermAsciiRecvStart		endm

TermXmodemRecvStart	method	TermClass, 	MSG_XMODEM_RECV_START
	mov	ds:[recvProtocol], XMODEM	
	call	TermFileRecvStart
	ret
TermXmodemRecvStart		endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Something has been put on the clip board.  geoComm checks
		if this object is something it can use.
	
CALLED BY:	UI via MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED


PASS:		ax - MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermTransferItemChanged	method	TermClass, \
				MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	clr	bp				;query about normal transfer
	call	ClipboardQueryItem
	mov	cx, bp 				;get #formats 
	push	bx, ax				;save transfer item header	
	jcxz	disable
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT			;we're looking for text scraps	
	call	ClipboardTestItemFormat
	jc	disable
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	short dorkEdit
disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
dorkEdit:
	mov     dl, VUM_NOW
	GetResourceHandleNS	PasteSelect, bx
	mov	si, offset PasteSelect
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bx, ax				;restore transfer item
	call	ClipboardDoneWithItem
	ret
TermTransferItemChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermModemStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if serial driver lost carrier
	
CALLED BY:	

PASS:		ax 	- MSG_MODEM_STATUS
		cx	- SerialModemStatus
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermModemStatus	method	TermClass, MSG_MODEM_STATUS
	.enter
	.leave
	ret
TermModemStatus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAsciiRecvSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up ascii receive box
	
CALLED BY:	

PASS:		ax 	- MSG_ASCII_RECV_SUMMONS
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermAsciiRecvSummons	method	TermClass, MSG_ASCII_RECV_SUMMONS
	.enter
	mov     dx, ds:[transferUIHandle]	;select the text in the chat
	mov     si, offset TextRecvTextEdit	; 	box
	CallMod SelectAllText			;

	mov	si, offset RecvAsciiBox		;bring up dialog box	
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, ds:[transferUIHandle]
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	.leave
	ret
TermAsciiRecvSummons		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermXmodemRecvSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up xmodem receive box
	
CALLED BY:	

PASS:		ax 	- MSG_XMODEM_RECV_SUMMONS
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermXmodemRecvSummons	method	TermClass, MSG_XMODEM_RECV_SUMMONS
	.enter
	mov     dx, ds:[transferUIHandle]	;select the text in the chat
	mov     si, offset RecvTextEdit		; 	box
	CallMod SelectAllText			;

	mov	si, offset RecvXmodemBox		;bring up dialog box	
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, ds:[transferUIHandle]
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	.leave
	ret
TermXmodemRecvSummons		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSaveBufSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up save as box
	
CALLED BY:	

PASS:		ax 	- MSG_SAVE_BUF_SUMMONS
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermSaveBufSummons	method	TermClass, MSG_SAVE_BUF_SUMMONS
	.enter
						;select the text in the chat
						; 	box
	GetResourceHandleNS	SaveAsTextEdit, dx
	mov     si, offset SaveAsTextEdit	; dx:si = text object
	CallMod SelectAllText			;

	GetResourceHandleNS	CaptureBox, bx
	mov	si, offset CaptureBox		;bring up dialog box	
	mov     ax, MSG_GEN_INTERACTION_INITIATE
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	.leave
	ret
TermSaveBufSummons		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermQuickDialSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up quick dial box
	
CALLED BY:	

PASS:		ax 	- MSG_QUICK_DIAL_SUMMONS
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TermQuickDialSummons	method	TermClass, MSG_QUICK_DIAL_SUMMONS
	.enter
	mov     dx, ds:[interfaceHandle]	;select the text in the chat
	mov     si, offset PhoneNum		; 	box
	CallMod SelectAllText			;

	mov	si, offset QuickDialBox		;bring up dialog box	
	mov     ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, ds:[interfaceHandle]
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	.leave
	ret
TermQuickDialSummons		endm

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitBucket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	dummy routine that ignores buffer of characters sent to it	

CALLED BY:	

PASS:		

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitBucket 	proc	far
	ret
BitBucket 	endp

if	not _TELNET

COMMENT @----------------------------------------------------------------------

FUNCTION:	TermFoundMatchContinueScript --
			MSG_TERM_FOUND_MATCH_CONTINUE_SCRIPT handler

DESCRIPTION:	This method is sent by the Serial thread (term:1), when
		it encounters a MATCH in the input stream. It is telling us
		to continue executing the script, starting with an offset
		of CX into the script. The serial thread has already suspended
		input from the host, so we don't have to worry about dropping
		characters while executing the script.

PASS:		ds	= dgroup
		cx	= offset to GOTO command in script.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/90		initial version

------------------------------------------------------------------------------@

TermFoundMatchContinueScript	method	TermClass, \
					MSG_TERM_FOUND_MATCH_CONTINUE_SCRIPT

EC <	call	ECCheckDS_dgroup					>

	CallMod	ScriptFoundMatchContinueScript
	ret
TermFoundMatchContinueScript	endm
endif	; !_TELNET


if	_SPECIAL_KEY
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDisplaySpecialKeyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an entry in the Special Key list

CALLED BY:	MSG_TERM_DISPLAY_SPECIAL_KEYS_LIST
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
		bp	= position of item requested
		^lcx:dx	= GenDynamicList object requesting the moniker
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermDisplaySpecialKeyList	method dynamic TermClass, 
					MSG_TERM_DISPLAY_SPECIAL_KEYS_LIST
		.enter
	;
	; Deref the entry string block
	;
		GetResourceHandleNS	SpecialKeyEntryStrings, bx
		push	bx			; save entry string block
		push	dx			; push lptr of dynamic list
		call	MemLock			; ax<-stpr of string blk
		mov	ds, ax
		mov	si, offset SpecialKeyEntryStringsTable
		mov	si, ds:[si]		; ds:si<-fptr key string table
	;
	; Find out the real offset to string table
	;
		mov	bx, bp			; bx <- index
		shl	bx			; 
		shl	bx			; get dword-size index
		add	si, bx			; si<-lptr of begin of string
	;
	; Get the offset to the real string to display
	;
		mov 	si, ds:[si]		; si<-lptr of begin of string
		mov	dx, ds:[si]		; dx<-nptr of begin of string
	;
	; Send message to dynamic list to display string
	;
		mov	bx, cx
		pop	si			; ^lbx:si<-GenDynamicList
		mov_tr	cx, ax			; cx:dx<-fptr to string
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
						; bp <- item index
EC <		Assert_nullTerminatedAscii	cxdx			>
		call	ObjMessage		; ax,cx,dx,bp destroyed
	;
	; unlock string block
	;
		pop	bx			; ^hbx<-SpecialKeyEntryStrings
		call	MemUnlock
		.leave
		ret
TermDisplaySpecialKeyList	endm

endif	; if _SPECIAL_KEY


if	_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermApplicationCancelConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User cancels connection when system is establishing
		connection 

CALLED BY:	MSG_TERM_APPLICATION_CANCEL_CONNECTION
PASS:		*ds:si	= TermApplicationClass object
		ds:di	= TermApplicationClass instance data
		es 	= segment of TermApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermApplicationCancelConnection	method dynamic TermApplicationClass, 
					MSG_TERM_APPLICATION_CANCEL_CONNECTION
		.enter
	
		GetResourceSegmentNS	dgroup, es
	
	;
	; Sets the status to -- user cancelling connection
	;
		BitSet	es:[statusFlags], TSF_USER_CANCEL_CONNECTION
	;
	; Depending on the status of connection, we want to do
	; different abort operation.
	;
		clr	bh
		mov	bl, es:[connectStatus]
RSP <		VSem	es, closeSem, TRASH_AX				>
		shl	bl
		shl	bl
		CheckHack <TelnetConnectStatus le 255/4>
EC <		cmp	bx, ((offset abortTelnetFuncTableEnd - offset abortTelnetFuncTable) - size vfptr)>
EC <		ERROR_A TERM_ERROR					>
		tstdw	cs:[abortTelnetFuncTable][bx]
		jz	exit			; abort if no action to take
		pushdw	cs:[abortTelnetFuncTable][bx]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	exit
		
done::

exit:
		.leave
		ret
TermApplicationCancelConnection	endm


DefAbortTelnetFunc	macro	func, status
.assert ($-abortTelnetFuncTable)/4 eq status, \
		<DefAbortTelnetFunc: corrupted table>
		vfptr	func
endm

abortTelnetFuncTable	label	vfptr.far
DefAbortTelnetFunc      0,                          TCS_NONE
DefAbortTelnetFunc      TelnetCloseDomainMedium,    TCS_OPEN_MEDIUM
DefAbortTelnetFunc      TelnetAbortResolveAddress,  TCS_RESOLVE_ADDR
DefAbortTelnetFunc      TelnetAbortConnect,         TCS_CONNECT
abortTelnetFuncTableEnd label	far
.assert ($-abortTelnetFuncTable)/4 eq TelnetConnectStatus


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermApplicationConnectionTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle telnet connection timeout 

CALLED BY:	MSG_TERM_APPLICATION_CONNECTION_TIMEOUT
PASS:		*ds:si	= TermApplicationClass object
		ds:di	= TermApplicationClass instance data
		es 	= segment of TermApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermApplicationConnectionTimeout	method dynamic TermApplicationClass, 
					MSG_TERM_APPLICATION_CONNECTION_TIMEOUT
		.enter
		call	TelnetTimeout
		.leave
		ret
TermApplicationConnectionTimeout	endm

endif	; _TELNET

if	_LOGIN_SERVER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermApplicationNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle various kinds of notifications

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= TermApplicationClass object
		es	- segment of TermApplicationClass
		ax	- message
		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		bp 	= change specific data
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	2/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermApplicationNotify	method dynamic TermApplicationClass, 
					MSG_META_NOTIFY,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
		uses	si, ax, cx, dx, bp
		.enter
if _LOGIN_SERVER
		call	HandleLoginNotifications
		jc	callSuper
endif ; _LOGIN_SEVER
	;
	; If your modification handles any notification types, put
	; them here.
	;
callSuper:
		.leave
		mov	di, offset TermApplicationClass
		GOTO	ObjCallSuperNoLock

TermApplicationNotify	endm

endif	; _RESPONDER or _LOGIN_SERVER
					

if _VSER
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermGainedFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the fact that we have the exclusive

CALLED BY:	MSG_META_GAINED_FULL_SCREEN_EXCL
PASS:		*ds:si	- TermApplicationClass object
		es	- segment of TermApplicationClass
		ax	- message
RETURN:		nothing
DESTROYED:	bx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermGainedFullScreenExcl	method dynamic TermApplicationClass, 
					MSG_META_GAINED_FULL_SCREEN_EXCL
		push	ds
		GetResourceSegmentNS dgroup, ds, TRASH_BX
		mov	ds:[haveExclusive], BB_TRUE
		mov	di, offset TermApplicationClass
		pop	ds
		GOTO	ObjCallSuperNoLock
TermGainedFullScreenExcl	endm

endif	; _VSER

if _VSER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLostFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle losing the full-screen exclusive

CALLED BY:	MSG_META_LOST_FULL_SCREEN_EXCL
PASS:		*ds:si	= TermApplicationClass object
		es	= segment of TermApplicationClass
		ax	= message
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    BULLET:
		Application is no longer the top object so ask the
		user if they'd like to disconnect and quit GeoComm 
		or if they'd like to leave GeoComm running in the back.
    RESPONDER: (VSER)
		Make a note that we've lost the exclusive

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JW	9/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLostFullScreenExcl	method dynamic TermApplicationClass, 
					MSG_META_LOST_FULL_SCREEN_EXCL
	uses	ax, si, es
	.enter
if _VSER
	GetResourceSegmentNS dgroup, es, TRASH_BX
	mov	es:[haveExclusive], BB_FALSE
		
endif	; _VSER
	.leave
	mov	di, offset TermApplicationClass		
	GOTO	ObjCallSuperNoLock	
TermLostFullScreenExcl	endm

endif	; _VSER or _BULLET

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDisplayProtocolWarningBoxIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a warning if they select 7 N 1 as a protocl

CALLED BY:	TermDoneProtocolInteraction
PASS:		es 	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		If the current setting are 7 N 1, put up a dialog box
		warning the user that some modems don't accept this.
		If not, then bring down dialog if it happens to be up.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	10/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermDisplayProtocolWarningBoxIfNeeded	proc	near
	uses	ax,di,bp, bx, ds
	.enter

		cmp 	es:[dataBits], (SL_7BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)
		jne	done
		cmp 	es:[parity], (SP_NONE shl offset SF_PARITY) or (mask SF_PARITY shl 8)
		jne	done
		cmp 	es:[stopBits], SBO_ONE	
		jne	done

		GetResourceHandleNS	ProtocolWarningString, bx
		call	MemLock
		mov	di, ax
		mov	ds, ax
		mov	bp, offset ProtocolWarningString
		mov	bp, ds:[bp]
		mov	ax, CustomDialogBoxFlags <0, CDT_WARNING, GIT_NOTIFICATION, 0 > 		
		call	TermUserStandardDialog
		call	MemUnlock
done:
	.leave
	ret
TermDisplayProtocolWarningBoxIfNeeded	endp

endif	; !_TELNET



if _LOGIN_SERVER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			LOGIN SERVER SHME

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchToLoginUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the UI to be appropriate for login mode

CALLED BY:	TTermAttachToPort
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchToLoginUI	proc	near
	uses	ax,bx,dx,si,di
	.enter
	;
	; Change Hangup to Continue
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS 	HangUpTrig, bx
		mov 	si, offset HangUpTrig
		call	SetUsability

CheckHack <(segment HangUpTrig) eq \
	   (segment ContinueLoginTrigger)>

		mov	ax, MSG_GEN_SET_USABLE
		mov	si, offset ContinueLoginTrigger
		call	SetUsability

	.leave
	ret
SwitchToLoginUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchFromLoginUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Change the UI back to normal after login mode is done.

CALLED BY:	TTermDetachFromPort
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchFromLoginUI	proc	near
	uses	ax,bx,dx,si,di
	.enter
	;
	; Change Continue to Hangupe
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	ContinueLoginTrigger, bx
		mov	si, offset ContinueLoginTrigger
		call	SetUsability

CheckHack <(segment HangUpTrig) eq \
	   (segment ContinueLoginTrigger)>

		mov	ax, MSG_GEN_SET_USABLE

		mov 	si, offset HangUpTrig

		call	SetUsability

	.leave
	ret
SwitchFromLoginUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUsability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an object usable/not usable, delayed via app queue

CALLED BY:	INTERNAL
PASS:		^lbx:si	= object
		ax	= set usability message
RETURN:		nothing
DESTROYED:	dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUsability	proc	near
	.enter
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage
	.leave
	ret
SetUsability	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleLoginNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles login server notifications

CALLED BY:	TermApplicationNotify
PASS:		*ds:si	= TermApplicationClass object
		ds:di	= TermApplicationClass instance data
		ds:bx	= TermApplicationClass object (same as *ds:si)
		es 	= segment of TermApplicationClass
		ax	= message #
		cx:dx - NotificationType
			cx - NT_manuf
			dx - NT_type
		^hbp - SHARABLE data block having a "reference count" 
		       initialized via MemInitRefCount.

RETURN:		Carry set if handled
			ax, bx, cx, dx, bp, di, si can be destroyed
		Carry clear if not handled
			above registers must be preserved
		ds, es fixed up if moved

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleLoginNotifications	proc	near
	uses	ax, cx
	.enter
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	done
	;
	; Check for login attach/detach notifications
	;
		mov	ax, MSG_TERM_DETACH_FROM_PORT
		cmp	dx, GWNT_LOGIN_DETACH
		mov	cx, LoginResponse <0, LS_ABORT>
		je	sendMessage

		mov	ax, MSG_TERM_ATTACH_TO_PORT
		cmp	dx, GWNT_LOGIN_ATTACH
		je	incAndSend

		mov	ax, MSG_TERM_LOGIN_INIT
		cmp	dx, GWNT_LOGIN_INITIALIZE
		clc
		jne	done
incAndSend:
		xchg	bx, bp
		call	MemIncRefCount
		xchg	bx, bp
sendMessage:
	;
	; Have process object handle login attach/detach
	;
		call	GeodeGetProcessHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		stc
done:
	.leave
	ret
notHandled:
		clc
		jmp	done
HandleLoginNotifications	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermLoginInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	invokes terminal emulator on a port already opened by an
		external communications protocol, like PPP.

CALLED BY:	MSG_TERM_LOGIN_INIT
PASS:		ds	= dgroup
		es 	= segment of TermClass
		ax	= message #
		^hbp	= LoginInitInfo
			  (Must be MemDecRefCount'ed when done using)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermLoginInit	method dynamic TermClass, 
					MSG_TERM_LOGIN_INIT
	.enter

		push	bp

		mov	bx, bp
		call	MemLock
		mov	es, ax			; es = LoginInitInfo
	;
	; Grab semaphore so no-one else can diddle variables behind our
	; back
	;
		PSem	ds, loginSem, TRASH_AX_BX

		cmp	ds:[loginPhase], LP_NONE
EC <		ERROR_NE TERM_ALREADY_IN_LOGIN_MODE			>
		jne	error

        ; For non-Responder stuff, we want to be able to read the
	; modem port into serialPort, so this doesn't make sense


	;
	; Copy LoginInitInfo data to global vars for later use.
	;
if LOGIN_PROTOCOL ne 1
PrintMessage <GeoComm only supports login server protocol 1>
endif
		segxchg	ds, es
		mov	di, offset loginInitVars
		clr	si
		mov	cx, size LoginInitInfo
		rep	movsb
		segxchg	ds, es

		cmp	ds:[loginInitVars].LII_protocol, LOGIN_PROTOCOL
		mov	ds:[loginPhase], LP_WAITING
		mov	dx, LoginResponse <0, LS_CONTINUE>
		mov	ax, offset protocolOK
		je	send
	;
	; Comm protocol trying to use a login protocol we don't understand.
	; Let it know this, and abort.
	;
error:
		mov	ds:[loginPhase], LP_NONE
		mov	dx, LoginResponse <0, LS_ERROR>
		mov	ax, offset done

send:	; ax = offset of code to execute after sending response message
	;
	; Send result back to PPP (we do this early, because we don't
	; want to hold up PPP while we fiddle with our UI)
	;
		push	ax
		mov	cx, es:[LII_connection]
		movdw	bxsi, es:[LII_responseOptr], ax
		mov	ax, es:[LII_responseMsg]
		clr	di
		call	ObjMessage
		pop	ax
		jmp	ax

protocolOK:

	;
	; prepare Terminal emulator
	;
		call	SwitchToLoginUI

done:
		VSem	ds, loginSem
	;
	; Free the notification block
	;
		pop	bx
		call	MemUnlock
		call	MemDecRefCount

	.leave
	ret

TTermLoginInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermAttachToPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	invokes terminal emulator on a port already opened by an
		external communications protocol, like PPP.

CALLED BY:	MSG_TERM_ATTACH_TO_PORT
PASS:		ds	= dgroup
		es 	= segment of TermClass
		ax	= message #
		^hbp	= LoginAttachInfo
			  (Must be MemDecRefCount'ed when done using)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		Implements the transition from START to CONNECTED states
		in login.def

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermAttachToPort	method dynamic TermClass, 
					MSG_TERM_ATTACH_TO_PORT
	.enter

		PSem	ds, loginSem, TRASH_AX_BX

	; Lock down info contained in passed block

		mov	bx, bp
		push	bx
		call	MemLock
		mov	es, ax			; es = LoginAttachInfo
	;
	; Make sure we're ready to be handling this
	;
		cmp	ds:[loginPhase], LP_WAITING
EC <		WARNING_NE TERM_LOGIN_PHASE_NOT_CORRECT			>
		jne	error
	;
	; Make sure the connection tokens match
	;
		mov	ax, es:[LAI_connection]
		cmp	ax, ds:[loginInitVars].LII_connection
		jne	error
	;
	; Copy LoginAttachInfo data to global vars for later use.
	;
		segxchg	ds, es
		mov	di, offset loginAttachVars
		clr	si
		mov	cx, size LoginAttachInfo
		rep	movsb
		segxchg	ds, es

if LOGIN_PROTOCOL ne 1
; If the external login API changes, change the code to support it, then
; update this message.
PrintMessage <GeoComm only supports login server protocol 1>
endif
	;
	; Save old port settings
	;
		movdw	ds:[serialDriverSaved], ds:[serialDriver], ax
		mov	ax, ds:[serialPort]
		mov	ds:[serialPortSaved], ax
	;
	; Prepare to use the passed-in serial port
	;
		movdw	ds:[serialDriver], ds:[loginAttachVars].LAI_strategy, ax
		mov	ax, ds:[loginAttachVars].LAI_port
		mov	ds:[serialPort], ax
	;
	; Move into ACTIVE phase of login
	;
		mov	ds:[loginPhase], LP_ACTIVE

		VSem	ds, loginSem
	;
	; And open it.
	;
		call	OpenComPort

		; This will be done by the visibility notification of
		; the dialog.
	;	call	TermComeToTop

done:
		pop	bx
		call	MemUnlock
		call	MemDecRefCount
	.leave
	ret

error:
	;
	; Send notification of error back to PPP
	;
		mov	dx, LoginResponse <0, LS_ERROR>
		mov	cx, es:[LAI_connection]
		movdw	bxsi, es:[LAI_responseOptr], ax
		mov	ax, es:[LAI_responseMsg]
		clr	di
		call	ObjMessage

		mov	ds:[loginPhase], LP_NONE

		VSem	ds, loginSem
	;
	; Undo ui changes
	;
		call	SwitchFromLoginUI

		jmp	done

TTermAttachToPort	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermDetachFromPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends session started with ATTACH_TO_PORT.  Does any
		cleanup necessry for the current login phase.

CALLED BY:	MSG_TERM_DETACH_FROM_PORT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
		cx	= LoginResponse to pass to PPP driver

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermDetachFromPort	method dynamic TermClass, 
					MSG_TERM_DETACH_FROM_PORT
	.enter
		PSem	ds, loginSem

		mov	di, ds:[loginPhase]
EC <		Assert_etype di, LoginPhase				>
		call	cs:loginDetachHandlers[di]

		mov	ds:[loginPhase], LP_NONE

		VSem	ds, loginSem

	.leave
	ret

TTermDetachFromPort	endm

loginDetachHandlers	nptr.near \
	offset LoginDetachNone,		; LP_NONE
	offset LoginDetachNone,		; LP_INIT
	offset LoginDetachWaiting,	; LP_WAITING
	offset LoginDetachActive	; LP_ACTIVE

;;;
;;; LP_NONE or LP_INIT
;;;
;;; When not a login server, nothing to be done to respond to
;;; GWNT_LOGIN_DETACH.
;;;

LoginDetachNone		proc	near

EC <		WARNING_E	TERM_NOT_IN_LOGIN_MODE			>
		ret
LoginDetachNone		endp

;;;
;;; LP_WAITING
;;;
;;; Just restore the original UI, if in that phase between
;;; initialization & waiting to attach to the com port.
;;;

LoginDetachWaiting	proc	near
	;
	; Undo ui changes
	;
if _LOGIN_SERVER
		call	SwitchFromLoginUI
endif ; _LOGIN_SERVER
		ret
LoginDetachWaiting	endp

;;;
;;; LP_ACTIVE
;;;
;;; We're in full-blown login attachment.  Must shut down the serial
;;; port, restore settings, restore UI, and send detach notification
;;; back to PPP.
;;;
;;; cx = LoginResponse

LoginDetachActive	proc	near
	;
	; Send detach response off to PPP.  Do it early so as not
	; to hold up PPP for too long while we fiddle with our UI.
	; Don't worry about the serial module reading from the
	; serial driver before PPP gets the notification, because
	; loginSem is grabbed throughout this entire routine. By
	; the time it finishes, serialPort will be invalid.
	;
		movdw	bxsi, ds:[loginAttachVars].LAI_responseOptr, ax
		mov	ax, ds:[loginAttachVars].LAI_responseMsg
		mov	dx, cx
		mov	cx, ds:[loginAttachVars].LAI_connection
		clr	di
		call	ObjMessage
	;
	; Restore old port settings.  This will also prevents the serial
	; module from reading any more data from the serial port
	; after it gets past the 'PSem loginSem'
	;
		movdw	ds:[serialDriver], ds:[serialDriverSaved], ax
		mov	ax, ds:[serialPortSaved]
		mov	ds:[serialPort], ax

if	_CLEAR_SCR_BUF
		;
		; Clear screen after each connection
		;
		mov	ax, MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
EC <		Assert_dgroup	ds					>
		mov	bx, ds:[termuiHandle]
		SendScreenObj

endif	; _CLEAR_SCR_BUF

		ret

LoginDetachActive	endp



endif ; _LOGIN_SERVER

