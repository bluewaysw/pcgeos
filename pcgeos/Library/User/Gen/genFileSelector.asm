COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genFileSelector.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenFileSelectorClass	File selection object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

DESCRIPTION:
	This file contains routines to implement the GenFileSelector class.

	$Id: genFileSelector.asm,v 1.1 97/04/07 11:45:02 newdeal Exp $

------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenFileSelector.doc

UserClassStructures	segment resource

	GenFileSelectorClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFileSelectorRelocOrUnReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the path bound to this object

CALLED BY:	MSG_META_RELOCATE, MSG_META_UNRELOCATE
PASS:		*ds:si	= object
	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFileSelectorRelocOrUnReloc method GenFileSelectorClass, reloc
		.enter
		cmp	ax, MSG_META_UNRELOCATE
		jne	done
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathUnrelocObjectPath
done:
		.leave
		mov	di, offset GenFileSelectorClass
		call	ObjRelocOrUnRelocSuper
		ret
GenFileSelectorRelocOrUnReloc endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for
						GenFileSelectorClass

DESCRIPTION:	Return the correct specific class for an object

PASS:	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenFileSelectorClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenFileSelectorBuild	method	GenFileSelectorClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

	mov	ax, SPIR_BUILD_FILE_SELECTOR
	GOTO	GenQueryUICallSpecificUI

GenFileSelectorBuild	endm

Build ends

;--------

GetUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetAttrs

DESCRIPTION:	Get current file selector attributes

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_ATTRS

RETURN: cx - FileSelectorAttrs

ALLOWED TO DESTROY:
	ax, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorGetAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_ATTRS

	mov	cx, ds:[di].GFSI_attrs
EC <	Destroy	ax, dx, bp						>
	ret

GenFileSelectorGetAttrs	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetAttrs

DESCRIPTION:	Set file selector attributes

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_ATTRS

	cx - FileSelectorAttrs

RETURN:	Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorSetAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_ATTRS

EC <	test	cx, not mask FileSelectorAttrs				>
EC <	ERROR_NZ	GEN_FILE_SELECTOR_BAD_ATTRS			>

	mov	bx, offset GFSI_attrs
	call	GenSetWord

	call	GenCallSpecIfGrown
EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetAttrs	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetFileCriteria

DESCRIPTION:	Get current file selector file criteria

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA

RETURN: cx - FileSelectorFileCriteria

ALLOWED TO DESTROY:
	ax, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/91		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorGetFileCriteria	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA

	mov	cx, ds:[di].GFSI_fileCriteria
EC <	Destroy	ax, dx, bp						>
	ret

GenFileSelectorGetFileCriteria	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetFileCriteria

DESCRIPTION:	Set file selector file criteria

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA

	cx - FileSelectorFileCriteria

RETURN:	Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/91		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorSetFileCriteria	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA

EC <	test	cx, not mask FileSelectorFileCriteria			>
EC <	ERROR_NZ	GEN_FILE_SELECTOR_BAD_FILE_CRITERIA		>

	mov	bx, offset GFSI_fileCriteria
	call	GenSetWord

	call	GenCallSpecIfGrown
EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetFileCriteria	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetAction -- MSG_GEN_FILE_SELECTOR_GET_ACTION
		for GenFileSelectorClass

DESCRIPTION:	Get the action descriptor for a file selector

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_ACTION


RETURN: ^lcx:dx - optr
	bp - method

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorGetAction	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_ACTION
	mov	cx,ds:[di].GFSI_destination.handle
	mov	dx,ds:[di].GFSI_destination.chunk
	mov	bp,ds:[di].GFSI_notificationMsg
EC<	call	ECCheckODCXDX						>
EC <	Destroy	ax							>
	ret

GenFileSelectorGetAction	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetAction -- MSG_GEN_FILE_SELECTOR_SET_ACTION
		for GenFileSelectorClass

DESCRIPTION:	Set the action descriptor for a file selector

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_ACTION

	^lcx:dx - OD
	bp - action

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorSetAction	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_ACTION
EC<	call	ECCheckODCXDX						>

	call	GFSMarkDirtyAndDeref

	mov	ds:[di].GFSI_destination.handle, cx
	mov	ds:[di].GFSI_destination.chunk, dx
	mov	ds:[di].GFSI_notificationMsg, bp

	ret

