/* srccore/var.h
 *
 *   defines the seVar struct and related structures, used to
 *   track and operate on the basic Javascript values
 *   used in programs, like numbers, strings, and objects.
 */

/* (c) COPYRIGHT 1993-2000         NOMBAS, INC.
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

#ifndef _SRCCORE_VAR_H
#define _SRCCORE_VAR_H


/* SE440 Notes
 *
 *
 * The basic struct 'seVar' can contain any of the basic JavaScript
 * types, numbers, objects, string, etc. It has a type field and
 * then 8 bytes of data storage (as a union). The various types
 * determine how to read the 8 bytes of data storage, by determining
 * which member of the field is accessed.
 *
 * Note that seVars never appear 'in limbo'. The garbage collector
 * needs to know where to find every one of them so it can figure
 * out what structures are still in use. seVars appear only in
 * a few places: the call structure itself, the secode stack,
 * an object member, or in the special API variable tracking
 * structures. Even adding them to the call requires modifying the
 * garbage collector to know about them. You can NEVER add them
 * as local variable, only pointers to them. If you need a temporary
 * seVar to store information, create one using STACK_PUSH and
 * STACK_POP it when you are done. See Garbage Collection notes
 * below for more info.
 *
 * In addition, the struct has 4 other types, VStorage, VLibFunc,
 * VReference, and VReferenceIndex. These are virtual types.
 *
 * VReferences are used for one variable to refer to another. They
 * are needed to support several legacy ScriptEase behaviors. First,
 * the API still can return a virtual structure member that can
 * be used for reading or writing. For instance, jseMember() can
 * do this. Since that reading or writing isn't determined until
 * later, we store this as a reference. Once we actually read
 * from it, we check for a dynamic _get then, and likewise for
 * write. The second behavior is pass-by-reference, where one
 * variable is actually referring to another variable. Again, this
 * is done by having that variable be a VReference to another
 * variable, effectively a pointer to it.
 *
 * References cannot be 'doubly-indirectly'. You never have a
 * reference which, when you check the object member, find that
 * the new member is also a reference. Instead, each new reference
 * points to the real seVar. References are used for only a
 * few language constructs, and never 'replace' an existing
 * member. Thus, you don't have to worry about pointing to
 * a valid member but then it becoming a reference and thus
 * violating the double-indirect rule.
 *
 * VReferenceIndex is an optimization of VReference. It has an
 * index into the object array so we can quickly manipulate that
 * member rather than having to relook it up. It is used only
 * in the cases that we know the object cannot change. VReferenceIndex
 * is a short-lived only type.
 *
 * VStorage is only used on the secode stack to store some information
 * for a function call, it can never be a valid variable.
 *
 * VLibFunc is an object-member-only item. It defers the creation of
 * a wrapper function, which involves creating a whole object and
 * function structure. If the object member is ever accessed,
 * VLibFuncs are immediately expanded to the full-blown stuff and
 * then access continues. For a typical script, if we include
 * lots of libraries, most of those provided functions are never
 * used and thus never expanded. This is a big time and space
 * saver.
 *
 *
 *
 * Garbage Collection:
 *
 * We garbage collect seObjects, seStrings, Functions, and VarNames.
 * From the Call structure, we can get list of all of these items
 * that we have allocated. We can also track down all the places
 * it can be referred to. We perform a simple mark-sweep garbage
 * collection, and free all items that are no longer used.
 *
 * Items that are freed are normally returned to a pool of available
 * items to be reused, so allocating and freeing by actually calling
 * the system memory routines is kept to a minimum. This mechanism
 * makes for very efficient code, and also gives a great indication
 * of when to do collection (when we run out of our pooled items.)
 * Because of this mechanism, advanced forms of garbage collection
 * simply don't make sense for our needs. The simple mark-sweep
 * collector meshes well with this system, and it works pretty
 * quickly, a win-win situation. The items needed to be collected has
 * been reduced from SE420, meaning that garbage collection is
 * faster than in the old version. Not having to collect 'Var'
 * structures (now 'seVar') really helps.
 *
 * Incremental collectors don't make much sense. We need the
 * garbage collection to trigger destructors, for instance, since
 * the API's forcing of a garbage collection has been defined
 * to cause this effect. Thus, we have to sweep all objects to
 * know which, if any, are free and have a destructor. It would
 * be possible to make the garbage collector more complex, but
 * I think the allocator pool mechanism makes partial collections
 * less efficient than our current method.
 *
 * Finally, tests have shown the collector to take up minimal
 * time, even when the test is designed to cause as many collections
 * as possible. It still amounts to only a small percent of execution
 * time. Thus, spending a lot of time to speed it up makes little
 * sense. Remember, purely computational scripts do not generate
 * any garbage. Only ones that create a lot of objects and strings,
 * and free them up a lot, do.
 */

