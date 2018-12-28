COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Spell Library
MODULE:		ICS
FILE:		icsManager.asm

AUTHOR:		Andrew Wilson, Aug  6, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 6/91		Initial revision

DESCRIPTION:
	Just includes relevant stuff for the ICS asm code.

	$Id: icsManager.asm,v 1.1 97/04/07 11:05:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include geos.def
include geode.def
include	library.def
include	ec.def
include heap.def
include	file.def
include sem.def
include system.def
include lmem.def
include	initfile.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the spell lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include	Internal/xip.def
endif
include	resource.def
include	thread.def
include Objects/processC.def
UseLib	ui.def
UseLib	Objects/vTextC.def

include spellConstant.def		;includes product features


INIT	segment 
ifdef __BORLANDC__
global ICGEOSPLINIT:far
global ICGEOSPLINITICBUFF:far
ICGEOSplInit equ ICGEOSPLINIT
ICGEOSplInitICBuff equ ICGEOSPLINITICBUFF
else
global ICGEOSplInit:far
global ICGEOSplInitICBuff:far
endif
INIT	ends

EXIT	segment 
ifdef __BORLANDC__
global ICGEOSPLEXITICBUFF:far
global ICGEOSPLEXIT:far
ICGEOSplExitICBuff equ ICGEOSPLEXITICBUFF
ICGEOSplExit equ ICGEOSPLEXIT
else
global ICGEOSplExitICBuff:far
global ICGEOSplExit:far
endif
EXIT	ends

IPPRINT	segment 
ifdef __BORLANDC__
global UPDATEUSERDICTIONARY:far
global IPGEOBUILDUSERLIST:far
UpdateUserDictionary equ UPDATEUSERDICTIONARY
IPGEOBuildUserList equ IPGEOBUILDUSERLIST
else
global UpdateUserDictionary:far
global IPGEOBuildUserList:far
endif
IPPRINT	ends

CODE	segment 
ifdef __BORLANDC__
global ICGEOSPL:far
global ICGEOGETALTERNATE:far
ICGEOSpl equ ICGEOSPL
ICGEOGetAlternate equ ICGEOGETALTERNATE
else
global ICGEOSpl:far
global ICGEOGetAlternate:far
endif
CODE	ends

IPCODE	segment
ifdef __BORLANDC__
global IPGEOUSR:far
global IPGEOADDUSER:far
global IPGEODELETEUSER:far
global ICGEOIGNORESTRING:far
global ICRESETIGNOREUSERDICT:far
IPGEOUsr equ IPGEOUSR
IPGEOAddUser equ IPGEOADDUSER
IPGEODeleteUser equ IPGEODELETEUSER
ICGEOIgnoreString equ ICGEOIGNORESTRING
ICResetIgnoreUserDict equ ICRESETIGNOREUSERDICT
else
global IPGEOUsr:far
global IPGEOAddUser:far
global IPGEODeleteUser:far
global ICGEOIgnoreString:far
global ICResetIgnoreUserDict:far
endif
IPCODE	ends

ThesaurusCode segment resource
global	ThesaurusOpen:far
global	ThesaurusClose:far
ThesaurusCode ends

DefLib	Internal/spelllib.def
include Internal/icbuff.def

include icsConstant.def
include icsVariable.def

include spell.asm
include	spellC.asm
include spellStrings.asm
include geos_asmcalls.asm
include geos_opts.asm

include icsThread.asm
