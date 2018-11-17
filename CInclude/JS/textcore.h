/* Textcore.h   All access to core text strings.
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

#ifdef _TEXTCORE_CPP
#  ifndef _TEXTCORE_H
#     error MUST INCLUDE TEXTCORE.H BEFORE DEFINING _TEXTCORE_CPP, \
            AND THEN AGAIN AFTER DEFINING _TEXTCORE_CPP
#  endif
#  undef _TEXTCORE_H
#endif

#ifndef _TEXTCORE_H
#define _TEXTCORE_H

#if defined(_TEXTCORE_CPP)
#  undef   TC_RESOURCE
#  if !defined(JSE_SHORT_RESOURCE) || (0==JSE_SHORT_RESOURCE)
#     define TC_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                     UNISTR(" ") UNISTR(SHORT) UNISTR(": ") \
                                                     UNISTR(DETAILS),
#  else
#     define TC_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                     UNISTR(" ") UNISTR(SHORT),
#  endif
   /* TC_LONG_RESOURCE is always long, even if JSE_SHORT_RESOURCE */
#  undef TC_LONG_RESOURCE
#  define TC_LONG_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) UNISTR("!") ERRORTYPE \
                                                       UNISTR(" ") UNISTR(SHORT) UNISTR(": ") \
                                                       UNISTR(DETAILS),
#  undef   TC_TEXT_STRING
#  define  TC_TEXT_STRING(ID,STRING) \
              CONST_STRING(ID,STRING);
#else
#  define  TC_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) ID,
#  define  TC_LONG_RESOURCE(ID,ERRORTYPE,SHORT,DETAILS) ID,
#  undef   TC_TEXT_STRING
#  define  TC_TEXT_STRING(ID,STRING) \
              extern CONST_DATA(jsecharptrdatum) ID[];
#endif



#if defined(_TEXTCORE_CPP)
  DEFINE_LARGE_STATIC_ARRAY('TC',jsecharptr,textcoreStrings,TEXTCORE_ID_COUNT)
  #if 1==JSE_INIT_STATIC_DATA
     UNISTR("Resource String Not Found."),
  #endif
#else
  DECLARE_LARGE_STATIC_ARRAY('TC',jsecharptr,textcoreStrings,TEXTCORE_ID_COUNT);
  enum textcoreID {
     RESOURCE_STRING_NOT_FOUND = 0,
#endif

#if !defined(_TEXTCORE_CPP) || 1==JSE_INIT_STATIC_DATA
/********* This is the basic concept behind the error number scheme. ********
 *
 *  0xxx:  Internal CENVI errors.
 *   00xx:  Finding source stuff.
 *   01xx:  Binding errors
 *
 *  1xxx:  Language errors
 *   10xx:  Preprocessor errors
 *   11xx:  Parsing errors
 *   12xx:  Parse error; missing a piece of a loop or something.
 *   13xx:  Misc parsing errors.
 *   14xx:  Function declaration stuff.
 *   15xx:  Expression evaluation errors
 *   16xx:  Data type errors
 *   17xx:  Math errors
 *
 *  2xxx: API errors
 *
 *  5xxx:  Library errors
 *   50xx:  Parameter types
 *   51xx:  Misc lib function errors
 *
 *  6xxx:  OS specific library error messages
 *   60xx:  Multi-os problems.
 *    609x:  Environment variable stuff.
 *   61xx:  NT
 *   62xx:  OS/2
 *   63xx:  Windows 3.1
 *   64xx:  DOS
 *   65xx:  Unix
 *
 *  7xxx:  CGI
 *
 *  8xxx:  Misc.
 *   81xx: Security
 *
 *  9xxx:  Debug version messages
 *   90xx:  Memory stuff
 *   91xx:  Unimplemented hooks
 *   92xx:  We're confused.
 *   99xx:  I haven't a clue what these mean
 *
 ***********************************************************************/

   TC_RESOURCE(textcoreSTACK_OVERFLOW, MEMORY_EXCEPTION, "0200",
               "ScriptEase internal stack exhausted.")
   TC_RESOURCE(textcoreOUT_OF_MEMORY, MEMORY_EXCEPTION, "0201",
               "Dynamic memory allocation failure.")
   TC_RESOURCE(textcoreSTRING_TOO_BIG, MEMORY_EXCEPTION, "0202",
               "String exceeds maximum size.")

   /* Internal ScriptEase errors. */
#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      TC_RESOURCE(textcoreUNABLE_TO_OPEN_SOURCE_FILE,SOURCE_EXCEPTION,"0001",
                  "Unable to open source file \"%s\" for reading.")
