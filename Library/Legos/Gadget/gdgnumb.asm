COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           gadgetNumber.asm

AUTHOR:         Ronald Braunstein, Jul 14, 1994

ROUTINES:
	Name                    Description
	----                    -----------

	
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	ron     7/14/94         Initial revision


DESCRIPTION:
	Code for a Number component
		

	$Id: gdgnumb.asm,v 1.1 98/03/11 04:30:24 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetNumberClass
idata	ends

	;
	; property data
	;

makePropEntry number, value, LT_TYPE_INTEGER,			\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_GET_VALUE>,	\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_SET_VALUE>

makePropEntry number, minimum, LT_TYPE_INTEGER,		\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_GET_MINIMUM>,	\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_SET_MINIMUM>

makePropEntry number, maximum, LT_TYPE_INTEGER,		\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_GET_MAXIMUM>,	\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_SET_MAXIMUM>

makePropEntry number, increment, LT_TYPE_INTEGER,		\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_GET_INCREMENT>,\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_SET_INCREMENT>

makePropEntry number, displayFormat, LT_TYPE_INTEGER,		\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_GET_DISPLAY_FORMAT>,\
	 PDT_SEND_MESSAGE, <PD_message MSG_GADGET_NUMBER_SET_DISPLAY_FORMAT>

makeUndefinedPropEntry number, readOnly
;
; Keep the caption property for now.  When I have time to replace
; all uses of numbers' .caption in the property boxes with a group
; and label, I'll do so. -jmagasin 6/28/96
;
;makeUndefinedPropEntry number, caption
makeUndefinedPropEntry number, graphic

compMkPropTable	GadgetNumberProperty, number, value, minimum, \
		maximum, increment, displayFormat, \
		readOnly, graphic
MakePropRoutines Number, number

makeActionEntry number, Inc, MSG_GADGET_NUMBER_ACTION_INC, LT_TYPE_UNKNOWN,0
makeActionEntry number, SetNumber, MSG_GADGET_NUMBER_ACTION_SET_VALUE, LT_TYPE_UNKNOWN,1

compMkActTable number, Inc, SetNumber
MakeActionRoutines Number, number


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       arrange our guts the way we wants 'em

CALLED BY:      MSG_ENT_INITIALIZE
PASS:           *ds:si  = GadgetNumberClass object
		ds:di   = GadgetNumberClass instance data
		ds:bx   = GadgetNumberClass object (same as *ds:si)
		es      = segment of GadgetNumberClass
		ax      = message #
RETURN:         
DESTROYED:      
SIDE EFFECTS:   

PSEUDO CODE/STRATEGY:
		First tell superclass to Init itself.
		Then send messages to the superclass telling it what
		the init numbers should really be.  We don't have much
		to initialize in the object at our level.

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dloft   6/ 3/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetNumberEntInitialize     method dynamic GadgetNumberClass, 
					MSG_ENT_INITIALIZE
	.enter

	;
	; Tell superclass to do its thing
	; (which is nothing but building itself out)
	; 
		mov     di, offset GadgetNumberClass
		call	ObjCallSuperNoLock
	;
	; Tell the object that is most likely a Gen thing
	;
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		or	ds:[di].EI_state, mask ES_IS_GEN
	;
	; Set the destination of the object to be itself
	;
		mov     ax, MSG_GEN_VALUE_SET_DESTINATION
		mov     cx, ds:[LMBH_handle]
		mov     dx, si          ; use me
		call    ObjCallInstanceNoLock
	;
	; Set the status message to be something we know about
	;
		mov     ax, ATTR_GEN_VALUE_STATUS_MSG
		mov     cx, size word
		call    ObjVarAddData
		mov	{word} ds:[bx], MSG_GADGET_NUMBER_RAISE_EVENT
	;
	; Set min, max, and increment
	;
		mov     ax, MSG_GEN_VALUE_SET_MINIMUM
		clr     cx
		mov     dx, 0
		call    ObjCallInstanceNoLock

		mov     ax, MSG_GEN_VALUE_SET_MAXIMUM
		clr     cx
		mov     dx, 0x7fff
		call    ObjCallInstanceNoLock
	
		mov     ax, MSG_GEN_VALUE_SET_INCREMENT
		mov     dx, 1
		clr     cx
		call    ObjCallInstanceNoLock

	;
	; Set display type
	;
		mov     ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
		mov     cl, GVDF_DECIMAL
		call    ObjCallInstanceNoLock
		

	.leave
	ret
GadgetNumberEntInitialize     endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Inform the system of our association to GenValue

