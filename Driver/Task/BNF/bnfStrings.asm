COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfStrings.asm

AUTHOR:		Adam de Boor, Sep 21, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/21/91		Initial revision


DESCRIPTION:
	Strings required by us, in an lmem segment so they can be localized.
		

	$Id: bnfStrings.asm,v 1.1 97/04/18 11:58:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TaskStrings	segment	lmem

confirmNukage	chunk.char	"It may be harmful to delete \1.  If it is using any expanded or extended memory, or has created any temporary files, deleting the task could impair the performance of your computer.  You should probably switch to the task and exit it normally.\r\rDo you still wish to delete \1?", 0

cannotSpawnTask chunk.char	"You have created all the tasks you can, or have run out of swap space. You must exit another task to run that program.", 0

;
; Add-shell errors
; 
couldNotExecShell	chunk.char "Unable to run your system", C_QUOTESNGRIGHT, "s command interpreter. Please make sure your COMSPEC environment variable is set correctly.", 0

TaskStrings	ends

Movable		segment	resource

;
; Used to set up the AppLaunchBlock
; 
EC <ourName	char	"BNFEC.GEO", 0			>
NEC <ourName	char	"BNF.GEO", 0			>

Movable		ends


TaskDriverExtInfo	segment lmem LMEM_TYPE_GENERAL

BNFDriverExtInfo	DriverExtendedInfoTable <
	{},			; lmem header added by Esp
	length bnfNameTable,	; number of supported "devices"
	offset bnfNameTable,	; names of supported "devices"
	offset bnfInfoTable
>

bnfNameTable	lptr.char	bnfName
		lptr.char	0		; terminate table
bnfName		chunk.char	"Back & Forth Professional", 0

bnfInfoTable	word		0		; bnfName

TaskDriverExtInfo	ends
