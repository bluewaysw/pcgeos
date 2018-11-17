COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefsnd.asm

AUTHOR:		Gene Anderson, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/25/92		Initial revision


DESCRIPTION:
	Code for keyboard module of Preferences

	$Id: prefsnd.asm,v 1.2 98/04/24 01:55:41 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefsnd.def
include prefsnd.rdef

ifdef GPC_VERSION
include sound.def
include	Internal/powerDr.def
endif

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
PrefSndCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSndGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSndGetPrefUITree	proc far
	mov	dx, handle PrefSndRoot
	mov	ax, offset PrefSndRoot
	ret
PrefSndGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSndGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECSnd/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSndGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefSndMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefSndMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'S' or ('N' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefSndGetModuleInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSndSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	send message to the UI to update itself

PASS:		*ds:si	= PrefSndDialogClass object
		ds:di	= PrefSndDialogClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

soundCat	char "sound",0
volume		char "volume", 0
balance		char "balance", 0
synthKey	char "synthDriver",0
sampleKey	char "sampleDriver",0
driverKey	char "driver",0
soundDir	char "sound",0

PrefSndSaveOptions	method	dynamic	PrefSndDialogClass, 
					MSG_META_SAVE_OPTIONS
driverName	local	FileLongName
driverDOSName	local	DosDotFileName
	.enter

	push	bp
	mov	di, offset PrefSndDialogClass
	call	ObjCallSuperNoLock
	pop	bp

	push	bp
	mov	ax, MSG_USER_UPDATE_SOUND_PARAMS
	mov	bx, handle ui
	clr	di
	call	ObjMessage
	pop	bp

	;
	; Save stuff that has multiple keys
	;
	; Get the DOS name of the driver (why DOS!?!)
	;
	segmov	ds, cs, cx
	push	bp, cx
	mov	si, offset soundCat
	mov	dx, offset driverKey
	segmov	es, ss
	lea	di, ss:driverName
	mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, (size driverName)>
	call	InitFileReadString
	pop	bp, cx
	jc	notFound
	;
	; Look in SYSTEM\SOUND
	;
	mov	bx, SP_SYSTEM				;bx <- StandardPath
	segmov	ds, cs
	mov	dx, offset soundDir			;ds:dx <- path
	call	FileSetCurrentPath
	segmov	es, ss, ax
	lea	di, ss:driverDOSName			;es:di <- buffer
	mov	ds, ax
	lea	dx, ss:driverName			;ds:dx <- filename
	mov	ax, FEA_DOS_NAME			;ax <- FileExtendedAtt
	mov	cx, (size driverDOSName)
	call	FileGetPathExtAttributes
	;
	; Write it to the synthDriver and sampleDriver keys
	;
	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset synthKey
	call	InitFileWriteString
	mov	dx, offset sampleKey
	call	InitFileWriteString
notFound:
	.leave
	ret
PrefSndSaveOptions	endm

ifdef GPC_VERSION

;
;  Intercept the handler and turn on/off the volume gadget.
;
PrefItemGroupSelect	method	MyPrefItemGroupClass, 
				MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	uses	bx
	.enter

	push	cx
	mov	di, offset MyPrefItemGroupClass
	call	ObjCallSuperNoLock
	pop	cx

	cmp	cx, TRUE
	mov	ax, MSG_GEN_SET_ENABLED
	je	enableSound
	mov	ax, MSG_GEN_SET_NOT_ENABLED

enableSound:
	;
	; enable/disable the volume control
	;
	mov	bx, ds:LMBH_handle
	mov	si, offset PrefVolume
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	push	bx, ax, dx, di
	call	ObjMessage
	pop	bx, ax, dx, di
	;
	; enable/disable the balance control too.
	;
	mov	si, offset PrefVolumeBalance
	call	ObjMessage
	.leave
	ret
PrefItemGroupSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSndOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the sound volume from the hardware device, and
	        set the UI gadget.

PASS:		
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        edwin	5/14/99   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSndOpen	method	dynamic	ChannelVolumeClass, 
					MSG_VIS_OPEN
	uses	di
	.enter

	mov	di, offset ChannelVolumeClass
	call	ObjCallSuperNoLock
	;
	;  Read the sound volume from the ini file
	;
	push	ds, si
	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset volume
	call	InitFileReadInteger ; ax 
	jnc	ok
	mov	ax, MIXER_LVL_MAX / 2	; default volume
ok:
	pop	ds, si
	;
	; set UI volume slider
	;
	mov	cx, ax
	mov	ax, MSG_PREF_VALUE_SET_ORIGINAL_VALUE
	clr	bp
	call	ObjCallInstanceNoLock
	;
	; record the original volume+balance setting.
	call	SoundMixerGetMasterVolume
	mov	di, ds:[si]
	add	di, ds:[di].ChannelVolume_offset
	mov	ds:[di].CV_originalVolumeBalance, ax

	; save self optr to pass to PM driver later.
	push	ds:[OLMBH_header].LMBH_handle, si

	;
	;  Read the balance from the ini file
	;
	push	ds
	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset balance
	call	InitFileReadInteger ; ax 
	jnc	ok2
	mov	ax, SOUND_BALANCE_MAX / 2	; default balance
ok2:
	pop	ds
	;
	; set the UI balance slider
	;
	mov	cx, ax
	mov	bx, ds:LMBH_handle
	mov	si, offset PrefVolumeBalance
	mov	ax, MSG_PREF_VALUE_SET_ORIGINAL_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; Connect to power driver to get volume button notifications.
	;
	pop	dx, cx			; ^ldx:cx = self
	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver	; ax = driver handle
	tst	ax
	jz	afterPM			; => no PM driver
	mov_tr	bx, ax			; bx = driver handle
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct
	mov	bx, si			; ds:bx = DriverInfoStruct
	mov	di, DR_POWER_ESC_COMMAND
	mov	si, POWER_ESC_VOL_BUTTON_NOTIF_REGISTER
	mov	ax, MSG_CV_VOL_UP_BUTTON_PRESSED
	mov	bp, MSG_CV_VOL_DOWN_BUTTON_PRESSED
	call	ds:[bx].DIS_strategy
EC <	WARNING_C CANT_REGISTER_WITH_PM_DRIVER_VOL_BUTTON_NOTIF		>
EC <	tst	ax							>
EC <	WARNING_NZ CANT_REGISTER_WITH_PM_DRIVER_VOL_BUTTON_NOTIF	>
afterPM:

	.leave
	ret
PrefSndOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CVVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect ourselves from power driver for volume button
		notifications.

CALLED BY:	MSG_VIS_CLOSE

PASS:		*ds:si	= ChannelVolumeClass object
		es 	= segment of ChannelVolumeClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/07/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CVVisClose	method dynamic ChannelVolumeClass, 
					MSG_VIS_CLOSE

	mov	di, offset ChannelVolumeClass
	call	ObjCallSuperNoLock

	mov	dx, ds:[OLMBH_header].LMBH_handle
	mov	cx, si			; ^ldx:cx = self
	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver	; ax = driver handle
	tst	ax
	jz	done			; => no PM driver
	mov_tr	bx, ax			; bx = driver handle
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct
	mov	bx, si			; ds:bx = DriverInfoStruct
	mov	di, DR_POWER_ESC_COMMAND
	mov	si, POWER_ESC_VOL_BUTTON_NOTIF_UNREGISTER
	call	ds:[bx].DIS_strategy
EC <	WARNING_C CANT_UNREGISTER_WITH_PM_DRIVER_VOL_BUTTON_NOTIF	>
EC <	tst	ax							>
EC <	WARNING_NZ CANT_UNREGISTER_WITH_PM_DRIVER_VOL_BUTTON_NOTIF	>

done:
	ret
CVVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CVVolButtonPressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A front-panel volume button is pressed.

CALLED BY:	MSG_CV_VOL_UP_BUTTON_PRESSED
		MSG_CV_VOL_DOWN_BUTTON_PRESSED

PASS:		*ds:si	= ChannelVolumeClass object
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/07/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CVVolButtonPressed	method dynamic ChannelVolumeClass, 
					MSG_CV_VOL_UP_BUTTON_PRESSED,
					MSG_CV_VOL_DOWN_BUTTON_PRESSED

	;
	; Do nothing if the object is disabled Gen-wise.
	;
	mov_tr	di, ax			; di = vol up/down msg
	mov	ax, MSG_GEN_GET_ENABLED
	call	ObjCallInstanceNoLock	; CF set if enabled
	jnc	done			; => disabled

	;
	; Add or subtract the increment as appropritate.
	;
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock	; dx.cx = value
	cmp	di, MSG_CV_VOL_DOWN_BUTTON_PRESSED
	je	down
if	(((MIXER_LVL_MAX - MIXER_LVL_MIN) * 65536 / SOUND_BUTTON_INC_FACTOR) \
		and 0xffff) ne 0
	add	cx, ((MIXER_LVL_MAX - MIXER_LVL_MIN) * 65536 \
		/ SOUND_BUTTON_INC_FACTOR) and 0xffff
	adc	dx, (MIXER_LVL_MAX - MIXER_LVL_MIN) / SOUND_BUTTON_INC_FACTOR
else
	add	dx, (MIXER_LVL_MAX - MIXER_LVL_MIN) / SOUND_BUTTON_INC_FACTOR
endif
	jmp	setValue

down:
if	(((MIXER_LVL_MAX - MIXER_LVL_MIN) * 65536 / SOUND_BUTTON_INC_FACTOR) \
		and 0xffff) ne 0
	sub	cx, ((MIXER_LVL_MAX - MIXER_LVL_MIN) * 65536 \
		/ SOUND_BUTTON_INC_FACTOR) and 0xffff
	sbb	dx, (MIXER_LVL_MAX - MIXER_LVL_MIN) / SOUND_BUTTON_INC_FACTOR
else
	sub	dx, (MIXER_LVL_MAX - MIXER_LVL_MIN) / SOUND_BUTTON_INC_FACTOR
endif

setValue:
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp			; not indeterminate
	call	ObjCallInstanceNoLock

	;
	; Mark the object modified, so that it becomes applyable.
	;
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	mov	cx, ax			; cx = non-zero to mark modified
	call	ObjCallInstanceNoLock

	;
	; Force the status message to be sent.
	;
	mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
	mov	cx, ax			; cx = non-zero for modified
	call	ObjCallInstanceNoLock

done:
	ret
CVVolButtonPressed	endm

;
;
;
PrefSndApply	method	dynamic	ChannelVolumeClass, 
					MSG_GEN_APPLY
	.enter
	mov	di, offset ChannelVolumeClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bp, ds:[di].GVLI_value.WWF_int

	;
	; Store the current values as the original values, because they
	; have now been "applied".
	;
	mov	dx, bp			; dx = volume
	call	ApplyLeftRightBalance	; al = left vol, ah = right vol
	mov	di, ds:[si]
	add	di, ds:[di].ChannelVolume_offset
	mov	ds:[di].CV_originalVolumeBalance, ax

	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset volume
	call	InitFileWriteInteger ; ax
		
	.leave
	ret
PrefSndApply	endm
PrefBalanceApply	method	dynamic	ChannelBalanceClass, 
					MSG_GEN_APPLY
	.enter
	mov	di, offset ChannelBalanceClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bp, ds:[di].GVLI_value.WWF_int

	segmov	ds, cs, cx
	mov	si, offset soundCat
	mov	dx, offset balance
	call	InitFileWriteInteger ; ax
		
	.leave
	ret
PrefBalanceApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChannelVolumeReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reset the sound volume.  User aborts the changes.

PASS:		none
RETURN:		none

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        edwin	5/14/99   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChannelVolumeReset	method	dynamic	ChannelVolumeClass,
					MSG_GEN_RESET
	.enter

	push	di
	mov	di, offset ChannelVolumeClass
	call	ObjCallSuperNoLock
	pop	di

	mov	ax, ds:[di].CV_originalVolumeBalance
	call	SoundMixerSetMasterVolume

	.leave
	ret
ChannelVolumeReset	endm


;
;  It's a fake fix to the system bug that the disabled slider can
;  actually react to the mouse action.
;
ChannelVolumeStartSelect	method	dynamic	ChannelVolumeClass,
					MSG_META_START_SELECT
	.enter
	mov	di, offset ChannelVolumeClass
	call	SliderInteraction
	.leave
	ret
ChannelVolumeStartSelect	endm
ChannelBalanceStartSelect	method	dynamic	ChannelBalanceClass,
					MSG_META_START_SELECT
	.enter
	mov	di, offset ChannelBalanceClass
	call	SliderInteraction
	.leave
	ret
ChannelBalanceStartSelect	endm
SliderInteraction	proc far
	class PrefValueClass
	.enter
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	pop	di
	jz	skip
	call	ObjCallSuperNoLock
	jmp	exit
skip:
	mov	ax, mask MRF_PROCESSED
exit:
	.leave
	ret
SliderInteraction	endp


;
;  Play a testing sound.
;
ChannelVolumeTest	method	dynamic	ChannelVolumeClass, 
					MSG_CV_TEST_VOLUME
	.enter

	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock	; dx.cx - int, frac
	call	ApplyLeftRightBalance   ; al - left, ah - right
	call	SoundMixerSetMasterVolume

	mov	ax, SST_ALARM or SST_IGNORE_SOUND_OFF
	call	UserStandardSound

	.leave
	ret
ChannelVolumeTest	endm


;
;  Apply the left-right volume balance.
;  Pass:   dx - master volume
;  Return: al - left channel volume
;          ah - right channel volume
;
ApplyLeftRightBalance	proc near
	uses	si, bx, cx, dx, bp, di
	.enter

	push	dx	; master volume

	mov	bx, ds:LMBH_handle
	mov	si, offset PrefVolumeBalance
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage	; dx.cx - int, frac

	mov_tr	ax, dx	; ax - balance indication: 0 - SOUND_BALANCE_MAX
	pop	dx	; master volume

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
	.leave
	ret
ApplyLeftRightBalance	endp

endif

PrefSndCode	ends
