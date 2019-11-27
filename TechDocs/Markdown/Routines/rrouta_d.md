# 3 Routines
All routines in the kernel and the supplied libraries are 
listed alphabetically in the following sections. In many 
cases, data structures are listed with certain routines.
Global data structures and data types are listed in the 
following chapter.

## 3.1 Routines A-D

----------
#### ArrayQuickSort()
	void	ArrayQuickSort(
			void	*array,		/* Pointer to start of array */
			word	count,		/* Number of elements in array */
			word	elementSize,/* Size of each element (in bytes) */
			word	valueForCallback, 	/* Passed to callback routine */
			QuickSortParameters *parameters);

This routine sorts an array of uniform-sized elements. It uses a modified 
QuickSort algorithm, using an insertion sort for subarrays below a certain 
size; this gives performance of 'O('nlog'n). The routine calls a callback routine 
to actually compare elements.

**ArrayQuickSort()** is passed five arguments: A pointer to the first element 
of the array, the number of elements in the array, the size of each element in 
bytes, a word of data (which is passed to all callback routines), and a pointer 
to a **QuickSortParameters** structure.

Before **ArrayQuickSort()** examines or changes any element, it calls a 
locking routine specified by the **QuickSortParameters** structure. This 
routine locks the element, if necessary, and takes any necessary preparatory 
steps. Similarly, after **ArrayQuickSort()** is finished with a routine, it calls 
an unlocking routine in the **QuickSortParameters**. Each of these routines 
is passed a pointer to the element and the word of callback data which was 
passed to **ArrayQuickSort()**.

The sort routine does not compare elements. Rather, it calls a comparison 
callback routine specified by the **QuickSortParameters**. This callback 
routine should be declared _pascal. Whenever **ArrayQuickSort()** needs to 
compare two elements, it calls the callback routine, passing the addresses of 
the elements and the *valueForCallback* word which was passed to 
**ChunkArraySort()**. The callback routine's return value determines which 
element will come first in the sorted array:

+ If element *el1* ought to come before *el2* in the sorted array, the callback 
routine should return a negative integer.

+ If element *el1* ought to come after *el2* in the sorted array, the callback 
routine should return a positive integer.

+ If it doesn't matter whether *el1* comes before or after *el2* in the array, the 
callback routine should return zero.

**Include:** chunkarr.h

**Tips and Tricks:** You may need to sort an array based on different criteria at different times. 
The simplest way to do this is to write one general-purpose callback routine 
and have the *valueForCallback* word determine how the sort is done. For 
example, the same callback routine could sort the array in ascending or 
descending order, depending on the *valueForCallback*.

**Be Sure To:** Lock the array on the global heap (unless it is in fixed memory).

**Warnings:** Do not have the callback routine do anything which might invalidate 
pointers to the array. For example, if the array is in a chunk, do not resize the 
chunks or allocate other chunks in the same LMem heap.

**See Also:** QuickSortParameters, ChunkArraySort()

----------
#### BlockFromTransferBlockID
	VMBlockHandle BlockFromTransferBlockID(id);
			TransferBlockID 	id;
This macro extracts the VMBlockHandle from a **TransferBlockID**.

----------
#### BlockIDFromFileAndBlock
	TransferBlockID BlockIDFromFileAndBlock(file, block);
			VMFileHandle 	file;
			VMBlockHandle 	block;
This macro creates the dword type **TransferBlockID** from a VMFileHandle 
and a VMBlockHandle.

----------
#### bsearch()
	extern void *_pascal bsearch(
			const void 		*key, 
			const void 		*array,
			word 			count, 
			word 			elementSize,
			PCB(int, compare, (const void *, const void *)));

This is a standard binary search routine. The callback routine must be 
declared _pascal.

----------
#### calloc()
	void *	calloc(
			word		n,			/* number of structures to allocate */
			size_t		size);		/* size of each structure in bytes */
The **malloc()** family of routines is provided for Standard C compatibility. If 
a geode needs a small amount of fixed memory, it can call one of the routines. 
The kernel will allocate a fixed block to satisfy the geode's **malloc()** requests; 
it will allocate memory from this block. When the block is filled, it will 
allocate another fixed malloc-block. When all the memory in the block is 
freed, the memory manager will automatically free the block.

When a geode calls **calloc()**, it will be allocated a contiguous section of 
memory large enough for the specified number of structures of the specified 
size. The memory will be allocated out of its malloc-block, and the address of 
the start of the memory will be returned. The memory will be zero-initialized. 
If the request cannot be satisfied, **calloc()** will return a null pointer. The 
memory is guaranteed not to be moved until it is freed (with **free()**) or resized 
(with **realloc()**). When GEOS shuts down, all fixed blocks are freed, and any 
memory allocated with **calloc()** is lost.

**Tips and Tricks:** You can allocate memory in another geode's malloc-block by calling 
**GeoMalloc()**. However, that block will be freed when the other geode exits.

**Be Sure To:** Request a size small enough to fit in a malloc-block; that is, the size of the 
structure times the number of structures requested must be somewhat 
smaller than 64K.

**Warnings:** All memory allocated with **calloc()** is freed when GEOS shuts down.

**See Also:** malloc(), free(), GeoMalloc(), realloc()

----------
#### CCB()
	#define CCB(return_type, pointer_name, args) \
			return_type _cdecl (*pointer_name) args
This macro is useful for declaring pointers to functions that use the C calling 
conventions. For example, to declare a pointer to a function which is passed 
two strings and returns an integer, one could write

	CCB(int, func_ptr, (const char *, const char *));

which would be expanded to

	int _cdecl (*func_ptr) (const char *, const char *);

**See Also:** PCB()

----------
#### CellDeref()
	void *	CellDeref(
			optr	CellRef);
This routine translates an optr to a cell into the cell's address. The routine is 
simply a synonym for **LMemDeref()**.

----------
#### CellDirty()  
	void	CellDirty(
			void *		ptr);	/* pointer to anywhere in locked cell */

This routine marks a cell as "dirty"; i.e., the cell will have to be copied from 
memory back to the disk.

**Include:** cell.h

**Tips and Tricks:** All the cells in an item block are marked dirty at once; thus, you can call this 
routine just once for several cells in the same item block. Only the segment 
portion of the pointer is significant; thus, you can pass a pointer to anywhere 
in the cell. This is useful if you have incremented the pointer to the cell.

**See Also:** Section 19.4.2.2 of the Concepts book

----------
#### CellGetDBItem()
	DBGroupAndItem 	CellGetDBItem(
			CellFunctionParameters *	cfp,
			word	row,		/* Get handles of cell in this row */
			byte	column);	/*...and this column */
All cells are stored as ungrouped DB items. If you wish to manipulate the 
cells with standard DB routines, you will need to know their handles. The 
routine is passed the address of the **CellFunctionParameters** and the row 
and column indices of the desired cell. It returns the **DBGroupAndItem** 
value for the specified cell. If there is no cell at the specified coordinates, it 
returns a null **DBGroupAndItem**. The routine does not lock the cell or 
change it in any way.

**Include:** cell.h

**See Also:** DBGroupAndItem, Section 19.4.2.2 of the Concepts book

----------
#### CellGetExtent()
	void	CellGetExtent(
			CellFunctionParameters *	cfp, 
			RangeEnumParams *	rep); /* write boundaries in REP_bounds field */
This routine returns the boundaries of the utilized portion of the cell file. The 
routine is passed the address of the cell file's **CellFunctionParameters** 
structure.) It writes the results into the *REP_bounds* field of the passed 
**RangeEnumParams** structure. The index of the first row to contain cells is 
written into *REP_bounds.R_top*; the index of the last occupied row is written 
to *REP_bounds.R_bottom*; the index of the first occupied column is written to 
*REP_bounds.R_left*; and the index of the last occupied row is written to 
*REP_bounds.R_right*. If the cell file contains no cells, all four fields will be set 
to -1.

**Include:** cell.h

**See Also:** Section 19.4.2.2 of the Concepts book

----------
#### CellLock()
	void *	CellLock(
			CellFunctionParameters*		cfp,
			word		row,		/* Lock cell in this row... */
			word		column);	/* ... and this column */

This routine is passed the address of the **CellFunctionParameters** of a cell 
file, and the row and column indices of a cell. It locks the cell and returns a 
pointer to it.

**Include:** cell.h

**See Also:** CellLockGetRef(), Section 19.4.2.2 of the Concepts book

----------
#### CellLockGetRef()
	void *	CellLockGetRef(
			CellFunctionParameters*		cfp,
			word		row,		/* Lock cell in this row... */
			word		column,		/* ... and this column */
			optr *		ref);		/* Write handles here */

This routine is passed the address of the **CellFunctionParameters** of a cell 
file, and the row and column indices of a cell. It locks the cell and returns a 
pointer to it. It also writes the locked cell's item-block and chunk handles to 
the optr. If the cell moves (e.g. because another cell is allocated), you can 
translate the optr structure into a pointer by passing it to **CellDeref()**.

**Include:** cell.h

**Warnings:** The optr becomes invalid when the cell is unlocked.

**See Also:** CellGetDBItem(). CellLock(), Section 19.4.2.2 of the Concepts book

----------
#### CellReplace()
	void	CellReplace{
			CellFunctionParameters *	cfp,
			word			row,		/* Insert/replace cell at this row... */
			word			column,		/* ... and this column */
			const void *	cellData,	/* Copy this data into the new cell */
			word			size);		/* Size of new cell (in bytes) */
This routine is used for creating, deleting, and replacing cells in a cell file. To 
create or replace a cell, set *cellData* to point to the data to copy into the new 
cell, and set *size* to the length of the cell in bytes, and row and column the 
cell's coordinates. (As usual, *cfp* is a pointer to the cell file's 
**CellFunctionParameters** structure.) Any pre-existing cell at the specified 
coordinates will automatically be freed, and a new cell will be created.

To delete a cell, pass a *size* of zero. If there is a cell at the specified 
coordinates, it will be freed. (The *cellData* argument is ignored.)

**Include:** cell.h

**Warnings:** If a cell is allocated or replaced, pointers to all ungrouped items (including 
cells) in that VM file may be invalidated. The **CellFunctionParameters** 
structure must not move during the call; for this reason, it may not be in an 
ungrouped DB item. Never replace or free a locked cell; if you do, the cell's 
item block will not have its lock count decremented, which will prevent the 
block from being unlocked.

----------
#### CellUnlock()
	void	CellUnlock(
			void *	ptr); /* pointer to anywhere in locked cell */
This routine unlocks the cell pointed to by *ptr*. Note that a cell may be locked 
several times. When all locks on all cells in an item-block have been released, 
the block can be swapped back to the disk.

