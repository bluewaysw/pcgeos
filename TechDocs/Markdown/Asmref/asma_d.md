# 2 Routines
All routines in the kernel and the supplied libraries are 
listed alphabetically in the following sections. In many 
cases, data structures are listed with certain routines.
Global data structures and data types are listed in the 
following chapter.

## 2.1 Routines A-D

----------
#### ArrayQuickSort
Sort the given array using a modified quicksort algorithm.

**Pass:**  
ds:si - Address of the first element in the array.  
ax - Size of each element (all of uniform size).  
cx - Number of elements in the array.  
ss:bp - Address of an inheritable **QuickSortParameters** structure.  
bx - Value to pass to callback routine specified in **ss:bp**.

**Returns:**  
Nothing.

**Destroyed:**  
ax, cx, dx

**Library:** chunkarr.def

----------
#### CellDirty
Mark a cell as dirty.

**Pass:**  
es - Segment address of block containing the cell.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### CellGetDBItem
Get the group and item numbers of the database item associated with the 
specified cell.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.  
ax - Row number of cell.  
cl - Column number of cell.

**Returns:**  
CF - Set if the item exists, clear otherwise.  
ax - Group number of the cell.  
di - Item number of the cell.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### CellGetExtent
Get the extent (bounds) of the current sheet of spreadsheet cells.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.  
ss:bx - Address of a **RangeEnumParams** structure. The caller 
does not need to set any values in the structure.

**Returns:**  
ss:bx - Address of the **RangeEnumParams** structure; the 
*REP_bounds* field will be filled in with the extent of the 
spreadsheet. If there is no current spreadsheet, all bounds 
will be set to -1.

**Destroyed:**  
Nothing.

**Library:** cell.def

----------
#### CellLock
Lock a cell's data to examine or change it. The cell should not be locked while 
also working with other cells; the caller should lock the cell, copy the data, 
then unlock it with **CellUnlock**.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.  
ax - Row number of cell.  
cl - Column number of cell.

**Returns:**  
CF - Set if the item exists, clear otherwise.  
*es:di - Segment:chunk handle of the cell data if cell exists.

**Destroyed:**  
di, unless it is returned.

**Library:** cell.def

----------
#### CellReplace
Replace a cell's data with new data.

**Pass:**  
ds:si - Address of **CellFunctionParameters** structure.  
ax - Row number of cell.  
cl - Column number of cell.  
es:di - Address of new data.  
dx - Size of data pointed to, or zero to free the cell.

**Returns:**  
Nothing.

**Destroyed:**  
Possibly **es**, if it pointed to a database item in the same file.

**Library:** cell.def

----------
#### CellUnlock
Unlock a cell previously locked with **CellLock**.

**Pass:**  
es - Segment address of block containing cell data.

**Returns:**  
Nothing.

**Destroyed:**  
Normally, nothing. If using the error-checking kernel and segment 
error-checking is active, then if either DS or ES is pointing to a block that has 
become unlocked, that register will be set to NULL_SEGMENT.

**Library:** cell.def

----------
#### CheckForDamagedES
When using the error-checking version of the ui, this routine checks the ES 
register to make sure it points to a valid LMem block. This comes in handy 
in code where *es:xx should point to an object.

In a non-error-checking environment, this routine does nothing.

**Pass:**  
es - Alleged local memory block handle.

**Returns:**  
Nothing (flags preserved as well).

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### ChunkArrayAppend
Append a new element to the end of a chunk array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ax - Size of new element, if variable-sized.

**Returns:**  
ds:di - Address of new, locked element.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** This routine may resize or move the LMem block, invalidating all pointers to 
chunks or elements within it.

----------
#### ChunkArrayCreate
Create a new general chunk array with no elements.

**Pass:**  
ds - Global handle of block for new array.

bx - Element size (zero for variable-sized elements).

cx - Size for **ChunkArrayHeader**, or zero for default. Extra 
space is initialized to zeroes.

si - Chuck to resize and use for chunk array (zero to allocate a 
new chunk).

al - **ObjChunkFlags** to be passed to **LMemAlloc**.

**Returns:**  
*ds:si - Address of the new array, locked.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** This routine may resize or move the passed block, invalidating all segment 
pointers to it.

----------
#### ChunkArrayDelete
Delete a specified element from the given array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ds:di - Address of locked element.

