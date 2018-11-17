COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		scriptEdit.asm

AUTHOR:		Eric Yeh, Nov 25, 1996

ROUTINES:
	Name			Description
	----			-----------
MSG_TERM_SCRIPT_EDITOR_OPEN	sets ScriptEditor to top, opens service's
				macro file.

MSG_TERM_SCRIPT_EDITOR_CLOSE	Closes script editor window, returns to Network 
				Settings dialog box (4.4 of new spec). 

MSG_TERM_SCRIPT_EDIT_DIALOG_YES	writes contents of text script editor text
				object to buffer.

MSG_TERM_SCRIPT_EDIT_DIALOG_NO	closes script editor window without saving.

GetScriptFile			Looks up current network service, then loads
				in appropriate history file.  Note: IAPL
				record must be loaded into buffer.  If file
				doesn't exist, creates it.

SetFileName			given IAPL record in buffer, sets to script
				directory and returns name of service's
				script file. 


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/25/96   	Initial revision


DESCRIPTION:
		
	Script Editor opening, closing, and function routines.

	$Id: scriptEdit.asm,v 1.1 97/04/04 16:55:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata segment 
scriptFileHandle	word	; file handle of script file currently in use
udata ends	

; Network Service script names
PCVANScriptFile		wchar	"PCVAN.MAC",0
NiftyServeScriptFile	wchar	"NIFTY.MAC",0
ASCIINETScriptFile	wchar	"ASCII.MAC",0
PeopleScriptFile	wchar	"PEOPLE.MAC",0
OtherScriptFile		wchar	"OTHER.MAC",0



; Service script name table
ScriptNameOffsetTable	word	offset PCVANScriptFile, offset NiftyServeScriptFile, offset ASCIINETScriptFile, offset PeopleScriptFile, offset OtherScriptFile

; Network directory name (inside UserData)
ScriptDirectory		wchar	"COMMACRO",0





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetworkRunScriptFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	runs service's associated script

CALLED BY:	
PASS:		es = dgroup
RETURN:		none
DESTROYED:	ax, bx, cx, dx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetworkRunScriptFile	proc	near
	uses	bp,es
	.enter

	clr	dx, cx
	mov	cl, es:[CurrentIAPLSelection]
	mov	ax, es:[IAPLDsToken]
	call	DataStoreLoadRecordNum	; load current record
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_RUN_SCRIPT_FILE	>
	call	SetFileName	; get name
	mov	cx, ds		; set proper segment for text
	mov	bx, segment dgroup
	mov	ds, bx		; set up dgroup
	
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_RUN_SCRIPT_FILE	>

	mov	bx, handle ScriptDisplay	; set up script display
	mov	bp, offset ScriptDisplay	; object.

	call	ScriptRunFile			; run the file

	.leave
	ret
NetworkRunScriptFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermScriptEditorOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets ScriptEditor to top, opens service's macro file

CALLED BY:	MSG_TERM_SCRIPT_EDITOR_OPEN
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/25/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermScriptEditorOpen	method dynamic TermClass, 
					MSG_TERM_SCRIPT_EDITOR_OPEN
;	uses	ax, cx, dx, bp
blockHandle	local	word
;chunkHandle	local	word

	.enter
	push	bp	; store stack frame
	
	; bring up warning dialog.  
	mov	bx, handle ScriptEditorWarningString
	mov	bp, offset ScriptEditorWarningString
	call	MemLock
	push	bx, es
	mov	di, ax
	mov	es, ax
	mov	bp, es:[bp]
	; bring up query dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; to bring to top
	call	TermUserStandardDialog
	pop	bx, es
	call	MemUnlock

	cmp	ax, IC_YES
	je	open_script_editor
		
	; user chickens out.  Restore old dialog.	
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	
	pop	bp	; restore stack frame
	.leave
	ret

open_script_editor:
	; bring ScriptEditor to top
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, handle ScriptEditorPrimary
	mov	si, offset ScriptEditorPrimary
	clr	di
	call	ObjMessage

	call	GetScriptFile	; get/open history file
	jnc	continue_script_editor_open ; script exists, allocate
					    ; block and read it in.


	jmp	open_with_blank_script
	
	; --------------------------------------------------
	; load the service's corresponding macro file
	; --------------------------------------------------
	

	; read file into ScriptEditor text file.
	; But first allocate a block for this first

