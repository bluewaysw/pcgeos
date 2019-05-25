## 14 Handles

One of the most important data types in GEOS is the handle. There are many 
different types of handles serving many different purposes. However, they all 
have one or both of these traits: they provide an unchanging reference to a 
changing (or moving) thing, and they allow geodes to access and manipulate 
indirectly certain structures which are maintained as internal to the kernel.

This chapter is an overview of the use of handles in GEOS. Before you read 
this chapter, you should be familiar with PC architecture; in particular, you 
should understand the segment:offset scheme of addressing memory 
(discussed in section A.2.1 of Appendix A). This section sketches some basic 
principles of memory usage and data manipulation. These topics are covered 
in greater detail in other chapters in this book, particularly in the chapters 
on Memory Management ("Memory Management," Chapter 15) and Local 
Memory management ("Local Memory," Chapter 16).

### 14.1 Design Philosophy

GEOS handles play many different roles. The most fundamental of these is 
memory access. GEOS moves memory in the global heap and swaps memory 
to the disk. This makes memory available as needed and means that the total 
memory being used by geodes can be many times larger than the physical 
memory in the computer; however, it means also that geodes need some way 
to keep track of their memory. In addition, the system needs to perform 
memory "housekeeping," doing such things as freeing memory when the 
geode which owns it exits, making sure that memory is only locked by 
appropriate geodes, noting which memory sections can be swapped to the 
hard disk, etc. This means that the kernel needs to maintain a data area for 
each block of memory. Although the memory itself may move around, the 
data about the memory should remain in the same place so the kernel can 
access it.

The solution to both difficulties is the handle table. The table contains entries 
for each block of memory. These entries keep track of the block, noting such 
information as where the block is in the global heap, whether it has been 
swapped to the disk, who its owner is, etc. The handle table does not move in 
memory. Each entry is referenced by a handle, which is simply the address of 
the table entry. When a geode needs access to a block, it can call a 
memory-management routine and pass the handle associated with that 
block. The memory manager dereferences the handle to find the data about 
the block and then takes any appropriate steps.

The handle table is useful for many other things. Often a geode will need to 
perform an action on something which is managed by the kernel. For 
example, the kernel keeps track of the different disk volumes it has seen. A 
geode may need to access a disk but not want to keep track of the volume 
name; or it might want to find out details (such as the size available) of a 
given disk. Similarly, it might want to find out how large a file which it has 
opened has grown. All of this information is managed by the kernel, but 
applications may need to access it or change it. Therefore, each of these 
things is given an entry in the same handle table as the memory blocks; 
geodes can reference these things by their handles, the same way they do 
memory blocks.

The handle mechanism is useful in other places. Sometimes a geode will 
want to subdivide a block of memory into smaller parcels (or chunks). GEOS 
provides a local memory library which implements this functionality. These 
chunks can be moved around within a block, so applications access them by 
handles. The handle in this case is an offset to a handle table within that 
block; dereferencing the handle gives the address of the chunk. Similar 
techniques are used to divide Virtual Memory files. The principle is the same 
as with global memory handles: an unchanging handle is used to find the 
address of a movable thing.

There are certain things all handles have in common. They are all sixteen 
bits long, allowing them to fit in an 80x86 register. They also all specify 
addresses. The address is of an entry in a handle table; this entry contains 
information about the thing whose handle this is. However, handles can be 
divided into two basic groups:

+ Those in the global handle table.
The global handle table is kept in main memory below the global heap. 
The table is never accessed directly by geodes. Instead, geodes pass the 
handle as an argument to kernel routines that access the handle table.

+ Those in local handle tables. 
Such handles are offsets into handle tables which may be stored in 
memory blocks or VM files. These handles persist as long as the entity 
containing the handle table does.

### 14.2 The Global Handle Table

Many handles refer to things which are managed by the kernel. These things 
include global memory blocks, disk volumes, files, and many other things. 
Each of these things has an entry in the global handle table. Only the GEOS 
kernel may directly access the global handle table. If a geode wants to access 
one of these things, it must call a system routine and pass the thing's handle.

Global handles may not be saved across sessions of GEOS. The global handle 
table has to be rebuilt each time GEOS is launched. For example, when GEOS 
shuts down, all open files are closed. When an application restores from state, 
it may choose to reopen a file; it will then be given the file's handle, which will 
almost certainly be different from the file's handle during the previous 
session.

Sometimes several threads will be using the same global handle, and they 
will need to synchronize their access to it. They can arrange this by using the 
HandleP() and HandleV() routines. These routines are most often used to 
synchronize access to a global memory block; for this reason, they are 
documented in section 15.3.6 of "Memory Management," Chapter 15.

### 14.3 Local Handles

Many handles are not kept in the global handle table. For example, a block 
of memory may be declared as a "local-memory (LMem) heap." An LMem 
heap can contain many different chunks of data; the LMem manager moves 
these chunks around to make room for new ones. Each chunk is referenced 
via a chunk handle. (For more details about LMem heaps, see "Local 
Memory," Chapter 16.)

Local handle tables are useful when a handle needs to persist across GEOS 
shutdowns. For example, data in VM files is accessed by its block handle. 
These handles therefore need to remain the same every time the file is 
opened.

Some local handle tables are intended to be directly accessible to geodes. For 
example, LMem Chunk handles are simply offsets into the block containing 
the LMem heap; the address specified by that offset contains another offset 
value, which is the offset to the chunk. This scheme is part of the LMem API. 
Geodes which are written in assembly generally look up chunk handles 
themselves, instead of calling a system routine to translate the chunk handle 
into an address. (Goc code generally dereferences a chunk handle with a call 
to LMemDeref().) Some other local handle tables are intended to be opaque 
to geodes. For example, applications treat VM block handles as opaque 16-bit 
tokens; to dereference a VM handle, a geode must pass it to an appropriate 
system routine (such as VMLock()).

Local handles are used by many different libraries; among them are the 
LMem, VM, Database, and Cell libraries. The details differ with each library; 
for more information, see the appropriate chapter. An object-descriptor is a 
combination of two handles: the handle of the global memory block 
containing the object, and the chunk handle of the object itself. For more 
information, see ["GEOS Programming," Chapter 5](ccoding.md).

[Sound Library](csound.md) <-- &nbsp;&nbsp; [table of contents](../concepts.md) &nbsp;&nbsp; --> [Memory Management](cmemory.md)
