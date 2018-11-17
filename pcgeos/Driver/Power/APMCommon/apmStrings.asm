COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Jedi
MODULE:		APM Power Manager driver
FILE:		apmpwrStrings.asm

AUTHOR:		Todd Stumpf, May 26th, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd	5/26/93		Initial revision

DESCRIPTION:
	Strings used in code

	$Id: apmStrings.asm,v 1.1 97/04/18 11:48:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringsUI segment lmem LMEM_TYPE_GENERAL

;--------------------------------------------
; PW_MAIN_BATTERY
;--------------------------------------------
MainWarningString	chunk.char	\
	"The main battery is low. ", 0

;--------------------------------------------
; PW_BACKUP_BATTERY
;--------------------------------------------
	chunk.char	\
	"The backup battery is low. ", 0

;--------------------------------------------
; PW_PCMCIA_SLOT_1_BATTERY
;--------------------------------------------=
	chunk.char	0

;--------------------------------------------
; PW_PCMCIA_SLOT_2_BATTERY
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_PCMCIA_SLOT_3_BATTERY
;--------------------------------------------
	chunk.char	0


;--------------------------------------------
; PW_PCMCIA_SLOT_4_BATTERY
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_APM_BIOS_STAND_BY_REQUEST (AKA PW_CUSTOM_1)
;--------------------------------------------
	chunk.char	\
	"There is an internal problem with the unit!  Please ",
	"restart the unit. ", 0

;--------------------------------------------
; PW_APM_BIOS_SUSPEND_REQUEST (AKA PW_CUSTOM_2)
;--------------------------------------------
	chunk.char	\
	"The batteries are too low on power.  Please turn the ",
	"unit off immediately and change the batteries. ", 0


;--------------------------------------------
; PW_APM_BIOS_RESTORE_FROM_CRITICAL_SUSPEND (AKA PW_CUSTOM_3)
;--------------------------------------------
if REBOOTS_ON_CRITICAL
	chunk.char	\
	"GEOS was unexpectedly interrupted; the unit will now ",
	"restart.  Please wait... ", 0
else

	chunk.char	\
	"GEOS was unexpectedly interrupted; please save all ",
	"data and restart the unit with <Ctrl>-<Alt>-<Del>.", 0

endif	; REBOOTS_ON_CRITICAL


;--------------------------------------------
; PW_LOW_STORAGE_CONDITION (AKA PW_CUSTOM_4)
;--------------------------------------------
	chunk.char	0


;--------------------------------------------
; PW_CUSTOM_5
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_CUSTOM_6
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_CUSTOM_7
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_CUSTOM_8
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_CUSTOM_9
;--------------------------------------------
	chunk.char	0

;--------------------------------------------
; PW_CUSTOM_10
;--------------------------------------------
	chunk.char	0


;-----------------------------------------------------------------------------
;
;		 Non-Power Warnings Strings that
;		are still basically power warnings
;			strings...
;
;-----------------------------------------------------------------------------

ifidn	HARDWARE_TYPE, <GPC1>
; PowerOffCustomString is not used for GPC.
else
PowerOffCustomString	chunk.char	\
	C_CTRL_A,"\r\rDo you still wish to shut down? ", 0
endif	; HARDWARE_TYPE, <GPC1>

if	NUM_SERIAL_PORTS gt 0
ifidn	HARDWARE_TYPE, <GPC1>
PowerOffSerialOnString	chunk.char	\
	"Warning: Your GlobalPC is still using the serial port.\r\r",
	"Please power off your GlobalPC after the task has been completed.", 0
else
PowerOffSerialOnString	chunk.char	\
	"Warning: A serial port is still in use.  Shutting down ",
	"now will abruptly break the connection. ", 0
endif	; HARDWARE_TYPE, <GPC1>
else
chunk.char	""
endif	; NUM_SERIAL_PORTS


if	NUM_PARALLEL_PORTS gt 0
ifidn	HARDWARE_TYPE, <GPC1>
PowerOffParallelOnString	chunk.char	\
	"Warning: Your GlobalPC is still using the printer port.\r\r",
	"Please power off your GlobalPC after the task has been completed.", 0
else
PowerOffParallelOnString	chunk.char	\
	"Warning: A parallel port is still in use.  You should let ",
	"the operation complete before shutting down. ", 0
endif	; HARDWARE_TYPE, <GPC1>
else
chunk.char	""
endif	; NUM_PARALLEL_PORTS gt 0

if	NUM_PCMCIA_PORTS gt 0
PowerOffPCMCIAOnString	chunk.char	\
	"Warning: A PCMCIA card is still in use.  You should ",
	"exit the application using the card before shutting down. ",0
else
chunk.char	""
endif	; NUM_PCMCIA_PORTS gt 0

if	NUM_DISPLAY_CONTROLS gt 0
PowerOffDisplayOnString	chunk.char	\
	"Warning: The display is still in use.  You should ",
	"let the operation complete before shutting down. ",0
else
chunk.char	""
endif	; NUM_DISPLAY_CONTROLS

if	NUM_SPEAKER_CONTROLS gt 0
PowerOffSpeakerOnString	chunk.TCHAR	\
	"Please wait for the sound or music to finish before powering off.",0
else
chunk.TCHAR	""
endif	; NUM_SPEAKER_CONTROLS

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

ifidn	HARDWARE_TYPE, <GPC1>
ResuspendConfirmString	chunk.TCHAR	\
	"The power to your GlobalPC was disrupted.  This may be due to a power outage, or unplugging the computer without using the Unplug GlobalPC utility.  Would you like to turn off your GlobalPC again?", 0
else
ResuspendConfirmString	chunk.TCHAR	\
	"The power to your computer was disrupted.  This may be due to a power outage, or unplugging the computer without shutting it down first.  Would you like to turn off your computer again?", 0
endif	; HARDWARE_TYPE, <GPC1>
	localize "This is the question that is displayed when the power is disconnected during suspend mode and is then re-connected."

endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

StringsUI ends
