# Common Mistakes of New GEOS Programmers

This file describes strategies for avoiding common problems that can occur, especially for
programmers who are new to GEOS programming. It was written in the
1990s and adopted for the freeGEOS project in 2026.

## Contents

- [Common Mistakes of New GEOS Programmers](#common-mistakes-of-new-geos-programmers)
  - [Contents](#contents)
  - [1. Use EC Coding to Catch Bugs](#1-use-ec-coding-to-catch-bugs)
    - [General Memory](#general-memory)
    - [LMem](#lmem)
    - [VM Files](#vm-files)
    - [Miscellaneous](#miscellaneous)
  - [2. Variables](#2-variables)
  - [3. Memory](#3-memory)
  - [4. Threads](#4-threads)
  - [5. Files](#5-files)
  - [6. UI and Generic Object Trees](#6-ui-and-generic-object-trees)
  - [7. Localization](#7-localization)
  - [8. Graphics](#8-graphics)
  - [9. Miscellaneous](#9-miscellaneous)

## 1. Use EC Coding to Catch Bugs

Since GEOS is multithreaded and unlocked memory blocks can be moved out from
under a pointer, debugging memory scribbling is quite difficult. Become familiar
with the EC routines that are available within GEOS and use them liberally.

When compiled as non-EC, these routines become empty stubs, so they will not
impact the performance of the shipping version of your application.

Related to this is stress-testing your application with **Swat**. By simply turning
on many of the EC flags, you can find many bugs that would otherwise take days
to find and duplicate.

Here is a partial list of flags to set. Please note that these flags are only 
applicable to an EC target.

### General Memory

- **`+unlockMove`**

  Force unlocked blocks to move whenever possible. This causes memory leaks to
  be more consistently reproducible. It makes the target run very slowly, 
  but it's an extremely effective way to detect memory leaks.

- **`+free`**

  Checks free blocks on the heap, which normally should contain `0xCC`. If they
  do not, a fatal error is generated, and information about the previous blocks
  on the heap is dumped.

  The previous block is useful because often you will simply be writing past the
  end of a block. Often you can figure out what this previous block is and then
  track the bug by looking at the code.

### LMem

This applies to chunks, huge arrays, DB, and so on.

- **`+lmem`**

  Checks the LMem internal structures. If you find that an `LMBH_handle`, or
  another header field, is messed up, this is frequently useful for finding out
  when it is happening.

- **`+lmemMove`**

  Forces LMem blocks to move whenever possible.

- **`+high`**

  Simply increases the level of LMem checking.

### VM Files

- **`+vm`**

  Checks VM file consistency.

- **`+vmemDiscard`**

  Forces clean VM blocks to be discarded when unlocked.

- **`+analVM`**

  Performs extensive VM memory checking.

### Miscellaneous

- **`+graphics`**

  Checks GStrings and similar graphics-related data.

- **`+segment`**

  Performs extensive segment checking.

- **`+text`**

  Performs extra error checking on Text objects.

## 2. Variables

- Global variables, static variables, and static strings take up space in
  `dgroup`. `dgroup` is a fixed block, so the bigger it gets, the more grief it
  causes the memory manager. Move as much static and global data as possible to
  object instance data or chunks in a data block.

- Local variables are stored on the stack. This is only a bad thing when you
  have a local variable that is a huge structure or array - tens or hundreds of
  bytes - because it could cause the stack to overflow.

  To reduce the size of variables on the stack, change the variable to a handle,
  `optr`, or `ptr` to a block or chunk that contains the structure.

- You can see the value of the stack-pointer register for each frame on the
  stack by entering the following command in Swat:

    backtrace -rsp

## 3. Memory

    In a method handler, pself can be invalidated after calling another message or 
    when performing an LMem action on the object block, oself.
    
    Make sure to dereference pself again - with ObjDerefGen or ObjDerefVis - when 
    using it after one of these invalidating actions. On the other hand, do not 
    overdo it by dereferencing after every routine call.
    
- Make sure to check for failed memory allocations or locks. This can be determined 
  by checking for NullHandle or a null pointer.

- Do not let resources get too big. Break them into multiple resources. The optimum 
  for the memory manager is 6k to 8k. Note that every code file creates its own resource.

- The same applies to object resources. Note that some objects store chunks in their own
  resource at runtime. The most important ones are:
  - GenText / VisText: They store their text in a chunk within their own resource. Text objects
    that can store much more text at runtime than at compile time should be placed in smaller 
    resources.
  - GenDynamicList: The (currently visible) list items of the GenDynamicList are created at 
    runtime within the GenDynamicList’s resource. Especially when graphical monikers are used,
    the resource can grow very large at runtime.
  - For all objects that are assigned graphical monikers at runtime, you should keep an eye on the
    resource size.

## 4. Threads

- Do not allow your application's UI thread to make calls to its process thread. **Never!**
  This can result in a deadlock because the process thread must occasionally make calls to the
  UI thread.

- All objects in a Gen tree must be run by the same thread, usually the UI thread.

- Use a semaphore if you want to access the same data structures from different threads.
  Otherwise, another thread might modify the data **while** you are reading it.

## 5. Files

Always check whether a file was opened or created successfully. You can simply check whether the
returned FileHandle is NullHandle.

If the file could not be opened or created and you try to access it, the system will crash.

## 6. UI and Generic Object Trees

- GenProcessClass has no instance data. **None!** It is a hybrid class that has no space
  allocated for instance data. If you try to give it instance data, you are guaranteed
  to get memory-scribbling errors.

  Remember to use the ```neverSaved``` flag on the ProcessClass ```@classdecl```. Do not 
  use this flag on objects that have instance data unless the object is marked ignoreDirty.

- Do not overuse ```HINT_DEFAULT_FOCUS``` or ```HINT_DEFAULT_TARGET```. Only one object at 
  a given level in the Gen tree can have the default focus or target.

## 7. Localization

- The resource containing chunks to be localized must be marked with the ```lmem``` flag.
  This can be done in the .gp file by adding ```lmem``` to the resource declaration.

- String chunks without an explicit length specification, such as
  ```@chunk char Info[] = “Operation was successful”;```, can be localized; chunks with
  an explicit length specification, such as ```@chunk char MonikerText[16] = “GI_visMoniker”;```,
  cannot be localized.

## 8. Graphics

Understand the difference between a **GString** and a **GState**.

- A GString is a data structure containing a sequence of graphics commands. See ```gstring.h```.
- A GState contains information that keeps track of how to draw, including colors,
  scaling, the current text font, and so on.
- In simple terms: a GString contains **what** is drawn, and a GState is the location **where**
  it is drawn. So: **GrDrawGstring()** draws a *GString* into a *GState*.

## 9. Miscellaneous

For standard menus such as File or Edit, use:

    ATTR_GEN_INTERACTION_GROUP_TYPE = GIGT_????_MENU
