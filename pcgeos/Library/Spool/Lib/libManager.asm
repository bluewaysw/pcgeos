COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		libManager.asm

AUTHOR:		Jim DeFrisco, 9 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision


DESCRIPTION:
	This file contains the code to assemble the library portion of the
	spooler 

	$Id: libManager.asm,v 1.1 97/04/07 11:10:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	spoolGeode.def				; this includes the .def files
include	spoolGlobal.def				; global defs needed

include	Internal/semInt.def
include	system.def
include medium.def

include	libConstant.def				; internal constants/structures
include libMacro.def				; paper size macros

include	gcnlist.def				; global GCN list definitions


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Resource initialization
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PageSizeData	segment lmem LMEM_TYPE_GENERAL
	PageSizeDataLMemBlockHeader <>
PageSizeData	ends



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


include		libPaper.asm			; paper size/strings routines
include		libPrinter.asm			; printer - initfile routines
include		libTables.asm			; some info tables
include		libMisc.asm			; miscellaneous routines
include		libDriver.asm			; driver callbacks.

include		libInit.asm			; library entry code

include		libIBM8bitTab.asm		; 8-bit ASCII translation tab
include		libIBM850Tab.asm		; 8-bit ASCII translation tab
include		libIBM860Tab.asm		; 8-bit ASCII translation tab
include		libIBM863Tab.asm		; 8-bit ASCII translation tab
include		libIBM865Tab.asm		; 8-bit ASCII translation tab
include		libRoman8bitTab.asm		; 8-bit ASCII translation tab
include		libVentura8bitTab.asm		; 8-bit ASCII translation tab
include		libWindows8bitTab.asm		; 8-bit ASCII translation tab
include		libLatin8bitTab.asm		; 8-bit ASCII translation tab

include		libC.asm			; C stubs for library module
