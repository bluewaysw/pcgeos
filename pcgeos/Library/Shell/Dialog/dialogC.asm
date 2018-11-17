COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shell -- Dialog
FILE:		dialogC.asm

AUTHOR:		Martin Turon, Dec 19, 1997

GLOBAL ROUTINES:
	Name			Description
	----			-----------
	SHELLREPORTFILEERROR	C stub for routine that displays error
				dialog given FileError and TCHAR *filename
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/19/97	Initial version


DESCRIPTION:
	Externally callable routines for this module.
	No global routines for the dialog module of the shell library
	should appear in any file other than this one.

RCS STAMP:
	$Id: dialogC.asm,v 1.1 97/04/04 19:37:18 newdeal Exp $

=============================================================================@

	SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SHELLREPORTFILEERROR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	
	ShellBuffer *ShellBufferOpen(THCAR *filename, FileAccessFlags flags);
	
SYNOPSIS:	C Stubs for the shell library buffer module.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	 12/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SHELLREPORTFILEERROR 	proc far error:FileError,
				 filename:fptr

		uses	ds
		.enter
		movdw	dsdx, ss:[filename], ax
		mov	ax,   ss:[error]
		call	ShellReportFileError
		.leave				
		ret
SHELLREPORTFILEERROR 	endp

	SetDefaultConvention


