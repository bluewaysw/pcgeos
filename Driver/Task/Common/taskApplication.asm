COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskApplication.asm

AUTHOR:		Adam de Boor, Sep 19, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/19/91		Initial revision


DESCRIPTION:
	...
		

	$Id: taskApplication.asm,v 1.1 97/04/18 11:58:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook all existing express menu controllers and set up to
		receive notification of further changes.

CALLED BY:	MSG_META_ATTACH
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAAttach	method dynamic TaskApplicationClass, MSG_META_ATTACH
		uses	ax, cx, dx, bp, si
		.enter
		tst	ds:[di].TAI_controlBox
		jz	done
	;
	; Hook all existing express menu controllers, adding a control
	; panel, if appropriate.
	; 
		mov	di, mask MF_RECORD
		call	TACreateControlPanelCommon
		call	TASendToAllExpressMenuControllers
done:
		.leave
		mov	di, offset TaskApplicationClass
		GOTO	ObjCallSuperNoLock
TAAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TARedoTasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update all express menus to contain the current list of tasks.

CALLED BY:	MSG_TA_REDO_TASKS
PASS:		*ds:si	= TaskApplication object
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TARedoTasks	method dynamic TaskApplicationClass, MSG_TA_REDO_TASKS
		.enter

		push	si		; save TaskApplication chunk
	;
	; Mark all the current task entries for deletion. As we find tasks in
	; the new task list that match, we'll mark them appropriately.
	; 
		mov	si, ds:[di].TAI_tasks
		mov	bx, cs
		mov	di, offset TAMarkAllTasksOld
		call	ChunkArrayEnum

		call	TAFetchTasks
		
	;
	; Now match the current tasks with their corresponding entries in
	; the TAI_tasks array. Any new task is appended to the end of the
	; array when it's found to not match an existing one.
	; 
		xchg	ax, si		; *ds:si <- new task array
					; *ds:ax <- known task array

		mov	bx, cs
		mov	di, offset TAMatchTasks
		clr	bp		; first entry is #0...
		call	ChunkArrayEnum
		
		xchg	ax, si		; *ds:si <- known task array
					; *ds:ax <- TaskName array
		call	LMemFree	; all done with the TaskName array
					;  from the switcher
		
	;
	; Now delete the old task items, create the new ones, and fix up the
	; index for any items whose index has changed.
	; *ds:si	= known task array (TAI_tasks)
	; 
		pop	ax		; *ds:ax <- app obj
		mov	di, ax
		mov	di, ds:[di]
		add	di, ds:[di].TaskApplication_offset
		mov	dx, ds:[di].TAI_expressMenuControls
		clr	cx		; cx <- entry #, for deleting
					;  elements from express menu arrays
		mov	bx, cs
		mov	di, offset TAUpdateTask
		call	ChunkArrayEnum
done:
		.leave
		ret
TARedoTasks	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAMarkAllTasksOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark all the TATask entries in the TAI_tasks array as old
		and needing deletion. As each is paired with an existing
		task in the TaskName array we get back from TAFetchTasks,
		the flag we set will be cleared.

CALLED BY:	TARedoTasks via ChunkArrayEnum
PASS:		*ds:si	= TAI_tasks array
		ds:di	= TATask entry to play with
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAMarkAllTasksOld proc	far
		.enter
		mov	ds:[di].TAT_flags, mask TATF_OLD
		clc
		.leave
		ret
TAMarkAllTasksOld endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAMatchTasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first unclaimed entry in TAI_tasks that has the same
		name as the given entry from the array of tasks known to
		the switcher.

CALLED BY:	TARedoTasks via ChunkArrayEnum
PASS:		*ds:si	= TATask array from switcher
		ds:di	= current TATask to pair
		bp	= index # w/in *ds:si
		*ds:ax	= known-task array (TATask elements)
RETURN:		carry set to stop enumerating (always clear)
		bp 	= bp+1
DESTROYED:	bx, si, di all allowed
		cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAMatchTasks	proc	far
		uses	ax
		.enter
		mov	dx, di		; ds:dx <- name to check
		xchg	si, ax		; *ds:si <- TATask array
		mov	bx, cs
		mov	di, offset TACompareNames
		segmov	es, ds
		call	ChunkArrayEnum
		jc	done
	;
	; Make a new entry for this name.
	; 
		call	ChunkArrayAppend
	;
	; Copy the name & index of the task into the TATask structure. Must
	; deref the element again, however, as ChunkArrayAppend could have
	; shifted the beast.
	; 
		push	di
		mov	si, ax		; *ds:si <- switcher array
		mov	ax, bp		; ax <- elt #
		call	ChunkArrayElementToPtr
		mov	si, di		; ds:si <- source TATask
		pop	di		; es:di <- dest TATask
		
			CheckHack <(size TaskName and 1) eq 0>
			CheckHack <TAT_index eq TAT_name+size TAT_name>
			CheckHack <size TAT_index eq word>
		mov	cx, (size TaskName/2)+1
		rep	movsw
	;
	; Set the flags appropriately.
	; 
			CheckHack <TAT_flags eq TAT_index+size TAT_index>
		mov	{byte}ds:[di], mask TATF_NEW