**Returns:**  
ds:di - Address of the same element, if it still exists.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ChunkArrayDeleteRange
Delete a range of elements from the given chunk array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ax - First element to delete (inclusive).  
cx - Total number of elements to delete (-1 to delete to the end of 
the array).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ChunkArrayElementResize
Resize an element in a variable-sized chunk array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ax - Element number of the element to be resized.  
cx - New size of the element.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** If you are resizing the element larger, all pointers you've stored to chunks in 
the block are invalidated. If you are resizing the element smaller, the array 
is guaranteed not to move or cause other chunks to move.

----------
#### ChunkArrayElementToPtr
Return the address of a specified element in a chunk array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ax - Element number of element to find.

**Returns:**  
CF - Set if element number out of bounds.  
cx - Size of the returned element, if variable-sized.  
ds:di - Address of element; if **ax** was out of bounds, **ds:di** will be 
returned pointing to the last element in the array.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** The error-checking version fatal-errors if passed CA_NULL_ELEMENT in ax.

----------
#### ChunkArrayEnum
Process all elements in a chunk array, calling a callback routine for each.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
bx:di - Address of the callback routine.  
ax - Initial data passed to callback *only* if fixed-size elements.  
cx, dx, bp, es - Initial data to pass to callback routine.

**Returns:**  
CF - Set if enumeration aborted by the callback routine.  
ax, cx, dx, bp, es - As set by the last call to the callback routine.

**Destroyed:**  
bx

**Callback Routine Specifications:**  
**Passed:**  
*ds:si - Segment:chunk handle of the chunk array.  
ds:di - Address of element being processed.  
ax - Size of element, if variable-sized; otherwise, 
inherited from **ChunkArrayEnum**.  
cx, dx, bp, es - Inherited from **ChunkArrayEnum**.  
**Return:**  
CF - Set to abort processing.  
cx, dx, bp, es - Data to pass to next enumeration.  
**May Destroy:**  bx, si, di

**Library:** chunkarr.def

----------
#### ChunkArrayEnumRange
Process the specified elements in a chunk array, calling a callback routine for 
each element.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
bx:di - Address of the callback routine.  
ax - Number of first element to process.  
cx - Number of elements to process (-1 to process all including the 
last element).  
dx, bp, es - Initial data to pass to the callback routine.

**Returns:**  
CF - Set if the routine was aborted before all specified elements 
were processed.  
ax, cx, dx, bp, es - As returned by the last call to the callback routine.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
*ds:si - Segment:chunk handle of the chunk array.  
ds:di - Address of element being processed.  
ax - Size of element, if variable-sized; otherwise, 
inherited from ChunkArrayEnumRange.  
cx, dx, bp, es - Inherited from ChunkArrayEnumRange.  
**Return:**  
CF - Set to abort processing.  
cx, dx, bp, es - Data to pass to next enumeration.  
**May Destroy:** bx, si, di

**Library:** chunkarr.def

----------
#### ChunkArrayGetCount
Return the number of elements in the given chunk array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.

**Returns:**  
cx - Number of elements in the array.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ChunkArrayGetElement
Get an element given its element number.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ax - Element number of element to be retrieved.  
cx:dx - Address of a buffer in which the element will be returned.

**Returns:**  
ax - Size of element returned.  
cx:dx - Address of filled buffer

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** The error-checking version will fatal-error if CA_NULL_ELEMENT is 
passed in ax or if **ax** is out of bounds.

----------
#### ChunkArrayInsertAt
Insert the specified element at a given position in the array.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ds:di - Address of element to insert.  
ax - Size of new element, if variable-sized.

**Returns:**  
ds:di - Address of new element in the array.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** This routine may resize or move the passed block, invalidating all segment 
pointers to it.

----------
#### ChunkArrayPtrToElement
Return the element number of the element pointed to.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.  
ds:di - Address of the element to be checked.

**Returns:**  
ax  Zero-based element number.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ChunkArraySort
Sort the given chunk array in ascending order.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array to sort.  
bx - Value to pass to callback routine.  
cx:dx - Address of callback routine.

**Returns:**  
Nothing.

**Destroyed:**  
cx, dx

**Callback Routine Specifications:**  
**Passed:**  
bx - Value inherited from **ChunkArraySort**.  
ds:si - Address of first element to compare.  
es:di - Address of second element to compare.  
**Return:**  
SF, OF, ZF - These flags should be set in the following 
conditions:

