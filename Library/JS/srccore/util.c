/* util.c      Random utilities used by the core.
 *
 * In most cases, they  are routines to big to put in the core segment
 * and are all far calls on DOS/WIN16.
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


#include "srccore.h"

#if defined(__JSE_GEOS__)

#define IS_PLUS_MINUS(c) ((c == '+') || (c == '-'))
#define IS_NUMBER(c)	 ((c >= '0') && (c <= '9'))
#define IS_EXPONENT(c)   ((c == 'E') || (c == 'e'))
#define IS_PERIOD(c)	  (c == '.')

/* Ansi function for converting a string to a double.  End pointer is
 * always returned as the trailing null!!
 */
extern double strtod(const char _FAR *s, char _FAR *_FAR *endptr) 
{
	double retValue;
	int i = 0;		/* number of chars in a legal number */

	/* GEOS doesn't actually parse the string for correctness so we'll
	 * have to do that ourselves.  This is what we expect:
	 *		"[+-] dddd.dddd [Ee] [+-] dddd"
	 */
	/* Looking for an optional +/-, followed by numbers */
	if (IS_PLUS_MINUS(s[i])) i++;
	/* Get some numbers */
	if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) i++;
	/* Looking for an optional '.' */
	if (IS_PERIOD(s[i])) i++;
	/* Now looking for more numbers, if there */
	if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) i++;
	/* Now looking for exponent, if there, and then a plus/minus */
	if (IS_EXPONENT(s[i])) {
		i++;
		if (IS_PLUS_MINUS(s[i])) i++;
		if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) i++;
	}

	FloatAsciiToFloat(FAF_PUSH_RESULT, i, s, NULL);
	FloatGeos80ToIEEE64(&retValue);
	*endptr = &(s[i]);
	return retValue;
}
#endif



static struct Library * NEAR_CALL libraryNew(struct Call *call,struct Library *Parent);

#  if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
#     if defined(__JSE_PALMOS__)
#        define ERROR_MSG_SIZE 80
#     else
#        define ERROR_MSG_SIZE 300
#     endif
#  else
      define ERROR_MSG_SIZE 1024
#  endif

/************************************************************
 **** STRING TABLE INITIALIZATION FOR TOP-LEVEL CONTEXTS ****
 ************************************************************/

#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
   jsebool
allocateGlobalStringTable()
{
   hashSize = JSE_HASH_SIZE;
   hashTable = jseMalloc(struct HashList *,
                         hashSize*sizeof(struct HashList *));
   if( hashTable==NULL )
   {
      return False;
   }
   else
   {
      memset(hashTable,0,hashSize*sizeof(struct HashList *));
      return True;
   }
}

   void
freeGlobalStringTable()
{
#     ifndef NDEBUG
      {
         uint i;
         jsebool stringTableOK = True;
         for( i = 0; i < hashSize; i++ )
         {
            if( NULL != hashTable[i] )
            {
               struct HashList * current = hashTable[i];
               while(current != NULL )
               {
                  DebugPrintf("String table entry \"%s\" not removed.\n",
                              NameFromHashList(current));
                  current = current->next;
               }
               stringTableOK = False;
            }
         }
        /* if it fails, don't assert, or we won't get the debug information
         * on memory not freed, which is probably causing this
         */
        /* assert( stringTableOK ); */
      }
#     endif
      jseMustFree(hashTable);
}
#endif /* defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE) */

/****************************************************
 *****************   STRING TABLE   *****************
 ****************************************************/

/* Note: all of the 'jsecharptr ' must be aligned to even boundaries -
 * if this fails, my cool scheme for fast number entries won't work,
 * and this would be *bad*. This is true on every system we've seen to
 * date, but if it fails, then the code will need to be modified to
 * have numbers legitimately enterred into the table too.
 */

#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
   VAR_DATA(struct HashList **) hashTable = NULL;
   VAR_DATA(uint) hashSize = JSE_HASH_SIZE;
#endif

#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
#  define getStringParameter(call,name)   (name)
#else
#  define getStringParameter(call,name)   (call->Global->name)
#endif


/* This table must be in ASCII order and it must match the
 * enumeration in call.h
 */
CONST_DATA(jsecharptr) stock_strings[STOCK_TABLE_SIZE] =
{
   UNISTR(":Global Initialization:"),

   /* uppercase */
   UNISTR("Array"),
   UNISTR("Boolean"),
   UNISTR("Buffer"),
   UNISTR("DYN_DEFAULT"),
   UNISTR("Date"),
   UNISTR("Error"),
   UNISTR("Function"),
   UNISTR("Number"),
   UNISTR("OPERATOR_DEFAULT_BEHAVIOR"),
   UNISTR("Object"),
   UNISTR("RegExp"),
   UNISTR("String"),

   /* underscore */
   UNISTR("__parent__"),
   UNISTR("_argc"),
   UNISTR("_argv"),
   UNISTR("_call"),
   UNISTR("_canPut"),
   UNISTR("_class"),
   UNISTR("_construct"),
   UNISTR("_defaultValue"),
   UNISTR("_delete"),
   UNISTR("_get"),
   UNISTR("_hasProperty"),
   UNISTR("_operator"),
   UNISTR("_prototype"),
   UNISTR("_put"),
   UNISTR("_value"),

   /* lowercase */
   UNISTR("arguments"),
   UNISTR("callee"),
   UNISTR("constructor"),
   UNISTR("global"),
   UNISTR("length"),
   UNISTR("main"),
   UNISTR("preferredType"),
   UNISTR("prototype"),
   UNISTR("this"),
   UNISTR("toSource"),
   UNISTR("toString"),
   UNISTR("valueOf")
};

#if JSE_USER_STRINGS==1
#include "userstr.h"
#define DO_USER_STRINGS
#include "userstr.inc"
#endif

/* All Strings are stored here, this table was a linked list, now it
 * is changed to a dynamic array because it will use less memory and
 * search faster. As with object members, strings are looked for a
 * lot more often than they are added to the table.
 */

   static VarName NEAR_CALL
EnterIntoStringTable(struct Call *this,jsecharptr Name,stringLengthType length)
{
   unsigned int location;
   struct HashList **next,*list;
   jsecharptr copy;
   stringLengthType i;
   sint result;
   jsechar tmpChar;
   uint strAllocSize;
   jsecharptr nameInHashList;
   uint lower,upper,middle;


#  if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
      UNUSED_PARAMETER(this);
#  endif
   /* pointers are compared as 16-bit by default -- brianc */
   if( (dword)((struct api_string *)Name)>=(dword)(this->Global->api_strings) &&
       (dword)((struct api_string *)Name)<(dword)(this->Global->api_strings + this->Global->api_strings_used) )
   {
      /* Already an internal string */
      return ((struct api_string *)Name)->name;
   }

   /* ---------------------------------------------------------------------- */
   /* special case #1, a number */

   /* Check out the special cases */
   if( isdigit_jsechar(JSECHARPTR_GETC(Name)) || JSECHARPTR_GETC(Name)=='-' )
   {
      jsebool neg = FALSE;
      /* Use an alternate pointer so if it turns out not to be a
       * storable number, we have the original next to enter into
       * the table.
       */
      jsecharptr nametmp = Name;
      ulong value = 0;
      stringLengthType act_length = 0;



      if( JSECHARPTR_GETC(nametmp)=='-' )
      {
         neg = TRUE;
         JSECHARPTR_INC(nametmp); act_length++;
      }
      if( !neg || isdigit_jsechar(JSECHARPTR_GETC(nametmp)) )
      {
         while( JSECHARPTR_GETC(nametmp) )
         {
            if( !isdigit_jsechar(JSECHARPTR_GETC(nametmp)) ) break;
            value = 10*value + JSECHARPTR_GETC(nametmp)-'0';
            if( value>0xffffff ) break;        /* too big */
            JSECHARPTR_INC(nametmp); act_length++;
         }

         if( JSECHARPTR_GETC(nametmp)=='\0' && act_length==length )
         {
            /* ensure it was small enough */
            assert( (value<<8)>>8==value );
            /* used up the whole name, so a valid number */
            return (VarName)(((neg)?ST_NUMBER_NEG:ST_NUMBER_POS) | (value<<8));
         }
      }
   }


   /* ---------------------------------------------------------------------- */
   /* special case #2, a stock string */

   /* Note that stock strings must take precedence over other special
    * cases. This is because we build and use stock strings in the
    * core (i.e. STOCK_STRING(toString), etc.) Therefore, that
    * is what those strings must resolve to. Thus, stock strings must
    * be checked first.
    */

   /* Make sure no one has updated the table without updating the enum */
   assert( strcmp_jsechar(stock_strings[valueOf_entry],UNISTR("valueOf"))==0 );
   assert( valueOf_entry+1==STOCK_TABLE_SIZE );

   /* we binary search the stock table. */
   upper = STOCK_TABLE_SIZE-1;
   lower = 0;

   for ( ; ; )
   {
      int result;

      assert( lower<=upper );
      middle = (lower+upper)/2;

      result = strncmp_jsechar(stock_strings[middle],Name,length);
      if( result==0 && strlen_jsechar(stock_strings[middle])>length )
         /* that means the stock string is longer, or 'greater' */
         result = 1;

      if( result==0 )
      {
         return (VarName)((middle<<8) | ST_STOCK_ENTRY);
      }

      if( result<0 )
      {
         if( middle==upper ) break;
         lower = middle + 1;
      }
      else
      {
         if( middle==lower ) break;
         upper = middle - 1;
      }
   }

#  if JSE_USER_STRINGS==1
   /* ---------------------------------------------------------------------- */
   /* special case #3, a user stock string */

   /* we binary search the stock table. */
   upper = NUM_USER_STRINGS-1;
   lower = 0;

   for ( ; ; )
   {
      int result;

      assert( lower<=upper );
      middle = (lower+upper)/2;

      result = strncmp_jsechar(user_string[middle],Name,length);
      if( result==0 && strlen_jsechar(user_string[middle])>length )
         /* that means the stock string is longer, or 'greater' */
         result = 1;

      if( result==0 )
      {
         return (VarName)((middle<<8) | ST_USER_ENTRY);
      }

      if( result<0 )
      {
         if( middle==upper ) break;
         lower = middle + 1;
      }
      else
      {
         if( middle==lower ) break;
         upper = middle - 1;
      }
   }
#  endif

   /* ---------------------------------------------------------------------- */
   /* special case #4, a short ascii string */

   #if JSE_MBCS==0 && JSE_UNICODE==0
   assert( sizeof(jsechar)==1 );
   if( length<=3 )
   {
      uword32 ret = ST_SHORT_ASCII;

      if( length>2 ) ret |= ((uword32)Name[2])<<24;
      if( length>1 ) ret |= ((uword32)Name[1])<<16;
      if( length>0 ) ret |= ((uword32)Name[0])<<8;

      return (VarName)ret;
   }

   if( length<=5 )
   {
      /* see if it can be an alnum version */
      int i;
      jsebool worked = TRUE;
      uword32 value = 0;


      assert( length==4 || length==5 );
      for( i=0;i<5;i++ )
      {
         int val = 0;

         if( i<4 || length==5 )
         {
            /* note for last character, 0=='no char', not=='$' */
            if( Name[i]>='a' && Name[i]<='z' )
            {
               val = Name[i]-'a'+2;
            }
            else if( Name[i]>='A' && Name[i]<='Z' )
            {
               val = Name[i]-'A'+28;
            }
            else if( Name[i]=='_' )
            {
               val = 1;
            }
            else if( Name[i]=='$' )
            {
               if( i==4 )
               {
                  worked = FALSE;
                  break;
               }
               val = 0;
            }
            else
            {
               worked = FALSE;
               break;
            }
         }
         /* else use the '\0' for last char = no char */

         value <<= 6;
         value |= val;
      }


      if( worked ) return (VarName)((value<<2)|ST_ALNUM_MASK);
   }
   #endif

   /* No special case, just find it or add it to the string table */

   assert( sizeof_jsechar('.') == sizeof(jsecharptrdatum) );
   strAllocSize = sizeof(jsecharptrdatum);
   for( location = 0, copy = Name, i = 0; i < length; JSECHARPTR_INC(copy), i++ )
   {
      tmpChar = JSECHARPTR_GETC(copy);
      strAllocSize += sizeof_jsechar(tmpChar);
      location = (location << 5) ^ tmpChar ^ location;
   }

   location %= getStringParameter(this,hashSize);

   next = &(getStringParameter(this,hashTable)[location]);

   while( (*next) != NULL )
   {
      if( length < LengthFromHashList(*next) )
         break;
      else if( length == LengthFromHashList(*next) )
      {
         result = jsecharCompare( NameFromHashList(*next), LengthFromHashList(*next),
                                  Name, length );
         if( result < 0 )
            break;
         if( result == 0 )
         {
            return VarNameFromHashList(*next);
         }
      }

      next = &((*next)->next);
   }

   /* we must pad all entries to 4 byte boundary, so that the low 2
    * bits are both 0.
    */
   list = jseMustMalloc(struct HashList,sizeof(struct HashList)+sizeof(stringLengthType)+
                        strAllocSize);

   /* VarName format demands the address be even aligned. */
   assert( (((uword32)list)&0x01)==0 );


   list->table_entry = 0;
   list->flags = 0;
   nameInHashList = NameFromHashList(list);
   STRCPYLEN_JSECHAR(nameInHashList,Name,length);

   *((stringLengthType *)(list+1)) = length;

   list->next = (*next);
   *next = list;

#ifdef MEM_TRACKING
   this->Global->hashAllocSize += *(((byte *)list)-2);
   if (this->Global->hashAllocSize > this->Global->maxHashAllocSize)
       this->Global->maxHashAllocSize = this->Global->hashAllocSize;
#endif

   return VarNameFromHashList(list);
}



   const jsecharptr
