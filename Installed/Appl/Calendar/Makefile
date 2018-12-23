#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = calendar
ALARM           = alarmReminder.asm alarmManager.asm alarmAlarm.asm
DAYEVENT        = dayeventManager.asm dayeventAlarm.asm\
                  dayeventSentToList.asm dayeventMisc.asm dayeventDraw.asm\
                  dayeventMain.asm
UI              = uiManager.asm uiStrings.ui uiDialog.ui uiMenu.ui\
                  uiManager.ui uiMain.ui
MAIN            = mainManager.asm mainEventsContent.asm mainApi.asm\
                  mainDatabase.asm mainApp.asm mainFile.asm\
                  mainConfirmDlg.asm mainUndo.asm mainMenu.asm mainCalc.asm\
                  mainAddressCtrl.asm mainUtils.asm mainVersitStrings.asm\
                  mainUpdateEvent.asm mainBookEvent.asm mainMailbox.asm\
                  mainRecvEvent.asm mainGeometry.asm mainCalendar.asm\
                  mainMailbox.def
YEAR            = yearYearMouse.asm yearYearMain.asm yearYearPrint.asm\
                  yearMonth.asm yearManager.asm
WEEK            = weekManager.asm weekScheduleContentClass.asm\
                  weekViewInteractionClass.asm weekDateTextContent.asm\
                  weekEventTextContentClass.asm
REPEAT          = repeatManager.asm repeatCreate.asm repeatDynamic.asm\
                  repeatUtils.asm repeatDatabase.asm repeatTable.asm\
                  repeatGenerate.asm
MISC            = miscPrint.asm miscSearch.asm miscMonthValue.asm\
                  miscCustomSpin.asm miscDateArrows.asm miscManager.asm
DAYPLAN         = dayplanBuffer.asm dayplanMailbox.asm dayplanInit.asm\
                  dayplanPreference.asm dayplanUtils.asm dayplanManager.asm\
                  dayplanApi.asm dayplanPrint.asm dayplanMain.asm\
                  dayplanRange.asm
HOLIDAY         = holidayFile.asm holidayManager.asm holidayUtils.asm\
                  holidaySetting.asm holidayData.asm
UI_TO_RDFS      = uiManager.ui
OBJS            =
COMMON          = calendarConstant.def calendarGlobal.def calendarMacro.def\
                  calendarGeode.def data.def
MODULES         = Alarm DayEvent UI Main Year Week Repeat Misc DayPlan\
                  Holiday
CMODULES        =
SRCS            = $(ALARM) $(DAYEVENT) $(UI) $(MAIN) $(YEAR) $(WEEK)\
                  $(REPEAT) $(MISC) $(DAYPLAN) $(HOLIDAY) $(COMMON)
LOBJS           =

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
