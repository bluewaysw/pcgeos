#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = js
ASMTOOLS        = asmtoolsManager.asm
SRCLIB          = seobject.c seregexp.c mathobj.c seliball.c regex.c\
                  sedate.c setxtlib.c seconvrt.c selibutl.c sebuffer.c\
                  fpemul.c seecma.c ecmamisc.c
SRCCORE         = library.c source.c secode.c varutil.c textcore.c\
                  expressn.c extlib.c token.c codeprt2.c call.c jsedll.c\
                  var.c jseengin.c brktest.c interprt.c garbage.c util.c\
                  jselib.c code.c function.c loclfunc.c analyze.c atexit.c\
                  security.c operator.c define.c statemnt.c
SRCMISC         = dbgprntf.c utilhuge.c jsemem.c dirparts.c memext.c\
                  seobjfun.c utilstr.c globldat.c malloc.h
UI_TO_RDFS      =
OBJS            = seobject.obj seregexp.obj mathobj.obj seliball.obj\
                  regex.obj sedate.obj setxtlib.obj seconvrt.obj\
                  selibutl.obj sebuffer.obj fpemul.obj seecma.obj\
                  ecmamisc.obj library.obj source.obj secode.obj\
                  varutil.obj textcore.obj expressn.obj extlib.obj\
                  token.obj codeprt2.obj call.obj jsedll.obj var.obj\
                  jseengin.obj brktest.obj interprt.obj garbage.obj\
                  util.obj jselib.obj code.obj function.obj loclfunc.obj\
                  analyze.obj atexit.obj security.obj operator.obj\
                  define.obj statemnt.obj dbgprntf.obj utilhuge.obj\
                  jsemem.obj dirparts.obj memext.obj seobjfun.obj\
                  utilstr.obj globldat.obj
COMMON          =
MODULES         = asmtools
CMODULES        = srclib srccore srcmisc
SRCS            = $(ASMTOOLS) $(SRCLIB) $(SRCCORE) $(SRCMISC) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = js

PRODUCTS        = DBCS 

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
