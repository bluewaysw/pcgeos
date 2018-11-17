COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genTextEditClass.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_INITIALIZE

    MTD MSG_GEN_LOAD_OPTIONS    Load options from .ini file

    MTD MSG_GEN_SAVE_OPTIONS    Save our options

    MTD MSG_GEN_TEXT_SET_INDETERMINATE_STATE 
				Sets the indeterminate state.

    MTD MSG_GEN_TEXT_IS_INDETERMINATE 
				Returns whether value is indeterminate.

    MTD MSG_GEN_TEXT_SET_MODIFIED_STATE

    MTD MSG_GEN_TEXT_IS_MODIFIED 
				Returns whether value is modified.

    MTD MSG_GEN_TEXT_SEND_STATUS_MSG 
				Sends off the status message.

    INT GenTextSendMsg          Sends a message to the destination, with
				usual arguments.

    MTD MSG_GEN_APPLY           Handles applies.

    MTD MSG_GEN_TEXT_GET_DESTINATION 
				Returns the destination.

    MTD MSG_GEN_TEXT_SET_DESTINATION 
				Sets a new destination.

    MTD MSG_GEN_TEXT_GET_APPLY_MSG 
				Returns apply message.

    MTD MSG_GEN_TEXT_SET_APPLY_MSG 
				Sets a new apply message.

    INT Text_DerefGenDI         Sets a new apply message.

    MTD MSG_GEN_TEXT_GET_ATTRS  Gets text attributes.

    MTD MSG_GEN_TEXT_SET_ATTRS  Sets attrs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

DESCRIPTION:
	This file contains routines to implement the TextEdit class

	$Id: genTextEdit.asm,v 1.1 97/04/07 11:45:01 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

GenTextClass:

Synopsis
--------

GenText class provides a text edit object.
	
------------------------------------------------------------------------------@
UserClassStructures	segment resource

	; Class definition

	GenTextClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenTextBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenTextClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@
GenTextBuild	method	GenTextClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

	mov	ax, SPIR_BUILD_TEXT
	GOTO	GenQueryUICallSpecificUI

GenTextBuild	endm



COMMENT @----------------------------------------------------------------------

		GenTextRelocOrUnReloc

DESCRIPTION:	relocate or unrelocate dynamic list

	SPECIAL NOTE:  This routine is run by the application's
	process thread.

PASS:	*ds:si - instance data
	es - segment of GenTextListClass
	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
	cx - handle of owner


RETURN:	carry clear to indicate successful relocation!

ALLOWED TO DESTROY:
	ax, cx, dx, bp 
	bx, si, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@

if	0	;Will comment in after distribution

	;CHRIS: You can't do this -- It is basically not a good thing to send
	;	a message here -- tony 8/24/92

GenTextRelocOrUnReloc	method GenTextClass, reloc
				; We only need to handle unrelocation, where
				; this object is about to go out to a state 
				; file.
	cmp	ax, MSG_META_UNRELOCATE
	jne	done

				; Make sure generic instance data is up-to-date
				; from the visual instance data.
	push	bp
	mov	ax, MSG_VIS_TEXT_UPDATE_GENERIC
	call	ObjCallInstanceNoLock
	pop	bp
done:
	clc
	mov	di, offset GenTextClass
	GOTO	ObjRelocOrUnRelocSuper

GenTextRelocOrUnReloc	endm

endif


Build	ends

;
;---------------
;
		
BuildUncommon	segment	resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenTextInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init instance data.

CALLED BY:	MSG_META_INITIALIZE

PASS:		nothing
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mav	12/xx/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenTextInitialize	method dynamic GenTextClass, MSG_META_INITIALIZE
	mov	ds:[di].GTXI_maxLength, -1

	mov	di, offset GenTextClass
	GOTO	ObjCallSuperNoLock
GenTextInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenTextCopyTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy this text display object

CALLED BY:	MSG_GEN_COPY_TREE

PASS:		*ds:si	= GenTextClass object
		ds:di	= GenTextClass instance data
		ax	= MSG_GEN_COPY_TREE

