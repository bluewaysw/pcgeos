COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File
FILE:		fileManager.asm

AUTHOR:		Dennis Chow, December 12, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      12/12/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: fileManager.asm,v 1.1 97/04/04 16:56:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_File = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	fileInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata 	segment
include	fileVariable.def
idata	ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
File 	segment resource

include	fileMain.asm		; externally called routines
include	fileLocal.asm		; internally called routines

File	ends

	end