/* Variable Debugging flags:
 *
 * These flags allow the core to be put through a thorough
 * set of tests that will find many possible bugs. It is
 * good to get the customer to use these as well for a
 * debug pass. After all, we'd love to we have no bugs, but
 * that is unrealistic. These flags will cause situations
 * to come up that might only come up very infrequently in
 * production code. Thus, the error is caught during
 * development, and we can fix it, rather than have an
 * infrequent crash in the customer's product.
 *
 *
 * JSE_ALWAYS_COLLECT
 *    If it is on, we collect every time we could collect.
 *    This is slow, but it really helps find garbage
 *    collection bugs.
 *
 * JSE_DONT_POOL
 *    Normally when we finish with an item, we pool
 *    it. This allows us to quickly give it out again,
 *    rather than using the memory allocation routines
 *    which are slow. However, this often makes a
 *    dangling pointer point to memory which then gets
 *    reused, so it points to good, but wrong memory.
 *    This turns it off.
 *
 * JSE_NEVER_FREE
 *    An extension of the above idea, many times the
 *    memory allocator will give us back the same
 *    memory, so it still acts like it does when we
 *    pool. This flag frees no memory for garbage
 *    collected items, ever, so they all point into
 *    that block which has been memset with garbage.
 *    Hopefully such an access will see garbage and
 *    crash. NYI: If I had some way to also tell the
 *    system to make any accesses to this memory
 *    a memory violation, that would be great.
 */

