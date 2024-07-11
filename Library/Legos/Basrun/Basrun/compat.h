/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		compat.h

AUTHOR:		Paul L. Du Bois, Apr  5, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/ 5/96  	Initial version, from runint.h

DESCRIPTION:
	Liberty/GEOS compatibility macros

	Some macros need the macro RMS defined.  If the variable
	rms is a pointer

#define RMS (*rms)

	otherwise

#define RMS rms
	
	$Revision: 1.1 $

	Liberty version control
	$Id: compat.h,v 1.1 98/10/05 12:43:11 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _COMPAT_H_
#define _COMPAT_H_

/* Features constants */
#ifdef LIBERTY
#define USES_SEGMENTS 0
#else /* GEOS */
#define USES_SEGMENTS 1
#endif

#ifndef LIBERTY
/* defines ERROR_CHECK */
#include <geos.h>
#endif

#ifdef LIBERTY
/* defines XIP stuff */
#include <Legos/legosxip.h>
#endif

/* bcl files are always little endian */
#define BCL_BIG_ENDIAN 0


/*- EC macros and other general purpose things
 */
/* special EC macros that are for GEOS only or LIBERTY only */
#if ERROR_CHECK
#ifdef LIBERTY
#define ECG(x)
#define ECL(x) EC(x)
#define EC_ERROR_IF(test, error) ASSERTS(!(test), #error)
#define ECG_ERROR_IF(a,b)
#define EC_CHECK_CONTEXT(_foo)

#else	/* GEOS version below */

#define ECG(x) EC(x)
#define ECL(x)
#define ECG_ERROR_IF(test, error) EC_ERROR_IF(test,error)
#define ASSERT(_test)  EC_ERROR_IF(!(_test), RE_FAILED_ASSERTION)
#define ASSERTS(_test, _str) ASSERT(_test)
#define ASSERTS_WARN(_test, _str)
#define EC_CHECK_CONTEXT(_foo) ECCheckFrameContext(_foo)

#endif	/* ifdef LIBERTY */
#else	/* if ERROR_CHECK */

/* define all these to do nothing if not ERROR_CHECK */
#define EC_CHECK_CONTEXT(_foo)
#define ECG(x)
#define ECL(x)
#define EC_ERROR_IF(test, error)
#define ECG_ERROR_IF(test, error)

#ifdef LIBERTY
#else
#define ASSERT(_test)
#define ASSERTS(_test, _str)
#define ASSERTS_WARN(_test, _str)
#endif

#endif	/* if ERROR_CHECK */

/* Can be used instead of ifdef foo bar else baz
 * do/while eats a semi, because extraneous semis annoy liberty compiler
 */
#ifdef LIBERTY
#if 0
#define LONLY(line) do {line;} while (0)
#define GONLY(line) while (0)
#else
#define LONLY(line) line
#define GONLY(line)
#endif
#define LIBERTY_XIP_MODULE(_rtask) \
	MODULE_TOKEN_IS_XIP(_rtask->RT_fidoModule)
#define ECNullHandle ((MemHandle)0xcccccccc)
#else /* GEOS */
#define LONLY(line) 
#define GONLY(line) line
#define LIBERTY_XIP_MODULE(_rtask) (0)
#define ECNullHandle 0xcccc
#endif


/*- Locking macros
 */
#ifdef LIBERTY

#else /* GEOS */
#define CheckLock MemLock
#define CheckUnlock MemUnlock
#define CheckDeref MemDeref
#endif

/*- FieldXXX macros
 */
#define FieldDword(_strP, _target) 	NextDword((_strP), (_target))
#define FieldWord(_strP, _target)	NextWord((_strP), (_target))
#define FieldByte(_strP, _target)	NextByte((_strP), (target))

#ifdef LIBERTY

#if ARCH_BIG_ENDIAN
#define FieldMemHandle(_strP, _target) 			\
    (((((int)(_strP)) & 0x03) == 0) ? 			\
     ((_target) = (MemHandle)(*(dword*)(_strP))) :	\
     ((_target) = (MemHandle)((*(_strP) << 24) | 	\
			      (*(_strP + 1) << 16) | 	\
			      (*(_strP + 2) << 8) | 	\
			      *(_strP + 3))))
