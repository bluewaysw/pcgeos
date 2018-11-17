COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/UI
FILE:		uiManager.asm

AUTHOR:		Don Reeves, 2-23-91

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/23/91		Initial revsion

DESCRIPTION:
	Manager for the UI object module
		
	$Id: uiManager.asm,v 1.1 97/04/04 14:49:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_UI	= 1					; module being defined

; Included definitions
;
include		calendarGeode.def		; geode declarations
include		calendarConstant.def		; structure definitions
include		calendarGlobal.def		; global definitions
include		calendarMacro.def		; macro definitions

; Include the UI information
;
include	uiManager.rdef

; ForceRef's to avoid warnings
;
ForceRef	FebMoniker
ForceRef	MarMoniker
ForceRef	AprMoniker
ForceRef	MayMoniker
ForceRef	JunMoniker
ForceRef	JulMoniker
ForceRef	AugMoniker
ForceRef	SepMoniker
ForceRef	OctMoniker
ForceRef	NovMoniker
ForceRef	DecMoniker

ForceRef	MonMoniker
ForceRef	TueMoniker
ForceRef	WedMoniker
ForceRef	ThuMoniker
ForceRef	FriMoniker
ForceRef	SatMoniker

ForceRef	SecondMoniker
ForceRef	ThirdMoniker
ForceRef	FourthMoniker
ForceRef	FifthMoniker
ForceRef	LastMoniker

ForceRef	montext
ForceRef	tuetext
ForceRef	wedtext
ForceRef	thutext
ForceRef	fritext
ForceRef	sattext