GetStringTableEntry(struct Call *this,VarName entry,stringLengthType *lenptr)
{
   uint form = (uint)ST_FORMAT(entry);
   jsecharptr ret;


   if( IsNormalStringTableEntry(entry ) )
   {
      /* The entry points to the extra allocated data, right before
       * that in memory is the length
       */
      if( lenptr!=NULL )
         *lenptr = LengthFromHashList(HashListFromVarName(entry));
      ret = NameFromHashList(HashListFromVarName(entry));
   }
   else if( (form&ST_ALNUM_MASK)==ST_ALNUM_MASK )
   {
      int i;
      uword32 e = (uword32)entry;
      JSE_POINTER_UINT len = 0;


      ret = (jsecharptr) JSECHARPTR_OFFSET((jsecharptr)(this->Global->tempNumToStringStorage),
            ((sizeof(this->Global->tempNumToStringStorage)/sizeof(jsechar)) - 1));

      e >>= 2;

      for( i=0;i<5;i++ )
      {
         int val;
         jsechar tmp;

         /* pop off characters from the right and push them in the buffer. This builds
          * the buffer in reverse order.
          */

         val = (int)e&0x3f;
         e >>= 6;

         if( val==0 )
         {
            tmp = (i)?'$':'\0';
         }
         else if( val==1 )
         {
            tmp = '_';
         }
         else if( val<28 )
         {
            tmp = 'a'+(val-2);
         }
         else
         {
            tmp = 'A'+(val-28);
         }
         if( tmp!='\0' )
         {
            ret = (jsecharptr)(((char *)ret) - 1);
            JSECHARPTR_PUTC(ret,tmp);
            len++;
         }
      }
      if( lenptr!=NULL )
      {
         *lenptr = (stringLengthType)len;
         assert( len == *lenptr );  /* did casting lose information */
      }
   }
   else if( form==ST_NUMBER_POS ||
            form==ST_NUMBER_NEG )
   {
      JSE_POINTER_SINT x = ST_DATA(entry);
      jsebool neg = (form==ST_NUMBER_NEG);
      JSE_POINTER_UINT len;


      ret = (jsecharptr) JSECHARPTR_OFFSET((jsecharptr)(this->Global->tempNumToStringStorage),
            ((sizeof(this->Global->tempNumToStringStorage)/sizeof(jsechar)) - 1));

      assert( JSECHARPTR_GETC(ret) == 0 );

      len = 0;
      if( x )
      {
         while( x )
         {
            jsechar tmpChar = (jsechar)((x%10) + '0' );
            ret = (jsecharptr)(((char *)ret) - sizeof_jsechar(tmpChar));
            JSECHARPTR_PUTC(ret,tmpChar);
            x /= 10;
            len++;
         }
      }
      else
      {
         jsechar tmpChar = '0';
         ret = (jsecharptr)(((char *)ret) - sizeof_jsechar(tmpChar));
         JSECHARPTR_PUTC(ret,tmpChar);
         len++;
      }
      if ( neg )
      {
         assert( sizeof_jsechar('-') == sizeof(jsecharptrdatum) );
         ret = (jsecharptr )(((char *)ret) - sizeof(jsecharptrdatum));
         JSECHARPTR_PUTC(ret,'-');
         len++;
      }
      if( lenptr!=NULL )
      {
         *lenptr = (stringLengthType)len;
         assert( len == *lenptr );  /* did casting lose information */
      }
   }
   else if( form==ST_STOCK_ENTRY )
   {
      uint offset = (uint)ST_DATA(entry);

      ret = (jsecharptr)stock_strings[offset];
      if( lenptr!=NULL )
         *lenptr = strlen_jsechar(ret);
   }
#  if JSE_USER_STRINGS==1
   else if( form==ST_USER_ENTRY )
   {
      uint offset = (uint)ST_DATA(entry);

      ret = (jsecharptr)user_string[offset];
      if( lenptr!=NULL )
         *lenptr = strlen_jsechar(ret);
   }
#  endif
   else if( form==ST_SHORT_ASCII )
   {
      JSE_POINTER_UINT len = 0;
      jsechar c;


      /* it is for ASCII strings only */
      assert( sizeof(jsechar)==1 );

      ret = (jsecharptr) JSECHARPTR_OFFSET((jsecharptr)(this->Global->tempNumToStringStorage),
            ((sizeof(this->Global->tempNumToStringStorage)/sizeof(jsechar)) - 1));

      /* Note that >>16 gives the original string [2]. Since we are going
       * from the right end of the string and counting back, we do it
       * first.
       */
      c = (jsechar)((ST_DATA(entry)>>16)&0xff);
      if( c!='\0' )
      {
         ret = (jsecharptr )(((char *)ret) - 1);
         JSECHARPTR_PUTC(ret,c);
         len++;
      }
      c = (jsechar)((ST_DATA(entry)>>8)&0xff);
      if( c!='\0' )
      {
         ret = (jsecharptr )(((char *)ret) - 1);
         JSECHARPTR_PUTC(ret,c);
         len++;
      }
      c = (jsechar)((ST_DATA(entry)>>0)&0xff);
      if( c!='\0' )
      {
         ret = (jsecharptr )(((char *)ret) - 1);
         JSECHARPTR_PUTC(ret,c);
         len++;
      }
      if( lenptr!=NULL )
         *lenptr = strlen_jsechar(ret);
   }
   else
   {
      assert( False );
   }

   return ret;
}


   VarName
LockedStringTableEntry(struct Call *call,const jsecharptr name,
                       stringLengthType length)
{
   VarName ret;

   ret = EnterIntoStringTable(call,(jsecharptr)name,length);

   if( IsNormalStringTableEntry(ret) )
   {
      struct HashList *it = HashListFromVarName(ret);
      it->flags = JSE_STRING_LOCK;
   }

   return ret;
}


   VarName
GrabStringTableEntry(struct Call *call,const jsecharptr name,
                     stringLengthType length,uword8 *temp)
{
   VarName ret;

   ret = EnterIntoStringTable(call,(jsecharptr)name,length);

   if( IsNormalStringTableEntry(ret) )
   {
      struct HashList *it = HashListFromVarName(ret);
      *temp = it->flags;
      it->flags = JSE_STRING_LOCK;
   }

   return ret;
}


   VarName
GrabStringTableEntryStrlen(struct Call *call,const jsecharptr name,
                           uword8 *temp)
{
   VarName ret;

   /* pointers are compared as 16-bit by default -- brianc */
   if( (dword)((struct api_string *)name)>=(dword)(call->Global->api_strings) &&
       (dword)((struct api_string *)name)<(dword)(call->Global->api_strings +
                                    call->Global->api_strings_used) )
   {
      /* Already an internal string */
      ret = ((struct api_string *)name)->name;
   }
   else
   {
      stringLengthType length = strlen_jsechar(name);

      ret = EnterIntoStringTable(call,(jsecharptr)name,length);
   }

   if( IsNormalStringTableEntry(ret) )
   {
      struct HashList *it = HashListFromVarName(ret);
      *temp = it->flags;
      it->flags = JSE_STRING_LOCK;
   }

   return ret;
}


/* use this when the sweeper finds an entry with flags==0, or to remove
 * everything when exiting.
 */
   void
RemoveStringTableEntry(struct Call * this,struct HashList *list)
{
#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
   UNUSED_PARAMETER(this);
#endif
#ifdef MEM_TRACKING
   this->Global->hashAllocSize -= *(((byte *)list)-2);
#endif
   jseMustFree(list);
}

   void
ReleaseStringTableEntry(/*struct Call *call,*/VarName entry,uword8 temp)
{
   if( IsNormalStringTableEntry(entry) )
   {
      struct HashList *it = HashListFromVarName(entry);
      it->flags = temp;
   }
}


/* Adds the string to the api string table with a count of 1, or
 * increments the count if already there. Returns the api string
 * table entry.
 */
   jseString
callApiStringEntry(struct Call *call,VarName name)
{
   struct HashList *it = NULL;
   struct api_string *s = NULL;
   struct Global_ *global = call->Global;
   uword16 index = 0;
   jsebool numeric = False;


   if( !IsNormalStringTableEntry(name) )
   {
      numeric = True;
      for( index=0;index<global->api_strings_used;index++ )
      {
         s = global->api_strings+index;
         if( s->name==name && s->count!=0 )
         {
            s->count++;
            return s;
         }

      }
   }
   else
   {
      it = HashListFromVarName(name);
      if( it->table_entry!=0 )
      {
         /* already exists */
         s = global->api_strings+it->table_entry;
         assert( s->name==name );
         s->count++;
         return s;
      }
   }


   /* create new entry */
   if( global->api_strings_used )
   {
      s = global->api_strings + global->api_last_unused;
      if( s->count==0 )
      {
         /* cached unused entry is fine */
         index = global->api_last_unused;
      }
      else
      {
         s = NULL;
      }
   }
   if( s==NULL )
   {
      /* 0 entry is reserved to indicate 'not used' */
      if( global->api_strings_used>0 )
      {
         for( index=(uword16)(global->api_strings_used-1),
                 s = global->api_strings + (global->api_strings_used-1);
              index>0;index--,s-- )
         {
            if( s->count==0 ) break;
         }
      }
      else
      {
         index = 0;
      }
      if( index==0 )
      {
         /* no space found to put it, allocate some more spaces */
         index = global->api_strings_used;
         global->api_strings_used += (sword16)100;
         if( index )
         {
            global->api_strings = jseMustReMalloc(struct api_string,
                                                  global->api_strings,
                                                  global->api_strings_used*
                                                  sizeof(struct api_string));
         }
         else
         {
            global->api_strings = jseMustMalloc(struct api_string,
                                                global->api_strings_used*
                                                sizeof(struct api_string));
            global->api_last_unused = 2;
         }
         s = global->api_strings + index;
         while( index<global->api_strings_used )
         {
            s->count = 0;
            s++;
            index++;
         }

         /* we don't fill in entry 0, that is reserved */
         if( index>1 )
         {
            index--;
            s--;
         }
      }
   }
   /* index,s give us the space to put it in */
   if( !numeric ) it->table_entry = (uword16)index;
   s->name = name;
   s->count = 1;
   return s;
}


/* decrements the count in the API string table and removes
 * the api string table entry if goes to 0.
 */
void callRemoveApiStringEntry(struct Call *call,struct api_string *s)
{
   if( IsNormalStringTableEntry(s->name) )
   {
      struct HashList *it = HashListFromVarName(s->name);

      assert( it->table_entry!=0 );
      assert( s==call->Global->api_strings+it->table_entry );
      if( --(s->count)==0 )
      {
         call->Global->api_last_unused = it->table_entry;
         it->table_entry = 0;
      }
   }
   else
   {
      (s->count)--;
   }
}

#pragma codeseg UTIL_CALL_GLOBAL

   static jsebool NEAR_CALL
createGlobalStrings( struct Call * call, const jsecharptr globalVariableName,
                     stringLengthType GlobalVariableNameLength )
{
#  ifndef NDEBUG
   int i;

   /* make sure the stock string table is correctly sorted */
   for( i=0;i<STOCK_TABLE_SIZE-1;i++ )
      assert( strcmp_jsechar(stock_strings[i],stock_strings[i+1])<0 );
#  endif
   call->Global->userglobal =
      LockedStringTableEntry(call,globalVariableName,GlobalVariableNameLength);

   return True;
}

#pragma codeseg UTIL_RARE

static jseLibFunc(Ecma_Object_construct)
{
   if( 0 < jseFuncVarCount(jsecontext) )
   {
      jseVariable var = jseFuncVar(jsecontext,0);
      jseDataType dt = jseGetType(jsecontext,var);

      if( dt==jseTypeObject )
      {
         jseReturnVar(jsecontext,var,jseRetCopyToTempVar);
         return;
      }
      if( dt==jseTypeString || dt==jseTypeBoolean || dt==jseTypeNumber )
      {
         jseVariable ret = jseCreateConvertedVariable(jsecontext,var,jseToObject);
         /* Conversion to an object can fail - if we return anyway then we replace
          * the error
          */
         if( !jseQuitFlagged(jsecontext) )
            jseReturnVar(jsecontext,ret,jseRetTempVar);
         else
            jseDestroyVariable(jsecontext,ret);
         return;
      }
      assert( dt==jseTypeNull || dt==jseTypeUndefined );
     /* fallthru intentional */
   }
   /* create object, instead of leaving on stack, so it automatically
    * inherits Object.prototype
    */
   jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeObject),jseRetTempVar);
}

static jseLibFunc(Ecma_Object_toString)
{
   jseVariable thisvar, mem, classvar, ret;
   const jsecharptr classname;
   jsecharptr buffer;

   thisvar = jseGetCurrentThisVariable(jsecontext);
   mem = jseGetMember(jsecontext,thisvar,CLASS_PROPERTY);
   classvar = mem ? jseCreateConvertedVariable(jsecontext,mem,jseToString) : NULL;
   classname = classvar
             ? (const jsecharptr)jseGetString( jsecontext, classvar, NULL)
             : (const jsecharptr)UNISTR("Object");
   buffer = (jsecharptr) jseMustMalloc(jsechar,sizeof(jsechar)*(strlen_jsechar(classname)+20));

   jse_sprintf(buffer,UNISTR("[object %s]"),classname);

   ret = jseCreateVariable(jsecontext,jseTypeString);

   jsePutString(jsecontext,ret,buffer);

   jseMustFree(buffer);
   jseDestroyVariable(jsecontext,classvar);

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}

static jseLibFunc(Ecma_Object_valueOf)
{
   jseReturnVar(jsecontext,jseGetCurrentThisVariable(jsecontext),jseRetCopyToTempVar);
}

static CONST_STRING(ObjectNameStr,"\"Object\"");
static CONST_DATA(struct jseFunctionDescription) ObjectProtoList[] =
{
   JSE_VARSTRING( PROTOTYPE_PROPERTY, textcorevtype_null, jseDontEnum ),
   JSE_VARSTRING( CLASS_PROPERTY, ObjectNameStr, jseDontEnum ),
   JSE_LIBMETHOD( CONSTRUCT_PROPERTY, Ecma_Object_construct, 0, -1, jseDontEnum,  jseFunc_Secure ),
   JSE_LIBMETHOD( TOSTRING_PROPERTY, Ecma_Object_toString, 0, -1, jseDontEnum,  jseFunc_Secure ),
   JSE_LIBMETHOD( VALUEOF_PROPERTY, Ecma_Object_valueOf, 0, -1, jseDontEnum,  jseFunc_Secure ),
   JSE_FUNC_DESC_END
};