- first element less than second element  
SF - set  
OF - clear  
ZF - unrestricted

- first element equal to second element  
SF - unrestricted  
OF - unrestricted  
ZF - set

- first element larger than second element  
SF - clear  
OF - clear  
ZF - clear

**May Destroy:** ax, bx, cx, dx, si, di

**Library:** chunkarr.def

----------
#### ChunkArrayZero
Free all the elements of the given chunk array and resize it.

**Pass:**  
*ds:si - Segment:chunk handle of the chunk array.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ClipboardAbortQuickTransfer
This routine aborts a quick-transfer. This routine is normally used if the 
quick-transfer source object is about to be destroyed or if an error occurs 
trying to register the quick-transfer item.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardAddToNotificationList
Add the passed OD to the transfer notify list.

**Pass:**  
cx:dx - OD to add. If **cx** is the process handle, then **dx** must be zero.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardClearQuickTransferNotification
This routine removes the quick-transfer OD notification.

**Pass:**  
bx:di - Notification OD to remove. 

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardDoneWithItem
This routine must be called when you are finished using the requested 
transfer item.

**Pass:**  
bx:ax - Transfer item header, as returned by 
**ClipboardQueryItem**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardEndQuickTransfer

End a quick-transfer. Reset the mouse pointer image, clear the 
quick-transfer region (if any), and clear the quick-transfer item. Send out 
notification if necessary.

**Pass:**  
bp - **ClipboardQuickNotifyFlags**. If a quick-transfer move 
operation was done, then CQNF_MOVE should be set. If a 
quick-transfer copy operation was done, then CQNF_COPY 
should be set. If the item was not accepted, the 
CQNF_NO_OPERATION should be set.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardEnumItemFormats
This routine returns the list of all available formats 
(**ClipboardItemFormatID** structures).

**Pass:**  
bx:ax - Transfer item header, as returned by  **ClipboardQueryItem**.

