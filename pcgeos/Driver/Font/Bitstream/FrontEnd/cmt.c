/***********************************************************************
 *
 *	Copyright (c) Geoworks 1993 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	FrontEnd/cmt.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: cmt.c,v 1.1 97/04/18 11:45:09 newdeal Exp $
 *
 ***********************************************************************/

#if PROC_TYPE1 || PROC_TRUETYPE
#undef CMT_PS
#define CMT_PS 1
#undef CMT_UNI
#define CMT_UNI 1
#endif

#pragma Code ("ConvertCode")

/******************************************************************************
 *                                                                            *
 *  Copyright 1992, as an unpublished work by Bitstream Inc., Cambridge, MA   *
 *                               Patent Pending                               *
 *                                                                            *
 *         These programs are the sole property of Bitstream Inc. and         *
 *           contain its proprietary and confidential information.            *
 *                           All rights reserved                              *
 *                                                                            *
 *
 * Revision 2.19  93/03/15  13:53:18  roberte
 * Release
 * 
 * Revision 2.8  93/03/11  15:56:58  roberte
 * Changed #if __MSDOS to #ifdef MSDOS.
 * 
 * Revision 2.7  93/03/09  12:06:10  roberte
 *  Replaced #if INTEL tests with #ifdef MSDOS as appropriate.
 * 
 * Revision 2.6  93/02/23  16:55:25  roberte
 * Added #include of finfotbl.h before #include of ufe.h.
 * 
 * Revision 2.5  93/02/08  13:07:12  roberte
 * Added PROTO macro to extern of GlyphNumElements()
 * 
 * Revision 2.4  93/01/27  15:26:21  roberte
 * Added reentrant code PARAMS and stuff
 * 
 * Revision 2.3  92/12/15  13:33:57  roberte
 * Change all prototype type function declarations to
 * standard declarations ala K&R.
 * 
 * Revision 2.2  92/12/09  16:38:25  laurar
 * add STACKFAR to pointers.
 * 
 * Revision 2.1  92/12/02  12:27:04  laurar
 * include fino.h.
 * 
 * Revision 2.0  92/11/19  15:38:04  roberte
 * Release
 * 
 * Revision 1.10  92/11/05  13:04:11  weili
 * In fi_CharCodeXlate, tested if inCharprotocol equals to outCharprotocol, and avoid doing translation
 * if it's true
 * 
 * Revision 1.9  92/11/03  13:55:06  laurar
 * inlucd
 * include type1.h for CHARACTERNAME declaration.
 * 
 * Revision 1.8  92/11/02  18:32:06  laurar
 * Add WDECL macro (for Windows CALLBACK) and STACKFAR for pointers.
 * These changes are for DLL.
 * 
 * Revision 1.7  92/10/15  17:34:58  roberte
 * Added support for PROTOS_AVAIL compile time option.
 * 
 * Revision 1.6  92/10/14  17:09:16  roberte
 * In fi_CharCodeXLate(), changed strPtr to plain char *, set
 * it to outValue in protoPSname branch, and strcpy the name there.
 * 
 * Revision 1.5  92/10/01  13:52:31  roberte
 * Added macros to shut off individual columns in the character mapping, and
 * saved some code in this module ifdefing out case branches.
 * 
 * Revision 1.4  92/09/26  16:44:32  roberte
 * Added copyright header and RCS markers. Added comments.
 * 
 * 
******************************************************************************/
/***********************************************************************************************
    FILE:       CMT.C
	PROJECT:	4-in-1
	AUTHOR:		WT
	CONTENTS:	Routines for translating canonical ID's
				
				fix15 NumComp  ()
				fix15 StrComp ()
				void  GlyphTableSort ()
				fix15    GlyphCompare ()
				boolean  BSearch ()
				boolean  BinarySearchGlyphTable  ()
				boolean  fi_CharCodeXLate  ()
***********************************************************************************************/
#include <Ansi/string.h>
#include "spdo_prv.h"               /* General definitions for Speedo    */
#include "fino.h"
#include "type1.h"
#include "finfotbl.h"
#include "ufe.h"


