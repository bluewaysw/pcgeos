/* seobjfun.c    Common utilities for manipulating objects
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

#include "jseopt.h"


#ifdef JSE_TOSOURCE_HELPER
/******************************************************
 ******************************************************
 *** Code for converting an object into source code ***
 ******************************************************
 ******************************************************/

/* A list of all objects we have already seen, along with the name
 * they have. This is used to allow self-referencing objects, so
 * we can just assign the member to the already-existing name.
 */
struct objectHelperPair
{
   jseVariable obj;
   const jsecharptr name;
};

struct objectHelperInfo
{
   /* Used to build the resulting string to be returned.
    */
   struct dynamicBuffer text;

   struct objectHelperPair *obj_seen;
   int num_seen,num_alloced;
};

static CONST_STRING(OBJ_HELPER_DATA,"object_to_string_helper_data");

   /* The basic goal of toSource() is to create a text string that
    * when 'eval()ed' will produce the exact object we had. This
    * algorithm gets most cases right. The text produced is NOT
    * going to be particularly easy to understand. Here is the
    * general idea. Suppose we define an object like this:
    *
    *   var a.foo = 10;
    *
    * And then use a.toSource()? What does that produce. The
    * following is the kind of thing produced:
    *
    *   ((new Function("var tmp1 = new Object(); tmp1.foo = 10; return tmp1;"))())
    *
    * Yes, ugly. The idea is that we make a function that can build
    * a duplicate of the object. Because it is a function we are able
    * to handle the hard cases, like objects that refer to themself.
    * We then call the created function and return its result as the
    * result of the expression. Bingo, the original object is created.
    *
    * Got it? Maybe you want to reread that. Sorry, its as clear
    * as I can make it.
    */

   jseVariable
