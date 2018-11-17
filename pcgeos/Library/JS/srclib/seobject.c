/* seobject.c
 *
 * Handles the ECMAScript objects for predefined types.
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
#if defined(JSE_NUMBER_ANY) && (0!=JSE_FLOATING_POINT) && !defined(__JSE_GEOS__)
#  include <float.h>
#endif


/* ---------------------------------------------------------------------- */

#if defined(JSE_ARRAY_SLICE) \
 || defined(JSE_ARRAY_SPLICE) \
 || defined(JSE_NUMBER_TOFIXED) \
 || defined(JSE_NUMBER_TOEXPONENTIAL) \
 || defined(JSE_NUMBER_TOPRECISION) \
 || defined(JSE_STRING_CHARAT) \
 || defined(JSE_STRING_CHARCODEAT) \
 || defined(JSE_STRING_SUBSTRING) \
 || defined(JSE_STRING_SUBSTR)
   static jsebool
GetSlongFromVar(jseContext jsecontext,jseVariable var,slong *value)
   /* get an slong from a variable via jseConvertVar(...jseToInteger), if there's
    * an error return False (and set *value to 0), else return True and *value is set
    */
{
   jseVariable tempVar = jseCreateConvertedVariable(jsecontext,var,jseToInteger);
   if ( NULL == tempVar )
   {
      *value = 0;
      return False;
   }
   *value = jseGetLong(jsecontext,tempVar);
   jseDestroyVariable(jsecontext,tempVar);
   return True;
}
#endif


/* ---------------------------------------------------------------------- */


/* ---------------------------------------------------------------------- */

#if defined(JSE_OBJECT_ANY)
#if !defined(JSE_OBJECT_OBJECT)
#  error must #define JSE_OBJECT_OBJECT 1 or #define JSE_OBJECT_ALL to use JSE_OBJECT_ANY
#endif

/* This is the 'builtin' object constructor. It is the most basic type.
 * It just initializes a new object and returns it.
 */
static InternalLibFunc(Ecma_Object_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,OBJECT_PROPERTY),jseRetTempVar);
   assert( jseApiOK );
}

/* Object() */
static jseLibFunc(Ecma_Object_call)
{
   jseVariable var,ret;

   if( jseFuncVarCount(jsecontext)==0 )
   {
      PlainNewObject:
      jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeObject),jseRetTempVar);
      return;
   }

   var = jseFuncVar(jsecontext,0);

   if( jseGetType(jsecontext,var)==jseTypeNull ||
       jseGetType(jsecontext,var)==jseTypeUndefined )
   {
      goto PlainNewObject;
   }

   if( NULL != (ret = jseCreateConvertedVariable(jsecontext,var,jseToObject)))
      jseReturnVar(jsecontext,ret,jseRetTempVar);
   assert( jseApiOK );
}
#endif /* #if defined(JSE_OBJECT_ANY) */

#if defined(JSE_OBJECT_PROPERTYISENUMERABLE)
/* ECMA2.0: Object.propertyIsEnumerable(name)
 *
 * Returns True if the current object has an enumerable property by the specified name,
 * false otherwise.
 */
static jseLibFunc(Ecma_Object_propertyIsEnumerable)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret;
   jseVariable jseProperty;
   const jsecharptr property;

   /* Get the name of the property - parameter one */
   JSE_FUNC_VAR_NEED(jseProperty,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   property = (const jsecharptr)jseGetString(jsecontext,jseProperty,NULL);

   ret = jseCreateVariable(jsecontext,jseTypeBoolean);

   jseProperty = jseGetMemberEx(jsecontext,thisVar,property,jseCreateVar|jseCheckHasProperty);
   if( jseProperty != NULL )
   {
      if( !(jseGetAttributes(jsecontext,jseProperty) & jseDontEnum) )
         jsePutBoolean(jsecontext,ret,True);

      jseDestroyVariable(jsecontext,jseProperty);
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif /* #if defined(JSE_OBJECT_PROPERTYISENUMERABLE) */

#if defined(JSE_OBJECT_ISPROTOTYPEOF)
/* ECMA2.0: Object.isPrototypeOf(var)
 *
 * Returns true if the object and var refer to the same object, or if the current object
 * exists as any part of var's prototype chain, and false otherwise
 */
static jseLibFunc(Ecma_Object_isPrototypeOf)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret = jseCreateVariable(jsecontext,jseTypeBoolean);
   jseVariable current;

   jseVariable param = jseFuncVar(jsecontext,0);
   if( param == NULL )
      return;

   if( jseTypeObject == jseGetType(jsecontext,param) )
   {
      if( jseCompareEquality(jsecontext,thisVar,param) )
         jsePutBoolean(jsecontext,ret,True);
      else
      {
         current = param;
         while( NULL != (current = jseGetMember(jsecontext,current,PROTOTYPE_PROPERTY)) &&
                jseTypeObject == jseGetType(jsecontext,current) )
         {
            if( jseCompareEquality(jsecontext,thisVar,current) )
               jsePutBoolean(jsecontext,ret,True);
         }
      }
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

#if defined(JSE_OBJECT_HASOWNPROPERTY)
/* ECMA2.0: Object.hasProperty(prop)
 *
 * Returns true if the object has a property named 'prop', and false otherwise
 */
static jseLibFunc(Ecma_Object_hasProperty)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseProperty;
   jseVariable ret;
   const jsecharptr property;

   JSE_FUNC_VAR_NEED(jseProperty,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   property = (const jsecharptr)jseGetString(jsecontext,jseProperty,NULL);

   ret = jseCreateVariable(jsecontext,jseTypeBoolean);

   if( NULL != (jseProperty = jseGetMemberEx(jsecontext,thisVar,property,
                                             jseCreateVar|jseCheckHasProperty|jseDontSearchPrototype)) )
   {
      jsePutBoolean(jsecontext,ret,True);
      jseDestroyVariable(jsecontext,jseProperty);
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif /* #if defined(JSE_OBJECT_HASOWNPROPERTY) */

#if defined(JSE_OBJECT_TOLOCALESTRING)
/* ECMA2.0: Object.toLocaleString()
 *
 * This simply returns the result of calling toString()
 */
static jseLibFunc(Ecma_Object_toLocaleString)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable converted = jseCreateConvertedVariable(jsecontext,thisVar,jseToString);

   if( converted != NULL )
      jseReturnVar(jsecontext,converted,jseRetTempVar);
}
#endif /* #if defined(JSE_OBJECT_TOLOCALESTRING) */


#if defined(JSE_OBJECT_TOSOURCE)
/* Object.toSource()
 */
static jseLibFunc(Ecma_Object_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);

   /* Pretty simple, use the object enumerator and start with the
    * base of a generic object.
    */
   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,UNISTR("new Object()")),
                jseRetTempVar);
}
#endif /* #if defined(JSE_OBJECT_TOSOURCE) */


/* ---------------------------------------------------------------------- */
/* The 'Function' object */
/* ---------------------------------------------------------------------- */

#if defined(JSE_FUNCTION_ANY)
#if !defined(JSE_FUNCTION_OBJECT)
#  error must #define JSE_FUNCTION_OBJECT 1 or #define JSE_FUNCTION_ALL to use JSE_FUNCTION_ANY
#endif

/* This is the 'builtin' array construct. */
static jseLibFunc(Ecma_Function_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,FUNCTION_PROPERTY),jseRetTempVar);
   assert( jseApiOK );
}

/* add_to_buffer - manage a dynamic buffer, used by Function.construct */
   static void NEAR_CALL
add_to_buffer(jsecharptr *buf,uint *size,const jsecharptr text)
{
   uint newsize;
   *buf = jseMustReMalloc(jsecharptrdatum,*buf,sizeof(jsechar)*(1+(newsize = *size + strlen_jsechar(text))));
   strcpy_jsechar(JSECHARPTR_OFFSET((*buf),(*size)),text);
   (*size) = newsize;
}

/* Function.construct */
static jseLibFunc(Ecma_Function_construct)
{
   /* Current method: interpret() a creation of the function with a
    * name 'anonymous' (first saving anything with that name),
    * then find and lock that function, replace its old value, and
    * return the lock.
    */
   uint num = jseFuncVarCount(jsecontext);
   jsecharptr buf = NULL;
   uint size = 0;
   uint x;
   jseVariable reterr,ret,var,args/*,proto,newproto,con*/;
   static CONST_STRING(anonymous_property,"anonymous");
   jseVariable act = jseActivationObject(jsecontext);


   add_to_buffer(&buf,&size,UNISTR("function anonymous("));
   for( x = 1; x < num; x++ )
   {
      jseVariable tmp = jseCreateConvertedVariable(jsecontext,
                                                   jseFuncVar(jsecontext,x-1),
                                                   jseToString);
      const jsecharptr str;

      if( tmp == NULL )
      {
         jseMustFree(buf);
         return;
      }

      str = (const jsecharptr )jseGetString(jsecontext,tmp,0);


      if( x!=1 ) add_to_buffer(&buf,&size,UNISTR(","));
      add_to_buffer(&buf,&size,str);
      jseDestroyVariable(jsecontext,tmp);
   }
   add_to_buffer(&buf,&size,UNISTR(")\n{\n"));


   if( num!=0 )
   {
      jseVariable tmp = jseCreateConvertedVariable(jsecontext,
                                                   jseFuncVar(jsecontext,num-1),
                                                   jseToString);
      const jsecharptr str;

      if( tmp == NULL )
      {
         jseMustFree(buf);
         return;
      }

      str = (const jsecharptr )jseGetString(jsecontext,tmp,0);

      add_to_buffer(&buf,&size,str);
      jseDestroyVariable(jsecontext,tmp);
   }

   add_to_buffer(&buf,&size,UNISTR("\n}\n"));

   var = jseGetMember(jsecontext,act,anonymous_property);
   if( var )
   {
      var = jseCreateSiblingVariable(jsecontext,var,0);
      jseDeleteMember(jsecontext,act,anonymous_property);
   }

   if( jseInterpret(jsecontext,NULL,buf,NULL,jseNewNone,
                    JSE_INTERPRET_LOAD|JSE_INTERPRET_TRAP_ERRORS,
                    NULL,&reterr) &&
       (ret = jseGetMember(jsecontext,act,anonymous_property))!=NULL )
   {
      ret = jseCreateSiblingVariable(jsecontext,ret,0);
      assert( reterr != NULL );
      jseDestroyVariable(jsecontext,reterr);
   }
   else
   {
      /* error parsing it - make an error in the context. */
      /* replace that error with the existing error object */
      if( reterr!=NULL )
      {
         jseReturnVar(jsecontext,reterr,jseRetTempVar);
      }
      jseLibSetErrorFlag(jsecontext);
      if( buf ) jseMustFree(buf);
      return;
   }

   if( buf ) jseMustFree(buf);

   if( var )
   {
      jseVariable old = jseMember(jsecontext,act,anonymous_property,jseTypeUndefined);
      jseAssign(jsecontext,old,var);
      jseDestroyVariable(jsecontext,var);
   }
   else
   {
      jseDeleteMember(jsecontext,act,anonymous_property);
   }

   {
      jseVariable proto, newproto, con;
      /* set up some properties - 15.3 says it will be set up like this, where F
       * is this new function object:
       *    F._prototype = Function.prototype;  this is handled internaly
       *        because all function objects implicitly inherit Function.prototype
       *    F._call = {this function};  if no _call then will default to calling
       *        this function anyway, so no need to explicitly add it
       *    F.prototype = new Object(); see following lines
       */
      proto = CreateNewObject(jsecontext,OBJECT_PROPERTY);
      newproto = jseMember(jsecontext,ret,ORIG_PROTOTYPE_PROPERTY,jseTypeUndefined);
      jseAssign(jsecontext,newproto,proto);
      /* ECMA2.0 - Add DontDelete flag */
      jseSetAttributes(jsecontext,newproto,jseDontDelete|jseDontEnum);
      /*    F.prototype.constructor = F;  see following lines */
      con = jseMember(jsecontext,ret,CONSTRUCTOR_PROPERTY,jseTypeUndefined);
      jseAssign(jsecontext,con,ret);
      jseSetAttributes(jsecontext,con,jseDontEnum);
      /* other properties F._construct, F.toString, F.length are handled automaically
       * by a function object inheriting from Function.prototype implicitly.
       * cleanup
       */
      jseDestroyVariable(jsecontext,proto);
   }
   args = jseMember(jsecontext,ret,ARGUMENTS_PROPERTY,jseTypeNull);
   jseSetAttributes(jsecontext,args,jseDontEnum | jseDontDelete | jseReadOnly);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_FUNCTION_ANY) */

#if defined(JSE_FUNCTION_CALL)
/* ECMA2.0: Function.call()
 *
 * This is a simple function which simply calls the '_call' property of a
 * function instance, setting the 'this' variable in the process.  If there is
 * no '_call' property, then a runtime error is generated.
 */
static jseLibFunc(Ecma_Function_call)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable returnVar, thisArg;
   jseStack stack;
   int i;

   if( !jseIsFunction(jsecontext,thisVar) )
   {
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibNO_CALL_PROPERTY));
   }
   else
   {
      stack = jseCreateStack(jsecontext);

      if( jseFuncVarCount(jsecontext) != 0 )
      {
         thisArg = jseFuncVarNeed(jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_OBJECT));
         if( thisArg == NULL )
         {
            jseDestroyStack(jsecontext,stack);
            return;
         }
      }
      else
         thisArg = NULL;  /* Use global variable */

      for( i = 1; i < (sint)jseFuncVarCount(jsecontext); i++ )
         jsePush(jsecontext,stack,jseFuncVar(jsecontext,(uint)i),False);

      jseCallFunction(jsecontext,thisVar,stack,&returnVar,thisArg);

      jseReturnVar(jsecontext,returnVar,jseRetCopyToTempVar);

      jseDestroyStack(jsecontext,stack);
   }
}
#endif /* #if defined(JSE_FUNCTION_CALL) */

#if defined(JSE_FUNCTION_APPLY)
/* ECMA2.0: Function.apply()
 *
 * Similar to Function.call, this function calls the '_call' property of the
 * current this object.  Unlike Function.call, it takes an array of arguments
 * as it's second argument.
 */
static jseLibFunc(Ecma_Function_apply)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable returnVar, thisArg;
   jseStack stack;
   int i;

   if( !jseIsFunction(jsecontext,thisVar) )
   {
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibNO_CALL_PROPERTY));
   }
   else
   {
      stack = jseCreateStack(jsecontext);

      if( jseFuncVarCount(jsecontext) != 0 )
      {
         thisArg = jseFuncVarNeed(jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_OBJECT));
         if( thisArg == NULL )
         {
            jseDestroyStack(jsecontext,stack);
            return;
         }
      }
      else
         thisArg = NULL;  /* Use global variable */

      if( jseFuncVarCount(jsecontext) > 1 )
      {
         jseVariable argArray = jseFuncVarNeed(jsecontext,1,JSE_VN_OBJECT);

         if( argArray == NULL )
         {
            jseDestroyStack(jsecontext,stack);
            return;
         }

         for( i = 0; i< (sint)jseGetArrayLength(jsecontext,argArray,NULL); i++ )
         {
            jsePush(jsecontext,stack,
                    jseIndexMemberEx(jsecontext,argArray,i,jseTypeUndefined,jseCreateVar),
                    True);

         }
      }

      if( jseCallFunction(jsecontext,thisVar,stack,&returnVar,thisArg) )
         jseReturnVar(jsecontext,returnVar,jseRetCopyToTempVar);

      jseDestroyStack(jsecontext,stack);
   }
}
#endif /* #if defined(JSE_FUNCTION_APPLY) */

#if defined(JSE_FUNCTION_TOSOURCE)
/* Function.toSource() */
static jseLibFunc(Ecma_Function_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable convertedVariable;
   const jsecharptr text;

   if( !ensure_type(jsecontext,thisVar,FUNCTION_PROPERTY) )
      return;

   if( jseIsLibraryFunction(jsecontext,thisVar) )
   {
      /* There is no way to get the source or even the name of a library function.
       * Instead, we simply return the string "DSP.unkownLibraryFunction", which
       * is assumed to exist on the other side.  For users who wich to pass a
       * function to a remote function, they can simply pass "conn.Clib.puts",
       * which is a DSP reference and will be resolved to "Clib.puts" when
       * converted to source
       */
      /* New idea - since this doesn't happen very often, we will try the
       * following method: For each object in the global object, if it is
       * same object, then simply return that object.  Otherwise, check to
       * see if it has that member.  If not, then check the .prototype
       * property.  This algorithm will find every known library function,
       * but it is still possible for it to fail
       */
      jseVariable  prototypeProperty;
      jseVariable globalMember = NULL, member = NULL;
      const jsecharptr globalMemberName;
      const jsecharptr memberName;

      while(NULL != (globalMember =jseGetNextMember(jsecontext,NULL,
                                                    globalMember,&globalMemberName)) )
      {
         /* We are only interested in objects (and functions, which are objects */
         if( jseTypeObject != jseGetType(jsecontext,globalMember) )
            continue;

         if( jseCompareEquality(jsecontext,globalMember,thisVar) )
         {
            jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,globalMemberName),
                jseRetTempVar);

            goto foundIt;
         }

         while( NULL != (member = jseGetNextMember(jsecontext,globalMember,
                                                   member,&memberName)) )
         {
            if( jseCompareEquality(jsecontext,member,thisVar) )
            {
               struct dynamicBuffer buffer;

               dynamicBufferInit(&buffer);
               dynamicBufferAppend(&buffer,globalMemberName);
               dynamicBufferAppend(&buffer,UNISTR("."));
               dynamicBufferAppend(&buffer,memberName);

               jseReturnVar(jsecontext,
                  objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                  jseRetTempVar);

               dynamicBufferTerm(&buffer);

               goto foundIt;
            }
         }

         prototypeProperty = jseGetMember(jsecontext,globalMember,ORIG_PROTOTYPE_PROPERTY);
         if( prototypeProperty != NULL )
         {
            while( NULL != (member = jseGetNextMember(jsecontext,prototypeProperty,
                                                      member,&memberName)) )
            {
               if( jseCompareEquality(jsecontext,member,thisVar) )
               {
                  struct dynamicBuffer buffer;

                  dynamicBufferInit(&buffer);
                  dynamicBufferAppend(&buffer,globalMemberName);
                  dynamicBufferAppend(&buffer,UNISTR("."));
                  dynamicBufferAppend(&buffer,ORIG_PROTOTYPE_PROPERTY);
                  dynamicBufferAppend(&buffer,UNISTR("."));
                  dynamicBufferAppend(&buffer,memberName);

                  jseReturnVar(jsecontext,
                      objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                      jseRetTempVar);

                  dynamicBufferTerm(&buffer);

                  goto foundIt;
               }
            }
         }
      }

      jseReturnVar(jsecontext,
          objectToSourceHelper(jsecontext,thisVar,UNISTR("unknownLibraryFunction")),
          jseRetTempVar);

   }
   else
   {
      struct dynamicBuffer buffer, escapedBuffer;
      jsecharptr loc;
      size_t len;

      convertedVariable = jseCreateConvertedVariable(jsecontext,thisVar,
                                                     jseToString);

      if( convertedVariable == NULL )
      {
         return;
      }

      text = (const jsecharptr)jseGetString(jsecontext,convertedVariable,NULL);

      /* Now we must dissect the result of ToString() and turn it into a
       * "new Function" statement.  This involves separating the body of the
       * function and the arguments.   The output of ToString() is something
       * akin to "function (params) {body}".
       */
      dynamicBufferInit(&buffer);

      dynamicBufferAppend(&buffer,UNISTR("new Function(\""));
      /* now we must pass the argument list - Start after first paren*/
      loc = strchr_jsechar( (jsecharptr)text, '(' );
      assert( loc != NULL );
      JSECHARPTR_INC(loc);
      /* We're now at the point just past the opening paren, eat up until
       * the closing paren, and add that to the buffer.
       */
      dynamicBufferAppendLength(&buffer,loc,(len = strcspn_jsechar( loc, UNISTR(")"))));

      dynamicBufferAppend(&buffer,UNISTR("\",\""));

      /* Now we go past the closing parenthesis so we're at the function body */
      loc = JSECHARPTR_OFFSET(loc,len);
      assert( JSECHARPTR_GETC(loc) == ')' );
      JSECHARPTR_INC(loc);

      escapedBuffer = jseEscapeString(loc,strlen_jsechar(loc));

      dynamicBufferAppend(&buffer,dynamicBufferGetString(&escapedBuffer));
      dynamicBufferTerm( &escapedBuffer );

      dynamicBufferAppend(&buffer,UNISTR("\")"));

      jseReturnVar(jsecontext,
          objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
          jseRetTempVar);

      dynamicBufferTerm(&buffer);
      jseDestroyVariable(jsecontext,convertedVariable);
   }

 foundIt:
   return;
}
#endif /* #if defined(JSE_FUNCTION_TOSOURCE) */


