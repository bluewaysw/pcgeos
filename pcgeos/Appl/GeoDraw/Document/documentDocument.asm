COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentDocument.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name	
	----	
DrawDocumentDuplicateMainBlock
DrawDocumentInitMapBlockBoundsMargins
DrawDocumentInitGrObjBody
DrawDocumentInitGOAM
DrawDocumentAttachRulerUI
DrawDocumentDetachRulerUI

METHOD HANDLERS:
	Name	
	----	
DrawDocumentInitializeDocumentFile
DrawDocumentAttachUI
DrawDocumentDetachUI
DrawDocumentVisDraw
DrawDocumentInvalidate	
DrawDocumentSendClassedEvent
DrawDocumentGainedTargetExcl
DrawDocumentLostTargetExcl
DrawDocumentUpdateRulers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/9/92		Initial revision

DESCRIPTION:

	$Id: documentDocument.asm,v 1.1 97/04/04 15:51:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include win.def
;;;include Internal/grWinInt.def

idata	segment

	DrawDocumentClass
	DrawGenDocumentControlClass

idata	ends

DocumentCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the passed file - native Writer or other file to
		be imported.

CALLED BY:	MSG_GEN_DOCUMENT_OPEN

PASS:		es 	= segment of DrawDocumentClass
		*ds:si	= DrawDocumentClass object
		ss:bp	= DocumentCommonParams

RETURN:		carry set on error, else clear
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/30/98   	Initial version
	Don	1/24/99		Modified for Artist
	Don	1/30/99		Send document path to Wizard object
	Don	3/1/99		Cleaned up code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

customLayerID		hptr	DocumentCode
customLayerPriority	byte	LAYER_PRIO_ON_BOTTOM

DrawDocumentOpen	method dynamic DrawDocumentClass, 
					MSG_GEN_DOCUMENT_OPEN
	;
	; See if it's one of our known DOS file types. If not,
	; just let the superclass do its job.
	;
		call	CheckIfNativeFile
		jc	doImport
	;
	; OK, complete the opening of the file
	;
		mov	ax, MSG_GEN_DOCUMENT_OPEN
		mov	di, offset DrawDocumentClass
		GOTO	ObjCallSuperNoLock
	;
	; It appears to be a file we can support, so let's do the import
	; First off...we need to create a new document, so get that going.
	;
doImport:
		push	bp
		push	bp
		mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC
		GetResourceHandleNS DrawDocumentControlObj, bx
		mov	si, offset DrawDocumentControlObj
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Need to interact with the ImportControl and some of its children
	; Since we really don't want to see the Import DB, we hide it using
	; some amazing vardata.
	;
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, cs
		mov	ss:[bp].AVDP_data.offset, offset customLayerID
		mov	ss:[bp].AVDP_dataSize, size customLayerID
		mov	ss:[bp].AVDP_dataType, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
		GetResourceHandleNS DrawImpexImportControl, bx
		mov	si, offset DrawImpexImportControl
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		push	ax, dx, bp
		call	ObjMessage

		pop	ax, dx, bp
		mov	ss:[bp].AVDP_data.segment, cs
		mov	ss:[bp].AVDP_data.offset, offset customLayerPriority
		mov	ss:[bp].AVDP_dataSize, size customLayerPriority
		mov	ss:[bp].AVDP_dataType, \
				ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, size AddVarDataParams
		
		mov	ax, MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = file selector
		movdw	bxsi, cxdx
		pop	bp
	;
	; Tell the file selector to select the file by name.
	; First set the disk & path, and then the filename.
	;
		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[bp].DCP_path
		mov	bp, ss:[bp].DCP_diskHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	bp
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
		mov	cx, ss
		lea	dx, ss:[bp].DCP_name
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to do the import now, after dismissing the dialog
	; We leave the format list on auto-detect - that's what it
	; is there for (we hope!). Also delete the vardata we added
	; earlier, so that "normal" importing will work.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GetResourceHandleNS DrawImpexImportControl, bx
		mov	si, offset DrawImpexImportControl
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_IMPORT
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	ax, MSG_META_DELETE_VAR_DATA
		mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	ax, MSG_META_DELETE_VAR_DATA
		mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Finally, we need to return an error indicating that the
	; "normal" sequence of opening a file failed, or else we'll
	; end up with two GenDocument objects having been created.
	;
		pop	bp			; BP *must* be preserved
		stc
		ret
DrawDocumentOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNativeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if this is a native Writer file

CALLED BY:	GeoCalcDocumentOpen()

PASS:		ss:bp	= DocumentCommonParams

RETURN:		carry	= clear if it is a native GeoCalc file
			- or -
		carry	= set if it is not (i.e. a DOS file)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		stevey 	10/29/98    	Initial version
		Don	3/1/99		Ported changes over from GeoCalc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfNativeFile	proc	near
		uses	ax, bx, cx, dx, bp, si, di, es, ds
		.enter
	;
	; Construct the complete path (sigh)
	;
		segmov	ds, ss, ax
		mov	es, ax
		mov	cx, PATH_BUFFER_SIZE + (size GeosFileType)
		sub	sp, cx
		mov	dx, sp
		mov	di, sp			; buffer => ES:DI
		mov	bx, ss:[bp].DCP_diskHandle
		lea	si, ss:[bp].DCP_path
		push	dx
		mov	dx, 1
		call	FileConstructFullPath
		pop	dx
		cmc				; invert carry
		jnc	done			; if error, assume native file
	;
	; Append the filename onto the path. Ensure that a BACKSLASH
	; separates the path from the filename.
	;
		mov	ax, C_BACKSLASH		
SBCS <		cmp	{byte} es:[di-1], al				>
DBCS <		cmp	{word} es:[di-2], ax				>
		je	copyString
		LocalPutChar	esdi, ax
copyString:
		lea	si, ss:[bp].DCP_name
		LocalCopyString
	;
	; OK...now see if this is a GEOS file or not. If we get
	; ERROR_ATTR_NOT_FOUND, then we don't have a GEOS file.
	;
		mov	ax, FEA_FILE_TYPE
		mov	di, dx
		add	di, PATH_BUFFER_SIZE
		mov	cx, size GeosFileType
		call	FileGetPathExtAttributes
		jnc	checkType
		cmp	ax, ERROR_ATTR_NOT_FOUND
		je	dosFile
		clc				; some other error...assume
		jmp	done			; native file and we're done
checkType:
		cmp	{word} es:[di], GFT_NOT_GEOS_FILE
		clc				; assume native file
		jne	done
dosFile:
		stc				; DOS file!!!
done:
		lahf
		add	sp, PATH_BUFFER_SIZE + (size GeosFileType)
		sahf

		.leave
		ret
CheckIfNativeFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the document file (newly created).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

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
DrawDocumentInitializeDocumentFile	method dynamic DrawDocumentClass, 
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	.enter

	;    Let superclass do its thang
	;

	mov	di,offset DrawDocumentClass
	call	ObjCallSuperNoLock


	call	DrawDocumentAllocMapBlock
	call	DrawDocumentInitMapBlockBoundsMargins
	call	DrawDocumentDuplicateMainBlock
	call	DrawDocumentInitGrObjBody
	call	DrawDocumentInitGOAM
	call	DrawDocumentUpdatePageSizeControl

	Destroy 	ax,cx,dx,bp

	clc			;no error
	.leave
	ret
DrawDocumentInitializeDocumentFile		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitMapBlockBoundsMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the bounds and the margins that are stored
		in the map block. 

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument
		map block must have been allocated

RETURN:		
		In map block
			DMB_width
			DMB_height	
			DMB_orientation
			DMB_margins

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
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitMapBlockBoundsMargins		proc	near
	uses	ax,bx,cx,dx,bp,si,es,di
	.enter

EC <	call	ECCheckDocument					>

	;    Set document dimensions from default document size
	;

	sub	sp, size PageSizeReport
	mov	di, sp					;es:di <- PageSizeReport
	push	si, ds					;document
	mov	ax, ss
	mov	es,ax
	mov	ds,ax
	mov	si, di					;ds:si <- PageSizeReport
	call	SpoolGetDefaultPageSizeInfo
	pop	si, ds					;document
	movdw	dxcx, es:[di].PSR_width
	movdw	bxax, es:[di].PSR_height
	mov	bp, es:[di].PSR_layout
	call	DrawDocumentSetDocumentDimensions

	;    Set margins in document data block
	;

	mov	ax,es:[di].PSR_margins.PCMP_left
	mov	bx,es:[di].PSR_margins.PCMP_top
	mov	cx,es:[di].PSR_margins.PCMP_right
	mov	dx,es:[di].PSR_margins.PCMP_bottom
	call	DrawDocumentSetDocumentMargins

	add	sp, size PageSizeReport

	.leave
	ret