#  endif


   /* Problems with User's code */
#  if (JSE_COMPILER==1) \
   && ( (defined(JSE_DEFINE) && (0!=JSE_DEFINE)) \
     || (defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)) \
     || (defined(JSE_LINK) && (0!=JSE_LINK)) )
      TC_RESOURCE(textcoreUNRECOGNIZED_PREPROCESSOR_DIRECTIVE,SYNTAX_EXCEPTION,"1001",
                  "Unrecognized Preprocessor Directive \"%s\".")
#  endif

#  if (0!=JSE_COMPILER)
      TC_RESOURCE(textcoreNO_BEGIN_COMMENT,SYNTAX_EXCEPTION,"1002",
         "'*/' found without '/*'. probable error: comments don't nest.")
      TC_RESOURCE(textcoreEND_COMMENT_NOT_FOUND,SYNTAX_EXCEPTION,"1003",
         "End-comment (\"*/\") never found.")
#  endif

#  if (JSE_COMPILER==1) \
   && ( ( defined(JSE_INCLUDE) && (0!=JSE_INCLUDE) ) \
     || ( defined(JSE_LINK) && (0!=JSE_LINK) ) )
      TC_RESOURCE(textcoreMISSING_INCLINK_NAME_QUOTE,SYNTAX_EXCEPTION,"1005",
         "\"%c\" not found for #%s directive.")
#  endif

#  if defined(JSE_LINK) && (0!=JSE_LINK)
      TC_RESOURCE(textcoreLINK_LIBRARY_LOAD_FAILED, SOURCE_EXCEPTION, "1008",
         "External Link Library \"%s\" Failed to Load.")
      TC_RESOURCE(textcoreLINK_LIBRARY_NOT_EXISTS, SOURCE_EXCEPTION, "1009",
         "External Link Library \"%s\" Does Not Exist.")
      TC_RESOURCE(textcoreLINK_LIBRARY_FUNC_NOT_EXIST, SOURCE_EXCEPTION, "1010",
         "\"%s\" Is not a valid Extension Link Library.")
      TC_RESOURCE(textcoreLINK_LIBRARY_BAD_VERSION, SOURCE_EXCEPTION, "1011",
         "Incorrect Version (%d) of External Link Library \"%s\". %d is required.")
#  endif


#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      TC_RESOURCE(textcoreMUST_APPEAR_WITHIN_CONDITIONAL_COMPILATION,SYNTAX_EXCEPTION,"1013",
         "#%s must appear within conditional compilation (#if...)")
      TC_RESOURCE(textcoreENDIF_NOT_FOUND,SYNTAX_EXCEPTION,"1014","#endif not found")
