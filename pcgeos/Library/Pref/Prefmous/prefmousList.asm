COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmousList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

DESCRIPTION:
	

	$Id: prefmousList.asm,v 1.1 97/04/05 01:38:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke the "No idea" extra entry if GENMOUSE.GEO isn't
		available. 

PASS:		*ds:si	- PrefMousListClass object
		ds:di	- PrefMousListClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousListInit	method	dynamic	PrefMousListClass, 
					MSG_PREF_INIT

		mov	di, offset PrefMousListClass
		call	ObjCallSuperNoLock

		mov	ax, SP_MOUSE_DRIVERS
		call	FileSetStandardPath

		mov	bx, offset GenericMouseDriver
		mov	dx, ds:[bx]	; ds:dx - filename
		call	FileGetAttributes
		jnc	done

		mov	ax, ATTR_PREF_TOC_LIST_EXTRA_ENTRY_2
		call	ObjVarDeleteData
done:
		.leave
		ret
PrefMousListInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousListSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle a selection change, either from the init file
		or user action.  Enable/disable the serial port list
		and the interrupt level value.

PASS:		*ds:si	- PrefMousListClass object
		ds:di	- PrefMousListClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousListSetSingleSelection	method	dynamic	PrefMousListClass, 
					MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION

		mov	di, offset PrefMousListClass
		call	ObjCallSuperNoLock

	;
	; Now, get the info word for this selection.  Enable/disable
	; the serial port list based on the info word.
	;
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		call	ObjCallInstanceNoLock
		jc	done

		push	ax		; MouseExtendedInfo

		test	ax, mask MEI_SERIAL
		mov	ax, MSG_GEN_SET_ENABLED
		jnz	setSerial

		
		mov	ax, MSG_GEN_SET_NOT_ENABLED

setSerial:
		mov	si, offset MousePortList
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		pop	cx		; MouseExtendedInfo

		test	cx, mask MEI_IRQ
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jz	setIntEnableState

	;
	; If there is an interrupt level, then store it in the GenValue
	;
		
		mov_tr	ax, cx
		andnf	ax, mask MEI_IRQ
		mov	cl, offset MEI_IRQ
		shr	ax, cl
		mov_tr	cx, ax
		mov	si, offset MouseIntValue
		clr	bp
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjCallInstanceNoLock 
		
		mov	ax, MSG_GEN_SET_ENABLED

setIntEnableState:
		mov	si, offset MouseIntValue
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
done:

		ret
PrefMousListSetSingleSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousListApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make something in the parent dialog applyable, so that
		the parent's "OK" trigger can be pressed.

PASS:		*ds:si	- PrefMousListClass object
		ds:di	- PrefMousListClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousListApply	method	dynamic	PrefMousListClass, 
					MSG_GEN_APPLY
		mov	di, offset PrefMousListClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_MAKE_APPLYABLE
		mov	si, offset MouseAccelList
		GOTO	ObjCallInstanceNoLock
PrefMousListApply	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousListUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the text object, unless nothing's selected

PASS:		*ds:si	- PrefMousListClass object
		ds:di	- PrefMousListClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousListUpdateText	method	dynamic	PrefMousListClass, 
					MSG_PREF_ITEM_GROUP_UPDATE_TEXT
		uses	ax,cx,dx,bp
		.enter

		push	cx, dx, bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp

		cmp	ax, GIGS_NONE
		je	done

		mov	ax, MSG_PREF_ITEM_GROUP_UPDATE_TEXT
		mov	di, offset PrefMousListClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
PrefMousListUpdateText	endm



