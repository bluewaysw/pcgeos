/* Automatically generated definition header file
 *
 * Nombas Internal memo:
 * Do not edit.  Edit the file toolsselibdef.dat and then run the script
 * toolsselibdef.bat to update the file.
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

#ifndef __SELIBDEF_H
#  define __SELIBDEF_H

/* handle old defines (pre 4.30b) where ECMA objects were all or nothing */
#  ifdef JSE_ECMA_ALL
#     if !defined(JSE_ECMA_OBJECT)
#        define JSE_ECMA_OBJECT     1
#     endif
#     if !defined(JSE_ECMA_ARRAY)
#        define JSE_ECMA_ARRAY      1
#     endif
#     if !defined(JSE_ECMA_STRING)
#        define JSE_ECMA_STRING     1
#     endif
#     if !defined(JSE_ECMA_REGEXP)
#        define JSE_ECMA_REGEXP     1
#     endif
#     if !defined(JSE_ECMA_BOOLEAN)
#        define JSE_ECMA_BOOLEAN    1
#     endif
#     if !defined(JSE_ECMA_NUMBER)
#        define JSE_ECMA_NUMBER     1
#     endif
#     if !defined(JSE_ECMA_EXCEPTIONS)
#        define JSE_ECMA_EXCEPTIONS 1
#     endif
#     if !defined(JSE_ECMA_BUFFER) \
      && (defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER))
#        define JSE_ECMA_BUFFER     1
#     endif
#     if !defined(JSE_ECMA_FUNCTION)
#        define JSE_ECMA_FUNCTION   1
#     endif
#     if !defined(JSE_ECMA_DATE) \
      && (0!=JSE_FLOATING_POINT)
#        define JSE_ECMA_DATE       1
#     endif
#     if !defined(JSE_ECMA_MATH) \
      && (0!=JSE_FLOATING_POINT)
#        define JSE_ECMA_MATH       1
#     endif
#     define JSE_ECMAMISC_ALL
#  endif
#  if defined(JSE_ECMA_OBJECT) && (0!=JSE_ECMA_OBJECT)
#      define JSE_OBJECT_ALL
#  endif
#  if defined(JSE_ECMA_ARRAY) && (0!=JSE_ECMA_ARRAY)
#      define JSE_ARRAY_ALL
#  endif
#  if defined(JSE_ECMA_STRING) && (0!=JSE_ECMA_STRING)
#      define JSE_STRING_ALL
#  endif
#  if defined(JSE_ECMA_REGEXP) && (0!=JSE_ECMA_REGEXP)
#      define JSE_REGEXP_ALL
#  endif
#  if defined(JSE_ECMA_BOOLEAN) && (0!=JSE_ECMA_BOOLEAN)
#      define JSE_BOOLEAN_ALL
#  endif
#  if defined(JSE_ECMA_NUMBER) && (0!=JSE_ECMA_NUMBER)
#      define JSE_NUMBER_ALL
#  endif
#  if defined(JSE_ECMA_EXCEPTIONS) && (0!=JSE_ECMA_EXCEPTIONS)
#      define JSE_EXCEPTION_ALL
#  endif
#  if defined(JSE_ECMA_BUFFER) && (0!=JSE_ECMA_BUFFER)
#      define JSE_BUFFER_ALL
#  endif
#  if defined(JSE_ECMA_FUNCTION) && (0!=JSE_ECMA_FUNCTION)
#      define JSE_FUNCTION_ALL
#  endif
#  if defined(JSE_ECMA_DATE) && (0!=JSE_ECMA_DATE)
#      define JSE_DATE_ALL
#  endif
#  if defined(JSE_ECMA_MATH) && (0!=JSE_ECMA_MATH)
#      define JSE_MATH_ALL
#  endif
#  if defined(JSE_ECMA_ESCAPE)
#      define JSE_ECMAMISC_ESCAPE JSE_ECMA_ESCAPE
#  endif
#  if defined(JSE_ECMA_UNESCAPE)
#     define JSE_ECMAMISC_UNESCAPE JSE_ECMA_UNESCAPE
#  endif
#  if defined(JSE_ECMA_EVAL)
#     define JSE_ECMAMISC_EVAL JSE_ECMA_EVAL
#  endif
#  if defined(JSE_ECMA_ISFINITE)
#     define JSE_ECMAMISC_ISFINITE JSE_ECMA_ISFINITE
#  endif
#  if defined(JSE_ECMA_ISNAN)
#     define JSE_ECMAMISC_ISNAN JSE_ECMA_ISNAN
#  endif
#  if defined(JSE_ECMA_PARSEINT)
#     define JSE_ECMAMISC_PARSEINT JSE_ECMA_PARSEINT
#  endif
#  if defined(JSE_ECMA_PARSEFLOAT)
#     define JSE_ECMAMISC_PARSEFLOAT JSE_ECMA_PARSEFLOAT
#  endif
#  if defined(JSE_ECMA_ENCODEURI)
#     define JSE_ECMAMISC_ENCODEURI JSE_ECMA_ENCODEURI
#  endif
#  if defined(JSE_ECMA_ENCODEURICOMPONENT)
#     define JSE_ECMAMISC_ENCODEURICOMPONENT JSE_ECMA_ENCODEURICOMPONENT
#  endif
#  if defined(JSE_ECMA_DECODEURI)
#     define JSE_ECMAMISC_DECODEURI JSE_ECMA_DECODEURI
#  endif
#  if defined(JSE_ECMA_DECODEURICOMPONENT)
#     define JSE_ECMAMISC_DECODEURICOMPONENT JSE_ECMA_DECODEURICOMPONENT
#  endif


/*****************
 * LANG          *
 *****************/

   /* Check for JSE_LANG_ALL */
#  if defined(JSE_LANG_ALL)
#     if !defined(JSE_LANG_DEFINED)
#        define JSE_LANG_DEFINED                 1
#     endif
#     if !defined(JSE_LANG_GETARRAYLENGTH)
#        define JSE_LANG_GETARRAYLENGTH          1
#     endif
#     if !defined(JSE_LANG_SETARRAYLENGTH)
#        define JSE_LANG_SETARRAYLENGTH          1
#     endif
#     if !defined(JSE_LANG_TOBOOLEAN)
#        define JSE_LANG_TOBOOLEAN               1
#     endif
#     if !defined(JSE_LANG_TOBUFFER) \
         && (defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER))
#        define JSE_LANG_TOBUFFER                1
#     endif
#     if !defined(JSE_LANG_TOBYTES) \
         && (defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER))
#        define JSE_LANG_TOBYTES                 1
#     endif
#     if !defined(JSE_LANG_TOINT32)
#        define JSE_LANG_TOINT32                 1
#     endif
#     if !defined(JSE_LANG_TOINTEGER)
#        define JSE_LANG_TOINTEGER               1
#     endif
#     if !defined(JSE_LANG_TONUMBER)
#        define JSE_LANG_TONUMBER                1
#     endif
#     if !defined(JSE_LANG_TOOBJECT)
#        define JSE_LANG_TOOBJECT                1
#     endif
#     if !defined(JSE_LANG_TOPRIMITIVE)
#        define JSE_LANG_TOPRIMITIVE             1
#     endif
#     if !defined(JSE_LANG_TOSTRING)
#        define JSE_LANG_TOSTRING                1
#     endif
#     if !defined(JSE_LANG_TOSOURCE)
#        define JSE_LANG_TOSOURCE                1
#     endif
#     if !defined(JSE_LANG_TOUINT16)
#        define JSE_LANG_TOUINT16                1
#     endif
#     if !defined(JSE_LANG_TOUINT32)
#        define JSE_LANG_TOUINT32                1
#     endif
#     if !defined(JSE_LANG_UNDEFINE)
#        define JSE_LANG_UNDEFINE                1
#     endif
#     if !defined(JSE_LANG_GETATTRIBUTES)
#        define JSE_LANG_GETATTRIBUTES           1
#     endif
#     if !defined(JSE_LANG_SETATTRIBUTES)
#        define JSE_LANG_SETATTRIBUTES           1
#     endif
#     if !defined(JSE_LANG_ENABLEDYNAMICMETHOD) \
         && defined(JSE_ENABLE_DYNAMETH) && (0!=JSE_ENABLE_DYNAMETH)
#        define JSE_LANG_ENABLEDYNAMICMETHOD     1
#     endif
#  endif /* JSE_LANG_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_LANG_DEFINED) && (0==JSE_LANG_DEFINED)
#     undef JSE_LANG_DEFINED
#  endif
#  if defined(JSE_LANG_GETARRAYLENGTH) && (0==JSE_LANG_GETARRAYLENGTH)
#     undef JSE_LANG_GETARRAYLENGTH
#  endif
#  if defined(JSE_LANG_SETARRAYLENGTH) && (0==JSE_LANG_SETARRAYLENGTH)
#     undef JSE_LANG_SETARRAYLENGTH
#  endif
#  if defined(JSE_LANG_TOBOOLEAN) && (0==JSE_LANG_TOBOOLEAN)
#     undef JSE_LANG_TOBOOLEAN
#  endif
#  if defined(JSE_LANG_TOBUFFER) && (0==JSE_LANG_TOBUFFER)
#     undef JSE_LANG_TOBUFFER
#  endif
#  if defined(JSE_LANG_TOBYTES) && (0==JSE_LANG_TOBYTES)
#     undef JSE_LANG_TOBYTES
#  endif
#  if defined(JSE_LANG_TOINT32) && (0==JSE_LANG_TOINT32)
#     undef JSE_LANG_TOINT32
#  endif
#  if defined(JSE_LANG_TOINTEGER) && (0==JSE_LANG_TOINTEGER)
#     undef JSE_LANG_TOINTEGER
#  endif
#  if defined(JSE_LANG_TONUMBER) && (0==JSE_LANG_TONUMBER)
#     undef JSE_LANG_TONUMBER
#  endif
#  if defined(JSE_LANG_TOOBJECT) && (0==JSE_LANG_TOOBJECT)
#     undef JSE_LANG_TOOBJECT
#  endif
#  if defined(JSE_LANG_TOPRIMITIVE) && (0==JSE_LANG_TOPRIMITIVE)
#     undef JSE_LANG_TOPRIMITIVE
#  endif
#  if defined(JSE_LANG_TOSTRING) && (0==JSE_LANG_TOSTRING)
#     undef JSE_LANG_TOSTRING
#  endif
#  if defined(JSE_LANG_TOSOURCE) && (0==JSE_LANG_TOSOURCE)
#     undef JSE_LANG_TOSOURCE
#  endif
#  if defined(JSE_LANG_TOUINT16) && (0==JSE_LANG_TOUINT16)
#     undef JSE_LANG_TOUINT16
#  endif
#  if defined(JSE_LANG_TOUINT32) && (0==JSE_LANG_TOUINT32)
#     undef JSE_LANG_TOUINT32
#  endif
#  if defined(JSE_LANG_UNDEFINE) && (0==JSE_LANG_UNDEFINE)
#     undef JSE_LANG_UNDEFINE
#  endif
#  if defined(JSE_LANG_GETATTRIBUTES) && (0==JSE_LANG_GETATTRIBUTES)
#     undef JSE_LANG_GETATTRIBUTES
#  endif
#  if defined(JSE_LANG_SETATTRIBUTES) && (0==JSE_LANG_SETATTRIBUTES)
#     undef JSE_LANG_SETATTRIBUTES
#  endif
#  if defined(JSE_LANG_ENABLEDYNAMICMETHOD) && (0==JSE_LANG_ENABLEDYNAMICMETHOD)
#     undef JSE_LANG_ENABLEDYNAMICMETHOD
#  endif
   /* Define generic JSE_LANG_ANY */
#  if defined(JSE_LANG_DEFINED) \
   || defined(JSE_LANG_GETARRAYLENGTH) \
   || defined(JSE_LANG_SETARRAYLENGTH) \
   || defined(JSE_LANG_TOBOOLEAN) \
   || defined(JSE_LANG_TOBUFFER) \
   || defined(JSE_LANG_TOBYTES) \
   || defined(JSE_LANG_TOINT32) \
   || defined(JSE_LANG_TOINTEGER) \
   || defined(JSE_LANG_TONUMBER) \
   || defined(JSE_LANG_TOOBJECT) \
   || defined(JSE_LANG_TOPRIMITIVE) \
   || defined(JSE_LANG_TOSTRING) \
   || defined(JSE_LANG_TOSOURCE) \
   || defined(JSE_LANG_TOUINT16) \
   || defined(JSE_LANG_TOUINT32) \
   || defined(JSE_LANG_UNDEFINE) \
   || defined(JSE_LANG_GETATTRIBUTES) \
   || defined(JSE_LANG_SETATTRIBUTES) \
   || defined(JSE_LANG_ENABLEDYNAMICMETHOD)
#     define JSE_LANG_ANY
#  endif

/*****************
 * ARRAY         *
 *****************/

   /* Check for JSE_ARRAY_ALL */
#  if defined(JSE_ARRAY_ALL)
#     if !defined(JSE_ARRAY_OBJECT)
#        define JSE_ARRAY_OBJECT                 1
#     endif
#     if !defined(JSE_ARRAY_TOSTRING)
#        define JSE_ARRAY_TOSTRING               1
#     endif
#     if !defined(JSE_ARRAY_TOSOURCE)
#        define JSE_ARRAY_TOSOURCE               1
#     endif
#     if !defined(JSE_ARRAY_JOIN)
#        define JSE_ARRAY_JOIN                   1
#     endif
#     if !defined(JSE_ARRAY_REVERSE)
#        define JSE_ARRAY_REVERSE                1
#     endif
#     if !defined(JSE_ARRAY_SORT)
#        define JSE_ARRAY_SORT                   1
#     endif
#     if !defined(JSE_ARRAY_CONCAT)
#        define JSE_ARRAY_CONCAT                 1
#     endif
#     if !defined(JSE_ARRAY_POP)
#        define JSE_ARRAY_POP                    1
#     endif
#     if !defined(JSE_ARRAY_PUSH)
#        define JSE_ARRAY_PUSH                   1
#     endif
#     if !defined(JSE_ARRAY_SHIFT)
#        define JSE_ARRAY_SHIFT                  1
#     endif
#     if !defined(JSE_ARRAY_SLICE)
#        define JSE_ARRAY_SLICE                  1
#     endif
#     if !defined(JSE_ARRAY_SPLICE)
#        define JSE_ARRAY_SPLICE                 1
#     endif
#     if !defined(JSE_ARRAY_UNSHIFT)
#        define JSE_ARRAY_UNSHIFT                1
#     endif
#  endif /* JSE_ARRAY_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_ARRAY_OBJECT) && (0==JSE_ARRAY_OBJECT)
#     undef JSE_ARRAY_OBJECT
#  endif
#  if defined(JSE_ARRAY_TOSTRING) && (0==JSE_ARRAY_TOSTRING)
#     undef JSE_ARRAY_TOSTRING
#  endif
#  if defined(JSE_ARRAY_TOSOURCE) && (0==JSE_ARRAY_TOSOURCE)
#     undef JSE_ARRAY_TOSOURCE
#  endif
#  if defined(JSE_ARRAY_JOIN) && (0==JSE_ARRAY_JOIN)
#     undef JSE_ARRAY_JOIN
#  endif
#  if defined(JSE_ARRAY_REVERSE) && (0==JSE_ARRAY_REVERSE)
#     undef JSE_ARRAY_REVERSE
#  endif
#  if defined(JSE_ARRAY_SORT) && (0==JSE_ARRAY_SORT)
#     undef JSE_ARRAY_SORT
#  endif
#  if defined(JSE_ARRAY_CONCAT) && (0==JSE_ARRAY_CONCAT)
#     undef JSE_ARRAY_CONCAT
#  endif
#  if defined(JSE_ARRAY_POP) && (0==JSE_ARRAY_POP)
#     undef JSE_ARRAY_POP
#  endif
#  if defined(JSE_ARRAY_PUSH) && (0==JSE_ARRAY_PUSH)
#     undef JSE_ARRAY_PUSH
#  endif
#  if defined(JSE_ARRAY_SHIFT) && (0==JSE_ARRAY_SHIFT)
#     undef JSE_ARRAY_SHIFT
#  endif
#  if defined(JSE_ARRAY_SLICE) && (0==JSE_ARRAY_SLICE)
#     undef JSE_ARRAY_SLICE
#  endif
#  if defined(JSE_ARRAY_SPLICE) && (0==JSE_ARRAY_SPLICE)
#     undef JSE_ARRAY_SPLICE
#  endif
#  if defined(JSE_ARRAY_UNSHIFT) && (0==JSE_ARRAY_UNSHIFT)
#     undef JSE_ARRAY_UNSHIFT
#  endif
   /* Define generic JSE_ARRAY_ANY */
#  if defined(JSE_ARRAY_OBJECT) \
   || defined(JSE_ARRAY_TOSTRING) \
   || defined(JSE_ARRAY_TOSOURCE) \
   || defined(JSE_ARRAY_JOIN) \
   || defined(JSE_ARRAY_REVERSE) \
   || defined(JSE_ARRAY_SORT) \
   || defined(JSE_ARRAY_CONCAT) \
   || defined(JSE_ARRAY_POP) \
   || defined(JSE_ARRAY_PUSH) \
   || defined(JSE_ARRAY_SHIFT) \
   || defined(JSE_ARRAY_SLICE) \
   || defined(JSE_ARRAY_SPLICE) \
   || defined(JSE_ARRAY_UNSHIFT)
#     define JSE_ARRAY_ANY
#  endif

/*****************
 * STRING        *
 *****************/

   /* Check for JSE_STRING_ALL */
#  if defined(JSE_STRING_ALL)
#     if !defined(JSE_STRING_OBJECT)
#        define JSE_STRING_OBJECT                1
#     endif
#     if !defined(JSE_STRING_FROMCHARCODE)
#        define JSE_STRING_FROMCHARCODE          1
#     endif
#     if !defined(JSE_STRING_CHARAT)
#        define JSE_STRING_CHARAT                1
#     endif
#     if !defined(JSE_STRING_CHARCODEAT)
#        define JSE_STRING_CHARCODEAT            1
#     endif
#     if !defined(JSE_STRING_INDEXOF)
#        define JSE_STRING_INDEXOF               1
#     endif
#     if !defined(JSE_STRING_LASTINDEXOF)
#        define JSE_STRING_LASTINDEXOF           1
#     endif
#     if !defined(JSE_STRING_SPLIT)
#        define JSE_STRING_SPLIT                 1
#     endif
#     if !defined(JSE_STRING_SUBSTR)
#        define JSE_STRING_SUBSTR                1
#     endif
#     if !defined(JSE_STRING_SUBSTRING)
#        define JSE_STRING_SUBSTRING             1
#     endif
#     if !defined(JSE_STRING_TOLOWERCASE)
#        define JSE_STRING_TOLOWERCASE           1
#     endif
#     if !defined(JSE_STRING_TOUPPERCASE)
#        define JSE_STRING_TOUPPERCASE           1
#     endif
#     if !defined(JSE_STRING_CONCAT)
#        define JSE_STRING_CONCAT                1
#     endif
#     if !defined(JSE_STRING_SLICE)
#        define JSE_STRING_SLICE                 1
#     endif
#     if !defined(JSE_STRING_TOLOCALELOWERCASE)
#        define JSE_STRING_TOLOCALELOWERCASE     1
#     endif
#     if !defined(JSE_STRING_TOLOCALEUPPERCASE)
#        define JSE_STRING_TOLOCALEUPPERCASE     1
#     endif
#     if !defined(JSE_STRING_TOLOCALECOMPARE)
#        define JSE_STRING_TOLOCALECOMPARE       1
#     endif
#     if !defined(JSE_STRING_TOSOURCE)
#        define JSE_STRING_TOSOURCE              1
#     endif
#     if !defined(JSE_STRING_MATCH)
#        define JSE_STRING_MATCH                 1
#     endif
#     if !defined(JSE_STRING_REPLACE)
#        define JSE_STRING_REPLACE               1
#     endif
#     if !defined(JSE_STRING_SEARCH)
#        define JSE_STRING_SEARCH                1
#     endif
#  endif /* JSE_STRING_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_STRING_OBJECT) && (0==JSE_STRING_OBJECT)
#     undef JSE_STRING_OBJECT
#  endif
#  if defined(JSE_STRING_FROMCHARCODE) && (0==JSE_STRING_FROMCHARCODE)
#     undef JSE_STRING_FROMCHARCODE
#  endif
#  if defined(JSE_STRING_CHARAT) && (0==JSE_STRING_CHARAT)
#     undef JSE_STRING_CHARAT
#  endif
#  if defined(JSE_STRING_CHARCODEAT) && (0==JSE_STRING_CHARCODEAT)
#     undef JSE_STRING_CHARCODEAT
#  endif
#  if defined(JSE_STRING_INDEXOF) && (0==JSE_STRING_INDEXOF)
#     undef JSE_STRING_INDEXOF
#  endif
#  if defined(JSE_STRING_LASTINDEXOF) && (0==JSE_STRING_LASTINDEXOF)
#     undef JSE_STRING_LASTINDEXOF
#  endif
#  if defined(JSE_STRING_SPLIT) && (0==JSE_STRING_SPLIT)
#     undef JSE_STRING_SPLIT
#  endif
#  if defined(JSE_STRING_SUBSTR) && (0==JSE_STRING_SUBSTR)
#     undef JSE_STRING_SUBSTR
#  endif
#  if defined(JSE_STRING_SUBSTRING) && (0==JSE_STRING_SUBSTRING)
#     undef JSE_STRING_SUBSTRING
#  endif
#  if defined(JSE_STRING_TOLOWERCASE) && (0==JSE_STRING_TOLOWERCASE)
#     undef JSE_STRING_TOLOWERCASE
#  endif
#  if defined(JSE_STRING_TOUPPERCASE) && (0==JSE_STRING_TOUPPERCASE)
#     undef JSE_STRING_TOUPPERCASE
#  endif
#  if defined(JSE_STRING_CONCAT) && (0==JSE_STRING_CONCAT)
#     undef JSE_STRING_CONCAT
#  endif
#  if defined(JSE_STRING_SLICE) && (0==JSE_STRING_SLICE)
#     undef JSE_STRING_SLICE
#  endif
#  if defined(JSE_STRING_TOLOCALELOWERCASE) && (0==JSE_STRING_TOLOCALELOWERCASE)
#     undef JSE_STRING_TOLOCALELOWERCASE
#  endif
#  if defined(JSE_STRING_TOLOCALEUPPERCASE) && (0==JSE_STRING_TOLOCALEUPPERCASE)
#     undef JSE_STRING_TOLOCALEUPPERCASE
#  endif
#  if defined(JSE_STRING_TOLOCALECOMPARE) && (0==JSE_STRING_TOLOCALECOMPARE)
#     undef JSE_STRING_TOLOCALECOMPARE
#  endif
#  if defined(JSE_STRING_TOSOURCE) && (0==JSE_STRING_TOSOURCE)
#     undef JSE_STRING_TOSOURCE
#  endif
#  if defined(JSE_STRING_MATCH) && (0==JSE_STRING_MATCH)
#     undef JSE_STRING_MATCH
#  endif
#  if defined(JSE_STRING_REPLACE) && (0==JSE_STRING_REPLACE)
#     undef JSE_STRING_REPLACE
#  endif
#  if defined(JSE_STRING_SEARCH) && (0==JSE_STRING_SEARCH)
#     undef JSE_STRING_SEARCH
#  endif
   /* Define generic JSE_STRING_ANY */