static jseLibFunc(Ecma_Function_prototype)
{
   jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeUndefined),
                jseRetTempVar);
}

static jseLibFunc(Ecma_Function_toString)
{
   jseVariable th = jseGetCurrentThisVariable(jsecontext);
   if( !jseIsFunction(jsecontext,th))
   {
      jseLibErrorPrintf(jsecontext,textcoreGet(jsecontext,textcoreTHIS_NOT_FUNCTION));
   }
   else
   {
      jseVariable ret;
#  if (0!=JSE_CREATEFUNCTIONTEXTVARIABLE)
      ret = jseCreateFunctionTextVariable(jsecontext,th);
#  else
      ret = jseCreateVariable(jsecontext,jseTypeString);
      jsePutString(jsecontext,ret,UNISTR("function _() { }"));
#  endif
      jseReturnVar(jsecontext,ret,jseRetTempVar);
   }
}

static CONST_STRING(FunctionNameStr,"\"Function\"");
static CONST_STRING(ZeroStr,"0");
static CONST_DATA(struct jseFunctionDescription) FunctionProtoList[] =
{
   JSE_LIBMETHOD( ORIG_PROTOTYPE_PROPERTY, Ecma_Function_prototype, 0, -1,
                  jseDontEnum | jseDontDelete | jseReadOnly, jseFunc_Secure ),
   /* give it a default NULL prototype to prevent looping prototype chains
    * is the ecma objects are not included.
    */
   JSE_VARSTRING( PROTOPROTO_PROPERTIES, textcorevtype_null, jseDontEnum ),
   JSE_VARSTRING( PROTOCLASS_PROPERTIES, FunctionNameStr, jseDontEnum ),
   JSE_VARSTRING( UNISTR("prototype.length"), ZeroStr, jseDontEnum | jseDontDelete | jseReadOnly ),
   JSE_PROTOMETH( TOSTRING_PROPERTY, Ecma_Function_toString, 0, -1, jseDontEnum, jseFunc_Secure ),
   JSE_FUNC_DESC_END
};


/* ---------------------------------------------------------------------- */

#pragma codeseg UTIL_CALL_GLOBAL

   void
callCleanupGlobal(struct Call *this)
{
   struct Global_ * global;
   uint i;


   assert( NULL != this );
   global = this->Global;
   if( global != NULL )
   {
#     if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      cleanupSecurity(this);
#     endif

#     if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
      if( global->FileNameList )
      {
         for( i=0;i<(uint)global->number;i++ )
            jseMustFree(global->FileNameList[i]);
         jseMustFree(global->FileNameList);
      }
#     endif

      seapiCleanup(this);

      collectUnallocate(this);

      {
#if 0
         int count = 0;
#endif
#        if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
            uint hashSize = global->hashSize;
            struct HashList ** hashTable = global->hashTable;
#        endif

         for( i = 0; i < hashSize; i++ )
         {
            while( NULL != hashTable[i] )
            {
               struct HashList * next = hashTable[i]->next;
               RemoveStringTableEntry(this,hashTable[i]);
               hashTable[i] = next;
#if 0
               count++;
#endif
            }
         }
#if 0
         DebugPrintf("String table entries used on exit: %d\n",count);
#endif
      }

#     if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
            /* If all added names are removed, this should be true */
#           ifndef NDEBUG
            {
               uint i;
               /*jsebool stringTableOK = True;*/
               for( i = 0; i < global->hashSize; i++ )
               {
                  if( NULL != global->hashTable[i] )
                  {
                     struct HashList * current = global->hashTable[i];
                     while(current != NULL )
                     {
                        DebugPrintf(UNISTR("String table entry \"%s\" not removed\n"),
                                    NameFromHashList(current));
                        current = current->next;
                     }
                     /*stringTableOK = False;*/
                  }
               }
               /* if it fails, don't assert, or we won't get the debug information
                * on memory not freed, which is probably causing this
                */
               /* assert( stringTableOK ); */
            }
#           endif
            jseMustFree(global->hashTable);
#     endif

      if( global->hDestructors!=NULL )
         jseMustFree(global->hDestructors);

#     if 0==JSE_DONT_POOL
         for( i=0;i<global->argvCallPoolCount;i++ )
            jseMustFree(global->argvCallPool[i]);
#     endif

      if( global->api_strings!=NULL )
      {
         assert( global->api_strings_used!=0 );
         jseMustFree(global->api_strings);
      }
      else
      {
         assert( global->api_strings_used==0 );
      }

      /* physically free all extlibs now that we are no
       * longer using them.
       */

#     if defined(JSE_LINK) && (0!=JSE_LINK)
         extensionFreeAllLibs(&(global->savedLibs));
#     endif

#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
      if( global->growingStack!=NULL ) jseMustFree(global->growingStack);
#     endif

      jseMustFree(global);
   }

#  if ( 2 <= JSE_API_ASSERTLEVEL )
      this->cookie += (uword8)1;        /* make it illegal so further uses of it will fail */
#  endif
}

#pragma codeseg UTIL_CALL

   jsebool
callNewSettings(struct Call *this,uword8 NewContextSettings)
{
   jsebool success = True;

   if ( 0 != (this->CallSettings = (uword8)NewContextSettings))
   {
      success = False;
#     if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
      if ( !(NewContextSettings & jseNewDefines) ||
           NULL != (this->Definitions = defineNew(this->Definitions)))
      {
#     endif
         if( NewContextSettings & jseNewGlobalObject )
         {
            callNewGlobalVariable(this);
         }
         if ( !(NewContextSettings & jseNewLibrary) ||
              NULL != (this->TheLibrary = libraryNew(this,this->TheLibrary)))
         {
            if ( !(NewContextSettings & jseNewAtExit) ||
                 NULL != (this->AtExitFunctions
                          = atexitNew(this->AtExitFunctions)))
            {
#              if defined(JSE_LINK) && (0!=JSE_LINK)
               if ( !(NewContextSettings & jseNewExtensionLib) ||
                    NULL != (this->ExtensionLib
                             = extensionNew(this,this->ExtensionLib)))
               {
#              endif
                  success = True;
#              if defined(JSE_LINK) && (0!=JSE_LINK)
               }
#              endif
            }
         }
#     if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
      }
#     endif
   }


   if( success && (NewContextSettings & jseNewLibrary)!=0 )
   {
      /* If we are initializing new libraries, we also want to initialize
       * our builtin ECMA stuff as well.
       */
      this->hObjectPrototype = InitGlobalPrototype(this,
         LockedStringTableEntry(this,OBJECT_PROPERTY,
                                (stringLengthType)strlen_jsechar(OBJECT_PROPERTY)));
      this->hFunctionPrototype = InitGlobalPrototype(this,
         LockedStringTableEntry(this,FUNCTION_PROPERTY,
                                (stringLengthType)strlen_jsechar(FUNCTION_PROPERTY)));
      this->hArrayPrototype = InitGlobalPrototype(this,STOCK_STRING(Array));
      this->hStringPrototype = InitGlobalPrototype(this,
         LockedStringTableEntry(this,STRING_PROPERTY,
                                (stringLengthType)strlen_jsechar(STRING_PROPERTY)));

      /* We initialize the builtin variables into each global else we
       * will not have them in sub-interprets
       */
      InitializeBuiltinVariables(this);
   }

#     if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   if( success &&
       (NewContextSettings & jseNewSecurity)!=0 &&
       !setSecurity(this) )
   {
      /* We already have the existing security copied over from
       * the old call, now we add a new one if jseNewSecurity &
       * that is not already part of the existing security
       *
       * I've moved this here because the new global variable
       * must be completely set up before the initialization
       * security function is called. This is due to the new
       * global having the new default prototypes, which is
       * how 'foo.setSecurity()' works.
       */
      success = False;
   }
#     endif

   return success;
}

#pragma codeseg UTIL_CALL_GLOBAL

   static struct Call *
callInitialGlobal(void _FAR_ *LinkData,
                  struct jseExternalLinkParameters *ExternalLinkParms,
                  const jsecharptr globalVariableName,
                  stringLengthType GlobalVariableNameLength)
{
   struct Call *this = jseMalloc(struct Call,sizeof(struct Call));
   struct Global_ *global = NULL;

   if( NULL != this )
   {
      int i;
      jsebool success = False;
      memset( this, 0, sizeof(struct Call));

      this->mustPrintError = True;

     /* Note: Because we use API calls, we can assert on this cookie, so we need to set it
      * here, even though it may be redundant
      */
#  if ( 2 <= JSE_API_ASSERTLEVEL )
      this->cookie = (uword8) jseContext_cookie;
#  endif

      global = this->Global = jseMalloc(struct Global_,sizeof(struct Global_));
      if( NULL != global )
      {
         memset(global,0,sizeof(struct Global_));

#        if (0!=JSE_COMPILER)
            assert( NULL == global->CompileStatus.CompilingFileName );
            assert( 0 == global->CompileStatus.NowCompiling );
#        endif
         global->GenericData = LinkData;

         assert( NULL == global->dynacallRecurseList );
         assert( 0 == global->dynacallDepth );

#        if JSE_PER_OBJECT_CACHE==0
            assert( 0 == global->recentObjectCache.index );
            assert( hSEObjectNull == global->recentObjectCache.hobj );
#        endif

#        if (!defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE))
         global->hashSize = ExternalLinkParms->hashTableSize
            ? ExternalLinkParms->hashTableSize : JSE_HASH_SIZE;
         global->hashTable = jseMustMalloc(struct HashList *,
                                           global->hashSize*sizeof(struct HashList *));
         if( NULL != global->hashTable )
         {
            memset(global->hashTable,0,global->hashSize*sizeof(struct HashList *));
#        endif

            global->ExternalLinkParms = *ExternalLinkParms;
#           if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__)) \
               && (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            /* determine caller's DS by reading where it was pushed on stack
             * it is pushed right after sp is saved into bp
             */
            global->ExternalDataSegment = (Get_SS_BP())[-1];
#           endif

            if( createGlobalStrings(this,globalVariableName,GlobalVariableNameLength) )
            {
#              if !defined(NDEBUG) && (2 <= JSE_API_ASSERTLEVEL)
               /* some asserts expect the cookie to be set already */
               this->cookie = (uword8) jseContext_cookie;
#              endif

               global->inErrorVPrintf = False;

               /* Finally!  we have successfully built the call */
               success = True;
            }

#        if (!defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE))
            }
#        endif
      }

#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
      global->length = 125;
      global->growingStack = jseMustMalloc(struct _SEVar,sizeof(struct _SEVar)*global->length);
      if( global->growingStack==NULL )
      {
         success = False;
      }
#     endif

      if( !success )
      {
         callCleanupGlobal(this);
         this = NULL;
      }

#     if 0==JSE_DONT_POOL
         global->argvCallPoolCount = ARGV_CALL_POOL_SIZE;
         for( i=0;i<ARGV_CALL_POOL_SIZE;i++ )
         {
            global->argvCallPool[i] =
               jseMustMalloc(jseVariable,ARGV_CALL_POOL_COUNT*sizeof(jseVariable));
         }
#     endif
   }

   /* set up the stack */
#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
   this->stackptr = 0;
#  else
   this->stackptr = global->stack;
#  endif

   {
      /* The first slot in the stack is not used and must be
       * valid for the collector. This is done because it allows
       * the stack index to never go to negatives, which makes
       * a lot of stuff easier. (Else, it would go to -1 when
       * the stack is empty.)
       */
      struct Call *call = this;
      SEVAR_INIT_UNDEFINED(STACK0);
   }

#  if 0==JSE_DONT_POOL
      collectRefill(this);
#  endif

   /* needed to call destructors */
   this->hScopeChain = seobjNew(this,False);

   return this;
}

   void
InitializeBuiltinVariables(struct Call *call)
   /* stock variables: undefined_var, null_var, true_var, false_var
    *
    * initialize these Object.prototype fields
    * Object.prototype._prototype = null
    * Object.prototype._class = UNISTR("Object")
    * Object.prototype.construct = <function>
    * Object.prototype.toString = <function>
    * Object.prototype.valueOf = <function>
    *
    * initialize these Function.prototype fields
    * Function.prototype = <function>
    * Function.prototype._class = UNISTR("Function")
    * Function.prototype.length = 0
    * Function.prototype.toString = <function>
    */
{
   jseAddLibrary(call,UNISTR("Object.prototype"),ObjectProtoList,NULL,NULL,NULL);

   jseAddLibrary(call,FUNCTION_PROPERTY,FunctionProtoList,NULL,NULL,NULL);


#  if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
#     if defined(__JSE_OS2TEXT__)
         jsePreDefineLong(call,UNISTR("_OS2_"),1L);
#     elif defined(__JSE_OS2PM__)
         jsePreDefineLong(call,UNISTR("_PM_"),1L);
#     elif defined(__JSE_DOS16__)
         jsePreDefineLong(call,UNISTR("_DOS_"),1L);
#     elif defined(__JSE_DOS32__)
         jsePreDefineLong(call,UNISTR("_DOS32_"),1L);
#     elif defined(__JSE_WIN16__)
         jsePreDefineLong(call,UNISTR("_WINDOWS_"),1L); /* legacy */
         jsePreDefineLong(call,UNISTR("_WIN16_"),1L);
#     elif defined(__JSE_CON32__) || defined(__JSE_WIN32__)
#        if defined(__JSE_WINCE__)
            jsePreDefineLong(call,UNISTR("_WINDOWS_CE_"),1L);
#        else
            jsePreDefineLong(call,UNISTR("_WIN32_"),1L);
#        endif
#     elif defined(__JSE_NWNLM__)
         jsePreDefineLong(call,UNISTR("_NWNLM_"),1L);
#     elif defined(__JSE_UNIX__)
         jsePreDefineLong(call,UNISTR("_UNIX_"),1L);
#     elif defined(__JSE_MAC__)
         jsePreDefineLong(call,UNISTR("_MAC_"),1L);
#     elif defined(__JSE_PSX__)
         jsePreDefineLong(call,UNISTR("_PSX_"),1L);
#     elif defined(__JSE_PALMOS__)
         jsePreDefineLong(call,UNISTR("_PALMOS_"),1L);
#     elif defined(__JSE_390__)
         jsePreDefineLong(call,UNISTR("_OS390_"),1L);
#     elif defined(__JSE_EPOC32__)
         jsePreDefineLong(call,UNISTR("_EPOC32_"),1L);
#     else
#        error define OS type
#     endif
#     if defined(JSE_LINK) && (0!=JSE_LINK)
         jsePreDefineLong(call,UNISTR("_LINK_"),1L);
#     endif
#     if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
         jsePreDefineLong(call,UNISTR("_INCLUDE_"),1L);
#     endif
#     if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
         jsePreDefineLong(call,UNISTR("_SECUREJSE_"),1L);
#     endif
#     if JSE_MBCS==1
         jsePreDefineLong(call,UNISTR("_MBCS_"),1L);
#     endif
#     if JSE_UNICODE==1
         jsePreDefineLong(call,UNISTR("_UNICODE_"),1L);
#     endif
#     if JSE_FLOATING_POINT==0
         jsePreDefineLong(call,UNISTR("_NO_FP_"),1L);
#     endif
#  endif

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      setupSecurity(call);
#  endif
}


/* Create the first, top-level context and set up the global object */
   struct Call * NEAR_CALL
callInitial(void _FAR_ *LinkData,
            struct jseExternalLinkParameters *ExternalLinkParms,
            const jsecharptr globalVariableName,
            stringLengthType GlobalVariableNameLength)
{
   struct Call *call = callInitialGlobal(LinkData,ExternalLinkParms,
                                         globalVariableName,GlobalVariableNameLength);
   if ( NULL != call  &&  !callNewSettings(call,jseAllNew) )
   {
      callCleanupGlobal(call);
      call = NULL;
   }
   return call;
}

#pragma codeseg UTIL_RARE

/*
 * Figure out the current source location
 */
   static jsebool NEAR_CALL
secodeSourceLocation(struct Call *call,const jsecharptr *name,uint *line)
{
   /* compatibility with existing code */
#  if (0!=JSE_COMPILER)
   if ( 0 != call->Global->CompileStatus.NowCompiling )
   {
      *name = call->Global->CompileStatus.CompilingFileName;
      *line = call->Global->CompileStatus.CompilingLineNumber;
   }
   else
#  endif
   {
      struct Function *func = call->funcptr;
      rSEVar fptr = STACK_FROM_STACKPTR(call->frameptr);
      uint num_args;
      secode sptr, base, iptr;

      *name = NULL;
      *line = 0;

#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
         if( fptr==call->Global->growingStack ) return False;
#     else
         if( fptr==NULL ) return False;
#     endif

      while( !FUNCTION_IS_LOCAL(func) )
      {
         rSEObject robj;

         num_args = (uint)SEVAR_GET_STORAGE_LONG(fptr-ARGS_OFFSET);
#        if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
            fptr = STACK_FROM_STACKPTR(SEVAR_GET_STORAGE_LONG(fptr));
            if( fptr==call->Global->growingStack ) return False;
#        else
            fptr = SEVAR_GET_STORAGE_PTR(fptr);
            if( fptr==NULL ) return False;
#        endif
         /* restore func from stack */
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(fptr - (num_args + FUNC_OFFSET)));
         func = SEOBJECT_PTR(robj)->func;
         SEOBJECT_UNLOCK_R(robj);
      }

#     if JSE_MEMEXT_SECODES==1
         base = jsememextLockRead(((struct LocalFunction *)func)->op_handle,jseMemExtSecodeType);
         iptr = base + ( call->iptr - call->base );
#     else
         base = ((struct LocalFunction *)func)->opcodes;
         iptr = call->iptr;
         /* assert we are in the right function frame */
         assert( (iptr-((struct LocalFunction *)func)->opcodes)>=0 );
         assert( (uint)(iptr-((struct LocalFunction *)func)->opcodes)<
                 ((struct LocalFunction *)func)->opcodesUsed );
#     endif

      /* search from beginning to find last function filename before error */
      for( sptr = base;sptr<=iptr;sptr++ )
      {
         if ( seFilename == *sptr )
         {
            *name = GetStringTableEntry(call,SECODE_GET_ONLY(sptr+1,VarName),NULL);
         }
         sptr += SECODE_DATUM_SIZE(*sptr);
      }
      /* search forward for next line number */
      for( sptr = iptr;;sptr++ )
      {
         if ( seLineNumber == *sptr  ||  seContinueFunc == *sptr )
         {
            *line = SECODE_GET_ONLY(sptr+1,CONST_TYPE);
            break;
         }
         sptr += SECODE_DATUM_SIZE(*sptr);
      }
#     if JSE_MEMEXT_SECODES==1
         jsememextUnlockRead(((struct LocalFunction *)func)->op_handle,base,jseMemExtSecodeType);
#     endif
   }

   return True;
}


   void