/* ---------------------------------------------------------------------- */
/* The 'Array' object */
/* ---------------------------------------------------------------------- */

#pragma codeseg SEOBJECT2_TEXT

#if defined(JSE_ARRAY_ANY)
#if !defined(JSE_ARRAY_OBJECT)
#  error must #define JSE_ARRAY_OBJECT 1 or #define JSE_ARRAY_ALL to use JSE_ARRAY_ANY
#endif
/* This is the 'builtin' array construct. */
static jseLibFunc(Ecma_Array_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,ARRAY_PROPERTY),jseRetTempVar);
   assert( jseApiOK );
}

/* Array() */
static jseLibFunc(Ecma_Array_call)
{
   jseVariable var = CreateNewObject(jsecontext,ARRAY_PROPERTY);
   int c = (int) jseFuncVarCount(jsecontext);

   if( c>1 || (c==1 && jseGetType(jsecontext,jseFuncVar(jsecontext,0))!=jseTypeNumber))
   {
      int x;

      jsePutLong(jsecontext,jseMember(jsecontext,var,LENGTH_PROPERTY,jseTypeNumber),c);
      for( x=0;x<c;x++ )
      {
         jsechar buffer[50];
         sprintf_jsechar((jsecharptr)buffer,UNISTR("%d"),x);
         jseAssign(jsecontext,jseMember(jsecontext,var,(jsecharptr)buffer,jseTypeUndefined),
                   jseFuncVar(jsecontext,(uint)x));
      }
   }
   else if( c==1 )
   {
      jseVariable original = jseFuncVar(jsecontext,0);
      jseVariable converted = jseCreateConvertedVariable(jsecontext,original,jseToUint32);

      if( converted == NULL )
      {
         jseDestroyVariable(jsecontext,var);
         return;
      }

      if( JSE_FP_NEQ(jseGetNumber(jsecontext,original),jseGetNumber(jsecontext,converted)) )
      {
         jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibARRAY_LENGTH_OUT_OF_RANGE));
         jseDestroyVariable(jsecontext,converted);
         jseDestroyVariable(jsecontext,var);
         return;
      }

      jseAssign(jsecontext,jseMember(jsecontext,var,LENGTH_PROPERTY,jseTypeNumber),
                converted);
      jseDestroyVariable(jsecontext,converted);
   }
   else
   {
      jsePutLong(jsecontext,jseMember(jsecontext,var,LENGTH_PROPERTY,jseTypeNumber),0);
   }

   jseReturnVar(jsecontext,var,jseRetTempVar);

   assert( jseApiOK );
}

/* Array.put
 *
 * NOTE: This routine is never actually called because the core knows about
 *       ECMA arrays and does the work internally for speed (though we mark the
 *       object as being an ECMA array. This is the code that does the
 *       work in case you don't want the core to do the work special, though
 *       that is much slower.
 */
#if 0
 old  static jseLibFunc(Ecma_Array_put)
 old  {
 old     jseVariable property,obj;
 old     jseVariable value = jseFuncVar(jsecontext,1);
 old     const jsecharptr pname;
 old     jseVariable prop;
 old     uint loc;
 old     ulong stringLength;
 old
 old     JSE_FUNC_VAR_NEED(property,jsecontext,0,JSE_VN_STRING);
 old
 old     pname = jseGetString(jsecontext,property,&stringLength);
 old
 old     obj = jseGetCurrentThisVariable(jsecontext);
 old
 old     /* ECMA section 15.3.4.1 */
 old     prop = jseGetMember(jsecontext,obj,pname);
 old
 old     if( NULL == prop )
 old     {  /* Step 7 */
 old        prop = jseMember(jsecontext,obj,pname,jseGetType(jsecontext,value));
 old        jseAssign(jsecontext,prop,value);
 old     }
 old     else if ( strcmp_jsechar(pname,LENGTH_PROPERTY) == 0 )
 old     {  /* Step 12 */
 old        jseVariable len;
 old        jseVariable val = jseCreateConvertedVariable(jsecontext,value,jseToNumber);
 old
 old        if( val == NULL )
 old           return;
 old
 old        jseSetArrayLength(jsecontext,obj,0,
 old                          (unsigned long)jseGetNumber(jsecontext,val));
 old        jseDestroyVariable(jsecontext,val);
 old        len = jseMember(jsecontext,
 old                        obj,pname,jseTypeUndefined);
 old        jseAssign(jsecontext,len,value);
 old        jseSetAttributes(jsecontext,len,jseDontEnum | jseDontDelete);
 old        return;
 old     }
 old     else
 old     {  /* Step 5 */
 old        jseAssign(jsecontext,prop,value);
 old     }
 old
 old     /* Step 8 */
 old     loc = 0;
 old     while( isdigit_jsechar(pname[loc]) )
 old        loc++;
 old
 old     if(  stringLength == loc )
 old     {  /* Step 9 */
 old        int max_val = atoi_jsechar(pname)+1;
 old
 old        jseVariable length = jseMember(jsecontext,obj,LENGTH_PROPERTY,jseTypeNumber);
 old        if( max_val>jseGetNumber(jsecontext,length))
 old           jsePutNumber(jsecontext,length,max_val);
 old     }
 old
 old     assert( jseApiOK );
 old  }
#endif /* #if 0 */
#endif /* #if defined(JSE_ARRAY_ANY) */

#if defined(JSE_ARRAY_JOIN) || defined(JSE_ARRAY_TOSTRING)
/* Array.join() */
static jseLibFunc(Ecma_Array_join)
{
   jsecharhugeptr string;

   jsecharhugeptr separator;
   jseVariable str = NULL;
   JSE_POINTER_UINDEX s;
   jseVariable lengthvar;
   jseVariable ret;
   JSE_POINTER_SINDEX x, length, loc;
   jsebool AllocError = False;

   if( jseFuncVarCount(jsecontext)==1 )
   {
      str = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),jseToString);

      if( str == NULL )
         return;

      separator = (jsecharhugeptr)jseGetString( jsecontext, str, &s );
   }
   else
   {
      separator = UNISTR(",");
      s = 1;
   }
   lengthvar = jseMember(jsecontext,jseGetCurrentThisVariable(jsecontext),
                         LENGTH_PROPERTY,jseTypeNumber);
   length = (JSE_POINTER_SINDEX) jseGetLong(jsecontext,lengthvar);

   ret = jseCreateVariable(jsecontext,jseTypeString);
   loc = 0;

   string = HugeMalloc(1);
   if ( NULL == string )
      AllocError = True;
   else
   {
      for( x = 0;x<length;x++ )
      {
         jsecharhugeptr newString;
         jseVariable v;

         if( x!=0 )
         {
            newString = HugeReMalloc(string,
                                     BYTECOUNT_FROM_STRLEN(string,loc) + (s+1)*sizeof(jsechar));
            if ( NULL == newString )
            {
               AllocError = True;
               break;
            }
            string = newString;
            HugeMemCpy(JSECHARPTR_OFFSET(string,loc),separator,BYTECOUNT_FROM_STRLEN(separator,s));
            loc += s;
         }

         v = jseIndexMember(jsecontext,jseGetCurrentThisVariable(jsecontext),
                            x,jseTypeUndefined);

         if( jseGetType(jsecontext,v)!=jseTypeUndefined &&
             jseGetType(jsecontext,v)!=jseTypeNull )
         {
            JSE_POINTER_UINDEX count;
            jsecharhugeptr srcStr;
            jseVariable v2 = jseCreateConvertedVariable(jsecontext,v,jseToString);

            if( v2 == NULL )
            {
               HugeFree(string);
               jseDestroyVariable(jsecontext,ret);
               return;
            }

            srcStr = (jsecharhugeptr)jseGetString(jsecontext,v2,&count);
            newString = HugeReMalloc(string,BYTECOUNT_FROM_STRLEN(string,loc) + (count+1)*sizeof(jsechar));
            if ( NULL == newString )
            {
               AllocError = True;
               break;
            }
            string = newString;
            HugeMemCpy(JSECHARPTR_OFFSET(string,loc),srcStr,BYTECOUNT_FROM_STRLEN(srcStr,count));
            loc += count;
            jseDestroyVariable(jsecontext,v2);
         }
      }
   }

   if( str ) jseDestroyVariable(jsecontext,str);

   jsePutStringLength(jsecontext,ret,string?string:(jsecharhugeptr)UNISTR(""),(JSE_POINTER_UINDEX)loc);
   if( string )
      HugeFree(string);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   if ( AllocError )
   {
      jseLibErrorPrintf(jsecontext,InsufficientMemory);
   }
   else
   {
      assert( jseApiOK );
   }
}
#endif /* #if defined(JSE_ARRAY_JOIN) || defined(JSE_ARRAY_TOSTRING) */


/* Array.toLocaleString() */
/* Unfinished for now */
#if 0
static jseLibFunc(Ecma_Array_toLocaleString)
{
   jsecharhugeptr string;

   const jsecharhugeptr separator;
   jseVariable str = NULL;
   JSE_POINTER_UINDEX s;
   jseVariable lengthvar;
   jseVariable ret;
   JSE_POINTER_SINDEX x, length, loc;
   jsebool AllocError = False;
   struct dynamicBuffer buffer;

   separator = UNISTR(",");
   s = 1;

   lengthvar = jseMember(jsecontext,jseGetCurrentThisVariable(jsecontext),
                         LENGTH_PROPERTY,jseTypeNumber);
   lengthvar = jseCreateConvertedVariable(jsecontext,lengthvar,
                                          jseToUint32);
   if( lengthvar == NULL )
      return;

   length = (JSE_POINTER_SINDEX) jseGetLong(jsecontext,lengthvar);
   jseDestroyVariable(jsecontext,lengthvar);

   ret = jseCreateVariable(jsecontext,jseTypeString);
   dynamicBufferInit(&buffer);

   for( x = 0;x<length;x++ )
   {
      jsecharhugeptr newString;
      jseVariable v;

      if( x!=0 )
      {
         dynamicBufferAppend(&buffer,UNISTR(","));

         v = jseIndexMember(jsecontext,jseGetCurrentThisVariable(jsecontext),
                            x,jseTypeUndefined);

         v = jseCreateConvertedVariable(jsecontext,v,jseToObject);
         if( jseErrorFlagged(jsecontext) )
         {
            jseDestroyVariable(jsecontext,v);
            jseDestryoVariable(ret);
            dynamicBufferTerm(&buffer);
            return;
         }

         /* Now look for .localeString() function */

         if( jseGetType(jsecontext,v)!=jseTypeUndefined &&
             jseGetType(jsecontext,v)!=jseTypeNull )
         {
            JSE_POINTER_UINDEX count;
            const jsecharhugeptr srcStr;
            jseVariable v2 = jseCreateConvertedVariable(jsecontext,v,jseToString);

            srcStr = jseGetString(jsecontext,v2,&count);
            newString = HugeReMalloc(string,1/*don't alloc 0 bytes*/+((loc+count)*sizeof(jsechar)));
            if ( NULL == newString )
            {
               AllocError = True;
               break;
            }
            string = newString;
            HugeMemCpy(string+loc,srcStr,count * sizeof(jsechar));
            loc += count;
            jseDestroyVariable(jsecontext,v2);
         }
      }
   }

   if( str ) jseDestroyVariable(jsecontext,str);

   jsePutStringLength(jsecontext,ret,string?string:(const jsecharhugeptr)UNISTR(""),(JSE_POINTER_UINDEX)loc);
   if( string )
      HugeFree(string);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   if ( AllocError )
   {
      jseLibErrorPrintf(jsecontext,InsufficientMemory);
   }
   else
   {
      assert( jseApiOK );
   }
}
#endif /* #if 0 */

#if defined(JSE_ARRAY_REVERSE)
/* Array.reverse() */
static jseLibFunc(Ecma_Array_reverse)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jseVariable lengthvar = jseMember(jsecontext,thisvar,LENGTH_PROPERTY,jseTypeNumber);
   JSE_POINTER_UINDEX maxs = (JSE_POINTER_UINDEX)jseGetLong(jsecontext,lengthvar) - 1;

   if( jseGetLong(jsecontext,lengthvar))
   {
      JSE_POINTER_UINDEX x;

      for( x=0;x<=maxs/2;x++ )
      {
         JSE_POINTER_UINDEX y = maxs - x;
         jseVariable t;

         if( x==y ) continue;

         t = jseCreateVariable(jsecontext,jseTypeUndefined);

         jseAssign(jsecontext,t,jseIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)x,jseTypeUndefined));
         jseAssign(jsecontext,jseIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)x,jseTypeUndefined),
                   jseIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)y,jseTypeUndefined));
         jseAssign(jsecontext,jseIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)y,jseTypeUndefined),t);

         jseDestroyVariable(jsecontext,t);
      }

      jseReturnVar(jsecontext,thisvar,jseRetCopyToTempVar);
   }

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_REVERSE) */


#if defined(JSE_ARRAY_SORT)
struct array_sort_struct {
  jseContext jsecontext;
  jseVariable func;
  jseVariable item;
};

/* array_sort_func - passed to qsort to do array sorting */
#if defined(__JSE_PALMOS__)
   static Int array_sort_func(VoidPtr one,VoidPtr two,Long lArg)
#else
#  if defined(__JSE_GEOS__) 
   static sint _pascal
#  else
   static sint /* Note: JSE_CFUNC bombs on Watcom */
#  endif
   array_sort_func(void const *one,void const *two)
#endif
{
   struct array_sort_struct *v1 = (struct array_sort_struct *)one;
   struct array_sort_struct *v2 = (struct array_sort_struct *)two;
   jseContext jsecontext = v1->jsecontext;
   int retval = 0;

   if( v1->item == NULL )
      retval = (v2->item == NULL) ? 0 : 1;
   else if( v2->item == NULL )
      retval = -1;
   else if( jseGetType(jsecontext,v1->item)==jseTypeUndefined )
   {
      retval = (jseGetType(jsecontext,v2->item)==jseTypeUndefined) ? 0 : 1 ;
   }
   else if( jseGetType(jsecontext,v2->item)==jseTypeUndefined )
   {
      retval = -1;
   }
   else if( v1->func==NULL )
   {
      /* no function supplied - default to a string comparison */
      jseVariable vc1,vc2;
      const jsecharhugeptr s1, _HUGE_ *s2;
      JSE_POINTER_UINDEX len1, len2;

      vc1 = jseCreateConvertedVariable(jsecontext,v1->item,jseToString);
      if( vc1 == NULL )
         return retval;
      s1 = jseGetString(jsecontext,vc1,&len1);
      vc2 = jseCreateConvertedVariable(jsecontext,v2->item,jseToString);
      if( vc2 == NULL )
         return retval;
      s2 = jseGetString(jsecontext,vc2,&len2);

      retval = jsecharCompare(s1,len1,s2,len2);

      jseDestroyVariable(jsecontext,vc1);
      jseDestroyVariable(jsecontext,vc2);
   }
   else
   {
      /* in the case of an error in the sort function, we kick the rest
       * out immediately
       */
      if( !jseQuitFlagged(jsecontext))
      {
         jseVariable retvar;
         jseStack stack = jseCreateStack(jsecontext);
         jsePush(jsecontext,stack,v1->item,False);
         jsePush(jsecontext,stack,v2->item,False);

         if( jseCallFunction(jsecontext,v1->func,stack,&retvar,NULL))
         {
            if( jseGetType(jsecontext,retvar)==jseTypeNumber )
            {
               jsenumber result = jseGetNumber(jsecontext,retvar);
               if ( !jseIsZero(result) )
               {
                  retval = jseIsNegative(result) ? -1 : 1 ;
               }
            }
         }
         jseDestroyStack(jsecontext,stack);
      }
   }
   return retval;
}

/* Array.sort() */
static jseLibFunc(Ecma_Array_sort)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jseVariable func = NULL;
   jseVariable lengthvar;
   JSE_POINTER_UINDEX num_items;
   struct array_sort_struct _HUGE_ *items;
   jseVariable item;
   JSE_POINTER_UINDEX x;

   if( jseFuncVarCount(jsecontext)==1 )
   {
      func = jseFuncVar(jsecontext,0);
   }

   lengthvar = jseMember(jsecontext,thisvar,LENGTH_PROPERTY,jseTypeNumber);
   num_items = (JSE_POINTER_UINDEX) jseGetLong(jsecontext,lengthvar);

   /* We do not need to sort arrays of length 0 or 1, and malloc'ing
    * arrays of size 0 would be bad, so just return in this case
    */
   if( num_items <= 1 )
      return;

   items = (struct array_sort_struct _HUGE_ *)HugeMalloc(
                         sizeof(struct array_sort_struct) * num_items);

   for( x=0;x<num_items;x++ )
   {
      items[x].jsecontext = jsecontext;
      item = jseGetIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)x);
      if( item == NULL )
         items[x].item = NULL;
      else
      {
         items[x].item = jseCreateVariable(jsecontext,jseTypeUndefined);
         jseAssign(jsecontext,items[x].item,item);
      }
      items[x].func = func;
   }

   assert( jseApiOK );

   qsort(items,(size_t)num_items,sizeof(struct array_sort_struct),array_sort_func);

   assert( jseApiOK );

   for( x=0;x<num_items;x++ )
   {
      if( items[x].item != NULL )
      {
         if( !jseQuitFlagged(jsecontext) )
            jseAssign(jsecontext,jseIndexMember(jsecontext,thisvar,(JSE_POINTER_SINDEX)x,jseTypeUndefined),
                      items[x].item);
         jseDestroyVariable(jsecontext,items[x].item);
      }
      else
      {
         jsechar buf[20];

         sprintf_jsechar((jsecharptr)buf,UNISTR("%ld"),x);
         jseDeleteMember(jsecontext,thisvar,(jsecharptr)buf);
      }
   }

   if( !jseQuitFlagged(jsecontext) )
   {
      jsePutLong(jsecontext,jseMember(jsecontext,thisvar,LENGTH_PROPERTY,jseTypeNumber),
                 (slong)num_items);
      jseReturnVar(jsecontext,thisvar,jseRetCopyToTempVar);
   }

   HugeFree(items);
   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_SORT) */

#if defined(JSE_ARRAY_CONCAT)
/* ECMA2.0: Array.concat()
 * Returns a new array with the contents of the 'this' array and any additional arguments
 * appended to it.
 *
 * This function is written based on the ECMA draft for version 2 of the specification,
 * last edited June 4, 1999.  See section 15.4.4.4 for a description of the steps to
 * be taken.
 */
