COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Visual Geos
MODULE:		Component Object library
FILE:		entMast.asm

AUTHOR:		David Loftesness, Jun  8, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB EntGetPropertyFromTable	Looks up the value for the given property
				in the chunk array of dyanmic properties.

    GLB EntSetPropertyInTable	Store value in user-defined-property table

 ?? INT EntCreatePropertyTables	This creates the tables so an ent component
				can store random properties set by the
				user.  It should only be called once.  One
				table is created.  It is a name array. The
				name contiains ComponentData as its data.

 ?? INT EntCompProcessChildren	Ent wrapper for ObjCompProcessChildren

 ?? INT EntProcessChildNCallback
				Gets the Nth child

 ?? INT EntConstructHandlerName	Generate the name of an event handler based
				on the component's instance data and the
				passed event name.

    INT EntSendToChildrenCallback
				

 ?? INT EntCallParent		

 ?? INT FixupDeletedComponentReference
				Checks to see if the current component OD
				is in the array of deleted components and
				if so pretends we no longer know about it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 8/94		Initial revision


DESCRIPTION:
	
		
	$Id: entMaster.asm,v 1.1 98/03/06 17:55:16 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	
makePropEntry ent, parent, LT_TYPE_COMPONENT, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_GET_PARENT_PROP>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_SET_PARENT_PROP>
makePropEntry ent, class, LT_TYPE_STRING, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_GET_CLASS_PROP>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_SET_CLASS_PROP>
makePropEntry ent, proto, LT_TYPE_STRING, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_GET_PROTO>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_SET_PROTO>
makePropEntry ent, version, LT_TYPE_INTEGER, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_GET_VERSION>, PDT_SEND_MESSAGE, \
	<PD_message MSG_ENT_SET_VERSION>

compMkPropTable EntProperty, ent, parent, class, proto, version

compMkActTable ent


include	Legos/basrun.def
include Legos/runheap.def
include Internal/heapInt.def
include Internal/threadIn.def


RunHeapLockWithSpaceStruct	struct
	RHLWSS_rhls	RunHeapLockStruct
	RHLWSS_tempCX	word
	RHLWSS_tempES	word
	RHLWSS_tempDI	word
RunHeapLockWithSpaceStruct	ends


	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetPropertyFromTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up the value for the given property in the chunk array
		of dyanmic properties.

CALLED BY:	GLOBAL - EntGetProperty

PASS:		ds	= segment of EntClass object (Component)
		ds:di	= EntClass instance data
		ss:bp	= GetPropertyArgs

RETURN:		if carry set 	- property not found
		otherwise	- ComponentData pointed to by 
				  GetPropertyArgs filled in

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	4/28/95    	Pulled out of EntGetProperty

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetPropertyFromTable	proc	far
		class	EntClass
		uses	ax, bx, cx, dx, di, si, es
		.enter

	;;
	;; Check to see if it is in the table by checking out name
	;; array index
	;;

		mov	si, ds:[di].EI_propIndex ; chunk of name array
		tst	si
		jz	notFound
		
		les	di, ss:[bp].GPA_propName; property name to find
		clr	cx			; null terminated
		clr	dx
		call	NameArrayFind

		cmp	ax, CA_NULL_ELEMENT
		LONG je	notFound
	
		call	ChunkArrayElementToPtr

	;;
	;; Copy the data from the table to the passed in buffer
	;;
		lea	di, ds:[di].NAE_data	; point at data, not cruft
		
		mov	ax, ds:[di].CD_type
		mov_tr	si, di			; ds:si = source
		les	di, ss:[bp].GPA_compDataPtr	; buffer to be filled
		mov	es:[di].CD_type, ax	; save type in result

copyNormal::
		Assert	fptr	esdi
		movdw	dxax, ds:[si].CD_data.LD_gen_dword
		movdw	es:[di].CD_data.LD_gen_dword, dxax
		clc

done:
		.leave
		ret
notFound:
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_UNKNOWN_PROPERTY
		stc
		jmp	done
EntGetPropertyFromTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetPropertyInTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store value in user-defined-property table

NOTES:		Automatically stores the new value for the given property
		into a chunk array of properties.  This routine will create
		the chunk array if it hasn't been instantiated yet. 

		This routine deals only with storing the current value of a
		given property, and not at all with implementing behavior
		associated with a given property.

		This routine was once called EntAutoStoreProperty with the
		idea the we could eventually expand the PropEntryStruct
		mechanism to allow automatic updating of component instance
		data. 

		Making this and other dynamic property table manipulation
		routines global allows component designers to add behavior
		associated with properties that may or may not exist within
		the life of a component.  See the managed property in
		goolgeom.asm for an example.

CALLED BY:	GLOBAL - EntSetProperty, GoolSetProperty

PASS:		*ds:si	= EntClass object (Component)
		ds:di	= EntClass instance data
		ss:bp	= SetPropertyArgs

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	4/28/95    	Pulled out of EntSetProperty

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetPropertyInTable	proc	far
		class	EntClass
		passedBP	local	word	push	bp
		cdata		local	ComponentData
		passedCdata	local	fptr.ComponentData
		uses	ax, bx, cx, dx, di, si, es, bp, ds
		.enter
	;
	; First make sure there is an entry in the table
	;
		mov	cx, ds:[di].EI_propIndex ; chunk of name array

	;
	; Make sure that the table has been created
	;
		tst	cx
		jnz	tableCreated
		call	EntCreatePropertyTables
		jmp	afterCreated

tableCreated:
		mov	si, cx			; chunk of name array
afterCreated:
		mov	di, ss:[passedBP]
		movdw	dxax, ss:[di].SPA_compDataPtr
		movdw	ss:[passedCdata], dxax
		les	di, ss:[di].SPA_propName; property name to find
		clr	cx			; null terminated
		mov	dx, ss			; dx:ax = fptr on stack
	; clear field because find may not set it.
		mov	ss:[cdata].CD_type, LT_TYPE_NONE
		lea	ax, ss:[cdata]
		call	NameArrayFind

		cmp	ax, CA_NULL_ELEMENT
		jne	setData
		

createEntry::
	;
	; Add the name of the property to the Name Array
	; *ds:si = name array
	; es:di = Name to add
	; cx = 0 for null terminated

		clr	bx			; NameArrayFlags
		movdw	dxax, ss:[passedCdata]	; fptr.ComponentData
		Assert	fptr	dxax
						
		call	NameArrayAdd
		jmp	incRefIfNeeded

setData:	

	;
	; Set the data for the element.  If the current data is a string,
	; then decrease the reference count before overwriting.
	;
	; ax = element number
	; *ds:si = name array
decRefIfNeeded::
		mov	cx, ss:[cdata].CD_type
		cmp	cx, LT_TYPE_STRUCT
		je	decRef
		cmp	cx, LT_TYPE_COMPLEX
		je	decRef
		cmp	cx, LT_TYPE_STRING
		je	decRef
		cmp	cx, LT_TYPE_COMPONENT
		jne	storeData
		cmp	ss:[cdata].CD_data.LD_comp.high, 0xffff
		jne	storeData
decRef:
		mov	bx, ss:[passedBP]
		push	ax		; element number
		push	ss:[cdata].CD_data.LD_string
		pushdw	ss:[bx].SPA_runHeapInfoPtr
		call	RunHeapDecRef
		add	sp, 6
		pop	ax
	; Don't pop the arguments off the stack until later as we
	; will reuse them.