#  endif

   TC_RESOURCE(textcoreCANNOT_PROCESS_BETWEEN_QUOTES,SYNTAX_EXCEPTION,"1107",
      "Invalid character data between <%c> characters.")
   TC_RESOURCE(textcoreNOT_LVALUE,TYPE_EXCEPTION,"1200",
      "can only assign to lvalues.")
   TC_RESOURCE(textcoreFUNC_OR_VAR_NOT_DECLARED,SYNTAX_EXCEPTION,"1212",
      "\"%s\" variable or function has not been declared.")
   TC_RESOURCE(textcoreBAD_DELETE_VAR,SYNTAX_EXCEPTION,"1217",
      "delete can only delete object members.")
   TC_RESOURCE(textcoreFUNCTION_BRACES,SYNTAX_EXCEPTION,"1400",
      "Function body must be enclosed in braces ('{' and '}').")
   TC_RESOURCE(textcoreFUNCTION_NAME_NOT_FOUND,SYNTAX_EXCEPTION,"1403",
      "Could not locate function \"%s\".")
   TC_RESOURCE(textcoreFUNCPARAM_NOT_PASSED,SYNTAX_EXCEPTION,"1404",
      "Expected parameter %d has not been passed to function \"%s\".")
   TC_RESOURCE(textcoreNOT_FUNCTION_VARIABLE,TYPE_EXCEPTION,"1406",
      "Variable %sis not a function type.")
   TC_RESOURCE(textcoreIS_NAN,MATH_EXCEPTION,"1519",
       "math operation failed due to NaN value or undefined variable.")
   TC_RESOURCE(textcorePROTOTYPE_LOOPS,SYNTAX_EXCEPTION,"1521",
      "prototypes chains cannot be circular.")
   TC_RESOURCE(textcoreINSTANCEOF_ONLY_FOR_FUNCTIONS,TYPE_EXCEPTION,"1522",
      "instanceof operator only valid for functions.")
   TC_RESOURCE(textcoreFUNCTION_BAD_PROTOTYPE_PROPERTY,TYPE_EXCEPTION,"1523",
      "Function has badly formed prototype property")
   TC_RESOURCE(textcoreIN_NEEDS_OBJECT,TYPE_EXCEPTION,"1524",
      "in operator requires right hand operand to be an object.")

   TC_RESOURCE(textcoreVAR_TYPE_UNKNOWN,TYPE_EXCEPTION,"1607","Variable \"%s\" is undefined.")
   TC_RESOURCE(textcoreDEFAULTVALUE_RETURN_PRIMITIVE,CONVERSION_EXCEPTION,
               "1613","%s property must return a primitive")
   TC_RESOURCE(textcoreNO_DEFAULT_VALUE,TYPE_EXCEPTION, "1614",
      "Object %sdoesn't have a valueOf() or toString() method, or these methods failed to return a primitive type.")
   TC_RESOURCE(textcoreCANNOT_CONVERT_OBJECT,TYPE_EXCEPTION,"1615",
      "Object failed to return a primitive from call to 'defaultvalue' method.")
   TC_RESOURCE(textcoreCANNOT_CONVERT_TO_OBJECT,CONVERSION_EXCEPTION,"1616",
      "Undefined and Null types cannot be converted to an object.")
   TC_RESOURCE(textcoreCANNOT_ADD_ARRAYS,MATH_EXCEPTION,"1701","Cannot add arrays.")
   TC_RESOURCE(textcoreCANNOT_DIVIDE_BY_ZERO,MATH_EXCEPTION,"1702","Cannot divide by zero.")
   TC_RESOURCE(textcoreCAN_ONLY_SUBTRACT_SAME_ARRAY,MATH_EXCEPTION,"1703",
      "Array differences only allowed for offsets into the same array.")
   TC_RESOURCE(textcoreINVALID_PARAMETER_COUNT,SYNTAX_EXCEPTION,"5001",
      "Invalid parameter count %d passed to function \"%s\".")

   /* This is really a library error, but it's used from within the core */
   TC_RESOURCE(textcoreTHIS_NOT_FUNCTION,TYPE_EXCEPTION,"6307",
               "'this' is not a Function")
    TC_RESOURCE(textcoreARRAY_LENGTH_OUT_OF_RANGE,ARRAYLENGTH_EXCEPTION,
                "6308","Array length parameter out of range or invalid.")

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      TC_RESOURCE(textcoreNO_APPROVAL_FROM_SECURITY_GUARD,SECURITY_EXCEPTION,"8100",
         "Security function did not approve call to function \"%s\".")
      TC_RESOURCE(textcoreNO_SECURITY_GUARD_FUNC,SECURITY_EXCEPTION,"8102",
         "No Security! %s() not available. Call not approved.")
      TC_RESOURCE(textcoreSECURITY_SET,SECURITY_EXCEPTION,"8103",
         "You may only set function security in the security initialization.")
      TC_RESOURCE(textcoreSECURITY_BAD,SECURITY_EXCEPTION,"8103",
         "Value is not a valid security option.")
