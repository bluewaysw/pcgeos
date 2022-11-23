COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom Library
FILE:		pccomManager.asm

AUTHOR:		Cassie Hartzog, Nov 11, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/11/93		Initial revision


DESCRIPTION:
	

	$Id: pccomManager.asm,v 1.1 97/04/05 01:26:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include geos.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the table lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

include ec.def
include geode.def
include heap.def
include	object.def
include	driver.def
include library.def
include lmem.def
include assert.def

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include resource.def
include system.def
include timer.def
include file.def
include fileEnum.def
include char.def
include localize.def
include initfile.def
include	Internal/semInt.def
include thread.def
include Internal/fileInt.def
include Internal/fileStr.def

include assert.def

UseDriver	Internal/streamDr.def
UseDriver	Internal/serialDr.def
UseDriver	Internal/ircommDr.def
UseLib		ui.def

DefLib  	pccom.def 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	pccomConstants.def
include	pccomMacro.def

;********************************************************************
;
; Need to verify the following constants match up.
;
;********************************************************************
CheckHack < PCCAT_REMOTE_RESERVED_ABORT_TYPE	eq ROBUST_QUOTE			>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 Global Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCComClass  	class	ProcessClass

MSG_PCCOM_READ_DATA	message		; internal msg sent by serial driver
MSG_PCCOM_DETACH	message		; internal msg sent by pccom
MSG_PCCOM_PCGET		message		; internal msg sent by pccom
MSG_PCCOM_PCSEND	message		; internal msg sent by pccom
MSG_PCCOM_PCCD		message		; internal msg sent by pccom
MSG_PCCOM_PCMKDIR	message		; internal msg sent by pccom
MSG_PCCOM_PCREMARK	message		; internal msg sent by pccom
MSG_PCCOM_PCPWD		message		; internal msg sent by pccom
MSG_PCCOM_WAIT_ALARM	message		; internal msg sent by pccom
PCComClass	endc

;********************************************************************
;
;
; Don't change the order or insert anything!  Code is sensitive.
;
;
;********************************************************************
udata	segment

serialDriver	fptr		(?)	; serial driver strategy
serialHandle	hptr		(?)	; handle of serial driver
sysFlags	SysFlags 	(?)
callbackOD	optr		(?)
threadHandle	hptr		(?)
serialBaud	SerialBaud	(?)
statusMSG	word		(?)	; msg to use in status reports
statusDest	optr		(?)	; OD for status reports
numStatus	word		(?)	; number of bytes to receive
					; between status messages
dataBlock	hptr		(?)	; incoming/outgoing info for
					; active PCCOMGET command
currentOffset	word		(?)	; pointer into dataBlock for
					; next filename
currentSize	word		(?)	; size of the datablock
statusName	char		PATH_BUFFER_SIZE dup(0)
statusFileSize	dword		(?)	; the size of the current file
statusXferSize	dword		(?)	; the number of bytes
					; transferred in the current
					; file
statusCond	PCComReturnType	(?)	; for the status report 
statusGrainSize	dword		(?)	; the number of bytes we
					; should recieve between
					; status reports
statusThresholdSize	dword	(?)	; the number of bytes we
					; have received before the
					; next status report
destname	char		PATH_BUFFER_SIZE dup(0)
oldpath		char		PATH_BUFFER_SIZE dup(0)

remoteCodePage	DosCodePage	(?)	; code page to translate
					; to/from on remote
dataBufferSize	dword		(?)	; amount of PCComData data we
					; can buffer from the other
					; side
datacallbackOD	optr		(?)
datacallbackMSG	word		(?)
waitTimer	word		(?)
waitTimerID	word		(?)
udata	ends


PCComClassStructures	segment resource
    PCComClass	mask CLASSF_NEVER_SAVED
    PCComFileSelectorClass
PCComClassStructures	ends

idata	segment
serialPort	SerialPortNum	NO_PORT		; communication port
client		hptr		NULL		; client thread

echoBack		byte		0
ackBack			byte		0
currentLsOption		LsOption	LO_short
currentStringBlock	StringBlock
		; a buffer to store text strings ScrWrite will write things
		; into this block first, and then send MSG_META_NOTIFY_WITH
		; DATA_BLOCK to send the string to application.
		; (this will prevent the system from getting flooded 
		;   by way too many MSG_META_NOTIFY(_WITH_DATA_BLOCK) )
;
; this Semaphore is used by the application thread to block until the
; serial thread is fully awake.
;
startSem	Semaphore <0,0>		; initially locked
;
; This Semaphore is used by the application thread to block in PCComExit
; until the serial thread is completely destroyed
;
destroySem      Semaphore <0,0>         ; initially locked
;
; this semaphore locks the common library interface code so that only
; one process can access the critical section.
;
initExitLock	Semaphore <1,0>		; initially NOT locked
;
; Used to protect the status variables in dgroup.
;
statusSem	Semaphore <1,0>		; initially NOT locked
;
; Used to wait on while fetching a file size from the remote.
;
pauseSem	Semaphore <0,0>		; initially locked
;
; Used to return detailed error code for an aborted command.  Default
; is PCCAT_DEFAULT_ABORT and is only set when statusCond is set with
; PCCRT_COMMAND_COMMAND_ABORTED.
;
pccomAbortType	PCComAbortType	PCCAT_DEFAULT_ABORT
;
; timeoutTime expresses the number of ticks to allow before a time out
; occurs.
;
timeoutTime	word		DEFAULT_TIMEOUT
defaultTimeout	word		DEFAULT_TIMEOUT

dataSem		Semaphore <1,0>		; initially NOT locked
;
; Used to synchornize access to PCComData data:
;

blockRetransAttempts	word		BLOCK_RESEND_ATTEMPTS
idata	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Code Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.wcheck
.rcheck
include	pccom.asm		
include pccomData.asm
include	pccomFile.asm		
include	pccomScr.asm		
include	pccomStrings.asm		
include	pccomUtils.asm		
include pccomClient.asm
include pccomFSel.asm
include pccomIntegrity.asm
.norcheck
.nowcheck




