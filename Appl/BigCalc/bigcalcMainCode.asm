COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigCalcMain.asm

AUTHOR:		Christian Puscasiu, Feb 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	2/26/92		Initial revision


DESCRIPTION:
	
		

	$Id: bigcalcMainCode.asm,v 1.1 97/04/04 14:37:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	System Include Files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include lmem.def
include localize.def
include initfile.def
include vm.def
include dbase.def
include timer.def
include timedate.def
include system.def
include font.def
include fontID.def
include char.def
include Objects/inputC.def


;------------------------------------------------------------------------------
;	Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/vTextC.def
UseLib math.def
UseLib parse.def


;------------------------------------------------------------------------------
;	Application specific stuff
;------------------------------------------------------------------------------

include bigcalcMain.def
include bigcalcProcess.def
include bigcalcCalc.def
include bigcalcMath.def
include bigcalcPCF.def


;------------------------------------------------------------------------------
;	Resources
;------------------------------------------------------------------------------

include bigcalcMain.rdef

;------------------------------------------------------------------------------
;	Code to be included
;------------------------------------------------------------------------------

BigCalcClassStructures 	segment

BigCalcProcessClass
BigCalcApplicationClass
PCFHolderClass
InputFieldClass
CalcInputFieldClass
MemoryInputFieldClass
PaperRollClass
CustBoxClass
CalcEngineClass			mask 	CLASSF_DISCARD_ON_SAVE
RPNEngineClass
InfixEngineClass
PreCannedFunctionClass
PCFChooserClass
FixedArgsPCFClass
VariableArgsPCFClass
FAPCFInputFieldClass
VAPCFInputFieldClass
PCFResultDisplayClass
VAItemGroupClass
VAItemClass
SetExchangeRateClass
CalcTriggerClass
CalcBooleanClass
CalcWorksheetListClass

BigCalcClassStructures	ends


include bigcalcProcess.asm
include	bigcalcCalc.asm
include bigcalcMath.asm
include bigcalcApplication.asm
include bigcalcFiniteState.asm
include bigcalcPCF.asm
include bigcalcHolder.asm
include	bigcalcMemory.asm
include bigcalcUnaryCvt.asm
include bigcalcBuildPCF.asm
include bigcalcBuildFixedArgsPCF.asm
include bigcalcBuildVariableArgsPCF.asm
include bigcalcFixedArgsPCF.asm
include bigcalcVariableArgsPCF.asm

