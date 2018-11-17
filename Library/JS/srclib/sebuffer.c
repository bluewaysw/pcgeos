/* sebuffer.c - Implements Nombas' built-in Buffer byte-manipulation object for ECMAScript.
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
#include "globldat.h"

#ifdef JSE_BUFFER_ANY
#if !defined(JSE_BUFFER_OBJECT)
#  error must #define JSE_BUFFER_OBJECT 1 or #define JSE_BUFFER_ALL to use JSE_BUFFER_ANY
#endif

/* constants */
#define  typeSigned    0
#define  typeUnsigned  1
#define  typeFloat     2
/* All of these must be unicode strings */
static CONST_STRING(DATA_MEMBER_NAME,"data");
static CONST_STRING(CURSOR_MEMBER_NAME,"cursor");
static CONST_STRING(SIZE_MEMBER_NAME,"size");
static CONST_STRING(UNICODE_MEMBER_NAME,"unicode");
static CONST_STRING(BIGENDIAN_MEMBER_NAME,"bigEndian");

/* Macros */
#define  GetCursor(obj) (JSE_POINTER_UINDEX)jseGetLong(jsecontext,jseMember(jsecontext,obj,CURSOR_MEMBER_NAME,jseTypeNumber))
#define  GetSize(obj)   (JSE_POINTER_UINDEX)jseGetLong(jsecontext,jseMember(jsecontext,obj,SIZE_MEMBER_NAME,jseTypeNumber))
#define  GetData(obj,size)  jseGetBuffer(jsecontext,jseMember(jsecontext,obj,DATA_MEMBER_NAME,jseTypeBuffer),size)
#define  GetUnicode(obj) jseEvaluateBoolean(jsecontext,jseMember(jsecontext,obj,UNICODE_MEMBER_NAME,jseTypeBoolean))
#define  GetBigEndian(obj) jseEvaluateBoolean(jsecontext,jseMember(jsecontext,obj,BIGENDIAN_MEMBER_NAME,jseTypeBoolean))
#define  SetCursor(obj,value)  jsePutLong(jsecontext,\
            jseMember(jsecontext,obj,CURSOR_MEMBER_NAME,jseTypeNumber),\
            (slong)(value))
#define  SetSize(obj,value)  jsePutLong(jsecontext,\
            jseMember(jsecontext,obj,SIZE_MEMBER_NAME,jseTypeNumber),\
            (slong)(value))
#define  SetDataSize(obj,size) \
   jseSetArrayLengthWithNulls(jsecontext,\
      jseMember(jsecontext,obj,DATA_MEMBER_NAME,jseTypeBuffer),\
      0,\
      (JSE_POINTER_UINDEX)(size))
/* This is more complicated because we must remove the read-only flag from the data member */
#define  GetDataVar(obj)  jseGetMember(jsecontext,obj,DATA_MEMBER_NAME)  /* just for use below */
#define  SetData(obj,buffer,size) \
   jseSetAttributes(jsecontext,GetDataVar(obj),jseGetAttributes(jsecontext,GetDataVar(obj)) & ~jseReadOnly); \
   jsePutBuffer(jsecontext,GetDataVar(obj),buffer,size); \
   jseSetAttributes(jsecontext,GetDataVar(obj),jseGetAttributes(jsecontext,GetDataVar(obj)) | jseReadOnly);

/* This helper function sets the array size, while also filling added memory with NULLS */
static void
jseSetArrayLengthWithNulls(jseContext jsecontext, jseVariable var, JSE_POINTER_SINDEX minIndex,
                           JSE_POINTER_UINDEX length)
{
   JSE_POINTER_UINDEX oldLen;
   const void _HUGE_ *oldBuffer;
   void _HUGE_ *newBuffer;

   jseSetAttributes(jsecontext,var,(jseVarAttributes)(jseGetAttributes(jsecontext,var) &
                                                      ~jseReadOnly));

   oldBuffer = jseGetBuffer(jsecontext,var,&oldLen);

   if( oldLen < length )
   {
      newBuffer = HugeMalloc( length );
      HugeMemSet(newBuffer,'\0',length);
      HugeMemCpy(newBuffer,oldBuffer,oldLen);
      jsePutBuffer(jsecontext,var,newBuffer,length);
      HugeFree( newBuffer );
   }

   jseSetArrayLength(jsecontext,var,minIndex,length);


   jseSetAttributes(jsecontext,var,(jseVarAttributes)(jseGetAttributes(jsecontext,var) | jseReadOnly));
}

/* Function prototypes */
static jsebool isBufferObject( jseContext jsecontext, jseVariable variable );
/*static const void * getBufferFromObject( jseContext jsecontext, jseVariable variable, ulong *size);*/

static jsebool
isBufferObject( jseContext jsecontext, jseVariable variable )
{
   jseVariable  jseClass;

   /* This function assumes that variable is already determined to be an object */
   assert(jseGetType(jsecontext,variable)==jseTypeObject);

   jseClass = jseGetMember(jsecontext,variable,CLASS_PROPERTY);
   if(jseClass == NULL ||
      jseTypeString != jseGetType(jsecontext,jseClass))
      return False;
   if(strcmp_jsechar((jsecharptr )jseGetString(jsecontext,jseClass,NULL),BUFFER_PROPERTY)!=0)
      return False;
   /* Unless someone is toying with us, this should be true */
   assert(jseGetMember(jsecontext,variable,DATA_MEMBER_NAME)!= NULL);
   return True;
}


#if JSE_UNICODE != 1
/* This is an attempt to provide unicode string support on platforms that don't support it */
static void
PseudoAsciiToJsechar(const char * asciiString, uint stringLength, char *unicodeString,jsebool isBigEndian)
{
   /* This function assumes that unicodeString is large enough to hold twice the
    * asciiString's length.
    */
   uint i;
   for(i = 0; i < stringLength; i++ )
   {
      if(isBigEndian)  /* big-endian byte ordering */
      {
         unicodeString[i*2] = '\0';
         unicodeString[i*2+1] = asciiString[i];
      }
      else
      {
         unicodeString[i*2] = asciiString[i];
         unicodeString[i*2+1] = '\0';
      }
   }
}

/* This is probably very wrong but its all we can do
 * Most likely the unicode string was created with PseduoAsciiToJsechar anyways
 */
