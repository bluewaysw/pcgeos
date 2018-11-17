COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainManager.asm

AUTHOR:		Jonathan Magasin, May  6, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/ 6/94   	Initial revision


DESCRIPTION:
	

	$Id: mainManager.asm,v 1.1 97/04/04 17:49:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include contentGeode.def		; Common include stuff.
include	Internal/heapInt.def		; need ThreadPrivateData definition
include	Internal/interrup.def		; for Sys{Enter,Exit}Critical

include mainConstant.def		; extra class definitions

;------------------------------------------------------------------------------
;			Classes
;------------------------------------------------------------------------------

ConviewClassStructures	segment	resource
	ContentGenViewClass
	ContentDocClass
	ContentTextClass
ConviewClassStructures	ends

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
include mainManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include mainStartEnd.asm
include	mainLink.asm
include	mainSpecialLink.asm
include mainText.asm
include	mainName.asm
include	mainUtils.asm
include	mainBook.asm
include	mainFile.asm
include mainContentPointer.asm
include	mainNotify.asm
include	mainCopy.asm
include mainSearch.asm
include mainHotspot.asm