**Include:** cell.h

**Tips and Tricks:** The DB manager does not keep track of locks on individual items; instead, it 
keeps a count of the total number of locks on all the items in an item-block. 
For this reason, only the segment address of the cell is significant; thus, you 
can pass a pointer to somewhere within (or immediately after) a cell to unlock 
it. This is useful if you have incremented the pointer to the cell.

**Be Sure To:** If you change the cell, dirty it (with CellDirty()) *before* you unlock it.

----------
#### CFatalError()
	void	CFatalError(
			word	code)
This routine generates a fatal error. It stores an error code passed for use by 
the debugger.

----------
#### ChunkArrayAppend()
	void *	ChunkArrayAppend(
			optr	array,			/* optr to chunk array */
			word	elementSize)	/* Size of new element (ignored if 
									 * elements are uniform-sized) */
This routine adds a new element to the end of a chunk array. It automatically 
expands the chunk to make room for the element and updates the 
**ChunkArrayHeader**. It returns a pointer to the new element.

One of the arguments is the size of the new element. This argument is 
significant if the array contains variable-sized elements. If the elements are 
uniform-sized, this argument is ignored. The array is specified with an optr.

**Include:** chunkarr.h

**Be Sure To:** Lock the block on the global heap (if it is not fixed).

**Warnings:** This routine resizes the chunk, which means it can cause heap compaction or 
resizing. Therefore, all existing pointers to within the LMem heap are 
invalidated.

**See Also:** ChunkArrayInsertAt(), ChunkArrayDelete(), ChunkArrayResize()

----------
#### ChunkArrayAppendHandles()
	void *	ChunkArrayAppendHandles(
			MemHandle		mh,		/* Handle of LMem heap's block */
			ChunkHandle		ch,		/* Handle of chunk array */
			word			size)	/* Size of new element (ignored if 
									 * elements are uniform-sized) */
This routine is exactly like **ChunkArrayAppend()**, except that the chunk 
array is specified by its global and local handles instead of by an optr.

**Include:** chunkarr.h

**Be Sure To:** Lock the block on the global heap (if it is not fixed).

**Warnings:** This routine resizes the chunk, which means it can cause heap compaction or 
resizing. Therefore, all existing pointers to within the LMem heap are 
invalidated.

**See Also:** ChunkArrayInsertAt(), ChunkArrayDelete(), ChunkArrayResize()

----------
#### ChunkArrayCreate()
	ChunkHandle	 ChunkArrayCreate(
			MemHandle 	mh,		/* Handle of LMem heap's block */
			word	elementSize,/* Size of each element (or zero if elements are
								 * variable-sized) */
			word	headerSize,	/* Amount of chunk to use for header (or zero for
							 	 * default size) */
			ObjChunkFlags ocf);
This routine sets up a chunk array in the specified LMem heap. The heap 
must have already been initialized normally. The routine allocates a chunk 
and sets up a chunk array in it. It returns the chunk's handle. If it cannot 
create the chunk array, it returns a null handle.

If the chunk array will have uniform-size elements, you must specify the 
element size when you create the chunk array. You will not be able to change 
this. If the array will have variable-sized elements, pass an element size of 
zero.

The chunk array always begins with a **ChunkArrayHeader**. You can 
specify the total header size; this is useful if you want to begin the chunk 
array with a special header containing some extra data. However, the header 
must be large enough to accommodate a **ChunkArrayHeader**, which will 
begin the chunk. If you define a header structure, make sure that its first 
element is a **ChunkArrayHeader**. Only the chunk array code should access 
the actual **ChunkArrayHeader**. If you pass a *headerSize* of zero, the default 
header size will be used (namely, **sizeof(ChunkArrayHeader)**). If you pass 
a non-zero *headerSize*, any space between the **ChunkArrayHeader** and the 
heap will be zero-initialized.

To free a chunk array, call **LMemFree()** as you would for any chunk.

**Include:** chunkarr.h

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Warnings:** Results are unpredictable if you pass a non-zero *headerSize* argument which 
is smaller than **sizeof(ChunkArrayHeader)**. Since the routine allocates a 
chunk, it can cause heap compaction or resizing; all pointers to within the 
block are invalidated.

----------
#### ChunkArrayCreateAt()
	ChunkHandle 	ChunkArrayCreateAt(
		optr	array,			/* Create chunk array in this chunk */
		word	elementSize,	/* Size of each element (or zero if elements are
								 * variable-sized) */
		word	headerSize,		/* Amount of chunk to use for header (or zero for
								 * default size) */
		ObjChunkFlags ocf);
This routine is exactly like **ChunkArrayCreate()**, except that you specify 
the chunk which will be made into a chunk array. The chunk is specified with 
an optr. Note that any data already existing in the chunk will be overwritten.

**Warnings:** The chunk may be resized, which invalidates all pointers to within the LMem 
heap.

**Include:** chunkarr.h

----------
#### ChunkArrayCreateAtHandles()
	ChunkHandle 	ChunkArrayCreateAtHandles(
			MemHandle 		mh,
			ChunkHandle 	ch,
			word			elementSize,
			word			headerSize,
			ObjChunkFlags	ocf);
This routine is exactly like **ChunkArrayCreate()**, except that the chunk is 
specified with its global and chunk handles instead of with an optr.

**Tips and Tricks:** If you pass a null chunk handle, a new chunk will be allocated.

**Warnings:** The chunk may be resized, which would invalidate all pointers to within the 
LMem heap.

**Include:** chunkarr.h

----------
#### ChunkArrayDelete()
	void	ChunkArrayDelete(
			optr	array,		/* optr to chunk array */
			void *	element);	/* Address of element to delete */
This routine deletes an element from a chunk array. It is passed the address 
of that element, as well as the optr of the array.

Since the chunk is being decreased in size, the routine is guaranteed not to 
cause heap compaction or resizing.

**Include:** chunkarr.h

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Tips and Tricks:** Only the chunk handle portion of the optr is significant; the memory block is 
determined from the pointer to the element.

**Warnings:** The addresses of all elements after the deleted one will change. No other 
addresses in the block will be affected. If the address passed is not the 
address of an element in the array, results are undefined.

**See Also:** ChunkArrayAppend(), ChunkArrayInsertAt(), ChunkArrayResize(), 
ChunkArrayZero()

----------
#### ChunkArrayDeleteHandle()
	void	ChunkArrayDeleteHandle(
			ChunkHandle		ch,		/* Handle of chunk array */
			void *			el);	/* Address of element to delete */
This routine is exactly like **ChunkArrayDelete()**, except that the chunk 
array is specified with its chunk handle instead of with an optr. The global 
memory handle is not needed, as the memory block is implicit in the pointer 
to the element.

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Include:** chunkarr.h

----------
#### ChunkArrayDeleteRange()
	void	ChunkArrayDeleteRange(
			optr	array,			/* optr to chunk array */
			word	firstElement,	/* index of first element to delete */
			word	count);			/* # of elements to delete (-1 to delete to 
									 * end of array) */
This routine deletes several consecutive elements from a chunk array. The 
routine is passed the optr of the chunk array, the index of the first element to 
delete, and the number of elements to delete. The routine is guaranteed not 
to cause heap compaction or resizing; thus, pointers to other elements in the 
array will remain valid.

----------
#### ChunkArrayElementResize()
	void	ChunkArrayElementResize(
			optr	array,		/* optr to chunk array */
			word	element,	/* Index of element to resize */
			word	newSize);	/* New size of element, in bytes */

This routine resizes an element in a chunk array. The chunk array must have 
variable-sized elements. The routine is passed an optr to the chunk array 
(which must be locked on the global heap), as well as the index of the element 
to resize and the new size (in bytes). It does not return anything.

If the new size is larger than the old, null bytes will be added to the end of 
the element. If the new size is smaller than the old, bytes will be removed 
from the end to truncate the element to the new size.

**Warnings:** If the element is resized larger, the chunk array may move within the LMem 
heap, and the heap itself may move on the global heap; thus, all pointers to 
within the LMem heap will be invalidated. 

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Include:** chunkarr.h

----------
#### ChunkArrayElementResizeHandles()
	void	ChunkArrayElementResizeHandles(
			Memhandle		mh,		/* Global handle of LMem heap */
			ChunkHandle		ch,		/* Chunk handle of chunk array */
			word			el,		/* Index of element to resize */
			word			ns);	/* New size of element, in bytes */
This routine is exactly like **ChunkArrayElementResize()** except that the 
chunk array is specified with its global and chunk handles, instead of with 
its optr.

**Warnings:** If the element is resized to larger than the old, the chunk array may move 
within the LMem heap, and the heap itself may move on the global heap; 
thus, all pointers to within the LMem heap will be invalidated. 

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Include:** chunkarr.h

----------
#### ChunkArrayElementToPtr()
	void *	ChunkArrayElementToPtr(
			optr		array,			/* optr to chunk array */
			word		elementNumber,	/* Element to get address of */
			void *		elementSize);	/* Write element's size here */
This routine translates the index of an element into the element's address. 
The routine is passed an optr to the chunk array, the index of the element in 
question, and a pointer to a word-sized variable. It returns a pointer to the 
element. If the elements in the array are of variable size, it writes the size of 
the element to the variable pointed to by the elementSize pointer. If the 
elements are of uniform size, it does not do this.

If the array index is out of bounds, the routine returns a pointer to the last 
element in the array. The routine will also do this if you pass the constant 
CA_LAST_ELEMENT.

**Include:** chunkarr.h

**Tips and Tricks:** If you are not interested in the element's size, pass a null pointer as the third 
argument.

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**Warnings:** The error-checking version fatal-errors if passed the index 
CA_NULL_ELEMENT (i.e. 0xffff, or -1).

----------
#### ChunkArrayElementToPtrHandles()
	void *	ChunkArrayElementToPtrHandles(
			Memhandle	mh,				/* Handle of LMem heap's block */
			ChunkHandle	chunk,			/* Handle of chunk array */
			word		elementNumber,	/* Element to get address of */
			void *		elementSize);	/* Write element's size here */
This routine is just like **ChunkArrayElementToPtr()**, except that the 
chunk array is specified with its global and chunk handles, instead of with 
an optr.

**Include:** chunkarr.h

**Tips and Tricks:** If you are not interested in the element's size, pass a null pointer as the 
fourth argument.

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**See Also:** ChunkArrayPtrToElement()

**Warnings:** The error-checking version fatal-errors if passed the index 
CA_NULL_ELEMENT (i.e. 0xffff, or -1).