#  endif

#  if ( 0 < JSE_API_ASSERTLEVEL )
      TC_RESOURCE(textcorePRINTERROR_FUNC_REQUIRED,INTERNAL_EXCEPTION,"2000",
         "PrintErrorFunc is required on jseExternalLinkparameters.")
#  endif
   TC_RESOURCE(textcoreVARNEEDED_PARAM_ERROR,TYPE_EXCEPTION,"5002",
       "Error with parameter%s %sin function \"%s\":\nType:%s. Expected:%s")
#  ifndef NDEBUG
      TC_RESOURCE(textcoreUNKNOWN_FUNCATTRIBUTE,INTERNAL_EXCEPTION,"9202",
         "FuncAttribute type %04X is unknown")
#  endif

#  if (0!=JSE_COMPILER) || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) )
#     if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
         TC_RESOURCE(textcoreNEWLINE_IN_REGEXP,SYNTAX_EXCEPTION,"1124",
                     "regular expression literal incomplete at end of line.")
         TC_RESOURCE(textcoreREGEXP_NOT_FOUND,SYNTAX_EXCEPTION,"1125",
                     "RegExp object not found to construct literal.")
#     endif
#  endif

#  if (0!=JSE_COMPILER)
      TC_RESOURCE(textcoreRESERVED_KEYWORD,SYNTAX_EXCEPTION,"1015",
         "Reserved keyword \"%s\" used as variable name")

      TC_RESOURCE(textcoreBAD_CHAR,SYNTAX_EXCEPTION,"1016",
         "Character code %x [%c] not recognized here.")

      TC_RESOURCE(textcoreTOKEN_MISSING,SYNTAX_EXCEPTION,"1101",
         "Unmatched %s \"%c\" in function \"%s\"; \"%c\" expected.")
      TC_RESOURCE(textcoreMISMATCHED_END_BRACE,SYNTAX_EXCEPTION,"1102",
         "Mismatched \"}\" in function \"%s\".")
      TC_RESOURCE(textcoreMISMATCHED_END_PAREN,SYNTAX_EXCEPTION,"1103",
         "No matching \"(\" for \")\" in function \"%s\".")
      TC_RESOURCE(textcoreMISMATCHED_END_BRACKET,SYNTAX_EXCEPTION,"1104",
         "No matching array \"[\" for \"]\" in function \"%s\".")
      TC_RESOURCE(textcoreNO_TERMINATING_QUOTE,SYNTAX_EXCEPTION,"1105",
         "No terminating <%c> for string %s.")
      TC_RESOURCE(textcoreEXPECT_COMMA_BETWEEN_ARRAY_INITS,SYNTAX_EXCEPTION,"1106",
         "Comma (,) expected between elements of array initialization.")
      TC_RESOURCE(textcoreMISPLACED_KEYWORD,SYNTAX_EXCEPTION,"1108","Misplaced keyword \"%s\".")

      TC_RESOURCE(textcoreMISSING_CLOSE_PAREN,SYNTAX_EXCEPTION,"1109","Expected ')' not found.")
      TC_RESOURCE(textcoreBAD_PRIMARY,SYNTAX_EXCEPTION,"1110",
         "Expecting to find an expression; possible cause is missing ';'.")
      TC_RESOURCE(textcoreMISSING_CLOSE_BRACKET,SYNTAX_EXCEPTION,"1111",
         "Expected ']' after array index not found.")
      TC_RESOURCE(textcoreBAD_BREAK,SYNTAX_EXCEPTION,"1112",
         "break and continue can only appear in switch, for, while, and do loops.")
      TC_RESOURCE(textcoreBAD_IF,SYNTAX_EXCEPTION,"1113",
         "if statement must meet the form: if ( <expression> ) statement;")
      TC_RESOURCE(textcoreBAD_WHILE,SYNTAX_EXCEPTION,"1114",
         "while statement must meet the form: while ( <expression> ) statement;")
      TC_RESOURCE(textcoreBAD_DO,SYNTAX_EXCEPTION,"1115",
         "do statement must meet the form: do statement while ( <expression> );")
      TC_RESOURCE(textcoreBAD_SWITCH,SYNTAX_EXCEPTION,"1116",
         "switch statement must meet the form: switch( <expression> ) { ... }")
      TC_RESOURCE(textcoreDUPLICATE_DEFAULT,SYNTAX_EXCEPTION,"1118",
         "switch statement has more than one default case.")
      TC_RESOURCE(textcoreSWITCH_NEEDS_CASE,SYNTAX_EXCEPTION,"1119",
         "first statement in a switch must be a case: or the default:")
      TC_RESOURCE(textcoreMISSING_PROPERTY_NAME,SYNTAX_EXCEPTION,"1121","Missing property name.")
      TC_RESOURCE(textcoreBAD_OBJECT_INITIALIZER,SYNTAX_EXCEPTION,"1122",
         "object initialization must be in the form: <identifier> : <expression>")
      TC_RESOURCE(textcoreEXPECT_COMMA_BETWEEN_OBJECT_INITS,SYNTAX_EXCEPTION,"1123",
         "comma expected between elements of object initialization")
      TC_RESOURCE(textcoreFUNCTION_NAME_MISSING,SYNTAX_EXCEPTION,"1126",
                  "Function keyword must be followed by an identifier.")
      TC_RESOURCE(textcoreCASE_STATEMENT_WITHOUT_VALUE,SYNTAX_EXCEPTION,"1201",
         "CASE statement without value in function \"%s\".")
      TC_RESOURCE(textcoreNO_MATCHING_CONDITIONAL_OR_CASE,SYNTAX_EXCEPTION,"1202",
         "No matching conditional \"?\" or CASE for \":\" in function \"%s\".")
      TC_RESOURCE(textcoreCONDITIONAL_MISSING_COLON,SYNTAX_EXCEPTION,"1203",
         "Conditional missing \":\".")
      TC_RESOURCE(textcoreBAD_FOR_STATEMENT,SYNTAX_EXCEPTION,"1205",
         "for statement must meet format \"for(init;test;increment) statement\".")
      TC_RESOURCE(textcoreSWITCH_NEEDS_BRACE,SYNTAX_EXCEPTION,"1207",
                  "\"{\" must follow switch statement.")

      TC_RESOURCE(textcoreBAD_FOR_IN_STATEMENT,SYNTAX_EXCEPTION,"1214",
         "for statement must meet format \"for( varname in object ) statement\".")
      TC_RESOURCE(textcoreBAD_WITH_STATEMENT,SYNTAX_EXCEPTION,"1215",
         "with statement must meet format \"with ( obj ) statement;\".")
      TC_RESOURCE(textcoreVAR_NEEDS_VARNAME,SYNTAX_EXCEPTION,"1216",
         "var statement requires a variable to be declared.")

      TC_RESOURCE(textcoreTRY_NEEDS_BLOCK,SYNTAX_EXCEPTION,"1219",
         "The 'try' statements must be inside { ... }.")
      TC_RESOURCE(textcoreTRY_NEEDS_SOMETHING,SYNTAX_EXCEPTION,"1220",
         "'try' statement needs catch clause or finally clause.")
      TC_RESOURCE(textcoreTRY_CATCH_PARAM,SYNTAX_EXCEPTION,"1221",
         "'try' catch clause needs one parameter.")
      TC_RESOURCE(textcoreTRY_CATCH_TWICE,SYNTAX_EXCEPTION,"1221",
         "Can only have one 'try' catch clause.")
      TC_RESOURCE(textcoreTHROW_NO_NEWLINE,SYNTAX_EXCEPTION,"1223",
	 "Throw expression must appear on the same line as the throw statement.")

      TC_RESOURCE(textcoreINVALID_PARAMETER_DECLARATION,SYNTAX_EXCEPTION,"1401",
         "Invalid parameter %d declaration for function: %s.")
      TC_RESOURCE(textcoreFUNCTION_IS_UNFINISHED,SYNTAX_EXCEPTION,"1402","Function %s is unfinished.")
      TC_RESOURCE(textcoreGOTO_LABEL_NOT_FOUND,SYNTAX_EXCEPTION,"1405",
         "Label \"%s\" not found to go to.")
      TC_RESOURCE(textcoreNOT_LOOP_LABEL,SYNTAX_EXCEPTION,"1407",
         "Label does not mark a looping statement.")