DrawDocumentInitMapBlockBoundsMargins		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDuplicateMainBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate and attach to the vm file the block
		that contains the GrObjBody, ObjectAttributeManager
		and Rulers. Allocate map block and store the
		vm block handle in it.

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

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
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDuplicateMainBlock		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,bp,es
	.enter

EC <	call	ECCheckDocument					>

	;    Duplicate block with GrObjBody and ObjectAttributeManager
	;    in it and have its burden thread be our process thread.
	;    The attach block to the vm file.The handles must be preserved,
	;    otherwise the block may get discarded and loaded back in
	;    with a different memory handle causing random obscure death 
	;    when we attempt to send messages to that object.
	;

	GetResourceHandleNS	DrawBodyRulerGOAMResTemp, bx
	clr	ax				; have current geode own block
	clr	cx				; have current thread run block
	call	ObjDuplicateResource

	mov	cx,bx				;mem handle of new block
	mov	bx,ds:[si]
	add	bx,ds:[bx].DrawDocument_offset
	mov	bx,ds:[bx].GDI_fileHandle
	clr	ax				;create new vm block
	call	VMAttach
	call	VMPreserveBlocksHandle

	call	DrawDocumentSetBodyGOAMRulerVMBlock

	.leave
	ret
DrawDocumentDuplicateMainBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send necessary initialization messages to GrObjBody

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

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
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitGrObjBody		proc	near
	uses	ax,di
	.enter

EC <	call	ECCheckDocument				>

	;    Set the bounds in the body from the data stored in the
	;    map block

	call	DrawDocumentSetGrObjBodyBounds

	.leave
	ret
DrawDocumentInitGrObjBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send necessary initialization message to 
		ObjectAttributeManager

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

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
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitGOAM		proc	near
	uses	di,ax
	.enter

	;    Have attribute manager create all the attribute and style arrays
	;    that it needs to use.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOAM_CREATE_ALL_ARRAYS
	call	DrawDocumentMessageToGOAM

	.leave
	ret
DrawDocumentInitGOAM		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document has been opened. Need to add body as child
		of document and notify it of opening

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

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
DrawDocumentAttachUI	method dynamic DrawDocumentClass, \
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	.enter

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

	;    Have superclass do its thang
	;

	mov	di, offset DrawDocumentClass	
	call	ObjCallSuperNoLock

	call	DrawDocumentSendDocumentSizeToView

	;    Attach ruler contents to ruler view
	;    and rulers to ruler contents
	;

	call	DrawDocumentAttachRulerUI

	;    Get output descriptor of GrObjBody from map block
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx
	mov	dx,offset DrawGrObjBodyObjTemp

	;    Add the graphic body as the first child of the
	;    Document/Content. Don't mark dirty because we don't
	;    want the document dirtied as soon as it is open, nor
	;    do we save the Document/Content or the parent pointer
	;    in the GrObjBody.
	;

	mov	bp,CCO_FIRST
	mov	ax,MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	call	ObjCallInstanceNoLock

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.
	;

	GetResourceHandleNS	DrawGrObjHeadObj,cx
	mov	dx, offset DrawGrObjHeadObj
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_ATTACH_UI
	call	DrawDocumentMessageToGrObjBody

	Destroy	ax,cx,dx,bp

	.leave
	ret
DrawDocumentAttachUI		endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageToRuler

DESCRIPTION:	Send a message to the ruler

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax, cx, dx, bp - message data

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
MessageToRuler	proc	near

	uses	bx, si, di, es
	.enter

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	si, offset DrawColumnRulerObjTemp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
MessageToRuler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentAttachRulerUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the ruler contents to the ruler views and
		the rulers to the ruler contents

CALLED BY:	INTERNAL
		DrawDocumentAttachUI