storeData:
		pushdw	dssi			; name array
		
		call	ChunkArrayElementToPtr
		segmov	es, ds			; es:di points to space
		lds	si, ss:[passedCdata]
		mov	cx, size ComponentData
		lea	di, es:[di].NAE_data	; point at data, not cruft
		Assert	okForRepMovsb
		rep	movsb
		popdw	dssi
		

incRefIfNeeded:
	; If the new data is a heap elt, increase the reference count
	; ax = element number of name
	;
		call	ChunkArrayElementToPtr
		lea	di, ds:[di].NAE_data
		mov	ax, ds:[di].CD_type
		cmp	ax, LT_TYPE_COMPLEX
		je	incRef
		cmp	ax, LT_TYPE_STRING
		je	incRef
		cmp	ax, LT_TYPE_STRUCT
		je	incRef
		cmp	ax, LT_TYPE_COMPONENT
		je	maybeIncComponent

done:
		.leave
		ret
maybeIncComponent:
		cmp	ds:[di].CD_data.LD_comp.high, 0xffff
		jne	done
incRef:
		mov	bx, ss:[passedBP]
		push	ds:[di].CD_data.LD_string
		pushdw	ss:[bx].SPA_runHeapInfoPtr
		call	RunHeapIncRef
		add	sp, 6
		jmp	done

EntSetPropertyInTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntGetProto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle get proto messages

CALLED BY:	MSG_ENT_GET_PROTO
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EEntSetProto	method dynamic EntClass, MSG_ENT_SET_PROTO
	.enter
		les	si, ss:[bp].SPA_compDataPtr
		cmp	es:[si].CD_type, LT_TYPE_STRING
		jne	errorDone

		mov	ax, es:[si].CD_data.LD_string
		push	ds:[di].EI_proto	; save for decref
		mov	ds:[di].EI_proto, ax

	; inc ref
		push	ax
		pushdw	ss:[bp].SPA_runHeapInfoPtr
		call	RunHeapIncRef	; trash ax-dx, es
		add	sp, 6

	; dec ref, token already on stack
		pushdw	ss:[bp].SPA_runHeapInfoPtr
		call	RunHeapDecRef	; trash ax-dx, es
		add	sp, 6
done:
	.leave
	ret
errorDone:
		mov	es:[si].CD_type, LT_TYPE_ERROR
		mov	es:[si].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done
EEntSetProto	endm

EEntGetProto	method dynamic EntClass, MSG_ENT_GET_PROTO
	.enter
		les	si, ss:[bp].GPA_compDataPtr
		mov	es:[si].CD_type, LT_TYPE_STRING
		memmov	es:[si].CD_data.LD_string, ds:[di].EI_proto, ax
	.leave
	ret
EEntGetProto	endm
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a flag so we know when we are built out.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSpecBuild	method dynamic EntClass, 
					MSG_SPEC_BUILD
		.enter
		BitSet	ds:[di].EI_flags, EF_BUILT
		mov	di, offset EntClass
		call	ObjCallSuperNoLock
		.leave
		ret
EntSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSpecUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a flag so we know we have been unbuilt.

CALLED BY:	MSG_SPEC_UNBUILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSpecUnbuild	method dynamic EntClass, 
					MSG_SPEC_UNBUILD
		.enter
		BitClr	ds:[di].EI_flags, EF_BUILT
		mov	di, offset EntClass
		call	ObjCallSuperNoLock
		.leave
		ret
EntSpecUnbuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the class property

CALLED BY:	MSG_ENT_GET_CLASS_PROP
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		convert our lovely fptr into a RunHeapToken

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetClassProp	method dynamic EntClass, MSG_ENT_GET_CLASS_PROP
		uses	es, di, ds, si
		.enter

	;
	; Get the string
	;
		mov	ax, MSG_ENT_GET_CLASS
		call	ObjCallInstanceNoLock

	;
	; Create string space on the heap;
	;
		sub	sp, size RunHeapAllocStruct
		mov	bx, sp
		movdw	ss:[bx].RHAS_data, cxdx

		movdw	esdi, cxdx
		call	LocalStringSize
		inc	cx			; add null
DBCS <		inc	cx						>
		mov	ss:[bx].RHAS_size, cx
		mov	ss:[bx].RHAS_refCount, 0
		mov	ss:[bx].RHAS_type, RHT_STRING
		movdw	cxdx, ss:[bp].GPA_runHeapInfoPtr
		movdw	ss:[bx].RHAS_rhi, cxdx
		
		call	RunHeapAlloc
		add	sp, size RunHeapAllocStruct

		;
		; Now return the string token
		;

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

	.leave
	ret
EntGetClassProp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetClassProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a readonly property error

CALLED BY:	MSG_ENT_SET_CLASS_PROP
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetClassProp	method dynamic EntClass, 
					MSG_ENT_SET_CLASS_PROP
		.enter

		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_READONLY_PROPERTY
		
		.leave
		ret
EntSetClassProp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the version property.  For now, just returns 0.

CALLED BY:	MSG_ENT_GET_VERSION
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This message is really intended to be intercepted by any subclass that
	adds API.  If it's not, we assume this is version 0 of this component.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetVersion	method dynamic EntClass, MSG_ENT_GET_VERSION
	.enter
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		clr	es:[di].CD_data.LD_integer
	.leave
	ret
EntGetVersion	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates a readonly property error.

CALLED BY:	MSG_ENT_SET_VERSION
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetVersion	method dynamic EntClass, MSG_ENT_SET_VERSION
	.enter
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_READONLY_PROPERTY
	.leave
	ret
EntSetVersion	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetParentProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the proto property

CALLED BY:	MSG_ENT_GET_PARENT_PROP
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetParentProp	method dynamic EntClass, MSG_ENT_GET_PARENT_PROP
	uses	es, di
	.enter
	les	di, ss:[bp].GPA_compDataPtr
	mov	es:[di].CD_type, LT_TYPE_COMPONENT
	mov	ax, MSG_ENT_GET_PARENT
	call	ObjCallInstanceNoLock
	tstdw	cxdx		
	jz	done

	; is the parent is an app object, return null
	push	es, di
	push	ds
	movdw	bxsi, cxdx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, segment GenApplicationClass
	mov	es, ax
	mov	di, offset GenApplicationClass
	call	ObjIsObjectInClass
	call	MemUnlock
	pop	ds
	pop	es, di	
	jc	isApp
done:		
	movdw	es:[di].CD_data.LD_comp, cxdx
	.leave
	ret
isApp:
	clrdw	cxdx
	jmp	done
EntGetParentProp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetParentProp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the proto property for ent class

CALLED BY:	MSG_ENT_SET_PARENT_PROP
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetParentProp	method dynamic EntClass, MSG_ENT_SET_PARENT_PROP
	uses	es, di
	.enter
	les	bx, ss:[bp].SPA_compDataPtr
	movdw	cxdx, es:[bx].CD_data.LD_comp
	mov	ax, MSG_ENT_SET_PARENT
	call	ObjCallInstanceNoLock
	.leave
	ret
