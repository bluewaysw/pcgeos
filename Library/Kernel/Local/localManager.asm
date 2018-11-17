COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Local
FILE:		localManager.asm

AUTHOR:		Tony Requist

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/91		Initial version

DESCRIPTION:
	This file assembles the localization code.

	See the spec for more information.

	$Id: localManager.asm,v 1.1 97/04/05 01:16:39 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include graphics.def
include sem.def
include initfile.def
include lmem.def
include localize.def
include char.def
if DBCS_PCGEOS
include chunkarr.def
endif
include timedate.def

include Internal/lexical.def
include Internal/fileInt.def
include Internal/localInt.def
if DBCS_PCGEOS
UseDriver Internal/fsDriver.def
endif

;--------------------------------------

include localConstant.def		; constants used by this module

;-------------------------------------

include	localInit.asm

include	localStrings.asm

include stringQuotes.asm
include stringConstant.def

if DBCS_PCGEOS
include stringCaseTablesDBCS.asm
else
include stringCaseTables.asm
endif

include stringCase.asm

if DBCS_PCGEOS
include stringSortTablesDBCS.asm
else
include stringSortTables.asm
endif

include stringSort.asm

if DBCS_PCGEOS
include stringCharTablesDBCS.asm
else
include stringCharTables.asm
endif

include stringChar.asm
include stringSize.asm

include dateTimeFields.asm
include dateTimeFormat.asm
include dateTimeParse.asm

include numericFormats.asm
include numericMeasure.asm

include dosVariable.asm

if DBCS_PCGEOS

include dosConvertDBCS.asm

else

include dosConvert.asm
include cmapUS.asm
include cmapMulti.asm
include cmapFrench.asm
include cmapNordic.asm
include cmapPort.asm
include cmapLatin1.asm

endif

include	localC.asm

if DBCS_PCGEOS

include localDBCS.asm

endif

if DBCS_PCGEOS			; useful for PIZZA, but we have these
				;	entry points for DBCS also
				;	(we just have stubs for DBCS)
include gengoDate.asm
include kinsokuChars.asm
endif

end
