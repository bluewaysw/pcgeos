COMMENT @----------------------------------------------------------------------

	Copyright (c) 1998 New Deal, Inc. -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Comp/File
FILE:		fileC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1998/1/07	Initial version

DESCRIPTION:
	This file contains C interface replacements for certain file
	system routines.
	
	$Id: fileC.asm,v 1.1 98/05/13 14:39:28 martin Exp $

------------------------------------------------------------------------------@

include stdapp.def

	SetGeosConvention
	
FileComponentCStubs	segment	resource

global FCLFILEREAD:far
global FCLFILEWRITE:far

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FCLFileRead

C DECLARATION:	extern word
		    _far _pascal FileRead(FileHandle fh, void _far *buf,
					word count, Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


		file read returns the number of bytes actually read if there
		are no errors, else it returns 0

		in our system if the EOF is reached we return an
		ERROR_SHORT_READ_WRITE but in C it just returns
		the number of bytes read, the system FileRead C stub 
		treats a short read as not being an error.  
		This stub returns *all* errors including short reads. 
		(returns means put into ax by the stub)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin  1998/1/07	Initial version
------------------------------------------------------------------------------@
FCLFILEREAD	proc	far	fh:hptr, buf:fptr, count:word, flag:word
				uses ds
	clc
FCLReadWriteCommon	label	far

	.enter		; won't biff carry b/c no local vars, just params

	lds	dx, buf
	mov	ax, flag
	mov	bx, fh
	mov	cx, count
	jc	write
	call	FileRead
	jmp	common
write:
	call	FileWrite
common:
	;;  ax=0 else ax=FileError
	.leave
	ret

FCLFILEREAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	FCCFileWrite

C DECLARATION:	extern word
		    _far _pascal FileWrite(FileHandle fh, const void _far *buf,
					word count, Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin  1998/1/07	Initial version

------------------------------------------------------------------------------@
FCLFILEWRITE	proc	far
	stc
	jmp	FCLReadWriteCommon

FCLFILEWRITE	endp

FileComponentCStubs	ends

	SetDefaultConvention