/* 
	EXTERNALS
*/
extern GlyphCodes  gMasterGlyphCodes [];
extern   ufix16 GlyphNumElements PROTO((void));

/*
	STATICS 
*/
static   fix7  gCurrentSort = UNKNOWN;
static   ufix16   aGlyphType;


/*************************************************************************************
*	NumComp()
*		Compares values pointed to by 2 ufix16 pointers.
*	RETURNS:	
*			-1 if value1 < value2
*			 0 if value1 == value2
*			 1 if value1 > value2
*************************************************************************************/
FUNCTION fix15 NumComp  (value1, value2)
ufix16 STACKFAR *value1, STACKFAR*value2;
{

   if ( *value1 < *value2 )
      return ( -1 );
   else if ( *value1 == *value2 )
      return ( 0 );
   else
      return ( 1 );
}

/*************************************************************************************
*	StrComp()
*		Compares values pointed to by 2 char **pointers.
*		Calls strcmp()
*	RETURNS:	
*			-1 if str1 < str2
*			 0 if str1 == str2
*			 1 if str1 > str2
*************************************************************************************/
FUNCTION fix15 StrComp (str1, str2)
char STACKFAR *STACKFAR*str1;
char STACKFAR*STACKFAR*str2;
{
   fix15	result;

#ifdef MSDOS
/*   result =  _fstrcmp (*str1, *str2);*/
   result =  strcmp (*str1, *str2);
#else
   result =  strcmp (*str1, *str2);
#endif
   if ( result < 0 )
      return ( -1 );
   else if ( result == 0 )
      return ( 0 );
   else 
      return ( 1 );
}


/*************************************************************************************
*	GlyphTableSort ()
*		Sorts the Glyph translation table based on keyField (eFontProtocol)
*		This is an insertion sort.
*************************************************************************************/
FUNCTION void  GlyphTableSort (keyField)
ufix16  keyField;
{
   ufix16      i, j, fieldOffset;
   GlyphCodes  temp_table;
   boolean     found_place;
   fix15       result, (*Comp) ();
   char        STACKFAR*originPtr;

   gCurrentSort = keyField;
   originPtr = (char STACKFAR*)&gMasterGlyphCodes[0];


   if ( keyField == protoPSName )
      Comp = StrComp;
   else
      Comp = NumComp;

   switch ( keyField )
   {
      case  protoBCID      :
            fieldOffset = (ufix16)((char STACKFAR*)( &gMasterGlyphCodes[0].BCID) - originPtr);
            break;
#if CMT_UNI
      case  protoUnicode   :
            fieldOffset = (ufix16)((char STACKFAR*)( &gMasterGlyphCodes[0].Unicode) - originPtr);
            break;
#endif
#if CMT_PS
      case  protoPSName    :
            fieldOffset = (ufix16)((char STACKFAR*)( &gMasterGlyphCodes[0].PSName) - originPtr);
            break;
#endif
#if CMT_MSL
      case  protoMSL       :
            fieldOffset = (ufix16)((char STACKFAR*)( &gMasterGlyphCodes[0].MSL) - originPtr);
            break;
#endif
#if CMT_USR
      case  protoUser      :
            fieldOffset = (ufix16)((char STACKFAR*)( &gMasterGlyphCodes[0].User) - originPtr);
            break;
#endif
      default  :
            break;
   }
      
   for ( i=1; i < GlyphNumElements(); i++ )
   {
      result = (*Comp) ( (char STACKFAR*)&gMasterGlyphCodes[i] + fieldOffset,
                         (char STACKFAR*)&gMasterGlyphCodes[i-1] + fieldOffset );                                                       
      if ( result == LESS_THAN )
      {   
         j = i;
         temp_table = gMasterGlyphCodes [i];
         found_place = FALSE;
         do 
         {
            j--;
            gMasterGlyphCodes [j+1] = gMasterGlyphCodes [j];
            if ( j == 0 )
               found_place = TRUE;
            else
            {
               result = (*Comp) ((char STACKFAR*)&gMasterGlyphCodes[j-1] + fieldOffset,
                                 (char STACKFAR*)&temp_table + fieldOffset );
               found_place = ( result == LESS_THAN );
            }              
         } while (!found_place) ;
         gMasterGlyphCodes[j] = *(GlyphCodes STACKFAR*)&temp_table;
      }/* if */                        
   }
}


