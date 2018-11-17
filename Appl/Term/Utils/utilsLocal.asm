COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Utils
FILE:		utilsLocal.asm

AUTHOR:		Dennis Chow, October 5, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      10/05/89        Initial revision.

DESCRIPTION:
	Internal callable routines for this module that deal with files. 
	No routines outside this file should be called from outside this
	module.

	$Id: utilsLocal.asm,v 1.1 97/04/04 16:56:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get size of a file

CALLED BY:	LoadFile
			
PASS:		bp:dx 	- filename
		ds - dgroup

RETURN:		ds:ax 	- filesize ( 0 if error)
		cx	- error code (if any)

DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		Would put an error message if couldn't open file, but
		since nobody calls this routine except for the termcap
		routines, will not display error message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	6/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileSize	proc	near
	push	ds, si, bp, dx
	mov	al, (mask FFAF_RAW) or FILE_ACCESS_R or FILE_DENY_NONE
	mov	ds, bp			;pass filename in ds:dx
	call	FileOpen
	jc	error			;if error flag it,
					;
	mov	bx, ax			;pass file handle in BX
	mov	al, FILE_POS_END	;jump to end
	clr	cx			;clear offsets
	clr	dx
	call	FilePos

	push	ax			;save file size
	mov	al, FILE_NO_ERRORS
	call	FileClose
	pop	ax
	jmp	short done
error:
	mov	cx, ax				;pass error code
	clr	dx
	clr	ax
done:
	pop	ds, si, bp, dx
	ret
GetFileSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	loads specified number of bytes from specified filename
		into specified buffer

CALLED BY:	LoadText

PASS:		bp:dx 	- filename
		es:di 	- buffer
		bx	- buffer handle
		cx 	- number of bytes

RETURN:		carry set if error

DESTROYED:	

PSEUDO CODE/STRATEGY:
		open file;
		read file into buffer;
		close file;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBuffer	proc	near
	push	ax, bx, cx, ds
	mov	ds, bp			; ds:dx = filename
	mov	al, (mask FFAF_RAW) or FILE_ACCESS_R or FILE_DENY_NONE
	call	FileOpen		; open file
	jc	error			; if FileOpen error, bail out
	mov	bx, ax			; get file handle for FileRead
	segmov	ds, es, ax		; set ds:dx = buffer
	mov	dx, di
	mov	al, 0			; FileRead flags
	call	FileRead		; read cx bytes into buffer
	mov	al, FILE_NO_ERRORS	; close file flags
	call	FileClose		; close file (bx = handle)
	jmp	short exit
error:
	mov	bp, ERR_GENERAL_FILE_OPEN
	call	DisplayErrorMessage
exit:
	pop	ax, bx, cx, ds
	ret
LoadBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DorkUIStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	send a method to a bunch of object is same resource

CALLED BY:	

PASS:		ax	- METHOD
		bx	- resource handle		
		bp	- start of object table
		dx	- end of object table
RETURN:		ds	- fixed up to point at object block

DESTROYED	di, si:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DorkUIStuff 	proc	near
	cmp	bp, dx
	je	exit
topLoop:
	mov     si, cs:[bp]                      ;bx:[si] ui object to dork
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	push  ax, bx, bp, dx                  ;save method, resource handle
	mov     dl, VUM_NOW                     ;    and object table ptrs
	call    ObjMessage                      ;
	pop ax, bx, bp, dx			;
	add     bp, 2                           ;advance table ptr
	cmp     bp, dx				;
	jb      topLoop                         ;       exit
exit:
	ret
DorkUIStuff endp

