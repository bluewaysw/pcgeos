COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hello (Sample PC GEOS application)
FILE:		hello.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		Initial version
	Eric	 3/91		Simplified by removing text color changes.

DESCRIPTION:
	This file source code for the Hello application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: hello2.asm,v 1.1 97/04/04 16:33:31 newdeal Exp $

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
UseLib Objects/vTextC.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "HelloProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

HelloProcessClass	class	GenProcessClass

;define messages for this class here.

MSG_DRAW_NEW_TEXT	message

HelloProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.

idata	segment
	HelloProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.

	winHandle	hptr.Window	0
	textToDraw	byte 	"Text to start with",0


idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "hello.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;hello2.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		hello2.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for HelloProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_META_EXPOSED handler.

DESCRIPTION:	This method is sent by the Windowing System when we must
		redraw a portion of the document in the View area.

PASS:		ds	= dgroup
		cx	= handle of window which we must draw to.

RETURN:		ds	= same

CAN DESTROY:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		initial version

------------------------------------------------------------------------------@

HelloExposed	method	HelloProcessClass, MSG_META_EXPOSED

	mov	ds:[winHandle], cx	; save handle for later
	mov	di, cx			;set ^hdi = window handle
	call	GrCreateState		;Get a default graphics state that we
					;can use while drawing.

	;first, start a window update. This tells the windowing system that
	;we are in the process of drawing to this window.

	call	GrBeginUpdate

	;if we had background graphics to draw, we would call the
	;apropriate graphics routines now.

	;draw the text into the window (pass ^hdi = GState)

	call	HelloDrawText

	;now free the GState, and indicate that we are done drawing to the
	;window.

	call	GrEndUpdate
	call	GrDestroyState

	ret

HelloExposed	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	HelloDrawText

DESCRIPTION:	This procedure will draw a simple line of text onto the
		document.

CALLED BY:	HelloExposed

PASS:		ds	= dgroup
		di	= handle of GState to draw with (the GState structure
			contains the handle of the window to draw into.)

RETURN:		ds, di	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		initial version

------------------------------------------------------------------------------@

;These constants are used in the code below:

TEXT_POINT_SIZE			equ	48	;point size
TEXT_ROTATION			equ	360-15	;angle of rotation, in degrees
TEXT_X_POSITION			equ	30	;x position, in document coords.
TEXT_Y_POSITION			equ	0	;y position, in document coords.

HelloDrawText	proc	near

	;	White out the background first

	mov	ah, CF_INDEX
	mov	al, C_WHITE
	call	GrSetAreaColor
	clr	ax
	clr	bx
	mov	cx,500
	mov	dx,500
	call	GrFillRect

	;first change some of the default GState values, such as font

	mov	cx, FID_DTC_URW_ROMAN	;font (URW Roman)
	mov	dx, TEXT_POINT_SIZE		;point size (integer)
	clr	ah				;point size (fraction) = 0
	call	GrSetFont		;change the GState

	;set the text color according to our textColor variable

	mov	ah, CF_INDEX		;indicate we are using a pre-defined
					;color, not an RGB value.
	mov	al, C_LIGHT_BLUE		;set text color value
	call	GrSetTextColor		;set text color in GState

	;apply a rotation to the transformation matrix, so the text
	;will be drawn at an angle.

	mov	dx, TEXT_ROTATION	;set rotation (integer) for text
	clr	cx			;zero fractional degrees.
	call	GrApplyRotation

	;draw some text onto the document

	mov	ax, TEXT_X_POSITION	;set (ax, bx) = top-left document
	mov	bx, TEXT_Y_POSITION	;	coordinate for text.

	mov	si, offset textToDraw

	clr	cx			;indicate is null-terminated string
	call	GrDrawText		;draw text into window
	ret
HelloDrawText	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	HelloDrawNewText

DESCRIPTION:	This procedure will draw a simple line of text onto the
		document.

CALLED BY:	MSG_DRAW_NEW_TEXT (when user selects button)

PASS:		ds	= dgroup
		di	= handle of GState to draw with (the GState structure
			contains the handle of the window to draw into.)

RETURN:		ds, di	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/90		initial version

------------------------------------------------------------------------------@
HelloDrawNewText	method  HelloProcessClass, MSG_DRAW_NEW_TEXT

	;	Start by reading in the text from the TextEdit object
	;
	GetResourceHandleNS	BoxResource,bx
	mov	si, offset	EnterText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx, ds		; copy into our buffer
	mov	bp, offset textToDraw
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	di, ds:[winHandle]	; create a GState to draw with
	call	GrCreateState

	call	HelloDrawText		; draw the new text

	call	GrDestroyState		; 

	ret

HelloDrawNewText	endm


CommonCode	ends		;end of CommonCode resource