----------
#### ChunkArrayEnum()
	Boolean	ChunkArrayEnum(
			optr		array,		/* optr to chunk array */
			void*		enumData,	/* This is passed to callback routine */
			Boolean _pascal (*callback) (void *element, void *enumData));
				/* callback called for each element; returns TRUE to stop */
This routine lets you apply a procedure to every element in a chunk array. 
The routine is passed an optr to the callback routine, a pointer (which is 
passed to the callback routine), and a pointer to a Boolean callback routine. 
The callback routine, in turn, is called once for each element in the array, and 
is passed two arguments: a pointer to an element and the pointer which was 
passed to **ChunkArrayEnum()**. If the callback routine ever returns true for 
an element, **ChunkArrayEnum** will stop with that element and return 
true. If it enumerates every element without being aborted, it returns false.

The callback routine can call such routines as **ChunkArrayAppend()**, 
**ChunkArrayInsertAt()**, and **ChunkArrayDelete()**. 
**ChunkArrayEnum()** will see to it that every element is enumerated exactly 
once. The callback routine can even make a nested call to 
**ChunkArrayEnum()**; the nested call will be completed for every element 
before the outer call goes to the next element. The callback routine should be 
declared _pascal.

**Include:** chunkarr.h

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

----------
#### ChunkArrayEnumHandles()
	Boolean	ChunkArrayEnumHandles(
			MemHandle		mh,			/* Handle of LMem heap's block */
			ChunkHandle		ch,			/* Handle of chunk array */
			void *			enumData,	/* Buffer used by callback routine */
			Boolean _pascal (*callback) (void *element, void *enumData));
				/* callback called for each element; returns TRUE to stop */
This routine is exactly like **ChunkArrayEnum()**, except that the chunk 
array is specified by its global and chunk handles (instead of with an optr). 

**Include:** chunkarr.h

----------
#### ChunkArrayEnumRange()
	Boolean 	ChunkArrayEnumRange(
			optr	array, 			/* optr to chunk array */
			word 	startElement,	/* Start enumeration with this element */
			word	count,			/* Process this many elements */
			void *	enumData,		/* This is passed to the callback routine */
			Boolean _pascal (*callback) (void *element, void *enumData));
				/* Return TRUE to halt enumeration */
This routine is exactly like **ChunkArrayEnum()** (described above), except 
that it acts on a limited portion of the array. It is passed two additional 
arguments: the index of the starting element, and the number of elements to 
process. It will begin the enumeration with the element specified (remember, 
the first element in a chunk array has an index of zero). If the count passed 
would take the enumeration past the end of the array, 
**ChunkArrayEnumRange()** will automatically stop with the last element. 
You can instruct **ChunkArrayEnumRange()** to process all elements by 
passing a *count* of CA_LAST_ELEMENT.

**Include:** chunkarr.h

**Warnings:** The start element must be within the bounds of the array.

**See Also:** ChunkArrayEnum()

----------
#### ChunkArrayEnumRangeHandles()
	Boolean 	ChunkArrayEnumRangeHandles(
			MemHandle 	mh,			/* Handle of LMem heap's block */
			ChunkHandle ch,			/* Handle of chunk array */
			word 		startElement,	/* Start enumeration with this element */
			word		count,		/* Process this many elements */
			void *		enumData,	/* This is passed to the callback routine */
			Boolean _pascal (*callback) (void *element, void *enumData));
				/* Return TRUE to halt enumeration */
This routine is exactly like **ChunkArrayEnumRange()**, except that the 
chunk array is specified by its global and chunk handles (instead of with an 
optr).

----------
#### ChunkArrayGetCount()
	word	ChunkArrayGetCount(
			optr	array);				/* optr of chunk array */
This routine returns the number of elements in the specified chunk array.

**Include:** chunkarr.h

**Tips and Tricks:** It is usually faster to examine the *CAH_count* field of the 
**ChunkArrayHeader**. This field is the first word of the 
**ChunkArrayHeader** (and therefore of the chunk). It contains the number 
of elements in the chunk array.

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed).

**See Also:** ChunkArrayHeader

----------
#### ChunkArrayGetCountHandles()
	word	ChunkArrayGetCountHandles(
			MemHandle		mh,		/* Handle of LMem heap's block */
			ChunkHandle		ch);	/* Handle of chunk array */
This routine is just like **ChunkArrayGetCount()**, except that the chunk 
array is specified by its global and local handles (instead of with an optr).

**Include:** chunkarr.h

----------
#### ChunkArrayGetElement()
	void	ChunkArrayGetElement(
			optr	array,			/* optr to chunk array */
			word	elementNumber,	/* Index of element to copy */
			void *	buffer);		/* Address to copy element to */
This routine copies an element in a chunk array into the passed buffer. It is 
your responsibility to make sure the buffer is large enough to hold the 
element.

**Include:** chunkarr.h

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed). Make sure 
the buffer is large enough to hold the element.

**See Also:** ChunkArrayPtrToElement(), ChunkArrayElementToPtr()

----------
#### ChunkArrayGetElementHandles()
	void	ChunkArrayGetElementHandles(
			Memhandle		mh,				/* Handle of LMem heap's block */
			ChunkHandle		array,			/* Handle of chunk array */
			word			elementNumber,	/* Index of element to copy */
			void *			buffer);		/* Address to copy element to */
This routine is just like **ChunkArrayGetElement()**, except that the chunk 
array is specified by its global and chunk handles (instead of with an optr).

**Include:** chunkarr.h

**Be Sure To:** Lock the LMem heap's block on the global heap (unless it is fixed). Make sure 
the buffer is large enough to hold the element.

**See Also:** ChunkArrayPtrToElement(), ChunkArrayElementToPtr()

----------
#### ChunkArrayInsertAt()
	void *	ChunkArrayInsertAt(
			optr	array,			/* Handle of chunk array */
			void *	insertPointer,	/* Address at which to insert
									 * element */
			word	elementSize);	/* Size of new element (ignored
									 * if elements are uniform-sized) */
This routine inserts a new element in a chunk array. You specify the location 
by passing a pointer to an element. A new element will be allocated at that 
location; thus, the element which was pointed to will be shifted, so it ends up 
immediately after the new element. The new element will be zero-initialized.

The routine is passed three arguments: the optr of the array, the address 
where the new element should be inserted, and the size of the new element. 
(If the array is of uniform-size elements, the size argument will be ignored.) 

**Include:** chunkarr.h

**Tips and Tricks:** Only the chunk-handle portion of the optr is significant; the memory block is 
implicit in the pointer to the element.

**Be Sure To:** Lock the block on the global heap (if it is not fixed).

**Warnings:** If the address passed is not the address of an element already in the chunk 
array, results are undefined. The routine may cause heap compaction or 
resizing; all pointers within the block are invalidated.

**See Also:** ChunkArrayAppend(), ChunkArrayDelete(), ChunkArrayResize()

----------
#### ChunkArrayInsertAtHandle()
	void *	ChunkArrayInsertAtHandle(
			ChunkHandle	chunk,			/* Handle of chunk array */
			void *		insertPointer,	/* Address at which to insert
										 * element */
			word		elementSize);	/* Size of new element (ignored
										 * if elements are uniform-sized) */
This routine is just like **ChunkArrayInsertAt()**, except that the chunk 
array is specified by its chunk handle. (The global block is implicit in the 
pointer passed.)

**Include:** chunkarr.h

----------
#### ChunkArrayPtrToElement()
	word	ChunkArrayPtrToElement(
			optr	array,		/* Handle of chunk array */
			void *	element);	/* Address of element */
This routine takes the address of an element in a chunk array, as well as an 
optr to the array. It returns the element's zero-based index.

**Include:** chunkarr.h

**Tips and Tricks:** Only the chunk-handle portion of the optr is significant; the memory block is 
implicit in the pointer to the element.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** If the address passed is not the address of the beginning of an element, 
results are unpredictable.

**See Also:** ChunkArrayElementToPtr()

----------
#### ChunkArrayPtrToElementHandle()
	word 	ChunkArrayPtrToElementHandle(
			ChunkHandle		array,		/* chunk handle of chunk array */
			void *			element);	/* Pointer to element to delete */
This routine is exactly like **ChunkArrayPtrToElement()**, except that the 
chunk array is indicated by its chunk handle. (The global block is implicit in 
the pointer passed.)

----------
#### ChunkArraySort()
	void	ChunkArraySort(
			optr		array,				/* optr to chunk array */
			word		valueForCallback,	/* Passed to callback routine */
			sword _pascal (*callback) (void *el1, void * el2, 
							 word valueForCallback))
					/* Sign of return value decides order of elements */
This is a general-purpose sort routine for chunk arrays. It does a modified 
Quicksort on the array, using an insertion sort for subarrays below a certain 
size; this gives performance of 'O('nlog'n)

The sort routine does not compare elements. Rather, it calls a comparison 
callback routine passed in the *callback* parameter. Whenever it needs to 
compare two elements, it calls the callback routine, passing the addresses of 
the elements and the *valueForCallback* word which was passed to 
**ChunkArraySort()**. The callback routine should be declared _pascal. The 
callback routine's return value determines which element will come first in 
the sorted array:

+ If element *el1* ought to come before *el2* in the sorted array, the callback 
routine should return a negative integer.

+ If element *el1* ought to come after *el2* in the sorted array, the callback 
routine should return a positive integer.

+ If it doesn't matter whether *el1* comes before or after *el2* in the sorted 
array, the callback routine should return zero.

**Include:** chunkarr.h

**Tips and Tricks:** You may need to sort an array based on different criteria at different times. 
The simplest way to do this is to write one general-purpose callback routine 
and have the *valueForCallback* word determine how the sort is done. For 
example, the same callback routine could sort the array in ascending or 
descending order, depending on the *valueForCallback*.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** Do not have the callback routine do anything which might invalidate 
pointers to the array (such as allocate a new chunk or element).

**See Also:** ArrayQuickSort()

