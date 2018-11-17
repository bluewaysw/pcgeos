COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		documentMessages.asm

AUTHOR:		John Wedgwood, May 28, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 5/28/91	Initial revision
	witt	11/15/93	DBCS-ized error dialog

DESCRIPTION:
	Code for putting up error/message dialog boxes.

	$Id: documentMessages.asm,v 1.1 97/04/04 15:48:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentMessageCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog box informing the user about something...

CALLED BY:	
PASS:		bx	= File handle
		si	= Chunk handle of the string to display. String should
			  be in the StringsUI resource.
		cx:dx	= String to substitute for each C_CTRL_A character
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Put up a dialog box with an OK in it.

	The form of the dialog box is:
		GeoCalc: "Document Name Here"

		Text of error message here

	This is accomplished by calling UserStandardDialog() and passing:
		di:bp	= Pointer to the string with the extra stuff
			  prepended to the start of the error message.
		bx:si	= Pointer to the file name

	The error message should be in the StringsUI resource:
		chunk errorString = "Text of error message here"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/28/91	Initial version
	witt	12/ 1/93	DBCS-ized.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS<MESSAGE_BUFFER_SIZE	=	256*(size char) 	>
DBCS<MESSAGE_BUFFER_SIZE	=	256*(size wchar)	>

DocumentMessage	proc	far
	uses	ax, bx, cx, dx, bp, di, si, ds, es
messageBuf	local	MESSAGE_BUFFER_SIZE dup (byte)
fileNameBuf	local	PathName
	.enter
	;
	; First copy our initialization string into the buffer
	;
	segmov	es, ss, di			; es:di <- ptr to messageBuf
	lea	di, ss:messageBuf

	push	bx, cx				; Save file, seg of string

	;
	; Lock the resource containing the init-string and the error message.
	;
	push	si				; Save chunk of message
	GetResourceHandleNS	MessageInitString, bx
	call	MemLock		; Load the string resource
	mov	ds, ax

	;
	; Copy the initialization string.
	;
	mov	si, offset MessageInitString
	mov	si, ds:[si]			; ds:si <- ptr to the string
	ChunkSizePtr	ds, si, cx		; cx <- string size
	LocalPrevChar	dscx			; Don't count the NULL
	
	rep	movsb				; Copy the initializer string
	pop	si				; Restore chunk of message
	
	;
	; Copy the error message into the buffer.
	;
	mov	si, ds:[si]			; ds:si <- ptr to message
	ChunkSizePtr	ds, si, cx		; cx <- size of the message
	rep	movsb				; Copy data and NULL

if DBCS_PCGEOS
	; Ensure we haven't overflowed our buffer.
	;
EC<	lea	ax, ss:messageBuf				>
EC<	mov	cx, di						>
EC<	sub	cx, ax						>
EC<	cmp	cx, (size messageBuf)				>
EC<	ERROR_A  -1		; error msg too long		>
endif
	;
	; Release the resource block and restore the file handle.
	;
	call	MemUnlock			; Release the resource
	pop	bx, cx				; Restore file, seg of string
	;
	; ss:bp	= Frame ptr with messageBuf filled in
	; cx:dx	= String to substitute for each C_CTRL_A character
	; bx	= File handle of the current file
	;
	; Get the name of the file into the file name buffer. To do this we need
	; to get the document object from the DocumentGroup. Then we call
	; the document to get the file name.
	;
	push	cx, dx				; Save substitution string

	push	bp				; Save frame ptr
	mov	cx, bx				; cx <- file handle
	GetResourceHandleNS	GCDocumentGroup, bx
	mov	si, offset GCDocumentGroup
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
	mov	di, mask MF_CALL
	call	ObjMessage			; ^lcx:dx <- Document object
	
	mov	bx, cx				; ^lbx:si <- Document object
	mov	si, dx
	pop	bp				; Restore frame ptr

	push	bp				; Save it again...
	mov	cx, ss				; cx:dx <- buffer
	lea	dx, ss:fileNameBuf
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp				; Restore frame ptr
	
	pop	cx, dx				; Restore subsitution string
	
	;
	; cx:dx = String to subsitute for each C_CTRL_A
	; ss:bp	= Frame ptr with messageBuf and fileNameBuf filled in
	; 

	;
	; Now call UserStandardDialog() to put up the message.
	;
	clr	cx
	push	cx, cx				; help context

	push	ax				; custom trigger optr (not used)
	push	ax
	
						; ptr to file name
	mov	cx, ss
	push	cx
	lea	ax, ss:fileNameBuf
	push	ax
	
						; ptr to substitute string
	push	cx
	push	dx
	
						; ptr to the string
	push	cx
	lea	ax, ss:messageBuf
	push	ax

	mov	ax, mask CDBF_SYSTEM_MODAL or \
		    (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	push	ax				; flags
	
	call	UserStandardDialog		; Put up the message
	.leave
	ret
DocumentMessage	endp

DocumentMessageCode	ends
