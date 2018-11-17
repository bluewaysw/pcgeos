/* srccore/seobject.h
 *
 * Defines for JavaScript objects.
 */

/* (c) COPYRIGHT 2000              NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#ifndef _SRCCORE_SEOBJECT_H
#define _SRCCORE_SEOBJECT_H

#if defined(__cplusplus)
   extern "C" {
#endif


typedef uword8 seAttribs;

/* Store a single object element */
struct _SEObjectMem
{
   VarName       name;
   struct _SEVar value;
   seAttribs     attributes;
};

#if JSE_MEMEXT_MEMBERS==0

   /* STANDARD ALLOC VERSION OF SEMEMBERS */
   typedef struct _SEObjectMem *hSEMembers;
   typedef struct _SEObjectMem *rSEMembers;
   typedef struct _SEObjectMem *wSEMembers;

   /* the following macros are used by standard and mem-handle forms */
#  define hSEMembersNull ((hSEMembers)NULL)
#  define SEMEMBERS_ASSIGN(r_or_w_semembers,hsemembers)  (r_or_w_semembers) = (hsemembers)
#  define SEMEMBERS_ASSIGN_LOCK_R(rsemembers,hsemembers) (rsemembers) = (hsemembers)
#  define SEMEMBERS_ASSIGN_LOCK_W(wsemembers,hsemembers) (wsemembers) = (hsemembers)
#  define SEMEMBERS_PTR(r_or_w_semembers) (r_or_w_semembers)
#  define SEMEMBERS_HANDLE(r_or_w_semembers) (r_or_w_semembers)
#  define SEMEMBERS_LOCK_R(rsemembers)       /* do nothing */
#  define SEMEMBERS_UNLOCK_R(rsemembers)     /* do nothing */
#  define SEMEMBERS_LOCK_W(wsemembers)       /* do nothing */
#  define SEMEMBERS_UNLOCK_W(wsemembers)     /* do nothing */
#  define SEMEMBERS_CAST_R(wsemembers)       (wsemembers)

#else

   /* MEMORY_HANDLE VERSION OF SEMEMBERS */

   /* implementation must defined the following six items */
   typedef jsememextHandle hSEMembers;
#  define hSEMembersNull jsememextNullHandle
#  define semembersAlloc(newCount) \
      (hSEMembers)jsememextAlloc((newCount)*sizeof(struct _SEObjectMem),jseMemExtMemberType)
#  define semembersRealloc(HSEMEMBERS,NEWCOUNT) \
      (hSEMembers)jsememextRealloc((HSEMEMBERS),(NEWCOUNT)*sizeof(struct _SEObjectMem),jseMemExtMemberType)
#  define semembersFree(HSEMEMBERS) \
      jsememextFree((HSEMEMBERS),jseMemExtMemberType)
#  define semembersLockRead(H) (JSE_MEMEXT_R struct _SEObjectMem *) \
      jsememextLockRead((H),jseMemExtMemberType)
#  define semembersUnlockRead(H,rseobjectmem) \
      jsememextUnlockRead((H),(rseobjectmem),jseMemExtMemberType)
#  define semembersLockWrite(H) (struct _SEObjectMem *) \
      jsememextLockWrite((H),jseMemExtMemberType)
#  define semembersUnlockWrite(H,rseobjectmem) \
      jsememextUnlockWrite((H),(rseobjectmem),jseMemExtMemberType)

   /* these typedefs help the common routines be used */
   typedef struct _rSEMembers {
      JSE_MEMEXT_R struct _SEObjectMem * semembers_ptr;
      hSEMembers semembers_handle;
   } rSEMembers;
#  if 0==JSE_MEMEXT_READONLY
      typedef rSEMembers wSEMembers;
#  else
      typedef struct _wSEMembers {
         struct _SEObjectMem * semembers_ptr;
         hSEMembers semembers_handle;
      } wSEMembers;
#  endif

   /* the following macros are used by standard and mem-handle forms */
#  define SEMEMBERS_ASSIGN(r_or_w_semembers,hsemembers) \
      (r_or_w_semembers).semembers_handle = (hsemembers)
#  define SEMEMBERS_PTR(r_or_w_semembers) (r_or_w_semembers).semembers_ptr
#  define SEMEMBERS_HANDLE(r_or_w_semembers) (r_or_w_semembers).semembers_handle

#  define SEMEMBERS_LOCK_R(rsemembers) \
      (rsemembers).semembers_ptr = semembersLockRead((rsemembers).semembers_handle)