----------
#### ChunkArraySortHandles()
	void	ChunkArraySortHandles(
			MemHandle		memHandle,			/* Handle of LMem heap's block */
			ChunkHandle		chunkHandle,		/* Handle chunk array */
			word			valueForCallback,	/* Passed to callback routine */
			sword _pascal(*callback)(void *el1, void * el2, word valueForCallback)
				/* Sign of return value decides order of elements */

This routine is exactly like **ChunkArraySort()** above, except that the chunk 
array is specified by its global and chunk handles (instead of by an optr).

**Include:** chunkarr.h

----------
#### ChunkArrayZero()
	void	ChunkArrayZero(
			optr	array);		/* optr to chunk array */
This routine destroys all the elements in an array. It does not affect the 
extra-space area between the **ChunkArrayHeader** and the elements. It is 
guaranteed not to cause heap compaction or resizing; thus, pointers to other 
chunks remain valid.

**Include:** chunkarr.h

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**See Also:** ChunkArrayDelete()

----------
#### ChunkArrayZeroHandles()
	void	ChunkArrayZeroHandles(
			MemHandle		mh		/* Global handle of LMem heap */
			ChunkHandle		ch);	/* Chunk handle of chunk array */
This routine is exactly like **ChunkArrayZero()** above, except that the 
chunk array is specified by its global and chunk handles (instead of by an 
optr).

**Include:** chunkarr.h

----------
#### ClipboardAbortQuickTransfer()
	void	ClipboardAbortQuickTransfer(void);
This routine cancels a quick-transfer operation in progress. It is typically 
used when an object involved in a quick-transfer is shutting down or when 
an error occurs in a quick-transfer. This routine is usually used only by the 
object or Process which initiated the quick-transfer.

**Include:** clipbrd.goh

----------
#### ClipboardAddToNotificationList()
	void	ClipboardAddToNotificationList(
			optr	notificationOD);
This routine registers the passed object or process for quick-transfer 
notification. This routine is typically called from within an object's 
MSG_META_INITIALIZE handler or within a Process object's 
MSG_GEN_PROCESS_OPEN_APPLICATION handler. Pass the optr of the 
object or the geode handle if the Process object should be registered.

**Include:** clipbrd.goh

**See Also:** ClipboardRemoveFromNotificationList()

----------
#### ClipboardClearQuickTransferNotification()
	void	ClipboardClearQuickTransferNotification(
			optr	notificationOD);
This routine removes an object or process from quick-transfer notification. It 
is typically used in the object's MSG_META_DETACH handler or in the Process 
object's MSG_GEN_PROCESS_CLOSE_APPLICATION to ensure that it is not 
notified after it has already detached.

Pass the optr of the object specified to receive notification in 
**ClipboardStartQuickTransfer()** (or the geode handle if a process).

Note that an object may also want to check if a quick-transfer is in progress 
when detaching and possibly abort it if there is one.

**See Also:** **clipbrd.goh**

----------
#### ClipboardDoneWithItem()
	void	ClipboardDoneWithItem(
			TransferBlockID header);
This routine is called when an object or Process is done using a transfer item. 
It relinquishes exclusive access to the item's transfer VM file after the caller 
had previously called **ClipboardQueryItem()**.

**Include:** clipbrd.goh

----------
#### ClipboardEndQuickTransfer()
	void	ClipboardEndQuickTransfer(
			ClipboardQuickNotifyFlags 		flags);
This routine ends a quick-transfer operation by resetting the pointer image, 
clearing any quick-transfer region, clearing the quick-transfer item, and 
sending out any needed notification of the completed transfer.

Pass this routine a record of **ClipboardQuickNotifyFlags**. Pass the value 
CQNF_MOVE if the operation was completed and was a move; pass 
CQNF_COPY if the operation was completed and was a copy. If the operation 
could not be completed (e.g. incompatible data types), pass 
CQNF_NO_OPERATION or CQNF_ERROR.

The notification sent out by the UI will be in the form of the message 
MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED. This 
message notifies the originator of the transfer item of the type of operation; 
the originator can then respond if necessary.

**Include:** clipbrd.goh

----------
#### ClipboardEnumItemFormats()
	word	ClipboardEnumItemFormats(
			TransferBlockID 		header,
			word 					maxNumFormats,
			ClipboardFormatID *		buffer);
This routine returns a list of all the formats supported by the current 
transfer item. To see whether a particular format is supported, you can use 
**ClipboardTestItemFormat()** instead.

Pass this routine the following:

*header* - The transfer item header as returned by 
**ClipboardQueryItem()**.

*maxNumFormats* - The maximum number of formats that should be returned. You 
should set your return buffer (see below) large enough to 
support this size.

*buffer* - A pointer to a locked or fixed buffer into which the formats will 
be copied. Upon return, the buffer will contain the proper 
number of **ClipboardFormatID** structures, one for each 
format available. This buffer should be at least large enough to 
support the number of formats requested in *maxNumFormats*.

The word return value is the total number of formats returned. This number 
will be equal to or less than the number passed in *maxNumFormats*. The 
routine will also return the passed buffer filled with that number of 
**ClipboardFormatID** structures.

**Include:** clipbrd.goh

**See Also:** ClipboardTestItemFormat()

----------
#### ClipboardGetClipboardFile()
	VMFileHandle ClipboardGetClipboardFile(void);
This routine returns the VM file handle of the current default transfer VM 
file.

**Include:** clipbrd.goh

----------
#### ClipboardGetItemInfo()
	optr	ClipboardGetItemInfo(
			TransferBlockID header);
This routine returns the source identifier (*CIH_sourceID*) of the current 
transfer item. Pass the transfer item's header returned by 
**ClipboardQueryItem()**. 

**Include:** clipbrd.goh

----------
#### ClipboardGetNormalItemInfo()
	TransferBlockID ClipboardGetNormalItemInfo(void);
This routine returns information about the normal transfer item. It returns 
a **TransferBlockID** dword which contains the VM file handle of the transfer 
file and the VM block handle of the transfer item's header block.

To extract the file handle from the return value, use the macro 
**FileFromTransferBlockID()**. To extract the block handle, use the macro 
**BlockFromTransferBlockID()**.

**Include:** clipbrd.goh

----------
#### ClipboardGetQuickItemInfo()
	TransferBlockID ClipboardGetQuickItemInfo(void);
This routine returns information about the quick-transfer transfer item. It 
returns a **TransferBlockID** dword which contains the VM file handle of the 
transfer file and the VM block handle of the transfer item's header block.

To extract the file handle from the return value, use the macro 
**FileFromTransferBlockID()**. To extract the block handle, use the macro 
**BlockFromTransferBlockID()**.

**Include:** clipbrd.goh

----------
#### ClipboardGetQuickTransferStatus()
	Boolean	ClipboardGetQuickTransferStatus(void);
This routine returns true if a quick-transfer operation is in progress, false 
otherwise. It is often called when objects or Processes are shutting down in 
order to abort any quick-transfers originated by the caller.

**Include:** clipbrd.goh

----------
#### ClipboardGetUndoItemInfo()
	TransferBlockID ClipboardGetUndoItemInfo(void);
This routine returns information about the undo transfer item. It returns a 
**TransferBlockID** dword which contains the VM file handle of the transfer 
file and the VM block handle of the transfer item's header block.

To extract the file handle from the return value, use the macro 
**FileFromTransferBlockID()**. To extract the block handle, use the macro 
**BlockFromTransferBlockID()**.

**Include:** clipbrd.goh

----------
#### ClipboardQueryItem()
	void	ClipboardQueryItem(
			ClipboardItemFlags 		flags,
			ClipboardQueryArgs *	retValues);
This routine locks the transfer item for the caller's exclusive access and 
returns information about the current transfer item. You should call this 
routine when beginning any paste or clipboard query operation. For 
operations in which you will change the clipboard's contents, you should 
instead use the routine **ClipboardRegisterItem()**.

Pass the following values:

*flags* - A record of **ClipboardItemFlags** indicating the transfer item 
you want to query. Use CIF_QUICK to get information on the 
quick transfer item, and pass zero (or TIF_NORMAL) to get 
information on the normal transfer item.

*retValues* - A pointer to an empty **ClipboardQueryArgs** structure into 
which return information about the transfer item will be 
passed. This structure is defined as follows:

	typedef struct {
		word				CQA_numFormats;
		optr				CQA_owner;
		TransferBlockID		CQA_header;
	} ClipboardQueryArgs;

The *CQA_header* field of **ClipboardQueryArgs** is used as a pass value to 
several other clipboard routines. It contains the VM file handle of the transfer 
VM file and the VM block handle of the transfer item's header block. The 
*CQA_owner* field is the optr of the object that originated the transfer item. 
The *CQA_numFormats* field specifies the total number of formats available 
for this transfer item. To see if a particular format is supported by the 
transfer item, call the routine **ClipboardTestItemFormat()**.

**Be Sure To:** You must call **ClipboardDoneWithItem()** when you are done accessing the 
transfer item. This routine relinquishes your exclusive access to the transfer 
VM file.

**Include:** clipbrd.goh

**See Also:** ClipboardRequestItemFormat(), ClipboardDoneWithItem()

----------
#### ClipboardRegisterItem()
	Boolean	ClipboardRegisterItem(
			TransferBlockID		header,
			ClipboardItemFlags	flags);
This routine completes a change to the transfer item. You should use this 
routine whenever copying or cutting something into the clipboard or 
whenever attaching something as the quick-transfer item.

This routine puts the item specified by *header* into the transfer VM file. It 
frees any transfer item that may already be in the file. Pass this routine the 
following:

*header* - Header information for the item, consisting of the transfer VM 
file handle and the VM block handle of the block containing the 
new transfer item. Create the **TransferBlockID** structure 
using the macro **BlockIDFromFileAndBlock()**.

*flags* - A record of **ClipboardItemFlags** indicating whether you're 
registering a clipboard item or a quick-transfer item. The flag 
CIF_QUICK indicates the item is a quick-transfer item; zero (or 
TIF_NORMAL) indicates the item is a normal clipboard item.

**Include:** clipbrd.goh

**See Also:** ClipboardRequestItemFormat()

----------
#### ClipboardRemoveFromNotificationList()
	Boolean	ClipboardRemoveFromNotificationList(
			optr	notificationOD);
This routine removes an object or Process from the clipboard's change 
notification list. It is typically called when the object or Process is being 
detached or destroyed. Pass it the same optr that was added to the 
notification list with **ClipboardAddToNotificationList()**.

This routine returns an error flag: The flag will be *true* if the object could not 
be found in the notification list, *false* if the object was successfully removed 
from the list.

**Include:** clipbrd.goh

**See Also:** ClipboardAddToNotificationList()

----------
#### ClipboardRequestItemFormat()
	void	ClipboardRequestItemFormat(
			ClipboardItemFormatID 		format,
			TransferBlockID 			header,
			ClipboardRequestArgs *		retValue);
This routine returns specific information about a particular transfer item. 
Because some of the passed information must be retrieved with 
**ClipboardQueryItem()**, you must call **ClipboardQueryItem()** before 
calling this routine.

Pass this routine the following:

*format* - The manufacturer ID and format type of the new transfer item 
being put into the transfer VM file. Create the 
**ClipboardItemFormatID** value with the macro 
**FormatIDFromManufacturerAndType()**.

*header* - Header information for the item, consisting of the transfer VM 
file handle and the VM block handle of the block containing the 
new transfer item. Create the **TransferBlockID** structure 
using the macro **BlockIDFromFileAndBlock()** using 
returned information from **ClipboardQueryItem()**.

*retValue* - A pointer to an empty **ClipboardRequestArgs** structure that 
will be filled by the routine. This structure is defined as follows:

	typedef struct {
		VMFileHandle	CRA_file;
		VMChain			CRA_data;
		word			CRA_extra1;
		word			CRA_extra2;
	} ClipboardRequestArgs;

Upon return, the *CRA_file* field will contain the transfer VM file's VM file 
handle and the *CRA_data* field will contain the VM block handle of the 
transfer item's header block. If there is no transfer item, CRA_data will be 
zero.

**Include:** clipbrd.goh

**See Also:** ClipboardRegisterItem(), ClipboardQueryItem()

----------
#### ClipboardSetQuickTransferFeedback()
	void	ClipboardSetQuickTransferFeedback(
			ClipboardQuickTransferFeedback 		cursor,
			UIFunctionsActive 					buttonFlags);
This routine sets the image of the mouse pointer during a quick-transfer 
operation. Use this routine to provide visual feedback to the user during the 
quick-transfer. For example, an object that could not accept the 
quick-transfer item would set the "no operation" cursor while the mouse 
pointer was over its bounds.

Pass the two following values:

*cursor* - A value of **ClipboardQuickTransferFeedback** type 
indicating the type of cursor to set. The possible values are 
listed below.

*buttonFlags* - A record of **UIFunctionsActive** flags. These flags are defined 
in the Input Manager section and deal with user override of the 
move/copy behavior.

The cursor parameter contains a value of 
**ClipboardQuickTransferFeedback**. This is an enumerated type that 
defines the cursor to be set, and it has the following values:  
CQTF_MOVE - This sets the cursor to the specific UI's move cursor.  
CQTF_COPY - This sets the cursor to the specific UI's copy cursor.  
CQTF_CLEAR - This clears the cursor and sets it to the specific UI's modal "no 
operation" cursor.

**Include:** clipbrd.goh

----------
#### ClipboardStartQuickTransfer()
	Boolean	ClipboardStartQuickTransfer(
			ClipboardQuickTransferFlags 		flags,
			ClipboardQuickTransferFeedback		initialCursor,
			word								mouseXPos,
			word								mouseYPos,
			ClipboardQuickTransferRegionInfo *	regionParams,
			optr								notificationOD);
This routine signals the beginning of a quick-transfer operation. Typically, an 
object or process will call this routine in its MSG_META_START_MOVE_COPY 
handler.

Pass it the following parameters:

*flags* - A record of **ClipboardQuickTransferFlags** indicating 
whether an addition graphic region will be attached to the 
cursor and whether the caller wants notification of transfer 
completion. The flags allowed are listed below, after the 
parameter list.

*initialCursor* - The initial cursor to use for visual feedback to the user. It is a 
value of **ClipboardQuickTransferFeedback**, either 
CQTF_MOVE or CQTF_COPY. If -1 is passed in this parameter, 
the initial cursor will be the default no-operation cursor (i.e. 
the transfer source may not also act as the transfer 
destination).

*mouseXPos* - This field is used only if CQTF_USE_REGION is passed in flags. 
It is the horizontal position of the mouse in screen coordinates.

*mouseYPos* - This field is used only if CQTF_USE_REGION is passed in flags. 
It is the vertical position of the mouse in screen coordinates.

*regionParams* - A pointer to a **ClipboardQuickTransferRegionInfo** 
structure defining the graphical region to be attached to the 
cursor during the transfer operation. This structure is only 
required if CQTF_USE_REGION is passed in flags. It is defined 
below.

*notificationOD* - The optr of the object to be notified upon transfer completion. 
The object specified will receive the notification messages 
MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCL
UDED and MSG_-_FEEDBACK.

The allowed ClipboardQuickTransferFlags are listed below:  
CQTF_COPY_ONLY - Source supports copying only (not cutting).  
CQTF_USE_REGION - Source has passed the definition of a graphical region which 
will be attached to the tail of the quick-transfer cursor.  
CQTF_NOTIFICATION - Source requires notification of completion of the transfer in 
order to cut original data or provide other feedback.

If a graphical region is to be attached to the quick-transfer cursor, you must 
pass a pointer to a **ClipboardQuickTransferRegionInfo** in the 
*regionParams* parameter. This structure is defined below.

	typedef struct {
		word	CQTRI_paramAX;
		word	CQTRI_paramBX;
		word	CQTRI_paramCX;
		word	CQTRI_paramDX;
		Point	CQTRI_regionPos;
		dword	CQTRI_strategy;
		dword	CQTRI_region;
	} ClipboardQuickTransferRegionInfo;

This structure is passed on the stack to the routine. The first four fields 
represent the region's definition parameters. *CQTRI_regionPos* is a Point 
structure indicating where (in screen coordinates) the region is to be located. 
*CQTRI_strategy* is a pointer to the region strategy routine. *CQTRI_strategy* 
should be a video driver strategy. To find out the strategy of the video driver 
associated with your window, send your object a MSG_VIS_VUP_QUERY with 
VUQ_VIDEO_DRIVER. Pass the handle thus gained to **GeodeInfoDriver()**, 
which will return the strategy.

This routine returns an error flag: If a quick-transfer is already in progress, 
the return will be *true*. If the quick-transfer is successfully begun, the error 
flag will be *false*.

**Include:** clipbrd.goh

----------
#### ClipboardTestItemFormat()
	Boolean	ClipboardTestItemFormat(
			TransferBlockID		header,
			ClipboardFormatID 	format);
This routine tests whether the given format is supported by the specified 
transfer item. It returns *true* if the format is supported, *false* if the format is 
not supported. Pass the following values:

*header* - A **TransferBlockID** specifying the VM file handle and VM 
block handle of the transfer item to be checked. This is 
returned by the routines **ClipboardGetNormalItemInfo()**, 
**ClipboardGetQuickItemInfo()**, 
**ClipboardGetUndoItemInfo()**, and 
**ClipboardQueryItem()**. Most often the proper routine to use 
is **ClipboardQueryItem()**.

*format* - A **ClipboardFormatID** specifying the type and manufacturer 
ID of the format to be checked. It is most appropriate to create 
this parameter from its individual parts using the macro 
**FormatIDFromManufacturerAndType()**.

**Include:** clipbrd.goh

----------
#### ClipboardUnregisterItem()
	void	ClipboardUnregisterItem(
			optr	owner);
This routine restores the transfer item to what it was before the last 
**ClipboardRegisterItem()**. Pass it the optr of the caller.

Only the object that last registered a transfer item is allowed to unregister 
it. If the transfer item is owned by a different object, or if there is no transfer 
item, nothing will be done. If the transfer item is owned by the caller, the 
transfer item will be unregistered and the clipboard will be restored to its 
previous state.

**Include:** clipbrd.goh

----------
#### ConstructOptr()
	optr	ConstructOptr(
			Handle 		han,
			ChunkHandle 		ch);
This macro constructs an optr type from the given handle (typically a 
MemHandle) and chunk handle.

**See Also:** HandleToOptr(), OptrToHandle(), OptrToChunk()

----------
#### DBAlloc()
	DBItem	DBAlloc(
			VMFileHandle	file,
			DBGroup			group,
			word			size);
This routine allocates an item in the specified file and group. It is passed the 
handles for the file and group which will contain the new item. It returns the 
new item's item-handle.

**Warnings:** All pointers to items in the group may be invalidated.

**Include:** dbase.h

**See Also:** DBAllocUngrouped()

----------
#### DBAllocUngrouped()
	DBGroupAndItem 	DBAllocUngrouped(
			VMFileHandle	file,			
			word			size);
This routine allocates an ungrouped item in the specified file. It is passed the 
handle of the file which will contain the new item. It returns the item's 
**DBGroupAndItem** value.

**Warnings:** All pointers to ungrouped items may be invalidated.

**Include:** dbase.h

**See Also:** DBAlloc()

----------
#### DBCombineGroupAndItem()
	DBGroupAndItem 	DBCombineGroupAndItem(
			DBGroup 	group,
			DBItem 		item);

This macro combines group and item handles into a dword-sized 
**DBGroupAndItem** value.

**Include:** dbase.h

**See Also:** DBGroupFromGroupAndItem(), DBItemFromGroupAndItem()

----------
#### DBCopyDBItem()
	DBItem 	DBCopyDBItem(
			VMFileHandle	srcFile,
			DBGroup			srcGroup,
			DBItem			srcItem,
			VMFileHandle	destFile,
			DBGroup			destGroup);
This routine makes a duplicate of a DB item in the specified DB file and group. 
It is passed the file handle, group handle, and item handle of the source item, 
as well as the file handle and group handle of the destination group. It makes 
a copy of the DB item and returns its **DBItem** handle.

**Warnings:** All pointers to items in the destination group may be invalidated.

**Include:** dbase.h

**See Also:** VMCopyVMChain()

----------
#### DBCopyDBItemUngrouped()
	DBGroupAndItem 	DBCopyDBItemUngrouped(
			VMFileHandle		srcFile, 
			DBGroupAndItem		srcID,		/* source item */
			VMFileHandle		destFile); 
This routine makes a duplicate of a specified DB item. It is passed the file 
handle and **DBGroupAndItem** value specifying the source item, and the file 
handle of the destination file. It allocates the item as an ungrouped item in 
the specified file and returns its **DBGroupAndItem** value.

**Tips and Tricks:** If the source item is not ungrouped, you can combine the group and item 
handles into a **DBGroupAndItem** value by calling the macro 
**DBCombineGroupAndItem()**.

**Warnings:** All pointers to ungrouped items in the destination file may be invalidated.

**Include:** dbase.h

**See Also:** VMCopyVMChain()

----------
#### DBDeleteAt()
	void	DBDeleteAt(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item,
			word			deleteOffset,
			word			deleteCount);
This routine deletes a sequence of bytes from within an item. It does not 
invalidate pointers to other items. The routine is passed the file, group, and 
item handles specifying the item, as well as an offset within the item and a 
number of bytes to delete. It will delete the specified number of bytes from 
within the item, starting with the byte at the specified offset.

**Include:** dbase.h

----------
#### DBDeleteAtUngrouped()
	void	DBDeleteAtUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id,
			word				deleteOffset,
			word				deleteCount);
