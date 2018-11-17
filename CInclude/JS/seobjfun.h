/* seobjfun.h    Common utilities for manipulating objects
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
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

#ifndef _SEOBJFUN_H
#  define _SEOBJFUN_H

#ifdef __cplusplus
   extern "C" {
#endif

#ifdef JSE_TOSOURCE_HELPER
   jseVariable objectToSourceHelper(jseContext jsecontext,jseVariable base_obj,
                                    const jsecharptr base_str);
#endif

#ifdef JSE_INSTANCEOF_HELPER
   jsebool jseInstanceof(jseContext jsecontext,jseVariable instanceVar,jseVariable classVar);
      /* return the equivalent of
       *    instanceVar instanceof classVar
       * This just checks of instanceof._prototype === classVar.prototype, or if
       * instanceof._prototype._prototype === classVar.prototype and so on, with some
       * limit for how far it will check just to make sure we don't get caught in some
       * loop.
       * This function is loose in its parameters, so instanceVar or classVar may be NULL
       * or don't have to be objects, in both cases this will return False.
       *
       * Example, to know if var inherits from String
       *    jseInstanceof(jsecontext,var,jseMember(jsecontext,NULL,"String"));
       */
#endif

#ifndef JSE_DATUM_HELPERS
#define JSE_DATUM_HELPERS 1
#endif

#if JSE_DATUM_HELPERS!=0

#define JSE_THIS_VAR ((jseVariable)-1)

/* All of the following functions are similar and will be
 * described here.
 *
 * Each function corresponds to jseCreateConvertedVariable()
 * with a similar target type. The formats are jseGetXXXData(),
 * where XXX is that same target type (i.e. jseToXXX for
 * the conversion function.) The return value of each function
 * is always the C type corresponding to the datum, i.e.
 * 'jsebool' for Boolean, 'const jsecharptr' for String,
 * etc.
 *
 * All functions will take the object and get the specified
 * member. The 'member' parameter can be a jseString instead
 * of a regular string. In order to retain Unicode compatibility
 * with your code, specify regular strings using the UNISTR()
 * macro, i.e. UNISTR("foo"). The member is converted to
 * the appropriate type. If the member does not exist or
 * cannot be converted to the appropriate type, an error
 * message is output. However, a usable value is still
 * returned. The will be 'False', 0, 0.0, UNISTR(""),
 * or a blank object as appropriate. This means that your
 * function can continue even with the error.
 *
 * You can specify several special values for the object.
 * ScriptEase often uses NULL to use the Global Object, and
 * thus function follows the convention. You can use the
 * special value 'JSE_THIS_VAR' to get members of the
 * current 'this' object. You can use 'JSE_NAMED_ARG'
 * to get the named argument with member giving the
 * name (NOTE: named arguments are not implemented yet in
 * ScriptEase but is planned for the future.)
 *
 * You may pass NULL as the member name to work with the
 * given 'object' directly. In this case, the 'object'
 * jseVariable might not really be an object, in fact it
 * can be any jseVariable. The parameter is named 'object'
 * simply because that is what it is in the most common
 * case.
 *
 * If you use jseReturnVar() in a jsecontext that has
 * already signalled an error, that is ignored. This
 * allows you to code wrapper functions that will continue
 * on their merry way, but if an error occured, their
 * work will just be ignored and the error returned.
 * Of course, if the function is complex or if it
 * has side effects in your code that should not be
 * called, you might need to abort on an error. Use
 * jseQuitFlagged() to determine if there was an error.
 * A useful method is to extract all of the data values
 * you are interested then do a single check to see
 * if there was an error.
 *
 * Realize that there are various different ways the
 * function can fail. You only know that it failed or
 * that it didn't. It is designed for typical wrapper
 * functions that either successfully get all the
 * values they need and return the result, or report
 * whatever error occurred. If you need more control,
 * to know exactly why it is failing, then use the
 * specific ScriptEase API functions such as
 * jseGetMember(), jseCreateConvertedVariable(),
 * jseGetNumber(), and so forth so that you can tell
 * exactly where a failure occurred.
 *
 * These functions are designed to only be used in
 * a wrapper function because they can generate temp
 * variables. Temp variables hang around until the
 * invoking wrapper function is complete, which is
 * normally quick. However if you generate them
 * outside of any function, they remain until the
 * context terminates. Thus, using these functions
 * in the main section of your code will effectively
 * leak memory.
 */

   jsebool
jseGetBooleanDatum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member);
   jsenumber
jseGetNumberDatum(jseContext jsecontext,jseVariable object,
                 const jsecharptr member);
   jsenumber
jseGetIntegerDatum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member);
   sword32
jseGetInt32Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member);
   uword32
jseGetUint32Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member);
   uword16
jseGetUint16Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member);
   const jsecharptr
jseGetStringDatum(jseContext jsecontext,jseVariable object,
                 const jsecharptr member,JSE_POINTER_UINDEX *length);

#endif

/* Initialize blank object, copying prototypes */
jsebool jseInitializeObject(jseContext jsecontext, jseVariable obj, const jsecharptr objName);
/* Construct a new standard object, calling _construct property, etc */
jsebool jseConstructObject(jseContext jsecontext, jseVariable obj, const jsecharptr objName,
                           jseStack stack);
   jseVariable
jseCreateNumberVariable(jseContext jsecontext,jsenumber v);

#if JSE_OBJECTDATA == 0
   /* if these objectdata function aren't implemented internally, they're still
    * useful to have.  So implement by adding a secret member to the object and
    * storing the pointer as a string
    */
   void jseSetObjectData(jseContext jsecontext,jseVariable variable,
                         void _FAR_ *data);
   void _FAR_ * jseGetObjectData(jseContext jsecontext,jseVariable variable);
#endif

#ifdef __cplusplus
   }
#endif

#endif