done:
		inc	bp
		clc
		.leave
		ret
TAMatchTasks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TACompareNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the current TATask entry is still unclaimed, see if it
		has the same name as the passed TaskName and claim it if so.

CALLED BY:	TAMatchTasks via ChunkArrayEnum
PASS:		*ds:si	= TAI_tasks array
		ds:di	= TATask to check
		ds:dx	= TATask against which to compare it.
		es	= ds
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di allowed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TACompareNames	proc	far
		uses	ax
		.enter
		test	ds:[di].TAT_flags, mask TATF_OLD
		jz	done		; already taken, so keep going
		
			CheckHack <TAT_name eq 0>
		mov	si, dx		; ds:si <- source
		mov	bx, di		; save base of TAI_tasks element
					;  for later setting of flags etc.
compareLoop:
		lodsb
		scasb
		clc			; assume mismatch => keep enumerating
		jne	done

		tst	al		; end of both strings?
		jnz	compareLoop	; no -- keep comparing
	;
	; Found a match. We always need to clear TATF_OLD, but also need
	; to set TATF_CHANGED and TAT_index if the index of the string that
	; matched is different from that the entry had before...
	; 
		mov	si, dx		; ds:si <- TATask from switcher
		mov	di, ds:[si].TAT_index
		cmp	ds:[bx].TAT_index, di	; same index?
		je	doneSetFlags	; => unchanged, so leave al 0

		mov	ds:[bx].TAT_index, di	; store as new index
		mov	al, mask TATF_CHANGED	; and mark as changed
doneSetFlags:
		mov	ds:[bx].TAT_flags, al
		stc			; stop enumerating
done:
		.leave
		ret
TACompareNames	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAUpdateTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the TaskItems themselves, deleting ones that no
		longer exist, creating ones that now do, and updating the
		index for any whose index has changed.

CALLED BY:	TARedoTasks via ChunkArrayEnum
PASS:		*ds:si	= TAI_tasks array
		ds:di	= TATask entry to process
		*ds:dx	= TAI_expressMenuControls array
		cx	= entry #
		*ds:ax	= TaskApplication
RETURN:		carry set to stop enumerating (always clear)
		cx	= entry # of next entry
DESTROYED:	bx, si, di allowed
		ax, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAUpdateTask	proc	far
		uses	ax
		.enter
		mov	bx, ax		; *ds:bx = TaskApplication

		mov	al, ds:[di].TAT_flags
		test	al, mask TATF_OLD
		jnz	nukeIt
		test	al, mask TATF_NEW
		jnz	addIt
		test	al, mask TATF_CHANGED
		jnz	changeIt
doneNextTaskNum:
		inc	cx		; nothing to do, so just advance to
					;  the next task
done:
		clc
		.leave
		ret
nukeIt:
	;
	; First biff the TATask entry from the array.
	; 
		call	ChunkArrayDelete
	;
	; Now run through the express-menu array doing likewise.
	; 
		mov	si, dx		; *ds:si <- TAI_expressMenuControls
					;  array
		mov	bx, cs
		mov	di, offset TANukeTaskItem
		call	ChunkArrayEnum
		jmp	done
addIt:
	;
	; Run through the express-menu array adding an entry to each and
	; creating the silly thing.
	; 
		xchg	si, dx		; *ds:si <- TAI_expressMenuControls
					;  array
					; *ds:dx <- TAI_tasks array
		mov	ax, bx		; *ds:ax = TaskApplication

		mov	di, ds:[si]
		tst	ds:[di].CAH_count
		jz	broadcastCreate

		mov	bx, cs
		mov	di, offset TACreateTaskTrigger
		call	ChunkArrayEnum
addItDone:
		xchg	si, dx
		jmp	doneNextTaskNum

broadcastCreate:
	;
	; We know of no express-menu controllers yet, so broadcast our request
	; to create a trigger to all that might exist without our knowledge.
	;
		call	TABroadcastCreateTaskTrigger
		jmp	addItDone		

changeIt:
	;
	; Run through the express-menu array changing the index for each
	; item created for this task to match the new index.
	; 
		mov	bp, ds:[di].TAT_index
		mov	si, dx
		mov	bx, cs
		mov	di, offset TAChangeTaskTriggerIndex
		call	ChunkArrayEnum
		jmp	doneNextTaskNum
TAUpdateTask	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TANukeTaskItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the item created for the current task int this
		express menu control.

