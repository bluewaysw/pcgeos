## 2.7 Routines V-Z

----------
#### VisCompInitialize
This routine initializes a VisComp object. This does parent class 
initialization first, followed by an initialization of the VisComp part. It 
initializes the composite linkage and marks the visible object as a composite.

**Pass:**  
*ds:si - Instance data.  
es - Segment of VisCompClass.  
ax, bx - Ignored (ergo, may safely be called using **CallMod**).

**Returns:**  
Nothing.

**Destroyed:**  
ax, bx, cx, dx, bp, si, di, ds, es.

**Library:** vCompC.def

----------
#### VisCompMakePressesInk
This routine is a handler for subclasses of VisCompClass that wish to make 
presses that are not on a child to be ink.

**Pass:**  
*ds:si - Instance data.  
es - Segment of VisCompClass.  
ax - MSG_META_QUERY_IF_PRESS_IS_INK.  
cx, dx - Press position.

**Returns:**  
bp - As returned by child object, if press was over a child object. 
Zero if press not over child object.  
ax - **InkReturnValue**.

**Destroyed:**  
Nothing.

**Library:** vCompC.def

----------
#### VisCompMakePressesNotInk
This routine is a handler for subclasses of VisCompClass that wish to make 
presses that are not on a child to be normal (i.e., not ink).

**Pass:**  
*ds:si - Instance data.  
es - Segment of VisCompClass.  
ax - MSG_META_QUERY_IF_PRESS_IS_INK.  
cx, dx - Press position.

**Returns:**  
bp - As returned by child object, if press was over a child object. 
Zero if press not over child object.  
ax - **InkReturnValue**.

**Destroyed:**  
Nothing.

**Library:** vCompC.def

----------
#### VisInitialize
This routine initializes the VisInstance part of a visual object's instance data. 
This includes setting the size of the object to zero (bounds being (0, 0) to 
(-1, -1)) and marking the object invalid in all ways (image, window, and 
geometry).

**Pass:**  
*ds:si - Instance data.  
es - Segment of VisClass.  
ax, bx - Ignored (ergo, this routine may be called using **CallMod**).

**Returns:**  
si - Intact.

**Destroyed:**  
ax, cx, dx, bp.

**Library:** visC.def

----------
#### VisObjectHandlesInkReply
This is a message handler to be used by those objects that want ink.

**Pass:**  
ss:bp - **VisCallChildrenInBoundsFrame** structure.

**Pass on stack:**  
**VisCallChildrenInBoundsFrame** structure.

**Returns:**  
Nothing.

**Destroyed:**  
ax, cx, di.

**Library:** visC.def

----------
#### VisTextGraphicCompressGraphic
This routine compresses the bitmaps in a VisTextGraphic.

**Pass:**  
All arguments passed on the stack.

**Pass on stack:**  
**VisTextGraphicCompressParams** structure.

**Returns:**  
dx:ax - **VMChain** of GString in destination file.

**Destroyed:**  
Nothing

**Library:** vTextC.def

----------
#### VMAlloc
Creates and allocates space for a VM block within a previously existing VM 
file. The block will not be initialized.

Before you use this block, make sure to lock it down with **VMLock**.

**Pass:**  
bx - VM file handle.  
ax - User ID. This can be any word-length data that the 
application wishes to associate with the VM block. (This ID 
can be used with **VMFind**.)  
cx - Number of bytes to allocate for the block. This may be 0, in 
which case no associated memory will be assigned to the 
block.