static void
PseudoJsecharToAscii(const char *unicodeString,char *asciiString,uint size,jsebool isBigEndian)
{
   uint i;
   for(i = 0; i < size; i++ )
   {
      if(isBigEndian)  /* big-endian byte ordering */
         asciiString[i] = unicodeString[i*2+1];
      else
         asciiString[i] = unicodeString[i*2];
   }
}
#endif

static void
CopyMem(ubyte _HUGE_ * mem, ubyte _HUGE_ * dest, uint length, jsebool bigEndian )
{
   ubyte _HUGE_ * src;
   int i;

   /* Because some systems don't have a real float80, we'll pretend here */
#  if !defined(_MSC_VER) && (0!=JSE_FLOATING_POINT)
   if( length == 10 )
      length = sizeof(float80);
#  endif
   /* This little for loop will walk through the bytes MSB to LSB and copy them*/
#  if SE_BIG_ENDIAN == True
   for( src = mem , i = 0; src < mem + length; src++, i++ )
#  elif SE_BIG_ENDIAN == False
   for( src = mem + length - 1, i = 0; src >= mem; src--, i++ )
#  else
#  error Invalid SE_BIG_ENDIAN
#  endif
   {
      if( bigEndian )
         *HugePtrAddition(dest,i) = *src;
      else
         *HugePtrAddition(dest,length - i - 1) = *src;
   }
}

#define SetMem(type,value)  *((type *)mem) = (type) value

static ubyte *
GetMemPointer(jseContext jsecontext, jseVariable jseValue, uint varSize, uword8 varType )
{
   ubyte * mem;

   if( varType == typeUnsigned || varType == typeSigned)
   {
      mem = jseMustMalloc(ubyte,4);
      *((sword32 *)mem) = (sword32) jseGetLong(jsecontext,jseValue);
   }
#  if (0!=JSE_FLOATING_POINT)
   else
   {
#     if !defined(_MSC_VER)
         float80 floatValue = (float80) JSE_FP_CAST_TO_DOUBLE(jseGetNumber(jsecontext,jseValue));
#     else
         float64 floatValue = (float64) JSE_FP_CAST_TO_DOUBLE(jseGetNumber(jsecontext,jseValue));
#     endif
      assert( 0 < varSize );
      mem = jseMustMalloc(ubyte,varSize);
      assert( varType == typeFloat);

      switch( varSize )
      {
         case 4:
            assert( 4 == sizeof(float32) );
            *((float32*)mem) = (float32) floatValue;
            break;
         case 8:
            assert( 8 == sizeof(float64) );
            *((float64*)mem) = (float64) floatValue;
            break;
#     if !defined(_MSC_VER)
         case 10:
            /* assert( 10 == sizeof(float80) ); */

            /* For some reason, float80 values are not necessarily 10 bytes
             * on some systems.  But since virtually no one uses them, we'll
             * just pretend.
             */
            /* First memset() it with null bytes */
            memset(mem,'\0',varSize);
            *((float80*)mem) = (float80) floatValue;
            break;
#     endif
         default:
            assert(False);
            break;
      }

   }
#  endif /* 0!=JSE_FLOATING_POINT */

   return mem;
}


/* This will actually put a value into an object
 * Called by jsePutValue as well as jseBufferPut
 */
static void PutValueInBuffer(jseContext jsecontext, jseVariable thisVar, jseVariable jseValue, uint varSize, uword8 varType)
{
   jsebool bigEndian;
   jseVariable dataMember;
   void * buffer;
   JSE_POINTER_UINDEX bufferSize;
   JSE_POINTER_UINDEX cursor;
   ubyte * mem;

   bigEndian = GetBigEndian(thisVar);
   bufferSize = GetSize(thisVar);
   cursor = GetCursor(thisVar);

   /* This would cause our buffer to be extended beyond the end, so resize */
   if( cursor + varSize > bufferSize )
   {
      SetSize(thisVar,(slong)(cursor+varSize));
         /* This can be called from within put(), so we have to explicitly set the buffer length */
      SetDataSize(thisVar,cursor+varSize);
   }

   dataMember = jseGetMemberEx(jsecontext,thisVar,DATA_MEMBER_NAME,jseCreateVar);
   assert( dataMember != NULL );
   jseSetAttributes(jsecontext,dataMember,(jseVarAttributes)(jseGetAttributes(jsecontext,dataMember) &
                                                      ~jseReadOnly));

   buffer = jseGetWriteableBuffer(jsecontext,
                                  jseGetMember(jsecontext,thisVar,DATA_MEMBER_NAME),
                                  &bufferSize);
   assert(bufferSize==GetSize(thisVar));


   /* Fetch a pointer to this value */
   mem = GetMemPointer(jsecontext,jseValue,varSize,varType);
   /* This little for loop will walk through the bytes MSB to LSB */
   if( varType == typeFloat )
   {
      if( 10 == varSize )
         HugeMemSet((ubyte _HUGE_ *)buffer+cursor,'\0',varSize);
      CopyMem(mem,(ubyte _HUGE_ *)buffer + cursor,varSize,bigEndian);
   }
   else
#  if SE_BIG_ENDIAN == True
      CopyMem(mem + 4 - varSize,(ubyte _HUGE_ *)buffer + cursor,varSize,bigEndian);
#  else
      CopyMem(mem,(ubyte _HUGE_ *)buffer + cursor,varSize,bigEndian);
#  endif
   /* Free the memory allocated in GetMemPointer */
   jseMustFree(mem);
   /* Set the buffer and update the cursor */
   jsePutBuffer(jsecontext,dataMember,buffer,bufferSize);
   SetCursor(thisVar,(slong)(cursor + varSize));

   jseSetAttributes(jsecontext,dataMember,(jseVarAttributes)(jseGetAttributes(jsecontext,dataMember) | jseReadOnly));
      /* Restore read only */
   jseDestroyVariable(jsecontext,dataMember);
}

/* Get a variable from a buffer
 * Called by jseGetValue and jseBufferGet
 */
