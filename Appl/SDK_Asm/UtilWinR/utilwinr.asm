COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	DOVE
MODULE:		UtilWinR sample app
FILE:		utilwinr.asm

AUTHOR:		Brian Chin, Nov 27, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/27/96   	Initial revision


DESCRIPTION:
		
	Sample app for utility mapping window.  Reads a file into physical
	memory.

	$Id: utilwinr.asm,v 1.1 97/04/04 16:35:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include system.def
include file.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

UtilWinProcessClass	class	GenProcessClass

MSG_UTIL_WIN_PROCESS_FILE_STATUS		message
;
; Notification from file selector.
;
; Pass:		cx = entry # of selection
;		bp = GenFileSelectorEntryFlags
;

MSG_UTIL_WIN_READ_FILE				message
;
; Read file into specified logical page.
;
; Pass:		nothing
;

UtilWinProcessClass	endc


idata	segment

	UtilWinProcessClass	mask CLASSF_NEVER_SAVED

;
; these hold information about the utility mapping window
;
mapWindowAddr	dword
mapWindowSize	word
mapWindowCount	word

idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include	utilwinr.rdef

;------------------------------------------------------------------------------
;		Code
;------------------------------------------------------------------------------

UtilWinCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWinProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize some stuff

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= UtilWinProcessClass object
		ds:di	= UtilWinProcessClass instance data
		ds:bx	= UtilWinProcessClass object (same as *ds:si)
		es 	= segment of UtilWinProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWinProcessOpenApplication	method dynamic UtilWinProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter
	;
	; call superclass for default handling
	;
	mov	di, offset UtilWinProcessClass
	call	ObjCallSuperNoLock
	;
	; get utility mapping window info
	;
	movdw	ds:[mapWindowAddr], 0
	mov	ds:[mapWindowSize], 0
	mov	ds:[mapWindowCount], 0
	call	SysGetUtilWindowInfo		; if (ax) dx:bp = window
						; cx = size, bx = number
	tst	ax
	jz	done
	movdw	ds:[mapWindowAddr], dxbp
	mov	ds:[mapWindowSize], cx
	mov	ds:[mapWindowCount], bx
done:
	.leave
	ret
UtilWinProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWinProcessFileStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update file status

CALLED BY:	MSG_UTIL_WIN_PROCESS_FILE_STATUS
PASS:		*ds:si	= UtilWinProcessClass object
		ds:di	= UtilWinProcessClass instance data
		ds:bx	= UtilWinProcessClass object (same as *ds:si)
		es 	= segment of UtilWinProcessClass
		ax	= message #
		cx	= entry # of selection
		bp	= GenFileSelectorEntryFlags
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWinProcessFileStatus	method dynamic UtilWinProcessClass, 
					MSG_UTIL_WIN_PROCESS_FILE_STATUS

sizeBuf		local	UHTA_NULL_TERM_BUFFER_SIZE dup (TCHAR)
pathBuf		local	PATH_BUFFER_SIZE dup (byte)
fileSize	local	dword
.assert (PATH_BUFFER_SIZE gt FILE_LONGNAME_BUFFER_SIZE)

	.enter
	;
	; if not file, set 0 size
	;
	test	{word}ss:[bp], mask GFSEF_NO_ENTRIES
	LONG jnz	setZeroSize
	andnf	{word}ss:[bp], mask GFSEF_TYPE
	cmp	{word}ss:[bp], GFSET_FILE shl offset GFSEF_TYPE
	jne	setZeroSize
	;
	; set path of selected file
	;
	push	bp
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ss
	lea	bp, pathBuf
	mov	cx, size pathBuf
	GetResourceHandleNS	UtilWinFS, bx
	mov	si, offset UtilWinFS
	mov	di, mask MF_CALL
	call	ObjMessage			; cx = disk handle
	pop	bp
	jc	setZeroSize
	mov	bx, cx
	segmov	ds, ss, dx
	lea	dx, pathBuf
	call	FileSetCurrentPath
	jc	setZeroSize
	;
	; get selected file
	;
	push	bp
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, ss
	lea	dx, pathBuf
	GetResourceHandleNS	UtilWinFS, bx
	mov	si, offset UtilWinFS
	mov	di, mask MF_CALL
	call	ObjMessage
	test	bp, mask GFSEF_NO_ENTRIES
	pop	bp
	jnz	setZeroSize
	;
	; get file size (works for dirs, also)
	;
	segmov	es, ss, dx
	mov	ds, dx
	lea	di, fileSize
	lea	dx, pathBuf
	mov	ax, FEA_SIZE
	mov	cx, size dword
	call	FileGetPathExtAttributes
	jc	setZeroSize
	mov	dx, es:[di].high
	mov	ax, es:[di].low
	jmp	setSize

