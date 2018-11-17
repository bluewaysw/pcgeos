COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		tcpipLog.asm

AUTHOR:		Jennifer Wu, Nov 19, 1994

ROUTINES:
	Name			Description
	----			-----------
	LogOpenFile
	LogCloseFile
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	11/19/94		Initial revision

DESCRIPTION:
	Code for logging information about the TCP driver.

	$Id: tcpipLog.asm,v 1.1 97/04/18 11:57:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;---------------------------------------------------------------------------
;			DEFINITIONS 
;---------------------------------------------------------------------------

TCPIP_LOG_CREATION_FAILED		enum	Warnings
TCPIP_LOG_CLOSE_FAILED			enum	Warnings


;---------------------------------------------------------------------------
;			CODE
;---------------------------------------------------------------------------

udata	segment

	logFile		hptr		

udata	ends

LogCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the log file.

CALLED BY:	TcpipInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, ds

PSEUDO CODE/STRATEGY:
		Open the log file in the document directory.  Create one
		if it doesn't already exist, else set file position at
		end of file.

		Save the log file's handle.

NOTE:  	Must use FE_NONE instead of FE_DENY_WRITE to be able to look
	at the file from Unix while the driver has it open.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/19/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
logFileName	char	"tcp.log", 0

LogOpenFile	proc	far
	;
	; Switch to document directory.
	;
		call	FilePushDir
		mov	ax, SP_DOCUMENT
		call	FileSetStandardPath
		jc	restoreDir
	;
	; Create the file if not already in existence.
	;
		mov	ax, ((mask FCF_NATIVE or FILE_CREATE_NO_TRUNCATE)\
				shl 8) or (FileAccessFlags \
				<FE_NONE, FA_WRITE_ONLY>)
		mov	cx, FILE_ATTR_NORMAL
		segmov	ds, cs, dx
		mov	dx, offset logFileName 		; ds:dx = file name
		call	FileCreate			; ax = file handle
EC <		WARNING_C TCPIP_LOG_CREATION_FAILED		>
		jc	restoreDir				

	;
	; Save file handle of log file.
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	ds:[logFile], ax
	;
	; Make file owned by tcp driver.
	;
		mov	bx, ax				; bx = file handle
		mov	ax, handle 0
		call	HandleModifyOwner
	;
	; Seek to end of file.
	;
		mov	al, FILE_POS_END		; offset is from end
		clrdw	cxdx				; offset is zero
		call	FilePos				
restoreDir:
		call	FilePopDir

		ret
LogOpenFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogCloseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the log file, writing out any stats if desired.

CALLED BY:	TcpipExit

PASS:		nothing

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/19/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LogCloseFile	proc	far

ifdef LOG_STATS		
		call	LogWriteStats		; may destroy all but bp
endif		
		mov	bx, handle dgroup
		call	MemDerefDS

		clr	bx
		xchg	bx, ds:[logFile]
		tst	bx
		je	exit

		clr	ax
		call	FileClose
EC <		WARNING_C TCPIP_LOG_CLOSE_FAILED		>

exit:
		ret
LogCloseFile	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	LogGetLogFile

DESCRIPTION: 	Get the file handle of the log file.
		
C DECLARATION:	extern FileHandle _far
		_far _pascal LogGetLogFile(void);

NOTE:		Take advantage of DS being dgroup because we are a 
		C stub.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/10/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
LOGGETLOGFILE		proc	far	
		mov	ax, ds:[logFile]
		ret
LOGGETLOGFILE		endp	
	SetDefaultConvention

LogCode	ends	