static void
GetValueFromBuffer(jseContext jsecontext, jseVariable thisVar, uint varSize, uword8 varType)
{
   const void * buffer;
   ubyte _HUGE_ * mem;
   sword32   signedValue = 0;
   uword32   unsignedValue = 0;
#  if (0!=JSE_FLOATING_POINT)

   float32   floatValue32;
   float64   floatValue64;
#     if !defined(_MSC_VER)
         float80   floatValue80;
#     endif
#  endif
   ulong cursor = (ulong) GetCursor(thisVar);
   jseVariable jseValue = jseCreateVariable(jsecontext,jseTypeNumber);
   jsebool bigEndian = GetBigEndian(thisVar);

   if( cursor + varSize > (ulong)GetSize(thisVar) )
      SetSize(thisVar,cursor+varSize);

   buffer = GetData(thisVar,NULL);
   mem = (ubyte _HUGE_ *) buffer + cursor;

   if( varType == typeSigned )
   {
      if( (varSize != 4) &&
          ((bigEndian && (mem[0] & 0x80)) ||
           (!bigEndian && (mem[varSize-1] & 0x80))) )   /* This is is a signed value (I think) */
      {
         memset((ubyte*)&signedValue,0xFF,4);
      }
#  if SE_BIG_ENDIAN == True
      CopyMem(mem,HugePtrAddition(&signedValue,4 - varSize),varSize,bigEndian);
#  else
      CopyMem(mem,HugePtrAddition(&signedValue,0),varSize,bigEndian);
#  endif
      /* Signed values are more difficult to handle */
      jsePutLong(jsecontext,jseValue,signedValue);
   }
   else if ( varType == typeUnsigned )
   {
#  if SE_BIG_ENDIAN == True
      CopyMem(mem,(ubyte _HUGE_ *)&unsignedValue + 4 - varSize,varSize,bigEndian);
#  else
      CopyMem(mem,(ubyte _HUGE_ *)&unsignedValue,varSize,bigEndian);
#  endif
      jsePutLong(jsecontext,jseValue,(slong)unsignedValue);
   }
#  if (0!=JSE_FLOATING_POINT)
   else if( varType == typeFloat )
   {
      switch(varSize)
      {
         case 4:
            assert( 4 == sizeof(floatValue32) );
            CopyMem(mem,(ubyte _HUGE_ *)&floatValue32,varSize,bigEndian);
            jsePutNumber(jsecontext,jseValue,JSE_FP_CAST_FROM_DOUBLE(floatValue32));
            break;
         case 8:
            assert( 8 == sizeof(floatValue64) );
            CopyMem(mem,(ubyte _HUGE_ *)&floatValue64,varSize,bigEndian);
            jsePutNumber(jsecontext,jseValue,JSE_FP_CAST_FROM_DOUBLE(floatValue64));
            break;
#        if !defined(_MSC_VER)
         case 10:
            CopyMem(mem,(ubyte _HUGE_ *)&floatValue80,varSize,bigEndian);
            jsePutNumber(jsecontext,jseValue,JSE_FP_CAST_FROM_DOUBLE(floatValue80));
            break;
#        endif
         default:
            assert(False);
      }
   }
#  endif /* 0!=JSE_FLOATING_POINT */

   SetCursor(thisVar,cursor+varSize);
   jseReturnVar(jsecontext,jseValue,jseRetTempVar);
}

#  if SE_BIG_ENDIAN == True
#  define BIG_ENDIAN_TEST(bigEndian) !bigEndian
#  elif SE_BIG_ENDIAN == False
#  define BIG_ENDIAN_TEST(bigEndian) bigEndian
#  else
#  error Invalid SE_BIG_ENDIAN
#  endif

#if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
   const jsecharptr NEAR_CALL
REV_UNICODE(const jsecharptr unicode_string,int length,jsebool bigEndian)
{
   jsecharptr new_string;
   if( BIG_ENDIAN_TEST(bigEndian) )
   {
      int k;
      new_string = jseMustMalloc(jsechar,(sizeof(jsechar)*length)+1/* avoid allocating 0 bytes */);
      memcpy((void *)new_string,(const void *)unicode_string,sizeof(jsechar)*length);
      for ( k = length - 1; k -= 2;  )
      {
         ubyte tempchar = ((ubyte *)new_string)[k];
         ((ubyte *)new_string)[k] = ((ubyte *)new_string)[k+1];
         ((ubyte *)new_string)[k+1] = tempchar;
      }
   }
   else
   {
      new_string = (jsecharptr )unicode_string;
   }
   return (const jsecharptr )new_string;
}

   static void NEAR_CALL
FREE_REV_UNICODE(const jsecharptr unicode_string,jsebool bigEndian)
{
   if( BIG_ENDIAN_TEST(bigEndian) )
      jseMustFree((void *)unicode_string);
}
#endif

/* Puts a string into the buffer
 * Called by constructor, jsePutString
 * See notes below on interaction of length / useCursor
 * This function WILL stretch the buffer to accomodate the string
 */
