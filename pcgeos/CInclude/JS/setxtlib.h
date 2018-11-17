/* setxtlib.h   All access to text strings.
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

#if defined(_TEXTLIB_CPP)
#  if !defined(_TEXTLIB_H)
#    error MUST INCLUDE TEXTLIB.H BEFORE DEFINING TEXTLIB_CPP, AND THEN AGAIN AFTER DEFINING _TEXTLIB_CPP
#  endif
#  undef _TEXTLIB_H
#endif

#ifndef _TEXTLIB_H
#  define _TEXTLIB_H

#  ifdef __cplusplus
extern "C" {
#  endif

#if defined(_TEXTLIB_CPP)
#  undef   TL_RESOURCE
#  if !defined(JSE_SHORT_RESOURCE) || (0==JSE_SHORT_RESOURCE)
#     define TL_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                     UNISTR(" ") UNISTR(SHORT) UNISTR(": ") \
                                                     UNISTR(DETAILS),
#  else
#     define TL_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                     UNISTR(" ") UNISTR(SHORT),
#  endif
   /* TL_LONG_RESOURCE is always long, even if JSE_SHORT_RESOURCE */
#  undef TL_LONG_RESOURCE
#  define TL_LONG_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                       UNISTR(" ") UNISTR(SHORT) UNISTR(": ") \
                                                       UNISTR(DETAILS),
#  undef   TL_TEXT_STRING
#  define  TL_TEXT_STRING(ID,STRING)     CONST_STRING(ID,STRING);
#else
#  define  TL_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) ID,
#  define  TL_LONG_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) ID,
#  undef   TL_TEXT_STRING
#  define  TL_TEXT_STRING(ID,STRING)     extern CONST_DATA(jsecharptrdatum) ID[];
#endif


