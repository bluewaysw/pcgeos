COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Avoid
FILE:		avoid.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

DESCRIPTION:
	Demonstration program for how to deal properly with becoming
	a non-detachable application on a system working in transparent-
	launch mode (such as Zoomer)

IMPORTANT:

RCS STAMP:
	$Id: avoid.asm,v 1.1 97/04/04 16:34:00 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include timer.def

include object.def
include graphics.def
include gstring.def

include Objects/winC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Avoid definitions & constants
;------------------------------------------------------------------------------

include avoidApp.def
include avoidDialog.def

AvoidBooleanID	record
	ABID_OPERATION_IN_PROGRESS:1
	; Bit used in Boolean group to represent whether the application has
	; an "operation" in progress that it should not interrupt with a
	; transparent detach.  Since Avoid has no real work to perform in
	; the background, we just provide a toggle box for the tester to
	; click on, to simulate such an operation.
	;
	:15
AvoidBooleanID	end

;------------------------------------------------------------------------------
;			AvoidProcessClass
;------------------------------------------------------------------------------

;Here we define "AvoidProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

AvoidProcessClass	class	GenProcessClass

AvoidProcessClass	endc	;end of class definition


;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	AvoidProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.
idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "avoid.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;avoid.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		avoid.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;			Code for AvoidProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

CommonCode	ends


;------------------------------------------------------------------------------
;			Other Avoid code
;------------------------------------------------------------------------------

include avoidApp.asm		; The application object class
include avoidDialog.asm		; Floating dialog class

