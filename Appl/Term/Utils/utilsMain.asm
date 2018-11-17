COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Utils
FILE:		utilsMain.asm

AUTHOR:		Dennis Chow, December 13, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      12/13/89        Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: utilsMain.asm,v 1.2 98/01/27 21:12:19 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up a dialog box with error string

CALLED BY:	GLOBAL Everyone

PASS:		bp	- DisplayErrorFlags
		ds	- dgroup
	
		For non-Responder only:
		di	- stuff
		cx:dx	- value for first parameters 
			(if cx == 0) then stuff string resource into cx
		
RETURN:		

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		set up error string

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayErrorMessage	proc 	far
EC <		Assert_dgroup	ds					>
EC <		push	bp						>
EC <		andnf	bp, not mask DEF_SYS_MODAL			>
EC <		cmp	bp, ERROR_STRING_TABLE_LENGTH			>
EC <		ERROR_AE	TERM_ERROR				>
EC <		pop	bp						>
	
	push	si, di

	mov	ds:[systemErr], TRUE		;flag that we're dorked

	cmp	ds:[protocolInteraction], TRUE	; are we doing Protocol-APPLY?
	jne	10$				; nope
	cmp	bp, ERR_COM_OPEN		; are we trying to put up
	je	5$				;	no-com-port error?
	cmp	bp, ERR_NO_COM
	jne	10$
5$:
	cmp	ds:[reportedProtocolInteractionError], TRUE	; reported error
								;	already?
	je	exit				; yes, don't do it again
	mov	ds:[reportedProtocolInteractionError], TRUE
10$:

	push	ds				;save dgroup segment

	shl	bp, 1				;calc offset into error table
	add	bp, offset errorTable		;get ptr to string offset1

	mov	bp, cs:[bp]			;dx:bp->string to set
	mov	bx, ds:[stringsHandle]		;get String Resource handle
	call	MemLock		;	and lock it
	mov	ds, ax				;lock String resource
	mov	di, ax				;
	mov	bp, ds:[bp]			;di:bp->string to set
						;pass custom dialog box flags
						;  for an OK box
	tst	cx				;check if argument in string
	jnz	50$				;	resource
	mov	cx, ax				;pass string resource  
	mov	bx, dx
	cmp	bx, 0xffff			; avoid protection violation
	je	50$
.norcheck
	mov	dx, ds:[bx]			;deref string ptr
.rcheck
50$:
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)


	call	TermUserStandardDialog

	pop	ds				;restore dgroup segment
	mov	bx, ds:[stringsHandle]		;unlock String Resource handle
	call	MemUnlock
exit:
	pop	si, di
	ret
DisplayErrorMessage	endp


;
; Not a Responder String
;

NRS	macro	line
	line
endm

errorTable      label   word
	word    offset diskErr			;ERR_DISK_WRITE		
	word    offset timeoutErr		;ERR_NO_HOST
NRS <	word    offset comPortErr		;ERR_NO_PORT		>
	word	offset termcapErr		;ERR_TERMCAP_NOT_FOUND 
	word	offset remoteErr		;ERR_NO_REMOTE
	word	offset sendAbortErr		;ERR_SEND_ABORT
	word	offset completeErr		;ERR_RESP_COMPLETE
	word	offset noFileErr		;ERR_NO_FILE		
	word	offset makeTermDirErr		;ERR_MAKE_TERM_DIR
	word	offset fileTooBigErr		;ERR_FILE_TOO_BIG
	word	offset generalFileOpenErr	;ERR_GENERAL_FILE_OPEN
	word	offset scriptFileOpenErr	;ERR_SCRIPT_FILE_OPEN
	word	offset ftransFileOpenErr	;ERR_FTRANS_FILE_OPEN
	word	offset createFileErr		;ERR_CREATE_FILE
	word	offset cursorMoveErr		;ERR_CURSOR_MOVE
	word	offset undefMacroErr		;ERR_UNDEF_MACRO
	word	offset undefBaudErr		;ERR_UNDEF_BAUD
	word	offset undefDataErr		;ERR_UNDEF_DATA
	word	offset undefParityErr		;ERR_UNDEF_PARITY
	word	offset undefStopErr		;ERR_UNDEF_STOP
	word	offset undefDuplexErr		;ERR_UNDEF_DUPLEX
	word	offset undefTermErr		;ERR_UNDEF_TERM
	word	offset undefPortErr		;ERR_UNDEF_PORT
	word	offset undefStrErr		;ERR_UNDEF_STR
	word	offset undefNumErr		;ERR_UNDEF_NUM
	word	offset undefCharErr		;ERR_UNDEF_CHAR
	word	offset undefLabelErr		;ERR_UNDEF_LABEL
	word	offset noGotoErr		;ERR_NO_GOTO
	word	offset noMemAbortErr		;ERR_NO_MEM_ABORT
	word	offset abortTransErr		;ERR_NO_MEM_TRANS_OBJ
	word	offset noMemFSMErr		;ERR_NO_MEM_FSM
	word	offset noMemFTransErr		;ERR_NO_MEM_FTRANS
	word	offset comOpenErr		;ERR_COM_OPEN
	word	offset comMissingErr		;ERR_COM_MISSING
NRS <	word	offset noComErr			;ERR_NO_COM		>
	word	offset noLabelErr		;ERR_NO_LABEL
	word	offset useSerialDrErr		;ERR_USE_SERIAL_DR
	word	offset missingStrErr		;ERR_MISSING_STR
	word	offset badScriptMacroErr	;ERR_BAD_SCRIPT_MACRO
	word	offset matchTableFullErr	;ERR_MATCH_TABLE_FULL
	word	offset fileOpenSharingDeniedErr	;ERR_FILE_OPEN_SHARING_DENIED
	word	offset fileNewWriteProtectedErr	;ERR_FILE_NEW_WRITE_PROTECTED
if INPUT_OUTPUT_MAPPING
	word	offset inputOutputMapErr	;ERR_INPUT_OUTPUT_MAP_ERROR
endif
	word	offset remoteCanErr		;ERR_REMOTE_CAN
if	_MODEM_STATUS 
	word	offset connectModemInitErr	;ERR_CONNECT_MODEM_INIT_ERROR
	word	offset connectDatarecInitErr	;ERR_CONNECT_DATAREC_INIT_ERROR
	word	offset connectNoPhoneNumErr	;ERR_CONNECT_NO_PHONE_NUM
	word	offset connectTempErr		;ERR_CONNECT_TEMP_ERROR
if	_TELNET
	word	offset connectProviderErr	;ERR_CONNECT_PROVIDER_ERROR
	word	offset connectTempErr		;ERR_RESOLVE_ADDR_ERROR
else
	word	offset connectBusyErr		;ERR_CONNECT_BUSY
endif	; _TELNET
	word	offset connectRingErr		;ERR_CONNECT_RING
	word	0				;ERR_CONNECT_NOT_CONNECT
	word	offset connectGeneralErr	;ERR_CONNECT_GENERAL_ERROR
	word	offset connectTimeoutErr	;ERR_CONNECT_TIMEOUT

endif	; _MODEM_STATUS

if	_TELNET
	word	offset ipaddrParseErr		;ERR_IP_ADDR
	word	offset noInternetAccessErr	;ERR_NO_INTERNET_ACCESS
	word	offset noAccpntUsernameErr	;ERR_NO_USERNAME
	word	offset authFailedErr		;ERR_AUTH_FAILED
	word	0				;ERR_LINE_BUSY
	word	0				;ERR_NO_ANSWER
	word	offset connectDialErr		;ERR_DIAL_ERROR
	word	offset appProviderErr		;ERR_CONNECT_REFUSED
endif

if	_TELNET
	word	offset closeDomainFailedErr	;ERR_CLOSE_DOMAIN_FAILED
endif	; _TELNET

ERROR_STRING_TABLE_LENGTH	equ (($-(offset errorTable))/(size word))


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermUserStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up and call UserStandardDialog

CALLED BY:	GLOBAL

PASS:		ax - CustomDialogBoxFlags
		di:bp = error string
		cx:dx = arg 1
		bx:si = arg 2

RETURN:		ax = InteractionCommand response

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermUserStandardDialog	proc	far

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
				; params on stack
	call	UserStandardDialog
	ret
TermUserStandardDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts dx to null terminated ascii string

CALLED BY:	

PASS:		dx	- value to convert	
		es:di	- buffer for ascii string		

RETURN:		es:di	- null terminated ascii string

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BinToAscii	proc 	far
	mov	ax, dx
	push  bx, cx, dx
	mov     bx, 10                          ;print in base ten
	clr     cx
nextDigit:
	clr     dx
	div     bx
SBCS <	add     dl, '0'                         ;convert to ASCII	>
DBCS <	add     dx, '0'                         ;convert to ASCII	>
	push    dx                              ;save resulting character
	inc     cx                              ;bump character count
	tst     ax                              ;check if done
	jnz     nextDigit                   	;if not, do next digit
nextChar:
	pop     ax                              ;retrieve character (in AL)