This routine is just like **DBDeleteAt()**, except it is passed a 
**DBGroupAndItem** value instead of separate group and item handles. It 
does not invalidate pointers to other items.

**Include:** dbase.h

----------
#### DBDeref()
	void *	DBDeref(
			optr		*ref);

This routine is passed an optr to a locked DB item. The routine returns the 
address of the item.

**Warnings:** The optr becomes invalid when the DB item is unlocked.

**Include:** dbase.h

----------
#### DBDirty()
	void	DBUnlock(
			const void *		ptr);
This routine marks a DB item as dirty; this insures that the VM manager will 
copy its item-block back to the disk before freeing its memory. The routine is 
passed a pointer to anywhere within the item.

**Tips and Tricks:** All the items in an item block are marked dirty at once; thus, you can call this 
routine just once for several items in the same item block. Only the segment 
portion of the pointer is significant; thus, you can pass a pointer to anywhere 
in the item. This is useful if you have incremented the pointer to the item.

**Include:** dbase.h

----------
#### DBFree()
	void	DBFree(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item);
This routine frees the specified item. It does not invalidate pointers to other 
items in the group. It is passed the file, group, and item handles specifying 
the item; it does not return anything.

**Never Use Situations:** Never call **DBFree()** on a locked item. If you do, the item-block's lock count 
will not be decremented, which will prevent the item block from ever being 
properly unlocked.