continue_script_editor_open:
	mov	bx, es:[scriptFileHandle]	; set file handle
	call	FileSize
	tst	ax	; make sure not zero sized file.  If so,
	jz	open_with_blank_script	; just blankify it.

	pop	bp	; restore stack frame to access blockHandle
	push	bp
	push	ax	; store size
	mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
	mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
	call	MemAlloc		; allocate new block
	mov	ss:[blockHandle], bx	; store block handle
	mov	ds, ax			; set up segment
	clr	al			; no flags

	; find size of file
	pop	cx			; restore size --> cx
	clr	dx			; start at beginning of block
	clr	al			; clear flags
	mov	bx, es:[scriptFileHandle]	; set file handle
	call	FileRead		; Read file data into buffer
EC <	ERROR_C	ERROR_FILE_READ_SCRIPT_EDITOR_OPEN	>		
	
	;finished reading in script file, now set the text item to buffer
	;contents.


	push	bp
DBCS <	shr	cx	>		; # chars <-- # bytes 
	mov	bp, dx		; set offset
	mov	dx, ds		; set target segment

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ScriptEditorText
	mov	si, offset ScriptEditorText
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

;	; discard chunk
;	mov	ax, chunkHandle		; set up chunk handle
;	call	LMemFree		; free chunk

	; discard block after sending contents to text object
	mov	bx, blockHandle		; restore block handle
;	call	MemUnlock		; unlock block
	call	MemFree			; free block

exit_script_editor_open:
	; set text field to not modified, so any changes user makes will set
	; this flag.
	mov	bx, handle ScriptEditorText
	mov	si, offset ScriptEditorText
	mov	di, mask MF_CALL
	clr	cx					; not modified
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	call	ObjMessage

	pop	bp	; restore stack frame
	.leave
	ret

open_with_blank_script:
	; either file doesn't exist or 0 sized file, so don't bother
	; allocating any memory and just write a blank.
	call	ClearStringBuffer
	mov	di, offset StringBuffer
	mov {TCHAR} es:[di], NULL_CHAR

	clr	cx	; null terminated
	mov	bp, di	; set offset
	mov	dx, es	; set segment

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ScriptEditorText
	mov	si, offset ScriptEditorText
	mov	di, mask MF_CALL
	call	ObjMessage

	jmp	exit_script_editor_open

TTermScriptEditorOpen	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermScriptEditorClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes script editor window, returns to Network Settings
dialog box (4.4 of new spec).

CALLED BY:	MSG_TERM_SCRIPT_EDITOR_CLOSE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: 

Brings TermView to top, and then raises Network
Settings Dialog Box (dialog 3.5)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/25/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermScriptEditorClose	method dynamic TermClass, 
					MSG_TERM_SCRIPT_EDITOR_CLOSE
;	uses	ax, cx, dx, bp
	.enter
	; check to see if the text object is modified.  If so, bring up save
	; confirm changes dialog and perform appropriate action

	mov	bx, handle ScriptEditorText
	mov	si, offset ScriptEditorText
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjMessage
	jnc	return_to_term_view	; return to network if no modifications

	; modifications made, bring up confirmation dialog
	mov	bx, handle ScriptEditorCloseDialog
	mov	si, offset ScriptEditorCloseDialog	
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage
		
	jmp	exit_script_editor_close	; let dialog routines handle
						; after effects.

return_to_term_view:
	mov	bx, es:[scriptFileHandle]	
	clr	al		; clear flags
	call	FileClose	; close file

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, handle TermPrimary
	mov	si, offset TermPrimary
	clr	di
	call	ObjMessage

	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

exit_script_editor_close:		
	.leave
	ret
TTermScriptEditorClose	endm




; ---------------------------------------------------------------------------
;
;			Script Editor Dialog Close buttons
;
; ---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermScriptEditDialogYes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	writes contents of text script editor text object to buffer. 

CALLED BY:	MSG_TERM_SCRIPT_EDIT_DIALOG_YES
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermScriptEditDialogYes	method dynamic TermClass, 
					MSG_TERM_SCRIPT_EDIT_DIALOG_YES
;	uses	ax, cx, dx, bp

blockHandle	local	word


	.enter
	
	; saving changes, so delete previous file
	clr	al		; clear flags
	mov	bx, es:[scriptFileHandle]
	call	FileClose	; close current file
EC <	ERROR_C	ERROR_FILE_CLOSE_SCRIPT_EDIT_DIALOG_YES	>
	call	SetFileName	; get file name
	call	FileDelete	; remove old file