functionInit(struct Function *this,
             struct Call *call,
             rSEVar ObjectToAddTo,
                  /*NULL if not to add to any object*/
             jseVarAttributes FunctionVariableAttributes,
                  /*not used if ObejctToAddTo is NULL*/
             jsebool iLocalFunction, /*else library*/
             jsebool iCBehavior,
                  /*else default javascript behavior*/
#            if 0 != JSE_MULTIPLE_GLOBAL
                jsebool iSwapGlobal,
#            endif
             sword16 Params)
{
   assert( ObjectToAddTo!=NULL );

#ifdef MEM_TRACKING
   call->Global->func_alloc_count++;
   call->Global->func_alloc_size += sizeof(struct LibraryFunction);
#endif

   /* Link it in */
   this->next = call->Global->funcs;
   call->Global->funcs = this;

#  if 0 != JSE_MULTIPLE_GLOBAL
      this->hglobal_object = iSwapGlobal ? CALL_GLOBAL(call) : hSEObjectNull;
#  endif
#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      if( iLocalFunction )
         this->functionSecurity = call->currentSecurity;
      else
         this->functionSecurity = NULL;
#  endif
   this->params = (uword16)Params;
   this->flags = 0;
   this->attributes = FunctionVariableAttributes;

   if ( iLocalFunction )
      this->flags |= Func_LocalFunction;
   if ( iCBehavior )
      this->flags |= Func_CBehavior;
   if ( NULL != ObjectToAddTo )
   {
      assert( VObject == SEVAR_GET_TYPE(ObjectToAddTo) );

      seobjSetFunction(call,SEVAR_GET_OBJECT(ObjectToAddTo),this);
   }
}


/* Construct an error object to return. */
   static void NEAR_CALL
ErrorVPrintf(struct Call *call, const jsecharptr FormatS,va_list arglist)
{
   wSEVar error_obj;
   const jsecharptr funcname;
   jsecharptr fname;
   /*
    * The initial size, must cover the FormatS and arglist, which we can't
    * estimate without excessive duplication of vsprintf.
    * The buffer can be grown if necessary.
    */
   uint errorMsgSize = ERROR_MSG_SIZE;
   jsecharptr error_msg;

   const jsecharptr SourceFileName = NULL;
   uint SourceLineNumber = 0;
   VarName name;
   jsebool trapped = callErrorTrapped(call);
   rSEVar fptr = STACK_FROM_STACKPTR(call->frameptr);
   uint num_args;
   secode sptr;
   uint i = 0;
#  if defined(__JSE_UNIX__)
     static CONST_STRING(eol,"\n");
#  elif defined(__JSE_MAC__)
     static CONST_STRING(eol,"\r");
#  else
     static CONST_STRING(eol,"\r\n");
#  endif
#  if JSE_MEMEXT_SECODES==1
      ulong iptr_offset;
#  else
      secode iptr;
#  endif

   /* If the error flag is on, lots of stuff doesn't work.
    * We need it to work because we call API functions to build
    * the error object. So, we make it off during this function
    * while building the object, and turn it on at the end.
    */
   CALL_SET_ERROR(call,FlowNoReasonToQuit);

   error_msg = jseMustMalloc( jsecharptrdatum, sizeof(jsechar) * errorMsgSize );

   JSECHARPTR_PUTC((jsecharptr)error_msg,'\0');
   jse_vsprintf((jsecharptr)error_msg,FormatS,arglist);

   assert(bytestrsize_jsechar( error_msg )<errorMsgSize);
   errorMsgSize = strlen_jsechar( error_msg ) + 1;

   if( call->Global->inErrorVPrintf )
      return;

   call->Global->inErrorVPrintf = True;

      /* If possible find line number information and add that */
   if ( secodeSourceLocation(call,&SourceFileName,&SourceLineNumber) &&
        SourceFileName!=NULL )
   {
      const jsecharptr parens = UNISTR("()");
      const jsecharptr ErrorNear = textcoreGet(call,textcoreErrorNear);
      /* We need to copy this because the textcoreGet() below could use the
       * same static buffer.
       */
      fname = callCurrentName(call);
      funcname = LFOM(fname);

      if( strcmp_jsechar(funcname,textcoreInitializationFunctionName)==0 )
         funcname = UNISTR("Global Code"), parens = UNISTR("");

      /*
       * Figure out the basic size of the formatted buffer,
       *
       */
      errorMsgSize += 6 + /* FMT characters */
         2 + /* eol */
         strlen_jsechar(ErrorNear) +
         strlen_jsechar(SourceFileName) +
         18 + /* room for SourceLineNumber */
         strlen_jsechar(funcname) +
         2 /* Parens */;
      error_msg = jseMustReMalloc( jsecharptrdatum, error_msg, sizeof(jsechar) * errorMsgSize );

      jse_sprintf(JSECHARPTR_OFFSET(error_msg,strlen_jsechar(error_msg)),
                  UNISTR("%s%s %s:%d [%s%s]."),
                  eol,
                  ErrorNear,
                  SourceFileName,
                  SourceLineNumber,
                  funcname,
                  parens);
      UFOM(fname);
      assert( strlen_jsechar((jsecharptr)error_msg) < errorMsgSize );
   }


#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
   while( fptr!=call->Global->growingStack )
#  else
   while( fptr!=NULL )
#  endif
   {
      const uint prevMsgLength = errorMsgSize;
      struct Function *func;
      rSEObject robj;
#     if JSE_MEMEXT_SECODES==1
         secode iptr;

         iptr_offset = SEVAR_GET_STORAGE_LONG(fptr-IPTR_OFFSET);
#     else
         iptr = SEVAR_GET_STORAGE_PTR(fptr-IPTR_OFFSET);
#     endif

      iptr = SEVAR_GET_STORAGE_PTR(fptr-IPTR_OFFSET);
      num_args = (uint)SEVAR_GET_STORAGE_LONG(fptr-ARGS_OFFSET);
#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
         fptr = STACK_FROM_STACKPTR(SEVAR_GET_STORAGE_LONG(fptr));
         if( fptr==call->Global->growingStack ) break;
#     else
         fptr = SEVAR_GET_STORAGE_PTR(fptr);
         if( fptr==NULL ) break;
#     endif
      /* restore func func stack */
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(fptr - (num_args + FUNC_OFFSET)));
      func = SEOBJECT_PTR(robj)->func;
      SEOBJECT_UNLOCK_R(robj);

      if( FUNCTION_IS_LOCAL(func) )
      {
         const jsecharptr filename = NULL;
         const jsecharptr funcName;
	 jsecharptr fname;
         uint linenum;
         secode base;

         /* we only print out the last 4 function calls */
         if( i++ > 5 )
            break;

#        if JSE_MEMEXT_SECODES==1
            base = jsememextLockRead(((struct LocalFunction *)func)->op_handle,jseMemExtSecodeType);
            iptr = base + iptr_offset;
#        else
            assert( (iptr-((struct LocalFunction *)func)->opcodes)>=0 );
            assert( (uint)(iptr-((struct LocalFunction *)func)->opcodes)<
                    ((struct LocalFunction *)func)->opcodesUsed );
            base = ((struct LocalFunction *)func)->opcodes;
#        endif

         /* IMPORTANT: This basic algorithm (granted, it is pretty small)
          *    is also used in secodeSourceLocation, and jseStackCallInfo,
          *    so keep that in mind if you change it.
          */

         /* search from beginning to find first function filename before error */

         for( sptr = base;sptr<=iptr;sptr++ )
         {
            if ( seFilename == *sptr )
            {
               filename = GetStringTableEntry(call,SECODE_GET_ONLY(sptr+1,VarName),NULL);
               break;
            }
            sptr += SECODE_DATUM_SIZE(*sptr);
         }
         /* search forward for next line number, it must be there */
         for( sptr = iptr;;sptr++ )
         {
            if ( seLineNumber == *sptr  ||  seContinueFunc == *sptr )
            {
               linenum = SECODE_GET_ONLY(sptr+1,CONST_TYPE);
               break;
            }
            sptr += SECODE_DATUM_SIZE(*sptr);
         }

#        if JSE_MEMEXT_SECODES==1
            jsememextUnlockRead(((struct LocalFunction *)func)->op_handle,base,jseMemExtSecodeType);
#        endif

         if( filename==NULL ) break;

         assert( func!=NULL );

         fname = functionName(func,call);
	 funcName = LFOM(fname);

         errorMsgSize += 18 + /* FMT characters added */
            2 +
            strlen_jsechar(filename) +
            8 +
            strlen_jsechar(funcName);
         error_msg = jseMustReMalloc( jsecharptrdatum, error_msg, sizeof(jsechar) * errorMsgSize );
         jse_sprintf(JSECHARPTR_OFFSET(error_msg,prevMsgLength),
                     UNISTR("%s      from %s:%d [%s()]"),
                     eol,
                     filename,
                     linenum,
                     funcName);
	 UFOM(fname);
      }
   }

   error_obj = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(error_obj);

   {
      const jsecharptr exceptionName;
      JSE_POINTER_UINT exceptionNameLength;
      jsecharptr errorStart;
      VarName originalName;
      wSEVar found = STACK_PUSH;

      SEVAR_INIT_UNDEFINED(found);
      /* Search for our special !exceptionType syntax */
      if( JSECHARPTR_GETC((jsecharptr)error_msg) == UNICHR('!') )
      {
         exceptionName = JSECHARPTR_NEXT((jsecharptr)error_msg);
         exceptionNameLength = strcspn_jsechar(exceptionName,UNISTR(" \t\r\n\v"));
         errorStart = (jsecharptr)JSECHARPTR_OFFSET(exceptionName,exceptionNameLength);
         if( JSECHARPTR_GETC(errorStart) != UNICHR('\0') )
            JSECHARPTR_INC(errorStart);
      }
      else
      {
         exceptionName = EXCEPTION_PROPERTY;
         exceptionNameLength = strlen_jsechar(EXCEPTION_PROPERTY);
         errorStart = (jsecharptr)error_msg;
      }

      /* Exception names and properties seem good candidates for locking - either
       * the program is going to exit, or the user is trapping errors and probably
       * generating a few of them.
       */
      originalName = name = LockedStringTableEntry(call,exceptionName,
                                                   (stringLengthType)exceptionNameLength);

      /* should this be a 'FindGlobalVariable()' call instead? */
      if( !callFindAnyVariable(call,name,False,False) )
      {
         wSEObject wobj;
         wSEObjectMem wMem;

         /* Try and create a basic exception object */
         name = LockedStringTableEntry(call,EXCEPTION_PROPERTY,
                                       (stringLengthType)strlen_jsechar(EXCEPTION_PROPERTY));

         if( !callFindAnyVariable(call,name,False,False) )
         {
         not_error_obj:
            SEVAR_INIT_BLANK_OBJECT(call,error_obj);

            SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(error_obj));
            wMem = SEOBJ_CREATE_MEMBER(call,wobj,originalName);
            SEVAR_INIT_STRING_NULLLEN(call,SEOBJECTMEM_VAR(wMem),UNISTR("Exception"),9);
            SEOBJECTMEM_UNLOCK_W(wMem);

            name = LockedStringTableEntry(call,UNISTR("message"),7);
            wMem = SEOBJ_CREATE_MEMBER(call,wobj,name);
            SEVAR_INIT_STRING_NULLLEN(call,SEOBJECTMEM_VAR(wMem),(jsecharptr)errorStart,strlen_jsechar(errorStart));
            SEOBJECTMEM_UNLOCK_W(wMem);

            /* This is a pseudo-string type, so .toString() will get this */
            name = STOCK_STRING(_value);
            wMem = SEOBJ_CREATE_MEMBER(call,wobj,name);
            SEVAR_INIT_STRING_NULLLEN(call,SEOBJECTMEM_VAR(wMem),(jsecharptr)errorStart,strlen_jsechar(errorStart));
            SEOBJECTMEM_UNLOCK_W(wMem);
            SEOBJECT_UNLOCK_W(wobj);
         }
         else
         {
            VarName nameProperty;
            wSEVar messageVar;
            stringLengthType len;
            const jsecharptr name;

            if( SEVAR_GET_TYPE(found)!=VObject ) goto not_error_obj;

            messageVar = STACK_PUSH;
            SEVAR_INIT_STRING_NULLLEN(call,messageVar,(jsecharptr)errorStart,
                                      strlen_jsechar(errorStart));

            if( !sevarCallConstructor(call,found,messageVar,error_obj) )
            {
               STACK_POP;
               goto not_error_obj;
            }
            else
            {
               STACK_POP;
            }

            /* Now we manually set the 'name' field to be what we want */
            nameProperty = LockedStringTableEntry(call,UNISTR("name"),4);
            SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(error_obj));
            wMem = SEOBJ_CREATE_MEMBER(call,wobj,nameProperty);
            name = GetStringTableEntry(call,originalName,&len);
            SEVAR_INIT_STRING_STRLEN(call,SEOBJECTMEM_VAR(wMem),(jsecharptr)name,len);
            SEOBJECTMEM_UNLOCK_W(wMem);
            SEOBJECT_UNLOCK_W(wobj);
         }
      }
      else
      {
         wSEVar messageVar;

         if( SEVAR_GET_TYPE(found)!=VObject ) goto not_error_obj;

         messageVar = STACK_PUSH;
         SEVAR_INIT_STRING_NULLLEN(call,messageVar,(jsecharptr)errorStart,
                                   strlen_jsechar(errorStart));
         if( !sevarCallConstructor(call,found,messageVar,error_obj) )
         {
            STACK_POP;
            goto not_error_obj;
         }
         else
         {
            STACK_POP;
         }
      }
      STACK_POP;
   }


   if( call->Global->ExternalLinkParms.AtErrorFunc!=NULL )
   {
      struct AtErrorStruct s;
#     if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
         char *FILE = __FILE__;
         int LINE = __LINE__;
#     endif
      jseVariable var = SEAPI_RETURN(call,error_obj,FALSE,UNISTR("AtErrorFunc"));

      s.errorVariable = var;
      s.trapped = trapped;

      CALL_SET_ERROR(call,FlowNoReasonToQuit);

#  if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
      (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
      DispatchToClient(call->Global->ExternalDataSegment,
                       (ClientFunction)(call->Global->ExternalLinkParms.
                                        AtErrorFunc),
                       (void *)call,&s);
#  else
      (*(call->Global->ExternalLinkParms.AtErrorFunc))(call,&s);
#  endif
   }

   CALL_SET_ERROR(call,FlowError);
   SEVAR_COPY(&(call->error_var),error_obj);

   if( !trapped )
   {
      callPrintError(call);
   }

   call->Global->inErrorVPrintf = False;
   jseMustFree( error_msg );
}

   void