#  if defined(JSE_STRING_OBJECT) \
   || defined(JSE_STRING_FROMCHARCODE) \
   || defined(JSE_STRING_CHARAT) \
   || defined(JSE_STRING_CHARCODEAT) \
   || defined(JSE_STRING_INDEXOF) \
   || defined(JSE_STRING_LASTINDEXOF) \
   || defined(JSE_STRING_SPLIT) \
   || defined(JSE_STRING_SUBSTR) \
   || defined(JSE_STRING_SUBSTRING) \
   || defined(JSE_STRING_TOLOWERCASE) \
   || defined(JSE_STRING_TOUPPERCASE) \
   || defined(JSE_STRING_CONCAT) \
   || defined(JSE_STRING_SLICE) \
   || defined(JSE_STRING_TOLOCALELOWERCASE) \
   || defined(JSE_STRING_TOLOCALEUPPERCASE) \
   || defined(JSE_STRING_TOLOCALECOMPARE) \
   || defined(JSE_STRING_TOSOURCE) \
   || defined(JSE_STRING_MATCH) \
   || defined(JSE_STRING_REPLACE) \
   || defined(JSE_STRING_SEARCH)
#     define JSE_STRING_ANY
#  endif

/*****************
 * REGEXP        *
 *****************/

   /* Check for JSE_REGEXP_ALL */
#  if defined(JSE_REGEXP_ALL)
#     if !defined(JSE_REGEXP_OBJECT)
#        define JSE_REGEXP_OBJECT                1
#     endif
#  endif /* JSE_REGEXP_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_REGEXP_OBJECT) && (0==JSE_REGEXP_OBJECT)
#     undef JSE_REGEXP_OBJECT
#  endif
   /* Define generic JSE_REGEXP_ANY */
#  if defined(JSE_REGEXP_OBJECT)
#     define JSE_REGEXP_ANY
#  endif

/*****************
 * BUFFER        *
 *****************/

   /* Check for JSE_BUFFER_ALL */
#  if defined(JSE_BUFFER_ALL)
#     if !defined(JSE_BUFFER_OBJECT)
#        define JSE_BUFFER_OBJECT                1
#     endif
#     if !defined(JSE_BUFFER_PUTVALUE)
#        define JSE_BUFFER_PUTVALUE              1
#     endif
#     if !defined(JSE_BUFFER_GETVALUE)
#        define JSE_BUFFER_GETVALUE              1
#     endif
#     if !defined(JSE_BUFFER_PUTSTRING)
#        define JSE_BUFFER_PUTSTRING             1
#     endif
#     if !defined(JSE_BUFFER_GETSTRING)
#        define JSE_BUFFER_GETSTRING             1
#     endif
#     if !defined(JSE_BUFFER_TOSTRING)
#        define JSE_BUFFER_TOSTRING              1
#     endif
#     if !defined(JSE_BUFFER_TOSOURCE)
#        define JSE_BUFFER_TOSOURCE              1
#     endif
#     if !defined(JSE_BUFFER_SUBBUFFER)
#        define JSE_BUFFER_SUBBUFFER             1
#     endif
#  endif /* JSE_BUFFER_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_BUFFER_OBJECT) && (0==JSE_BUFFER_OBJECT)
#     undef JSE_BUFFER_OBJECT
#  endif
#  if defined(JSE_BUFFER_PUTVALUE) && (0==JSE_BUFFER_PUTVALUE)
#     undef JSE_BUFFER_PUTVALUE
#  endif
#  if defined(JSE_BUFFER_GETVALUE) && (0==JSE_BUFFER_GETVALUE)
#     undef JSE_BUFFER_GETVALUE
#  endif
#  if defined(JSE_BUFFER_PUTSTRING) && (0==JSE_BUFFER_PUTSTRING)
#     undef JSE_BUFFER_PUTSTRING
#  endif
#  if defined(JSE_BUFFER_GETSTRING) && (0==JSE_BUFFER_GETSTRING)
#     undef JSE_BUFFER_GETSTRING
#  endif
#  if defined(JSE_BUFFER_TOSTRING) && (0==JSE_BUFFER_TOSTRING)
#     undef JSE_BUFFER_TOSTRING
#  endif
#  if defined(JSE_BUFFER_TOSOURCE) && (0==JSE_BUFFER_TOSOURCE)
#     undef JSE_BUFFER_TOSOURCE
#  endif
#  if defined(JSE_BUFFER_SUBBUFFER) && (0==JSE_BUFFER_SUBBUFFER)
#     undef JSE_BUFFER_SUBBUFFER
#  endif
   /* Define generic JSE_BUFFER_ANY */
#  if defined(JSE_BUFFER_OBJECT) \
   || defined(JSE_BUFFER_PUTVALUE) \
   || defined(JSE_BUFFER_GETVALUE) \
   || defined(JSE_BUFFER_PUTSTRING) \
   || defined(JSE_BUFFER_GETSTRING) \
   || defined(JSE_BUFFER_TOSTRING) \
   || defined(JSE_BUFFER_TOSOURCE) \
   || defined(JSE_BUFFER_SUBBUFFER)
#     define JSE_BUFFER_ANY
#  endif

/*****************
 * BOOLEAN       *
 *****************/

   /* Check for JSE_BOOLEAN_ALL */
#  if defined(JSE_BOOLEAN_ALL)
#     if !defined(JSE_BOOLEAN_OBJECT)
#        define JSE_BOOLEAN_OBJECT               1
#     endif
#     if !defined(JSE_BOOLEAN_TOSTRING)
#        define JSE_BOOLEAN_TOSTRING             1
#     endif
#     if !defined(JSE_BOOLEAN_TOSOURCE)
#        define JSE_BOOLEAN_TOSOURCE             1
#     endif
#  endif /* JSE_BOOLEAN_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_BOOLEAN_OBJECT) && (0==JSE_BOOLEAN_OBJECT)
#     undef JSE_BOOLEAN_OBJECT
#  endif
#  if defined(JSE_BOOLEAN_TOSTRING) && (0==JSE_BOOLEAN_TOSTRING)
#     undef JSE_BOOLEAN_TOSTRING
#  endif
#  if defined(JSE_BOOLEAN_TOSOURCE) && (0==JSE_BOOLEAN_TOSOURCE)
#     undef JSE_BOOLEAN_TOSOURCE
#  endif
   /* Define generic JSE_BOOLEAN_ANY */
#  if defined(JSE_BOOLEAN_OBJECT) \
   || defined(JSE_BOOLEAN_TOSTRING) \
   || defined(JSE_BOOLEAN_TOSOURCE)
#     define JSE_BOOLEAN_ANY
#  endif

/*****************
 * DATE          *
 *****************/

   /* Check for JSE_DATE_ALL */
#  if defined(JSE_DATE_ALL)
#     if !defined(JSE_DATE_OBJECT) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_OBJECT                  1
#     endif
#     if !defined(JSE_DATE_GETYEAR) \
         && (0!=JSE_FLOATING_POINT) && (!defined(JSE_MILLENIUM) || (0!=JSE_MILLENIUM))
#        define JSE_DATE_GETYEAR                 1
#     endif
#     if !defined(JSE_DATE_FROMSYSTEM) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_FROMSYSTEM              1
#     endif
#     if !defined(JSE_DATE_TOSYSTEM) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOSYSTEM                1
#     endif
#     if !defined(JSE_DATE_PARSE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_PARSE                   1
#     endif
#     if !defined(JSE_DATE_UTC) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_UTC                     1
#     endif
#     if !defined(JSE_DATE_TOSTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOSTRING                1
#     endif
#     if !defined(JSE_DATE_TODATESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TODATESTRING            1
#     endif
#     if !defined(JSE_DATE_TOTIMESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOTIMESTRING            1
#     endif
#     if !defined(JSE_DATE_TOLOCALESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOLOCALESTRING          1
#     endif
#     if !defined(JSE_DATE_TOLOCALEDATESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOLOCALEDATESTRING      1
#     endif
#     if !defined(JSE_DATE_TOLOCALETIMESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOLOCALETIMESTRING      1
#     endif
#     if !defined(JSE_DATE_GETTIME) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETTIME                 1
#     endif
#     if !defined(JSE_DATE_GETFULLYEAR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETFULLYEAR             1
#     endif
#     if !defined(JSE_DATE_GETUTCFULLYEAR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCFULLYEAR          1
#     endif
#     if !defined(JSE_DATE_GETMONTH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETMONTH                1
#     endif
#     if !defined(JSE_DATE_GETUTCMONTH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCMONTH             1
#     endif
#     if !defined(JSE_DATE_GETDATE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETDATE                 1
#     endif
#     if !defined(JSE_DATE_GETUTCDATE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCDATE              1
#     endif
#     if !defined(JSE_DATE_GETDAY) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETDAY                  1
#     endif
#     if !defined(JSE_DATE_GETUTCDAY) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCDAY               1
#     endif
#     if !defined(JSE_DATE_GETHOURS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETHOURS                1
#     endif
#     if !defined(JSE_DATE_GETUTCHOURS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCHOURS             1
#     endif
#     if !defined(JSE_DATE_GETMINUTES) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETMINUTES              1
#     endif
#     if !defined(JSE_DATE_GETUTCMINUTES) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCMINUTES           1
#     endif
#     if !defined(JSE_DATE_GETSECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETSECONDS              1
#     endif
#     if !defined(JSE_DATE_GETUTCSECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCSECONDS           1
#     endif
#     if !defined(JSE_DATE_GETMILLISECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETMILLISECONDS         1
#     endif
#     if !defined(JSE_DATE_GETUTCMILLISECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETUTCMILLISECONDS      1
#     endif
#     if !defined(JSE_DATE_GETTIMEZONEOFFSET) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_GETTIMEZONEOFFSET       1
#     endif
#     if !defined(JSE_DATE_SETTIME) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETTIME                 1
#     endif
#     if !defined(JSE_DATE_SETMILLISECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETMILLISECONDS         1
#     endif
#     if !defined(JSE_DATE_SETUTCMILLISECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCMILLISECONDS      1
#     endif
#     if !defined(JSE_DATE_SETSECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETSECONDS              1
#     endif
#     if !defined(JSE_DATE_SETUTCSECONDS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCSECONDS           1
#     endif
#     if !defined(JSE_DATE_SETMINUTES) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETMINUTES              1
#     endif
#     if !defined(JSE_DATE_SETUTCMINUTES) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCMINUTES           1
#     endif
#     if !defined(JSE_DATE_SETHOURS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETHOURS                1
#     endif
#     if !defined(JSE_DATE_SETUTCHOURS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCHOURS             1
#     endif
#     if !defined(JSE_DATE_SETDATE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETDATE                 1
#     endif
#     if !defined(JSE_DATE_SETUTCDATE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCDATE              1
#     endif
#     if !defined(JSE_DATE_SETMONTH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETMONTH                1
#     endif
#     if !defined(JSE_DATE_SETUTCMONTH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCMONTH             1
#     endif
#     if !defined(JSE_DATE_SETFULLYEAR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETFULLYEAR             1
#     endif
#     if !defined(JSE_DATE_SETUTCFULLYEAR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETUTCFULLYEAR          1
#     endif
#     if !defined(JSE_DATE_SETYEAR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_SETYEAR                 1
#     endif
#     if !defined(JSE_DATE_TOLOCALESTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOLOCALESTRING          1
#     endif
#     if !defined(JSE_DATE_TOUTCSTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOUTCSTRING             1
#     endif
#     if !defined(JSE_DATE_TOGMTSTRING) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOGMTSTRING             1
#     endif
#     if !defined(JSE_DATE_TOSOURCE) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_DATE_TOSOURCE                1
#     endif
#  endif /* JSE_DATE_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_DATE_OBJECT) && (0==JSE_DATE_OBJECT)
#     undef JSE_DATE_OBJECT
#  endif
#  if defined(JSE_DATE_GETYEAR) && (0==JSE_DATE_GETYEAR)
#     undef JSE_DATE_GETYEAR
#  endif
#  if defined(JSE_DATE_FROMSYSTEM) && (0==JSE_DATE_FROMSYSTEM)
#     undef JSE_DATE_FROMSYSTEM
#  endif
#  if defined(JSE_DATE_TOSYSTEM) && (0==JSE_DATE_TOSYSTEM)
#     undef JSE_DATE_TOSYSTEM
#  endif
#  if defined(JSE_DATE_PARSE) && (0==JSE_DATE_PARSE)
#     undef JSE_DATE_PARSE
#  endif
#  if defined(JSE_DATE_UTC) && (0==JSE_DATE_UTC)
#     undef JSE_DATE_UTC
#  endif
#  if defined(JSE_DATE_TOSTRING) && (0==JSE_DATE_TOSTRING)
#     undef JSE_DATE_TOSTRING
#  endif
#  if defined(JSE_DATE_TODATESTRING) && (0==JSE_DATE_TODATESTRING)
#     undef JSE_DATE_TODATESTRING
#  endif
#  if defined(JSE_DATE_TOTIMESTRING) && (0==JSE_DATE_TOTIMESTRING)
#     undef JSE_DATE_TOTIMESTRING
#  endif
#  if defined(JSE_DATE_TOLOCALESTRING) && (0==JSE_DATE_TOLOCALESTRING)
#     undef JSE_DATE_TOLOCALESTRING
#  endif
#  if defined(JSE_DATE_TOLOCALEDATESTRING) && (0==JSE_DATE_TOLOCALEDATESTRING)
#     undef JSE_DATE_TOLOCALEDATESTRING
#  endif
#  if defined(JSE_DATE_TOLOCALETIMESTRING) && (0==JSE_DATE_TOLOCALETIMESTRING)
#     undef JSE_DATE_TOLOCALETIMESTRING
#  endif
#  if defined(JSE_DATE_GETTIME) && (0==JSE_DATE_GETTIME)
#     undef JSE_DATE_GETTIME
#  endif
#  if defined(JSE_DATE_GETFULLYEAR) && (0==JSE_DATE_GETFULLYEAR)
#     undef JSE_DATE_GETFULLYEAR
#  endif
#  if defined(JSE_DATE_GETUTCFULLYEAR) && (0==JSE_DATE_GETUTCFULLYEAR)
#     undef JSE_DATE_GETUTCFULLYEAR
#  endif
#  if defined(JSE_DATE_GETMONTH) && (0==JSE_DATE_GETMONTH)
#     undef JSE_DATE_GETMONTH
#  endif
#  if defined(JSE_DATE_GETUTCMONTH) && (0==JSE_DATE_GETUTCMONTH)
#     undef JSE_DATE_GETUTCMONTH
#  endif
#  if defined(JSE_DATE_GETDATE) && (0==JSE_DATE_GETDATE)
#     undef JSE_DATE_GETDATE
#  endif
#  if defined(JSE_DATE_GETUTCDATE) && (0==JSE_DATE_GETUTCDATE)
#     undef JSE_DATE_GETUTCDATE
#  endif
#  if defined(JSE_DATE_GETDAY) && (0==JSE_DATE_GETDAY)
#     undef JSE_DATE_GETDAY
#  endif
#  if defined(JSE_DATE_GETUTCDAY) && (0==JSE_DATE_GETUTCDAY)
#     undef JSE_DATE_GETUTCDAY
#  endif
#  if defined(JSE_DATE_GETHOURS) && (0==JSE_DATE_GETHOURS)
#     undef JSE_DATE_GETHOURS
#  endif
#  if defined(JSE_DATE_GETUTCHOURS) && (0==JSE_DATE_GETUTCHOURS)
#     undef JSE_DATE_GETUTCHOURS
#  endif
#  if defined(JSE_DATE_GETMINUTES) && (0==JSE_DATE_GETMINUTES)
#     undef JSE_DATE_GETMINUTES
#  endif
#  if defined(JSE_DATE_GETUTCMINUTES) && (0==JSE_DATE_GETUTCMINUTES)
#     undef JSE_DATE_GETUTCMINUTES
#  endif
#  if defined(JSE_DATE_GETSECONDS) && (0==JSE_DATE_GETSECONDS)
#     undef JSE_DATE_GETSECONDS
#  endif
#  if defined(JSE_DATE_GETUTCSECONDS) && (0==JSE_DATE_GETUTCSECONDS)
#     undef JSE_DATE_GETUTCSECONDS
#  endif
#  if defined(JSE_DATE_GETMILLISECONDS) && (0==JSE_DATE_GETMILLISECONDS)
#     undef JSE_DATE_GETMILLISECONDS
#  endif
#  if defined(JSE_DATE_GETUTCMILLISECONDS) && (0==JSE_DATE_GETUTCMILLISECONDS)
#     undef JSE_DATE_GETUTCMILLISECONDS
#  endif
#  if defined(JSE_DATE_GETTIMEZONEOFFSET) && (0==JSE_DATE_GETTIMEZONEOFFSET)
#     undef JSE_DATE_GETTIMEZONEOFFSET
#  endif
#  if defined(JSE_DATE_SETTIME) && (0==JSE_DATE_SETTIME)
#     undef JSE_DATE_SETTIME
#  endif
#  if defined(JSE_DATE_SETMILLISECONDS) && (0==JSE_DATE_SETMILLISECONDS)
#     undef JSE_DATE_SETMILLISECONDS
#  endif
#  if defined(JSE_DATE_SETUTCMILLISECONDS) && (0==JSE_DATE_SETUTCMILLISECONDS)
#     undef JSE_DATE_SETUTCMILLISECONDS
#  endif
#  if defined(JSE_DATE_SETSECONDS) && (0==JSE_DATE_SETSECONDS)
#     undef JSE_DATE_SETSECONDS
#  endif
#  if defined(JSE_DATE_SETUTCSECONDS) && (0==JSE_DATE_SETUTCSECONDS)
#     undef JSE_DATE_SETUTCSECONDS
#  endif
#  if defined(JSE_DATE_SETMINUTES) && (0==JSE_DATE_SETMINUTES)
#     undef JSE_DATE_SETMINUTES
#  endif
#  if defined(JSE_DATE_SETUTCMINUTES) && (0==JSE_DATE_SETUTCMINUTES)
#     undef JSE_DATE_SETUTCMINUTES
#  endif
#  if defined(JSE_DATE_SETHOURS) && (0==JSE_DATE_SETHOURS)
#     undef JSE_DATE_SETHOURS
#  endif
#  if defined(JSE_DATE_SETUTCHOURS) && (0==JSE_DATE_SETUTCHOURS)
#     undef JSE_DATE_SETUTCHOURS
#  endif
#  if defined(JSE_DATE_SETDATE) && (0==JSE_DATE_SETDATE)
#     undef JSE_DATE_SETDATE
#  endif
#  if defined(JSE_DATE_SETUTCDATE) && (0==JSE_DATE_SETUTCDATE)
#     undef JSE_DATE_SETUTCDATE
#  endif
#  if defined(JSE_DATE_SETMONTH) && (0==JSE_DATE_SETMONTH)
#     undef JSE_DATE_SETMONTH
#  endif
#  if defined(JSE_DATE_SETUTCMONTH) && (0==JSE_DATE_SETUTCMONTH)
#     undef JSE_DATE_SETUTCMONTH
#  endif
#  if defined(JSE_DATE_SETFULLYEAR) && (0==JSE_DATE_SETFULLYEAR)
#     undef JSE_DATE_SETFULLYEAR
#  endif
#  if defined(JSE_DATE_SETUTCFULLYEAR) && (0==JSE_DATE_SETUTCFULLYEAR)
#     undef JSE_DATE_SETUTCFULLYEAR
#  endif
#  if defined(JSE_DATE_SETYEAR) && (0==JSE_DATE_SETYEAR)
#     undef JSE_DATE_SETYEAR
#  endif
#  if defined(JSE_DATE_TOLOCALESTRING) && (0==JSE_DATE_TOLOCALESTRING)
#     undef JSE_DATE_TOLOCALESTRING
#  endif
#  if defined(JSE_DATE_TOUTCSTRING) && (0==JSE_DATE_TOUTCSTRING)
#     undef JSE_DATE_TOUTCSTRING
#  endif
#  if defined(JSE_DATE_TOGMTSTRING) && (0==JSE_DATE_TOGMTSTRING)
#     undef JSE_DATE_TOGMTSTRING
#  endif
#  if defined(JSE_DATE_TOSOURCE) && (0==JSE_DATE_TOSOURCE)
#     undef JSE_DATE_TOSOURCE
#  endif
   /* Define generic JSE_DATE_ANY */
