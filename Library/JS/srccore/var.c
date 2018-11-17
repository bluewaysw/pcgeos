/* Var.c  - Handles creation and access to variables.
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


#include "srccore.h"

   static void NEAR_CALL
sevarChopFromLeft(struct Call *call,struct seVarString *it,
                  JSE_POINTER_UINDEX num,jsebool isBuffer)
{
   ubyte _HUGE_ *from;
   ulong len = (it->data->length-num);
   ubyte _HUGE_ *olddata = (ubyte _HUGE_ *)SESTRING_GET_DATA(it->data);

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   if ( isBuffer )
   {
      from = olddata+num;
   }
   else
#endif
   {
      from = olddata + BYTECOUNT_FROM_STRLEN(((jsecharptr)olddata),num);
      len = BYTECOUNT_FROM_STRLEN(from,len);
   }
#  ifdef JSE_NO_HUGE
      HugeMemMove(olddata,from,(size_t)len);
#  else
      HugeMemMove(olddata,from,(size_t)len);
#  endif
   it->data->length -= num;
   it->data->zoffset -= num;
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
   /* recalculate physical length */
   it->data->bytelength = BYTECOUNT_FROM_STRLEN(olddata,it->data->length);
#  endif

   SESTRING_UNGET_DATA(it->data,olddata);
}


   void NEAR_CALL
sevarValidateIndex(struct Call *call,const struct seVarString *it,
                   JSE_POINTER_SINDEX start,JSE_POINTER_UINDEX length,
                   jsebool isBuffer/*else string*/)
{
   JSE_POINTER_SINDEX absmin = start + it->loffset + (JSE_POINTER_SINDEX)it->data->zoffset;
   JSE_MEMEXT_R void *olddata;
   void _HUGE_ *newdata;
   void _HUGE_ *indata;
   JSE_POINTER_UINDEX byteOffset;
   JSE_POINTER_UINDEX byteLength;
   ulong totalSize;
   uint datumSize;
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   if ( isBuffer )
      datumSize = 1;
   else
#  endif
      datumSize = sizeof(jsechar);

   if( absmin<0 )
   {
      /* Need to grow the array but on the left size by -(absmin) elements */

#        if JSE_ALWAYS_COLLECT==0
         if( call->Global->stringallocs>=JSE_STRINGS_COLLECT )
#        endif
         {
            call->Global->stringallocs = 0;
            garbageCollect(call);
         }

      totalSize = it->data->length - absmin;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( !isBuffer )
#     endif
         totalSize *= sizeof(jsechar);
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
      totalSize += sizeof(jsecharptrdatum);

#     ifdef HUGE_MEMORY
      if( totalSize>=HUGE_MEMORY )
      {
         callQuit(call,textcoreSTRING_TOO_BIG);
         return;
      }
#     endif

      newdata = (void *)jseMallocWithGC(call,(uint)totalSize);
      if( newdata==NULL )
      {
         jseInsufficientMemory();
      }

      call->Global->stringallocs -= absmin * datumSize;
      /* Note that absmin is <0 accounting for the seemingly reverse
       * subtraction in the stuff below.
       */
      assert( absmin <= 0 );
      byteOffset = (JSE_POINTER_UINDEX)-absmin;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( !isBuffer )
#     endif
      {
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         byteOffset *= sizeof(jsecharptrdatum);
      }

#     ifdef JSE_NO_HUGE
         HugeMemSet(newdata,0,(size_t)byteOffset);
#     else
         HugeMemSet(newdata,0,byteOffset);
#     endif

      byteLength = it->data->length;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( !isBuffer )
#     endif
#     if defined(JSE_MBCS) && JSE_MBCS!=0
         byteLength = it->data->bytelength;
#     else
         byteLength *= sizeof(jsechar);
#     endif
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );

      olddata = SESTRING_GET_DATA(it->data);
#     ifdef JSE_NO_HUGE
         HugeMemCpy(HugePtrAddition(newdata,byteOffset),olddata,
                    (size_t)(byteLength + sizeof(jsecharptrdatum)));
#     else
              HugeMemCpy(HugePtrAddition(newdata,byteOffset),olddata,
                    byteLength + sizeof(jsecharptrdatum));
#     endif
      SESTRING_UNGET_DATA(it->data,olddata);
      SESTRING_FREE_DATA(it->data);
      SESTRING_PUT_DATA(it->data,newdata,totalSize);
      it->data->zoffset -= absmin;
      it->data->length -= absmin;
#     if defined(JSE_MBCS) && JSE_MBCS!=0
      /* we filled the new additions with '\0', which by our MBCS assumptions
       * are always 1 byte long
       */
      it->data->bytelength -= absmin;
#     endif
   }

   /* length passed in is length from the given start, we want it to be actual length */
   length += start + it->data->zoffset + it->loffset;

   if( it->data->length < length )
   {
#        if JSE_ALWAYS_COLLECT==0
         if( call->Global->stringallocs>=JSE_STRINGS_COLLECT )
#        endif
         {
            call->Global->stringallocs = 0;
            garbageCollect(call);
         }

         /* overhead already allocated! */
         call->Global->stringallocs += ((length-it->data->length)*datumSize);

      /* allocate one extra byte for our '\0' at end convenience */
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
      olddata = SESTRING_GET_DATA(it->data);

#     ifdef HUGE_MEMORY
      if( (length)*datumSize+sizeof(jsechar)>=HUGE_MEMORY )
      {
         callQuit(call,textcoreSTRING_TOO_BIG);
         return;
      }
#     endif
#     if JSE_MEMEXT_STRINGS==1
         /* In this case we must always free the old data and insert
          * the new. We can't reallocate because the pointer retrieved
          * comes from an underlying MEM_EXT system and isn't necessarily
          * something reallocatable.
          */
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         newdata = jseMallocWithGC(call,(uint)((length)*datumSize)+sizeof(jsecharptrdatum));
         memcpy(newdata,olddata,(it->data->length)*datumSize+sizeof(jsecharptrdatum));
#     else
         newdata = jseMustReMalloc(void,(void *)olddata,
                                   (uint)((length)*datumSize)+sizeof(jsecharptrdatum));
#     endif

      if( newdata==NULL )
      {
         /* Garbage collect then try again */
         garbageCollect(call);
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         newdata = jseMustReMalloc(void,/*rich*/(void *)olddata,
                                   (uint)(length*datumSize+sizeof(jsecharptrdatum)));
      }

      byteOffset = it->data->length;
      byteLength = length - it->data->length;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( !isBuffer )
#     endif
      {
#     if defined(JSE_MBCS) && JSE_MBCS!=0
         byteOffset = it->data->bytelength;
#     else
         byteOffset = BYTECOUNT_FROM_STRLEN(newdata,byteOffset);
#     endif
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         byteLength *= sizeof(jsecharptrdatum);
      }
#     ifdef JSE_NO_HUGE
         HugeMemSet( HugePtrAddition(newdata,byteOffset), 0, (size_t)byteLength );
#     else
         HugeMemSet( HugePtrAddition(newdata,byteOffset), 0, byteLength );
#     endif

      SESTRING_UNGET_DATA(it->data,olddata);
#     if JSE_MEMEXT_STRINGS==1
         /* for non-extended versions, we are just putting back a realloced
          * pointer. For extended, we always allocate new and copy over.
          * Thus we need to free the old value.
          */
         SESTRING_FREE_DATA(it->data);
#     endif
      SESTRING_PUT_DATA(it->data,newdata,(uint)((length)*datumSize)+sizeof(jsechar));

      it->data->length = length;
#     if defined(JSE_MBCS) && JSE_MBCS!=0
         it->data->bytelength += byteLength;
#     endif
   }

