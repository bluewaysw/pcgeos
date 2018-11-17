/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:        GEOS
MODULE:         Standard C Library
FILE:           assert.h

AUTHOR:         Chris Ruppel

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------

DESCRIPTION:
        A wrapper implementing assert() in a GEOS-like fashion. This
        is mostly intended as a convenience for people who do not want
        to define their own more specific FatalError codes.

        $Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef __ASSERT_H
#define __ASSERT_H

#include <geos.h>
#include <ec.h>

#define assert(_cond) EC_ERROR_IF(!(_cond), -1)

#endif