PASS:		*ds:si - DrawDocument


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The Ruler Contents are in the same block as this 
		document object.

		The Ruler Views are in the same block as the main view, 
		which is in the same block as the display.

		The Rulers are in the same block as the graphic body.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentAttachRulerUI		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECCheckDocument					>

	;    Attach the contents to the views
	;

	push	si					;document chunk
	mov	di,ds:[si]
	add	di,ds:[di].DrawDocument_offset
	mov	bx,ds:[di].GDI_display
	mov	cx,ds:[LMBH_handle]
	mov	dx,offset DrawColumnContentObjTemp
	mov	si,offset DrawColumnViewObjTemp
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_CONTENT
	call	ObjMessage
	mov	dx,offset DrawRowContentObjTemp
	mov	si,offset DrawRowViewObjTemp
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;document chunk

	;    Attach the rulers to the contents
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx					;ruler handle
	mov	si,dx					;RowContent chunk
	mov	dx,offset DrawRowRulerObjTemp
	mov	bp, CCO_FIRST
	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock
	mov	si,offset DrawColumnContentObjTemp
	mov	dx, offset DrawColumnRulerObjTemp
	mov	bp, CCO_FIRST
	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock

	.leave
	ret
DrawDocumentAttachRulerUI		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document is being closed. Need to remove body
		from document.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Handling MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT should
		undo all of the things done by ATTACH_UI. When the document
		is saved and restored to and from state, both these
		messages are called, so the need to mirror each other
		so that the file will be connected correctly.


		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDetachUI	method dynamic DrawDocumentClass, \
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter

	;    Get output descriptor of GrObjBody from map block
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx
	mov	dx,offset DrawGrObjBodyObjTemp

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
	;

	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_REMOVE_NON_DISCARDABLE
	call	ObjMessage
	pop	si					;document chunk

	;    Detach ruler contents from ruler view
	;    and rulers from ruler contents
	;

	call	DrawDocumentDetachRulerUI
	
	;    Have superclass do its thang
	;

	mov	ax,MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset DrawDocumentClass	
	call	ObjCallSuperNoLock


	Destroy	ax,cx,dx,bp

	.leave
	ret
DrawDocumentDetachUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDetachRulerUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the ruler contents from the ruler views and
		the rulers from the ruler contents

CALLED BY:	INTERNAL
		DrawDocumentDetachUI

PASS:		*ds:si - DrawDocument


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The Ruler Contents are in the same block as this 
		document object.

		The Ruler Views are in the same block as the main view, 
		which is in the same block as the display.

		The Rulers are in the same block as the GrObj body.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDetachRulerUI		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECCheckDocument					>

	;    Detach the contents from the views
	;

	push	si					;document chunk
	mov	di,ds:[si]
	add	di,ds:[di].DrawDocument_offset
	mov	bx,ds:[di].GDI_display
	clr	cx
	mov	dx,cx
	mov	si,offset DrawColumnViewObjTemp
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_CONTENT
	call	ObjMessage
	mov	si,offset DrawRowViewObjTemp
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;document chunk

	;    Detach the rulers from the contents
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	si,offset DrawRowRulerObjTemp
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_REMOVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset DrawColumnRulerObjTemp
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_REMOVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
DrawDocumentDetachRulerUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitiateTemplateWizard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate template wizard

CALLED BY:	MSG_GEN_DOCUMENT_INITIATE_TEMPLATE_WIZARD

PASS:		*ds:si	= DrawDocumentClass object
		ds:di	= DrawDocumentClass instance data
		ds:bx	= DrawDocumentClass object (same as *ds:si)
		es 	= segment of DrawDocumentClass
		ax	= message #
		ss:bp	= DocumentCommonParams
		dx	= size DocumentCommonParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/11/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitiateTemplateWizard	method dynamic DrawDocumentClass, 
			MSG_GEN_DOCUMENT_INITIATE_TEMPLATE_WIZARD

	;
	; Bail if we are already doing "Done" handling
	;
	push	bp
	mov	ax, MSG_GEN_APPLICATION_GET_MODAL_WIN
	call	GenCallApplication		; ^lcx:dx = modal win
	pop	bp
	jcxz	continue
	ret