#if defined(_TEXTLIB_CPP)
   static CONST_DATA(jsecharptr ) textlibStrings[TEXTLIB_ID_COUNT] = {
            UNISTR("Resource String Not Found."),
#else
   enum textlibID {
            TL_RESOURCE_STRING_NOT_FOUND = 0,
#endif

/********** This is the basic concept behind the error number scheme. ********
   *
   * 0xxx:  Internal CENVI errors.
   *  00xx:  Finding source stuff.
   *  01xx:  Binding errors
   *
   * 1xxx:  Language errors
   *  10xx:  Preprocessor errors
   *  11xx:  Parsing errors
   *  12xx:  Parse error; missing a piece of a loop or something.
   *  13xx:  Misc parsing errors.
   *  14xx:  Function declaration stuff.
   *  15xx:  Expression evaluation errors
   *  16xx:  Data type errors
   *  17xx:  Math errors
   *
   * 5xxx:  Library errors
   *  50xx:  Parameter types
   *
   * 6xxx - 7xxxx:  Library error messages
   *  60xx:  Common
   *  61xx:  SElib
   *  62xx:  Clib
   *  63xx:  Ecma
   *  64xx:  Lang
   *  65xx:  Unix
   *  66xx:  Win
   *  67xx:  Dos
   *  68xx:  Mac
   *  69xx:  OS2
   *  70xx:  NLM
   *  71xx:  Link libraries (md5,gd,rx)
   *
   * 8xxx:  Misc.
   *  81xx: Security
   *
   * 9xxx:  Debug version messages
   *  90xx:  Memory stuff
   *  91xx:  Unimplemented hooks
   *  92xx:  We're confused.
   *  99xx:  I haven't a clue what these mean
   *
   ******************************************************************************/

#  if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
      TL_RESOURCE(textlibINSUFFICIENT_MEMORY,MEMORY_EXCEPTION,"0003",
                  "Insufficient Memory to continue operation.")
#  endif

#  if defined(JSE_CLIB_LDIV) || \
      defined(JSE_CLIB_DIV)
   TL_RESOURCE(textlibCANNOT_DIVIDE_BY_ZERO,MATH_EXCEPTION,"1702","Cannot divide by zero.")
#  endif

#  if defined(JSETOOLKIT_LINK)
      TL_RESOURCE(textlibLINK_FUNC_NOT_SUPPORTED,INTERNAL_EXCEPTION,"5100","Application does not support function \"%s\"/")
      TL_RESOURCE(textlibOUTDATED_HOST,INTERNAL_EXCEPTION,"5101","This is an outdated ScriptEase host")
#  endif

   /*** Common ****/
#if defined(JSE_SELIB_BLOB_SIZE) || \
    defined(JSE_LANG_SETARRAYLENGTH)
   TL_RESOURCE(textlibBAD_MAX_ARRAY_LENGTH,SYNTAX_EXCEPTION,"6000",
               "Array length must be 0 or positive.")
#endif
#if defined(JSE_SELIB_BLOB_GET) || \
    defined(JSE_SELIB_BLOB_PUT) || \
    defined(JSE_SELIB_BLOB_SIZE) || \
    defined(JSE_CLIB_FREAD)   || \
    defined(JSE_CLIB_FWRITE)  || \
    defined(JSE_SELIB_PEEK)    || \
    defined(JSE_SELIB_POKE)    || \
    defined(JSE_SOCKET_READ)   || \
    defined(JSE_SOCKET_WRITE)  || \
    defined(JSE_SELIB_DYNAMICLINK)
   TL_RESOURCE(textlibINVALID_DATA_DESCRIPTION,TYPE_EXCEPTION,"6001",
               "Blob data description variable is invalid for data conversion.")
   TL_RESOURCE(textlibINVALID_BLOB_DESC_MEMBER,TYPE_EXCEPTION,"6002",
               "Invalid data type for a member of a %s.")
#endif
#  if defined(JSE_SELIB_DYNAMICLINK) || defined(JSE_OS2_PMDYNAMICLINK)
      TL_RESOURCE(textlibDYNA_CANNOT_LOAD_MODULE,SYSTEM_EXCEPTION,"6003",
                  "Cannot load %s \"%s\" Error code: %d.")
      TL_RESOURCE(textlibDYNA_CANNOT_FIND_NAMED_SYM,SYSTEM_EXCEPTION,"6004",
                  "Cannot find %s \"%s\" in %s \"%s\"; Error code: %d.")
      TL_RESOURCE(textlibDYNA_CANNOT_FIND_ORDINAL_SYM,SYSTEM_EXCEPTION,"6005",
                  "Cannot find %s %d in %s \"%s\"; Error code: %d.")
      TL_RESOURCE(textlibDYNA_INVALID_BIT_SIZE,SYSTEM_EXCEPTION,"6006",
                  "Invalid bit size for dynamic link call, must be BIT16 or BIT32.")
#     if defined(__JSE_WIN16__)
         TL_RESOURCE(textlibDYNA_INVALID_DYNA_RETURN_TYPE,SYSTEM_EXCEPTION,"6007",
                     "Invalid return type for dynamic link call.")
#     endif
      TL_RESOURCE(textlibDYNA_INVALID_CALLING_CONVENTION,SYSTEM_EXCEPTION,"6008",
                  "Invalid calling convention for dynamic link call.")
      TL_RESOURCE(textlibDYNA_BAD_PARAMETER,SYSTEM_EXCEPTION,"6009",
                  "Bad parameter %d for dynamic link call")
#  endif
#  if defined(JSE_TOSOURCE_HELPER)
      TL_RESOURCE(textlibOBJECT_HAS_NO_TOSOURCE,TYPE_EXCEPTION,"6010",
                  "Object does not have a .toSource property")
      TL_RESOURCE(textlibERROR_IN_TOSOURCE,TYPE_EXCEPTION,"6011",
                  "Error calling .toSource property of object")
      TL_RESOURCE(textlibTOSOURCE_MUST_RETURN_OBJECT,TYPE_EXCEPTION,"6012",
                  ".toSource property must return an object")
#  endif

   /*** SElib ***/
#if defined(JSE_SELIB_SPAWN)
   TL_RESOURCE(textlibINVALID_SPAWN_MODE,SYNTAX_EXCEPTION,"6100",
               "Unrecognized spawn() mode %d.")
   TL_RESOURCE(textlibSPAWN_CANNOT_CONVERT_TO_STRING,TYPE_EXCEPTION,"6101",
               "Cannot convert the %d spawn parameter to a string.")
#endif
#if defined(JSE_SELIB_BLOB_GET)
   TL_RESOURCE(textlibBLOB_GET_INVALID_SIZE,TYPE_EXCEPTION,"6102",
               "The blob is not big enough to contain data; offset too low or size too big.")
#endif
#if defined(JSE_SELIB_INTERPRET)
   TL_RESOURCE(textlibNOT_TOKEN_BUFFER,TYPE_EXCEPTION,"6103",
               "This does not appear to be a compiled script")
   TL_RESOURCE(textlibCANNOT_READ_TOKEN_FILE,SOURCE_EXCEPTION,"6104",
               "Compiled scripts cannot be read from a file")
#endif
#if defined(JSE_SELIB_COMPILESCRIPT)
   TL_RESOURCE(textlibCOMPILE_SCRIPT_ERROR,SYNTAX_EXCEPTION,"6105","Error compiling script: %s")
#endif
   /*** Clib ***/
#if defined(JSE_CLIB_FREOPEN)  || \
    defined(JSE_CLIB_FOPEN)    || \
    defined(JSE_CLIB_FPRINTF)  || \
    defined(JSE_CLIB_FSCANF)   || \
    defined(JSE_CLIB_FPUTS)    || \
    defined(JSE_CLIB_FGETS)    || \
    defined(JSE_CLIB_VFPRINTF) || \
    defined(JSE_CLIB_FCLOSE)   || \
    defined(JSE_CLIB_FLOCK)    || \
    defined(JSE_CLIB_FSEEK)    || \
    defined(JSE_CLIB_FTELL)    || \
    defined(JSE_CLIB_FGETC)    || \
    defined(JSE_CLIB_UNGETC)   || \
    defined(JSE_CLIB_FPUTC)    || \
    defined(JSE_CLIB_VFSCANF)  || \
    defined(JSE_CLIB_TMPFILE)  || \
    defined(JSE_CLIB_FFLUSH)   || \
    defined(JSE_CLIB_FREAD)    || \
    defined(JSE_CLIB_FWRITE)   || \
    defined(JSE_CLIB_FGETPOS)  || \
    defined(JSE_CLIB_FSETPOS)  || \
    defined(JSE_CLIB_CLEARERROR)  || \
    defined(JSE_CLIB_REWIND)   || \
    defined(JSE_CLIB_FEOF)     || \
    defined(JSE_CLIB_FERROR)   || \
    defined(JSE_CLIB_PRINTF)   || \
    defined(JSE_CLIB_GETCH)    || \
    defined(JSE_CLIB_GETCHE)   || \
    defined(JSE_CLIB_KBHIT)    || \
    defined(JSE_CLIB_FPRINTF)  || \
    defined(JSE_CLIB_VPRINTF)  || \
    defined(JSE_CLIB_VFPRINTF) || \
    defined(JSE_CLIB_GETS)     || \
    defined(JSE_CLIB_GETCHAR)  || \
    defined(JSE_CLIB_PUTCHAR)  || \
    defined(JSE_CLIB_PERROR)
   TL_RESOURCE(textlibINVALID_FILE_VAR,TYPE_EXCEPTION,"6200","File variable is not valid")
#endif
#if   defined(JSE_CLIB_PRINTF)    || \
      defined(JSE_CLIB_FPRINTF)   || \
      defined(JSE_CLIB_VPRINTF)   || \
      defined(JSE_CLIB_SPRINTF)   || \
      defined(JSE_CLIB_VSPRINTF)  || \
      defined(JSE_CLIB_RVSPRINTF) || \
      defined(JSE_CLIB_SYSTEM)
   TL_RESOURCE(textlibUNKNOWN_FORMAT_SPECIFIER,SYNTAX_EXCEPTION,"6201",\
               "Unknown Format Type Specifier \"%c\" in ?printf string.")
   TL_RESOURCE(textlibZERO_WIDTH_IS_INVALID,SYNTAX_EXCEPTION,"6202","Zero width is invalid.")
   TL_RESOURCE(textlibSCANF_BRACKET_NOT_FOUND,SYNTAX_EXCEPTION,"6203",
               "\"]\" character not found in scanf format string.")
   TL_RESOURCE(textlibSCANF_TYPE_UNKNOWN,SYNTAX_EXCEPTION,"6204",
               "Unrecognized Type character \"%c\" in ?scanf format.")
#endif
#if   defined(JSE_CLIB_ASSERT)
   TL_RESOURCE(textlibASSERTION_FAILED,EXCEPTION_EXCEPTION,"6205","Assertion Failed:")
#endif
#  if defined(JSE_CLIB_VA_ARG)    || \
      defined(JSE_CLIB_VA_START)  || \
      defined(JSE_CLIB_VA_END)    || \
      defined(JSE_CLIB_PRINTF)    || \
      defined(JSE_CLIB_FPRINTF)   || \
      defined(JSE_CLIB_VPRINTF)   || \
      defined(JSE_CLIB_SPRINTF)   || \
      defined(JSE_CLIB_VSPRINTF)  || \
      defined(JSE_CLIB_RVSPRINTF) || \
      defined(JSE_CLIB_SYSTEM)    || \
      defined(JSE_CLIB_FSCANF)    || \
      defined(JSE_CLIB_VFSCANF)   || \
      defined(JSE_CLIB_SCANF)     || \
      defined(JSE_CLIB_VSCANF)    || \
      defined(JSE_CLIB_SSCANF)    || \
      defined(JSE_CLIB_VSSCANF)
   TL_RESOURCE(textlibINVALID_VA_LIST,TYPE_EXCEPTION,"6206","Invalid VA_LIST.")
   TL_RESOURCE(textlibVA_VAR_NOT_FOUND,TYPE_EXCEPTION,"6207","Variable not in va_xxx parameter list")
#endif
#if defined(JSE_CLIB_FSETPOS)
   TL_RESOURCE(textlibINVALID_FPOS_T,TYPE_EXCEPTION,"6208",
               "Invalid fpos_t structure to fsetpos().")
#endif
#if defined(JSE_CLIB_QSORT)
   TL_RESOURCE(textlibQSORT_MUST_RETURN_INTEGER,TYPE_EXCEPTION,"6209",
               "qsort compare function must return an integer.")
   TL_RESOURCE(textlibQSORT_ELEMENT_COUNT_TOO_BIG,TYPE_EXCEPTION,"6210",
               "qsort element count is bigger than array.")
#endif
#if defined(JSE_CLIB_MKTIME) || defined(JSE_CLIB_ASCTIME) || \
    defined(JSE_CLIB_GMTIME) || defined(JSE_CLIB_LOCALTIME) || \
    defined(JSE_CLIB_STRFTIME)
    TL_RESOURCE(textlibTM_ELEMENT_INVALID,TYPE_EXCEPTION,
                "6211","%s element of tm structure is invalid.")
    TL_RESOURCE(textlibTM_ELEMENT_INVALID_RANGE,TYPE_EXCEPTION,
                "6212","%s element of time object is out of range (%d - %d).")
    TL_RESOURCE(textlibTM_ELEMENT_INVALID_LOWER_RANGE,TYPE_EXCEPTION,
                "6213","%s element of time object is out of range ( > %d ).")
#endif
   /*** Ecma ***/
#if defined(JSE_BUFFER_ANY)
   TL_RESOURCE(textlibBAD_BUFFER_VARSIZE,TYPE_EXCEPTION,
               "6300","Bad variable size in buffer constructor.")
   TL_RESOURCE(textlibBAD_BUFFER_VARTYPE,TYPE_EXCEPTION,
               "6301","Bad variable type in buffer constructor.")
   TL_RESOURCE(textlibBAD_BUFFER_VARCOMBO,TYPE_EXCEPTION,
               "6302","Bad variable size / type combination in buffer constructor.")
   TL_RESOURCE(textlibBAD_BUFFER_OBJECT,TYPE_EXCEPTION,"6304",
               "Bad object passed to buffer constructor.")
#endif
#if defined(JSE_FUNCTION_ANY)
   TL_RESOURCE(textlibNO_CALL_PROPERTY,TYPE_EXCEPTION,
               "6305","Object has no _call property")
#endif
#if defined(JSE_STRING_OBJECT) || defined(JSE_NUMBER_OBJECT) || \
    defined(JSE_BOOLEAN_OBJECT) || defined(JSE_DATE_OBJECT)
   TL_RESOURCE(textlibTHIS_NOT_CORRECT_OBJECT,TYPE_EXCEPTION,
               "6306","'this' variable must be a %s object.")
#endif
   /* Error 6307 is used from within the core for Function.toSTRING(textlib) -
    * do not use.
    */
#if defined(JSE_ARRAY_ANY)
    TL_RESOURCE(textlibARRAY_LENGTH_OUT_OF_RANGE,ARRAYLENGTH_EXCEPTION,
                "6308","Array length parameter out of range or invalid.")
#endif

#if defined(JSE_REGEXP_OBJECT)
    TL_RESOURCE(textlibREGEXP_CANT_COMPILE,REGEXP_EXCEPTION,
                "6309","Can't compile regular expression: %s")
    TL_RESOURCE(textlibREGEXP_INVALID_OPTIONS,REGEXP_EXCEPTION,
                "6310","Invalid flags passed to RegExp constructor")
#endif
#if defined(JSE_ECMAMISC_EVAL)
    TL_RESOURCE(textlibCANNOT_EVALUATE_EXPRESSION,EXCEPTION_EXCEPTION,
                "6311","Could not evaluate expression.")
#endif
#if defined(JSE_NUMBER_TOFIXED) \
 || defined(JSE_NUMBER_TOEXPONENTIAL) \
 || defined(JSE_NUMBER_TOPRECISION)
    TL_RESOURCE(textlibPRECISION_OUT_OF_RANGE,EXCEPTION_EXCEPTION,
                "6313","Parameter is out of range or invalid.")
#endif
#if defined(JSE_STRING_SPLIT)    \
 || defined(JSE_STRING_SEARCH)   \
 || defined(JSE_STRING_REPLACE)  \
 || defined(JSE_STRING_MATCH)
    TL_RESOURCE(textlibNO_REGEXP,TYPE_EXCEPTION,
                "6315","RegExp constructor needed but not found or not a function.")
#endif
#if defined(JSE_ECMAMISC_ENCODEURI)
    TL_RESOURCE(textlibINVALID_URIENCODE_STRING,URI_EXCEPTION,
                "6316","Invalid character sequence found in URI string.")
#endif
#if defined(JSE_ECMAMISC_ENCODEURICOMPONENT)
    TL_RESOURCE(textlibINVALID_URIENCODECOMPONENT_STRING,URI_EXCEPTION,
                "6317","Invalid character sequence found in URI component string.")
#endif
#if defined(JSE_ECMAMISC_DECODEURI)
    TL_RESOURCE(textlibINVALID_URIDECODE_STRING,URI_EXCEPTION,
                "6318","Invalid encoded URI string.")
#endif
#if defined(JSE_ECMAMISC_DECODEURICOMPONENT)
    TL_RESOURCE(textlibINVALID_URIDECODECOMPONENT_STRING,URI_EXCEPTION,
                "6319","Invalid encoded URI component string.")
#endif


    /*** Lang ***/
#if defined(JSE_LANG_SETARRAYLENGTH)
   TL_RESOURCE(textlibBAD_MIN_ARRAY_SPAN,ARRAYLENGTH_EXCEPTION,"6400",
               "Array span Minimum index must be 0 or negative.")
#endif
   /*** Unix ***/
   /*** Win ***/
#  if defined(__JSE_WIN32__) || defined(__JSE_CON32__)
      TL_RESOURCE(textlibCANNOT_LOAD_MODULE,SYSTEM_EXCEPTION,"6600",
                  "Error %d loading dll module \"%s\".")
      TL_RESOURCE(textlibNO_THREAD_ID,SYSTEM_EXCEPTION,"6602",
                  "Couldn't get thread id for window.")
#  endif
#  if defined(__JSE_WIN16__) || defined(__JSE_WIN32__)
      TL_RESOURCE(textlibNOT_ENOUGH_TIMERS,SYSTEM_EXCEPTION,"6603",
                  "Not enough timer resources available for Suspend().")
#  endif
#  if defined(__JSE_WIN16__)
      TL_RESOURCE(textlibCANNOT_ALLOCATE_SELECTOR,SYSTEM_EXCEPTION,"6604",
                  "Cannot allocated selector.")
      TL_RESOURCE(textlibCANNOT_MYSPAWN,SYSTEM_EXCEPTION,"6605",
                  "Error starting task, check paths, filenames, and SEWINDOS.COM location.")
#  endif
   /*** Dos ***/
   /*** Mac ***/
   /*** OS2 ***/
#  if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
      TL_RESOURCE(textlibCANNOT_LOAD_MODULE,SYSTEM_EXCEPTION,"6900",
                  "Error %d loading dll module \"%s\".")
      TL_RESOURCE(textlibSOM_METHOD_NO_WORKY,SYSTEM_EXCEPTION,"6901",
                  "somMethod() doesn't work in this beta.  Sorry.")
      TL_RESOURCE(textlibDOSQPROCSTATUS_ERROR,SYSTEM_EXCEPTION,"6902",
                  "DosQProcStatus() error %d.")
#  endif
#  if defined(__JSE_OS2TEXT__)
      TL_RESOURCE(textlibCANNOT_START_CENVI2PM,SYSTEM_EXCEPTION,"6905",
                  "Error %d: Unable to start SEOS22PM.exe.")
      TL_RESOURCE(textlibCENVI2PM_SEMAPHORE_ERROR,SYSTEM_EXCEPTION,"6906",
                  "Error %d: Unable to communicate with SEOS22PM.exe.")
#  endif
   /*** NLM ***/
#  ifdef __JSE_NWNLM__
      TL_RESOURCE(textlibNETWARE_UNRECOGNIZED_CHAR_INI,SYSTEM_EXCEPTION,"7000",
                  ".ini Line %d: Unrecognized character in Netware initialization file - %c.\n")
      TL_RESOURCE(textlibNETWARE_MISSING_TYPE,SYSTEM_EXCEPTION,"7001",
                  ".ini Line %d: A variable's type must be specified.\n")
      TL_RESOURCE(textlibNETWARE_MISSING_IDENTIFIER,SYSTEM_EXCEPTION,"7002",
                  ".ini Line %d: Missing function name.\n")
      TL_RESOURCE(textlibNETWARE_MISSING_OPEN_PAREN,SYSTEM_EXCEPTION,"7003",
                  ".ini Line %d: Opening parenthesis expected.\n")
      TL_RESOURCE(textlibNETWARE_MISSING_CLOSE_PAREN,SYSTEM_EXCEPTION,"7004",
                  ".ini Line %d: Closing parenthesis expected.\n")
      TL_RESOURCE(textlibNETWARE_NO_VOID,SYSTEM_EXCEPTION,"7005",
                  ".ini Line %d: Argument type VOID not meaningful.\n")
      TL_RESOURCE(textlibNETWARE_TOO_MANY_ARGS,SYSTEM_EXCEPTION,"7006",
                  ".ini Line %d: Too many arguments.\n")
      TL_RESOURCE(textlibNETWARE_MISSING_SEMICOLON,SYSTEM_EXCEPTION,"7007",
                  ".ini Line %d: Missing semicolon.\n")
      TL_RESOURCE(textlibNETWARE_GARBAGE,SYSTEM_EXCEPTION,"7008",
                  ".ini Line %d: Garbage after legal declaration.\n")
      TL_RESOURCE(textlibNETWARE_BAD_INDIRECT,SYSTEM_EXCEPTION,"7009",
                  ".ini Line %d: Only integral types can be indirected.\n")
      TL_RESOURCE(textlibNETWARE_BADNAME,SYSTEM_EXCEPTION,"7010",
                  ".ini Line %d: Only 'SEDESKPATH = value' is supported.\n")
      TL_RESOURCE(textlibNETWARE_BADEQUAL,SYSTEM_EXCEPTION,"7011",
                  ".ini Line %d: Only 'SEDESKPATH = value' is supported.\n")
      TL_RESOURCE(textlibNETWARE_BAD_SYMBOL,SYSTEM_EXCEPTION,"7012",
                  "Unable to import Netware symbol \"%s\".")
      TL_RESOURCE(textlibNETWARE_UNKNOWN_IMPORT,SYSTEM_EXCEPTION,"7013",
                  "Function \"%s\" does not exist in Netware or any loaded NLM.")
      TL_RESOURCE(textlibNETWARE_STUCK_SYMBOL,SYSTEM_EXCEPTION,"7014",
                  "Unable to remove Netware symbol \"%s\".")
      TL_RESOURCE(textlibNETWARE_ON_CONSOLE,SYSTEM_EXCEPTION,"7016",
                  "Input is not allowed on Netware System Console.")
      TL_RESOURCE(textlibNETWARE_PANIC_CORRUPT,SYSTEM_EXCEPTION,"7017",
                  "PANIC! Netware dispatcher internal table corrupt!")
      TL_RESOURCE(textlibNETWARE_PANIC_UNKNOWN,SYSTEM_EXCEPTION,"7018",
                  "PANIC! Netware dispatcher called with non-Netware function!")
#  endif

#  ifdef JSE_MD5_ANY
      TL_RESOURCE(textlibMD5_NOT_VALID_HANDLE,EXCEPTION_EXCEPTION,"7100",
                  "First parameter is not a valid md5 handle")
#  endif
#  ifdef JSE_GD_ANY
      TL_RESOURCE(textlibGD_NOT_VALID_GD_OBJECT,TYPE_EXCEPTION,
                  "7101","Invalid GD object")
      TL_RESOURCE(textlibGD_BAD_POINT_SPEC,TYPE_EXCEPTION,
                  "7102","Bad point specification for parameter %d.")
      TL_RESOURCE(textlibGD_BAD_FONT_SPEC,TYPE_EXCEPTION,
                  "7103","Invalid GD font specification")
      TL_RESOURCE(textlibGD_BAD_COLOR_SPEC,TYPE_EXCEPTION,
                  "7104","Invalid color specification")
      TL_RESOURCE(textlibGD_BAD_STYLE,TYPE_EXCEPTION,
                  "7105","Unknown color style \"%s\"")
#  endif

#  ifdef JSE_DSP_ANY
      TL_RESOURCE(textlibDSP_UNEXPECTED_COMMAND,DSP_EXCEPTION,"7110",
                  "Unkown DSP command received from server")
      TL_RESOURCE(textlibDSP_INTERNAL_ERROR,DSP_EXCEPTION,"7111",
                  "Internal DSP error interpreting return script")
      TL_RESOURCE(textlibDSP_CANT_CONVERT_BACK,DSP_EXCEPTION,"7112",
                  "Cannot convert parameter %d back to source")
      TL_RESOURCE(textlibDSP_CANT_CONVERT_RETURN,DSP_EXCEPTION,"7113",
                  "Return value cannot be converted to source")
      TL_RESOURCE(textlibDSP_UNEXPECTED_RETURN,DSP_EXCEPTION,"7114",
                  "Unexpected DSP return command")
      TL_RESOURCE(textlibDSP_UNKNOWN_COMMAND,DSP_EXCEPTION,"7115",
                  "Unknown DSP command")
      TL_RESOURCE(textlibDSP_TRANSPORT_BAD_RETURN,DSP_EXCEPTION,"7116",
                  "%s function must return a number")
      TL_RESOURCE(textlibDSP_TRANSPORT_FAILED,DSP_EXCEPTION,"7117",
                  "%s function failed")
      TL_RESOURCE(textlibDSP_NO_TRANSPORT,DSP_EXCEPTION,"7118",
                  "DSP object does not have a %s property")
      TL_RESOURCE(textlibDSP_BUFFER_TOO_SMALL,DSP_EXCEPTION,"7119",
                  "Size of buffer is smaller than length read")
      TL_RESOURCE(textlibDSP_BAD_CONTENT_TYPE,DSP_EXCEPTION,"7120",
                  "Invalid DSP packet.  Only DSP/ScriptEase Content-type supported")
      TL_RESOURCE(textlibDSP_MISSING_CONTENT_LENGTH,DSP_EXCEPTION,"7121",
                  "Invalid DSP packet.  Missing Content-length")
      TL_RESOURCE(textlibDSP_MISSING_DSP_COMMAND,DSP_EXCEPTION,"7122",
                  "Invalid DSP packet. Missing DSP-command")
      TL_RESOURCE(textlibDSP_NOT_DSP_PACKET,DSP_EXCEPTION,"7123",
                  "Data does not appear to be a DSP packet")
      TL_RESOURCE(textlibDSP_MISSING_CONTENT_TYPE,DSP_EXCEPTION,"7124",
                  "Invalid DSP packet.  Missing Content-type")
      TL_RESOURCE(textlibDSP_CONNECTION_LOST,DSP_EXCEPTION,"7125",
                  "DSP connection lost")
#  endif

#  ifdef JSE_UUCODE_ANY
      TL_RESOURCE(textlibUUCODE_CANT_READ_FILE,SYSTEM_EXCEPTION,"7130",
                  "Unable to open file \"%s\" for reading")
      TL_RESOURCE(textlibUUCODE_CANT_WRITE_FILE,SYSTEM_EXCEPTION,"7131",
                  "Unable to open file \"%s\" for writing")
      TL_RESOURCE(textlibUUCODE_NO_BEGIN_LINE,SYSTEM_EXCEPTION,"7132",
                  "No 'begin' line found")
      TL_RESOURCE(textlibUUCODE_SHORT_FILE,SYSTEM_EXCEPTION,"7133",
                  "Unexpected end of file")
      TL_RESOURCE(textlibUUCODE_NO_END_LINE,SYSTEM_EXCEPTION,"7134",
                  "No 'end' line found")
#  endif

#  ifdef JSE_SOCKET_ANY
      TL_RESOURCE(textlibSOCKET_INVALID_OBJECT,TYPE_EXCEPTION,"7140",
                  "Invalid socket object")
      TL_RESOURCE(textlibSOCKET_INVALID_PARAMETER,TYPE_EXCEPTION,"7141",
                  "Invalid socket object as parameter %d")
      TL_RESOURCE(textlibSOCKET_INVALID_ARRAY,TYPE_EXCEPTION,"7142",
                  "Invalid array of sockets passed as parameter %d")
#  endif

#  ifdef JSE_TEST_ANY
      TL_RESOURCE(textlibTEST_START_CALLED,EXCEPTION_EXCEPTION,"7150",
                  "Test.start() was called more than once.")
      TL_RESOURCE(textlibTEST_END_CALLED,EXCEPTION_EXCEPTION,"7151",
                  "Test.end() was called more than once.")
      TL_RESOURCE(textlibTEST_ASSERT_FAILED,EXCEPTION_EXCEPTION,"7152",
                  "AssertFunction failed!.  Value was false (line# %u).")
      TL_RESOURCE(textlibTEST_ASSERTNUM_FAILED,EXCEPTION_EXCEPTION,"7153",
                  "NumEqualFunction: numbers (%s,%s) in (line %u) are not close enough.")
      TL_RESOURCE(textlibTEST_START_NEVER_CALLED,EXCEPTION_EXCEPTION,"7154",
                  "Test.start() never called.")
      TL_RESOURCE(textlibTEST_END_NEVER_CALLED,EXCEPTION_EXCEPTION,"7155",
                  "Test.end() never called.")
#  endif


#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      TL_RESOURCE(textlibNO_INSECURE_WITHOUT_SECURITY,SECURITY_EXCEPTION,"8002",
                  "No security file running. InSecurity() not valid.")
#  endif

#  ifndef NDEBUG
      TL_RESOURCE(textlibVARARGS_CTYPE_UNDEFINED,TYPE_EXCEPTION,"9203",
                  "CType %d is undefined.")
#  endif


#  if defined(_TEXTLIB_CPP)
      };