setZeroSize:
	clrdw	dxax
	;
	; convert size to string
	;	dx:ax = size
	;
setSize:
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss, di
	lea	di, sizeBuf
	call	UtilHex32ToAscii
	;
	; indicate size via moniker
	;
	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, ss
	lea	dx, sizeBuf
	mov	bp, VUM_NOW
	GetResourceHandleNS	UtilWinFileSize, bx
	mov	si, offset UtilWinFileSize
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
done::
	.leave
	ret
UtilWinProcessFileStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWinProcessReadFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read file into physical memory

CALLED BY:	MSG_UTIL_WIN_READ_FILE
PASS:		*ds:si	= UtilWinProcessClass object
		ds:di	= UtilWinProcessClass instance data
		ds:bx	= UtilWinProcessClass object (same as *ds:si)
		es 	= segment of UtilWinProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWinProcessReadFile	method dynamic UtilWinProcessClass, 
					MSG_UTIL_WIN_READ_FILE

pathBuf		local	PATH_BUFFER_SIZE dup (byte)
.assert (PATH_BUFFER_SIZE gt FILE_LONGNAME_BUFFER_SIZE)

	.enter
	;
	; mark app busy
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication
	;
	; set path of selected file
	;
	push	bp
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ss
	lea	bp, pathBuf
	mov	cx, size pathBuf
	GetResourceHandleNS	UtilWinFS, bx
	mov	si, offset UtilWinFS
	mov	di, mask MF_CALL
	call	ObjMessage			; cx = disk handle
	pop	bp
	LONG jc	done
	mov	bx, cx
	push	ds
	segmov	ds, ss, dx
	lea	dx, pathBuf
	call	FileSetCurrentPath
	pop	ds
	LONG jc	done
	;
	; get selected file
	;
	push	bp
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, ss
	lea	dx, pathBuf
	GetResourceHandleNS	UtilWinFS, bx
	mov	si, offset UtilWinFS
	mov	di, mask MF_CALL
	call	ObjMessage
	test	bp, mask GFSEF_NO_ENTRIES
	pop	bp
	LONG jnz	done
	;
	; open file
	;
	push	ds
	segmov	ds, ss, dx
	lea	dx, pathBuf
	mov	al, FILE_ACCESS_R or FILE_DENY_NONE
	call	FileOpen
	pop	ds
	LONG jc	done
	mov	bx, ax				; bx = file handle
	;
	; read into desired starting logical page
	;
	push	bx, bp				; save file handle, locals
	GetResourceHandleNS	UtilWinMemLoc, bx
	mov	si, offset UtilWinMemLoc
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage			; dx.cx = value
	pop	bx, bp				; bx = file handle, bp = locals
	;
	; convert K into bytes (dxax = dx << 10)
	;
	push	bp				; save locals		(1)
	clr	ax
	mov	ah, dl
	mov	dl, dh
	shrdw	dxax
	shrdw	dxax
	add	dx, 22h				; start at dir mapping addr
	mov	bp, ax				; dx:bp = address
	;
	; map in page
	;
readMore:
	pushdw	dxbp				; save address		(2)
	mov	ax, 0				; use window 0
	call	SysMapUtilWindow		; dx:bp = window address
	tst	ax
	jz	mapError
	;
	; read window-size bytes into window
	;	dx:bp = buffer
	;	bx = file handle
	;	ax = number of bytes mapped in
	;
	push	ds				; save dgroup		(3)
	mov	cx, ax
	mov	ds, dx
	mov	dx, bp				; ds:dx = buffer
	clr	al
	call	FileRead
	pop	ds				; ds = dgroup		(3)
	popdw	dxbp				; dxbp = address	(2)
	jc	checkResult
	call	SysUnmapUtilWindow
	add	bp, cx				; advance by # bytes read
	adc	dx, 0
	jmp	short readMore

mapError:
	popdw	dxbp				; restore address
	jmp	short error

checkResult:
	push	ax				; save error code
	call	SysUnmapUtilWindow
	;
	; close file
	;	bx = file handle
	;
	clr	al
	call	FileClose

	pop	ax				; ax = error code
	cmp	ax, ERROR_SHORT_READ_WRITE
	je	donePop				; end of file, done
error:
	mov	ax, SST_ERROR			; else, indicate error
	call	UserStandardSound
donePop:
	pop	bp				; bp = locals		(1)
done:
	;
	; mark app not busy
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	UserCallApplication

	.leave
	ret
UtilWinProcessReadFile	endm

UtilWinCode	ends