#  if defined(JSE_DATE_OBJECT) \
   || defined(JSE_DATE_GETYEAR) \
   || defined(JSE_DATE_FROMSYSTEM) \
   || defined(JSE_DATE_TOSYSTEM) \
   || defined(JSE_DATE_PARSE) \
   || defined(JSE_DATE_UTC) \
   || defined(JSE_DATE_TOSTRING) \
   || defined(JSE_DATE_TODATESTRING) \
   || defined(JSE_DATE_TOTIMESTRING) \
   || defined(JSE_DATE_TOLOCALESTRING) \
   || defined(JSE_DATE_TOLOCALEDATESTRING) \
   || defined(JSE_DATE_TOLOCALETIMESTRING) \
   || defined(JSE_DATE_GETTIME) \
   || defined(JSE_DATE_GETFULLYEAR) \
   || defined(JSE_DATE_GETUTCFULLYEAR) \
   || defined(JSE_DATE_GETMONTH) \
   || defined(JSE_DATE_GETUTCMONTH) \
   || defined(JSE_DATE_GETDATE) \
   || defined(JSE_DATE_GETUTCDATE) \
   || defined(JSE_DATE_GETDAY) \
   || defined(JSE_DATE_GETUTCDAY) \
   || defined(JSE_DATE_GETHOURS) \
   || defined(JSE_DATE_GETUTCHOURS) \
   || defined(JSE_DATE_GETMINUTES) \
   || defined(JSE_DATE_GETUTCMINUTES) \
   || defined(JSE_DATE_GETSECONDS) \
   || defined(JSE_DATE_GETUTCSECONDS) \
   || defined(JSE_DATE_GETMILLISECONDS) \
   || defined(JSE_DATE_GETUTCMILLISECONDS) \
   || defined(JSE_DATE_GETTIMEZONEOFFSET) \
   || defined(JSE_DATE_SETTIME) \
   || defined(JSE_DATE_SETMILLISECONDS) \
   || defined(JSE_DATE_SETUTCMILLISECONDS) \
   || defined(JSE_DATE_SETSECONDS) \
   || defined(JSE_DATE_SETUTCSECONDS) \
   || defined(JSE_DATE_SETMINUTES) \
   || defined(JSE_DATE_SETUTCMINUTES) \
   || defined(JSE_DATE_SETHOURS) \
   || defined(JSE_DATE_SETUTCHOURS) \
   || defined(JSE_DATE_SETDATE) \
   || defined(JSE_DATE_SETUTCDATE) \
   || defined(JSE_DATE_SETMONTH) \
   || defined(JSE_DATE_SETUTCMONTH) \
   || defined(JSE_DATE_SETFULLYEAR) \
   || defined(JSE_DATE_SETUTCFULLYEAR) \
   || defined(JSE_DATE_SETYEAR) \
   || defined(JSE_DATE_TOLOCALESTRING) \
   || defined(JSE_DATE_TOUTCSTRING) \
   || defined(JSE_DATE_TOGMTSTRING) \
   || defined(JSE_DATE_TOSOURCE)
#     define JSE_DATE_ANY
#  endif

/*****************
 * FUNCTION      *
 *****************/

   /* Check for JSE_FUNCTION_ALL */
#  if defined(JSE_FUNCTION_ALL)
#     if !defined(JSE_FUNCTION_OBJECT)
#        define JSE_FUNCTION_OBJECT              1
#     endif
#     if !defined(JSE_FUNCTION_TOSOURCE)
#        define JSE_FUNCTION_TOSOURCE            1
#     endif
#     if !defined(JSE_FUNCTION_CALL)
#        define JSE_FUNCTION_CALL                1
#     endif
#     if !defined(JSE_FUNCTION_APPLY)
#        define JSE_FUNCTION_APPLY               1
#     endif
#  endif /* JSE_FUNCTION_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_FUNCTION_OBJECT) && (0==JSE_FUNCTION_OBJECT)
#     undef JSE_FUNCTION_OBJECT
#  endif
#  if defined(JSE_FUNCTION_TOSOURCE) && (0==JSE_FUNCTION_TOSOURCE)
#     undef JSE_FUNCTION_TOSOURCE
#  endif
#  if defined(JSE_FUNCTION_CALL) && (0==JSE_FUNCTION_CALL)
#     undef JSE_FUNCTION_CALL
#  endif
#  if defined(JSE_FUNCTION_APPLY) && (0==JSE_FUNCTION_APPLY)
#     undef JSE_FUNCTION_APPLY
#  endif
   /* Define generic JSE_FUNCTION_ANY */
#  if defined(JSE_FUNCTION_OBJECT) \
   || defined(JSE_FUNCTION_TOSOURCE) \
   || defined(JSE_FUNCTION_CALL) \
   || defined(JSE_FUNCTION_APPLY)
#     define JSE_FUNCTION_ANY
#  endif

/*****************
 * MATH          *
 *****************/

   /* Check for JSE_MATH_ALL */
#  if defined(JSE_MATH_ALL)
#     if !defined(JSE_MATH_E) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_E                       1
#     endif
#     if !defined(JSE_MATH_LN10) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_LN10                    1
#     endif
#     if !defined(JSE_MATH_LN2) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_LN2                     1
#     endif
#     if !defined(JSE_MATH_LOG2E) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_LOG2E                   1
#     endif
#     if !defined(JSE_MATH_LOG10E) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_LOG10E                  1
#     endif
#     if !defined(JSE_MATH_PI) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_PI                      1
#     endif
#     if !defined(JSE_MATH_SQRT1_2) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_SQRT1_2                 1
#     endif
#     if !defined(JSE_MATH_SQRT2) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_SQRT2                   1
#     endif
#     if !defined(JSE_MATH_ABS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ABS                     1
#     endif
#     if !defined(JSE_MATH_ACOS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ACOS                    1
#     endif
#     if !defined(JSE_MATH_ASIN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ASIN                    1
#     endif
#     if !defined(JSE_MATH_ATAN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ATAN                    1
#     endif
#     if !defined(JSE_MATH_ATAN2) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ATAN2                   1
#     endif
#     if !defined(JSE_MATH_CEIL) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_CEIL                    1
#     endif
#     if !defined(JSE_MATH_COS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_COS                     1
#     endif
#     if !defined(JSE_MATH_EXP) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_EXP                     1
#     endif
#     if !defined(JSE_MATH_FLOOR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_FLOOR                   1
#     endif
#     if !defined(JSE_MATH_LOG) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_LOG                     1
#     endif
#     if !defined(JSE_MATH_MAX) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_MAX                     1
#     endif
#     if !defined(JSE_MATH_MIN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_MIN                     1
#     endif
#     if !defined(JSE_MATH_POW) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_POW                     1
#     endif
#     if !defined(JSE_MATH_SIN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_SIN                     1
#     endif
#     if !defined(JSE_MATH_SQRT) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_SQRT                    1
#     endif
#     if !defined(JSE_MATH_TAN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_TAN                     1
#     endif
#     if !defined(JSE_MATH_RANDOM) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_RANDOM                  1
#     endif
#     if !defined(JSE_MATH_ROUND) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_MATH_ROUND                   1
#     endif
#  endif /* JSE_MATH_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_MATH_E) && (0==JSE_MATH_E)
#     undef JSE_MATH_E
#  endif
#  if defined(JSE_MATH_LN10) && (0==JSE_MATH_LN10)
#     undef JSE_MATH_LN10
#  endif
#  if defined(JSE_MATH_LN2) && (0==JSE_MATH_LN2)
#     undef JSE_MATH_LN2
#  endif
#  if defined(JSE_MATH_LOG2E) && (0==JSE_MATH_LOG2E)
#     undef JSE_MATH_LOG2E
#  endif
#  if defined(JSE_MATH_LOG10E) && (0==JSE_MATH_LOG10E)
#     undef JSE_MATH_LOG10E
#  endif
#  if defined(JSE_MATH_PI) && (0==JSE_MATH_PI)
#     undef JSE_MATH_PI
#  endif
#  if defined(JSE_MATH_SQRT1_2) && (0==JSE_MATH_SQRT1_2)
#     undef JSE_MATH_SQRT1_2
#  endif
#  if defined(JSE_MATH_SQRT2) && (0==JSE_MATH_SQRT2)
#     undef JSE_MATH_SQRT2
#  endif
#  if defined(JSE_MATH_ABS) && (0==JSE_MATH_ABS)
#     undef JSE_MATH_ABS
#  endif
#  if defined(JSE_MATH_ACOS) && (0==JSE_MATH_ACOS)
#     undef JSE_MATH_ACOS
#  endif
#  if defined(JSE_MATH_ASIN) && (0==JSE_MATH_ASIN)
#     undef JSE_MATH_ASIN
#  endif
#  if defined(JSE_MATH_ATAN) && (0==JSE_MATH_ATAN)
#     undef JSE_MATH_ATAN
#  endif
#  if defined(JSE_MATH_ATAN2) && (0==JSE_MATH_ATAN2)
#     undef JSE_MATH_ATAN2
#  endif
#  if defined(JSE_MATH_CEIL) && (0==JSE_MATH_CEIL)
#     undef JSE_MATH_CEIL
#  endif
#  if defined(JSE_MATH_COS) && (0==JSE_MATH_COS)
#     undef JSE_MATH_COS
#  endif
#  if defined(JSE_MATH_EXP) && (0==JSE_MATH_EXP)
#     undef JSE_MATH_EXP
#  endif
#  if defined(JSE_MATH_FLOOR) && (0==JSE_MATH_FLOOR)
#     undef JSE_MATH_FLOOR
#  endif
#  if defined(JSE_MATH_LOG) && (0==JSE_MATH_LOG)
#     undef JSE_MATH_LOG
#  endif
#  if defined(JSE_MATH_MAX) && (0==JSE_MATH_MAX)
#     undef JSE_MATH_MAX
#  endif
#  if defined(JSE_MATH_MIN) && (0==JSE_MATH_MIN)
#     undef JSE_MATH_MIN
#  endif
#  if defined(JSE_MATH_POW) && (0==JSE_MATH_POW)
#     undef JSE_MATH_POW
#  endif
#  if defined(JSE_MATH_SIN) && (0==JSE_MATH_SIN)
#     undef JSE_MATH_SIN
#  endif
#  if defined(JSE_MATH_SQRT) && (0==JSE_MATH_SQRT)
#     undef JSE_MATH_SQRT
#  endif
#  if defined(JSE_MATH_TAN) && (0==JSE_MATH_TAN)
#     undef JSE_MATH_TAN
#  endif
#  if defined(JSE_MATH_RANDOM) && (0==JSE_MATH_RANDOM)
#     undef JSE_MATH_RANDOM
#  endif
#  if defined(JSE_MATH_ROUND) && (0==JSE_MATH_ROUND)
#     undef JSE_MATH_ROUND
#  endif
   /* Define generic JSE_MATH_ANY */
#  if defined(JSE_MATH_E) \
   || defined(JSE_MATH_LN10) \
   || defined(JSE_MATH_LN2) \
   || defined(JSE_MATH_LOG2E) \
   || defined(JSE_MATH_LOG10E) \
   || defined(JSE_MATH_PI) \
   || defined(JSE_MATH_SQRT1_2) \
   || defined(JSE_MATH_SQRT2) \
   || defined(JSE_MATH_ABS) \
   || defined(JSE_MATH_ACOS) \
   || defined(JSE_MATH_ASIN) \
   || defined(JSE_MATH_ATAN) \
   || defined(JSE_MATH_ATAN2) \
   || defined(JSE_MATH_CEIL) \
   || defined(JSE_MATH_COS) \
   || defined(JSE_MATH_EXP) \
   || defined(JSE_MATH_FLOOR) \
   || defined(JSE_MATH_LOG) \
   || defined(JSE_MATH_MAX) \
   || defined(JSE_MATH_MIN) \
   || defined(JSE_MATH_POW) \
   || defined(JSE_MATH_SIN) \
   || defined(JSE_MATH_SQRT) \
   || defined(JSE_MATH_TAN) \
   || defined(JSE_MATH_RANDOM) \
   || defined(JSE_MATH_ROUND)
#     define JSE_MATH_ANY
#  endif

/*****************
 * NUMBER        *
 *****************/

   /* Check for JSE_NUMBER_ALL */
#  if defined(JSE_NUMBER_ALL)
#     if !defined(JSE_NUMBER_OBJECT)
#        define JSE_NUMBER_OBJECT                1
#     endif
#     if !defined(JSE_NUMBER_TOSTRING)
#        define JSE_NUMBER_TOSTRING              1
#     endif
#     if !defined(JSE_NUMBER_TOLOCALESTRING)
#        define JSE_NUMBER_TOLOCALESTRING        1
#     endif
#     if !defined(JSE_NUMBER_TOSOURCE)
#        define JSE_NUMBER_TOSOURCE              1
#     endif
#     if !defined(JSE_NUMBER_MAX_VALUE)
#        define JSE_NUMBER_MAX_VALUE             1
#     endif
#     if !defined(JSE_NUMBER_MIN_VALUE)
#        define JSE_NUMBER_MIN_VALUE             1
#     endif
#     if !defined(JSE_NUMBER_NAN)
#        define JSE_NUMBER_NAN                   1
#     endif
#     if !defined(JSE_NUMBER_NEGATIVE_INFINITY)
#        define JSE_NUMBER_NEGATIVE_INFINITY     1
#     endif
#     if !defined(JSE_NUMBER_POSITIVE_INFINITY)
#        define JSE_NUMBER_POSITIVE_INFINITY     1
#     endif
#     if !defined(JSE_NUMBER_TOFIXED) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_NUMBER_TOFIXED               1
#     endif
#     if !defined(JSE_NUMBER_TOEXPONENTIAL) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_NUMBER_TOEXPONENTIAL         1
#     endif
#     if !defined(JSE_NUMBER_TOPRECISION) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_NUMBER_TOPRECISION           1
#     endif
#  endif /* JSE_NUMBER_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_NUMBER_OBJECT) && (0==JSE_NUMBER_OBJECT)
#     undef JSE_NUMBER_OBJECT
#  endif
#  if defined(JSE_NUMBER_TOSTRING) && (0==JSE_NUMBER_TOSTRING)
#     undef JSE_NUMBER_TOSTRING
#  endif
#  if defined(JSE_NUMBER_TOLOCALESTRING) && (0==JSE_NUMBER_TOLOCALESTRING)
#     undef JSE_NUMBER_TOLOCALESTRING
#  endif
#  if defined(JSE_NUMBER_TOSOURCE) && (0==JSE_NUMBER_TOSOURCE)
#     undef JSE_NUMBER_TOSOURCE
#  endif
#  if defined(JSE_NUMBER_MAX_VALUE) && (0==JSE_NUMBER_MAX_VALUE)
#     undef JSE_NUMBER_MAX_VALUE
#  endif
#  if defined(JSE_NUMBER_MIN_VALUE) && (0==JSE_NUMBER_MIN_VALUE)
#     undef JSE_NUMBER_MIN_VALUE
#  endif
#  if defined(JSE_NUMBER_NAN) && (0==JSE_NUMBER_NAN)
#     undef JSE_NUMBER_NAN
#  endif
#  if defined(JSE_NUMBER_NEGATIVE_INFINITY) && (0==JSE_NUMBER_NEGATIVE_INFINITY)
#     undef JSE_NUMBER_NEGATIVE_INFINITY
#  endif
#  if defined(JSE_NUMBER_POSITIVE_INFINITY) && (0==JSE_NUMBER_POSITIVE_INFINITY)
#     undef JSE_NUMBER_POSITIVE_INFINITY
#  endif
#  if defined(JSE_NUMBER_TOFIXED) && (0==JSE_NUMBER_TOFIXED)
#     undef JSE_NUMBER_TOFIXED
#  endif
#  if defined(JSE_NUMBER_TOEXPONENTIAL) && (0==JSE_NUMBER_TOEXPONENTIAL)
#     undef JSE_NUMBER_TOEXPONENTIAL
#  endif
#  if defined(JSE_NUMBER_TOPRECISION) && (0==JSE_NUMBER_TOPRECISION)
#     undef JSE_NUMBER_TOPRECISION
#  endif
   /* Define generic JSE_NUMBER_ANY */
#  if defined(JSE_NUMBER_OBJECT) \
   || defined(JSE_NUMBER_TOSTRING) \
   || defined(JSE_NUMBER_TOLOCALESTRING) \
   || defined(JSE_NUMBER_TOSOURCE) \
   || defined(JSE_NUMBER_MAX_VALUE) \
   || defined(JSE_NUMBER_MIN_VALUE) \
   || defined(JSE_NUMBER_NAN) \
   || defined(JSE_NUMBER_NEGATIVE_INFINITY) \
   || defined(JSE_NUMBER_POSITIVE_INFINITY) \
   || defined(JSE_NUMBER_TOFIXED) \
   || defined(JSE_NUMBER_TOEXPONENTIAL) \
   || defined(JSE_NUMBER_TOPRECISION)
#     define JSE_NUMBER_ANY
#  endif

/*****************
 * OBJECT        *
 *****************/

   /* Check for JSE_OBJECT_ALL */
#  if defined(JSE_OBJECT_ALL)
#     if !defined(JSE_OBJECT_OBJECT)
#        define JSE_OBJECT_OBJECT                1
#     endif
#     if !defined(JSE_OBJECT_TOSOURCE)
#        define JSE_OBJECT_TOSOURCE              1
#     endif
#     if !defined(JSE_OBJECT_ISPROTOTYPEOF)
#        define JSE_OBJECT_ISPROTOTYPEOF         1
#     endif
#     if !defined(JSE_OBJECT_PROPERTYISENUMERABLE)
#        define JSE_OBJECT_PROPERTYISENUMERABLE  1
#     endif
#     if !defined(JSE_OBJECT_HASOWNPROPERTY)
#        define JSE_OBJECT_HASOWNPROPERTY        1
#     endif
#     if !defined(JSE_OBJECT_TOLOCALESTRING)
#        define JSE_OBJECT_TOLOCALESTRING        1
#     endif
#  endif /* JSE_OBJECT_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_OBJECT_OBJECT) && (0==JSE_OBJECT_OBJECT)
#     undef JSE_OBJECT_OBJECT
#  endif
#  if defined(JSE_OBJECT_TOSOURCE) && (0==JSE_OBJECT_TOSOURCE)
#     undef JSE_OBJECT_TOSOURCE
#  endif
#  if defined(JSE_OBJECT_ISPROTOTYPEOF) && (0==JSE_OBJECT_ISPROTOTYPEOF)
#     undef JSE_OBJECT_ISPROTOTYPEOF
#  endif
#  if defined(JSE_OBJECT_PROPERTYISENUMERABLE) && (0==JSE_OBJECT_PROPERTYISENUMERABLE)
#     undef JSE_OBJECT_PROPERTYISENUMERABLE
#  endif
#  if defined(JSE_OBJECT_HASOWNPROPERTY) && (0==JSE_OBJECT_HASOWNPROPERTY)
#     undef JSE_OBJECT_HASOWNPROPERTY
#  endif
#  if defined(JSE_OBJECT_TOLOCALESTRING) && (0==JSE_OBJECT_TOLOCALESTRING)
#     undef JSE_OBJECT_TOLOCALESTRING
#  endif
   /* Define generic JSE_OBJECT_ANY */
#  if defined(JSE_OBJECT_OBJECT) \
   || defined(JSE_OBJECT_TOSOURCE) \
   || defined(JSE_OBJECT_ISPROTOTYPEOF) \
   || defined(JSE_OBJECT_PROPERTYISENUMERABLE) \
   || defined(JSE_OBJECT_HASOWNPROPERTY) \
   || defined(JSE_OBJECT_TOLOCALESTRING)
#     define JSE_OBJECT_ANY
#  endif

/*****************
 * EXCEPTION     *
 *****************/

   /* Check for JSE_EXCEPTION_ALL */
#  if defined(JSE_EXCEPTION_ALL)
#     if !defined(JSE_EXCEPTION_OBJECT)
#        define JSE_EXCEPTION_OBJECT             1
#     endif
#  endif /* JSE_EXCEPTION_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_EXCEPTION_OBJECT) && (0==JSE_EXCEPTION_OBJECT)
#     undef JSE_EXCEPTION_OBJECT
#  endif
   /* Define generic JSE_EXCEPTION_ANY */
#  if defined(JSE_EXCEPTION_OBJECT)
#     define JSE_EXCEPTION_ANY
#  endif

/*****************
 * ECMAMISC      *
 *****************/

   /* Check for JSE_ECMAMISC_ALL */