CALLED BY:      MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:           *ds:si  = GadgetNumberClass object
		ds:di   = GadgetNumberClass instance data
		ds:bx   = GadgetNumberClass object (same as *ds:si)
		es      = segment of GadgetNumberClass
		ax      = message #
RETURN:         cx:dx   = superclass to use
DESTROYED:      
SIDE EFFECTS:   

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	dloft   6/30/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetNumberMetaResolveVariantSuperclass       method dynamic GadgetNumberClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		compResolveSuperclass	GadgetNumber, GenValue
		
GadgetNumberMetaResolveVariantSuperclass       endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "number"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetNumberClass object
		ds:di	= GadgetNumberClass instance data
		ds:bx	= GadgetNumberClass object (same as *ds:si)
		es 	= segment of GadgetNumberClass
		ax	= message #
RETURN:		cx:dx	= "number"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetNumberGetClass	method dynamic GadgetNumberClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetNumberString
		mov	dx, offset GadgetNumberString
		ret
GadgetNumberGetClass	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberGetPropertyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the number of the property.

CALLED BY:      MSG_ENT_GET_PROPERTY
PASS:           *ds:si  = GadgetNumberClass object
		ds:di   = GadgetNumberClass instance data
		ds:bx   = GadgetNumberClass object (same as *ds:si)
		es      = segment of GadgetNumberClass
		ax      = message #
		on stack:	GetPropertyArgs
RETURN:         
DESTROYED:      ax, cx, dx
SIDE EFFECTS:   

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	ron     8/ 3/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetNumberGetPropertyJumpTable	nptr \
		offset	numberGet_value,
		offset  numberGet_minimum,
		offset	numberGet_maximum,
		offset	numberGet_increment,
		offset	numberGet_displayFormat
	
GadgetNumberGetPropertyCommon    method dynamic GadgetNumberClass, \
					MSG_GADGET_NUMBER_GET_VALUE,
					MSG_GADGET_NUMBER_GET_MINIMUM,
					MSG_GADGET_NUMBER_GET_MAXIMUM,
					MSG_GADGET_NUMBER_GET_INCREMENT,
					MSG_GADGET_NUMBER_GET_DISPLAY_FORMAT
				
		uses	es, di
		.enter
		sub	ax, MSG_GADGET_NUMBER_GET_VALUE
		mov	bx, ax
		shr	ax
		jmp	cs:[GadgetNumberGetPropertyJumpTable][bx]
	

numberGet_increment label near
		mov	ax, MSG_GEN_VALUE_GET_INCREMENT
		jmp	numberGetIntegerCommon
numberGet_minimum label near
		mov	ax, MSG_GEN_VALUE_GET_MINIMUM
		jmp	numberGetIntegerCommon
numberGet_maximum label near
		mov	ax, MSG_GEN_VALUE_GET_MAXIMUM
		jmp	numberGetIntegerCommon
numberGet_value label near
		mov	ax, MSG_GEN_VALUE_GET_VALUE
numberGetIntegerCommon:
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp		; frame ptr
					;dx.cx = return number int.fract
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
		jmp	done

numberGet_displayFormat label near
		mov	ax, MSG_GEN_VALUE_GET_DISPLAY_FORMAT
		push 	bp
		call	ObjCallInstanceNoLock
		pop	bp

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		clr	ah			; al = GenValueDisplayFormat
		mov	es:[di].CD_data.LD_integer, ax
done:
		.leave
		ret
GadgetNumberGetPropertyCommon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberSetPropertyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the number of the property.

CALLED BY:      many messages
PASS:           *ds:si  = GadgetNumberClass object
		ds:di   = GadgetNumberClass instance data
		ds:bx   = GadgetNumberClass object (same as *ds:si)
		es      = segment of GadgetNumberClass
		ax      = message #
		on stack:	GetPropertyArgs
RETURN:         
DESTROYED:      ax, cx, dx
SIDE EFFECTS:   

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	jimmy     8/ 3/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetNumberSetPropertyJumpTable	nptr \
		offset	numberSet_value,
		offset  numberSet_minimum,
		offset	numberSet_maximum,
		offset	numberSet_increment,
		offset	numberSet_displayFormat
	
GadgetNumberSetPropertyCommon    method dynamic GadgetNumberClass, \
					MSG_GADGET_NUMBER_SET_VALUE,
					MSG_GADGET_NUMBER_SET_MINIMUM,
					MSG_GADGET_NUMBER_SET_MAXIMUM,
					MSG_GADGET_NUMBER_SET_INCREMENT,
					MSG_GADGET_NUMBER_SET_DISPLAY_FORMAT
				
		uses	es, di
		.enter
		sub	ax, MSG_GADGET_NUMBER_SET_VALUE
		mov	bx, ax
		shr	ax
		les	di, ss:[bp].SPA_compDataPtr

		jmp	cs:[GadgetNumberSetPropertyJumpTable][bx]
	