static void
PutStringInBuffer(jseContext jsecontext, jseVariable thisVar, const jsecharptr string,
                  JSE_POINTER_UINDEX stringLength, int *theLength, jsebool useCursor)
{
   jsebool unicode = GetUnicode(thisVar);
   jsebool bigEndian = GetBigEndian(thisVar);
   ulong size = GetSize(thisVar);
   void _HUGE_ * data, *originalData;
   sint length;
   ulong cursor = GetCursor(thisVar);
#  if JSE_UNICODE == 1
      const char * asciiString = NULL;
#  endif
   JSE_POINTER_UINDEX bufferLength;
   jseVariable dataMember;

   if( theLength != NULL )
      length = *theLength;
   else
      length = -1;

   if( !useCursor )
      cursor = 0;

   if( length < 0 )
      length = (sint) stringLength;

#  if JSE_UNICODE == 1
   if( unicode )   /* Unicode to Ascii - halve the length */
      length *= sizeof(jsechar);
#  else
   if( unicode )    /* Ascii to Unicode - double the length */
      length *= 2;
#  endif

   if( theLength != NULL )
      *theLength = length;

   if( cursor + length > size )
   {
      SetSize(thisVar,cursor+length);  /* This can be called from within put(), so these must be done explicitly */
      SetDataSize(thisVar,cursor+length);
   }

   assert( GetSize(thisVar) >= (useCursor ? (cursor + length) : length) );
   dataMember = jseGetMemberEx(jsecontext,thisVar,DATA_MEMBER_NAME,jseCreateVar);
   assert( dataMember != NULL );
   jseSetAttributes(jsecontext,dataMember,(jseVarAttributes)(jseGetAttributes(jsecontext,dataMember) &
                                                      ~jseReadOnly));
   data = jseGetWriteableBuffer(jsecontext,jseGetMember(jsecontext,thisVar,DATA_MEMBER_NAME),&bufferLength);
   assert(bufferLength == GetSize(thisVar));

   originalData = data;
   if(useCursor)
      data = (void _HUGE_ *)HugePtrAddition(data,cursor);

#  if JSE_UNICODE == 1
   if( unicode )   /* Unicode to Unicode */
   {
      const jsecharptr fromStr = REV_UNICODE(string,length/sizeof(jsechar),bigEndian);
      memcpy(data,(const void *)fromStr,length);
      FREE_REV_UNICODE(fromStr,bigEndian);
   }
   else            /* Unicode to Ascii */
   {
      asciiString = JsecharToAscii(string);
      memcpy(data,(void *)asciiString,length);
      FreeAsciiString(asciiString);
   }
#  else
   if( unicode )   /* Ascii to Unicode */
   {
      jsecharptr writeableString;
      writeableString = jseMustMalloc(jsecharptrdatum,(size_t)(length)+1/* avoid allocating 0 bytes */);
      PseudoAsciiToJsechar(string,(uint)(length/2),writeableString,bigEndian);
      memcpy(data,(void *)writeableString,(size_t)length);
      jseMustFree(writeableString);
   }
   else            /* Ascii to Ascii */
   {
      memcpy(data,(void *)string,(size_t)length);
   }
#endif
   /* Put buffer back in */
   jsePutBuffer(jsecontext,dataMember,originalData,bufferLength);
   jseSetAttributes(jsecontext,dataMember,(jseVarAttributes)(jseGetAttributes(jsecontext,dataMember) | jseReadOnly));
   jseDestroyVariable(jsecontext,dataMember);
}

/* Gets a string from the buffer
 * Note that it returns a jseVariable, not a real string
 *   If useCursor is true, then the string is taken from the current cursor position, of the specified length, but the
 *   cursor is NOT updated afterwards.  If useCursor is false, then the string is the entire buffer, and length is
 *   ignored.
 * Upon exiting, length refers to the actual number of bytes read, unless it was null.  This is for updating the
 *   cursor
 */
static jseVariable
GetStringFromBuffer(jseContext jsecontext, jseVariable thisVar, sint *theLength, jsebool useCursor)
{
   jsebool unicode = GetUnicode(thisVar);
   jsebool bigEndian = GetBigEndian(thisVar);
   JSE_POINTER_UINDEX size;
   sint length;
   const void _HUGE_ * data = GetData(thisVar,&size);
   ulong cursor = GetCursor(thisVar);
#  if JSE_UNICODE == 1
      const jsecharptr data_string = NULL;
#  endif
   jseVariable jseString = jseCreateVariable(jsecontext,jseTypeString);

   if( theLength == NULL )
      length = -1;
   else
      length = *theLength;

   if( useCursor )
      data = (const void _HUGE_ *)HugePtrAddition(data,cursor);
   else
      length = (sint)size;

   /* if length is less than 0, that means we must read until the end of the buffer or until a null byte is encountered */
   if( length < 0 )
   {
      int i;
      /* First we assume until the end of the buffer */
      length = (sint)size;
      for( i = 0; i < length; i++ )
      {
         if( unicode )
         {
            if( ((ubyte*)data)[i] == '\0' && ((ubyte*)data)[i+1] == '\0' )   /* A unicode null byte */
            {
               length = i;
               break;
            }
            i++;
         }
         else
         {
            if( ((ubyte*)data)[i] == '\0' )  /* Ascii null byte */
            {
               length = i;
               break;
            }
         }
      }
   }
   else if( unicode && useCursor)
      length *= 2;

   /* Adjust size */
   if( (useCursor ? cursor + length : length) > size )
   {
      SetSize(thisVar,(useCursor ? (cursor + length) : length));
      SetDataSize(thisVar,(useCursor ? (cursor + length) : length));
      data = GetData(thisVar,&size);
      if( useCursor )
         data = (const void _HUGE_ *)HugePtrAddition(data,cursor);
   }


   assert(size >= (useCursor ? (cursor + length) : length) );

#  if JSE_UNICODE == 1
   if( unicode )   /* Unicode to Unicode */
   {
      data_string = REV_UNICODE(data,length,bigEndian);
      jsePutStringLength(jsecontext,jseString,data_string,length/sizeof(jsechar));
      FREE_REV_UNICODE(data_string,bigEndian);
   }
   else
   {               /* Ascii to Unicode */
      data_string = AsciiLenToJsechar((char *)data,length);
      jsePutStringLength(jsecontext,jseString,data_string,length);
      FreeJsecharString(data_string);
   }
#  else
   if( unicode )   /* Unicode to Ascii */
   {
      jsecharptr string;
      string = jseMustMalloc(char,(size_t)(length/2)+1/* avoid allocating 0 bytes */);
      PseudoJsecharToAscii((const char *)data,string,(uint)(length/2),bigEndian);
      jsePutStringLength(jsecontext,jseString,string,(uint)(length/2));
      jseMustFree(string);
   }
   else
   {               /* Ascii to Ascii */
      jsePutStringLength(jsecontext,jseString,(char *)data,(JSE_POINTER_UINDEX)length);
   }
#  endif

   if( theLength != NULL )
      *theLength = length;

   return jseString;
}

static jsebool isNumber(jsecharptr _string)
{
   while( JSECHARPTR_GETC(_string) != '\0' )
   {
      if(!isdigit_jsechar(JSECHARPTR_GETC(_string)))
      {
         return False;
      }
      JSECHARPTR_INC(_string);
   }
   return True;
}

#if defined(JSE_BUFFER_GETVALUE) || defined(JSE_BUFFER_PUTVALUE)
/* This function gets the varType and varSize parameters to the function
 * It is defined as a separate function because the code is common to both
 * getValue and putValue
 */