CALLED BY:	TAUpdateTask via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls array
		ds:di	= TAEMControl
		cx	= index of item to biff
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
		ax, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TANukeTaskItem	proc	far
		uses	dx, cx
		.enter
	;
	; First locate the optr within the TAEMC_tasks array for this express
	; menu control.
	;
		pushdw	ds:[di].TAEMC_emc	; save ExpressMenuControl optr
		mov_tr	ax, cx		; ax <- element # to find
		mov	si, ds:[di].TAEMC_tasks
		call	ChunkArrayElementToPtr
	;
	; Fetch the optr out...
	;
		mov	cx, ds:[di].handle
		mov	dx, ds:[di].chunk
	;
	; And delete it from the array.
	;
		call	ChunkArrayDelete
	;
	; Now send MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM to the
	; little beastie.
	;
		popdw	bxsi			; ^lbx:si = ExpressMenuControl
		mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
		mov	bp, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Keep enumerating, please.
	; 
		clc
		.leave
		ret
TANukeTaskItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TASendToAllExpressMenuControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a recorded message to all the active express menu
		controllers.

CALLED BY:	(INTERNAL) TARedoTasks, TABroadcastCreateTaskTrigger
PASS:		di	= recorded message
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TASendToAllExpressMenuControllers proc	near
		class	TaskApplicationClass
		.enter
		mov	cx, di
		clr	dx				; no extra data block
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
		clr	bp				; no cached event
		call	GCNListSend			; send to all EMCs
		.leave
		ret
TASendToAllExpressMenuControllers endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TABroadcastCreateTaskTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Broadcast a request to all existing express menus to
		create an item for us.

CALLED BY:	(INTERNAL) TAUpdateTask
PASS:		*ds:ax	= TaskApplication object
		*ds:dx	= TAI_tasks array
		cx	= index into same for new item
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TABroadcastCreateTaskTrigger proc	near
		class	TaskApplicationClass
		uses	cx, dx, si
		.enter
	;
	; Record the message to send.
	; 
		mov	di, mask MF_RECORD
		call	TACreateTaskTriggerCommon
	;
	; And send it.
	; 
		call	TASendToAllExpressMenuControllers
		.leave
		ret
TABroadcastCreateTaskTrigger endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TACreateTaskTriggerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to one or more express menu controllers
		asking them to create a trigger for a DOS task

CALLED BY:	(INTERNAL) TACreateTaskTrigger, TABroadcastCreateTaskTrigger
PASS:		di	= MessageFlags
			  if !MF_RECORD:
			  	^lbx:si	= ExpressMenuControl object to
					  which to send it.
		*ds:ax	= TaskApplication object
		cx	= index into TAI_tasks for new item
RETURN:		di	= message handle, if MF_RECORD
DESTROYED:	ax, bx, dx, bp, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TACreateTaskTriggerCommon proc	near
		class	TaskApplicationClass
		.enter
		sub	sp, size CreateExpressMenuControlItemParams
		mov	bp, sp
		mov	ss:[bp].CEMCIP_feature, CEMCIF_DOS_TASKS_LIST
		mov	ss:[bp].CEMCIP_class.segment, segment TaskTriggerClass
		mov	ss:[bp].CEMCIP_class.offset, offset TaskTriggerClass
		mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
		mov	ss:[bp].CEMCIP_responseMessage,
				MSG_TA_DOS_TASKS_LIST_ITEM_CREATED
						; send response back here
		mov	ss:[bp].CEMCIP_responseDestination.chunk, ax
		mov	ss:[bp].CEMCIP_responseData, cx
		mov	ax, ds:[LMBH_handle]
		mov	ss:[bp].CEMCIP_responseDestination.handle, ax
		movdw	ss:[bp].CEMCIP_field, 0
		mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
		mov	dx, size CreateExpressMenuControlItemParams
		ornf	di, mask MF_STACK
		test	di, mask MF_RECORD
		jnz	sendMessage
		ornf	di, mask MF_FIXUP_DS
sendMessage:
		call	ObjMessage
		add	sp, size CreateExpressMenuControlItemParams
		.leave
		ret
TACreateTaskTriggerCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TACreateTaskTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an item for the indicated task in the express menu
		control stored in this TAEMControl entry.

CALLED BY:	TAUpdateTask via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls array
		ds:di	= TAEMControl entry
		*ds:dx	= TAI_tasks array
		cx	= index of task (w/in TAI_tasks, not the switcher's
			  index for the task) for which to create an item.
		*ds:ax	= TaskApplication object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
		ax, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TACreateTaskTrigger proc	far
		uses	ax, cx, dx
		.enter
	;
	; First get the express menu control to instantiate a TaskItem object
	; for us.
	; 
		mov	bx, ds:[di].TAEMC_emc.handle
		mov	si, ds:[di].TAEMC_emc.chunk

		clr	di		; send to this controller, please
		call	TACreateTaskTriggerCommon

		clc
		.leave
		ret