GenFileSelectorSetAction	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetMask -- MSG_GEN_FILE_SELECTOR_GET_MASK
		for GenFileSelectorClass

DESCRIPTION:	Get the filemask of files currently being shown in the
		file selector.

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_MASK
	cx:dx - address to copy to (VOLUME_NAME_LENGTH+1 bytes)

RETURN:	carry set if mask defined:
		cx:dx - filled with mask (fptr preserved)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorGetMask	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_MASK
	mov	ax, ATTR_GEN_FILE_SELECTOR_NAME_MASK
	call	GFSCopyOutAttr
EC <	Destroy	ax, bp							>
	ret

GenFileSelectorGetMask	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetMask -- MSG_GEN_FILE_SELECTOR_SET_MASK
		for GenFileSelectorClass

DESCRIPTION:	Set the filemask for a file selector

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_MASK

	cx:dx - new filemask (null-terminated)
	(cx:dx *cannot* be pointing to the movable XIP code segment.)

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorSetMask	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_MASK

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	push	es, cx
	movdw	esdi, cxdx
	call	LocalStringSize
	inc	cx
DBCS <	inc	cx							;>
	mov	bp, cx					;bp <- size of string
	pop	es, cx

	mov	ax, ATTR_GEN_FILE_SELECTOR_NAME_MASK
	push	cx, dx
	call	GFSCopyInAttr
	pop	cx, dx

	mov	ax, MSG_GEN_FILE_SELECTOR_SET_MASK
	call	GenCallSpecIfGrown

EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetMask	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetFileAttrs

DESCRIPTION:	Get current DOS file attributes

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_FILE_ATTRS

RETURN: cl - FileAttrs to match (file attributes)
	ch - FileAttrs to not match

ALLOWED TO DESTROY:
	ax, ch, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorGetFileAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_FILE_ATTRS

	;
	; Prepare buffer for copy-out of the attribute, setting it to the
	; default value if no attribute is defined (hidden & system files
	; not included).
	; 
	mov	ax, (mask FA_SYSTEM or mask FA_HIDDEN) shl 8
	push	ax
	mov	cx, ss		; cx:dx <- buffer
	mov	dx, sp
	mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_ATTR
	call	GFSCopyOutAttr

	;
	; Pop our return value from the buffer on the stack.
	; 
	pop	cx

EC <	Destroy	ax, dx, bp						>
	ret
GenFileSelectorGetFileAttrs	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetFileAttrs

DESCRIPTION:	Set file selector file attributes

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS

	cl - FileAttrs to match (file attributes)
	ch - FileAttrs to not match

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorSetFileAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS

EC <	test	cx, not (mask FileAttrs or mask FileAttrs shl 8)	>
EC <	ERROR_NZ	GEN_FILE_SELECTOR_BAD_DOS_ATTRS			>

	push	cx
	mov	cx, ss
	mov	dx, sp
	mov	ax, ATTR_GEN_FILE_SELECTOR_FILE_ATTR
	mov	bp, size GenFileSelectorFileAttrs
	call	GFSCopyInAttr
	pop	cx

	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS
	call	GenCallSpecIfGrown

EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetFileAttrs	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetGeodeAttrs

DESCRIPTION:	Get current GeodeAttrs

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_GEODE_ATTRS

RETURN: carry set if geode attributes used in file selection:
		cx - match GeodeAttrs
		dx - mismatch GeodeAttrs

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorGetGeodeAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_GEODE_ATTRS

	sub	sp, size GenFileSelectorGeodeAttrs
	mov	cx, ss
	mov	dx, sp
	mov	ax, ATTR_GEN_FILE_SELECTOR_GEODE_ATTR
	call	GFSCopyOutAttr
	
	CheckHack <GFSGA_match eq 0 and GFSGA_mismatch eq 2 and \
			size GenFileSelectorGeodeAttrs eq 4>
	pop	cx
	pop	dx
EC <	Destroy	ax, bp							>
	ret

GenFileSelectorGetGeodeAttrs	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetGeodeAttrs

DESCRIPTION:	Set file selector GeodeAttrs

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS

	cx - match GeodeAttrs
	dx - mismatch GeodeAttrs

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorSetGeodeAttrs	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS

EC <	test	cx, not mask GeodeAttrs					>
EC <	ERROR_NZ	GEN_FILE_SELECTOR_BAD_GEODE_ATTRS		>
EC <	test	dx, not mask GeodeAttrs					>
EC <	ERROR_NZ	GEN_FILE_SELECTOR_BAD_GEODE_ATTRS		>


	CheckHack <GFSGA_match eq 0 and GFSGA_mismatch eq 2 and \
			size GenFileSelectorGeodeAttrs eq 4>
	push	dx
	push	cx
	mov	dx, sp
	mov	cx, ss
	mov	ax, ATTR_GEN_FILE_SELECTOR_GEODE_ATTR
	mov	bp, size GenFileSelectorGeodeAttrs
	call	GFSCopyInAttr
	pop	cx
	pop	dx
	
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS
	call	GenCallSpecIfGrown

EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetGeodeAttrs	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetToken

DESCRIPTION:	Get current token

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_TOKEN

RETURN: carry set if file token used in selection:
		 cx:dx - four bytes of token
		bp - manufacturer id of token

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorGetToken	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_TOKEN
	mov	ax, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
	call	GFSCopyOutToken
	ret
GenFileSelectorGetToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCopyOutToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy out an attribute that contains a GeodeToken structure

CALLED BY:	GenFileSelectorGetToken, GenFileSelectorGetCreator
PASS:		*ds:si	= object
		ax	= VarData tag for the attribute
RETURN:		carry set if token being used:
			cx:dx	= token characters
			bp	= token manufacturer ID
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCopyOutToken	proc	near
		.enter
		sub	sp, size GeodeToken
		mov	cx, ss
		mov	dx, sp
		call	GFSCopyOutAttr
	CheckHack <GT_chars eq 0 and GT_manufID eq 4 and size GeodeToken eq 6>
		pop	cx
		pop	dx
		pop	bp
		.leave
		ret
GFSCopyOutToken	endp


GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetToken

DESCRIPTION:	Set file selector token

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_TOKEN

	cx:dx - four bytes of token chars
	bp - manufacturer id of token

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorSetToken	method	GenFileSelectorClass, \
				MSG_GEN_FILE_SELECTOR_SET_TOKEN

	mov	bx, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
	call	GFSCopyInToken
EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetToken	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetCreator

DESCRIPTION:	Get current creator

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_CREATOR

RETURN: carry set if creator token used in file selection:
		cx:dx - four bytes of creator
		bp - manufacturer id of creator

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorGetCreator	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_CREATOR
	mov	ax, ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH
	call	GFSCopyOutToken
	ret
GenFileSelectorGetCreator	endm

GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetCreator

DESCRIPTION:	Set file selector creator

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_CREATOR

	cx:dx - four bytes of creator chars
	bp - manufacturer id of creator

RETURN: Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		Initial version
	brianc	4/91		Completed 2.0 revisions
	ardeb	12/91		Changed to use vardata

------------------------------------------------------------------------------@

GenFileSelectorSetCreator	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_CREATOR

	mov	bx, ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH
	call	GFSCopyInToken
EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFileSelectorSetCreator	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCopyInToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy inut an attribute that contains a GeodeToken structure

CALLED BY:	GenFileSelectorSetToken, GenFileSelectorSetCreator
PASS:		*ds:si	= object
		ax	= message to send to specific UI when done, if grown
		bx	= VarData tag for the attribute
		cx:dx	= token characters
		bp	= token manufacturer ID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCopyInToken	proc	near
		.enter
		push	ax	; save message #

	CheckHack <GT_chars eq 0 and GT_manufID eq 4 and size GeodeToken eq 6>
		push	bp	; push token in correct GeodeToken order
		push	dx
		push	cx
		mov	bp, size GeodeToken	; bp <- attr size
		mov	cx, ss	; cx:dx <- attr value
		mov	dx, sp
		mov_tr	ax, bx	; ax <- vardata tag
		call	GFSCopyInAttr
		pop	cx
		pop	dx
		pop	bp
		
		pop	ax
		call	GenCallSpecIfGrown
		.leave
		ret
GFSCopyInToken	endp

BuildUncommon	ends

;
;---------------
;
		
FileSelectorCommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetSelection -- 
				MSG_GEN_FILE_SELECTOR_GET_SELECTION
		for GenFileSelectorClass

DESCRIPTION:	Get the current selection in the file selector.

PASS:	*ds:si - instance data
	ds:di - Gen instance data
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_SELECTION
	cx:dx - address to copy to (FILE_LONGNAME_BUFFER_SIZE bytes)
		(cx = 0 if no copy desired)

RETURN:	cx:dx - filled with selection
	ax - entry # of selection
	bp - GenFileSelectorEntryFlags
			GFSEF_TYPE - type of entry selection is
				GFSET_FILE
				GFSET_SUBDIR
				GFSET_VOLUME
			GFSEF_OPEN - (not used)
			GFSEF_NO_ENTRIES - set if no entries
			GFSEF_LONGNAME - selection is longname file
			GFSEF_ERROR - (not used)

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorGetSelection	method	dynamic GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	ax, TEMP_GEN_FILE_SELECTOR_DATA
	call	ObjVarDerefData		; ds:bx = GFS temp data

	push	ds:[bx].GFSTDE_selectionNumber	; save entry #
	mov	bp, ds:[bx].GFSTDE_selectionFlags	; bp = selection flags
	call	GFSDeref_SI_Gen_DI	; ds:di = gen instance
	lea	si, ds:[di].GFSI_selection
	jcxz	exit			;If no copy desired, branch
	mov	ax, FILE_LONGNAME_BUFFER_SIZE
	call	GFSGetString
exit:
	pop	ax			; ax = entry # of selection
	ret

GenFileSelectorGetSelection	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetSelection --
			MSG_GEN_FILE_SELECTOR_SET_SELECTION
		for GenFileSelectorClass

DESCRIPTION:	Set the current selection for a file selector.

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_SELECTION

	cx:dx - new selection (null-terminated)
	(cx:dx *cannot* be pointing into the movable XIP code resource.)

RETURN: carry - clear if selection passed and found (or if suspended)
		set otherwise

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version
	brianc	4/91		Completed 2.0 revisions

------------------------------------------------------------------------------@

GenFileSelectorSetSelection	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_SET_SELECTION
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	call	GFSMarkDirtyAndDeref		; ds:di = generic instance

	push	cx, si, ds, es
	add	di, offset GFSI_selection
	segmov	es, ds
	mov	ds, cx
	mov	si, dx
SBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE				>
DBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2				>
SBCS <	rep movsb							>
DBCS <	rep movsw							>
	pop	cx, si, ds, es

	call	GenCheckIfSpecGrown
	jnc	done
	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock

done:
	Destroy	ax, cx, dx, bp
	ret

GenFileSelectorSetSelection	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetFullSelectionPath -- 
			MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		for GenFileSelectorClass

DESCRIPTION:	Get the full pathname of the current selection in the file
		selector.

PASS:	*ds:si - instance data
	ds:di - Gen instance data
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	cx:dx - address to copy to (PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE
		bytes)
		(cx = 0 if no copy desired)

RETURN:	cx:dx - filled with selection
	ax - disk handle of path
	bp - GenFileSelectorEntryFlags
			GFSEF_TYPE - type of entry selection is
				GFSET_FILE
				GFSET_SUBDIR
				GFSET_VOLUME
			GFSEF_OPEN - (not used)
			GFSEF_NO_ENTRIES - set if no entries
			GFSEF_LONGNAME - selection is longname file
			GFSEF_ERROR - (not used)

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version
	ardeb	12/91		Changed to deal with std path as disk handle

------------------------------------------------------------------------------@

GenFileSelectorGetFullSelectionPath	method	dynamic GenFileSelectorClass, \
				MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	uses	cx, dx
	.enter

	mov	ax, TEMP_GEN_FILE_SELECTOR_DATA
	call	ObjVarDerefData		; ds:bx = GFS temp data

	mov	bp, ds:[bx].GFSTDE_selectionFlags	; bp = entry flags
	jcxz	getJustDiskHandle

	;
	; Extract the bound path and disk handle.
	; 
	segmov	es, cx
	mov	di, dx
	mov	cx, PATH_BUFFER_SIZE