EC <	ERROR_C	ERROR_FILE_DELETE_SCRIPT_EDIT_DIALOG_YES	>
	call	GetScriptFile	; create new file

	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx	; allocate new block

	mov	bx, handle ScriptEditorText
	mov	si, offset ScriptEditorText
	mov	di, mask MF_CALL
	call	ObjMessage
DBCS <	shl	ax	>	; byte sized <-- word sized length
	push	ax		; store length
	
	mov	ss:[blockHandle], cx	; store block handle
	mov	bx, cx		; move file handle to bx
	call	MemLock		; lock the block		
EC <	ERROR_C	ERROR_MEM_LOCK_SCRIPT_EDIT_DIALOG_YES	>

	mov	ds, ax		; store segment of block to ds
	pop	cx		; restore length

;	mov	dx, ax		; store segment of block in dx


;	mov	ax, LMEM_TYPE_GENERAL	; allocate block, since most likely
;					; will not have a 64K script file ha ha
;	mov	cx, 0	; default block header
;	call	MemAllocLMem	; allocate new buffer 
;	pop	cx		; restore buffer byte count

;EC <	ERROR_C	ERROR_MEM_ALLOC_SCRIPT_EDIT_DIALOG_YES	>
;	mov	newBlockHandle, bx	; store new block handle	
;	
;	call	MemLock		; lock new block
;EC <	ERROR_C	ERROR_MEM_LOCK_SCRIPT_EDIT_DIALOG_YES	>
;	mov	ds, ax		; store segment of new block
;	
;	push	es		; save dgroup
;	mov	es, dx		; put old block segment into es
;	clr	di, si		; both point to the beginning
;	call	BufferAddLFToCR
;
;	pop	es		; restore dgroup

script_edit_write_to_file:
	; set target & write to file
	mov	dx, 0		; set to beginning of block
				; ds points to the new block
;	clr	al		; clear flags
;	mov	bx, es:[scriptFileHandle]	
;	call	FileWrite

	push	bp
	mov	bp, es:[scriptFileHandle]
	call	WriteBufToDisk
	pop	bp

;	; add a CR at the end of the file so that script FSM doesn't puke
;	; allocate space on stack to represent CR
;SBCS <	sub	sp, 1	>	
;DBCS <	sub	sp, 2	>

;	mov	di, sp		
;	mov	ss:[di], CHAR_CR
;SBCS <	mov	ss:[di+1], CHAR_LF	>
;DBCS <	mov	ss:[di+1], 0	>	; upper half of character
;DBCS <	mov	ss:[di+2], CHAR_LF	>
;DBCS <	mov	ss:[di+3], 0	>
;	segmov	ds, ss, bx		; set to write contents of stack
;	mov	dx, di

;	clr	al	; clear flags
;	mov	bx, es:[scriptFileHandle]	
;SBCS <	mov	cx, 1	>
;DBCS <	mov	cx, 2	>
;	call	FileWrite

;SBCS <	add	sp, 1	>	; restore space on stack
;DBCS <	add	sp, 2	>

	clr	al		; clear flags
	call	FileClose	; close file


	; finished writing, unlock block and clean up
	mov	bx, blockHandle
;	call	MemUnlock	; unlock block
	call	MemFree		; free up block
	
	; unlock new block and free it up
;	mov	bx, newBlockHandle
;	call	MemUnlock	; unlock block
;	call	MemFree		; free up block

	; Return to Network app UI sequence

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, handle TermPrimary
	mov	si, offset TermPrimary
	clr	di
	call	ObjMessage

	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
TTermScriptEditDialogYes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermScriptEditDialogNo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes script editor window without saving

CALLED BY:	MSG_TERM_SCRIPT_EDIT_DIALOG_NO
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermScriptEditDialogNo	method dynamic TermClass, 
					MSG_TERM_SCRIPT_EDIT_DIALOG_NO
	uses	ax, cx, dx, bp
	.enter

	mov	bx, es:[scriptFileHandle]	
	clr	al		; clear flags
	call	FileClose	; close file

	; Return to Network app UI sequence

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, handle TermPrimary
	mov	si, offset TermPrimary
	clr	di
	call	ObjMessage

	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
TTermScriptEditDialogNo	endm



; ---------------------------------------------------------------------------
;
;			misc. routines
;
; ---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScriptFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up current network service, then loads in appropriate
history file.  Note: IAPL record must be loaded into buffer.  If file
doesn't exist, creates it.