numberSet_displayFormat label near
		mov	ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
		mov	cx, es:[di].CD_data.LD_integer
		jmp	setCommon
numberSet_increment label near
		mov	ax, MSG_GEN_VALUE_SET_INCREMENT
		jmp	setIntegerCommon
numberSet_minimum label near
		mov	ax, MSG_GEN_VALUE_SET_MINIMUM
		jmp	setIntegerCommon
numberSet_maximum label near
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		jmp	setIntegerCommon
numberSet_value label near
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	cx, es:[di].CD_type
		cmp	cx, LT_TYPE_INTEGER
		je	setIntegerSure
		cmp	cx, LT_TYPE_NUMBER
		jne	typeError
	;
	; FIXME	We should be able to change the float to an int/fixed num
	; and do the right thing with it.  For now, we won't
	;		movdw	dxcx, ss:[bp].SPA_compData.CD_data.LD_num
	;		jmp	setCommon
		jmp	typeError
setIntegerCommon:
	;	
	;
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	typeError
setIntegerSure:
		mov	dx, es:[di].CD_data.LD_integer
						; integer
		clr	cx			; fraction
setCommon:
		clr	bp
		call	ObjCallInstanceNoLock

		jmp	done
typeError:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
done:
		.leave
		ret
GadgetNumberSetPropertyCommon	endm
	

GadgetNumberDoActionCommon	method dynamic 	GadgetNumberClass, 
					MSG_GADGET_NUMBER_ACTION_INC,
					MSG_GADGET_NUMBER_ACTION_SET_VALUE
		.enter
		cmp	ax, MSG_GADGET_NUMBER_ACTION_SET_VALUE
		je	setNumber
	
		mov	ax, MSG_GEN_VALUE_INCREMENT
		call	ObjCallInstanceNoLock
		jmp	done
setNumber:
		les	di, ss:[bp].EDAA_argv

		push	bp
		mov	dx, es:[di].CD_data.LD_integer
		clr	cx
		clr	bp			; determinate
		
		mov	ax, segment GadgetNumberClass
		mov	es, ax
		mov	di, offset GadgetNumberClass
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallSuperNoLock
		pop	bp
		
done:
		.leave
		ret

GadgetNumberDoActionCommon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberRaiseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for the GenValue's status message.

CALLED BY:	MSG_GADGET_NUMBER_RAISE_EVENT (status message for number)
PASS:		*ds:si	= GadgetNumberClass object
		ds:di	= GadgetNumberClass instance data
		ds:bx	= GadgetNumberClass object (same as *ds:si)
		es	= segment of GadgetNumberClass
		ax	= message #
		dx:cx	= number entered int.fract
		bp	= GenValueStateFlags
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	7/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
setEventString	TCHAR	"changed", C_NULL
GadgetNumberRaiseEvent	method dynamic GadgetNumberClass, 
					MSG_GADGET_NUMBER_RAISE_EVENT
		passedBP	local	word	push bp
		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp

		.enter

	;
	; If we have been interacted with by the user, then
	; the modified bit will be set and we should send an event.
	; If user changes value via code, then we don't want to send
	; and event. (infinite loop problems.)
	; Also, don't send the event if we're out of date, as the internal
	; value hasn't been updated yet.
	;
		test	ss:[passedBP], mask GVSF_MODIFIED
		jz	ignore

		test	ss:[passedBP], mask GVSF_OUT_OF_DATE
		jnz	ignore

	;		pushdw	cxdx			; data for message
		mov	ax, offset setEventString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, dx
		mov	dx, ax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

	;		stc
	;		popdw	cxdx			; data for message

	;		tst	ax
	;		jnz	clearModify
	;
	; if not, just pass it on and let the object handle it
	;
ignore:
if 0
		push	bp
		clr	bp			; determinate
		mov	di, offset GadgetNumberClass
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallSuperNoLock
		pop	bp
endif
		
done::
		.leave
		ret
if 0
clearModify:
	;
	; There was an event handler.  Make sure we clear the modified bit to
	; prevent any confusion (and possible infinite loops) down the line...
	;
		mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
		clr	cx			; not modified
		call	ObjCallInstanceNoLock
		jmp	done
endif
GadgetNumberRaiseEvent	endm


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the user has a script to change or filter the
		data that is about to be entered.

