COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Book Bindery
MODULE:		Bindery
FILE:		uiPageName.asm

AUTHOR:		Jenny Greenwood, Sep  9, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/94   	Initial revision

DESCRIPTION:
	This file contains the code for StudioLocalPageNameControlClass.

	$Id: uiPageName.asm,v 1.1 97/04/04 14:40:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocSTUFF	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioLocalPageNameControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an extra GCN list and notification type to those
		specified by our superclass.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= StudioLocalPageNameControlClass object
		ds:di	= StudioLocalPageNameControlClass instance data
		es 	= segment of StudioLocalPageNameControlClass
		ax	= message #

		cx:dx	= GenControlBuildInfo structure to fill in

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	We need to be able to enable/disable the StudioPageNameControl
	when the GrObj tool changes, which means we must add ourselves
	to another notification list beyond those chosen by our
	superclass. To do this, we get the GenControlBuildInfo
	specified by our superclass and then replace the relevant
	parts to include, not only the lists we know the superclass
	wants to be on, but also an extra GCN list and notification type.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioLocalPageNameControlGetInfo	method dynamic StudioLocalPageNameControlClass, 
					MSG_GEN_CONTROL_GET_INFO
	;
	; First call our superclass to get the current info.
	;
		pushdw	cxdx
		mov	di, offset StudioLocalPageNameControlClass
		call	ObjCallSuperNoLock
	;
	; Now modify the info.
	;
		popdw	esdi
		mov	si, offset SLPNC_newFields
		mov	cx, length SLPNC_newFields
		call	CopyNewFieldsToBuildInfo
		ret
StudioLocalPageNameControlGetInfo	endm

NewFieldEntry	struct
	NFE_offset	byte
	NFE_size	byte
	NFE_data	dword
NewFieldEntry	ends

SLPNC_newFields	NewFieldEntry \
	<offset GCBI_gcnList, size GCBI_gcnList, 
					SLPNC_gcnList>,
	<offset	GCBI_gcnCount, size GCBI_gcnCount,
					length SLPNC_gcnList>,
	<offset	GCBI_notificationList, size GCBI_notificationList,
					SLPNC_notificationList>,
	<offset	GCBI_notificationCount, size GCBI_notificationCount,
					length SLPNC_notificationList>
;
; The PageNameControl always wants to be on the text name change,
; document change, and page name change GCN lists. The
; StudioPageNameControl needs to be on the GrObj current tool change
; list as well.
;
SLPNC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_PAGE_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, 
			GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE>

SLPNC_notificationList	NotificationType \
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_DOCUMENT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_PAGE_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_CURRENT_TOOL_CHANGE>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNewFieldsToBuildInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy fields from a table of NewFieldEntry structures
		to a GenControlBuildInfo structure.

CALLED BY:	INTERNAL	StudioLocalPageNameControlGetInfo
PASS:		es:di	= GenControlBuildInfo structure.
		cs:si	= table of NewFieldEntry structures
		cx	= table length

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, bp, ds
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNewFieldsToBuildInfo	proc	near
		segmov	ds, cs
copyLoop:
	;
	; Copy field at which ds:si is pointing.
	;
		push	cx, si, di
		clr	ax
		lodsb			; ax <- offset	
		add	di, ax
		clr	ax
		lodsb
		mov_tr	cx, ax		; cx <- count
		rep	movsb
	;
	; Advance to next field and loop.
	;
		pop	cx, si, di
		add	si, size NewFieldEntry
		loop	copyLoop

		ret
CopyNewFieldsToBuildInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioLocalPageNameControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle GWNT_GROBJ_CURRENT_TOOL_CHANGE notification.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= StudioLocalPageNameControlClass object
		ds:di	= StudioLocalPageNameControlClass instance data
		ds:bx	= StudioLocalPageNameControlClass object (same as *ds:si)
		es 	= segment of StudioLocalPageNameControlClass
		ax	= message #

		ss:bp	= GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	This handler works in conjunction with the handler for 
	MSG_GEN_SET_ENABLED, found below, to disable the
	StudioPageNameControl when the text doesn't have the target.

	When the GrObj drawing tool changes not to be the text tool,
	Studio gives the target to the GrObjBody rather than the text
	object. When MSG_GEN_CONTROL_UPDATE_UI arrives here at the
	StudioPageNameControl with GWNT_GROBJ_CURRENT_TOOL_CHANGE, we
	check whether the tool is the text tool and disable ourselves if not. 

	Then we hit a snarl - GenControlNotifyWithDataBlock notices
	that we're disabled when it thinks we should be enabled, so it
	helpfully tries to enable us. In our handler for MSG_GEN_SET_ENABLED,
	we decline the favor if the text doesn't have the target.

	Note that if we don't intercept MSG_GEN_CONTROL_UPDATE_UI and
	disable ourselves here, then GenControlNotifyWithDataBlock
	will see that we're enabled, as it thinks we should be, and so
	will never try to enable us, denying us	the opportunity to
	turn up our nose. We must intercept both messages.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioLocalPageNameControlUpdateUI	method dynamic StudioLocalPageNameControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	;
	; We handle things here only if the current grobj drawing tool has
	; changed.
	;
		cmp	ss:[bp].GCUUIP_changeType,
				GWNT_GROBJ_CURRENT_TOOL_CHANGE
		je	toolChange
	;
	; Call the superclass to handle all other notifications.
	;
		mov	di, offset StudioLocalPageNameControlClass
		call	ObjCallSuperNoLock
done:
		ret

toolChange:
	;
	; Get the class of the current tool.
	;
		mov	bx, ss:[bp].GCUUIP_dataBlock
		call	MemLock
		mov	es, ax
		movdw	cxdx, es:[GONCT_toolClass]
		call	MemUnlock
	;
	; If the current tool is not the text tool, we disable ourselves.
	;
	CheckHack <FALSE eq 0>
		clr	bp			; bp <- FALSE
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, segment EditTextGuardianClass
		jne	enableDisable
		cmp	dx, offset EditTextGuardianClass
		jne	enableDisable
	;
	; Ah, it is the text tool. We revive.
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	bp, TRUE
enableDisable:
	;
	; Declare our decision and keep a record of it.
	;
		mov	ds:[di].SLPNCI_allowEnable, bp
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		jmp	done

StudioLocalPageNameControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioLocalPageNameControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the StudioPageNameControl only if it's a good idea.

CALLED BY:	MSG_GEN_SET_ENABLED
PASS:		*ds:si	= StudioLocalPageNameControlClass object
		ds:di	= StudioLocalPageNameControlClass instance data
		ds:bx	= StudioLocalPageNameControlClass object (same as *ds:si)
		es 	= segment of StudioLocalPageNameControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	See comments for StudioLocalPageNameControlUpdateUI, above.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioLocalPageNameControlSetEnabled	method dynamic StudioLocalPageNameControlClass, 
					MSG_GEN_SET_ENABLED
	;
	; We refuse to be enabled unless we've previously decided it's
	; allowable.
	;
		cmp	ds:[di].SLPNCI_allowEnable, TRUE

if not ERROR_CHECK
		jne	done
else
		je	callSuper
		cmp	ds:[di].SLPNCI_allowEnable, FALSE
		je	done
		ERROR STUDIO_PAGE_NAME_CONTROL_INSTANCE_DATA_TRASHED
callSuper:
endif

		mov	di, offset StudioLocalPageNameControlClass
		call	ObjCallSuperNoLock
done:
		ret
StudioLocalPageNameControlSetEnabled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioLocalPageNameControlSetAllowEnable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the SLPNCI_allowEnable instance data field

CALLED BY:	MSG_SLPNC_SET_ALLOW_ENABLE
PASS:		*ds:si	= StudioLocalPageNameControlClass object
		ds:di	= StudioLocalPageNameControlClass instance data
		ds:bx	= StudioLocalPageNameControlClass object (same as *ds:si)
		es 	= segment of StudioLocalPageNameControlClass
		ax	= message #

		cx	= BooleanWord

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioLocalPageNameControlSetAllowEnable	method dynamic StudioLocalPageNameControlClass, 
					MSG_SLPNC_SET_ALLOW_ENABLE

		mov	ds:[di].SLPNCI_allowEnable, cx
		ret
StudioLocalPageNameControlSetAllowEnable	endm

DocSTUFF	ends