RETURN:		cx:dx	- OD of new object created

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenTextCopyTree	method	GenTextClass, MSG_GEN_COPY_TREE
EC <	call	ECCheckGenCopyTreeArgs	;check passed arguments		>
	push	bp
	;
	; First call my superclass
	;
	mov	di, offset GenTextClass
	call	ObjCallSuperNoLock
	;
	; Lock the new block, and access generic data of new and old
	;
	mov	bx, cx				; block handle to BX
	call	ObjLockObjBlock
	mov	es, ax				; segment to ES
	mov	bx, dx				; chunk handle to BX
	mov	bx, es:[bx]			; dereference it
	add	bx, es:[bx].Gen_offset		; access generic data of new
	mov	di, ds:[si]			; dereference old chunk handle
	add	di, ds:[di].Gen_offset		; access generic data of old
	;
	; Copy the text chunk over
	;
	mov	ax, ds:[di].GTXI_text
	pop	bp
	and	bp, mask CCF_MARK_DIRTY		;Restore dirty flag
	push	cx, dx				; save our new object
	segxchg	ds, es
	call	GenCopyChunk
	segxchg	ds, es
	pop	cx, dx				; restore our new object

	mov	bx, dx				; chunk handle back to BX
	mov	bx, es:[bx]			; dereference it
	add	bx, es:[bx].Gen_offset		; access generic data of new
	mov	es:[bx].GTXI_text, ax		; store the new text handle

	mov	bx, cx				; put block handle back in BX
	GOTO	MemUnlock			; clean up

GenTextCopyTree	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenTextReplaceParams

DESCRIPTION:	Replaces any generic instance data paramaters that match
		BranchReplaceParamType

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_BRANCH_REPLACE_PARAMS

	dx	- size BranchReplaceParams structure
	ss:bp	- offset to BranchReplaceParams


RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

GenTextReplaceParams	method	GenTextClass, \
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output OD?
	je	replaceOD		; 	branch if so
	jmp	short done

replaceOD:
					; Replace action OD if matches
					;	search OD
	mov	ax, MSG_GEN_TEXT_SET_DESTINATION
	mov	bx, offset GTXI_destination
	call	GenReplaceMatchingDWord
done:
	ret				; & all done (superclass only calls
					; children, which we don't have)

GenTextReplaceParams	endm

BuildUncommon	ends

IniFile segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenTextLoadOptions -- MSG_GEN_LOAD_OPTIONS for GenTextClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of GenTextClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenTextLoadOptions	method dynamic	GenTextClass, MSG_GEN_LOAD_OPTIONS
	push	ds, si
	segmov	ds, ss
	lea	si, ss:[bp].GOP_category
	mov	cx, ss
	lea	dx, ss:[bp].GOP_key
	mov	bp, INITFILE_INTACT_CHARS
	call	InitFileReadString		;bx = buffer
	pop	ds, si
	jc	done

	mov	dx, bx				;dx = block
	clr	cx				;cx = size
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	call	ObjCallInstanceNoLock

	call	MemFree
done:
	ret

GenTextLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenTextSaveOptions -- MSG_GEN_SAVE_OPTIONS
						for GenTextClass

DESCRIPTION:	Save our options

PASS:
	*ds:si - instance data
	es - segment of GenTextClass

	ax - The message

	ss:bp - GenOptionsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenTextSaveOptions	method dynamic	GenTextClass, MSG_GEN_SAVE_OPTIONS

	mov	si, ds:[di].GTXI_text
	mov	di, ds:[si]
	segmov	es, ds

	segmov	ds, ss
	lea	si, ss:[bp].GOP_category
	mov	cx, ss
	lea	dx, ss:[bp].GOP_key
	call	InitFileWriteString

	ret

GenTextSaveOptions	endm

IniFile ends


		
DestroyCommon	segment	resource


COMMENT @-----------------------------------------------------------------------

METHOD:		GenFinalObjFree -- MSG_META_FINAL_OBJ_FREE for GenClass

DESCRIPTION:	Intercept method normally handled at MetaClass to add
		behavior of freeing the chunks that a GenClass object
		references.
		Free chunk, hints & vis moniker, unless any of these chunks
		came from a resource, in which case we mark dirty & resize
		to zero.

PASS:	*ds:si - object

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

-------------------------------------------------------------------------------@

GenTextFinalObjFree	method GenTextClass, MSG_META_FINAL_OBJ_FREE

;	If we are built out, don't free our text chunk (which we share with the
;	VisText object), as the VisText message handler frees it.

	call	VisCheckIfVisGrown
	jc	afterText
	mov	ax, ds:[di].GTXI_text
	tst	ax
	jz	afterText
	call	ObjFreeChunk