CALLED BY:	
PASS:		none
RETURN:		carry set = new file created (kinda an error condition)
		carry clear = no new files
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScriptFile	proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

	call	SetFileName				; get file name
						
	mov	al, FILE_ACCESS_RW or FILE_DENY_W	; file flags
	call	FileOpen
	jnc	exit_GET_SCRIPT_FILE
	
	; error occured.  If a file-not-found error, then create new file.
	; Else error.
	cmp	ax, ERROR_FILE_NOT_FOUND
	jz	create_new_file_GET_SCRIPT_FILE	; create new file if
							; it doesn't exist.

	; if not file not found, then error
EC <	ERROR_C	ERROR_FILE_OPEN_GET_SCRIPT_FILE	>

	clc	; no new files

exit_GET_SCRIPT_FILE:
	mov	es:[scriptFileHandle], ax		; store file handle
	.leave
	ret

create_new_file_GET_SCRIPT_FILE:
	mov	ah, mask FCF_NATIVE or FILE_CREATE_ONLY  ; create
							; file. Should have 
						; no problems with this
						; since it is being created.
	mov	al, FILE_ACCESS_RW or FILE_DENY_RW	; set access flag
	mov	cx, FILE_ATTR_NORMAL
;	mov	cx, FILE_OVERWRITE 
	call	FileCreate
EC <	ERROR_C	ERROR_FILE_CREATE_GET_SCRIPT_FILE	>
	stc	; new file created
	jmp	exit_GET_SCRIPT_FILE

GetScriptFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given IAPL record in buffer, sets to script directory and
returns name of service's script file.

CALLED BY:	GetScriptFile
PASS:		none
RETURN:		ds:dx = fptr to name
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFileName	proc	near
	uses	ax,bx,cx,di,bp
	.enter

	; first figure out the service
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1 ; even to keep swat happy
	mov	di, sp			; set pointer to storage area
	mov	ax, es:[IAPLDsToken]	; set datastore token
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	push	es	; store dgroup
	segmov	es, ss, bx	; set target segment to stack
	clr	bx	; use field ID only
	call	DataStoreGetField
	pop	es	; restore dgroup
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_SET_FILE_NAME	>
	mov	cx, ss:[di]	; put current service # into cx
	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1 ; restore stack

	; set current directory to userdata
	mov	ax, SP_USER_DATA
	call	FileSetStandardPath
EC <	ERROR_C	ERROR_FILE_SET_STANDARD_PATH_SET_FILE_NAME	>

	; now set current directory to userdata\commacro
	segmov	ds, cs, bx	; set target segment
	clr	bx	; use current path
	mov	dx, offset ScriptDirectory	; offset to string name of
						; directory.
	call	FileSetCurrentPath
EC <	ERROR_C	ERROR_FILE_SET_CURRENT_PATH_SET_FILE_NAME	>

	; load in the file
	clr	ch	
	mov	di, cx	; set service #
	shl	di	; word offset
	mov	dx, cs:[ScriptNameOffsetTable][di]	; set offset to
							; target file string

	.leave
	ret
SetFileName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferAddLFToCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given buffer & size, adds a new LF after CR to text.  This
text is returned in a new buffer.  Note new buffer is presumed to have been
initialized to the proper size.

CALLED BY:	
PASS:		es:di	= buffer 
		ds:si	= new buffer
		cx	= buffer size (bytes)
RETURN:		cx	= # bytes written	
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BufferAddLFToCR	proc	near
	uses	ax,bx,dx,si,di,bp
	.enter
	
	clr	dx	; set count to 0
	jcxz	exit_buffer_add_lf	; empty buffer

	; set cx from byte size to char size (for DBCS)
DBCS <	shr	cx	>	

	LocalLoadChar	bx, CHAR_LF ; set up bx = CHAR_LF

replace_buffer_loop:
	LocalGetChar	ax, esdi	; get old character
	LocalPutChar	dssi, ax	; store character in new buffer
	LocalCmpChar	ax, CHAR_CR     ; get char
	jnz		continue_buffer_loop

	; Is a CR, add in LF
	LocalPutChar	dssi, bx	; insert LF
	inc	dx			; increment count

continue_buffer_loop:
	inc	dx	; increment count
	dec	cx	; lower counter
	tst	cx
	jnz	replace_buffer_loop	; finished going through buffer?

					

exit_buffer_add_lf:
	xchg	cx, dx	; set # bytes written to cx
DBCS <	shl	cx	> ; set chars --> bytes

	.leave
	ret
BufferAddLFToCR	endp






