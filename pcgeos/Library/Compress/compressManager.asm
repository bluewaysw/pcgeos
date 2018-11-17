COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Compress -- Compress
FILE:		compressManager.asm

AUTHOR:		David Loftesness, April 26, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dl      04/26/92        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: compressManager.asm,v 1.1 97/04/04 17:49:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Compress = 1

;Standard include files


include	geos.def
include geode.def
include ec.def

include	library.def
include geode.def

include resource.def

include object.def
include	graphics.def
include gstring.def
include	win.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include	chunkarr.def
include thread.def
include	sem.def
DefLib	compress.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include compressConstant.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	compressVariable.def

;------------------------------------------------------------------------------
;	Misc. Functions (from PKWARE library)
;------------------------------------------------------------------------------
;PK_TEXT	segment private 'CODE'
;
; We'll have to deal with the "segment for XXXX unknown" warnings. It doesn't
; hurt anything. There's no way to map to a "private" segment	
;
global IMPLODE:far
global EXPLODE:far
;PK_TEXT	ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
CompressCode	segment	resource

include compressIO.asm
include	compressMain.asm		; Main code file for this module.

CompressCode	ends