cx - Maximum number of formats to return.  
es:di - Buffer for formats (should be at least **cx** * 
sizeof(**ClipboardItemFormatID**).

**Returns:**  
cx - Number of formats returned.  
es:di - (unchanged) Buffer now filled.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardFreeItem
Free the passed clipboard item.

**Pass:**  
bx:ax - **VMFileHandle:VMBlockHandle** of item to free.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardFreeItemsNotInUse
Frees normal or quick transfer item if nobody's using it, nukes references to 
it, sends proper GCN messages out.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

**Warning:** The user should not have called **ClipboardRegisterItem** with this transfer 
item, as this routine just frees the data without updating any references in 
the map block.

----------
#### ClipboardGetClipboardFile
Return the VM file used to hold clipboard items.

**Pass:**  
Nothing.

**Returns:**  
bx - Handle of UI's clipboard VM file.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardGetItemInfo

Get more information about the passed transfer item.

**Pass:**  
bx:ax - Transfer item header, as returned by 
**ClipboardQueryItem**.

**Returns:**  
cx:dx - Handle:chunk of *CIH_sourceID* from clipboard item header.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardGetNormalItemInfo

Return normal clipboard item information.

**Pass:**  
Nothing.

**Returns:**  
bx - Clipboard VM file handle.  
ax - Clipboard VM block handle.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardGetQuickItemInfo

Return quick clipboard item information.

**Pass:**  
Nothing.

**Returns:**  
bx - Clipboard VM file handle.  
ax - Clipboard VM block handle.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardGetQuickTransferStatus

Check to see if a quick-transfer is in progress.

**Pass:**  
Nothing.

**Returns:**  
ZF - Clear if quick-transfer is in progress; set otherwise.  
ax - If a quick transfer is in progress, this will be 
**ClipboardQuckTransferFlags** indicating what stage the 
process is in.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardGetUndoItemInfo

Return undo clipboard item information.

**Pass:**  
Nothing.

**Returns:**  
bx - Clipboard VM file handle.  
ax - Clipboard VM block handle.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardHandleEndMoveCopy
This routine handles a MSG_META_END_COPY, either preparing to finish the 
quick-transfer and send a MSG_META_END_MOVE_COPY to the object with 
the active grab or ending the quick-transfer and sending a 
MSG_META_END_OTHER to the object with the implied grab.

**Pass:**  
bx - Zero to send a MSG_META_END_OTHER; non-zero to send a 
MSG_META_END_MOVE_COPY.  
bp - High byte is a **UIFunctionsActive** structure.  
CF - Should be set clear. Set to check if quick-transfer is in 
progress (this is needed only for internal input handling). 

**Returns:**  
ax - MSG_META_END_OTHER or MSG_META_END_MOVE_COPY 
(as determined by passed value in **bx**).

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardQueryItem
This routine registers the passed transfer item.

**Pass:**  
bp - **ClipboardItemFlags** (all but CIF_QUICK will be ignored).

**Returns:**  
bp - Number of formats available (zero if no clipboard item).  
cx:dx - Owner of clipboard item.  
bx:ax - **VMFileHandle:VMBlockHandle** to clipboard item header 
(which may then be passed to 
**ClipboardRequestItemFormat**).

**Destroyed:**  
Nothing.

**Warning:** After calling this routine, **ClipboardDoneWithItem** must be called.

**Library:** clipbrd.def

----------
#### ClipboardRegisterItem

This routine registers the passed transfer item.

**Pass:**  
ax - Handle of VM block containing **ClipboardItemHeader** 
structure or zero to null the clipboard item.  
bx - Handle of VM file containing clipboard item.  
bp - **ClipboardItemFlags**.

**Returns:**  
CF - If registering a quick transfer item, this flag's behavior is 
undefined. If registering a normal transfer item, this flag will 
be set on an error, clear otherwise.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardRemoteReceive
Receive clipboard from remotely connected machine.

**Pass:**  
Nothing.

**Returns:**  
CF - Set on error, clear on success.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardRemoteSend
Send clipboard to remotely connected machine.

**Pass:**  
Nothing.

**Returns:**  
CF - Set on failure, clear on success.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardRemoveFromNotificationList
Remove the passed OD from the transfer notify list.

**Pass:**  
cx:dx - OD to remove. If **cx** is the process handle, then **dx** must be 
zero.

**Returns:**  
CF - Clear if successfully removed, set if was not found.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardRequestItemFormat
This routine requests the given transfer item, as stored in the given format 
type.

**Pass:**  
bx:ax - Transfer item header, as returned by 
**ClipboardQueryItem**.  
cx:dx - Format manufacturer:format type.

**Returns:**  
bx - File handle of transfer item.  
ax:bp - VM chain (zero if none).  
cx - First extra data word.  
dx - Second extra data word.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardSetQuickTransferFeedback
Set mouse cursor for quick-transfer.

**Pass:**  
ax - **ClipboardQuickTransferFeedback** value.  
bp - If ax is CQTF_MOVE or CQTF_COPY, then the high byte of this 
register should hold a UIFunctionsActive value. UIFA_MOVE 
signals that you wish to force the cursor to be that associated 
with a quick-move; UIFA_COPY that you wish to force the 
quick-copy cursor.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardStartQuickTransfer
Initiate a quick transfer (normally called from 
MSG_META_START_MOVE_COPY).

**Pass:**  
si - **ClipboardQuickTransferFlags**. The CQTF_COPY_ONLY 
flag should be set if the source only supports copying.
The CQTF_USE_REGION flag should be set if you will be 
passing a region to use as the quick-transfer cursor.
The CQTF_NOTIFICATION flag should be set if the source 
wants notification when the quick-transfer item is accepted 
by the destination.  
ax - Initial cursor to use (CQTF_MOVE or CQTF_COPY). This 
should be -1 if you wish to use the default cursor (i.e. object is 
a quick-transfer source, but not a quick transfer destination).  
cx, dx - If CQTF_USE_REGION set, these registers hold the mouse 
position in screen coordinates. Otherwise they are ignored.  
bx:di - If CQTF_NOTIFICATION set, these registers hold the OD to 
receive MSG_NOTIFY_QUICK_TRANSFER_MOVE, 
MSG_NOTIFY_QUICK_TRANSFER_COPY, and 
MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEED
BACK.  
ss:bp - If CQTF_USE_REGION set, values will be passed on stack.

**Pass on stack:** The following structure will only be passed if CQTF_USE_REGION is set:

    ClipboardQuickTransferRegionInfo struct
         CQTRI_paramAX word
         CQTRI_paramBX word
         CQTRI_paramCX word
         CQTRI_paramDX word
         CQTRI_regionPos Point
         CQTRI_strategy dword
         CQTRI_region dword         ; pointer to region
    ClipboardQuickTransferRegionInfo ends

*CQTRI_region* must be in a block that is in memory already.

*CQTRI_strategy* should be a video driver strategy. To find out the strategy of 
the video driver associated with your window, send your object a 
MSG_VIS_VUP_QUERY with VUQ_VIDEO_DRIVER. Pass the handle thus 
gained to **GeodeInfoDriver**, which will return the strategy.

**Returns:**  
CF - Clear if UI part of new quick-transfer successfully begun; set 
if a quick-transfer was already in progress.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardTestItemFormat
This routine determines whether the clipboard item supports the specified 
format.

**Pass:**  
bx:ax - Transfer item header, as returned by 
**ClipboardQueryItem**.  
cx:dx - Format manufacturer:format type.

**Returns:**  
CF - Clear if format supported; set otherwise.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ClipboardUnregisterItem

This routine unregisters the passed clipboard item, restoring any transfer 
which may have been disturbed by the last normal clipboard item.

**Pass:**  
cx:dx - Owner output descriptor used when registering previous 
item.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** clipbrd.def

----------
#### ConfigBuildTitledMoniker
Global routine to build a titled moniker based on the passed moniker list

**Pass:**  
*ds:si - visual moniker list.

**Returns:**  
Nothing; visMoniker list replaced with visMoniker.

**Destroyed:**  
Nothing.

**Library:** config.def

----------
#### ConfigBuildTitledMonikerUsingToken
Combine 2 vis monikers-placing the text moniker centered below the 
picture moniker.

**Pass:**  
ds - Local memory block in which to create the new moniker.  
ax:bx:si - Token characters.

**Returns:**  
CF - Clear if found; set otherwise.  
*ds:dx - New moniker.

**Destroyed:**  
ax, bx, cx, di

**Library:** config.def

----------
#### DBAlloc
Allocate a new database item in a specified group.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the new item (VM block handle).
For an ungrouped item, pass DB_UNGROUPED.  
cx - Size of the new item.  
ds - Optional segment address of an item-block.  
es - Optional segment address of an item-block.

**Returns:**  
di - Item number of newly allocated item.  
ax - Group number of new item.  
ds - (If passed) fixed up.  
es - (If passed) fixed up.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBCopyDBItem
Copy an existing database item into a newly-allocated item.

**Pass:**  
bx - File handle of the source database file.  
ax - Group identifier of the source database item.  
di - Item number of the source database item.  
bp - File handle of the destination database file.  
cx - Group identifier of the destination item's group. For and 
ungrouped item, pass DB_UNGROUPED.

**Returns:**  
di - Item number of the new item.  
ax - Group identifier of the new item.

**Destroyed:**  
Nothing.

**Library:** dbase.def

**Warning:** Because a new chunk is allocated, chunks or blocks may be moved. Thus, all 
pointers are invalidated by this routine.

----------
#### DBDeleteAt
Delete a given number of bytes from within the specified database item.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the item.  
di - Item number of the item.  
dx - Offset of first byte to be deleted.  
cx - Total number of bytes to be deleted.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBDirty

Mark a database item as dirty so it will be written to the database file with 
its changes.

**Pass:**  
es - Segment of locked block containing the database item.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBFree
Remove the specified item from the database.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the item.  
di - Item number of the item to be freed.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBGetMap
Return the item that is set to be the database's map.

**Pass:**  
bx - File handle of the database file.

**Returns:**  
ax - Group identifier of the map item's group.  
di - Item number of the map item.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBGroupAlloc
Create a new database group.

**Pass:**  
bx - File handle of the database file.

**Returns:**  
ax - Group identifier of the new group.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBGroupFree
Remove all items in the specified group and delete the group.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the group to be deleted.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBInsertAt
Insert a specified number of bytes within a given database item. The bytes 
may be inserted at any offset, and the new bytes will be zeroed.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the item.  
di - Item number of the item.  
cx - Total number of bytes to insert.  
ds - Optional segment address of an item-block.  
es - Optional segment address of an item-block.

**Returns:**  
ds - (If passed) fixed up.  
es - (If passed) fixed up.  
si - Old segment address of changed item block.  
ax - New segment address of changed item block.

**Destroyed:**  
Nothing.

**Library:** dbase.def

**Warning:** Because the chunk is resized larger, chunks or blocks may be moved. Thus, 
all pointers are invalidated by this routine.

----------
#### DBLock
Lock a database item for exclusive access. When you're done with the item, 
unlock it with **DBUnlock**.

**Pass:**  
bx - File handle of the database file.  
ax - Item's group number.  
di - Item's item number.

**Returns:**  
*es:di - Segment:chunk handle of database item.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBLockMap
Lock the map item for the database file. This is a utility that is slightly 
quicker than calling **DBGetMap** followed by **DBLock**. When finished with 
the map item, you must call **DBUnlock** on it.

**Pass:**  
bx - File handle of the database file.

**Returns:**  
*es:di - Segment:chunk handle of the locked map item.  
di - Zero if there is no map item. In this case, es is not returned.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBReAlloc
Change the size of an existing database item.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the item (VM block handle).  
di - Item number of the item to be reallocated.  
cx - New size of the item.  
ds - Optional segment address of an item-block.  
es - Optional segment address of an item-block.

**Returns:**  
ds - (If passed) fixed up.  
es - (If passed) fixed up.  
**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBSetMap
Mark a database item as being the map item for the database file.

**Pass:**  
bx - File handle of the database file.  
ax - Group identifier of the item's group.  
di - Item number of the item to be made the map.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** dbase.def

----------
#### DBUnlock
Unlocks a database item that had previously been locked with **DBLock**.

**Pass:**  
es - Segment address of the item's item-block.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing. (Error-checking code may destroy ds or es by writing 
NULL_SEGMENT to it, if it pointed to a block that had become unlocked.)