continue:
	;
	; To ensure we get a clean look, we're going to suspend
	; all windows while we check to see if we really have
	; a Design Assistant (wizard) for this document
	;
	push	si, bp
	GetResourceHandleNS DrawPrimary, bx
	mov	si, offset DrawPrimary
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx = window
	mov	di, cx			; first Window
	call	DrawSuspendWindowTree
	pop	si, bp	

	;
	; OK, duplicate the Wizard resource and start the process
	;
	push	si
	clr	bx			; get appObj for current process
	call	GeodeGetAppObject	; ^lbx:si = appObj
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo		; ax = ^hexecThread
	pop	si

	mov	cx, ax			; cx = thread to run
	clr	ax			; ax = current geode own block
	mov	bx, handle TemplateWizardDialog
	call	ObjDuplicateResource	; bx = new block

	push	bp
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, bx
	mov	dx, offset TemplateWizardDialog
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
	call	UserCallApplication
	pop	bp

	push	si
	mov	ax, MSG_DRAW_TEMPLATE_IMAGE_SET_IMAGE_PATH
	mov	cx, ss
	lea	dx, ss:[bp].DCP_path
	mov	bp, ss:[bp].DCP_diskHandle
	mov	si, offset TemplateWizardDocumentImage
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	mov	ax, MSG_DRAW_TEMPLATE_WIZARD_INITIALIZE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si			; ^lcx:dx = GenDocumentClass object
	clr	di
	mov	si, offset TemplateWizardDialog
	call	ObjMessage

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	di
	GOTO	ObjMessage

DrawDocumentInitiateTemplateWizard	endm

DrawSuspendWindowTree	proc	far
	;
	; Stolen from the incredible Brian Chin
	;
	tst	di
	jz	done
	push	di
	call	WinSuspendUpdate
	mov	si, WIT_FIRST_CHILD_WIN
	call	WinGetInfo
	mov	di, ax
	tst	di
	jz	donePop
	call	DrawSuspendWindowTree
	mov	si, WIT_NEXT_SIBLING_WIN
	call	WinGetInfo
	mov	di, ax
	call	DrawSuspendWindowTree
donePop:
	pop	di
done:
	ret
DrawSuspendWindowTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DrawDocumentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	DrawDocument method for MSG_VIS_DRAW
		Subclassed to draw the grid before anything else

Called by:	

Pass:		*ds:si = DrawDocument object
		ds:di = DrawDocument instance
		bp - gstate
		cl - DrawFlags

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  4, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentVisDraw	method dynamic	DrawDocumentClass, MSG_VIS_DRAW
	.enter

	test	cl, mask DF_PRINT
	jnz	callSuper

	mov	di, bp					;gstate

	clr	ax,dx
	call	GrSetLineWidth

	mov	ax, C_LIGHT_BLUE
	call	GrSetLineColor

	mov	al, SDM_50 or mask SDM_INVERSE
	call	GrSetLineMask

	mov	ax, MSG_VIS_RULER_DRAW_GRID
	call	MessageToRuler

	mov	ax, C_LIGHT_RED
	call	GrSetLineColor

	mov	ax, MSG_VIS_RULER_DRAW_GUIDES
	call	MessageToRuler

	call	DrawDocumentDrawMargins

callSuper:
	mov	ax, MSG_VIS_DRAW
	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock

	.leave
	
	Destroy	ax,cx,dx,bp

	ret
DrawDocumentVisDraw	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDrawMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw document margins

CALLED BY:	INTERNAL
		DrawDocumentVisDraw

PASS:		*ds:si - Document
		di - gstate

RETURN:		
		nothing

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
	srs	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDrawMargins		proc	near
	uses	ax,bx,cx,dx,ds,bp
	.enter

EC <	call	ECCheckDocument			>

	;    Set attributes for drawing margins
	;

	clr	ax,dx
	call	GrSetLineWidth

	mov	al,SDM_50 or mask SDM_INVERSE
	call	GrSetLineMask

	mov	ax, C_BLACK
	call	GrSetLineColor

	;    Get Document dimensions
	;

	call	DrawDocumentGetDocumentDimensions
	sub	sp, size RectDWord
	mov	bp, sp
	mov	ss:[bp].RD_right.low,cx
	mov	ss:[bp].RD_bottom.low,ax
	mov	ss:[bp].RD_right.high,dx
	mov	ss:[bp].RD_bottom.high,bx
	clr	ax
	mov	ss:[bp].RD_left.low,ax
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.low,ax
	mov	ss:[bp].RD_top.high,ax

	;    Inset document dimensions by margins
	;

	call	DrawDocumentGetDocumentMargins
	add	ss:[bp].RD_left.low,ax
	mov	ax,0					;preserve carry
	adc	ss:[bp].RD_left.high,ax	
	adddw	ss:[bp].RD_top,axbx
	subdw	ss:[bp].RD_right,axcx
	subdw	ss:[bp].RD_bottom,axdx

	;    Draw that baby
	;

	segmov	ds,ss
	mov	bx,bp
	call	GrObjDraw32BitRect
	add	sp,size RectDWord

	.leave
	ret