static jseLibFunc(Ecma_Array_concat)
{
   /* Create a new array to return */
   jseVariable ret = CreateNewObject(jsecontext,ARRAY_PROPERTY);
   ulong length;
   jseVariable jseLength, dest, source, param;
   int arg, paramCount;
   ulong i;
   jseVariable temp;
   uint current = 0;

   paramCount = (int) jseFuncVarCount(jsecontext);

   /* Cycle through the same process, first with the current this variable, and then
    * with all the arguments.  The special value -1 is used to indicate that the this
    * variable is to be used the first time around, rather then fetching a value from
    * the argument list.
    */
   for( arg = -1; arg < paramCount; arg++ )
   {
      /* First, use the 'this' variable */
      if( arg == -1 )
      {
         param = jseGetCurrentThisVariable(jsecontext);
      }
      /* Otherwise get the next argument */
      else
      {
         param = jseFuncVar(jsecontext,(uint)arg);
      }

      temp = NULL;
      /* Check to see if this is an array object */
      if( jseTypeObject == jseGetType(jsecontext,param) &&
          NULL != (temp = jseMemberEx(jsecontext,param,CLASS_PROPERTY,
                                      jseTypeUndefined,jseCreateVar|jseDontCreateMember)) &&
          jseTypeString == jseGetType(jsecontext,temp) &&
          0 == strcmp_jsechar( ARRAY_PROPERTY,
                               (const jsecharptr)jseGetString(jsecontext,temp,NULL)) )
      {
         /* If it is, then cycle through all the elements and append them at the
          * current location
          */
         jseLength = jseMemberEx(jsecontext,param,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
         length = (ulong)jseGetLong(jsecontext,jseLength);
         jseDestroyVariable(jsecontext,jseLength);

         for( i = 0; i < length; i++, current++ )
         {
            /* If this element exists, then copy it, otherwise leave an empty space */
            if( NULL != (source = jseIndexMemberEx(jsecontext,param,
                                                   (JSE_POINTER_SINDEX)i,
                                                   jseTypeUndefined,
                                                   jseCreateVar|jseDontCreateMember) ) )
            {
               dest = jseIndexMemberEx(jsecontext,ret,
                                       (JSE_POINTER_SINDEX)current,
                                       jseTypeUndefined,jseCreateVar);
               jseAssign(jsecontext,dest,source);
               jseDestroyVariable(jsecontext,dest);
               jseDestroyVariable(jsecontext,source);
            }
         }
      }
      else
      {
         /* If not an array, convert to a string and append it at the current location */
         dest = jseIndexMemberEx(jsecontext,ret,(JSE_POINTER_SINDEX)current,
                                 jseTypeUndefined,jseCreateVar);
         source = jseCreateConvertedVariable(jsecontext,param,jseToString);
         if( source == NULL )
         {
            if( temp != NULL )
               jseDestroyVariable(jsecontext,temp);
            return;
         }

         jseAssign(jsecontext,dest,source);
         jseDestroyVariable(jsecontext,dest);
         jseDestroyVariable(jsecontext,source);
         current++;
      }

      if( temp != NULL )
         jseDestroyVariable(jsecontext,temp);

   }

   dest = jseMemberEx(jsecontext,ret,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   jsePutLong(jsecontext,dest,(slong)current);
   jseDestroyVariable(jsecontext,dest);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_CONCAT) */

#if defined(JSE_ARRAY_POP)
/* ECMA2.0: Array.pop()   The last element of the array is removed from the array
 * and returned
 *
 * This function is written based on the ECMA draft for version 2 of the
 * specification, last edited June 4, 1999.  See section 15.4.4.6 for a
 * description of the steps to be taken.
 */
static jseLibFunc(Ecma_Array_pop)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseLength, member;
   ulong length;
   jsechar buffer[15];

   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);

   /* If this array is empty, then return undefined */
   if( length == 0 )
   {
      jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeUndefined),jseRetTempVar);
   }
   else
   {  /* Otherwise pop it off and adjust the length */
      length--;
      member = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)length,
                                jseTypeUndefined,jseCreateVar);
      /* Return what we popped */
      jseReturnVar(jsecontext,member,jseRetTempVar);
      /* Now delete the member */
      sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),length);
      jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);
   }

   /* In either case, we must adjust the length.  It doesn't seem to make much
    * sense to set the length if it was 0, but since this function is intentially
    * generic, it probably has some purpose.
    */
   jsePutLong(jsecontext,jseLength,(slong)length);

   jseDestroyVariable(jsecontext, jseLength);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_POP) */

#if defined(JSE_ARRAY_PUSH)
/* ECMA2.0: Array.push( [item1] [,item2] ... )
 * The arguments are appended to the end of the array, in the order in which they
 * appear. The new length of the array is returned as the result of the call.
 *
 * This function is written based on the ECMA draft for version 2 of the
 * specification, last edited June 4, 1999.  See section 15.4.4.7 for a
 * description of the steps to be taken.
 */
static jseLibFunc(Ecma_Array_push)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseLength;
   ulong length;
   uint paramCount, i;
   jseVariable param, member;

   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,
                           jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);

   paramCount = jseFuncVarCount(jsecontext);
   /* Cycle through each argument, and append it to the array */
   for( i = 0; i < paramCount; i++, length++ )
   {
      param = jseFuncVar(jsecontext,i);

      if( NULL == param )
         return;

      /* Get the new member of the array (the member at location 'length') */
      member = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)length,
                                jseTypeUndefined,
                                jseCreateVar);
      /* Assign the parameter to the new member */
      jseAssign(jsecontext,member,param);
      jseDestroyVariable(jsecontext,member);
      /* The length is automatically incremented in the for loop */
   }

   /* Put the new length back into the 'length' member */
   jsePutLong(jsecontext,jseLength,(slong)length);
   /* Now return the new length, letting the intepreter destroy the member */
   jseReturnVar(jsecontext,jseLength,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_PUSH) */

#if defined(JSE_ARRAY_SHIFT)
/* Array.shift()  The first element of the array is removed from the array and
 *                returned
 *
 * This function is written based on the ECMA draft for version 2 of the
 * specification, last edited January 7, 1999.  See section 15.4.4.8 for a
 * description of the steps to be taken.
 */
static jseLibFunc(Ecma_Array_shift)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseLength, ret;
   ulong length, i;
   jseVariable prev, current;
   jsechar buffer[15];

   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);

   if( length == 0 )
   {
      /* We're supposed to put the length to be 0, but we just got it, so why bother? */
      jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeUndefined),jseRetTempVar);
   }
   else
   {
      /* Save the first member to return later */
      ret = jseIndexMemberEx(jsecontext,thisVar,0,jseTypeUndefined,jseCreateVar);
      /* We copy to a temp var because the value will be altered later */
      jseReturnVar(jsecontext,ret,jseRetCopyToTempVar);
      jseDestroyVariable(jsecontext,ret);

      for (i = 1; i < length; i++ )
      {
         /* Get the current member, if it exists */
         current = jseGetIndexMemberEx(jsecontext,thisVar,
                                       (JSE_POINTER_SINDEX)i,
                                       jseCreateVar|jseCheckHasProperty);
         /* And get the previous member too */
         prev = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)i-1,
                                 jseTypeUndefined,
                                 jseCreateVar);

         /* Only do the following if it exists - ECMA states this is optional,
          * i.e. you can pretend to treat the member as if it exists if you want
          */
         if( current != NULL )
         {
            /* assign to the previous member */
            jseAssign(jsecontext,prev,current);

            /* Don't forget to delete the member we created */
            jseDestroyVariable(jsecontext,current);
         }
         else
         {
            /* Otherwise we delete the previous one */
            sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i-1);
            jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);
         }

         jseDestroyVariable(jsecontext,prev);

      }

      /* Finally we delete the member at length-1 */
      sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i-1);
      jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);

      /* And adjust the length member to reflect the new length */
      jsePutLong(jsecontext,jseLength,(slong)i-1);
   }

   jseDestroyVariable(jsecontext,jseLength);
   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_SHIFT) */

#if defined(JSE_ARRAY_SLICE)
/* ECMA2.0: Array.slice( start [, end] )
 * When the slice method is called with one or two argument 'start' and (optionally)
 * 'end', it returns an array containing the elements of the array from element
 * 'start' up to, but not including, element 'end' (or through the end of the array
 * if 'end' is not supplied).  If 'start' is negative, it is treated as (length+start)
 * where 'length' is the length of the array.  If 'end' is supplied and negative, it
 * is treated as (length+end) where 'length' is the length of the array.
 *
 * This function is written based on the ECMA draft for version 2 of the specification,
 * last edited June, 1999.  See section 15.4.4.10 for a description of the steps to
 * be taken.
 */
static jseLibFunc(Ecma_Array_slice)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret;
   jseVariable jseLength, jseStart, jseEnd;
   ulong length;
   slong start, end, n;
   jseVariable source, dest;

   /* Get the current length */
   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);
   jseDestroyVariable(jsecontext,jseLength);

   JSE_FUNC_VAR_NEED(jseStart,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
   if ( !GetSlongFromVar(jsecontext,jseStart,&start) )
      return;

   /* If end is supplied, use that.  Otherwise use length */
   if( 1 < jseFuncVarCount(jsecontext) )
   {
      JSE_FUNC_VAR_NEED(jseEnd,jsecontext,1,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
      if ( !GetSlongFromVar(jsecontext,jseEnd,&end) )
         return;
   }
   else
   {
      end = (slong) length;
   }

   if( start < 0 )
      start = max((slong) length + start, 0);
   else
      start = min( start, (slong) length );

   /* Check for negative 'end' values */
   if( end < 0 )
      end = max((slong) length + end, 0 );
   else
      end = min( end, (slong) length );

   /* Create the return array */
   ret = CreateNewObject(jsecontext,ARRAY_PROPERTY);


   /* Now we enter the main for loop */
   for( n = 0; start < end; start++, n++ )
   {
      source = jseGetIndexMemberEx(jsecontext,thisVar,
                                   (JSE_POINTER_SINDEX)start,
                                   jseCreateVar|jseCheckHasProperty);

      if( NULL != source )
      {
         dest = jseIndexMemberEx(jsecontext,ret,(JSE_POINTER_SINDEX)n,
                                 jseTypeUndefined,jseCreateVar);
         jseAssign(jsecontext,dest,source);

         jseDestroyVariable(jsecontext,dest);
         jseDestroyVariable(jsecontext,source);
      }

      /* start and n are automatically increased */
   }
   /* Update length */
   jseLength = jseMemberEx(jsecontext,ret,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   jsePutLong(jsecontext,jseLength,(slong)n);
   jseDestroyVariable(jsecontext,jseLength);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_SLICE) */

#if defined(JSE_ARRAY_SPLICE)
/* ECMA2.0: Array.splice(start, deleteCount [,item1] [,item2] ... )
 * When the splice method is called with two or more arguments, 'start',
 * 'deleteCount', and (optionally) 'item1', 'item2', etc., the 'deleteCount'
 * elements of the array starting at array index 'start' are replaced by the
 * arguments 'item1', 'item2', etc. The array of elements removed is returned
 *
 * This function is written based on the ECMA draft for version 2 of the
 * specification, last edited June 4, 1999.  See section 15.4.4.12 for a
 * description of the steps to be taken.
 */
/* This is a 54 step function, so it's going to be long!!! */
static jseLibFunc(Ecma_Array_splice)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable retVar;
   jseVariable jseLength, jseStart, jseDeleteCount;
   jseVariable source, dest;
   ulong length, i;
   slong start, deleteCount;
   uint paramCount, j;
   jsechar buffer[15];

   /* Next, get the current length */
   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);
   jseDestroyVariable(jsecontext,jseLength);

   /* Next, get the arguments */
   JSE_FUNC_VAR_NEED(jseStart,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
   if ( !GetSlongFromVar(jsecontext,jseStart,&start) )
      return;

   JSE_FUNC_VAR_NEED(jseDeleteCount,jsecontext,1,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
   if ( !GetSlongFromVar(jsecontext,jseDeleteCount,&deleteCount) )
      return;

   /* First, create the return array */
   retVar = CreateNewObject(jsecontext,ARRAY_PROPERTY);

   /* Now, we make sure they are valid indexes, checking for negatives */
   if( start < 0 )
      start = (slong) max( length + start, 0 );
   else
      start = (slong) min( (ulong)start, length );

   deleteCount = min( deleteCount, (slong)length - start );

   /* Copy the members into the new array */
   for( i = 0; i < (uint)deleteCount; i++ )
   {
      source = jseGetIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i+start),jseCreateVar|jseCheckHasProperty);

      if( NULL != source )
      {
         dest = jseIndexMemberEx(jsecontext,retVar,(JSE_POINTER_SINDEX)i,jseTypeUndefined,
                               jseCreateVar);
         jseAssign(jsecontext,dest,source);
         /* Destroy members we've created */
         jseDestroyVariable(jsecontext,dest);
         jseDestroyVariable(jsecontext,source);
      }
   }

   dest = jseMemberEx(jsecontext,retVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   jsePutLong(jsecontext,dest,(slong)i);
   jseDestroyVariable(jsecontext,dest);

   /* OK, now we're up to step 17... 37 to go! */
   paramCount = jseFuncVarCount(jsecontext) - 2;

   /* We have fewer parameters to insert than we're deleting, so move the others down */
   if( paramCount < (uint)deleteCount )
   {
      /* First we move them down */
      for( i = (ulong) start; i < length - deleteCount; i++ )
      {
         source = jseGetIndexMemberEx(jsecontext,thisVar,
                                      (JSE_POINTER_SINDEX)(i+deleteCount),jseCreateVar|jseCheckHasProperty);

         if( NULL != source )
         {
            dest = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i+paramCount),
                                    jseTypeUndefined,jseCreateVar);
            jseAssign(jsecontext,dest,source);

            jseDestroyVariable(jsecontext,dest);
            jseDestroyVariable(jsecontext,source);
         }
         else
         {  /* Otherwise, we just delete this member */
            sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i+paramCount);
            jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);
         }
      }

      /* Then delete the extras */
      for( i = length; i > length - deleteCount + paramCount; i-- )
      {
         sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i);
         jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);
      }
   }
   else if( paramCount > (uint)deleteCount )
   {
      /* We have too many parameters, so move extras up */
      for( i = length - deleteCount; i > (ulong)start; i-- )
      {
         source = jseGetIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i+deleteCount-1),
                                      jseCreateVar|jseCheckHasProperty);

         if( NULL != source )
         {
            dest = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i+paramCount-1),
                                    jseTypeUndefined,jseCreateVar);
            jseAssign(jsecontext,dest,source);

            jseDestroyVariable(jsecontext,dest);
            jseDestroyVariable(jsecontext,source);
         }
         else
         {  /* Otherwise, we just delete this member */
            sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i+paramCount);
            jseDeleteMember(jsecontext,thisVar,(jsecharptr)buffer);
         }
      }
   }

   /* By now, we have exactly enough room for the parameters, so simply copy them */
   for( i = (ulong)start, j = 0; j < paramCount; i++, j++ )
   {
      source = jseFuncVar(jsecontext,j+2);
      assert( NULL != source );

      dest = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)i,jseTypeUndefined,
                              jseCreateVar);
      jseAssign(jsecontext,dest,source);

      jseDestroyVariable(jsecontext,dest);
   }

   /* Finally!!!!! Now we just have to set the new length and return the return array */
   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   jsePutLong(jsecontext,jseLength,(slong)(length-deleteCount+paramCount));
   jseDestroyVariable(jsecontext,jseLength);

   jseReturnVar(jsecontext,retVar,jseRetTempVar);
}
#endif /* #if defined(JSE_ARRAY_SPLICE) */

#if defined(JSE_ARRAY_UNSHIFT)
/* ECMA2.0: Array.unshift( [item1] [,item2] ... )
 * The arguments are prepended to the start of the array, such that their order within the
 * array is the same as the order in which they appear in the argument list.  The new length of
 * of the array is returned.
 *
 * This function is written based on the ECMA draft for version 2 of the specification,
 * last edited June 4, 1999.  See section 15.4.4.13 for a description of the steps to
 * be taken.
 */
static jseLibFunc(Ecma_Array_unshift)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseLength;
   ulong length, i;
   uint argCount, parmi;
   jseVariable source, dest;
   jsechar buffer[15];

   /* Get the current array */
   jseLength = jseMemberEx(jsecontext,thisVar,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
   length = (ulong) jseGetLong(jsecontext,jseLength);

   /* Get the number of arguments */
   argCount = jseFuncVarCount(jsecontext);

   /* First move the existing elements to make room */
   for( i = length; i > 0; i-- )
   {
      source = jseGetIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i-1),jseCreateVar|jseCheckHasProperty);

      if( NULL != source )
      {
         dest = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)(i+argCount-1),jseTypeUndefined,jseCreateVar);

         jseAssign( jsecontext, dest, source );

         jseDestroyVariable( jsecontext, dest );
         jseDestroyVariable( jsecontext, source );
      }
      else
      {
         sprintf_jsechar((jsecharptr)buffer,UNISTR("%ld"),i+argCount-1);
         jseDeleteMember( jsecontext, thisVar, (jsecharptr)buffer );
      }
   }

   /* Now we add in the arguments in the appropriate order */
   for( parmi = 0; parmi < argCount; parmi++ )
   {
      source = jseFuncVar(jsecontext,parmi);
      assert( NULL != source );

      dest = jseIndexMemberEx(jsecontext,thisVar,(JSE_POINTER_SINDEX)parmi,jseTypeUndefined,jseCreateVar);
      jseAssign( jsecontext, dest, source );

      jseDestroyVariable(jsecontext,dest);
   }

   /* Finally, adjust the length */
   jsePutLong(jsecontext,jseLength,(slong)(length+argCount));
   /* And return it */
   jseReturnVar(jsecontext,jseLength,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_ARRAY_UNSHIFT) */

#if defined(JSE_ARRAY_TOSOURCE)
/* Array.toSource() */
static jseLibFunc(Ecma_Array_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   struct dynamicBuffer buffer;
   jseVariable ret = jseCreateVariable(jsecontext,jseTypeString);
   jseVariable member;
   JSE_POINTER_UINDEX i, arrayLength;
   jsebool firstTime = True;

   dynamicBufferInit(&buffer);

   dynamicBufferAppend(&buffer,UNISTR("["));

   /* Now we cycle through the members and append them in literal syntax */
   arrayLength = jseGetArrayLength(jsecontext,thisVar,NULL);

   for( i = 0; i < arrayLength; i++ )
   {
      if( firstTime )
         firstTime = False;
      else
         dynamicBufferAppend(&buffer,UNISTR(","));

      if( NULL != (member = jseGetIndexMember(jsecontext,thisVar,
                                              (JSE_POINTER_SINDEX)i)) )
      {
         jseVariable convertedVariable = jseConvertToSource(jsecontext,member);

         if( NULL == convertedVariable )
         {
            jseConvert(jsecontext,ret,jseTypeNull);
            jseReturnVar(jsecontext,ret,jseRetTempVar);
            dynamicBufferTerm(&buffer);
            return;
         }
         else
         {
            const jsecharptr text = (const jsecharptr)jseGetString(jsecontext,
                                                                   convertedVariable,NULL);

            dynamicBufferAppend(&buffer,text);

            jseDestroyVariable(jsecontext,convertedVariable);
         }
      }
   }

   dynamicBufferAppend(&buffer,UNISTR("]"));

   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                jseRetTempVar);

   dynamicBufferTerm(&buffer);

}
#endif /* #if defined(JSE_ARRAY_TOSOURCE) */


/* ---------------------------------------------------------------------- */

#pragma codeseg SEOBJECT3_TEXT

/* Boolean object functions */

#ifdef JSE_BOOLEAN_ANY
#if !defined(JSE_BOOLEAN_OBJECT)
#  error must #define JSE_BOOLEAN_OBJECT 1 or #define JSE_BOOLEAN_ALL to use JSE_BOOLEAN_ANY
#endif
/* This is the 'builtin' boolean construct. */
static jseLibFunc(Ecma_Boolean_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,BOOLEAN_PROPERTY),jseRetTempVar);
   assert( jseApiOK );
}