#  if defined(JSE_ECMAMISC_ALL)
#     if !defined(JSE_ECMAMISC_INFINITY)
#        define JSE_ECMAMISC_INFINITY            1
#     endif
#     if !defined(JSE_ECMAMISC_NAN)
#        define JSE_ECMAMISC_NAN                 1
#     endif
#     if !defined(JSE_ECMAMISC_ESCAPE)
#        define JSE_ECMAMISC_ESCAPE              1
#     endif
#     if !defined(JSE_ECMAMISC_UNESCAPE)
#        define JSE_ECMAMISC_UNESCAPE            1
#     endif
#     if !defined(JSE_ECMAMISC_EVAL)
#        define JSE_ECMAMISC_EVAL                1
#     endif
#     if !defined(JSE_ECMAMISC_ISFINITE)
#        define JSE_ECMAMISC_ISFINITE            1
#     endif
#     if !defined(JSE_ECMAMISC_ISNAN)
#        define JSE_ECMAMISC_ISNAN               1
#     endif
#     if !defined(JSE_ECMAMISC_PARSEINT)
#        define JSE_ECMAMISC_PARSEINT            1
#     endif
#     if !defined(JSE_ECMAMISC_PARSEFLOAT) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_ECMAMISC_PARSEFLOAT          1
#     endif
#     if !defined(JSE_ECMAMISC_ENCODEURI)
#        define JSE_ECMAMISC_ENCODEURI           1
#     endif
#     if !defined(JSE_ECMAMISC_ENCODEURICOMPONENT)
#        define JSE_ECMAMISC_ENCODEURICOMPONENT  1
#     endif
#     if !defined(JSE_ECMAMISC_DECODEURI)
#        define JSE_ECMAMISC_DECODEURI           1
#     endif
#     if !defined(JSE_ECMAMISC_DECODEURICOMPONENT)
#        define JSE_ECMAMISC_DECODEURICOMPONENT  1
#     endif
#  endif /* JSE_ECMAMISC_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_ECMAMISC_INFINITY) && (0==JSE_ECMAMISC_INFINITY)
#     undef JSE_ECMAMISC_INFINITY
#  endif
#  if defined(JSE_ECMAMISC_NAN) && (0==JSE_ECMAMISC_NAN)
#     undef JSE_ECMAMISC_NAN
#  endif
#  if defined(JSE_ECMAMISC_ESCAPE) && (0==JSE_ECMAMISC_ESCAPE)
#     undef JSE_ECMAMISC_ESCAPE
#  endif
#  if defined(JSE_ECMAMISC_UNESCAPE) && (0==JSE_ECMAMISC_UNESCAPE)
#     undef JSE_ECMAMISC_UNESCAPE
#  endif
#  if defined(JSE_ECMAMISC_EVAL) && (0==JSE_ECMAMISC_EVAL)
#     undef JSE_ECMAMISC_EVAL
#  endif
#  if defined(JSE_ECMAMISC_ISFINITE) && (0==JSE_ECMAMISC_ISFINITE)
#     undef JSE_ECMAMISC_ISFINITE
#  endif
#  if defined(JSE_ECMAMISC_ISNAN) && (0==JSE_ECMAMISC_ISNAN)
#     undef JSE_ECMAMISC_ISNAN
#  endif
#  if defined(JSE_ECMAMISC_PARSEINT) && (0==JSE_ECMAMISC_PARSEINT)
#     undef JSE_ECMAMISC_PARSEINT
#  endif
#  if defined(JSE_ECMAMISC_PARSEFLOAT) && (0==JSE_ECMAMISC_PARSEFLOAT)
#     undef JSE_ECMAMISC_PARSEFLOAT
#  endif
#  if defined(JSE_ECMAMISC_ENCODEURI) && (0==JSE_ECMAMISC_ENCODEURI)
#     undef JSE_ECMAMISC_ENCODEURI
#  endif
#  if defined(JSE_ECMAMISC_ENCODEURICOMPONENT) && (0==JSE_ECMAMISC_ENCODEURICOMPONENT)
#     undef JSE_ECMAMISC_ENCODEURICOMPONENT
#  endif
#  if defined(JSE_ECMAMISC_DECODEURI) && (0==JSE_ECMAMISC_DECODEURI)
#     undef JSE_ECMAMISC_DECODEURI
#  endif
#  if defined(JSE_ECMAMISC_DECODEURICOMPONENT) && (0==JSE_ECMAMISC_DECODEURICOMPONENT)
#     undef JSE_ECMAMISC_DECODEURICOMPONENT
#  endif
   /* Define generic JSE_ECMAMISC_ANY */
#  if defined(JSE_ECMAMISC_INFINITY) \
   || defined(JSE_ECMAMISC_NAN) \
   || defined(JSE_ECMAMISC_ESCAPE) \
   || defined(JSE_ECMAMISC_UNESCAPE) \
   || defined(JSE_ECMAMISC_EVAL) \
   || defined(JSE_ECMAMISC_ISFINITE) \
   || defined(JSE_ECMAMISC_ISNAN) \
   || defined(JSE_ECMAMISC_PARSEINT) \
   || defined(JSE_ECMAMISC_PARSEFLOAT) \
   || defined(JSE_ECMAMISC_ENCODEURI) \
   || defined(JSE_ECMAMISC_ENCODEURICOMPONENT) \
   || defined(JSE_ECMAMISC_DECODEURI) \
   || defined(JSE_ECMAMISC_DECODEURICOMPONENT)
#     define JSE_ECMAMISC_ANY
#  endif

/*****************
 * SELIB         *
 *****************/

   /* Check for JSE_SELIB_ALL */
#  if defined(JSE_SELIB_ALL)
#     if !defined(JSE_SELIB_BLOB_GET)
#        define JSE_SELIB_BLOB_GET               1
#     endif
#     if !defined(JSE_SELIB_BLOB_PUT)
#        define JSE_SELIB_BLOB_PUT               1
#     endif
#     if !defined(JSE_SELIB_BLOB_SIZE)
#        define JSE_SELIB_BLOB_SIZE              1
#     endif
#     if !defined(JSE_SELIB_BOUND) \
         && defined(JSE_BINDABLE) && (0!=JSE_BINDABLE)
#        define JSE_SELIB_BOUND                  1
#     endif
#     if !defined(JSE_SELIB_COMPILESCRIPT) \
         && (defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC))
#        define JSE_SELIB_COMPILESCRIPT          1
#     endif
#     if !defined(JSE_SELIB_CREATECALLBACK) \
         && 0 && (defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__))
#        define JSE_SELIB_CREATECALLBACK         1
#     endif
#     if !defined(JSE_SELIB_DESTROYCALLBACK) \
         && 0 && (defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__))
#        define JSE_SELIB_DESTROYCALLBACK        1
#     endif
#     if !defined(JSE_SELIB_DIRECTORY)
#        define JSE_SELIB_DIRECTORY              1
#     endif
#     if !defined(JSE_SELIB_DYNAMICLINK) \
         && !defined(__JSE_DOS16__) && !defined(__JSE_DOS32__) && !defined(__JSE_IOS__)
#        define JSE_SELIB_DYNAMICLINK            1
#     endif
#     if !defined(JSE_SELIB_FULLPATH)
#        define JSE_SELIB_FULLPATH               1
#     endif
#     if !defined(JSE_SELIB_GETOBJECTPROPERTIES)
#        define JSE_SELIB_GETOBJECTPROPERTIES    1
#     endif
#     if !defined(JSE_SELIB_INSECURITY) \
         && defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
#        define JSE_SELIB_INSECURITY             1
#     endif
#     if !defined(JSE_SELIB_INTERPRET)
#        define JSE_SELIB_INTERPRET              1
#     endif
#     if !defined(JSE_SELIB_INTERPRETINNEWTHREAD) \
         && (defined(__JSE_WIN32__) || defined(__JSE_CON32__) || \
defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) || defined(__JSE_UNIX__) || \
defined(__JSE_UNIX__) || defined(__JSE_MAC__))
#        define JSE_SELIB_INTERPRETINNEWTHREAD   1
#     endif
#     if !defined(JSE_SELIB_MEMDEBUG) \
         && defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG)
#        define JSE_SELIB_MEMDEBUG               1
#     endif
#     if !defined(JSE_SELIB_MEMVERBOSE) \
         && defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG)
#        define JSE_SELIB_MEMVERBOSE             1
#     endif
#     if !defined(JSE_SELIB_PEEK)
#        define JSE_SELIB_PEEK                   1
#     endif
#     if !defined(JSE_SELIB_POINTER)
#        define JSE_SELIB_POINTER                1
#     endif
#     if !defined(JSE_SELIB_POKE)
#        define JSE_SELIB_POKE                   1
#     endif
#     if !defined(JSE_SELIB_SPAWN)
#        define JSE_SELIB_SPAWN                  1
#     endif
#     if !defined(JSE_SELIB_SPLITFILENAME)
#        define JSE_SELIB_SPLITFILENAME          1
#     endif
#     if !defined(JSE_SELIB_SUSPEND)
#        define JSE_SELIB_SUSPEND                1
#     endif
#     if !defined(JSE_SELIB_VERSION)
#        define JSE_SELIB_VERSION                1
#     endif
#  endif /* JSE_SELIB_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_SELIB_BLOB_GET) && (0==JSE_SELIB_BLOB_GET)
#     undef JSE_SELIB_BLOB_GET
#  endif
#  if defined(JSE_SELIB_BLOB_PUT) && (0==JSE_SELIB_BLOB_PUT)
#     undef JSE_SELIB_BLOB_PUT
#  endif
#  if defined(JSE_SELIB_BLOB_SIZE) && (0==JSE_SELIB_BLOB_SIZE)
#     undef JSE_SELIB_BLOB_SIZE
#  endif
#  if defined(JSE_SELIB_BOUND) && (0==JSE_SELIB_BOUND)
#     undef JSE_SELIB_BOUND
#  endif
#  if defined(JSE_SELIB_COMPILESCRIPT) && (0==JSE_SELIB_COMPILESCRIPT)
#     undef JSE_SELIB_COMPILESCRIPT
#  endif
#  if defined(JSE_SELIB_CREATECALLBACK) && (0==JSE_SELIB_CREATECALLBACK)
#     undef JSE_SELIB_CREATECALLBACK
#  endif
#  if defined(JSE_SELIB_DESTROYCALLBACK) && (0==JSE_SELIB_DESTROYCALLBACK)
#     undef JSE_SELIB_DESTROYCALLBACK
#  endif
#  if defined(JSE_SELIB_DIRECTORY) && (0==JSE_SELIB_DIRECTORY)
#     undef JSE_SELIB_DIRECTORY
#  endif
#  if defined(JSE_SELIB_DYNAMICLINK) && (0==JSE_SELIB_DYNAMICLINK)
#     undef JSE_SELIB_DYNAMICLINK
#  endif
#  if defined(JSE_SELIB_FULLPATH) && (0==JSE_SELIB_FULLPATH)
#     undef JSE_SELIB_FULLPATH
#  endif
#  if defined(JSE_SELIB_GETOBJECTPROPERTIES) && (0==JSE_SELIB_GETOBJECTPROPERTIES)
#     undef JSE_SELIB_GETOBJECTPROPERTIES
#  endif
#  if defined(JSE_SELIB_INSECURITY) && (0==JSE_SELIB_INSECURITY)
#     undef JSE_SELIB_INSECURITY
#  endif
#  if defined(JSE_SELIB_INTERPRET) && (0==JSE_SELIB_INTERPRET)
#     undef JSE_SELIB_INTERPRET
#  endif
#  if defined(JSE_SELIB_INTERPRETINNEWTHREAD) && (0==JSE_SELIB_INTERPRETINNEWTHREAD)
#     undef JSE_SELIB_INTERPRETINNEWTHREAD
#  endif
#  if defined(JSE_SELIB_MEMDEBUG) && (0==JSE_SELIB_MEMDEBUG)
#     undef JSE_SELIB_MEMDEBUG
#  endif
#  if defined(JSE_SELIB_MEMVERBOSE) && (0==JSE_SELIB_MEMVERBOSE)
#     undef JSE_SELIB_MEMVERBOSE
#  endif
#  if defined(JSE_SELIB_PEEK) && (0==JSE_SELIB_PEEK)
#     undef JSE_SELIB_PEEK
#  endif
#  if defined(JSE_SELIB_POINTER) && (0==JSE_SELIB_POINTER)
#     undef JSE_SELIB_POINTER
#  endif
#  if defined(JSE_SELIB_POKE) && (0==JSE_SELIB_POKE)
#     undef JSE_SELIB_POKE
#  endif
#  if defined(JSE_SELIB_SPAWN) && (0==JSE_SELIB_SPAWN)
#     undef JSE_SELIB_SPAWN
#  endif
#  if defined(JSE_SELIB_SPLITFILENAME) && (0==JSE_SELIB_SPLITFILENAME)
#     undef JSE_SELIB_SPLITFILENAME
#  endif
#  if defined(JSE_SELIB_SUSPEND) && (0==JSE_SELIB_SUSPEND)
#     undef JSE_SELIB_SUSPEND
#  endif
#  if defined(JSE_SELIB_VERSION) && (0==JSE_SELIB_VERSION)
#     undef JSE_SELIB_VERSION
#  endif
   /* Define generic JSE_SELIB_ANY */
#  if defined(JSE_SELIB_BLOB_GET) \
   || defined(JSE_SELIB_BLOB_PUT) \
   || defined(JSE_SELIB_BLOB_SIZE) \
   || defined(JSE_SELIB_BOUND) \
   || defined(JSE_SELIB_COMPILESCRIPT) \
   || defined(JSE_SELIB_CREATECALLBACK) \
   || defined(JSE_SELIB_DESTROYCALLBACK) \
   || defined(JSE_SELIB_DIRECTORY) \
   || defined(JSE_SELIB_DYNAMICLINK) \
   || defined(JSE_SELIB_FULLPATH) \
   || defined(JSE_SELIB_GETOBJECTPROPERTIES) \
   || defined(JSE_SELIB_INSECURITY) \
   || defined(JSE_SELIB_INTERPRET) \
   || defined(JSE_SELIB_INTERPRETINNEWTHREAD) \
   || defined(JSE_SELIB_MEMDEBUG) \
   || defined(JSE_SELIB_MEMVERBOSE) \
   || defined(JSE_SELIB_PEEK) \
   || defined(JSE_SELIB_POINTER) \
   || defined(JSE_SELIB_POKE) \
   || defined(JSE_SELIB_SPAWN) \
   || defined(JSE_SELIB_SPLITFILENAME) \
   || defined(JSE_SELIB_SUSPEND) \
   || defined(JSE_SELIB_VERSION)
#     define JSE_SELIB_ANY
#  endif

/*****************
 * UNIX          *
 *****************/

   /* Check for JSE_UNIX_ALL */
#  if defined(JSE_UNIX_ALL)
#     if !defined(JSE_UNIX_FORK)
#        define JSE_UNIX_FORK                    1
#     endif
#     if !defined(JSE_UNIX_KILL)
#        define JSE_UNIX_KILL                    1
#     endif
#     if !defined(JSE_UNIX_SETGID)
#        define JSE_UNIX_SETGID                  1
#     endif
#     if !defined(JSE_UNIX_SETSID)
#        define JSE_UNIX_SETSID                  1
#     endif
#     if !defined(JSE_UNIX_SETUID)
#        define JSE_UNIX_SETUID                  1
#     endif
#     if !defined(JSE_UNIX_WAIT)
#        define JSE_UNIX_WAIT                    1
#     endif
#     if !defined(JSE_UNIX_WAITPID)
#        define JSE_UNIX_WAITPID                 1
#     endif
#  endif /* JSE_UNIX_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_UNIX_FORK) && (0==JSE_UNIX_FORK)
#     undef JSE_UNIX_FORK
#  endif
#  if defined(JSE_UNIX_KILL) && (0==JSE_UNIX_KILL)
#     undef JSE_UNIX_KILL
#  endif
#  if defined(JSE_UNIX_SETGID) && (0==JSE_UNIX_SETGID)
#     undef JSE_UNIX_SETGID
#  endif
#  if defined(JSE_UNIX_SETSID) && (0==JSE_UNIX_SETSID)
#     undef JSE_UNIX_SETSID
#  endif
#  if defined(JSE_UNIX_SETUID) && (0==JSE_UNIX_SETUID)
#     undef JSE_UNIX_SETUID
#  endif
#  if defined(JSE_UNIX_WAIT) && (0==JSE_UNIX_WAIT)
#     undef JSE_UNIX_WAIT
#  endif
#  if defined(JSE_UNIX_WAITPID) && (0==JSE_UNIX_WAITPID)
#     undef JSE_UNIX_WAITPID
#  endif
   /* Define generic JSE_UNIX_ANY */
#  if defined(JSE_UNIX_FORK) \
   || defined(JSE_UNIX_KILL) \
   || defined(JSE_UNIX_SETGID) \
   || defined(JSE_UNIX_SETSID) \
   || defined(JSE_UNIX_SETUID) \
   || defined(JSE_UNIX_WAIT) \
   || defined(JSE_UNIX_WAITPID)
#     define JSE_UNIX_ANY
#  endif

/*****************
 * DOS           *
 *****************/

   /* Check for JSE_DOS_ALL */
#  if defined(JSE_DOS_ALL)
#     if !defined(JSE_DOS_ADDRESS)
#        define JSE_DOS_ADDRESS                  1
#     endif
#     if !defined(JSE_DOS_ASM)
#        define JSE_DOS_ASM                      1
#     endif
#     if !defined(JSE_DOS_INPORT)
#        define JSE_DOS_INPORT                   1
#     endif
#     if !defined(JSE_DOS_INPORTW)
#        define JSE_DOS_INPORTW                  1
#     endif
#     if !defined(JSE_DOS_INTERRUPT)
#        define JSE_DOS_INTERRUPT                1
#     endif
#     if !defined(JSE_DOS_OFFSET)
#        define JSE_DOS_OFFSET                   1
#     endif
#     if !defined(JSE_DOS_OUTPORT)
#        define JSE_DOS_OUTPORT                  1
#     endif
#     if !defined(JSE_DOS_OUTPORTW)
#        define JSE_DOS_OUTPORTW                 1
#     endif
#     if !defined(JSE_DOS_SEGMENT)
#        define JSE_DOS_SEGMENT                  1
#     endif
#  endif /* JSE_DOS_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_DOS_ADDRESS) && (0==JSE_DOS_ADDRESS)
#     undef JSE_DOS_ADDRESS
#  endif
#  if defined(JSE_DOS_ASM) && (0==JSE_DOS_ASM)
#     undef JSE_DOS_ASM
#  endif
#  if defined(JSE_DOS_INPORT) && (0==JSE_DOS_INPORT)
#     undef JSE_DOS_INPORT
#  endif
#  if defined(JSE_DOS_INPORTW) && (0==JSE_DOS_INPORTW)
#     undef JSE_DOS_INPORTW
#  endif
#  if defined(JSE_DOS_INTERRUPT) && (0==JSE_DOS_INTERRUPT)
#     undef JSE_DOS_INTERRUPT
#  endif
#  if defined(JSE_DOS_OFFSET) && (0==JSE_DOS_OFFSET)
#     undef JSE_DOS_OFFSET
#  endif
#  if defined(JSE_DOS_OUTPORT) && (0==JSE_DOS_OUTPORT)
#     undef JSE_DOS_OUTPORT
#  endif
#  if defined(JSE_DOS_OUTPORTW) && (0==JSE_DOS_OUTPORTW)
#     undef JSE_DOS_OUTPORTW
#  endif
#  if defined(JSE_DOS_SEGMENT) && (0==JSE_DOS_SEGMENT)
#     undef JSE_DOS_SEGMENT
#  endif
   /* Define generic JSE_DOS_ANY */
#  if defined(JSE_DOS_ADDRESS) \
   || defined(JSE_DOS_ASM) \
   || defined(JSE_DOS_INPORT) \
   || defined(JSE_DOS_INPORTW) \
   || defined(JSE_DOS_INTERRUPT) \
   || defined(JSE_DOS_OFFSET) \
   || defined(JSE_DOS_OUTPORT) \
   || defined(JSE_DOS_OUTPORTW) \
   || defined(JSE_DOS_SEGMENT)
#     define JSE_DOS_ANY
#  endif

/*****************
 * WIN           *
 *****************/

   /* Check for JSE_WIN_ALL */
#  if defined(JSE_WIN_ALL)
#     if !defined(JSE_WIN_ASM)
#        define JSE_WIN_ASM                      1
#     endif
#     if !defined(JSE_WIN_BASEWINDOWFUNCTION) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_BASEWINDOWFUNCTION       1
#     endif
#     if !defined(JSE_WIN_BREAKWINDOW) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_BREAKWINDOW              1
#     endif
#     if !defined(JSE_WIN_DOWINDOWS) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_DOWINDOWS                1
#     endif
#     if !defined(JSE_WIN_INSTANCE) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_INSTANCE                 1
#     endif
#     if !defined(JSE_WIN_MAKEWINDOW) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_MAKEWINDOW               1
#     endif
#     if !defined(JSE_WIN_MESSAGEFILTER) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_MESSAGEFILTER            1
#     endif
#     if !defined(JSE_WIN_MULTITASK) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_MULTITASK                1
#     endif
#     if !defined(JSE_WIN_SUBCLASSWINDOW) \
         && !defined(__JSE_CON32__) && defined(JSE_WINDOW)
#        define JSE_WIN_SUBCLASSWINDOW           1
#     endif
#     if !defined(JSE_WIN_WINDOWLIST)
#        define JSE_WIN_WINDOWLIST               1
#     endif
#  endif /* JSE_WIN_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_WIN_ASM) && (0==JSE_WIN_ASM)
#     undef JSE_WIN_ASM
#  endif
#  if defined(JSE_WIN_BASEWINDOWFUNCTION) && (0==JSE_WIN_BASEWINDOWFUNCTION)
#     undef JSE_WIN_BASEWINDOWFUNCTION
#  endif
#  if defined(JSE_WIN_BREAKWINDOW) && (0==JSE_WIN_BREAKWINDOW)
#     undef JSE_WIN_BREAKWINDOW
#  endif
#  if defined(JSE_WIN_DOWINDOWS) && (0==JSE_WIN_DOWINDOWS)
#     undef JSE_WIN_DOWINDOWS
#  endif
#  if defined(JSE_WIN_INSTANCE) && (0==JSE_WIN_INSTANCE)
#     undef JSE_WIN_INSTANCE
#  endif
#  if defined(JSE_WIN_MAKEWINDOW) && (0==JSE_WIN_MAKEWINDOW)
#     undef JSE_WIN_MAKEWINDOW
#  endif
#  if defined(JSE_WIN_MESSAGEFILTER) && (0==JSE_WIN_MESSAGEFILTER)
#     undef JSE_WIN_MESSAGEFILTER
#  endif
#  if defined(JSE_WIN_MULTITASK) && (0==JSE_WIN_MULTITASK)
#     undef JSE_WIN_MULTITASK
#  endif
#  if defined(JSE_WIN_SUBCLASSWINDOW) && (0==JSE_WIN_SUBCLASSWINDOW)
#     undef JSE_WIN_SUBCLASSWINDOW
#  endif
#  if defined(JSE_WIN_WINDOWLIST) && (0==JSE_WIN_WINDOWLIST)
#     undef JSE_WIN_WINDOWLIST
#  endif
   /* Define generic JSE_WIN_ANY */