**Returns:**  
ax - VM block handle, marked dirty if memory is allocated within 
the block.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMAllocLMem
Allocates a VM block and initializes it to contain a local memory heap. If you 
want a fixed data header space, you must pass the total size to allocate 
(including the **LMemBlockHeader**; otherwise, pass zero indicating that 
only enough space for an **LMemBlockHeader** will be allocated in the local 
memory block header.

You do not need to specify a block size, since the heap will automatically 
expand itself.

**Pass:**  
ax - Type of LMem heap to create (**LMemType**).  
bx - VM file handle.  
cx - Size of block handle (or 0 for default).

**Returns:**  
ax - VM block handle.

**Destroyed:**  
Destroyed.

**Library:** vm.def

----------
#### VMAttach
Attaches an existing block of memory to a VM block, deleting whatever data 
was stored there before.

**Pass:**  
bx - VM file handle.  
ax - VM block handle (or 0 to allocate a new VM block). Any data 
previously associated with that block will be lost.  
cx - Handle of global memory block to attach.

**Returns:**  
ax - VM block.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMCheckForModifications
Checks whether a VM file has been marked as modified.

**Pass:**  
bx - VM file handle.

**Returns:**  
CF - Set if file is modified.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMClose
Closes a VM file. This routine updates all dirty blocks, frees all global memory 
blocks attached to the file and closes the file.

Make sure to update the file before closing it. If **VMClose** encounters an 
error when closing the file, it will still close the file and free its memory 
anyway.

**Pass:**  
al - FILE_NO_ERRORS or 0.  
bx - VM file handle.

**Returns:**  
CF - Set on error.  
ax - **VMStatus** (which may possibly be an error code).

**Destroyed:**  
bx (if file was actually closed).

**Library:** vm.def

----------
#### VMCompareVMChains
Compares two VM chains or DB items.

**Pass:**  
bx - VM file handle #1.  
ax:bp - VM chain #1.  
dx - VM file handle #2.  
cx:di - VM chain #2.

**Returns:**  
CF - Set if the VM chains are equal.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMCopyVMBlock
Creates a duplicate of a VM block into the specified destination file. This 
destination file may be the same as the source file. The duplicate VM block 
user ID will remain the same as the original block's user.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.  
dx - Destination file handle.

**Returns:**  
ax - New block handle.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMCopyVMChain
Creates a duplicate of a VM chain (or DB item) in the specified destination 
file. This destination file may be the same as the source file. All blocks in the 
duplicate will have the same user ID number.

**Pass:**  
bx - Source file.  
ax:bp - Source VM chain. (If this is a DB item, **bp** will contain the 
item number, otherwise it will be zero.)  
dx - Destination file.

**Returns:**  
ax:bp - Destination VM chain (or DB item) created.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMDetach
Detaches a VM block from a VM file, returning the handle of the detached 
global memory block (which may have been allocated). The VM block will 
contain no data after the detach.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.  
cx - Owner of memory handle (0 for the current thread's geode).

**Returns:**  
di - Handle of global memory block.

**Destroyed:**  
ax

**Library:** vm.def

----------
#### VMDirty
Marks a locked VM block as dirty.

**Pass:**  
bp - Locked VM memory handle containing the VM block.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMFind
Given a VM block's user ID, locates and returns the first VM block handle 
whose user ID matches.

**Pass:**  
bx - VM file handle.  
ax - User ID.  
cx - 0 to find the first block with the given ID; otherwise, a VM 
block handle to find the *next* block with the given ID.

**Returns:**  
CF - Clear if found, set otherwise.  
ax - VM block handle if found, else **ax** = 0.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMFree
Frees a VM block handle. If a global memory block is attached to the VM 
block, that is freed also.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMFreeVMChain
Frees a VM chain (or DB item). If freeing a VM chain, all blocks in the chain 
will be freed.

**Pass:**  
bx - VM file handle.  
ax:bp - VM chain.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMGetAttributes
Returns the **VMAttributes** associated with the specified VM file.

**Pass:**  
bx - VM file handle.

**Returns:**  
al - **VMAttributes**.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMGetDirtyState
Returns the dirty state of a VM file, in a word-length value that specifies both 
if the file has been dirtied since the last save and whether it has been dirtied 
since the last save, auto-save, or update.

**Pass:**  
bx - VM file handle.

**Returns:**  
al - Non-zero if the file has been marked dirty since the last save.  
ah - Non-zero if the file has been marked dirty since the last save, 
auto-save, or update.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMGetMapBlock
Returns the VM block handle of the VM file's map block.

**Pass:**  
bx - VM file handle.

**Returns:**  
ax - VM block handle of map block (or 0 if there is none).

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMGrabExclusive
Provides the current thread with exclusive access to the VM file.

**Pass:**  
bx - VM file handle.  
ax - **VMOperation** for the operation to be performed.  
cx - Timeout value in increments of 1/10th of a second. Pass zero 
to wait for as long as it takes.

**Returns:**  
ax - **VMStartExclusiveReturnValue**

cx - existing **VMOperation** (if the routine was timed out).

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMInfo
Fetches information about a VM block. Returns the memory handle, block 
size, and user ID of the specified VM block.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.

**Returns:**  
CF - Clear if block handle is valid.  
 - Set if block handle is free, out of range, or otherwise illegal. 
No other registers will be altered if this is the case.  
cx - Size of block. (This size is not a guarantee that the block will 
remain the same size after this routine returns. It must be 
locked with VMLock to ensure this.)  
ax - Associated memory handle, if any (or 0 if none).  
di - User ID of the block.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMLock
Locks the given VM block into the global memory heap.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.

**Returns:**  
ax - Segment of locked VM block.  
bp - Memory handle of locked VM block.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMMemBlockToVMBlock
Returns the VM block and VM file associated with a given VM memory 
handle.

**Pass:**  
bx - VM memory handle.

**Returns:**  
ax - VM block handle.  
bx - VM file handle.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMModifyUserID
Changes the user ID of the passed VM block.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.  
cx - New user ID.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMOpen
Opens (or creates) a VM file, returning the handle of the opened file. 
**VMOpen** looks for the file in the thread's current working directory (unless 
creating a temporary file). 

**Pass:**  
ah - **VMOpenType**.  
al - **VMAccessFlags**.  
cx - Compression threshold percentage passed as an integer. 
(Pass zero to use the system default.)  
ds:dx - Pointer to file name to open (null-terminated text string).

**Returns:**  
CF - Set on error.  
ax - **VMStatus**.  
bx - VM file handle.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMPreserveBlocksHandle
Keeps the same global memory block with this VM block until the block is 
explicitly detached or the VM block is freed.

**Pass:**  
bx - VM file handle.  
ax - VM block handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMReleaseExclusive
Relinquishes a thread's exclusive access to a VM file.

**Pass:**  
bx - VM file handle (or override).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMRevert
Reverts a file to its last-saved state.

**Pass:**  
bx - VM file handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMSave
Updates and saves a VM file, freeing all backup blocks.

**Pass:**  
bx - VM file handle.

**Returns:**  
CF - Set on error.  
ax - (If CF is set) error code.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMSaveAs
Saves a VM file under a new name. The old file is reverted to its last-saved 
state.

**Pass:**  
ah - **VMOpenType**.  
al - **VMAccessFlags**.  
bx - VM file handle.  
cx - Compression threshold percentage passed as an integer. 
(Pass zero to use the system default.)  
ds:dx - Pointer to new file name (null-terminated string).

**Returns:**  
CF - Set on error.  
bx - Handle for new file.  
ax - **VMStatus**.

**Destroyed:**  
cx, dx

**Library:** vm.def

----------
#### VMSetAttributes
Changes a VM file's **VMAttributes** settings, also returning the new 
attributes in a word-length record.

**Pass:**  
bx - VM file handle.  
al - Bits in **VMAttributes** record to set.  
ah - Bits in **VMAttributes** to clear.

**Returns:**  
al - New **VMAttributes**.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMSetExecThread
Sets the thread that will execute methods of all objects within the passed VM 
file.

**Pass:**  
bx - VM file handle.  
ax - Thread handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMSetMapBlock
Sets the map block of a VM file.

**Pass:**  
bx - VM file handle.  
ax - VM block handle of map block.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMSetReloc
Sets the (fixed-memory) data relocation routine to be called whenever a block 
is brought into memory from a VM file (or written to memory).

**Pass:**  
bx - VM file handle.  
cx:dx - Address of routine to call.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ax - Memory handle.  
bx - VM file handle.  
di - Block handle of loaded block.  
dx - Segment address of block.  
cx - **VMRelocType**.  
bp - User ID of block.  
**Return:**  
Block relocated/unrelocated.  
**May Destroy:**  
ax, bx, cx, dx, si, di, bp, ds, es

**Library:** vm.def

----------
#### VMUnlock
Unlocks a locked VM block. Note that the block's global memory handle is 
passed (not it's VM handle).

**Pass:**  
bp - Memory handle of locked VM block.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing except, possibly **ds** and **es** if error-checking.  
(If segment error-checking is on, and either **ds** or **es** is 
pointing to a block that has become unlocked, then that 
register will be set to NULL_SEGMENT upon return from this 
procedure.)

**Library:** vm.def

----------
#### VMUpdate
Updates all dirty blocks within a VM file to the disk. (This is known as 
flushing all changes onto disk.)

**Pass:**  
bx - VM file handle.

**Returns:**  
CF - Clear if successful, set otherwise.  
ax - (If CF is set): error code.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VMVMBlockToMemBlock
Returns the handle of the global memory block attached to a specified VM 
block. If no global block is currently attached, it will allocate and attach one.

**Pass:**  
bx - VM file handle (or override).  
ax - VM block handle.

**Returns:**  
ax - Global memory block handle.

**Destroyed:**  
Nothing.

**Library:** vm.def

----------
#### VTFClearSmartQuotes
Clear the variable that prohibits smart quotes.

**Pass:**  
*ds:si - Instance data of a VisText object (or subclass).   

**Returns:**  
Nothing

**Destroyed:**  
Nothing

**Library:** vTextC.def

----------
#### WarningNotice
A place for Swat to place a breakpoint to catch taken invocations of the 
WARNING family of macros

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### WinAckUpdate
Acknowledges an update in the window without performing any visual 
updating. This is equivalent to calling **GrBeginUpdate**, then 
**GrEndUpdate** but does not require a GState to do so. 

This routine should be used when responding to a MSG_META_EXPOSED 
when the application does not wish to perform any update drawing.

**Pass:**  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinApplyRotation
Applies the passed rotation to the window's transformation matrix.

**Pass:**  
di - **WindowHandle** or GState handle.  
dx.ax - Angle to rotate (as a **WWFixed** value).  
si - **WinInvalFlag**.  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
CF - Set if **di** is a gstate or a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinApplyScale
Applies the passed scale factor to the window's transformation matrix.

**Pass:**  
di - **WindowHandle**.  
dx.cx - X-scale factor (**WWFixed** value).  
bx.ax - Y-scale factor (**WWFixed** value).  
si - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
CF - Set if **di** is a gstate or a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinApplyTransform
Concatenates the passed transformation matrix (**TMatrix**) with the 
window's current transformation matrix, forming the window's new 
transformation matrix.

**Pass:**  
di - **WindowHandle**.  
ds:si - Pointer to new **TMatrix** to use.  
cx - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
Nothing.

**Destroyed:**  
ax, bx

**Library:** win.def

----------
#### WinApplyTranslation
Applies the passed translation to the window's transformation matrix.

**Pass:**  
di - **WindowHandle**.  
dx.cx - X translation to apply (**WWFixed** value).  
bx.ax - Y translation to apply (**WWFixed** value).  
si - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
CF - Set if **di** is a gstate or a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinApplyTranslationDWord
Applies a 32-bit translation to a window's transformation matrix.

**Pass:**  
di - **WindowHandle**.  
dx.cx - X translation to apply (32-bit integer).  
bx.ax - Y translation to apply (32-bit integer).  
si - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
CF - Set if **di** is a gstate or a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinChangeAck
Called to acknowledge a MSG_META_WIN_CHANGE, this function generates 
"Enter" and "Leave" events for any windows which the mouse may have 
moved across. 

**Pass:**  
cx, dx - Screen location to traverse to.  
bp - Window handle of tree to traverse to.  

**Returns:**  
cx:dx - Enter/leave Output Descriptor for that window (zero if none).  
bp - Handle of window that mouse pointer is in.

**Destroyed:**  
Nothing.

**Library:** win.def

**Warning:**  
This routine may resize LMem and/or object blocks, moving then on the heap 
and invalidating stored segment pointers and current register or stored 
offsets to them.

----------
#### WinChangePriority
Changes a window's priority.

**Pass:**  
ax - **WinPassFlags**.  
dx - Layer ID.  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinClose
Closes and frees the specified window.

**Pass:**  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
di

**Library:** win.def

----------
#### WinDecRefCount
Handle acknowledge of window death. To be called by whoever receives a 
MSG_META_WIN_DEC_REF_COUNT.

**Pass:**  
di - Window handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinEnsureChangeNotification
Ensures that if the window that has the implied mouse grab has changed 
since the last MSG_META_WIN_CHANGE, then another 
MSG_META_WIN_CHANGE will be sent out to update the system.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeGetFlags
Returns the **GeodeWinFlags** associated with a geode.

**Pass:**  
bx - Geode handle.

**Returns:**  
ax - **GeodeWinFlags**.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeGetInputObj
Returns the optr of the input object associated with the specified geode. (If 
there is no such object, this routine returns a null optr.)

**Pass:**  
bx - Geode handle.

**Returns:**  
cx:dx - Optr of Input object (or 0 if none).

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeGetParentObj
Returns the optr of the parent object associated with the passed geode. (If 
there is no such parent object, this routine returns a null optr.)

**Pass:**  
bx - Geode handle.

**Returns:**  
cx:dx - Parent object (or 0 if none).

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeSetActiveWin
Sets the passed window within the specified geode to be that geode's "active" 
window.

**Pass:**  
bx - Geode handle.  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeSetFlags
Sets the GeodeWinFlags associated with the specified geode.

**Pass:**  
bx - Geode handle.  
ax - **GeodeWinFlags**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeSetInputObj
Sets the passed geode's input object to the specified optr.

**Pass:**  
bx - Geode handle.  
cx:dx - Input object (or 0 to set it to none).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeSetParentObj
Sets the passed geode's parent object to the specified optr.

**Pass:**  
bx - Geode handle.  
cx:dx - Parent object (or 0 to set it to none).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGeodeSetPtrImage
Sets the pointer image of the specified geode to the passed **PointerDef**.

**Pass:**  
cx:dx - Optr of **PointerDef** image in sharable memory block. (If **cx** = 
0, **dx** = PtrImageValue.)  
bx - Geode handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGetInfo
Returns information (including any private data) associated with a window.

**Pass:**  
di - **WindowHandle**.  
si - **WinInfoType**.

**Returns:**  
CF - Set if **di** is a gstate or is a window that is closing.  
Otherwise (based on passed si value):  
WIT_PRIVATE_DATA  
 - ax, bx, cx, dx - Private data.  
WIT_COLOR  
 - al - Color index (or red value for RGB).  
 - ah - WCF_TRANSPARENT if none, WIN_RGB if
RGB colors. 
Low bits store the color map mode.  
WIT_INPUT_OBJ  
 - cx:dx - Optr of input object.  
WIT_EXPOSURE_OBJ  
 - cx:dx - Optr of exposure object.  
WIT_STRATEGY  
 - cx:dx - Address of strategy routine.  
WIT_FLAGS  
 - al - **WinRegFlags**.  
 - ah - **WinPtrFlags**.  
WIT_LAYER_ID  
 - ax - Layer ID.  
WIT_PARENT_WIN  
WIT_FIRST_CHILD_WIN  
WIT_LAST_CHILD_WIN  
WIT_PREV_SIBLING_WIN  
WIT_NEXT_SIBLING_WIN  
 - ax - Appropriate window link.  
WIT_PRIORITY  
 - al - WinPriorityData.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGetTransform
Returns the transformation matrix of the specified window.

**Pass:**  
di - **WindowHandle**.  
ds:si - Pointer to buffer to hold **TMatrix**. (There should be room for 
6 **WWFixed** arguments.)

**Returns:**  
Buffer at **ds:si** filled in the following order:  
Original Matrix:  
[e11 e12 0]  
[e21 e22 0]  
[e31 e32 1]  
Order of returned array:  
[e11 e12 e21 e22 e31 e32] 

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGetWinScreenBounds
Returns the bounds of the on-screen portion of the specified window.

**Pass:**  
di - **WindowHandle**.

**Returns:**  
CF - Set if **di** is a gstate or is a window that is closing.  
ax - Left position of window.  
bx - Top position of window.  
cx - Right position of window.  
dx - Bottom position of window.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinGrabChange
Allows an object to grab pointer events for windows within the system.

**Pass:**  
bx:si - Object to send change events to.

**Returns:**  
INTs ON  
CF - Set if grabbed, clear if grab is unsuccessful.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinInvalReg
Invalidates a portion of the specified window, indicated by the passed region 
(or rectangle).

**Pass:**  
ax, bx, cx, dx - Parameters for region. (Bounds if a rectangular region.) 
These coordinates must be WINDOW coordinates.  
bp:si - Region. (Zero if rectangular.)  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinLocatePoint
Searches through a window tree, returning the window in which the passed 
point lies within, along with other information about the window.

**Pass:**  
di - **WindowHandle** of window to start search at.  
cx - X screen position.  
dx - Y screen position.

**Returns:**  
di - **WindowHandle** of window containing the passed point (or 
NULL_WINDOW).  
bx:si - Optr associated with window.  
cx - Horizontal (X) absolute position of window.  
dx - Vertical (Y) absolute position of window.

**Destroyed:**  
ax, bx, cx, dx

**Library:** win.def

----------
#### WinMove
Moves a window, either relative to its current position or in an absolute 
manner (relative to the parent).

**Pass:**  
ax - Horizontal units to move window.  
bx - Vertical units to move window.  
si - **WinPassFlags**. (WPF_ABS is set if this move is an absolute 
position, clear if this is a relative move.)  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinOpen
Allocates and initializes a window and (optionally) its associated GState.

The region/rectangle passed is expressed in units relative to the parent's 
window. (I.e. the width of a rectangle should be *right* - *left* + 1.)

**Pass:**  
al - Color index (or red value if using RGB).  
ah - **WinColorFlags**.  
bl - Green value (if using RGB values).  
bh - Blue value (if using RGB values).  
cx:dx - Optr of input object (object responsible for handling mouse 
input for this window). This object must be run by the same 
thread as the owning geode's input object.  
di:bp - Optr of exposure object.  
si - **WinPassFlags**.

**Pass on stack:**  
word - Layer ID.  
word - Geode which should own this window. Pass zero for the 
current running geode.  
word - **WindowHandle** of parent (or handle of the video driver if 
there is no parent).  
word - High word of region (0 for rectangular window).  
word - Low word of region (0 for rectangular window).  
word - PARAM_3 for region (bottom if rectangular).  
word - PARAM_2 for region (right if rectangular).  
word - PARAM_1 for region (top if rectangular).  
word - PARAM_0 for region (left if rectangular).

**Returns:**  
bx - Handle to allocated and opened window.  
di - Handle to allocated and opened GState (if any).

**Destroyed:**  
ax, cx, dx, si, bp

**Library:** win.def

----------
#### WinRealizePalette
Realize the palette for this window in hardware.

**Pass:**  
di - **WindowHandle** of window.    

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinReleaseChange
Releases an object from being notified of window changes.

**Pass:**  
bx:si - Object to release change notification.

**Returns:**  
 - INTs ON.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinResize
Resizes a window. It is also possible to move it at the same time.

**Pass:**  
ax, bx, cx, dx - Parameters of the region (or bounds if the region is instead a 
rectangle).  
bp:si - Region (or 0 for a rectangle).  
di - **WindowHandle**.

**Pass on stack:**  
**WinPassFlags** (with mask WPF_ABS to perform an absolute resize/move).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinScroll
Scrolls a document within a window by the passed values. Actual 
displacement values may be different than the passed values due to rounding 
and optimizations.

This routine will not work for rotated windows.

**Pass:**  
di - **WindowHandle**  
dx.cx - Horizontal displacement (**WWFixed** value).  
bx.ax - Vertical displacement (**WWFixed** value).

**Returns:**  
dx.cx - Actual horizontal displacement applied.  
bx.ax - Actual vertical displacement applied.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSetInfo
Sets information within a window. Passed register arguments depend on the 
**WinInfoType** passed in **si**.

**Pass:**  
di - **WindowHandle**.  
si - **WinInfoType**.  
WIT_PRIVATE_DATA  
 - ax, bx, cx, dx - Private data.  
WIT_COLOR  
 - al - Color index (or red value for RGB).  
 - ah - WCF_TRANSPARENT if none, WIN_RGB if 
RGB colors. 
Low bits store the color map mode.  
WIT_INPUT_OBJ  
 - cx:dx - New optr of input object.  
WIT_EXPOSURE_OBJ  
 - cx:dx - New optr of exposure object.  
WIT_STRATEGY  
 - cx:dx - Address of strategy routine.

**Returns:**  
CF  Set if di is a GState or references a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSetNullTransform
Replaces a window's transformation matrix with a null (identity) 
transformation.

**Pass:**  
di - **WindowHandle**.  
cx - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSetPtrImage
Sets the pointer image within the range of the passed window.

**Pass:**  
bp - PIL_GADGET or PIL_WINDOW.  
cx:dx - Optr to **PointerDef** in sharable memory block. (If **cx** = 0, **dx** 
= **PtrImageValue**.)  
di - WindowHandle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSetTransform
Sets the transformation matrix of a window. Any previous transformation 
matrix is lost.

**Pass:**  
di - **WindowHandle**.  
ds:si - Pointer to new **TMatrix**.  
cx - **WinInvalFlag**  
 - (WIF_INVALIDATE to invalidate the window.  
 - WIF_DONT_INVALIDATE to avoid invalidating the window.)

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSuspendUpdate

Suspends the sending of update messages to the window. If an update is 
already in progress, it will be allowed to continue and suspend behavior will 
commence afterward.

**Pass:**  
di - WindowHandle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinSysSetActiveGeode
Sets the passed geode to be the system's "active" geode.

**Pass:**  
bx - Geode handle to make active (0 sets none active).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinTransform
Translates the passed document coordinates into screen coordinates, 
ignoring the effect of any transformation in the associated GState.

**Pass:**  
ax - X coordinate (in document coordinates).  
bx - Y coordinate (in document coordinates).  
di - **WindowHandle**.

**Returns:**  
CF - Set on error.

ax - On success, *x* screen coordinate; on error, an error code.

bx - On success, *y* screen coordinate; destroyed on error.

**Destroyed:**  
Nothing (except possibly **bx**, see above).

**Library:** win.def

----------
#### WinTransformDWord
Translates the passed 32-bit document coordinates into 32-bit screen 
coordinates.

**Pass:**  
dx.cx - *x* document coordinate (32-bit integer).  
bx.ax - *y* document coordinate (32-bit integer).  
di - **WindowHandle**.

**Returns:**  
dx.cx - *x* screen coordinate (32-bit integer).  
bx.ax - *y* screen coordinate (32-bit integer).  
CF - Set if **di** is a gstate or a window that is closing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinUnSuspendUpdate
Cancels any previous **WinSuspendUpdate** call, allowing update drawing to 
the window.

**Pass:**  
di - **WindowHandle**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** win.def

----------
#### WinUntransform
Translates a coordinate pair from screen coordinates into document 
coordinates, ignoring the effects in the associated GState.

**Pass:**  
ax - X screen coordinate.  
bx - Y screen coordinate.  
di - **WindowHandle**.

**Returns:**  
CF - Set on error.  
ax - On success, *x* screen coordinate; on error, an error code.  
bx - On success, *y* screen coordinate; destroyed on error.

**Destroyed:**  
Nothing (except possibly **bx**; see above).

**Library:** win.def

----------
#### WinUntransformDWord
Translates a 32-bit coordinate pair into 32-bit screen coordinates.

**Pass:**  
dx.cx - X screen coordinate (32-bit integer).  
bx.ax - Y screen coordinate (32-bit integer).  
di - **WindowHandle**.

**Returns:**  
CF - Set if **di** was a GState or a window that is closing. (**ax**, **bx**, **cx**, 
and **dx** remain unchanged).  
dx.cx - On success, *x* document coordinate (32-bit integer), otherwise 
unchanged.  
bx.ax - On success, *y* document coordinate (32-bit integer), otherwise 
unchanged.

**Destroyed:**  
Nothing.

**Library:** win.def

[Routines R-U](asmr_u.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Structures A-C](asmstrac.md)