TACreateTaskTrigger endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TADOSTasksListItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the creation/deletion of an express menu

CALLED BY:	MSG_TA_DOS_TASKS_LIST_ITEM_CREATED
PASS:		*ds:si	= TaskApplication object
		ss:bp = CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TADOSTasksListItemCreated method dynamic TaskApplicationClass, 
				MSG_TA_DOS_TASKS_LIST_ITEM_CREATED
again:
		push	si
		mov	si, ds:[di].TAI_expressMenuControls
		mov	dx, ds:[di].TAI_tasks
		mov	bx, cs
		mov	di, offset TADOSTasksListItemCreatedCallback
		call	ChunkArrayEnum
		pop	si
		jnc	hookMenu
		ret
hookMenu:
	;
	; Express menu not found, so create an entry for it.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskApplication_offset
		movdw	cxdx, ss:[bp].CEMCIRP_expressMenuControl
		push	si, bp
		call	TAHookExpressMenu
		pop	si, bp
	;
	; And go repeat the search.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskApplication_offset
		jmp	again
TADOSTasksListItemCreated	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TADOSTasksListItemCreatedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the creation/deletion of an express menu

CALLED BY:	TADOSTasksListItemCreated via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls array
		ds:di	= TAEMControl entry
		*ds:dx	= TAI_tasks array
		ss:bp = CreateExpressMenuControlItemResponseParams
RETURN:		carry set to stop enumeration (when EMC found)
DESTROYED:	ax, cx, dx, bp (if stopping enumeration)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TADOSTasksListItemCreatedCallback	proc	far
		mov	ax, ds:[di].TAEMC_emc.handle
		cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
		jne	noMatch
		mov	ax, ds:[di].TAEMC_emc.chunk
		cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
		jne	noMatch
	;
	; Append its optr to the TAEMC_tasks array for this express menu
	; control.
	; 
		mov	si, ds:[di].TAEMC_tasks
		call	ChunkArrayAppend
		call	ChunkArrayPtrToElement	; ax = index
		mov	bx, ss:[bp].CEMCIRP_newItem.handle
		mov	ds:[di].handle, bx
		mov	si, ss:[bp].CEMCIRP_newItem.chunk
		mov	ds:[di].chunk, si
		mov	ax, ss:[bp].CEMCIRP_data
		call	TAInitializeTaskTrigger
		stc				; stop enumeration
		jmp	done

noMatch:
		clc				; continue enumeration
done:
		ret
TADOSTasksListItemCreatedCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAInitializeTaskTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a newly-instantiated TaskTrigger object from
		an entry in an array of TATask structures

CALLED BY:	TACreateTaskTrigger
PASS:		*ds:dx	= chunkarray of TATask structures
		ax	= index of element from which to obtain name &
			  task index
		^lbx:si	= new trigger
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAInitializeTaskTrigger proc near
		.enter
	;
	; Now set up the item itself.
	; 
		xchg	si, dx		; *ds:si <- TAI_tasks
		call	ChunkArrayElementToPtr	; ds:di <- TATask
		push	ds:[di].TAT_index	; save index for setting
						;  entry index
	;
	; First set the moniker from the task name.
	;
		mov	si, dx			; ^lbx:si <- item
		mov	cx, ds
		lea	dx, ds:[di].TAT_name	; cx:dx <- string fptr
		mov	bp, VUM_MANUAL		; bp <- VisUpdateMode
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjMessage
	;
	; Set the task index.
	;
		pop	cx			; cx <- task index
		mov	ax, MSG_TT_SET_INDEX
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now set the item usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
TAInitializeTaskTrigger endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAInitializeTaskItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a newly-instantiated TaskItem object from
		an entry in an array of TATask structures

CALLED BY:	TABuildTaskList
PASS:		*ds:dx	= chunkarray of TATask structures
		ax	= index of element from which to obtain name &
			  task index
		^lbx:si	= new item
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAInitializeTaskItem proc near
		.enter
	;
	; Now set up the item itself.
	; 
		xchg	si, dx		; *ds:si <- TAI_tasks
		call	ChunkArrayElementToPtr	; ds:di <- TATask
	;
	; First set the moniker from the task name.
	; 
		mov	si, dx			; ^lbx:si <- item
		mov	cx, ds
		lea	dx, ds:[di].TAT_name	; cx:dx <- string fptr
		mov	bp, VUM_MANUAL		; bp <- VisUpdateMode
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjMessage
	;
	; Now set the item usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
