COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SndPlay (Sample PC GEOS application)
FILE:		sndplay.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/10/93		Initial version

DESCRIPTION:
	This file source code for the SndPlay application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: sndplayManager.asm,v 1.1 97/04/04 16:32:44 newdeal Exp $

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
UseLib sound.def

;------------------------------------------------------------------------------
;			Local Definitions
;------------------------------------------------------------------------------

include	sndplayConstant.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "SndPlayGenProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

SndPlayGenProcessClass		class	GenProcessClass

;define messages for this class here.

MSG_SND_PLAY_PRESSED_NOTE		message		; indicate which note
							; is to be played

MSG_SND_PLAY_UPDATE_DURATION		message		; indicates that the
							; GenItemGroup has
							; a new selection

MSG_SND_PLAY_PLAY			message		; indicates that the
							; 'Play' button has
							; been pressed

MSG_SND_PLAY_PLAY_NEXT_NOTE		message		; used to traverse
							; music piece while
							; still allowing
							; user input

MSG_SND_PLAY_STOP			message		; indicates that the
							; 'Stop' button has
							; been pressed

MSG_SND_PLAY_RECORD			message		; indicates that the
							; 'Record' button has
							; been pressed

MSG_SND_PLAY_REWIND			message		; indicates that the
							; 'Rewind' button has
							; been pressed

MSG_SND_PLAY_SCAN			message		; indicates that the
							; value in the 'Scan'
							; GenValue has changed

MSG_SND_PLAY_ADVANCE			message		; indicates that the
							; 'Advance' button has
							; been pressed

MSG_SND_PLAY_INSERT			message		; indicates that the
							; 'Insert' button has
							; been pressed

MSG_SND_PLAY_DELETE			message		; indicates that the
							; 'Delete' button has
							; been pressed

MSG_SND_PLAY_CHANGE			message		; indicates that the
							; 'Change' button has
							; been pressed

MSG_SND_PLAY_ERASE			message		; indicates that the
							; 'Erase' button has
							; been pressed

SndPlayGenProcessClass		endc	;end of class definition


;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	SndPlayGenProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because GenProcessClass
				;objects are hybrid objects.

idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "sndplay.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;sndplay.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		sndplay.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for ItemGenProcessClass
;------------------------------------------------------------------------------

include	sndplayInit.asm		;initialization code
include sndplayUI.asm		;code for managing user interface
include	sndplayList.asm		;code for managing linked list
include	sndplayPlay.asm		;code for playing music