#  define SEMEMBERS_ASSIGN_LOCK_R(rsemembers,hsemembers)   \
      (rsemembers).semembers_ptr = semembersLockRead((rsemembers).semembers_handle=(hsemembers))
#  define SEMEMBERS_UNLOCK_R(rsemembers) \
      semembersUnlockRead((rsemembers).semembers_handle,(rsemembers).semembers_ptr)
#  define SEMEMBERS_LOCK_W(wsemembers) \
      (wsemembers).semembers_ptr = semembersLockWrite((wsemembers).semembers_handle)
#  define SEMEMBERS_ASSIGN_LOCK_W(wsemembers,hsemembers)   \
      (wsemembers).semembers_ptr = semembersLockWrite((wsemembers).semembers_handle=(hsemembers))
#  define SEMEMBERS_UNLOCK_W(wsemembers) \
      semembersUnlockWrite((wsemembers).semembers_handle,(wsemembers).semembers_ptr)
   /* following cast allows W to be passed to a function that accepts only R */
#  define SEMEMBERS_CAST_R(wsemembers)  \
      *((rSEMembers *)(&(wsemembers)))

#endif


#if JSE_MEMEXT_MEMBERS==0

   /* STANDARD ALLOC VERSION OF SEOBJECTMEM */
   typedef struct _SEObjectMem *rSEObjectMem;
   typedef struct _SEObjectMem *wSEObjectMem;

   /* the following macros are used by standard and mem-handle forms */
#  define SEOBJECTMEM_ASSIGN_INDEX(r_or_w_seobjectmem,members,index) \
      (r_or_w_seobjectmem)=(members)+(index)
#  define SEOBJECTMEM_ASSIGN_PTR(r_or_w_seobjectmem,seobjectmem) \
      (r_or_w_seobjectmem)=(seobjectmem)
#  define SEOBJECTMEM_PTR(r_or_w_seobjectmem) (r_or_w_seobjectmem)

#  define SEOBJECTMEM_PTR(r_or_w_seobjectmem) (r_or_w_seobjectmem)
#  define SEOBJECTMEM_UNLOCK_R(rseobjectmem) /* do nothing */
#  define SEOBJECTMEM_UNLOCK_W(wseobjectmem) /* do nothing */
#  define SEOBJECTMEM_CAST_R(wseobjectmem)   (wseobjectmem)

#else

   /* MEMBERS ARE HANDLE-BASED */

   typedef struct _rSEObjectMem {
      JSE_MEMEXT_R struct _SEObjectMem *seobjectmem_ptr;
      rSEMembers semembers;
   } rSEObjectMem;
#  if 0==JSE_MEMEXT_READONLY
      typedef rSEObjectMem wSEObjectMem;
#  else
      typedef struct _wSEObjectmem {
         struct _SEObjectMem *seobjectmem_ptr;
         wSEMembers semembers;
      } wSEObjectMem;
#  endif


   /* the following macros are used by standard and mem-handle forms */
#  define SEOBJECTMEM_ASSIGN_INDEX(r_or_w_seobjectmem,members,index) \
      (r_or_w_seobjectmem).semembers.semembers_ptr=(members).semembers_ptr; \
      (r_or_w_seobjectmem).semembers.semembers_handle=(members).semembers_handle; \
      (r_or_w_seobjectmem).seobjectmem_ptr = SEMEMBERS_PTR(members)+(index)
#  define SEOBJECTMEM_ASSIGN_PTR(r_or_w_seobjectmem,seobjectmem) \
      (r_or_w_seobjectmem).semembers.semembers_ptr=(members).semembers_ptr; \
      (r_or_w_seobjectmem).semembers.semembers_handle=(members).semembers_handle; \
      (r_or_w_seobjectmem).seobjectmem_ptr = (seobjectmem)
#  define SEOBJECTMEM_PTR(r_or_w_seobjectmem) \
     (r_or_w_seobjectmem).seobjectmem_ptr
#  define SEOBJECTMEM_MEMBERS(r_or_w_seobjectmem) \
     (r_or_w_seobjectmem).semembers
#  define SEOBJECTMEM_UNLOCK_R(rseobjectmem) \
     SEMEMBERS_UNLOCK_R((rseobjectmem).semembers)
#  define SEOBJECTMEM_UNLOCK_W(wseobjectmem) \
     SEMEMBERS_UNLOCK_W((wseobjectmem).semembers)
   /* following cast allows W to be passed to a function that accepts only R */
#  define SEOBJECTMEM_CAST_R(wseobjectmem)  \
      *((rSEObjectMem *)(&(wseobjectmem)))

