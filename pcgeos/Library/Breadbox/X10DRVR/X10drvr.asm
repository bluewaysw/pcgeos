COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:	X-10 Power Code Driver	
FILE:		x10drvr.asm

AUTHOR: Fred Goya

REVISION HISTORY:

DESCRIPTION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

;
include	geos.def
include	file.def
include	geode.def
include	resource.def
include	ec.def
include	driver.def
include object.def
include	heap.def
include	system.def
include	timer.def
include	initfile.def
include internal/interrup.def
include	timechip.def
include Objects/winC.def
UseLib	ui.def
UseDriver Internal/serialDr.def

global	X10Sleep:far

;-----------------------------------------------------------------------------
;		Equates/Constants
;-----------------------------------------------------------------------------

SETTINGS_NONE			equ 0
SETTINGS_DIRECT			equ 1
SETTINGS_SERIAL_CM11	equ 2

X10DRVR_SERIAL_RECEIVE_TIMEOUT			enum Warnings
X10DRVR_SERIAL_INIT_RETRYING			enum Warnings
X10DRVR_HANDLE_POLL						enum Warnings
X10DRVR_HANDLE_POLL_NO_POLL				enum Warnings
X10DRVR_HANDLE_POLL_PFMD_CHKSUM_TIMEOUT	enum Warnings
X10DRVR_HANDLE_POLL_PFMD_CHKSUM_BAD		enum Warnings
X10DRVR_HANDLE_POLL_PFMD_READY_TIMEOUT	enum Warnings
X10DRVR_HANDLE_POLL_PFMD_NOT_READY		enum Warnings
X10DRVR_HANDLE_POLL_UNKNOWN_POLL		enum Warnings
X10DRVR_HANDLE_POLL_RECV_POLL_TIMEOUT	enum Warnings
X10DRVR_HANDLE_POLL_SUCCESS				enum Warnings
X10DRVR_HANDLE_POLL_PFMD_SUCCESS		enum Warnings

NoPortOpen				equ	 0ffffh

;-----------------------------------------------------------------------------
;		Initialized data segment
;-----------------------------------------------------------------------------

idata	segment

DriverTable	DriverInfoStruct <
		X10Strategy,
		0,
		DRIVER_TYPE_OUTPUT>

	; Port number of X10 interface - 0 = none, 1 = COM1, etc..
	X10Port				word		0h

	; Determines which interface is being driven
	X10Settings			word		SETTINGS_NONE

	; Physical base address of serial port for TW523 communication, or
	basePortAddress		word		0h
	; Port number of serial stream for CM11 communication
	portHandle			word		NoPortOpen
	
	zeroFlag			byte		0h

	x10DriverCategory 	char		"X-10Control",0
	x10DriverKey 		char 		"port",0
	x10SettingsKey		char		"settings",0

idata	ends

;-----------------------------------------------------------------------------
;		Uninitialized data segment
;-----------------------------------------------------------------------------

udata    segment

	serialStrategy      fptr		; serial driver strategy routine

udata    ends

;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include X10Init.asm		; set up board for use
include X10Strat.asm	; strategy routine and nothing else
include X10Send.asm		; code for sending codes synchronized w/zero
						;  crossing point
include X10Sleep.asm	; microsecond delay code.
include X10Ser.asm		; true serial communcations code for CM11
include X10Chg.asm		; how to change the serial port.

include dialog.rdf		; template dialog definitions resource
