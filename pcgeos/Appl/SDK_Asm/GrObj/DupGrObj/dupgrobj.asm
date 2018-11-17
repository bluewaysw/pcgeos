COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DupGrObj (Sample PC GEOS application)
FILE:		dupgrobj.asm

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl	7/91		Initial version

DESCRIPTION:
	This file source code for the DGrObj application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for using the graphic object library. In this example 
	most the grobj objects needed are duplicated with
	ObjDuplicateResource and GeodeDuplicateResource (hence the Dup in the 
	directory and file names)
	See the example InstGrObj for creating the needed graphic objects
	 with ObjInstantiate and initializing them with messages.

	Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: dupgrobj.asm,v 1.1 97/04/04 16:33:33 newdeal Exp $

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

DGProcessClass	class	GenProcessClass

;define messages for this class here.

DGProcessClass	endc

idata	segment
	DGProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; DGDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument. Placing the use VisContentClass here
; allows us to access the VisContent fields without generating warnings.

DGDocumentClass	class	GenDocumentClass
	uses	VisContentClass

DGDocumentClass endc

idata	segment
	DGDocumentClass
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

DGMapBlock	struct
    DGMB_vmBlockHandle	word		;VM block handle of the block
					;that contains the GrObjBody
					;and the GOAM
					;Storing the vm block handle,
					;instead of the mem handle, so
					;that it won't have to relocate
					;and unrelocate it
DGMapBlock	ends


DG_OBJECT_NOT_AN_DGDOCUMENT		enum FatalErrors

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		dupgrobj.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for DGProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE: DGDocumentRecalcSize -- MSG_VIS_RECALC_SIZE for DGDocumentClass

DESCRIPTION:	Calculate and return our size

PASS:
	*ds:si - instance data
	es - segment of DGDocumentClass

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
DGDocumentRecalcSize	method dynamic	DGDocumentClass, MSG_VIS_RECALC_SIZE
	mov	cx, DOCUMENT_WIDTH
	mov	dx, DOCUMENT_HEIGHT
	ret

DGDocumentRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DGDocumentInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the document file (newly created).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DGDocumentClass

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
DGDocumentInitializeDocumentFile	method dynamic DGDocumentClass, \
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	.enter

	;    Get vm file handle, we'll need it in a moment
	;

	push	ds:[di].GDI_fileHandle

	;    Let superclass do its thang
	;

	mov	di,offset DGDocumentClass
	call	ObjCallSuperNoLock


	;    Duplicate block with GrObjBody and GrObjAttributeManager
	;    in it and have its burden thread be our process thread.
	;    The attach block to the vm file.The handles must be preserved,
	;    otherwise the block may get discarded and loaded back in
	;    with a different memory handle causing random obscure death 
	;    when we attempt to send messages to that object.
	;

	GetResourceHandleNS	BodyGOAMRuler, bx
	clr	ax				; have current geode own block
	clr	cx				; have current thread run block
	call	ObjDuplicateResource
	mov	cx,bx				;mem handle of new block
	pop	bx				;vm file handle
	clr	ax				;create new vm block
	call	VMAttach
	push	ax				;vm block handle
	call	VMPreserveBlocksHandle
	xchg	cx,bx				;vm file handle, mem handle

	;    Have attribute manager create all the attribute and style arrays
	;    that it needs to use.
	;

	mov	si, offset DGOAM
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOAM_CREATE_ALL_ARRAYS
	call	ObjMessage

	;    Store the vm block handle in the map block, so we can
	;    get to the objects each time the document is opened.
	;    Store the vm block handle, instead of the mem handle, 
	;    because the vm block handle
	;    doesn't have to be relocated and urelocated.
	;

	mov	bx,cx				;vm file handle
	call	DGDocumentAllocMapBlock
	call	VMGetMapBlock
	call	VMLock
	mov	es,ax
	pop	es:[DGMB_vmBlockHandle]		;body vm block handle
	call	VMDirty
	call	VMUnlock

	Destroy 	ax,cx,dx,bp

	clc			;no error
	.leave
	ret
DGDocumentInitializeDocumentFile		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DGDocumentAllocMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the map block in the document vm file

CALLED BY:	INTERNAL
		DGDocumentInitializeDocumentFile

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
DGDocumentAllocMapBlock		proc	near
	uses	ax,cx
	.enter

	mov	cx, size DGMapBlock
	clr	ax					;VM id
	call	VMAlloc
	call	VMSetMapBlock

	.leave
	ret
DGDocumentAllocMapBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DGDocumentAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document has been opened. Need to add body as child
		of document and notify it of opening

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DGDocumentClass

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
DGDocumentAttachUI	method dynamic DGDocumentClass, \
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	.enter

	;    Have superclass do its thang
	;

	mov	di, offset DGDocumentClass	
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

	call	DGDocumentGetBodyOD

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
	GetResourceHandleNS	DGrObjHead,cx
	mov	dx, offset DGrObjHead
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_ATTACH_UI
	call	ObjMessage

	Destroy	ax,cx,dx,bp

	.leave
	ret
DGDocumentAttachUI		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DGDocumentDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document is being closed. Need to remove body
		from document.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DGDocumentClass

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
DGDocumentDetachUI	method dynamic DGDocumentClass, \
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter

	;    Get output descriptor of GrObjBody from map block
	;

	call	DGDocumentGetBodyOD

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
	;

	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_REMOVE
	call	ObjMessage
	pop	si					;document chunk

	;    Have superclass do its thang
	;

	mov	ax,MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset DGDocumentClass	
	call	ObjCallSuperNoLock

	Destroy	ax,cx,dx,bp

	.leave
	ret
DGDocumentDetachUI		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DGDocumentGetBodyOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the output descriptor of the GrObjBody. The
		vm block handle of the GrObjBody is
		stored in the map block. This must be retrieved
		and then the vm block handle must be converted to
		to a vm memory handle. The chunk of the GrObjBody
		is always the same since we duplicated the 
		ui template that it is in.

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
DGDocumentGetBodyOD		proc	near
	class	DGDocumentClass
	uses	ax,bp,di,ds
	.enter

EC <	call	ECCheckDGDocument					>

	mov	di,ds:[si]
	add	di,ds:[di].DGDocument_offset
	mov	bx,ds:[di].GDI_fileHandle
	call	VMGetMapBlock
	call	VMLock
	mov	ds,ax
	mov	ax,ds:[DGMB_vmBlockHandle]	;body vm block handle
	call	VMUnlock
	call	VMVMBlockToMemBlock
	mov	cx,ax				;body vm memory handle
	mov	dx, offset DGrObjBody		;body chunk

	.leave
	ret
DGDocumentGetBodyOD		endp


if	ERROR_CHECK




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDGDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the object at *ds:si is indeed a
		DGDocumentClass object

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
ECCheckDGDocument		proc	near
	class	DGDocumentClass
	uses	bx,di,es
	.enter

	pushf	

	;    Dgroup is guaranteed to be locked while we are excuting
	;    so we can just derefence the resource handle to get
	;    the class segment.
	;

	GetResourceHandleNS DGDocumentClass, bx
	call	MemDerefES
	mov	di,offset DGDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC DG_OBJECT_NOT_AN_DGDOCUMENT
	popf

	.leave
	ret
ECCheckDGDocument		endp


endif

CommonCode	ends		;end of CommonCode resource