#else
#define FieldMemHandle(_strP, _target) 			\
    (((((int)(_strP)) & 0x03) == 0) ? 			\
     ((_target) = (MemHandle)(*(dword*)(_strP))) :	\
     ((_target) = (MemHandle)((*(_strP)) | 		\
			      (*(_strP + 1) << 8) | 	\
			      (*(_strP + 2) << 16) | 	\
			      (*(_strP + 3) << 24))))
#endif

#if ARCH_BIG_ENDIAN
#define FieldRunHeapToken(_strP, _target) 		\
    (((((int)(_strP)) & 0x03) == 0) ? 			\
     ((_target) = (RunHeapToken)(*(dword*)(_strP))) :	\
     ((_target) = (RunHeapToken)((*(_strP) << 24) | 	\
				 (*(_strP + 1) << 16) | \
				 (*(_strP + 2) << 8) | 	\
				 *(_strP + 3))))
#else
#define FieldRunHeapToken(_strP, _target) 		\
    (((((int)(_strP)) & 0x03) == 0) ? 			\
     ((_target) = (RunHeapToken)(*(dword*)(_strP))) :	\
     ((_target) = (RunHeapToken)((*(_strP)) |	 	\
				 (*(_strP + 1) << 8) | 	\
				 (*(_strP + 2) << 16) | \
				 (*(_strP + 3) << 24))))
#endif

#else	/* GEOS version below */

#define FieldMemHandle(_strP, _target) 	FieldWord((_strP), (_target))
#define FieldRunHeapToken(_strP, _target) FieldWord((_strP), (_target))

#endif

#define FieldNDword(_strP, _n, _target) \
    NextDword(((byte*)(_strP) + (_n)*5), (_target))
#define FieldNWord(_strP, _n, _target) \
    NextWord(((byte*)(_strP) + (_n)*5), (_target))
#define FieldNByte(_strP, _n, _target) \
    NextByte(((byte*)(_strP) + (_n)*5), (_target))
#define FieldNMemHandle(_strP, _n, _target) \
    FieldMemHandle(((byte*)(_strP) + (_n)*5), (_target))
#define FieldNRunHeapToken(_strP, _n, _target)  \
    FieldRunHeapToken(((byte*)(_strP) + (_n)*5), (_target))

#define FieldType(_strP, _target)		\
 ((_target) = (LegosType)(_strP)[4])

#define FieldNType(_strP, _n, _target)		\
 ((_target) = (LegosType)(_strP)[4+(_n)*5])

#define FieldNRVal(_strP, _n, _rv)			\
 (_rv).type  = (LegosType)(_strP)[4+(_n)*5];		\
 FieldNDword((_strP), (_n), (_rv).value)

/*- NextXXX Macros
 */
#define NextType(bytePtr, byteTarget) ((byteTarget) = (LegosType)*(bytePtr))
#define NextByte(bytePtr, byteTarget) ((byteTarget) = *(bytePtr))

#ifdef LIBERTY

#if BCL_BIG_ENDIAN
#define NextWordBcl(bclBytePtr, wordTarget) \
    ((wordTarget) = (*(byte*)(bclBytePtr) << 8) | *((byte*)(bclBytePtr) + 1))
#else	/* BCL_LITTLE_ENDIAN */
#define NextWordBcl(bclBytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bclBytePtr) + 1) << 8) | *((byte*)(bclBytePtr)))
#endif

#if BCL_BIG_ENDIAN
#define NextWordFromDwordBcl(bytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bytePtr) + 2) << 8) | *((byte*)(bytePtr) + 3))
#else	/* BCL_LITTLE_ENDIAN */
#define NextWordFromDwordBcl(bytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bytePtr) + 1) << 8) | *((byte*)(bytePtr)))
#endif

#if ARCH_BIG_ENDIAN
#define NextWord(bytePtr, wordTarget) \
    ((wordTarget) = (*(byte*)(bytePtr) << 8) | *((byte*)(bytePtr) + 1))
#else	/* ARCH_LITTLE_ENDIAN */
#define NextWord(bytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bytePtr) + 1) << 8) | *((byte*)(bytePtr)))
#endif