static jsebool
GetVarParameters(jseContext jsecontext, uint firstparam, uint *varSize,
                 uword8 *varType)
{
   jseVariable tempVar;
   slong      size = 0;
   jsebool   gotSize = False;
   const jsecharptr type = NULL;

   *varSize = 1;
   *varType = typeSigned;

   if( jseFuncVarCount(jsecontext) > firstparam )
   {
      tempVar = jseFuncVarNeed(jsecontext,firstparam,JSE_VN_NUMBER);
      if( tempVar == NULL )
         return False;

      size = jseGetLong(jsecontext,tempVar);
      gotSize = True;
   }

   if( jseFuncVarCount(jsecontext) > firstparam+1 )
   {
      tempVar = jseFuncVarNeed(jsecontext,firstparam+1,JSE_VN_STRING);
      if( tempVar == NULL )
         return False;
      type = (const jsecharptr )jseGetString(jsecontext,tempVar,NULL);
   }

   /* OK we now have our two parameters, size and type.
    * gotSize will tell us if we need to check the size, if type is not null
    * then we need to check that as well
    */
   if( gotSize )
   {
      if( size != 1 && size != 2 && size != 3 && size != 4 && size != 8
#  if !defined(_MSC_VER)
          && size != 10
#  endif
        )
      {
         /* Print error message */
         jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibBAD_BUFFER_VARSIZE));
         return False;
      }
      *varSize = (uint) size;
   }

   if( type != NULL )
   {
      if( strcmp_jsechar(type,UNISTR("unsigned")) == 0 )
         *varType = typeUnsigned;
#if (0!=JSE_FLOATING_POINT)
      else if ( strcmp_jsechar(type,UNISTR("float")) == 0 )
         *varType = typeFloat;
#endif
      else if ( strcmp_jsechar(type,UNISTR("signed")) == 0 )
         *varType = typeSigned;
      else
      {
         /* Print error message */
         jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibBAD_BUFFER_VARTYPE));
         return False;
      }
   }

   /* We now have the real varType and varSize, and we must check to make sure
    * they are compatible
    */
   switch( *varType )
   {
      case typeSigned:
      case typeUnsigned:
         /* Integers.  Only values less than 4 bytes (a long) are acceptable */
         if( *varSize > 4 )
         {
            /* Print error message */
            jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibBAD_BUFFER_VARCOMBO));
            return False;
         }
         break;
#     if (0!=JSE_FLOATING_POINT)
      case typeFloat:
         /* Floating point value.  Only acceptable values are 4,8, and 10 */
         if( *varSize != 4 && *varSize != 8 && *varSize != 10 )
         {
            /* Print error message */
            jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibBAD_BUFFER_VARCOMBO));
            return False;
         }
         break;
#     endif
      default:
         assert(False);
   }

   /* Finally.  Everything should be right now */
   return True;
}
#endif /* #if defined(JSE_BUFFER_GETVALUE) || defined(JSE_BUFFER_PUTVALUE) */

static jseLibFunc(BufferPut)
{
   jseVariable  thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable  jseName, jseValue;
   jsecharptr name;
   slong value;

   JSE_FUNC_VAR_NEED(jseName,jsecontext,0,JSE_VN_STRING);
   jseValue = jseFuncVar(jsecontext,1);
   if( jseValue == NULL )
      return;

   name = (jsecharptr )jseGetString(jsecontext,jseName,NULL);

   /* Setup 'length' as an alias for 'size' so they mean the same thing */
   if( !strcmp_jsechar(name,LENGTH_PROPERTY) )
      name = (jsecharptr)SIZE_MEMBER_NAME;

   if( !strcmp_jsechar((jsecharptr)CURSOR_MEMBER_NAME,name) )  /* We're setting the cursor */
   {
      if (!jseVarNeed(jsecontext,jseValue,JSE_VN_NUMBER))
         return;
      value = jseGetLong(jsecontext,jseValue);
      if( value < 0 )
         value = 0;
      /* User is walking beyond the edge of the buffer, stretch to accomodate it */
      if( (ulong)value > GetSize(thisVar) )
      {
         SetSize(thisVar,value);
         SetDataSize(thisVar,value);
      }
      SetCursor(thisVar,value);
   }
   else if( !strcmp_jsechar((jsecharptr)SIZE_MEMBER_NAME,name) )
   {
      if(!jseVarNeed(jsecontext,jseValue,JSE_VN_NUMBER))
         return;
      value = jseGetLong(jsecontext,jseValue);
      if( value < 0 )
         value = 0;
      /* The user is setting the size to something less than the current cursor */
      if( GetCursor(thisVar) >= (ulong)value )
         SetCursor(thisVar,value);
      SetDataSize(thisVar,value);
      SetSize(thisVar,value);
   }
   else if( !strcmp_jsechar((jsecharptr)UNICODE_MEMBER_NAME,name) ||
            !strcmp_jsechar((jsecharptr)BIGENDIAN_MEMBER_NAME,name) )
   {
      /* We should ensure the type for these two variables */
      if(!jseVarNeed(jsecontext,jseValue,JSE_VN_CONVERT(JSE_VN_NUMBER|JSE_VN_BOOLEAN,JSE_VN_BOOLEAN)))
         return;
      jsePutBoolean(jsecontext,jseMember(jsecontext,thisVar,name,jseTypeBoolean),
                    jseEvaluateBoolean(jsecontext,jseValue));
   }
   else if( isNumber(name) )
   {
      slong pos = atoi_jsechar(name);
      if(pos < 0)
         pos = 0;
      if( pos < 0 )
         pos = 0;
      /* User is walking beyond the edge of the buffer, stretch to accomodate it */
      if( (ulong)pos > GetSize(thisVar) )
      {
         SetDataSize(thisVar,pos);
         SetSize(thisVar,pos);
      }
      SetCursor(thisVar,pos);

      if (!jseVarNeed(jsecontext,jseValue,JSE_VN_NUMBER))
         return;
      PutValueInBuffer(jsecontext,thisVar,jseValue,1,typeSigned);
   }
   else
   {
      jseVariable  theMember;
      /* This should handle all of the other cases */
      theMember = jseMember(jsecontext,thisVar,name,jseTypeUndefined);
      jseAssign(jsecontext,theMember,jseValue);
   }
}