getJustDiskHandle:
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	push	cx
	call	GenPathGetObjectPath		; can cause chunks to move...
	pop	ax

	xchg	ax, cx				; ax <- disk handle, cx <-
						;  buffer segment again, or
						;  non-zero
	jcxz	exit

	push	ax				; save disk handle

	; find the end of the path

SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	not	cx				; cx <- # chars (including null)

	; append a backslash if there's anything there.

	cmp	cx, 2				; empty?
	jb	addSeparator			; yes -- add separating
						;  backslash; this is fine since
						;  FileSetCurrentPath handles
						;  absolute paths with SP
						;  constants correctly.
	LocalPrevChar esdi			; assume null won't be
						;  overwritten yet
	dec	cx				; update count also
SBCS <	cmp	{char}es:[di-1], C_BACKSLASH	; root?			>
DBCS <	cmp	{wchar}es:[di-2], C_BACKSLASH	; root?			>
	je	checkSelection			; yes -- no separator req'd
	inc	di				; no -- set to overwrite null
DBCS <	inc	di							>
	inc	cx				; update count also

addSeparator:
SBCS <	mov	{char}es:[di-1], C_BACKSLASH				>
DBCS <	mov	{wchar}es:[di-2], C_BACKSLASH				>

checkSelection:
	; see if there's any selection.

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	tst	ds:[si].GFSI_selection[0]
	jnz	haveSelection
	
	;
	; Nope. clear the return buffer to indicate this.
	; 
	sub	di, cx				; back to start of buffer
	LocalPutChar esdi, ax			; zero first byte in the passed
						;  buffer (al still from scasb)
	jmp	done

noPath:
	sub	di, cx
	jmp	copySelection

haveSelection:
	mov	ax, bp
	andnf	ax, mask GFSEF_TYPE
	cmp	ax, GFSET_VOLUME shl offset GFSEF_TYPE	; volume listing?
	je	noPath				; yes, skip path

copySelection:

	; copy the whole field in, rather than going until a null or something
	; like that

	mov	cx, size GFSI_selection
	add	si, offset GFSI_selection
	rep	movsb

done:
	pop	ax			; ax = disk handle
exit:
	.leave
	ret

GenFileSelectorGetFullSelectionPath	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorSetFullSelectionPath --
			MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH
		for GenFileSelectorClass

DESCRIPTION:	Set the current selection for a file selector given full path.

PASS:	*ds:si - instance data
	ds:di - GenFileSelector instance data (Gen)
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_SET_SELECTION

	cx:dx - full pathname of new selection (null-terminated)
		(if partial pathname is passed, it is relative to current path
		 and passed disk handle is ignored)
		(cx:dx *cannot* be pointing into the movable XIP code resource.)
	bp - disk handle of full path (if zero, path is on current disk)

RETURN: carry - clear if selection passed and found (or if suspended)
		set otherwise

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version
	ardeb	12/91		changed to make use of new SET_PATH
				functionality

------------------------------------------------------------------------------@

GenFileSelectorSetFullSelectionPath	method	GenFileSelectorClass, \
				MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Find the selection portion of the passed path. It comes after the
	; last backslash.
	; 
	mov	es, cx
	mov	di, dx
SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	not	cx
	LocalPrevChar esdi	; point back to null
	std
	LocalLoadChar ax, C_BACKSLASH
	LocalFindChar		; repne scasb/scasw
	cld
	mov	cx, es
	jne	setSelection	; => it's all selection, so just do that.

	;
	; Found the selection, now copy the path onto the stack so we can
	; null-terminate it, as we don't think we're allowed to mess with the
	; passed buffer (might be a read-only constant, you know...)
	; 
	LocalNextChar esdi		; point to backslash
	;
	; if we are passed something like <drive letter>:\<selection>,
	; we must treat the slash itself as part of the path.  Nothing
	; need be done specially if we have <drive letter>:\<path>\<selection>.
	;
	mov	bx, 0		; set flag indicating whether we make this fix
	cmp	di, dx		; were we passed "\<selection>" or "\<path>"?
	je	rootFix		; "\selection", special handling
SBCS <	cmp	{byte} es:[di-1], ':'	; have "<drive letter>:\<selection>"?>
DBCS <	cmp	{wchar}es:[di-2], ':'	; have "<drive letter>:\<selection>"?>
	jne	noRootFix
