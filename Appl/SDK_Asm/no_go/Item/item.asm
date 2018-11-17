COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Item (Sample PC GEOS application)
FILE:		item.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

DESCRIPTION:
	This file source code for the Item application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: item.asm,v 1.1 97/04/04 16:34:27 newdeal Exp $

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

include	system.def			;for UtilHex32ToAscii


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

SOLUTION		equ	TRUE

;misc stuff

ITEM_ERROR						enum FatalErrors

ITEM_ERROR_BLOCK_ALREADY_CREATED			enum FatalErrors

ITEM_ERROR_BLOCK_ALREADY_DESTROYED			enum FatalErrors

ITEM_ERROR_CALL_TRASHED_REGISTER			enum FatalErrors
;This is a test


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "ItemGenProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

ItemGenProcessClass	class	GenProcessClass

;define messages for this class here.

MSG_ITEM_LIST_REQUEST_ITEM_MONIKER	message

MSG_ITEM_LIST_ITEM_SELECTED		message

MSG_ITEM_INSERT_ITEM			message

MSG_ITEM_DELETE_ITEM			message

MSG_ITEM_SET_ITEM_VALUE			message

MSG_ITEM_RESCAN_LIST			message

ItemGenProcessClass	endc	;end of class definition


;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	ItemGenProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because GenProcessClass
				;objects are hybrid objects.

idata	ends

;------------------------------------------------------------------------------
;			Global Variables
;------------------------------------------------------------------------------

idata	segment

itemListBlock	hptr.LMemHeader		;handle of the LMem heap which contains
					;our item list.

idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "item.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;item.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		item.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for ItemGenProcessClass
;------------------------------------------------------------------------------

include	init.asm		;initialization code
include user.asm		;code for managing user interface
include	list.asm		;code to manage linked list