static jseLibFunc(BufferGet)
{
   jseVariable  thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable  jseName, /*jsePrototype,*/ theMember;
   jsecharptr name;

   JSE_FUNC_VAR_NEED(jseName,jsecontext,0,JSE_VN_STRING);
   name = (jsecharptr )jseGetString(jsecontext,jseName,NULL);

   /* Setup 'length' and 'size' to be the same thing */
   if( 0 == strcmp_jsechar(name,LENGTH_PROPERTY) )
      name = (jsecharptr)SIZE_MEMBER_NAME;

   if( isNumber(name) )
   {
      slong pos = atoi_jsechar(name);
      if(pos < 0)
         pos = 0;
      if( pos < 0 )
         pos = 0;
      /* User is walking beyond the edge of the buffer, stretch to accomodate it */
      SetCursor(thisVar,pos); /* put() will adjust sizes */

      /* Call GetValueFromBuffer */
      GetValueFromBuffer(jsecontext,thisVar,1,typeSigned);
   }
   else
   {
      /* First we search the object - jseMember doesn't support _prototype*/
      theMember = jseGetMemberEx(jsecontext,thisVar,name,jseLockRead);
      if( theMember == NULL )
      {
          /* Now we create it */
         theMember = jseMemberEx(jsecontext,thisVar,name,jseTypeUndefined,
                                 jseLockRead);
      }
      jseReturnVar(jsecontext, theMember,jseRetKeepLVar);
   }
}

static jseVariable BuildBufferObject( jseContext jsecontext )
{
   jseVariable jseParameter, jseUnicode, jseBigEndian, tempVar;
   uint varCount;
   jsebool isUnicode = False;
   jsebool isBigEndian = SE_BIG_ENDIAN;
   JSE_POINTER_UINDEX   size = 0;
   const jsecharptr fromString = NULL;
   const void _HUGE_ * fromBuffer = NULL;
   jseVariable bufferObject;
/*    ulong cursor;*/

   varCount = jseFuncVarCount(jsecontext);
   if( varCount > 0 )
   {
      jseDataType parameterType;
      jseParameter = jseFuncVarNeed(jsecontext,0,JSE_VN_STRING | JSE_VN_NUMBER |
                                                  JSE_VN_OBJECT | JSE_VN_BUFFER);
      if(jseParameter==NULL)
         return NULL;
      parameterType = jseGetType(jsecontext,jseParameter);

      /* First we check for unicode / bigEndian, since its the same for both versions */
      if ( varCount == 3 )  /* bigEndian */
      {
         jseBigEndian = jseFuncVarNeed(jsecontext,2,JSE_VN_BOOLEAN);
         if(jseBigEndian == NULL)
             return NULL;
         isBigEndian = jseEvaluateBoolean(jsecontext,jseBigEndian);
      }
      if ( varCount >= 2 )  /* unicode   */
      {
         jseUnicode = jseFuncVarNeed(jsecontext,1,JSE_VN_BOOLEAN);
         if(jseUnicode == NULL)
            return NULL;
         isUnicode = jseEvaluateBoolean(jsecontext,jseUnicode);
      }
      /* Now we branch according to the type of the first parameter */
      switch( parameterType )
      {
         case jseTypeString:   /* String - set fromString */
            fromString = (const jsecharptr )jseGetString(jsecontext,jseParameter,&size);
            break;
         case jseTypeBuffer:
            fromBuffer = jseGetBuffer(jsecontext,jseParameter,&size);
            break;
         case jseTypeNumber:
            if ( jseGetLong(jsecontext,jseParameter) < 0 )
               size = 0;
            else
               size = (JSE_POINTER_UINDEX) jseGetLong(jsecontext,jseParameter);
            break;
         case jseTypeObject:
            if ( isBufferObject(jsecontext,jseParameter) )
            {
               fromBuffer = GetData(jseParameter,&size);
               size = GetSize(jseParameter);
               /*cursor = */ /*GetCursor(jseParameter);*/
               isBigEndian = GetBigEndian(jseParameter);
               isUnicode = GetUnicode(jseParameter);
            }
            else
            {
               /* Print an error message */
               jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibBAD_BUFFER_OBJECT));
               return NULL;
            }
            break;
         default:
            assert(False);
      }
   }

   /* Alright.  Now we have all are parameters read in and we're ready to start constructing */

   /* This function will create the new object and add all the members of the prototype property */
   bufferObject = CreateNewObject(jsecontext,BUFFER_PROPERTY);

   /* Add our members */
   tempVar = jseMember(jsecontext,bufferObject,CURSOR_MEMBER_NAME,jseTypeNumber);        /* cursor */
   jsePutLong(jsecontext,tempVar,0);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete|jseDontEnum);

   tempVar = jseMember(jsecontext,bufferObject,SIZE_MEMBER_NAME,jseTypeNumber);            /* size */
   jsePutLong(jsecontext,tempVar,(slong)size);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete|jseDontEnum);

   tempVar = jseMember(jsecontext,bufferObject,UNICODE_MEMBER_NAME,jseTypeBoolean);     /* unicode */
   jsePutBoolean(jsecontext,tempVar,isUnicode);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete|jseDontEnum);

   tempVar = jseMember(jsecontext,bufferObject,BIGENDIAN_MEMBER_NAME,jseTypeBoolean); /* bigEndian */
   jsePutBoolean(jsecontext,tempVar,isBigEndian);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete|jseDontEnum);

   tempVar = jseMember(jsecontext,bufferObject,DATA_MEMBER_NAME,jseTypeBuffer);            /* data */
   jseSetArrayLengthWithNulls(jsecontext,tempVar,0,size);

   /* We must and "get" and "put" directly */
   jseMemberWrapperFunction(jsecontext,bufferObject,GET_PROPERTY,BufferGet,1,-1,jseDontEnum,jseFunc_PassByReference,NULL);
   jseMemberWrapperFunction(jsecontext,bufferObject,PUT_PROPERTY,BufferPut,2,2,jseDontEnum,jseFunc_PassByReference,NULL);

   /* Now we must look at fromString and fromBuffer to see if we need to convert at all */

   /* Yes tempVar still points to this, but just in case... */
   tempVar = jseMember(jsecontext,bufferObject,DATA_MEMBER_NAME,jseTypeBuffer);
   jseSetAttributes(jsecontext,tempVar,
                    (jseVarAttributes)(jseGetAttributes(jsecontext,tempVar) & ~jseReadOnly));
      /* Turn off read only */

   if( fromString != NULL )  /* We are converting from a string */
   {
      sint newSize = (sint) size;
      PutStringInBuffer(jsecontext,bufferObject,fromString,size,&newSize,False);
      if( newSize != (sint)size )
         SetSize(bufferObject,newSize);
   }
   else if (fromBuffer != NULL)   /* We are converting from a buffer */
      jsePutBuffer(jsecontext,tempVar,fromBuffer,size);

   jseSetAttributes(jsecontext,tempVar,(jseVarAttributes)(jseGetAttributes(jsecontext,tempVar) | jseReadOnly|jseDontEnum));
      /* Restore read only */

   return bufferObject;   /* Finally, we return the object */
}


