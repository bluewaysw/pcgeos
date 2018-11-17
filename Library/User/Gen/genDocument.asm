COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genDocument.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDocumentClass	Document management

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to implement the GenDocument class.

	$Id: genDocument.asm,v 1.1 97/04/07 11:44:58 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------


			        GenDocumentClass

Synopsis
--------
GenDocumentClass is part of the document control mechanism that implements
high level document handling.

See the file "documentControl" for full documentation.

Limitations
-----------
See "documentControl".

Alternatives
------------
See "documentControl".

Implementation Status
---------------------
See "documentControl".

See Also
--------
See "documentControl".

;------------------------------------------------------------------------------
;	Implementation Notes
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Most frequently asked questions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	Inheritance
;------------------------------------------------------------------------------

From GenClass:
-------------

    GI_link		LinkPart <>
    ; Legal parents are GenAppDocumentControlClass

    GI_comp		CompPart <>
    ; A GenDocumentClass object has children if it is being used as a
    ; content object at the head of a visual (or generic tree).

    GI_visMoniker	lptr
    ; The moniker for a GenDocument is currently not used

    GI_kbdAccelerator	KeyboardShortcut <>
    ; The keyboard accelerator for a document is currently not used

    GI_attrs		GenAttrs
    ; Documents should be both usable and enabled

    GI_states		GenStates

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenDocumentClass

UserClassStructures	ends

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDocumentBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for
						GenDocumentClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenDocumentClass

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

GenDocumentBuild	method	GenDocumentClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

	mov	ax, SPIR_BUILD_DOCUMENT
	GOTO	GenQueryUICallSpecificUI

GenDocumentBuild	endm

Build	ends

;
;---------------
;
		
Build	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentRelocOrUnReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the path bound to this object

CALLED BY:	MSG_META_RELOCATE, MSG_META_UNRELOCATE
PASS:		*ds:si	= object
		ds:di	= GenDocumentInstance
		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		perhaps this thing should reloc/unreloc the enableDisableList?
		currently it is referenced exactly once on the spui, so it
		doesn't seem worth it...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDocumentRelocOrUnReloc method GenDocumentClass, reloc
		.enter
		cmp	ax, MSG_META_UNRELOCATE
		jne	done
		mov	ds:[di].GDI_fileHandle, 0
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathUnrelocObjectPath
done:
		clc
		.leave
		mov	di, offset GenDocumentClass
		call	ObjRelocOrUnRelocSuper
		ret
GenDocumentRelocOrUnReloc endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the initialization of ATTR_GEN_PATH_DATA, if such
		this be.

CALLED BY:	MSG_META_INITIALIZE_VAR_DATA
PASS:		*ds:si	= generic object
		cx	= variable data type
RETURN:		ax	= offset to extra data created
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDocumentInitializeVarData method dynamic GenDocumentClass,
				       MSG_META_INITIALIZE_VAR_DATA
		cmp	cx, ATTR_GEN_PATH_DATA
		je	initGenDocumentPathData
		mov	di, offset GenDocumentClass
		GOTO	ObjCallSuperNoLock

initGenDocumentPathData:
	;
	; Add the data to the object.
	; 
		mov	ax, ATTR_GEN_PATH_DATA or mask VDF_SAVE_TO_STATE
		mov	cx, size GenFilePath
		call	ObjVarAddData
	;
	; Initialize it to SP_DOCUMENT (SP_TOP for redwood)
	; 
if UNTITLED_DOCS_ON_SP_TOP
		mov	ds:[bx].GFP_disk, SP_TOP
else
		mov	ds:[bx].GFP_disk, SP_DOCUMENT
endif
		mov	ds:[bx].GFP_path[0], 0
	;
	; Return offset in ax
	; 
		mov_tr	ax, bx
		ret
GenDocumentInitializeVarData endm

Build	ends
