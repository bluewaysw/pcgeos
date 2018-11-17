#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ijgjpeg
API             = JCAPIMIN.C JCAPISTD.C JCOMAPI.C JCPARAM.C JCTRANS.C\
                  JDAPIMIN.C JDAPISTD.C JDTRANS.C
ASMTOOLS        = asmtoolsManager.asm
COMP            = JCCOEFCT.C JCCOLOR.C JCDCTMGR.C JCHUFF.C JCINIT.C\
                  JCMAINCT.C JCMARKER.C JCMASTER.C JCPHUFF.C JCPREPCT.C\
                  JCSAMPLE.C JDATADST.C JFDCTFLT.C JFDCTFST.C JFDCTINT.C\
                  JIDCTFLT.C
DECOMP          = JDATASRC.C JDCOEFCT.C JDCOLOR.C JDDCTMGR.C JDHUFF.C\
                  JDINPUT.C JDMAINCT.C JDMARKER.C JDMASTER.C JDMERGE.C\
                  JDPHUFF.C JDPOSTCT.C JDSAMPLE.C JIDCTFLT.C JIDCTFST.C\
                  JIDCTINT.C JIDCTRED.C JQUANT1.C JQUANT2.C
SUPPT           = JERROR.C JMEMGEOS.C JMEMMGR.C JUTILS.C
UI_TO_RDFS      =
OBJS            = JCAPIMIN.obj JCAPISTD.obj JCOMAPI.obj JCPARAM.obj\
                  JCTRANS.obj JDAPIMIN.obj JDAPISTD.obj JDTRANS.obj\
                  JCCOEFCT.obj JCCOLOR.obj JCDCTMGR.obj JCHUFF.obj\
                  JCINIT.obj JCMAINCT.obj JCMARKER.obj JCMASTER.obj\
                  JCPHUFF.obj JCPREPCT.obj JCSAMPLE.obj JDATADST.obj\
                  JFDCTFLT.obj JFDCTFST.obj JFDCTINT.obj JIDCTFLT.obj\
                  JDATASRC.obj JDCOEFCT.obj JDCOLOR.obj JDDCTMGR.obj\
                  JDHUFF.obj JDINPUT.obj JDMAINCT.obj JDMARKER.obj\
                  JDMASTER.obj JDMERGE.obj JDPHUFF.obj JDPOSTCT.obj\
                  JDSAMPLE.obj JIDCTFLT.obj JIDCTFST.obj JIDCTINT.obj\
                  JIDCTRED.obj JQUANT1.obj JQUANT2.obj JERROR.obj\
                  JMEMGEOS.obj JMEMMGR.obj JUTILS.obj
COMMON          = JCHUFF.H JDCT.H JDHUFF.H JERROR.H JINCLUDE.H JMEMSYS.H\
                  JPEGINT.H JVERSION.H
MODULES         = ASMTOOLS
CMODULES        = API COMP DECOMP SUPPT
SRCS            = $(API) $(ASMTOOLS) $(COMP) $(DECOMP) $(SUPPT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ijgjpeg

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