**Library:** dbase.def

----------
#### DiskCheckInUse
Determine if the passed disk is actively being used, either by an open file or 
by a thread having a directory on the disk in its directory stack.

**Pass:**  
bx - Disk handle of disk to be checked.

**Returns:**  
CF - Set if disk is in use, clear if it is not.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskCheckUnnamed
Check if the passed disk handle refers to an unnamed disk (i.e. a disk that 
has no user-supplied volume name).

**Pass:**  
bx - Disk handle of disk to be checked.

**Returns:**  
CF - Set if disk is unnamed, clear if it is named.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskCheckWritable
See if the passed volume is writable.

**Pass:**  
bx - Disk handle of volume to be checked.

**Returns:**  
CF - Set if the volume is writable, clear if it is not.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskCopy
Copies the contents of the source disk to the destination disk, prompting for 
them as necessary.

**Pass:**  
dh - source drive number  
dl - destination drive number  
al - **DiskCopyFlags**  
cx:bp - callback routine

**Returns:**  
ax  DiskCopyError/FormatError; Zero if successful.

**Callback Routine Specifications:**  
**Passed:**  
ax - DiskCopyCallback value signalling what to 
do next.  
bx, dx - Additional information based on value of ax:  
DCC_GET_SOURCE_DISK  
  **dl** = Zero-based drive number.  