#  if defined(JSE_WIN_ASM) \
   || defined(JSE_WIN_BASEWINDOWFUNCTION) \
   || defined(JSE_WIN_BREAKWINDOW) \
   || defined(JSE_WIN_DOWINDOWS) \
   || defined(JSE_WIN_INSTANCE) \
   || defined(JSE_WIN_MAKEWINDOW) \
   || defined(JSE_WIN_MESSAGEFILTER) \
   || defined(JSE_WIN_MULTITASK) \
   || defined(JSE_WIN_SUBCLASSWINDOW) \
   || defined(JSE_WIN_WINDOWLIST)
#     define JSE_WIN_ANY
#  endif

/*****************
 * OS2           *
 *****************/

   /* Check for JSE_OS2_ALL */
#  if defined(JSE_OS2_ALL)
#     if !defined(JSE_OS2_ASM)
#        define JSE_OS2_ASM                      1
#     endif
#     if !defined(JSE_OS2_BEGINTHREAD) \
         && 0
#        define JSE_OS2_BEGINTHREAD              1
#     endif
#     if !defined(JSE_OS2_ENDTHREAD) \
         && 0
#        define JSE_OS2_ENDTHREAD                1
#     endif
#     if !defined(JSE_OS2_ESET)
#        define JSE_OS2_ESET                     1
#     endif
#     if !defined(JSE_OS2_INFO)
#        define JSE_OS2_INFO                     1
#     endif
#     if !defined(JSE_OS2_INPORT)
#        define JSE_OS2_INPORT                   1
#     endif
#     if !defined(JSE_OS2_INPORTW)
#        define JSE_OS2_INPORTW                  1
#     endif
#     if !defined(JSE_OS2_OUTPORT)
#        define JSE_OS2_OUTPORT                  1
#     endif
#     if !defined(JSE_OS2_OUTPORTW)
#        define JSE_OS2_OUTPORTW                 1
#     endif
#     if !defined(JSE_OS2_PMDYNAMICLINK)
#        define JSE_OS2_PMDYNAMICLINK            1
#     endif
#     if !defined(JSE_OS2_PMINFO)
#        define JSE_OS2_PMINFO                   1
#     endif
#     if !defined(JSE_OS2_PMPEEK)
#        define JSE_OS2_PMPEEK                   1
#     endif
#     if !defined(JSE_OS2_PMPOKE)
#        define JSE_OS2_PMPOKE                   1
#     endif
#     if !defined(JSE_OS2_PROCESSLIST)
#        define JSE_OS2_PROCESSLIST              1
#     endif
#     if !defined(JSE_OS2_SOMMETHOD)
#        define JSE_OS2_SOMMETHOD                1
#     endif
#  endif /* JSE_OS2_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_OS2_ASM) && (0==JSE_OS2_ASM)
#     undef JSE_OS2_ASM
#  endif
#  if defined(JSE_OS2_BEGINTHREAD) && (0==JSE_OS2_BEGINTHREAD)
#     undef JSE_OS2_BEGINTHREAD
#  endif
#  if defined(JSE_OS2_ENDTHREAD) && (0==JSE_OS2_ENDTHREAD)
#     undef JSE_OS2_ENDTHREAD
#  endif
#  if defined(JSE_OS2_ESET) && (0==JSE_OS2_ESET)
#     undef JSE_OS2_ESET
#  endif
#  if defined(JSE_OS2_INFO) && (0==JSE_OS2_INFO)
#     undef JSE_OS2_INFO
#  endif
#  if defined(JSE_OS2_INPORT) && (0==JSE_OS2_INPORT)
#     undef JSE_OS2_INPORT
#  endif
#  if defined(JSE_OS2_INPORTW) && (0==JSE_OS2_INPORTW)
#     undef JSE_OS2_INPORTW
#  endif
#  if defined(JSE_OS2_OUTPORT) && (0==JSE_OS2_OUTPORT)
#     undef JSE_OS2_OUTPORT
#  endif
#  if defined(JSE_OS2_OUTPORTW) && (0==JSE_OS2_OUTPORTW)
#     undef JSE_OS2_OUTPORTW
#  endif
#  if defined(JSE_OS2_PMDYNAMICLINK) && (0==JSE_OS2_PMDYNAMICLINK)
#     undef JSE_OS2_PMDYNAMICLINK
#  endif
#  if defined(JSE_OS2_PMINFO) && (0==JSE_OS2_PMINFO)
#     undef JSE_OS2_PMINFO
#  endif
#  if defined(JSE_OS2_PMPEEK) && (0==JSE_OS2_PMPEEK)
#     undef JSE_OS2_PMPEEK
#  endif
#  if defined(JSE_OS2_PMPOKE) && (0==JSE_OS2_PMPOKE)
#     undef JSE_OS2_PMPOKE
#  endif
#  if defined(JSE_OS2_PROCESSLIST) && (0==JSE_OS2_PROCESSLIST)
#     undef JSE_OS2_PROCESSLIST
#  endif
#  if defined(JSE_OS2_SOMMETHOD) && (0==JSE_OS2_SOMMETHOD)
#     undef JSE_OS2_SOMMETHOD
#  endif
   /* Define generic JSE_OS2_ANY */
#  if defined(JSE_OS2_ASM) \
   || defined(JSE_OS2_BEGINTHREAD) \
   || defined(JSE_OS2_ENDTHREAD) \
   || defined(JSE_OS2_ESET) \
   || defined(JSE_OS2_INFO) \
   || defined(JSE_OS2_INPORT) \
   || defined(JSE_OS2_INPORTW) \
   || defined(JSE_OS2_OUTPORT) \
   || defined(JSE_OS2_OUTPORTW) \
   || defined(JSE_OS2_PMDYNAMICLINK) \
   || defined(JSE_OS2_PMINFO) \
   || defined(JSE_OS2_PMPEEK) \
   || defined(JSE_OS2_PMPOKE) \
   || defined(JSE_OS2_PROCESSLIST) \
   || defined(JSE_OS2_SOMMETHOD)
#     define JSE_OS2_ANY
#  endif

/*****************
 * MAC           *
 *****************/

   /* Check for JSE_MAC_ALL */
#  if defined(JSE_MAC_ALL)
#     if !defined(JSE_MAC_MULTITHREAD) \
         && defined(USE_MAC_THREADS)
#        define JSE_MAC_MULTITHREAD              1
#     endif
#     if !defined(JSE_MAC_RUNAPPLESCRIPT)
#        define JSE_MAC_RUNAPPLESCRIPT           1
#     endif
#     if !defined(JSE_MAC_PLAYSOUND)
#        define JSE_MAC_PLAYSOUND                1
#     endif
#     if !defined(JSE_MAC_SENDAE)
#        define JSE_MAC_SENDAE                   1
#     endif
#  endif /* JSE_MAC_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_MAC_MULTITHREAD) && (0==JSE_MAC_MULTITHREAD)
#     undef JSE_MAC_MULTITHREAD
#  endif
#  if defined(JSE_MAC_RUNAPPLESCRIPT) && (0==JSE_MAC_RUNAPPLESCRIPT)
#     undef JSE_MAC_RUNAPPLESCRIPT
#  endif
#  if defined(JSE_MAC_PLAYSOUND) && (0==JSE_MAC_PLAYSOUND)
#     undef JSE_MAC_PLAYSOUND
#  endif
#  if defined(JSE_MAC_SENDAE) && (0==JSE_MAC_SENDAE)
#     undef JSE_MAC_SENDAE
#  endif
   /* Define generic JSE_MAC_ANY */
#  if defined(JSE_MAC_MULTITHREAD) \
   || defined(JSE_MAC_RUNAPPLESCRIPT) \
   || defined(JSE_MAC_PLAYSOUND) \
   || defined(JSE_MAC_SENDAE)
#     define JSE_MAC_ANY
#  endif

/*****************
 * CLIB          *
 *****************/

   /* Check for JSE_CLIB_ALL */
#  if defined(JSE_CLIB_ALL)
#     if !defined(JSE_CLIB_ABORT)
#        define JSE_CLIB_ABORT                   1
#     endif
#     if !defined(JSE_CLIB_ABS)
#        define JSE_CLIB_ABS                     1
#     endif
#     if !defined(JSE_CLIB_ACOS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_ACOS                    1
#     endif
#     if !defined(JSE_CLIB_ASCTIME)
#        define JSE_CLIB_ASCTIME                 1
#     endif
#     if !defined(JSE_CLIB_ASIN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_ASIN                    1
#     endif
#     if !defined(JSE_CLIB_ASSERT)
#        define JSE_CLIB_ASSERT                  1
#     endif
#     if !defined(JSE_CLIB_ATAN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_ATAN                    1
#     endif
#     if !defined(JSE_CLIB_ATAN2) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_ATAN2                   1
#     endif
#     if !defined(JSE_CLIB_ATEXIT)
#        define JSE_CLIB_ATEXIT                  1
#     endif
#     if !defined(JSE_CLIB_ATOI)
#        define JSE_CLIB_ATOI                    1
#     endif
#     if !defined(JSE_CLIB_ATOF) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_ATOF                    1
#     endif
#     if !defined(JSE_CLIB_ATOL)
#        define JSE_CLIB_ATOL                    1
#     endif
#     if !defined(JSE_CLIB_BSEARCH)
#        define JSE_CLIB_BSEARCH                 1
#     endif
#     if !defined(JSE_CLIB_CEIL) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_CEIL                    1
#     endif
#     if !defined(JSE_CLIB_CHDIR)
#        define JSE_CLIB_CHDIR                   1
#     endif
#     if !defined(JSE_CLIB_CLEARERR)
#        define JSE_CLIB_CLEARERR                1
#     endif
#     if !defined(JSE_CLIB_CLOCK)
#        define JSE_CLIB_CLOCK                   1
#     endif
#     if !defined(JSE_CLIB_CTIME)
#        define JSE_CLIB_CTIME                   1
#     endif
#     if !defined(JSE_CLIB_COS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_COS                     1
#     endif
#     if !defined(JSE_CLIB_COSH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_COSH                    1
#     endif
#     if !defined(JSE_CLIB_DIFFTIME) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_DIFFTIME                1
#     endif
#     if !defined(JSE_CLIB_DIV)
#        define JSE_CLIB_DIV                     1
#     endif
#     if !defined(JSE_CLIB_ERRNO)
#        define JSE_CLIB_ERRNO                   1
#     endif
#     if !defined(JSE_CLIB_EXIT)
#        define JSE_CLIB_EXIT                    1
#     endif
#     if !defined(JSE_CLIB_EXP) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_EXP                     1
#     endif
#     if !defined(JSE_CLIB_FABS) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_FABS                    1
#     endif
#     if !defined(JSE_CLIB_FCLOSE)
#        define JSE_CLIB_FCLOSE                  1
#     endif
#     if !defined(JSE_CLIB_FEOF)
#        define JSE_CLIB_FEOF                    1
#     endif
#     if !defined(JSE_CLIB_FERROR)
#        define JSE_CLIB_FERROR                  1
#     endif
#     if !defined(JSE_CLIB_FFLUSH)
#        define JSE_CLIB_FFLUSH                  1
#     endif
#     if !defined(JSE_CLIB_FGETC)
#        define JSE_CLIB_FGETC                   1
#     endif
#     if !defined(JSE_CLIB_FGETPOS)
#        define JSE_CLIB_FGETPOS                 1
#     endif
#     if !defined(JSE_CLIB_FGETS)
#        define JSE_CLIB_FGETS                   1
#     endif
#     if !defined(JSE_CLIB_FLOCK)
#        define JSE_CLIB_FLOCK                   1
#     endif
#     if !defined(JSE_CLIB_FLOOR) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_FLOOR                   1
#     endif
#     if !defined(JSE_CLIB_FMOD) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_FMOD                    1
#     endif
#     if !defined(JSE_CLIB_FOPEN)
#        define JSE_CLIB_FOPEN                   1
#     endif
#     if !defined(JSE_CLIB_FPUTC)
#        define JSE_CLIB_FPUTC                   1
#     endif
#     if !defined(JSE_CLIB_FPRINTF)
#        define JSE_CLIB_FPRINTF                 1
#     endif
#     if !defined(JSE_CLIB_FPUTS)
#        define JSE_CLIB_FPUTS                   1
#     endif
#     if !defined(JSE_CLIB_FREAD)
#        define JSE_CLIB_FREAD                   1
#     endif
#     if !defined(JSE_CLIB_FREXP) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_FREXP                   1
#     endif
#     if !defined(JSE_CLIB_FREOPEN)
#        define JSE_CLIB_FREOPEN                 1
#     endif
#     if !defined(JSE_CLIB_FSCANF)
#        define JSE_CLIB_FSCANF                  1
#     endif
#     if !defined(JSE_CLIB_FSEEK)
#        define JSE_CLIB_FSEEK                   1
#     endif
#     if !defined(JSE_CLIB_FSETPOS)
#        define JSE_CLIB_FSETPOS                 1
#     endif
#     if !defined(JSE_CLIB_FTELL)
#        define JSE_CLIB_FTELL                   1
#     endif
#     if !defined(JSE_CLIB_FWRITE)
#        define JSE_CLIB_FWRITE                  1
#     endif
#     if !defined(JSE_CLIB_GETC)
#        define JSE_CLIB_GETC                    1
#     endif
#     if !defined(JSE_CLIB_GETCH)
#        define JSE_CLIB_GETCH                   1
#     endif
#     if !defined(JSE_CLIB_GETCHAR)
#        define JSE_CLIB_GETCHAR                 1
#     endif
#     if !defined(JSE_CLIB_GETCHE)
#        define JSE_CLIB_GETCHE                  1
#     endif
#     if !defined(JSE_CLIB_GETCWD)
#        define JSE_CLIB_GETCWD                  1
#     endif
#     if !defined(JSE_CLIB_GETENV)
#        define JSE_CLIB_GETENV                  1
#     endif
#     if !defined(JSE_CLIB_GETS)
#        define JSE_CLIB_GETS                    1
#     endif
#     if !defined(JSE_CLIB_GMTIME)
#        define JSE_CLIB_GMTIME                  1
#     endif
#     if !defined(JSE_CLIB_ISALNUM)
#        define JSE_CLIB_ISALNUM                 1
#     endif
#     if !defined(JSE_CLIB_ISALPHA)
#        define JSE_CLIB_ISALPHA                 1
#     endif
#     if !defined(JSE_CLIB_ISASCII)
#        define JSE_CLIB_ISASCII                 1
#     endif
#     if !defined(JSE_CLIB_ISCNTRL)
#        define JSE_CLIB_ISCNTRL                 1
#     endif
#     if !defined(JSE_CLIB_ISDIGIT)
#        define JSE_CLIB_ISDIGIT                 1
#     endif
#     if !defined(JSE_CLIB_ISGRAPH)
#        define JSE_CLIB_ISGRAPH                 1
#     endif
#     if !defined(JSE_CLIB_ISLOWER)
#        define JSE_CLIB_ISLOWER                 1
#     endif
#     if !defined(JSE_CLIB_ISPRINT)
#        define JSE_CLIB_ISPRINT                 1
#     endif
#     if !defined(JSE_CLIB_ISPUNCT)
#        define JSE_CLIB_ISPUNCT                 1
#     endif
#     if !defined(JSE_CLIB_ISSPACE)
#        define JSE_CLIB_ISSPACE                 1
#     endif
#     if !defined(JSE_CLIB_ISUPPER)
#        define JSE_CLIB_ISUPPER                 1
#     endif
#     if !defined(JSE_CLIB_ISXDIGIT)
#        define JSE_CLIB_ISXDIGIT                1
#     endif
#     if !defined(JSE_CLIB_KBHIT)
#        define JSE_CLIB_KBHIT                   1
#     endif
#     if !defined(JSE_CLIB_LABS)
#        define JSE_CLIB_LABS                    1
#     endif
#     if !defined(JSE_CLIB_LDEXP) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_LDEXP                   1
#     endif
#     if !defined(JSE_CLIB_LDIV)
#        define JSE_CLIB_LDIV                    1
#     endif
#     if !defined(JSE_CLIB_LOCALTIME)
#        define JSE_CLIB_LOCALTIME               1
#     endif
#     if !defined(JSE_CLIB_LOG) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_LOG                     1
#     endif
#     if !defined(JSE_CLIB_LOG10) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_LOG10                   1
#     endif
#     if !defined(JSE_CLIB_MAX)
#        define JSE_CLIB_MAX                     1
#     endif
#     if !defined(JSE_CLIB_MIN)
#        define JSE_CLIB_MIN                     1
#     endif
#     if !defined(JSE_CLIB_MKDIR)
#        define JSE_CLIB_MKDIR                   1
#     endif
#     if !defined(JSE_CLIB_MEMCHR)
#        define JSE_CLIB_MEMCHR                  1
#     endif
#     if !defined(JSE_CLIB_MEMCMP)
#        define JSE_CLIB_MEMCMP                  1
#     endif
#     if !defined(JSE_CLIB_MEMCPY)
#        define JSE_CLIB_MEMCPY                  1
#     endif
#     if !defined(JSE_CLIB_MEMMOVE)
#        define JSE_CLIB_MEMMOVE                 1
#     endif
#     if !defined(JSE_CLIB_MEMSET)
#        define JSE_CLIB_MEMSET                  1
#     endif
#     if !defined(JSE_CLIB_MKTIME)
#        define JSE_CLIB_MKTIME                  1
#     endif
#     if !defined(JSE_CLIB_MODF) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_MODF                    1
#     endif
#     if !defined(JSE_CLIB_PERROR)
#        define JSE_CLIB_PERROR                  1
#     endif
#     if !defined(JSE_CLIB_POW) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_POW                     1
#     endif
#     if !defined(JSE_CLIB_PRINTF)
#        define JSE_CLIB_PRINTF                  1
#     endif
#     if !defined(JSE_CLIB_PUTC)
#        define JSE_CLIB_PUTC                    1
#     endif
#     if !defined(JSE_CLIB_PUTCHAR)
#        define JSE_CLIB_PUTCHAR                 1
#     endif
#     if !defined(JSE_CLIB_PUTENV)
#        define JSE_CLIB_PUTENV                  1
#     endif
#     if !defined(JSE_CLIB_PUTS)
#        define JSE_CLIB_PUTS                    1
#     endif
#     if !defined(JSE_CLIB_QSORT)
#        define JSE_CLIB_QSORT                   1
#     endif
#     if !defined(JSE_CLIB_RAND)
#        define JSE_CLIB_RAND                    1
#     endif
#     if !defined(JSE_CLIB_REMOVE)
#        define JSE_CLIB_REMOVE                  1
#     endif
#     if !defined(JSE_CLIB_RENAME)
#        define JSE_CLIB_RENAME                  1
#     endif
#     if !defined(JSE_CLIB_REWIND)
#        define JSE_CLIB_REWIND                  1
#     endif
#     if !defined(JSE_CLIB_RMDIR)
#        define JSE_CLIB_RMDIR                   1
#     endif
#     if !defined(JSE_CLIB_RSPRINTF)
#        define JSE_CLIB_RSPRINTF                1
#     endif
#     if !defined(JSE_CLIB_RVSPRINTF)
#        define JSE_CLIB_RVSPRINTF               1
#     endif
#     if !defined(JSE_CLIB_SCANF)
#        define JSE_CLIB_SCANF                   1
#     endif
#     if !defined(JSE_CLIB_SIN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_SIN                     1
#     endif
#     if !defined(JSE_CLIB_SINH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_SINH                    1
#     endif
#     if !defined(JSE_CLIB_SPRINTF)
#        define JSE_CLIB_SPRINTF                 1
#     endif
#     if !defined(JSE_CLIB_SQRT) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_SQRT                    1
#     endif
#     if !defined(JSE_CLIB_SRAND)
#        define JSE_CLIB_SRAND                   1
#     endif
#     if !defined(JSE_CLIB_SSCANF)
#        define JSE_CLIB_SSCANF                  1
#     endif
#     if !defined(JSE_CLIB_STRCAT)
#        define JSE_CLIB_STRCAT                  1
#     endif
#     if !defined(JSE_CLIB_STRCHR)
#        define JSE_CLIB_STRCHR                  1
#     endif
#     if !defined(JSE_CLIB_STRCMP)
#        define JSE_CLIB_STRCMP                  1
#     endif
#     if !defined(JSE_CLIB_STRCPY)
#        define JSE_CLIB_STRCPY                  1
#     endif
#     if !defined(JSE_CLIB_STRCSPN)
#        define JSE_CLIB_STRCSPN                 1
#     endif
#     if !defined(JSE_CLIB_STRERROR)
#        define JSE_CLIB_STRERROR                1
#     endif
#     if !defined(JSE_CLIB_STRFTIME)
#        define JSE_CLIB_STRFTIME                1
#     endif
#     if !defined(JSE_CLIB_STRICMP)
#        define JSE_CLIB_STRICMP                 1
#     endif
#     if !defined(JSE_CLIB_STRLEN)
#        define JSE_CLIB_STRLEN                  1
#     endif
#     if !defined(JSE_CLIB_STRLWR)
#        define JSE_CLIB_STRLWR                  1
#     endif
#     if !defined(JSE_CLIB_STRNCAT)
#        define JSE_CLIB_STRNCAT                 1
#     endif
#     if !defined(JSE_CLIB_STRNCMP)
#        define JSE_CLIB_STRNCMP                 1
#     endif
#     if !defined(JSE_CLIB_STRNICMP)
#        define JSE_CLIB_STRNICMP                1
#     endif
#     if !defined(JSE_CLIB_STRNCPY)
#        define JSE_CLIB_STRNCPY                 1
#     endif
#     if !defined(JSE_CLIB_STRPBRK)
#        define JSE_CLIB_STRPBRK                 1
#     endif
#     if !defined(JSE_CLIB_STRRCHR)
#        define JSE_CLIB_STRRCHR                 1
#     endif
#     if !defined(JSE_CLIB_STRSPN)
#        define JSE_CLIB_STRSPN                  1
#     endif
#     if !defined(JSE_CLIB_STRSTR)
#        define JSE_CLIB_STRSTR                  1
#     endif
#     if !defined(JSE_CLIB_STRSTRI)
#        define JSE_CLIB_STRSTRI                 1
#     endif
#     if !defined(JSE_CLIB_STRTOD) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_STRTOD                  1
#     endif
#     if !defined(JSE_CLIB_STRTOK)
#        define JSE_CLIB_STRTOK                  1
#     endif
#     if !defined(JSE_CLIB_STRTOL)
#        define JSE_CLIB_STRTOL                  1
#     endif
#     if !defined(JSE_CLIB_STRUPR)
#        define JSE_CLIB_STRUPR                  1
#     endif
#     if !defined(JSE_CLIB_SUSPEND)
#        define JSE_CLIB_SUSPEND                 1
#     endif
#     if !defined(JSE_CLIB_SYSTEM)
#        define JSE_CLIB_SYSTEM                  1
#     endif
#     if !defined(JSE_CLIB_TAN) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_TAN                     1
#     endif
#     if !defined(JSE_CLIB_TANH) \
         && (0!=JSE_FLOATING_POINT)