/* Buffer constructor
 * Buffer( [size] [, unicode] [, bigEndian] );
 * Buffer( string [, unicode] [, bigEndian] );
 * Buffer( buffer [, unicode] [, bigEndian] );
 * Buffer( bufferObject );
 */
static jseLibFunc(BufferConstruct)
{
   jseVariable returnVar = BuildBufferObject(jsecontext);
   if( returnVar == NULL )
      return;
   jseReturnVar(jsecontext,returnVar,jseRetTempVar);
}

static jseLibFunc(BufferCall)
{
   jseVariable object = BuildBufferObject(jsecontext);
   if( object != NULL )
   {
      /* We just want to return the data portion of the variable */
      jseVariable retVar = jseCreateVariable(jsecontext,jseTypeBuffer);
      jseVariable data = jseGetMember(jsecontext,object,DATA_MEMBER_NAME);
      assert(data != NULL);
      jseAssign(jsecontext,retVar,data);
      jseDestroyVariable(jsecontext,object);
      jseReturnVar(jsecontext,retVar,jseRetTempVar);
   }
}


/* 'builtin' Buffer constructor. */
static jseLibFunc(BuiltinBufferConstruct)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,BUFFER_PROPERTY),jseRetTempVar);
}

#if defined(JSE_BUFFER_PUTVALUE)
static jseLibFunc(Ecma_Buffer_putValue)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseValue;
   uint  varSize;
   uword8 varType;

   if( !GetVarParameters(jsecontext,1,&varSize,&varType ) )
      return;
   assert( varSize > 0 );

   JSE_FUNC_VAR_NEED(jseValue,jsecontext,0,JSE_VN_NUMBER);
   PutValueInBuffer(jsecontext,thisVar,jseValue,varSize,varType);
}
#endif /* #if defined(JSE_BUFFER_PUTVALUE) */

#if defined(JSE_BUFFER_GETVALUE)
static jseLibFunc(Ecma_Buffer_getValue)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   uint varSize;
   uword8 varType;

   if( !GetVarParameters(jsecontext,0,&varSize,&varType) )
      return;
   assert( varSize > 0 );

   GetValueFromBuffer(jsecontext,thisVar,varSize,varType);
}
#endif /* #if defined(JSE_BUFFER_GETVALUE) */

#if defined(JSE_BUFFER_PUTSTRING)
static jseLibFunc(Ecma_Buffer_putString)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   ulong cursor = GetCursor(thisVar);
   jseVariable stringVar, lengthVar;
   const jsecharptr theString;
   sint length = -1;
   JSE_POINTER_UINDEX  stringLength;

   JSE_FUNC_VAR_NEED(stringVar,jsecontext,0,JSE_VN_STRING);
   if( jseFuncVarCount(jsecontext) == 2)
   {
      JSE_FUNC_VAR_NEED(lengthVar,jsecontext,1,JSE_VN_NUMBER);
      length = (sint)jseGetLong(jsecontext,lengthVar);
   }
   theString = (const jsecharptr )jseGetString(jsecontext,stringVar,&stringLength);

   PutStringInBuffer(jsecontext,thisVar,theString,stringLength,&length,True);
   SetCursor(thisVar,cursor+length);
}
#endif /* #if defined(JSE_BUFFER_PUTSTRING) */

#if defined(JSE_BUFFER_GETSTRING)
static jseLibFunc(Ecma_Buffer_getString)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   ulong cursor = GetCursor(thisVar);
   jseVariable stringVar, lengthVar;
   sint length = -1;

   if( jseFuncVarCount(jsecontext) == 1)
   {
      JSE_FUNC_VAR_NEED(lengthVar,jsecontext,0,JSE_VN_NUMBER);
      length = (sint)jseGetLong(jsecontext,lengthVar);
   }
   stringVar = GetStringFromBuffer(jsecontext,thisVar,&length,True);
   SetCursor(thisVar,cursor+length);
   jseReturnVar(jsecontext,stringVar,jseRetTempVar);
}
#endif /* #if defined(JSE_BUFFER_GETSTRING) */

#if defined(JSE_BUFFER_TOSTRING)
static jseLibFunc(Ecma_Buffer_toString)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable stringVar;

   stringVar = GetStringFromBuffer(jsecontext,thisVar,NULL,False);  /* Get the entire buffer */
   jseReturnVar(jsecontext,stringVar,jseRetTempVar);
}
#endif /* #if defined(JSE_BUFFER_TOSTRING) */