DCC_REPORT_NUM_SWAP  
  **dx** = Number of swaps required.  
DCC_GET_DEST_DISK  
  **dl** = Zero-based drive number.  
DCC_VERIFY_DEST_DESTRUCTION  
  **bx** = Disk handle of destination disk  
  **dl** = Zero-based drive number  
DCC_REPORT_FORMAT_PCT  
  **dx** = Percentage of disk formatted.  
DCC_REPORT_READ_PCT  
  **dx** = Percentage of disk read.  
DCC_REPORT_WRITE_PCT  
  **dx** = Percentage of disk written.  
**Return:** Zero to continue, non-zero to abort.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskFind
Search the list of registered disks and return the handle of that having the 
passed volume name. An additional search is also made to ensure the match 
is unique.

**Pass:**  
ds:si - Address of null-terminated volume name to search for.

**Returns:**  
CF - Set if error.  
ax - DiskFindResult:  
DFR_UNIQUE if found and unique match.  
DFR_NOT_UNIQUE if found but not unique.  
DFR_NOT_FOUND if no match found.  
bx - If successful, disk handle of first disk found; otherwise, zero.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskForEach
Call a callback routine for each disk registered with the system, allowing the 
callback to cancel the operation.

**Pass:**  
ax, cx, dx, bp - Initial data to pass to the callback routine.  
di:si - Address of callback routine.

**Returns:**  
ax, cx, dx, bp - As returned by last callback execution.  
CF - Set if callback forced early termination.  
bx - If CF set, the disk handle of the last disk processed; otherwise 
will be returned zero.

**Destroyed:**  
di, si