#endif
#define SEOBJECTMEM_VAR(OMEM) (&(SEOBJECTMEM_PTR(OMEM)->value))



#if JSE_PACK_OBJECTS==0
   /* For unlimited memory, we give it a reasonable number of elements
    * to avoid massive reallocations later.
    */
#  define OBJ_DEFAULT_SIZE 8
#else
   /* For Min Memory, we allocate only as much space as needed.
    */
#  if JSE_FUNCTION_LENGTHS==1
#     define OBJ_DEFAULT_SIZE 1
#  else
#     define OBJ_DEFAULT_SIZE 0
#  endif
#endif

struct _SEObject
{
   /* Used to link together all objects allocated on the system */
   hSEObject hNext;

   /* otherwise they are the same */
#  if JSE_PACK_OBJECTS==0
   MemCountUInt alloced;        /* how many members allocated */
#  endif
   MemCountUInt used;           /* how many members used */

#  if 0!=JSE_PER_OBJECT_CACHE
      /* Cache often used members */
      MemCountUInt cache;
#  endif

#  if JSE_OBJECTDATA != 0
      void _FAR_ *data;
#  endif
#  if defined(JSE_DYNAMIC_OBJS)
      struct jseObjectCallbacks *callbacks;
#  endif

   struct Function *func;       /* if this is a function, this is
                                 * it's _call property
                                 */

   /* The structure is realloced as necessary to store all objects.
    * This cannot be part of the object proper, because we have
    * multiple pointer to the object spread throughout the system,
    * and reallocing would be bad
    */
   hSEMembers hsemembers;

   /* The member array is sorted by the Name key. */
   uword8 flags;
};


/* Garbage collection variables. The 'free list' is a mempool of
 * old object structures we store so we don't have to allocate
 * and free them. When we free an object, it goes to this free list.
 * We do the same thing for the 'seObjectMem' array that goes
 * in structures. However, we limit the size of these arrays.
 * Sure, a bigger array will always work for the minimum size
 * array we need for a new object, but by saving such an array
 * that had been used to store a really big object with lots of
 * members, we waste a lot of space, so we have a cutoff on how
 * big of an object we will save the member array for.
 */


#if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
#  define IS_ARRAY                  0x0008
#  define OBJ_IS_DYNAMIC            0x0010
#  define SEOBJ_DYNAMIC_UNDEFINED   0x0020
#  define SEOBJ_DONT_SORT           0x0040
#endif

/* exactly analogous to the one in vars */
#  define SEOBJ_FREE_LIST_BIT       0x0001
#  define SEOBJ_SWEEP_BIT           0x0002
#if 0 && JSE_MEMEXT_OBJECTS==0 && JSE_MEMEXT_MEMBERS==0
#  define SEOBJ_FLAG_BIT            0x0004
#else
   struct VarRecurse
   {
      struct VarRecurse *prev;
      hSEObject been_here;
   };
#  define CHECK_FOR_RECURSION(PREV_RECURSE_PTR,NEW_RECURSE,OBJECT_HANDLE)                    \
      assert( hSEObjectNull != (OBJECT_HANDLE) );                                            \
      (NEW_RECURSE).been_here = (OBJECT_HANDLE);                                             \
      if ( NULL != ((NEW_RECURSE).prev = (PREV_RECURSE_PTR)) )                               \
      {                                                                                      \
         uint recurse_depth = 0;                                                             \
         do {                                                                                \
            if ( (PREV_RECURSE_PTR)->been_here == (NEW_RECURSE).been_here                    \
                 /* recursion too-deep leads to stack error; 50 is good enough */            \
              || 50 < ++recurse_depth )                                                      \
            {                                                                                \
               assert( recurse_depth <= 50);                                                 \
               (NEW_RECURSE).been_here = hSEObjectNull; /* indicate recursion */             \
               break;                                                                        \
            }                                                                                \
         } while ( NULL != ((PREV_RECURSE_PTR)=(PREV_RECURSE_PTR)->prev) );                  \
      }
#  define ALREADY_BEEN_HERE(MYRECURSE)    ( hSEObjectNull == (MYRECURSE).been_here )

#endif

#if defined(SEOBJ_FLAG_BIT)
   const struct Function * NEAR_CALL sevarGetFunction(struct Call *call,rSEVar obj);
#else
   const struct Function * NEAR_CALL sevarGetFunctionRecurse(struct Call *call,rSEVar obj,struct VarRecurse *prev);