#  if JSE_MEMEXT_STRINGS==1

      /* Again, we cannot write the data it is read only, so
       * we need to copy, update, and write back.
       */
      olddata = SESTRING_GET_DATA(it->data);
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
#     if defined(JSE_MBCS) && JSE_MBCS!=0
         newdata = jseMallocWithGC(call,it->data->bytelength+sizeof(jsecharptrdatum));
         memcpy(newdata,olddata,it->data->bytelength+sizeof(jsecharptrdatum));
#     else
         newdata = jseMallocWithGC(call,it->data->length+sizeof(jsecharptrdatum));
         memcpy(newdata,olddata,it->data->length+sizeof(jsecharptrdatum));
#     endif

#  else
      olddata = newdata = SESTRING_GET_DATA(it->data);
#  endif

   /* we terminate all data in a '\0' for convenience */
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   if ( isBuffer )
   {
      indata = (void *)HugePtrAddition(newdata,it->data->length);
   }
   else
#  endif
   {
#     if defined(JSE_MBCS) && JSE_MBCS!=0
         indata = (void *)HugePtrAddition(newdata,it->data->bytelength);
#     else
         indata = (void *)HugePtrAddition(newdata,
                                          BYTECOUNT_FROM_STRLEN(newdata,it->data->length));
#     endif
   }
   JSECHARPTR_PUTC((jsecharptr)indata,'\0');

   SESTRING_UNGET_DATA(it->data,olddata);

#  if JSE_MEMEXT_STRINGS==1
      SESTRING_FREE_DATA(it->data);
      SESTRING_PUT_DATA(it->data,newdata,(length)*datumSize+sizeof(jsechar));
#  endif
}


   void NEAR_CALL
sevarSetArrayLength(struct Call *call,wSEVar this,
                    JSE_POINTER_SINDEX MinIndex,
                    JSE_POINTER_UINDEX Length)
{
   assert( sevarIsValid(call,this) );

   if( SEVAR_ARRAY_PTR(this) )
   {
      jsebool isBuffer;

#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( VBuffer == (this)->type )
         isBuffer = True;
      else
#     endif
         isBuffer = False;

      if( Length + this->data.string_val.loffset + this->data.string_val.data->zoffset<
          this->data.string_val.data->length )
      {
         /* shrink if too big */
         this->data.string_val.data->length =
            Length + this->data.string_val.loffset + this->data.string_val.data->zoffset;
         /* need to recalculate length */
#        if defined(JSE_MBCS) && JSE_MBCS!=0
            this->data.string_val.data->bytelength =
               BYTECOUNT_FROM_STRLEN(SESTRING_GET_DATA(this->data.string_val.data),
                                     this->data.string_val.data->length);
#        endif
      }

      /* Only if the MinIndex<0 do we really want to chop */
      if( MinIndex<0 &&
          -MinIndex<(sint)this->data.string_val.loffset+(sint)this->data.string_val.data->zoffset )
      {
         /* shrink if too many elements to the left */
         sevarChopFromLeft(call,&(this->data.string_val),
                           this->data.string_val.loffset+
                           this->data.string_val.data->zoffset+MinIndex /* i.e. - (-MinIndex) */,
                           isBuffer);
      }

      sevarValidateIndex(call,&(this->data.string_val),MinIndex,Length,isBuffer);
   }
   else
   {
      wSEObject wobj;
      rSEMembers rMembers;
      jsebool MaxFound = ( 0 < (JSE_POINTER_SINDEX)Length ) ? False : True ;
      JSE_POINTER_UINDEX maxIndex = Length - 1;
      uint x;

      assert( SEVAR_GET_TYPE(this)==VObject );

      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(this));
      if (SEOBJECT_PTR(wobj)->used != 0)
      {
	SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(wobj)->hsemembers);
        for( x=0;x<SEOBJECT_PTR(wobj)->used;x++ )
        {
         VarName entry = SEMEMBERS_PTR(rMembers)[x].name;
         if( IsNumericStringTableEntry(entry) )
         {
            JSE_POINTER_SINDEX value = (JSE_POINTER_SINDEX)GetNumericStringTableEntry(entry);
            /* we need the strange looking double compare to make sure all
             * negative entries aren't deleted
             */
            if( value<MinIndex ||
                (value>=0 && ((JSE_POINTER_UINDEX)value)>=Length) )
            {
               /* deletemember amy realloc rmembers */
               SEMEMBERS_UNLOCK_R(rMembers);
               seobjDeleteMember(call,wobj,entry,False);
               SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(wobj)->hsemembers);
               /* decrement 'x' to do this slot over again since its former
                * occupant is gone, and the next entry has slid into its place
                */
               x--;
            }
            else if ( (JSE_POINTER_UINDEX)value == maxIndex  &&  0 <= value )
            {
               MaxFound = True;
            }
         }
	}
	SEMEMBERS_UNLOCK_R(rMembers);
      }
      if ( !MaxFound )
      {
         /* "grow" the array to this new size */
         wSEObjectMem wMem;
         wMem = SEOBJ_CREATE_MEMBER(call,wobj,PositiveStringTableEntry(maxIndex));
         SEVAR_INIT_UNDEFINED(SEOBJECTMEM_VAR(wMem));
         SEOBJECTMEM_UNLOCK_W(wMem);
      }
      SEOBJECT_UNLOCK_W(wobj);
   }
}


/* ---------------------------------------------------------------------- */


/* This is how we do the "a[0] = 'a';" code, where the variable
 * is a string in a cfunction. This puts the value into the string
 * at the correct location. The string is grown, if necessary, to
 * be have the given character location.
 */
   static void NEAR_CALL