**Callback Routine Specifications:**  
**Passed:**  
bx - Disk handle of current disk.  
ax, cx, dx, bp  Data set by caller and callback.  
**Return:**  
ax, cx, dx, bp - May be modified or preserved.  
CF - et if processing should be aborted.  
**May Destroy:**  
ax, cx, dx, bp

**Library:**    disk.def

----------
#### DiskFormat
Format the disk in the specified drive.

**Pass:**  
al - Drive number.  
ah - GEOS media descriptor (**MediaType**).  
bx - Handle of the disk to be formatted, or
Zero if disk is known to be unformatted, or
-1 if state of drive is not known.  
bp - **DiskFormatFlags**.  
ds:si - New null-terminated ASCII volume name for the disk.  
cx:dx - Address of callback routine, initialized only if 
DFF_CALLBACK_PCT_DONE or DFF_CALLBACK_CYL_HEAD 
passed in **bp**.

**Returns:**  
CF - Set on error.  
ax - Error code if error (FormatError), or FMT_DONE if 
successful.  
si:di - If successful, returns number of bytes in good clusters.  
dx:cx - If successful, returns number of bytes in bad clusters.

**Destroyed:**  
ax, bx

**Callback Routine Specifications:**  
**Passed:**  
ax - Percentage done or number of cylinder heads 
finished, appropriate to bp parameter.  
**Return:**  
CF - Return set to cancel format.  
**May Destroy:** Nothing.

**Library:** disk.def

**Warning:** All data on the destination disk is lost.

----------
#### DiskGetDrive
Return the drive number of the drive in which the passed disk was 
registered.

**Pass:**  
bx - Disk handle of registered disk.

**Returns:**  
al - Zero-based drive number.

**Destroyed:**  
ah

**Library:** disk.def

----------
#### DiskGetVolumeFreeSpace
Return the number of bytes free on a volume.

**Pass:**  
bx - Disk handle of registered volume.

**Returns:**  
CF - Set if error, clear if successful.  
ax - If error, error code: ERROR_INVALID_VOLUME.  
dx.ax - If successful, number of bytes free on volume.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskGetVolumeInfo
Return information about a registered disk.

**Pass:**  
bx - Disk handle of registered disk.  
es:di - Address of **DiskInfoStruct** to fill in.

**Returns:**  
CF - Set if error.  
ax - Zero if successful, otherwise ERROR_INVALID_VOLUME.  
es:di - If successful, the address of the returned DiskInfoStruct 
structure, filled in.

**Destroyed:**  
ax

**Library:** disk.def

----------
#### DiskGetVolumeName
Return the volume name of the disk specified by the passed handle.

**Pass:**  
bx - Disk handle of registered disk.  
es:di - Pointer to locked or fixed buffer at least 
VOLUME_NAME_LENGTH_ZT bytes long.

**Returns:**  
es:di - Pointer to null-terminated volume name (with no trailing 
spaces).

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskRegisterDisk
Register a disk with the system.

**Pass:**  
al - Drive number containing disk to be registered.

**Returns:**  
CF - Clear if successful, set if error.  
bx - Disk handle of registered disk if successful, zero if error.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskRegisterDiskSilently
Register a disk with the system without informing the user.

**Pass:**  
al - Drive number containing disk to be registered.

**Returns:**  
CF - Clear if successful, set if error.  
bx - Disk handle of registered disk if successful, zero if error.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskRestore
Restore a disk handle that had been saved to the state file with DiskSave.

**Pass:**  
ds:si - Address of locked or fixed buffer originally passed to 
**DiskSave**.  
cx:dx - Address of callback routine to call if the user must be 
prompted for the disk. If cx is zero, no callback will be 
attempted and the routine will fail if the disk is unavailable 
(i.e. the drive no longer exists or the disk is not in the drive).

**Returns:**  
CF - Set if disk handle could not be restored.  
ax - If CF clear, the disk handle of the registered disk.
If CF set, a **DiskRestoreError** indicating the failure.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ds:dx - Address of null-terminated drive name, with 
":" (colon) as the last character.  
ds:di - Address of null-terminated disk name.  
ds:si - Address of buffer originally passed to 
**DiskSave**.  
ax - **DiskRestoreError** to be returned if the 
callback routine was not being called.  
bx, bp - As passed to **DiskRestore**.  
**Return:**  
CF - Clear if disk should be in the drive, set if user 
cancelled the restoration.  
ds:si - If CF clear, address of buffer originally passed 
to **DiskSave**.  
ax - If CF set, error code returned (typically 
DRE_USER_CANCELED_RESTORE).  
**May Destroy:** Nothing.