DrawDocumentDrawMargins		endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentGainedTargetExcl -- MSG_META_GAINED_TARGET_EXCL
						for DrawDocumentClass

DESCRIPTION:	Handle gaining the target

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
DrawDocumentGainedTargetExcl	method dynamic	DrawDocumentClass,
						MSG_META_GAINED_TARGET_EXCL
	.enter

	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToRuler

	call	DrawDocumentUpdatePageSizeControl

	.leave
	ret
DrawDocumentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentLostTargetExcl -- MSG_META_LOST_TARGET_EXCL
						for DrawDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
DrawDocumentLostTargetExcl	method dynamic	DrawDocumentClass,
						MSG_META_LOST_TARGET_EXCL
	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToRuler

	mov	ax, MSG_META_LOST_TARGET_EXCL
	mov	di, offset DrawDocumentClass
	GOTO	ObjCallSuperNoLock

DrawDocumentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentSendClassedEvent -- MSG_META_SEND_CLASSED_EVENT
							for DrawDocumentClass

DESCRIPTION:	Pass a classed event to the right place

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

	ax - The message

	cx - event
	dx - travel option

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
DrawDocumentSendClassedEvent	method dynamic	DrawDocumentClass,
					MSG_META_SEND_CLASSED_EVENT
	.enter

	push	ax, cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cxsi = class
	movdw	bxdi, cxsi			;bxdi = class
	pop	ax, cx, si

	cmp	bx, segment GrObjHeadClass
	jnz	notHead
	cmp	di, offset GrObjHeadClass
	jnz	notHead

	; this message is destined for the GrObjHead

	GetResourceHandleNS	DrawGrObjHeadObj, bx
	mov	si, offset DrawGrObjHeadObj
	clr	di
	call	ObjMessage

done:
	.leave
	ret
notHead:
	;
	;	Must fix for subclasses of VisRuler
	;
	cmp	bx, segment VisRulerClass
	jnz	notRuler
	cmp	di, offset VisRulerClass
	jnz	notRuler

	; this message is destined for the ruler

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	MessageToRuler
	jmp	done

notRuler:

	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock
	jmp	done
DrawDocumentSendClassedEvent	endm
COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentLoadStyleSheet --
		MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for DrawDocumentClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

	ax - The message

	bp - SSCLoadStyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/25/92		Initial version

------------------------------------------------------------------------------@
DrawDocumentLoadStyleSheet	method dynamic	DrawDocumentClass,
				MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET

	call	StyleSheetOpenFileForImport
	LONG_EC jc	done

	; bx = file handle

	; We need to get a StyleSheetParams structure from the file.

	push	bx
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax			;es = map block
	mov	ax, es:[DMB_bodyRulerGOAM]
	call	VMUnlock

	call	VMLock
	mov	es, ax
	mov	di, offset DrawGOAMObjTemp
	mov	di, es:[di]
	add	di, es:[di].GrObjAttributeManager_offset
	mov	ax, es:[di].GOAMI_grObjStyleArrayHandle
	mov	cx, es:[di].GOAMI_areaAttrArrayHandle
	mov	dx, es:[di].GOAMI_lineAttrArrayHandle
	call	VMUnlock

	sub	sp, size StyleSheetParams
	mov	bp, sp

	mov	ss:[bp].SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmFile, bx

	mov	ss:[bp].SSP_xferStyleArray.SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_chunk,
							VM_ELEMENT_ARRAY_CHUNK

	mov	ss:[bp].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, dx

	mov	ax, MSG_GOAM_LOAD_STYLE_SHEET
	mov	dx, size StyleSheetParams
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	DrawDocumentMessageToGOAM

	add	sp, size StyleSheetParams

	pop	bx
	mov	al, FILE_NO_ERRORS
	call	VMClose

done:
	ret
DrawDocumentLoadStyleSheet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedwoodPrintNotifyPrintDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PRINT_NOTIFY_PRINT_DB
PASS:		*ds:si	= DrawDocumentClass object
		ds:di	= DrawDocumentClass instance data
		ds:bx	= DrawDocumentClass object (same as *ds:si)
		es 	= segment of DrawDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	1/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150				;code for Redwood