#  else
            TEXTLIB_ID_COUNT
         };
#  endif

   TL_TEXT_STRING(textlibPathEnvironmentVariable,"PATH")

#  if defined(JSE_BOOLEAN_TOSTRING)
      TL_TEXT_STRING(textlibstrEcmaFALSE,"false")
      TL_TEXT_STRING(textlibstrEcmaTRUE,"true")
#  endif

#  if defined(JSE_CLIB_ANY)
      TL_TEXT_STRING(textlibClib,"Clib")
#  endif
#  if defined(JSE_SELIB_ANY) || defined(CLI_SHELL)
      TL_TEXT_STRING(textlibSElib,"SElib")
#  endif
#  if defined(JSE_UNIX_ANY)
      TL_TEXT_STRING(textlibUnix,"Unix")
#  endif
#  if defined(JSE_DOS_ANY)
      TL_TEXT_STRING(textlibDos,"Dos")
#  endif
#  if defined(JSE_MAC_ANY)
      TL_TEXT_STRING(textlibMac,"Mac")
#  endif

#  if !defined(_TEXTLIB_CPP)

   const jsecharptr textlibGet(jseContext jsecontext,sint id);
      /* if jsecontext is NULL then no translation is possible, so
       * this will just return the default english string
       */

#  endif

#  ifdef __cplusplus
}
#  endif

#endif
