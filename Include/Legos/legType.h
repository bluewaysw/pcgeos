/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		
FILE:		legtype.h

AUTHOR:		Roy Goldman, Jul  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95	Initial version.

DESCRIPTION:
	Legos interpreter type information, used by 
	many different modules

	$Id: legType.h,v 1.1 97/12/05 12:16:25 gene Exp $

	$Revision: 1.1 $

	Liberty version control
	$Id: legType.h,v 1.1 97/12/05 12:16:25 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _LEGTYPE_H_
#define _LEGTYPE_H_

/* NOTE: the different types of numbers must fall between TYPE_NUMBER
 * and TYPE_LONG in this array as bwb_vtov relies on that
 * NOTE: the LegosType enum MUST match the one in legos.def!!!
 */
#ifdef LIBERTY
typedef byte LegosType;
#define TYPE_UNKNOWN		0x00	/* at runtime, means "variant" */

#define TYPE_FLOAT		0x01
#define TYPE_INTEGER		0x02
#define TYPE_LONG		0x03
#define TYPE_STRING		0x04
#define TYPE_COMPONENT		0x05
#define TYPE_ARRAY		0x06
#define TYPE_ARRAY_ELT_LV	0x07
#define TYPE_ERROR		0x08 /* TYPE_ERROR added to provide a way for
                                      * components to return an error from a
				      * SET_PROPERTY handler.
				      *
				      * Also used within the compiler 
				      * typechecker
				      */
#define TYPE_FOR_LOOP		0x09	/* Runtime-internal */
#define TYPE_FRAME_CONTEXT	0x0a	/* Runtime-internal */
#define TYPE_MODULE		0x0b
#define TYPE_ILLEGAL		0x0c
#define TYPE_COMPLEX		0x0d

#define TYPE_ERROR_HANDLER	0x0e	/* Runtime-internal */

#define TYPE_LOCAL_VAR_LV	0x0f
#define TYPE_MODULE_VAR_LV	0x10
#define TYPE_PROPERTY_LV	0x11
#define TYPE_BC_PROPERTY_LV	0x12  	/* getting and setting byte 
                                         * compiled properties */
#define TYPE_MODULE_REF_LV  	0x13    /* token used to indicate 
                                         * cross module reference */
#define TYPE_STRUCT		0x14
#define TYPE_STRUCT_REF_LV	0x15
#define TYPE_VOID		0x16	/* Used in compiler for 
                                         * nodes with no type */
#define TYPE_CUSTOM_PROPERTY_LV 0x17
#define TYPE_BYTE		0x18
#define TYPE_NUM_TYPES		0x19	/* Keep this last */

#else	/* GEOS version below */

/* If you change these around, please modify runerr.goc which depends
 * on the order
 */
typedef enum
{
    TYPE_UNKNOWN,		/* 0: at runtime, means "variant" */
    TYPE_FLOAT,
    TYPE_INTEGER,
    TYPE_LONG,
    TYPE_STRING,
    TYPE_COMPONENT,		/* 5 */
    TYPE_ARRAY,
    TYPE_ARRAY_ELT_LV,
    TYPE_ERROR,			/* TYPE_ERROR added to provide a way for
				 * components to return an error from a
				 * SET_PROPERTY handler.
				 *
				 * Also used within the compiler typechecker
				 */

    TYPE_FOR_LOOP,		/* Runtime-internal */
    TYPE_FRAME_CONTEXT,		/* 10: Runtime-internal */
    TYPE_MODULE,
    TYPE_ILLEGAL,
    TYPE_COMPLEX,

    TYPE_ERROR_HANDLER,		/* Runtime-internal */

    TYPE_LOCAL_VAR_LV,		/* 15 */
    TYPE_MODULE_VAR_LV,
    TYPE_PROPERTY_LV,
    TYPE_BC_PROPERTY_LV,  /* getting and setting byte compiled properties */
    TYPE_MODULE_REF_LV,  /* token used to indicate cross module reference */

    TYPE_STRUCT,		/* 20 */
    TYPE_STRUCT_REF_LV,
    TYPE_VOID,			/* Used in compiler for nodes with no type */
    TYPE_CUSTOM_PROPERTY_LV,
    TYPE_BYTE,
    TYPE_NUM_TYPES		/* Keep this last */
} LegosType;
#endif
#define TYPE_NONE   	TYPE_UNKNOWN
#define TYPE_VARIANT	TYPE_UNKNOWN

/* Remove me when possible */
#define TYPE_ARRAY_ELEMENT	TYPE_ARRAY_ELT_LV

/* Within compiler, setting this bit on <type> turns it into
 * array-of <type>
 */
#define TYPE_ARRAY_FLAG	0x8000
#define MAX_DIMS    3


/* Bit to set in offsets after OP_END_{PROC,FUNC}
 * if the parameter was a variant
 */
#define VARIANT_PARAM 0xf000

/* Return true if the component is an aggregate
 * (ie, a struct in disguise)
 */
#ifdef LIBERTY
#define COMP_IS_AGG(_c) (((int)(_c) & 0x02) == 0x02)
#define AGG_TO_STRUCT(_c) ((RunHeapToken)((int)(_c)+1))
#define STRUCT_TO_AGG(_a) ((_a)-1)
#else	/* GEOS version below */
#define COMP_IS_AGG(_c) (((_c) >> 16) == 0xffff)
#define AGG_TO_STRUCT(_c) ((RunHeapToken)(_c))
#define STRUCT_TO_AGG(_a) (0xffff0000 | (dword)(_a))
#endif

/* Return true if type could be a run heap type
 * (can't make the distinction for components at compile-time
 */
#define RUN_HEAP_TYPE_CT(_t)			\
 ((_t)==TYPE_COMPLEX || (_t)==TYPE_STRUCT ||	\
  (_t)==TYPE_STRING || (_t)==TYPE_COMPONENT)

/* Return true if the type is a run heap type
 */
#define RUN_HEAP_TYPE(_t, _data)		\
 ((_t)==TYPE_COMPLEX || (_t)==TYPE_STRUCT ||	\
  (_t)==TYPE_STRING ||  ((_t)==TYPE_COMPONENT && COMP_IS_AGG(_data) ))


/* For CASE statements, ie
 * case TYPE_RUN_HEAP_CASE:
 * separate out TYPE_COMPONENT because it's a special case.
 */
#define TYPE_RUN_HEAP_CASE \
 TYPE_COMPLEX: case TYPE_STRUCT: case TYPE_STRING

/* This is defined in about a 1000 different places. Just do it
   once and for all here. */
#define VAR_SIZE 5
#define VAR_MODULE 0
#define VAR_LOCAL 1

#endif /* _LEGTYPE_H_ */
