#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Chart
AXIS            = axisAttrs.asm axisBuild.asm axisCategory.asm axisEC.asm\
                  axisFloat.asm axisGeometry.asm axisGrObj.asm\
                  axisLabels.asm axisManager.asm axisMisc.asm\
                  axisPosition.asm axisRange.asm axisRealize.asm\
                  axisSpider.asm axisTicks.asm axisUtils.asm axisValue.asm
CBODY           = cbodyComposite.asm cbodyCreate.asm cbodyGrObj.asm\
                  cbodyManager.asm cbodyNotify.asm cbodyRelocate.asm\
                  cbodySelect.asm cbodySuspend.asm cbodyTarget.asm\
                  cbodyTransfer.asm cbodyUI.asm
CCOMP           = ccompBuild.asm ccompComposite.asm ccompGeometry.asm\
                  ccompManager.asm ccompPosition.asm ccompRealize.asm\
                  ccompState.asm ccompUtils.asm
CGROBJ          = cgrobjManager.asm cgrobjRect.asm cgrobjSpline.asm
CGROUP          = cgroupAttrs.asm cgroupBuild.asm cgroupData.asm\
                  cgroupEC.asm cgroupGeometry.asm cgroupGrObj.asm\
                  cgroupManager.asm cgroupOrder.asm cgroupPosition.asm\
                  cgroupRealize.asm cgroupSelect.asm cgroupState.asm\
                  cgroupUtils.asm
COBJECT         = cobjectAttrs.asm cobjectBuild.asm cobjectDual.asm\
                  cobjectEC.asm cobjectEvent.asm cobjectGeometry.asm\
                  cobjectGrObj.asm cobjectManager.asm cobjectMultiple.asm\
                  cobjectNotify.asm cobjectPosition.asm cobjectRealize.asm\
                  cobjectState.asm cobjectUtils.asm
LEGEND          = legendAttrs.asm legendBuild.asm legendGeometry.asm\
                  legendItem.asm legendManager.asm legendPair.asm\
                  legendSelect.asm
MAIN            = mainCreate.asm mainDelete.asm mainManager.asm\
                  mainUpdate.asm
PAREA           = pareaBuild.asm pareaEC.asm pareaGeometry.asm\
                  pareaManager.asm pareaPosition.asm pareaRealize.asm
SERIES          = seriesArea.asm seriesColumn.asm seriesDual.asm\
                  seriesEC.asm seriesGroupRealize.asm seriesHighLow.asm\
                  seriesLegendRealize.asm seriesLine.asm seriesManager.asm\
                  seriesPie.asm seriesRealize.asm seriesScatter.asm\
                  seriesSpider.asm seriesUtils.asm
SGROUP          = sgroupBuild.asm sgroupEC.asm sgroupFind.asm\
                  sgroupGeometry.asm sgroupManager.asm sgroupRelocate.asm\
                  sgroupSelect.asm
TITLE           = titleBuild.asm titleGeometry.asm titleGrObj.asm\
                  titleManager.asm titleMessages.asm titleRealize.asm
UI              = uiAxis.asm uiControl.asm uiGrid.asm uiGroup.asm\
                  uiManager.asm uiType.asm strings.ui uiAxis.ui uiBody.ui\
                  uiGrid.ui uiGroup.ui uiManager.ui uiStrings.ui\
                  uiTemplate.ui uiType.ui
UTILS           = utilsEC.asm utilsFile.asm utilsFloat.asm utilsGrObj.asm\
                  utilsGroup.asm utilsManager.asm utilsObject.asm\
                  utilsStrings.asm utilsText.asm utilsTextObject.asm\
                  utilsUI.asm
UI_TO_RDFS      = UIMANAGER.UI
OBJS            =
COMMON          = axis.def ccomp.def cgrobj.def cgroup.def\
                  chartConstants.def chartGeode.def chartGlobal.def\
                  chartMacros.def cobject.def legend.def parea.def\
                  sarea.def series.def sgroup.def title.def
MODULES         = Axis CBody CComp CGrObj CGroup CObject Legend Main PArea\
                  Series SGroup Title UI Utils
CMODULES        =
SRCS            = $(AXIS) $(CBODY) $(CCOMP) $(CGROBJ) $(CGROUP) $(COBJECT)\
                  $(LEGEND) $(MAIN) $(PAREA) $(SERIES) $(SGROUP) $(TITLE)\
                  $(UI) $(UTILS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = chart

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