#if defined(__cplusplus)
   extern "C" {
#endif


#include "sestring.h"
#include "seobjhan.h"

struct InvalidVarDescription
{
   jsechar VariableName[100]; /* set to \0 if cannot figure out a good name */
   jsechar VariableType[50];  /* put in message describing type of the variable */
   jsechar VariableWanted[200]; /* message describing type of variable needed */
};

struct seCallStackVar
{
   struct seAPIVar *var;
   jsebool free_on_del; /* if the variables are to be unlocked on exit */
};

struct seCallStack
{
   struct seCallStackVar *vars;  /* realloced as needed */

   /* must be byte 5 */
#  if ( 2 <= JSE_API_ASSERTLEVEL )
      ubyte cookie;
#  endif
   uint Count;                  /* size of stack */
};

#define SECALLSTACK_PEEK(s,e) ((s)->vars[(s)->Count -1 - (e)].var)
#define SECALLSTACK_DEPTH(s) ((s)->Count)

   void
secallstackPush(/*struct Call *call,*/struct seCallStack *This,
                struct seAPIVar *v,jsebool deleteme);


/* ---------------------------------------------------------------------- */

/* See the full description at the top of the values for what these
 * values do.
 *
 * The name 'seVar' is historic, it has evolved from 'Var' and
 * 'jseVariable'. I would prefer 'seValue'.
 */

#define VNumber     jseTypeNumber
#define VString     jseTypeString
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
#  define VBuffer   jseTypeBuffer
#endif
#define VObject     jseTypeObject
#define VNull       jseTypeNull
#define VUndefined  jseTypeUndefined
#define VBoolean    jseTypeBoolean

/* only used in special cases, the above are actual values.
 * See the writeup at the top of this file.
 */
#define VStorage    7
#if JSE_COMPACT_LIBFUNCS==1
#  define VLibFunc    8
#endif
#define VReference      9
#define VReferenceIndex 10


#define SEVAR_IS_VALID_TYPE(t) ((t)<VStorage)


typedef ubyte jseVarType;


/* More than one variable can share the same string, but
 * point to a different place in it (i.e. a cfunction
 * statement 'var a = "foo"; var b = a + 1;') This
 * is how we do it.
 */
struct seVarString
{
   struct seString *data;       /* contains 'data' and 'length' members, can be collected */
   JSE_POINTER_SINDEX loffset;  /* as the offset for times like 'a = b + 4' where b
                                 * is a string in a cfunction, or the offset for
                                 * deref cases i.e. a = b[4] in a cfunction. Usually is 0.
                                 */
};

/* If it is a reference */
struct seReference
{
   hSEObject hBase;
   VarName reference;           /* if a VReferenceIndex, this is the index cast
                                 * to a VarName
                                 */
};

/* If the seVar is an object */
struct seObjVar
{
   hSEObject hobj;
   hSEObject hSavedScopeChain;
};

#if JSE_COMPACT_LIBFUNCS==1
struct seLibFunc
{
   struct jseFunctionDescription const *funcDesc;
   void _FAR_ * *data;
};
#endif


/* An seVar is a real value on the system. */
struct _SEVar
{
   union {
      jsenumber num_val;                /* used for VNumber */
      jsebool   bool_val;               /* used for VBoolean */
      ulong  long_value;                /* used only for VStorage */
      void  *ptr_value;                 /* again, VStorage */
      struct seVarString string_val;    /* for VString and VBuffer */
      struct seObjVar object_val;       /* for VObject */
      struct seReference ref_val;       /* VReference and VReferenceIndex */
#     if JSE_COMPACT_LIBFUNCS==1
      struct seLibFunc libfunc_val;     /* VLibFunc */
#     endif
   } data;

   jseVarType type;
};
typedef JSE_MEMEXT_R struct _SEVar * rSEVar;
typedef struct _SEVar * wSEVar;


#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
#  define SEVAR_ARRAY_PTR(v) ((v)->type==VString || (v)->type==VBuffer)
#else
#  define SEVAR_ARRAY_PTR(v) ((v)->type==VString)
#endif


#define SEVAR_GET_TYPE(v) ((v)->type)
#define SEVAR_GET_OBJECT(v) ((v)->data.object_val.hobj)
#define SEVAR_GET_STRING(v) ((v)->data.string_val)


#define GV_DEFAULT      0
#define GV_NO_PROTOTYPE 1

   jsebool NEAR_CALL
sevarGetValue(struct Call *call,wSEVar obj,VarName mem,wSEVar dest,int flags);
   jsebool NEAR_CALL
sevarPutValueEx(struct Call *call,wSEVar obj,VarName mem,wSEVar val,jsebool is_index);

#define SEVAR_PUT_VALUE(c,o,m,v) sevarPutValueEx((c),(o),(m),(v),False)


#if (0==JSE_INLINES) || (0!=JSE_MEMEXT_OBJECTS) || (0!=JSE_MEMEXT_MEMBERS)
   void NEAR_CALL SEVAR_DEREFERENCE(struct Call *call,wSEVar v);
#else
#  define SEVAR_DEREFERENCE(c,v)                                                             \
   {                                                                                         \
      if( (v)->type==VReferenceIndex )                                                       \
      {                                                                                      \
         rseobjIndexMemberStruct((c),(v)->data.ref_val.hBase,                                \
            (MemCountUInt)(JSE_POINTER_UINT)(v)->data.ref_val.reference);                    \
         SEVAR_COPY((v),SEOBJECTMEM_VAR(rseobjIndexMemberStruct((c),(v)->data.ref_val.hBase, \
            (MemCountUInt)(JSE_POINTER_UINT)(v)->data.ref_val.reference)));                  \
      }                                                                                      \
      else if( (v)->type==VReference )                                                       \
      {                                                                                      \
         wSEVar deref_tmp = STACK_PUSH;                                                      \
         SEVAR_INIT_OBJECT(deref_tmp,(v)->data.ref_val.hBase);                               \
         sevarGetValue((c),deref_tmp,(v)->data.ref_val.reference,(v),GV_DEFAULT);            \
         if( !CALL_QUIT(c) ) STACK_POP;                                                      \
      }                                                                                      \
      assert( (v)->type<VReference );                                                        \
   }
#endif

/* NYI: no longer a macro, make lowercase name */
   JSE_POINTER_UINDEX NEAR_CALL
SEVAR_STRING_LEN(rSEVar v);
   JSE_MEMEXT_R void *
NEAR_CALL sevarGetData(struct Call *call,rSEVar v);

#if 0!=JSE_MEMEXT_STRINGS
   void
SEVAR_FREE_DATA(struct Call *call,JSE_MEMEXT_R void *data);
#else
#define SEVAR_FREE_DATA(c,d) /* nothing */
#endif

   void NEAR_CALL
sevarValidateIndex(struct Call *call,const struct seVarString *it,JSE_POINTER_SINDEX start,
                   JSE_POINTER_UINDEX length,jsebool isBuffer/*else string*/);


#define SEVAR_CONSTANT_STRING(v) (SEVAR_GET_STRING(v).data->flags |= STR_CONSTANT)


#define SEVAR_COPY(t,s) (*(t) = *(s))

/* In this one and the string/buffer below, we initialize it to undefined
 * so if the object initializer part causes a collection, it will be
 * valid. This is because we might have stuff like:
 *
 * SEVAR_INIT_OBJECT(tmp,seobjNew(call,True));
 */
#define SEVAR_INIT_OBJECT(v,o) \
   ((v)->data.object_val.hobj = (o), \
    (v)->data.object_val.hSavedScopeChain = hSEObjectNull,\
    (v)->type = VObject)
#define SEVAR_INIT_LIBFUNC(v,f,d) \
   ((v)->type = VLibFunc, (v)->data.libfunc_val.funcDesc = (f), \
    (v)->data.libfunc_val.data = (d))

#define SEVAR_INIT_UNDEFINED(v) ((v)->type = VUndefined)
#define SEVAR_INIT_NULL(v) ((v)->type = VNull)
#define SEVAR_INIT_NUMBER(v,n) \
   ((v)->data.num_val = (n), (v)->type = VNumber)
#define SEVAR_INIT_SLONG(v,l) \
   ((v)->data.num_val = JSE_FP_CAST_FROM_SLONG(l), (v)->type = VNumber)
#define SEVAR_INIT_BOOLEAN(v,b) \
   ((v)->data.bool_val = (b), (v)->type = VBoolean)

#if defined(JSE_MBCS) && (JSE_MBCS!=0)

   /* Best case, we already know the byte length, this is MUCH faster */
#  define SEVAR_INIT_STRING(c,v,s,l,bl) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l),(bl)))

   /* NULL-terminated MBCS strings have a quicker way to determine length */
#  define SEVAR_INIT_STRING_NULLLEN(c,v,s,l) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l),strlen(s)))

   /* worst case, don't just use this arbitrarily, try to determine if the
    * context allows one of the above two, which are MUCH faster
    */
#  define SEVAR_INIT_STRING_STRLEN(c,v,s,l) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l),BYTECOUNT_FROM_STRLEN((s),(l))))

#else
#  define SEVAR_INIT_STRING(c,v,s,l) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l)))
#  define SEVAR_INIT_STRING_STRLEN(c,v,s,l) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l)))
#  define SEVAR_INIT_STRING_NULLLEN(c,v,s,l) \
      SEVAR_INIT_STRING_AS((v),sestrCreate((c),(s),(l)))
#endif
#define SEVAR_INIT_BUFFER(c,v,s,l) \
   SEVAR_INIT_BUFFER_AS((v),sestrCreateBuffer((c),(s),(l)))

#define SEVAR_INIT_STRING_AS(v,s) \
   ((v)->type = VUndefined, (v)->data.string_val.data = (s), \
    (v)->type = VString, (v)->data.string_val.loffset = 0)
#define SEVAR_INIT_BUFFER_AS(v,s) \
   ((v)->type = VUndefined, (v)->data.string_val.data = (s), \
    (v)->type = VBuffer, (v)->data.string_val.loffset = 0)

#define SEVAR_INIT_ARRAY_SIBLING(v,s,o) \
   (SEVAR_COPY(v,s), (v)->data.string_val.loffset += (o))
#define SEVAR_INIT_OBJECT_SIBLING(v,s) \
   SEVAR_COPY(v,s)


#define SEVAR_INIT_REFERENCE(v,b,m) \
   ((v)->data.ref_val.hBase = (b), (v)->data.ref_val.reference = (m), (v)->type = VReference)
#define SEVAR_INIT_REFERENCE_INDEX(v,b,m) \
   ((v)->data.ref_val.hBase = (b), (v)->data.ref_val.reference = (m), (v)->type = VReferenceIndex)
#define SEVAR_INIT_STORAGE_LONG(v,l) \
   ((v)->type = VStorage, (v)->data.long_value = (l))
#define SEVAR_INIT_STORAGE_PTR(v,p) \
   ((v)->type = VStorage, (v)->data.ptr_value = (p))


   void NEAR_CALL
sevarInitType(struct Call *call,wSEVar dest,jseVarType type);

   void NEAR_CALL
SEVAR_INIT_BLANK_OBJECT(struct Call *call,rSEVar this);
#define SEVAR_INIT_BLANK_OBJECT(c,t) SEVAR_INIT_OBJECT((t),seobjNew(c,True))

   void NEAR_CALL
SEVAR_INIT_UNORDERED_OBJECT(struct Call *call,rSEVar this);
#define SEVAR_INIT_UNORDERED_OBJECT(c,t) SEVAR_INIT_OBJECT((t),seobjNew(c,False))

   void NEAR_CALL
sevarInitNewObject(struct Call *call,wSEVar thisvar,rSEVar thefunc);


#define SEVAR_GET_NUMBER(v) ((v)->data.num_val)
#define SEVAR_GET_BOOLEAN(v) ((jsebool)((v)->data.bool_val))
#define SEVAR_GET_SLONG(v) (JSE_FP_CAST_TO_SLONG((v)->data.num_val))
#define SEVAR_PUT_SLONG(v,l) ((v)->data.num_val = JSE_FP_CAST_FROM_SLONG(l))

#define SEVAR_GET_STORAGE_LONG(v) ((v)->data.long_value)
#define SEVAR_GET_STORAGE_PTR(v) ((v)->data.ptr_value)

/* Does conversion to get the appropriate value. SEVAR_GET_NUMBER()
 * above returns the number data field which only works for
 * type==VNumber || type==VBoolean.
 */
jsenumber SEVAR_GET_NUMBER_VALUE(rSEVar v);

   JSE_POINTER_UINDEX NEAR_CALL
sevarGetArrayLength(struct Call *call,rSEVar this,JSE_POINTER_SINDEX *MinIndex);
   void NEAR_CALL
sevarSetArrayLength(struct Call *call,wSEVar this,JSE_POINTER_SINDEX MinIndex,
                    JSE_POINTER_UINDEX MaxIndex);

/* Both take _call into account if there */
#if (0==JSE_INLINES) || (0!=JSE_MEMEXT_OBJECTS) || (0!=JSE_MEMEXT_MEMBERS)
   jsebool NEAR_CALL SEVAR_IS_FUNCTION(struct Call *call,rSEVar obj);
#else
#  define SEVAR_IS_FUNCTION(c,o) \
      (SEVAR_GET_TYPE(o)==VObject && (SEVAR_GET_OBJECT(o)->func!=NULL ||\
       rseobjGetMemberStruct((c),SEVAR_GET_OBJECT(o),STOCK_STRING(_call))!=NULL))
#endif

   void NEAR_CALL
sevarDoPut(struct Call *call,wSEVar wPlace,wSEVar wVal);

#if 0!=JSE_INLINES
#  define SEVAR_DO_PUT(c,p,v)     \
      if( (p)->type<VReference )  \
         SEVAR_COPY(p,v);         \
      else                        \
         sevarDoPut(c,p,v);
#else
#  define SEVAR_DO_PUT(c,p,v)  sevarDoPut((c),(p),(v))
#endif

/* Super anal checker to try to make darn sure the variable
 * is valid. Use it like:
 *
 * assert( sevarIsValid(call,myvar) );
 */
#ifndef NDEBUG
   jsebool NEAR_CALL
sevarIsValid(struct Call *call,rSEVar check);
#endif


#include "seobject.h"
#include "seapivar.h"


/* utility functions */

   void NEAR_CALL
GetDotNamedVar(struct Call *call,wSEVar me,const jsecharptr NameWithDots,
               jsebool FinalMustBeVObject);

enum whichDynamicCall
{
   /* this first bunch only called if SEOBJ_DYNAMIC_UNDEFINED and members does not exist */
    dynacallGet = 0
   ,dynacallPut
   ,dynacallCanput
   ,dynacallHas
   /* the next bunch are called always, even if SEOBJ_DYNAMIC_UNDEFINED */
   ,dynaBeginAlwaysCall
   ,dynacallDelete = dynaBeginAlwaysCall
   ,dynacallDefaultvalue
#  if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
   ,dynacallOperator,
#  endif
};

struct dynacallRecurse  /* structure to prevent calling a dynamic object while within that call */
{
   struct dynacallRecurse *prev; /* linked list of all such existing calls */
   enum whichDynamicCall whichCall;  /* which call is made, so that other dynacalls still work */
   hSEObject whichObject;  /* this object this is currently running on */
};

   jsebool NEAR_CALL
seobjCallDynamicProperty(struct Call *call,rSEObject rthis,
                         enum whichDynamicCall whichCall,
                         VarName PropertyName,rSEVar Parameter2,
                         wSEVar  dest);

   jsebool NEAR_CALL
seobjCanPut(struct Call *call,rSEObject robj,VarName name);


/* void sevarNewGlobalVariable(struct Call *call,seVar ngv);*/


/* The default name is where you put the 'object member' which you
 * were trying to access when a problem occured. NULL = none.
 */
   jsebool
FindNames(struct Call *call,rSEVar me,jsecharptr const Buffer,uint BufferLength,
          VarName default_name);
   void
DescribeInvalidVar(struct Call *this,rSEVar v,jseDataType vType,
                   const struct Function *FuncPtrIfObject,jseVarNeeded need,
                   struct InvalidVarDescription *BadDesc);
   void NEAR_CALL
AutoConvert(struct Call *call,wSEVar it,jseVarNeeded need);

   void NEAR_CALL
sevarDuplicateString(struct Call *call,wSEVar wSrcVar);

/* The given variable is filled in with the constant value compiled
 * from the text.
 */
   jsebool NEAR_CALL
sevarAssignFromText(wSEVar target,struct Call *call,jsecharptr Source,
                    jsebool *AssignSuccess,
                    jsebool MustUseFullSourceString,jsecharptr *End);

   void
ConcatenateStrings(struct Call *call,wSEVar dest,rSEVar s1,rSEVar s2);

   void
AppendString(struct Call *call,wSEVar dest,rSEVar s2);

/* conversion routines */


   jsenumber NEAR_CALL
convertToSomeInteger(jsenumber val,jseConversionTarget dest_type);

/* These do an ECMA conversion on the target, replacing the old value
 * with the ECMA-converted value.
 */
   void NEAR_CALL
sevarConvert(struct Call *call,wSEVar v,jseConversionTarget new_type);
   jsebool NEAR_CALL
sevarConvertToBoolean(struct Call *call,wSEVar var);
#define SEVAR_CONVERT_TO_BOOLEAN(c,v) \
   (((v)->type==VBoolean)?(v)->data.bool_val:sevarConvertToBoolean(c,v))

   jsenumber NEAR_CALL
sevarConvertToNumber(struct Call *call,wSEVar SourceVar);
   void NEAR_CALL
sevarConvertToString(struct Call *call,wSEVar wSourceVar);
   void NEAR_CALL
sevarConvertToObject(struct Call *call,wSEVar SourceVar);
   jsenumber
convertStringToNumber(struct Call *call,jsecharptr str,size_t lenStr);
   jsebool NEAR_CALL
sevarCallConstructor(struct Call *call,rSEVar this,rSEVar SourceVar,wSEVar new_var);


   jsebool NEAR_CALL
sevarCompare(struct Call *call,wSEVar vx,wSEVar vy,slong *CompareResult);

#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   jsebool NEAR_CALL SEVAR_COMPARE_EQUALITY(struct Call *call,rSEVar v1,
                                            rSEVar v2);
   /* return -1, 0, or 1 */
   sint NEAR_CALL SEVAR_COMPARE_LESS(struct Call *call,wSEVar vx,
                                     wSEVar vy);
