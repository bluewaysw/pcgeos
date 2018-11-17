##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	NewDesk
# FILE: 	local.mk
# AUTHOR: 	Chris Boyke
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CDB	7/10/92		Initial version 
#	martin	12/16/92	Added SMARTFOLDERS flag.
#
# DESCRIPTION:
#	Special definitions for NewDesk
#
#	$Id: local.mk,v 1.2 98/06/03 12:43:44 joon Exp $
#
###############################################################################

#
# NEWDESK - base desktop version
#
# CREATE_LINKS - local link creation functionality, doesn't use installable
# tool
#
# SMARTFOLDERS - save size and position of folder windows across open/close
# in directory information file
#
# GPC - GlobalPC extensions (see cdesktopGeode.def)
#
# LEFTCLICKDRAGDROP - use the left mouse button for drag & drop
#

ASMFLAGS	+= -DNEWDESK -DSMARTFOLDERS -DGPC
UICFLAGS	+= -DNEWDESK -DSMARTFOLDERS -DGPC
LINKFLAGS	+= -DGPC

#include    <$(SYSMAKEFILE)>
