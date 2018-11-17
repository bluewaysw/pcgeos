COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		InstGrObj (Sample PC GEOS application)
FILE:		instgrobj.asm

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl	7/91		Initial version

DESCRIPTION:
	This file source code for the IGrObj application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for using the graphic object library. In this example 
	most the grobj objects needed are create with ObjInstantiate
	(hence the Inst in the directory and file names) and initialized 
	with messages. See the example DupGrObj for using the graphic object 
	library with grobj objects duplicated with ObjDuplicateResource and
	GeodeDuplicateResource.

	Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: instgrobj.asm,v 1.1 97/04/04 16:35:12 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def

include object.def
include graphics.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib grobj.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

IGProcessClass	class	GenProcessClass

;define messages for this class here.

IGProcessClass	endc

idata	segment
	IGProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; IGDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument. Placing the use VisContentClass here
; allows us to access the VisContent fields without generating warnings.

IGDocumentClass	class	GenDocumentClass
	uses	VisContentClass

IGDocumentClass endc

idata	segment
	IGDocumentClass
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_PROTOCOL_MAJOR	=	1
DOCUMENT_PROTOCOL_MINOR	=	0

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72


;    This is the structure of information stored in the vm files map block.
;

IGMapBlock	struct
    IGMB_body	optr			;VM block handle, chunk
					;of the GrObjBody.
					;Storing the vm block handle,
					;instead of the mem handle, so
					;that it won't have to relocate
					;and unrelocate it
IGMapBlock	ends


IG_OBJECT_NOT_AN_IGDOCUMENT		enum FatalErrors

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		instgrobj.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for IGProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE: IGDocumentRecalcSize -- MSG_VIS_RECALC_SIZE for IGDocumentClass

DESCRIPTION:	Calculate and return our size

PASS:
	*ds:si - instance data
	es - segment of IGDocumentClass

	ax - The message

	cx - RecalcSizeArgs
	dx - RecalcSizeArgs

RETURN:
	cx - width
	dx - height

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
IGDocumentRecalcSize	method dynamic	IGDocumentClass, MSG_VIS_RECALC_SIZE
	mov	cx, DOCUMENT_WIDTH
	mov	dx, DOCUMENT_HEIGHT
	ret

IGDocumentRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the document file (newly created).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of IGDocumentClass

RETURN:		
		carry - set if error
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentInitializeDocumentFile	method dynamic IGDocumentClass, \
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	.enter

	;    Get vm file handle, we'll need it in a moment
	;

	push	ds:[di].GDI_fileHandle

	;    Let superclass do its thang
	;

	mov	di,offset IGDocumentClass
	call	ObjCallSuperNoLock

	;    Allocate block to hold Attribute Manager and the GrObjBody
	;    and attach it to the vm file. The handles must be preserved,
	;    otherwise the block may get discarded and loaded back in
	;    with a different memory handle causing random obscure death 
	;    when we attempt to send messages to that object.
	;

	call	GeodeGetProcessHandle
	call	ProcInfo
	call	UserAllocObjBlock
	mov	cx,bx				;mem handle
	pop	bx				;vm file handle
	clr	ax				;create new vm block
	call	VMAttach
	call	VMPreserveBlocksHandle
	xchg	cx,bx				;vm file handle, mem handle

	;    Create and do REQUIRED initialization of AttributeManager
	;    and the GrObjBody.
	;

	call	IGDocumentCreateAttributeManager
	call	IGDocumentCreateGrObjBody

	;    At this point numerous other fields in the GrObjBody can
	;    be initialized. Including bound, margins, defaultOptions,
	;    rulers, etc
	;

	push	ax				;vm block handle
	sub	sp,size RectDWord
	mov	bp,sp
	clr	ax
	mov	ss:[bp].RD_left.low,ax
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.low,ax
	mov	ss:[bp].RD_top.high,ax
	mov	ss:[bp].RD_right.high,ax
	mov	ss:[bp].RD_bottom.high,ax
	mov	ss:[bp].RD_right.low,DOCUMENT_WIDTH
	mov	ss:[bp].RD_bottom.low,DOCUMENT_HEIGHT
	mov	dx, size RectDWord
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GB_SET_BOUNDS
	call	ObjMessage	
	add	sp,size RectDWord
	pop	ax				;vm block handle

	;    Store the GrObjBody od in the map block, so we can
	;    get to it later when we need to add it as a child of
	;    of the document/content. Store the vm block handle, 
	;    instead of the mem handle, because the vm block handle
	;    doesn't have to be relocated and urelocated.
	;

	mov	bx,cx				;vm file handle
	call	IGDocumentAllocMapBlock
	mov	dx,ax				;body vm block handle
	call	VMGetMapBlock
	call	VMLock
	mov	es,ax
	mov	es:IGMB_body.handle,dx		;body vm block handle
	mov	es:IGMB_body.chunk,si
	call	VMDirty
	call	VMUnlock

	Destroy 	ax,cx,dx,bp

	clc			;no error
	.leave
	ret
IGDocumentInitializeDocumentFile		endm








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentCreateAttributeManager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize an attribute manager

CALLED BY:	INTERNAL
		IGDocumentInitializeDocumentFile

PASS:		
		bx - object block to create Attribute Manager in

RETURN:		
		bx:si - OD of ObjectAttributeManager

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentCreateAttributeManager		proc	near
	uses	ax,di,es
	.enter

	;    Instantiate an Attribute Manager,
	;

	mov	di, segment GrObjAttributeManagerClass
	mov	es, di
	mov	di, offset GrObjAttributeManagerClass
	call	ObjInstantiate

	;    Have attribute manager perform other basic initialization 
	;    and then have it create all the attribute and style arrays
	;    that it needs to use.
	;

	mov	ax,MSG_GOAM_CREATE_ALL_ARRAYS
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
IGDocumentCreateAttributeManager		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentCreateGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the GrObjBody and perform REQUIRED
		initialization.