/* Boolean() call */
static jseLibFunc(Ecma_Boolean_call)
{
   if( jseFuncVarCount(jsecontext)==1 )
   {
      jseVariable ret;
      if( NULL != (ret = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),
                                                    jseToBoolean)) )
         jseReturnVar(jsecontext,ret,jseRetTempVar);
   }
   else
   {
      jseVariable ret = jseCreateVariable(jsecontext,jseTypeBoolean);
      jsePutBoolean(jsecontext,ret,FALSE);
      jseReturnVar(jsecontext,ret,jseRetTempVar);
   }

   assert( jseApiOK );
}

/* new Boolean() - Boolean.construct */
static jseLibFunc(Ecma_Boolean_construct)
{
   jsebool value;
   jseVariable val, thisvar;

   if( 0 < jseFuncVarCount(jsecontext) )
   {
      JSE_FUNC_VAR_NEED(val,jsecontext,0,
                        JSE_VN_LOCKREAD
                       |JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_BOOLEAN));
      value = (jsebool)jseGetLong(jsecontext,val);
   }
   else
   {
      value = False;
   }
   thisvar = jseGetCurrentThisVariable(jsecontext);
   jsePutBoolean(jsecontext,
                 jseMemberEx(jsecontext,thisvar,VALUE_PROPERTY,jseTypeBoolean,jseLockWrite),
                 value);

   assert( jseApiOK );
}

/* Boolean.valueOf() */
static jseLibFunc(Ecma_Boolean_valueOf)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);

   if( !ensure_type(jsecontext,thisvar,BOOLEAN_PROPERTY) )
      return;

   jseReturnVar(jsecontext,
                jseCreateSiblingVariable(jsecontext,
                   jseMember(jsecontext,thisvar,VALUE_PROPERTY,jseTypeBoolean),0),
                jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #ifdef JSE_BOOLEAN_ANY */

#if defined(JSE_BOOLEAN_TOSTRING)
/* Boolean.toString() */
static jseLibFunc(Ecma_Boolean_toString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret,val;
   jsebool value;

   if( !ensure_type(jsecontext,thisvar,BOOLEAN_PROPERTY) )
      return;

   ret = jseCreateVariable(jsecontext,jseTypeString);

   val = jseMember(jsecontext,thisvar,VALUE_PROPERTY,jseTypeBoolean);
   value = (jseGetType(jsecontext,val)==jseTypeBoolean)?
      (jsebool)jseGetLong(jsecontext,val):FALSE;

   jsePutString(jsecontext,ret,value?textlibstrEcmaTRUE:textlibstrEcmaFALSE);
   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_BOOLEAN_TOSTRING) */

#if defined(JSE_BOOLEAN_TOSOURCE)
/* Boolean.toSource() */
static jseLibFunc(Ecma_Boolean_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable convertedVariable = jseCreateConvertedVariable(jsecontext,
                                         thisVar,jseToString);
   struct dynamicBuffer buffer;

   if( convertedVariable == NULL )
      return;

   dynamicBufferInit(&buffer);

   dynamicBufferAppend(&buffer,UNISTR("new Boolean("));
   dynamicBufferAppend(&buffer,
                       (const jsecharptr)jseGetString(jsecontext,convertedVariable,NULL));
   dynamicBufferAppend(&buffer,UNISTR(")"));

   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                jseRetTempVar);

   jseDestroyVariable(jsecontext,convertedVariable);
   dynamicBufferTerm(&buffer);

}
#endif /* #if defined(JSE_BOOLEAN_TOSOURCE) */

/* ----------------------------------------------------------------------
 * 'Number' Object methods
 * ---------------------------------------------------------------------- */

#ifdef JSE_NUMBER_ANY
#if !defined(JSE_NUMBER_OBJECT)
#  error must #define JSE_NUMBER_OBJECT 1 or #define JSE_NUMBER_ALL to use JSE_NUMBER_ANY
#endif
/* This is the 'builtin' number construct. */
static jseLibFunc(Ecma_Number_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,NUMBER_PROPERTY),jseRetTempVar);
   assert( jseApiOK );
}

/* Number() call */
static jseLibFunc(Ecma_Number_call)
{
   if( jseFuncVarCount(jsecontext)==1 )
   {
      jseVariable ret = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),
                                                   jseToNumber);
      if( ret != NULL )
         jseReturnVar(jsecontext,ret,jseRetTempVar);
   }
   else
   {
      jseVariable ret = jseCreateVariable(jsecontext,jseTypeNumber);
      jsePutLong(jsecontext,ret,0);
      jseReturnVar(jsecontext,ret,jseRetTempVar);
   }

   assert( jseApiOK );
}

/* new Number() - Number.construct */
static jseLibFunc(Ecma_Number_construct)
{
   jsenumber value;
   jseVariable val, tmp, thisvar;

   if( 0 < jseFuncVarCount(jsecontext) )
   {
      JSE_FUNC_VAR_NEED(val,jsecontext,0,
                        JSE_VN_LOCKREAD
                       |JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
      value = jseGetNumber(jsecontext,val);
   }
   else
   {
      value = jseZero;
   }
   thisvar = jseGetCurrentThisVariable(jsecontext);
   jsePutNumber(jsecontext,
                tmp=jseMemberEx(jsecontext,thisvar,VALUE_PROPERTY,jseTypeNumber,jseLockWrite),
                value);
   jseSetAttributes(jsecontext,tmp,jseDontEnum);

   assert( jseApiOK );
}

/* Number.valueOf() */
static jseLibFunc(Ecma_Number_valueOf)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret;

   if( !ensure_type(jsecontext,thisvar,NUMBER_PROPERTY) )
      return;

   ret = jseCreateConvertedVariable(jsecontext,
                                    jseMember(jsecontext,thisvar,VALUE_PROPERTY,jseTypeNumber),
                                    jseToNumber);

   if( ret != NULL )
      jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #ifdef JSE_NUMBER_ANY */

#if defined(JSE_NUMBER_TOSTRING) || defined(JSE_NUMBER_TOLOCALESTRING)
/* Number.toString() */
static jseLibFunc(Ecma_Number_toString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jseVariable ret;
   jsechar buffer[ECMA_NUMTOSTRING_MAX];

   if( !ensure_type(jsecontext,thisvar,NUMBER_PROPERTY))
      return;

   ret = jseCreateVariable(jsecontext,jseTypeString);

   EcmaNumberToString(buffer,
                      jseGetNumber(jsecontext,jseMember(jsecontext,thisvar,VALUE_PROPERTY,jseTypeNumber)));

   jsePutString(jsecontext,ret,(jsecharptr)buffer);
   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_NUMBER_TOSTRING) */

#if defined(JSE_NUMBER_TOSOURCE)
/* Number.toSource() */
static jseLibFunc(Ecma_Number_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable convertedVariable = jseCreateConvertedVariable(jsecontext,
                                         thisVar,jseToString);
   struct dynamicBuffer buffer;

   if( convertedVariable == NULL )
      return;

   dynamicBufferInit(&buffer);

   dynamicBufferAppend(&buffer,UNISTR("new Number("));
   dynamicBufferAppend(&buffer,
                       (const jsecharptr)jseGetString(jsecontext,convertedVariable,NULL));
   dynamicBufferAppend(&buffer,UNISTR(")"));

   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                jseRetTempVar);

   jseDestroyVariable(jsecontext,convertedVariable);
   dynamicBufferTerm(&buffer);
}
#endif /* #if defined(JSE_NUMBER_TOSOURCE) */

#if defined(JSE_NUMBER_TOFIXED) \
 || defined(JSE_NUMBER_TOEXPONENTIAL) \
 || defined(JSE_NUMBER_TOPRECISION)
#define _toFixed       2
#define _toExponential 1
#define _toPrecision   0
   static jseVariable NEAR_CALL
Ecma_Number_toSomething(jseContext jsecontext,uint argc,jseVariable *argv,
                        int toWhat)
{
   jsenumber x;
   slong f;
   jseVariable ret = jseCreateVariable(jsecontext,jseTypeString);
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable valueVar = jseMember(jsecontext,thisVar,VALUE_PROPERTY,jseTypeNumber);

   assert( toWhat==_toPrecision || toWhat==_toExponential || toWhat==_toFixed );

   /* get the number value from 'this' */
   x = jseGetNumber(jsecontext,valueVar);
   /* jseGetNumber() can pull a number of out anything, although it may be !Finite */
   assert( 0 == jseQuitFlagged(jsecontext) );

   /* determine value for f */
   if ( argc==0 )
   {
      if ( _toPrecision == toWhat )
      {
         goto StandardConversion;
      }
      f = 0;
   }
   else
   {
      /* safe to ignore error; quit flag will be already set */
      GetSlongFromVar(jsecontext,argv[0],&f);
   }

   /* check on range error */
   if ( ( _toPrecision == toWhat && (f<1 || f>21) )
     || ( _toPrecision != toWhat && (f<0 || f>20) ) )
   {
     /* RangeError Exception */
     jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibPRECISION_OUT_OF_RANGE));
   }
   else
   {
      if ( !jseIsFinite(x) )
      {
         StandardConversion:
         /* NaN, Infinity, or -Infinity, standard conversion */
         jseDestroyVariable(jsecontext,ret);
         ret = jseCreateConvertedVariable(jsecontext,valueVar,jseToString);
      }
      else
      {
         jsechar buffer[ECMA_NUMTOSTRING_MAX];
         if ( _toExponential == toWhat )
         {
            /* Format number as Exponential notation */
            /* field width must be an int */
            JSE_FP_DTOSTR(x,(int)f,buffer,UNISTR("e"));
         }
         else if ( _toFixed == toWhat )
         {
            /* if |x| > pow (10,21) */
            if( JSE_FP_LTE(JSE_FP_POW(JSE_FP_CAST_FROM_SLONG(10),JSE_FP_CAST_FROM_SLONG(21)),JSE_FP_FABS(x)) )
            {
               /* ToString(x) */
               goto StandardConversion;
            }
            /* Format number as fixed-point notation*/
            /* field width must be an int */
            JSE_FP_DTOSTR(x,(int)f,buffer,UNISTR("f"));
         }
         else
         {
            assert( _toPrecision == toWhat );
            /* field width must be an int */
            /* if x>=pow(10,-6) && x<pow(10,f), use fixed-point notation
             * otherwise, use exponential notation */
            if( JSE_FP_LTE(JSE_FP_POW(JSE_FP_CAST_FROM_SLONG(10),JSE_FP_CAST_FROM_SLONG(-6)),x) &&
                JSE_FP_LT(x, JSE_FP_POW(JSE_FP_CAST_FROM_SLONG(10),JSE_FP_CAST_FROM_SLONG(f))) )
            {
               JSE_FP_DTOSTR(x,(int)f,buffer,UNISTR("f"));
            }
            else
            {
               JSE_FP_DTOSTR(x,(int)f,buffer,UNISTR("e"));
            }
         }
         jsePutString(jsecontext,ret,(jsecharptr)buffer);
      }
   }
   assert( jseApiOK );

   return ret;
}

/* ECMAScript 3rd edition - 15.7.4.5 */
/* Number.toFixed() */
#if defined(JSE_NUMBER_TOFIXED)
static jseArgvLibFunc(Ecma_Number_toFixed)
{
   return Ecma_Number_toSomething(jsecontext,argc,argv,_toFixed);
}
#endif

/* ECMAScript 3rd edition - 15.7.4.6 */
/* Number.toExponential() */
#if defined(JSE_NUMBER_TOEXPONENTIAL)
static jseArgvLibFunc(Ecma_Number_toExponential)
{
   return Ecma_Number_toSomething(jsecontext,argc,argv,_toExponential);
}
#endif

/* ECMAScript 3rd edition - 15.7.4.7 */
/* Number.toPrecision() */
#if defined(JSE_NUMBER_TOPRECISION)
static jseArgvLibFunc(Ecma_Number_toPrecision)
{
   return Ecma_Number_toSomething(jsecontext,argc,argv,_toPrecision);
}
#endif
#endif /* #if defined(JSE_NUMBER_TOFIXED) || _TOEXPONENTIAL) || _TOPRECISION) */



#if defined(JSE_EXCEPTION_ANY)
#if !defined(JSE_EXCEPTION_OBJECT)
#  error must #define JSE_EXCEPTION_OBJECT 1 or #define JSE_EXCEPTION_ALL to use JSE_EXCEPTION_ANY
#endif

static jseLibFunc(Ecma_Exception_toString)
{
   struct dynamicBuffer buffer;
   jseVariable thisVar, name, message, convertedMessage, ret;

   thisVar = jseGetCurrentThisVariable(jsecontext);

   if(!ensure_type(jsecontext,thisVar,EXCEPTION_PROPERTY))
      return;

   dynamicBufferInit(&buffer);

   name = jseGetMemberEx(jsecontext,thisVar,UNISTR("name"),jseCreateVar);
   if( name != NULL )
   {
      dynamicBufferAppend(&buffer,(const jsecharptr)jseGetString(jsecontext,name,NULL));
      jseDestroyVariable(jsecontext,name);
   }
   else
   {
      dynamicBufferAppend(&buffer,EXCEPTION_PROPERTY);
   }

   message = jseGetMemberEx(jsecontext,thisVar,UNISTR("message"),jseCreateVar);
   if( message != NULL)
   {
      const jsecharptr text;
      size_t loc;
      convertedMessage = jseCreateConvertedVariable(jsecontext,message,jseToString);

      if( convertedMessage != NULL )
      {
         text = (const jsecharptr)jseGetString(jsecontext,convertedMessage,NULL);
         /* Let's see if this is one of our messages with the ID number, in which case
          * we won't add the colon for readability
          */
         loc = strspn_jsechar(text,UNISTR("0123456789"));
         if( JSECHARPTR_GETC(JSECHARPTR_OFFSET(text,loc)) != UNICHR(':') )
            dynamicBufferAppend(&buffer,UNISTR(": "));
         else
            dynamicBufferAppend(&buffer,UNISTR(" "));

         dynamicBufferAppend(&buffer,text);
         jseDestroyVariable(jsecontext,convertedMessage);
         jseDestroyVariable(jsecontext,message);
      }
      else
         jseDestroyVariable(jsecontext,message);
   }

   ret = jseCreateVariable(jsecontext,jseTypeString);
   jsePutString(jsecontext,ret,dynamicBufferGetString(&buffer));
   jseReturnVar(jsecontext,ret,jseRetTempVar);

   dynamicBufferTerm(&buffer);
}

static jseVariable
MakeExceptionObject(jseContext jsecontext, jseVariable ret,
                      const jsecharptr exceptionName )
{
   jseVariable name;

   jseInitializeObject(jsecontext,ret,(exceptionName==NULL ? EXCEPTION_PROPERTY :
                                                            exceptionName) );

   if( exceptionName != NULL )
   {
      name = jseMemberEx(jsecontext,ret,UNISTR("name"),jseTypeString,jseCreateVar);
      jsePutString(jsecontext,name,exceptionName);
      jseDestroyVariable(jsecontext,name);
   }

   if( jseFuncVarCount(jsecontext) > 0 )
   {
      jseVariable param = jseFuncVar(jsecontext,0);
      jseVariable message;

      assert( param != NULL );

      message = jseMemberEx(jsecontext,ret,UNISTR("message"),jseTypeString,
                            jseCreateVar);
      jseAssign(jsecontext,message,param);
      jseDestroyVariable(jsecontext,message);
   }

   return ret;
}

static jseLibFunc(Ecma_Exception)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               NULL),
                jseRetTempVar);
}

static jseLibFunc(Ecma_Exception_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               NULL),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_SyntaxError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               SYNTAX_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_SyntaxError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               SYNTAX_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_ReferenceError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               REFERENCE_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_ReferenceError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               REFERENCE_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_ConversionError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               CONVERSION_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_ConversionError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               CONVERSION_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_ArrayLengthError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               ARRAYLENGTH_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_ArrayLengthError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               ARRAYLENGTH_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_TypeError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               TYPE_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_TypeError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               TYPE_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_URIError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               URI_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_URIError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               URI_EXCEPTION),
                jseRetCopyToTempVar);
}

static jseLibFunc(Ecma_EvalError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               EVAL_EXCEPTION),
                jseRetTempVar);
}

static jseLibFunc(Ecma_EvalError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               EVAL_EXCEPTION),
                jseRetCopyToTempVar);
}

#if defined(JSE_REGEXP_OBJECT)
static jseLibFunc(Ecma_RegExpError)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseCreateVariable(jsecontext,jseTypeObject),
                                               REGEXP_EXCEPTION),
                jseRetTempVar);
}
static jseLibFunc(Ecma_RegExpError_construct)
{
   jseReturnVar(jsecontext,MakeExceptionObject(jsecontext,
                                               jseGetCurrentThisVariable(jsecontext),
                                               REGEXP_EXCEPTION),
                jseRetCopyToTempVar);
}
#endif

#endif /* #if defined(JSE_EXCEPTION_ANY) */

/* ---------------------------------------------------------------------- */
#if defined(JSE_NUMBER_ANY)
#  if (0!=JSE_FLOATING_POINT)
#     if !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR)
#        if defined(__DJGPP__) || defined(__BORLANDC__) || defined(__MWERKS__)
         /* Under Metrowerks,DBL_MAX and DBL_MIN are not simply defines, and cannot
          * be used in static assignments... same for 390
          */
#           if defined(JSE_NUMBER_MAX_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MAX = 1.7976931348623157E+308;
#           endif
#           if defined(JSE_NUMBER_MIN_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MIN = 0.0;
#           endif
#        elif defined(__JSE_390__)
#           if defined(JSE_NUMBER_MAX_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MAX = 1.75+308;
#           endif
#           if defined(JSE_NUMBER_MIN_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MIN = 0.0;
#           endif
#        elif defined(__JSE_NWNLM__)
            /* DBL_MAX from watcom header looks like infinity, so take
             * from the standard header value
             */
#           if defined(JSE_NUMBER_MAX_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MAX = 1.79769313486231500e+308 /* DBL_MAX */;
#           endif
#           if defined(JSE_NUMBER_MIN_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MIN = 2.22507385850720160e-308 /* DBL_MIN */;
#           endif
#        else
#           if defined(JSE_NUMBER_MAX_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MAX = DBL_MAX;
#           endif
#           if defined(JSE_NUMBER_MIN_VALUE)
               static CONST_DATA(jsenumber) jse_DBL_MIN = DBL_MIN;
#           endif
#        endif
#     endif
#  else
#     if defined(JSE_NUMBER_MAX_VALUE)
         static jsenumber seMax;
#     endif
#     if defined(JSE_NUMBER_MIN_VALUE)
        static jsenumber seMin;
#     endif
#  endif

#if defined(JSE_NUMBER_NEGATIVE_INFINITY)
   static VAR_DATA(jsenumber) seNegInfinity;
#endif

#endif /* #if defined(JSE_NUMBER_ANY) */

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

#if defined(JSE_ARRAY_ANY)     \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_EXCEPTION_ANY)
static CONST_DATA(struct jseFunctionDescription) ObjectLibFunctionList[] =
{
   /*
    * This table builds up all of the pre-defined links between the
    * various types of builtin objects. Its all pretty confusing. I
    * built it by reading the spec and doing exactly what they said (or
    * the best I could gather from it.) I hope I didn't make too many
    * mistakes.
    */

   /*
    * Notes: all prototype objects have object prototype as their _prototype
    * except the object prototype object itself.
    */

   /* ---------------------------------------------------------------------- */
   /* Next we build up the 'Function' global function/object. */
   /* ---------------------------------------------------------------------- */
   /*
    * functions in the function prototype object dont point back to itself
    * anymore, section 15 pg 58.
    */
#  ifdef JSE_FUNCTION_ANY
      JSE_LIBOBJECT( FUNCTION_PROPERTY,    Ecma_Function_construct, 0, -1,
                     jseDontEnum,  jseFunc_NoGlobalSwitch | jseFunc_Secure ),
      JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_Function_builtin,   0,  0,
                     jseDontEnum,  jseFunc_Secure ),