SBCS <	stosb                                   ;stuff in buffer	>
DBCS <	stosw                                   ;stuff in buffer	>
	loop    nextChar                    	;loop to stuff all
SBCS <	clr     al							>
DBCS <	clr     ax							>
SBCS <	stosb                                   ;null-terminate it	>
DBCS <	stosw                                   ;null-terminate it	>
	pop bx, cx, dx
	ret
BinToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a file handle

CALLED BY:	FileRecvStart,  FileStartSend

PASS:		si	- text object to get filename from
		cx      - FILE_OVERWRITE
			(if existing files should be overwritten)

		dx	- handle of resource containing text object
		
RETURN:		C	- set if error opening/creating file
			(will display system err message for std file err).
			- clear if file handle okay 
		bx	 (opened) file handle for disk operations

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileHandle	proc 	far
	push	ds				;save ptr to instance data
	push	cx				;save file append flag
	call	GetFileName			;get file name (ds:dx)
	pop	cx
	;
	; first save away download directory for file-change stuff after
	; download
	;
	push	ds, si, bx, cx
	GetResourceSegmentNS	dgroup, ds, TRASH_BX
	mov	si, offset downloadDirectory
	mov	cx, PATH_BUFFER_SIZE
	call	FileGetCurrentPath		; save pathname
	mov	ds:[downloadDiskHandle], bx	; save disk handle
	pop	ds, si, bx, cx
openFile:
	;
	; then open file
	;
	mov	al, (mask FFAF_RAW) or FILE_ACCESS_RW or FILE_DENY_W
	call	FileOpen			;open file to write to
	jnc	fileOpened			;if file exists continue
	cmp	ax, ERROR_FILE_NOT_FOUND	;else can we create it?
	jne	error
	mov	ah, (mask FCF_NATIVE) or FILE_CREATE_TRUNCATE 
	mov	al, FILE_ACCESS_RW or  FILE_DENY_W
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate			;else create it
	jc	reportUnknownError		; no notification if error
	push	cx, si, es, di
	mov	si, dx				; ds:si = filename created
	mov	cx, FILE_CHANGE_FILE_NAME_BUFFER_LENGTH
	GetResourceSegmentNS	fileChangeFileName, es
	mov	di, offset fileChangeFileName
SBCS <	rep movsb				; copy name into buffer	>
DBCS <	rep movsw				; copy name into buffer	>
	pop	cx, si, es, di
	call	MemFree				;free block with filename
	mov	bx, ax				;put file handle in bx
	jmp	short flagOk

fileOpened:
	call	MemFree
	mov	bx, ax				;pass file handle in bx
	cmp	cx, FILE_OVERWRITE		;if we're overwriting 
	jne	20$				;  the file
	clr	cx				;  then truncate the file
	mov	dx, cx				;  to 0 length.
	call	FileTruncate
	jmp	short flagOk

20$:
	mov	al, FILE_POS_END		;point to end of file
	clr	cx				;
	clr	dx				;
	call	FilePos				;
	jmp	short flagOk

error:
	cmp	ax, ERROR_WRITE_PROTECTED	;is this a write protect err?
	je	writeProtect			; yes, handle it
reportUnknownError:
SBCS <	call	ConvertDSDXDOSToGEOS					>
	mov	cx, ds				; cx:dx = filename
	mov	bp, ERR_CREATE_FILE
	push	bx, ds				; save filename block
	GetResourceSegmentNS	dgroup, ds
	call	DisplayErrorMessage
	pop	bx, ds
	jmp	freeAndFlagErr			; else, free filename block
						; then return error

writeProtect:
	mov	bp, ERR_FILE_NEW_WRITE_PROTECTED
SBCS <	call	ConvertDSDXDOSToGEOS		; convert filename DOS->GEOS>
	push	cx				;save overwrite file flag	
	mov	cx, ds				;cx:dx  - file name
	call	DisplayErrorMessage
	pop	cx
	cmp	ax, IC_YES			; 	again then go do it
	jne	freeAndFlagErr			; give up
SBCS <	call	ConvertDSDXGEOSToDOS		; convert back to DOS and...>
	jmp	openFile			; ...try again

						; else...
freeAndFlagErr:
	call	MemFree				; free filename block
flagErr:
	stc
	jmp	short exit
flagOk:
	;
	; Register opened file with IACP.  BX = file handle.
	;
	call	RegisterDocumentFar
	clc

exit:
	pop	ds				;save ptr to instance data
	ret
GetFileHandle	endp


		
if not DBCS_PCGEOS
;
; destructive DOS->GEOS convert
;
; pass:
;	ds:dx = null-terminated filename
; return:
;	filename converted
; destroy:
;	nothing
;
ConvertDSDXDOSToGEOS	proc	far
	;
	; convert filename from DOS character set to GEOS character set for
	; display in error dialog box
	;	(okay to convert in-place as it is thrown away afterwards)
	;
	uses	ax, cx, di, si
	.enter
	mov	si, dx				; ds:si = filename
	clr	cx				; null-terminated
	mov	ax, FILE_MAPPING_DEFAULT_CHAR
	call	LocalDosToGeos
	.leave
	ret
ConvertDSDXDOSToGEOS	endp

;
; destructive GEOS->DOS convert
;
; pass:
;	ds:dx = null-terminated filename
; return:
;	filename converted
; destroy:
;	nothing
;
ConvertDSDXGEOSToDOS	proc	near
	;
	; convert filename from DOS character set to GEOS character set for
	; display in error dialog box
	;	(okay to convert in-place as it is thrown away afterwards)
	;
	uses	ax, cx, di, si
	.enter
	mov	si, dx				; ds:si = filename
	clr	cx				; null-terminated
	mov	ax, FILE_MAPPING_DEFAULT_CHAR
	call	LocalGeosToDos
	.leave
	ret
ConvertDSDXGEOSToDOS	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFileCloseFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send notification of file close

CALLED BY:	FileRecvEnd, EndAsciiRecv, CaptureDone

PASS:		fileChangeFileName - name of file being closed

RETURN:		nothing

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	08/27/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendFileCloseFileChange	proc	far
	ret
SendFileCloseFileChange	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBufToDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       write buffer to disk

CALLED BY:

PASS:           ds:dx   - buffer to write from
		cx      - number of bytes to write 
		bp      - file handle
		es	- dgroup

RETURN:		C	- set if error and ds->dgroup
			- clear if file write okay (ds unchanged)

DESTROYED:      ax, cx, dx, di, ds

PSEUDO CODE/STRATEGY:
		write passed buffer to disk
		display error message if file write dorked

KNOWN BUGS/SIDE EFFECTS/IDEAS:



REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dennis  12/13/89        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBufToDisk proc    far

EC <	call	ECCheckES_dgroup					>

	;
	; We'll first compare the file handle to BOGUS_VAL.  If
	; they're equal, ie. the other thread for some reason has
	; already closed the file, thus invalidating the file handle.
	; 6/15/95 - ptrinh
	;
	cmp	bp, BOGUS_VAL
	je	done				; CF clear, not an error

	push	si, bp				;save file handle
	clr     al
	mov	bx, bp				;transfer file Handle
	call    FileWrite
	jc      error
	jmp     short exit
error:
	segmov  ds, es, bp
	mov     bp, ERR_DISK_WRITE
	call 	DisplayErrorMessage
	stc					;flag error
exit:
	pop	si, bp				;restore file handle
done:
	ret
WriteBufToDisk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDisplayCounter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       update the value on text displaynumber 

CALLED BY:      

PASS:           ds, es  - dgroup
		es:di	- buffer
		si	- text object
		dx	- variable to display
		bp	- handle of text object
RETURN:

DESTROYED:	ax, bx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dennis  12/13/89        Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateDisplayCounter	proc    far
	push	cx
	push	bp				;save handle to resource
	mov     bp, di
	call	BinToAscii			;es:di->character buffer
	mov     dx, es                          ;dx:bp->ascii string
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR         	;set the text
	clr     cx                              ;null-terminated string
	pop	bx				;get resource handle
	mov     di, mask MF_FORCE_QUEUE
	call    ObjMessage
	pop	cx
	ret
UpdateDisplayCounter	endp	

UpdateDisplayCounterNow	proc    far
	push	cx
	push	bp				;save handle to resource
	mov     bp, di
	call	BinToAscii			;es:di->character buffer
	mov     dx, es                          ;dx:bp->ascii string
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR         	;set the text
	clr     cx                              ;null-terminated string
	pop	bx				;get resource handle
	mov     di, mask MF_CALL
	call    ObjMessage
	pop	cx
	ret
UpdateDisplayCounterNow	endp	

UpdateNoDupCounter	proc    far
	push	cx
	push	bp				;save handle to resource
	mov     bp, di
	call	BinToAscii			;es:di->character buffer
	mov     dx, es                          ;dx:bp->ascii string
	mov     ax, MSG_VIS_TEXT_REPLACE_ALL_PTR         	;set the text
	clr     cx                              ;null-terminated string
	pop	bx				;get resource handle
	mov     di, mask MF_FORCE_QUEUE
	call    ObjMessage
	pop	cx
	ret