seobjPutIntoString(struct Call *call,rSEVar str,VarName mem,jsechar val)
{
   wSEVar tmp = STACK_PUSH;

   assert( sevarIsValid(call,str) );

   SEVAR_COPY(tmp,str);
   SEVAR_GET_STRING(tmp).loffset += (JSE_POINTER_SINDEX)GetNumericStringTableEntry(mem);
   str = tmp;

   assert( SEVAR_ARRAY_PTR(str) );

   if( SEVAR_GET_TYPE(str)==VString )
   {
      /* make space for this character. Used to be done when we first reference
       * it, but that screws making a sibling just to get a lock. (It adds a
       * character.) It should only add the character here, now that we are
       * trying to use it.
       */
      JSE_MEMEXT_R jsecharptr text;

      sevarValidateIndex(call,&(SEVAR_GET_STRING(str)),0,1,False);
      text = sevarGetData(call,str);

#     if defined(JSE_MBCS) && (0!=JSE_MBCS)
      /*** NYI: This MBCS code is extremely experimental
       ***/
         if( sizeofnext_jsechar(text) == sizeof_jsechar(val) )
         {
            JSECHARPTR_PUTC(text,val);
         }
         else
         {  /* In this case they are of different sizes, so this
             * is not good.  We'll have to do some work to make
             * sure that it can fit.
             */
            size_t loc,size;
            jsecharptr offset;
            jsecharptr tmp;

            loc = (size_t)(str->data.string_val.data->zoffset + str->data.string_val.loffset);

            text = SESTRING_GET_DATA(str->data.string_val.data);

            /* We add 1 extra for the null byte, and then one more in case we are
             * increasing the size.
             */

            size = str->data.string_val.data->bytelength+2;
            tmp = (jsecharptr)jseMallocWithGC(call,size);
            if( tmp==NULL )
            {
               jseInsufficientMemory();
            }

            /* First, copy up until this length */
            memcpy( tmp, text, BYTECOUNT_FROM_STRLEN(text,loc));
            offset = JSECHARPTR_OFFSET(tmp,loc);
            /* Now, put this character */
                        JSECHARPTR_PUTC(offset,val);
            /* Now, copy the rest of the text */
            JSECHARPTR_INC(offset);
            memcpy( tmp, JSECHARPTR_OFFSET(text,loc)+sizeof_jsechar(val),
                    BYTECOUNT_FROM_STRLEN(JSECHARPTR_OFFSET(text,loc),
                                          str->data.string_val.data->length - loc)+1 );
            /* We add 1 here to get the extra null at the end of the string */

               /* Finally, now we can put the data back - This is copied from varValidateIndex */
#              if JSE_ALWAYS_COLLECT==0
            if( call->Global->stringallocs>=JSE_STRINGS_COLLECT )
#              endif
            {
               garbageCollect(call);
               call->Global->stringallocs = 0;
            }

            /* overhead already allocated! */
            call->Global->stringallocs += (str->data.string_val.data->length+1);

            str->data.string_val.data->bytelength =
               BYTECOUNT_FROM_STRLEN(tmp,str->data.string_val.data->length);
            SESTRING_PUT_DATA(str->data.string_val.data,tmp,str->data.string_val.data->length);
         }
#     else
         /* NYI: this is illegal in the new stuff */
         JSECHARPTR_PUTC(/*Rich:*/(jsecharptr)text,val);
#     endif
      SEVAR_FREE_DATA(call,text);
   }
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   else
   {
      ubyte *text;

      assert( SEVAR_GET_TYPE(str)==VBuffer );
      sevarValidateIndex(call,&(SEVAR_GET_STRING(str)),0,1,True);
      text = (ubyte *)sevarGetData(call,str);
      /* NYI: illegal in extended memory version */
      text[0] = (ubyte)val;
      SEVAR_FREE_DATA(call,text);
   }
#  endif

   STACK_POP;
}


/* Get the given object member to the given destination.
 * Note that the object may be locked into memory currently
 * by the destination, so do not update the 'dest' and then
 * do something which might garbage-collect.
 *
 * To the caller: 'dest' must be valid on entry. If you've
 * just allocated it, use SEVAR_INIT_UNDEFINED() on it before
 * calling us. Usually, this won't be applicable, because it
 * will be overwriting a value on the stack, which currently
 * has a valid value.
 *
 * Also, 'obj' will be auto-converted into an object. Don't
 * pass a variable you care about unless you really want it
 * to become an object. The way the secode engine works, it
 * will always get passed a temp copy on the stack, any other
 * caller must take this into account.
 */
   jsebool NEAR_CALL
sevarGetValue(struct Call *call,wSEVar obj,VarName mem,wSEVar dest,int flags)
{
   rSEObject rThisObject;

   assert( sevarIsValid(call,obj) );
   assert( sevarIsValid(call,dest) );

   /* first, if this is a String in a CFunction (or a Buffer at any
    * time), and the member is a numeric index, we do our special
    * 'get the element as a number' code.
    */
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   if( SEVAR_GET_TYPE(obj)==VBuffer && IsNumericStringTableEntry(mem) )
   {
      JSE_POINTER_SINDEX loc = (JSE_POINTER_SINDEX)GetNumericStringTableEntry(mem);

      if( loc>=0 )
      {
         if( loc>=(sint)SEVAR_STRING_LEN(obj) )
         {
            /* read past end of string */
            SEVAR_INIT_NUMBER(dest,jseZero);
         }
         else
         {
            JSE_MEMEXT_R ubyte *data = sevarGetData(call,obj);
            SEVAR_INIT_SLONG(dest,data[loc]);   /* buffers are always 1 byte */
            SEVAR_FREE_DATA(call,data);
         }
      }
      else
      {
         JSE_POINTER_SINDEX lim;
         sevarGetArrayLength(call,obj,&lim);
         if( loc<=lim )
         {
            /* read past end of string */
            SEVAR_INIT_NUMBER(dest,jseZero);
         }
         else
         {
            JSE_MEMEXT_R ubyte *data = sevarGetData(call,obj);
            /* will go back, but we've verified there is enough stuff to read from */
            SEVAR_INIT_SLONG(dest,data[loc]);   /* buffers are always 1 byte */
            SEVAR_FREE_DATA(call,data);
         }
      }
      return !CALL_QUIT(call);
   }

#  endif
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
      if( SEVAR_GET_TYPE(obj)==VString && CALL_CBEHAVIOR &&
       IsNumericStringTableEntry(mem) )
      {
         JSE_POINTER_SINDEX loc = (JSE_POINTER_SINDEX)GetNumericStringTableEntry(mem);

         if( loc>=0 )
         {
            if( loc>=(sint)SEVAR_STRING_LEN(obj) )
            {
               /* read past end of string */
               SEVAR_INIT_NUMBER(dest,jseZero);
            }
            else
            {
               JSE_MEMEXT_R jsecharptr data = sevarGetData(call,obj);
               SEVAR_INIT_SLONG(dest,JSECHARPTR_GETC(JSECHARPTR_OFFSET(data,loc)));
               SEVAR_FREE_DATA(call,data);
            }
         }
         else
         {
            JSE_POINTER_SINDEX lim;
            sevarGetArrayLength(call,obj,&lim);
            if( loc<=lim )
            {
               /* read past end of string */
               SEVAR_INIT_NUMBER(dest,jseZero);
            }
            else
            {
               JSE_MEMEXT_R jsecharptr data = sevarGetData(call,obj);
               /* will go back, but we've verified there is enough stuff to read from */
               SEVAR_INIT_SLONG(dest,JSECHARPTR_GETC(JSECHARPTR_OFFSET(data,loc)));
               SEVAR_FREE_DATA(call,data);
            }
         }
         return !CALL_QUIT(call);
      }
#  endif

   /* Ok, if this is not already an object, we must auto-convert
    * it to an object.
    */
   if( SEVAR_GET_TYPE(obj)!=VObject )
   {
      /* We are trying to read a field, if this cannot be converted
       * to an object, that is an appropriate error
       */
      sevarConvertToObject(call,obj);
   }

   assert( SEVAR_GET_TYPE(obj)==VObject );
   SEOBJECT_ASSIGN_LOCK_R(rThisObject,SEVAR_GET_OBJECT(obj));

#  if defined(JSE_DYNAMIC_OBJS)
   /* pass hint about whether this is being retrieved to be called
    * as a function
    */
   if( !SEOBJ_IS_DYNAMIC(rThisObject) ||
       !seobjCallDynamicProperty(call,rThisObject,dynacallGet,mem,
           (rSEVar)(NULL != FUNCPTR && FUNCTION_IS_LOCAL(FUNCPTR)
                   && (seToCallFunc==*IPTR || seToNewFunc==*IPTR)),
           dest) )
#  endif
   {
      rSEObjectMem rIt;

      /* Else it is a regular object, just grab the member */
      if( (flags&GV_NO_PROTOTYPE)!=0 )
         rIt = rseobjGetMemberStruct(call,rThisObject,mem);
      else
         rIt = seobjChildMemberStruct(call,rThisObject,mem);
      if( NULL != SEOBJECTMEM_PTR(rIt) )
      {
         SEVAR_COPY(dest,SEOBJECTMEM_VAR(rIt));
         SEOBJECTMEM_UNLOCK_R(rIt);
      }
      else
      {
         SEVAR_INIT_UNDEFINED(dest);
      }
   }

   SEOBJECT_UNLOCK_R(rThisObject);

   /* undo any redirection for CFunction stuff */
   SEVAR_DEREFERENCE(call,dest);

   assert( sevarIsValid(call,dest) );

   return !CALL_QUIT(call);
}