TAInitializeTaskItem endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAChangeTaskTriggerIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the stored index of the TaskTrigger for the task in
		this express menu control to match the new index stored in
		the TAI_tasks table.

CALLED BY:	TAUpdateTask via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls
		ds:di	= TAEMControl
		bp	= new task index
		cx	= index of TATask within TAI_tasks array (and this
			  within the TAEMC_tasks array for this express menu
			  control)
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di all allowed
		ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAChangeTaskTriggerIndex proc	far
		uses	cx, bp
		.enter
		mov	si, ds:[di].TAEMC_tasks
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr	; ds:di <- fptr.optr

		mov	bx, ds:[di].handle
		mov	si, ds:[di].chunk	; ^lbx:si <- TaskItem
		mov	ax, MSG_TT_SET_INDEX
		mov	cx, bp			; cx <- new index
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		clc
		.leave
		ret
TAChangeTaskTriggerIndex endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TADoStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with putting up a standard dialog box from the
		TaskControl box by making sure any requested dialog
		is system-modal.

CALLED BY:	MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
PASS:		*ds:si	= TaskApplication object
		dx	= size GenAppDoDialogParams
		ss:bp	= GenAppDoDialogParams
RETURN:		cx:dx	= summons, on-screen
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TADoStandardDialog method dynamic TaskApplicationClass, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		.enter
		ornf	ss:[bp].GADDP_dialog.SDP_customFlags, 
			mask CDBF_SYSTEM_MODAL
		mov	di, offset TaskApplicationClass
		CallSuper	MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		.leave
		ret
TADoStandardDialog endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TANotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the creation/deletion of an express menu

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE
PASS:		*ds:si	= TaskApplication object
		ds:di	= TaskApplicationInstance
		^lcx:dx	= Express Menu Control
		bp	= GCNExpressMenuNotificationType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TANotifyExpressMenuChange method dynamic TaskApplicationClass, 
				MSG_NOTIFY_EXPRESS_MENU_CHANGE
		.enter
		cmp	bp, GCNEMNT_CREATED
		jne	checkDestroyed
		
	;
	; Make sure we aren't already familiar with this beast (could happen
	; if this thing is in the queue when we get our first MSG_TA_REDO_TASKS)
	; 
		push	si, di
		mov	si, ds:[di].TAI_expressMenuControls
		mov	bx, cs
		mov	di, offset TANEMC_locateController
		call	ChunkArrayEnum
		pop	si, di
		jc	done

				; ax != 0 to create items for existing
				;  tasks in new menu
		call	TAHookExpressMenu
done:
		.leave
		ret
checkDestroyed:
		cmp	bp, GCNEMNT_DESTROYED
		jne	done		; XXX: EC CODE
		
		mov	si, ds:[di].TAI_expressMenuControls
		mov	bx, cs
		mov	di, offset TALocateAndNukeEMC
		call	ChunkArrayEnum
		jmp	done
TANotifyExpressMenuChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TANEMC_locateController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this TAEMControl structure refers to the passed
		controller.

CALLED BY:	(INTERNAL) TANotifyExpressMenuChange via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls
		ds:di	= TAEMControl
		^lcx:dx	= Express Menu Control
RETURN:		carry set if TAEMControl refers to the passed EMC
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TANEMC_locateController proc	far
		.enter
		cmp	ds:[di].TAEMC_emc.handle, cx
		jne	noMatch
		cmp	ds:[di].TAEMC_emc.chunk, dx
		jne	noMatch
		stc
done:
		.leave
		ret
noMatch:
		clc
		jmp	done
TANEMC_locateController endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAHookExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook a newly-discovered express menu.

CALLED BY:	(INTERNAL) TANotifyExpressMenuChange, TADOSTasksListItemCreated
PASS:		*ds:si	= TaskApplication object
		ds:di	= TaskApplicationInstance
		^lcx:dx	= optr of ExpressMenuControl object
		ax	= non-zero to create dos-task entries in the controller
			  for all the tasks about which we know.
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bp, bx
SIDE EFFECTS:	a TAEMControl is added to the TAI_expressMenuControls array
     		chunks in the heap move around.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAHookExpressMenu proc	near
		class	TaskApplicationClass
		.enter
		push	si		; save TaskApplication chunk

		push	ax		; save create-items flag

		tst	ds:[di].TAI_controlBox
		jz	controlPanelHandled
		call	TACreateControlPanel

controlPanelHandled:
		call	TARecordEMC
	;
	; See if we should add the existing tasks to the controller.
	; 
		pop	ax
		tst	ax
		jz	popDone		; no
	;
	; Add all the known tasks to the new express menu.
	; 
		call	ChunkArrayPtrToElement
		mov	dx, si		; *ds:dx <- TAI_expressMenuControls
		mov	si, bp		; *ds:si <- TAI_tasks
		clr	cx		; cx <- index w/in TAI_tasks
		mov_tr	bp, ax		; bp <- element # w/in
					;  TAI_expressMenuControls
		mov	bx, cs
		mov	di, offset TAInitializeNewExpressMenu
		pop	ax		; *ds:ax = TaskApplication
		call	ChunkArrayEnum