callPrintError(struct Call *call)
{
   uint errorMsgSize = ERROR_MSG_SIZE;
   jsecharptr error_msg;
   wSEVar loc = STACK_PUSH;
   rSEVar error = &(call->error_var);

   call->state = 0;

   /* Just convert the error to a string and print it */

   if( call->errorPrinted ) return;
   assert( call->mustPrintError );
   call->errorPrinted = True;

   error_msg = jseMustMalloc( jsecharptrdatum, sizeof(jsechar) * errorMsgSize );

   SEVAR_COPY(loc,error);

   /* If this is a basic string, then the outer application does not support
    * exception objects, so we add our own "Error " at the beginning of the
    * message.  Otherwise, the .toString() method will put the appropriate
    * one there.
    */
   if( SEVAR_GET_TYPE(error) == VString )
      strcpy_jsechar(error_msg,UNISTR("Error "));
   else
      JSECHARPTR_PUTC(error_msg,UNICHR('\0'));

   sevarConvertToString(call,loc);
   if( SEVAR_GET_TYPE(loc)==VString )
   {
      const jsecharptr tmp;
      /* truncate if necessary to not overflow buffer */
      JSE_POINTER_UINDEX len = strlen_jsechar(error_msg);
      jsecharptr offset = JSECHARPTR_OFFSET(error_msg,len);
      tmp = sevarGetData(call,loc);
      strncpy_jsechar(offset,(jsecharptr)tmp,ERROR_MSG_SIZE-len-1);
      SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)tmp);
   }
   else
   {
      strcat_jsechar(error_msg,UNISTR("Can't convert to string."));
   }

   if ( (call->Global->ExternalLinkParms.PrintErrorFunc) )
   {
#     if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) \
      && (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
         DispatchToClient(call->Global->ExternalDataSegment,
                          (ClientFunction)(call->Global->ExternalLinkParms.PrintErrorFunc),
                          (void *)call,(void *)error_msg);
#     else
         (*(call->Global->ExternalLinkParms.PrintErrorFunc))((jseContext)call,
                                                          error_msg);
#     endif
#     if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
         if ( !jseApiOK )
         {
            DebugPrintf(UNISTR("Error calling PrintErrorFunc"));
            DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
         }
#     endif
      assert( jseApiOK );
   }

   STACK_POP;
   call->state = FlowError;
   jseMustFree( error_msg );
}

#pragma codeseg UTIL2_TEXT

   jsenumber
convertStringToNumber(struct Call *call,jsecharptr str,size_t lenStr)
{
   jsenumber val;
   jsecharptr parseEnd;
   size_t lenParsed = 0;

   /* some of the following code relies on our knowledge that data
    * returned from varGetData always has at least one extra null
    * character at the end that is not reported in the length
    */
   assert( strlen_jsechar(str) <= lenStr );

   /* skip whitespace */
   assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
   while ( 0!=JSECHARPTR_GETC(str)  &&  IS_WHITESPACE(JSECHARPTR_GETC(str)) )
   {
      lenParsed++;
      JSECHARPTR_INC(str);
   }

   if ( lenStr <= lenParsed )
   {
      /* a string with only whitespace is 0 for pure ecmascript,
       * NaN if implementor wants math errors warned about
       */
      val = ( jseOptWarnBadMath & call->Global->ExternalLinkParms.options )
          ? jseNaN : jseZero ;
   }
   else
   {
#     ifdef __JSE_UNIX__
      /* Solaris, and possibly other Unixes, parse "Infinity", etc, but they
       * also 'eat' the last '\0' character. The easiest way to get them to
       * work as expected is to just force our own conversion to happen rather
       * than redo the logic.
       */
      assert( sizeof_jsechar('-') == sizeof(jsecharptrdatum) );
      if( isalpha_jsechar(JSECHARPTR_GETC(str))
       || ( JSECHARPTR_GETC(str)=='-'
         && isalpha_jsechar(JSECHARPTR_GETC(str+1))) )
         parseEnd = str;
      else
#     endif
         val = ( 0 == strnicmp_jsechar(str,UNISTR("0x"),2) )
             ? /* hex number */ MY_strtol(str,&parseEnd,16)
#            if (0!=JSE_FLOATING_POINT)
                : /* dec number */ JSE_FP_STRTOD(str,(jsecharptrdatum **)&parseEnd) ;
#            else
                : /* dec number */ MY_strtol(str,&parseEnd,10) ;
#            endif
      /* check that parsing ending because of null-char or whitespace */
      assert( NULL != parseEnd );
      SKIP_WHITESPACE(parseEnd);
      lenParsed += JSECHARPTR_DIFF(parseEnd,str);
      if ( lenParsed == lenStr )
      {
         /* some systems parse "-0" the same as "0", so catch those systems here */
         assert( sizeof_jsechar('-') == sizeof(jsecharptrdatum) );
         if ( '-'==JSECHARPTR_GETC(str)  &&  jseIsPosZero(val) )
         {
            val = jseNegZero;
         }
      }
      else
      {
         /* a character caused parsing to fail.  The only valid
          * characters to cause this are Infinity, +Infinity, or
          * -Infinity, else is jseNaN
          */
         jsebool neg = False;
         assert( sizeof_jsechar('-') == sizeof(jsecharptrdatum) );
         assert( sizeof_jsechar('+') == sizeof(jsecharptrdatum) );
         if ( '-' == JSECHARPTR_GETC(str) )
         {
            JSECHARPTR_INC(str);
            neg = True;
#           if (0!=JSE_FLOATING_POINT)
               lenParsed++;
#           endif
         }
         else if ( '+' == JSECHARPTR_GETC(str) )
         {
            JSECHARPTR_INC(str);
#           if (0!=JSE_FLOATING_POINT)
               lenParsed++;
#           endif
         }
         if ( !strncmp_jsechar(str,textcorevtype_Infinity,8) )
         {

#           if JSE_MBCS==1
               parseEnd = (jsecharptr)(((char *)str)+bytestrlen_jsechar(textcorevtype_Infinity));
#           else
               parseEnd = (jsecharptr)str + 8;
#           endif
            lenParsed += 8;
            while ( JSECHARPTR_GETC(parseEnd)
                 && IS_WHITESPACE(JSECHARPTR_GETC(parseEnd)) )
            {
               lenParsed++;
               JSECHARPTR_INC(parseEnd);
            }
         }
         if ( lenParsed == lenStr )
         {
            val = neg ? jseNegInfinity : jseInfinity ;
         }
         else
         {
            /* all attempts at making a number failed; it is NaN */
            val = jseNaN;
         }
      }
   }
   return val;
}

#if (JSE_COMPILER==1) \
 && ( (defined(JSE_DEFINE) && (0!=JSE_DEFINE)) \
   || (defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)) \
   || (defined(JSE_LINK) && (0!=JSE_LINK)) )
struct PreProcesses_ {
   const jsecharptr Name;
   jsebool (*Function)(struct Source **source,struct Call *call);
   /* return False and print error if problem, else returns True */
};