EntSetParentProp	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetNumChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_ENT_GET_NUM_CHILDREN
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		numChildren is no longer an Ent property.  This method
		is called from GadgetGadgetClass or GadgetGeomClass,
		which are the only subclasses having children. -jmagasin

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	2/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetNumChildren	method dynamic EntClass, 
					MSG_ENT_GET_NUM_CHILDREN
	uses	bp
	.enter
		clr	ax
		mov	bx, ax
		mov	di, OCCT_COUNT_CHILDREN
		call	EntCompProcessChildren
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
	.leave
	Destroy	ax, cx, dx
	ret
EntGetNumChildren	endm
		
		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This will set the property for the component.  It will
		either send another message to set the property or
		just add it to a table. It will overwrite the property
		if it already exists, otherwise it will create it.
		

CALLED BY:	MSG_ENT_SET_PROPERTY
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Check to see if this is one of the special properties
		that we deal with (name, parent, ...)  If not just
		add it to a table.

		It is expected that the Chunk array in the properties
		instance data has already been created.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	7/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetProperty	method dynamic EntClass, 
				MSG_ENT_SET_PROPERTY
.warn -jmp	
	uses	si, es
	.enter

	;
	; Do we know about this property
	;
		segmov	es, cs
		mov	bx, offset entPropertyTable
		call	EntDispatchSetProperty
		cmp	ax, PDT_ERROR
		je	done
		cmp	ax, PDT_SEND_MESSAGE
		je	done
		tst	ax
		jz	storeInTable				; not found
	;
	; Property found -- nptr data returned in cx
	;
		Assert_nptr	cx, cs
		jmp	cx

	;
	; We don't know about it, just add it to the table
	; First make sure there is an entry in the table
	;
storeInTable:
		call	EntSetPropertyInTable
done:
		.leave
		ret
.warn @jmp
EntSetProperty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntResolveAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert an action string to a message number

CALLED BY:	MSG_ENT_RESOLVE_ACTION
PASS:		ds,si,di,bx,es,ax - stuff
		dx:bp	= EntResolveStruct
RETURN:		carry	= set on failure
		dx:bp	= filled in if successful
DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EEntResolveAction	method dynamic EntClass, 
					MSG_ENT_RESOLVE_ACTION

		uses	ax,cx
		.enter
			segmov	es, cs
			mov	bx, offset entActionTable
			call	EntResolveAction
		.leave
		ret
EEntResolveAction	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntResolveProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	resolve property routine for ent class

CALLED BY:	MSG_ENT_RESOLVE_PROPERTY
PASS:		ds,si,di,bx,es,ax - stuff
		dx:bp	= EntResolveStruct
RETURN:		carry	= set on failure
		dx:bp	= filled in if successful
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntResolveProperty method dynamic EntClass, MSG_ENT_RESOLVE_PROPERTY
		uses	ax, cx		;bp, dx
		.enter
		segmov	es, cs, ax
		mov	bx, offset entPropertyTable
		call	EntResolvePropertyAccess
		.leave
		ret			
EntResolveProperty endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntGetCustomProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get a custom property

CALLED BY:	MSG_ENT_GET_CUSTOM_PROPERTY
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EEntGetCustomProperty	method dynamic EntClass, 
					MSG_ENT_GET_CUSTOM_PROPERTY
		.enter
		call	EntGetPropertyFromTable
		.leave
		ret
EEntGetCustomProperty	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntSetCustomProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get a custom property

CALLED BY:	MSG_ENT_SET_CUSTOM_PROPERTY
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EEntSetCustomProperty	method dynamic EntClass, 
					MSG_ENT_SET_CUSTOM_PROPERTY
		.enter
		call	EntSetPropertyInTable
		.leave
		ret
EEntSetCustomProperty	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the named property. It is either a property that this
		class knows about or it is property the user added for this
		object.	 If neither, an error is returned

CALLED BY:	MSG_ENT_GET_PROPERTY
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		ss:bp	= GetPropertyArgs

RETURN:		If property not found, CF set
		else buffer filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		First check to see if it is a property that is stored as part
		of the object (name, parent) then scan the table
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 2/94		Initial version
	martin	10/4/94		Changed to return ComponentData struct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetProperty	method dynamic EntClass, 
					MSG_ENT_GET_PROPERTY
.warn -jmp
	uses	es, si, di, bp
	.enter

	;
	; Do we know about this property
	;
		segmov	es, cs
		mov	bx, offset entPropertyTable
		call	EntDispatchGetProperty
		tst	ax
		jz	checkTable
		cmp	ax, PDT_SEND_MESSAGE
		je	setCarry
		cmp	ax, PDT_UNDEFINED_PROPERTY
		je	setCarry
	;
	; Property found -- nptr data returned in cx
	;
		Assert	nptr	cx, cs
		jmp	cx
if 0
	;
	; Property found -- use ax as offset into jump table
	;
		mov	bx, ax
		shl	bx			; word offset
		jmp	cs:[entGetPropertyJumpTable+bx]
endif
		
checkTable:
		call	EntGetPropertyFromTable
		jmp	done

setCarry:
		stc			; prop not found

done:
	.leave
	Destroy ax, cx, dx
		ret

.warn @jmp
EntGetProperty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns an optr to the parent of the given object.

CALLED BY:	MSG_ENT_GET_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #

RETURN:		cx:dx	= optr to parent

DESTROYED:	bx, si

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetParent	method dynamic EntClass, 
					MSG_ENT_GET_PARENT
	.enter
EC <	call	ECCheckEntObject					>
		mov	bx, offset Ent_offset
		mov	di, offset EI_link
		call	ObjLinkFindParent
		movdw	cxdx, bxsi
	.leave
	ret
EntGetParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the instance data of the component for the parent.
		Send a message to the parent telling it that this object
		is a new child.	 Unregister from any parent it used to belong
		too.  This is a tree operation. It moves all children beneath
		it too.

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		cx:dx	= optr of new parent

RETURN:		ax	= 0 if parent was set
			  non-zero if parent was not set
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Currently, just setting instance data.	It does not move
		objects from one resource to another.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/3/94		Initial version
	martin	9/23/94		Changed to use Ent linkage (instead of Gen)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetParent	method dynamic EntClass, 
					MSG_ENT_SET_PARENT
	uses	cx, dx, bp
	.enter

	;
	; First, see if we're an okay child
	; FIXME Should check if this is an Ent object first...
	;
		mov	bx, ds:[LMBH_handle]	
		xchgdw	bxsi, cxdx		; ^lbx:si = parent
						; ^lcx:dx = child (self)
		mov	ax, MSG_ENT_VALIDATE_CHILD
		mov	di, mask MF_CALL
		call	ObjMessage
		tst	ax
EC <		WARNING_NZ	ENT_WARNING_CHILD_REJECTED		>
		jnz	done
	;
	; Next, check if the passed in parent is valid.
	;
		xchgdw	bxsi, cxdx		; ^lcx:dx = parent
		call	MemDerefDS		; *ds:si  = child (self)
		mov	ax, MSG_ENT_VALIDATE_PARENT
		call	ObjCallInstanceNoLock
		tst	ax