#     if defined(JSE_FUNCTION_TOSOURCE)
         JSE_PROTOMETH( TOSOURCE_PROPERTY,    Ecma_Function_toSource,  0,  0,
                        jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_FUNCTION_CALL)
         JSE_PROTOMETH( UNISTR("call"),       Ecma_Function_call,      0,  -1,
                        jseDontEnum,  jseFunc_Secure ),
         JSE_VARSTRING( UNISTR("prototype.call.length"), UNISTR("1"),
                        jseDontEnum | jseReadOnly | jseDontDelete ),
#     endif
#     if defined(JSE_FUNCTION_APPLY)
         JSE_PROTOMETH( UNISTR("apply"),      Ecma_Function_apply,     0,  2,
                        jseDontEnum,  jseFunc_Secure ),
#     endif
      /* Spec says length is 1. */
      JSE_VARSTRING( LENGTH_PROPERTY, UNISTR("1"), jseDontEnum | jseDontDelete | jseReadOnly ),
      /* the function prototype object itself is a function */
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, UNISTR("Object.prototype"),  jseDontEnum ),
      JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
#  endif

   /* ---------------------------------------------------------------------- */
   /* Set up the 'Object' global object. It is a function. We change its */
   /* construct property because it behaives differently depending on if */
   /* it is called as a function or a construct. */
   /* ---------------------------------------------------------------------- */
#  if defined(JSE_OBJECT_ANY)
      JSE_LIBOBJECT( OBJECT_PROPERTY,      Ecma_Object_call,    0,      1,
                     jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"Object\""),
                     jseDontEnum ),
      JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_Object_builtin, 0,      0,
                     jseDontEnum,  jseFunc_Secure ),
#     if defined(JSE_OBJECT_TOSOURCE)
         JSE_PROTOMETH( TOSOURCE_PROPERTY, Ecma_Object_toSource,   0,      0,
                        jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_OBJECT_ISPROTOTYPEOF)
         JSE_PROTOMETH( UNISTR("isPrototypeOf"), Ecma_Object_isPrototypeOf,  1,  1,
                        jseDontEnum|jseFunc_PassByReference, jseFunc_Secure ),
#     endif
#     if defined(JSE_OBJECT_PROPERTYISENUMERABLE)
         JSE_PROTOMETH( UNISTR("propertyIsEnumerable"), Ecma_Object_propertyIsEnumerable, 1, 1,
                        jseDontEnum, jseFunc_Secure),
#     endif
#     if defined(JSE_OBJECT_HASOWNPROPERTY)
         JSE_PROTOMETH( UNISTR("hasOwnProperty"), Ecma_Object_hasProperty, 1, 1,
                        jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_OBJECT_TOLOCALESTRING)
         JSE_PROTOMETH( UNISTR("toLocaleString"), Ecma_Object_toLocaleString, 0, 0,
                        jseDontEnum, jseFunc_Secure ),
#     endif
      JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
#  endif

   /* ---------------------------------------------------------------------- */
   /* The 'Array' object */
   /* ---------------------------------------------------------------------- */
#  if defined(JSE_ARRAY_ANY)
      JSE_LIBOBJECT( ARRAY_PROPERTY,       Ecma_Array_call,     0,     -1,      jseDontEnum,  jseFunc_Secure ),
      /* Ecma_Array_call used for both _call and _construct, so don't need them individually */
      /* Spec says length is 1. */
      JSE_VARSTRING( LENGTH_PROPERTY, UNISTR("1"), jseDontEnum | jseDontDelete | jseReadOnly ),
      JSE_VARSTRING( UNISTR("prototype.length"), UNISTR("0"), jseDontEnum ),
      JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"Array\""), jseDontEnum ),
      JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_Array_builtin, 0, 0, jseDontEnum,  jseFunc_Secure ),
#     if defined(JSE_ARRAY_TOSTRING)
         JSE_PROTOMETH( TOSTRING_PROPERTY, Ecma_Array_join, 0, 0, jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_TOSOURCE)
         JSE_PROTOMETH( TOSOURCE_PROPERTY, Ecma_Array_toSource, 0, 0, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_JOIN)
         JSE_PROTOMETH( UNISTR("join"), Ecma_Array_join,0,1, jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_REVERSE)
         JSE_PROTOMETH( UNISTR("reverse"), Ecma_Array_reverse,0,0, jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_SORT)
         JSE_PROTOMETH( UNISTR("sort"), Ecma_Array_sort,0,1, jseDontEnum,  jseFunc_Secure ),
#     endif
      /*JSE_PROTOMETH( UNISTR("put"), Ecma_Array_put,2,2, jseDontEnum,  jseFunc_Secure ),*/
#     if defined(JSE_ARRAY_CONCAT)
         JSE_PROTOMETH( UNISTR("concat"), Ecma_Array_concat, 0, -1, jseDontEnum, jseFunc_Secure ),
         JSE_VARSTRING( UNISTR("prototype.concat.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete ),
#     endif
#     if defined(JSE_ARRAY_POP)
         JSE_PROTOMETH( UNISTR("pop"), Ecma_Array_pop, 0, 0, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_PUSH)
         JSE_PROTOMETH( UNISTR("push"), Ecma_Array_push, 0, -1, jseDontEnum, jseFunc_Secure ),
         JSE_VARSTRING( UNISTR("prototype.push.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#     endif
#     if defined(JSE_ARRAY_SHIFT)
         JSE_PROTOMETH( UNISTR("shift"), Ecma_Array_shift, 0, 0, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_SLICE)
         JSE_PROTOMETH( UNISTR("slice"), Ecma_Array_slice, 1, 2, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_ARRAY_SPLICE)
         JSE_PROTOMETH( UNISTR("splice"), Ecma_Array_splice, 2, -1, jseDontEnum, jseFunc_Secure ),
         JSE_VARSTRING( UNISTR("prototype.splice.length"), UNISTR("2"), jseDontEnum|jseReadOnly|jseDontDelete),
#     endif
#     if defined(JSE_ARRAY_UNSHIFT)
         JSE_PROTOMETH( UNISTR("unshift"), Ecma_Array_unshift, 0, -1, jseDontEnum, jseFunc_Secure ),
         JSE_VARSTRING( UNISTR("prototype.unshift.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#     endif
      JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
#  endif /* #if defined(JSE_ARRAY_ANY) */


   /* ---------------------------------------------------------------------- */
   /* The 'Boolean' object */
   /* ---------------------------------------------------------------------- */
#  ifdef JSE_BOOLEAN_ANY
      JSE_LIBOBJECT( BOOLEAN_PROPERTY,     Ecma_Boolean_call,    0,      1,      jseDontEnum,  jseFunc_Secure ),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,  Ecma_Boolean_construct,0,1, jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"Boolean\""), jseDontEnum ),
      JSE_VARSTRING( UNISTR("prototype._value"), UNISTR("false"), jseDontEnum ),
      JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_Boolean_builtin,0,0, jseDontEnum,  jseFunc_Secure ),
      JSE_PROTOMETH( VALUEOF_PROPERTY, Ecma_Boolean_valueOf,0,0, jseDontEnum,  jseFunc_Secure ),
#     if defined(JSE_BOOLEAN_TOSTRING)
         JSE_PROTOMETH( TOSTRING_PROPERTY, Ecma_Boolean_toString,0,0, jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_BOOLEAN_TOSOURCE)
         JSE_PROTOMETH( TOSOURCE_PROPERTY, Ecma_Boolean_toSource, 0, 0, jseDontEnum, jseFunc_Secure ),
#     endif
      JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
#  endif

   /* ---------------------------------------------------------------------- */
   /* The 'Number' object. */
   /* ---------------------------------------------------------------------- */
#  ifdef JSE_NUMBER_ANY
      JSE_LIBOBJECT( NUMBER_PROPERTY,     Ecma_Number_call,    0,      1,      jseDontEnum,  jseFunc_Secure ),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,  Ecma_Number_construct,0,1, jseDontEnum,  jseFunc_Secure ),
      JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_Number_builtin,0,0, jseDontEnum,  jseFunc_Secure ),
      JSE_PROTOMETH( VALUEOF_PROPERTY, Ecma_Number_valueOf,0,0, jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"Number\""), jseDontEnum ),
      JSE_VARSTRING( UNISTR("prototype._value"), UNISTR("0"), jseDontEnum ),

#     if (0!=JSE_FLOATING_POINT)
#        if defined(JSE_NUMBER_MAX_VALUE)
            JSE_VARNUMBER( UNISTR("MAX_VALUE"), &jse_DBL_MAX, jseDontEnum | jseDontDelete | jseReadOnly ),
#        endif
#        if defined(JSE_NUMBER_MIN_VALUE)
            JSE_VARNUMBER( UNISTR("MIN_VALUE"), &jse_DBL_MIN, jseDontEnum | jseDontDelete | jseReadOnly ),
#        endif
#     else
#        if defined(JSE_NUMBER_MAX_VALUE)
            JSE_VARNUMBER( UNISTR("MAX_VALUE"), &seMax, jseDontEnum | jseDontDelete | jseReadOnly ),
#        endif
#        if defined(JSE_NUMBER_MIN_VALUE)
            JSE_VARNUMBER( UNISTR("MIN_VALUE"), &seMin, jseDontEnum | jseDontDelete | jseReadOnly ),
#        endif
#     endif
#     if defined(JSE_NUMBER_NAN)
         JSE_VARNUMBER( UNISTR("NaN"), &seNaN, jseDontEnum | jseDontDelete | jseReadOnly ),
#     endif
#     if defined(JSE_NUMBER_NEGATIVE_INFINITY)
         JSE_VARNUMBER( UNISTR("NEGATIVE_INFINITY"), &seNegInfinity, jseDontEnum | jseDontDelete | jseReadOnly ),
#     endif
#     if defined(JSE_NUMBER_POSITIVE_INFINITY)
         JSE_VARNUMBER( UNISTR("POSITIVE_INFINITY"), &seInfinity, jseDontEnum | jseDontDelete | jseReadOnly ),
#     endif
#     if defined(JSE_NUMBER_TOSTRING)
         JSE_PROTOMETH( TOSTRING_PROPERTY, Ecma_Number_toString,0,0, jseDontEnum,  jseFunc_Secure ),
#     endif
#     if defined(JSE_NUMBER_TOLOCALESTRING)
         JSE_PROTOMETH( UNISTR("toLocaleString"), Ecma_Number_toString,0,0, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_NUMBER_TOSOURCE)
         JSE_PROTOMETH( TOSOURCE_PROPERTY, Ecma_Number_toSource, 0,0, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_NUMBER_TOFIXED)
         JSE_ARGVPROTOMETH( UNISTR("toFixed"), Ecma_Number_toFixed, 0,1, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_NUMBER_TOEXPONENTIAL)
         JSE_ARGVPROTOMETH( UNISTR("toExponential"), Ecma_Number_toExponential, 0,1, jseDontEnum, jseFunc_Secure ),
#     endif
#     if defined(JSE_NUMBER_TOPRECISION)
         JSE_ARGVPROTOMETH( UNISTR("toPrecision"), Ecma_Number_toPrecision, 0,1, jseDontEnum, jseFunc_Secure ),
#     endif
      JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
#  endif

   /*------------------------*/
   /* Exception objects */
   /*------------------------*/
#  if defined(JSE_EXCEPTION_ANY)
      JSE_LIBOBJECT( EXCEPTION_PROPERTY,    Ecma_Exception, 0, 1, jseDontEnum,  jseFunc_Secure ),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,Ecma_Exception_construct, 0, 1, jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"") EXCEPTION_EXCEPTION UNISTR("\""), jseDontEnum | jseReadOnly ),
      JSE_VARSTRING( UNISTR("prototype.name"), UNISTR("\"") EXCEPTION_EXCEPTION UNISTR("\""), jseDefaultAttr ),
      JSE_VARSTRING( UNISTR("prototype.message"),  UNISTR("\"\""),  jseDefaultAttr),
      JSE_PROTOMETH( TOSTRING_PROPERTY,          Ecma_Exception_toString, 0, 0, jseDontEnum, jseFunc_Secure),
      JSE_LIBOBJECT( SYNTAX_EXCEPTION,      Ecma_SyntaxError,      0, 1, jseDontEnum, jseFunc_Secure ),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_SyntaxError_construct,      0, 1, jseDontEnum, jseFunc_Secure ),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( REFERENCE_EXCEPTION,   Ecma_ReferenceError,   0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_ReferenceError_construct,  0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( CONVERSION_EXCEPTION,  Ecma_ConversionError,  0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_ConversionError_construct,  0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( ARRAYLENGTH_EXCEPTION, Ecma_ArrayLengthError, 0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_ArrayLengthError_construct, 0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( TYPE_EXCEPTION,        Ecma_TypeError,        0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_TypeError_construct, 0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( EVAL_EXCEPTION,        Ecma_EvalError,        0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_EvalError_construct, 0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
      JSE_LIBOBJECT( URI_EXCEPTION,         Ecma_URIError,         0, 1, jseDontEnum, jseFunc_Secure),
      JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_URIError_construct, 0, 1, jseDontEnum, jseFunc_Secure),
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
#     if defined(JSE_REGEXP_OBJECT)
         JSE_LIBOBJECT( REGEXP_EXCEPTION,      Ecma_RegExpError,         0, 1, jseDontEnum, jseFunc_Secure),
         JSE_LIBMETHOD( CONSTRUCT_PROPERTY,    Ecma_RegExpError_construct, 0, 1, jseDontEnum, jseFunc_Secure),
#     endif
      JSE_VARASSIGN( PROTOPROTO_PROPERTIES, EXCEPTION_EXCEPTION UNISTR(".prototype"), jseDontEnum),
#  endif
   JSE_FUNC_DESC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

static jseLibInitFunc(DeclareUndefined)
{
   jseVariable undefined;

   UNUSED_PARAMETER(PreviousInstanceData);

   /* ECMA2.0: Add 'undefined' as a global constant */
   undefined = jseMemberEx(jsecontext,NULL,UNISTR("undefined"),jseTypeUndefined,jseCreateVar);
   jseSetAttributes(jsecontext,undefined,jseDontEnum|jseDontDelete);
   jseDestroyVariable(jsecontext,undefined);

   return NULL;
}

   void NEAR_CALL
InitializeLibrary_Ecma_Objects(jseContext jsecontext)
{
#   ifdef JSE_NUMBER_ANY
#     if defined(JSE_NUMBER_NEGATIVE_INFINITY)
         seNegInfinity = jseNegInfinity;
#     endif
#     if (0==JSE_FLOATING_POINT)
#        if defined(JSE_NUMBER_MAX_VALUE)
            seMax = MAX_SLONG;
#        endif
#        if defined(JSE_NUMBER_MIN_VALUE)
            seMin = 0;
#        endif
#     endif
#   endif

   jseAddLibrary(jsecontext,NULL,ObjectLibFunctionList,NULL,DeclareUndefined,NULL);
}
#endif /* ECMA objects */


#if defined(JSE_ARRAY_ANY)     \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_BUFFER_ANY)    \
 || defined(JSE_DATE_ANY)      \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_STRING_ANY)
/* Creates a blank object of one of the default types. It doesn't
 * check the types, so you can add new ones. For this to work as
 * expected, you need to have already set up the type in the global
 * context. If you don't, this new object will have prototype that
 * doesn't implement anything.
 */
   jseVariable _export
CreateNewObject(jseContext jsecontext,const jsecharptr objname)
{
   jseVariable var = jseCreateVariable(jsecontext,jseTypeObject);

   if ( 0 != strcmp_jsechar(objname,OBJECT_PROPERTY) )
   {
      jseInitializeObject(jsecontext,var,objname);

#     if defined(JSE_ARRAY_ANY)
         /* All arrays must have the special put property. I don't think it is a good
          * idea for these properties to be inherited, as they are supposed to be internal
          * properties of the object.
          */
         if( 0 == strcmp_jsechar(objname,ARRAY_PROPERTY) )
         {
            jseVariable t2;
            /* set up its length */
            t2 = MyjseMember(jsecontext,var,LENGTH_PROPERTY,jseTypeNumber);
            jsePutLong(jsecontext,t2,0);
            jseSetAttributes(jsecontext,t2,jseDontEnum);

            jseSetAttributes(jsecontext,var,jseEcmaArray);
         }
#     endif
   }
   return var;
}

/* NOTE: For most string routines, it is an error if the 'this' is not
 * actually a string. This routine checks for it and bombs out if it
 * fails.
 */
#if defined(JSE_DATE_ANY)    \
 || defined(JSE_BOOLEAN_ANY) \
 || defined(JSE_STRING_ANY)   \
 || defined(JSE_NUMBER_ANY)
   jsebool
ensure_type(jseContext jsecontext,jseVariable what,const jsecharptr type)
{
   jsebool success = TRUE;

   if( jseGetType(jsecontext,what)!=jseTypeObject )
      success = FALSE;
   else
   {
      jseVariable v = jseGetMember(jsecontext,what,CLASS_PROPERTY);

      if( jseGetType(jsecontext,v) != jseTypeString )
         success = FALSE;
      else
      {
         jsecharptr str = (jsecharptr )jseGetString(jsecontext,v,NULL);

         if( v==NULL || jseGetType(jsecontext,v)!=jseTypeString ||
             strcmp_jsechar(type,str)!=0 )
            success = FALSE;
      }
   }

   if( !success )
   {
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibTHIS_NOT_CORRECT_OBJECT),type);
   }

   return success;
}
#endif

#if defined(JSE_ARRAY_ANY)      \
 || defined(JSE_DATE_ANY)
jseVariable _export MyjseMember(jseContext jsecontext,jseVariable obj,const jsecharptr name,jseDataType t)
{
   jseVariable var = jseMember(jsecontext,obj,name,t);
   jseSetAttributes(jsecontext,var,(jseVarAttributes)
                    (jseGetAttributes(jsecontext,var)&~jseReadOnly)); /* make sure not readonly */
   if( t!=jseGetType(jsecontext,var)) jseConvert(jsecontext,var,t);
   return var;
}
#endif

#endif /* ECMA objects */

/* This is the 'builtin' string construct. */

#pragma codeseg SEOBJECT4_TEXT

#if defined(JSE_STRING_ANY)
#if !defined(JSE_STRING_OBJECT)
#  error must #define JSE_STRING_OBJECT 1 or #define JSE_STRING_ALL to use JSE_STRING_ANY
#endif
static jseLibFunc(Ecma_String_builtin)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,STRING_PROPERTY),jseRetTempVar);
}

/* String() call */
static jseLibFunc(Ecma_String_call)
{
   jseVariable ret;

   if( jseFuncVarCount(jsecontext)==1 )
   {
      ret = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),jseToString);
   }
   else
   {
      ret = jseCreateVariable(jsecontext,jseTypeString);
   }

   if( ret != NULL )
      jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}