#  define sevarGetFunction(CALL,ROBJ) sevarGetFunctionRecurse((CALL),(ROBJ),NULL)
#endif



   void
seobjMakeEcmaArray(struct Call *call,wSEObject wobj);
#define SEOBJ_MAKE_DYNAMIC(obj) (SEOBJECT_PTR(obj)->flags |= OBJ_IS_DYNAMIC)
#define SEOBJ_MAKE_DYNAMIC_UNDEFINED(obj) (SEOBJECT_PTR(obj)->flags |= SEOBJ_DYNAMIC_UNDEFINED)
#define SEOBJ_IS_DYNAMIC(obj) (SEOBJECT_PTR(obj)->flags & OBJ_IS_DYNAMIC)

#if defined(SEOBJ_FLAG_BIT)
#  define SEOBJ_MARK_FLAGGED(o) (SEOBJECT_PTR(o)->flags |= SEOBJ_FLAG_BIT)
#  define SEOBJ_MARK_NOT_FLAGGED(o) (SEOBJECT_PTR(o)->flags &= ~SEOBJ_FLAG_BIT)
#  define SEOBJ_WAS_FLAGGED(o) ((SEOBJECT_PTR(o)->flags & SEOBJ_FLAG_BIT)!=0)
#endif

/* Search a given object for the member. This doesn't do any
 * fancy stuff like search prototype chains. Either it has the
 * member or it does not. NULL = member not found.
 */
   rSEObjectMem NEAR_CALL
rseobjGetMemberStructEx(struct Call *call,rSEObject rthis,VarName Name
#  if JSE_MEMEXT_READONLY!=0
      ,jsebool returnReadOnly /* if false the what this returns is really a rSEObjectMem */
#  endif
#  if JSE_COMPACT_LIBFUNCS!=0
      ,jsebool libExpand
#  endif
);
#if JSE_MEMEXT_READONLY==0
#  if JSE_COMPACT_LIBFUNCS==0
#     define rseobjGetMemberStruct rseobjGetMemberStructEx
#     define rseobjGetMemberStructNoExpand rseobjGetMemberStructEx
#  else
#     define rseobjGetMemberStruct(c,o,m) rseobjGetMemberStructEx((c),(o),(m),True)
#     define rseobjGetMemberStructNoExpand(c,o,m) rseobjGetMemberStructEx((c),(o),(m),False)
#  endif
#  define wseobjGetMemberStructNoExpand rseobjGetMemberStructNoExpand
#  define wseobjGetMemberStruct rseobjGetMemberStruct
#else
#  if JSE_COMPACT_LIBFUNCS==0
#     define rseobjGetMemberStruct(c,o,m) rseobjGetMemberStructEx((c),(o),(m),True)
#     define rseobjGetMemberStructNoExpand(c,o,m) rseobjGetMemberStructEx((c),(o),(m),True)
#     define wseobjGetMemberStruct(c,o,m) rseobjGetMemberStructEx((c),(o),(m),False)
#     define wseobjGetMemberStructNoExpand(c,o,m) rseobjGetMemberStructEx((c),(o),(m),False)
#  else
#     define rseobjGetMemberStruct(c,o,m) rseobjGetMemberStructEx((c),(o),(m),True,True)
#     define rseobjGetMemberStructNoExpand(c,o,m) rseobjGetMemberStructEx((c),(o),(m),True,False)
#     define wseobjGetMemberStruct(c,o,m) rseobjGetMemberStructEx((c),(o),(m),False,True)
#     define wseobjGetMemberStructNoExpand(c,o,m) rseobjGetMemberStructEx((c),(o),(m),False,False)
#  endif
#endif

#if JSE_MEMEXT_READONLY==0 && JSE_MEMEXT_MEMBERS==0 && JSE_COMPACT_LIBFUNCS==0
#  define rseobjIndexMemberStruct(c,o,i)  (SEOBJECT_PTR(o)->hsemembers+(i))
#else
      rSEObjectMem NEAR_CALL
   rseobjIndexMemberStructEx(struct Call *call,rSEObject robj,MemCountUInt member
#     if JSE_MEMEXT_READONLY!=0
         ,jsebool returnReadOnly /* if false the what this returns is really a rSEObjectMem */
#     endif
   );
#  if JSE_MEMEXT_READONLY==0
#     define rseobjIndexMemberStruct rseobjIndexMemberStructEx
#     define wseobjIndexMemberStruct rseobjIndexMemberStruct
#  else
#     define rseobjIndexMemberStruct(c,o,i) rseobjIndexMemberStructEx((c),(o),(i),True)
#     define wseobjIndexMemberStruct(c,o,i) rseobjIndexMemberStructEx((c),(o),(i),False)
#  endif
#endif


   rSEVar NEAR_CALL