/*************************************************************************************
*	GlyphCompare ()
*		Comparison function called by BSearch() when binary searching GlyphTable
*		Compares ambiguous data type input keyValue with some field at index idx
*		of gMasterGlyphCodes[]
*	RETURNS:
*		-1, 0 or 1 (somewhat like strcmp())
*************************************************************************************/
FUNCTION fix15    GlyphCompare (PARAMS2 idx, keyValue)
GDECL
fix31 idx;
void STACKFAR *keyValue;
{
   ufix16   STACKFAR *numberPtr;
   char     STACKFAR *STACKFAR*strPtr;
   fix15    result;

   if ( aGlyphType == protoPSName )
       strPtr = (void STACKFAR*)&keyValue;
   else
      numberPtr = keyValue;

      switch ( aGlyphType )
      {
         case  protoBCID      :
               result = NumComp( numberPtr, (ufix16 STACKFAR*)&gMasterGlyphCodes[idx].BCID );
               break;
#if CMT_UNI
         case  protoUnicode   :
               result = NumComp( numberPtr, (ufix16 STACKFAR*)&gMasterGlyphCodes[idx].Unicode );
               break;
#endif
#if CMT_PS
         case  protoPSName    :
               result = StrComp( strPtr, (char STACKFAR* STACKFAR*)&gMasterGlyphCodes[idx].PSName );
               break;
#endif
#if CMT_MSL
         case  protoMSL       :
               result = NumComp( numberPtr, (ufix16 STACKFAR*)&gMasterGlyphCodes[idx].MSL );
               break;
#endif
#if CMT_USR
         case  protoUser      :
               result = NumComp( numberPtr, (ufix16 STACKFAR*)&gMasterGlyphCodes[idx].User );
               break;
#endif
         default  :
               result = FALSE;
               break;
      }
   return (result);
}

/*************************************************************************************
*	BSearch()
*	A binary search with data abstraction.  Requires a function pointer to
*	a callback function for the actual comparison.
*	RETURNS:	TRUE on success, FAlSE on failure.
*				If successful, *indexPtr contains index of where found.
*************************************************************************************/
#if PROTOS_AVAIL
#if REENTRANT_ALLOC
FUNCTION boolean  BSearch (SPEEDO_GLOBALS *sp_global_ptr, fix15 STACKFAR*indexPtr,
					fix15 (*ComparisonTo)(SPEEDO_GLOBALS *,fix31, void STACKFAR *),
					void STACKFAR *theValue, fix31 nElements)
#else
FUNCTION boolean  BSearch (fix15 STACKFAR*indexPtr,
					fix15 (*ComparisonTo)(fix31, void STACKFAR *),
					void STACKFAR *theValue, fix31 nElements)
#endif
#else
FUNCTION boolean  BSearch (PARAMS2 indexPtr, ComparisonTo, theValue, nElements)
GDECL
fix15 STACKFAR*indexPtr;
fix15 (*ComparisonTo)();
void STACKFAR *theValue;
fix31 nElements;
#endif
{
   fix15    left, right, middle;
   fix15    result;


   left = 0;
   right = nElements -1;

   while ( right >= left )
   {
      middle = (left + right)/2;
 
      result = ((*ComparisonTo)(PARAMS2  (fix31)middle, theValue ));
      if ( result == LESS_THAN )
         right = middle -1;
      else
         left = middle + 1;
      if ( result == EQUAL_TO )
      {
         *indexPtr = middle;
         return ( TRUE );
      }
   }
   return ( FALSE );
}