/* new String() - String.construct */
static jseLibFunc(Ecma_String_construct)
{
   jseVariable value, tmp, thisvar;

   if ( 0 < jseFuncVarCount(jsecontext ) )
   {
      JSE_FUNC_VAR_NEED(value,jsecontext,0,
                        JSE_VN_LOCKREAD|JSE_VN_CREATEVAR
                       |JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   }
   else
   {
      value = jseCreateVariable(jsecontext,jseTypeString);
   }
   thisvar = jseGetCurrentThisVariable(jsecontext);
   jseAssign(jsecontext,tmp = jseMemberEx(jsecontext,thisvar,VALUE_PROPERTY,jseTypeString,jseLockWrite),value);
   jseSetAttributes(jsecontext,tmp,jseDontEnum | jseDontDelete | jseReadOnly);
   jsePutLong(jsecontext,tmp = jseMemberEx(jsecontext,thisvar,LENGTH_PROPERTY,jseTypeNumber,jseLockWrite),
              (slong)jseGetArrayLength(jsecontext,value,NULL));
   jseSetAttributes(jsecontext,tmp,jseDontEnum | jseDontDelete | jseReadOnly);
   jseDestroyVariable(jsecontext,value);

   assert( jseApiOK );
}

/* String.toString(), String.valueOf() */
static jseLibFunc(Ecma_String_toString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);

   if( !ensure_type(jsecontext,thisvar,STRING_PROPERTY) )
      return;

   jseReturnVar(jsecontext,
                jseCreateSiblingVariable(jsecontext,
                   jseMember(jsecontext,thisvar,VALUE_PROPERTY,jseTypeString),0),
                jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_ANY) */

#if defined(JSE_STRING_FROMCHARCODE)
/* String.fromCharCode() */
static jseArgvLibFunc(Ecma_String_fromCharCode)
{
   jseVariable ret = jseCreateVariable(jsecontext,jseTypeString);

   jsecharptr string = jseMustMalloc(jsecharptrdatum,(jseFuncVarCount(jsecontext)+1)*sizeof(jsechar));
   JSE_POINTER_UINDEX i;
   jsecharptr current = string;

   for( i=0;i<argc;i++, JSECHARPTR_INC(current) )
   {
      jseVariable t = jseCreateConvertedVariable(jsecontext,argv[i],jseToUint16);
      if( t == NULL )
      {
         jseMustFree(string);
         jseDestroyVariable(jsecontext,ret);
         return NULL;
      }
      JSECHARPTR_PUTC(current,(jsechar)jseGetLong(jsecontext,t));
      jseDestroyVariable(jsecontext,t);
   }
   JSECHARPTR_PUTC(current,UNICHR('\0'));
   jsePutStringLength(jsecontext,ret,string,i);
   jseMustFree(string);

   assert( jseApiOK );

   return ret;
}
#endif /* #if defined(JSE_STRING_FROMCHARCODE) */


#if defined(JSE_STRING_CHARAT)
/* String.charAt() */
static jseLibFunc(Ecma_String_charAt)
{
   jseVariable string;
   jseVariable pos = NULL;
   slong temppos;
   ulong thepos;
   jseVariable ret;

   string = jseCreateConvertedVariable(jsecontext,
                                       jseGetCurrentThisVariable(jsecontext),
                                       jseToString);
   if ( string==NULL )
      return;

   if ( !GetSlongFromVar(jsecontext,jseFuncVar(jsecontext,0),&temppos) )
   {
      jseDestroyVariable(jsecontext,string);
      return;
   }
   thepos = (ulong)temppos;

   ret = jseCreateVariable(jsecontext,jseTypeString);

   if( jseGetArrayLength(jsecontext,string,NULL)>thepos )
   {
      jsePutStringLength(jsecontext,ret,JSECHARPTR_OFFSET(jseGetString(jsecontext,string,NULL),thepos),1);
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   jseDestroyVariable(jsecontext,string);
   jseDestroyVariable(jsecontext,pos);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_CHARAT) */

#if defined(JSE_STRING_CHARCODEAT)
/* String.charCodeAt() */
static jseLibFunc(Ecma_String_charCodeAt)
{
   jseVariable string;
   jseVariable pos = NULL;
   slong temppos;
   ulong thepos;
   jseVariable ret;

   string = jseCreateConvertedVariable(jsecontext,
                                       jseGetCurrentThisVariable(jsecontext),
                                       jseToString);
   if ( string==NULL )
      return;

   if ( !GetSlongFromVar(jsecontext,jseFuncVar(jsecontext,0),&temppos) )
   {
      jseDestroyVariable(jsecontext,string);
      return;
   }
   thepos = (ulong)temppos;

   ret = jseCreateVariable(jsecontext,jseTypeNumber);

   if( jseGetArrayLength(jsecontext,string,NULL)>thepos )
   {
      jsePutLong(jsecontext,ret,(ujsechar)(JSECHARPTR_GETC(JSECHARPTR_OFFSET(jseGetString(jsecontext,string,NULL),thepos))));
   }
   else
   {
      jsePutNumber(jsecontext,ret,jseNaN);
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   jseDestroyVariable(jsecontext,string);
   jseDestroyVariable(jsecontext,pos);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_CHARCODEAT) */

#if defined(JSE_STRING_INDEXOF)
/* String.indexOf() */
static jseLibFunc(Ecma_String_indexOf)
{
   jseVariable string = jseCreateConvertedVariable(jsecontext,
                                                   jseGetCurrentThisVariable(jsecontext),
                                                   jseToString);
   jseVariable searchstring = jseCreateConvertedVariable(jsecontext,
                                                   jseFuncVar(jsecontext,0),
                                                   jseToString);
   JSE_POINTER_SINDEX start, found;
   JSE_POINTER_UINDEX stringLen, searchStringLen;
   jseVariable ret;
   jsecharhugeptr st;
   jsecharhugeptr sub;
   jsechar firstChar;

   if( string == NULL || searchstring == NULL )
   {
      if( string != NULL )
         jseDestroyVariable(jsecontext,string);
      if( searchstring != NULL )
         jseDestroyVariable(jsecontext,searchstring);
      return;
   }

   if( jseFuncVarCount(jsecontext) < 2 )
   {
      start = 0;
   }
   else
   {
      jseVariable pos = jseFuncVarNeed(jsecontext,1,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
      jsenumber startf;

      if( pos == NULL)
      {
         jseDestroyVariable(jsecontext,string);
         jseDestroyVariable(jsecontext,searchstring);
         return;
      }
      startf = jseGetNumber(jsecontext,pos);
      start = jseIsFinite(startf) ? (JSE_POINTER_SINDEX)JSE_FP_CAST_TO_SLONG(startf) : 0 ;
      if ( start < 0 )
         start = 0;
   }

   ret = jseCreateVariable(jsecontext,jseTypeNumber);

   st =  (jsecharhugeptr)jseGetString(jsecontext,string,&stringLen);
   sub = (jsecharhugeptr)jseGetString(jsecontext,searchstring,&searchStringLen);

   found = -1;

   if ( 0 < searchStringLen  &&  searchStringLen <= stringLen )
   {
      if ( (JSE_POINTER_UINT)start <= (stringLen-=searchStringLen) )
      {
         JSE_POINTER_UINDEX SearchSize = BYTECOUNT_FROM_STRLEN(sub,searchStringLen);
         firstChar = JSECHARPTR_GETC(sub);
         st = JSECHARPTR_OFFSET(st,start);
         while( (JSE_POINTER_UINT)start <= stringLen )
         {
            if ( JSECHARPTR_GETC(st) == firstChar
              && !HugeMemCmp(st,sub,SearchSize) )
            {
               found = start;
               break;
            }
            start++;
            JSECHARPTR_INC(st);
         }
      }
   }

   jsePutLong(jsecontext,ret,found);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   jseDestroyVariable(jsecontext,string);
   jseDestroyVariable(jsecontext,searchstring);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_INDEXOF) */

#if defined(JSE_STRING_LASTINDEXOF)
/* String.lastIndexOf() */
static jseLibFunc(Ecma_String_lastIndexOf)
{
   jseVariable string = jseCreateConvertedVariable(jsecontext,
                                                   jseGetCurrentThisVariable(jsecontext),
                                                   jseToString);
   jseVariable searchstring = jseCreateConvertedVariable(jsecontext,
                                                   jseFuncVar(jsecontext,0),
                                                   jseToString);
   JSE_POINTER_SINDEX current, start, lastindex;
   JSE_POINTER_UINDEX stringLen, searchStringLen;
   jseVariable ret;
   jsecharhugeptr st, _HUGE_ *sub;
   jsechar firstChar;

   if( string == NULL || searchstring == NULL )
   {
      if( string != NULL )
         jseDestroyVariable(jsecontext,string);
      if( searchstring != NULL )
         jseDestroyVariable(jsecontext,searchstring);
      return;
   }

   if( jseFuncVarCount(jsecontext) < 2 )
   {
      start = JSE_PTR_MAX_SINDEX;
   }
   else
   {
      jseVariable pos = jseFuncVarNeed(jsecontext,1,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
      jsenumber startf;

      if( pos == NULL )
      {
         jseDestroyVariable(jsecontext,string);
         jseDestroyVariable(jsecontext,searchstring);
         return;
      }
      startf = jseGetNumber(jsecontext,pos);
      start = jseIsFinite(startf) ? (JSE_POINTER_SINDEX)JSE_FP_CAST_TO_SLONG(startf) : JSE_PTR_MAX_SINDEX ;
      if ( start < 0 )
         start = -1;
   }

   ret = jseCreateVariable(jsecontext,jseTypeNumber);
   lastindex = -1;

   if ( 0 <= start )
   {
      JSE_POINTER_UINDEX SearchSize;

      st =  (jsecharhugeptr)jseGetString(jsecontext,string,&stringLen);
      sub = (jsecharhugeptr)jseGetString(jsecontext,searchstring,&searchStringLen);

      SearchSize = BYTECOUNT_FROM_STRLEN(sub,searchStringLen);

      if ( 0 < searchStringLen  &&  searchStringLen <= stringLen )
      {
         firstChar = JSECHARPTR_GETC(sub);
         current = 0;

         if( (JSE_POINTER_UINDEX)start > stringLen )
            start = (JSE_POINTER_SINDEX)stringLen;

         while( current <= start &&
                current + searchStringLen <= stringLen )
         {
            if ( JSECHARPTR_GETC(st) == firstChar
              && !HugeMemCmp(st,sub,SearchSize) )
            {
               lastindex = current;
            }
            JSECHARPTR_INC(st);
            current++;
         }
      }
   }

   jsePutLong(jsecontext,ret,lastindex);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   jseDestroyVariable(jsecontext,string);
   jseDestroyVariable(jsecontext,searchstring);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_LASTINDEXOF) */

#if defined(JSE_STRING_SPLIT)
#  if !defined(JSE_ARRAY_OBJECT)
#     error must define JSE_ARRAY_OBJECT to use JSE_STRING_SPLIT
#  endif
   static jseVariable
SplitMatch(jseContext jsecontext,jseVariable R,
           const jsecharptr sep_str,JSE_POINTER_UINDEX sep_len,
           jseVariable S,JSE_POINTER_UINDEX q)
   /* return match object, or NULL if no match. Returned value
    * needs to be destroyed.
    */
{
   jseVariable ret;

   if( R!=NULL )
   {
#     if !defined(JSE_REGEXP_OBJECT)
         jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibNO_REGEXP));
         ret = NULL;
#     else
         /* RegExp */
         jseStack stack = jseCreateStack(jsecontext);
         /* save old value */
         jseVariable reg_func;
         jseVariable tmp;
         JSE_POINTER_UINDEX len;
         const jsecharptr S_data = (const jsecharptr)jseGetString(jsecontext,S,&len);

         tmp = jseCreateVariable(jsecontext,jseTypeString);
         jsePutStringLength(jsecontext,tmp,JSECHARPTR_OFFSET(S_data,q),len-q);
         jsePush(jsecontext,stack,tmp,True);

         reg_func = jseGetMember(jsecontext,R,exec_MEMBER);
         if( reg_func==NULL )
         {
            ret = NULL;
         }
         else if( !jseCallFunctionEx(jsecontext,reg_func,
                                stack,&ret,R,JSE_FUNC_TRAP_ERRORS) )
         {
            /* an error, need to propogate it along. Unfortunately,
             * the Argv function still has to call these functions
             * if it needs to return an error. We can't just return
             * the error object, because although the return would
             * be correct the error flag is not set. If we set the
             * error flag, later returns are ignored, so we need
             * to set up a return, set the error flag which
             * 'stamps in' that return as an error. We then return
             * the result, even though it will be ignored, for
             * consistent code between normal and error paths.
             */
            jseReturnVar(jsecontext,ret,jseRetCopyToTempVar);
            jseLibSetErrorFlag(jsecontext);
            ret = NULL;
         }
         else
         {
            /* [[Match]] is never described in the document. I'm guessing it
             * means match the given string at the given index exactly,
             * that's what they do for a regular string
             */
            ret = ( jseGetType(jsecontext,ret)==jseTypeNull )
                ? NULL : jseCreateSiblingVariable(jsecontext,ret,0) ;
         }
         jseDestroyStack(jsecontext,stack);
#     endif
   }
   else
   {
      jseVariable mem0;

      /* Normal string */
      if( strncmp_jsechar(sep_str,
                          JSECHARPTR_OFFSET(jseGetStringDatum(jsecontext,S,NULL,NULL),q),
                          sep_len)!=0 )
      {
         ret = NULL;
      }
      else
      {
         /* to make it sync with the regexp one, we have the 0
          * element set to the matched string (and its length
          * can be used to determine 'endIndex') and no capture
          * array (i.e. no elements 1, 2, etc.
          */
         ret = jseCreateVariable(jsecontext,jseTypeObject);

         jseConstructObject(jsecontext, ret, ARRAY_PROPERTY, NULL);
         mem0 = jseIndexMember(jsecontext,ret,0,jseTypeString);
         jsePutStringLength(jsecontext,mem0,sep_str,sep_len);
      }
   }
   return ret;
}

/* String.split() */
static jseArgvLibFunc(Ecma_String_split)
{
   jseVariable ret;
   uword32 limit = 0xffffffff;  /* 2^32-1, this exact number specified in the doc */
   /* 'S' is the name in the doc, so why not? */
   jseVariable S = jseCreateConvertedVariable(jsecontext,
                                              jseGetCurrentThisVariable(jsecontext),
                                              jseToString);
   JSE_POINTER_UINDEX s;
   const jsecharptr str;
   jsebool done = False;


   if( S==NULL ) return NULL;
   str = (const jsecharptr)jseGetString(jsecontext,S,&s);


   if( argc==2 )
   {
      limit = jseGetUint32Datum(jsecontext,argv[1],NULL);
   }

   ret = CreateNewObject(jsecontext,ARRAY_PROPERTY);

   if( jseFuncVarCount(jsecontext)==0 )
   {
      /* step 33 */
      jseAssign(jsecontext,jseIndexMember(jsecontext,ret,0,jseTypeString),S);
   }
   else if( limit!=0 )  /* if limit is 0, just return the new array. */
   {
      JSE_POINTER_UINDEX p = 0;
      JSE_POINTER_UINDEX sep_len = 0;
      const jsecharptr sep_str = NULL;
      jseVariable R;
      jseVariable tmp;

#     if defined(JSE_REGEXP_ANY)
      if( jseGetType(jsecontext,argv[0])==jseTypeObject
       && (tmp = jseGetMember(jsecontext,argv[0],CLASS_PROPERTY))!=NULL
       && strcmp_jsechar(jseGetStringDatum(jsecontext,tmp,NULL,NULL),REGEXP_PROPERTY)==0 )
      {
         R = argv[0];
         /* RegExp */
      }
      else
#     endif
      {
         /* A string */
         sep_str = jseGetStringDatum(jsecontext,argv[0],NULL,&sep_len);
         R = NULL;
      }

      if( s==0 )
      {
         /* step 31 */
         jseVariable z = SplitMatch(jsecontext,R,sep_str,sep_len,S,0);

         if( z==NULL )
         {
            tmp = jseIndexMember(jsecontext,ret,
                                 (JSE_POINTER_SINDEX)jseGetUint32Datum(jsecontext,ret,LENGTH_PROPERTY),
                                 jseTypeUndefined);
            jseAssign(jsecontext,tmp,S);
         }
         else
         {
            jseDestroyVariable(jsecontext,z);
         }
      }
      else
      {
         JSE_POINTER_UINDEX q;


      step_10:
         /* step 10 */
         q = p;

         /* step 11 */
         while( q!=s )
         {
            jseVariable z = SplitMatch(jsecontext,R,sep_str,sep_len,S,q);
            if( z!=NULL )
            {
               /* step 14 */
               JSE_POINTER_UINDEX e = 0;
               jseVariable tmp2,tmp = jseGetIndexMember(jsecontext,z,0);
               if( tmp )
               {

                  (void)jseGetStringDatum(jsecontext,tmp,NULL,&e);
                  e += q;
               }
               else
               {
                  e = p; /* force it to exit, something unexpected happened */
               }

               if( e!=p )
               {
                  JSE_POINTER_UINDEX i;
                  JSE_POINTER_UINDEX len = (JSE_POINTER_UINDEX)jseGetUint32Datum(jsecontext,ret,LENGTH_PROPERTY);

                  tmp = jseIndexMember(jsecontext,ret,(JSE_POINTER_SINDEX)len,jseTypeString);
                  /* exclusive of the last character, so if 0...1, just put char 0 */
                  if( q>p )
                     jsePutStringLength(jsecontext,tmp,JSECHARPTR_OFFSET(str,p),(q-p));
                  if( len+1==limit )
                  {
                     done = True;
                     jseDestroyVariable(jsecontext,z);
                     break;
                  }
                  p = e;
                  i = 1;        /* add in the cap[] array */
                  while( (tmp2 = jseGetIndexMember(jsecontext,z,(JSE_POINTER_SINDEX)i))!=NULL )
                  {
                     len = (JSE_POINTER_UINDEX)jseGetUint32Datum(jsecontext,ret,LENGTH_PROPERTY);
                     tmp = jseIndexMember(jsecontext,ret,(JSE_POINTER_SINDEX)len,jseTypeUndefined);
                     jseAssign(jsecontext,tmp,tmp2);
                     if( len+1==limit )
                     {
                        done = True;
                        break;
                     }
                     i++;
                  }
                  if( done )
                  {
                     jseDestroyVariable(jsecontext,z);
                     break;
                  }

                  jseDestroyVariable(jsecontext,z);
                  /* goes back to step 10 */
                  goto step_10;
               }
               else
               {
                  jseDestroyVariable(jsecontext,z);
               }
            }

            /* step 26 */
            q++;
         }

         /* step 28 */
         if( !done )
         {
            tmp = jseIndexMember(jsecontext,
                                 ret,
                    (JSE_POINTER_SINDEX)jseGetUint32Datum(jsecontext,ret,LENGTH_PROPERTY),
                                 jseTypeString);
            /* exclusive of the last character, so if 0...1, just put char 0 */
            if( s>p )
               jsePutStringLength(jsecontext,tmp,JSECHARPTR_OFFSET(str,p),(s-p));
         }
      }
   }

   jseDestroyVariable(jsecontext,S);

   return ret;
}
#endif /* #if defined(JSE_STRING_SPLIT) */


#if defined(JSE_STRING_SUBSTR)
/* String.substr() -
 *    takes start,length.
 */
static jseArgvLibFunc(Ecma_String_substr)
{
   JSE_POINTER_UINDEX length;
   JSE_POINTER_SINDEX start_pos,len;
   const jsecharptr text;
   jseVariable result;

   /* get the text */
   text = jseGetStringDatum(jsecontext,JSE_THIS_VAR,NULL,&length);

   /* get the start pos */
   start_pos = (JSE_POINTER_SINDEX)(JSE_FP_CAST_TO_SLONG(jseGetIntegerDatum(jsecontext,argv[0],NULL)));
   /* negatives specify from end of string */
   if( start_pos<0 )
   {
      start_pos += length;
      if( start_pos<0 ) start_pos = 0;
   }

   /* get the length, or if none, use the rest of the string */
   assert( argc==1 || argc==2 );
   if( argc>1 )
      len = (JSE_POINTER_SINDEX)(JSE_FP_CAST_TO_SLONG(jseGetIntegerDatum(jsecontext,argv[1],NULL)));
   else
      len = length-start_pos;
   if( len+(JSE_POINTER_UINDEX)start_pos > length ) len = length-start_pos;

   /* create and put results in result variable */
   result = jseCreateVariable(jsecontext,jseTypeString);
   if( len>0 )
   {
      /* length can be <0 if end before start */
      jsePutStringLength(jsecontext,result,
                         JSECHARPTR_OFFSET(text,start_pos),
                         (JSE_POINTER_UINDEX)len);
   }

   assert( jseApiOK );
   return result;
}
#endif


#if defined(JSE_STRING_SUBSTRING)
/* String.substr() -
 *    takes start,length.
 */
static jseArgvLibFunc(Ecma_String_substring)
{
   JSE_POINTER_UINDEX length;
   JSE_POINTER_SINDEX fstart_pos, fend_pos, len;  /* len signed -- brianc 10/25/00 */
   JSE_POINTER_UINDEX start_pos,end_pos;
   const jsecharptr text;
   jseVariable result;

   /* get text */
   text = jseGetStringDatum(jsecontext,JSE_THIS_VAR,NULL,&length);
   /* get start */
   fstart_pos = (JSE_POINTER_SINDEX)(JSE_FP_CAST_TO_SLONG(jseGetIntegerDatum(jsecontext,argv[0],NULL)));

   /* get end or if not there, the rest of the string */
   assert( argc==1 || argc==2 );
   fend_pos = ( argc>1 )
            ? (JSE_POINTER_SINDEX)(JSE_FP_CAST_TO_SLONG(jseGetIntegerDatum(jsecontext,argv[1],NULL)))
            : length;

   /* replace arguments as specified in spec */
   start_pos = ( fstart_pos<0 /*|| jseIsNaN(fstart_pos)*/ )
             ? 0 : (JSE_POINTER_UINDEX)fstart_pos ;
   end_pos = ( fend_pos<0 /*|| jseIsNaN(fend_pos)*/ )
           ? 0 : (JSE_POINTER_UINDEX)fend_pos ;

   /* if end<start, swap them */
   if( start_pos>end_pos )
   {
      JSE_POINTER_UINDEX tmp = end_pos;
      end_pos = start_pos;
      start_pos = tmp;
   }
   /* note technically if either bigger than length of string,
    * replace with end of string. Calculating the length like
    * this does the exact same thing. If you can't figure out
    * that it does, take some remedial basic math courses.
    */
   len = end_pos - start_pos;
   if( (JSE_POINTER_UINDEX)start_pos+len > length ) len = length-start_pos;

   /* create and put results in result variable */
   result = jseCreateVariable(jsecontext,jseTypeString);
   if( len>0 )
   {
      /* length can be <0 if end before start */
      jsePutStringLength(jsecontext,result,
                         JSECHARPTR_OFFSET(text,start_pos),
                         (JSE_POINTER_UINDEX)len);
   }

   assert( jseApiOK );
   return result;
}
#endif /* #if defined(JSE_STRING_SUBSTRING) */


#if defined(JSE_STRING_TOLOWERCASE) || defined(JSE_STRING_TOLOCALELOWERCASE)
/* String.toLowerCase() */
static jseLibFunc(Ecma_String_toLowerCase)
{
   jseVariable ret = jseCreateConvertedVariable(jsecontext,
                                                jseGetCurrentThisVariable(jsecontext),
                                                jseToString);
   JSE_POINTER_UINDEX limit, i;
   jsecharhugeptr value = (jsecharptr)jseGetString(jsecontext,ret,&limit);
   jsecharptr copy = StrCpyMallocLen((jsecharptr)value,limit);
   jsecharptr current = copy;

   if( ret == NULL )
      return;

   for( i=0;i<limit;i++, JSECHARPTR_INC(current), JSECHARPTR_INC(value) )
   {
      JSECHARPTR_PUTC(current,(jsechar)tolower_jsechar(JSECHARPTR_GETC(value)));
   }
   jsePutStringLength(jsecontext,ret,copy,limit);
   jseReturnVar(jsecontext,ret,jseRetTempVar);

   jseMustFree(copy);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_TOLOWERCASE) || defined(JSE_STRING_TOLOCALELOWERCASE) */

#if defined(JSE_STRING_TOUPPERCASE) || defined(JSE_STRING_TOLOCALEUPPERCASE)
/* String.toUpperCase() */
static jseLibFunc(Ecma_String_toUpperCase)
{
   jseVariable ret = jseCreateConvertedVariable(jsecontext,
                                                jseGetCurrentThisVariable(jsecontext),
                                                jseToString);
   JSE_POINTER_UINDEX limit, i;
   jsecharhugeptr value;
   jsecharptr copy;
   jsecharptr current;

   if( ret == NULL )
      return;

   value = (jsecharptr)jseGetString(jsecontext,ret,&limit);
   copy = current = StrCpyMallocLen((jsecharptr)value,limit);

   for( i=0;i<limit;i++,JSECHARPTR_INC(value),JSECHARPTR_INC(current) )
   {
      JSECHARPTR_PUTC(current,(jsechar)toupper_jsechar(JSECHARPTR_GETC(value)));
   }
   jsePutStringLength(jsecontext,ret,copy,limit);

   jseMustFree(copy);

   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_TOUPPERCASE) || defined(JSE_STRING_TOLOCALEUPPERCASE) */

#if defined(JSE_STRING_CONCAT)
/* ECMA2.0: String.concat( string1, string2, ... )
 * When the concat method is called with zero or more arguments 'string1', 'string2', etc., it
 * returns a string consisting of the characters of this object( converted to a string) followed
 * by the characters of each of 'string1', 'string2', etc. (where each argument is converted to
 * a string).  The result is a string value, not a String Object.
 *
 * This function is written based on the ECMA draft for version 2 of the specification,
 * last edited June 4, 1999.  See section 15.5.4.6 for a description of the steps to
 * be taken.
 */
static jseLibFunc(Ecma_String_concat)
{
   jseVariable ret = jseCreateConvertedVariable(jsecontext,
                                                jseGetCurrentThisVariable(jsecontext),
                                                jseToString);
   uint i;
   jseVariable param;
   jsecharhugeptr str;
   jsecharhugeptr result, _HUGE_ * tempResult;
   JSE_POINTER_UINDEX length, strlength;

   if( ret == NULL )
      return;

   /* First we copy the current contents of this string into the result buffer */
   str = (jsecharhugeptr)jseGetString(jsecontext,ret,&length);
   result = HugeMalloc(BYTECOUNT_FROM_STRLEN(str,length)+1); /* Don't allocate 0 bytes */
   if ( NULL != result )
   {
      HugeMemCpy(result,str,BYTECOUNT_FROM_STRLEN(str,length));

      /* Now we loop through each argument */
      for( i = 0; i < jseFuncVarCount(jsecontext); i++ )
      {
         param = jseFuncVarNeed(jsecontext,i,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));

         if( param == NULL )
         {
            HugeFree(result);
            jseDestroyVariable(jsecontext,ret);
            return;
         }

         /* Get the string */
         str = (jsecharhugeptr)jseGetString(jsecontext,param,&strlength);
         /* Adjust our buffer to fit it */
         tempResult = HugeReMalloc(result,BYTECOUNT_FROM_STRLEN(result,length)+BYTECOUNT_FROM_STRLEN(str,strlength));
         if ( NULL == tempResult )
         {
            HugeFree(result);
            result = NULL;
            break;
         }
         result = tempResult;
         /* Now copy in the data, moving past the last point that was copied */
         HugeMemCpy( JSECHARPTR_OFFSET(result,length), str, BYTECOUNT_FROM_STRLEN(str,strlength) );
         /* Adjust the length to reflec tthe change */
         length += strlength;
      }

      /* Finally, put it back in the return variable */
      jsePutStringLength(jsecontext,ret,result,length);
   }

   if ( NULL == result )
   {
      jseLibErrorPrintf(jsecontext,InsufficientMemory);
   }
   else
   {
      /* And free our buffer */
      HugeFree(result);
   }

   /* And return it */
   jseReturnVar(jsecontext,ret,jseRetTempVar);

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_CONCAT) */

#if defined(JSE_STRING_SLICE)
/* ECMA2.0: String.slice( start [,end] )
 * When the slice method is called with arguments 'start' and, optionally, 'end'.  If 'end'
 * is not supplied, then the length of of the this variable is used.  It returns a substring
 * of the result of converting this object to a astring, starting from character position
 * 'start' and running to, but not including, characte rposition 'end' of the string.  If
 * 'start' is negative, it is treated as (sourceLength+start) where sourceLength is the
 * length of the string.  If 'end' is negative, it is treated as (sourceLength+end) where
 * sourceLength is the length of the string.  The result is a string value, not a String
 * object.
 *
 * This function is written based on the ECMA draft for version 2 of the specification,
 * last edited June 4, 1999.  See section 15.5.4.9 for a description of the steps to
 * be taken.
 */
static jseLibFunc(Ecma_String_slice)
{
   const jsecharhugeptr str;
   JSE_POINTER_UINDEX length;
   jseVariable jseStart, jseEnd = NULL;
   slong start, end;
   jseVariable ret;
   jseVariable thisString;

   JSE_FUNC_VAR_NEED(jseStart,jsecontext,0,JSE_VN_NUMBER);
   if( 1 < jseFuncVarCount(jsecontext) )
   {
      JSE_FUNC_VAR_NEED(jseEnd,jsecontext,1,JSE_VN_NUMBER);
   }

   thisString = jseCreateConvertedVariable(jsecontext,
                                           jseGetCurrentThisVariable(jsecontext),
                                           jseToString);
   if( NULL != thisString )
   {
      str = jseGetString(jsecontext,thisString,&length);

      start = jseGetLong(jsecontext,jseStart);

      /* Get 'end', or use length if it's not provided */
      if( 1 < jseFuncVarCount(jsecontext) )
      {
         end = jseGetLong(jsecontext,jseEnd);
      }
      else
      {
         end = (slong) length;
      }

      /* Check for negative values */
      if( start < 0 )
      {
         start = max( ((slong)length) + start, 0 );
      }
      else
      {
         start = (slong) min( (ulong)start, length );
      }

      if( end < 0 )
      {
         end = max( ((slong)length) + end, 0 );
      }
      else
      {
         end = (slong) min( (ulong)end, length );
      }

      /* Now if the user wants a negative length, then use 0 */
      ret = jseCreateVariable(jsecontext,jseTypeString);

      jsePutStringLength(jsecontext,ret,JSECHARPTR_OFFSET(str,start),
                         (JSE_POINTER_UINDEX)max(end-start,0));

      jseReturnVar(jsecontext,ret,jseRetTempVar);

      jseDestroyVariable(jsecontext,thisString);
   }

   assert( jseApiOK );
}
#endif /* #if defined(JSE_STRING_SLICE) */

#if defined(JSE_STRING_TOSOURCE)
/* String.toSource() */
static jseLibFunc(Ecma_String_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable stringVar;
   struct dynamicBuffer buffer, escapedBuffer;
   const jsecharptr string;
   JSE_POINTER_UINDEX length;

   stringVar = jseCreateConvertedVariable(jsecontext,thisVar,jseToString);

   dynamicBufferInit(&buffer);
   dynamicBufferAppend(&buffer,UNISTR("new String(\""));

   /* Escape string */
   string = (const jsecharptr)jseGetString(jsecontext,stringVar,&length);
   escapedBuffer = jseEscapeString(string,length);

   dynamicBufferAppend(&buffer,dynamicBufferGetString(&escapedBuffer));
   dynamicBufferTerm(&escapedBuffer);

   dynamicBufferAppend(&buffer,UNISTR("\")"));

   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                jseRetTempVar);

   dynamicBufferTerm(&buffer);
   jseDestroyVariable(jsecontext,stringVar);
}
#endif /* #if defined(JSE_STRING_TOSOURCE) */

#if defined(JSE_STRING_TOLOCALECOMPARE)
/* String.prototype.localeCompare() */
static jseArgvLibFunc(Ecma_String_localeCompare)
{
   const jsecharptr thisstring;
   const jsecharptr thatstring;

   thisstring = jseGetStringDatum(jsecontext,JSE_THIS_VAR,NULL,NULL);
   thatstring = ( 0 < argc )
              ? jseGetStringDatum(jsecontext,argv[0],NULL,NULL)
              : UNISTR("") ;
   return jseCreateLongVariable(jsecontext,strcmp_jsechar(thisstring,thatstring));
}
#endif /* #if defined(JSE_STRING_TOLOCALECOMPARE) */

#if defined(JSE_STRING_MATCH) || defined(JSE_STRING_SEARCH) || defined(JSE_STRING_REPLACE)
#  if !defined(JSE_REGEXP_OBJECT)
#     error must defined JSE_REGEXP_OBJECT to use JSE_STRING_MATCH or JSE_STRING_SEARCH or JSE_STRING_REPLACE
#  endif

#  if defined(JSE_STRING_MATCH)
#     define JSE_MATCH   0
#  endif
#  if defined(JSE_STRING_SEARCH)
#     define JSE_SEARCH  1
#  endif
#  if defined(JSE_STRING_REPLACE)
#     define JSE_REPLACE 2
#  endif

#if defined(JSE_STRING_REPLACE)
   static void NEAR_CALL
add_char(jsecharptr *str,JSE_POINTER_UINDEX *len,jsechar c)
{
   *str = jseMustReMalloc(void,*str,sizeof(jsechar)*((*len)+1));

   JSECHARPTR_PUTC(JSECHARPTR_OFFSET(*str,*len),c);
   (*len) += 1;
}

   static void NEAR_CALL
add_string(jsecharptr *str,JSE_POINTER_UINDEX *len,
           const jsecharptr text,JSE_POINTER_UINDEX add_len)
{
   *str = jseMustReMalloc(jsecharptrdatum,*str,sizeof(jsechar)*((*len)+add_len));

   memcpy(JSECHARPTR_OFFSET(*str,*len),text,BYTECOUNT_FROM_STRLEN(text,add_len));
   (*len) += add_len;
}


/* Replace the 'result' (a RegExp search result) portion of 'str' with
 * 'replacement', returning a new jseVariable in place of 'str'.
 * If replacement is NULL, replace with nothing. Adjust the
 * 'lastIndex' of the regexp based on the corresponding adjustment
 * to the string, i.e. so the replaced text is not scanned. I.e. if
 * the orig string is "abc" and lastIndex is 1, when we replace "a"
 * with "all", the lastIndex is correspondingly adjusted to 3.
 */
   static jseVariable NEAR_CALL
replace_string(jseContext jsecontext,jseVariable result,
               jseVariable regexp,jseVariable replacement)
{
   jsecharptr replace_text;
   const jsecharptr orig_text;
   const jsecharptr to_replace_text;
   jsecharptr new_text;
   JSE_POINTER_UINDEX replace_len,orig_len,to_replace_len,repl_loc;
   jseVariable ret;
   jseVariable orig;
   jseVariable last;
   jseVariable converted = NULL;
   JSE_POINTER_UINDEX tmp,tmp2;
   jsebool free_repl = False;
   jseStack stack;

   const jsecharptr lastParen_text;
   JSE_POINTER_UINDEX lastParen_len;
   JSE_POINTER_UINDEX lp_index;
   jsechar index_str[30];

   orig = jseGetMember(jsecontext,result,input_MEMBER);
   if( orig==NULL )
   {
      /* return a blank string on this unexpected error */
      return jseCreateVariable(jsecontext,jseTypeString);
   }

   orig_text = jseGetStringDatum(jsecontext,orig,NULL,&orig_len);
   repl_loc = (JSE_POINTER_UINDEX)jseGetUint32Datum(jsecontext,result,index_MEMBER);
   to_replace_text = jseGetStringDatum(jsecontext,result,UNISTR("0"),&to_replace_len);

   lp_index = (JSE_POINTER_UINDEX)jseGetUint32Datum(jsecontext,result,LENGTH_PROPERTY);
   assert( 0 < lp_index );
   long_to_string(lp_index-1,(jsecharptr)index_str);
   assert( bytestrsize_jsechar((jsecharptr)index_str) <= sizeof(index_str) );
   lastParen_text = jseGetStringDatum(jsecontext,result,(const jsecharptr)index_str,&lastParen_len);

   if( replacement==NULL )
   {
      /* NYI: why not the empty string? */
      replace_text = UNISTR("undefined");
      replace_len = 9;
   }
   else if( jseIsFunction(jsecontext,replacement) )
   {
      JSE_POINTER_SINDEX len,i;

      stack = jseCreateStack(jsecontext);

      /* the argument that matched followed by all the capture arguments,
       * which conveniently are 0 then 1...
       */
      len = (JSE_POINTER_SINDEX)jseGetUint32Datum(jsecontext,orig,LENGTH_PROPERTY);
      for( i=0;i<len;i++ )
      {
         jseVariable mem = jseGetIndexMember(jsecontext,result,i);

         if( mem!=NULL )
            jsePush(jsecontext,stack,mem,False);
         else
            jsePush(jsecontext,stack,jseCreateVariable(jsecontext,jseTypeUndefined),True);
      }
      /* offset in string of match */
      jsePush(jsecontext,stack,jseCreateLongVariable(jsecontext,(JSE_POINTER_SINDEX)repl_loc),True);
      /* the string */
      jsePush(jsecontext,stack,jseMember(jsecontext,result,input_MEMBER,jseTypeString),False);

      /* call the function */
      if( !jseCallFunctionEx(jsecontext,replacement,stack,&ret,regexp,JSE_FUNC_TRAP_ERRORS) )
      {
         /* see notes below for more explanation on this mysterious-looking
          * thing.
          */
         jseReturnVar(jsecontext,ret,jseRetCopyToTempVar);
         jseLibSetErrorFlag(jsecontext);
      }

      converted = jseCreateConvertedVariable(jsecontext,ret,jseToString);
      if( converted )
      {
         replace_text = (jsecharptr)jseGetStringDatum(jsecontext,converted,NULL,&replace_len);
      }
      else
      {
         replace_text = UNISTR("");
         replace_len = 0;
      }

      jseDestroyStack(jsecontext,stack);
   }
   else
   {
      const jsecharptr r_text;
      JSE_POINTER_UINDEX r_len,i;
      jsechar c;


      free_repl = True;
      replace_text = jseMustMalloc(jsecharptrdatum,sizeof(jsechar));
      replace_len = 0;

      r_text = jseGetStringDatum(jsecontext,replacement,NULL,&r_len);
      for( i=0;i<r_len;i++ )
      {
         if( (c = JSECHARPTR_GETC(JSECHARPTR_OFFSET(r_text,i)))=='$' )
         {
            c = JSECHARPTR_GETC(JSECHARPTR_OFFSET(r_text,i+1));
            switch( c )
            {
               default:
                  if( isdigit_jsechar(c) )
                  {
                     jsecharptrdatum buf[3];
                     const jsecharptr text;
                     JSE_POINTER_UINDEX len;

                     i++;
                     assert( sizeof_jsechar(c) == sizeof(jsecharptrdatum) );
                     buf[0] = (jsecharptrdatum)c;
                     c = JSECHARPTR_GETC(JSECHARPTR_OFFSET(r_text,i+1));
                     if( isdigit_jsechar(c) )
                     {
                        assert( sizeof_jsechar(c) == sizeof(jsecharptrdatum) );
                        buf[1] = (jsecharptrdatum)c;
                        assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
                        buf[2] = '\0';
                        i++;
                     }
                     else
                     {
                        assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
                        buf[1] = '\0';
                     }

                     text = jseGetStringDatum(jsecontext,result,buf,&len);
                     add_string(&replace_text,&replace_len,text,len);
                  }
                  else
                  {
                     /* leave as is */
                     add_char(&replace_text,&replace_len,'$');
                  }
                  break;
               case '$':
                  i++;
                  add_char(&replace_text,&replace_len,'$');
                  break;
               case '&':
                  i++;
                  add_string(&replace_text,&replace_len,
                             to_replace_text,to_replace_len);
                  break;
               case '`':
                  i++;
                  add_string(&replace_text,&replace_len,
                             orig_text,repl_loc);
                  break;
               case '\'':
                  i++;
                  add_string(&replace_text,&replace_len,
                             JSECHARPTR_OFFSET(orig_text,repl_loc+to_replace_len),
                             orig_len-(repl_loc+to_replace_len));
                  break;
               case '+':
                  i++;
                  add_string(&replace_text,&replace_len,
                             lastParen_text,lastParen_len);
                  break;
            }
         }
         else
         {
            add_char(&replace_text,&replace_len,c);
         }
      }
   }


   /* build a new string */
   ret = jseCreateVariable(jsecontext,jseTypeString);

   /* ensure enough space, a few extra doesn't matter, we are going to
    * free it right away.
    */
   new_text = jseMustMalloc(jsecharptrdatum,sizeof(jsechar)*(orig_len+replace_len));
   /* copy old stuff up to the replaced stuff */
   memcpy(new_text,orig_text,tmp = BYTECOUNT_FROM_STRLEN(orig_text,repl_loc));
   /* add the replacement text */
   memcpy(((ubyte *)new_text)+tmp,replace_text,
          tmp2 = BYTECOUNT_FROM_STRLEN(replace_text,replace_len));
   /* and the stuff left over */
   memcpy(((ubyte *)new_text)+tmp+tmp2,JSECHARPTR_OFFSET(orig_text,repl_loc+to_replace_len),
          BYTECOUNT_FROM_STRLEN(orig_text,orig_len)-
          BYTECOUNT_FROM_STRLEN(orig_text,repl_loc+to_replace_len));
   jsePutStringLength(jsecontext,ret,new_text,orig_len-to_replace_len+replace_len);
   jseMustFree(new_text);

   /* and update the index */
   last = jseMember(jsecontext,regexp,lastIndex_MEMBER,jseTypeNumber);
   if( jseGetType(jsecontext,last)==jseTypeNumber )
   {
      jsePutNumber(jsecontext,last,
                   JSE_FP_ADD(JSE_FP_SUB(jseGetNumber(jsecontext,last),\
                                         JSE_FP_CAST_FROM_ULONG(to_replace_len)),\
                              JSE_FP_CAST_FROM_ULONG(replace_len)));
   }

   if( free_repl ) jseMustFree(replace_text);
   if( converted ) jseDestroyVariable(jsecontext,converted);

   return ret;
}
#endif /* #if defined(JSE_STRING_REPLACE) */


/* Both String.search and String.match are very similar, so one
 * helper function does them.
 */
   static jseVariable NEAR_CALL
string_search_helper(jseContext jsecontext,uint argc,
                     jseVariable *argv,int mode)
{
   jsebool free_regexp = False;
   jseVariable regexp;
   jseVariable ret = NULL;
   jseVariable string;
   jsebool which;
   jseVariable reg_func;

   /* Mimic browser behavior */
   if ( argc==0 )
   {
#     if defined(JSE_STRING_MATCH)
         if( mode==JSE_MATCH )
         {
            return jseCreateVariable(jsecontext,jseTypeNull);
         }
#     endif
#     if defined(JSE_STRING_SEARCH)
         if( mode==JSE_SEARCH )
         {
            return jseCreateLongVariable(jsecontext,-1);
         }
#     endif
#     if defined(JSE_STRING_REPLACE)
         if( mode==JSE_REPLACE )
         {
            return jseCreateSiblingVariable(jsecontext,
                                            jseGetCurrentThisVariable(jsecontext),0);
         }
#     endif
   }

   string = jseCreateConvertedVariable(jsecontext,
                                       jseGetCurrentThisVariable(jsecontext),
                                       jseToString);
   /* The manual says it can fail, so make sure no weird crash
    * waiting to happen.
    */
   if( string==NULL ) return NULL;

   /* Paragraph1, if not a RegExp, pass it to RegExp constructor */

   if( jseGetType(jsecontext,argv[0])!=jseTypeObject
    || strcmp_jsechar(jseGetStringDatum(jsecontext,argv[0],CLASS_PROPERTY,NULL),REGEXP_PROPERTY)!=0 )
   {
      /* It is not already a regexp, call regexp constructor on it and
       * note it needs to be freed.
       */
      jseVariable reg_con = jseGetMember(jsecontext,NULL,REGEXP_PROPERTY);
      jseStack stack = jseCreateStack(jsecontext);
      jseVariable retvar;


      jsePush(jsecontext,stack,argv[0],False);
      if( reg_con==NULL ||
          !jseCallFunctionEx(jsecontext,reg_con,stack,&retvar,NULL,
                             JSE_FUNC_CONSTRUCT|JSE_FUNC_TRAP_ERRORS) )
      {
         /* some error occured */
         if( !jseQuitFlagged(jsecontext) )
         {
            /* if already reported an error, fine, else a generic
             * "can't find it" error.
             */
            jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibNO_REGEXP));
         }
         jseDestroyStack(jsecontext,stack);
         return NULL;
      }
      /* can't just use retvar, that goes away with the stack */
      regexp = jseCreateSiblingVariable(jsecontext,retvar,0);
      free_regexp = True;
      jseDestroyStack(jsecontext,stack);
   }
   else
   {
      regexp = argv[0];
   }