UpdateNoDupCounter	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a file name from text object

CALLED BY:	FileStartSend

PASS:		si	-  text object to get filename from
		dx	-  handle of resource containing the text object
		
RETURN:		ds:dx	-  file name from text object
				(in DOS code page)
		bx	-  handle of block with filename
		C	-  set if filename dorked

DESTROYED:	ax, cx, dx, di, ds, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileName	proc 	far
	mov	bx, dx				;pass the handle 
	clr	dx				;flag no buffer allocated
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	bx, cx				;lock the filename block
	tst	ax				;if filename block empty
	jnz	gotName
	call	MemFree
	mov	bp, ERR_NO_FILE			;then no text selected
	call	DisplayErrorMessage
	stc					;flag error
	jmp	short exit
gotName:
	call	MemLock
	mov	ds, ax				;ds:dx ->filename	
	clr	dx				;
SBCS <	call	ConvertDSDXGEOSToDOS		; convert to DOS char set>
	clc					;flag no error
exit:
	ret
GetFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads file into a buffer

CALLED BY:	ProcessTermcap, ScriptRunFile

PASS:		bp:dx	- filename to open
	
RETURN:		ax	- buffer segment
		bx	- buffer handle
		cx	- file size
		C	- set if error

DESTROYED:	ax, bx, di, si, bp