**Include:** dbase.h

**See Also:** DBFreeUngrouped()

----------
#### DBFreeUngrouped()
	void	DBFreeUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id);
This routine frees the specified item. It does not invalidate pointers to other 
ungrouped items. It is passed the file handle and **DBGroupAndItem** value 
specifying the item; it does not return anything.

**Never Use Situations:** Never call **DBFreeUngrouped()** on a locked item. If you do, the 
item-block's lock count will not be decremented, which will prevent the item 
block from ever being properly unlocked.

**Include:** dbase.h

**See Also:** DBFree()

----------
#### DBGetMap()
	DBGroupAndItem 	DBGetmap(
			VMFileHandle		file);
This routine returns the **DBGroupAndItem** structure for the passed file's 
map item. If there is no map item, it returns a null handle.

**Include:** dbase.h

**See Also:** DBSetMap(), DBLockMap()

----------
#### DBGroupAlloc()
	DBGroup	DBGroupAlloc(
			VMFileHandle		file);
This routine allocates a new DB group in the specified file and returns its 
handle. If the group cannot be allocated, **DBGroupAlloc()** returns a null 
handle.

**Include:** dbase.h

----------
#### DBGroupFree()
	void	DBGroupFree(
			VMFileHandle		file,
			DBGroup		group);
This routine frees the specified group. This deletes all items and item-blocks 
associated with the group. It is passed the file and group handle specifying 
the group. Note that you can free a group even if some of its items are locked; 
those locked items will also be freed.

**Include:** dbase.h

----------
#### DBGroupFromGroupAndItem()
	DBGroup	DBGroupFromGroupAndItem(
			DBGroupAndItem		id);
This macro returns the **DBGroup** portion of a **DBGroupAndItem** value.

**Include:** dbase.h

----------
#### DBInsertAt()
	void	DBInsertAt(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item,
			word			insertOffset,
			word			insertCount);
This routine inserts bytes at a specified offset within a DB item. The bytes are 
zero-initialized. It is passed the file, group, and item handles specifying a DB 
item, as well as an offset within the cell and a number of bytes to insert. It 
inserts the specified number of bytes beginning at the specified offset; the 
data which was at the passed offset will end up immediately after the 
inserted bytes.

**Warnings:** This routine invalidates pointers to other items in the same group.

**Include:** dbase.h

----------
#### DBInsertAtUngrouped()
	void	DBInsertAtUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id,
			word				insertOffset,
			word				insertCount);
This routine is just like **DBInsertAt()**, except it is passed a 
**DBGroupAndItem** value instead of separate group and item handles.

**Warnings:** This routine invalidates pointers to other ungrouped items.

**Include:** dbase.h

----------
#### DBItemFromGroupAndItem()
	DBItem	DBItemFromGroupAndItem(
			DBGroupAndItem		id);
This macro returns the **DBItem** portion of a **DBGroupAndItem** value.

**Include:** dbase.h

----------
#### DBLock()
	void *	DBLock(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item);
This routine locks the specified item and returns a pointer to it. It is passed 
the file, group, and item handles specifying a DB item. If it fails, it returns a 
null pointer.

**Include:** dbase.h

**See Also:** DBLockGetRef(), DBLockUngrouped()

----------
#### DBLockGetRef()
	void *	DBLockGetRef(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item,
			optr *			ref);
This routine is just like **DBLock()**, except that it writes the item's optr to the 
passed address.

**Include:** dbase.h

**Warnings:** The optr is only valid until the DB item is unlocked.

----------
#### DBLockGetRefUngrouped()
	void *	DBLockGetRefUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id,
			optr *				ref);
This routine is the same as **DBLockGetRef()**, except that it is passed a 
**DBGroupAndItem** value.

**Include:** dbase.h

----------
#### DBLockMap()
	void *	DBLockMap(
			VMFileHandle		file);
This routine locks the specified file's map item and returns its address. To 
unlock the map item, call **DBUnlock()** normally.

**Include:** dbase.h

**See Also:** DBUnlock()

----------
#### DBLockUngrouped()
	void *	DBLockUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id);
This routine is the same as **DBLock()**, except that it is passed a 
**DBGroupAndItem** value.

**Include:** dbase.h

----------
#### DBReAlloc()
	void	DBReAlloc(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item,
			word			size);
This routine changes the size of a DB item. It is passed the file, group, and 
item handles specifying the DB item, and a new size for the item (in bytes). 
If the new size is larger than the old, space will be added to the end of the 
item; if the new size is smaller than the old, the item will be truncated to fit.

**Warnings:** If the new size is larger than the old, all pointers to items in the group are 
invalidated. Space added is not zero-initialized.

**Include:** dbase.h

----------
#### DBReAllocUngrouped()
	void	DBReAllocUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id,
			word				size);
This routine is just like **DBReAlloc()**, except it is passed a 
**DBGroupAndItem** value instead of separate group and item handles.

**Warnings:** If the new size is larger than the old, all pointers to ungrouped items are 
invalidated. Space added is not zero-initialized.

**Include:** dbase.h

----------
#### DBSetMap()
	void	DBSetMap(
			VMFileHandle	file,
			DBGroup			group,
			DBItem			item);
This routine sets the DB map item. You can later retrieve a 
**DBGroupAndItem** structure identifying this item by calling **DBGetMap()**. 
The routine is passed the file, group, and item handles specifying the new 
map item; it does not return anything.

**Include:** dbase.h

----------
#### DBSetMapUngrouped()
	void	DBSetMapUngrouped(
			VMFileHandle		file,
			DBGroupAndItem		id);
This routine is just like **DBSetMap()**, except it is passed a 
**DBGroupAndItem** value instead of separate group and item handles.

**Include:** dbase.h

----------
#### DBUnlock()
	void	DBUnlock(
			void *	ptr); /* address of item to unlock */
This routine unlocks the DB item whose address is passed.

**Tips and Tricks:** Only the segment address of the pointer is significant. Thus, you can pass a 
pointer to somewhere within an item (or immediately after it) to unlock it.

**Be Sure To:** If the item has been changed, make sure you call **DBDirty()** *before* you 
unlock it.

**Include:** dbase.h

----------
#### DiskCheckInUse()
	Boolean	DiskCheckInUse(
			DiskHandle		disk);
This routine checks if a registered disk is being used. If a file on that disk is 
open, or if a path on that disk is on some thread's directory stack, the routine 
will return *true* (i.e. non-zero); otherwise it will return *false* (i.e. zero). Note 
that a disk may be "in use" even if it is not currently in any drive.

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file (which is guaranteed to be 
in use).

**Include:** disk.h

----------
#### DiskCheckUnnamed()
	Boolean	DiskCheckUnnamed( 	/* returns true if disk is unnamed */
			DiskHandle		disk);
This routine checks if a registered disk has a permanent name. If the disk 
does not have a name, the routine returns *true* (i.e. non-zero); otherwise it 
returns *false*. Note that GEOS assigns a temporary name to unnamed disks 
when they are registered. To find out a disk's temporary or permanent name, 
call **DiskGetVolumeName()**.

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**See Also:** DiskGetVolumeName()

**Include:** disk.h

----------
#### DiskCheckWritable()
	Boolean	DiskCheckWritable(
			DiskHandle		disk);
**DiskCheckWritable()** checks if a disk is currently writable. It returns *false* 
(i.e. zero) if the disk is not writable, whether by nature (e.g. a CD-ROM disk) 
or because the write-protect tab is on; otherwise it returns *true* (i.e. non-zero). 

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**Include:** disk.h

----------
#### DiskCopy()
	DiskCopyError 	DiskCopy(
			word		source,
			word		dest,
			Boolean _pascal (*callback)
					(DiskCopyCallback		code,
					 DiskHandle				disk,
					 word					param));
This routine copies one disk onto another. The destination disk must be 
formattable to be the same type as the source disk. The first two arguments 
specify the source and destination drive. These drives may or may not be the 
same. If they are different, they must take compatible disks. 

A disk copy requires frequent interaction with the user. For example, the 
copy routine must prompt the user to swap disks when necessary. For this 
reason, **DiskCopy()** is passed a pointer to a callback routine. This routine 
handles all interaction with the user. It must be declared _pascal. Each time 
it is called, it is passed three arguments. The first is a member of the 
**DiskCopyCallback** enumerated type; this argument specifies what the 
callback routine should do. The second argument is a disk handle; its 
significance depends on the value of the **DiskCopyCallback** argument. The 
third argument is a word-sized piece of data whose significance depends on 
the value of the **DiskCopyCallback** argument. Note that either of these 
arguments may be null values, depending on the value of the 
**DiskCopyCallback** argument.

The callback routine can abort the copy by returning *true* (i.e. non-zero); 
otherwise, it should return *false* (i.e. zero). The callback routine is called for 
several situations, identified by the value of **DiskCopyCallback** associated 
with them:

CALLBACK_GET_SOURCE_DISK  
The callback routine should prompt the user to insert the 
source disk into the appropriate drive. The second argument is 
meaningless for this call. The third argument is the number 
identifying the drive; use **DriveGetName()** to find the name 
for this drive.

CALLBACK_GET_DEST_DISK  
The callback routine should prompt the user to insert the 
destination disk into the appropriate drive. The second 
argument is meaningless for this call. The third argument is 
the number identifying the drive.