#else
#  define SEVAR_COMPARE_EQUALITY(CALL,V1,V2) sevarECMACompareEquality(CALL,V1,V2,False)
   /* returns -1, 0, or 1 */
   sint NEAR_CALL sevarECMACompareLess(struct Call *call,wSEVar vx,wSEVar vy);
#  define SEVAR_COMPARE_LESS(CALL,V1,V2) sevarECMACompareLess(CALL,V1,V2)
#endif
jsebool NEAR_CALL sevarECMACompareEquality(struct Call *call,rSEVar vx,
                                           rSEVar vy,jsebool strictEquality);


/* garbage collection */

   void NEAR_CALL
collectUnallocate(struct Call *call);
#if 0==JSE_DONT_POOL
   void NEAR_CALL collectRefill(struct Call *call);
#endif
   void NEAR_CALL
callDestructors(struct Call *call);
   void NEAR_CALL
garbageCollect(struct Call *call);


/* Tries to allocate the given amount of memory. If it fails,
 * it performs a garbage collection and tries again. It
 * will return NULL if it still fails. In the case of returning
 * NULL, it will generate an out-of-memory error. The caller
 * should recover as gracefully as possible and take the
 * above behavior into account.
 */
   void *
jseMallocWithGC(struct Call *call,uint size);


/* ---------------------------------------------------------------------- */
/* anal stuff */
#ifndef NDEBUG
#  define JSE_INVALID_COLLECT 0xfa
#endif


#if defined(__cplusplus)
   }
#endif

#endif