RedwoodPrintNotifyPrintDB	method dynamic DrawDocumentClass, 
					MSG_PRINT_NOTIFY_PRINT_DB
	.enter

	cmp	bp, PCS_PRINT_BOX_VISIBLE
	jne	callSuper

	;
	; save the regs for the call to the super class
	;
	push	ax, cx, dx, bp, si, es

	;
	; set up dx:bp to hold the PageSizeReport
	;
	sub	sp, size PageSizeReport
	mov	bp, sp
	mov	dx, ss

	;
	; being here means that the PrintControlbox is just about to be
	; put onto the screen.  Now we want to get the data from the
	; Document to set up the PageSizeReport.  the margins are not
	; important in this context
	;
	push	bx

	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle

	;
	; save bp, since it points to the PageSizeReport
	;
	mov	si, bp

	call	VMGetMapBlock
	call	VMLock

	mov	es, ax
	clr	bx

	movdw	cxdx, es:[bx].DMB_width
	movdw	ss:[si].PSR_width, cxdx

	movdw	cxdx, es:[bx].DMB_height
	movdw	ss:[si].PSR_height, cxdx

	mov	cx, es:[bx].DMB_orientation
	mov	ss:[si].PSR_layout, cx
	call	VMUnlock

	pop	bx

	;
	; We want to reset the pagesize of the print control, to be
	; the same as the one stroed in the document
	;
	GetResourceHandleNS DrawPrintControl, bx
	mov	bp, si
	segmov	dx, ss
	mov	si, offset DrawPrintControl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_PRINT_SET_PRINT_CONTROL_PAGE_SIZE
	call	ObjMessage 
	add	sp, size PageSizeReport

	;
	; restore the data from the initial call
	;
	pop	ax, cx, dx, bp, si, es

callSuper:
	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock	

	.leave
	ret
RedwoodPrintNotifyPrintDB	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle creating a GState and initialize it to our liking

CALLED BY:	MSG_VIS_VUP_CREATE_GSTATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawDocumentClass
		ax - the message
RETURN:		bp - handle of GState
		carry - set for success
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentVupCreateGState		method dynamic DrawDocumentClass,
						MSG_VIS_VUP_CREATE_GSTATE
	;
	; Call our superclass to create the GState
	;
	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock
	;
	; Initialize the GState to our liking
	;
	mov	di, bp				;di <- GState handle
	mov	al, ColorMapMode <0, CMT_DITHER>
	call	GrSetTextColorMap
	stc					;carry <- success
	ret
DrawDocumentVupCreateGState		endm

DrawDocumentDrawUnSuspend	method dynamic DrawDocumentClass, 
					MSG_DRAW_DOCUMENT_UNSUSPEND_WIN_UPDATE

	GetResourceHandleNS DrawPrimary, bx
	mov	si, offset DrawPrimary
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx = window
	mov	di, cx			; first Window
	call	DrawUnSuspendWindowTree

	ret
DrawDocumentDrawUnSuspend		endm

DrawUnSuspendWindowTree	proc	far
	;
	; Stolen from the incredible Brian Chin
	;
	tst	di
	jz	done
	push	di
	call	WinUnSuspendUpdate
	mov	si, WIT_FIRST_CHILD_WIN
	call	WinGetInfo
	mov	di, ax
	tst	di
	jz	donePop
	call	DrawUnSuspendWindowTree
	mov	si, WIT_NEXT_SIBLING_WIN
	call	WinGetInfo
	mov	di, ax
	call	DrawUnSuspendWindowTree
donePop:
	pop	di
done:
	ret
DrawUnSuspendWindowTree	endp


DrawDocumentControlInitiate	method dynamic DrawGenDocumentControlClass,
					MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC
	;
	; Call our superclass to create the GState
	;
	mov	di, offset DrawGenDocumentControlClass
	call	ObjCallSuperNoLock
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	{byte}ds:[di].DGDC_DALaunched, 1

	ret
DrawDocumentControlInitiate		endm
DrawDocumentControl	method dynamic DrawGenDocumentControlClass,
					MSG_DRAW_DOCUMENT_CONTROL_LAUNCHED_DA
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	cx
	mov	cl, ds:[di].DGDC_DALaunched
	pop	di
	ret
DrawDocumentControl		endm

DocumentCode ends