#  if defined(JSE_STRING_SEARCH)
      if ( mode == JSE_SEARCH )
      {
         which = False;
      }
      else
#  endif
      {
#        if defined(JSE_STRING_MATCH) || defined(JSE_STRING_REPLACE)
            which = jseGetBooleanDatum(jsecontext,regexp,global_MEMBER);
#        endif
      }

   /* We are going to be calling functions, that is complex
    * enough to warrent checking the quit flag before
    * doing so.
    */
   if( jseQuitFlagged(jsecontext) ) return NULL;

   if( (reg_func = jseGetMember(jsecontext,regexp,exec_MEMBER))==NULL )
   {
      /* Couldn't find RegExp.prototype.exec, obviously can't go on. */
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibNO_REGEXP));
   }
   /* do '!' case first so same order as spec, easier to
    * see how they match up.
    */
   else if( !which )
   {
      jseStack stack;
      jseVariable index UNUSED_INITIALIZER(0);
      jseVarAttributes attribs UNUSED_INITIALIZER(0);
      jsenumber old;

#     if defined(JSE_STRING_SEARCH)
         if( mode==JSE_SEARCH )
         {
            /* search ignores lastIndex and doesn't change it */
            index = jseMember(jsecontext,regexp,lastIndex_MEMBER,jseTypeNumber);
            assert( index!=NULL );    /* jseMember() always returns something */
            attribs = jseGetAttributes(jsecontext,index);
            old = jseGetNumberDatum(jsecontext,index,NULL);
            jseSetAttributes(jsecontext,index,0);
            jsePutNumber(jsecontext,index,jseZero);
            jseSetAttributes(jsecontext,index,attribs);
         }
#     endif

      /* Call it once and return the result. */
      stack = jseCreateStack(jsecontext);
      jsePush(jsecontext,stack,string,False);
      if( !jseCallFunctionEx(jsecontext,reg_func,stack,&ret,regexp,JSE_FUNC_TRAP_ERRORS) )
      {
         /* an error, need to propogate it along. Unfortunately,
          * the Argv function still has to call these functions
          * if it needs to return an error. We can't just return
          * the error object, because although the return would
          * be correct the error flag is not set. If we set the
          * error flag, later returns are ignored, so we need
          * to set up a return, set the error flag which
          * 'stamps in' that return as an error. We then return
          * the result, even though it will be ignored, for
          * consistent code between normal and error paths.
          */
         jseReturnVar(jsecontext,ret,jseRetCopyToTempVar);
         jseLibSetErrorFlag(jsecontext);
      }

#     if defined(JSE_STRING_REPLACE)
         /* could be no match, if replace, return the string from thisVar */
         if( jseGetType(jsecontext,ret)==jseTypeNull && mode==JSE_REPLACE )
         {
            jseDestroyStack(jsecontext,stack);
            if( free_regexp )
               jseDestroyVariable(jsecontext,regexp);
            assert( string!=NULL );
            ret = jseCreateSiblingVariable(jsecontext,string,0);
            jseDestroyVariable(jsecontext,string);

            return ret;
         }
#     endif

#     if defined(JSE_STRING_MATCH)
         if( mode==JSE_MATCH )
         {
            ret = jseCreateSiblingVariable(jsecontext,ret,0);
         }
#     endif
#     if defined(JSE_STRING_SEARCH)
         if( mode==JSE_SEARCH )
         {
            /* Actually should be NULL or an object, but if something
             * else (i.e. a buggie exec), pretend NULL.
             */
            if( jseGetType(jsecontext,ret)!=jseTypeObject )
               ret = jseCreateLongVariable(jsecontext,-1);
            else
               ret = jseCreateLongVariable(jsecontext,
                                           (sint)jseGetUint32Datum(jsecontext,ret,index_MEMBER));
         }
#     endif
#     if defined(JSE_STRING_REPLACE)
         if( mode==JSE_REPLACE )
         {
            ret = replace_string(jsecontext,ret,regexp,(argc==2)?argv[1]:NULL);
         }
#     endif

      jseDestroyStack(jsecontext,stack);

#     if defined(JSE_STRING_SEARCH)
         if( mode==JSE_SEARCH )
         {
            /* search ignores lastIndex and doesn't change it, set it back */
            jseSetAttributes(jsecontext,index,0);
            jsePutNumber(jsecontext,index,old);
            jseSetAttributes(jsecontext,index,attribs);
         }
#     endif
   }
   else
   {
#     if defined(JSE_STRING_MATCH) || defined(JSE_STRING_REPLACE)
         slong last_index = 0,new_index;
         jseVariable index;
         jseVarAttributes attribs;
         JSE_POINTER_SINDEX array_index = 0;

#        if defined(JSE_STRING_SEARCH)
            assert( mode != JSE_SEARCH ); /* search shouldn't get here */
#        endif

         /* set regexp.lastIndex to 0 */
         index = jseMember(jsecontext,regexp,lastIndex_MEMBER,jseTypeNumber);
         assert( index!=NULL );    /* jseMember() always returns something */
         attribs = jseGetAttributes(jsecontext,index);
         jseSetAttributes(jsecontext,index,0);
         jsePutNumber(jsecontext,index,jseZero);
         jseSetAttributes(jsecontext,index,attribs);


#        if defined(JSE_STRING_REPLACE)
            if( mode==JSE_REPLACE )
            {
               ret = jseCreateSiblingVariable(jsecontext,string,0);
            }
#        endif
#        if defined(JSE_STRING_MATCH)
            if ( mode==JSE_MATCH )
            {
               /* Construct a new Array() to hold results. */
               ret = jseCreateVariable(jsecontext,jseTypeObject);
               assert( ret!=NULL );  /* create cannot fail */
               jseSetAttributes(jsecontext,ret,jseEcmaArray);
            }
#        endif

         /* Repeatedly search */
         while( 1 )
         {
            jseStack stack;
            jseVariable func_ret;
            jseVariable pushVar;

            /* Call exec to get the match. */
            stack = jseCreateStack(jsecontext);
            /* If we are replacing, we keep using the new updated string,
             * and we will just be searching after the already-replace
             * stuff. For plain searches, the string doesn't change so
             * we use the original string.
             */
            pushVar = string;
#           if defined(JSE_STRING_REPLACE)
               if ( mode == JSE_REPLACE )
                  pushVar = ret;
#           endif
            jsePush(jsecontext,stack,pushVar,False);

            if( !jseCallFunctionEx(jsecontext,reg_func,stack,&func_ret,regexp,JSE_FUNC_TRAP_ERRORS) )
            {
               /* Ack, some error in the called function, kick out */
               jseReturnVar(jsecontext,func_ret,jseRetCopyToTempVar);
               jseLibSetErrorFlag(jsecontext);
               jseDestroyStack(jsecontext,stack);

               /* Don't worry about 'ret', it will be superceded
                * by the error.
                */
               break;
            }

            /* no match, that ends the search */
            if( jseGetType(jsecontext,func_ret)==jseTypeNull )
            {
               /* I hate destroying the stack in multiple places, but the
                * 'func_ret' will go away with the stack, so the stack
                * has to remain as long as accessing it.
                */
               jseDestroyStack(jsecontext,stack);
               break;
            }

            /* The return from exec should be an object. If that function
             * is broken, don't bomb. This isn't an assert, since someone
             * could change the exec function at runtime, so we don't
             * want that to crash us. In this case, it is better to
             * skip it (me thinks.)
             */
            if( jseGetType(jsecontext,func_ret)==jseTypeObject )
            {
#              if defined(JSE_STRING_REPLACE)
                  if( mode==JSE_REPLACE )
                  {
                     jseVariable newret =
                        replace_string(jsecontext,func_ret,regexp,(argc==2)?argv[1]:NULL);
                     jseDestroyVariable(jsecontext,ret);
                     ret = newret;
                     if( jseQuitFlagged(jsecontext) )
                     {
                        jseDestroyStack(jsecontext,stack);
                        break;
                     }
                  }
#              endif
#              if defined(JSE_STRING_MATCH)
                  if( mode==JSE_MATCH )
                  {
                     /* All we care about is the '0th' (i.e. first) element of
                      * the return, again don't bomb.
                      */
                     func_ret = jseGetIndexMember(jsecontext,func_ret,0);
                     if( func_ret!=NULL )
                     {
                        jseVariable put_place =
                           jseIndexMember(jsecontext,ret,array_index++,jseTypeUndefined);

                        jseAssign(jsecontext,put_place,func_ret);
                     }
                  }
#              endif
            }

            /* if lastIndex is the same, increment it */
            new_index = jseGetLong(jsecontext,index);
            if( new_index==last_index )
            {
               new_index++;
               jseSetAttributes(jsecontext,index,0);
               jsePutLong(jsecontext,index,new_index);
               jseSetAttributes(jsecontext,index,attribs);
            }

            last_index = new_index;

            jseDestroyStack(jsecontext,stack);
         }
#     endif /* if defined(JSE_STRING_MATCH) || defined(JSE_STRING_REPLACE) */
   }


   if( free_regexp ) jseDestroyVariable(jsecontext,regexp);
   assert( string!=NULL );
   jseDestroyVariable(jsecontext,string);

   return ret;
}

