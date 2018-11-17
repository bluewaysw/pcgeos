COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Input Manager
FILE:		imMain.asm

AUTHOR:		Doug Fults

YET TO BE DONE:

	- allow setting of desired mouse report rate

ROUTINES:
	Name			Description
	----			-----------
	ImInfoInputProcess	Return our handle (for input drivers)
	ImGrabInput		Force all input to a single location
	ImReleaseInput		Release input
	ImSetPtrMode		Set ptr-send mode (continuous/enter-leave)
	ImForcePtrMethod	Force a pointer method to be sent
	ImSetPtrWin		Set root window in which pointer is displayed
	ImSetDoubleClick	Set double-click interval
	ImInfoDoubleClick	Find double-click interval
	ImPtrJump		Force the pointer to a new position
	ImGetMousePos		Find where the mouse is now
	ImStartMoveResize	Start a move/resize rubber-banding
	ImStopMoveResize	Stop same
	ImConstrainMouse	Constrain the mouse to a rectangular area
	ImUnconstrainMouse	Allow mouse to roam free
	ImAddMonitor		Add a monitor routine to the input chain
	ImRemoveMonitor		Remove a monitor routine from the chain

For use by FlowClass object only:
	ImBumpMouse		Special synchronous PtrJump 
	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Doug	8/5/88	First code
	Clayton	5/89	Added move/resize stuff
	Adam	9/89	Added handling of multiple screens


DESCRIPTION:

		User Input Processing Manager.  Provides shell for input to
	pass through all levels of processing, & finally off to applications.
	Provides standard processing functions as specific levels.



	Input Data Processing Order
	---------------------------

		All drivers for user input will be initialized with a call
	to the INIT function in their Strategy (IOCTL) routine.  All changes
	in device data should then be sent to the User Input Manager process
	via an event:

		EVENT TYPE					1 word
		EVENT specific data				3 words
		unused						1 word (si)
				

	This data will then be processed via input processing modules in
	the following order:

	LEVEL  0
		- INPUT ENTRY POINT.  Actually the Event Queue for the User
		  Input Manager.

		  EVENTS:	MSG_KBD_SCAN
				MSG_PTR_CHANGE
				MSG_PRESSURE_CHANGE
				MSG_DIRECTION_CHANGE
				MSG_BUTTON_CHANGE

	LEVEL 20
		- EXTENSIONS OF DRIVER PROCESSING.  (OPTIONAL)
		  Data processing that would require more time than we feel
		  comfortable leaving interrupts off for is done here.
		  Drivers will attach a monitor here to do this processing.
		  he keyboard driver does this, & converts MSG_KBD_SCAN to
		  MSG_META_KBD_CHAR events.

		  MSG_KBD_SCAN -> MSG_META_KBD_CHAR

	LEVEL 40
		- INPUT COMBINATION.  Example: PTR CHANGE, BUTTON CHANGE,
		  DIRECTION & PRESSURE CHANGE events are "summed", to yield
		  the final versions of these events.  Input devices could
		  be mapped to other devices at this point (a MSG_PTR_CHANGE
		  for the 2nd pointing device could be mapped to be a
		  MSG_PTR_2 type).

		  MSG_PTR_CHANGE		MSG_META_PTR
		  MSG_PRESSURE_CHANGE   ->	MSG_META_PRESSURE
		  MSG_DIRECTION_CHANGE 	MSG_META_DIRECTION
		  MSG_BUTTON_CHANGE		MSG_META_BUTTON

	LEVEL 60
		- POINTER PERTURBATIONS (OPTIONAL)
		  PTR is made to perform "snap" & "ratchet" operations, and/or
		  confined to some region (rectangle only?), per information
		  from current process.  Pointer image could be changed here,
		  based on position, or whatever.

	LEVEL 100
		- POINTER DRAWN TO SCREEN
		- EVENTS SENT TO DESTINATION OUTPUT DESCRIPTOR
			(Usually a FlowClass object running under the UI)


	$Id: imManager.asm,v 1.1 97/04/05 01:17:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	kernelGeode.def

include sem.def
include timer.def
include timedate.def
include char.def
include localize.def
include	input.def
include initfile.def
include graphics.def
include win.def
include gcnlist.def	;For MSG_NOTIFY_*
include geoworks.def	;For GWNT_INK
include Internal/gstate.def ;Needed because the ink code calls the vid driver.
include Objects/processC.def
include Objects/inputC.def
include Objects/winC.def

include	Internal/kbdMap.def
include Internal/im.def
include Internal/heapInt.def
include Internal/interrup.def
include Internal/window.def		;For W_visReg

UseDriver Internal/kbdDr.def
UseDriver Internal/videoDr.def
UseDriver Internal/powerDr.def
UseDriver Internal/mouseDr.def

UseLib	hwr.def				; for IXC_TERMINATE_STROKE
;----------------------------------------

include	imConstant.def
include imVariable.def
include imMacro.def


;----------------------------------------

include	imMonitors.asm
include imInit.asm
include imMisc.asm
include	imPtr.asm
include	imScreenSaver.asm
include imPen.asm