afterText:
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset GenTextClass
	GOTO	ObjCallSuperNoLock

GenTextFinalObjFree	endm

DestroyCommon ends


Text	segment 	resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSetIndeterminateState -- 
		MSG_GEN_TEXT_SET_INDETERMINATE_STATE for GenTextClass

DESCRIPTION:	Sets the indeterminate state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_INDETERMINATE_STATE
		
		cx	- non-zero to set the value indeterminate

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextSetIndeterminateState	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SET_INDETERMINATE_STATE

	mov	dl, mask GVSF_INDETERMINATE
	mov	bx, offset GTXI_stateFlags
	call	GenSetBitInByte
	jnc	exit

	call	GenCallSpecIfGrown		;need to redraw things
exit:
	Destroy	ax, cx, dx, bp
	ret
GenTextSetIndeterminateState	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenTextIsIndeterminate -- 
		MSG_GEN_TEXT_IS_INDETERMINATE for GenTextClass

DESCRIPTION:	Returns whether value is indeterminate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_IS_INDETERMINATE

RETURN:		carry set if value is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextIsIndeterminate	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_IS_INDETERMINATE

	test	ds:[di].GTXI_stateFlags, mask GVSF_INDETERMINATE
	jz	exit			;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenTextIsIndeterminate	endm







COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSetModifiedState -- 
		MSG_GEN_TEXT_SET_MODIFIED_STATE for GenTextClass

DESCRIPTION:	

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_MODIFIED_STATE

		cx	- non-zero to mark modified, zero to mark not modified.

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextSetModifiedState	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SET_MODIFIED_STATE

	push	cx
	mov	dl, mask GVSF_MODIFIED
	mov	bx, offset GTXI_stateFlags
	call	GenSetBitInByte
	pop	cx
 	jnc	exit				;no change, exit

	push	cx
	call	GenCallSpecIfGrown		;send on to superclass
	pop	cx				;  (4/20/93 cbh)

 	tst	cx
 	jz	exit				;not setting modified, exit

 	;	
 	; Make the summons this object is in applyable.  -cbh 9/ 8/92
 	;
 	mov	ax, MSG_GEN_MAKE_APPLYABLE
 	call	ObjCallInstanceNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret

GenTextSetModifiedState	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenTextIsModified -- 
		MSG_GEN_TEXT_IS_MODIFIED for GenTextClass

DESCRIPTION:	Returns whether value is modified.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_IS_MODIFIED

RETURN:		carry set if value is modified.
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextIsModified	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_IS_MODIFIED

	test	ds:[di].GTXI_stateFlags, mask GVSF_MODIFIED
	jz	exit				;not modified, exit, carry clear
	stc	
exit:
	Destroy	ax, cx, dx, bp
	ret
GenTextIsModified	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSendStatusMsg -- 
		MSG_GEN_TEXT_SEND_STATUS_MSG for GenTextClass

DESCRIPTION:	Sends off the status message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SEND_STATUS_MSG

		cx	- non-zero if GIGSF_MODIFIED bit should be passed set
			  in status message

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextSendStatusMsg	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SEND_STATUS_MSG

	mov	ax, ATTR_GEN_TEXT_STATUS_MSG
	call	ObjVarFindData		; ds:bx = data, if found
	jnc	exit			; no message, exit
	mov	ax, ds:[bx]		; else, fetch message

	tst	cx			; check for changed flag passed
	jz	10$			; no, branch
	mov	ch, mask GVSF_MODIFIED	; else pass modified
10$:
	mov	cl, ds:[di].GTXI_stateFlags
	andnf	cl, mask GVSF_INDETERMINATE
	ornf	cl, ch			; use indeterminate flag plus modified
					;   flag passed
	GOTO	GenTextSendMsg
exit:	
	ret

GenTextSendStatusMsg	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GenTextSendMsg

SYNOPSIS:	Sends a message to the destination, with usual arguments.

CALLED BY:	GenTextSendStatusMsg, GenTextApply

PASS:		*ds:si -- object
		ax     -- message to send
		cl     -- state flags to pass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/28/92		Initial version

------------------------------------------------------------------------------@