objectToSourceHelper(jseContext jsecontext,jseVariable base_obj,const jsecharptr base_str)
{
   /* Since we need to recursively call helper toSource functions,
    * those functions need to know what functions we have already
    * enumerated. We use one list for all helpers to share.
    */
   struct objectHelperInfo *info =
      (struct objectHelperInfo *)
      jseGetSharedData(jsecontext,OBJ_HELPER_DATA);

   /* If we are the first helper called, we must get rid of the
    * shared data when done.
    */
   jsebool orig = (info==NULL);

   /* For enumerating members */
   const jsecharptr memberName;
   jseVariable member = NULL;

   jsechar buffer[20];

   struct dynamicBuffer escapedName;

   /* final value to return */

   jseVariable ret = jseCreateVariable(jsecontext,jseTypeString);


   /* Let's add ourself to the objectHelperPair table.
    */
   if( orig )
   {
      assert( info==NULL );
      info = jseMustMalloc(struct objectHelperInfo,sizeof(struct objectHelperInfo));
      dynamicBufferInit(&(info->text));

      dynamicBufferAppend(&(info->text),UNISTR("((new Function(\""));
      info->num_seen = 0;
      info->num_alloced = 10;
      info->obj_seen = jseMustMalloc(struct objectHelperPair,
                                     sizeof(struct objectHelperPair)*info->num_alloced);

      jseSetSharedData(jsecontext,OBJ_HELPER_DATA,info,NULL);
   }

   if( info->num_seen>=info->num_alloced )
   {
      assert( info->num_seen==info->num_alloced );
      info->num_alloced += 10;
      info->obj_seen = jseMustReMalloc(struct objectHelperPair,
                                       info->obj_seen,
                                       sizeof(struct objectHelperPair)*info->num_alloced);
   }

   jse_sprintf((jsecharptr)buffer,UNISTR("tmp%d"),info->num_seen+1);
   info->obj_seen[info->num_seen].obj = jseCreateSiblingVariable(jsecontext,base_obj,0);
   info->obj_seen[info->num_seen].name = StrCpyMalloc((jsecharptr)buffer);
   info->num_seen++;

   /* now write out the construction text for our object. */

   dynamicBufferAppend(&(info->text),UNISTR("var "));
   dynamicBufferAppend(&(info->text),(jsecharptr)buffer);
   dynamicBufferAppend(&(info->text),UNISTR(" = "));

   /* base_str may have some escape sequences in it, so escape them here */
   escapedName = jseEscapeString(base_str,strlen_jsechar(base_str));
   dynamicBufferAppend(&(info->text),dynamicBufferGetString(&escapedName));
   dynamicBufferTerm(&escapedName);

   dynamicBufferAppend(&(info->text),UNISTR("; "));

   /* enumerate all object members */
   while( (member = jseGetNextMember(jsecontext,base_obj,member,&memberName))!=NULL )
   {
      /* we duplicate the string because it can be allocated in a
       * static context-specific buffer which gets overwritten
       * by our recursive calls.
       */
      const jsecharptr mem;

      /* We skip the prototype, that should be set up by the construction
       * passed to us as 'base_str'
       */
      if( 0 == strcmp_jsechar(memberName,PROTOTYPE_PROPERTY) )
         continue;
      mem = StrCpyMalloc(memberName);
      if( mem==NULL ) break;


      /* Ok, if the item is dont enum, we employ some rules.
       *
       * 1. if the item is a non-object type, we assume the
       *    item is set up by the constructor. This is for
       *    things like '_value', etc. Thus, we don't explicitly
       *    assign it.
       *
       * 2. If the item is an object, we assume we are looking
       *    at a built-in object, like Clib, or String. In this
       *    case, we don't try to rebuild the object from
       *    scratch, we assign to that literal object.
       *
       * Otherwise it is enum. In this case, 'regular' members
       * are easy, just write them out. If the object is in
       * the table, use its entry. Else call the object's
       * toSource method and use that. Both cases are subsumed
       * into 'jseConvertToSource'
       */
      /* NYI: we currently skip dontenum objects, because they
       *      don't help us. The problem is that if we say
       *      'var a = Clib;', 'a' is not dontenum even though
       *      clib is, and we have no way to find the name 'Clib'
       *      even if we did know it was the case. So rather than
       *      enumerate all the members of clib, we just skip
       *      it.
       */
      if( (jseGetAttributes(jsecontext,member)&jseDontEnum)==0 )
      {
         jsebool found = False;
         jseVariable converted;


         if( jseGetType(jsecontext,member)==jseTypeObject )
         {
            int i;


            /* look in our existing names to see if it is there */
            for( i=0;i<info->num_seen;i++ )
            {
               if( jseCompare(jsecontext,member,info->obj_seen[i].obj,JSE_COMPVAR) )
               {
                  found = True;

                  dynamicBufferAppend(&(info->text),(jsecharptr)buffer);
                  dynamicBufferAppend(&(info->text),UNISTR("[\\\""));

                  /* Escape name in case of illegal characters */
                  escapedName = jseEscapeString(mem,strlen_jsechar(mem));
                  dynamicBufferAppend(&(info->text),dynamicBufferGetString(&escapedName));
                  dynamicBufferTerm(&escapedName);
                  dynamicBufferAppend(&(info->text),UNISTR("\\\"] = "));

                  dynamicBufferAppend(&(info->text),info->obj_seen[i].name);
                  break;
               }
            }
         }

         if( !found )
         {
            const jsecharptr buf;

            converted = jseConvertToSource(jsecontext,member);

            if( converted == NULL ) break;

            buf = (const jsecharptr)jseGetString(jsecontext,converted,NULL);

            dynamicBufferAppend(&(info->text),(jsecharptr)buffer);
            dynamicBufferAppend(&(info->text),UNISTR("[\\\""));

            /* Escape name in case of illegal characters */
            escapedName = jseEscapeString(mem,strlen_jsechar(mem));
            dynamicBufferAppend(&(info->text),dynamicBufferGetString(&escapedName));
            dynamicBufferTerm(&escapedName);
            dynamicBufferAppend(&(info->text),UNISTR("\\\"] = "));

            /* escape it because we are putting it inside a string */
            escapedName = jseEscapeString(buf,strlen_jsechar(buf));
            dynamicBufferAppend(&(info->text),dynamicBufferGetString(&escapedName));
            dynamicBufferTerm(&escapedName);
            jseDestroyVariable(jsecontext,converted);
         }

         dynamicBufferAppend(&(info->text),UNISTR("; "));
      }
      jseMustFree((void *)mem);
   }

   if( orig )
   {
      int i;

      dynamicBufferAppend(&(info->text),UNISTR("return "));
      dynamicBufferAppend(&(info->text),(jsecharptr)buffer);
      dynamicBufferAppend(&(info->text),UNISTR(";\"))())"));
      jsePutString(jsecontext,ret,dynamicBufferGetString(&info->text));

      dynamicBufferTerm(&info->text);

      /* Free and get rid of the info structure */
      for( i=0;i<info->num_seen;i++ )
      {
         jseDestroyVariable(jsecontext,info->obj_seen[i].obj);
         jseMustFree((void *)(info->obj_seen[i].name));
      }
      jseMustFree(info->obj_seen);
      jseMustFree(info);
      jseSetSharedData(jsecontext,OBJ_HELPER_DATA,NULL,NULL);
   }
   else
   {
      /* return out object name in the table, which is currently
       * stored in 'buffer'
       */
      jsePutString(jsecontext,ret,(jsecharptr)buffer);
   }

   return ret;
}
#endif /* #ifdef JSE_TOSOURCE_HLPER */


