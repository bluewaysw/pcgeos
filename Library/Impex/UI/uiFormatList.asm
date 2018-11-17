COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiFormatList.asm

AUTHOR:		jimmy lefkowitz	4/91

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial revision
	don	5/92		Major changes

DESCRIPTION:
	Implementation of FormatList, a subclass of GenDynamicList

	$Id: uiFormatList.asm,v 1.1 97/04/04 22:23:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUICode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build format list

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= FormatListClass object
		ds:di	= FormatListClass instance data
		ds:bx	= FormatListClass object (same as *ds:si)
		es 	= segment of FormatListClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ALLOW_FLOPPY_BASED_LIBS	;----------------------------------------------

FormatListVisOpen	method dynamic FormatListClass, 
					MSG_VIS_OPEN
	mov	di, offset FormatListClass
	call	ObjCallSuperNoLock

	call	BuildFormatList
	ret
FormatListVisOpen	endm

endif	; if ALLOW_FLOPPY_BASED_LIBS ------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListSetDataClasses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set data classes for format list

CALLED BY:	MSG_FORMAT_LIST_SET_DATA_CLASSES

PASS:		DS:DI	- FormatList instance data
		CX	- ImpexDataClasses

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListSetDataClasses method	dynamic	FormatListClass,
					MSG_FORMAT_LIST_SET_DATA_CLASSES
		mov	ds:[di].FLI_dataClasses, cx
		ret
FormatListSetDataClasses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListGetFormatInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns the FormatInfo block handle

PASS:		DS:DI	= FormatListInstance

RETURN:		AX	= # of formats available (excluding No Idea)
		CX	= Format #
		DX	= FormatInfo handle

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListGetFormatInfo	method	dynamic	FormatListClass,
					MSG_FORMAT_LIST_GET_FORMAT_INFO
		.enter

		; Return the information desired
		;
		mov	bx, ds:[di].FLI_formatInfo
		mov	dx, ds:[di].FLI_currentFormat
		call	MemLock
		mov	ds, ax
		mov	si, ds:[FI_formats]
		call	ChunkArrayGetCount	; element count => CX
		call	MemUnlock
		mov_tr	ax, cx			; element count => AX
		mov	cx, dx			; current element => CX
		mov	dx, bx			; FormatInfo handle => DX

		.leave
		ret
FormatListGetFormatInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build format list

CALLED BY:	MSG_FORMAT_LIST_RESCAN
PASS:		*ds:si	= FormatListClass object
		ds:di	= FormatListClass instance data
		ds:bx	= FormatListClass object (same as *ds:si)
		es 	= segment of FormatListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ALLOW_FLOPPY_BASED_LIBS	;----------------------------------------------

FormatListRescan	method dynamic FormatListClass, 
					MSG_FORMAT_LIST_RESCAN
	call	BuildFormatList
	ret
FormatListRescan	endm

endif	; if ALLOW_FLOPPY_BASED_LIBS ------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the initial build of a FormatList by finding
		all libraries with the bound token.

CALLED BY:	MSG_SPEC_BUILD

PASS:		*DS:SI	= FormatListClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		See BUGS/SIDE EFFECTS/IDEAS in FormatEnum, in the
		file uiFormatListLow.asm.
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	 4/91		Initial version
		jenny	12/91		Cleanup, handling of error in FormatEnum
		don	 5/92		More clean-up work & simplification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListSpecBuild	method dynamic	FormatListClass, MSG_SPEC_BUILD
		.enter

		; Let the superclass do what it wants.
		;
		mov	di, offset FormatListClass
		call	ObjCallSuperNoLock	; call our superclass

if not ALLOW_FLOPPY_BASED_LIBS
		call	BuildFormatList
endif
		.leave
		ret
FormatListSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build format list

CALLED BY:	GLOBAL
PASS:		*ds:si	= FormatListClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	6/29/93    	Pulled out of FormatListSpecBuild

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFormatList	proc	near
		class	FormatListClass
		.enter

		; EC-version dies with STACK_OVERFLOW, so borrow stack space
		;
		mov	di, 1000		; stack size we need
		call	ThreadBorrowStackSpace
		push	di			; save borrowed stack "token"

		; If the FormatList is already set up, we're done.
		;
		mov	di, ds:[si]
		add	di, ds:[di].FormatList_offset

if not ALLOW_FLOPPY_BASED_LIBS
		tst	ds:[di].FLI_formatInfo
		jnz	exit
else
		; Since the floppy disk may change, we want this to 
		; always rescan the disk

		clr	bx
		xchg	bx, ds:[di].FLI_formatInfo
		tst	bx
		jz	continue

		call	MemFree			; free old format info block
continue:
endif
		
		mov	bx, ds:[di].FLI_dataClasses
		mov	di, ds:[di].FLI_attrs
