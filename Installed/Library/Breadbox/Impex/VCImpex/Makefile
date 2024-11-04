#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = vcimpex
CGM             = cgm.h cgm.goc cgmraw.goc
HPGL            = hpgl.goc
IMPTPROC        = imptproc.goc
VCIMPEX         = vcimpexManager.asm vcimpex_ui.goc
UI_TO_RDFS      =
OBJS            = cgm.obj cgmraw.obj hpgl.obj imptproc.obj vcimpex_ui.obj
COMMON          = VConvert.h vconv_ui.h
MODULES         = VCImpex
CMODULES        = CGM HPGL imptproc VCImpex
SRCS            = $(CGM) $(HPGL) $(IMPTPROC) $(VCIMPEX) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = vcimpex

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