done:
		.leave
		ret
popDone:
		pop	si
		jmp	done
TAHookExpressMenu endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TARecordEMC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the passed ExpressMenuControl in our array

CALLED BY:	(INTERNAL) TAHookExpressMenu, TAControlPanelItemCreated
PASS:		^lcx:dx	= ExpressMenuControl object
		*ds:si	= TaskApplication object
RETURN:		ds	= fixed up
		*ds:bp	= TAI_tasks
		ds:di	= TAEMControl for EMC
		*ds:ax	= TAEMC_tasks array
DESTROYED:	bx
SIDE EFFECTS:	things move around

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TARecordEMC	proc	near
		class	TaskApplicationClass
		.enter
	;
	; Create the chunk array to hold the tasks for this menu.
	; 
		push	cx, si
		mov	bx, size TATask
		clr	cx, si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov_tr	ax, si
		pop	cx, si
	;
	; Now append an entry to the array of EMCs.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskApplication_offset
		mov	bp, ds:[di].TAI_tasks
		mov	si, ds:[di].TAI_expressMenuControls
		call	ChunkArrayAppend
	;
	; Initialize it.
	; 
		mov	ds:[di].TAEMC_tasks, ax
		mov	ds:[di].TAEMC_emc.handle, cx
		mov	ds:[di].TAEMC_emc.chunk, dx
		.leave
		ret
TARecordEMC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TACreateControlPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GenTrigger in the control-panel section of the
		express menu that will cause us to bring up the control
		box for the switcher when it's pressed.

CALLED BY:	TANotifyExpressMenuChange
PASS:		*ds:si	= TaskApplication object
		^lcx:dx	= new express menu control
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TACreateControlPanel proc	near
		uses	cx, dx, bx, si, bp
		class	TaskApplicationClass
		.enter
		clr	di
		call	TACreateControlPanelCommon
		.leave
		ret
TACreateControlPanel endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TACreateControlPanelCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to tell one or more express menu controllers
		to create a control panel for us.

CALLED BY:	(INTERNAL) TACreateControlPanel, TARedoTasks
PASS:		*ds:si	= TaskApplication object
		di	= MessageFlags
			if !MF_RECORD:
				^lcx:dx		= express menu
RETURN:		if MF_RECORD, di = message
DESTROYED:	bx, si, cx, dx, bp, ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TACreateControlPanelCommon proc	near
		class	TaskApplicationClass
		.enter
	;
	; Now tell the express menu control to create us a GenTrigger.
	; 
		mov_tr	ax, si		; *ds:ax = TaskApplication
		movdw	bxsi, cxdx
		mov	dx, size CreateExpressMenuControlItemParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].CEMCIP_feature, CEMCIF_CONTROL_PANEL
		mov	ss:[bp].CEMCIP_class.segment, segment GenTriggerClass
		mov	ss:[bp].CEMCIP_class.offset, offset GenTriggerClass
		mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
		mov	ss:[bp].CEMCIP_responseMessage,
				MSG_TA_CONTROL_PANEL_ITEM_CREATED
		mov	ss:[bp].CEMCIP_responseDestination.chunk, ax
		mov	ax, ds:[LMBH_handle]
		mov	ss:[bp].CEMCIP_responseDestination.handle, ax
		movdw	ss:[bp].CEMCIP_field, 0		; field doesn't matter
		mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
		ornf	di, mask MF_STACK
		test	di, mask MF_RECORD
		jnz	sendMessage
		ornf	di, mask MF_FIXUP_DS
sendMessage:
		call	ObjMessage
		add	sp, size CreateExpressMenuControlItemParams
		.leave
		ret
TACreateControlPanelCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAControlPanelItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the creation/deletion of an express menu

CALLED BY:	MSG_TA_CONTROL_PANEL_ITEM_CREATED
PASS:		*ds:si	= TaskApplication object
		ss:bp = CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAControlPanelItemCreated method dynamic TaskApplicationClass, 
				MSG_TA_CONTROL_PANEL_ITEM_CREATED

again:
		push	si
		mov	dx, si
		mov	si, ds:[di].TAI_expressMenuControls
		mov	bx, cs
		mov	di, offset TAControlPanelItemCreatedCallback
		call	ChunkArrayEnum
		pop	si
		jnc	hookMenu
		ret
