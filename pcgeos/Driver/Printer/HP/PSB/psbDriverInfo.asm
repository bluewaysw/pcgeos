COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		psbDriverInfo.asm

AUTHOR:		Jim DeFrisco

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision

DESCRIPTION:
	Driver info for the Bitmap PostScript printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: psbDriverInfo.asm,v 1.1 97/04/18 11:52:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Info Resource

	This part of the file contains the information that pertains to
	all device supported by the driver.  It includes device names and
	a table of the resource handles for the specific device info.  A
	pointer to this info is provided by the DriverInfo function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment	lmem LMEM_TYPE_GENERAL

;----------------------------------------------------------------------------
;	Device Enumerations
;----------------------------------------------------------------------------

; This etype defined in printDriver.def
;  PrintDevice	etype	word, 0, 2
PD_POSTSCRIPT_BITMAP	enum	PrintDevice,0	; generic bitmap PostScript

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

psbDriverInfo	DriverExtendedInfoTable < 
					  {},			; lmem hdr
					  PrintDevice/2,	; # devices
					  offset deviceStrings, ; devices
					  offset deviceInfoTab	; info blocks
					  >

psbSpecInfo	PrintDriverInfo         < 60,		;device timout
					  PR_RESEND,	;
					  asciiTransTable
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

deviceStrings	lptr.char \
  	     	PSBString			;one for all
		word	0				; table terminator

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

	; strings
PSBString	chunk.char "PostScript, use PC/GEOS fonts (slow)", 0

;----------------------------------------------------------------------------
;	Device Info Table and Info Structures
;----------------------------------------------------------------------------

deviceInfoTab	label	word
	hptr handle psbInfo	;generic entry

	word	0				; table terminator


DriverInfo	ends