PSEUDO CODE/STRATEGY:
		(swiped from brianc's notepad code)	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		since this routine returns a locked buffer it should not 
		be passed with a file that is too big.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadFile	proc	far
	call	GetFileSize			;return filesize in ax
	tst	ax				;
	jnz	5$				;
	mov	ax, cx				;if error, then pass error code
	jmp	short LTF_exit
5$:
	cmp	ax, FILE_SIZE_MAX		;
	ja	LTF_exit			;set error flag
10$:
	push	ax				;
	mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
						;block type flags
						;allocation method flags
						; (zero init to ensure script
						;	is null-term'ed)
	mov	ch, mask HAF_LOCK or mask HAF_ZERO_INIT
	add	ax, PACKET_1K			;add room to file for padding
						;	characters
	call	MemAlloc			;allocate a buffer for file
						;returns ax = buffer segment
						;	 bx = buffer handle
	pop	cx				;restore low word of file size 
						;(dx:cx)
	jc	LTF_exit			;if MemAlloc error, exit
	push	es
	mov	es, ax				;set es:di to buffer	
	clr	di				;
	call	LoadBuffer			;load text into buffer
						;pass bp:dx - filename
						;     es:di - buffer	
						;     cx    - number of bytes
	pop	es
	clc
	jmp	short done
LTF_exit:
	stc					;flag error
done:
	ret
LoadFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoTermDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change directories

CALLED BY:	ProcessTermcap

PASS:		cx	- standard directory to change to
		ds:dx	- specific directory to go into
	
RETURN:		

DESTROYED:	bp	

PSEUDO CODE/STRATEGY:
		Goto to directory 
		if TERM subdirectory does not exist 
			make it
		Go down into directory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 1/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GotoTermDir	proc	far
	mov	ax, cx
	call	FileSetStandardPath		;change to general directory
	clr	bx				;specify default disk
	call	FileSetCurrentPath		;does specific dir exists?
	jnc	exit				;yes
	call	FileCreateDir			;nope, create it
	jnc	intoSpecific			;no errors on creating dir
	mov	cx, ds				;cx:dx - pass name of directory
	mov	bp, ERR_MAKE_TERM_DIR		;couldn't make TERM directory
	;parameter is hardwired and doesn't need DOS->GEOS conversion
	call	DisplayErrorMessage		;  buggin out
	jmp	short exit
intoSpecific:
	clr	bx				;specify default disk
	call	FileSetCurrentPath		;descend into specific dir
exit:
	ret
GotoTermDir	endp



if 0	; not used

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAppendFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When write to file should append or overwrite

CALLED BY:	ScreenScrollBufSave, FileReceiveStart

PASS:		
		si	- non exclusive entry to check
	
RETURN:		cx	- FILE_OVERWRITE or FILE_APPEND

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckAppendFile	proc	far
	push	di
	mov	ax, MSG_GEN_LIST_ENTRY_GET_STATE		;check if file overwrite set
	GetResourceHandleNS TransferUI, bx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	cx, mask LES_ACTUAL_EXCL
	jnz	overwrite				;if set 
	mov	cx, FILE_APPEND
	jmp	short exit
overwrite:
	mov	cx, FILE_OVERWRITE
exit:
	pop	di
	ret	
CheckAppendFile	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TableSeach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Check if one string is inside another

CALLED BY:      DoCommand

PASS:         	es:di		- sub string (white space delimited)
		ds:si		- search string
		cx		- end of search string
		dx		- alternate word delimeter

RETURN:         C		- set if string not found
		es:di		- points at start of sub string

		C		- clear if string found
		es:di		- points one past end of sub string
		ds:si		- points one past where the string was found

DESTROYED: 	bx, bp

PSEUDO CODE/STRATEGY:
		Check if substring (macro) is in search string (macro table).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TableSearch	proc	far
	clr	bx
	mov	bp, di				;save ptr to start of word
nextSub:
SBCS <	mov	al, es:[di]			;get char of substring	>
DBCS <	mov	ax, es:[di]			;get char of substring	>
SBCS <	cmp	al, dl				;is substring done	>
DBCS <	cmp	ax, dx				;is substring done	>
	je	last
SBCS <	cmp	al, CHAR_SPACE			;is substring done	>
DBCS <	cmp	ax, CHAR_SPACE			;is substring done	>
	je	last
SBCS <	cmp	al, CHAR_TAB			;is substring done	>
DBCS <	cmp	ax, CHAR_TAB			;is substring done	>
	je	last
SBCS <	cmp	al, CHAR_CR			;is substring done	>
DBCS <	cmp	ax, CHAR_CR			;is substring done	>
	je	last				;yes
nextSearch:
SBCS <	cmp	al, ds:[si]			;does chars match	>
DBCS <	cmp	ax, ds:[si]			;does chars match	>
	jne	next				;no, 
	inc	si				;adv search sting ptr
DBCS <	inc	si							>
	inc	di				;adv sub string ptr
DBCS <	inc	di							>
	jmp	short nextSub
last:
SBCS <	cmp	{byte} ds:[si], CHAR_NULL	;if word terminated	>
DBCS <	cmp	{wchar} ds:[si], CHAR_NULL	;if word terminated	>
	je	done				;then match done
next:						;else match is dorked	
	inc	si				;goto to end of word
DBCS <	inc	si							>
SBCS <	cmp	{byte} ds:[si], CHAR_NULL				>
DBCS <	cmp	{wchar} ds:[si], CHAR_NULL				>
	jne	next
	inc	si				;get ptr to next word
DBCS <	inc	si							>
	mov	bl, ds:[si]
	add	si, bx				;offset to next word
	cmp	si, cx				;if at end of table
	jae	notFound			;	exit
	mov	di, bp				;reset sub string
SBCS <	mov	al, es:[di]			;get char of substring	>
DBCS <	mov	ax, es:[di]			;get char of substring	>
	jmp	short nextSearch
notFound:
	mov	di, bp				;reset to start of string
	stc					;set error flag
	jmp	short exit
done:
	add	si, STR_INFO_OFFSET		; point past null terminator
	clc		
exit:
	ret
TableSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if token is a valid number in the current number system

CALLED BY:	HandleEscape, CheckFSMState

PASS:		cl		- token to check
		es:[inputBase]	- number system to use (OCTAL, DECIMAL, HEX)

RETURN:		C		- clear if a number
				- set if not

DESTROYED:	cl

PSEUDO CODE/STRATEGY:
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Name	Date		Description
	----	----		-----------
	dennis	09/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
CheckIfNum	proc	far
	cmp	cl, "0"			;char not a number
	jl	CIN_NotNum
	cmp	es:[inputBase], OCTAL	;check high bound for octal number
	jne	CIN_DECorHEX
	cmp	cl, "7"
	jmp	short CIN_checkNum
CIN_DECorHEX:
	cmp	cl, "9"			;cmp the number
	jle	CIN_IsNum		;if < 9 then DEC or HEX its a number
	cmp	es:[inputBase], DECIMAL	;its > 9, if DEC base then not number
	je	CIN_NotNum
	cmp	cl, "a"			;we're in HEX mode is the char
	jl	CIN_NotNum		;  between "a" and "f"
	cmp	cl, "f"			
CIN_checkNum:
	jl	CIN_IsNum		;set the return codes
	jmp	short CIN_NotNum
CIN_NotNum:
	stc
	jmp 	short CIN_ret
CIN_IsNum:
	clc 
CIN_ret:
	ret
CheckIfNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDecNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts decimal ascii number to a hex value

CALLED BY:	GetFunction

PASS:		ds:si		- beginning of string
		es:[inputBase]	- number system (DECIMAL, OCTAL, HEX)

RETURN:		ax	- number converted
			  0ffh	if error
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
		For each character			
		get value curChar - "0"
		multiply current number by 10
		add in value

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* lets just assume its a decimal number, kay? *

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	09/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
ConvertDecNumber	proc	far	
	clr	ax				;clear out the number
	clr	cx
	mov	bx, DECIMAL_BASE
CAD_loop:
	mov	cl, ds:[si]			;get ascii number to covert  
	cmp	cl, CHAR_CR			;if at end of line then
	jz	CAD_ret				;	done, exit
	call	CheckIfNum			;is it a number?
	jc	CAD_error			;no, signal error 
	push	dx
	mul	bx				;shift the number one digit 
	pop	dx				; ignore overflow
	sub	cl, "0"				;yes, convert it
	add	ax, cx				;and add in the new digit
	inc	si				;get next digit
	jmp	short CAD_loop	
CAD_error:
	mov	ax, ERROR_FLAG
CAD_ret:
	ret
ConvertDecNumber	endp

if DBCS_PCGEOS
ConvertDecNumberDBCS	proc	far	
	clr	ax				;clear out the number
	clr	cx
	mov	bx, DECIMAL_BASE
CAD_loop:
	mov	cx, ds:[si]			;get ascii number to covert  
	cmp	cx, CHAR_CR			;if at end of line then
	jz	CAD_ret				;	done, exit
	tst	ch
	jnz	CAD_error
	call	CheckIfNum			;is it a number?
	jc	CAD_error			;no, signal error 
	push	dx
	mul	bx				;shift the number one digit 
	pop	dx				; ignore overflow
	sub	cl, "0"				;yes, convert it
	add	ax, cx				;and add in the new digit
	inc	si				;get next digit
	inc	si
	jmp	short CAD_loop	
CAD_error:
	mov	ax, ERROR_FLAG
CAD_ret:
	ret
ConvertDecNumberDBCS	endp
endif

if	not _TELNET
	;
	; Telnet appl's Telnet module has the SendChar and SendBuffer which
	; performs the same functions.
	;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       send character out com port

CALLED BY:      DoDial

PASS:         	cl	- char to write 
		ds	- dgroup

		(character in BBS code page)

RETURN:        	C	- set if couldn't write out the character
				(because com port not opened)

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendChar	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	mov     bx, ds:[serialPort]             ;set serial port
	cmp	bx, NO_PORT
	jne	doWrite
	clr	cx				;flag that cx should be stuffed
	push	dx, bp
	mov	dx, offset sendCharErr		;  with Strings resource
	mov	bp, ERR_NO_COM
	CallMod	DisplayErrorMessage
	pop	dx, bp
	stc					;flag error
	jmp	short exit
doWrite:
	push	di				;save ptr to macro file
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE_BYTE		;write out the character
	pop	di
	clc					;clear error flag
exit:
	.leave
	ret
SendChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       send buffer out com port

CALLED BY:      DoDial

PASS:         	es:si	- buffer to write from
		ds	- dgroup
		cx	- number of chars to write

		(characters in BBS code page)

RETURN:        	es:si	- points past the text that was written out 
		C	- set if couldn't send the buffer  
				(the error we're checking for is if no 
				com port is opened).

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Can't make the buffer to write out es:di, because di is passed
		in the serial write routine.

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendBuffer	proc	far	uses ax, bx, cx, dx, es, di, ds, bp
	clc
	jcxz	noChars
	.enter					;save ptr into macro file
	mov     bx, ds:[serialPort]             ;set serial port
	cmp	bx, NO_PORT
	jne	doWrite
	clr	cx				;flag that cx should be stuffed
	mov	dx, offset sendBufErr		;  with Strings resource
	mov	bp, ERR_NO_COM
	CallMod	DisplayErrorMessage
	stc					;set error flag	
	jmp	short exit
doWrite:

	push	ds				; xchg ds, es
	push	es
	pop	ds
	pop	es
	
	;
	; In Responder, we don't want to block if there is not enough to send
	; data so that we can allow redraw to happen.
	;
RSP <	mov	ax, STREAM_NOBLOCK					>
NRSP <	mov	ax, STREAM_BLOCK		;ok to block if not all fits>
	CallSer	DR_STREAM_WRITE, es		;write out the buffer
	add	si, cx				; point si past end
	clc					;clear error flag
exit:
	.leave
noChars:
	ret
SendBuffer	endp
endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferedSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send buffer of characters out with a delay after each line
		or after a small number of characters

CALLED BY:	EXTERNAL
			TermSendChat
			PasteTransferItem

PASS:		ds - dgroup
		es:si - buffer to send
		cx - number of characters to send

		(characters are in GEOS character set)

RETURN:		C - set if couldn't send the buffer
			(no com port opened - reported)
			(not enough memory - reported)
			(buffered send going already - not reported)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BufferedSendBuffer	proc	far
	uses	ax, bx, cx, dx, si, di, bp, es
	clc
	jcxz	noChars
	.enter
	tst	ds:[bufferedSendBuf]	; is there a buffered send in progress?
	stc				; assume error, indicate error
	jnz	doneJMP			; yes, exit with error
	;
	; create local work buffer for characters to send
	;
	push	cx			; save number of bytes
	mov	ax, cx			; ax = size of buffer
if DBCS_PCGEOS
	;
	; allow for 2 byte (1 word) - to - 5 byte expansion
	;
	mov	cx, ax
	shl	ax, 1			; *2
	jc	memError
	shl	ax, 1			; *4
	jc	memError
	add	ax, cx			; *5
	jc	memError
	mov	dx, ax			; dx = allocated buffer size
endif
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
DBCS <memError:								>
	pop	cx			; restore buffer size
	jnc	noError
	mov	bp, ERR_NO_MEM_TRANS_OBJ
	call	DisplayErrorMessage
	stc				; indicate error
doneJMP:
	jmp	done

noChars:
	ret			; <-- EXIT HERE ALSO

noError:
	;
	; copy buffer to send into a local work buffer
	;
	mov	ds:[bufferedSendBuf], bx	; save buffer handle
	mov	ds:[bufferedSendSize], cx	; save size of buffer
SBCS <	mov	bx, ds:[bbsCP]		; bx = destination code page	>
DBCS <	mov	bx, ds:[bbsSendCP]	; bx = destination code page	>
	push	ds			; save dgroup
	segmov	ds, es			; ds:si = buffer to send
	mov	es, ax			; es:di = new buffer
if DBCS_PCGEOS
	mov	di, dx			; es:di = past end of buffer
	sub	di, cx			; es:di = end part of buffer
	sub	di, cx
	mov	dx, di			; save offset of GEOS chars
else
	clr	di
endif
	push	cx
SBCS <	rep movsb			; copy into new buffer		>
DBCS <	rep movsw			; copy GEOS into end part of buffer>
	;
	; convert new buffer from GEOS code page to BBS code page
	;
if DBCS_PCGEOS
	mov	ds, ax
	mov	si, dx			; ds:si = GEOS at end part of buffer
	mov	es, ax
	clr	di			; es:di = BBS at beginning of buffer
	pop	cx
	mov	ax, MAPPING_DEFAULT_CHAR
	clr	dx
	call	LocalGeosToDos		; cx = new size of text
	pop	ds
EC <	WARNING_C	SEND_CONVERSION_ERROR				>
	jc	convErr			; error converting
	mov	ds:[bbsSendCP], bx	; update in case JIS
	mov	ds:[bufferedSendSize], cx
else
	mov	ds, ax			; ds:si = new buffer
	clr	si
	pop	cx			; cx = size of buffer
	mov	ax, MAPPING_DEFAULT_CHAR
	call	LocalGeosToCodePage
if INPUT_OUTPUT_MAPPING
	call	OutputMapBuffer
endif

	pop	ds			; restore dgroup
endif
	mov	bx, ds:[bufferedSendBuf]	; unlock new buffer
	call	MemUnlock
	mov	ds:[bufferedSendDone], FALSE
	clr	ds:[bufferedSendOffset]	; send from start of buffer
if DBCS_PCGEOS	;-------------------------------------------------------------
	mov	ax, ds:[bbsRecvCP]
	mov	ds:[bufferedSendCP], ax
	call	StartEcho
endif	;---------------------------------------------------------------------
	call	BufferedSend
					; return error
done:
	.leave
	ret

if DBCS_PCGEOS
convErr:
	clr	bx
	xchg	bx, ds:[bufferedSendBuf]
	call	MemFree
	jmp	short done
endif

BufferedSendBuffer	endp

;
; pass:
;	ds - dgroup
;	ds:[bufferedSendDone] - TRUE if buffer is completely sent
;	ds:[bufferedSendBuf] - handle of buffer to send
;	ds:[bufferedSendOffset] - offset into buffer of chars to send
;	ds:[bufferedSendSize] - number of chars in buffer to send
;	(characters in BBS code page)
; return:
;	carry set on error
; destroys:
;	ax, bx, cx, dx, si, di, bp
;
BufferedSend	proc	far
	uses	es
	.enter
	mov	dx, ds:[bufferedSendSize] ; get # chars to send
	mov	bx, ds:[bufferedSendBuf]
	tst	bx
	LONG jz	done
	call	MemLock
	;
	; note that for DBCS, we don't the encoding format of the text we
	; are scanning, so we could end up finding a CHAR_CR that is really
	; part of a two-byte character -- we don't care, we'll get the stuff
	; sent correctly anyway - brianc 2/11/94
	;
	mov	es, ax
	mov	di, ds:[bufferedSendOffset] ; es:di = start of buffer to send
	mov	si, di			; es:si = buffer (for SendBuffer)
	mov	cx, dx			; cx = # chars to scan
	mov	al, CHAR_CR
	repne scasb			; search for end of line
	je	sendLine		; if found, send line
	;
	; no CR found, try to send rest of packet
	;
	mov	cx, ds:[bufferedSendSize] ; cx = # chars to write
	clr	dx			; no chars left in packet
	cmp	cx, MAX_NUM_BUFFERED_SEND_CHARS	; too many chars to write?
	ja	sendPartial		; yes, send partial buffer
	jmp	short sendNow		; else, send entire buffer

sendLine:
	xchg	cx, dx
	sub	cx, dx			; cx = # chars to write
					; dx = # chars left in buffer
sendPartial:
	mov	ax, MAX_NUM_BUFFERED_SEND_CHARS
	cmp	cx, ax			; more than we should send at once?
	jbe	sendNow			; nope, send them all
	xchg	ax, cx
	sub	ax, cx			; ax = # chars too many
	add	dx, ax			; add back into # chars left in buffer
	sub	di, ax			; adjust back offset to rest of buffer
sendNow:
	push	si, cx			; save offset and count for half duplex
	call	SendBuffer		; send partial buffer
	pop	bp, cx			; restore offset and count
	jc	freeBuf			; if error, free buffer and exit
	;
	; if in half duplex mode, send buffer to screen object also
	;
	cmp	ds:[halfDuplex], TRUE	; half duplex?
	jne	afterHalfDuplex		; nope
	push	dx, di			; save # chars left and offset
	mov	dx, es			; dx:bp = buffer, cx = # chars
;;	mov	ax, MSG_READ_BUFFER
;;	mov	bx, ds:[threadHandle]
;;	mov	di, mask MF_FORCE_QUEUE
;;	call	ObjMessage
;;block will not be around when this method is handled
	call	SendMethodReadBlock
;;
	pop	dx, di			; restore # chars left and offset
afterHalfDuplex:

	tst	dx			; any chars left?
	mov	ds:[bufferedSendDone], TRUE	; assume not
	jz	doneWithBuffer		; all chars sent, (carry clear)
	mov	ds:[bufferedSendDone], FALSE
	mov	ds:[bufferedSendOffset], di	; save offset to rest of buffer
	mov	ds:[bufferedSendSize], dx ; save # chars left in buffer to send
	;
	; send method off timer to handle rest of buffer
	;
	mov	bx, ds:[bufferedSendBuf]
	call	MemUnlock		; unlock buffer
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[termProcHandle]
	mov	cx, ONE_SECOND/4
	mov	dx, MSG_BUFFERED_SEND
	call	TimerStart
	clc				; indicate no error
	jmp	short done
	;
	; characters in buffer have all been sent, free buffer
	;
doneWithBuffer:
	clc				; indicate no error
freeBuf:
	pushf				; save error status
if DBCS_PCGEOS	;-------------------------------------------------------------
	mov	ax, ds:[bufferedSendCP]	; ax = desired CP
	call	EndEcho
endif	;---------------------------------------------------------------------
	clr	bx
	xchg	bx, ds:[bufferedSendBuf]
	call	MemFree			; preserves flags
	popf				; retreive error status
done:
	.leave
	ret
BufferedSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMethodReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create buffer and send MSG_READ_BLOCK to serial thread

CALLED BY:	EXTERNAL
			half duplex handling
				BufferedSend
				SendAsciiPacket

PASS:		ds = dgroup
		dx:bp = buffer of text
		cx = size of buffer

		(characters are in BBS code page)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMethodReadBlock	proc	far
	uses	ax, bx, cx, dx, si, di, es, bp
	jcxz	exit
	.enter
	push	ds			; save dgroup
	push	cx
	mov	ax, cx			; ax = size of buffer
DBCS <	add	ax, 8			; room for two escapes added below>
	mov     cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax			; es:di = new buffer
	clr	di
if 0
if DBCS_PCGEOS	;-------------------------------------------------------------
	;
	; maintain current bbsRecvCP by switching into mode of passed text
	; (i.e. bbsSendCP) and then switching back
	;	ds = dgroup
	;
	mov	ax, ds:[bbsSendCP]	; ax = desired CP
	cmp	ax, ds:[bbsRecvCP]
	stc				; assume no escape inserted
	je	noStartEscape		; already set
	call	insertEscape		; carry clear if escape inserted
noStartEscape:
endif	;---------------------------------------------------------------------
endif
	mov	ds, dx			; ds:si = original buffer
	mov	si, bp
	pop	cx			; size of buffer
	push	cx			; save again
	rep movsb			; copy buffer
	pop	cx			; cx = size of buffer
	pop	ds			; restore dgroup
if 0
if DBCS_PCGEOS	;-------------------------------------------------------------
	jc	noStart			; carry set from above if no escape
	add	cx, 3			; add size of start escape
noStart:
	;
	; escape back to bbsRecvCP
	;
	mov	ax, ds:[bbsRecvCP]	; ax = desired CP
	cmp	ax, ds:[bbsSendCP]
	je	noEnd			; no changed at start
	call	insertEscape
	jc	noEnd
	mov	ax, 0			; add null to force escape to be used
	stosw
	add	cx, 5			; add size of end escape + null word
noEnd:
endif	;---------------------------------------------------------------------
endif
	call	MemUnlock
	mov	dx, bx			; dx = handle of new buffer

if	_TELNET
	PrintMessage <"Not Sent MSG_READ_BLOCK message to serial thread">
else
	mov	ax, MSG_READ_BLOCK
	mov	bx, ds:[threadHandle]	; bx = handle of serial thread
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif	; _TELNET

	.leave
exit:
	ret

if 0
if DBCS_PCGEOS	;-------------------------------------------------------------
insertEscape	label	near
	cmp	ax, CODE_PAGE_JIS
	je	toSingle		; (carry clear)
	cmp	ax, CODE_PAGE_JIS_DB
	je	toDouble		; (carry clear)
	stc				; indicate no escape added
	retn

toDouble:
	mov	ax, JIS_ESCAPE_TO_DOUBLE_1 or (JIS_ESCAPE_TO_DOUBLE_2 shl 8)
	stosw
	mov	al, JIS_ESCAPE_TO_DOUBLE_3
	stosb
	retn

toSingle:
	mov	ax, JIS_ESCAPE_TO_SINGLE_1 or (JIS_ESCAPE_TO_SINGLE_2 shl 8)
	stosw
	mov	al, JIS_ESCAPE_TO_SINGLE_3
	stosb
	retn
endif	;---------------------------------------------------------------------
endif
SendMethodReadBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSingleByteEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send ESCAPE to single byte mode if in JIS DB mode

CALLED BY:	DoSend

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
SendSingleByteEscape	proc	far
	uses	ax, cx, si, ds, es
	.enter
	GetResourceSegmentNS	dgroup, ds, ax
	cmp	ds:[bbsSendCP], CODE_PAGE_JIS_DB
	jne	done
	segmov	es, ds, ax
	mov	si, offset singleByteEscape
	mov	cx, 3			; 3 bytes
	call	SendBuffer
	mov	ds:[bbsSendCP], CODE_PAGE_JIS
done:
	.leave
	ret
SendSingleByteEscape	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartEcho, EndEcho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start/end echoing by sending escape sequence to shift
		into/from CP expected for receive

CALLED BY:	EXTERNAL
			DoAsciiSend/SendAsciiPacket

PASS:		ds - dgroup
		ax (EndEcho) - CP expected for receive

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS ;------------------------------------------------------------
StartEcho	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter
	tst	ds:[halfDuplex]
	jz	noStartEscape
	mov	ax, ds:[bbsSendCP]		; ax = desired CP
	cmp	ax, ds:[bbsRecvCP]
	je	noStartEscape
	mov	cx, 5				; cx = escape + null word
	mov	bp, offset singleByteEscape	; assume to single
	cmp	ax, CODE_PAGE_JIS
	je	sendIt
	mov	bp, offset doubleByteEscape	; assume to double
	cmp	ax, CODE_PAGE_JIS_DB
	jne	sendDone
sendIt:
	mov	dx, ds				; dx:bp = escape sequence
	mov	ax, MSG_READ_BUFFER
	mov	bx, ds:[threadHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
sendDone:
noStartEscape:
	.leave
	ret
StartEcho	endp

EndEcho	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter
	tst	ds:[halfDuplex]
	jz	noEndEscape
	cmp	ax, ds:[bbsSendCP]
	je	noEndEscape
	mov	cx, 5				; cx = escape + null word
	mov	bp, offset singleByteEscape	; assume to single
	cmp	ax, CODE_PAGE_JIS
	je	sendIt
	mov	bp, offset doubleByteEscape	; assume to double
	cmp	ax, CODE_PAGE_JIS_DB
	jne	sendDone
sendIt:
	mov	dx, ds				; dx:bp = escape sequence
	mov	ax, MSG_READ_BUFFER
	mov	bx, ds:[threadHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
sendDone:
noEndEscape:
	.leave
	ret
EndEcho	endp
endif ; DBCS_PCGEOS ------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTermList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in terminal list 

CALLED BY:      DoComm

PASS:         	es	- dgroup
		cl	- terminal type to use
		di	- something we shouldn't trash

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTermList	proc	far
	push	di
	clr	ch
	GetResourceHandleNS	TermList, bx
	mov	si, offset TermList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
SetTermList	endp

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPortList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in com port list 

CALLED BY:      DoPort

PASS:         	es	- dgroup
		cx	- SERIAL_COM[1,2,3,4]
RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPortList	proc	far
	uses	cx
	.enter
	GetResourceHandleNS	ComList, bx
	mov	si, offset ComList
	clr	dx
	inc	cx				; convert to MY_SERIAL_X
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SetPortList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBaudList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set entry in Baud list 

CALLED BY:      DoComm

PASS:         	es	- dgroup
		cx	- baud rate to use

RETURN:		
			
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   2/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBaudList	proc	far
	GetResourceHandleNS	BaudList, bx
	mov	si, offset BaudList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
SetBaudList	endp

endif	; !_TELNET
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       get selected entry in file selector

CALLED BY:      TermMacroOpen

PASS:         	ds	- dgroup
		dx:si	- chunk/offset of file selector

RETURN:		C	- set if no file selected 
				(a directory or volume was selected)
		C	- clear if file selected	
			cx:dx	- name of selected file
			bp	- GenFileSelectorEntryFlags
					GFSEF_LONGNAME
DESTROYED: 

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name    Date            Description
	----    --------	-----------
	dennis   5/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileSelection	proc	far
	push  dx, si				;save address of file selector
	mov	bx, dx				;pass handle of object resource
	mov     ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov     cx, ds                          ;
	mov     dx, offset pathnameBuf          ;cx:dx->path buffer
	mov	di, mask MF_CALL		;
	call	ObjMessage			; ax = entry #
	pop	bx, si				;get address of file selector
	mov     di, bp				;test selection flags to see
	and     di, mask GFSEF_TYPE		;	if file selected
	cmp     di, GFSET_FILE                  ;if selected file
	clc                                     ;  flag got the file
	je      exit                            ;  and exit
	mov     cx, ax                          ;else open up the vol or dir
						; cx = entry #
	mov     ax, MSG_GEN_FILE_SELECTOR_OPEN_ENTRY
	mov	di, mask MF_CALL		;
	call	ObjMessage			;
	stc                                     ;flag no file selected
exit:
	ret
GetFileSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFilePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the path of the selected file in the file selector

CALLED BY:	FileSendStart	

PASS:		ds	- dgroup	
		dx:si	- chunk:offset of file selector

RETURN:		C	- set if path was dorked	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/01/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFilePath	proc 	far
	push	dx				; save OD.handle in case of err
	mov	bx, dx				;bx:si ->gen file selector 
	mov	ax, MSG_GEN_PATH_GET
	mov	di, mask MF_CALL
	mov	dx, ds
	mov	bp, offset filePathBuf		;dx:bp-> buffer to hold path
	mov	cx, size filePathBuf
	call	ObjMessage			;dx:bp=filled, cx=disk handle
	pop	bx				; bx = OD.handle of file sel.
	jc	error
	;handle error here?
	;mov	bx, dx				;check for null path
	;mov	al, {byte} ds:[bx]
	;tst	al
	;jz	error
	mov	bx, cx				;pass disk handle of path
	mov	dx, bp				;ds:dx = path
	call	FileSetCurrentPath		;
	jmp	short exit
error:
	mov	dx, bx				; dx:si = OD of file selector
	call	GetFileSelection
	stc
exit:
	ret
SetFilePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectAllText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all the text in the passed text object

CALLED BY:	InitTerm	

PASS:		dx:si	- chunk:offset of file selector

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectAllText	proc 	far
	mov	bx, dx					;bx:si -> text object
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage	
	ret
SelectAllText	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableFileTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Enable stuff in Transfer Resource that needs a port 
		to be opened

CALLED BY:	

PASS:		ds	- dgroup

RETURN:		

DESTROYED:	ax, bx, dx, bp	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; must be in MenuInterface
;
transStuffTable		label	word
	dw	offset 	MenuInterface:AsciiSubMenu
	dw	offset 	MenuInterface:XModemSubMenu
	dw	offset	MenuInterface:EditSubMenu
transStuffTableEnd	label	word

EnableFileTransfer	proc	far 
	mov	ds:[canPaste], TRUE
	mov     ax, MSG_GEN_SET_ENABLED      ;
	GetResourceHandleNS	MenuInterface, bx
	mov	bp, offset transStuffTable	;
	mov	dx, offset transStuffTableEnd	;
	call	DorkUIStuff
if	not _TELNET
	call	EnableEditAndDial
endif
	ret
EnableFileTransfer	endp

DisableFileTransfer	proc	far 
	mov	ds:[canPaste], FALSE
	mov     ax, MSG_GEN_SET_NOT_ENABLED      ;
	GetResourceHandleNS	MenuInterface, bx
	mov	bp, offset transStuffTable	;
	mov	dx, offset transStuffTableEnd	;
	call	DorkUIStuff
if	not _TELNET
	call	DisableEditAndDial
endif
	ret
DisableFileTransfer	endp

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableModemCmd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Enable stuff in Modem Resource that requires a port 
		be opened

CALLED BY:	

PASS:		ds	- dgroup

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; must be in MenuInterface!
;
modemStuffTable		label	word
	dw	offset 	MenuInterface:ModemBox
modemStuffTableEnd	label	word

EnableModemCmd	proc	far 
	mov     ax, MSG_GEN_SET_ENABLED      ;
	GetResourceHandleNS	MenuInterface, bx
	mov	bp, offset modemStuffTable	;
	mov	dx, offset modemStuffTableEnd	;
	call	DorkUIStuff
	ret
EnableModemCmd	endp

DisableModemCmd	proc	far 
	mov     ax, MSG_GEN_SET_NOT_ENABLED  ;
	GetResourceHandleNS	MenuInterface, bx
	mov	bp, offset modemStuffTable	;
	mov	dx, offset modemStuffTableEnd	;
	call	DorkUIStuff
	ret
DisableModemCmd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableEditAndDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Enable stuff in Interface Resource that requires a port 
		be opened

CALLED BY:	

PASS:		ds	- dgroup

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnableEditAndDial	proc	far 
	GetResourceHandleNS	ChatSend, bx
	mov	si, offset ChatSend
	mov     ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	GetResourceHandleNS	QuickDialTrig, bx
	mov	si, offset QuickDialTrig
	mov     ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
EnableEditAndDial	endp

DisableEditAndDial	proc	far 
	GetResourceHandleNS	ChatSend, bx
	mov	si, offset ChatSend
	mov     ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	GetResourceHandleNS	QuickDialTrig, bx
	mov	si, offset QuickDialTrig
	mov     ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
DisableEditAndDial	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableScripts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable script file selector

CALLED BY:	

PASS:		ax	- method to send to each of the file transfer triggers
         	bx      - resource handle
		bp      - start of object table
		dx      - end of object table

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; must be in MenuInterface
;
macroObjTable		label	word
	dw	offset	MenuInterface:MacroFileBox		;script box
macroObjTableEnd	label	word

EnableScripts	proc 	far
	mov	ax, MSG_GEN_SET_ENABLED  	;enable file transfer triggers 
	GetResourceHandleNS	MenuInterface, bx
	mov     bp, offset macroObjTable   	;
	mov     dx, offset macroObjTableEnd	;
	call	DorkUIStuff
	ret
EnableScripts 	endp

DisableScripts 	proc 	far
	mov	ax, MSG_GEN_SET_NOT_ENABLED  ;enable file transfer triggers 
	GetResourceHandleNS	MenuInterface, bx
	mov     bp, offset macroObjTable   	;
	mov     dx, offset macroObjTableEnd	;
	call	DorkUIStuff
	ret
DisableScripts 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable script file selector

CALLED BY:	

PASS:		ax	- method to send to each of the file transfer triggers
         	bx      - resource handle
		bp      - start of object table
		dx      - end of object table

RETURN:		
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; these must all be in MenuInteface
;
protocolTable		label	word
	dw	offset	MenuInterface:ProtocolBox	;communications box
protocolTableEnd	label	word

EnableProtocol	proc 	far
	mov	ax, MSG_GEN_SET_ENABLED  	;enable protocol box 
	GetResourceHandleNS	MenuInterface, bx
	mov     bp, offset protocolTable   	;
	mov     dx, offset protocolTableEnd	;
	call	DorkUIStuff
	ret
EnableProtocol 	endp

DisableProtocol 	proc 	far
	mov	ax, MSG_GEN_SET_NOT_ENABLED  ;disable protocol box 
	GetResourceHandleNS	MenuInterface, bx
	mov     bp, offset protocolTable   	;
	mov     dx, offset protocolTableEnd	;
	call	DorkUIStuff
	ret
DisableProtocol 	endp
endif	; !_RESPONDER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if file in use

CALLED BY:	

PASS:		ds	- dgroup
		es	- dgroup
		ds:dx	- filename 

RETURN:		C	- clear if file doesn't exists
			- clear if user overwrites existing file
			- clear some other disk error that can be delayed
				(like write-protect)
		C	- set if file already in use
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
		if file in use	
			error
		else if file exists
			ask user if wants to overwrite it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileStatus proc 	far
	mov     al, (mask FFAF_RAW) or FILE_ACCESS_RW or FILE_DENY_W
	call	FileOpen
	jnc	fileExists
	cmp	ax, ERROR_FILE_NOT_FOUND
	je	noError
	cmp	ax, ERROR_SHARING_VIOLATION
;	jne	flagError
;allow other errors to fall through to GetFileHandle - brianc 9/25/90
	jne	noError
inUse:
	mov	bp, ERR_FILE_OPEN_SHARING_DENIED
SBCS <	call	ConvertDSDXDOSToGEOS		; convert filename DOS->GEOS>
	mov	cx, ds				; cx = filename segment
	push	ds
	segmov	ds, es				; ds = dgroup
	call	DisplayErrorMessage
	pop	ds
	jmp	short flagError
fileExists:
	mov	bx, ax				;pass file handle
	mov	al, FILE_NO_ERRORS
	call	FileClose

	mov     bx, es:[stringsHandle]
	call	MemLock
	push	ds
	mov	ds, ax
	mov	di, ax
	mov	bp, offset overwriteText
	mov	bp, ds:[bp]			; di:bp = text
	pop	ds
	mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	call    TermUserStandardDialog
	call	MemUnlock
	cmp     ax, IC_YES			; overwrite?
	je	noError				; yes


flagError:
	stc
	jmp	short exit
noError:	
	clc					;clear error flag
exit:
	ret
CheckFileStatus endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableSaveScroll
		DisableSaveScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Enable/Disable stuff to save scroll buffer
		

CALLED BY:	

PASS:		ss	- dgroup

RETURN:		ds	- fixed up to point at object block

DESTROYED:	ax, bx, dx, bp	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; must be CaptureUI
;
saveScrollTable		label	word
	dw	offset 	CaptureUI:CapScroll
	dw	offset 	CaptureUI:CapScrollAndScreen
saveScrollTableEnd	label	word

EnableSaveScroll	proc	far 
	uses	bp, dx, di, si
	.enter
	mov     ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	CaptureUI, bx
	mov	bp, offset saveScrollTable
	mov	dx, offset saveScrollTableEnd
	call	DorkUIStuff
	.leave
	ret
EnableSaveScroll	endp

DisableSaveScroll	proc	far 
	uses	bp, dx, di, si
	.enter
	mov     ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	CaptureUI, bx
	mov	bp, offset saveScrollTable
	mov	dx, offset saveScrollTableEnd
	call	DorkUIStuff
	.leave
	ret
DisableSaveScroll	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDS_dgroup, ECCheckES_dgroup, ECCheckDS_ES_dgroup

DESCRIPTION:	Error checking routines to make sure we are not fucking up.

PASS:		ds, es	= see below

RETURN:		ds, es	= same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/90		initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckDS_ES_dgroup	proc	far
	push	ax, bx

	mov	ax, es
	GetResourceSegmentNS dgroup, es, TRASH_BX
	mov	bx, es

	cmp	ax, bx
	ERROR_NE TERM_ERROR_ES_NOT_DGROUP_SEGMENT
	mov	es, ax

	mov	ax, ds
	cmp	ax, bx
	ERROR_NE TERM_ERROR_DS_NOT_DGROUP_SEGMENT

	pop	ax, bx
	ret
ECCheckDS_ES_dgroup	endp


ECCheckES_dgroup	proc	far
	push	ax, bx

	mov	ax, es
	GetResourceSegmentNS dgroup, es, TRASH_BX
	mov	bx, es

	cmp	ax, bx
	ERROR_NE TERM_ERROR_ES_NOT_DGROUP_SEGMENT
	mov	es, ax

	pop	ax, bx
	ret
ECCheckES_dgroup	endp

ECCheckDS_dgroup	proc	far
	push	ax, bx

	mov	ax, ds
	GetResourceSegmentNS dgroup, ds, TRASH_BX
	mov	bx, ds

	cmp	ax, bx
	ERROR_NE TERM_ERROR_DS_NOT_DGROUP_SEGMENT
	mov	ds, ax

	pop	ax, bx
	ret
ECCheckDS_dgroup	endp

endif	;end of ERROR_CHECK


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckRunBySerialThread

DESCRIPTION:	Error-checking routine to make sure that we are being run
		by the Serial thread (term:1).

PASS:		ss		stack segment of current thread

RETURN:		ds, es	= same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/90		initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

if	not _TELNET
ECCheckRunBySerialThread	proc	far
	push	ax, bx, es

	GetResourceSegmentNS dgroup, es, TRASH_BX
					;set es = dgroup, trashing bx

	clr	bx			;get handle of current thread
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo
	mov	bx, ax

	cmp	bx, es:[threadHandle]	;compare to handle of Serial thread
	ERROR_NE TERM_ERROR_NOT_RUNNING_IN_SERIAL_THREAD

	pop	ax, bx, es
	ret
ECCheckRunBySerialThread endp
endif	; !_TELNET

endif	;end of ERROR_CHECK

if INPUT_OUTPUT_MAPPING
;----------------------------------------------------------------------------
;
; Routines for input/output mapping
;
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputMapBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map buffer of characters coming from host

CALLED BY:	FSMParseString - input from host FSM/Screen
		WriteAsciiPacket - input from host to disk (capture to file)

PASS:		ds:si - buffer
		cx - # chars in buffer

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputMapBuffer	proc	far
	uses	bx
	.enter
	mov	bx, offset inputMap
	call	MapBufferCommon
	.leave
	ret
InputMapBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputMapBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map buffer of characters to be sent to host

CALLED BY:	SendAsciiPacket - output from disk to host (send ASCII file)
		BuferedSendBuffer - output from misc to host (send chat,
					paste text, arrow keys mapping,
					script's SEND command)

PASS:		ds:si - buffer
		cx - # chars in buffer

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputMapBuffer	proc	far
	uses	bx
	.enter
	mov	bx, offset outputMap
	call	MapBufferCommon
	.leave
	ret
OutputMapBuffer	endp

;
; pass:	ds:si = buffer
;	cx = # chars
;	bx = map offset
;
MapBufferCommon	proc	near
	uses	ax, cx, ds, si, es
	.enter
	GetResourceSegmentNS	dgroup, es
mapLoop:
	lodsb				; al = char in buffer
	xlat	es:[bx]			; map it
	mov	ds:[si]-1, al		; store it back
	loop	mapLoop
	.leave
	ret
MapBufferCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputMapChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map single character to be sent to host

CALLED BY:	ScreenKeyboard - output from keyboard to host (typing)
		StringCopyAndConvert - output from misc to host (building
					script's MATCH command match table)

PASS:		al - character

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputMapChar	proc	far
	uses	ds, bx
	.enter
	GetResourceSegmentNS	outputMap, ds
	mov	bx, offset outputMap
	xlat	ds:[outputMap]
	.leave
	ret
OutputMapChar	endp
endif	; INPUT_OUTPUT_MAPPING


if	_ACCESS_POINT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentAccessPointConnectName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current access point connection name

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if no selection
		carry clear if no error
			cx	= # chars retrieved
			^hbx	= block storing name
DESTROYED:	ds, es may be destroyed if pointing at object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the name from current access point ID;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentAccessPointConnectName	proc	far
		uses	ax, dx, si, di, bp, es
		.enter
	
		GetResourceSegmentNS	dgroup, es
		mov	ax, es:[settingsConnection]
	;
	; Get connection name
	;
		mov	dx, APSP_NAME
		clr	cx, bp			; to allocate block
		call	AccessPointGetStringProperty
						; carry set if error
						; cx<- #chars returned,
						; ^hbx<-str block 
		.leave
		ret
GetCurrentAccessPointConnectName	endp


if	_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentInternetAccessName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current access point connection name

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if no selection
		carry clear if no error
			cx	= # chars retrieved
			^hbx	= block storing name
DESTROYED:	ds, es may be destroyed if pointing at object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the name from current access point ID;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentInternetAccessName	proc	far
		uses	ax, dx, si, di, bp, es
		.enter
	
		GetResourceSegmentNS	dgroup, es
		mov	ax, es:[remoteExtAddr].APESACA_accessPoint
	;
	; Get connection name
	;
		mov	dx, APSP_NAME
		clr	cx, bp			; to allocate block
		call	AccessPointGetStringProperty
						; carry set if error
						; cx<- #chars returned,
						; ^hbx<-str block 
		.leave
		ret
GetCurrentInternetAccessName	endp
	

endif	; _TELNET



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncateLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate the passed name to the desired length.

CALLED BY:	GetCurrentAccessPointConnectName
		GetCurrentInternetAccessName

PASS:		di	= width limit on string
		^lbx	= string block
		cx	= # chars in string
		dx	= TRUE to add ellipsis

RETURN:		cx	= new number of chars

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		If string is too long, place "..." at the desired point 
		in the string and null terminate it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/31/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncateLongName	proc	near
		uses	si, ds
		.enter
	;
	; Calculate number of chars to truncate string to.
	;
		call	MemLock
		mov	ds, ax			
		clr	si			; ds:si = string 
		call	GetTruncateLimit 	; cx = # chars that fit
		jnc	unlock
	;
	; Replace last char with ellipsis before null terminating, if desired.
	;
		mov	si, cx		; ds:si = after last char that fits
DBCS <		shl	si						>

		tst	dx			; need ellipsis?
		jz	nullTerminate

		LocalPrevChar	dssi
		mov	ax, C_ELLIPSIS
		LocalPutChar	dssi, ax
nullTerminate:
		clr	ax			
		LocalPutChar	dssi, ax
unlock:
		call	MemUnlock

		.leave
		ret
TruncateLongName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTruncateLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine number of characters to truncate the string to.

CALLED BY:	TruncateLongName

PASS:		di	= width limit
		cx	= # chars in string
		ds:si	= null-terminated string

RETURN:		carry set if string needs to be truncated
		cx	= # chars that fit

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GrCharWidth on each char in string until limit
			has been exceeded

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 2/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTruncateLimitFar	proc	far
		call	GetTruncateLimit
		ret
GetTruncateLimitFar	endp

GetTruncateLimit	proc	near
		uses	ax, bx, dx, di, si
numChars	local	word		push cx
widthLimit	local	word		push di
		.enter
	;
	; Create a GState.
	;
		clr	bx, di
		call	GrCreateState			; di = gstate handle
	;
	; Go through characters in string adding up width.
	;
addWidth:
		clr	ah
		LocalGetChar	ax, dssi
		call	GrCharWidth			; dx:ah = width

		add	bx, dx
		tst	ah
		jz	checkTotal
		inc	bx				; round up the fraction
checkTotal:
		cmp	widthLimit, bx
		jb	done				; over limit, carry set

		loop	addWidth			
		clc					; everything fit
done:
	;
	; Destroy the GState.
	;
		lahf
		call	GrDestroyState

		mov	dx, numChars
		xchg	dx, cx
		sub	cx, dx				; cx = # chars that fit
		sahf

		.leave
		ret
GetTruncateLimit	endp


endif	; if _ACCESS_POINT


if	_VSER

datarecCategory		char	DATA_RECEIVER_CATEGORY
datarecModemKey		char	DATA_RECEIVER_MODEM_KEY
datarecPointKey		char	"terminalAccpnt",0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermGetDatarecAccPnt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get Data receive appl's access point ID

CALLED BY:	
PASS:		nothng
RETURN: 	carry clear if no error
			ax	= access point ID	
DESTROYED:	ax, bx, cx, dx, ds, si, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermGetDatarecAccPnt	proc	far
		.enter
	;
	; get init file params
	;
		mov	cx, cs
		mov	dx, offset datarecPointKey
		mov	ds, cx
		mov	si, offset datarecCategory
		call	InitFileReadInteger		; ax = accpnt ID
		jnc	done
	;
	; create and remember an access point
	;
		clr	bx
		mov	ax, APT_APP_LOCAL
		call	AccessPointCreateEntry		; ax = accpnt ID
		mov	bp,ax
		call	InitFileWriteInteger
		call	InitFileCommit
		clc
done:
		.leave
		ret
TermGetDatarecAccPnt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSendDatarecModemInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SNOPSIS:	Send modem initialization string for data receive appl

CALLED BY:	TermMakeConnection
PASS:		es	= dgroup
RETURN:		carry set if connection error
DESTROYED:	ds, si, ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSendDatarecModemInit	proc	far
		.enter
EC <		Assert_dgroup	es					>
		mov	cx, cs
		mov	dx, offset datarecModemKey
		mov	ds, cx
		mov	si, offset datarecCategory
		clr	bp
		call	InitFileReadString		; ^hbx = string,
							; cx = length
		cmc
		jnc	ok				; no init string
	;
	; lock and send it
	;
		jcxz	emptyString
		call	MemLock
		mov_tr	dx, ax
		clr	bp				; dxbp<-string to send
EC <		tst	ch						>
EC <		ERROR_NZ TERM_DATAREC_MODEM_INIT_STRING_TOO_LONG	>
		mov	ch, 1
		mov	ax, MSG_SERIAL_SEND_CUSTOM_MODEM_COMMAND
		push	bx				; save text block
		call	TermWaitForModemResponse	; carry set if error
		pop	bx				; restore text block
	
		pushf
		call	MemFree				; free text block
	;
	; If timeout in waiting for modem response, mark it as modem init
	; error for datarec.
	;
		cmp	es:[responseType], TMRT_TIMEOUT
		jne	notTimeout
		mov	es:[responseType], TMRT_DATAREC_INIT_ERROR
	
notTimeout:
		popf
		jmp	exit
ok:
		mov	es:[responseType], TMRT_OK
exit:
		.leave
		ret
emptyString:
	;
	; Everything is fine if the init string is empty. Assume response is
	; OK.
	;
		call	MemFree		
		clc
		jmp	ok
TermSendDatarecModemInit	endp

endif	; _VSER

if	not _TELNET
if	_MODEM_STATUS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermWaitForModemResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for modem response

CALLED BY:	GLOBAL
PASS:		es	= dgroup
		ax	= message to send to Serial thread

		if custom command or dial command:
			ch	= timeout value:
				if 0: TERM_LONG_REPLY_TIMEOUT 
				if 1: TERM_SHORT_REPLY_TIMEOUT
			cl	= number of characters to send
			dx:bp	= fptr to modem string
		else
			dl	= TermInternalModemInitString
	
RETURN:		ds	= dgroup
		carry set if connection error

		dgroup:[responseType] updated by parser about the
		modem response
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call serial thread to start waiting for modem response;
	Wait on a semaphore to be released by serial thread;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermWaitForModemResponse	proc	far
		.enter
EC <		call	ECCheckES_dgroup				>
	;
	; Set the flag so that the VSem routine will know if they know they
	; need to VSem
	;
		segmov	ds, es, bx		; ds <- dgroup
		CallSerialThread		; carry set if connection err
						; ax,bx,cx,dx,di,bp destroyed
		jc	done
		PSem	es, responseReplySem	; wait for response
done::
		.leave
		ret
TermWaitForModemResponse	endp
endif	; _MODEM_STATUS
endif	; !_TELNET
	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripNULFromBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destructively removes C_NULL characters from a buffer

CALLED BY:	GLOBAL
			SerialReadData (GeoComm)
			TelnetReadDataLoop (Telnet)
PASS:		ds:si	= buffer
		cx	= size of buffer (in bytes)
RETURN:		cx	= new buffer size (will be <= original size)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

BUGS:
	If the DBCS version of this routine is passed a buffer
	with start & endpoints in the middle of a character,
	NUL's may not be correctly removed.  This might happen
	when being passed a buffer which is read from a
	byte-stream, which doesn't respect character boundaries.
	The caller should be insuring that the buffer boundaries
	lie on character boundaries.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StripNULFromBuffer	proc	far
	uses	ax, dx, es, di, si
	.enter

	mov	dx, cx				; dx = original size

	jcxz	noWork

	; Start off by scanning for the first NUL.  If none found, then
	; we don't have to do any work beyond the scanning.

	segmov	es, ds, di
	mov	di, si
	clr	ax
if DBCS_PCGEOS ; ----------------------------------------

	shr	cx, 1							
EC <	WARNING_C DBCS_BAD_BUFFER_BOUNDARY				>
	repnz	scasw							

else ; SBCS  ---------------------------------------------

	repnz	scasb							

endif ; --------------------------------------------------

	jnz	noWork				; no NUL found

	; Start moving characters after NUL to position occupied
	; by the NUL.
	; es:di points one char beyond NUL, cx = chars left in buffer

	mov	si, di
	dec	di
DBCS <	dec	di							>

	jcxz	done

shiftChar: ; ds:si = char to test/copy
	   ; es:di = next position in output buffer

SBCS <	lodsb								>
DBCS <	lodsw								>

SBCS <	tst	al							>
DBCS <	tst	ax							>
	jz	nextChar

SBCS <	stosb								>
DBCS <	stosw								>
nextChar:
	loop	shiftChar

done:	; ds:si = 1 char beyond input buffer
	; ds:di = 1 char beyond output buffer
	; dx = size of input buffer

	sub	si, di				; reduce buf size by the
	sub	dx, si				; difference in i/o buffers
noWork:
	mov	cx, dx

	.leave
	ret

StripNULFromBuffer	endp

