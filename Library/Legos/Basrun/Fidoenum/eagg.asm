COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		eagg.asm

AUTHOR:		Paul L. Du Bois, Jul 10, 1995

ROUTINES:
	Name			Description
	----			-----------
    GLB FIDOREGISTERAGG		C anti-stub for FidoRegisterAgg

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/10/95   	Initial revision


DESCRIPTION:
	Aggregate component support for FidoFindComponent.
		

	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include localize.def

MainCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOREGISTERAGG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register an aggregate component

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
		    FidoRegisterAgg
			(FTaskHan	fidoTask,
			 ModuleToken	module,
			 char _far*	aggName,
			 RTaskHan	rtask,
			 word		func)

PSEUDO CODE/STRATEGY:
	Return FALSE if agg was already registered.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOREGISTERAGG	proc	far \
	task:hptr, module:word, aggName:fptr.char, rtaskHan:hptr, func:word
	aggNameLen	local	word
	uses	ds,si, es,di ;,cx,dx
	.enter

		mov	bx, ss:[task]
		call	TaskLockDS

		les	di, ss:[aggName]
		call	LocalStringLength
		inc	cx
		mov	ss:[aggNameLen], cx

		mov	si, ds:[FT_modules]
		mov	ax, ss:[module]
		call	ChunkArrayElementToPtr
EC <		ERROR_C	FIDO_INVALID_MODULE_TOKEN			>

		mov	ax, ds:[di].MD_myLibrary
		cmp	ax, CA_NULL_ELEMENT
		jne	noCreate

	; Create an element in the library array for this aggregate library
	; and fill in some agg-specific data
	;
		clr	ax, bx, cx, si	; variable size, std header, no chunk
		call	ChunkArrayCreate
		mov	cx, si		; cx <- array of AggCompDecl

		mov	ax, mask LDF_AGGREGATE
		mov	bx, ss:[rtaskHan]
		call	Fido_AddLibrary	; ax <- new FT_libraries element
if 1
PrintMessage <temporary backwards-compatibility code>
	; Need to give builder a chance to add UseLibrary() calls
	; when there are loaded agg libs
		call	Fido_AddGlobalLibraryRef
		mov	si, ds:[FT_libraries]
		call	ElementArrayAddReference
endif
	; Init extra fields in elt
		mov	si, ds:[FT_libraries]
		call	ChunkArrayElementToPtr
		mov_tr	dx, ax		; dx <- new library elt
		mov	ds:[di].LD_components, cx
		mov	ax, ss:[module]
		mov	ds:[di].LD_myModule, ax

	; and give module a reference to library
		mov	si, ds:[FT_modules]
		call	ChunkArrayElementToPtr
		mov	ds:[di].MD_myLibrary, dx
		mov_tr	ax, dx

noCreate:
	; ax <- FT_libraries element #
	; Add a component to this library's list of decls
	;
		mov	si, ds:[FT_libraries]
		call	ChunkArrayElementToPtr
		mov	si, ds:[di].LD_components

		mov	ax, ss:[aggNameLen]
DBCS <		shl	ax		; convert to size		>
		add	ax, size AggCompDecl
		call	ChunkArrayAppend
		mov	ax, ss:[func]
		mov	ds:[di].ACD_constructor, ax
	; copy in the name
		push	ds
		add	di, offset ACD_name
		segmov	es, ds, ax	; es:di <- ACD_name
		lds	si, ss:[aggName]
		mov	cx, ss:[aggNameLen]
		LocalCopyNString
		pop	ds
		call	TaskUnlockDS
	.leave
	ret
FIDOREGISTERAGG	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoRegisterAgg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	asm stub for FidoRegisterAgg

CALLED BY:	GLOBAL
PASS:		ds:si	- name of agg
		bx	- hptr.FidoTask
		cx	- module
		dx	- "constructor" function
RETURN:		ax	- zero on error (already registered)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoRegisterAgg	proc	far
	uses	cx,dx
	.enter
		push	bx			;fidoTask
		pushdw	dssi			;aggName
		push	cx			;module
		push	dx			;func
		call	FIDOREGISTERAGG
	.leave
	ret
FidoRegisterAgg	endp
MainCode	ends
