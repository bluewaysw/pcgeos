#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = os2
ASM_TO_OBJS     = os2Manager.asm
UI_TO_RDFS      =
SRCS            = os2Drive.asm os2HostFs.asm os2InitExit.asm os2Lfn.asm\
                  os2Manager.asm os2Strings.asm os2Utils.asm dosStrings.asm\
                  dosEntry.asm dosDisk.asm dosDrive.asm dosPath.asm\
                  dosEnum.asm dosFormat.asm dosFormatInit.asm\
                  dosDiskCopy.asm dosIO.asm dosPrimary.asm dosInitExit.asm\
                  dosCritical.asm dosUtils.asm dosVirtual.asm\
                  dosSuspend.asm dosLink.asm dosIdle.asm dosFileChange.asm\
                  dosConvert.asm dosCMapUS.asm dosCMapMulti.asm\
                  dosConvertSJIS.asm dosCMapSJIS.asm dosConvertJIS.asm\
                  dosConvertEUC.asm dosConvertGB.asm dosCMapGB.asm\
                  os2Interface.def os2Variable.def
OBJS            = os2Manager.obj
LOBJS           =
LIBNAME         = fsd
PROTOCONST      = FS

PRODUCTS        = DBCS GB SJISGB 

SYSMAKEFILE     = geode.mk

#include <geos.mk>
#include <gpath.mk>

#if exists(local.mk)
#include "local.mk"
#else
#include <$(SYSMAKEFILE)>
#endif

#if exists($(DEPFILE))
#include "$(DEPFILE)"
#endif

#if exists(DBCS/$(DEPFILE))
#include "DBCS/$(DEPFILE)"
#endif

#if exists(GB/$(DEPFILE))
#include "GB/$(DEPFILE)"
#endif

#if exists(SJISGB/$(DEPFILE))
#include "SJISGB/$(DEPFILE)"
#endif
