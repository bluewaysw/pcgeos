COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmousDriverDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

DESCRIPTION:
	

	$Id: prefmousDriverDialog.asm,v 1.1 97/04/05 01:38:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogInitiate	method	dynamic	PrefMousDriverDialogClass, 
					MSG_GEN_INTERACTION_INITIATE

		mov	ds:[di].PMDDI_onScreen, TRUE


	;
	; Set this dialog to its initial state, in case it's coming up
	; for the second time.
	;
		push	ax
		mov	ax, MSG_PREF_SET_ORIGINAL_STATE
		call	ObjCallInstanceNoLock
		pop	ax
		
		mov	di, offset PrefMousDriverDialogClass
		GOTO	ObjCallSuperNoLock
PrefMousDriverDialogInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogPreApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If any of the mouse driver paramters changed, then
		unload the mouse driver and reload it.

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogPreApply	method	dynamic	PrefMousDriverDialogClass, 
					MSG_GEN_PRE_APPLY

		tst	ds:[di].PMDDI_onScreen
		jz	done
		
	;
	; Save options now, before verifying.  If error, then
	; we'll change them back
	;
		
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock 

	;
	; Free the old driver.  If the old driver is the default, then
	; update the default as well.  Use cx as a boolean to tell
	; whether we need to update the default or not.
	;
		call	UnloadMouseDriver


	;
	; Load the new mouse driver.
	;
		call	LoadMouseDriver
		jc	errorLoading
		
		tst	bx
		jz	done

	;
	; Put up a dialog asking the user to click on a trigger to
	; test the mouse.
	;
		push	bx			; drive handle
		segmov	es, dgroup, ax
		clr	es:[mouseClicked]
		mov	si, offset TestMouseDialog
		mov	bx, ds:[LMBH_handle]
		call	UserDoDialog
		call	MemDerefDS
		pop	bx			; driver handle
		
		cmp	ax, IC_APPLY
		jne	errorUnload
		tst_clc	es:[mouseClicked]
		jz	errorUnload
done:
		ret
errorLoading:
	;
	; There was an error loading the mouse driver.  Inform the
	; user, and reset the mouse info.
	;
		CheckHack <size StandardDialogOptrParams eq 22>
		
		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	ax, ax		; SDOP_stringArg1
		mov	ax, handle Strings
		push	ax
		mov	ax, offset ErrorLoadingMouse
		push	ax		; SDOP_customString
		
		mov	ax, CustomDialogBoxFlags  <0, CDT_ERROR,
				GIT_NOTIFICATION,0>
		push	ax
		call	UserStandardDialogOptr	
resetMouse:

		mov	si, offset MouseDriverSummons
		mov	ax, MSG_GEN_RESET
		call	ObjCallInstanceNoLock

		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock

		call	LoadMouseDriver
		stc			; return error
		jmp	done

errorUnload:

	;
	; Turn the mouse cursor back off (in pen mode)
	;
		call	UnloadMouseDriver
		jmp	resetMouse
		
PrefMousDriverDialogPreApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogClickTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogClickTest	method	dynamic	PrefMousDriverDialogClass, 
					MSG_PREF_MOUS_DRIVER_DIALOG_CLICK_TEST

		tst	es:[mouseClicked]
		jz	continue
		ret
continue:
		dec	es:[mouseClicked]

		mov	ax, SST_NOTIFY		;Just a general beep
		call    UserStandardSound

		
		mov	ax, MSG_GEN_MAKE_APPLYABLE
		mov	si, offset TestMouseDialog
		GOTO	ObjCallInstanceNoLock
		
PrefMousDriverDialogClickTest	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadMouseDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the mouse driver using the category stored in the
		MouseDriverSummons object.

CALLED BY:	PrefMousDriverDialogPreApply

PASS:		ds - segment of UI objects

RETURN:		if error
			carry set
		else
			carry clear
			bx - driver handle, zero if none loaded

DESTROYED:	ax,bx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadMouseDriver	proc near

		.enter
	;
	; Get the selection from the mouse list.  If it's "No mouse",
	; then bail.
	;
		mov	si, offset MouseList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock

;Pizza has no "None" entry - brianc 7/6/94
NPZ <		mov_tr	bx, ax						>
NPZ <		tst_clc	bx						>
NPZ <		jz	done						>

		mov	si, offset MouseDriverSummons
		mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
		call	ObjVarFindData
		mov	si, bx			; ds:si - init file category
		mov	cx, MOUSE_PROTO_MAJOR
		mov	dx, MOUSE_PROTO_MINOR
		mov	ax, SP_MOUSE_DRIVERS
		call	UserLoadExtendedDriver
		jc	done
		
	;
	; We've loaded a new mouse driver.  If there's no default,
	; then make this one the default, and turn on the pointer.
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax
		jnz	done

		mov	ax, GDDT_MOUSE
		call	GeodeSetDefaultDriver

		call	ShowPointer
		clc
done:
		
		.leave
		ret

LoadMouseDriver	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnloadMouseDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the old mouse driver.  If that driver was the
		default mouse driver, then return a flag saying so

CALLED BY:	PrefMousDriverDialogPreApply, LoadNewMouseDriver

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnloadMouseDriver	proc near
		.enter

		call	GetMouseDriver
		tst	bx
		jz	done

		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver

		cmp	ax, bx
		jne	afterClearDefault

		push	bx
		mov	ax, GDDT_MOUSE
		clr	bx
		call	GeodeSetDefaultDriver
		pop	bx

	;
	; If nuking the default, hide the pointer
	;
		
		call	HidePointer

afterClearDefault:
		call	GeodeFreeDriver
done:
		.leave
		ret
UnloadMouseDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Swallow IC_INTERACTION_COMPLETE

PASS:		*ds:si	- PrefMousDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogGupInteractionCommand method dynamic \
					PrefMousDriverDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND

		cmp	cx, IC_INTERACTION_COMPLETE
		je	done

		mov	di, offset PrefMousDriverDialogClass
		GOTO	ObjCallSuperNoLock

done:
		ret
PrefMousDriverDialogGupInteractionCommand	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogApply	method	dynamic	PrefMousDriverDialogClass, 
					MSG_GEN_APPLY

		tst	ds:[di].PMDDI_onScreen
		jz	bail
		
		mov	di, offset PrefMousDriverDialogClass
		call	ObjCallSuperNoLock

	;
	; Now, send IC_INTERACTION_COMPLETE to superclass, because if
	; we send it to ourselves, we'll eat it.
	;
		
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_INTERACTION_COMPLETE
		GOTO	ObjCallSuperNoLock

bail:
		ret
PrefMousDriverDialogApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverDialogVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Signal that we're off-screen

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverDialogVisClose	method	dynamic	PrefMousDriverDialogClass, 
					MSG_VIS_CLOSE

		clr	ds:[di].PMDDI_onScreen
		mov	di, offset PrefMousDriverDialogClass
		GOTO	ObjCallSuperNoLock
PrefMousDriverDialogVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDriverSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Ensure that 'port = X' is nuked if non-serial mouse

PASS:		*ds:si	- PrefMousDriverDialogClass object
		ds:di	- PrefMousDriverDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/17/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDriverSaveOptions	method	dynamic	PrefMousDriverDialogClass, 
					MSG_META_SAVE_OPTIONS

		mov	di, offset PrefMousDriverDialogClass
		call	ObjCallSuperNoLock

		mov	si, offset MousePortList
		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjCallInstanceNoLock	; carry set if enabled	
		jc	done
	;
	; MousePortList is disable, nuke the 'port = X' entry in the
	; 'mouse' category
	;
		segmov	ds, cs, cx
		mov	si, offset mousePortCat
		mov	dx, offset mousePortKey
		call	InitFileDeleteEntry
done:
		ret
PrefMousDriverSaveOptions	endm

;sorry, we'll just hardwire these
mousePortCat	byte	'mouse',0
mousePortKey	byte	'port',0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HidePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide the mouse cursor

CALLED BY:	UnloadMouseDriver

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HidePointer	proc near
		uses	ds,si,di,ax
		.enter

		call	GetVideoDriverInfo
		mov	di, DR_VID_HIDEPTR
		call	ds:[si].DIS_strategy
		

		.leave
		ret
HidePointer	endp

ShowPointer	proc near
		uses	ds,si,di,ax
		.enter
		call	GetVideoDriverInfo
		mov	di, DR_VID_SHOWPTR
		call	ds:[si].DIS_strategy

		.leave
		ret
ShowPointer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVideoDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the DriverInfoStruct for the default video driver

CALLED BY:	HidePointer, ShowPointer

PASS:		nothing 

RETURN:		ds:si -DriverInfoStruct

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVideoDriverInfo	proc near
		uses	ax,bx
		.enter

		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
		call	GeodeInfoDriver

		.leave
		ret
GetVideoDriverInfo	endp