#     if (0==JSE_FLOATING_POINT)
         TC_RESOURCE(textcoreNO_FLOATING_POINT,INTERNAL_EXCEPTION,"2001",
           "Floating point numbers are not supported in this version.")
#     endif

#     if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
         TC_RESOURCE(textcoreNO_SECURITY_WHILE_COMPILING,SECURITY_EXCEPTION,"8103",
            "Insecure function not allowed during conditional compilation.")
#     endif


      TC_RESOURCE(textcoreUNMATCHED_CODE_CARD_PAIRS,INTERNAL_EXCEPTION,"9900",
         "Unmatched code card pairs in function \"%s\".")

#  endif

   /* The following are not error messages, but pseudo-strings that may
    * need to be translated for different locale
    */
   TC_LONG_RESOURCE(textcorePARAM_TYPE_UNDEFINED,UNISTR(""),"-0001","undefined")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_NULL,UNISTR(""),"-0002","null")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_BOOLEAN,UNISTR(""),"-0003","boolean")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_OBJECT,UNISTR(""),"-0004","object")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_STRING,UNISTR(""),"-0005","string")
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      TC_LONG_RESOURCE(textcorePARAM_TYPE_BUFFER,UNISTR(""),"-0006","buffer")
#  endif
   TC_LONG_RESOURCE(textcorePARAM_TYPE_NUMBER,UNISTR(""),"-0007","number")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_INT,UNISTR(""),"-0008", "integer")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_BYTE,UNISTR(""),"-0009", "byte")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_FUNCTION_OBJECT,UNISTR(""),"-0010","function object")
   TC_LONG_RESOURCE(textcorePARAM_TYPE_OR,UNISTR(""),"-0011"," or ")