CALLBACK_REPORT_NUM_SWAPS  
The second argument is meaningless for this call. The third 
argument is the number of disk swaps that will be necessary. 
The callback routine may wish to report this number to the 
user and ask for confirmation.

CALLBACK_VERIFY_DEST_DESTRUCTION  
If the destination disk has already been formatted, the callback 
routine will be called with this parameter. The callback routine 
may wish to remind the user that the destination disk will be 
erased. The second argument is the handle of the destination 
disk; this is useful if, for example, you want to report the disk's 
name. The third argument is the destination drive's number. If 
the callback routine aborts the copy at this time by returning 
non-zero, the destination disk will not be harmed.

CALLBACK_REPORT_FORMAT_PERCT  
If the destination disk needs to be formatted, **DiskCopy()** will 
periodically call the callback routine with this parameter. The 
callback routine may wish to notify the user how the format is 
progressing. In this case, the second argument will be 
meaningless; the third parameter will be the percentage of the 
destination disk which has been formatted. The callback 
routine may wish to notify the user how the format is 
progressing.

CALLBACK_REPORT_COPY_PERCT  
While the copy is taking place, **DiskCopy()** will periodically 
call the callback routine with this parameter. The callback 
routine may wish to notify the user how the copy is progressing. 
In this case, the second parameter will be meaningless; the 
third parameter will be the percentage of the copy which has 
been completed.

If the copy was successful, **DiskCopy()** returns zero. Otherwise, it returns a 
member of the **DiskCopyErrors** enumerated type. That type has the 
following members:

ERR_DISKCOPY_INSUFFICIENT_MEM - This is returned if the routine was unable to get adequate 
memory.

ERR_CANT_COPY_FIXED_DISKS 

ERR_CANT_READ_FROM_SOURCE 

ERR_CANT_WRITE_TO_DEST 

ERR_INCOMPATIBLE_FORMATS - The destination drive must be able to write disks in exactly the 
same format as the source disk. Note that the source and 
destination drives may be the same.

ERR_OPERATION_CANCELLED - This is returned if the callback routine ever returned a 
non-zero value, thus aborting the copy.

ERR_CANT_FORMAT_DEST 

**Include:** disk.h

----------
#### DiskFind()
	DiskHandle 	DiskFind(
			const char *		fname,	/* Null-terminated volume name */
			DiskFindResult *	code);	/* DiskFindResult written here */
This routine returns the handle of the disk with the specified name. If there 
is no registered disk with the specified name, **DiskFind()** returns a null 
handle. Note that while disk handles are unique, volume names are not; 
therefore, there may be several registered disks with identical volume 
names. For this reason, **DiskFind()** writes a member of the 
**DiskFindResults** enumerated type (described below) into the space pointed 
to by the *code* pointer.

**Structures:** **DiskFind()** uses the **DiskFindResults** enumerated type, which has the 
following values:

DFR_UNIQUE - There is exactly one registered disk with the specified name; its 
handle was returned.

DFR_NOT_UNIQUE - There are two or more registered disks with the specified name; 
the handle of an arbitrary one of these disks was returned.

DFR_NOT_FOUND - There are no registered disks with the specified name; a null 
disk handle was returned.

**Tips and Tricks:** If you want to find all the disks with a given volume name, call 
**DiskForEach()** and have the callback routine check each disk's name with 
**DiskGetVolumeName()**.

**See Also:** DiskRegisterDisk()

**Include:** disk.h

----------
#### DiskForEach()
	DiskHandle 	DiskForEach(
			Boolean _pascal (* callback) (DiskHandle disk))
This routine lets you perform an action on every registered disk. It calls the 
callback routine once for each disk, passing the disk's handle. The callback 
routine must be declared _pascal. The callback routine can force an early 
termination by returning *true* (i.e. non-zero). If the callback routine ever 
returns *true*, **DiskForEach()** terminates and returns the handle of the last 
disk passed to the callback routine. If the callback routine examines every 
disk without returning *true*, **DiskForEach()** returns a null handle.

**Tips and Tricks:** **DiskForEach()** is commonly used to look for a specific disk. The callback 
routine checks each disk to see if it's the one; if it finds a match, the callback 
routine simply returns *true*, and **DiskForEach()** returns the disk's handle.
(See Section 17.3.2.2 of the Concepts book)

**Include:** disk.h

----------
#### DiskFormat()
	FormatError 	DiskFormat(
			word 		driveNumber,
			MediaType	media,		/* Format to this size */
			word 		flags,		/* See flags below */
			dword		*goodClusters,		/* These are filled in at the */
			dword		*badClusters,		/* end of the format */
			Boolean _pascal (*callback)	
					(word percentDone));	/* Return true to cancel */
This routine formats a disk to the specified size. When it is finished, it fills in 
the passed pointers to contain the number of good and bad clusters on the 
disk. (To find out the size of each cluster, call **DiskGetVolumeInfo()**.) The 
routine returns a member of the **FormatError** enumerated type (whose 
members are described below).

**DiskFormat()** can be instructed to call a callback routine periodically. This 
allows the application to keep the user informed about how the format is 
progressing. The callback routine is passed either the percent of the disk 
which has been formatted, or the cylinder and head currently being 
formatted. The callback routine must be declared _pascal. The callback 
routine can cancel the format by returning *true* (i.e. non-zero); otherwise, it 
should return *false* (i.e. zero).

The third argument passed is a word-length flag field. Currently, only three 
flags are defined:

DFF_CALLBACK_PERCENT_DONE  
A callback routine should be called periodically. The callback 
routine should be passed a single argument, namely the 
percentage of the format which has been done.

DFF_CALLBACK_CYL_HEAD  
A callback routine should be called periodically. The callback 
routine should be passed a single argument, namely the 
cylinder head being formatted. If both 
DFF_CALLBACK_PERCENT_DONE and 
DFF_CALLBACK_CYL_HEAD are passed, results are undefined. 
If neither flag is set, the callback routine will never be called; a 
null function pointer may be passed.

DFF_FORCE_ERASE  
A "hard format" should be done, i.e. the sectors should be 
rewritten and initialized to zeros. If this flag is not set, 
**DiskFormat()** will do a "soft format" if possible; it will check 
the sectors and write a blank file allocation table, but it will not 
necessarily erase the data from the disk.

**DiskFormat()** returns a member of the **FormatErrors** enumerated type. If 
the format was successful, it will return the constant FMT_DONE (which is 
guaranteed to equal zero). Otherwise, it will return one of the following 
constants:

	FMT_DRIVE_NOT_READY
	FMT_ERROR_WRITING_BOOT
	FMT_ERROR_WRITING_ROOT_DIR
	FMT_ERROR_WRITING_FAT
	FMT_ABORTED
	FMT_SET_VOLUME_NAME_ERROR
	FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
	FMT_BAD_PARTITION_TABLE
	FMT_ERR_NO_PARTITION_FOUND
	FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER
	FMT_ERR_DISK_IS_IN_USE
	FMT_ERR_WRITE_PROTECTED
	FMT_ERR_DRIVE_CANNOT_SUPPORT_GIVEN_FORMAT
	FMT_ERR_INVALID_DRIVE_SPECIFIED
	FMT_ERR_DRIVE_CANNOT_BE_FORMATTED
	FMT_ERR_DISK_UNAVAILABLE

**Include:** disk.h

----------
#### DiskGetDrive()
	word	DiskGetDrive(
			DiskHandle		dh);
This routine returns the drive number associated with a registered disk. 
Note that it will do this even if the drive is no longer usable (e.g. if a network 
drive has been unmapped).

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**See Also:** DiskFind(), DiskRegisterDisk()

**Include:** disk.h

----------
#### DiskGetVolumeFreeSpace()
	dword	DiskGetVolumeFreeSpace( 
			DiskHandle		dh);
This routine returns the amount of free space (measured in bytes) on the 
specified disk. If the disk is, by nature, not writable (e.g. a CD-ROM disk), 
**DiskGetVolumeFreeSpace()** returns zero and clears the thread's error 
value. If an error condition exists, **DiskGetVolumeFreeSpace()** returns 
zero and sets the thread's error value.

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**See Also:** DiskGetVolumeInfo()

**Include:** disk.h

----------
#### DiskGetVolumeInfo()
	word	DiskGetVolumeInfo(  /* Returns 0 if successful */
			DiskHandle		dh,
			DiskInfoStruct	*info);		/* Routine fills this structure */
This routine returns general information about a disk. It returns the 
following four pieces of information:

+ The size of each disk block in bytes. When space is allocated, it is rounded 
up to the nearest whole block.

+ The number of free bytes on the disk.

+ The total number of bytes on the disk; this is the total of free and used 
space.

+ The disk's volume name. If the volume is unnamed, the current 
temporary name will be returned.

The information is written to the passed **DiskInfoStruct**. If an error 
condition occurs, **DiskGetVolumeInfo()** will return the error code and set 
the thread's error value; otherwise, it will return zero.

**Structures:** The routine writes the information to a **DiskInfoStruct**:

	typedef struct {
		word		DIS_blockSize;
		sdword		DIS_freeSpace;
		sdword		DIS_totalSpace;
		VolumeName	DIS_name;
	} DiskInfoStruct;

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**Include:** disk.h

----------
#### DiskGetVolumeName()
	void	DiskGetVolumeName(
			DiskHandle	dh,
			char *		buffer);	/* Must be VOLUME_NAME_LENGTH_ZT bytes
									 * long */

This routine copies the disk's volume name (as a null-terminated string) to 
the passed buffer. If an error occurs, it sets the thread's error value. If the 
volume has no name, the routine returns the current temporary name.

**Warnings:** **DiskGetVolumeName()** does not check the size of the buffer passed. If the 
buffer is not at least VOLUME_NAME_LENGTH_ZT bytes long, the routine 
may write beyond its boundaries.

**Tips and Tricks:** If you pass a standard path constant, this routine will return information 
about the disk containing the main **geos.ini** file.

**See Also:** DiskGetVolumeInfo(), DiskSetVolumeName()

----------
#### DiskRegisterDisk()
	DiskHandle 	DiskRegisterDisk(
				word	driveNumber); 
This routine registers a disk in the specified drive and assigns it a disk 
handle. (The disk handle persists only to the end of the current session of 
GEOS.) If the disk already has a handle, **DiskRegisterDisk()** will return it. 
If the disk does not have a name, GEOS will assign it a temporary name (such 
as "UNNAMED1") and display an alert box telling the user what the 
temporary name is. (This is done only the first time the disk is registered in 
each session.) Note that the temporary name is not written to the disk; thus, 
it persists only until the end of the current session of GEOS.

