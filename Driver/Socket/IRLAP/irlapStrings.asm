COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		irlapStrings.asm

AUTHOR:		Steve Jang, Sep 29, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94   	Initial revision

DESCRIPTION:
	
	This file contains strings for IRLAP driver.	

	$Id: irlapStrings.asm,v 1.1 97/04/18 11:57:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapStrings	segment lmem	LMEM_TYPE_GENERAL
;
; Notifications
;
mediaBusyStr		chunk.char \
	"Operation failed because there are other traffic in media", 0
primaryConflictStr	chunk.char \
	"Connection failed because there is another primary out there", 0
connectFailed		chunk.char \
	"Aim your gun straight!", 0
;
; Driver name
;
EC<  serialDriverName	chunk.TCHAR "serialec.geo", 0 >
NEC< serialDriverName	chunk.TCHAR "serial.geo", 0 >

;
; Temp strings
;
irlapDomainName		chunk.char \
	"irlap", 0
;
; Address dialog
;
irlapConnectionAddressDialog	chunk.char \
	"Select new address for CONNECTION",0
irlapDatagramAddressDialog	chunk.char \
	"Select new address for DATAGRAM",0
;
; .INI file categories and keywords
;
irlapCategory		chunk.char \
	"irlap   ", 0

if _SOCKET_INTERFACE
addressKeyword		chunk.char \
	"address", 0

defaultAddressStr	chunk.char \
	"UNKNOWN", 0
endif

portKeyword		chunk.char \
	"port", 0

;
; Connection parameters
;
baudrateKeyword		chunk.char \
	"baudRate", 0
maxTurnaroundKeyword	chunk.char \
	"maxTurnaround", 0
dataSizeKeyword		chunk.char \
	"dataSize", 0
windowSizeKeyword	chunk.char \
	"windowSize", 0
numBOFsKeyword		chunk.char \
	"numBOFs", 0
minTurnaroundKeyword	chunk.char \
	"minTurnaround", 0
linkDisconnectKeyword	chunk.char \
	"linkDisconnect", 0

IrlapStrings	ends

