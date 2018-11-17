# $Id: local.mk,v 1.1 97/04/04 16:27:27 newdeal Exp $

#
# To allow the Printer module to support multiple types of printer
# devices (like faxes), ensure the following two lines are present.
# For Bullet, these two must be commented out.
#
UICFLAGS	+= -DMULTIPLE_PRINTER_DRIVER_TYPES
ASMFLAGS	+= -DMULTIPLE_PRINTER_DRIVER_TYPES
#
# Read/Write checking
#
#ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

.PATH.uih .PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common
.PATH.ui	: Art $(INSTALL_DIR)/Art
UICFLAGS	+= -I../Common -I$(INSTALL_DIR:H)/Common \
                    -IArt -I$(INSTALL_DIR)/Art -DPREFMGR

ASMFLAGS	+= -Wall

#if $(PRODUCT) == "NDO2000"
#else
#ASMFLAGS	+= -DGPC_ONLY
#UICFLAGS	+= -DGPC_ONLY
#LINKFLAGS	+= -DGPC_ONLY
#endif
#ASMFLAGS	+= -DGPC_VERSION
#UICFLAGS	+= -DGPC_VERSION
#LINKFLAGS	+= -DGPC_VERSION

UICFLAGS	+= -DPREFMGR
LINKFLAGS	+= -DPREFMGR

#include    <$(SYSMAKEFILE)>