jsebool PreprocessorDirective(struct Source **source,struct Call *call)
{
   jsebool success;
   static CONST_DATA(struct PreProcesses_) PreProcesses[] = {
#     if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
         { textcoreIncludeDirective,     sourceInclude },
#     endif
#     if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
         { textcoreDefineDirective,      defineProcessSourceStatement },
#     endif
#     if defined(JSE_LINK) && (0!=JSE_LINK)
         { textcoreExtLinkDirective,     extensionLink },
#     endif
      { NULL, NULL } };
   jsecharptr src = sourceGetPtr(*source);

   /* find end of the PreProcessor directive */
   jsecharptr end;
   jsechar tmpChar;
   uint srcLen;
   struct PreProcesses_ const *PrePro;

   assert( '#' == JSECHARPTR_GETC(src) );

   JSECHARPTR_INC(src);
   /* skip spaces before directive */
   SKIP_SAMELINE_WHITESPACE(src);
   end = src;
   srcLen = 0;
   while ( '\0' != (tmpChar=JSECHARPTR_GETC(end))  &&  !IS_SAMELINE_WHITESPACE(tmpChar) )
   {
      JSECHARPTR_INC(end);
      srcLen++;
   } /* endwhile */
   if ( 0 == srcLen  ||  IS_NEWLINE(JSECHARPTR_GETC(end)) )
      goto UnknownDirective;
   /* find this preprocessor directive in the list of known ones */
   for ( PrePro = PreProcesses; NULL != PrePro->Name; PrePro++ ) {
      if ( 0 == strnicmp_jsechar(PrePro->Name,src,(size_t)srcLen)  &&
           srcLen == strlen_jsechar(PrePro->Name) )
      {
         break;
      }
   }

   if ( NULL == PrePro->Name ) {
      UnknownDirective:
      callError(call,textcoreUNRECOGNIZED_PREPROCESSOR_DIRECTIVE,src);
      success = False;
   } else {
      /* increment source beyond directive and up to the
         non-whitespace characters */
      SKIP_SAMELINE_WHITESPACE(end);
      /* call the chosen preprocessor directive routine */
      sourceSetPtr(*source,end);
      success = PrePro->Function(source,call);
   } /* endif */

   return success;
}
#endif


#ifndef NDEBUG
void JSE_CFUNC InstantDeath(enum textcoreID TextID,...)
{
#  if (0!=JSE_FLOATING_POINT) && !defined(__JSE_GEOS__)
      FILE *fp = fopen_jsechar(UNISTR("JSEERROR.LOG"),UNISTR("at"));
      va_list arglist;

      va_start(arglist,TextID);
      if ( fp ) {
         vfprintf_jsechar(fp,textcoreGet(NULL,TextID),arglist);
         fclose(fp);
      }
      va_end(arglist);
#  endif

   assert( False );     /* so if debugging, will stop here. */

   exit(EXIT_FAILURE);
}
#endif

   const jsecharptr
callCurrentName(struct Call *call)
{
   struct Function *func = FUNCPTR;

   return (FRAME!=NULL && func!=NULL) ? functionName(func,call) : UNISTR("");
}

   const jsecharptr
functionName(const struct Function *this,struct Call *call)
{
   return FUNCTION_IS_LOCAL(this)
        ? GetStringTableEntry(call,((struct LocalFunction *)this)->FunctionName,NULL)
        : ((struct LibraryFunction *)this)->FuncDesc->FunctionName ;
}


   void JSE_CFUNC
callError(struct Call *this,enum textcoreID id,...)
{
   if ( FlowError != this->state )
   {
      va_list arglist;
      va_start(arglist,id);
      if(id!=0)
         ErrorVPrintf(this,textcoreGet(this,id),arglist);
      else
         ErrorVPrintf(this,UNISTR(""),arglist);
      va_end(arglist);
   }
   assert( this->Global->inErrorVPrintf || FlowError == this->state );
}

   void JSE_CFUNC
callQuit(struct Call *this,enum textcoreID id,...)
{
   if ( !CALL_QUIT(this) )
   {
      if ( 0 != id )
      {
         va_list arglist;
         va_start(arglist,id);
         ErrorVPrintf(this,textcoreGet(this,id),arglist);
         va_end(arglist);
      }
   }
   assert( this->Global->inErrorVPrintf || CALL_QUIT(this) );
}


void ParseSourceTextIntoArgv(jsecharptr SourceText,uint *_argc, jsecharptr **_argv)
{
   uint argc = *_argc;
   jsecharptr *argv = *_argv;
   jsecharptr endcp; jsecharptr cp;
   jsecharptr TooFar;
   jsechar tmpChar;

   RemoveWhitespaceFromHeadAndTail(SourceText);
   cp = SourceText;
   TooFar = (jsecharptr)((char *)cp + bytestrlen_jsechar(cp));
   if ( '\0' != JSECHARPTR_GETC(cp) )
   {
      assert( !IS_SAMELINE_WHITESPACE(JSECHARPTR_GETC(cp)) );
      while ( TooFar != cp )
      {
         size_t len;

         argv = jseMustReMalloc(jsecharptr,argv,sizeof(jsecharptr) * (++argc));
         /* cp is start of argument, move endcp to the end, including any
          * quotes along the way
          */
         assert( cp < TooFar  &&  JSECHARPTR_GETC(cp)  &&  !IS_SAMELINE_WHITESPACE(JSECHARPTR_GETC(cp)) );
         for ( endcp = cp;
               endcp != TooFar && !IS_SAMELINE_WHITESPACE(tmpChar=JSECHARPTR_GETC(endcp));
             )
         {
            if ( '\"' == tmpChar )
            {
               int quoteLen;
               assert( sizeof_jsechar('\"') == sizeof(jsecharptrdatum) );
               quoteLen = sizeof(jsecharptrdatum);
               /* eat-up this quote, then find matching quote */
               TooFar = (jsecharptr)((char *)TooFar - quoteLen);
               memmove(endcp,(char *)endcp+quoteLen,
                       (size_t)((char *)TooFar - (char *)endcp));
               JSECHARPTR_PUTC(TooFar,'\0');
               if ( NULL == (endcp = strchr_jsechar(endcp,'\"'))  ||  TooFar < endcp )
               {
                  endcp = TooFar;
               }
               else
               {
                  /* remove ending quote */
                  TooFar = (jsecharptr)((char *)TooFar - quoteLen);
                  memmove(endcp,(char *)endcp+quoteLen,
                          (size_t)((char *)TooFar - (char *)endcp));
                  JSECHARPTR_PUTC(TooFar,'\0');
               }
            }
            else
            {
               JSECHARPTR_INC(endcp);
            } /* endif */
         } /* endfor */
         /* len is used number of bytes, not number of characters */
         len = (size_t)((char *)endcp-(char *)cp);
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         argv[argc-1] = (jsecharptr) jseMustMalloc(jsechar,len+sizeof(jsecharptrdatum));
         memcpy(argv[argc-1],cp,len+sizeof(jsecharptrdatum));
         JSECHARPTR_PUTC((jsecharptr)(((char *)(argv[argc-1]))+len),'\0');
         cp = endcp;
         assert( cp <= TooFar );
         if ( cp != TooFar )
         {
            if ( '\"' == JSECHARPTR_GETC(cp) )
               JSECHARPTR_INC(cp);
            while( cp != TooFar  &&  IS_SAMELINE_WHITESPACE(JSECHARPTR_GETC(cp)) )
               JSECHARPTR_INC(cp);
         } /* endif */
         assert( cp <= TooFar );
      } /* end while */
   } /* endif */
   *_argc = argc;
   *_argv = argv;
}

void FreeArgv(uint argc,jsecharptr argv[])
{
   uint i;

   /* free all the argv fields and argv itself */
   for ( i = 0; i < argc; i++ ) {
      assert( NULL != argv[i] );
      jseMustFree(argv[i]);
   }
   jseMustFree(argv);
}

/***************************************************
 ****** infrequent library init/term routines ******
 ***************************************************/

   static struct Library * NEAR_CALL
libraryNew(struct Call *call,struct Library *Parent)
{
   struct Library *this = (struct Library *)jseMallocWithGC(call,sizeof(struct Library));


   this->prev = NULL;
   if ( NULL != Parent )
   {
      /* This 'count' stuff is necessary since we must link the libraries in
       * the same order they were originally added - the stuff at the front
       * of the list was added last.
       */

      int count;
      struct Library *ll;
      int i;

      for ( count = 0, ll = Parent->prev; NULL != ll; ll = ll->prev )
      {
         count++;
      }

      for( i = count - 1;i>=0;i-- )
      {
         int j;
         ll = Parent->prev;
         for( j = 0;j<i;j++ ) ll = ll->prev;

         if( !libraryAddFunctions(this,call,ll->ObjectVarName,ll->FunctionList,
                                  ll->LibInit,
                                  ll->LibTerm,ll->LibraryData) )
         {
            libraryDelete(this,call);
            this = NULL;
            break;
         }
      }
   }
   return this;
}


void libraryDelete(struct Library *this,struct Call *call)
{
   struct Library *loop = this->prev,*tmp;
   while( loop )
   {
      if ( NULL != (loop->LibTerm) )
      {
#        if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) &&\
            (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            DispatchToClient(call->Global->ExternalDataSegment,
                             (ClientFunction)(loop->LibTerm),
                             (void *)(call),loop->LibraryData);
#        else
            (*(loop->LibTerm))(call,loop->LibraryData);
#        endif
#        if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
            if ( !jseApiOK )
            {
               DebugPrintf(UNISTR("Error calling library terminate function"));
               DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
            }
#        endif
         assert( jseApiOK );
      }

      tmp = loop->prev;
      jseMustFree(loop);
      loop = tmp;
   }
   jseMustFree(this);
}

#if JSE_COMPACT_LIBFUNCS==1
   struct LibraryFunction *
libfuncExpand(struct Call *call,wSEVar dest,
              struct jseFunctionDescription const *iFuncDesc,
              void _FAR_ * * LibraryDataPtr)
{
   struct LibraryFunction *this =
      jseMustMalloc(struct LibraryFunction,sizeof(struct LibraryFunction));
   uword8 attribs = (uword8)iFuncDesc->VarAttributes;


#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   if( (iFuncDesc->FuncAttributes & jseFunc_Secure)==0 )
   {
      /* if it is insecure, we must make it ReadOnly and DontDelete or
       * we have a potential security hole
       */
      attribs |= (jseDontDelete|jseReadOnly);
   }
#  endif

   /* Get rid of old 'VLibFunc' value and replace with new blank object
    * to fill in.
    */
   SEVAR_INIT_BLANK_OBJECT(call,dest);

   functionInit(&(this->function),call,dest,
                attribs,False,
                iFuncDesc->FuncAttributes & jseFunc_PassByReference,
#               if 0 != JSE_MULTIPLE_GLOBAL
                   0 == (iFuncDesc->FuncAttributes & jseFunc_NoGlobalSwitch),
#               endif
                (sword16)((iFuncDesc->MaxVariableCount==-1)
                          ?iFuncDesc->MinVariableCount:iFuncDesc->MaxVariableCount));

   assert(NULL != iFuncDesc);
   assert(NULL != iFuncDesc->FuncPtr);

   this->FuncDesc = (struct jseFunctionDescription *)iFuncDesc;
   this->LibData.DataPtr =  LibraryDataPtr;
   this->function.flags |= Func_StaticLibrary;

   return this;
}
#endif

struct LibraryFunction * libfuncNew(struct Call *call,
                                    hSEObject hObjectToAddTo,
                                    struct jseFunctionDescription const *iFuncDesc,
                                    void _FAR_ * * LibraryDataPtr)
{
   struct LibraryFunction *this =
      jseMustMalloc(struct LibraryFunction,sizeof(struct LibraryFunction));
   uword8 attribs = (uword8)iFuncDesc->VarAttributes;
   wSEVar dest = STACK_PUSH;
   wSEVar attribvar = STACK_PUSH;


#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   if( (iFuncDesc->FuncAttributes & jseFunc_Secure)==0 )
   {
      /* if it is insecure, we must make it ReadOnly and DontDelete or
       * we have a potential security hole
       */
      attribs |= (jseDontDelete|jseReadOnly);
   }
#  endif

   SEVAR_INIT_OBJECT(dest,hObjectToAddTo);
   GetDotNamedVar(call,dest,LFOM(iFuncDesc->FunctionName),True);
   UFOM(iFuncDesc->FunctionName);
   SEVAR_COPY(attribvar,dest);
   SEVAR_DEREFERENCE(call,dest);
   functionInit(&(this->function),call,dest,
                attribs,False,
                iFuncDesc->FuncAttributes & jseFunc_PassByReference,
#               if 0 != JSE_MULTIPLE_GLOBAL
                   0 == (iFuncDesc->FuncAttributes & jseFunc_NoGlobalSwitch),
#               endif
                (sword16)((iFuncDesc->MaxVariableCount==-1)
                          ?iFuncDesc->MinVariableCount:iFuncDesc->MaxVariableCount));

   if( attribvar->type==VReference )
   {
      seobjSetAttributes(call,attribvar->data.ref_val.hBase,
                         attribvar->data.ref_val.reference,
                         attribs);
   }

   STACK_POPX(2);
   assert(NULL != iFuncDesc);
   assert(NULL != iFuncDesc->FuncPtr);

   this->FuncDesc = (struct jseFunctionDescription *)iFuncDesc;
   this->LibData.DataPtr =  LibraryDataPtr;
   this->function.flags |= Func_StaticLibrary;

   return this;
}


struct LibraryFunction * libfuncNewWrapper(
               struct Call *call,const jsecharptr iFunctionName,
               void (JSE_CFUNC FAR_CALL *FuncPtr)(jseContext jsecontext),
               sword8 MinVariableCount, sword8 MaxVariableCount,
               jseVarAttributes VarAttributes, jseFuncAttributes FuncAttributes,
               void _FAR_ *fData,rSEVar dest)
{
   struct LibraryFunction *this =
      jseMustMalloc(struct LibraryFunction,sizeof(struct LibraryFunction));

   functionInit(&(this->function),call,dest,0,False,
                FuncAttributes & jseFunc_PassByReference,
#               if 0 != JSE_MULTIPLE_GLOBAL
                   0 == (FuncAttributes & jseFunc_NoGlobalSwitch),
#               endif
                (sword16)((MaxVariableCount==-1)?MinVariableCount:MaxVariableCount));
   assert(NULL != iFunctionName);
   assert(NULL != FuncPtr);
   assert( !(Func_StaticLibrary & this->function.flags) );
   this->FuncDesc =
      jseMustMalloc(struct jseFunctionDescription, \
                    sizeof(struct jseFunctionDescription));
   this->FuncDesc->FunctionName = StrCpyMalloc(iFunctionName);
#ifdef MEM_TRACKING
   call->Global->func_alloc_size += sizeof(struct jseFunctionDescription);
   call->Global->func_alloc_size += jseChunkSize(this->FuncDesc->FunctionName);
#endif
   this->FuncDesc->FuncPtr = FuncPtr;
   this->FuncDesc->MinVariableCount = MinVariableCount;
   this->FuncDesc->MaxVariableCount = MaxVariableCount;
   this->FuncDesc->VarAttributes = VarAttributes;
   this->FuncDesc->FuncAttributes = FuncAttributes;
   this->LibData.Data = fData;

   return this;
}

static void NEAR_CALL libfuncDelete(struct LibraryFunction *this)
{
   if ( !(Func_StaticLibrary & this->function.flags) )
   {
      assert( NULL != this->FuncDesc );
      assert( NULL != this->FuncDesc->FunctionName );
      assert( NULL != this->FuncDesc->FunctionName );
      jseMustFree( (jsecharptr)(this->FuncDesc->FunctionName) );
      jseMustFree(this->FuncDesc);
   }
}

   void
functionDelete(struct Function *this,struct Call *call)
{
   if ( FUNCTION_IS_LOCAL(this) )
      localDelete(call,(struct LocalFunction *)this);
   else
      libfuncDelete((struct LibraryFunction *)this);
   jseMustFree(this);
}

/* ***************************************************************************
 * *** The followinjg function are the external interface to the core that ***
 * *** do not need to be in the small core segment (those in the tight     ***
 * *** segment are in jselib.cpp                                           ***
 * ***************************************************************************
 */

JSE_POINTER_UINDEX
jseGetNameLength(jseContext call,
                 const jsecharptr name )
{
   UNUSED_PARAMETER(call);

   return strlen_jsechar(name);
}

const jsecharptr
jseSetNameLength(jseContext call, const jsecharptr name,
                 JSE_POINTER_UINDEX length)
{
   UNUSED_PARAMETER(call);
   UNUSED_PARAMETER(length);

   return name;
}

   JSECALLSEQ( void _FAR_ * )
jseLibraryData(jseContext call)
{
   struct LibraryFunction *func = (struct LibraryFunction *)(FUNCPTR);

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseLibraryData"),
                  return False);
   assert( call->next==NULL );
   return (Func_StaticLibrary & func->function.flags) ?
      *(func->LibData.DataPtr) : func->LibData.Data;
}

   JSECALLSEQ( uint )