If this routine returns a disk handle, there's a disk in the drive; if it doesn't, 
there may still be a disk in the drive, but the disk is unformatted.

**Tips and Tricks:** There is no harm in registering the same disk several times. Thus, if you 
want to get the disk handle for the disk in a specific drive, you can simply call 
**DiskRegisterDisk()**.

**See Also:** DiskRegisterDiskSilently()

**Include:** disk.h

----------
#### DiskRegisterDiskSilently()
	DiskHandle 	DiskRegisterDiskSilently(
				word		driveNumber);
This routine is almost identical to **DiskRegisterDisk()** (described 
immediately above). There is only one difference: If GEOS assigns a 
temporary name to the disk, it will not present an alert box to the user.

**See Also:** DiskRegisterDisk()

**Include:** disk.h

----------
#### DiskRestore()
	DiskHandle 	DiskRestore(
			void *		buffer,			/* buffer written by DiskSave() */
			DiskRestoreError _pascal (*callback)	
					(const char 				*driveName,
					 const char 				*diskName,
					 void 						**bufferPtr,
					 DiskRestoreError 			error);
**DiskRestore()** examines a buffer written by **DiskSave()** and returns the 
handle of the disk described by that buffer. If that disk is already registered, 
**DiskRestore()** will simply return its handle. If the disk is not registered and 
is not in the drive, **DiskRestore()** will call the specified callback routine. The 
callback routine should be declared _pascal. The callback routine is passed 
four arguments:

+ A null-terminated string containing the name of the drive for the disk.

+ A null-terminated string containing the disk's volume label.

+ A pointer to a variable in the **DiskRestore()** routine. This variable is 
itself a pointer to the opaque data structure provided by **DiskSave()**. If 
the callback routine takes any action which causes that structure to 
move (e.g. if it causes the global or local heap containing the buffer to be 
shuffled), it should update the pointer in **DiskRestore()**.

+ A member of the **DiskRestoreError** enumerated type. This is the error 
which **DiskRestore()** would have returned if there had not been a 
callback routine. This is usually 
DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK.

The callback routine should prompt the user to insert a disk. If the callback 
routine was successful, it should return DRE_DISK_IN_DRIVE (which is 
guaranteed to be equal to zero). Otherwise, it should return a member of the 
**DiskRestoreError** enumerated type; usually it will return 
DRE_USER_CANCELLED_RESTORE. Note that the callback routine will not 
generally know if the user has inserted a disk; it generally just displays an 
alert box and returns when the user clicks "OK." After the callback routine 
returns, **DiskRestore()** registers the disk and makes sure that it's the 
correct one; if it is not, it calls the callback routine again.

You can pass a null function pointer to **DiskRestore()** instead of providing 
a callback routine. In this case, **DiskRestore()** will fail if the disk has not 
been registered and is not currently in the drive.

**DiskRestore()** returns the handle of the disk. If it fails for any reason, it 
returns a null handle and sets the thread's error value to a member of the 
**DiskReturnError** enumerated type. This type has the following members:

DRE_DISK_IN_DRIVE  
This is returned by the callback routine. This is guaranteed to 
equal zero.

DRE_DRIVE_NO_LONGER_EXISTS  
The disk is associated with a drive which is no longer attached 
to the system.

DRE_REMOVABLE_DRIVE_DOESNT_CONTAIN_DISK  
The disk is unregistered, and it is not currently in the drive 
associated with it. If a callback routine was provided, 
DiskRestore() will call it under these circumstances.

DRE_USER_CANCELLED_RESTORE  
This is returned by the callback routine if the user cancels the 
restore.

DRE_COULDNT_CREATE_NEW_HANDLE  
DiskRestore() was unable to register the disk in the 
appropriate drive because it couldn't create a new disk handle.

DRE_REMOVABLE_DRIVE_IS_BUSY  
The appropriate drive is busy with a time-consuming operation 
(e.g. a disk format).

**See Also:** DiskSave()

**Include:** disk.h

----------
#### DiskSave()
	Boolean	DiskSave(
			DiskHandle	disk,
			void *		buffer,			/* data will be written here */
			word *		bufferSize);	/* Size of buffer (in bytes) */
This routine writes information about a disk in the specified buffer. 
**DiskRestore()** can use this information to return the disk handle, even in 
another session of GEOS. The *bufferSize* argument should point to a word 
containing the size of the buffer (in bytes). If the buffer is large enough, 
**DiskSave()** will write an opaque data structure into the buffer, and change 
the value of **bufferSize* to the actual size of the data structure; any extra 
buffer space can be freed or otherwise used. In this case, **DiskSave()** will 
return *true* (i.e. non-zero). If the buffer was too small, **DiskSave()** will return 
*false* (i.e. zero) and write the size needed into **bufferSize*. Simply call 
**DiskSave()** again with a large enough buffer. If **DiskSave()** failed for some 
other reason, it will return false and set **bufferSize* to zero.

**See Also:** DiskRestore()

**Include:** disk.h

----------
#### DiskSetVolumeName()
	word	DiskSetVolumeName(
			DiskHandle		dh,
			const char *	name);		/* Change the name to this */
This routine changes the disk's volume label. If it is successful, it returns 
zero; otherwise it returns an error code. It also sets or clears the thread's 
error value appropriately. The following error codes may be returned:

ERROR_INVALID_VOLUME  
An invalid disk handle was passed to the routine.

ERROR_ACCESS_DENIED  
For some reason, the volume's name could not be changed. For 
example, the volume might not be writable.

ERROR_DISK_STALE  
The drive containing that disk has been deleted. This usually 
only happens with network drives.

**Include:** disk.h

----------
#### DosExec()
	word	DosExec(
			const char *		prog,
			DiskHandle 			progDisk,
			const char *		arguments,
			const char *		execDir,
			DiskHandle 			execDisk,
			DosExecFlags 		flags);
This routine shuts down GEOS to run a DOS program. It returns an error code 
if an error occurs or zero if successful. Its parameters are listed below:

*prog* - A pointer to a null-terminated character string representing 
the path of the program to be run. If a null string (not a null 
pointer), the system's DOS command interpreter will be run. 
The path string should not contain the drive name.

*progDisk* - A disk handle indicating the disk on which the program to be 
executed sits. If zero is passed, the disk on which GEOS resides 
will be used.

*arguments* - A pointer to a locked or fixed buffer containing arguments to be 
passed to the program being run.

*execDir* - A pointer to a null-terminated character string representing 
the path in which the program is to be run. The string should 
not contain the drive name. If a null pointer is passed and 
*execDisk* is zero, the program will be run in the directory in 
which GEOS was first started.

*execDisk* - The disk handle of the disk containing the directory in execDir.

*flags* - A record of **DosExecFlags** indicating whether the DOS 
program will give a prompt to the user to return to GEOS. The 
possible flags are DEF_PROMPT, DEF_FORCED_SHUTDOWN, 
and DEF_INTERACTIVE. For more information, see the entry 
for **DosExecFlags** in the Data 
Structures reference.

If there was no error, **DosExec()** will return zero. Otherwise it will return one 
of the following error values: ERROR_FILE_NOT_FOUND, 
ERROR_DOS_EXEC_IN_PROGRESS, ERROR_INSUFFICIENT_MEMORY, or 
ERROR_ARGS_TOO_LONG.

**Include:** system.h

----------
#### DriveGetDefaultMedia()
	MediaType 	DriveGetDefaultMedia(
				word		driveNumber);
This routine returns the default media type for the specified drive. It returns 
a member of the **MediaType** enumerated type (described in the Data 
Structures reference). Note that a drive can be used for media types other 
than the default. For example, a high-density 3.5-inch drive will have a 
default media type of MEDIA_1M44, but it can read from, write to, and format 
3.5-inch disks with size MEDIA_720K.

**See Also:** DriveTestMediaSupport()

**Include:** drive.h

----------
#### DriveGetExtStatus()
	word	DriveGetExtStatus(
			word		driveNumber);
This routine is much like **DriveGetStatus()** (described immediately below). 
However, in addition to returning all of the flags set by **DriveGetStatus()**, 
it also sets additional flags in the upper byte of the return value. It returns 
the following additional flags:

DES_LOCAL_ONLY - This flag is set if the device cannot be viewed over a network.

DES_READ_ONLY - This flag is set if the device is read only, i.e. no data can ever be 
written to a volume mounted on it (e.g., a CD-ROM drive).

DES_FORMATTABLE - This flag is set if disks can be formatted in the drive.

DES_ALIAS - This flag is set if the drive is actually an alias for a path on 
another drive.

DES_BUSY - This flag is set if the drive will be busy for an extended period 
of time (e.g., if a disk is being formatted).

If an error condition exists, **DriveGetExtStatus()** returns zero.

**See Also:** DriveGetStatus()

**Include:** drive.h

----------
#### DriveGetName()
	char *	DriveGetName(
			word	driveNumber,	/* Get name of this drive */
			char *	buffer,			/* Write name to this buffer */
			word	bufferSize);	/* Size of buffer (in bytes) */

This routine finds the name of a specified drive. You should use this name 
when prompting the user to take any action regarding this drive (e.g. to 
insert a disk). The routine writes the name, as a null terminated string, to 
the buffer passed. It returns a pointer to the trailing null. If the drive does 
not exist, or the buffer is too small, **DriveGetName()** returns a null pointer.

**Include:** drive.h

----------
#### DriveGetStatus()
	word	DriveGetStatus(
			word	driveNumber);
This routine returns the current status of a drive. The drive is specified by its 
drive number. The routine returns a word of **DriveStatus** flags. These flags 
are listed below:

DS_PRESENT - This flag is set if the physical drive exists, regardless of 
whether the drive contains a disk.

DS_MEDIA_REMOVABLE - This flag is set if the disk can be removed from the drive.

DS_NETWORK - This flag is set if the drive is accessed over a network (or via 
network protocols), which means the drive cannot be formatted 
or copied.

DS_TYPE - This is a mask for the lowest four bits of the field. These bits 
contain a member of the **DriveType** enumerated type.

If an error condition exists, **DriveGetStatus()** returns zero.

**See Also:** DriveGetExtStatus()

**Include:** drive.h

----------
#### DriveTestMediaSupport()
	Boolean	DriveTestMediaSupport(
			word		DriveNumber,			
			MediaType	media);			/* Desired disk size */
This routine checks whether the specified drive can support disks in the 
specified size. It returns *true* (i.e. non-zero) if the drive supports the size.

**See Also:** DriveGetDefaultMedia()

**Include:** drive.h

[Parameters File Keywords](rgp.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Routines E-F](rroute_f.md)