#        define JSE_CLIB_TANH                    1
#     endif
#     if !defined(JSE_CLIB_TIME)
#        define JSE_CLIB_TIME                    1
#     endif
#     if !defined(JSE_CLIB_TMPFILE)
#        define JSE_CLIB_TMPFILE                 1
#     endif
#     if !defined(JSE_CLIB_TMPNAM)
#        define JSE_CLIB_TMPNAM                  1
#     endif
#     if !defined(JSE_CLIB_TOASCII)
#        define JSE_CLIB_TOASCII                 1
#     endif
#     if !defined(JSE_CLIB_TOLOWER)
#        define JSE_CLIB_TOLOWER                 1
#     endif
#     if !defined(JSE_CLIB_TOUPPER)
#        define JSE_CLIB_TOUPPER                 1
#     endif
#     if !defined(JSE_CLIB_UNGETC)
#        define JSE_CLIB_UNGETC                  1
#     endif
#     if !defined(JSE_CLIB_VA_ARG)
#        define JSE_CLIB_VA_ARG                  1
#     endif
#     if !defined(JSE_CLIB_VA_END)
#        define JSE_CLIB_VA_END                  1
#     endif
#     if !defined(JSE_CLIB_VA_START)
#        define JSE_CLIB_VA_START                1
#     endif
#     if !defined(JSE_CLIB_VFSCANF)
#        define JSE_CLIB_VFSCANF                 1
#     endif
#     if !defined(JSE_CLIB_VFPRINTF)
#        define JSE_CLIB_VFPRINTF                1
#     endif
#     if !defined(JSE_CLIB_VPRINTF)
#        define JSE_CLIB_VPRINTF                 1
#     endif
#     if !defined(JSE_CLIB_VSCANF)
#        define JSE_CLIB_VSCANF                  1
#     endif
#     if !defined(JSE_CLIB_VSPRINTF)
#        define JSE_CLIB_VSPRINTF                1
#     endif
#     if !defined(JSE_CLIB_VSSCANF)
#        define JSE_CLIB_VSSCANF                 1
#     endif
#  endif /* JSE_CLIB_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_CLIB_ABORT) && (0==JSE_CLIB_ABORT)
#     undef JSE_CLIB_ABORT
#  endif
#  if defined(JSE_CLIB_ABS) && (0==JSE_CLIB_ABS)
#     undef JSE_CLIB_ABS
#  endif
#  if defined(JSE_CLIB_ACOS) && (0==JSE_CLIB_ACOS)
#     undef JSE_CLIB_ACOS
#  endif
#  if defined(JSE_CLIB_ASCTIME) && (0==JSE_CLIB_ASCTIME)
#     undef JSE_CLIB_ASCTIME
#  endif
#  if defined(JSE_CLIB_ASIN) && (0==JSE_CLIB_ASIN)
#     undef JSE_CLIB_ASIN
#  endif
#  if defined(JSE_CLIB_ASSERT) && (0==JSE_CLIB_ASSERT)
#     undef JSE_CLIB_ASSERT
#  endif
#  if defined(JSE_CLIB_ATAN) && (0==JSE_CLIB_ATAN)
#     undef JSE_CLIB_ATAN
#  endif
#  if defined(JSE_CLIB_ATAN2) && (0==JSE_CLIB_ATAN2)
#     undef JSE_CLIB_ATAN2
#  endif
#  if defined(JSE_CLIB_ATEXIT) && (0==JSE_CLIB_ATEXIT)
#     undef JSE_CLIB_ATEXIT
#  endif
#  if defined(JSE_CLIB_ATOI) && (0==JSE_CLIB_ATOI)
#     undef JSE_CLIB_ATOI
#  endif
#  if defined(JSE_CLIB_ATOF) && (0==JSE_CLIB_ATOF)
#     undef JSE_CLIB_ATOF
#  endif
#  if defined(JSE_CLIB_ATOL) && (0==JSE_CLIB_ATOL)
#     undef JSE_CLIB_ATOL
#  endif
#  if defined(JSE_CLIB_BSEARCH) && (0==JSE_CLIB_BSEARCH)
#     undef JSE_CLIB_BSEARCH
#  endif
#  if defined(JSE_CLIB_CEIL) && (0==JSE_CLIB_CEIL)
#     undef JSE_CLIB_CEIL
#  endif
#  if defined(JSE_CLIB_CHDIR) && (0==JSE_CLIB_CHDIR)
#     undef JSE_CLIB_CHDIR
#  endif
#  if defined(JSE_CLIB_CLEARERR) && (0==JSE_CLIB_CLEARERR)
#     undef JSE_CLIB_CLEARERR
#  endif
#  if defined(JSE_CLIB_CLOCK) && (0==JSE_CLIB_CLOCK)
#     undef JSE_CLIB_CLOCK
#  endif
#  if defined(JSE_CLIB_CTIME) && (0==JSE_CLIB_CTIME)
#     undef JSE_CLIB_CTIME
#  endif
#  if defined(JSE_CLIB_COS) && (0==JSE_CLIB_COS)
#     undef JSE_CLIB_COS
#  endif
#  if defined(JSE_CLIB_COSH) && (0==JSE_CLIB_COSH)
#     undef JSE_CLIB_COSH
#  endif
#  if defined(JSE_CLIB_DIFFTIME) && (0==JSE_CLIB_DIFFTIME)
#     undef JSE_CLIB_DIFFTIME
#  endif
#  if defined(JSE_CLIB_DIV) && (0==JSE_CLIB_DIV)
#     undef JSE_CLIB_DIV
#  endif
#  if defined(JSE_CLIB_ERRNO) && (0==JSE_CLIB_ERRNO)
#     undef JSE_CLIB_ERRNO
#  endif
#  if defined(JSE_CLIB_EXIT) && (0==JSE_CLIB_EXIT)
#     undef JSE_CLIB_EXIT
#  endif
#  if defined(JSE_CLIB_EXP) && (0==JSE_CLIB_EXP)
#     undef JSE_CLIB_EXP
#  endif
#  if defined(JSE_CLIB_FABS) && (0==JSE_CLIB_FABS)
#     undef JSE_CLIB_FABS
#  endif
#  if defined(JSE_CLIB_FCLOSE) && (0==JSE_CLIB_FCLOSE)
#     undef JSE_CLIB_FCLOSE
#  endif
#  if defined(JSE_CLIB_FEOF) && (0==JSE_CLIB_FEOF)
#     undef JSE_CLIB_FEOF
#  endif
#  if defined(JSE_CLIB_FERROR) && (0==JSE_CLIB_FERROR)
#     undef JSE_CLIB_FERROR
#  endif
#  if defined(JSE_CLIB_FFLUSH) && (0==JSE_CLIB_FFLUSH)
#     undef JSE_CLIB_FFLUSH
#  endif
#  if defined(JSE_CLIB_FGETC) && (0==JSE_CLIB_FGETC)
#     undef JSE_CLIB_FGETC
#  endif
#  if defined(JSE_CLIB_FGETPOS) && (0==JSE_CLIB_FGETPOS)
#     undef JSE_CLIB_FGETPOS
#  endif
#  if defined(JSE_CLIB_FGETS) && (0==JSE_CLIB_FGETS)
#     undef JSE_CLIB_FGETS
#  endif
#  if defined(JSE_CLIB_FLOCK) && (0==JSE_CLIB_FLOCK)
#     undef JSE_CLIB_FLOCK
#  endif
#  if defined(JSE_CLIB_FLOOR) && (0==JSE_CLIB_FLOOR)
#     undef JSE_CLIB_FLOOR
#  endif
#  if defined(JSE_CLIB_FMOD) && (0==JSE_CLIB_FMOD)
#     undef JSE_CLIB_FMOD
#  endif
#  if defined(JSE_CLIB_FOPEN) && (0==JSE_CLIB_FOPEN)
#     undef JSE_CLIB_FOPEN
#  endif
#  if defined(JSE_CLIB_FPUTC) && (0==JSE_CLIB_FPUTC)
#     undef JSE_CLIB_FPUTC
#  endif
#  if defined(JSE_CLIB_FPRINTF) && (0==JSE_CLIB_FPRINTF)
#     undef JSE_CLIB_FPRINTF
#  endif
#  if defined(JSE_CLIB_FPUTS) && (0==JSE_CLIB_FPUTS)
#     undef JSE_CLIB_FPUTS
#  endif
#  if defined(JSE_CLIB_FREAD) && (0==JSE_CLIB_FREAD)
#     undef JSE_CLIB_FREAD
#  endif
#  if defined(JSE_CLIB_FREXP) && (0==JSE_CLIB_FREXP)
#     undef JSE_CLIB_FREXP
#  endif
#  if defined(JSE_CLIB_FREOPEN) && (0==JSE_CLIB_FREOPEN)
#     undef JSE_CLIB_FREOPEN
#  endif
#  if defined(JSE_CLIB_FSCANF) && (0==JSE_CLIB_FSCANF)
#     undef JSE_CLIB_FSCANF
#  endif
#  if defined(JSE_CLIB_FSEEK) && (0==JSE_CLIB_FSEEK)
#     undef JSE_CLIB_FSEEK
#  endif
#  if defined(JSE_CLIB_FSETPOS) && (0==JSE_CLIB_FSETPOS)
#     undef JSE_CLIB_FSETPOS
#  endif
#  if defined(JSE_CLIB_FTELL) && (0==JSE_CLIB_FTELL)
#     undef JSE_CLIB_FTELL
#  endif
#  if defined(JSE_CLIB_FWRITE) && (0==JSE_CLIB_FWRITE)
#     undef JSE_CLIB_FWRITE
#  endif
#  if defined(JSE_CLIB_GETC) && (0==JSE_CLIB_GETC)
#     undef JSE_CLIB_GETC
#  endif
#  if defined(JSE_CLIB_GETCH) && (0==JSE_CLIB_GETCH)
#     undef JSE_CLIB_GETCH
#  endif
#  if defined(JSE_CLIB_GETCHAR) && (0==JSE_CLIB_GETCHAR)
#     undef JSE_CLIB_GETCHAR
#  endif
#  if defined(JSE_CLIB_GETCHE) && (0==JSE_CLIB_GETCHE)
#     undef JSE_CLIB_GETCHE
#  endif
#  if defined(JSE_CLIB_GETCWD) && (0==JSE_CLIB_GETCWD)
#     undef JSE_CLIB_GETCWD
#  endif
#  if defined(JSE_CLIB_GETENV) && (0==JSE_CLIB_GETENV)
#     undef JSE_CLIB_GETENV
#  endif
#  if defined(JSE_CLIB_GETS) && (0==JSE_CLIB_GETS)
#     undef JSE_CLIB_GETS
#  endif
#  if defined(JSE_CLIB_GMTIME) && (0==JSE_CLIB_GMTIME)
#     undef JSE_CLIB_GMTIME
#  endif
#  if defined(JSE_CLIB_ISALNUM) && (0==JSE_CLIB_ISALNUM)
#     undef JSE_CLIB_ISALNUM
#  endif
#  if defined(JSE_CLIB_ISALPHA) && (0==JSE_CLIB_ISALPHA)
#     undef JSE_CLIB_ISALPHA
#  endif
#  if defined(JSE_CLIB_ISASCII) && (0==JSE_CLIB_ISASCII)
#     undef JSE_CLIB_ISASCII
#  endif
#  if defined(JSE_CLIB_ISCNTRL) && (0==JSE_CLIB_ISCNTRL)
#     undef JSE_CLIB_ISCNTRL
#  endif
#  if defined(JSE_CLIB_ISDIGIT) && (0==JSE_CLIB_ISDIGIT)
#     undef JSE_CLIB_ISDIGIT
#  endif
#  if defined(JSE_CLIB_ISGRAPH) && (0==JSE_CLIB_ISGRAPH)
#     undef JSE_CLIB_ISGRAPH
#  endif
#  if defined(JSE_CLIB_ISLOWER) && (0==JSE_CLIB_ISLOWER)
#     undef JSE_CLIB_ISLOWER
#  endif
#  if defined(JSE_CLIB_ISPRINT) && (0==JSE_CLIB_ISPRINT)
#     undef JSE_CLIB_ISPRINT
#  endif
#  if defined(JSE_CLIB_ISPUNCT) && (0==JSE_CLIB_ISPUNCT)
#     undef JSE_CLIB_ISPUNCT
#  endif
#  if defined(JSE_CLIB_ISSPACE) && (0==JSE_CLIB_ISSPACE)
#     undef JSE_CLIB_ISSPACE
#  endif
#  if defined(JSE_CLIB_ISUPPER) && (0==JSE_CLIB_ISUPPER)
#     undef JSE_CLIB_ISUPPER
#  endif
#  if defined(JSE_CLIB_ISXDIGIT) && (0==JSE_CLIB_ISXDIGIT)
#     undef JSE_CLIB_ISXDIGIT
#  endif
#  if defined(JSE_CLIB_KBHIT) && (0==JSE_CLIB_KBHIT)
#     undef JSE_CLIB_KBHIT
#  endif
#  if defined(JSE_CLIB_LABS) && (0==JSE_CLIB_LABS)
#     undef JSE_CLIB_LABS
#  endif
#  if defined(JSE_CLIB_LDEXP) && (0==JSE_CLIB_LDEXP)
#     undef JSE_CLIB_LDEXP
#  endif
#  if defined(JSE_CLIB_LDIV) && (0==JSE_CLIB_LDIV)
#     undef JSE_CLIB_LDIV
#  endif
#  if defined(JSE_CLIB_LOCALTIME) && (0==JSE_CLIB_LOCALTIME)
#     undef JSE_CLIB_LOCALTIME
#  endif
#  if defined(JSE_CLIB_LOG) && (0==JSE_CLIB_LOG)
#     undef JSE_CLIB_LOG
#  endif
#  if defined(JSE_CLIB_LOG10) && (0==JSE_CLIB_LOG10)
#     undef JSE_CLIB_LOG10
#  endif
#  if defined(JSE_CLIB_MAX) && (0==JSE_CLIB_MAX)
#     undef JSE_CLIB_MAX
#  endif
#  if defined(JSE_CLIB_MIN) && (0==JSE_CLIB_MIN)
#     undef JSE_CLIB_MIN
#  endif
#  if defined(JSE_CLIB_MKDIR) && (0==JSE_CLIB_MKDIR)
#     undef JSE_CLIB_MKDIR
#  endif
#  if defined(JSE_CLIB_MEMCHR) && (0==JSE_CLIB_MEMCHR)
#     undef JSE_CLIB_MEMCHR
#  endif
#  if defined(JSE_CLIB_MEMCMP) && (0==JSE_CLIB_MEMCMP)
#     undef JSE_CLIB_MEMCMP
#  endif
#  if defined(JSE_CLIB_MEMCPY) && (0==JSE_CLIB_MEMCPY)
#     undef JSE_CLIB_MEMCPY
#  endif
#  if defined(JSE_CLIB_MEMMOVE) && (0==JSE_CLIB_MEMMOVE)
#     undef JSE_CLIB_MEMMOVE
#  endif
#  if defined(JSE_CLIB_MEMSET) && (0==JSE_CLIB_MEMSET)
#     undef JSE_CLIB_MEMSET
#  endif
#  if defined(JSE_CLIB_MKTIME) && (0==JSE_CLIB_MKTIME)
#     undef JSE_CLIB_MKTIME
#  endif
#  if defined(JSE_CLIB_MODF) && (0==JSE_CLIB_MODF)
#     undef JSE_CLIB_MODF
#  endif
#  if defined(JSE_CLIB_PERROR) && (0==JSE_CLIB_PERROR)
#     undef JSE_CLIB_PERROR
#  endif
#  if defined(JSE_CLIB_POW) && (0==JSE_CLIB_POW)
#     undef JSE_CLIB_POW
#  endif
#  if defined(JSE_CLIB_PRINTF) && (0==JSE_CLIB_PRINTF)
#     undef JSE_CLIB_PRINTF
#  endif
#  if defined(JSE_CLIB_PUTC) && (0==JSE_CLIB_PUTC)
#     undef JSE_CLIB_PUTC
#  endif
#  if defined(JSE_CLIB_PUTCHAR) && (0==JSE_CLIB_PUTCHAR)
#     undef JSE_CLIB_PUTCHAR
#  endif
#  if defined(JSE_CLIB_PUTENV) && (0==JSE_CLIB_PUTENV)
#     undef JSE_CLIB_PUTENV
#  endif
#  if defined(JSE_CLIB_PUTS) && (0==JSE_CLIB_PUTS)
#     undef JSE_CLIB_PUTS
#  endif
#  if defined(JSE_CLIB_QSORT) && (0==JSE_CLIB_QSORT)
#     undef JSE_CLIB_QSORT
#  endif
#  if defined(JSE_CLIB_RAND) && (0==JSE_CLIB_RAND)
#     undef JSE_CLIB_RAND
#  endif
#  if defined(JSE_CLIB_REMOVE) && (0==JSE_CLIB_REMOVE)
#     undef JSE_CLIB_REMOVE
#  endif
#  if defined(JSE_CLIB_RENAME) && (0==JSE_CLIB_RENAME)
#     undef JSE_CLIB_RENAME
#  endif
#  if defined(JSE_CLIB_REWIND) && (0==JSE_CLIB_REWIND)
#     undef JSE_CLIB_REWIND
#  endif
#  if defined(JSE_CLIB_RMDIR) && (0==JSE_CLIB_RMDIR)
#     undef JSE_CLIB_RMDIR
#  endif
#  if defined(JSE_CLIB_RSPRINTF) && (0==JSE_CLIB_RSPRINTF)
#     undef JSE_CLIB_RSPRINTF
#  endif
#  if defined(JSE_CLIB_RVSPRINTF) && (0==JSE_CLIB_RVSPRINTF)
#     undef JSE_CLIB_RVSPRINTF
#  endif
#  if defined(JSE_CLIB_SCANF) && (0==JSE_CLIB_SCANF)
#     undef JSE_CLIB_SCANF
#  endif
#  if defined(JSE_CLIB_SIN) && (0==JSE_CLIB_SIN)
#     undef JSE_CLIB_SIN
#  endif
#  if defined(JSE_CLIB_SINH) && (0==JSE_CLIB_SINH)
#     undef JSE_CLIB_SINH
#  endif
#  if defined(JSE_CLIB_SPRINTF) && (0==JSE_CLIB_SPRINTF)
#     undef JSE_CLIB_SPRINTF
#  endif
#  if defined(JSE_CLIB_SQRT) && (0==JSE_CLIB_SQRT)
#     undef JSE_CLIB_SQRT
#  endif
#  if defined(JSE_CLIB_SRAND) && (0==JSE_CLIB_SRAND)
#     undef JSE_CLIB_SRAND
#  endif
#  if defined(JSE_CLIB_SSCANF) && (0==JSE_CLIB_SSCANF)
#     undef JSE_CLIB_SSCANF
#  endif
#  if defined(JSE_CLIB_STRCAT) && (0==JSE_CLIB_STRCAT)
#     undef JSE_CLIB_STRCAT
#  endif
#  if defined(JSE_CLIB_STRCHR) && (0==JSE_CLIB_STRCHR)
#     undef JSE_CLIB_STRCHR
#  endif
#  if defined(JSE_CLIB_STRCMP) && (0==JSE_CLIB_STRCMP)
#     undef JSE_CLIB_STRCMP
#  endif
#  if defined(JSE_CLIB_STRCPY) && (0==JSE_CLIB_STRCPY)
#     undef JSE_CLIB_STRCPY
#  endif
#  if defined(JSE_CLIB_STRCSPN) && (0==JSE_CLIB_STRCSPN)
#     undef JSE_CLIB_STRCSPN
#  endif
#  if defined(JSE_CLIB_STRERROR) && (0==JSE_CLIB_STRERROR)
#     undef JSE_CLIB_STRERROR
#  endif
#  if defined(JSE_CLIB_STRFTIME) && (0==JSE_CLIB_STRFTIME)
#     undef JSE_CLIB_STRFTIME
#  endif
#  if defined(JSE_CLIB_STRICMP) && (0==JSE_CLIB_STRICMP)
#     undef JSE_CLIB_STRICMP
#  endif
#  if defined(JSE_CLIB_STRLEN) && (0==JSE_CLIB_STRLEN)
#     undef JSE_CLIB_STRLEN
#  endif
#  if defined(JSE_CLIB_STRLWR) && (0==JSE_CLIB_STRLWR)
#     undef JSE_CLIB_STRLWR
#  endif
#  if defined(JSE_CLIB_STRNCAT) && (0==JSE_CLIB_STRNCAT)
#     undef JSE_CLIB_STRNCAT
#  endif
#  if defined(JSE_CLIB_STRNCMP) && (0==JSE_CLIB_STRNCMP)
#     undef JSE_CLIB_STRNCMP
#  endif
#  if defined(JSE_CLIB_STRNICMP) && (0==JSE_CLIB_STRNICMP)
#     undef JSE_CLIB_STRNICMP
#  endif
#  if defined(JSE_CLIB_STRNCPY) && (0==JSE_CLIB_STRNCPY)
#     undef JSE_CLIB_STRNCPY
#  endif
#  if defined(JSE_CLIB_STRPBRK) && (0==JSE_CLIB_STRPBRK)
#     undef JSE_CLIB_STRPBRK
#  endif
#  if defined(JSE_CLIB_STRRCHR) && (0==JSE_CLIB_STRRCHR)
#     undef JSE_CLIB_STRRCHR
#  endif
#  if defined(JSE_CLIB_STRSPN) && (0==JSE_CLIB_STRSPN)
#     undef JSE_CLIB_STRSPN
#  endif
#  if defined(JSE_CLIB_STRSTR) && (0==JSE_CLIB_STRSTR)
#     undef JSE_CLIB_STRSTR
#  endif
#  if defined(JSE_CLIB_STRSTRI) && (0==JSE_CLIB_STRSTRI)
#     undef JSE_CLIB_STRSTRI
#  endif
#  if defined(JSE_CLIB_STRTOD) && (0==JSE_CLIB_STRTOD)
#     undef JSE_CLIB_STRTOD
#  endif
#  if defined(JSE_CLIB_STRTOK) && (0==JSE_CLIB_STRTOK)
#     undef JSE_CLIB_STRTOK
#  endif
#  if defined(JSE_CLIB_STRTOL) && (0==JSE_CLIB_STRTOL)
#     undef JSE_CLIB_STRTOL
#  endif
#  if defined(JSE_CLIB_STRUPR) && (0==JSE_CLIB_STRUPR)
#     undef JSE_CLIB_STRUPR
#  endif
#  if defined(JSE_CLIB_SUSPEND) && (0==JSE_CLIB_SUSPEND)
#     undef JSE_CLIB_SUSPEND
#  endif
#  if defined(JSE_CLIB_SYSTEM) && (0==JSE_CLIB_SYSTEM)
#     undef JSE_CLIB_SYSTEM
#  endif
#  if defined(JSE_CLIB_TAN) && (0==JSE_CLIB_TAN)
#     undef JSE_CLIB_TAN
#  endif
#  if defined(JSE_CLIB_TANH) && (0==JSE_CLIB_TANH)
#     undef JSE_CLIB_TANH
#  endif
#  if defined(JSE_CLIB_TIME) && (0==JSE_CLIB_TIME)
#     undef JSE_CLIB_TIME
#  endif
#  if defined(JSE_CLIB_TMPFILE) && (0==JSE_CLIB_TMPFILE)
#     undef JSE_CLIB_TMPFILE
#  endif
#  if defined(JSE_CLIB_TMPNAM) && (0==JSE_CLIB_TMPNAM)
#     undef JSE_CLIB_TMPNAM
#  endif
#  if defined(JSE_CLIB_TOASCII) && (0==JSE_CLIB_TOASCII)
#     undef JSE_CLIB_TOASCII
#  endif
#  if defined(JSE_CLIB_TOLOWER) && (0==JSE_CLIB_TOLOWER)
#     undef JSE_CLIB_TOLOWER
#  endif
#  if defined(JSE_CLIB_TOUPPER) && (0==JSE_CLIB_TOUPPER)
#     undef JSE_CLIB_TOUPPER
#  endif
#  if defined(JSE_CLIB_UNGETC) && (0==JSE_CLIB_UNGETC)
#     undef JSE_CLIB_UNGETC
#  endif
#  if defined(JSE_CLIB_VA_ARG) && (0==JSE_CLIB_VA_ARG)
#     undef JSE_CLIB_VA_ARG
#  endif
#  if defined(JSE_CLIB_VA_END) && (0==JSE_CLIB_VA_END)
#     undef JSE_CLIB_VA_END
#  endif
#  if defined(JSE_CLIB_VA_START) && (0==JSE_CLIB_VA_START)
#     undef JSE_CLIB_VA_START
#  endif
#  if defined(JSE_CLIB_VFSCANF) && (0==JSE_CLIB_VFSCANF)
#     undef JSE_CLIB_VFSCANF
#  endif
#  if defined(JSE_CLIB_VFPRINTF) && (0==JSE_CLIB_VFPRINTF)
#     undef JSE_CLIB_VFPRINTF
#  endif
#  if defined(JSE_CLIB_VPRINTF) && (0==JSE_CLIB_VPRINTF)
#     undef JSE_CLIB_VPRINTF
#  endif
#  if defined(JSE_CLIB_VSCANF) && (0==JSE_CLIB_VSCANF)
#     undef JSE_CLIB_VSCANF
#  endif
#  if defined(JSE_CLIB_VSPRINTF) && (0==JSE_CLIB_VSPRINTF)
#     undef JSE_CLIB_VSPRINTF
#  endif
#  if defined(JSE_CLIB_VSSCANF) && (0==JSE_CLIB_VSSCANF)
#     undef JSE_CLIB_VSSCANF
#  endif
   /* Define generic JSE_CLIB_ANY */