EC <		WARNING_NZ	ENT_WARNING_PARENT_REJECTED		>
		jnz	done
	;
	; Ditch our old parent if we have one.
	;
		mov	bp, mask CCF_MARK_DIRTY
		mov	ax, MSG_ENT_REMOVE_PARENT_LINKAGE
		call	ObjCallInstanceNoLock

		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		mov	ax, MSG_ENT_SET_PARENT_LINKAGE
		call	ObjCallInstanceNoLock
	;
	; Parent added okay, return 0
	;
		clr	ax
done:
		.leave
		ret
EntSetParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used for setting composite linkages for Ent and other master
		levels. 

CALLED BY:	MSG_ENT_ADD_CHILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		cx:dx	= child to add
		bp	= CompChildFlags

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntAddChild	method dynamic EntClass, 
					MSG_ENT_ADD_CHILD
		.enter
	;
	; Set the EntClass linkage.
	;
		mov	ax, offset EI_link
		mov	bx, offset Ent_offset
		mov	di, offset EI_comp
		call	ObjCompAddChild		; destroys ax, bx & di only
		.leave
		ret
EntAddChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntRemoveChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used for setting composite linkages for Ent and other master
		levels. 

CALLED BY:	MSG_ENT_REMOVE_CHILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		cx:dx	= child to remove
		bp	= CompChildFlags

RETURN:		
DESTROYED:	

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntRemoveChild	method dynamic EntClass, 
					MSG_ENT_REMOVE_CHILD
		.enter
	;
	; Set the EntClass linkage.
	;
		mov	ax, offset EI_link
		mov	bx, offset Ent_offset
		mov	di, offset EI_comp
		call	ObjCompRemoveChild	; destroys ax, bx & di only
		.leave
		ret
EntRemoveChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntRemoveParentLinkage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		bp	= CompChildFlags

RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntRemoveParentLinkage	method dynamic EntClass, 
					MSG_ENT_REMOVE_PARENT_LINKAGE
		uses	cx, dx, bp
		.enter

		test	ds:[di].EI_state, mask ES_INITIALIZED
		jz	skipRemove
	;
	; Remove Ent parent if it has an Ent part
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; ^lcx:dx = child (self)
		mov	bl, ds:[di].EI_state	; bl = EntState of object
		mov	ax, MSG_ENT_REMOVE_CHILD
		call	EntCallParent
	;
	; Now, based on EI_state, set any other master-level linkages
	; that are necessary.
	;
		test	bl, mask ES_IS_GEN
		jz	notGen
		mov	ax, MSG_GEN_REMOVE_CHILD
		call	GenCallParent
notGen:
		test	bl, mask ES_IS_VIS
		jz	notVis
		mov	ax, MSG_VIS_REMOVE_CHILD
		call	VisCallParent
notVis:
skipRemove:
		.leave
		ret
EntRemoveParentLinkage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetParentLinkage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used by EntClass children that are able to be children of
		non-Ent composites.  This handler will send the correct
		message to the parent to add this component to its tree. 

CALLED BY:	MSG_ENT_SET_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		^lcx:dx = parent to add
		bp	= CompChildFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetParentLinkage	method dynamic EntClass, 
					MSG_ENT_SET_PARENT_LINKAGE
		.enter
	;
	; Set Ent parent if it has an Ent part
	; 
		push	{word}ds:[di].EI_state	
		mov	bx, ds:[LMBH_handle]
		xchgdw	bxsi, cxdx		; bx:si = parent, cx:dx = child
		mov	ax, MSG_ENT_ADD_CHILD
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Set Gen parent if we have a Gen part
	; 
		pop	ax			; al = EntState of object
		test	al, mask ES_IS_GEN	; Does child have Gen part?
		jz	notGen
		push	ax
		mov	ax, MSG_GEN_ADD_CHILD
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	ax
notGen:
	;
	; Set Vis parent if we have a Vis part
	; 
		test	al, mask ES_IS_VIS	; Does child have Vis part?
		jz	notVis
		mov	ax, MSG_VIS_ADD_CHILD
		mov	di, mask MF_CALL
		call	ObjMessage
notVis:
		.leave
		ret

EntSetParentLinkage	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup instance date for the object.
		Create chunk arrays for the properties ...

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntMetaInitialize method dynamic EntClass, 
					MSG_META_INITIALIZE

	.enter
	;

	;
	; Record that we're not initialized yet...
	;
		BitClr	ds:[di].EI_state, ES_INITIALIZED

	;
	; Clear the proto field
	; Conveniently enough, 0 is the null string token
	;
		clr	ds:[di].EI_proto
	.leave
	ret
EntMetaInitialize endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntCreatePropertyTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This creates the tables so an ent component can store
		random properties set by the user.  It should only be
		called once.  One table is created.  It is a name array.
		The name contiains ComponentData as its data.

CALLED BY:	EntSetProperty
PASS:		ds:si	- ent object
		ds:di	= instance data
RETURN:		si	- chunk handle of name array (EI_propIndex)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntCreatePropertyTables proc	near
		class	EntClass
	uses	ax,bx,cx,dx,di
	.enter

EC <		tst	ds:[di].EI_propIndex				>
EC <		ERROR_NZ ERROR_ENT_PROPERTY_TABLE_ALREADY_CREATED	>
		
		mov_tr	dx, si			;save so we can deref inst data
	;;
	;; Create name array for names of properties
	;;
		mov	bx, size ComponentData
		clr	cx			; header
		mov	al, mask OCF_DIRTY
		clr	si			; create a new chunk
		call	NameArrayCreate

		mov_tr	di, dx			; lptr of object
		mov	di, ds:[di]		; deref chunk
		add	di, ds:[di].Ent_offset	; get inst data ptr
		mov	ds:[di].EI_propIndex, si ; store handle

	.leave
	ret
EntCreatePropertyTables endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntDoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the action is defined for the class

CALLED BY:	MSG_ENT_DO_ACTION
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ss:bp	= EntDoActionArgs
		ax	= message #
RETURN:		ax	= 1 if defined, 0 if not.
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntDoAction	method dynamic EntClass, 
					MSG_ENT_DO_ACTION
		uses	es
		.enter

		segmov	es, cs
		mov	bx, offset entActionTable
		call	EntDispatchAction
		tst	ax
		jnz	done
	; there was no action of that name so return a type error
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_INVALID_ACTION
	;;  normally we would call the super class, but ent is the top
done::						; master class yet
		.leave
		ret
EntDoAction	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntCompProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ent wrapper for ObjCompProcessChildren

CALLED BY:	global
PASS:		ax = child to start at.
		bxdi = callback routine
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntCompProcessChildren	proc	far
		class	EntClass
		.enter

		clr	dx			; num children
		pushdw	dxax			; start at first child
		mov	ax, offset EI_link
		push	ax
		push	bx
		push	di
		clr	ax
		mov	bx, Ent_offset
		mov	di, offset EI_comp
		call	ObjCompProcessChildren	;fixes up stack

		.leave
		ret
EntCompProcessChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntActionGetChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the Nth child