#if ARCH_BIG_ENDIAN
#define NextWordFromDword(bytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bytePtr) + 2) << 8) | *((byte*)(bytePtr) + 3))
#else	/* ARCH_LITTLE_ENDIAN */
#define NextWordFromDword(bytePtr, wordTarget) \
    ((wordTarget) = (*((byte*)(bytePtr) + 1) << 8) | *((byte*)(bytePtr)))
#endif

#if ARCH_BIG_ENDIAN
#define NextDword(bytePtr, dwordTarget) 		\
    (((((int)(bytePtr)) & 0x03) == 0) ? 		\
     ((dwordTarget) = *(dword*)(bytePtr)) : 		\
     ((dwordTarget) = ((*(byte*)(bytePtr)) << 24) | 	\
                      (*((byte*)(bytePtr) + 1) << 16) |	\
                      (*((byte*)(bytePtr) + 2) << 8) |	\
                      (*((byte*)(bytePtr) + 3))))
#else	/* ARCH_LITTLE_ENDIAN */
#define NextDword(bytePtr, dwordTarget) 		\
    (((((int)(bytePtr)) & 0x03) == 0) ? 		\
     ((dwordTarget) = *(dword*)(bytePtr)) : 		\
     ((dwordTarget) = ((*(byte*)(bytePtr))) |	 	\
                      (*((byte*)(bytePtr) + 1) << 8) |	\
                      (*((byte*)(bytePtr) + 2) << 16) |	\
                      (*((byte*)(bytePtr) + 3) << 24)))
#endif

#if BCL_BIG_ENDIAN
#if ARCH_BIG_ENDIAN
/* local is BIG, bcl is BIG, do byte copy or eval if aligned */
#define NextDwordBcl(bytePtr, dwordTarget) 		\
    (((((int)(bytePtr)) & 0x03) == 0) ? 		\
     ((dwordTarget) = *(dword*)(bytePtr)) : 		\
     ((dwordTarget) = ((*(byte*)(bytePtr)) << 24) | 	\
                      (*((byte*)(bytePtr) + 1) << 16) |	\
                      (*((byte*)(bytePtr) + 2) << 8) |	\
                      (*((byte*)(bytePtr) + 3))))
#else	/* ARCH_LITTLE_ENDIAN */
/* local is LITTLE, bcl is BIG, do only byte copies (eval won't work) */
#define NextDwordBcl(bytePtr, dwordTarget) 		\
     ((dwordTarget) = ((*(byte*)(bytePtr)) << 24) | 	\
                      (*((byte*)(bytePtr) + 1) << 16) |	\
                      (*((byte*)(bytePtr) + 2) << 8) |	\
                      (*((byte*)(bytePtr) + 3)))
#endif	/* ARCH_XXX_ENDIAN */

#else	/* BCL_LITTLE_ENDIAN */

#if ARCH_BIG_ENDIAN
/* local is BIG, bcl is little, do only byte copies (eval won't work) */
#define NextDwordBcl(bytePtr, dwordTarget) 		\
     ((dwordTarget) = ((*(byte*)(bytePtr))) |	 	\
                      (*((byte*)(bytePtr) + 1) << 8) |	\
                      (*((byte*)(bytePtr) + 2) << 16) |	\
                      (*((byte*)(bytePtr) + 3) << 24))
#else	/* ARCH_LITTLE_ENDIAN */
/* local is LITTLE, bcl is LITTLE, do copy or eval if aligned */
#define NextDwordBcl(bytePtr, dwordTarget) 		\
    (((((int)(bytePtr)) & 0x03) == 0) ? 		\
     ((dwordTarget) = *(dword*)(bytePtr)) : 		\
     ((dwordTarget) = ((*(byte*)(bytePtr))) |	 	\
                      (*((byte*)(bytePtr) + 1) << 8) |	\
                      (*((byte*)(bytePtr) + 2) << 16) |	\
                      (*((byte*)(bytePtr) + 3) << 24)))
#endif 	/* ARCH_XXX_ENDIAN */
#endif	/* BCL_XXX_ENDIAN */