/*************************************************************************************
*	BinarySearchGlyphTable()
*			Wrap around to BSearch()
*	RETURNS:	TRUE on succes, FALSE on failure
*				If successful, *indexPtr contains index of where found.
*************************************************************************************/
FUNCTION boolean  BinarySearchGlyphTable  (indexPtr, theValue, keyField)
fix15  STACKFAR*indexPtr;
void  STACKFAR *theValue;
ufix16   keyField;
{
   boolean    result;

   aGlyphType = keyField;
#if REENTRANT_ALLOC
   result = BSearch ((SPEEDO_GLOBALS *)0, indexPtr, GlyphCompare, theValue, (fix31)GlyphNumElements() );
#else
   result = BSearch (indexPtr, GlyphCompare, theValue, (fix31)GlyphNumElements() );
#endif
   return (result);

}



/*************************************************************************************
*	fi_CharCodeXLate()
*			Sorts the GlypTable if neccessary, then calls BinarySearchGlyphTable()
*	RETURN:	TRUE on success, FALSE on failure
*			If success, then outValue points at translated value.
*************************************************************************************/
FUNCTION boolean  fi_CharCodeXLate  ( inValue, outValue, inCharProtocol, outCharProtocol)
void STACKFAR *inValue;
void  STACKFAR *outValue;
ufix16   inCharProtocol;
ufix16   outCharProtocol;
{
   fix15    index;
   ufix16   STACKFAR *numberPtr;
   ufix16   STACKFAR *in_numPtr, STACKFAR *out_numPtr;
   char     STACKFAR *strPtr;


   if (  inCharProtocol == protoSymSet || inCharProtocol == protoPSEncode  )
         return ( FALSE );

   if (  inCharProtocol == protoDirectIndex  || inCharProtocol == outCharProtocol )
   {
         in_numPtr = inValue;
         out_numPtr = outValue;
         *out_numPtr = *in_numPtr;
         return   (  TRUE  );
   }


   if (  inCharProtocol != gCurrentSort   )
   {
         GlyphTableSort (  inCharProtocol );
   }
   if (  BinarySearchGlyphTable  ( (fix15 STACKFAR*)&index, inValue, inCharProtocol ) == (boolean) TRUE )
      {
         switch ( outCharProtocol )
          {
            case  protoBCID      :
                  numberPtr = outValue;
                  *numberPtr = gMasterGlyphCodes[index].BCID;
                  break;
#if CMT_UNI
            case  protoUnicode   :
                  numberPtr = outValue;
                  *numberPtr = gMasterGlyphCodes[index].Unicode;
                  break;
#endif
#if CMT_PS
            case  protoPSName    :
                  strPtr = outValue;
#ifdef MSDOS
/*				  _fstrncpy(strPtr, gMasterGlyphCodes[index].PSName, 32);*/
				  strncpy(strPtr, gMasterGlyphCodes[index].PSName, 32);
#else
				  strncpy(strPtr, gMasterGlyphCodes[index].PSName, 32);
#endif
                  break;
#endif
#if CMT_MSL
            case  protoMSL       :
                  numberPtr = outValue;
                  *numberPtr = gMasterGlyphCodes[index].MSL;
                  break;
#endif
#if CMT_USR
            case  protoUser      :
                  numberPtr = outValue;
                  *numberPtr = gMasterGlyphCodes[index].User;
                  break;
#endif
            default  :
                  return ( FALSE );
                  break;
          }
          return ( TRUE );
      }  
   else
      return ( FALSE );   
}

/* EOF cmt.c */

#pragma Code ()
