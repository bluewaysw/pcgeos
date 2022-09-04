##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	New UI -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 15, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for new ui
#
#	$Id: local.mk,v 1.6 96/05/01 04:28:23 joon Exp $
#
###############################################################################

# search inside COMMENT blocks for tags
PCTAGSFLAGS	+= -c

PROTOCONST	= SPUI

#
#	Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS	+= -DPM -DWIZARDBA -wprivate -wunref -wunref_local

UICFLAGS	+= -DPM -DWIZARDBA

#include    <$(SYSMAKEFILE)>
