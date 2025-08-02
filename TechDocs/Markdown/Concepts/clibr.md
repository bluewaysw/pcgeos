## C Libraries

If you write more than one application, you may find yourself repeating a 
lot of effort. You may end up writing the same routines several times, or 
defining very similar classes for different applications. 

For this reason, GEOS lets you define libraries. Libraries are much like 
applications. However, they don't do anything on their own; instead, they 
must be loaded by other geodes. They provide applications with routines 
and object classes. This lets applications share code easily and efficiently.

Before you read this chapter, you should be familiar with programming in 
GEOS; you should have successfully written a simple GEOS application. You 
should also be very familiar with the material in ["First Steps: Hello World," 
Chapter 4](cgetsta.md) and ["GEOS Programming," Chapter 5](ccoding.md).

### C.1 Design Philosophy

GEOS libraries are designed to make code-sharing simple and efficient. 
They allow several different applications to make use of the same routines 
and classes while using the minimum amount of space.

Conventional libraries are fully included in each application. The usual 
technique is to write a header file which contains the code for the library's 
routines. Any application which needs to use the routines can then include 
this library. This has one main advantage: The code can be written and 
tested once, and applications can then rely on it to work. However, there is 
a severe drawback to this approach: every application which uses the 
library will contain identical code. This is not a problem for 
non-multitasking environments; if only a single application can run at a 
time, then there will be only a single copy of each library. In a 
multithreaded environment like GEOS, however, this is a very inefficient 
use of resources.

GEOS libraries solve this problem. Each geode specifies which libraries it 
will use, either at compile-time (in the .gp file) or at run-time (with 
**GeodeUseLibrary()**). The kernel will see to it that the library is loaded 
when necessary. This means that if a dozen applications are all using the 
same library, the code needs only be loaded once.

Conventional libraries contain only routines. GEOS libraries, on the other 
hand, may contain both routines and object classes. There are several 
advantages to defining a class in a library instead of in an application. 
First, there is the same code-sharing benefit that routines have. If a class 
is defined in a library, the heap will contain at most one copy of each of the 
class's methods, no matter how many applications use objects from that 
class. There is another advantage as well; all applications which use that 
class can be sure that they are using objects whose definitions are identical. 
this makes it possible for applications to send messages to objects owned 
by other geodes.

Writing a library is very much like writing an application. There are only 
a few differences, which are covered in this appendix. You should already 
be familiar with writing applications before you try to write a library.

### C.2 Library Basics

A library is a geode, much like an application geode. However, its behavior 
is slightly different. In particular, libraries do not have any threads of their 
own, unless they explicitly create them.

When a geode calls a routine which is exported from a library, the routine 
is run by the thread which made the call, not by the library's thread. This 
has several implications. First, it means that a library's response time is 
not dependent on the number of applications which use the library. An 
application which uses the library a lot will do so on its own time and may 
have its priority reduced accordingly. Indeed, a library with many users is 
likely to perform better than one with few users, since its code will be less 
likely to be swapped out of the global heap. Similarly, library routines will 
use the stack of the calling thread; this means that the same routine can 
be called by several different threads at once, with less danger of a 
synchronization problem.

Another consequence is that if a library routine allocates memory, that 
memory will belong to the owning geode. Thus, when the application exits, 
the memory will automatically be freed; on the other hand, if the library 
exits before the application does, the memory block will remain. If a library 
wants to have the block owned by the library geode, it must set the owner 
explicitly.

Geodes which use a library are said to be its "clients." A client may declare 
that it uses a library in its .gp file, or it may load the library at runtime by 
calling **GeodeUseLibrary()**. One library may be a client of another; in 
this case, when the first library is loaded, the second will be as well.