/*********************************************************
 *********************************************************
 *** Code for initializing objects like "new Something ***
 *********************************************************
 *********************************************************/

/* Initialize blank object, copying prototypes */
jsebool
jseInitializeObject(jseContext jsecontext, jseVariable object, const jsecharptr objName)
{
   jseVariable gl_obj, proto, orig_proto;
   jsebool success = False;

   gl_obj = jseFindVariable(jsecontext,objName,jseCreateVar);
   if( NULL != gl_obj &&
       jseTypeObject == jseGetType(jsecontext,gl_obj))
   {
      orig_proto = jseMemberEx(jsecontext,gl_obj,ORIG_PROTOTYPE_PROPERTY,jseTypeObject,jseCreateVar|jseDontCreateMember);
      if( orig_proto != NULL )
      {
         proto = jseMemberEx(jsecontext,object,PROTOTYPE_PROPERTY,jseTypeObject,jseCreateVar);

         jseAssign(jsecontext,proto,orig_proto);
         jseSetAttributes(jsecontext,proto,jseDontEnum);

         success = True;

         jseDestroyVariable(jsecontext,proto);
         jseDestroyVariable(jsecontext,orig_proto);
      }

   }
   if( gl_obj != NULL )
      jseDestroyVariable(jsecontext,gl_obj);

   return success;
}

/* Construct a new standard object, calling _construct property, etc */
jsebool
jseConstructObject(jseContext jsecontext, jseVariable object,
                   const jsecharptr objName, jseStack stack)
{
   jseVariable funcObj;
   jsebool success = False;

   funcObj = jseGetMemberEx(jsecontext,NULL,objName,jseCreateVar);
   if ( NULL != funcObj )
   {
      jseVariable newobj;
      if ( jseCallFunctionEx(jsecontext,funcObj,stack,
                             &newobj,NULL,JSE_FUNC_CONSTRUCT) )
      {
         success = True;
         jseAssign(jsecontext,object,newobj);
      }
      jseDestroyVariable(jsecontext,funcObj);
   }
   return success;
}

#if JSE_OBJECTDATA == 0

/********************************************************
 ********************************************************
 *** Code for jseSetObjectData and jseGetObjectData   ***
 *** if these functions are not available in the core ***
 ********************************************************
 ********************************************************/

