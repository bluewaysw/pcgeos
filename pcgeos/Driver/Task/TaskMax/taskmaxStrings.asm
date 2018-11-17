COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxStrings.asm

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
		

	$Id: taskmaxStrings.asm,v 1.2 98/02/23 20:08:12 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TaskStrings	segment	lmem

taskHasOpenFiles	chunk.char	"The task you wish to delete still has files open.  Deleting the task may cause you to lose data in those files.  You should probably switch to the task and exit it normally.\r\rDo you still wish to delete \1?", 0

taskNotAtRoot		chunk.char	"It may be harmful to delete \1.  If it is using any expanded or extended memory, or has created any temporary files, deleting the task could impair the performance of your computer.  You should probably switch to the task and exit it normally.\r\rDo you still wish to delete \1?", 0


;
; The name of the system as it should appear in the TM menu when we're not
; running.
; 
systemName	chunk.char	"NewDeal", 0

;
; Add-shell errors
; 
couldNotExecShell	chunk.char "Unable to run your system", C_QUOTESNGRIGHT, "s command interpreter. Please make sure your COMSPEC environment variable is set correctly.", 0

TaskStrings	ends

Movable		segment	resource

EC <ourName	char	"TASKMAXE.GEO", 0			>
NEC <ourName	char	"TASKMAX.GEO", 0			>

Movable		ends


TaskDriverExtInfo	segment lmem LMEM_TYPE_GENERAL

TMDriverExtInfo	DriverExtendedInfoTable <
	{},			; lmem header added by Esp
	length tmNameTable,	; number of supported "devices"
	offset tmNameTable,	; names of supported "devices"
	offset tmInfoTable
>

tmNameTable	lptr.char	tmName,
				novellName

		lptr.char	0		; terminate table

tmName		chunk.char	"DR DOS 6.0 TaskMAX", 0
novellName	chunk.char	"Novell DOS 7.0 Task Manager", 0

tmInfoTable	word		0		; tmName

TaskDriverExtInfo	ends