CALLED BY:	MSG_GEN_VALUE_SET_VALUE
PASS:		*ds:si	= GadgetNumberClass object
		ds:di	= GadgetNumberClass instance data
		ds:bx	= GadgetNumberClass object (same as *ds:si)
		es	= segment of GadgetNumberClass
		ax	= message #
		dx:cx	= number entered int.fract
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	7/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetNumberSetNumber	method dynamic GadgetNumberClass, 
					MSG_GEN_VALUE_SET_VALUE
		params	local	EntHandleEventStruct
		result	local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp

		.enter

	;
	; If we have been interacted with by the user, then
	; the modified bit will be set and we should send an event.
	; If user changes value via code, then we don't want to send
	; and event. (infinite loop problems.)
		push	cx, dx, bp		; data for message
		mov	ax, MSG_GEN_VALUE_IS_MODIFIED
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp		; data for message
		jnc	callSuper

		pushdw	cxdx			; data for message
		mov	ax, offset setEventString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, dx
		mov	dx, ax
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock
		stc

		popdw	cxdx			; data for message

		tst	ax
		jnz	clearModify
	;
	; if not, just pass it on and let the object handle it
	;
callSuper:
		push	bp
		clr	bp			; determinate
		mov	di, offset GadgetNumberClass
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallSuperNoLock
		pop	bp
done:
		.leave
		ret
clearModify:
	;
	; There was an event handler.  Make sure we clear the modified bit to
	; prevent any confusion (and possible infinite loops) down the line...
	;
		mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
		clr	cx			; not modified
		call	ObjCallInstanceNoLock
		jmp	done
GadgetNumberSetNumber	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetCmpStringDXCXESAX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the strings

CALLED BY:	global
PASS:		dx:cx		- string 1
		es:ax		- string 2
RETURN:		flag from cmps
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetCmpStringDXCXESAX	proc	far
	uses	ax,si,di,ds, si
	.enter
		mov	di, ax
		movdw	dssi, dxcx
		call	LocalCmpStrings
	.leave
	ret
GadgetCmpStringDXCXESAX	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GNEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send ourselves a MSG_META_QUERY_IF_PRESS_IS_INK to
		stop a possible timer for going off after we are
		destroyed

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetNumberClass object
		ds:di	= GadgetNumberClass instance data
		ds:bx	= GadgetNumberClass object (same as *ds:si)
		es 	= segment of GadgetNumberClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	NOTE: the call to QUERY_IF_PRESS_IS_INK is
			basically a SPUI specific bug fix (read HACK)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GNEntDestroy	method dynamic GadgetNumberClass, 
					MSG_ENT_DESTROY
		uses	ax, cx, dx, bp
		.enter

	; SPUI specific HACK to prevent one shot timer from going off
	; after we are destroyed
		push	cx, dx, bp
		mov	ax, MSG_META_QUERY_IF_PRESS_IS_INK
		clrdw	cxdx
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp
		
		mov	ax, MSG_ENT_DESTROY
		mov	di, offset GadgetNumberClass
		call	ObjCallSuperNoLock
		.leave
		ret
GNEntDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetNumberSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the look for the number.  Removes old looks if needed.

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		*ds:si - instance data
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/23/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetNumberSetLook	method dynamic GadgetNumberClass, 
					MSG_GADGET_SET_LOOK
		.enter
	;
	; call our superclass
	;
		mov	di, offset GadgetNumberClass
		call	ObjCallSuperNoLock
	;
	; call utility to add and remove hints as necessary
	;
		mov	ax, GadgetNumberLook		;ax <- maximum look
		mov	cx, length numberHints		;cx <- length of hints
		segmov	es, cs
		mov	dx, offset numberHints		;es:dx <- ptr to hints
		call	GadgetUtilSetLookHints
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetNumberSetLook	endm

numberHints word \
	HINT_VALUE_ANALOG_DISPLAY,
	HINT_VALUE_ORIENT_VERTICALLY
spinnerHints nptr \
	GadgetRemoveHint,	;no analog display
	GadgetRemoveHint	;no orient vertically
sliderHints nptr \
	GadgetAddHint,		;analog display
	GadgetRemoveHint	;no orient vertically
verticalSliderHints word \
	GadgetAddHint,		;analog display
	GadgetAddHint		;orient vertically

CheckHack <length spinnerHints eq length numberHints>
CheckHack <length sliderHints eq length numberHints>
CheckHack <length verticalSliderHints eq length numberHints>
CheckHack <offset spinnerHints eq offset numberHints+size numberHints>
CheckHack <offset sliderHints eq offset spinnerHints+size spinnerHints>
CheckHack <offset verticalSliderHints eq offset sliderHints+size sliderHints>

ForceRef sliderHints
ForceRef spinnerHints
ForceRef verticalSliderHints
