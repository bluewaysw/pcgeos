COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer	
MODULE:		context controller 
FILE:		ctxtcontrolControl.asm

AUTHOR:		Jonathan Magasin, Jun 15, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT CCCCustomizeUI 		Adds or Removes the tools.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/15/94   	Initial revision


DESCRIPTION:
	Code for the context controller, which just
	displays the current context for the viewer.
		

	$Id: ctxtcontrolControl.asm,v 1.1 97/04/04 17:49:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContextControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContextGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the ContextControlClass
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContextGetInfo	method dynamic ContextControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset CC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, (size GenControlBuildInfo)/(size word)
	rep movsw
CheckHack <((size GenControlBuildInfo) and 1) eq 0>
	ret
ContextGetInfo	endm


CC_dupInfo	GenControlBuildInfo	<
	mask GCBF_ALWAYS_UPDATE or \
	mask GCBF_ALWAYS_ON_GCN_LIST or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_INTERACTABLE, 	; GCBI_flags
	CC_IniFileKey,			; GCBI_initFileKey
	CC_gcnList,			; GCBI_gcnList
	length CC_gcnList,		; GCBI_gcnCount
	CC_notifyTypeList,		; GCBI_notificationList
	length CC_notifyTypeList,	; GCBI_notificationCount
	ContextControllerName,		; GCBI_controllerName

; JM:  No features for this controller.  Will they be necessary?
;      Will be same as toolbox UI, just a GenGlyph.

	0,				; GCBI_dupBlock
	0,				; GCBI_childList
	0,				; GCBI_childCount
	0,				; GCBI_featuresList
	0,				; GCBI_featuresCount
	0,				; GCBI_features

	ContextToolUI,			; GCBI_toolBlock
	CC_toolList,			; GCBI_toolList
	length CC_toolList,		; GCBI_toolCount
	CC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures


if 	_FXIP
ConviewControlInfoXIP	segment	resource
endif

CC_IniFileKey	char	"context", 0

CC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE>

CC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CONTENT_BOOK_CHANGE>


;---

CC_toolList	GenControlChildInfo	\
	<offset ContextToolTitleBar,
		mask CCTF_TITLE_BAR,
		mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CC_toolFeaturesList GenControlFeaturesInfo \
	<offset ContextToolTitleBar,
		CCTTitleBarName,
		0>

if	_FXIP
ConviewControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContextReceiveNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for MSG_META_NOTIFY_WITH_DATA_BLOCK
		Causes the context bar to be updated to display
		the new context.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= ContextControlClass object
		ds:di	= ContextControlClass instance data
		ds:bx	= ContextControlClass object (same as *ds:si)
		ax	= message #
		ss:bp - GenControlUpdateUIParams
RETURN:		whatever superclass returns (nothing)
DESTROYED:	whatever superclass destroys (ax,cx,dx,bp)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContextReceiveNotification	method dynamic ContextControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI

		cmp	ss:[bp].GCUUIP_changeType, GWNT_CONTENT_BOOK_CHANGE
		jne	done
	;
	; Get data from block.
	;
		mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle
		tst	bx
		jz	removeContextBar
		call	MemLock
		mov	es, ax
	;
	; If restoring from state, the tools will be properly enabled
	;
		test	es:[NCBC_flags], mask NCBCF_retnWithState
		jnz	noCustomize

		mov	ax, es:[NCBC_tools]		;Get BookFeatures
		call	CCCCustomizeUI

noCustomize:	
		test	es:[NCBC_tools], mask BFF_BOOK_TITLE
		jz	doneUnlock
	;
	; Update title bar.
	;
		push	bp
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	si, offset ContextToolTitleBar
		mov	bx, ds:[bx].TGCI_toolBlock	;^lbx:si=object
		mov	cx, es		
		mov	dx, offset NCBC_bookname	;cx:dx = bookname

		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bp, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
doneUnlock:
		mov	bx, ss:[bp].GCUUIP_dataBlock	;Get handle
		call	MemUnlock
done:		
		ret

removeContextBar:
		clr	ax				;no BookFeatures
		call	CCCCustomizeUI
		jmp	done
ContextReceiveNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CCCCustomizeUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds or Removes the tools.

CALLED BY:	ContextReceiveNotification
PASS:		*ds:si	- context controller
		ax - BookFeatureFlags
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	ds fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CCCCustomizeUI	proc	near
		uses	bp
		.enter

		mov	bx, ds:[LMBH_handle]
	;
	; Make CCToolFeatures from BookFeatures
	;
		clr	cx
		test	ax, mask BFF_BOOK_TITLE
		jz	haveFlags
		mov	cx, mask CCTF_TITLE_BAR

haveFlags:
		push	cx				;save tool flags
		mov	ax, MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
		call	ObjCallInstanceNoLock	
		mov_tr	cx, ax				;cx <- current tools
		pop	dx				;dx <- tools want on

		push	cx				;save for disabling
		not	cx				;cx <- tools not on
		and	cx, dx				;cx = stuff to enable

		jcxz	disableTools			;nothing to enable?
		push	dx
		mov	ax, MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
		pop	dx

disableTools:
		pop	cx				;cx <- current tools
		not	dx				;dx <- tools want off
		and	cx, dx				;cx = stuff to disable
		jcxz	done
		mov	ax, MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage

done:
		.leave
		ret
CCCCustomizeUI	endp


ContextControlCode ends