#if defined(JSE_STRING_MATCH)
static jseArgvLibFunc(Ecma_String_match)
{
   return string_search_helper(jsecontext,argc,argv,JSE_MATCH);
}
#endif /* #if defined(JSE_STRING_MATCH) */

#if defined(JSE_STRING_SEARCH)
/* String.prototype.search() */
static jseArgvLibFunc(Ecma_String_search)
{
   return string_search_helper(jsecontext,argc,argv,JSE_SEARCH);
}
#endif /* #if defined(JSE_STRING_SEARCH) */

#if defined(JSE_STRING_REPLACE)
static jseArgvLibFunc(Ecma_String_replace)
{
   return string_search_helper(jsecontext,argc,argv,JSE_REPLACE);
}
#endif /* #if defined(JSE_STRING_REPLACE) */
#endif /* #if defined(JSE_STRING_MATCH) || defined(JSE_STRING_SEARCH) || defined(JSE_STRING_REPLACE) */

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

#if defined(JSE_STRING_ANY)
static CONST_DATA(struct jseFunctionDescription) EcmaStringFunctions[] =
{
   JSE_LIBOBJECT( STRING_PROPERTY,       Ecma_String_call,    0,      1,      jseDontEnum,  jseFunc_Secure ),
   /* Set its prototype to 'Object.prototype' */
   JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"String\""), jseDontEnum ),
   JSE_LIBMETHOD( CONSTRUCT_PROPERTY, Ecma_String_construct,0,1, jseDontEnum,  jseFunc_Secure ),
   JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, Ecma_String_builtin,0,0, jseDontEnum,  jseFunc_Secure ),
   JSE_PROTOMETH( TOSTRING_PROPERTY, Ecma_String_toString,0,0, jseDontEnum,  jseFunc_Secure ),
   JSE_VARASSIGN( UNISTR("prototype.valueOf"), UNISTR("String.prototype.toString"), jseDontEnum ),
#if defined(JSE_STRING_FROMCHARCODE)
      JSE_ARGVLIBMETHOD( UNISTR("fromCharCode"), Ecma_String_fromCharCode, 0,-1,
                         jseDontEnum, jseFunc_Secure ),
      JSE_VARSTRING( UNISTR("fromCharCode.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#endif
#if defined(JSE_STRING_CHARAT)
      JSE_PROTOMETH( UNISTR("charAt"), Ecma_String_charAt,1,1, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_CHARCODEAT)
      JSE_PROTOMETH( UNISTR("charCodeAt"), Ecma_String_charCodeAt,1,1, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_INDEXOF)
      JSE_PROTOMETH( UNISTR("indexOf"), Ecma_String_indexOf,1,2, jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( UNISTR("prototype.indexOf.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#endif
#if defined(JSE_STRING_LASTINDEXOF)
      JSE_PROTOMETH( UNISTR("lastIndexOf"),  Ecma_String_lastIndexOf,1,2, jseDontEnum,  jseFunc_Secure ),
      JSE_VARSTRING( UNISTR("prototype.lastIndexOf.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#endif
#if defined(JSE_STRING_SPLIT)
      JSE_ARGVPROTOMETH( UNISTR("split"),  Ecma_String_split,0,2, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_SUBSTR)
      JSE_ARGVPROTOMETH( UNISTR("substr"),  Ecma_String_substr,1,2, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_SUBSTRING)
      JSE_ARGVPROTOMETH( UNISTR("substring"),  Ecma_String_substring,1,2, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOLOWERCASE)
      JSE_PROTOMETH( UNISTR("toLowerCase"),  Ecma_String_toLowerCase,0,0, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOUPPERCASE)
      JSE_PROTOMETH( UNISTR("toUpperCase"),  Ecma_String_toUpperCase,0,0, jseDontEnum,  jseFunc_Secure ),
#endif
#if defined(JSE_STRING_CONCAT)
      JSE_PROTOMETH( UNISTR("concat"),  Ecma_String_concat, 0, -1, jseDontEnum, jseFunc_Secure ),
      JSE_VARSTRING( UNISTR("prototype.concat.length"), UNISTR("1"), jseDontEnum|jseReadOnly|jseDontDelete),
#endif
#if defined(JSE_STRING_SLICE)
      JSE_PROTOMETH( UNISTR("slice"), Ecma_String_slice, 1, 2, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOLOCALELOWERCASE)
      JSE_PROTOMETH( UNISTR("toLocaleLowerCase"), Ecma_String_toLowerCase,0,0, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOLOCALEUPPERCASE)
      JSE_PROTOMETH( UNISTR("toLocaleUpperCase"), Ecma_String_toUpperCase,0,0, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOLOCALECOMPARE)
      JSE_ARGVPROTOMETH( UNISTR("localeCompare"), Ecma_String_localeCompare, 0,1, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_TOSOURCE)
      JSE_PROTOMETH( TOSOURCE_PROPERTY, Ecma_String_toSource, 0, 0, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_MATCH)
      JSE_ARGVPROTOMETH( UNISTR("match"), Ecma_String_match, 0,1, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_REPLACE)
      JSE_ARGVPROTOMETH( UNISTR("replace"), Ecma_String_replace, 0,2, jseDontEnum, jseFunc_Secure ),
#endif
#if defined(JSE_STRING_SEARCH)
      JSE_ARGVPROTOMETH( UNISTR("search"), Ecma_String_search, 0,1, jseDontEnum, jseFunc_Secure ),
#endif
   JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),
   JSE_FUNC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

void NEAR_CALL
InitializeLibrary_Ecma_String(jseContext jsecontext)
{
   jseAddLibrary(jsecontext,NULL,EcmaStringFunctions,NULL,NULL,NULL);
}
#endif /* #if defined(JSE_STRING_ANY) */

ALLOW_EMPTY_FILE