CheckHack	<mask FLA_IMPORT eq mask IFI_IMPORT_CAPABLE>
CheckHack	<mask FLA_EXPORT eq mask IFI_EXPORT_CAPABLE>
		and	di, (mask IFI_IMPORT_CAPABLE or mask IFI_EXPORT_CAPABLE)

		; Mark application as busy
		;
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		call	GenCallApplication

		; Now go find all of the libraries & formats
		;
		mov	dx, di			; dx <- ImpexFormatInfo
		call	FormatEnum		; bx <- formatsAndLibs handle
						; cx <- number of formats
		jc	done			; if error, done
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].FLI_formatInfo, bx

		; Initialize the list of formats displayed to the user
		;
		andnf	ds:[di].FLI_attrs, not (mask FLA_NO_IDEA_PRESENT)

if not ALLOW_FLOPPY_BASED_LIBS
		test	ds:[di].FLI_attrs, mask FLA_EXPORT
		jnz	initialize
		cmp	cx, 1			; if only one entry, then
		jbe	initialize		; don't both with "No Idea"
		inc	cx			; add an entry for No Idea
		or	ds:[di].FLI_attrs, mask FLA_NO_IDEA_PRESENT
initialize:
endif
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	bx, cx			; format count => BX
		call	ObjCallInstanceNoLock

		; Shift the exclusive to the first entry in the list.
		; 
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	cx, dx
		tst	bx			; any formats ??
		jnz	setSelection		; yes, so jump
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
setSelection:
		call	ObjCallInstanceNoLock

		; Set the list enabled/disabled as appropriate
		;
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bx
		jnz	setAbled
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setAbled:
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjCallInstanceNoLock

		; Done, no longer busy
done:
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		call	GenCallApplication

		; Return the stack space we borrowed
exit::
		pop	di			; recover "token"
		call	ThreadReturnStackSpace

		.leave
		ret

if (0)	; This doesn't work since ax contains garbage. - Joon (11/4/94)
		; An error occurred while searching for libraries. Tell the
		; user, and then bail out
error:
		mov_tr	bp, ax			; error message chunk => BP
		call	FormatListShowError	; display an error to user
		jmp	done
endif
BuildFormatList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListSpecUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the FormatList structure, as we are going away

CALLED BY:	GLOBAL (MSG_SPEC_UNBUILD)

PASS:		ES	= Segment of FormatListClass
		*DS:SI	= FormatListClass object
		DS:DI	= FormatListClassInstance
		BP	= SpecBuildFlags

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not ALLOW_FLOPPY_BASED_LIBS

FormatListSpecUnbuild	method dynamic	FormatListClass, MSG_SPEC_UNBUILD

		; Free the format info block, if we have not yet done so
		;
		clr	bx
		xchg	bx, ds:[di].FLI_formatInfo
		tst	bx
		jz	done			; if no FormatInfo, we're done
		call	MemFree			; else free the sucker

		; Let the superclass do what it wants.
done:
		mov	di, offset FormatListClass
		GOTO	ObjCallSuperNoLock	; call our superclass
FormatListSpecUnbuild	endm

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListRequestFormatMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request a moniker for the passed format #

CALLED BY:	GLOBAL (MSG_FORMAT_LIST_REQUEST_FORMAT_MONIKER)

PASS:		*DS:SI	= FormatListClass object
		DS:DI	= FormatListClassInstance
		CX:DX	= OD of requestor
		BP	= Format #

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListRequestFormatMoniker	method	dynamic	FormatListClass,
					MSG_FORMAT_LIST_REQUEST_FORMAT_MONIKER
		.enter

		; First see if we have the special "No Idea" case
		;
		push	ds			; save FormatList object segment
		push	bp			; save the item #
		test	ds:[di].FLI_attrs, mask FLA_NO_IDEA_PRESENT
		jz	normal
		dec	bp
		jge	normal			; if not negative 1, then jump

		; We have the special "No Idea" string
		;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	dx, ds:[NoIdeaString]	; string => DS:DX
		assume	ds:nothing
		jmp	common

		; We have the normal case
normal:
		mov	bx, ds:[di].FLI_formatInfo
		mov	cx, bp			; format # => CX
		call	LockFormatDescriptor	; ImpexFormatDescriptor => DS:DI
		mov	dx, di
		add	dx, offset IFD_formatName ; string => DS:DX

		; Now replace the moniker
common:
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		mov	cx, ds			; string => CX:DX
		pop	bp			; item # => BP
		pop	ds			; FormatList OD => *DS:SI
		call	ObjCallInstanceNoLock
		call	MemUnlock		; unlock block locked above

		.leave
		ret
FormatListRequestFormatMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListSelectFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Put up appropriate UI and file spec for the selected format

PASS:		*DS:SI	= FormatList object
		DS:DI	= FormatList instance data
		CX	= Format selected (= which element in array)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Call our parent to deal with the selection

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version
		don	5/92		Changed to let parent deal with it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListSelectFormat	method	dynamic	FormatListClass,
					MSG_FORMAT_LIST_SELECT_FORMAT
		.enter

		; Pass this message on to our parent, after storing
		; the actual format.
		;
if not ALLOW_FLOPPY_BASED_LIBS
		cmp	cx, GIGS_NONE
		je	done
endif
		mov	ds:[di].FLI_currentFormat, cx
		clr	bp			; no "No Idea" choice
		test	ds:[di].FLI_attrs, mask FLA_NO_IDEA_PRESENT
		jz	sendToParent
		dec	ds:[di].FLI_currentFormat
		dec	bp			; yes, "No Idea" is present