hookMenu:
	;
	; Express menu not found, so create an entry for it. We don't use
	; TAHookExpressMenu as that would create another control panel, and
	; either this panel was created due to a task-list entry having been
	; created, or due to our being notified of a new express menu, or
	; on META_ATTACH. In all of these cases, the task list is either already
	; initialized, or will be shortly.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskApplication_offset
		movdw	cxdx, ss:[bp].CEMCIRP_expressMenuControl
		push	si, bp
		call	TARecordEMC
		pop	si, bp
	;
	; And go repeat the search.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].TaskApplication_offset
		jmp	again
TAControlPanelItemCreated endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAControlPanelItemCreatedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if this is the express menu for which
		the control panel was created, and to initialize it if so

CALLED BY:	(INTERNAL) TAControlPanelItemCreated via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls array
		*ds:dx	= TaskApplication object
		ds:di	= TAEMControl entry
		ss:bp	= CreateExpressMenuControlItemResponseParams
RETURN:		carry set if found EMC
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAControlPanelItemCreatedCallback proc	far
		class	TaskApplicationClass
		.enter
		mov	ax, ds:[di].TAEMC_emc.handle
		cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
		jne	noMatch
		mov	ax, ds:[di].TAEMC_emc.chunk
		cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
		je	initialize
noMatch:
		clc
		jmp	done

initialize:
	;
	; Record the OD.
	; 
		movdw	bxsi, ss:[bp].CEMCIRP_newItem
		movdw	ds:[di].TAEMC_panel, bxsi

		push	dx		; save app obj chunk for setting
					;  destination of the trigger
	;
	; Locate and save the chunk of the vis moniker for the control box.
	; We'll set it as the moniker for the newly-created control-panel
	; trigger once it's newly-created...
	;
		mov	di, dx
		mov	di, ds:[di]
		add	di, ds:[di].TaskApplication_offset
		mov	di, ds:[di].TAI_controlBox

		mov	di, ds:[di]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GI_visMoniker

	;
	; Set the moniker of the trigger to that of the control box. Use
	; a far pointer so it won't die trying to lock an object block run by
	; a different thread...
	;
		mov	dx, size ReplaceVisMonikerFrame
		sub	sp, dx
		mov	bp, sp
		mov	ax, ds:[di]
		mov	ss:[bp].RVMF_source.offset, ax
		mov	ss:[bp].RVMF_source.segment, ds
		mov	ss:[bp].RVMF_sourceType, VMST_FPTR
		mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
		ChunkSizeHandle ds, di, ax
		mov	ss:[bp].RVMF_length, ax
		mov	ss:[bp].RVMF_updateMode, VUM_MANUAL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	objMessageCallFixupDSStack
		add	sp, size ReplaceVisMonikerFrame
	;
	; Set the trigger up to send us a message when it's pressed.
	; 
		mov	cx, MSG_TA_BRING_UP_CONTROL_BOX
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		call	objMessageFixupDS
		
		pop	dx			; dx = TaskApplication chunk
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		call	objMessageFixupDS
	;
	; Mark the thing as bringing up a window, since it does.
	; 
		mov	dx, size AddVarDataParams
		mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
		push	ax		; AVDP_dataType
		clr	ax
		push	ax,		; AVDP_dataSize
			ax, ax		; AVDP_data
		mov	bp, sp
			CheckHack <size AddVarDataParams eq 8>
		mov	ax, MSG_META_ADD_VAR_DATA
		call	objMessageCallFixupDSStack
		add	sp, size AddVarDataParams
	;
	; Now set the beast usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	objMessageFixupDS

		stc			; stop enumerating
done:
		.leave
		ret

objMessageFixupDS:
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		retn

objMessageCallFixupDSStack:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		retn
TAControlPanelItemCreatedCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TAInitializeNewExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an item for the new express menu

CALLED BY:	TANotifyExpressMenuChange via ChunkArrayEnum
PASS:		*ds:si	= TAI_tasks
		ds:di	= TATask
		cx	= index of same w/in TAI_tasks
		*ds:dx	= TAI_expressMenuControls
		bp	= index of new menu w/in same
		*ds:ax	= TaskApplication object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di all allowed
		ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TAInitializeNewExpressMenu proc	far
		uses	ax, cx, dx, bp
		.enter
	;
	; Call the normal routine to create an item after setting up the
	; registers as if it were being called from ChunkArrayEnum
	; 
		push	ax		; save TaskApplication chunk
		xchg	si, dx		; *ds:dx <- TAI_tasks
					; *ds:si <- TAI_expressMenuControls
		mov	ax, bp		; ax <- index of TAEMControl
		call	ChunkArrayElementToPtr	; ds:di <- TAEMControl
		pop	ax		; *ds:ax = TaskApplication
		call	TACreateTaskTrigger
		.leave
		inc	cx
		clc
		ret
TAInitializeNewExpressMenu endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TALocateAndNukeEMC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the entry for an express menu control and biff it, as
		it is going away.