jseFuncVarCount(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseFuncVarCount"),
                  return False);
   assert( call->next==NULL );

   return call->true_args;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyMemberWrapperFunction(jseContext call,jseVariable objectVar,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
      sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData,
      char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jseMemberWrapperFunction(jseContext call,jseVariable objectVar,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
      sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData)
#endif
{
   jseVariable funcvar, membervar;
   JSE_API_STRING(ThisFuncName,"jseMemberWrapperFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(functionName,3,ThisFuncName,return NULL);
   JSE_API_ASSERT_(funcPtr,4,ThisFuncName,return NULL);

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   UNUSED_PARAMETER(FILE);
   UNUSED_PARAMETER(LINE);
#endif
   funcvar = jseCreateWrapperFunction(call,functionName,funcPtr,
                                      minVariableCount,maxVariableCount,
                                      varAttributes,funcAttributes,fData);

   membervar = jseMember(call,objectVar,functionName,jseTypeUndefined);
   jseSetAttributes(call, membervar, 0 );
   /* set to zero in case it existed and might be readonly */
   jseAssign(call,membervar,funcvar);
   jseDestroyVariable(call,funcvar);
   /* since we set the attributes to 0 above, reset them */
   jseSetAttributes(call,membervar,varAttributes);
   return membervar;
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyGlobalObjectEx(jseContext call,jseActionFlags flags,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseGlobalObjectEx(jseContext call,jseActionFlags flags)
#endif
{
   wSEVar g = STACK_PUSH;
   jseVariable ret;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseGlobalObjectEx"),
                  return NULL);
   assert( call->next==NULL );
   SEVAR_INIT_OBJECT(g,CALL_GLOBAL(call));
   ret = SEAPI_RETURN(call,g,(flags & jseCreateVar)?True:False,
                      UNISTR("jseGlobalObjectEx"));
   STACK_POP;
   return ret;
}

   JSECALLSEQ( const jsecharptr )
jseLocateSource(jseContext call,uint *lineNumber)
{
   const jsecharptr FileName;
   JSE_API_STRING(ThisFuncName,"jseLocateSource");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(lineNumber,2,ThisFuncName,return NULL);

   if ( !secodeSourceLocation(call,&FileName,lineNumber) )
      FileName = NULL;
   return FileName;
}

   JSECALLSEQ( const jsecharptr )
jseCurrentFunctionName(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseCurrentFunctionName"),
                  return NULL);
   assert( call->next==NULL );
   return callCurrentName(call);
}

   JSECALLSEQ(jseContext)
jseAppExternalLinkRequest(jseContext call,jsebool Initialize)
{
   jseAppLinkFunc AppLinkFunc;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseAppExternalLinkRequest"),
                  return NULL);
   assert( call->next==NULL );

   AppLinkFunc = call->Global->ExternalLinkParms.AppLinkFunc;
   return ( NULL == AppLinkFunc ) ? (jseContext)NULL :
      (*AppLinkFunc)(call,Initialize) ;
}


#if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
   JSECALLSEQ(jsecharptr *)
jseGetFileNameList(jseContext call,int *number)
{
   JSE_API_STRING(ThisFuncName,"jseGetFileNameList");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(number,2,ThisFuncName,return NULL);

   return CALL_GET_FILENAME_LIST(call,number);
}
#endif

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyGetCurrentThisVariable(jseContext call,char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jseGetCurrentThisVariable(jseContext call)
#endif
{
   wSEVar this;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseGetCurrentThisVariable"),
                  return NULL);
   assert( call->next==NULL );


   if( FRAME==NULL )
   {
      /* no function, global is 'this' */
      jseVariable ret;
      this = STACK_PUSH;
      SEVAR_INIT_OBJECT(this,CALL_GLOBAL(call));
      ret = SEAPI_RETURN(call,this,FALSE,UNISTR("jseGetCurrentThisVariable"));
      STACK_POP;
      return ret;
   }
   else
   {
      this = CALL_THIS;
      return SEAPI_RETURN(call,this,FALSE,UNISTR("jseGetCurrentThisVariable"));
   }
}


   JSECALLSEQ( jseStack )
jseCreateStack(jseContext jsecontext)
{
   struct seCallStack *This = jseMustMalloc(struct seCallStack,
                                            sizeof(struct seCallStack));
   UNUSED_PARAMETER(jsecontext);
#  if ( 2 <= JSE_API_ASSERTLEVEL )
      This->cookie = (ubyte) jseStack_cookie;
#  endif
   This->vars = jseMustMalloc(struct seCallStackVar,sizeof(This->vars[0]));
   This->Count = 0;
   return This;
}

   JSECALLSEQ( void )
jsePush(jseContext call,jseStack jsestack,jseVariable var,
        jsebool DeleteVariableWhenFinished)
{
   JSE_API_STRING(ThisFuncName,"jsePush");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseQuitFlagged"),
                    return);
   assert( call->next==NULL );
   JSE_API_ASSERT_C(jsestack,2,jseStack_cookie,ThisFuncName,return);

   secallstackPush(/*call,*/jsestack,var,DeleteVariableWhenFinished);
}

   JSECALLSEQ( uint )
jseQuitFlagged(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseQuitFlagged"),
                  return True);
   assert( call->next==NULL );

   assert( JSE_CONTEXT_ERROR == JSE_DEBUG_FEEDBACK(FlowError) );
   assert( JSE_CONTEXT_EXIT == JSE_DEBUG_FEEDBACK(FlowExit) );
   if ( CALL_QUIT(call) )
   {
      assert( JSE_CONTEXT_ERROR == call->state || \
              JSE_CONTEXT_EXIT == call->state );
      return call->state;
   }
   return 0;
}


   JSECALLSEQ( jseContext )
jseCurrentContext(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseCurrentContext"),
                  return NULL);
   while( call->next ) call = call->next;
   return call;
}

   JSECALLSEQ(jsebool)
jseGetVariableName(jseContext call,jseVariable variableToFind,
                   jsecharptr const buffer, uint bufferSize)
{
   JSE_API_STRING(ThisFuncName,"jseFindName");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,
                    return False);
   assert( call->next==NULL );

   /* We want to leave it as a reference, because that makes
    * it MUCH easier to give it a name, in fact in many cases,
    * it makes it possible to do so.
    */
   return FindNames(call,seapiGetValue(call,variableToFind),buffer,bufferSize,UNISTR(""));
}

#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   JSECALLSEQ( void )
jseDestroyCodeTokenBuffer(jseContext call, jseTokenRetBuffer buffer )
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseDestroyCodeTokenBuffer"),return);
   assert( call->next==NULL );

   jseMustFree(buffer);
}
#endif


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyCurrentFunctionVariable(jseContext call,char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jseCurrentFunctionVariable(jseContext call)
#endif
{
   rSEVar var;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseCurrentFunctionVariable"),return NULL);
   assert( call->next==NULL );


   var = FUNCVAR;
   return SEAPI_RETURN(call,var,FALSE,UNISTR("jseCurrentFunctionVariable"));
}

#if (0!=JSE_COMPILER) || (defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC))
#if 0
old    VarName
old AppendVarnamesWithDot(struct Call *call,VarName name1,VarName name2)
old    /* get two varnames and return one with the names concatenated.
old     * e.g. foo and goo become foo.goo
old     */
old {
old    const jsecharptr NameStr1;
old    const jsecharptr NameStr2;
old    stringLengthType NameLen1, NameLen2, NewNameLen;
old    stringLengthType NameSize1, NameSize2, NewNameSize;
old    VarName NewName;
old    jsecharptr NewNameStr;
old
old    /* retrieve old names as varnames */
old    NameStr1 = GetStringTableEntry(call,name1,&NameLen1);
old    assert( NULL != NameStr1 );
old    NameStr2 = GetStringTableEntry(call,name2,&NameLen2);
old    assert( NULL != NameStr2 );
old
old    /* convert character lengths to byte lengths */
old    NameSize1 = BYTECOUNT_FROM_STRLEN(NameStr1,NameLen1);
old    NameSize2 = BYTECOUNT_FROM_STRLEN(NameStr2,NameLen2);
old
old    /* create buffer big enough for both names plus the dot */
old    NewNameLen = NameLen1 + 1 + NameLen2;
old    assert( sizeof_jsechar('.') == sizeof(jsecharptrdatum) );
old    NewNameSize = NameSize1 + sizeof(jsecharptrdatum) + NameSize2;
old    NewNameStr = (jsecharptr) jseMustMalloc(jsechar,NewNameSize);
old
old    /* move data into the big buffer, with dot in the middle */
old    memcpy(NewNameStr,NameStr1,NameSize1);
old    JSECHARPTR_PUTC((((char *)NewNameStr)+NameSize1),'.');
old    assert( sizeof_jsechar('.') == sizeof(jsecharptrdatum) );
old    memcpy(((char *)NewNameStr)+NameSize1+sizeof(jsecharptrdatum),
old           NameStr2,NameSize2);
old
old    /* This routine is used for parsing code - stuff that needs to get
old     * locked.
old     */
old    NewName = LockedStringTableEntry(call,NewNameStr,NewNameLen);
old
old    jseMustFree(NewNameStr);
old
old    return NewName;
old }
#endif
#endif

#if defined(JSE_BREAKPOINT_TEST) && (0!=JSE_BREAKPOINT_TEST)
   JSECALLSEQ(jsebool)
jseBreakpointTest(jseContext call,const jsecharptr FileName,
                  uint LineNumber)
{
   JSE_API_STRING(ThisFuncName,"jseBreakpointTest");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );
   JSE_API_ASSERT_(FileName,2,ThisFuncName,return False);

   return callBreakpointTest(call,CALL_GLOBAL(call),FileName,LineNumber,1);
}
#endif


   JSECALLSEQ( void )
jseGetFloatIndirect(jseContext call,jseVariable variable,
                    jsenumber *GetFloat)
{
   JSE_API_STRING(ThisFuncName,"jseGetFloatIndirect");
   JSE_API_ASSERT_(GetFloat,3,ThisFuncName,return);


   *GetFloat = GENERIC_GET_NUMBER(ThisFuncName,call,variable/*,VNumber*/);
}

   JSECALLSEQ( slong )
jseGetLong(jseContext call,jseVariable variable)
{
   return JSE_FP_CAST_TO_SLONG(GENERIC_GET_NUMBER(UNISTR("jseGetLong"),call,variable/*,VNumber*/));
}
   JSECALLSEQ( jsebool )
jseGetBoolean(jseContext call,jseVariable variable)
{
   jsenumber n = GENERIC_GET_NUMBER(UNISTR("jseGetBoolean"),call,variable/*,VBoolean*/);
   return jseIsZero(n) ? False : True ;
}

   JSECALLSEQ( const jsecharhugeptr )
jseGetString(jseContext call,jseVariable variable,
             JSE_POINTER_UINDEX *filled)
{
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *FILE = __FILE__;
   int LINE = __LINE__;
#endif
   return (const jsecharhugeptr )
      GENERIC_GET_DATAPTR(UNISTR("jseGetString"),call,variable,filled,
                          VString,False);
}

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   JSECALLSEQ( const void _HUGE_ * )
jseGetBuffer(jseContext call,jseVariable variable,
             JSE_POINTER_UINDEX *filled)
{
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *FILE = __FILE__;
   int LINE = __LINE__;
#endif
   return (const void _HUGE_ *)
      GENERIC_GET_DATAPTR(UNISTR("jseGetBuffer"),call,variable,filled,
                          VBuffer,False);
}
#endif
   JSECALLSEQ( jsecharhugeptr )
