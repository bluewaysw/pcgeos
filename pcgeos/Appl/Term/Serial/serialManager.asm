COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Serial
FILE:		serialManager.asm

AUTHOR:		Dennis Chow, September 6, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 6/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: serialManager.asm,v 1.1 97/04/04 16:55:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Serial = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	serialInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata segment
include	serialVariable.def
include serialScriptVar.def	;variables for use by Script code
idata ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
Serial segment resource

include	serialMain.asm		;Externally callable routines
include serialIn.asm		;Routines to watch com port
include serialScript.asm	;code which is considered part of the
				;future Script object.
Serial ends

	end
