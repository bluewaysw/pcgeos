COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genAppDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDocumentGroupClass	Document management

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to implement the GenDocumentGroup
	class.

	$Id: genAppDocumentControl.asm,v 1.1 97/04/07 11:44:53 newdeal Exp $

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
    ; Legal parents are GenDocumentGroupClass

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

	GenDocumentGroupClass


	;
	; Pass this on to each of our GenDocument children.
	;
	method	GenSendToChildren, GenDocumentGroupClass, MSG_META_REMOVING_DISK

UserClassStructures	ends

;---------------------------------------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenDocumentGroupBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for
						GenDocumentGroupClass

DESCRIPTION:	Return the correct specific class for an object

PASS:	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenDocumentGroupClass

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

GenDocumentGroupBuild	method	GenDocumentGroupClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

	mov	ax, SPIR_BUILD_APP_DOCUMENT_CONTROL
	GOTO	GenQueryUICallSpecificUI

GenDocumentGroupBuild	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenDocumentGroupStartup -- 
		MSG_META_APP_STARTUP for GenDocumentGroupClass

DESCRIPTION:	Do what we must when application first starts up.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_APP_STARTUP
		^hdx	- AppLaunchBlock

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/18/93         	Initial Version

------------------------------------------------------------------------------@

GenDocumentGroupStartup	method dynamic	GenDocumentGroupClass, \
				MSG_META_APP_STARTUP

	mov	di, offset GenDocumentGroupClass
	call	ObjCallSuperNoLock

	;
	; Add to removable disk list, so we'll be notified of the disk being
	; removed.
	;
	call	GenDocumentGroupAddToRemovableDiskList


	ret
GenDocumentGroupStartup	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentGroupRemoveFromRemovableDiskList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes app obj from removable disk list, if it is on it

CALLED BY:	INTERNAL
		GenDocumentGroupTransparentDetach
		UI_Detach
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDocumentGroupRemoveFromRemovableDiskList	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Take ourselves off GCNSLT_REMOVABLE_DISK list, if we're on it.
	;
	call	GetRemovableDiskListArgs
	call	GCNListRemove
	.leave
	ret
GenDocumentGroupRemoveFromRemovableDiskList	endp

GenDocumentGroupAddToRemovableDiskList	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Add ourselves to the GCNSLT_REMOVABLE_DISK list, if we're not
	; on it.
	;
	call	GetRemovableDiskListArgs
	call	GCNListAdd
	.leave
	ret
GenDocumentGroupAddToRemovableDiskList	endp

GetRemovableDiskListArgs	proc	near
	mov	cx, ds:[LMBH_handle]
	mov	dx, si	
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_REMOVABLE_DISK
	ret
GetRemovableDiskListArgs	endp

COMMENT @----------------------------------------------------------------------

METHOD:		GenDocumentGroupDetach -- MSG_META_DETACH for
						GenDocumentGroupClass

DESCRIPTION:	Send attach to children

PASS:
	*ds:si - instance data
	es - segment of GenDocumentGroupClass
	ax - MSG_META_APP_SHUTDOWN

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
GenDocumentGroupDetach	method dynamic GenDocumentGroupClass,
						MSG_META_APP_SHUTDOWN

	mov	di, offset GenDocumentGroupClass
	call	ObjCallSuperNoLock

	;
	; Remove from removable disk list.
	;
	call	GenDocumentGroupRemoveFromRemovableDiskList


	Destroy	ax, cx, dx, bp
	ret

GenDocumentGroupDetach	endm

Build ends