#if defined(JSE_BUFFER_TOSOURCE)
static jseLibFunc(Ecma_Buffer_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable stringVar;
   struct dynamicBuffer buffer, escapedBuffer;
   const jsecharptr string;
   JSE_POINTER_UINDEX length;

   stringVar = GetStringFromBuffer(jsecontext,thisVar,NULL,False);  /* Get the entire buffer */

   dynamicBufferInit(&buffer);

   dynamicBufferAppend(&buffer,UNISTR("new Buffer(\""));

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
#endif /* #if defined(JSE_BUFFER_TOSOURCE) */


#if defined(JSE_BUFFER_SUBBUFFER)
/* Creates a sub-buffer from the current buffer */
static jseLibFunc(Ecma_Buffer_subBuffer)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseStart, jseEnd, tempVar;
   jseVariable bufferObject;
   JSE_POINTER_SINDEX start, end;
   JSE_POINTER_UINDEX size, length, cursor;
   void _HUGE_ * buffer;

   if( jseFuncVarCount(jsecontext) > 0 )
   {
      JSE_FUNC_VAR_NEED(jseStart,jsecontext,0,JSE_VN_NUMBER);
      start = (JSE_POINTER_SINDEX)jseGetLong(jsecontext,jseStart);
   }
   else
      start = 0;

   if( jseFuncVarCount(jsecontext) > 1 )
   {
      JSE_FUNC_VAR_NEED(jseEnd,jsecontext,1,JSE_VN_NUMBER);
      end = (JSE_POINTER_SINDEX)jseGetLong(jsecontext,jseEnd);
   }
   else
      end = (JSE_POINTER_SINDEX) GetSize(thisVar);

   if( start < 0 )
      start = (JSE_POINTER_SINDEX)(GetSize(thisVar) + start);
   if( end < 0 )
      end = (JSE_POINTER_SINDEX)(GetSize(thisVar) + end);

   if( start > end )
      end = start;

   size = (JSE_POINTER_UINDEX)(end - start);
   cursor = GetCursor(thisVar);
   if( (JSE_POINTER_SINDEX)cursor < start )
      cursor = (JSE_POINTER_UINDEX) start;
   if( (JSE_POINTER_SINDEX)cursor > end )
      cursor = (JSE_POINTER_UINDEX) end;
   cursor -= (JSE_POINTER_UINDEX) start;  /* We convert it relative to the new buffer */

   /* This function will create the new object and add all the members of the prototype property */
   bufferObject = CreateNewObject(jsecontext,BUFFER_PROPERTY);

   /* Add our members */
   tempVar = jseMember(jsecontext,bufferObject,CURSOR_MEMBER_NAME,jseTypeNumber);        /* cursor */
   jsePutLong(jsecontext,tempVar,(slong)cursor);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete);

   tempVar = jseMember(jsecontext,bufferObject,SIZE_MEMBER_NAME,jseTypeNumber);            /* size */
   jsePutLong(jsecontext,tempVar,(slong)size);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete);

   tempVar = jseMember(jsecontext,bufferObject,UNICODE_MEMBER_NAME,jseTypeBoolean);     /* unicode */
   jsePutBoolean(jsecontext,tempVar,GetUnicode(thisVar));
   jseSetAttributes(jsecontext,tempVar,jseDontDelete);

   tempVar = jseMember(jsecontext,bufferObject,BIGENDIAN_MEMBER_NAME,jseTypeBoolean); /* bigEndian */
   jsePutBoolean(jsecontext,tempVar,GetBigEndian(thisVar));
   jseSetAttributes(jsecontext,tempVar,jseDontDelete);

   tempVar = jseMember(jsecontext,bufferObject,DATA_MEMBER_NAME,jseTypeBuffer);            /* data */
   jseSetArrayLength(jsecontext,tempVar,0,size);

   buffer = HugeMalloc(size+1/* avoid allocating 0 bytes */);
   HugeMemSet(buffer,'\0',size);
   if( (ulong)start < GetSize(thisVar) )
   {
      if( (JSE_POINTER_UINDEX)end > GetSize(thisVar) )
         length = GetSize(thisVar) - start;
      else
         length = (JSE_POINTER_UINDEX) (end - start);
      assert( size >= length );
      HugeMemCpy(buffer,HugePtrAddition(GetData(thisVar,NULL),start),length);
   }
   jsePutBuffer(jsecontext,tempVar,buffer,size);
   HugeFree(buffer);
   jseSetAttributes(jsecontext,tempVar,jseDontDelete|jseReadOnly); /* Now we set ReadOnly flag */

   /* We must and "get" and "put" directly */
   jseMemberWrapperFunction(jsecontext,bufferObject,GET_PROPERTY,BufferGet,1,-1,jseDontEnum,jseFunc_PassByReference,NULL);
   jseMemberWrapperFunction(jsecontext,bufferObject,PUT_PROPERTY,BufferPut,2,2,jseDontEnum,jseFunc_PassByReference,NULL);

   jseReturnVar(jsecontext,bufferObject,jseRetTempVar);
}
#endif

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

static CONST_DATA(struct jseFunctionDescription) BufferLibFunctionList[] =
{
   /* Constructors */
   JSE_LIBOBJECT( BUFFER_PROPERTY, BufferCall,           0, 3, jseDontEnum, jseFunc_Secure ),
   JSE_LIBMETHOD( CONSTRUCT_PROPERTY,  BufferConstruct,      0, 3, jseDontEnum, jseFunc_Secure ),
   JSE_PROTOMETH( CONSTRUCTOR_PROPERTY, BuiltinBufferConstruct, 0, 0, jseDontEnum, jseFunc_Secure ),
   /* Properties */
   JSE_VARSTRING( PROTOCLASS_PROPERTIES, UNISTR("\"Buffer\""), jseDontEnum ),
   /* Methods */
#  if defined(JSE_BUFFER_PUTVALUE)
      JSE_PROTOMETH( UNISTR("putValue"),    Ecma_Buffer_putValue,       1, 3, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_GETVALUE)
      JSE_PROTOMETH( UNISTR("getValue"),    Ecma_Buffer_getValue,       0, 2, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_PUTSTRING)
      JSE_PROTOMETH( UNISTR("putString"),   Ecma_Buffer_putString,      1, 2, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_GETSTRING)
      JSE_PROTOMETH( UNISTR("getString"),   Ecma_Buffer_getString,      0, 1, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_TOSTRING)
      JSE_PROTOMETH( TOSTRING_PROPERTY,     Ecma_Buffer_toString,       0, 0, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_TOSOURCE)
      JSE_PROTOMETH( TOSOURCE_PROPERTY,     Ecma_Buffer_toSource,       0, 0, jseDontEnum, jseFunc_Secure ),
#  endif
#  if defined(JSE_BUFFER_SUBBUFFER)
      JSE_PROTOMETH( UNISTR("subBuffer"),   Ecma_Buffer_subBuffer,      0, 2, jseDontEnum, jseFunc_Secure ),
#  endif
   JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY,  jseDontEnum | jseReadOnly | jseDontDelete ),
   JSE_FUNC_END

};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

   void NEAR_CALL
InitializeLibrary_Ecma_Buffer(jseContext jsecontext)
{
   jseAddLibrary(jsecontext,NULL,BufferLibFunctionList,NULL,NULL,NULL);
}

#else
   ALLOW_EMPTY_FILE
#endif /* #ifdef JSE_BUFFER_ANY */
