COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shell -- Buffer
FILE:		bufferMain.asm

AUTHOR:		Martin Turon, Aug 21, 1992

GLOBAL ROUTINES:
	Name			Description
	----			-----------
	ShellBufferOpen		Opens a ShellBuffer
	ShellBufferReadNLines	Reads the next N lines from ShellBuffer
	ShellBufferReadLine	Reads the next line of a ShellBuffer
	ShellBufferClose	Closes a ShellBuffer file
	ShellBufferLock		Locks a ShellBuffer
	ShellBufferUnlock	Unlocks a ShellBuffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/21/92		Initial version


DESCRIPTION:
	Routines to deal with reading huge files. (64k+)

	Externally callable routines for this module.
	No global routines for the buffer module of the shell library
	should appear in any file other than this one.

RCS STAMP:
	$Id: bufferC.asm,v 1.1 97/04/04 19:37:18 newdeal Exp $

=============================================================================@

	SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFEROPEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	
	ShellBuffer *ShellBufferOpen(THCAR *filename, FileAccessFlags flags);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	 12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFEROPEN 	proc far filename:fptr,
                                 flags:FileAccessFlags

		uses	es, ds
		.enter
		movdw	dsdx, ss:[filename], ax
		mov	al,   ss:[flags]
		call	ShellBufferOpen
		.leave				
		ret
SHELLBUFFEROPEN 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFERCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	FileError ShellBufferClose(ShellBuffer *);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	 12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFERCLOSE 	proc far buffer:sptr.ShellBuffer

		uses	es, ds
		.enter
		mov	es, ss:[buffer]
		call	ShellBufferOpen
		.leave				
		ret
SHELLBUFFERCLOSE 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFERLOCK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	FileError ShellBufferClose(ShellBuffer *);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	 12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFERLOCK 	proc far bufhan:hptr

		uses	ds
		.enter
		mov	bx, ss:[bufhan]
		call	ShellBufferLock
		.leave				
		ret
SHELLBUFFERLOCK 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFERUNLOCK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	FileError ShellBufferClose(ShellBuffer *);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFERUNLOCK 	proc far buffer:sptr.ShellBuffer

		uses	es
		.enter
		mov	es, ss:[buffer]
		call	ShellBufferUnlock
		.leave				
		ret
SHELLBUFFERUNLOCK 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFERREADNLINES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	FileError ShellBufferClose(ShellBuffer *);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFERREADNLINES 	proc far buffer:sptr.ShellBuffer,
                                 numlines:word

		uses	es
		.enter
		mov	cx, ss:[numlines]
		mov	es, ss:[buffer]
                call	ShellBufferReadNLines
		.leave				
		ret
SHELLBUFFERREADNLINES 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLBUFFERREADNLINES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	FileError ShellBufferClose(ShellBuffer *);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLBUFFERREADLINE 	proc far buffer:sptr.ShellBuffer

		uses	es
		.enter
		mov	es, ss:[buffer]
                call	ShellBufferReadLine
		.leave				
		ret
SHELLBUFFERREADLINE 	endp
	SetDefaultConvention