#  if (0!=JSE_COMPILER)
      TC_LONG_RESOURCE(textcoreBLOCK_TOKEN_MISSING,UNISTR(""),"-0012","block")
      TC_LONG_RESOURCE(textcoreFUNCTION_CALL_TOKEN_MISSING,UNISTR(""),"-0013","function call")
      TC_LONG_RESOURCE(textcoreGROUPING_TOKEN_MISSING,UNISTR(""),"-0014","grouping")
      TC_LONG_RESOURCE(textcoreARRAY_TOKEN_MISSING,UNISTR(""),"-0015","array")
      TC_LONG_RESOURCE(textcoreCONDITIONAL_TOKEN_MISSING,UNISTR(""),"-0016","conditional")
#  endif

   TC_LONG_RESOURCE(textcoreInlineSourceCodePhonyFilename,UNISTR(""),"-0017","<inline source code>")

   TC_LONG_RESOURCE(textcoreUnknown,UNISTR(""),"-0018","unknown")
   TC_LONG_RESOURCE(textcoreErrorNear,UNISTR(""),"-0019","Error near")

#if defined(_TEXTCORE_CPP)
   };

#else
   TEXTCORE_ID_COUNT
   };
#endif

#endif /* defined(JSE_INIT_STATIC_DATA) */

/* initial (global) function name must start with root character that cannot
    * be part of a real function name so that it's easy to distinguish
    */
   TC_TEXT_STRING(textcoreInitializationFunctionName,":Global Initialization:")
#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
      TC_TEXT_STRING(textcoreIncludeDirective,"include")
#  endif
#  if (JSE_COMPILER==1) && (defined(JSE_LINK) && (0!=JSE_LINK))
      TC_TEXT_STRING(textcoreExtLinkDirective,"link")
#  endif
#  if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
      TC_TEXT_STRING(textcoreDefineDirective,"define")
#  endif

#ifdef __JSE_GEOS__

/* these are only used in the KeyWords table, so put them into that code
   resource */

#  if (0!=JSE_COMPILER) \
   || (defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING))
      #define textcoreDeleteKeyword "delete"
      #define textcoreTypeofKeyword "typeof"
      #define textcoreInstanceofKeyword "instanceof"
      #define textcoreVoidKeyword "void"
