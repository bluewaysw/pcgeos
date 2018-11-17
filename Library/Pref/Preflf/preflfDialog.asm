COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		preflfDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

DESCRIPTION:

	$Id: preflfDialog.asm,v 1.2 98/01/27 21:19:04 gene Exp $	



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFDialogInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine which product we're running under

PASS:		*ds:si	- PrefLFDialogClass object
		ds:di	- PrefLFDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
uiCategory	char	"ui",0
productKey	char	"productName",0
wizardName	char	"SchoolView",0
sysCategory	char	"system",0
penKey		char	"penBased",0
PrefLFDialogInit	method	dynamic	PrefLFDialogClass, 
					MSG_PREF_INIT
		uses	ax,cx,dx,bp,si,es,bx
		.enter

		clr	bx		
	;
	; See if system is pen based
	;
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	si, offset sysCategory
		mov	dx, offset penKey
		call	InitFileReadBoolean
		pop	ds
		jc	cont
		tst	ax
		jz	cont
	;
	; it is pen based so enable pen options
	;
		mov	si, offset PenWidthGroup
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

cont:	
	;
	; See if the is CGA -- if so, we'll remove the Font Size
	; and Editable Text Size categories.  They don't apply as
	; CGA uses 9 point only.
	;
		call	UserGetDisplayType
		and	ah, mask DT_DISP_SIZE
		cmp	ah, DS_TINY shl (offset DT_DISP_SIZE)
		jne	notCGA				;branch if not CGA
	;
	; Set the font stuff not usable
	;
		mov	si, offset PrefLFFontGroup
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		mov	si, offset PrefLFEditableFontGroup
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
notCGA:
	;
	; See if this is Wizard
	;

		sub	sp, size wizardName+1
		mov	di, sp
		segmov	es, ss

		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	si, offset uiCategory
		mov	dx, offset productKey
		mov	bp, size wizardName
		call	InitFileReadString
		pop	ds
		
		jc	done
		
		push	ds
		segmov	ds, cs
		mov	si, offset wizardName
		clr	cx
		call	LocalCmpStrings
		pop	ds
		
		jne	done
		
	;
	; This is wizard, so set wizard "startup" item usable
	;
							
		mov	si, offset WizardStartupItemGroup
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
	;
	; If this is wizard or pen based, change orientation
	;
		mov	si, offset PrefLFComp2
		mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
		call	ObjVarDeleteData
		mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY
		clr	cx
		call	ObjVarAddData
		
done:
		
		add	sp, size wizardName+1
		
		.leave
		mov	di, offset PrefLFDialogClass
		GOTO	ObjCallSuperNoLock
PrefLFDialogInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFDialogSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefLFDialogClass object
		ds:di	= PrefLFDialogClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFDialogSaveOptions	method	PrefLFDialogClass,
				MSG_META_SAVE_OPTIONS

	mov	di, offset PrefLFDialogClass
	call	ObjCallSuperNoLock

	mov	si, offset OverstrikeModeItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	call	UserSetOverstrikeMode
	ret
PrefLFDialogSaveOptions	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLFDialogConfirmReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If the font item group has changed, let the user know
		that state files will be nuked.

PASS:		*ds:si	- PrefLFDialogClass object
		ds:di	- PrefLFDialogClass instance data
		es	- dgroup

RETURN:		carry SET if confirmed, carry CLEAR otherwise

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/28/93   	Initial version.
        JimG	3/8/94		Added check to EditableFontItemGroup
				Fixed bug with ObjCallSuperNoLock args.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLFDialogConfirmReboot	method	dynamic	PrefLFDialogClass, 
					MSG_PREF_DIALOG_CONFIRM_REBOOT
; For NIKE this wont be used cos user can't change the font size
		mov	di, si
		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		mov	si, offset PrefLFFontItemGroup
		call	ObjCallInstanceNoLock
		jc	tellUserOfStateFileNukage
		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		mov	si, offset PrefLFEditableFontItemGroup
		call	ObjCallInstanceNoLock
		jc	tellUserOfStateFileNukage

		mov	si, di		; restore ds:si => PrefLFDialog obj
		mov	di, offset PrefLFDialogClass
		GOTO	ObjCallSuperNoLock

tellUserOfStateFileNukage:

		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	ax, ax		; SDOP_stringArg1
		mov	ax, handle fontChangeString
		push	ax
		mov	ax, offset fontChangeString
		push	ax

		mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)

		push	ax		; SDOP_customFlags

	CheckHack <size StandardDialogOptrParams eq 22>

		call	UserStandardDialogOptr

		cmp	ax, IC_NO	; clears carry if equal
		je	done
		stc
done:
		ret
PrefLFDialogConfirmReboot	endm