CALLED BY:	MSG_ENT_DO_ACTION
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		ss:bp	= DoActionArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntActionGetChildren	method dynamic EntClass, 
					MSG_ENT_GET_CHILDREN
	uses	es
	.enter
		les	di, ss:[bp].EDAA_argv
		mov	cx, es:[di].CD_data.LD_integer
		push	cx
		clr	bx
		mov	ax, bx
		mov	di, OCCT_COUNT_CHILDREN
		call	EntCompProcessChildren
		pop	ax
		cmp	ax, dx
		jae	returnNullOptr
		
		mov	bx, cs
		mov	di, offset EntProcessChildNCallback
		call	EntCompProcessChildren
returnOptr:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_COMPONENT
		movdw	es:[di].CD_data.LD_gen_dword, cxdx
	.leave
	ret
returnNullOptr:
		clrdw	cxdx
		jmp	returnOptr
EntActionGetChildren	endm


; ds:si = child
; return cx:dx = child
EntProcessChildNCallback proc far

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		stc
		ret

EntProcessChildNCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntFindChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds posisition of a given child

CALLED BY:	MSG_ENT_FIND_CHILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		cx:dx	= optr of child
RETURN:		ax	- position of child or -1 if not found.
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntFindChild	method EntClass, 
					MSG_ENT_FIND_CHILD
	uses	cx, dx, bp, di, bx
		.enter
		mov	ax, offset EI_link
		mov	bx, Ent_offset
		mov	di, offset EI_comp
		call	ObjCompFindChild
		mov	ax, -1
		jc	done
		mov	ax, bp
done:
		.leave
		ret
EntFindChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntFindChildAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the position of a child, return its optr

CALLED BY:	MSG_ENT_FIND_CHILD_AT_POSITION
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		cx	= Number of child to find
		carry set if not found
		^lcx:dx = child or null if no child at that position
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntFindChildAtPosition	method dynamic EntClass, 
					MSG_ENT_FIND_CHILD_AT_POSITION
	uses	di, bp
		.enter
		mov	ax, offset EI_link
		mov	bx, Ent_offset
		mov	di, offset EI_comp
		mov	dx, cx			; number of child
		clr	cx			; find at position
		call	ObjCompFindChild
		jnc	done
		clrdw	cxdx
done:
		.leave
		ret
EntFindChildAtPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntCountChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Counts ent children of an object.

CALLED BY:	MSG_ENT_COUNT_CHILDREN
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		ax	= # of ent children.
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntCountChildren	method dynamic EntClass, 
					MSG_ENT_COUNT_CHILDREN
	uses	bx, di, dx
		.enter
		clr	bx
		mov	ax, bx
		mov	di, OCCT_COUNT_CHILDREN
		call	EntCompProcessChildren
		mov_tr	ax, dx
		.leave
		ret
EntCountChildren	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup whatever we need to

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		dx	= handle to store in EI_interpreter
RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	master levels built out

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntInitialize	method dynamic EntClass, 
					MSG_ENT_INITIALIZE
		uses	ax, cx, dx, bp
		.enter

	;
	; We need to build out our class heirarchy before those who
	; subclassed us can muck with various instance data.
	; We send a message to our superclass that it does not know about
	; to make sure the whole tree above us gets built out.
	;	
		mov	di, offset EntClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset

		BitSet	ds:[di].EI_state, ES_INITIALIZED

	;;  	we now just use the stuff in the EntObjBlockHeader
	;; 	mov	ds:[di].EI_interpreter, dx
		.leave
		ret
EntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntValidateParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for this message -- prevents it from building
		out master levels above ent.

CALLED BY:	MSG_ENT_VALIDATE_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
RETURN:		ax	= 0
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntValidateParent	method dynamic EntClass, 
					MSG_ENT_VALIDATE_PARENT
		clr	ax
		ret
EntValidateParent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntValidateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for this message -- check instance data to see
		if we accept children.

CALLED BY:	MSG_ENT_VALIDATE_CHILD
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
RETURN:		ax	= 0, if accept child,
			= 1, if deny
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntValidateChild	method dynamic EntClass, 
					MSG_ENT_VALIDATE_CHILD
		clr	ax
		test	ds:[di].EI_flags, mask EF_ALLOWS_CHILDREN
		jnz	done
		inc	ax
done:
		ret
EntValidateChild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntHandleEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the interpreter has a function defined for the
		component for the current event the event recieved.  Pass on
		arguments from the event and add "self" as an argument.

CALLED BY:	MSG_ENT_HANDLE_EVENT, MSG_ENT_HANDLE_EVENT_WITH_KEY
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		cx:dx	= EntHandleEventStruct
RETURN:		ax	= 1 if handled, 0 if not.
		cx:dx.EHES_eventID will be overwritten with the function key
		for the event handler called.  This may be used with
		MSG_ENT_HANDLE_EVENT_WITH_KEY for better performance.
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; This is guess at the stack space needed for a call into the interpreter
; The higher this number, the fewer recursive calls you can have in events.
; (where an event sets a property that triggers another event).
; 1200 is too small.
; Moving funcFullName off the stack would probably help.
STACK_THRESHOLD equ 2000	
EntHandleEvent	method dynamic EntClass, 	MSG_ENT_HANDLE_EVENT,
						MSG_ENT_HANDLE_EVENT_WITH_KEY
	args		local	fptr.EntHandleEventStruct
	taskhan		local	hptr
	self		local	optr
	funcFullName	local	128 dup (char)		;proto_funcName
	paramBuffer	local	10 dup (ComponentData)

ForceRef funcFullName

	; Just bail if the component's module has been destroyed
	; Note we haven't hit a .enter yet
		tst	ds:[EOBH_task]
		jnz	afterCheck
		clr	ax
		ret
afterCheck:

ifdef KERNEL_SUPPORTS_ERRORS_IN_TBSS
	;
	; Currently the Kernel does not support errors in ThreadBorrow
	; StackSpace, so this is commented out.
	; Also we need to ensure that none of parameters passed in point
	; to something on the stack.
	; *Note: This can't be moved to a separate function without messing
	; with the stack even more.
		
	;
	; If we are low on stack space, don't call into the interpreter.
	; Instead put up a dialog to tell the user bad things are happening.
		mov	di, STACK_THRESHOLD
		call	ThreadBorrowStackSpace
else
		mov	ax, ss:[TPD_stackBot]
		add	ax, STACK_THRESHOLD
	; if sp < ax, not enough space
		cmp	sp, ax		; carry will be clear if sp >= ax