/* this handles putting to a derefed place and doing dynamic puts */
   void NEAR_CALL
sevarDoPut(struct Call *call,wSEVar wPlace,wSEVar wVal)
     /* NYI: Brent had this as 'rSEVar' */
{
   wSEVar tmp;

#  if 0 == JSE_INLINES
      if( SEVAR_GET_TYPE(wPlace) < VReference )
      {
         SEVAR_COPY(wPlace,wVal);
         return;
      }
#  else
      assert( VReference <= SEVAR_GET_TYPE(wPlace) );
#  endif

   assert( sevarIsValid(call,wPlace) );
#  if JSE_COMPACT_LIBFUNCS==1
      assert( SEVAR_GET_TYPE(wVal)==VLibFunc || sevarIsValid(call,wVal) );
#  else
      assert( sevarIsValid(call,wVal) );
#  endif

   tmp = STACK_PUSH;

   SEVAR_INIT_OBJECT(tmp,wPlace->data.ref_val.hBase);
   if( sevarPutValueEx(call,tmp,wPlace->data.ref_val.reference,wVal,
                       SEVAR_GET_TYPE(wPlace)!=VReference) )
   {
      STACK_POP;
   }
}


/*
 * Also, 'obj' will be auto-converted into an object. Don't
 * pass a variable you care about unless you really want it
 * to become an object. The way the secode engine works, it
 * will always get passed a temp copy on the stack, any other
 * caller must take this into account.
 */
   jsebool NEAR_CALL
sevarPutValueEx(struct Call *call,wSEVar obj,VarName mem,wSEVar val,jsebool is_index)
{
   hSEObject hThisObject;
   rSEObject rThisObject;
   wSEObject wThisObject;
   wSEObjectMem wsmem;
   jsebool found;

   assert( sevarIsValid(call,obj) );
#  if JSE_COMPACT_LIBFUNCS==1
      assert( SEVAR_GET_TYPE(val)==VLibFunc || sevarIsValid(call,val) );
#  else
      assert( sevarIsValid(call,val) );
#  endif

   if( is_index )
   {
      /* also is_index indicates a VariableObject which can never be
       * dynamic, see asserts below.
       */
      assert( SEVAR_GET_TYPE(obj)==VObject );
   }

 top:

   /* if it is a String in a cfunction (or a Buffer anywhere), and the
    * member is a numeric index, turn the 'val' into a number and stuff
    * it into the given character location.
    */
#  if ( defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER) ) \
   || ( defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS) )
      if (
#        if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
         SEVAR_GET_TYPE(obj)==VBuffer
#           if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
            ||
#           endif
#        endif
#        if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
         (SEVAR_GET_TYPE(obj)==VString && CALL_CBEHAVIOR)
#        endif
      )
      {
         if ( IsNumericStringTableEntry(mem) )
         {
            seobjPutIntoString(call,obj,mem,(jsechar)JSE_FP_CAST_TO_SLONG(sevarConvertToNumber(call,val)));
            return True;
         }
      }
#  endif

   /* otherwise, if not already an object, auto-convert it into one. */
   if( SEVAR_GET_TYPE(obj)!=VObject )
   {
      sevarConvertToObject(call,obj);
   }
   assert( SEVAR_GET_TYPE(obj)==VObject );
   hThisObject = SEVAR_GET_OBJECT(obj);
   SEOBJECT_ASSIGN_LOCK_R(rThisObject,hThisObject);

   /* if it has a CanPut dynamic property, call that and only continue
    * if it doesn't veto. Check attributes if appropriate
    */
#  if defined(JSE_DYNAMIC_OBJS)
   if( SEOBJ_IS_DYNAMIC(rThisObject) )
   {
      jsebool result;
      if( !seobjCanPut(call,rThisObject,mem) )
      {
         assert( !is_index );
         SEOBJECT_UNLOCK_R(rThisObject);
         return True;
      }

      /* If it is a dynamic object with a Put dynamic property, call that
       * now.
       */
      result = seobjCallDynamicProperty(call,rThisObject,dynacallPut,mem,val,NULL);
      if( result || CALL_QUIT(call) )
      {
         SEOBJECT_UNLOCK_R(rThisObject);
         return True;
      }
   }