CONST_STRING(SECRET_OBJECT_DATA_NAME,"__object_data__");

union ptr_num_caster
{
   void _FAR_ *ptr;
   jsenumber   num;
};

   void
jseSetObjectData(jseContext jsecontext,jseVariable variable,
                 void _FAR_ *data)
{
   if ( jseTypeObject == jseGetType(jsecontext,variable) )
   {
      union ptr_num_caster caster;

      jseVariable dataVar = jseMemberEx(jsecontext,variable,SECRET_OBJECT_DATA_NAME,
                                        jseTypeNumber,
                                        jseCreateVar|jseLockWrite|jseDontSearchPrototype);
      assert( NULL != dataVar );
      assert( sizeof(caster)==sizeof(caster.num) );
      caster.ptr = data;
      jseSetAttributes(jsecontext,dataVar,jseDefaultAttr);
      jsePutNumber(jsecontext,dataVar,caster.num);
      jseSetAttributes(jsecontext,dataVar,jseDontEnum|jseReadOnly|jseDontDelete);
      jseDestroyVariable(jsecontext,dataVar);
   }
}

   void _FAR_ *
jseGetObjectData(jseContext jsecontext,jseVariable variable)
{
   union ptr_num_caster caster;

   caster.ptr = NULL; /* in case of failure elsewhere */

   if ( jseTypeObject == jseGetType(jsecontext,variable) )
   {
      jseVariable dataVar = jseMemberEx(jsecontext,variable,SECRET_OBJECT_DATA_NAME,
                                        jseTypeNumber,
                                        jseCreateVar|jseLockRead|jseDontCreateMember|jseDontSearchPrototype);
      if ( NULL != dataVar )
      {
         assert( sizeof(caster)==sizeof(caster.num) );
         caster.num = jseGetNumber(jsecontext,dataVar);
         jseDestroyVariable(jsecontext,dataVar);
      }
   }
   return caster.ptr;
}
#endif  /* #if JSE_OBJECTDATA == 0 */

#ifdef JSE_INSTANCEOF_HELPER

/*********************************************
 *********************************************
 *** Code for API version of jseInstanceof ***
 *********************************************
 *********************************************/
#define JSE_INSTANCEOF_MAXTEST  50  /* don't search beyond this depth */
   jsebool