#if ARCH_BIG_ENDIAN
#define NextMemHandle(bytePtr, memHandleTarget) 			\
    (((((int)(bytePtr)) & 0x03) == 0) ? 				\
     ((memHandleTarget) = (MemHandle)(*(dword*)(bytePtr))) : 		\
     ((memHandleTarget) = (MemHandle)((*((byte*)(bytePtr)) << 24) | 	\
				      (*((byte*)(bytePtr) + 1) << 16) |	\
				      (*((byte*)(bytePtr) + 2) << 8) | 	\
				      *((byte*)(bytePtr) + 3))))
#else	/* ARCH_LITTLE_ENDIAN */
#define NextMemHandle(bytePtr, memHandleTarget) 			\
    (((((int)(bytePtr)) & 0x03) == 0) ? 				\
     ((memHandleTarget) = (MemHandle)(*(dword*)(bytePtr))) : 		\
     ((memHandleTarget) = (MemHandle)((*((byte*)(bytePtr))) | 		\
				      (*((byte*)(bytePtr) + 1) << 8) |	\
				      (*((byte*)(bytePtr) + 2) << 16) |	\
				      (*((byte*)(bytePtr) + 3) << 24))))
#endif

#define NextRunHeapToken(bytePtr, tokenTarget) \
    NextDword(bytePtr, *(dword*)(&(tokenTarget)))

#else	/* GEOS version below */

#define NextWord(bytePtr, wordTarget) ((wordTarget) = *(word*)(bytePtr))
#define NextWordBcl(bytePtr, wordTarget) NextWord(bytePtr, wordTarget)
#define NextWordFromDword(bytePtr, wordTarget) NextWord(bytePtr, wordTarget)
#define NextDword(bytePtr, dwordTarget) ((dwordTarget) = *(dword*)(bytePtr))
#define NextDwordBcl(bytePtr, dwordTarget) NextDword(bytePtr, dwordTarget)
#define NextMemHandle(bytePtr, memHandleTarget) \
    ((memHandleTarget) = (MemHandle)(*(word*)(bytePtr)))
#define NextRunHeapToken(bytePtr, tokenTarget) NextWord(bytePtr, tokenTarget)

#endif

/*- GetXXX macros
 *  Like NextXXX but pointer is advanced
 */

#define GetOpcode(bytePtr, byteTarget) ((byteTarget) = (Opcode)*(bytePtr)++)
#define GetType(bytePtr, byteTarget) ((byteTarget) = (LegosType)*(bytePtr)++)
#define GetByte(bytePtr, byteTarget) ((byteTarget) = *(bytePtr)++)
#define GetWord(bytePtr, wordTarget) \
    NextWord((bytePtr), (wordTarget)); (bytePtr)+=2
#define GetDword(bytePtr, dwordTarget) \
    NextDword((bytePtr), (dwordTarget)); (bytePtr)+=4

#define GetWordBcl(bytePtr, wordTarget) \
    NextWordBcl((bytePtr), (wordTarget)); (bytePtr)+=2
#define GetDwordBcl(bytePtr, dwordTarget) \
    NextDwordBcl((bytePtr), (dwordTarget)); (bytePtr)+=4

/*- CopyXXX macros
 */

#define CopyByte(destPtr, sourcePtr) *(byte*)(destPtr) = *(byte*)(sourcePtr)

#ifdef LIBERTY
#define CopyWord(destPtr, sourcePtr)				\
{            							\
    *(byte*)(destPtr) = *(byte*)(sourcePtr);			\
    *((byte*)(destPtr) + 1) = *((byte*)(sourcePtr) + 1);	\
}

#if ARCH_BIG_ENDIAN
#define CopyWordFromDword(destPtr, sourcePtr)			\
{            							\
    *(byte*)(destPtr) = *((byte*)(sourcePtr) + 2);		\
    *((byte*)(destPtr) + 1) = *((byte*)(sourcePtr) + 3);	\
}
#else
#define CopyWordFromDword(destPtr, sourcePtr)			\
{            							\
    *(byte*)(destPtr) = *((byte*)(sourcePtr));			\
    *((byte*)(destPtr) + 1) = *((byte*)(sourcePtr) + 1);	\
}
#endif