GenTextSendMsg	proc	far
	class	GenTextClass

	tst	ax			; no message, exit
	jz	exit
	mov	bp, cx			; state flags in bp low now

	call	Text_DerefGenDI	
	pushdw	ds:[di].GTXI_destination ; push them for GenProcessAction

	call	GenProcessGenAttrsBeforeAction
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction	; send the message
	call	GenProcessGenAttrsAfterAction
exit:
	Destroy	ax, cx, dx, bp
	ret
GenTextSendMsg	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenTextApply -- 
		MSG_GEN_APPLY for GenTextClass

DESCRIPTION:	Handles applies.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_APPLY

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextApply	method dynamic	GenTextClass, MSG_GEN_APPLY
	call	GenCallSpecIfGrown			;get up to date
	;	
	; in general, only send out apply if modified.
	;
	call	Text_DerefGenDI
	mov	ax, ds:[di].GTXI_applyMsg
	mov	cl, ds:[di].GTXI_stateFlags
	test	cl, mask GTSF_MODIFIED			;modified?
	jnz	sendMsg					;yes, send message

	;
	; Not modified, will still send apply message if dougarized hint is
	; present...
	;
	push	ax
	mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	call	ObjVarFindData				;does this exist?
	pop	ax
	jc	sendMsg					;yes, send anyway
	ret
sendMsg:
	;
	; Send out the apply message
	;
	call	GenTextSendMsg
	;
	; Clear the modified bit.
	;
	call	Text_DerefGenDI	
	and	ds:[di].GTXI_stateFlags, not mask GVSF_MODIFIED
	ret

GenTextApply	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenTextGetDestination -- 
		MSG_GEN_TEXT_GET_DESTINATION for GenTextClass

DESCRIPTION:	Returns the destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_GET_DESTINATION

RETURN:		^lcx:dx - destination
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextGetDestination	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_GET_DESTINATION
	mov	bx, offset GTXI_destination
	call	GenGetDWord
	Destroy	ax, bp
	ret
GenTextGetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSetDestination -- 
		MSG_GEN_TEXT_SET_DESTINATION for GenTextClass

DESCRIPTION:	Sets a new destination.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_DESTINATION

		^lcx:dx - destination

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextSetDestination	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SET_DESTINATION
	mov	bx, offset GTXI_destination
	GOTO	GenSetDWord
GenTextSetDestination	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenTextGetApplyMsg -- 
		MSG_GEN_TEXT_GET_APPLY_MSG for GenTextClass

DESCRIPTION:	Returns apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_GET_APPLY_MSG

RETURN:		ax 	- current apply message
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextGetApplyMsg	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_GET_APPLY_MSG
	mov	ax, ds:[di].GTXI_applyMsg
	Destroy	cx, dx, bp
	ret
GenTextGetApplyMsg	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSetApplyMsg -- 
		MSG_GEN_TEXT_SET_APPLY_MSG for GenTextClass

DESCRIPTION:	Sets a new apply message.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_APPLY_MSG

		cx	- new apply message

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
	chris	5/28/92		Initial Version

------------------------------------------------------------------------------@

GenTextSetApplyMsg	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SET_APPLY_MSG
	mov	bx, offset GTXI_applyMsg
	GOTO	GenSetWord
GenTextSetApplyMsg	endm


Text_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
Text_DerefGenDI	endp


Text	ends


UtilityUncommon	segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		GenTextGetAttrs -- 
		MSG_GEN_TEXT_GET_ATTRS for GenTextClass

DESCRIPTION:	Gets text attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_GET_ATTRS

RETURN:		al	- GenTextAttrs
		ah, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

GenTextGetAttrs	method dynamic	GenTextClass, MSG_GEN_TEXT_GET_ATTRS
	mov	al, ds:[di].GTXI_attrs
	ret
GenTextGetAttrs	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenTextSetAttrs -- 
		MSG_GEN_TEXT_SET_ATTRS for GenTextClass

DESCRIPTION:	Sets attrs.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_ATTRS
		cl	- attributes to set
		ch	- attributes to clear

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
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

GenTextSetAttrs	method dynamic	GenTextClass, \
				MSG_GEN_TEXT_SET_ATTRS
	mov	al, ds:[di].GTXI_attrs
	or	al, cl
	not	ch
	and	al, ch
	mov	cl, al
	mov	bx, offset GTXI_attrs
	GOTO	GenSetByte

GenTextSetAttrs	endm


UtilityUncommon	ends
