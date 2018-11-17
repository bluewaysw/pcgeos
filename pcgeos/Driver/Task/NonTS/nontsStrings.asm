COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsStrings.asm

AUTHOR:		Adam de Boor, May  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/92		Initial revision


DESCRIPTION:
	String-data for the driver.
		

	$Id: nontsStrings.asm,v 1.2 98/02/23 20:17:56 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NTSDriverInfoSegment	segment	lmem LMEM_TYPE_GENERAL
NTSDriverExtInfo	DriverExtendedInfoTable <
	{},			; lmem header added by Esp
	length ntsNameTable,	; number of supported "devices"
	offset ntsNameTable,	; names of supported "devices"
	offset ntsInfoTable
>

ntsNameTable	lptr.char	ntsName
		lptr.char	0		; terminate table
LocalDefString ntsName		<"No Task-Switcher", 0>

ntsInfoTable	word		0		; ntsName
NTSDriverInfoSegment	ends

NTSStrings	segment	lmem LMEM_TYPE_GENERAL

;
; Name of the environment variable holding the command prompt string.
; (SBCS, used to search DOS environment string)
; 
promptVariable  chunk.char      'PROMPT='

;
; String to stick before any existing prompt when invoking DosExec
; (DBCS, will be converted to DOS and copied into environment string)
;
if DBCS_PCGEOS
promptMessage   chunk.wchar      'Type "exit" to return to \1.$_', 0
else
promptMessage   chunk.char      'Type "exit" to return to \1.$_', 0
endif

;
; Default DOS prompt if no PROMPT variable in the environment. Appended to
; promptMessage
; (SBCS, to copy into environment string w/o conversion to DOS)
;
defaultPrompt   chunk.char      '$n$g', 0

;
; Default product name, in the absence of a .ini file preferences.
; 
LocalDefString defaultProduct	<'Ensemble',0>

;
;       Resident strings (null-terminated for NTSSizeWithProductName and
;       NTSCopyWithProductName)
;
if DBCS_PCGEOS
DE_execError    chunk.wchar	\
      "\r\nUnable to run DOS program (Error Code: DE-01)\r\n$", 0
else
DE_execError    chunk.char	\
      "\r\nUnable to run DOS program (Error Code: DE-01)\r\n$", 0
endif

if DBCS_PCGEOS
DE_prompt       chunk.wchar	\
      "\r\nPress ENTER to return to \1, or ESC to exit to DOS.\r\n$", 0
else
DE_prompt       chunk.char	\
      "\r\nPress ENTER to return to \1, or ESC to exit to DOS.\r\n$", 0
endif

if DBCS_PCGEOS
DE_failedReload chunk.wchar      \
        "\r\nCould not find the loader file. You may need to restart your computer. (Error Code DE-02)\r\n$", 0
else
DE_failedReload chunk.char      \
        "\r\nCould not find the loader file. You may need to restart your computer. (Error Code DE-02)\r\n$", 0
endif

if DBCS_PCGEOS
noMemError      chunk.wchar      \
        "\r\nNot enough DOS memory to reload \1. A DOS program may not\r\n",
	"have released all the memory it used. (Error Code: DE-03)\r\n$", 0
else
noMemError      chunk.char      \
        "\r\nNot enough DOS memory to reload \1. A DOS program may not\r\n",
	"have released all the memory it used. (Error Code: DE-03)\r\n$", 0
endif

NTSStrings	ends
