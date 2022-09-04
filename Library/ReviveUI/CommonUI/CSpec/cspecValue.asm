COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		specValue.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildValue		Convert a generic value to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic value.

   	$Id: cspecValue.asm,v 1.11 96/08/28 18:28:11 brianc Exp $
	
------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildValue

DESCRIPTION:	Return the specific UI class for a GenValue

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

OLBuildValue	proc	far
	mov	di, cs
	mov	es, di
	mov	di, offset ScrollbarHints
	mov	ax, length ScrollbarHints

	mov	bp, offset OLValueClass		;assume OLValueClass
	mov	cx, 2				;cx <- counter for Maybe-
						; ReturnSlider. Need both
						; hints to be a slider
	call	ObjVarScanData			;bp -- class to use

	mov	dx, bp
	mov	cx, segment OLValueClass
	ret

OLBuildValue	endp

if GEN_VALUES_ARE_TEXT_ONLY

ScrollbarHints	VarDataHandler \
 <HINT_VALUE_X_SCROLLER, offset RetnScrollbar>,
 <HINT_VALUE_Y_SCROLLER, offset RetnScrollbar>,
 <HINT_SPEC_SLIDER, ReturnSlider>,
if SPINNER_GEN_VALUE
 <HINT_SPEC_SPINNER, ReturnSlider>,
endif
 <HINT_VALUE_ANALOG_DISPLAY, MaybeReturnSlider>

else

ScrollbarHints	VarDataHandler \
 <HINT_VALUE_X_SCROLLER, offset RetnScrollbar>,
 <HINT_VALUE_Y_SCROLLER, offset RetnScrollbar>,
 <HINT_SPEC_SLIDER, ReturnSlider>,
if SPINNER_GEN_VALUE
 <HINT_SPEC_SPINNER, ReturnSlider>,
endif
 <HINT_VALUE_ANALOG_DISPLAY, MaybeReturnSlider>,
 <HINT_VALUE_MERGE_ANALOG_AND_DIGITAL_DISPLAYS, MaybeReturnSlider>

endif  	;GEN_VALUES_ARE_TEXT_ONLY
 
RetnScrollbar	proc	far
	mov	bp, offset OLScrollbarClass
	ret
RetnScrollbar	endp


ReturnSlider	proc	far
	mov	bp, offset OLSliderClass
	ret
ReturnSlider	endp

MaybeReturnSlider proc far
if not GEN_VALUES_ARE_TEXT_ONLY
	dec	cx
	jnz	done
	; found both analog & merge hints, so turn into a slider
else
	mov	bp, offset OLValueClass		; assume not read-only
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	jz	done
endif
if (not SLIDER_INCLUDES_VALUES)
;
; never become a slider directly
;
	mov	bp, offset OLSliderClass
endif
done:
	ret
MaybeReturnSlider endp

Build ends