CALLED BY:	TANotifyExpressMenuChange via ChunkArrayEnum
PASS:		*ds:si	= TAI_expressMenuControls
		ds:di	= TAEMControl to check
		^lcx:dx	= express menu contorl who dieth.
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di all allowed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TALocateAndNukeEMC proc	far
		.enter
		cmp	ds:[di].TAEMC_emc.handle, cx
		jne	continue
		cmp	ds:[di].TAEMC_emc.chunk, dx
		je	biffIt
continue:
		clc
done:
		.leave
		ret
biffIt:
	;
	; The items will take care of themselves, so we need only biff the
	; ChunkArray that pointed to them.
	; 
		mov	ax, ds:[di].TAEMC_tasks
		call	LMemFree
	;
	; Now delete this element from the array.
	; 
		call	ChunkArrayDelete
		stc			; stop enumerating -- mission
					;  accomplished.
		jmp	done
TALocateAndNukeEMC endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TABringUpControlBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the driver's control panel up onto the screen.

CALLED BY:	MSG_TA_BRING_UP_CONTROL_BOX
PASS:		*ds:si	= TaskApplication object
		ds:di	= TaskApplicationInstance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TABringUpControlBox method dynamic TaskApplicationClass, MSG_TA_BRING_UP_CONTROL_BOX
		.enter
		mov	si, ds:[di].TAI_controlBox
EC <		tst	si						>
EC <		ERROR_Z	CANNOT_BRING_UP_NONEXISTENT_CONTROL_BOX		>
   		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		.leave
		ret
TABringUpControlBox endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TABuildTaskList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a GenItemGroup with entries representing the
		known tasks, excluding our own.

CALLED BY:	MSG_TA_BUILD_TASK_LIST
PASS:		*ds:si	= TaskApplication object
		^lcx:dx	= GenItemGroup to which to add the new items
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TABuildTaskList	method dynamic TaskApplicationClass, MSG_TA_BUILD_TASK_LIST
		.enter
	;
	; Fetch the array of known tasks.
	; 
		call	TAFetchTasks
	;
	; Now enumerate over that array to create items for each.
	; 
		mov_tr	si, ax
		mov	bx, cs
		mov	di, offset TABTL_callback
		call	ChunkArrayEnum
	;
	; Biff the array, as we're done with it.
	; 
		mov_tr	ax, si
		call	LMemFree
		.leave
		ret
TABuildTaskList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TABTL_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a TaskItem object for the current entry in the array.

CALLED BY:	TABuildTaskList via ChunkArrayEnum
PASS:		*ds:si	= task array
		ds:di	= TATask structure
		^lcx:dx	= GenItemGroup to which to add an entry.
RETURN:		nothing
DESTROYED:	bx, si, di, es all allowed
		ax, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TABTL_callback	proc	far
		uses	cx, dx
		.enter
	;
	; Figure out the element number within the array, so we can pass it
	; to TAInitializeTaskItem.
	; 
		call	ChunkArrayPtrToElement
	;
	; Save the array, index into it, and task index for later use.
	; 
		push	si, ax, ds:[di].TAT_index
	;
	; Create the object within the same block as the GenItemGroup
	; 
		segmov	es, <segment TaskItemClass>, di
		mov	di, offset TaskItemClass
		mov	bx, cx
		call	ObjInstantiate
	;
	; Set the identifier for the item before we add it to the GenItemGroup.
	; Its identifier is, naturally enough, its task index.
	; 
		pop	cx
		mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now add it as the last generic child of the group. Mark the links
	; dirty, just in case.
	; 
		mov	cx, bx
		xchg	dx, si
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now set the item's IGNORE_DIRTY flag to match that of its containing
	; group, so it doesn't get left behind when the thing goes to state (if
	; the group is ignore-dirty, but the item isn't), nor does the linkage
	; end up corrupt (if the group isn't ignore-dirty but the item is).
	; 
		mov	cx, si			; cx <- chunk whose flags are
						;  desired
		mov	ax, MSG_META_GET_FLAGS
		push	dx			; save item chunk, j.i.c.
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; al <- flags

		pop	si			; ^lbx:si <- item
		mov	cx, si			; cx <- chunk whose flags are
						;  to be altered
		mov_tr	dx, ax			; dl <- bits to set (dh <- 0)
		andnf	dl, mask OCF_IGNORE_DIRTY
		mov	dh, dl
		xornf	dh, mask OCF_IGNORE_DIRTY
		mov	ax, MSG_META_SET_FLAGS
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now perform the rest of the intialization required for the item.
	; 
		pop	dx, ax			; *ds:dx <- TATask array
						; ax <- index of TATask within
						;  it.
		call	TAInitializeTaskItem
		.leave
		ret
TABTL_callback	endp

Movable	ends