jseInstanceof(jseContext jsecontext,jseVariable instanceVar,jseVariable classVar)
{
   jsebool isInstanceof = False;

   /* cut out if any of the inputs are not object variables */
   if ( NULL != classVar
     && NULL != instanceVar
     && jseTypeObject == jseGetType(jsecontext,instanceVar)
     && jseTypeObject == jseGetType(jsecontext,classVar) )
   {
      jseVariable origPrototype;

      origPrototype = jseMemberEx(jsecontext,classVar,ORIG_PROTOTYPE_PROPERTY,jseTypeUndefined,
                                  jseCreateVar|jseLockRead|jseDontCreateMember|jseDontSearchPrototype);
      if ( NULL != origPrototype )
      {
         if ( jseTypeObject == jseGetType(jsecontext,origPrototype) )
         {
            sint attempts;
            jseVariable prototypes[JSE_INSTANCEOF_MAXTEST];
            jseVariable tempInstanceVar = instanceVar;
            for ( attempts = 0; attempts < JSE_INSTANCEOF_MAXTEST; )
            {
               tempInstanceVar = jseMemberEx(jsecontext,tempInstanceVar,PROTOTYPE_PROPERTY,jseTypeUndefined,
                                            jseCreateVar|jseLockRead|jseDontCreateMember|jseDontSearchPrototype);
               if ( NULL == tempInstanceVar )
               {
                  break;
               }
               prototypes[attempts++] = tempInstanceVar;
               if ( 1 == jseCompareEquality(jsecontext,origPrototype,tempInstanceVar) )
               {
                  isInstanceof = True;
                  break;
               }
            }
            /* remove all variables created while searching */
            while ( attempts-- )
            {
               jseDestroyVariable(jsecontext,prototypes[attempts]);
            }
            if ( !isInstanceof )
            {
               /* special cases; if there's no real prototype this this could be getting
                * the default Function or Object prototypes, depending on if this is a function
                * or an object.
                */
               /* all objects inherit from Object.prototype */
               jseVariable globalObject = jseMemberEx(jsecontext,NULL,OBJECT_PROPERTY,jseTypeUndefined,
                                                      jseCreateVar|jseLockRead|jseDontCreateMember|jseDontSearchPrototype);
               if ( NULL != globalObject )
               {
                  if ( 1 == jseCompareEquality(jsecontext,globalObject,classVar) )
                  {
                     isInstanceof = True;
                  }
                  jseDestroyVariable(jsecontext,globalObject);
               }
               if ( !isInstanceof && jseIsFunction(jsecontext,instanceVar) )
               {
                  /* all functions inherit from Function.prototype */
                  jseVariable functionObject = jseMemberEx(jsecontext,NULL,FUNCTION_PROPERTY,jseTypeUndefined,
                     jseCreateVar|jseLockRead|jseDontCreateMember|jseDontSearchPrototype);
                  if ( NULL != functionObject )
                  {
                     if ( 1 == jseCompareEquality(jsecontext,functionObject,classVar) )
                     {
                        isInstanceof = True;
                     }
                     jseDestroyVariable(jsecontext,functionObject);
                  }
               }
            }
         }
         jseDestroyVariable(jsecontext,origPrototype);
      }
   }
   return isInstanceof;
}

#endif /* #ifdef JSE_INSTANCEOF_HELPER */


/* NYI: move this into the core or whereever is appropriate */
   jseVariable
jseCreateNumberVariable(jseContext jsecontext,jsenumber v)
{
   jseVariable ret = jseCreateVariable(jsecontext,jseTypeNumber);

   if( ret!=NULL ) jsePutNumber(jsecontext,ret,v);
   return ret;
}


#if JSE_DATUM_HELPERS!=0

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
 * returned. The will be 'False', 0, jseNaN, UNISTR(""),
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

   static jseVariable NEAR_CALL
getDatumVar(jseContext jsecontext,jseVariable object,const jsecharptr member,
            jseConversionTarget convTarget, /* convert to this */
            jseDataType type,               /* if not already this type, use 0 to always convert */
            jseVariable *releaseVar)
{
   /* get the variable to be working with */
   if( object==NULL )
   {
      object = jseGlobalObject(jsecontext);
   }
   else if( object==JSE_THIS_VAR )
   {
      object = jseGetCurrentThisVariable(jsecontext);
   }
   if( member!=NULL )
   {
      if( jseGetType(jsecontext,object)==jseTypeObject )
      {
         object = jseGetMember(jsecontext,object,member);
      }
      else
      {
         object = NULL;
      }

      if ( NULL == object )
      {
         if( !jseQuitFlagged(jsecontext) )
            jseLibErrorPrintf(jsecontext,UNISTR("Member '%s' not found in object or not an object."),member);
      }
   }

   if ( object  &&  (0 == type  ||  type != jseGetType(jsecontext,object)) )
   {
      object = *releaseVar = jseCreateConvertedVariable(jsecontext,object,convTarget);
#     ifndef NDEBUG
         if ( NULL != object )
         {
            if ( 0 != type )
            {
               assert( type == jseGetType(jsecontext,object) );
            }
         }
         else
         {
            assert( jseQuitFlagged(jsecontext) );
         }
#     endif
   }
   else
   {
      /* no conversion was made */
      *releaseVar = NULL; /* assume that there is no variable to release */
   }
   return object;
}

   static void NEAR_CALL
releaseDatumVar(jseContext jsecontext,jseVariable releaseVar)
{
   if ( NULL != releaseVar )
      jseDestroyVariable(jsecontext,releaseVar);
}

   jsebool
