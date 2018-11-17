COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Library/Stream
FILE:		streamCManager.asm

AUTHOR:		John D. Mitchell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

DESCRIPTION:
	This files contains the main source code inclusion for the
	C Stream Driver Library.

	$Id: streamCManager.asm,v 1.1 97/04/07 11:15:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include ec.def
include	driver.def
include geode.def
include heap.def
include initfile.def
include library.def
include lmem.def
include resource.def
include sem.def
include system.def
include timedate.def
include vm.def
include file.def
include	assert.def

UseDriver	Internal/streamDr.def
UseDriver	Internal/serialDr.def
UseDriver	Internal/parallDr.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	streamCConstant.def
include streamCVariable.def

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Global Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;
; SerialPortStatusMap is used to keep track of the current status of each
; serial port's current status.   See SerialSetNotify for more information.
;
SerialPortStatusMap	word	MAX_NUM_SERIAL_PORT	dup	\
	(SERIAL_PORT_STATUS_UNKNOWN or SERIAL_PORT_INVALID)

idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Code Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	streamCDriver.asm			; Generic Driver entries.
include	streamCStream.asm			; Stream Driver entries.
include	streamCSerial.asm			; Serial Driver entries.
include	streamCParallel.asm			; Parellel Driver entries.
include streamCEntry.asm
include streamCUtils.asm
