COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		SDK_C/Hello4 (Sample Asm UI/C implemenation)
FILE:		hello.asm

AUTHOR:		John D. Mitchell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	6/9/92		Initial version.

DESCRIPTION:
	This file contains the inclusion of the hello.rdef file for the Asm
	UI/C implementation "Hello" sample application.

	$Id: helloUI.asm,v 1.1 97/04/04 16:38:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include object.def
include graphics.def
include Objects/winC.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Libraries Used
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseLib ui.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Class Definitions & Declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Here we define "HelloProcessClass" as a subclass of the system provided
; "GenProcessClass". As this application is launched, an instance of this class
; will be created, and will handle all application-related events (messages).
; The application thread will be responsible for running this object,
; meaning that whenever this object handles a message, we will be executing
; in the application thread.
;
; You will find no object in this file declared to be of this class. Instead,
; it is specified as the class for the application thread in "hello.gp".
;
; Note that this class must also be defined here and in the .goc file that
; contains all of the handlers for this class.
;

HelloProcessClass	class	GenProcessClass

; Define messages and instance data for this class here.

HelloProcessClass	endc	;end of class definition


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI Class Definitions & Declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; The "helloUI.ui" file, which contains user-interface descriptions for this
; application, is written in a language called Espire. That file gets compiled
; by UIC, and the resulting assembly statements are written into the
; helloUI.rdef file. We include that file here, so that these descriptions
; can be assembled into our application.
; 
; Precisely, we are assembling db and dw statements which comprise the
; exact instance data for each generic object in the .ui file. When this
; application is launched, these resources (such as MenuResource) will be
; loaded into the Global Heap. The objects in the resource can very quickly
; become usable, as they are pre-instantiated.

include	helloUI.rdef		; Include compiled UI definitions.
