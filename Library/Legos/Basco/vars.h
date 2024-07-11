/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		vars.h

AUTHOR:		Roy Goldman, Dec 22, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/22/94		Initial version.

DESCRIPTION:
        Module which performs analysis of a module's variables,
	creating the appropriate tables and parse tree modifications
	to ensure maximum speed in variable lookup.

	$Id: vars.h,v 1.1 98/10/13 21:43:55 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _VARS_H_
#define _VARS_H_

#include <tree.h>
#include <Legos/opcode.h>
#include "vtab.h"
#include "bascoint.h"
#include "mystdapp.h"

#define DECLARATION_ROUTINE 0
#define NORMAL_ROUTINE  1

#define MAKE_VAR_KEY(vartype, index) ((dword) 65536*(vartype) + (index))
#define VAR_KEY_TYPE(key)   ( (word) ((key) >> 16))

/* VAR_KEY_ELEMENT does not give you the offset into a scope
 * use var_key_offset for that.
 */
#define VAR_SIZE 5
#define VAR_SIZE_NO_TYPE 4

#define VAR_KEY_ELEMENT(key)  ( (word) (key))
#define VAR_KEY_OFFSET(_key, _func) (VarGetOffset(task, _func, _key)/VAR_SIZE)


#define ARRAY_PRESERVE_NODE 0
#define ARRAY_IDENT_NODE 1
#define ARRAY_NUM_DIMS_NODE 2
#define ARRAY_DIMS_START_NODE 3

/* Analyze the current function.  Create appropriate global
   and local variable tables, and adjust variable references
   within the tree accordingly.

   if funcType == DECLARATIONS, then the function we are processing
   is special and actually works in the global scope.  All global
   declarations in the code should be gathered into functions
   of this type.

   if funcType == NORMAL then we do standard analysis.
*/

/* Converts data in IDENTIFIER nodes from string table ID to
 * scope/var# notation
 */
Boolean VarAnalyzeFunction(TaskPtr task, word funcNumber);

/* Use these routines to get at var info from a scope/var# token
 */
void	VarGetVTabEntry(TaskPtr task, word funcNum, dword key, VTabEntry* vte);
word	VarGetOffset(TaskPtr task, word funcNum, dword key);

#endif /* _VARS_H_ */