#  endif

   /* otherwise, it is a regular object, just update the given member,
    * if the attribute is not ReadOnly. The given member could possibly
    * be type >=VReference, so use the standard block if needed to figure
    * out where to put it.
    */
   if( SEVAR_GET_TYPE(obj)==VReference )
   {
      /* can't have double-indirection */
      assert( !is_index );
      mem = obj->data.ref_val.reference;
      SEVAR_INIT_OBJECT(obj,obj->data.ref_val.hBase);
      SEOBJECT_UNLOCK_R(rThisObject);
      goto top;
   }
   else if( SEVAR_GET_TYPE(obj)==VReferenceIndex )
   {
      /* can't have double-indirection */
      mem = obj->data.ref_val.reference;
      is_index = True;
      SEVAR_INIT_OBJECT(obj,obj->data.ref_val.hBase);
      SEOBJECT_UNLOCK_R(rThisObject);
      goto top;
   }

   if( is_index )
   {
      SEOBJECT_PTR(wThisObject) = NULL;
      SEOBJECTMEM_CAST_R(wsmem) = wseobjIndexMemberStruct(call,rThisObject,(MemCountUInt)(JSE_POINTER_UINT)mem);
   }
   else
   {
      SEOBJECT_ASSIGN_LOCK_W(wThisObject,hThisObject);
      wsmem = seobjNewMember(call,wThisObject,mem,&found);
   }

   if( (SEOBJECTMEM_PTR(wsmem)->attributes & jseReadOnly)==0 )
   {
      wSEVar tmpvar = STACK_PUSH;
      SEVAR_COPY(tmpvar,SEOBJECTMEM_VAR(wsmem));
      IF_OPERATOR_NOT_OVERLOADED(call,tmpvar,val,seAssignLocal)
      {
         SEVAR_COPY(SEOBJECTMEM_VAR(wsmem),val);
      }
#     if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
      else
      {
         SEVAR_COPY(val,tmpvar);
      }
#     endif
      STACK_POP;

      /* _prototype coding for inheriting dynamic properties */

      if( SEOBJECTMEM_PTR(wsmem)->name==STOCK_STRING(_prototype)
       && SEVAR_GET_TYPE(SEOBJECTMEM_VAR(wsmem))==VObject )
      {
         rSEObject robj;
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wsmem)));
         if ( SEOBJECT_PTR(wThisObject) == NULL )
         {
            SEOBJECT_ASSIGN_LOCK_W(wThisObject,hThisObject);
         }
         if( SEOBJ_IS_DYNAMIC(robj) )
            SEOBJ_MAKE_DYNAMIC(wThisObject);
         SEOBJECT_UNLOCK_R(robj);
      }

      /* ecma array special case coding, speeds execution tremendously */

      /* Note that creating the member automatically updates length. */
      if( (SEOBJECT_PTR(rThisObject)->flags & IS_ARRAY)
       && SEOBJECTMEM_PTR(wsmem)->name==STOCK_STRING(length) )
      {
         jsenumber value;

         value = ( SEVAR_GET_TYPE(val)==VNumber ) ? SEVAR_GET_NUMBER(val) : jseZero ;

         sevarConvert(call,val,jseToUint32);
         if( !CALL_QUIT(call) )
         {
            if( !jseIsZero(value) && JSE_FP_NEQ(value,JSE_FP_CAST_FROM_SLONG(SEVAR_GET_SLONG(val))) )
               callError(call,textcoreARRAY_LENGTH_OUT_OF_RANGE);
            else
               sevarSetArrayLength(call,obj,JSE_PTR_MIN_SINDEX,
                                   (JSE_POINTER_UINDEX)SEVAR_GET_SLONG(val));
         }
      }
   }
   SEOBJECTMEM_UNLOCK_W(wsmem);
#  if JSE_MEMEXT_OBJECTS!=0
      if ( NULL != SEOBJECT_PTR(wThisObject) )
         SEOBJECT_UNLOCK_W(wThisObject);
#  endif
   SEOBJECT_UNLOCK_R(rThisObject);
   return !CALL_QUIT(call);
}


#if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
/* NULL if not object. Handle _call. For various reasons, the _call cannot
 * be dynamically gotten - there must be some real memory for this to point
 * to. Later, could throw it into a temp object, but this seems inadvisable.
 */
#if defined(SEOBJ_FLAG_BIT)
   const struct Function * NEAR_CALL
sevarGetFunction(struct Call *call,rSEVar obj)
{
   rSEObject robj;
   hSEObject hobj;
   const struct Function *func;
   assert( sevarIsValid(call,obj) );

   if( SEVAR_GET_TYPE(obj)!=VObject ) return NULL;

   hobj = SEVAR_GET_OBJECT(obj);
   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);

   /* Prevent looping call chains */
   if( !SEOBJ_WAS_FLAGGED(robj)  &&  SEOBJ_IS_DYNAMIC(robj) )
   {
      rSEObjectMem obj2;

      obj2 = rseobjGetMemberStruct(call,robj,STOCK_STRING(_call));
      if( NULL != SEOBJECTMEM_PTR(obj2) )
      {
         func = NULL;
         if ( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(obj2))==VObject )
         {
            wSEObject wobj;
            SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
            SEOBJ_MARK_FLAGGED(wobj);
            func = sevarGetFunction(call,SEOBJECTMEM_VAR(obj2));
            SEOBJ_MARK_NOT_FLAGGED(wobj);
            SEOBJECT_UNLOCK_W(wobj);
         }
         SEOBJECTMEM_UNLOCK_R(obj2);
         if( func )
         {
            SEOBJECT_UNLOCK_R(robj);
            return func;
         }
      }
      else
      {
         SEOBJECTMEM_UNLOCK_R(obj2);
      }
   }

   func = SEOBJECT_PTR(robj)->func;
   SEOBJECT_UNLOCK_R(robj);
   return func;
}
#else /* #if defined(SEOBJ_FLAG_BIT) */
   const struct Function * NEAR_CALL
sevarGetFunctionRecurse(struct Call *call,rSEVar obj,struct VarRecurse *prev)
{
   rSEObject robj;
   hSEObject hobj;
   const struct Function *func;
   assert( sevarIsValid(call,obj) );

   if( SEVAR_GET_TYPE(obj)!=VObject ) return NULL;

   hobj = SEVAR_GET_OBJECT(obj);
   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);

   if( SEOBJ_IS_DYNAMIC(robj) )
   {
      struct VarRecurse myRecurse;
      CHECK_FOR_RECURSION(prev,myRecurse,hobj)
      if ( !ALREADY_BEEN_HERE(myRecurse) )
      {
         rSEObjectMem obj2 = rseobjGetMemberStruct(call,robj,STOCK_STRING(_call));
         if( NULL != SEOBJECTMEM_PTR(obj2) )
         {
            func = sevarGetFunctionRecurse(call,SEOBJECTMEM_VAR(obj2),&myRecurse);
            SEOBJECTMEM_UNLOCK_R(obj2);
            if( NULL != func )
            {
               SEOBJECT_UNLOCK_R(robj);
               return func;
            }
         }
      }
   }

   func = SEOBJECT_PTR(robj)->func;
   SEOBJECT_UNLOCK_R(robj);
   return func;
}
#endif /* #if defined(SEOBJ_FLAG_BIT) */
#endif /* #if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS) */


   void NEAR_CALL
seobjSetAttributes(struct Call *call,hSEObject hobj,VarName prop,uword8 attribs)
{
   rSEObject robj;
   wSEObjectMem wmem;

   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
   SEOBJECTMEM_CAST_R(wmem) = wseobjGetMemberStructNoExpand(call,robj,prop);
   SEOBJECT_UNLOCK_R(robj);
   if( NULL != SEOBJECTMEM_PTR(wmem) )
   {
      SEOBJECTMEM_PTR(wmem)->attributes = attribs;
      SEOBJECTMEM_UNLOCK_W(wmem);
   }
}

   seAttribs NEAR_CALL