seobjGetFuncVar(struct Call *call,rSEVar thefunc,
                VarName entry, /* constructor_entry or call_entry */
                rSEObjectMem *rMem /* callers must free IF ptr is not null */);


/* If the object has the variable, return it. Search prototype
 * chains. NULL = failure.
 */
#if defined(SEOBJ_FLAG_BIT)
   rSEObjectMem NEAR_CALL seobjChildMemberStruct(struct Call *call,rSEObject robj,
                             VarName member);
#else
   rSEObjectMem NEAR_CALL seobjChildMemberStructRecurse(struct Call *call,rSEObject robj,
                             VarName member,struct VarRecurse *prev);
#  define seobjChildMemberStruct(CALL,ROBJ,MEMBER) \
          seobjChildMemberStructRecurse((CALL),(ROBJ),(MEMBER),NULL)
#endif

/* Another candidate for inlining */
#define SEOBJ_DEFAULT_PROTOTYPE(call,this) \
  (( (this->flags & IS_ARRAY)!=0 ) ? call->hArrayPrototype :\
  ((this->func==NULL)?call->hObjectPrototype:call->hFunctionPrototype))


/* Create a new object member of the given name. It is assertable it
 * does not already exist. In the case of unordered objects, name is
 * supposed to be NULL and is ignored. Make its initial value the
 * same as the given seVar.  If newObjectMem is NULL then will not return
 * the result.
 */
void NEAR_CALL seobjCreateMemberCopy(wSEObjectMem *newObjectMem,
                                     struct Call *call,wSEObject wobj,
                                     VarName member,rSEVar rCopyFrom);

/* Create an object member, make it undefined. It is assertable it
 * does not already exist.
 */
wSEObjectMem NEAR_CALL SEOBJ_CREATE_MEMBER(struct Call *call,wSEObject wobj,
					   VarName member);
#define SEOBJ_CREATE_MEMBER(c,o,m) seobjCreateMemberType(c,o,m,VUndefined)

/* Create an object member, make it the given type. It is assertable it
 * does not already exist.
 */
wSEObjectMem NEAR_CALL seobjCreateMemberType(struct Call *call,wSEObject wobj,
                                             VarName member,jseVarType type);

/* Creates a new member and returns it, but only if it wasn't already
 * there. Otherwise, return the existing member. The boolean 'found'
 * will be true if it already existed. If it was created, it will be
 * initialized as undefined.
 */
wSEObjectMem seobjNewMember(struct Call *call,wSEObject wobj,
                            VarName members,jsebool *found);


/* Get rid of a member, boolean return is True if a member was deleted,
 * False if it didn't exist.
 */
jsebool NEAR_CALL seobjDeleteMember(struct Call *call,wSEObject wobj,VarName member,
                                    jsebool testDontDeleteAttribute);

/* Get rid of a member, boolean return is True if a member was deleted,
 * False if it didn't exist. This one will call the dynamic delete
 * if present. Otherwise it just calls on through to seobjDeleteMember.
 */
   jsebool NEAR_CALL
seobjFullDeleteMember(struct Call *call,hSEObject hobj,VarName member);


/* if unordered then allocate and initialize to have no members a new object.
 * make it unordered, used for ScopeChains and Function constant storage.
 * Else create a regular blank object */
hSEObject seobjNew(struct Call *call,jsebool ordered);


#define HP_DEFAULT      0
#define HP_NO_PROTOTYPE 1
#define HP_REFERENCE    2

/* Returns true if the property exists (using the _hasProperty routine.)
 * Will stick the property into the given destination. Note that getting
 * the property can be a result of calling _get if the object also
 * has that dynamic property.
 */
jsebool NEAR_CALL seobjHasProperty(struct Call *call,rSEObject robj,VarName prop,
                                   wSEVar dest,int flags);

/* Note: the function contains the 'Implicit' attributes, so separate
 * them out and store them there, and bring them back from there.
 */
   void NEAR_CALL
seobjSetAttributes(struct Call *call,hSEObject hthis,VarName prop,seAttribs attribs);
   seAttribs NEAR_CALL
seobjGetAttributes(struct Call *call,hSEObject hthis,VarName prop);

void seobjSetFunction(struct Call *call,hSEObject hobj,struct Function *func);


#if defined(__cplusplus)
   }
#endif

#endif
