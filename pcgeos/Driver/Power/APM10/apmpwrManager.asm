COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Power Drivers
FILE:		apmpwrManager.asm

AUTHOR:		Todd Stumpf, Jul 28, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/28/94   	Initial revision

DESCRIPTION:
	This file brings together all the files necessary to produce
	the default APM driver.

	This driver should run on any system with APM, but will not
	take advantage of special features on the hardware platform
	(like BIOS level passwords and such...)
		

	$Id: apmpwrManager.asm,v 1.1 97/04/18 11:48:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Common Code Defines and Includes
;-----------------------------------------------------------------------------

; Use APM v1.0 features.
APM_MAJOR_VERSION		equ	1
APM_MINOR_VERSION		equ	0
APM_MAJOR_VERSION_BCD		equ	1
APM_MINOR_VERSION_BCD		equ	0

HARDWARE_TYPE			equ	<PC>

;-----------------------------------------------------------------------------
;		Standard Common Power Code Definitions
;-----------------------------------------------------------------------------
PowerStrategy			equ	<APMPowerStrategy>

NUMBER_OF_CUSTOM_POWER_WARNINGS	equ 3

PW_APM_BIOS_STAND_BY_REQUEST			equ	<PW_CUSTOM_1>
PW_APM_BIOS_SUSPEND_REQUEST			equ	<PW_CUSTOM_2>
PW_APM_BIOS_RESTORE_FROM_CRITICAL_SUSPEND	equ	<PW_CUSTOM_3>

WARNINGS_SUPPORTED 	equ (mask PW_MAIN_BATTERY or			\
			     mask PW_APM_BIOS_STAND_BY_REQUEST or	\
			     mask PW_APM_BIOS_SUSPEND_REQUEST or	\
			     mask PW_APM_BIOS_RESTORE_FROM_CRITICAL_SUSPEND)

BATTERY_POLL_INITIAL_WAIT =	15*60	; 15 seconds
BATTERY_POLL_INTERVAL     =	30	; twice per seconds

include geos.def		; to define TRUE and FALSE
include apm10Configure.def	; must be included next
include powerGeode.def		; this is where all the powerCommon gets
				; included

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------
include	Internal/im.def
include Internal/interrup.def
include thread.def
include file.def
include fileEnum.def
include Objects/inputC.def
include	system.def
include timedate.def
include assert.def

;-----------------------------------------------------------------------------
;		Included Libraries & Drivers
;-----------------------------------------------------------------------------
if	HAS_PCMCIA_PORTS
UseLib	pcmcia.def
endif

if	HAS_SERIAL_PORTS
UseDriver Internal/serialDr.def
endif

;----------------------------------------------------------------------------
;		Definitions local to this module
;-----------------------------------------------------------------------------

include	apmConstant.def
include	apmVariables.def
include apmStrings.asm
include	apmpwrMacro.def

;-----------------------------------------------------------------------------
;		Code
;-----------------------------------------------------------------------------

include	apmCustom.asm
include	apmStrategy.asm
include	apmPassword.asm
include	apmIdle.asm
include	apmOnOff.asm
include	apmVerify.asm
include	apmUtil.asm
include	apmRegister.asm
include	apmPoll.asm
include apmEsc.asm

include apm10Poll.asm


