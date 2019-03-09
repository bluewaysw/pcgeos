##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Dec 27, 1989
#
# REVISION HISTORY:
#	Name	Date		Descriptionm
#	----	----		-----------
#	ardeb	12/27/89	Initial Revision
#
# DESCRIPTION:
#	Special definitions for tools library
#
#	$Id: local.mk,v 1.1 97/04/18 11:21:03 dbaumann Exp $
#
###############################################################################

TYPE		= library
#if defined(unix)
#pragma message ("ntcurses was designed to only be compiled for nt, not unix.")
#endif

#include    <$(SYSMAKEFILE)>
