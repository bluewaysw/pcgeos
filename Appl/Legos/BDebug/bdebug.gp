##############################################################################

#

#	Copyright (c) Geoworks 1994 -- All Rights Reserved

#

# PROJECT:	Legos

# MODULE:	

# FILE:		

# AUTHOR:	Paul L. Du Bois

#

# REVISION HISTORY:

#	Name	Date		Description

#	----	----		-----------

#	dubois	 7/26/95	Initial Revision

#

# DESCRIPTION:

#	

#

#	$Id: bdebug.gp,v 1.1 97/12/02 14:55:53 gene Exp $

#	$Revision: 1.1 $

#

###############################################################################

name bdebug.app

longname "Legos Startup App"

tokenchars "LSAP"

tokenid 0

type    appl, process, single

class   BDProcessClass

appobj  BDApp



library geos

library ui



resource AppResource    object

resource Interface      object



stack   4096



export BDApplicationClass

