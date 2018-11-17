COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		TwoDLists (Sample PC GEOS application)
FILE:		twodlists.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		Initial version
	Eric	 3/91		Simplified by removing text color changes.

DESCRIPTION:
	This file source code for the TwoDLists application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT:
	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
	we have new ObjectAssembly and Object-C versions.

RCS STAMP:
	$Id: twodlists.asm,v 1.1 97/04/04 16:34:56 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include Objects/winC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "TwoDListsProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

TwoDListsProcessClass	class	GenProcessClass

MSG_TDLP_FIRST_DLIST_MONIKER_QUERY		message
MSG_TDLP_SECOND_DLIST_MONIKER_QUERY		message
;
; Moniker queries for the two lists.
;
; Pass:		^lcx:dx -- list
;		bp -- item to get moniker for
; Return:	nothing
;

MSG_TDLP_FIRST_DLIST_APPLY			message
MSG_TDLP_SECOND_DLIST_APPLY			message
;
; Messages for handling user changes to the lists.
;
; Pass:		cx -- selection
;		bp -- num selections
;		dl -- GenItemGroupState
;

MSG_TDLP_FIRST_TO_SECOND_TRANSFER		message
MSG_TDLP_SECOND_TO_FIRST_TRANSFER		message
;
; Action messages for the copy triggers.  Causes items to be "copied" from one
; list to the other.
;
; Pass:		nothing
; Return:	nothing
;


NUM_TOTAL_COLORS	equ	16


TwoDListsProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	TwoDListsProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.

;
; First list, initialized with all the colors.
;
firstListItems		word C_BLACK, C_BLUE, C_GREEN, C_CYAN, C_RED, C_VIOLET,\
		     	     C_BROWN, C_LIGHT_GREY, C_DARK_GREY, C_LIGHT_BLUE, \
		             C_LIGHT_GREEN, C_LIGHT_CYAN, C_LIGHT_RED, \
			     C_LIGHT_VIOLET, C_YELLOW, C_WHITE

numFirstListItems 	word NUM_TOTAL_COLORS

;
;Second list, initialized with no items.
;
secondListItems  	word NUM_TOTAL_COLORS dup (0)
numSecondListItems  	word 0


idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "twodlists.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;twodlists.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		twodlists.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for TwoDListsProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


CommonCode	ends		;end of CommonCode resource