#if ARCH_BIG_ENDIAN
#define CopyWordToDword(destPtr, sourcePtr)			\
{            							\
    *((byte*)(destPtr) + 2) = *(byte*)(sourcePtr);		\
    *((byte*)(destPtr) + 3) = *((byte*)(sourcePtr) + 1);	\
}
#else	/* ARCH_LITTLE_ENDIAN */
#define CopyWordToDword(destPtr, sourcePtr)			\
{            							\
    *((byte*)(destPtr)) = *(byte*)(sourcePtr);			\
    *((byte*)(destPtr) + 1) = *((byte*)(sourcePtr) + 1);	\
}
#endif

#define CopyDword(destPtr, sourcePtr)				\
{            							\
    *(byte*)(destPtr) = *(byte*)(sourcePtr);			\
    *((byte*)(destPtr) + 1) = *((byte*)(sourcePtr) + 1);	\
    *((byte*)(destPtr) + 2) = *((byte*)(sourcePtr) + 2);	\
    *((byte*)(destPtr) + 3) = *((byte*)(sourcePtr) + 3);	\
}

#if BCL_BIG_ENDIAN

#if ARCH_BIG_ENDIAN
/* local is BIG, bcl is BIG, just do byte copy */
#define CopyDwordBclToLocal(localDestPtr, bclSourcePtr)	\
    CopyDword(localDestPtr, bclSourcePtr)
#else /* ARCH_LITTLE_ENDIAN */
/* local is LITTLE, bcl is BIG, reverse the order */
#define CopyDwordBclToLocal(localDestPtr, bclSourcePtr)			\
{									\
    *(byte*)(localDestPtr) = *((byte*)(bclSourcePtr) + 3);		\
    *((byte*)(localDestPtr) + 1) = *((byte*)(bclSourcePtr) + 2);	\
    *((byte*)(localDestPtr) + 2) = *((byte*)(bclSourcePtr) + 1);	\
    *((byte*)(localDestPtr) + 3) = *(byte*)(bclSourcePtr);		\
}
#endif /* ARCH_XXX_ENDIAN */

#else /* BCL_LITTLE_ENDIAN */

#if ARCH_BIG_ENDIAN
/* local is BIG, bcl is LITTLE, reverse the order */
#define CopyDwordBclToLocal(localDestPtr, bclSourcePtr)			\
{									\
    *(byte*)(localDestPtr) = *((byte*)(bclSourcePtr) + 3);		\
    *((byte*)(localDestPtr) + 1) = *((byte*)(bclSourcePtr) + 2);	\
    *((byte*)(localDestPtr) + 2) = *((byte*)(bclSourcePtr) + 1);	\
    *((byte*)(localDestPtr) + 3) = *(byte*)(bclSourcePtr);		\
}
#else /* ARCH_LITTLE_ENDIAN */
/* local is LITTLE, bcl is LITTLE, just do byte copy */
#define CopyDwordBclToLocal(localDestPtr, bclSourcePtr)	\
    CopyDword(localDestPtr, bclSourcePtr)
#endif /* ARCH_XXX_ENDIAN */

#endif /* BCL_XXX_ENDIAN */

#define CopyMemHandle(destPtr, sourcePtr) CopyDword(destPtr, sourcePtr)
#define CopyRunHeapToken(destPtr, runHeapTokenPtr) \
    CopyDword(destPtr, runHeapTokenPtr)

#else	/* GEOS version below */

#define CopyWord(destPtr, sourcePtr) *(word*)(destPtr) = *(word*)(sourcePtr)
#define CopyWordFromDword(destPtr, sourcePtr) CopyWord((destPtr), (sourcePtr))
#define CopyWordToDword(destPtr, sourcePtr) CopyWord((destPtr), (sourcePtr))
#define CopyDword(destPtr, sourcePtr) *(dword*)(destPtr) = *(dword*)(sourcePtr)
#define CopyDwordBclToLocal(destPtr, sourcePtr) CopyDword(destPtr, sourcePtr)
#define CopyMemHandle(destPtr, sourcePtr) \
    *(MemHandle*)(destPtr) = *(MemHandle*)(sourcePtr)
#define CopyRunHeapToken(destPtr, runHeapTokenPtr) \
    *(RunHeapToken*)(destPtr) = *(RunHeapToken*)(runHeapTokenPtr)
#endif

#endif /* _COMPAT_H_ */
