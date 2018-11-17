##############################################################################
#
#       Copyright (c) 1998 New Deal, Inc. -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       New UI -- special definitions
# FILE:         local.mk
# AUTHOR:       Martin Turon, January 21, 1998
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       martin   1/21/98         Initial Revision
#
# DESCRIPTION:
#       Special definitions for new ui
#
#       $Id: local.mk,v 1.1 98/03/11 06:20:59 joon Exp $
#
###############################################################################

# search inside COMMENT blocks for tags
PCTAGSFLAGS     += -c
PROTOCONST      = SPUI

#
#       Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS        += -DNEWUI -wprivate -wunref -wunref_local
UICFLAGS        += -DNEWUI

#
# GPC additions
#  GPC: document control, etc. (contents not confirmed)
#  GPC_FS: file selector
#
ASMFLAGS	+= -DGPC -DGPC_FS 
UICFLAGS	+= -DGPC -DGPC_FS
#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_ONLY -DGPC_ART
UICFLAGS	+= -DGPC_ONLY -DGPC_ART
LINKFLAGS	+= -DGPC_ONLY
#endif

#include    <$(SYSMAKEFILE)>