#  if defined(JSE_CLIB_ABORT) \
   || defined(JSE_CLIB_ABS) \
   || defined(JSE_CLIB_ACOS) \
   || defined(JSE_CLIB_ASCTIME) \
   || defined(JSE_CLIB_ASIN) \
   || defined(JSE_CLIB_ASSERT) \
   || defined(JSE_CLIB_ATAN) \
   || defined(JSE_CLIB_ATAN2) \
   || defined(JSE_CLIB_ATEXIT) \
   || defined(JSE_CLIB_ATOI) \
   || defined(JSE_CLIB_ATOF) \
   || defined(JSE_CLIB_ATOL) \
   || defined(JSE_CLIB_BSEARCH) \
   || defined(JSE_CLIB_CEIL) \
   || defined(JSE_CLIB_CHDIR) \
   || defined(JSE_CLIB_CLEARERR) \
   || defined(JSE_CLIB_CLOCK) \
   || defined(JSE_CLIB_CTIME) \
   || defined(JSE_CLIB_COS) \
   || defined(JSE_CLIB_COSH) \
   || defined(JSE_CLIB_DIFFTIME) \
   || defined(JSE_CLIB_DIV) \
   || defined(JSE_CLIB_ERRNO) \
   || defined(JSE_CLIB_EXIT) \
   || defined(JSE_CLIB_EXP) \
   || defined(JSE_CLIB_FABS) \
   || defined(JSE_CLIB_FCLOSE) \
   || defined(JSE_CLIB_FEOF) \
   || defined(JSE_CLIB_FERROR) \
   || defined(JSE_CLIB_FFLUSH) \
   || defined(JSE_CLIB_FGETC) \
   || defined(JSE_CLIB_FGETPOS) \
   || defined(JSE_CLIB_FGETS) \
   || defined(JSE_CLIB_FLOCK) \
   || defined(JSE_CLIB_FLOOR) \
   || defined(JSE_CLIB_FMOD) \
   || defined(JSE_CLIB_FOPEN) \
   || defined(JSE_CLIB_FPUTC) \
   || defined(JSE_CLIB_FPRINTF) \
   || defined(JSE_CLIB_FPUTS) \
   || defined(JSE_CLIB_FREAD) \
   || defined(JSE_CLIB_FREXP) \
   || defined(JSE_CLIB_FREOPEN) \
   || defined(JSE_CLIB_FSCANF) \
   || defined(JSE_CLIB_FSEEK) \
   || defined(JSE_CLIB_FSETPOS) \
   || defined(JSE_CLIB_FTELL) \
   || defined(JSE_CLIB_FWRITE) \
   || defined(JSE_CLIB_GETC) \
   || defined(JSE_CLIB_GETCH) \
   || defined(JSE_CLIB_GETCHAR) \
   || defined(JSE_CLIB_GETCHE) \
   || defined(JSE_CLIB_GETCWD) \
   || defined(JSE_CLIB_GETENV) \
   || defined(JSE_CLIB_GETS) \
   || defined(JSE_CLIB_GMTIME) \
   || defined(JSE_CLIB_ISALNUM) \
   || defined(JSE_CLIB_ISALPHA) \
   || defined(JSE_CLIB_ISASCII) \
   || defined(JSE_CLIB_ISCNTRL) \
   || defined(JSE_CLIB_ISDIGIT) \
   || defined(JSE_CLIB_ISGRAPH) \
   || defined(JSE_CLIB_ISLOWER) \
   || defined(JSE_CLIB_ISPRINT) \
   || defined(JSE_CLIB_ISPUNCT) \
   || defined(JSE_CLIB_ISSPACE) \
   || defined(JSE_CLIB_ISUPPER) \
   || defined(JSE_CLIB_ISXDIGIT) \
   || defined(JSE_CLIB_KBHIT) \
   || defined(JSE_CLIB_LABS) \
   || defined(JSE_CLIB_LDEXP) \
   || defined(JSE_CLIB_LDIV) \
   || defined(JSE_CLIB_LOCALTIME) \
   || defined(JSE_CLIB_LOG) \
   || defined(JSE_CLIB_LOG10) \
   || defined(JSE_CLIB_MAX) \
   || defined(JSE_CLIB_MIN) \
   || defined(JSE_CLIB_MKDIR) \
   || defined(JSE_CLIB_MEMCHR) \
   || defined(JSE_CLIB_MEMCMP) \
   || defined(JSE_CLIB_MEMCPY) \
   || defined(JSE_CLIB_MEMMOVE) \
   || defined(JSE_CLIB_MEMSET) \
   || defined(JSE_CLIB_MKTIME) \
   || defined(JSE_CLIB_MODF) \
   || defined(JSE_CLIB_PERROR) \
   || defined(JSE_CLIB_POW) \
   || defined(JSE_CLIB_PRINTF) \
   || defined(JSE_CLIB_PUTC) \
   || defined(JSE_CLIB_PUTCHAR) \
   || defined(JSE_CLIB_PUTENV) \
   || defined(JSE_CLIB_PUTS) \
   || defined(JSE_CLIB_QSORT) \
   || defined(JSE_CLIB_RAND) \
   || defined(JSE_CLIB_REMOVE) \
   || defined(JSE_CLIB_RENAME) \
   || defined(JSE_CLIB_REWIND) \
   || defined(JSE_CLIB_RMDIR) \
   || defined(JSE_CLIB_RSPRINTF) \
   || defined(JSE_CLIB_RVSPRINTF) \
   || defined(JSE_CLIB_SCANF) \
   || defined(JSE_CLIB_SIN) \
   || defined(JSE_CLIB_SINH) \
   || defined(JSE_CLIB_SPRINTF) \
   || defined(JSE_CLIB_SQRT) \
   || defined(JSE_CLIB_SRAND) \
   || defined(JSE_CLIB_SSCANF) \
   || defined(JSE_CLIB_STRCAT) \
   || defined(JSE_CLIB_STRCHR) \
   || defined(JSE_CLIB_STRCMP) \
   || defined(JSE_CLIB_STRCPY) \
   || defined(JSE_CLIB_STRCSPN) \
   || defined(JSE_CLIB_STRERROR) \
   || defined(JSE_CLIB_STRFTIME) \
   || defined(JSE_CLIB_STRICMP) \
   || defined(JSE_CLIB_STRLEN) \
   || defined(JSE_CLIB_STRLWR) \
   || defined(JSE_CLIB_STRNCAT) \
   || defined(JSE_CLIB_STRNCMP) \
   || defined(JSE_CLIB_STRNICMP) \
   || defined(JSE_CLIB_STRNCPY) \
   || defined(JSE_CLIB_STRPBRK) \
   || defined(JSE_CLIB_STRRCHR) \
   || defined(JSE_CLIB_STRSPN) \
   || defined(JSE_CLIB_STRSTR) \
   || defined(JSE_CLIB_STRSTRI) \
   || defined(JSE_CLIB_STRTOD) \
   || defined(JSE_CLIB_STRTOK) \
   || defined(JSE_CLIB_STRTOL) \
   || defined(JSE_CLIB_STRUPR) \
   || defined(JSE_CLIB_SUSPEND) \
   || defined(JSE_CLIB_SYSTEM) \
   || defined(JSE_CLIB_TAN) \
   || defined(JSE_CLIB_TANH) \
   || defined(JSE_CLIB_TIME) \
   || defined(JSE_CLIB_TMPFILE) \
   || defined(JSE_CLIB_TMPNAM) \
   || defined(JSE_CLIB_TOASCII) \
   || defined(JSE_CLIB_TOLOWER) \
   || defined(JSE_CLIB_TOUPPER) \
   || defined(JSE_CLIB_UNGETC) \
   || defined(JSE_CLIB_VA_ARG) \
   || defined(JSE_CLIB_VA_END) \
   || defined(JSE_CLIB_VA_START) \
   || defined(JSE_CLIB_VFSCANF) \
   || defined(JSE_CLIB_VFPRINTF) \
   || defined(JSE_CLIB_VPRINTF) \
   || defined(JSE_CLIB_VSCANF) \
   || defined(JSE_CLIB_VSPRINTF) \
   || defined(JSE_CLIB_VSSCANF)
#     define JSE_CLIB_ANY
#  endif

/*****************
 * SCREEN        *
 *****************/

   /* Check for JSE_SCREEN_ALL */
#  if defined(JSE_SCREEN_ALL)
#     if !defined(JSE_SCREEN_CLEAR)
#        define JSE_SCREEN_CLEAR                 1
#     endif
#     if !defined(JSE_SCREEN_CURSOR)
#        define JSE_SCREEN_CURSOR                1
#     endif
#     if !defined(JSE_SCREEN_HANDLE) \
         && (defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__))
#        define JSE_SCREEN_HANDLE                1
#     endif
#     if !defined(JSE_SCREEN_SETBACKGROUND) \
         && (defined(__JSE_WIN16__) || defined(__JSE_WIN32__))
#        define JSE_SCREEN_SETBACKGROUND         1
#     endif
#     if !defined(JSE_SCREEN_SETFOREGROUND) \
         && (defined(__JSE_WIN16__) || defined(__JSE_WIN32__))
#        define JSE_SCREEN_SETFOREGROUND         1
#     endif
#     if !defined(JSE_SCREEN_SIZE)
#        define JSE_SCREEN_SIZE                  1
#     endif
#     if !defined(JSE_SCREEN_WRITE)
#        define JSE_SCREEN_WRITE                 1
#     endif
#     if !defined(JSE_SCREEN_WRITELN)
#        define JSE_SCREEN_WRITELN               1
#     endif
#  endif /* JSE_SCREEN_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_SCREEN_CLEAR) && (0==JSE_SCREEN_CLEAR)
#     undef JSE_SCREEN_CLEAR
#  endif
#  if defined(JSE_SCREEN_CURSOR) && (0==JSE_SCREEN_CURSOR)
#     undef JSE_SCREEN_CURSOR
#  endif
#  if defined(JSE_SCREEN_HANDLE) && (0==JSE_SCREEN_HANDLE)
#     undef JSE_SCREEN_HANDLE
#  endif
#  if defined(JSE_SCREEN_SETBACKGROUND) && (0==JSE_SCREEN_SETBACKGROUND)
#     undef JSE_SCREEN_SETBACKGROUND
#  endif
#  if defined(JSE_SCREEN_SETFOREGROUND) && (0==JSE_SCREEN_SETFOREGROUND)
#     undef JSE_SCREEN_SETFOREGROUND
#  endif
#  if defined(JSE_SCREEN_SIZE) && (0==JSE_SCREEN_SIZE)
#     undef JSE_SCREEN_SIZE
#  endif
#  if defined(JSE_SCREEN_WRITE) && (0==JSE_SCREEN_WRITE)
#     undef JSE_SCREEN_WRITE
#  endif
#  if defined(JSE_SCREEN_WRITELN) && (0==JSE_SCREEN_WRITELN)
#     undef JSE_SCREEN_WRITELN
#  endif
   /* Define generic JSE_SCREEN_ANY */
#  if defined(JSE_SCREEN_CLEAR) \
   || defined(JSE_SCREEN_CURSOR) \
   || defined(JSE_SCREEN_HANDLE) \
   || defined(JSE_SCREEN_SETBACKGROUND) \
   || defined(JSE_SCREEN_SETFOREGROUND) \
   || defined(JSE_SCREEN_SIZE) \
   || defined(JSE_SCREEN_WRITE) \
   || defined(JSE_SCREEN_WRITELN)
#     define JSE_SCREEN_ANY
#  endif

/*****************
 * TEST          *
 *****************/

   /* Check for JSE_TEST_ALL */
#  if defined(JSE_TEST_ALL)
#     if !defined(JSE_TEST_ASSERT)
#        define JSE_TEST_ASSERT                  1
#     endif
#     if !defined(JSE_TEST_START)
#        define JSE_TEST_START                   1
#     endif
#     if !defined(JSE_TEST_END)
#        define JSE_TEST_END                     1
#     endif
#     if !defined(JSE_TEST_ASSERTNUMEQUAL)
#        define JSE_TEST_ASSERTNUMEQUAL          1
#     endif
#     if !defined(JSE_TEST_SETATTRIBUTES)
#        define JSE_TEST_SETATTRIBUTES           1
#     endif
#     if !defined(JSE_TEST_ISNAN)
#        define JSE_TEST_ISNAN                   1
#     endif
#     if !defined(JSE_TEST_ISNEGZERO)
#        define JSE_TEST_ISNEGZERO               1
#     endif
#     if !defined(JSE_TEST_ISPOSZERO)
#        define JSE_TEST_ISPOSZERO               1
#     endif
#     if !defined(JSE_TEST_ISFINITE)
#        define JSE_TEST_ISFINITE                1
#     endif
#     if !defined(JSE_TEST_WARNBADMATH)
#        define JSE_TEST_WARNBADMATH             1
#     endif
#     if !defined(JSE_TEST_DEFINE)
#        define JSE_TEST_DEFINE                  1
#     endif
#  endif /* JSE_TEST_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_TEST_ASSERT) && (0==JSE_TEST_ASSERT)
#     undef JSE_TEST_ASSERT
#  endif
#  if defined(JSE_TEST_START) && (0==JSE_TEST_START)
#     undef JSE_TEST_START
#  endif
#  if defined(JSE_TEST_END) && (0==JSE_TEST_END)
#     undef JSE_TEST_END
#  endif
#  if defined(JSE_TEST_ASSERTNUMEQUAL) && (0==JSE_TEST_ASSERTNUMEQUAL)
#     undef JSE_TEST_ASSERTNUMEQUAL
#  endif
#  if defined(JSE_TEST_SETATTRIBUTES) && (0==JSE_TEST_SETATTRIBUTES)
#     undef JSE_TEST_SETATTRIBUTES
#  endif
#  if defined(JSE_TEST_ISNAN) && (0==JSE_TEST_ISNAN)
#     undef JSE_TEST_ISNAN
#  endif
#  if defined(JSE_TEST_ISNEGZERO) && (0==JSE_TEST_ISNEGZERO)
#     undef JSE_TEST_ISNEGZERO
#  endif
#  if defined(JSE_TEST_ISPOSZERO) && (0==JSE_TEST_ISPOSZERO)
#     undef JSE_TEST_ISPOSZERO
#  endif
#  if defined(JSE_TEST_ISFINITE) && (0==JSE_TEST_ISFINITE)
#     undef JSE_TEST_ISFINITE
#  endif
#  if defined(JSE_TEST_WARNBADMATH) && (0==JSE_TEST_WARNBADMATH)
#     undef JSE_TEST_WARNBADMATH
#  endif
#  if defined(JSE_TEST_DEFINE) && (0==JSE_TEST_DEFINE)
#     undef JSE_TEST_DEFINE
#  endif
   /* Define generic JSE_TEST_ANY */
#  if defined(JSE_TEST_ASSERT) \
   || defined(JSE_TEST_START) \
   || defined(JSE_TEST_END) \
   || defined(JSE_TEST_ASSERTNUMEQUAL) \
   || defined(JSE_TEST_SETATTRIBUTES) \
   || defined(JSE_TEST_ISNAN) \
   || defined(JSE_TEST_ISNEGZERO) \
   || defined(JSE_TEST_ISPOSZERO) \
   || defined(JSE_TEST_ISFINITE) \
   || defined(JSE_TEST_WARNBADMATH) \
   || defined(JSE_TEST_DEFINE)
#     define JSE_TEST_ANY
#  endif

/*****************
 * UUCODE        *
 *****************/

   /* Check for JSE_UUCODE_ALL */