**Library:** disk.def

----------
#### DiskSave
Save information that will allow a disk handle to be restored when the caller 
is restoring itself from a state file after a shutdown.

**Pass:**  
bx - Disk handle to save.  
es:di - Address of locked or fixed buffer for opaque data.  
cx - Size of buffer in **es:di**.

**Returns:**  
CF - Clear if successful, set if error.  
cx - If CF clear, actual number of bytes used in the buffer.
If CF set, the number of bytes needed to save the disk; zero if 
the disk can not be saved at all (e.g. it is a network drive that 
no longer exists).

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DiskSetVolumeName
Set the name of a registered disk.

**Pass:**  
bx - Disk handle of registered volume.  
ds:si - Address of null-terminated ASCII name.

**Returns:**  
CF - Set if error.  
ax - Error code, or zero if no error
ERROR_INVALID_VOLUME
ERROR_ACCESS_DENIED.

**Destroyed:**  
Nothing.

**Library:** disk.def

----------
#### DosExec
Begin execution of a DOS application, shutting down GEOS to state files or 
creating a new task in the task-switcher for the DOS application.

**Pass:**  
bx - Optional disk handle for the disk on which the DOS program 
resides. (Pass zero for the disk containing GEOS.)  
ds:si - Address of null-terminated path of the DOS application. If 
this is just a null character, the system's command 
interpreter will be run with the given command-line 
arguments.  
es:di - If DEF_MEM_REQ is passed, this will contain the 
DosExecArgAndMemReqsStruct containing the memory 
requirements of the program; Otherwise, this is the address 
of a buffer containing the command-line arguments to pass to 
the application.  
ax - Optional disk handle for the disk that contains the path or 
directory in which the application should be executed.  
dx:bp - Address of a buffer containing the null-terminated path or 
directory name in which the application should be executed.  
cx - A record of **DosExecFlags**.

**Returns:**  
CF - Set if the program could not be run.  
ax - Error code if CF is set:  
ERROR_FILE_NOT_FOUND  
ERROR_DOS_EXEC_IN_PROGRESS  
ERROR_INSUFFICIENT_MEMORY  
ERROR_ARGS_TOO_LONG

**Destroyed:**  
ax, bx, cx, dx, di, si, bp, ds, es

**Library:** system.def

----------
#### DriveGetDefaultMedia
Return the GEOS media descriptor of the highest density format supported 
by the specified drive.

**Pass:**  
al - Zero-based drive number.

**Returns:**  
CF - Set if drive does not exist.  
ah - GEOS media descriptor (**MediaType**).

**Destroyed:**  
Nothing.

**Library:** drive.def

----------
#### DriveGetExtStatus
Return the extended status word for the specified drive.

**Pass:**  
al - Zero-based drive number.

**Returns:**  
CF - Set if drive does not exist.  
ax - **DriveExtendedStatus** record if successful.

**Destroyed:**  
Nothing.

**Library:** drive.def

----------
#### DriveGetName
Return the name of the specified drive.

**Pass:**  
al - Zero-based drive number.  
es:di - Address of locked or fixed buffer into which the 
null-terminated name will be written.  
cx - Number of bytes in the buffer.

**Returns:**  

- CF - clear:  
cx - Number of bytes written to the buffer including the 
terminating null.  
es:di - Address of the terminating null, not the first character.

- CF set:  
cx - Zero if the drive does not exist.
Total number of bytes needed if the buffer is too small.

**Destroyed:**  
Nothing.

**Library:** drive.def

----------
#### DriveGetStatus
Returns status information on the specified drive.

**Pass:**  
al - Zero-based drive number.

**Returns:**  
CF - Set if drive does not exist.  
ah - **DriveStatus** record if successful.

**Destroyed:**  
Nothing.

**Library:** drive.def

----------
#### DriveTestMediaSupport
Test if the specified drive supports the given media type.

**Pass:**  
al - Zero-based drive number.  
ah - MediaType media descriptor.

**Returns:**  
CF - Clear if media type supported by the drive; set otherwise.

**Destroyed:**  
Nothing.

**Library:** drive.def

[Parameters File Keywords](agp.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Routines E-F](asme_f.md)