rootFix:
	LocalNextChar esdi	; yes, include slash
	mov	bx, 1		; fix made
noRootFix:
	mov_tr	ax, di
	sub	ax, dx		; figure length of path portion
	stc			; and make a buffer for it on the stack
	sbb	sp, ax		; leaving room for the null...

	; need to allocate one extra space on the stack for DBCS null
DBCS <	dec	sp		>
	segmov	es, ss		; es:di <- buffer for which we just made room
	mov	di, sp
	push	ds, si		; save object
	mov	ds, cx		; ds:si <- passed path
	mov	si, dx
	mov	cx, ax		; cx <- # bytes to copy
	push	bx		; save fix flag
	mov	bx, di		; keep track of this for actually setting the
				;  path
	rep	movsb
	xchg	cx, ax		; al <- 0, cx <- # bytes to clear from stack
SBCS <  stosb			; null-terminate	>   
DBCS <  stosw			; null-terminate	>
SBCS <	lea	dx, [si+1]	; point dx after backslash, which wasn't copied>
DBCS <	lea	dx, [si+2]	; point dx after backslash, which wasn't copied>
	pop	ax		; ax = fix flag (0 if no fix, 1 if fix)
	sub	dx, ax		; adjust if we make a fix, no adjust otherwise
	mov	ax, ds
	;
	; Recover the object and call ourselves to set the path from the buffer
	; we just created.
	; 
	pop	ds, si
	push	ax, dx, cx	; save start of selection (ax:dx) and number
				;  of bytes we'll need to clear from the stack
	mov	cx, ss		; cx:dx <- path to set
	mov	dx, bx		; bp still the disk handle, or whatnot
	mov	ax, MSG_GEN_PATH_SET
	call	ObjCallInstanceNoLock
	pop	cx, dx, ax	; cx:dx <- selection, ax <- bytes to clear
	stc
	adc	sp, ax		; clear buffer off the stack

	; add back extra byte for dbcs case
DBCS <	inc	sp		>
setSelection:
	;
	; Now call ourselves to set the selection itself.
	; 
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
	GOTO	ObjCallInstanceNoLock
GenFileSelectorSetFullSelectionPath	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorGetDestinationPath -- 
			MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
		for GenFileSelectorClass

DESCRIPTION:	Get the current pathname for destination-related operations.

PASS:	*ds:si - instance data
	ds:di - Gen instance data
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	dx:bp - address to copy to
	cx - size of buffer (may be zero)

