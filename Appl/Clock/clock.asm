COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
FILE:		clock.asm

AUTHOR:		Gene Anderson, Jan 22, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/22/91		Initial revision

DESCRIPTION:
	Manager file for PC/GEOS clock

	$Id: clock.asm,v 1.1 97/04/04 14:50:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include clock.def
;------------------------------------------------------------------------------
;			File-specific Include Files
;------------------------------------------------------------------------------
include gstring.def	; For monikers (gstring macros)...
include initfile.def
include Internal/grWinInt.def	; for regions in there...

UseLib	Internal/im.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

.warn	-private	; no object context when defining the individual
			;  objects, so Esp whines about the pointers to the
			;  various color tables, which isn't helpful...
include	clock.rdef
.warn	@private

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

ForceRef DigitalBackgroundString

ForceRef AnalogBackgroundString
ForceRef AnalogHourHandString
ForceRef AnalogMinuteHandString
ForceRef AnalogSecondHandString
ForceRef AnalogTickMarksString
ForceRef AnalogSecondaryTicksString

ForceRef HermanLeftEyebrow
ForceRef HermanRightEyebrow
ForceRef HermanLeftEye
ForceRef HermanRightEye
ForceRef HermanNose
ForceRef HermanMustache
ForceRef HermanMinuteHand
ForceRef HermanHourHand

idata	segment

ClockClass	mask CLASSF_NEVER_SAVED		;process class

ClockColorSelectorClass

idata	ends

;---------------------------------------------------

;-----------------------------------------------------------------------------

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockBanishPrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the primary off the screen.

CALLED BY:	MSG_CLOCK_BANISH_PRIMARY
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockBanishPrimary method dynamic ClockClass, MSG_CLOCK_BANISH_PRIMARY
		.enter
	;
	; First take the primary off-screen so it gives up the app exclusive, &c
	;
		GetResourceHandleNS	ClockPrimary, bx
		mov	si, offset ClockPrimary
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

	;
	; Set the application non-focusable and non-targetable.
	;
		mov	ax, MSG_GEN_SET_ATTRS
		GetResourceHandleNS	ClockAppObj, bx
		mov	cx, mask GA_TARGETABLE shl 8	; clear this bit
		mov	si, offset ClockAppObj
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_APPLICATION_SET_STATE
		clr	cx
		mov	dx, mask AS_FOCUSABLE or mask AS_MODELABLE
		clr	di
		call	ObjMessage
		.leave
		ret
ClockBanishPrimary endm

CommonCode	ends

;------------------------------------------------------------------------------
;
;		       ClockColorSelectorClass
;
;------------------------------------------------------------------------------

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockColorSelectorGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to make sure HINT_IF_SYSTEM_ATTRS has been processed
		before we look at our hints.

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		?
RETURN:		?
DESTROYED:	?
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockColorSelectorGenerateUI method dynamic ClockColorSelectorClass, MSG_GEN_CONTROL_GENERATE_UI
		uses	ax, cx, dx, bp
		.enter
		mov	ax, MSG_SPEC_SCAN_GEOMETRY_HINTS
		call	ObjCallInstanceNoLock
		.leave
		mov	di, offset ClockColorSelectorClass
		GOTO	ObjCallSuperNoLock
ClockColorSelectorGenerateUI endm

CommonCode	ends
