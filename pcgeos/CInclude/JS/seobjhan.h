/* srccore/seobjhan.h
 *
 * Defines for JavaScript object handles.
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

#ifndef _SRCCORE_SEOBJHAN_H
#define _SRCCORE_SEOBJHAN_H

#if defined(__cplusplus)
   extern "C" {
#endif


#if JSE_MEMEXT_OBJECTS==0

   /* STANDARD ALLOC VERSION OF SEOBJECT */
   typedef struct _SEObject *hSEObject;
   typedef struct _SEObject *rSEObject;
   typedef struct _SEObject *wSEObject;

   /* the following macros are used by standard and mem-handle forms */
#  define hSEObjectNull ((hSEObject)NULL)
#  define SEOBJECT_ASSIGN(r_or_w_seobject,hseobject)  (r_or_w_seobject) = (hseobject)
#  define SEOBJECT_ASSIGN_LOCK_R(rseobject,hseobject) (rseobject) = (hseobject)
#  define SEOBJECT_ASSIGN_LOCK_W(wseobject,hseobject) (wseobject) = (hseobject)
#  define SEOBJECT_PTR(r_or_w_seobject) (r_or_w_seobject)
#  define SEOBJECT_HANDLE(r_or_w_seobject) (r_or_w_seobject)
#  define SEOBJECT_LOCK_R(rseobject)       /* do nothing */
#  define SEOBJECT_UNLOCK_R(rseobject)     /* do nothing */
#  define SEOBJECT_LOCK_W(wseobject)       /* do nothing */
#  define SEOBJECT_UNLOCK_W(wseobject)     /* do nothing */
#  define SEOBJECT_CAST_R(wseobject)       (wseobject)

#else

   /* MEMORY_HANDLE VERSION OF SEOBJECT */

   /* implementation must define the following six items */
   typedef jsememextHandle hSEObject;
#  define hSEObjectNull jsememextNullHandle
#  define seobjectAlloc() jsememextAlloc(sizeof(struct _SEObject),jseMemExtObjectType)
#  define seobjectFree(HSEOBJECT) jsememextFree((HSEOBJECT),jseMemExtObjectType)
#  define seobjectLockRead(HSEOBJECT) (JSE_MEMEXT_R struct _SEObject *) \
      jsememextLockRead((HSEOBJECT),jseMemExtObjectType)
#  define seobjectUnlockRead(HSEOBJECT,ROBJ) \
      jsememextUnlockRead((HSEOBJECT),(ROBJ),jseMemExtObjectType)
#  define seobjectLockWrite(HSEOBJECT) (struct _SEObject *) \
      jsememextLockWrite((HSEOBJECT),jseMemExtObjectType)
#  define seobjectUnlockWrite(HSEOBJECT,ROBJ) \
      jsememextUnlockWrite((HSEOBJECT),(ROBJ),jseMemExtObjectType)

   /* these typedefs help the common routines be used */
   typedef struct _rSEObject {
      JSE_MEMEXT_R struct _SEObject * seobject_ptr;
      hSEObject seobject_handle;
   } rSEObject;
#  if 0==JSE_MEMEXT_READONLY
      typedef rSEObject wSEObject;
#  else
      typedef struct _wSEObject {
         struct _SEObject * seobject_ptr;
         hSEObject seobject_handle;
      } wSEObject;
#  endif

   /* the following macros are used by standard and mem-handle forms */
#  define SEOBJECT_ASSIGN(r_or_w_seobject,hseobject) \
      (r_or_w_seobject).seobject_handle = (hseobject)
#  define SEOBJECT_PTR(r_or_w_seobject) (r_or_w_seobject).seobject_ptr
#  define SEOBJECT_HANDLE(r_or_w_seobject) (r_or_w_seobject).seobject_handle

#  define SEOBJECT_LOCK_R(rseobject) \
      (rseobject).seobject_ptr = seobjectLockRead((rseobject).seobject_handle)
#  define SEOBJECT_ASSIGN_LOCK_R(rseobject,hseobject) \
      (rseobject).seobject_ptr = seobjectLockRead((rseobject).seobject_handle=(hseobject))
#  define SEOBJECT_UNLOCK_R(rseobject) \
      seobjectUnlockRead((rseobject).seobject_handle,(rseobject).seobject_ptr)
#  define SEOBJECT_LOCK_W(wseobject) \
      (wseobject).seobject_ptr = seobjectLockWrite((wseobject).seobject_handle)
#  define SEOBJECT_ASSIGN_LOCK_W(wseobject,hseobject) \
      (wseobject).seobject_ptr = seobjectLockWrite((wseobject).seobject_handle=(hseobject))
#  define SEOBJECT_UNLOCK_W(wseobject) \
      seobjectUnlockWrite((wseobject).seobject_handle,SEOBJECT_PTR(wseobject))
   /* following cast allows W to be passed to a function that accepts only R */
#  define SEOBJECT_CAST_R(wseobject)  \
      *((rSEObject *)(&(wseobject)))
#endif

#if defined(__cplusplus)
   }
#endif

#endif