seobjGetAttributes(struct Call *call,hSEObject hobj,VarName prop)
{
   seAttribs ret;
   rSEObject robj;
   rSEObjectMem rmem;

   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
   rmem = rseobjGetMemberStructNoExpand(call,robj,prop);
   SEOBJECT_UNLOCK_R(robj);
   if( NULL != SEOBJECTMEM_PTR(rmem) )
   {
      ret = SEOBJECTMEM_PTR(rmem)->attributes;
      SEOBJECTMEM_UNLOCK_R(rmem);
   }
   else
   {
      ret = 0;
   }
   return ret;
}

#if JSE_MEMEXT_READONLY!=0 || JSE_MEMEXT_MEMBERS!=0 || JSE_COMPACT_LIBFUNCS!=0
   rSEObjectMem NEAR_CALL
rseobjIndexMemberStructEx(struct Call *call,rSEObject robj,MemCountUInt member
#  if JSE_MEMEXT_READONLY!=0
      ,jsebool returnReadOnly /* if false the what this returns is really a rSEObjectMem */
#  endif
)
{
   wSEObjectMem ret;
   wSEMembers wMembers;

   assert( member < SEOBJECT_PTR(robj)->used );

#  if JSE_MEMEXT_READONLY!=0
   if ( returnReadOnly )
      SEMEMBERS_ASSIGN_LOCK_R(SEMEMBERS_CAST_R(wMembers),SEOBJECT_PTR(robj)->hsemembers);
   else
#  endif
      SEMEMBERS_ASSIGN_LOCK_W(wMembers,SEOBJECT_PTR(robj)->hsemembers);

   SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,member);

#  if JSE_COMPACT_LIBFUNCS!=0
      if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(ret))==VLibFunc )
      {
         /* libfuncExpand needs writeable seobjectmem, but this may be readonly */
#        if JSE_MEMEXT_READONLY!=0
         if ( returnReadOnly )
         {
            SEOBJECTMEM_UNLOCK_R(ret);
            SEOBJECTMEM_CAST_R(ret) = rseobjIndexMemberStructEx(call,robj,member,False);
            SEOBJECTMEM_UNLOCK_W(ret);
            SEOBJECTMEM_CAST_R(ret) = rseobjIndexMemberStructEx(call,robj,member,True);
         }
         else
#        endif
         {
            libfuncExpand(call,SEOBJECTMEM_VAR(ret),
                          SEOBJECTMEM_PTR(ret)->value.data.libfunc_val.funcDesc,
                          SEOBJECTMEM_PTR(ret)->value.data.libfunc_val.data);
         }
      }
#  endif
   return SEOBJECTMEM_CAST_R(ret);
}

#endif /* JSE_MEMEXT_READONLY!=0 || JSE_MEMEXT_MEMBERS!=0 || JSE_COMPACT_LIBFUNCS!=0 */

   rSEObjectMem NEAR_CALL
rseobjGetMemberStructEx(struct Call *call,rSEObject rthis,VarName Name
#  if JSE_MEMEXT_READONLY!=0
      ,jsebool returnReadOnly /* if false the what this returns is really a rSEObjectMem */
#  endif
#  if JSE_COMPACT_LIBFUNCS!=0
      ,jsebool libExpand
#  endif
)
{
   wSEObjectMem ret;
   MemCountUInt used;

   /* If this is 'arguments', recreate appropriate arguments object
    * for this item. callCreateVariableObject will recreate it for
    * this function if need be. This makes sure the latest 'arguments'
    * are here while deferring building until needed.
    */
   if( Name==STOCK_STRING(arguments) && SEOBJECT_PTR(rthis)->func )
   {
      callCreateVariableObject(call,SEOBJECT_PTR(rthis)->func);
   }

   if( 0 != (used=SEOBJECT_PTR(rthis)->used) )
   {
      wSEMembers wMembers;

#     if JSE_MEMEXT_READONLY!=0
      if ( returnReadOnly )
         SEMEMBERS_ASSIGN_LOCK_R(SEMEMBERS_CAST_R(wMembers),SEOBJECT_PTR(rthis)->hsemembers);
      else
#     endif
         SEMEMBERS_ASSIGN_LOCK_W(wMembers,SEOBJECT_PTR(rthis)->hsemembers);

      /* check the last accessed members - members tend to be accessed
       * more than once at a time. Upgrade their cache status the more
       * they are used.
       */
#     if 0==JSE_PER_OBJECT_CACHE
         if ( call->Global->recentObjectCache.hobj == SEOBJECT_HANDLE(rthis)
           && call->Global->recentObjectCache.index < SEOBJECT_PTR(rthis)->used )
         {
            SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,call->Global->recentObjectCache.index);
            if( Name == SEOBJECTMEM_PTR(ret)->name )
            {
               goto ReturnObjectMem;
            }
         }
#     else
         SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,SEOBJECT_PTR(rthis)->cache);
         if( Name == SEOBJECTMEM_PTR(ret)->name )
         {
            goto ReturnObjectMem;
         }
#     endif

      if( (SEOBJECT_PTR(rthis)->flags & SEOBJ_DONT_SORT) != 0 )
      {
         register sword16 i = (sword16)(used-1);

         SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,i);
         for( ; 0 <= i; i-- )
         {
            if( SEOBJECTMEM_PTR(ret)->name == Name )
            {
#              if 0==JSE_PER_OBJECT_CACHE
                  call->Global->recentObjectCache.hobj = SEOBJECT_HANDLE(rthis);
                  call->Global->recentObjectCache.index = i;
#              else
                  SEOBJECT_PTR(rthis)->cache = i;
#              endif
               assert( NULL != SEOBJECTMEM_PTR(ret) );
               return SEOBJECTMEM_CAST_R(ret);
            }
            SEOBJECTMEM_PTR(ret)--;
         }
      }
      else
      {
         MemCountUInt lower, upper, middle;

         upper = used - 1;

         lower = 0;
         for ( ; ; )
         {
            assert( lower<=upper );
            SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,(middle = ((lower+upper) >> 1)));
            /* casting for systems where addition must be HUGE */

            /* mgroeber 07/06/00: pointers are compared as 16-bit by default */
            if( (dword)SEOBJECTMEM_PTR(ret)->name <= (dword)Name )
            {
               if( SEOBJECTMEM_PTR(ret)->name == Name )
               {
#                 if 0==JSE_PER_OBJECT_CACHE
                     call->Global->recentObjectCache.hobj = SEOBJECT_HANDLE(rthis);
                     call->Global->recentObjectCache.index = middle;
#                 else
                     SEOBJECT_PTR(rthis)->cache = middle;
#                 endif

                  ReturnObjectMem:
#                 if JSE_COMPACT_LIBFUNCS==1
                     if( libExpand && SEVAR_GET_TYPE(SEOBJECTMEM_VAR(ret))==VLibFunc )
                     {
                        /* libfuncExpand needs writeable seobjectmem, but this may be readonly */
#                       if JSE_MEMEXT_READONLY!=0
                        if ( returnReadOnly )
                        {
                           SEOBJECTMEM_UNLOCK_R(ret);
                           SEOBJECTMEM_CAST_R(ret) = rseobjGetMemberStructEx(call,rthis,Name,False,True);
                           SEOBJECTMEM_UNLOCK_W(ret);
                           SEOBJECTMEM_CAST_R(ret) = rseobjGetMemberStructEx(call,rthis,Name,True,False);
                        }
                        else
#                       endif
                        {
                           libfuncExpand(call,SEOBJECTMEM_VAR(ret),
                                         SEOBJECTMEM_PTR(ret)->value.data.libfunc_val.funcDesc,
                                         SEOBJECTMEM_PTR(ret)->value.data.libfunc_val.data);
                        }
                     }
#                 endif
                  assert( NULL != SEOBJECTMEM_PTR(ret) );
                  return SEOBJECTMEM_CAST_R(ret);
               }
               if( middle==upper )
                  break;
               lower = middle + 1;
            }
            else
            {
               if( middle==lower )
                  break;
               upper = middle - 1;
            }
         }
      }