#  if defined(JSE_UUCODE_ALL)
#     if !defined(JSE_UUCODE_ENCODE)
#        define JSE_UUCODE_ENCODE                1
#     endif
#     if !defined(JSE_UUCODE_DECODE)
#        define JSE_UUCODE_DECODE                1
#     endif
#  endif /* JSE_UUCODE_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_UUCODE_ENCODE) && (0==JSE_UUCODE_ENCODE)
#     undef JSE_UUCODE_ENCODE
#  endif
#  if defined(JSE_UUCODE_DECODE) && (0==JSE_UUCODE_DECODE)
#     undef JSE_UUCODE_DECODE
#  endif
   /* Define generic JSE_UUCODE_ANY */
#  if defined(JSE_UUCODE_ENCODE) \
   || defined(JSE_UUCODE_DECODE)
#     define JSE_UUCODE_ANY
#  endif

/*****************
 * GD            *
 *****************/

   /* Check for JSE_GD_ALL */
#  if defined(JSE_GD_ALL)
#     if !defined(JSE_GD_FROMGIF)
#        define JSE_GD_FROMGIF                   1
#     endif
#     if !defined(JSE_GD_FROMGD)
#        define JSE_GD_FROMGD                    1
#     endif
#     if !defined(JSE_GD_FROMXBM)
#        define JSE_GD_FROMXBM                   1
#     endif
#     if !defined(JSE_GD_DESTROY)
#        define JSE_GD_DESTROY                   1
#     endif
#     if !defined(JSE_GD_SETPIXEL)
#        define JSE_GD_SETPIXEL                  1
#     endif
#     if !defined(JSE_GD_GETPIXEL)
#        define JSE_GD_GETPIXEL                  1
#     endif
#     if !defined(JSE_GD_LINE)
#        define JSE_GD_LINE                      1
#     endif
#     if !defined(JSE_GD_DASHEDLINE)
#        define JSE_GD_DASHEDLINE                1
#     endif
#     if !defined(JSE_GD_RECTANGLE)
#        define JSE_GD_RECTANGLE                 1
#     endif
#     if !defined(JSE_GD_FILLEDRECTANGLE)
#        define JSE_GD_FILLEDRECTANGLE           1
#     endif
#     if !defined(JSE_GD_BOUNDSSAFE)
#        define JSE_GD_BOUNDSSAFE                1
#     endif
#     if !defined(JSE_GD_CHAR)
#        define JSE_GD_CHAR                      1
#     endif
#     if !defined(JSE_GD_CHARUP)
#        define JSE_GD_CHARUP                    1
#     endif
#     if !defined(JSE_GD_STRING)
#        define JSE_GD_STRING                    1
#     endif
#     if !defined(JSE_GD_STRINGUP)
#        define JSE_GD_STRINGUP                  1
#     endif
#     if !defined(JSE_GD_POLYGON)
#        define JSE_GD_POLYGON                   1
#     endif
#     if !defined(JSE_GD_FILLEDPOLYGON)
#        define JSE_GD_FILLEDPOLYGON             1
#     endif
#     if !defined(JSE_GD_COLORALLOCATE)
#        define JSE_GD_COLORALLOCATE             1
#     endif
#     if !defined(JSE_GD_COLORCLOSEST)
#        define JSE_GD_COLORCLOSEST              1
#     endif
#     if !defined(JSE_GD_COLOREXACT)
#        define JSE_GD_COLOREXACT                1
#     endif
#     if !defined(JSE_GD_COLORTRANSPARENT)
#        define JSE_GD_COLORTRANSPARENT          1
#     endif
#     if !defined(JSE_GD_COLORDEALLOCATE)
#        define JSE_GD_COLORDEALLOCATE           1
#     endif
#     if !defined(JSE_GD_TOGIF)
#        define JSE_GD_TOGIF                     1
#     endif
#     if !defined(JSE_GD_TOGD)
#        define JSE_GD_TOGD                      1
#     endif
#     if !defined(JSE_GD_ARC)
#        define JSE_GD_ARC                       1
#     endif
#     if !defined(JSE_GD_FILLTOBORDER)
#        define JSE_GD_FILLTOBORDER              1
#     endif
#     if !defined(JSE_GD_FILL)
#        define JSE_GD_FILL                      1
#     endif
#     if !defined(JSE_GD_COPY)
#        define JSE_GD_COPY                      1
#     endif
#     if !defined(JSE_GD_COPYRESIZED)
#        define JSE_GD_COPYRESIZED               1
#     endif
#     if !defined(JSE_GD_SETBRUSH)
#        define JSE_GD_SETBRUSH                  1
#     endif
#     if !defined(JSE_GD_SETSTYLE)
#        define JSE_GD_SETSTYLE                  1
#     endif
#     if !defined(JSE_GD_SETTILE)
#        define JSE_GD_SETTILE                   1
#     endif
#     if !defined(JSE_GD_INTERLACE)
#        define JSE_GD_INTERLACE                 1
#     endif
#     if !defined(JSE_GD_COLORSTOTAL)
#        define JSE_GD_COLORSTOTAL               1
#     endif
#     if !defined(JSE_GD_GREEN)
#        define JSE_GD_GREEN                     1
#     endif
#     if !defined(JSE_GD_RED)
#        define JSE_GD_RED                       1
#     endif
#     if !defined(JSE_GD_BLUE)
#        define JSE_GD_BLUE                      1
#     endif
#     if !defined(JSE_GD_WIDTH)
#        define JSE_GD_WIDTH                     1
#     endif
#     if !defined(JSE_GD_HEIGHT)
#        define JSE_GD_HEIGHT                    1
#     endif
#     if !defined(JSE_GD_GETTRANSPARENT)
#        define JSE_GD_GETTRANSPARENT            1
#     endif
#     if !defined(JSE_GD_GETINTERLACED)
#        define JSE_GD_GETINTERLACED             1
#     endif
#  endif /* JSE_GD_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_GD_FROMGIF) && (0==JSE_GD_FROMGIF)
#     undef JSE_GD_FROMGIF
#  endif
#  if defined(JSE_GD_FROMGD) && (0==JSE_GD_FROMGD)
#     undef JSE_GD_FROMGD
#  endif
#  if defined(JSE_GD_FROMXBM) && (0==JSE_GD_FROMXBM)
#     undef JSE_GD_FROMXBM
#  endif
#  if defined(JSE_GD_DESTROY) && (0==JSE_GD_DESTROY)
#     undef JSE_GD_DESTROY
#  endif
#  if defined(JSE_GD_SETPIXEL) && (0==JSE_GD_SETPIXEL)
#     undef JSE_GD_SETPIXEL
#  endif
#  if defined(JSE_GD_GETPIXEL) && (0==JSE_GD_GETPIXEL)
#     undef JSE_GD_GETPIXEL
#  endif
#  if defined(JSE_GD_LINE) && (0==JSE_GD_LINE)
#     undef JSE_GD_LINE
#  endif
#  if defined(JSE_GD_DASHEDLINE) && (0==JSE_GD_DASHEDLINE)
#     undef JSE_GD_DASHEDLINE
#  endif
#  if defined(JSE_GD_RECTANGLE) && (0==JSE_GD_RECTANGLE)
#     undef JSE_GD_RECTANGLE
#  endif
#  if defined(JSE_GD_FILLEDRECTANGLE) && (0==JSE_GD_FILLEDRECTANGLE)
#     undef JSE_GD_FILLEDRECTANGLE
#  endif
#  if defined(JSE_GD_BOUNDSSAFE) && (0==JSE_GD_BOUNDSSAFE)
#     undef JSE_GD_BOUNDSSAFE
#  endif
#  if defined(JSE_GD_CHAR) && (0==JSE_GD_CHAR)
#     undef JSE_GD_CHAR
#  endif
#  if defined(JSE_GD_CHARUP) && (0==JSE_GD_CHARUP)
#     undef JSE_GD_CHARUP
#  endif
#  if defined(JSE_GD_STRING) && (0==JSE_GD_STRING)
#     undef JSE_GD_STRING
#  endif
#  if defined(JSE_GD_STRINGUP) && (0==JSE_GD_STRINGUP)
#     undef JSE_GD_STRINGUP
#  endif
#  if defined(JSE_GD_POLYGON) && (0==JSE_GD_POLYGON)
#     undef JSE_GD_POLYGON
#  endif
#  if defined(JSE_GD_FILLEDPOLYGON) && (0==JSE_GD_FILLEDPOLYGON)
#     undef JSE_GD_FILLEDPOLYGON
#  endif
#  if defined(JSE_GD_COLORALLOCATE) && (0==JSE_GD_COLORALLOCATE)
#     undef JSE_GD_COLORALLOCATE
#  endif
#  if defined(JSE_GD_COLORCLOSEST) && (0==JSE_GD_COLORCLOSEST)
#     undef JSE_GD_COLORCLOSEST
#  endif
#  if defined(JSE_GD_COLOREXACT) && (0==JSE_GD_COLOREXACT)
#     undef JSE_GD_COLOREXACT
#  endif
#  if defined(JSE_GD_COLORTRANSPARENT) && (0==JSE_GD_COLORTRANSPARENT)
#     undef JSE_GD_COLORTRANSPARENT
#  endif
#  if defined(JSE_GD_COLORDEALLOCATE) && (0==JSE_GD_COLORDEALLOCATE)
#     undef JSE_GD_COLORDEALLOCATE
#  endif
#  if defined(JSE_GD_TOGIF) && (0==JSE_GD_TOGIF)
#     undef JSE_GD_TOGIF
#  endif
#  if defined(JSE_GD_TOGD) && (0==JSE_GD_TOGD)
#     undef JSE_GD_TOGD
#  endif
#  if defined(JSE_GD_ARC) && (0==JSE_GD_ARC)
#     undef JSE_GD_ARC
#  endif
#  if defined(JSE_GD_FILLTOBORDER) && (0==JSE_GD_FILLTOBORDER)
#     undef JSE_GD_FILLTOBORDER
#  endif
#  if defined(JSE_GD_FILL) && (0==JSE_GD_FILL)
#     undef JSE_GD_FILL
#  endif
#  if defined(JSE_GD_COPY) && (0==JSE_GD_COPY)
#     undef JSE_GD_COPY
#  endif
#  if defined(JSE_GD_COPYRESIZED) && (0==JSE_GD_COPYRESIZED)
#     undef JSE_GD_COPYRESIZED
#  endif
#  if defined(JSE_GD_SETBRUSH) && (0==JSE_GD_SETBRUSH)
#     undef JSE_GD_SETBRUSH
#  endif
#  if defined(JSE_GD_SETSTYLE) && (0==JSE_GD_SETSTYLE)
#     undef JSE_GD_SETSTYLE
#  endif
#  if defined(JSE_GD_SETTILE) && (0==JSE_GD_SETTILE)
#     undef JSE_GD_SETTILE
#  endif
#  if defined(JSE_GD_INTERLACE) && (0==JSE_GD_INTERLACE)
#     undef JSE_GD_INTERLACE
#  endif
#  if defined(JSE_GD_COLORSTOTAL) && (0==JSE_GD_COLORSTOTAL)
#     undef JSE_GD_COLORSTOTAL
#  endif
#  if defined(JSE_GD_GREEN) && (0==JSE_GD_GREEN)
#     undef JSE_GD_GREEN
#  endif
#  if defined(JSE_GD_RED) && (0==JSE_GD_RED)
#     undef JSE_GD_RED
#  endif
#  if defined(JSE_GD_BLUE) && (0==JSE_GD_BLUE)
#     undef JSE_GD_BLUE
#  endif
#  if defined(JSE_GD_WIDTH) && (0==JSE_GD_WIDTH)
#     undef JSE_GD_WIDTH
#  endif
#  if defined(JSE_GD_HEIGHT) && (0==JSE_GD_HEIGHT)
#     undef JSE_GD_HEIGHT
#  endif
#  if defined(JSE_GD_GETTRANSPARENT) && (0==JSE_GD_GETTRANSPARENT)
#     undef JSE_GD_GETTRANSPARENT
#  endif
#  if defined(JSE_GD_GETINTERLACED) && (0==JSE_GD_GETINTERLACED)
#     undef JSE_GD_GETINTERLACED
#  endif
   /* Define generic JSE_GD_ANY */
#  if defined(JSE_GD_FROMGIF) \
   || defined(JSE_GD_FROMGD) \
   || defined(JSE_GD_FROMXBM) \
   || defined(JSE_GD_DESTROY) \
   || defined(JSE_GD_SETPIXEL) \
   || defined(JSE_GD_GETPIXEL) \
   || defined(JSE_GD_LINE) \
   || defined(JSE_GD_DASHEDLINE) \
   || defined(JSE_GD_RECTANGLE) \
   || defined(JSE_GD_FILLEDRECTANGLE) \
   || defined(JSE_GD_BOUNDSSAFE) \
   || defined(JSE_GD_CHAR) \
   || defined(JSE_GD_CHARUP) \
   || defined(JSE_GD_STRING) \
   || defined(JSE_GD_STRINGUP) \
   || defined(JSE_GD_POLYGON) \
   || defined(JSE_GD_FILLEDPOLYGON) \
   || defined(JSE_GD_COLORALLOCATE) \
   || defined(JSE_GD_COLORCLOSEST) \
   || defined(JSE_GD_COLOREXACT) \
   || defined(JSE_GD_COLORTRANSPARENT) \
   || defined(JSE_GD_COLORDEALLOCATE) \
   || defined(JSE_GD_TOGIF) \
   || defined(JSE_GD_TOGD) \
   || defined(JSE_GD_ARC) \
   || defined(JSE_GD_FILLTOBORDER) \
   || defined(JSE_GD_FILL) \
   || defined(JSE_GD_COPY) \
   || defined(JSE_GD_COPYRESIZED) \
   || defined(JSE_GD_SETBRUSH) \
   || defined(JSE_GD_SETSTYLE) \
   || defined(JSE_GD_SETTILE) \
   || defined(JSE_GD_INTERLACE) \
   || defined(JSE_GD_COLORSTOTAL) \
   || defined(JSE_GD_GREEN) \
   || defined(JSE_GD_RED) \
   || defined(JSE_GD_BLUE) \
   || defined(JSE_GD_WIDTH) \
   || defined(JSE_GD_HEIGHT) \
   || defined(JSE_GD_GETTRANSPARENT) \
   || defined(JSE_GD_GETINTERLACED)
#     define JSE_GD_ANY
#  endif

/*****************
 * SOCKET        *
 *****************/

   /* Check for JSE_SOCKET_ALL */
#  if defined(JSE_SOCKET_ALL)
#     if !defined(JSE_SOCKET_ADDRESSBYNAME)
#        define JSE_SOCKET_ADDRESSBYNAME         1
#     endif
#     if !defined(JSE_SOCKET_ERROR)
#        define JSE_SOCKET_ERROR                 1
#     endif
#     if !defined(JSE_SOCKET_HOSTBYNAME)
#        define JSE_SOCKET_HOSTBYNAME            1
#     endif
#     if !defined(JSE_SOCKET_HOSTNAME)
#        define JSE_SOCKET_HOSTNAME              1
#     endif
#     if !defined(JSE_SOCKET_SELECT)
#        define JSE_SOCKET_SELECT                1
#     endif
#     if !defined(JSE_SOCKET_ACCEPT)
#        define JSE_SOCKET_ACCEPT                1
#     endif
#     if !defined(JSE_SOCKET_BLOCKING)
#        define JSE_SOCKET_BLOCKING              1
#     endif
#     if !defined(JSE_SOCKET_CLOSE)
#        define JSE_SOCKET_CLOSE                 1
#     endif
#     if !defined(JSE_SOCKET_LINGER)
#        define JSE_SOCKET_LINGER                1
#     endif
#     if !defined(JSE_SOCKET_READ)
#        define JSE_SOCKET_READ                  1
#     endif
#     if !defined(JSE_SOCKET_READY)
#        define JSE_SOCKET_READY                 1
#     endif
#     if !defined(JSE_SOCKET_REMOTEHOST)
#        define JSE_SOCKET_REMOTEHOST            1
#     endif
#     if !defined(JSE_SOCKET_WRITE)
#        define JSE_SOCKET_WRITE                 1
#     endif
#  endif /* JSE_SOCKET_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_SOCKET_ADDRESSBYNAME) && (0==JSE_SOCKET_ADDRESSBYNAME)
#     undef JSE_SOCKET_ADDRESSBYNAME
#  endif
#  if defined(JSE_SOCKET_ERROR) && (0==JSE_SOCKET_ERROR)
#     undef JSE_SOCKET_ERROR
#  endif
#  if defined(JSE_SOCKET_HOSTBYNAME) && (0==JSE_SOCKET_HOSTBYNAME)
#     undef JSE_SOCKET_HOSTBYNAME
#  endif
#  if defined(JSE_SOCKET_HOSTNAME) && (0==JSE_SOCKET_HOSTNAME)
#     undef JSE_SOCKET_HOSTNAME
#  endif
#  if defined(JSE_SOCKET_SELECT) && (0==JSE_SOCKET_SELECT)
#     undef JSE_SOCKET_SELECT
#  endif
#  if defined(JSE_SOCKET_ACCEPT) && (0==JSE_SOCKET_ACCEPT)
#     undef JSE_SOCKET_ACCEPT
#  endif
#  if defined(JSE_SOCKET_BLOCKING) && (0==JSE_SOCKET_BLOCKING)
#     undef JSE_SOCKET_BLOCKING
#  endif
#  if defined(JSE_SOCKET_CLOSE) && (0==JSE_SOCKET_CLOSE)
#     undef JSE_SOCKET_CLOSE
#  endif
#  if defined(JSE_SOCKET_LINGER) && (0==JSE_SOCKET_LINGER)
#     undef JSE_SOCKET_LINGER
#  endif
#  if defined(JSE_SOCKET_READ) && (0==JSE_SOCKET_READ)
#     undef JSE_SOCKET_READ
#  endif
#  if defined(JSE_SOCKET_READY) && (0==JSE_SOCKET_READY)
#     undef JSE_SOCKET_READY
#  endif
#  if defined(JSE_SOCKET_REMOTEHOST) && (0==JSE_SOCKET_REMOTEHOST)
#     undef JSE_SOCKET_REMOTEHOST
#  endif
#  if defined(JSE_SOCKET_WRITE) && (0==JSE_SOCKET_WRITE)
#     undef JSE_SOCKET_WRITE
#  endif
   /* Define generic JSE_SOCKET_ANY */
#  if defined(JSE_SOCKET_ADDRESSBYNAME) \
   || defined(JSE_SOCKET_ERROR) \
   || defined(JSE_SOCKET_HOSTBYNAME) \
   || defined(JSE_SOCKET_HOSTNAME) \
   || defined(JSE_SOCKET_SELECT) \
   || defined(JSE_SOCKET_ACCEPT) \
   || defined(JSE_SOCKET_BLOCKING) \
   || defined(JSE_SOCKET_CLOSE) \
   || defined(JSE_SOCKET_LINGER) \
   || defined(JSE_SOCKET_READ) \
   || defined(JSE_SOCKET_READY) \
   || defined(JSE_SOCKET_REMOTEHOST) \
   || defined(JSE_SOCKET_WRITE)
#     define JSE_SOCKET_ANY
#  endif

/*****************
 * COMOBJ        *
 *****************/

   /* Check for JSE_COMOBJ_ALL */
#  if defined(JSE_COMOBJ_ALL)
#     if !defined(JSE_COMOBJ_CREATEOBJECT)
#        define JSE_COMOBJ_CREATEOBJECT          1
#     endif
#  endif /* JSE_COMOBJ_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_COMOBJ_CREATEOBJECT) && (0==JSE_COMOBJ_CREATEOBJECT)
#     undef JSE_COMOBJ_CREATEOBJECT
#  endif
   /* Define generic JSE_COMOBJ_ANY */
#  if defined(JSE_COMOBJ_CREATEOBJECT)
#     define JSE_COMOBJ_ANY
#  endif

/*****************
 * MD5           *
 *****************/

   /* Check for JSE_MD5_ALL */
#  if defined(JSE_MD5_ALL)
#     if !defined(JSE_MD5_OBJECT)
#        define JSE_MD5_OBJECT                   1
#     endif
#  endif /* JSE_MD5_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_MD5_OBJECT) && (0==JSE_MD5_OBJECT)
#     undef JSE_MD5_OBJECT
#  endif
   /* Define generic JSE_MD5_ANY */
#  if defined(JSE_MD5_OBJECT)
#     define JSE_MD5_ANY
#  endif

/*****************
 * DSP           *
 *****************/

   /* Check for JSE_DSP_ALL */
#  if defined(JSE_DSP_ALL)
#     if !defined(JSE_DSP_OBJECT)
#        define JSE_DSP_OBJECT                   1
#     endif
#  endif /* JSE_DSP_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_DSP_OBJECT) && (0==JSE_DSP_OBJECT)
#     undef JSE_DSP_OBJECT
#  endif
   /* Define generic JSE_DSP_ANY */
#  if defined(JSE_DSP_OBJECT)
#     define JSE_DSP_ANY
#  endif

/*****************
 * SEDBC         *
 *****************/

   /* Check for JSE_SEDBC_ALL */
#  if defined(JSE_SEDBC_ALL)
#     if !defined(JSE_SEDBC_OBJECT)
#        define JSE_SEDBC_OBJECT                 1
#     endif
#  endif /* JSE_SEDBC_ALL */
   /* Convert zeros to undefines */
#  if defined(JSE_SEDBC_OBJECT) && (0==JSE_SEDBC_OBJECT)
#     undef JSE_SEDBC_OBJECT
#  endif
   /* Define generic JSE_SEDBC_ANY */
#  if defined(JSE_SEDBC_OBJECT)
#     define JSE_SEDBC_ANY
#  endif
#endif /* __SELIBDEF_H */
