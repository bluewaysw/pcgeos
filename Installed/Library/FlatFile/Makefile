#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = flatfile
Database        = ffDExtrn.h ffDatabase.goc ffDatabaseCreate.goc\
                  ffDatabaseFieldOrder.goc ffDatabaseFields.goc\
                  ffDatabaseFloatController.goc ffDatabaseImpex.goc\
                  ffDatabaseLabels.goc ffDatabaseLayout.goc\
                  ffDatabaseMeta.goc ffDatabaseParse.goc\
                  ffDatabasePaste.goc ffDatabaseRCP.goc ffDatabaseSort.goc\
                  ffDatabaseSubset.goc ffDatabaseText.goc\
                  ffPageLayoutRect.goc
ExprBuilder     = ffExprBuilder.goc
FFManager       = ffmanagerManager.asm
FieldProperties = ffFieldEdges.goc ffFieldProperties.goc ffFpText.goc
GrObj           = ffGrObjBody.goc
Localization    = ffStrings.goc
RecordControl   = ffRCPValue.goc ffRecordControl.goc ffRecordControlUI.goc
TreasureChest   = ffTreasureChest.goc
UI_TO_RDFS      =
OBJS            = ffDatabase.obj ffDatabaseCreate.obj\
                  ffDatabaseFieldOrder.obj ffDatabaseFields.obj\
                  ffDatabaseFloatController.obj ffDatabaseImpex.obj\
                  ffDatabaseLabels.obj ffDatabaseLayout.obj\
                  ffDatabaseMeta.obj ffDatabaseParse.obj\
                  ffDatabasePaste.obj ffDatabaseRCP.obj ffDatabaseSort.obj\
                  ffDatabaseSubset.obj ffDatabaseText.obj\
                  ffPageLayoutRect.obj ffExprBuilder.obj ffFieldEdges.obj\
                  ffFieldProperties.obj ffFpText.obj ffGrObjBody.obj\
                  ffStrings.obj ffRCPValue.obj ffRecordControl.obj\
                  ffRecordControlUI.obj ffTreasureChest.obj
COMMON          = extern.h ffFatal.h
MODULES         = FFManager
CMODULES        = Database ExprBuilder FieldProperties GrObj Localization\
                  RecordControl TreasureChest
SRCS            = $(Database) $(ExprBuilder) $(FFManager)\
                  $(FieldProperties) $(GrObj) $(Localization)\
                  $(RecordControl) $(TreasureChest) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ffile

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
