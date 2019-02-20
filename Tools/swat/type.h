/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Type Description Module Interface
 * FILE:	  type.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Constant, type and function definitions for interfacing to Type
 *	module.
 *
 *
* 	$Id: type.h,v 4.8 96/05/20 18:54:20 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _TYPE_H
#define _TYPE_H

/*
 * Classes of types.
 */
#define TYPE_POINTER	    0
#define TYPE_ARRAY  	    1
#define TYPE_RANGE	    2
#define TYPE_UNION	    3
#define TYPE_STRUCT	    4
#define TYPE_ENUM	    5
#define TYPE_FUNCTION	    6
#define TYPE_INT	    7
#define TYPE_CHAR	    8
#define TYPE_VOID	    9
#define TYPE_FLOAT	    10
#define TYPE_EXTERNAL	    11
#define TYPE_BITFIELD	    12
#define TYPE_NULL   	    13

/*
 * Subclasses of TYPE_POINTER
 */
#define TYPE_PTR_NEAR	'n'   	/* Near pointer */
#define TYPE_PTR_FAR	'f'   	/* two-word far pointer */
#define TYPE_PTR_SEG	's'   	/* Segment address only */
#define TYPE_PTR_LMEM	'l'   	/* Value is LMem handle */
#define TYPE_PTR_HANDLE	'h'   	/* Value is global handle */
#define TYPE_PTR_OBJECT	'o'   	/* Value is two-word object pointer
				 * (low is lmem handle, high is global
				 * handle) */
#define TYPE_PTR_VIRTUAL 'F'	/* offset + virtual segment */
#define TYPE_PTR_VM 	'v' 	/* vm block handle + vm file handle */

/*
 * Pre-defined (machine-specific) types.
 */
extern Type 	  type_Void,
		  type_Int,
		  type_Short,
		  type_Long,
		  type_Char,
		  type_WChar,
		  type_SByte,
		  type_UnsignedInt,
		  type_UnsignedShort,
		  type_UnsignedLong,
		  type_UnsignedChar,
		  type_Float,
		  type_Double,
    	    	  type_LongDouble,
		  type_Byte,
		  type_Word,
		  type_DWord;

extern Type 	Type_CreateInt (int  size, Boolean isSigned);
extern Type 	Type_CreateChar (int min, int max, int size);
extern void 	Type_GetCharData (Type type, int *minPtr, int *maxPtr);
extern Type 	Type_CreatePointer (Type baseType, int ptrType);
extern void 	Type_GetPointerData (Type type, int *ptype, Type *base);
extern Type 	Type_GetPointerType (Type type);
extern void 	Type_SetPointerBase (Type type, Type baseType);
extern Type 	Type_CreateArray (int lower, int upper, Type indexType,
				  Type baseType);
extern void 	Type_GetArrayData (Type type, int *lowerPtr, int *upperPtr,
				   Type *indexTypePtr, Type *baseTypePtr);
extern Type 	Type_CreateRange (int lowerBound, int upperBound,
				  Type baseType);
extern void 	Type_GetRangeData (Type type, int *lowerBoundPtr,
				   int *upperBoundPtr, Type *baseTypePtr);
extern Type 	Type_CreateUnion (int size);
extern Type 	Type_CreateStruct (int size);
extern Type 	Type_EndStructUnion (Type type);
extern void 	Type_AddField (Type type, char *fieldName, int offset,
			       int length, Type fieldType);
extern Boolean 	Type_GetFieldData (Type type, char *fieldName,
				   int *offsetPtr, int *lengthPtr,
				   Type *fieldTypePtr);
extern void 	Type_ForEachField (Type type, Boolean (*func)(),
				   Opaque clientData);
extern Boolean 	Type_FindFieldData (Type type, int offset,
				    char **fieldNamePtr, int *lengthPtr,
				    Type *fieldTypePtr, int *diffPtr);
extern Type 	Type_CreateEnum (int size);
extern void 	Type_GetEnumData (Type type, int *minPtr, int *maxPtr);
extern void 	Type_AddEnumMember (Type type, char *enumName, int enumValue);
extern int  	Type_GetEnumValue (Type type, char *name);
extern char 	*Type_GetEnumName (Type type, int value);
typedef Boolean (*type_foreachenum_callback)(Type, char *, int, Opaque) ;
extern void 	Type_ForEachEnum (Type type, type_foreachenum_callback func,
				  Opaque clientData);
extern Type 	Type_CreateFunction (Type returnType);
extern Type 	Type_GetFunctionReturn (Type type);
extern Type 	Type_CreateFloat (int size);
extern Type 	Type_CreateExternal (word class, char *name);
extern void 	Type_GetExternalData (Type type, word *classPtr,
				      char **namePtr);
extern void 	Type_GetBitFieldData(Type type,
				     unsigned *offsetPtr,
				     unsigned *widthPtr,
				     Type *typePtr);
extern Type 	Type_CreateBitField(unsigned offset, unsigned width,
				    Type type);

extern int  	Type_Sizeof (Type type);
extern word 	Type_Class (Type type);
extern char 	*Type_Name (Type type, char *name, Boolean expand);
extern char 	*Type_NameOffset (Type type, char *name,
				  int offset, Boolean expand);
extern Boolean 	Type_Equal (Type type1, Type type2);
extern Boolean 	Type_Cast (Opaque *valuePtr, Type srcType, Type dstType);
extern Boolean 	Type_IsSigned (Type type);
extern Type 	Type_CreatePackedStruct (char *firstname, ...);

extern Type 	Type_ToToken(char *token);
extern char 	*Type_ToAscii(Type type);
extern Boolean	Type_IsNull(Type type);
extern void     Type_Nuke(Opaque type, int *sizeFree, int *numFree);

extern Boolean	Type_IsRecord(Type type);

extern void 	Type_Init (void);

#endif /* _TYPE_H */