jseGetBooleanDatum(jseContext jsecontext,jseVariable object,
                   const jsecharptr member)
{
   jsebool result;
   jseVariable tempVar;

   object = getDatumVar(jsecontext,object,member,jseToBoolean,jseTypeBoolean,&tempVar);
   result = object ? jseGetBoolean(jsecontext,object) : False ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

   jsenumber
jseGetNumberDatum(jseContext jsecontext,jseVariable object,
                 const jsecharptr member)
{
   jsenumber result;
   jseVariable tempVar;

   object = getDatumVar(jsecontext,object,member,jseToNumber,jseTypeNumber,&tempVar);
   result = object ? jseGetNumber(jsecontext,object) : jseNaN ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

   jsenumber
jseGetIntegerDatum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member)
{
   jsenumber result;
   jseVariable tempVar;

   object = getDatumVar(jsecontext,object,member,jseToInteger,jseTypeNumber,&tempVar);
   result = object ? jseGetNumber(jsecontext,object) : jseNaN ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

   sword32
jseGetInt32Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member)
{
   sword32 result;
   jseVariable tempVar;

   /* always have to convert as even a jseTypeNumber not
    * necessarily an Int32.
    */
   object = getDatumVar(jsecontext,object,member,jseToInt32,0,&tempVar);
   result = object ? JSE_FP_CAST_TO_SLONG(jseGetNumber(jsecontext,object)) : 0 ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

   uword32
jseGetUint32Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member)
{
   uword32 result;
   jseVariable tempVar;

   /* always have to convert as even a jseTypeNumber not
    * necessarily an Uint32.
    */
   object = getDatumVar(jsecontext,object,member,jseToUint32,0,&tempVar);
   result = object ? JSE_FP_CAST_TO_ULONG(jseGetNumber(jsecontext,object)) : 0 ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

   uword16
jseGetUint16Datum(jseContext jsecontext,jseVariable object,
                  const jsecharptr member)
{
   uword16 result;
   jseVariable tempVar;

   /* always have to convert as even a jseTypeNumber not
    * necessarily an Uint16.
    */
   object = getDatumVar(jsecontext,object,member,jseToUint16,0,&tempVar);
   result = object ? (uword16)JSE_FP_CAST_TO_ULONG(jseGetNumber(jsecontext,object)) : (uword16)0 ;
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

#define HELPER_MEMBER UNISTR("__jseGetStringDatumHelperItem")

   const jsecharptr
jseGetStringDatum(jseContext jsecontext,jseVariable object,
                 const jsecharptr member,JSE_POINTER_UINDEX *length)
{
   const jsecharptr result;
   jseVariable tempVar;

   object = getDatumVar(jsecontext,object,member,jseToString,jseTypeString,&tempVar);
   if ( object )
   {
      /* Ok, this is going to be a little complex. We need to arrange for
       * the object to become a tempvar. Otherwise, the result
       * may become invalid.
       */
      jseVariable obj1,obj2 =
         jseMember(jsecontext,NULL,HELPER_MEMBER,jseTypeUndefined);
      jseAssign(jsecontext,obj2,object);

      /* By locking read, we lock the value (the string). Without
       * that, we have a reference. This way, even deleting the
       * member, we still have access to it
       */
      obj1 = jseGetMemberEx(jsecontext,NULL,HELPER_MEMBER,jseLockRead);
      if( obj1!=NULL )
      {
         result = (const jsecharptr)jseGetString(jsecontext,obj1,length);
      }
      else
      {
         result = UNISTR("");
         if ( length )
            *length = 0;
      }
      jseDeleteMember(jsecontext,NULL,HELPER_MEMBER);
   }
   else
   {
      result = UNISTR("");
      if ( length )
         *length = 0;
   }
   releaseDatumVar(jsecontext,tempVar);
   return result;
}

#endif
