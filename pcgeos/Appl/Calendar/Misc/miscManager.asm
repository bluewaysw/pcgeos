COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc
FILE:		miscManager.asm

AUTHOR:		Don Reeves, March 2, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/2/91		Initial revision

DESCRIPTION:
	Manager file for Misc module
		
	$Id: miscManager.asm,v 1.1 97/04/04 14:48:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Misc		= 1				; module being defined

; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions
include		vm.def				; definitions for kernel VM
include		input.def
include		system.def			; localization entry point
include		initfile.def			; initfile routines

UseLib		dbase.def			; definitions for database


; Additonal information
;
udata	segment
	printWidth		word	(?)	; printable width
	printHeight		word	(?)	; printable height
	printMarginLeft		word	(?)	; set by MyPrintGetMargins
	printMarginTop		word	(?)	; set by MyPrintGetMargins
udata	ends


;Included source files
;
include		miscCustomSpin.asm
include		miscDateArrows.asm
include		miscMonthValue.asm
include		miscPrint.asm
include		miscSearch.asm

end