RETURN:	carry set if error (path won't fit in the passed buffer):
		ax - number of bytes required
		cx - disk handle of path
	carry clear if ok:
		dx:bp - filled with complete path (fptr preserved)
		cx - disk handle of path
		ax - destroyed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if error, give only rough approximation of additional space needed

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/92		Initial version

------------------------------------------------------------------------------@

GenFileSelectorGetDestinationPath	method	dynamic GenFileSelectorClass, \
				MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	uses	dx, bp
	.enter

	mov	bx, cx				; save buffer size
	mov	es, dx				; es:di = buffer (for later)
	mov	di, bp

	mov	ax, MSG_GEN_PATH_GET		; fill in path portion
	call	ObjCallInstanceNoLock		; carry clear if ok:
						;	cx = disk handle
						; carry set if error
						;	ax = bytes needed or 0
						;	cx = disk handle
	pushf					; save error flag
	add	ax, size GFSI_selection		; assume error, will need this
						;	many MORE bytes for
						;	selection
	popf					; restore error flag
	jc	done				; error

	push	bx				; save buffer size
	mov	ax, TEMP_GEN_FILE_SELECTOR_DATA
	call	ObjVarDerefData			; ds:bx = GFS temp data
						; (may cause obj block motion)
	mov	bp, ds:[bx].GFSTDE_selectionFlags	; bp = entry flags
	pop	bx				; restore buffer size
	test	bp, mask GFSEF_PARENT_DIR	; is parent dir selected?
	jnz	done				; yes, done (no selection)
	test	bp, mask GFSEF_NO_ENTRIES	; anything selected?
	jnz	done				; nope, done
	andnf	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_SUBDIR shl offset GFSEF_TYPE	; subdir selected?
	jne	done				; nope, done

	push	cx				; save disk handle for return

	; find the end of the path

SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
	LocalFindChar				;repne scasb/scasw
	not	cx				; cx <- # chars (including null)

	sub	bx, cx				; bx = space left in buffer
DBCS <	sub	bx, cx							>
	mov	ax, size GFSI_selection		; space needed for selection
	inc	bx				; account for twice-counted null
DBCS <	inc	bx							>
	cmp	bx, ax				; is there enough room for
						;	selection?
	jb	donePopDiskHandle		; nope (carry set)
						; ax = size GFSI_selection

	; append a backslash if there's anything there.

	cmp	cx, 2				; empty?
	jb	addSeparator			; yes -- add separating
						;  backslash; this is fine since
						;  FileSetCurrentPath handles
						;  absolute paths with SP
						;  constants correctly.
	LocalPrevChar esdi			; assume null won't be
						;  overwritten yet
	dec	cx				; update count also
SBCS <	cmp	{char}es:[di-1], C_BACKSLASH	; root?			>
DBCS <	cmp	{wchar}es:[di-2], C_BACKSLASH	; root?			>
	je	checkSelection			; yes -- no separator req'd
	LocalNextChar esdi			; no -- set to overwrite null
	inc	cx				; update count also

addSeparator:
SBCS <	mov	{char}es:[di-1], C_BACKSLASH				>
DBCS <	mov	{wchar}es:[di-2], C_BACKSLASH				>

checkSelection:
	;
	; copy the selected directory name over
	;
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	add	si, offset GFSI_selection	; *ds:si = selection field
	mov	cx, size GFSI_selection
	rep movsb

donePopDiskHandle:
	pop	cx				; cx = disk handle

done:
	.leave
	ret

GenFileSelectorGetDestinationPath	endm

FileSelectorCommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFileSelectorReplaceParams -- 
			MSG_GEN_BRANCH_REPLACE_PARAMS for GenFileSelectorClass

DESCRIPTION:	Replaces action optr, if needed.

PASS:	*ds:si - instance data
	ds:di - Gen instance data
	es - segment of GenFileSelectorClass

	ax - MSG_GEN_BRANCH_REPLACE_PARAMS

	dx - size BranchReplaceParams structure
	ss:bp - BranchReplaceParams

RETURN:	Nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@

GenFileSelectorReplaceParams	method	dynamic GenFileSelectorClass, \
				MSG_GEN_BRANCH_REPLACE_PARAMS
	push	dx
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; replace output optr?
	jne	done					; nope, done
	mov	cx, ss:[bp].BRP_searchParam.handle	; get search param
	mov	dx, ss:[bp].BRP_searchParam.chunk
	cmp	cx, ds:[di].GFSI_destination.handle	; compare search param
	jne	done
	cmp	dx, ds:[di].GFSI_destination.chunk
	jne	done
	mov	cx, ss:[bp].BRP_replaceParam.handle	; get new optr
	mov	dx, ss:[bp].BRP_replaceParam.chunk
	mov	ds:[di].GFSI_destination.handle, cx	; store new optr
	mov	ds:[di].GFSI_destination.chunk, dx
done:
	pop	dx
	mov	di, offset GenFileSelectorClass		; let superclass do
	GOTO	ObjCallSuperNoLock			;	its instance
GenFileSelectorReplaceParams	endm

BuildUncommon	ends

;
;---------------
;
		
FileSelectorCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFileSelectorSendToSpec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send message to specific UI if built, otherwise, do nothing

CALLED BY:	various GenFileSelector messages

PASS:	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenFileSelectorClass

	ax, cx, dx, bp - various

RETURN:	various

ALLOWED TO DESTROY:
	various
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFileSelectorSendToSpec	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_RESCAN,
					MSG_GEN_FILE_SELECTOR_UP_DIRECTORY
	call	GenCallSpecIfGrown
	ret
GenFileSelectorSendToSpec	endm

GenFileSelectorSendToSpecReturnFlags	method	GenFileSelectorClass, \
					MSG_GEN_FILE_SELECTOR_OPEN_ENTRY,
					MSG_GEN_FILE_SELECTOR_SUSPEND,
					MSG_GEN_FILE_SELECTOR_END_SUSPEND
	call	GenCheckIfSpecGrown
	jnc	notGrown
	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock	; Return error flag
notGrown:
	stc				; Return error condition
	ret
GenFileSelectorSendToSpecReturnFlags	endm

;
; Utility routines
;

;
; pass:		*ds:si = GenFileSelector
; return:	ds:di = gen instance
;
GFSMarkDirtyAndDeref	proc	far
	call	ObjMarkDirty
	call	GFSDeref_SI_Gen_DI
	ret

GFSMarkDirtyAndDeref	endp

;
; pass:		*ds:si = file selector
; return:	ds:di = gen instance
;
GFSDeref_SI_Gen_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
GFSDeref_SI_Gen_DI	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSGetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string out of our instance data.

CALLED BY:	GenFileSelectorGetPath, GenFileSelectorGetSelection
PASS:		ds:si	= source string
		cx:dx	= destination string
		ax	= size to copy
RETURN:		nothing
DESTROYED:	ax, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSGetString	proc	near
	mov	es, cx
	mov	di, dx
	xchg	cx, ax		; cx <- size, ax <- preserved cx
	rep movsb
	mov_tr	cx, ax		; restore cx
	ret
GFSGetString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCopyOutAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy out the data associated with a VarData tag, if such
		a tag exists.

CALLED BY:	INTERNAL
PASS:		ax	= GenFileSelectorVarData tag
		cx:dx	= destination for the copy
		*ds:si	= object
RETURN:		carry set if attribute existed
DESTROYED:	ax, bp, bx, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCopyOutAttr	proc	far
		uses	cx
		.enter
	;
	; Look for the VarData first. If not there, return carry clear
	; 
		call	ObjVarFindData
		jnc	done
	;
	; es:di <- cx:dx
	; ds:si <- ds:bx (returned from ObjVarFindData)
	; 
		mov	es, cx
		mov	di, dx
		mov	si, bx
	;
	; Determine the length of the data stored, accounting for the
	; VarDataEntry header itself.
	; 
		mov	cx, ds:[bx-VDE_extraData].VDE_entrySize
		sub	cx, size VarDataEntry
	;
	; And move that all into the destination.
	; 
		rep	movsb
		stc		; signal VarData found
done:
		.leave
		ret
GFSCopyOutAttr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCopyInAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data into a VarData entry for the object.

CALLED BY:	INTERNAL
PASS:		ax	= GenFileSelectorVarData tag
		cx:dx	= buffer from which to copy
		bp	= size of buffer to copy
		*ds:si	= object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCopyInAttr	proc	far
		uses	si, es
		.enter
		ornf	ax, mask VDF_SAVE_TO_STATE	; all attributes go
							;  to state...
	;
	; Add the room in the VarData heap for the object.
	; 
		xchg	cx, bp
		call	ObjVarAddData
	;
	; have:
	; 	cx = size to copy in.
	; 	bp:dx = passed buffer
	; 	ds:bx = new buffer
	; need:
	; 	es:di <- new buffer
	; 	ds:si <- passed buffer
	; 
		segmov	es, ds, ax	; es, ax <- object block
		mov	di, bx
		mov	si, dx
		mov	ds, bp
		rep	movsb
	;
	; Recover ds, just in case.
	; 
		mov	ds, ax
		.leave
		ret
GFSCopyInAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFileSelectorInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialized variable data component passed

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_INITIALIZE_VAR_DATA
		cx	- data type

RETURN:		ds:ax	- ptr to data entry
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version (init code from Brian C)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFileSelectorInitializeVarData	method GenFileSelectorClass,
					MSG_META_INITIALIZE_VAR_DATA
	cmp	cx, TEMP_GEN_FILE_SELECTOR_DATA
	je	TempData
	mov	di, offset GenFileSelectorClass
	GOTO	ObjCallSuperNoLock

TempData:
	mov	ax, cx
	mov	cx, size GFSTempDataEntry
	call	ObjVarAddData		; ds:bx = GFSTempDataEntry

	;
	; Initialize the data entry
	;
	mov	ds:[bx].GFSTDE_selectionFlags, mask GFSEF_ERROR
	mov_tr	ax, bx		; return offset in ax.
	ret

GenFileSelectorInitializeVarData	endm

FileSelectorCommon ends