#  endif
#  if (0!=JSE_COMPILER)
      #define textcoreIfKeyword "if"
      #define textcoreElseKeyword "else"
      #define textcoreSwitchKeyword "switch"
      #define textcoreCaseKeyword "case"
      #define textcoreDefaultKeyword "default"
      #define textcoreWhileKeyword "while"
      #define textcoreDoKeyword "do"
      #define textcoreForKeyword "for"
      #define textcoreInKeyword "in"
      #define textcoreTryKeyword "try"
      #define textcoreThrowKeyword "throw"
      #define textcoreCatchKeyword "catch"
      #define textcoreFinallyKeyword "finally"
      #define textcoreWithKeyword "with"
      #define textcoreBreakKeyword "break"
      #define textcoreContinueKeyword "continue"
      #define textcoreGotoKeyword "goto"
      #define textcoreReturnKeyword "return"
      #define textcoreNewKeyword "new"
      #define textcoreVariableKeyword "var"

      /* reserved keywords */

      #define textcoreAbstractKeyword "abstract"
      #define textcoreBooleanKeyword "boolean"
      #define textcoreByteKeyword "byte"
      #define textcoreCharKeyword "char"
      #define textcoreClassKeyword "class"
      #define textcoreConstKeyword "const"
      #define textcoreDebuggerKeyword "debugger"
      #define textcoreDoubleKeyword "double"
      #define textcoreEnumKeyword "enum"
      #define textcoreExportKeyword "export"
      #define textcoreExtendsKeyword "extends"
      #define textcoreFinalKeyword "final"
      #define textcoreFloatKeyword "float"
      #define textcoreImplementsKeyword "implements"
      #define textcoreImportKeyword "import"
      #define textcoreIntKeyword "int"
      #define textcoreInterfaceKeyword "interface"
      #define textcoreLongKeyword "long"
      #define textcoreNativeKeyword "native"
      #define textcorePackageKeyword "package"
      #define textcorePrivateKeyword "private"
      #define textcoreProtectedKeyword "protected"
      #define textcorePublicKeyword "public"
      #define textcoreShortKeyword "short"
      #define textcoreStaticKeyword "static"
      #define textcoreSuperKeyword "super"
      #define textcoreSynchronizedKeyword "synchronized"
      #define textcoreThrowsKeyword "throws"
      #define textcoreTransientKeyword "transient"
      #define textcoreVolatileKeyword "volatile"

/* no change to this one, it is used elsewhere also */
#     if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
         TC_TEXT_STRING(textcoreCFunctionKeyword,"cfunction")
#     endif

#  endif

#else  /**** __JSE_GEOS__ *****/

#  if (0!=JSE_COMPILER) \
   || (defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING))
      TC_TEXT_STRING(textcoreDeleteKeyword, "delete")
      TC_TEXT_STRING(textcoreTypeofKeyword, "typeof")
      TC_TEXT_STRING(textcoreInstanceofKeyword, "instanceof")
      TC_TEXT_STRING(textcoreVoidKeyword, "void")
