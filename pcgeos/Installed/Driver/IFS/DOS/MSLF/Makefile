#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = mslf
LIBNAME		= fsd
ASM_TO_OBJS     = mslfManager.asm
UI_TO_RDFS      =
SRCS            = mslfManager.asm mslfStrings.asm DOSSTRINGS.ASM\
                  DOSENTRY.ASM DOSDISK.ASM DOSDRIVE.ASM MSDRIVE.ASM\
                  DOSPATH.ASM DOSENUM.ASM DOSFORMAT.ASM DOSFORMATINIT.ASM\
                  DOSDISKCOPY.ASM DOSIO.ASM DOSPRIMARY.ASM DOSINITEXIT.ASM\
                  MSINITEXIT.ASM DOSCRITICAL.ASM DOSUTILS.ASM\
                  DOSVIRTUAL.ASM DOSWAITPOST.ASM MSSFT.ASM DOSSUSPEND.ASM\
                  DOSLINK.ASM DOSIDLE.ASM DOSFILECHANGE.ASM DOSCONVERT.ASM\
                  DOSCMAPUS.ASM DOSCMAPMULTI.ASM DOSCONVERTSJIS.ASM\
                  DOSCMAPSJIS.ASM DOSCONVERTJIS.ASM DOSCONVERTEUC.ASM\
                  mslfInterface.def
OBJS            = mslfManager.obj
LOBJS           =

PRODUCTS	= DBCS GB SJISGB

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
