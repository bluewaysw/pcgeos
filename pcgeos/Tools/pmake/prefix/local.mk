##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake/Prefix -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jul  4, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 4/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for prefix command/daemon
#
#	$Id: local.mk,v 1.7 91/07/12 17:20:26 adam Exp Locker: adam $
#
###############################################################################

.PATH.h		: ../src/customs $(INSTALL_DIR:H)/src/customs \
                  ../src/lib/lst $(INSTALL_DIR:H)/src/lib/lst \
                  ../src/lib/include $(INSTALL_DIR:H)/src/lib/include
.PATH.a		: ../lib/lst $(INSTALL_DIR:H)/lib/lst

LIBS		= -llst -lrpcsvc

CFLAGS		= -DEXPORTS=\"/etc/exports\"
DEST		= `set - $(.ALLSRC:H:S/.md//); echo /usr/etc.$1`

#include    <$(SYSMAKEFILE)>