A library may have a single special routine, known as its entry point. The 
kernel calls this routine to inform the library when it is launched or freed, 
when it acquires a new client, or when a client is unloaded. The entry point 
routine is described more fully in [section C.3](#c3-the-library-entry-point).

A library may export object classes or routines. If a routine is exported, it 
may be called by any geode which uses the library. If an object class is 
exported, any geode which uses the library may instantiate objects of that 
class, and may define a subclass of it.

Every library should have a library header file. This header file contains 
declarations for all exported routines and classes, as well as definitions of 
any appropriate macros, constants, structures, etc. Every geode which uses 
the library will need to include this header file. If the library exports any 
object classes, the header file should be a Goc header file with the suffix 
.goh; otherwise it should be a standard C header file with the suffix .h. The 
header file is described in more detail in [section C.5](#c5-header-files).

### C.3 The Library Entry Point

LibraryEntry(), LibraryCallType

A library may need to do bookkeeping when it is launched, when a client is 
attached, or at other times. For this reason, some libraries will have an 
entry point routine. The entry point routine is called by the kernel; it 
should never be called by other geodes. Some of the calls are made in the 
kernel thread, while others are made by a geode's thread. All of the calls 
are made automatically by the kernel.

An entry point routine must take two arguments. The format of an entry 
point is shown in Code Display C-1.

---
Code Display C-1 A Library Entry Point
~~~
Boolean _pascal
        LibraryEntry(LibraryCallType ty,
                        GeodeHandle client);
~~~

When the kernel calls the entry point routine, it passes the following 
arguments:

+ A member of the **LibraryCallType** enumerated type. This specifies 
why the kernel is calling the routine. This type is described below.

+ A geode handle. This parameter is valid only if certain 
**LibraryCallType** values are passed.

The entry point should return true if an error occurs; otherwise it should 
return false (i.e. zero).

**LibraryCallType** contains the following members:

**LCT_ATTACH**  
This is passed when the library has just been launched. The 
client parameter is undefined. The call is made in the kernel 
thread.

**LCT_DETACH**  
This is passed when the library is about to be unloaded. The 
client parameter is undefined. The call is made in the kernel 
thread.

**LCT_NEW_CLIENT**  
A thread has just called **GeodeUseLibrary()**, or a geode 
which depends on the library is being launched. The client 
parameter contains the **GeodeHandle** of the new client. The 
call is made in the kernel thread.

**LCT_NEW_CLIENT_THREAD**  
A geode which depends on the library has just spawned a new 
thread. The client parameter contains the **GeodeHandle** of 
the thread's owner. The call is made in the new thread.

**LCT_CLIENT_THREAD_EXIT**  
A thread which uses the library is being destroyed. The client 
parameter contains the **GeodeHandle** of the thread's owner. 
The call is made in the soon-to-be destroyed thread.

**LCT_CLIENT_EXIT**  
A client loaded this library with **GeodeUseLibrary()** has 
just called **GeodeFreeLibrary()**. The client parameter 
contains the **GeodeHandle** of the former client. The call is 
made in the kernel thread.

**LCT_DETACH**  
The library is about to be unloaded. The call is made in the 
kernel thread.

Sometimes a single action can prompt several calls to the entry point, each 
with a different **LibraryCallType** value. For example, suppose FooWrite 
is launched. This application's .gp file specifies that it uses the BarObj 
library. At the time FooWrite is launched, BarObj has not been loaded. The 
kernel will automatically launch BarObj and immediately call the entry 
point with parameter LCT_ATTACH. The kernel will then call the entry 
point again with parameter LCT_NEW_CLIENT, passing FooWrite's 
**GeodeHandle**. It will then call the entry point once for each FooWrite 
thread, passing LCT_NEW_CLIENT_THREAD; it will make these calls as 
each thread is started.

Some libraries will not need to take any actions when the entry point is 
called; these libraries need not have an entry point routine. On the other 
hand, some libraries will need to do bookkeeping chores. This is left 
entirely to the library's discretion.

The entry point should take care not to perform any actions with side 
effects outside the library. If the entry point allocates memory, it should 
make sure to make the library's geode the block's owner. Similarly, the 
entry point should not change the working directory; instead, it should use 
**FilePushDir()** and **FilePopDir()** to make temporary changes to the 
working directory.

### C.4 Exported Routines and Classes

Writing routines for a library is very much like writing them for an 
application. Simply export the routine in the .gp file and any geode which 
uses the library will be able to call the routine.

It is important when writing routines for export to document the routines 
exhaustively. Remember that the library will probably be used by other 
programmers; they will rely on the routines to behave exactly as specified. 
Exported routines should also minimize side effects; for example, it is a bad 
idea for a library routine to change the working directory without changing 
it back, unless that is the routine's main purpose.

Most libraries will have a number of routines which are not for export, but 
are used by routines that are exported. These are simply written normally, 
and are not exported in the .gp or declared in the header file. Remember 
that programmers will not see these routines; their side effects should thus 
be fully documented with the exported routines which call them.

Some libraries will declare classes of objects. In this case, the library 
should specify in the .gp file that it uses whichever library defines the 
superclass of the object. For example, if a library defines a subclass of 
**GenClass**, it should specify that it uses the UI library. It should then 
export the new class.

Some libraries will declare classes that are not intended to be used by 
clients. For example, the Impex library declares **ImportExportClass**. 
This class is never instantiated; it contains code and instance data that are 
used by its subclasses (**ImportControlClass** and **ExportControlClass**). 
Such "hidden" classes need not be exported. However, the classes must be 
fully declared in the header files so the subclasses can be defined accurately 
and consistently.

### C.5 Header Files

Every library should have at least one header file. This file contains 
declarations and definitions which are needed by each of the geodes which 
uses the library.

If a library exports routines but does not export object classes, its header 
will be a standard C header file. This file should contain declarations of 
every exported routine. It should also contain the definitions of any macros, 
constants, structures, etc., which clients might use. 

If a library exports object classes, its header will be a Goc header with the 
suffix .goh. In addition to routine declarations, it must contain the 
complete declarations of each of the exported object classes, including all 
the message declarations. A .goh file should begin with the Goc directive 
"**@deflib <libname>**", and end with the directive "**@endlib**". This ensures 
that the header will only be included once, even if the code tries to include 
it several times.

Large libraries may have several header files. For example, a library might 
declare several similar object classes. It is usually simpler to write a 
separate header for each class; a client can then include only the headers 
for classes which it will use. Note that the header for a class should use a 
Goc **@include** directive to include the header for that class's superclass.

It is of the utmost importance that the headers be kept in synchronization 
with the libraries they describe. As a rule, a library will include each one 
of those headers; that helps to keep all the files compatible. Nevertheless, 
you must be careful whenever changing a library.

### C.6 Compiler Directives

Libraries have to be compiled slightly differently from applications. Since 
library routines are run under application threads, they must treat global 
variables differently than applications do. You must therefore add pragmas 
to ensure that the library is compiled correctly.

There are several steps to take:

+ The compiler should not to expect the ss register to be the same as ds.

+ The compiler must generate code to load the dgroup segment address 
into ds at the start of exported routines.

+ The compiler must set up semaphores or other data-synchronization 
structures for global variables.

Most compiler manuals have a section on compiling dynamically-linked 
libraries (DLLs) for Microsoft Windows; this section will describe how to set 
up these conditions. Note that you need only do this if your library will have 
its own global or static variables. If the library's routines and methods use 
only local, automatic variables, you need not perform these actions.

When you compile a library, you must pass the argument "-L <libname>" 
to Goc. Edit your local.mk file to make it insert this flag. For more 
information about the local.mk file, see ["Using Tools," Chapter 10 of the 
Tools book](../Tools/ttools.md).

[Threads and Semaphores](cmultit.md) <-- &nbsp;&nbsp; [table of contents](../concepts.md) &nbsp;&nbsp; --> [The Math Library](cmath.md)