CALLED BY:	INTERNAL
		IGDocumentInitializeDocumentFile

PASS:		
		bx - vm mem handle 
		si - chunk of AttributeManager (routine assumes it
						is in same block as body)
	
RETURN:		
		bx:si - OD of ObjectGrObjBody

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentCreateGrObjBody		proc	near
	uses	ax,cx,dx,di,es
	.enter

	mov	dx,si					;GOAM chunk 

	;    Instantiate the graphic body
	;

	mov	di, segment GrObjBodyClass
	mov	es, di
	mov	di, offset GrObjBodyClass
	call	ObjInstantiate

	;    Attach the AttributeManager to the GrObjBody.
	;    The GrObjBody cannot function without an AttributeManager,
	;    though several GraphicBodies can be attached to the
	;    same AttributeManager.
	;

	mov	cx,bx					;GOAM block
	mov	ax,MSG_GB_ATTACH_GOAM
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage


	.leave
	ret
IGDocumentCreateGrObjBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentAllocMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the map block in the document vm file

CALLED BY:	INTERNAL
		IGDocumentInitializeDocumentFile

PASS:		
		bx -  vm file handle

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentAllocMapBlock		proc	near
	uses	ax,cx
	.enter

	mov	cx, size IGMapBlock
	clr	ax					;VM id
	call	VMAlloc
	call	VMSetMapBlock

	.leave
	ret
IGDocumentAllocMapBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document has been opened. Need to add body as child
		of document and notify it of opening

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of IGDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentAttachUI	method dynamic IGDocumentClass, \
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	.enter

	;    Have superclass do its thang
	;

	mov	di, offset IGDocumentClass	
	call	ObjCallSuperNoLock

	;    Set bits for large document model
	;    clear bits for unmanaged geometry
	;

	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL \
				 or mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
	andnf	ds:[di].VI_attrs, not (mask VA_MANAGED)
	andnf	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
				       or mask VOF_GEO_UPDATE_PATH)
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	;    Get output descriptor of GrObjBody from map block
	;

	call	IGDocumentGetBodyOD

	;    Add the graphic body as the first child of the
	;    Document/Content. Don't mark dirty because we don't
	;    want the document dirtied as soon as it is open, nor
	;    do we save the Document/Content or the parent pointer
	;    in the GrObjBody.
	;

	mov	bp,CCO_FIRST
	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.
	;

	mov	bx,cx					;body vm memory handle
	mov	si,dx					;body chunk
	GetResourceHandleNS	IGrObjHead,cx
	mov	dx, offset IGrObjHead
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_ATTACH_UI
	call	ObjMessage

	Destroy	ax,cx,dx,bp

	.leave
	ret
IGDocumentAttachUI		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document is being closed. Need to remove body
		from document.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of IGDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentDetachUI	method dynamic IGDocumentClass, \
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter

	;    Get output descriptor of GrObjBody from map block
	;

	call	IGDocumentGetBodyOD

	;    Notify the GrObjBody that it is about to be
	;    removed from the Document/Content and closed
	;

	push	si					;document chunk
	mov	bx,cx					;body vm memory handle
	mov	si,dx					;body chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_DETACH_UI
	call	ObjMessage

	;    Remove the GrObjBody from the Document/Content.
	;    Don't mark dirty because we don't save the Document/Content 
	;    or the parent pointer in the GrObjBody.
	;
	;

	clr	bp					;don't dirty
	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_REMOVE
	call	ObjMessage
	pop	si					;document chunk

	;    Have superclass do its thang
	;

	mov	ax,MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset IGDocumentClass	
	call	ObjCallSuperNoLock


	Destroy	ax,cx,dx,bp

	.leave
	ret
IGDocumentDetachUI		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IGDocumentGetBodyOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the output descriptor of the GrObjBody. The
		vm block handle and chunk of the GrObjBody are
		stored in the map block. These must be retrieved
		and then the vm block handle must be converted to
		to a vm memory handle.

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - Document/Content

RETURN:		
		cx:dx	- GrObjBody OD

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IGDocumentGetBodyOD		proc	near
	class	IGDocumentClass
	uses	ax,bp,di,ds
	.enter

EC <	call	ECCheckIGDocument					>

	mov	di,ds:[si]
	add	di,ds:[di].IGDocument_offset
	mov	bx,ds:[di].GDI_fileHandle
	call	VMGetMapBlock
	call	VMLock
	mov	ds,ax
	mov	ax,ds:IGMB_body.handle		;body vm block handle
	mov	dx,ds:IGMB_body.chunk
	call	VMUnlock
	call	VMVMBlockToMemBlock
	mov	cx,ax				;body vm memory handle

	.leave
	ret
IGDocumentGetBodyOD		endp


if	ERROR_CHECK




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIGDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the object at *ds:si is indeed a
		IGDocumentClass object

CALLED BY:	INTENRAL (UTILITY)

PASS:		
		*ds:si

RETURN:		
		nothing

DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckIGDocument		proc	near
	class	IGDocumentClass
	uses	bx,di,es
	.enter

	pushf	

	;    Dgroup is guaranteed to be locked while we are excuting
	;    so we can just derefence the resource handle to get
	;    the class segment.
	;

	GetResourceHandleNS IGDocumentClass, bx
	call	MemDerefES
	mov	di,offset IGDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC IG_OBJECT_NOT_AN_IGDOCUMENT
	popf

	.leave
	ret
ECCheckIGDocument		endp


endif

CommonCode	ends		;end of CommonCode resource