#  endif
#  if (0!=JSE_COMPILER)
      TC_TEXT_STRING(textcoreIfKeyword,"if")
      TC_TEXT_STRING(textcoreElseKeyword,"else")
      TC_TEXT_STRING(textcoreSwitchKeyword,"switch")
      TC_TEXT_STRING(textcoreCaseKeyword,"case")
      TC_TEXT_STRING(textcoreDefaultKeyword,"default")
      TC_TEXT_STRING(textcoreWhileKeyword,"while")
      TC_TEXT_STRING(textcoreDoKeyword,"do")
      TC_TEXT_STRING(textcoreForKeyword,"for")
      TC_TEXT_STRING(textcoreInKeyword, "in")
      TC_TEXT_STRING(textcoreTryKeyword, "try")
      TC_TEXT_STRING(textcoreThrowKeyword, "throw")
      TC_TEXT_STRING(textcoreCatchKeyword, "catch")
      TC_TEXT_STRING(textcoreFinallyKeyword, "finally")
      TC_TEXT_STRING(textcoreWithKeyword, "with")
      TC_TEXT_STRING(textcoreBreakKeyword,"break")
      TC_TEXT_STRING(textcoreContinueKeyword,"continue")
      TC_TEXT_STRING(textcoreGotoKeyword,"goto")
      TC_TEXT_STRING(textcoreReturnKeyword,"return")
      TC_TEXT_STRING(textcoreNewKeyword,"new")
      TC_TEXT_STRING(textcoreVariableKeyword,"var")

      /* reserved keywords */

      TC_TEXT_STRING(textcoreAbstractKeyword, "abstract")
      TC_TEXT_STRING(textcoreBooleanKeyword, "boolean")
      TC_TEXT_STRING(textcoreByteKeyword, "byte")
      TC_TEXT_STRING(textcoreCharKeyword, "char")
      TC_TEXT_STRING(textcoreClassKeyword, "class")
      TC_TEXT_STRING(textcoreConstKeyword, "const")
      TC_TEXT_STRING(textcoreDebuggerKeyword, "debugger")
      TC_TEXT_STRING(textcoreDoubleKeyword, "double")
      TC_TEXT_STRING(textcoreEnumKeyword, "enum")
      TC_TEXT_STRING(textcoreExportKeyword, "export")
      TC_TEXT_STRING(textcoreExtendsKeyword, "extends")
      TC_TEXT_STRING(textcoreFinalKeyword, "final")
      TC_TEXT_STRING(textcoreFloatKeyword, "float")
      TC_TEXT_STRING(textcoreImplementsKeyword, "implements")
      TC_TEXT_STRING(textcoreImportKeyword, "import")
      TC_TEXT_STRING(textcoreIntKeyword, "int")
      TC_TEXT_STRING(textcoreInterfaceKeyword, "interface")
      TC_TEXT_STRING(textcoreLongKeyword, "long")
      TC_TEXT_STRING(textcoreNativeKeyword, "native")
      TC_TEXT_STRING(textcorePackageKeyword, "package")
      TC_TEXT_STRING(textcorePrivateKeyword, "private")
      TC_TEXT_STRING(textcoreProtectedKeyword, "protected")
      TC_TEXT_STRING(textcorePublicKeyword, "public")
      TC_TEXT_STRING(textcoreShortKeyword, "short")
      TC_TEXT_STRING(textcoreStaticKeyword, "static")
      TC_TEXT_STRING(textcoreSuperKeyword, "super")
      TC_TEXT_STRING(textcoreSynchronizedKeyword, "synchronized")
      TC_TEXT_STRING(textcoreThrowsKeyword, "throws")
      TC_TEXT_STRING(textcoreTransientKeyword, "transient")
      TC_TEXT_STRING(textcoreVolatileKeyword, "volatile")

#     if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
         TC_TEXT_STRING(textcoreCFunctionKeyword,"cfunction")
#     endif

#  endif

#endif  /**** __JSE_GEOS ****/

   TC_TEXT_STRING(textcorevtype_bool_true,"true")
   TC_TEXT_STRING(textcorevtype_bool_false,"false")

   TC_TEXT_STRING(textcoreFunctionKeyword,"function")

   TC_TEXT_STRING(textcorevtype_undefined,"undefined")
   TC_TEXT_STRING(textcorevtype_null,"null")
   TC_TEXT_STRING(textcorevtype_object,"object")
   TC_TEXT_STRING(textcorevtype_Infinity,"Infinity")

   TC_TEXT_STRING(textcoreThisVariableName,"this")
   TC_TEXT_STRING(textcoreGlobalVariableName,"global")

   TC_TEXT_STRING(textcoreMainFunctionName,"main")
   TC_TEXT_STRING(textcore_ArgcName,"_argc")
   TC_TEXT_STRING(textcore_ArgvName,"_argv")

#if !defined(_TEXTCORE_CPP)

   const jsecharptr textcoreGet(struct Call *call,sint id);
      /* if call is NULL then no translation is possible */

#endif

#endif
