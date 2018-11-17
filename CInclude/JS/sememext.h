/* seMemExt.h - Routines for core builds that are using extended
 *              memory (i.e. cannot just malloc and free).
 */

#ifndef _SEMEMEXT_H
#define _SEMEMEXT_H

/* By default, NONE of the MEMEXT code is turned on */

#if !defined(JSE_MEMEXT_SECODES)
#  define JSE_MEMEXT_SECODES 0
#endif
#if !defined(JSE_MEMEXT_STRINGS)
#  define JSE_MEMEXT_STRINGS 0
#endif
#if !defined(JSE_MEMEXT_OBJECTS)
#  define JSE_MEMEXT_OBJECTS 0
#endif
#if !defined(JSE_MEMEXT_MEMBERS)
#  define JSE_MEMEXT_MEMBERS 0
#endif
#if !defined(JSE_MEMEXT_READONLY)
#  define JSE_MEMEXT_READONLY 0
#endif

#  if JSE_MEMEXT_READONLY==0
#     define JSE_MEMEXT_R  /* nothing, because read==write */
#  else
#     define JSE_MEMEXT_R  const
#  endif

#if JSE_MEMEXT_SECODES==0  \
 && JSE_MEMEXT_STRINGS==0  \
 && JSE_MEMEXT_OBJECTS==0  \
 && JSE_MEMEXT_MEMBERS==0

   /* NO EXTENDED MEMORY */
#  if JSE_MEMEXT_READONLY!=0
#     error JSE_MEMEXT_READONLY must be off if no SEMEMEXT
#  endif

#else

   /* EXTENDED MEMORY IS ENABLED */

   /* The memory extension defines will cause ScriptEase to
    * allocate and access memory for the appropriate structure
    * through the functions defined below, which you must
    * write. An example implementation is found in
    * 'srcmisc/memext.c'.
    *
    * Defining JSE_MEMEXT_SECODES causes secodes to be
    * allocated this way. Secodes are the bytecodes your
    * script is compiled into internally.
    *
    * Defining JSE_MEMEXT_STRINGS causes strings to be
    * allocated this way. This is the raw data of strings
    * (and buffers), the text of the strings.
    *
    * I would expect that if we port to a system that uses
    * memory in a way to need this stuff, we will implement
    * the functions and put them in the 'seisdk/libs/<system>'
    * directory for that system, then the targets for that
    * system will include it.
    *
    *
    * When implementing this system, you will see below that
    * we have six functions. The jsememStore and jsememUnstore
    * routines are used to store one of the above items into
    * your special memory, so you move it to wherever and
    * return a handle of some kind to it or get rid of it
    * given the handle in the second case. Note that for
    * all four functions, the type of memory is the final
    * parameter, so you can store different types of memory
    * in different places.
    *
    * The next two functions, jsememLockRead and jsememUnlockRead,
    * access the memory for reading. Note that both strings
    * and secodes only access the memory for reading, never
    * for writing. They calculate the value and store it,
    * never modifying it. When the value changes, the old
    * value is unstored and a new one stored.
    *
    * The final two functions are jsememLockWrite and
    * jsememUnlockWrite. Neither of the two memory extensions
    * I have so far, but other structures in the core,
    * which are read/write will be written to in the future.
    * I'll save usage notes for implementors of these
    * functions until we know how the core uses them.
    * For instance, will the core lock an item
    * for both reading and writing, and that sort of thing.
    *
    *
    * For the two read functions, it is very much suggested
    * the implementor keeps a cache of the items. In our example
    * implementation, we simulate two kinds of memory by
    * copying the value into a malloced block when it needs
    * to be read and freeing the block when it is no longer
    * needed. However, we keep 3 or so blocks around even after
    * they are unlocked. If they are locked again, we have them
    * and don't have to recopy. Because the core will often
    * use the same value many times, this helps tremendously.
    * The core's complexity is intentionally kept to a minimum
    * counting on the cache. The core makes no attempt to do
    * any 'cache-like' stuff. It does a simple 'lock-use-unlock'
    * with the understanding that a cache will make this simplistic
    * approach work.
    */

   /* Here are the current types of memory you can receive. */
   enum jseMemExtType
   {
      phony_type = -1,  /* make sure the first type starts at 0 */
#     if JSE_MEMEXT_SECODES!=0
         jseMemExtSecodeType,
#     endif
#     if JSE_MEMEXT_STRINGS!=0
         jseMemExtStringType,
#     endif
#     if JSE_MEMEXT_OBJECTS!=0
         jseMemExtObjectType,
#     endif
#     if JSE_MEMEXT_MEMBERS!=0
         jseMemExtMemberType,
#     endif
      jseMemExtTypeCount   /* at compile-time this is set to how many types */
   };

   /* memext routines require that a jsememextHandle be defined, and that
    * a way to compare to zero be defined.  Here's an example:
    *    typedef uword16 jsememextHandle;
    *    #define jsememextNullHandle  ((jsememextHandle)0)
    */

#  if defined(__JSE_GEOS__)
      typedef optr jsememextHandle;
#     define jsememextNullHandle NullOptr
#  endif

#  if (JSE_MEMEXT_OBJECTS!=0) || (JSE_MEMEXT_MEMBERS!=0)
      jsememextHandle jsememextAlloc(JSE_POINTER_UINDEX size,enum jseMemExtType type);
#  endif
#  if (JSE_MEMEXT_MEMBERS!=0)
      jsememextHandle jsememextRealloc(jsememextHandle memHandle,JSE_POINTER_UINDEX size,enum jseMemExtType type);
#  endif
#  if (JSE_MEMEXT_SECODES!=0) || (JSE_MEMEXT_STRINGS!=0)
      jsememextHandle jsememextStore(const void *data,JSE_POINTER_UINDEX size,enum jseMemExtType type);
#  endif
   void jsememextFree(jsememextHandle memHandle,enum jseMemExtType type);

   JSE_MEMEXT_R void * jsememextLockReadReally(jsememextHandle memHandle,enum jseMemExtType type);
   void jsememextUnlockReadReally(jsememextHandle memHandle,JSE_MEMEXT_R void * data,enum jseMemExtType type);
#  ifdef MEM_TRACKING
    JSE_MEMEXT_R void * jsememextLockRead(jsememextHandle memHandle,enum jseMemExtType type);
    void jsememextUnlockRead(jsememextHandle memHandle,JSE_MEMEXT_R void * data,enum jseMemExtType type);
#  else
#   define jsememextLockRead jsememextLockReadReally
#   define jsememextUnlockRead jsememextUnlockReadReally
#  endif
#  if JSE_MEMEXT_READONLY==0
#     define jsememextLockWrite jsememextLockRead
#     define jsememextUnlockWrite jsememextUnlockRead
#  else
      void * jsememextLockWrite(jsememextHandle memHandle,enum jseMemExtType type);
      void jsememextUnlockWrite(jsememextHandle memHandle,void * data,enum jseMemExtType type);
#  endif

#endif

#endif /* #ifndef _SEMEMEXT_H */