jseGetWriteableString(jseContext call,jseVariable variable,
                      JSE_POINTER_UINDEX *filled)
{
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *FILE = __FILE__;
   int LINE = __LINE__;
#endif
   return (jsecharhugeptr )
      GENERIC_GET_DATAPTR(UNISTR("jseGetWriteableString"),call,variable,
                          filled,VString,True);
}
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   JSECALLSEQ( void _HUGE_ * )
jseGetWriteableBuffer(jseContext call,jseVariable variable,
                      JSE_POINTER_UINDEX *filled)
{
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *FILE = __FILE__;
   int LINE = __LINE__;
#endif
   return (jsecharhugeptr )
      GENERIC_GET_DATAPTR(UNISTR("jseGetWriteableBuffer"),call,variable,
                          filled,VBuffer,True);
}
#endif

   JSECALLSEQ( void )
jsePutString(jseContext call,jseVariable variable,
             const jsecharhugeptr data)
{
   GENERIC_PUT_DATAPTR(UNISTR("jsePutString"),call,variable,
                       (void _HUGE_ *)data,VString,NULL);
}
   JSECALLSEQ( void )
jsePutStringLength(jseContext call,jseVariable variable,
                   const jsecharhugeptr data,
                   JSE_POINTER_UINDEX size)
{
   GENERIC_PUT_DATAPTR(UNISTR("jsePutStringLen"),call,variable,
                       (void _HUGE_ *)data,VString,&size);
}
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   JSECALLSEQ( void )
jsePutBuffer(jseContext call,jseVariable variable,
             const void _HUGE_ *data,
             JSE_POINTER_UINDEX size)
{
   GENERIC_PUT_DATAPTR(UNISTR("jsePutStringLen"),call,variable,
                       (void _HUGE_ *)data,VBuffer,&size);
}
#endif

static JSE_POINTER_UINDEX CopyPtrData(
#  if (0!=JSE_API_ASSERTNAMES)
      const jsecharptr ThisFuncName,
#  endif
   jseContext call,jseVariable variable,void _HUGE_ *buffer,
   JSE_POINTER_UINDEX start,JSE_POINTER_UINDEX length,
   jseVarType vType)
{
   JSE_POINTER_UINDEX filled;
   const void _HUGE_ *data;
   JSE_POINTER_UINDEX CopyLen;

#if !defined(NDEBUG) && JSE_TRACKVARS==1
   char *FILE = __FILE__;
   int LINE = __LINE__;
#endif

   assert( SEVAR_IS_VALID_TYPE(vType) );
   data = GENERIC_GET_DATAPTR(ThisFuncName,call,variable,&filled,
                              vType,False);
   if ( NULL == data )
      return 0;

   if( (start+length)>filled )
   {
      length = filled-start;
      if( start>filled || length==0 )
         return 0;
   }
   CopyLen = length;
#  if (JSE_MBCS==1) || (JSE_UNICODE==1)
   if ( VString == vType )
   {
      /* jsechars can take up extra room */
      start = BYTECOUNT_FROM_STRLEN(data,start);
      CopyLen = BYTECOUNT_FROM_STRLEN(HugePtrAddition(data,start),CopyLen);
   }
#  endif  /* if (JSE_MBCS==1) || (JSE_UNICODE==1) */
   HugeMemMove(buffer,HugePtrAddition(data,start),CopyLen);

   return length;
}

#if (0!=JSE_API_ASSERTNAMES)
#  define COPY_PTR_DATA(FNAME,CNTXT,VAR,BUF,START,LEN,VTYPE) \
            CopyPtrData(FNAME,CNTXT,VAR,BUF,START,LEN,VTYPE)
#else
#  define COPY_PTR_DATA(FNAME,CNTXT,VAR,BUF,START,LEN,VTYPE) \
            CopyPtrData(CNTXT,VAR,BUF,START,LEN,VTYPE)
#endif
   JSECALLSEQ( JSE_POINTER_UINDEX )
jseCopyString(jseContext call,jseVariable variable,
              jsecharhugeptr buffer,
              JSE_POINTER_UINDEX start,JSE_POINTER_UINDEX length)
{
   return COPY_PTR_DATA(UNISTR("jseCopyString"),call,variable,buffer,start,
                        length,VString);
}
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   JSECALLSEQ( JSE_POINTER_UINDEX )
jseCopyBuffer(jseContext call,jseVariable variable,void _HUGE_ *buffer,
              JSE_POINTER_UINDEX start,JSE_POINTER_UINDEX length)
{
   return COPY_PTR_DATA(UNISTR("jseCopyBuffer"),call,variable,buffer,start,
                        length,VBuffer);
}
#endif

   JSECALLSEQ(void _FAR_ *)
jseGetSharedData(jseContext call, const jsecharptr name)
{
   struct sharedDataNode * current = call->Global->sharedDataList;

   while( current != NULL )
   {
      if( 0 == strcmp_jsechar( current->name, name ) )
         return current->data;

      current = current->next;
   }

   return NULL;
}

   JSECALLSEQ(void)
jseSetSharedData(jseContext call, const jsecharptr name,
                 void _FAR_ * data,jseShareCleanupFunc cleanupFunc)
{
   struct sharedDataNode * current = call->Global->sharedDataList;
   struct sharedDataNode * newNode;

   while( current != NULL )
   {
      if( 0 == strcmp_jsechar( current->name, name ) )
      {
         if( current->cleanupFunc != NULL )
            current->cleanupFunc( current->data );
         current->data = data;
         current->cleanupFunc = cleanupFunc;
         return;
      }

      current = current->next;
   }

   newNode = jseMustMalloc( struct sharedDataNode,
                            sizeof(struct sharedDataNode) );

   newNode->next = call->Global->sharedDataList;
   newNode->data = data;
   newNode->name = StrCpyMalloc(name);
   newNode->cleanupFunc = cleanupFunc;

   call->Global->sharedDataList = newNode;
}



   JSECALLSEQ( void )
jseLibSetErrorFlag(jseContext call)
{
   assert( NULL != call );
   if( NULL == call )
   {
      return;
   }
   SEVAR_COPY(&(call->error_var),STACK0);
   CALL_SET_ERROR(call,FlowError);
}


   JSECALLSEQ_CFUNC( void )
jseLibErrorPrintf(jseContext call,const jsecharptr formatS,...)
{
   va_list arglist;

   assert( NULL != call );
   if( NULL == call)
   {
      return;
   }
   va_start(arglist,formatS);
   ErrorVPrintf(call,formatS,arglist);
   va_end(arglist);
}


#if JSE_OBJECTDATA != 0
   JSECALLSEQ(void)
jseSetObjectData(jseContext call,jseVariable variable,
                 void _FAR_ *data)
{
   rSEVar var;

   JSE_API_STRING(ThisFuncName,"jseSetObjectData");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   var = seapiGetValue(call,variable);
   if( VObject == SEVAR_GET_TYPE(var) )
   {
      wSEObject wobj;
      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(var));
      SEOBJECT_PTR(wobj)->data = data;
      SEOBJECT_UNLOCK_W(wobj);
   }
#  if ( 0 < JSE_API_ASSERTLEVEL )
   else
   {
      SetLastApiError( UNISTR("%s: variable is not an object"),ThisFuncName );
   }
#  endif
}

   JSECALLSEQ(void _FAR_ *)
jseGetObjectData(jseContext call,jseVariable variable)
{
   rSEVar var;
   void _FAR_ * ret = NULL;

   JSE_API_STRING(ThisFuncName,"jseGetObjectData");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   var = seapiGetValue(call,variable);
   if( VObject == SEVAR_GET_TYPE(var) )
   {
      rSEObject robj;
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(var));
      ret = SEOBJECT_PTR(robj)->data;
      SEOBJECT_UNLOCK_R(robj);
   }
#  if ( 0 < JSE_API_ASSERTLEVEL )
   else
   {
      SetLastApiError( UNISTR("%s: variable is not an object"),ThisFuncName );
   }
#  endif
   return ret;
}
#endif


   JSECALLSEQ(void)
jseGarbageCollect(jseContext jsecontext,uint action)
{
   JSE_API_STRING(ThisFuncName,"jseGarbageCollect");

   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,ThisFuncName,return);

   switch( action )
   {
      case JSE_GARBAGE_COLLECT:
      {
         uword16 old = jsecontext->Global->collect_disable;
         jsecontext->Global->collect_disable = 0;

         garbageCollect(jsecontext);

         /* by adding it, if anyone has since mucked with this, we
          * preserve it.
          */
         jsecontext->Global->collect_disable += old;
         break;
      }
      case JSE_GARBAGE_OFF:
         jsecontext->Global->collect_disable++;
         break;
      case JSE_GARBAGE_ON:
         jsecontext->Global->collect_disable--;
         break;
#     ifndef NDEBUG
      case JSE_COLLECT_AND_ANALYZE:
         seInternalAnalysis(jsecontext);
         break;
#     endif
   }
}


   void
DescribeInvalidVar(struct Call *this,rSEVar v,jseDataType vType,
                   const struct Function *FuncPtrIfObject,jseVarNeeded need,
                   struct InvalidVarDescription *BadDesc)
{
   const jsecharptr TypeWeGot = NULL;
   jsechar ValidBuf[sizeof(BadDesc->VariableWanted)];


   /* The new textcoreGet puts it to a fixed internal buffer, so we
    * can't 'save' the pointers
    */


   /* prepare variable name if we can figure it out */
   if ( FindNames(this,v,JSECHARPTR_OFFSET((jsecharptr)BadDesc->VariableName,1),
                  sizeof(BadDesc->VariableName)-3,UNISTR("")) )
   {
      JSECHARPTR_PUTC((jsecharptr)BadDesc->VariableName,UNICHR('('));
      strcat_jsechar((jsecharptr)BadDesc->VariableName,UNISTR(") "));
   }

   /* prepare variable to show what type of buffer we did get */
   switch ( vType )
   {
      case VUndefined:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_UNDEFINED);
         break;
      case VNull:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_NULL);
         break;
      case VBoolean:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_BOOLEAN);
         break;
      case VObject:
         TypeWeGot =  NULL == FuncPtrIfObject
                                  ? textcoreGet(this,textcorePARAM_TYPE_OBJECT)
                                  : textcoreGet(this,textcorePARAM_TYPE_FUNCTION_OBJECT) ;
         break;
      case VString:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_STRING);
         break;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_BUFFER);
         break;
#     endif
      case VNumber:
         TypeWeGot = textcoreGet(this,textcorePARAM_TYPE_NUMBER);
         break;
   }
   assert( bytestrlen_jsechar(TypeWeGot) < sizeof(BadDesc->VariableType) );
   strcpy_jsechar((jsecharptr)BadDesc->VariableType,TypeWeGot);

   /* prepare string showing what types would have been valid */
   memset(ValidBuf,0,sizeof(ValidBuf));
   if ( need & JSE_VN_UNDEFINED )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_UNDEFINED));
   }
   if ( need & JSE_VN_NULL )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_NULL));
   }
   if ( need & JSE_VN_BOOLEAN )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_BOOLEAN));
   }
   if ( need & JSE_VN_OBJECT )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OBJECT));
   }
   if ( need & JSE_VN_STRING )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_STRING));
   }
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( need & JSE_VN_BUFFER )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_BUFFER));
   }
#  endif
   if ( need & JSE_VN_NUMBER )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_NUMBER));
   }
   if ( need & JSE_VN_FUNCTION )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_FUNCTION_OBJECT));
   }
   if ( need & JSE_VN_BYTE )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_BYTE));
   }
   if ( need & JSE_VN_INT )
   {
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_OR));
      strcat_jsechar((jsecharptr)ValidBuf,textcoreGet(this,textcorePARAM_TYPE_INT));
   }
   assert( bytestrlen_jsechar((jsecharptr)ValidBuf) < sizeof(ValidBuf) );
   strcpy_jsechar( (jsecharptr)BadDesc->VariableWanted,
                   (jsecharptr)((char *)ValidBuf +
                                bytestrlen_jsechar(textcoreGet(this,textcorePARAM_TYPE_OR))));
}

#if (0!=JSE_COMPILER)
   ulong
BaseToULong(const jsecharptr HexStr,uint Base,uint MaxStrLen,
            ulong MaxResult,uint *CharsUsed)
{
   ulong i, prev_i;
   uint Used;
   uint c;

   for ( i = prev_i = 0, Used = 0; 0 < MaxStrLen;
         MaxStrLen--, JSECHARPTR_INC(HexStr), Used++ )
   {
      c = (uint) toupper_jsechar(JSECHARPTR_GETC((jsecharptr)HexStr));
      if ( '0' <= c  &&  c <= '9' )
      {
         c -= '0';
      }
      else if ( 'A' <= c )
      {
         c -= ('A' - 10);
      }
      else
      {
         break;
      } /* endif */
      if ( Base <= c )
      {
         break;
      } /* endif */
      i = (i * Base) + c;
      if ( MaxResult < i  ||  i < prev_i/*rollover*/ )
      {
         i = prev_i;
         break;
      } /* endif */
   } /* endfor */
   if ( NULL != CharsUsed )
   {
      *CharsUsed = Used;
   } /* endif */
   return(i);
}
#endif

   jsenumber
SEVAR_GET_NUMBER_VALUE(rSEVar v)
{
   if ( v->type == VNumber )
      return v->data.num_val;
   if ( v->type == VBoolean )
      return v->data.bool_val ? jseOne : jseZero ;
   if ( v->type == VNull )
      return jseZero;
   if ( v->type == VUndefined )
      return jseNaN;
   return jseOne;
}

#if defined(JSE_INLINES) && (0==JSE_INLINES)
   void
CALL_KILL_TEMPVARS(struct Call *call,seAPIVar mark)
{
   CALL_KILL_TEMPVARS_GUTS(call,mark);
}
#endif

#if 0!=JSE_MEMEXT_OBJECTS
void NEAR_CALL CALL_REMOVE_SCOPE_OBJECT(struct Call *call)
{
   wSEObject wobj;
   SEOBJECT_ASSIGN_LOCK_W(wobj,call->hScopeChain);
   SEOBJECT_PTR(wobj)->used--;
   SEOBJECT_UNLOCK_W(wobj);
}
#endif