sendToParent:
		mov	ax, MSG_IMPORT_EXPORT_SELECT_FORMAT
		mov	dx, ds:[di].FLI_formatInfo
		call	FormatListCallParent	; send message to our parent
done::
		.leave
		ret
FormatListSelectFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListFetchFormatUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the UI (if any) for the currently selected format

CALLED BY:	GLOBAL (MSG_FORMAT_LIST_FETCH_FORMAT_UI)

PASS:		*DS:SI	= FormatListClass object
		DS:DI	= FormatListClassInstance
		BP	= Offset into ImpexFormatDescriptor
				IFD_importUIFlag
				IFD_exportUIFlag
		DX	= Translation library function to call
		CX	= Format #

RETURN:		CX:DX	= Format UI (CX = 0 indicates no UI)
		BP	= Library handle
		Carry	= Clear
			- or -
		Carry	= Set

DESTROYED:	AX, BX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListFetchFormatUI	method dynamic	FormatListClass,
					MSG_FORMAT_LIST_FETCH_FORMAT_UI
		.enter

		; First, let's see if there's any UI to get
		;
		segmov	es, ds			; FormatList segment => ES
		mov	bx, ds:[di].FLI_formatInfo
		call	LockFormatDescriptor	; ImpexFormatDescriptor => DS:DI
		clr	cx			; assume no UI
		cmp	{word} ds:[di][bp], 0
		je	exit			; no UI, so we're done

		; We have UI, so we need to load the library & ask for it
		; We can't just look into the data we have stored away, as
		; the handle we have has not been unrelocated.
		;
		push	bx			; save FormatInfo handle
		push	di			; save offset to IFD
		mov	di, ds:[di].IFD_library
		mov	di, ds:[di]		; ImpexLibraryDescriptor=>DS:DI
		call	ImpexLoadLibrary	; library handle => BX
		mov_tr	ax, dx			; library function to call => AX
		mov	dx, di			; library name => DS:DX
		pop	di			; ImpexFormatDescriptor => DS:DI
		jc	errorLibrary		; if error, abort
		mov	cx, ds:[di].IFD_formatNumber
		push	bx			; save library handle
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; format UI => CX:DX
		pop	bp			; library handle => BP
		clc				; indicate success
done:
		pop	bx			; FormatInfo handle => BX
exit:
		call	MemUnlock		; unlock FormatInfo

		.leave
		ret		

		; Display an error to the user
errorLibrary:
		mov	cx, ds			; library name => CX:DX
		segmov	ds, es			; FormatList segment => DS
		mov	bp, IE_COULD_NOT_LOAD_XLIB
		call	FormatListShowError	; display an error to user
		mov	cx, 0			; no UI to display (carry=set)
		jmp	done
FormatListFetchFormatUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utitlities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListCallParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to our controller parent via a CALL

CALLED BY:	INTERNAL

PASS:		AX	= Message to send
		CX,DX,BP= Data to send
		DS	= Object block segment

RETURN:		see message declaration

DESTROYED:	see message declaration (+ BX, SI, DI)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListCallParent	proc	near
		.enter
	
		; Send the message off
		;
		call	ObjBlockGetOutput
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
FormatListCallParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultFileMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Gets the default file mask string

CALLED BY: 	INTERNAL

PASS:		BX	= FormatInfo handle
		CX	= Format # to use

RETURN: 	CX:DX	= NULL-terminated file mask string
		BX	= FormatInfo handle (now locked)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWNN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDefaultFileMask	proc	near
		uses	ax, di, si, ds
		.enter

		; Get appropriate element from  array
		;
		call	LockFormatDescriptor	; ImpexFormatDescriptor => DS:DI
		mov	cx, ds
		mov	dx, di
		add	dx, offset IFD_defaultFileMask
		call	UpcaseString		; make all characters upper-case

		.leave
		ret
GetDefaultFileMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatListShowError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error by calling the parent Import/Export clas
		object with a string to display

CALLED BY:	INTERNAL

PASS:		DS	= Segment of FormatList object
		BP	= ImpexError
		CX:DX	= Optional string argument (NULL-terminated)

RETURN:		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatListShowError	proc	far
		uses	ax, bx, di, si
		.enter
	
		mov	ax, MSG_IMPORT_EXPORT_SHOW_ERROR
		call	FormatListCallParent
		stc

		.leave
		ret
FormatListShowError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFormatDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down a FormatDescriptor

CALLED BY:	INTERNAL

PASS:		BX	= FormatInfo block handle
		CX	= Selected format => CX

RETURN:		DS:DI	= ImpexFormatDescriptor

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockFormatDescriptor	proc	near
		uses	ax, cx, si
		.enter
	
		; Lock down the block, and do some dereferencing
		;
		call	MemLock
		mov	ds, ax
		mov	si, ds:[FI_formats]
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr	; chunk handle => DI
		mov	di, ds:[di]		; descriptor chunk => DI
		mov	di, ds:[di]		; descriptor => DS:DI

		.leave
		ret
LockFormatDescriptor	endp

ImpexUICode	ends
