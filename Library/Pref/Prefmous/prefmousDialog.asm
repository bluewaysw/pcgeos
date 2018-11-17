COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmousDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/26/93   	Initial version.

DESCRIPTION:
	

	$Id: prefmousDialog.asm,v 1.1 97/04/05 01:38:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDialogInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make inactive serial ports not enabled, set the max
		interrupt level, and determine whether we're on a
		pen-based system or not

PASS:		*ds:si	- PrefMousDialogClass object
		ds:di	- PrefMousDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
secondMouseCategory	char	"secondMouse",0

PrefMousDialogInit	method	dynamic	PrefMousDialogClass, 
					MSG_PREF_INIT

		mov	di, offset PrefMousDialogClass
		call	ObjCallSuperNoLock

	;
	; Set the max interrupt for the interrupt GenValue
	;
		
		call	SysGetConfig
		test	al, mask SCF_2ND_IC
		jz	afterInterrupts
		mov	cx, 15
		mov	si, offset MouseIntValue
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	ObjCallInstanceNoLock 

afterInterrupts:

	;
	; On a pen-based system, change the "mouse" category to
	; "secondMouse", since the [mouse] category contains the name
	; of a pen driver, and we don't want to mess with that.
	;
		call	SysGetPenMode
		tst	ax
		jz	afterPen

		mov	si, offset MouseDriverSummons
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	cx, cs
		mov	dx, offset secondMouseCategory
		call	ObjCallInstanceNoLock

afterPen:
		
		ret
PrefMousDialogInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDialogDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Close driver dialog on MSG_GEN_REMOVE and
		MSG_GEN_DESTROY_AND_FREE_BLOCK

PASS:		*ds:si	- PrefMousDialogClass object
		ds:di	- PrefMousDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       	brianc	7/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMousDialogDestroy	method	dynamic	PrefMousDialogClass, 
					MSG_GEN_REMOVE,
					MSG_GEN_DESTROY_AND_FREE_BLOCK

		push	ax, si, dx, bp
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov	si, offset MouseDriverSummons
		call	ObjCallInstanceNoLock
		pop	ax, si, dx, bp

		mov	di, offset PrefMousDialogClass
		call	ObjCallSuperNoLock
		ret
PrefMousDialogDestroy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDialogReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reload previous mouse driver

PASS:		*ds:si	- PrefMousDialogClass object
		ds:di	- PrefMousDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       	brianc	7/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMousDialogReset	method	dynamic	PrefMousDialogClass, 
					MSG_GEN_RESET

		push	si
		mov	si, offset MouseList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	si
		push	ax			; save current selection

		mov	ax, MSG_GEN_RESET
		mov	di, offset PrefMousDialogClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_RESET
		mov	si, offset MouseDriverSummons
		call	ObjCallInstanceNoLock

		mov	si, offset MouseList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; get original selection
		pop	cx
		cmp	ax, cx			; changed mouse driver?
		je	done			; nope

		;
		; unload temporararily selected driver and restore
		;  previous one
		;
		call	UnloadMouseDriver

		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock

		call	LoadMouseDriver

done:
		ret		
PrefMousDialogReset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDialogChangeDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Modify the double click time

PASS:		*ds:si	- PrefMousDialogClass object
		ds:di	- PrefMousDialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDialogChangeDoubleClick	method	dynamic	PrefMousDialogClass, 
				MSG_PREF_MOUS_DIALOG_CHANGE_DOUBLE_CLICK
	.enter
	push	cx
	call	ImInfoDoubleClick	;bx <- dbl click distance
					; Don't destroy cos needed for setting
					; dbl click time.
	pop	ax
	call	ImSetDoubleClick

	.leave
	ret
PrefMousDialogChangeDoubleClick	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousDialogChangeAccel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Change the acceleration for all mouse drivers

PASS:		*ds:si	- PrefMousDialog
		ds:di	- PrefMousDialog
		es	- dgroup
		cx	- mouse acceleration
RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMousDialogChangeAccel	method	dynamic	PrefMousDialogClass,
					MSG_PREF_MOUS_DIALOG_CHANGE_ACCEL

		call	GetMouseDriver		; bx - driver handle
		tst	bx
		jz	done
		
	;
	; Set the acceleration
	;

		call    GeodeInfoDriver         ;ds:si <- DriverInfoStruct
		push	cx			;save multiplier

		mov	di, DR_MOUSE_GET_ACCELERATION	;cx <- threshold
		call    ds:[si]. DIS_strategy

		pop	dx				;dx <- multiplier
		mov	di, DR_MOUSE_SET_ACCELERATION
		call    ds:[si]. DIS_strategy

done:
		ret

PrefMousDialogChangeAccel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMouseDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of the mouse driver

CALLED BY:	PrefMousDialogChangeAccel, PrefMousDriverialogApply

PASS:		nothing 

RETURN:		bx - mouse driver handle, or 0

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMouseDriver	proc near
		uses	ax,di,si
		.enter

	;
	; If this is a pen-based system, then look through the list of
	; geodes for a mouse driver.  Otherwise, just return the
	; default driver.
	;
		call	SysGetPenMode
		tst	ax
		jnz	findMouse

		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
done:
		.leave
		ret

findMouse:
		clr	bx
		mov	di, cs
		mov	si, offset GetMouseDriverCB
		call	GeodeForEach
		jmp	done
		
GetMouseDriver	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMouseDriverCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the mouse driver, for a pen-based
		system, where the mouse driver may be buried somewhere

CALLED BY:	GetMouseDriver via GeodeForEach

PASS:		bx - geode handle

RETURN:		if found
			carry set
			bx - handle
		else
			carry clear 

DESTROYED:	ax,cx,dx,bp,di,si,es,ds

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
mouseToken	char	"MOUS"

GetMouseDriverCB	proc far
		
		.enter
		
	;
	; Is it a driver?
	;
		mov	ax, GGIT_TYPE
		call	GeodeGetInfo
		cmp	ax, GEODE_TYPE_DRIVER
		clc
		jne	done			

	;
	; Is it a mouse driver?
	;
		sub	sp, size GeodeToken
		segmov	es, ss
		mov	di, sp
		mov	ax, GGIT_TOKEN_ID
		call	GeodeGetInfo
		segmov	ds, cs
		mov	si, offset mouseToken

		push	cx
		mov	cx, size mouseToken/2
		repe	cmpsw
		pop	cx
		
		lahf
		add	sp, size GeodeToken
		sahf

		clc
		jne	done


	;
	; Is it the default?  If so, we don't want it -- we want the
	; OTHER driver!  Note, this isn't necessary on the bullet,
	; since the bullet pen driver has a different GeodeToken, but
	; it's necessary on the PC bullet demo, which I'm using to
	; test this...
	;
		
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		cmp	ax, bx
		je	done		; carry is clear
		
		stc
done:
		.leave
		ret
GetMouseDriverCB	endp



