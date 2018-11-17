##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Parse Library
# FILE:		parse.gp
#
# AUTHOR:	John Wedgwood,  1/16/91
#
#	$Id: parse.gp,v 1.1 97/04/05 01:27:22 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name parse.lib

library geos
library cell
library math
library ui

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Parse Library"
tokenchars	"PARS"
tokenid		0
#
# Define the library entry point
#
entry LibraryEntry

#
# Define resources other than standard discardable code
#
nosort
resource Init		 code read-only shared
resource Scanner		 code read-only shared
resource ParserCode		 code read-only shared
resource EvalCode		 code read-only shared
resource ParseMonikerCode		 code read-only shared
resource FormatCode		 code read-only shared
resource ParserErrorCode		 code read-only shared
resource C_Code		 code read-only shared
resource ErrorMessages	 lmem shared read-only
resource FunctionArgs	 lmem shared read-only
resource ECCode		code read-only shared
#
# Export routines
#
export	ParserParseString

export	ParserEvalExpression

export	ParserFormatExpression
export	ParserErrorMessage

export	ParserEvalPushArgument
export	ParserEvalPopNArgs
export	ParserEvalForeachArg

export	ParserEvalPushNumericConstant
export	ParserEvalPushNumericConstantWord
export	ParserEvalPushStringConstant
export	ParserEvalPushCellReference
export	ParserEvalPushRange

export	ParserEvalRangeIntersection

export	ParserAddDependencies
export	ParserAddSingleDependency
export	ParserRemoveDependencies
export	ParserForeachReferenceOLD
export	ParserForeachTokenOLD
export	ParserForeachPrecedent
export	ParserEvalPropagateEvalError

export	ParserFormatColumnReference
export	ParserFormatRowReference
export	ParserFormatWordConstant

export	ParserGetNumberOfFunctions
export	ParserGetFunctionMoniker

#
# exported C functions
#
export	PARSERGETNUMBEROFFUNCTIONS
export	PARSERGETFUNCTIONMONIKER
export	PARSERFORMATCOLUMNREFERENCE
export	PARSERPARSESTRING
export	PARSERFORMATEXPRESSION
export	PARSEREVALEXPRESSION

#
# Move when done
#
export	ParserFormatCellReference
export	ParserFormatRangeReference
export	ParserGetFunctionArgs
export	ParserGetFunctionDescription
export	PARSERGETFUNCTIONARGS
export	PARSERGETFUNCTIONDESCRIPTION

incminor
export	ParserLocalizeFormats

incminor
export	ParserForeachToken
export	ParserForeachReference

#
# XIP-enabled
#