#     if JSE_MEMEXT_READONLY!=0
      if ( returnReadOnly )
         SEMEMBERS_UNLOCK_R(SEMEMBERS_CAST_R(wMembers));
      else
#     endif
      SEMEMBERS_UNLOCK_W(wMembers);
   }
   /* if fall-through to here then field was never found */
   SEOBJECTMEM_PTR(ret) = NULL;
   return SEOBJECTMEM_CAST_R(ret);
}


/* Search the prototype too */
#if defined(SEOBJ_FLAG_BIT)
   rSEObjectMem NEAR_CALL
seobjChildMemberStruct(struct Call *call,rSEObject this,VarName name)
{
   rSEObject orig = this;
   rSEObjectMem it;
   hSEObject newthis;
   rSEObjectMem ret = NULL;
   int pass;
   jsebool bad = False;

   /* First pass is to find the member, second pass is to
    * erase our marks left for finding circular prototype
    * chains.
    */
   for( pass=0;pass<2;pass++ )
   {
      this = orig;
      while( 1 )
      {
         if( pass==1 )
         {
            if( (this->flags & SEOBJ_FLAG_BIT)==0 ) break;
            this->flags &= ~SEOBJ_FLAG_BIT;
         }
         else
         {
            if( this->flags & SEOBJ_FLAG_BIT )
            {
               /* ACK! infinite prototype loop. Don't call the error
                * routine here because we have some stuff marked, we
                * must make sure to unmark it before any of that
                * kind of thing can be called.
                */
               bad = True;
               break;
            }

            if( (ret = rseobjGetMemberStruct(call,this,name)) != NULL ) break;

            this->flags |= SEOBJ_FLAG_BIT;
         }
         /* replace 'this' with 'this._prototype' and keep searching */
         it = rseobjGetMemberStruct(call,this,STOCK_STRING(_prototype));
         if( it==NULL )
         {
            /* default prototype */
            newthis = SEOBJ_DEFAULT_PROTOTYPE(call,this);
            if( newthis==NULL || newthis==this ) break;
            this = newthis;
         }
         else
         {

            if( SEVAR_GET_TYPE(&(it->value))!=VObject ) break;
            this = SEVAR_GET_OBJECT(&(it->value));
         }
      }
   }

   if( bad )
      callQuit(call,textcorePROTOTYPE_LOOPS);

   return ret;
}
#else /* #if defined(SEOBJ_FLAG_BIT) */
   rSEObjectMem NEAR_CALL
seobjChildMemberStructRecurse(struct Call *call,rSEObject robj,VarName name,struct VarRecurse *prev)
{
   rSEObjectMem ret = rseobjGetMemberStruct(call,robj,name);

   if ( NULL == SEOBJECTMEM_PTR(ret) )
   {
      rSEObjectMem it;
      hSEObject hNewThis;

      /* replace 'this' with 'this._prototype' and keep searching */
      it = rseobjGetMemberStruct(call,robj,STOCK_STRING(_prototype));
      if( NULL == SEOBJECTMEM_PTR(it) )
      {
         /* default prototype */
         hNewThis = SEOBJ_DEFAULT_PROTOTYPE(call,SEOBJECT_PTR(robj));
         if ( hNewThis == SEOBJECT_HANDLE(robj) )
            /* default refers to itself; not found! */
            hNewThis = hSEObjectNull;
      }
      else
      {
         hNewThis = ( VObject==SEVAR_GET_TYPE(SEOBJECTMEM_VAR(it)) )
                  ? SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(it))
                  : hSEObjectNull;
         SEOBJECTMEM_UNLOCK_R(it);
      }
      if ( hSEObjectNull != hNewThis )
      {
         /* going to try this with a new child object */
         struct VarRecurse myRecurse;

         /* if we've already tried this object then error */
         CHECK_FOR_RECURSION(prev,myRecurse,SEOBJECT_HANDLE(robj))
         if ( ALREADY_BEEN_HERE(myRecurse) )
         {
            callQuit(call,textcorePROTOTYPE_LOOPS);
         }
         else
         {
            /* make the call; return whatever's returned one level down */
            rSEObject rNewThis;
            SEOBJECT_ASSIGN_LOCK_R(rNewThis,hNewThis);
            ret = seobjChildMemberStructRecurse(call,rNewThis,name,&myRecurse);
            SEOBJECT_UNLOCK_R(rNewThis);
         }
      }
   }
   return ret;
}
#endif /* #if defined(SEOBJ_FLAG_BIT) */


   void
seobjSetFunction(struct Call *call,hSEObject hobj,struct Function *func)
{
   wSEObject wobj;
#  if JSE_FUNCTION_LENGTHS==1
      wSEObjectMem len;
      VarName name = STOCK_STRING(length);
      jsebool found;
#  endif

   SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
   SEOBJECT_PTR(wobj)->func = func;

#  if JSE_FUNCTION_LENGTHS==1
      len = seobjNewMember(call,wobj,name,&found);
      SEVAR_INIT_SLONG(SEOBJECTMEM_VAR(len),FUNCTION_PARAM_COUNT(func));
      SEOBJECTMEM_PTR(len)->attributes = jseDontDelete | jseDontEnum | jseReadOnly;
      SEOBJECTMEM_UNLOCK_W(len);
#  endif
   SEOBJECT_UNLOCK_W(wobj);
}


#ifndef NDEBUG
   jsebool NEAR_CALL
