/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           errors.h

AUTHOR:         Roy Goldman, Dec  9, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 9/94           Initial version.

DESCRIPTION:
	Swat errors for tree library

	$Id: errors.h,v 1.1 97/05/30 08:20:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _ERRORS_H_
#define _ERRORS_H_

#include <ec.h>

typedef enum {

    /* Your node has been allocated with too many children */
    TOO_MANY_CHILD_SLOTS,

    /* Illegal parameters to a library routine */
    ILLEGAL_PARAMETERS,

    /* Try to do useful operations on a NullNode */
    NULL_NODE,

    /* Try to reference a child which doesn't exist */
    BAD_CHILD_SPECIFIER,

    /* Integrity of children data has been undermined */
    CHILDREN_MESSED_UP,

    /* Illegal node reference */
    ILLEGAL_INDEX,

    /* Circular dependency in tree */
    CIRCULAR_DEPENDENCY,
} FatalErrors;

typedef enum {
    /* Give a warning when a single node in a tree
       is starting to get full */

    WARN_NODE_LARGER_THAN_6K
} Warnings;


#endif /* _ERRORS_H_ */
