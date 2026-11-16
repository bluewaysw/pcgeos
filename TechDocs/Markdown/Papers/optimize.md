# Creating Applications with Multiple Source Files

---

### Advantages

Splitting your Goc application into multiple source files is a good thing, for
several reasons:

1. Since a code resource (memory block) is generated for each source code file,
   you can control the size of your code resources. Remember that in GEOS,
   resources should be kept between two to six kilobytes in size for optimal
   paging.

2. Class definitions (`@class`/`@endc`), if placed in `.goh` files, can then be
   accessible as a library for your own development, as well as for other
   developers.

3. Compilation time can be reduced, since PMAKE only needs to recompile those
   files which have changed.

4. Normal C code can be separated from Goc code to improve code readability and
   organization.

### The Source Files

This document outlines the guidelines for creating multi-source-file GEOS
applications that will compile and run correctly. The steps are divided by file
type as follows:

- [Creating Applications with Multiple Source Files](#creating-applications-with-multiple-source-files)
    - [Advantages](#advantages)
    - [The Source Files](#the-source-files)
    - [Application Header — `app.goh`](#application-header--appgoh)
    - [Globals Header — `global.goh`](#globals-header--globalgoh)
    - [Static Objects — `appUI.goc`](#static-objects--appuigoc)
    - [Methods — `method1.goc`, `method2.goc`, etc.](#methods--method1goc-method2goc-etc)
    - [C Code — `code1.c`, `code2.c`, etc.](#c-code--code1c-code2c-etc)

---

### Application Header — `app.goh`

This header file will declare all the `#define`d constants and `typedef`d data
types. It will also contain all the `@class`/`@endc` Goc class definitions. In
this file, place statements of the following kinds:

```c
#define
typedef
@class
@endc
```

---

### Globals Header — `global.goh`

This header file will declare as `extern` all the global variables and all the
Goc objects. Any globally used routines can have their prototype declarations
here as well:

```c
extern dataType globalVar;
@extern object ObjectName;
returnType MyGloballyUsedRoutine(dataType arg1, dataType arg2);
```

---

### Static Objects — `appUI.goc`

The standard Geoworks paradigm is to put all the static object definitions in
this one file. Remember that different resources will be defined within this
file.

Since the Glue linker does not create links between objects if they are in
separate source files, you must keep children in the same source file as their
parent. In other words, all objects that are statically connected should be in
the same file.

However, objects that are linked only within an object subtree, such as document
or display templates, can be stored in separate `.goc` files. These resources
are typically duplicated at runtime, using the kernel routine
`ObjDuplicateResource()`, and then dynamically added to the application's object
tree, using `MSG_GEN_ADD_CHILD()`.

You can also store objects that are related to each other, such as those that
are part of a menu, in a separate source file. When you do this, you must
dynamically add these menu object trees to the `GenPrimary` in your `appUI.goc`
file. Here is roughly how to do this:

In the `process.goc` file (`GenProcessClass` methods):

```c
@extern method MyProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION {
    if (!(attachFlags & AAF_RESTORING_FROM_STATE)) {
        /*
         * Do only if not restoring from state.
         * The 2 in the second parameter is the position
         * among the primary's children. I.e. MyOptionsMenu
         * will be the third child of the primary.
         */
        @send MyPrimary::MSG_GEN_ADD_CHILD(
            MyOptionsMenu,
            (CCF_MARK_DIRTY | 2)
        );
        @call MyOptionsMenu::MSG_GEN_SET_USABLE(
            VUM_DELAYED_VIA_APP_QUEUE
        );
        @callsuper();
    }
}
```

If you are going to be adding controllers, you will probably have to add them
to the GCN lists in the application object. Use `MSG_META_GCN_LIST_ADD` to do
this:

```c
@call application::MSG_META_GCN_LIST_ADD(
    @MyControllerObject,
    GAGCNLT_SELF_LOAD_OPTIONS,
    MANUFACTURER_ID_GEOWORKS
);
```

With this taken care of, you can have your `appUI.goc` file contain the objects
that are related to the application and primary objects. Then you can put the
sometimes large object trees related to a menu in another source file. This
keeps the compile time shorter and the code easier to organize and read.

**Contents of `appUI.goc`**

1. Include all the necessary header files:

   ```c
   @include <stdapp.goh>
   #include <whatever.h>
   @include "app.goh"
   ```

2. Define all the global variables that you declared as `extern` in the
   `global.goh` file:

   ```c
   dataType globalVar1;
   dataType globalVar2;
   ```

3. Declare the classes that this file will use when defining objects, using the
   Goc `@classdecl` keyword:

   ```c
   @classdecl WhatEverClass;
   ```

4. Declare the methods for these classes. Since these will be defined in
   separate `.goc` files, declare the methods using the `@extern` keyword. If
   you do not do this, the code will not cause a compile error, but it will
   never be executed:

   ```c
   @extern method WhatEverClass, MSG_WHAT_EVER_DO_IT;
   ```

5. Define static objects in user-defined object resources. You should declare
   your resources using the Goc `@start` and `@end` keywords, and define your
   objects using the `@object` keyword:

   ```c
   @start NewResource;

   @object WhatEverClass WhatEverObject = {
       [ ...instance data initializations... ]
   }

   [ ...more objects... ]

   @end NewResource;
   ```

---

### Methods — `method1.goc`, `method2.goc`, etc.

These files hold the method definitions for the classes. Remember that each
`.goc` source file becomes a code resource for your application. Therefore, it
is a good idea to group related methods and routines in the same file. This can
help reduce the paging that your application will generate by using locality of
code reference.

**Contents of `method1.goc`, `method2.goc`, etc.**

1. Include the necessary files:

   ```c
   @include <stdapp.goh>
   #include <whatever.h>
   @include "app.goh"
   @include "global.goh"
   ```

2. Prototype the functions local to this file. Remember that the prototypes for
   globally used routines were declared in `global.goh`.

   ```c
   dataType RoutineDefinedInThisFile(dataType var);
   ```

3. Define your methods using the Goc `@extern method` keywords, and define your
   routines. Do not forget to define your globally used routines somewhere.

   ```c
   @extern method AppWhatEverClass, MSG_APP_WHATEVER_DO_IT {
       [ ...code... ]
   }

   dataType RoutineDefinedInThisFile(dataType var) {
       [ ...code... ]
   }
   ```

---

### C Code — `code1.c`, `code2.c`, etc.

These files hold normal C code. No Goc compiler directives—keywords beginning
with `@`—exist within them.

Placing C code into separate files is good because they will not have to run
through the Goc preprocessor, which will reduce compilation time. Remember that
each `.c` source file becomes a code resource for your application.

Therefore, it is a good idea to group related routines in the same file. This
can help reduce the paging that your application will generate by using locality
of code reference.

---

[Whitepapers](../index.html)

**Last modified:** Thu Jan 8 10:37:10 PST

---

![](../BILDER/LETTER.GIF)

`r*bettsteller#web*de`

If you are not a robot, replace `*` with `.` (dot) and `#` with `@`.

Wenn Sie kein Roboter sind, ersetzen Sie `*` durch `.` (Punkt) und `#` durch
`@` (Klammeraffe).

- [Datenschutzerklärung](../PRIVATE/PRIVAT.HTM)
- [Haftungsausschluss](http://www.disclaimer.de/disclaimer.htm)
- [Impressum](../PRIVATE/IMPRESSUM.HTM)
- [Privacy Policy (English)](../PRIVATE/PRIVATE.HTM)
- [Disclaimer (English)](http://www.disclaimer.de/disclaimer.htm#2)