sevarIsValid(struct Call *call,rSEVar check)
{
   jsebool onstack = False;
   jseVarType type;

   if( check==NULL )
   {
      DebugPrintf(UNISTR("sevarIsValid failed: check==NULL\n"));
      return False;
   }

#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
      if ( (JSE_POINTER_UINT)check < (JSE_POINTER_UINT)call->Global->growingStack
        || (JSE_POINTER_UINT)check > (JSE_POINTER_UINT)STACK0 )
      {
         if ( (JSE_POINTER_UINT)check >= (JSE_POINTER_UINT)call->Global->growingStack
         &&   (JSE_POINTER_UINT)check < (JSE_POINTER_UINT)(call->Global->growingStack + call->Global->length) )
         {
            /* it is on an unused part of the stack, that is
             * bad.
             */
            DebugPrintf(UNISTR("sevarIsValid failed: unused part of the stack 1\n"));
            return False;
         }
         /* it is not currently on the stack, it must be in
          * memory we have allocated.
          *
          * NYI: add some kind of check against allocated memory
          */
      }
#  else
      if( (JSE_POINTER_UINT)check < (JSE_POINTER_UINT)call->Global->stack
       || (JSE_POINTER_UINT)check > (JSE_POINTER_UINT)STACK0 )
      {
         if ( (JSE_POINTER_UINT)check >= (JSE_POINTER_UINT)call->Global->stack
           && (JSE_POINTER_UINT)check < (JSE_POINTER_UINT)(call->Global->stack + SE_STACK_SIZE) )
         {
            /* it is on an unused part of the stack, that is
             * bad.
             */
            DebugPrintf(UNISTR("sevarIsValid failed: unused part of the stack 2\n"));
            return False;
         }
         /* it is not currently on the stack, it must be in
          * memory we have allocated.
          *
          * NYI: add some kind of check against allocated memory
          */
      }
#  endif
   else
   {
      onstack = True;
   }

   /* validate the contents of the variable */
   switch( type = SEVAR_GET_TYPE(check) )
   {
#     if JSE_COMPACT_LIBFUNCS==1
      case VLibFunc:
         /* VLibFuncs can only be object members, and are expanded if
          * ever used.
          */
         if( onstack )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: VLibFunc onstack\n"));
            return False;
         }
         break;
#     endif

      case VNumber:
      case VNull:
      case VUndefined:
         /* nothing */
         break;
      case VBoolean:
         if( check->data.bool_val!=False && check->data.bool_val!=True )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: VBoolean!=True/False\n"));
            return False;
         }
         break;

      case VString:
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
#     endif
      {
         struct seString *l;

         /* make sure it points to one of our known string data structures */
         for ( l = call->Global->stringdatas; NULL != l; l = l->prev )
         {
            if( l==check->data.string_val.data )
               break;
         }
         if( l==NULL )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: String or Buffer data NULL\n"));
            return False;
         }
         break;
      }

      case VObject:
      {
         hSEObject l = call->Global->all_hobjs;

         /* make sure it points to one of our known string data structures */
         while( l )
         {
            rSEObject robj;
            if( l==check->data.object_val.hobj ) break;
            SEOBJECT_ASSIGN_LOCK_R(robj,l);
            l = SEOBJECT_PTR(robj)->hNext;
            SEOBJECT_UNLOCK_R(robj);
         }
         if( l==hSEObjectNull )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: VObject l==NULL 1\n"));
            return False;
         }

         /* ditto for the saved scope chain object */
         if( check->data.object_val.hSavedScopeChain!=hSEObjectNull )
         {
            l = call->Global->all_hobjs;
            while( l )
            {
               rSEObject robj;
               if( l==check->data.object_val.hSavedScopeChain ) break;
               SEOBJECT_ASSIGN_LOCK_R(robj,l);
               l = SEOBJECT_PTR(robj)->hNext;
               SEOBJECT_UNLOCK_R(robj);
            }
            if( l==hSEObjectNull )
            {
               DebugPrintf(UNISTR("sevarIsValid failed: VObject l==NULL 2\n"));
               return False;
            }
         }
         break;
      }

      case VStorage:
         /* storage is only for stack frames, never for anything else */
         if( onstack==False )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: VStorage onstack\n"));
            return False;
         }
         break;

      case VReference:
      case VReferenceIndex:
      {
         hSEObject l = call->Global->all_hobjs;

         /* make sure it points to one of our known object data structures */
         while( l )
         {
            rSEObject robj;
            if( l==check->data.ref_val.hBase ) break;
            SEOBJECT_ASSIGN_LOCK_R(robj,l);
            l = SEOBJECT_PTR(robj)->hNext;
            SEOBJECT_UNLOCK_R(robj);
         }
         if( l==hSEObjectNull )
         {
            DebugPrintf(UNISTR("sevarIsValid failed: VReference/Index l==NULL\n"));
            return False;
         }
         break;
      }

      default:
         DebugPrintf(UNISTR("sevarIsValid failed: Unknown type %d\n"),type);
         return False;
   }

   return True;
}
#endif

#if (0==JSE_INLINES) || (0!=JSE_MEMEXT_OBJECTS) || (0!=JSE_MEMEXT_MEMBERS)
   void NEAR_CALL
SEVAR_DEREFERENCE(struct Call *call,wSEVar v)
{
   if( v->type==VReferenceIndex )
   {
      rSEObject robj;
      rSEObjectMem rMem;
      SEOBJECT_ASSIGN_LOCK_R(robj,v->data.ref_val.hBase);
      rMem = rseobjIndexMemberStruct(call,robj,
         (MemCountUInt)(JSE_POINTER_UINT)v->data.ref_val.reference);
      SEOBJECT_UNLOCK_R(robj);
      assert( NULL != SEOBJECTMEM_PTR(rMem) );
      SEVAR_COPY(v,SEOBJECTMEM_VAR(rMem));
      SEOBJECTMEM_UNLOCK_R(rMem);
   }
   else if( v->type==VReference )
   {
      wSEVar deref_tmp = STACK_PUSH;
      SEVAR_INIT_OBJECT(deref_tmp,v->data.ref_val.hBase);
      sevarGetValue(call,deref_tmp,v->data.ref_val.reference,v,GV_DEFAULT);
      if( !CALL_QUIT(call) ) STACK_POP;
   }
   assert( v->type<VReference );
}

   jsebool NEAR_CALL
SEVAR_IS_FUNCTION(struct Call *c,rSEVar o)
{
   jsebool ret = False;
   if ( VObject == SEVAR_GET_TYPE(o) )
   {
      rSEObject robj;
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(o));
      if ( NULL != SEOBJECT_PTR(robj)->func )
      {
         ret = True;
      }
      else
      {
         rSEObjectMem rMem;
         rMem = rseobjGetMemberStruct(c,robj,STOCK_STRING(_call));
         if ( NULL != SEOBJECTMEM_PTR(rMem) )
         {
            ret = True;
            SEOBJECTMEM_UNLOCK_R(rMem);
         }
      }
      SEOBJECT_UNLOCK_R(robj);
   }
   return ret;
}
#endif /* #if (0==JSE_INLINES) || (0!=JSE_MEMEXT_OBJECTS) || (0!=JSE_MEMEXT_MEMBERS) */

   void
seobjMakeEcmaArray(struct Call *call,wSEObject wobj)
{
   jsebool found;
   wSEObjectMem wmem;

   SEOBJECT_PTR(wobj)->flags |= IS_ARRAY;

   /* make sure it has a length */
   wmem = seobjNewMember(call,wobj,STOCK_STRING(length),&found);
   SEVAR_INIT_NUMBER(SEOBJECTMEM_VAR(wmem),jseZero);
   SEOBJECTMEM_UNLOCK_W(wmem);
}
