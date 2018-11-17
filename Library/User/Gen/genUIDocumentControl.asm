COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genUIDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDocumentControlClass	Document management

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to implement the GenDocumentControl class.

	$Id: genUIDocumentControl.asm,v 1.1 97/04/07 11:45:03 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

GenDocumentControlClass:

Synopsis
--------

GenDocumentControlClass is the part of document control that runs in the
application thread.  It manages GenDocument's and works with a
GenDocumentControl to give the user controls to manipulate the documents
(usually new, open, close, save, save as).

See the file "documentControl" for full documentation.

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenDocumentControlClass

UserClassStructures	ends

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDocumentControlBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for
						GenDocumentControlClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenDocumentControlClass

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

GenDocumentControlBuild	method	GenDocumentControlClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

	mov	ax, SPIR_BUILD_UI_DOCUMENT_CONTROL
	GOTO	GenQueryUICallSpecificUI

GenDocumentControlBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentControlInitializeVarData
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
GenDocumentControlInitializeVarData method dynamic GenDocumentControlClass,
				       MSG_META_INITIALIZE_VAR_DATA
		cmp	cx, ATTR_GEN_PATH_DATA
		je	initGenDocumentControlPathData
		mov	di, offset GenDocumentControlClass
		GOTO	ObjCallSuperNoLock

initGenDocumentControlPathData:
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
GenDocumentControlInitializeVarData endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentControlRelocOrUnReloc
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
GenDocumentControlRelocOrUnReloc method GenDocumentControlClass, reloc
		.enter
		cmp	ax, MSG_META_UNRELOCATE
		jne	done
		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathUnrelocObjectPath
done:
		clc
		.leave
		mov	di, offset GenDocumentControlClass
		call	ObjRelocOrUnRelocSuper
		ret
GenDocumentControlRelocOrUnReloc endm

Build ends