endif
		jnc	beginFunc

	;
	; Let the user know something went wrong
	;
		clr	ax
		pushdw	axax			; don't care about help
		pushdw	axax			; customTriggers
		pushdw	axax			; string arg 2
		pushdw	axax			; string arg 1
		mov	di, offset stackProblemString
		pushdw	csdi			; string to use
		mov	di, (CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		push	di			; custom flags
		call	UserStandardDialog
		clr	ax

		ret
beginFunc:
		
		
		uses	cx, dx, bp, es, ds, si
		.enter

		movdw	ss:[args], cxdx
;;.warn -jmp
ifdef KERNEL_SUPPORTS_ERRORS_IN_TBSS
		push	di		; token for ThreadReturnStackSpace
endif
		
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[self], bxsi
		mov	bx, ds:[EOBH_task]
		mov	ss:[taskhan], bx

EC <		call	ECCheckStack	>

	; Skip getting the function key, if we've already got it
	;
		cmp	ax, MSG_ENT_HANDLE_EVENT_WITH_KEY
		je	gotKey
		call	EntConstructHandlerName
		cmp	ax, NULL_KEY
		je	funcNotFound
	
		mov 	dx, 0
		les	di, ss:[args]
		movdw	es:[di].EHES_eventID.EID_eventKey, dxax
gotKey:
	;
	; Push paramters on stack for call to legos
	;
	;  BASCO takes arguments in reverse order, the format is
	;  one byte for the type and four bytes for the data
	; 
	;  for now we just have one argument, an interger so it looks like
	;  so   TYPE_INTEGER data

		segmov	es, ss
		lea	di, ss:[paramBuffer]
		lds	si, ss:[args]

	;  store the number of params

		mov	cx, ds:[si].EHES_argc
		lea	si, ds:[si].EHES_argv
		
		mov	al, cl
		inc	al
		stosb

	; store "self"
		mov	al, LT_TYPE_COMPONENT

		stosb
		mov	ax, ss:[self].offset
		stosw
		mov	ax, ss:[self].handle
		stosw

	; ds:si points to a ComponentData struct
		jcxz	doCall

argLoop:
	; *Note*: we store the type as a byte instead of as an integer.  The enum
	; is an integer and thus too big.
	; 
		mov	ax, ds:[si].CD_type
		stosb

storeNormalArg::
		mov	ax, ds:[si].CD_data.LD_gen_dword.low
		stosw
		mov	ax, ds:[si].CD_data.LD_gen_dword.high
		stosw
		add	si, size ComponentData
		loop	argLoop

doCall:
		push	bp

	;;  fetch return value's address to pass to CallFunction
		les	di, ss:[args]
		tstdw	es:[di].EHES_result
		jz	pushTwoNulls
		lds	si, es:[di].EHES_result
		
		add	si, offset CD_data
		push	ds, si
		add	si, offset CD_type - offset CD_data
		push	ds, si
		jmp	afterPushes
pushTwoNulls:
		clr	ax
		push	ax, ax, ax, ax
afterPushes:				
		lea	di, ss:[paramBuffer]
		push	ss, di			; params
	
		les	di, ss:[args]
		pushdw	es:[di].EHES_eventID.EID_eventKey

		mov	ax, ss:[taskhan]
		push	ax			; taskhan

		call	RunCallFunctionWithKey
		add	sp, 18			; take args off stack
		pop	bp
		mov	ax, 1
ifdef KERNEL_SUPPORTS_ERRORS_IN_TBSS
		pop	di			; token
		call	ThreadReturnStackSpace
endif
		
done:		
;;.warn @jmp
		.leave
		ret
funcNotFound:
		clr	ax
		jmp	done
		
EntHandleEvent	endm
;
; Not in resource as it ThreadBorrowStackSpace probably couldn't find space
; for the stack.
stackProblemString TCHAR "You ran out of stack space and the program may not operate correctly.  It is likely that there is an infinite loop", C_NULL
if 0
		mov	ax, ss:[TPD_stackBot]
		add	ax, STACK_THRESHOLD
	; if sp < ax, not enough space
		cmp	sp, ax		; carry will be clear if sp >= ax
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntConstructHandlerName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the name of an event handler based on the component's
		instance data and the passed event name.  

CALLED BY:	EntHandleEvent
PASS:		ds:di	= component's instance data
		stack inherited from EntHandleEvent

RETURN:		ax <- function # or NULL_KEY if not found

DESTROYED:	bx-dx
STRATEGY:
		Lock down the string on the heap associated with
		the property.  Copy the string into a buffer and unlock it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	5/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntConstructHandlerName	proc	near
	class	EntClass
	uses	ds,es,si,di
	.enter inherit EntHandleEvent

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		mov	ax, ds:[di].EI_proto
		call	RunHeapLock_asm

	; es:di <- proto.  Put <proto>_ into ss:funcFullName
	;
		push	ds		; save obj block
		push	ax		; save token

		segmov	ds, es
		mov	si, di		; ds:si <- proto
		segmov	es, ss
		lea	di, ss:[funcFullName]
		Assert	fptr	dssi
		Assert	fptr	esdi
		LocalCopyString			; writes in funcFullName
		LocalPrevChar	esdi
		LocalLoadChar	ax, C_UNDERSCORE
		LocalPutChar	esdi, ax

		pop	ax
		pop	ds		; obj block
		call	RunHeapUnlock_asm

	; copy event name.  es:di points after the _
	;
		lds	si, ss:[args]		; fptr to struct
		lds	si, ds:[si].EHES_eventID.EID_eventName	; fptr to name
		LocalCopyString
		
	; Now check to see if it exists
	;
		mov	ax, ss:[taskhan]
		lea	di, ss:[funcFullName]
		Assert	nullTerminatedAscii, esdi
		push	es, di			; push name of function 
		push	ax			; interp handle
		call	RunFindFunction
		add	sp, 6			; restore stack
	.leave
	ret
EntConstructHandlerName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSendToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the given event to all children of an EntClass object.

CALLED BY:	MSG_ENT_SEND_TO_CHILDREN

PASS:		*ds:si	   = EntClass object
		^hcx	   = ClassedEvent (freed by this handler)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

SIDE EFFECTS:	This routine MAY resize LMem and/or object blocks, moving
		them on the heap and invalidating stored segment pointers
		to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSendToChildren	method dynamic EntClass, 
					MSG_ENT_SEND_TO_CHILDREN
		.enter
		push	cx		; save ClassedEvent to be freed later

		clr	ax
		mov	bx, cs
		mov	di, offset EntSendToChildrenCallback
		call	EntCompProcessChildren
	;
	; after calling all the appropriate children, free the classed event
	;
		pop	bx		; restore ClassedEvent
		call	ObjFreeMessage
		.leave
		ret
EntSendToChildren	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSendToChildrenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL - EntSendToChildren via ObjCompProcessChildren

PASS:		*ds:si	= child object
		*es:di	= parent object
		ax	= message to send 
		cx	= ClassedEvent 

RETURN:		carry		= set to end processing
		ax, cx, dx, bp	= data to send to next child

DESTROYED:	bx, si, di, ds, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSendToChildrenCallback	proc	far
		uses	ax, cx, dx, bp
		.enter
		mov	bx, cx			; bx	  = ClassedEvent
		mov	cx, ds:[LMBH_handle]	; ^lcx:si = this child	  
		call	MessageSetDestination	; set destination to this obj
		mov	di, mask MF_CALL or mask MF_RECORD
		call	MessageDispatch
		clc
		.leave
		ret
EntSendToChildrenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSendToParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_SEND_TO_PARENT
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
		^hcx	= ClassedEvent
RETURN:		
DESTROYED:	

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSendToParent method dynamic EntClass, 
					MSG_ENT_SEND_TO_PARENT

		.enter
		clr	si
		mov	bx, cx
		mov	ax, offset EntCallParent
		pushdw	csax			; cs:ax = callback routine
		call	MessageProcess		; process event
		.leave
		ret
EntSendToParent endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntCallParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si		= EntClass object
		ax		= message
		cx, dx, bp	= data

RETURN:		
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntCallParent	proc	far
	class	EntClass
	uses	bx,di
	.enter
	mov	bx, offset Ent_offset	; Call generic parent
	mov	di, offset EI_link	; Pass generic linkage
	call	ObjLinkCallParent
	.leave
	ret
EntCallParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the flags

CALLED BY:	MSG_ENT_SET_FLAGS
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		cl 	= EntFlags to set
		dl	= EntFlags to clear
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 4/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetFlags	method dynamic EntClass, 
					MSG_ENT_SET_FLAGS
		.enter

		mov	al, ds:[di].EI_flags
		or	al, cl
		not	dl
		and	al, dl
		mov	ds:[di].EI_flags, al
		not	dl
		.leave
		ret
EntSetFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current flags for this component

CALLED BY:	MSG_ENT_GET_FLAGS
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		al	= EntFlags
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 4/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetFlags	method dynamic EntClass, 
					MSG_ENT_GET_FLAGS
		.enter
		mov	al, ds:[di].EI_flags	
		.leave
		ret
EntGetFlags	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return that this class is unknown.

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
RETURN:		cx:dx	= fptr to "unknown"
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/21/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
unknownClassString	TCHAR	'unknown', C_NULL

EntGetClass	method dynamic EntClass, 
					MSG_ENT_GET_CLASS
		.enter

		mov	cx, cs
		mov	dx, offset unknownClassString
		
		.leave
		ret
EntGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetPropertyExternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used when the caller wants to get a string into a buffer
		instead of getting a token

CALLED BY:	MSG_ENT_GET_PROPERTY_EXTERNAL
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= GetPropertyArgs with CD_data.LD_fptr pointing to
			  buffer
			  runHeapInfoPtr won't be valid.
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPropertyExternalArgs	struct
	SPEA_propName		fptr.TCHAR
	SPEA_compDataPtr	fptr.ComponentData
SetPropertyExternalArgs	ends

GetPropertyExternalArgs	struct
	GPEA_propName		fptr.TCHAR
	GPEA_compDataPtr	fptr.ComponentData
GetPropertyExternalArgs	ends

EntGetPropertyExternal	method dynamic EntClass, 
					MSG_ENT_GET_PROPERTY_EXTERNAL
		uses	ax, cx, dx, bp
		.enter
		clr	ax
		push	ds:[LMBH_handle]		; objblock handle
		pushdw	dsax
		call	RunComponentLockHeap
		add	sp, size fptr
	;
	; Make the call and get a StringToken
	;
		mov	bx, bp				; bx -> old args
		sub	sp, size GetPropertyArgs
		mov	bp, sp				; bp -> new args
		movdw	ss:[bp].GPA_runHeapInfoPtr, dxax
		movdw	ss:[bp].GPA_compDataPtr, ss:[bx].GPEA_compDataPtr, ax
		movdw	ss:[bp].GPA_propName, ss:[bx].GPEA_propName, ax
		les	di, ss:[bx].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_ILLEGAL
		pushdw	esdi
		les	di, es:[di].CD_data.LD_fptr ; passed in buffer
		mov	ax, MSG_ENT_GET_PROPERTY
		call	ObjCallInstanceNoLock
		movdw	cxdx, dssi
		popdw	dssi
		cmp	ds:[si].CD_type, LT_TYPE_STRING
		LONG_EC	jne	done
		movdw	dssi, cxdx

	; dxax = rhi
		movdw	dxax, ss:[bp].GPA_runHeapInfoPtr
		
	;
	; Copy the string into the desired buffer
	;
		lds	si, ss:[bp].GPA_compDataPtr
		Assert	fptr	dssi
		Assert	e	ds:[si].CD_type, LT_TYPE_STRING


	; Lock it down;
		sub	sp, size RunHeapLockWithSpaceStruct
		mov	bx, sp
		mov	cx, ds:[si].CD_data.LD_string
		mov	ss:[bx].RHLS_token, cx
		movdw	ss:[bx].RHLS_rhi, dxax
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	ss:[bx].RHLWSS_tempES, es
		mov	ss:[bx].RHLWSS_tempDI, di	; es:di = passed buffer

		call	RunHeapLock
		mov	bx, sp

	; Copy it
		lds	si, ss:[bx].RHLS_eptr
		mov	es, ss:[bx].RHLWSS_tempES
		mov	di, ss:[bx].RHLWSS_tempDI
		Assert	nullTerminatedAscii	dssi
		Assert	fptr	esdi

		LocalCopyString


	; The component didn't increment the token ref count.
	; We can't just decref or delete it.  We need to incref, then
	; decref it.  Weird API, I know.
		call	RunHeapUnlock
		call	RunHeapIncRef
		call	RunHeapDecRef

		add	sp, size RunHeapLockWithSpaceStruct

done:
		add	sp, size GetPropertyArgs
		pop	bx				; objblock handle
		Assert	objblock, bx
		call	MemDerefDS
		clr	ax
		pushdw	dsax
		call	RunComponentUnlockHeap
		add	sp, size fptr
		
		.leave
		ret
EntGetPropertyExternal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetPropertyExternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a property from a given fptr instead of a HeapToken

CALLED BY:	MSG_ENT_SET_PROPERTY_EXTERNAL
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		ss:bp	= EntSetProperty args less runHeapInfoPtr
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetPropertyExternal	method dynamic EntClass, 
					MSG_ENT_SET_PROPERTY_EXTERNAL
		uses	ax, cx, dx, bp
		.enter
	;
	; First create a string token to pass on
	;
		clr	ax
		pushdw	dsax				; args
		call	RunComponentLockHeap
		add	sp, size fptr

		mov	bx, bp				; bx -> old args
		sub	sp, size SetPropertyArgs
		mov	bp, sp				; bp -> new args
		movdw	ss:[bp].SPA_runHeapInfoPtr, dxax
		movdw	ss:[bp].SPA_compDataPtr, ss:[bx].SPEA_compDataPtr, ax
		movdw	ss:[bp].SPA_propName, ss:[bx].SPEA_propName, ax
		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_STRING
		je	doStringStuff
		mov	ax, MSG_ENT_SET_PROPERTY
		call	ObjCallInstanceNoLock
		jmp	done

doStringStuff:
		movdw	dxax, ss:[bp].SPA_runHeapInfoPtr

		sub	sp, size RunHeapAllocStruct
		mov	bx, sp

		movdw	ss:[bx].RHAS_rhi, dxax

		les	di, ss:[bp].SPA_compDataPtr
		les	di, es:[di].CD_data.LD_fptr

		Assert	nullTerminatedAscii	esdi
		call	LocalStringSize
		inc	cx
DBCS <		inc	cx						>
		mov	ss:[bx].RHAS_size, cx

		movdw	ss:[bx].RHAS_data, esdi
		mov	ss:[bx].RHAS_refCount, 1
		mov	ss:[bx].RHAS_type, RHT_STRING

		call	RunHeapAlloc
		mov	bx, sp

		movdw	cxdx, ss:[bx].RHAS_rhi
		add	sp, size RunHeapAllocStruct

		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		movdw	ss:[bx].RHLS_rhi, cxdx
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	ss:[bx].RHLS_token, ax
		call	RunHeapLock
		mov	bx, sp
		mov	ax, ss:[bx].RHLS_token

	;
	; Now, send the message
	;
		les	di, ss:[bp].SPA_compDataPtr
		clrdw	es:[di].CD_data.LD_gen_dword
		mov	es:[di].CD_data.LD_string, ax	; token
		mov	ax, MSG_ENT_SET_PROPERTY
		call	ObjCallInstanceNoLock

	;
	; Decrement the refCount on the string
	;

		call	RunHeapUnlock
		call	RunHeapDecRef
		add	sp, size RunHeapLockStruct

done:
		add	sp, size SetPropertyArgs
		Assert	objblock, ds:[LMBH_handle]
		clr	ax
		pushdw	dsax
		call	RunComponentUnlockHeap
		add	sp, size fptr

		.leave
		ret
EntSetPropertyExternal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the state as set in instance data.

CALLED BY:	MSG_ENT_GET_STATE
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		dl	- new state
		dh	- clear
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntGetState	method dynamic EntClass, 
					MSG_ENT_GET_STATE
		.enter
		clr	dh
		mov	dl, ds:[di].EI_state
		
		.leave
		ret
EntGetState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state for the object, just instance data.

CALLED BY:	MSG_ENT_SET_STATE
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		cl	- bits to set
		ch	- bits to clear
RETURN:		dl	- new state
		dh	- clear
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSetState	method dynamic EntClass, 
					MSG_ENT_SET_STATE
		.enter
		or	ds:[di].EI_state, cl	; set bits
		not	ch			; mask bits clearn
		and	ds:[di].EI_state, ch
		not	ch
		clr	dh
		mov	dl, ds:[di].EI_state
		
		.leave
		ret
EntSetState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntSendMeesageToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	this is code that just passes a message down the ent tree

CALLED BY:	MSG_ENT_UNIV_LEAVE, PAUSE, RESUME
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: just propogate this too all the children in case
			somebody wants to know

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntSendMessageToChildren	method dynamic EntClass, 
					MSG_ENT_UNIV_LEAVE,
					MSG_ENT_PAUSE,
					MSG_ENT_RESUME
		uses	ax, cx, dx, bp
		.enter
	;; first recurse down the ent tree
		mov	bx, ds:LMBH_handle
		mov	di, mask MF_RECORD
		call	ObjMessage

	;  move event handle into cx for ENT_SENT_TO_CHILDREN
		mov	cx, di
		mov	ax, MSG_ENT_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock
		
		.leave
		ret
EntSendMessageToChildren	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EntRemoveComponentReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Null out any stored component references in the user-defined
		component table.

CALLED BY:	MSG_ENT_REMOVE_COMPONENT_REFERENCES
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		^fcx:dx = RemoveReferenceStruct
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EntRemoveComponentReferences	method dynamic EntClass, 
					MSG_ENT_REMOVE_COMPONENT_REFERENCES
		uses	es, bx
		.enter

	; Null out EOBH_task if it's one of the modules going away
		tst	ds:[EOBH_task]
		jz	afterEOBH

		segmov	es, ds, ax
		mov	bx, es:[EOBH_task]

		push	ds,si
		movdw	dssi, cxdx
		lds	si, ds:[si].RRS_modules

	; ds:si - null-terminated array of module handles
	; es - obj block
	; bx - es:EOBH_task
checkLoop:
		lodsw
		tst	ax
		jz	checkDone
		cmp	ax, bx
		jne	checkLoop
		clr	es:[EOBH_task]	; match, so null it otu
checkDone:
		pop	ds,si

afterEOBH:
		movdw	esbx, cxdx	; esbx <- RRS
		mov	bp, si		; save obj chunk
		mov	si, ds:[di].EI_propIndex
		cmp	si, 0
		je	recurse

	; Loop through custom property table, check if components
	; or modules have gone away.  Delete reference if so
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayGetCount
		mov	ax, cx
arrayLoop:
		dec	ax
		js	recurse		; if < 0, done

		call	ChunkArrayElementToPtr
		lea	di, ds:[di].NAE_data
		call	FixupDeletedComponentReference
		jmp	arrayLoop
		

recurse:
	; es:bx - RRS
		Assert	fptr, esbx
		movdw	cxdx, esbx
		mov	ax, MSG_ENT_REMOVE_COMPONENT_REFERENCES
		clr	bx, si		; dest object will be filled in
		mov	di, mask MF_RECORD
		call	ObjMessage

		push	di		; save event

		clr	ax
		mov	si, bp		; restore obj chunk
		mov	cx, di		; cx <- Event
		mov	bx, cs
		mov	di, offset EntSendToChildrenCallback
		call	EntCompProcessChildren

		pop	bx
		call	ObjFreeMessage
		.leave
		Destroy	ax, cx, dx, bp
		ret
EntRemoveComponentReferences	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupDeletedComponentReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current component OD is in the array
		of deleted components and if so pretends we no longer know
		about it.

CALLED BY:	EntRemoveComponentReferences
PASS:		ds:di		= Component Data
		^fes:bx		= RemoveReferenceStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Do one pass.  If the type is component, check it against
		the component array.  If it is a module, check it against
		the module array.  If neither, leave.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupDeletedComponentReference	proc	near
	uses	ax,bx,dx, es
		.enter
		cmp	ds:[di].CD_type, LT_TYPE_COMPONENT
		je	checkComp
		cmp	ds:[di].CD_type, LT_TYPE_MODULE
		je	checkModule
		jmp	done
checkComp:
		les	bx, es:[bx].RRS_comps
		movdw	dxax, ds:[di].CD_data.LD_comp
	;
	; FIXME: perhaps using scasw would be faster.
	;
	; es:bx	- array of optrs, null terminated
	; dxax	- stored optr
	; ds:di	- stored component data
scanLoop:
		cmpdw	es:[bx], 0
		je	done
		cmpdw	dxax, es:[bx]
		je	nullIt
		add	bx, size optr
EC <		push	bx,si, di
EC <		mov	di, bx						>
EC <		movdw	bxsi, es:[di]					>
EC <		call	ECCheckOD					>
EC <		pop	bx, si, di					>
		jmp	scanLoop
nullIt:
		clrdw	ds:[di].CD_data.LD_comp
		jmp	done

checkModule:
		les	bx, es:[bx].RRS_modules
		mov	dx, ds:[di].CD_data.LD_module
	;
	; FIXME: perhaps using scasw would be faster.

	; es:bx	- array of modules
	; dx = module we have stored
	; ds:di - stored component data
modScanLoop:
		cmp	{word}es:[bx], 0
		je	done
		cmp	dx, es:[bx]
		je	modNullIt
		add	bx, size hptr
		jmp	modScanLoop
modNullIt:
		clr	ds:[di].CD_data.LD_module

done:
		
		.leave
		ret
FixupDeletedComponentReference	endp

		

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EEntGetPropertyNameAndData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get a property from a propNumber

CALLED BY:	MSG_ENT_GET_PROPERTY_NAME_AND_DATA
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es 	= segment of EntClass
		ax	= message #
		ss:bp	= EntGetPropNameAndDataStruct
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EEntGetPropertyNameAndData	method dynamic EntClass, 
					MSG_ENT_GET_PROPERTY_NAME_AND_DATA
		uses	ax, cx, dx, bp
		.enter
		mov	cx, cs
		mov	bx, offset entPropertyTable
		mov	di, offset EntClass
		call	EntGetPropNameAndDataCommon
		.leave
		ret
EEntGetPropertyNameAndData	endm


