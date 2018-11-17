/* sedate.c   Implements the ECMAScript date object
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#include "jseopt.h"
#if defined(__JSE_GEOS__)
#	include <timedate.h>
#       include <localize.h>
#endif

#ifdef JSE_DATE_ANY
#if !defined(JSE_DATE_OBJECT)
#  error must #define JSE_DATE_OBJECT 1 or #define JSE_DATE_ALL to use JSE_DATE_ANY
#endif

/* JSE_MILLENIUM - flag that if set (!=0) turns off any functionality that will represent
 *                 two-digite dates with the assumption that they're between 1900
 *                 and 1999 (inclusive).
 */
#if !defined(JSE_MILLENIUM)
#  define JSE_MILLENIUM 0  /* By default this flag is off for pure ECMASCRIPT behavior */
#endif

/* Prototypes to shut up compiler */
static long NEAR_CALL DaysInYear(long y);
static slong NEAR_CALL YearFromTime(jsenumber t);
static int NEAR_CALL InLeapYear(jsenumber t);
static int NEAR_CALL DayWithinYear(jsenumber t);
static int NEAR_CALL MonthFromTime(jsenumber t);
static int NEAR_CALL DateFromTime(jsenumber t);
static jsenumber NEAR_CALL millisec_from_gmtime(void);
static jsenumber NEAR_CALL DaylightSavingTA(jsenumber t);
static jsenumber NEAR_CALL MakeDay(jsenumber year,jsenumber month,jsenumber date);
static jsenumber NEAR_CALL MakeDate(jsenumber day,jsenumber time);
static jsebool NEAR_CALL IsFinite(jsenumber val);
static jsenumber NEAR_CALL msElapsedSince1970(void);
static jsenumber NEAR_CALL TimeWithinDay(jsenumber t);
static CONST_STRING(DATE_VALUE_PROPERTY,"_date_value_");
   /* don't use _value because date doesn't follow standard toprimitive rules */


/* All of these defines are used by the spec. I might optimize them later,
 * but using them this way means its more likely to be correct.
 */

/* if this is compiled with a redefined jsenumber then this initialization section
 * will need to be executed once.  otherwise all of these values are simply
 * defined with macros.
 */
#if !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR)
   /* All of these found in the docs */

#  define SecondsPerMinute 60.0
#  define MinutesPerHour 60.0
#  define HoursPerDay 24.0
#  define msPerSecond 1000.0

#  define msPerMinute ( msPerSecond * SecondsPerMinute )
#  define msPerHour ( msPerMinute * MinutesPerHour )
#  define msPerDay ( HoursPerDay * msPerHour )

#  define jseFP_fudge  ( 0.01 )
#  define jseFP_TimeClip ( 8.64e15 )

#else
   static VAR_DATA(jsebool)   jseFPinitialized = False;
   static VAR_DATA(jsenumber) SecondsPerMinute;
   static VAR_DATA(jsenumber) MinutesPerHour;
   static VAR_DATA(jsenumber) HoursPerDay;
   static VAR_DATA(jsenumber) msPerSecond;
   static VAR_DATA(jsenumber) msPerHour;
   static VAR_DATA(jsenumber) msPerMinute;
   static VAR_DATA(jsenumber) msPerDay;
   static VAR_DATA(jsenumber) jseFP_fudge;
   static VAR_DATA(jsenumber) jseFP_TimeClip;

   static void NEAR_CALL
initialize_jseFPdate()
{
   if ( jseFPinitialized ) return;
   jseFPinitialized = True;
   SecondsPerMinute = JSE_FP_CAST_FROM_SLONG(60);
   MinutesPerHour   = JSE_FP_CAST_FROM_SLONG(60);
   HoursPerDay      = JSE_FP_CAST_FROM_SLONG(24);
   msPerSecond      = JSE_FP_CAST_FROM_SLONG(1000);

   msPerMinute      = JSE_FP_MUL( msPerSecond , SecondsPerMinute );
   msPerHour        = JSE_FP_MUL( msPerMinute , MinutesPerHour );
   msPerDay         = JSE_FP_MUL( HoursPerDay , msPerHour );

   jseFP_fudge      = JSE_FP_DIV( jseOne , JSE_FP_CAST_FROM_SLONG(100) );
   jseFP_TimeClip   = JSE_FP_MUL(JSE_FP_CAST_FROM_SLONG(86400000L),\
                                 JSE_FP_CAST_FROM_SLONG(100000000L));
}
#endif


#  define Day(t) JSE_FP_FLOOR(JSE_FP_DIV(t,msPerDay))
/* Due to the problem caused by modulos of negative numbers,
 * this define will be changed to function call
 * #  define TimeWithinDay(t) fmod(t,msPerDay)
 */


/* Each platform needs a function to tell the current time, in milliseconds, since
 * jan 1 1970.  On most systems the underlying library can alread handle
 * this.  If all else fails then just use time()*msPerSecond
 */
#if defined(__FreeBSD__) || defined(__sgi__)
#define __DEFAULT_TIME_C_FUNCTION__
#endif
#if defined(__JSE_NWNLM__) || defined(__JSE_390__)
   /* for these systems, we don't yet know how to get milli-second accuracy */
#  define __DEFAULT_TIME_C_FUNCTION__
#endif
#if defined(__JSE_MAC__)
#  include <timer.h>
#elif defined(__JSE_UNIX__)
#  include <sys/timeb.h>
#elif defined(__DEFAULT_TIME_C_FUNCTION__)
   /* for systems without ftime */
#else
#  if !defined(__JSE_WINCE__) && !defined(__GEOS__)
#     include <sys/timeb.h>
#  endif /* !(__JSE_WINCE__) */
#endif


/* looking at the spec, it seems to think that modulos of negative numbers
 * result in positive numbers, but they do not - that is not how modulo works!
 */
   static int NEAR_CALL
HourFromTime(jsenumber t)
{
   /* spec says: HourFromTime(t) = floor(t / msPerHour) modulo HoursPerDay */
   jsenumber hourTotal, hour;

   assert( IsFinite(t) );
   hourTotal = JSE_FP_FLOOR(JSE_FP_DIV(JSE_FP_ADD(t,jseFP_fudge),msPerHour));
   hour = JSE_FP_FMOD(hourTotal,HoursPerDay);
   if ( JSE_FP_LT(hour,jseZero) )
   {
      JSE_FP_ADD_EQ(hour,HoursPerDay);
   }
   assert( JSE_FP_LTE(jseZero,hour) && JSE_FP_LT(hour,HoursPerDay) );
   return (int)JSE_FP_CAST_TO_SLONG(hour);
}

   static int NEAR_CALL
MinFromTime(jsenumber t)
{
   /* spec says: MinFromTime(t) = floor(t / msPerMinute) modulo MinutesPerHour */
   jsenumber minuteTotal, minute;

   assert( IsFinite(t) );
   minuteTotal = JSE_FP_FLOOR(JSE_FP_DIV(t,msPerMinute));
   minute = JSE_FP_FMOD(minuteTotal,MinutesPerHour);
   if ( JSE_FP_LT(minute,jseZero)  )
   {
      JSE_FP_ADD_EQ(minute,MinutesPerHour);
   }
   assert( JSE_FP_LTE(jseZero,minute) && JSE_FP_LT(minute,MinutesPerHour) );
   return (int)JSE_FP_CAST_TO_SLONG(minute);
}

   static int NEAR_CALL
SecFromTime(jsenumber t)
{
   /* spec says: SecFromTime(t) = floor(t / msPerSecond) modulo SecondsPerMinute */
   jsenumber secTotal, sec;

   assert( IsFinite(t) );
   secTotal = JSE_FP_FLOOR(JSE_FP_DIV(t,msPerSecond));
   sec = JSE_FP_FMOD(secTotal,SecondsPerMinute);
   if ( JSE_FP_LT(sec,jseZero) )
   {
      JSE_FP_ADD_EQ(sec,SecondsPerMinute);
   }
   assert( JSE_FP_LTE(jseZero,sec) && JSE_FP_LTE(sec,SecondsPerMinute) );
   return (int)JSE_FP_CAST_TO_SLONG(sec);
}

#if defined(JSE_DATE_GETMILLISECONDS) || defined(JSE_DATE_GETUTCMILLISECONDS) \
 || defined(JSE_DATE_SETMILLISECONDS) || defined(JSE_DATE_SETUTCMILLISECONDS) \
 || defined(JSE_DATE_SETSECONDS) || defined(JSE_DATE_SETUTCSECONDS) \
 || defined(JSE_DATE_SETMINUTES) || defined(JSE_DATE_SETUTCMINUTES) \
 || defined(JSE_DATE_SETHOURS) || defined(JSE_DATE_SETUTCHOURS)
   static slong NEAR_CALL
msFromTime(jsenumber t)
{
   /* spec says: msFromTime(t) = t modulo msPerSecond */
   jsenumber ms;

   assert( IsFinite(t) );
   ms = JSE_FP_FMOD(t,msPerSecond);
   if ( JSE_FP_LT(ms,jseZero) )
   {
      JSE_FP_ADD_EQ(ms,msPerSecond);
   }
   assert( JSE_FP_LTE(jseZero,ms) && JSE_FP_LT(ms,msPerSecond) );
   return JSE_FP_CAST_TO_SLONG(ms);
}
#endif

/* This is the 'builtin' date constructor. */
static jseLibFunc(BuiltinDateConstructor)
{
   jseReturnVar(jsecontext,CreateNewObject(jsecontext,DATE_PROPERTY),jseRetTempVar);
}

/* ---------------------------------------------------------------------- */

   static long NEAR_CALL
DaysInYear(long y)
{
   if((y%4)!=0 ) return 365;
   if((y%100)!=0 ) return 366;
   if((y%400)!=0 ) return 365;
   return 366;
}

   static jsenumber NEAR_CALL
DayFromYear(slong y)
{
   /* spec says: DayFromYear(y) = 365 * (y-1970)
    *                           + floor((y-1969)/4)
    *                           - floor((y-1901)/100)
    *                           + floor((y-1601)/400)
    */
   return JSE_FP_ADD(JSE_FP_SUB(JSE_FP_ADD(JSE_FP_CAST_FROM_SLONG(365*(y-1970)),\
          JSE_FP_FLOOR(JSE_FP_DIV(JSE_FP_CAST_FROM_SLONG(y-1969),JSE_FP_CAST_FROM_SLONG(4)))),\
          JSE_FP_FLOOR(JSE_FP_DIV(JSE_FP_CAST_FROM_SLONG(y-1901),JSE_FP_CAST_FROM_SLONG(100)))),\
          JSE_FP_FLOOR(JSE_FP_DIV(JSE_FP_CAST_FROM_SLONG(y-1601),JSE_FP_CAST_FROM_SLONG(400))));
}

#  define TimeFromYear(y) JSE_FP_MUL(msPerDay,DayFromYear(y))

   static slong NEAR_CALL
YearFromTime(jsenumber t)
{
   slong year;

   assert( IsFinite(t) );

   /* make a guess about the year, overguess then work back to real year */
   year = 1970 + JSE_FP_CAST_TO_SLONG(JSE_FP_DIV(t,JSE_FP_MUL(msPerDay,JSE_FP_CAST_FROM_SLONG(367))));
   if( !jseIsNegative(t) )
   {
      while ( JSE_FP_LTE(TimeFromYear(year),t) )
         ++year;
      --year;
   }
   else
   {
      while ( JSE_FP_LT(t,TimeFromYear(year)) )
         --year;
   }
   return year;
}

/* These next two must become functions because 'YearFromTime' is a function
 * call and cannot be successfully inserted into macros
 */
   static int NEAR_CALL
InLeapYear(jsenumber t)
{
   long year;
   assert( IsFinite(t) );
   year = YearFromTime(t);
   return (DaysInYear(year)==366) ? 1 : 0 ;
}

   static int NEAR_CALL
DayWithinYear(jsenumber t)
{
   long year;
   assert( IsFinite(t) );
   year = YearFromTime(t);
   return (int)JSE_FP_CAST_TO_SLONG(JSE_FP_SUB(Day(t),DayFromYear(year)));
}

   static int NEAR_CALL
MonthFromTime(jsenumber t)
{
   long i, i2;

   assert( IsFinite(t) );
   i = DayWithinYear(t);
   i2 = InLeapYear(t);
   if( i<31 ) return 0;
   if( i<59+i2 ) return 1;
   if( i<90+i2 ) return 2;
   if( i<120+i2 ) return 3;
   if( i<151+i2 ) return 4;
   if( i<181+i2 ) return 5;
   if( i<212+i2 ) return 6;
   if( i<243+i2 ) return 7;
   if( i<273+i2 ) return 8;
   if( i<304+i2 ) return 9;
   if( i<334+i2 ) return 10;
   return 11;
}

   static int NEAR_CALL
DateFromTime(jsenumber t)
{
   int i, d, m;

   assert( IsFinite(t) );
   d = DayWithinYear(t);
   m = MonthFromTime(t);
   i = InLeapYear(t);
   switch( m )
   {
      case 0: return d+1;
      case 1: return d-30;
      case 2: return d-58-i;
      case 3: return d-89-i;
      case 4: return d-119-i;
      case 5: return d-150-i;
      case 6: return d-180-i;
      case 7: return d-211-i;
      case 8: return d-242-i;
      case 9: return d-272-i;
      case 10: return d-303-i;
      case 11: return d-333-i;
   }

   /* Assertion means it should never get here and will trigger if it does. */
   assert( m>=0 && m<=11 );
   return 0;
}

   static int NEAR_CALL
WeekDay(jsenumber tm)
{
   int weekday;
   assert( IsFinite(tm) );
   weekday = (int)JSE_FP_CAST_TO_SLONG(JSE_FP_FMOD(JSE_FP_ADD(Day(tm),JSE_FP_CAST_FROM_SLONG(4)),JSE_FP_CAST_FROM_SLONG(7)));
   if ( weekday < 0 )
      weekday += 7;
   return weekday;
}

static CONST_DATA(int) days_in_month[12] =
{
   31,28,31,30,31,30,31,31,30,31,30,31
};

   static jsenumber NEAR_CALL
millisec_from_gmtime(void)
{
#if defined(__JSE_GEOS__)
    jsenumber t ;
    Boolean dst ;
    sword zone ;

    zone = LocalGetTimezone(&dst) ;
    t = JSE_FP_CAST_FROM_SLONG(zone) ;
    t = JSE_FP_DIV(t, JSE_FP_CAST_FROM_SLONG(60)) ;
    t = JSE_FP_MUL(t, msPerHour) ;

   return t ;
#else
   static VAR_DATA(jsebool) first_time = True;
   static VAR_DATA(jsenumber) diff;

   if( first_time )
   {

#     if defined(__JSE_WINCE__)

         SYSTEMTIME st,lt;
         jsenumber t_utc, t_local;
         jsenumber dayFromYear_l, dayWithinYear_l;
         int x;

         memset(&st,0,sizeof(st));
         memset(&lt,0,sizeof(lt));
         GetSystemTime(&st);
         GetLocalTime(&lt);

         t_utc = time(NULL) * msPerSecond + st.wMilliseconds;

         dayFromYear_l = DayFromYear( lt.wYear );
         dayWithinYear_l = 0 ;
         for( x = 0; x < (lt.wMonth-1); x++ )
         {
            dayWithinYear_l += days_in_month[x];
            if ( x==1 && DaysInYear(lt.wYear)==366 )
               dayWithinYear_l ++;
         }
         dayWithinYear_l += lt.wDay ;

         t_local = ((dayFromYear_l + dayWithinYear_l - 1) * msPerDay + lt.wHour * msPerHour
                           + lt.wMinute * msPerMinute + lt.wSecond * msPerSecond + lt.wMilliseconds);

         diff = t_local-t_utc ;
         JSE_FP_SUB_EQ(diff,JSE_FP_MUL(msPerSecond,JSE_FP_MUL(SecondsPerMinute,MinutesPerHour)));
#     else
      {
         /* Difference between time here and GMT.  This computation
          * can be a tad slow and doesn't change once computed,
          * so do it once and save the result
          */
         time_t ourtime, utctime;
         struct tm *ourtmstr;
         struct tm *utctmstr;
#        if (1==JSE_THREADSAFE_POSIX_CRTL)
            struct tm tm_buf1, tm_buf2;
#        endif

         time(&utctime);

#        if (1==JSE_THREADSAFE_POSIX_CRTL)
#        ifdef __hpux__
            ourtmstr = localtime_r(&utctime,&tm_buf1)?NULL:&tm_buf1;
#        else
            ourtmstr = localtime_r(&utctime,&tm_buf1);
#        endif
#        else
            ourtmstr = localtime(&utctime);
#        endif
#        if (1==JSE_THREADSAFE_POSIX_CRTL)
#        ifdef __hpux__
            utctmstr = gmtime_r(&utctime,&tm_buf2)?NULL:&tm_buf2;
#        else
            utctmstr = gmtime_r(&utctime,&tm_buf2);
#        endif
#        else
            utctmstr = gmtime(&utctime);
#        endif
         utctmstr->tm_isdst = -1; /* no DST for utc */
         ourtime = mktime(utctmstr);

         diff = JSE_FP_SUB(JSE_FP_CAST_FROM_SLONG(utctime),JSE_FP_CAST_FROM_SLONG(ourtime));
         /* localtime is adjusted for DST, so we unadjust it */
         if ( ourtmstr->tm_isdst )
            JSE_FP_SUB_EQ(diff,JSE_FP_MUL(SecondsPerMinute,MinutesPerHour));
         JSE_FP_MUL_EQ(diff,msPerSecond);
      }
#     endif
      first_time = False;
   }
   return diff;
#endif
}

   static jsenumber NEAR_CALL
DaylightSavingTA(jsenumber t)
{
#if defined(__JSE_GEOS__)
    return jseZero ;
#else
   /* pick a known 1990's year with monday falling on the same day as that year
    * and determine DST as if it were that 90's year
    */
   static CONST_DATA(uword8) March1Years[7] =
      /* years in 19th century with March 1 falling on sun, moon, tues, etc... */
      { 92, 93, 94, 95, 90, 91, 97 };
   int weekday;
   jsenumber March1Date;
   long year;
   struct tm buildTime, *st;
   time_t timeIn90s;
#  if (1==JSE_THREADSAFE_POSIX_CRTL)
      struct tm tm_buf;
#  endif

   assert( IsFinite(t) );
   year = YearFromTime(t);
   March1Date = MakeDate(MakeDay(JSE_FP_CAST_FROM_SLONG(year),JSE_FP_CAST_FROM_SLONG(2),jseOne),jseZero);
   assert( year == YearFromTime(March1Date) );

   weekday = WeekDay(March1Date);
   assert( 0 <= weekday  &&  weekday < 7 );

   buildTime.tm_sec = SecFromTime(t);
   buildTime.tm_min = MinFromTime(t);
   buildTime.tm_hour = HourFromTime(t);
   buildTime.tm_mday = DateFromTime(t);
   buildTime.tm_mon = MonthFromTime(t);
   buildTime.tm_year = March1Years[weekday];
   buildTime.tm_wday = 0;
   buildTime.tm_yday = 0;
   buildTime.tm_isdst = -1; /* let C library figure this out */
   timeIn90s = mktime(&buildTime);

#  if (1==JSE_THREADSAFE_POSIX_CRTL)
#  ifdef __hpux__
      st = localtime_r(&timeIn90s,&tm_buf)?NULL:&tm_buf;
#  else
      st = localtime_r(&timeIn90s,&tm_buf);
#  endif
#  else
      st = localtime(&timeIn90s);
#  endif
   assert( NULL != st);

#  if defined(__JSE_WINCE__)
      st->tm_isdst = SetDayLightSavingTime(st->tm_year,timeIn90s);
#  endif
   return ( st->tm_isdst ) ? msPerHour : jseZero ;
#endif
}

   static jsenumber NEAR_CALL
LocalTime(jsenumber t)
{
   return ( IsFinite(t) )
        ? JSE_FP_ADD(JSE_FP_ADD(t,millisec_from_gmtime()),DaylightSavingTA(t))
        : jseNaN ;
}

   static jsenumber NEAR_CALL
UTC(jsenumber t)
{
   return ( IsFinite(t) )
        ? JSE_FP_SUB(JSE_FP_SUB(t,millisec_from_gmtime()),DaylightSavingTA(JSE_FP_SUB(t,millisec_from_gmtime())))
        : jseNaN ;
}

static CONST_DATA(jsecharptr) monthnames[12] = {
   UNISTR("Jan"), UNISTR("Feb"), UNISTR("Mar"), UNISTR("Apr"),
   UNISTR("May"), UNISTR("Jun"), UNISTR("Jul"), UNISTR("Aug"),
   UNISTR("Sep"), UNISTR("Oct"), UNISTR("Nov"), UNISTR("Dec")
};

static CONST_DATA(jsecharptr) daynames[7] = {
   UNISTR("Sun"), UNISTR("Mon"), UNISTR("Tue"),
   UNISTR("Wed"), UNISTR("Thu"), UNISTR("Fri"), UNISTR("Sat")
};

#define MY_ASCTIME_BUFFER_SIZE 200
   static void
my_asctime(jsechar buffer[MY_ASCTIME_BUFFER_SIZE],jsenumber tm,jsebool ConvertToLocaltime)
{
   long dt;

   assert( IsFinite(tm) );
   if ( ConvertToLocaltime )
   {
      tm = LocalTime(tm);
   }
   dt = DateFromTime(tm);

   sprintf_jsechar((jsecharptr)buffer,UNISTR("%s %s %s%ld %02d:%02d:%02d %04d"),
           daynames[WeekDay(tm)],
           monthnames[MonthFromTime(tm)],
           dt<10?UNISTR(" "):UNISTR(""),dt,
           HourFromTime(tm),MinFromTime(tm),SecFromTime(tm),
           (int)YearFromTime(tm));
   if ( !ConvertToLocaltime )
      strcat_jsechar((jsecharptr)buffer,UNISTR(" GMT"));
   assert( bytestrsize_jsechar((jsecharptr)buffer) <= MY_ASCTIME_BUFFER_SIZE*sizeof(jsechar) );
}

/* ---------------------------------------------------------------------- */

/* all of these function are documented in the spec in section 15.9.x
 *
 * note: some of these functions do various casts from float->int->float.
 * this is needed to meet the spec.
 *
 * some utility functions to ease implementing as below
 */

/*
 * Determine if the input is finite. Infinite, -Infinite, or NaN are bad
 */
static jsebool NEAR_CALL IsFinite(jsenumber val)
{
   return jseIsFinite(val);
}

#if defined(JSE_DATE_SETDATE) || defined(JSE_DATE_SETUTCDATE) \
 || defined(JSE_DATE_SETMONTH) || defined(JSE_DATE_SETUTCMONTH) \
 || defined(JSE_DATE_SETFULLYEAR) || defined(JSE_DATE_SETUTCFULLYEAR) \
 || defined(JSE_DATE_SETYEAR)
   static jsenumber NEAR_CALL
TimeWithinDay(jsenumber t)
{
   jsenumber ret;
   assert( IsFinite(t) );
   ret = JSE_FP_FMOD(t,msPerDay);
   if ( jseIsNegative(ret) && !jseIsZero(ret) /* NYI qqq ret<0.0*/ )
   {
      assert( JSE_FP_LT(ret,jseZero) );
      JSE_FP_ADD_EQ(ret,msPerDay);
   }
   return ret;
}
#endif

static jsenumber NEAR_CALL MakeTime(jsenumber hour,jsenumber mins,jsenumber sec,jsenumber ms)
{
   return ( IsFinite(hour) && IsFinite(mins) && IsFinite(sec) && IsFinite(ms) )
        ? JSE_FP_ADD(JSE_FP_ADD(JSE_FP_ADD(JSE_FP_MUL(hour,msPerHour),\
                                           JSE_FP_MUL(mins,msPerMinute)),\
                                JSE_FP_MUL(sec,msPerSecond)),\
                     ms)
        : jseNaN ;
}

   static jsenumber NEAR_CALL
MakeDay(jsenumber year,jsenumber month,jsenumber date)
{
   long y,d,r5,r6;
   int x, m, a;
   jsenumber t;

   if( !IsFinite(year) || !IsFinite(month) ||
       !IsFinite(date))
      return jseNaN;

   y = JSE_FP_CAST_TO_SLONG(year);
   m = (int)JSE_FP_CAST_TO_SLONG(month);
   d = JSE_FP_CAST_TO_SLONG(date);

   r5 = y + m/12;
   r6 = m%12;

   t = TimeFromYear(r5);
   /* The following code was optimized to multiply after determining
      the total number of days. -dhunter 10/3/00 */
   for( x=0,a=0;x<r6;x++ )
   {
      a += days_in_month[x];
      if( x==1 && InLeapYear(t))
	  a++;
   }
   JSE_FP_ADD_EQ(t,JSE_FP_MUL(JSE_FP_CAST_FROM_SLONG(a),msPerDay));

   assert( YearFromTime(t)==r5 && MonthFromTime(t)==r6 && DateFromTime(t)==1 );

   return JSE_FP_SUB(JSE_FP_ADD(Day(t),JSE_FP_CAST_FROM_SLONG(d)),jseOne);
}

   static jsenumber NEAR_CALL
MakeDate(jsenumber day,jsenumber time)
{
   return ( IsFinite(day) && IsFinite(time) )
        ? JSE_FP_ADD(JSE_FP_MUL(day,msPerDay),time)
        : jseNaN ;
}

   static jsenumber NEAR_CALL
TimeClip(jsenumber time)
{
   jsebool isNeg;

   if ( !IsFinite(time) )
      return jseNaN;

   isNeg = jseIsNegative(time);
   if ( isNeg )
      time = JSE_FP_NEGATE(time);

   if ( JSE_FP_LT(jseFP_TimeClip,time) )
      return jseNaN;

   time = JSE_FP_FLOOR(time);
   if ( isNeg )
      time = JSE_FP_NEGATE(time);
   return time;
}

   static jsebool NEAR_CALL
ensure_valid_date(jseContext jsecontext,jseVariable what)
{
   return ensure_type(jsecontext,what,DATE_PROPERTY);
}
/* ---------------------------------------------------------------------- */

static CONST_DATA(jsecharptr) month_names[12] =
{
UNISTR("jan"), UNISTR("feb"), UNISTR("mar"), UNISTR("apr"), UNISTR("may"), UNISTR("jun"),
UNISTR("jul"), UNISTR("aug"), UNISTR("sep"), UNISTR("oct"), UNISTR("nov"), UNISTR("dec")
};

   static int NEAR_CALL
GetNumbersFromString(jsecharptr str,jsechar separator,int nums[3])
   /* retrieve numbers in string that may look like ##/##/## or ##:## or
    * differnt types of 2 or 3 sets of numbers.  As values are used
    * they are replaces with spaces so that these same numbers won't
    * be used elsewhere in parsing this string.  (This replacement
    * will be a problem if future MBCS versions use different sizes
    * for spaces and what they replace--this isn't likely and in any
    * case the assert() statements will catch that.
    * Return 0 for failure, else 2 or 3 if filled 2 or 3 of the numbers
    */
{
   int i;
   for ( i = 0; i < 3; i++ )
   {
      int num = 0;
      jsebool neg = False;
      jsechar c = JSECHARPTR_GETC(str);

      if ( '+' == c )
      {
         assert( sizeof_jsechar('+') == sizeof_jsechar(' ') );
         assert( sizeof_jsechar(' ') == sizeof(jsecharptrdatum) );
         *(jsecharptrdatum *)str = ' ';
         str = ((jsecharptrdatum *)str) + 1;
      }
      else if ( '-' == c )
      {
         assert( sizeof_jsechar('-') == sizeof_jsechar(' ') );
         assert( sizeof_jsechar(' ') == sizeof(jsecharptrdatum) );
         *(jsecharptrdatum *)str = ' ';
         str = ((jsecharptrdatum *)str) + 1;
         neg = True;
      }
      c=JSECHARPTR_GETC(str);
      if ( !isdigit_jsechar(c) )
         return 0;
      while ( isdigit_jsechar(c) )
      {
         num = (num*10) + (c - '0');
         assert( sizeof_jsechar(c) == sizeof_jsechar(' ') );
         assert( sizeof_jsechar(' ') == sizeof(jsecharptrdatum) );
         *(jsecharptrdatum *)str = ' ';
         str = ((jsecharptrdatum *)str) + 1;
         c=JSECHARPTR_GETC(str);
      }
      nums[i] = neg ? -num : num ;
      if ( c == separator )
      {
         /* bad to have separator even after third number */
         assert( sizeof_jsechar(separator) == sizeof_jsechar(' ') );
         assert( sizeof_jsechar(' ') == sizeof(jsecharptrdatum) );
         *(jsecharptrdatum *)str = ' ';
         str = ((jsecharptrdatum *)str) + 1;
         if ( i == 2 )
            return 0;
      }
      else
      {
         if ( i == 0 )
            /* error not to get separator after first number */
            return 0;
         if ( i == 1 )
         {
            /* no separator after second number, so 3rd is 0 */
            nums[2] = 0;
            i++;
            break;
         }
      }
   }
   return i;
}

   static jsenumber NEAR_CALL
do_parse(jseContext jsecontext,jseVariable string)
{
   jsenumber t;
   const jsecharptr str;
   jsecharptr DateBuf;
   jsecharptr colon;
   jsecharptr slash;
   jsecharptr cptr;
   jsechar c;
   jsebool ParseOK;
   int time[3]; /* hour, min, sec */
   int date[3]; /* month, day, year */
   int i;

   str = (const jsecharptr)jseGetString(jsecontext,string,NULL);

   t = jseNaN; /* assume failure */

   /* date comes in many formats.  Here we do our best of parsing in
    * the possible dates and figuring out from clues.
    */
   DateBuf = StrCpyMalloc(str);
   ParseOK = True;


   strlwr_jsechar(DateBuf);
   /* easiest bit to parse is time, which always has colons in it */
   colon = strchr_jsechar(DateBuf,':');
   if ( NULL == colon )
   {
      /* no time specified */
      time[0] = time[1] = time[2] = 0;
   }
   else
   {
      /* backup before colon */
      size_t colonOffset;

      assert( colon >= DateBuf );
      colonOffset = (size_t)JSECHARPTR_DIFF(colon,DateBuf);
      while ( colonOffset )
      {
         cptr = JSECHARPTR_OFFSET(DateBuf,colonOffset-1);
         c = JSECHARPTR_GETC(cptr);
         if ( IS_WHITESPACE(c) )
            break;
         colonOffset--;
      }
      colon = JSECHARPTR_OFFSET(DateBuf,colonOffset);

      if ( 2 <= GetNumbersFromString(colon,':',time) )
      {
         /* if there is a PM anywhere in string and <= 12 then adjust to PM */
         if ( time[0] < 12  &&  strstr_jsechar(DateBuf,UNISTR("pm")) )
            time[0] += 12;
      }
      else
      {
         ParseOK = False;
      }
   }

   if ( ParseOK )
   {
      ParseOK = False;
      /* try to find date in convenient m/d/y format */
      slash = strchr_jsechar(DateBuf,'/');
      date[2] = 0;
      if ( NULL != slash )
      {
         int slashmatch;

         /* backup before slash */
         size_t slashOffset;

         assert( slash >= DateBuf );
         slashOffset = (size_t)JSECHARPTR_DIFF(slash,DateBuf);
         while ( slashOffset )
         {
            cptr = JSECHARPTR_OFFSET(DateBuf,slashOffset-1);
            c = JSECHARPTR_GETC(cptr);
            if ( IS_WHITESPACE(c) )
               break;
            slashOffset--;
         }
         slash = JSECHARPTR_OFFSET(DateBuf,slashOffset);

         slashmatch = GetNumbersFromString(slash,'/',date);
         if ( 1 < slashmatch )
         {
            /* found convenient month/day/year format */
            date[0]--;
            if ( 2 == slashmatch )
            {
               /* year not found, make lastditch effort */
               goto LastDitchNumberSearch;
            }
            ParseOK = True;
         }
      }
      if ( !ParseOK )
      {
         /* look for names of month */
         for ( i = 0; i < 12; i++ )
         {
            if ( strstr_jsechar(DateBuf,(jsecharptr)month_names[i]) )
               break;
         }
         if ( i < 12 )
         {
            date[0] = i;
            date[1] = 0; /* indicate that not yet found */
            /* there must be two more numbers, one is date other
             * is year.  year is bigger
             */
            LastDitchNumberSearch:
            for ( cptr = DateBuf;
                  0!=(c=JSECHARPTR_GETC(cptr)) && (!date[1] || !date[2]);
                  JSECHARPTR_INC(cptr) )
            {
               int num;
               if ( isdigit_jsechar(c) )
               {
                  num = atoi_jsechar(cptr);

                  /* skip beyond all digits */
                  while ( isdigit_jsechar(c) )
                  {
                     JSECHARPTR_INC(cptr);
                     c = JSECHARPTR_GETC(cptr);
                  }

                  /* year is 70 or greater */
                  if ( num < 70 )
                     date[1] = num;
                  else
                     date[2] = num;

                  if ( 0 == c )
                     break;
               }
            }
            if ( date[1] && date[2] )
            {
               ParseOK = True;
            }
         }
      }

      if ( ParseOK )
      {
         const jsecharptr gmt;

#        if !JSE_MILLENIUM
            /* do silly 1900 addition */
            if ( 0 <= date[2]  &&  date[2] <= 99 )
               date[2] += 1900;
#        endif

         /* convert to ecmascript date */
         t = TimeClip(MakeDate(MakeDay(JSE_FP_CAST_FROM_SLONG(date[2]),\
                                       JSE_FP_CAST_FROM_SLONG(date[0]),\
                                       JSE_FP_CAST_FROM_SLONG(date[1])),
                               MakeTime(JSE_FP_CAST_FROM_SLONG(time[0]),\
                                        JSE_FP_CAST_FROM_SLONG(time[1]),\
                                        JSE_FP_CAST_FROM_SLONG(time[2]),jseZero)));

         gmt = strstr_jsechar(DateBuf,UNISTR("gmt"));
         if ( gmt == NULL )
         {
            /* convert to local time */
            t = UTC(t);
         }
         else
         {
            /* time is already GMT, but there may be numbers following that
             * to adjust from GMT
             */
            int adjust;
            jsenumber fadjust;
            adjust = atoi_jsechar(JSECHARPTR_OFFSET(gmt,3));
            if ( adjust )
            {
               /* adjust time number of hours and/or seconds */
               fadjust = JSE_FP_CAST_FROM_SLONG(adjust);
               if ( 100 < adjust )
               {
                  /* high part is hours, low part is minutes */
                  fadjust = JSE_FP_ADD(JSE_FP_DIV(fadjust,JSE_FP_CAST_FROM_SLONG(100)),\
                                       JSE_FP_DIV(JSE_FP_CAST_FROM_SLONG(adjust % 100),SecondsPerMinute));
               }
               /* adjust time by fadjust hours */
               JSE_FP_SUB_EQ(t,JSE_FP_MUL(fadjust,msPerHour));
            }
         }
      }
   }
   jseMustFree(DateBuf);

   return t;
}

/* ---------------------------------------------------------------------- */

#pragma codeseg SEDATE2_TEXT

   static jsenumber NEAR_CALL
msElapsedSince1970(void)
{
#if defined(__JSE_MAC__)
   /* macintosh does not support ftime */
#  ifdef __MWERKS__
      /* For metrowerks, time() returns seconds since 1900, so merely adjust by subtracting
       * 70 years from the time returned
       */
      UnsignedWide ms;
      jsenumber milliseconds;
      time_t t = time(NULL);
      Microseconds(&ms);

      milliseconds =  ( ((jsenumber)t * msPerSecond)
             + ((unsigned short)((ms.lo/1000) % 1000)) );
      return milliseconds - TimeFromYear(2040) - millisec_from_gmtime() - DaylightSavingTA(milliseconds);
#  else
      /* time() does not necessarily return seconds since 1970, so we create a timeval
       * representing January 1, 1970, and then do a difftime() to determine the difference
       * in seconds.  This is the most portable method.
       */
      struct tm tm1970;
      UnsignedWide   ms;
      time_t t1970, tNow;
      jsenumber seconds;
      jsenumber milliseconds;

      tm1970.tm_sec = 0;
      tm1970.tm_min = 0;
      tm1970.tm_hour = 0;
      tm1970.tm_mday = 1;
      tm1970.tm_mon = 0;
      tm1970.tm_year = 70;
      tm1970.tm_wday = 0;
      tm1970.tm_yday = 0;
      tm1970.tm_isdst = 0;
      /* Make the timeval */
      t1970 = mktime(&tm1970);
      tNow = time(NULL);  /* timeval for now */
      Microseconds(&ms);  /* Microseconds for now */
      /* Get the difference */
      seconds = difftime(tNow,t1970);
      /* Convert to milliseconds */
      milliseconds = ( (seconds * msPerSecond)
             + ((unsigned short)((ms.lo/1000) % 1000)) );
      /* mktime() used GMT time, so now we must SUBTRACT it to get the
       * local time
       */
      return milliseconds - millisec_from_gmtime() - DaylightSavingTA(milliseconds);
#  endif
#elif defined(__JSE_GEOS__)
    jsenumber a, b ;
    Boolean dst;
    sword zone ;

    /* Grab the local time and convert it to an internal date and time */
    TimerDateAndTime now;
    TimerGetDateAndTime(&now);
    zone = LocalGetTimezone(&dst) ;

    /* Convert internally to GMT timezone */
    LocalNormalizeDateTime(&now, &now, zone) ;
    a = MakeDay(
            JSE_FP_CAST_FROM_SLONG(now.TDAT_year), 
            JSE_FP_CAST_FROM_SLONG(now.TDAT_month-1), 
            JSE_FP_CAST_FROM_SLONG(now.TDAT_day)) ;
    b = MakeTime(
            JSE_FP_CAST_FROM_SLONG(now.TDAT_hours), 
            JSE_FP_CAST_FROM_SLONG(now.TDAT_minutes), 
            JSE_FP_CAST_FROM_SLONG(now.TDAT_seconds), 
            jseZero) ;
    a = JSE_FP_MUL(a, msPerDay) ;
    a = JSE_FP_ADD(a, b) ;
    if (!dst)
        a = JSE_FP_ADD(a, msPerHour) ;
    return a ;

#elif defined(__DEFAULT_TIME_C_FUNCTION__)
   /* a system without ftime() may use this version, but it will not return
    * millisecond accuracy.
    */
   time_t t = time(NULL);
   return ( ((jsenumber)t * msPerSecond) );
#elif defined(__JSE_WINCE__)
   SYSTEMTIME st;
   time_t t = time(NULL);
   jsenumber ms;

   memset(&st,0,sizeof(st));
   GetSystemTime(&st);

   ms = t * msPerSecond + st.wMilliseconds;

   return ms ;

#else
   struct timeb tb;
   ftime(&tb);
   return ( JSE_FP_ADD(JSE_FP_MUL(JSE_FP_CAST_FROM_SLONG(tb.time),msPerSecond),\
                       JSE_FP_CAST_FROM_SLONG(tb.millitm)) );
#endif
}

/* Old: was an ignoreParameters flag, new just pass # args as 0
 * instead of the real number.
 */
   static void NEAR_CALL
do_date_construction(jseContext jsecontext,jseVariable thisvar,
                     uint args,jseVariable *argv)
{
   jsenumber value;
   jseVariable da,tmp;

   if( args>1 )
   {
      /* all of these perform more or less the same way. The values that are */
      /* not included are all set to 0 (1 for date). */

      jsenumber years;
      jsenumber months;
      jsenumber date = jseOne;
      jsenumber hours = jseZero;
      jsenumber minutes = jseZero;
      jsenumber seconds = jseZero;
      jsenumber millis = jseZero;


      assert( args>=2 );

      years = jseGetNumberDatum(jsecontext,argv[0],NULL);
#     if !JSE_MILLENIUM
         if( !jseIsNegative(years) && JSE_FP_LTE(years,JSE_FP_CAST_FROM_SLONG(99)) )
            JSE_FP_ADD_EQ(years,JSE_FP_CAST_FROM_SLONG(1900));
#     endif
      months = jseGetNumberDatum(jsecontext,argv[1],NULL);

      if ( args>2 )
      {
         date = jseGetNumberDatum(jsecontext,argv[2],NULL);
      }
      if( args>3 )
      {
         hours = jseGetNumberDatum(jsecontext,argv[3],NULL);
      }
      if( args>4 )
      {
         minutes = jseGetNumberDatum(jsecontext,argv[4],NULL);
      }
      if( args>5 )
      {
         seconds = jseGetNumberDatum(jsecontext,argv[5],NULL);
      }

      if( args>6 )
      {
         millis = jseGetNumberDatum(jsecontext,argv[6],NULL);
      }

      value = TimeClip(UTC(MakeDate(MakeDay(years,months,date),
                                    MakeTime(hours,minutes,seconds,millis))));
   }

   else if( args==1 )
   {
      jseVariable cv = jseCreateConvertedVariable(jsecontext,argv[0],jseToPrimitive);

      if( cv == NULL  )
         return;

      /* We can call Ecma_Date_parse directly because in this case it takes
       * one parameter just like we do, the same type, and returns the result
       */
      if( jseGetType(jsecontext,cv)==jseTypeString )
      {
         value = do_parse(jsecontext,cv);
      }
      else
      {
         value = jseGetNumberDatum(jsecontext,cv,NULL);
      }
      jseDestroyVariable(jsecontext,cv);
   }
   else
   {
      assert( args == 0 );
      value = msElapsedSince1970();
   }

   jseConvert(jsecontext,thisvar,jseTypeObject);

   /* First assign our prototype to the prototype from the original date object */
   da = jseFindVariable(jsecontext,DATE_PROPERTY,0);
   if( da )
   {
      jseVariable pr = jseGetMember(jsecontext,da,ORIG_PROTOTYPE_PROPERTY);
      if( pr )
      {
         jseVariable me = MyjseMember(jsecontext,thisvar,PROTOTYPE_PROPERTY,jseTypeObject);
         jseAssign(jsecontext,me,pr);
         jseSetAttributes(jsecontext,me,jseDontEnum);
      }
   }

   /* next assign our class to DATE_PROPERTY */
   da = jseMember(jsecontext,thisvar,CLASS_PROPERTY,jseTypeString);
   jseConvert(jsecontext,da,jseTypeString);
   jsePutString(jsecontext,da,DATE_PROPERTY);
   jseSetAttributes(jsecontext,da,jseDontEnum);

   /* assign the value. */
   jsePutNumber(jsecontext,
                tmp = MyjseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber),
                value);
   jseSetAttributes(jsecontext,tmp,jseDontEnum);
}

static jseArgvLibFunc(DateConstruct)
{
   /* 'new' has already created the variable to work with as 'this' */
   do_date_construction(jsecontext,jseGetCurrentThisVariable(jsecontext),argc,argv);

   return NULL; /* Use the preconstructed object */
}

/* In this case, we construct a new variable */
static jseArgvLibFunc(DateCall)
{
   jseVariable newobj = jseCreateVariable(jsecontext,jseTypeObject);
   jseVariable strvar;

   UNUSED_PARAMETER(argc);

   do_date_construction(jsecontext,newobj,0,argv);

   /* return this variable as a string */
   strvar = jseCreateConvertedVariable(jsecontext,newobj,jseToString);
   assert( strvar != NULL );
   jseDestroyVariable(jsecontext,newobj);

   return strvar;
}

#if defined(JSE_DATE_FROMSYSTEM)
/* Date.fromSystem() */
static jseArgvLibFunc(Ecma_Date_fromSystem)
{
   jseVariable newobj = jseCreateVariable(jsecontext,jseTypeObject);
   jseVariable mem;
   time_t tSys;
   jsenumber t = jseZero;

   /* We have this explicit cast here because tSys could be unsigned, we don't know.
    * If we just did a jseGetNumber() as we used to, it could be negative, which would
    * have serious side effects
    */
   tSys = (time_t)JSE_FP_CAST_TO_SLONG(jseGetIntegerDatum(jsecontext,argv[0],NULL));
   JSE_FP_ADD_EQ(t,JSE_FP_CAST_FROM_SLONG(tSys));

   if ( IsFinite(t) )
      /* system date was in seconds, so convert ot milliseconds */
      JSE_FP_MUL_EQ(t,msPerSecond);

#if defined(__JSE_MAC__)
   {
#  ifdef __MWERKS__
      /* For metrowerks, time() returns seconds since 1900, so merely adjust by subtracting
       * 70 years from the time returned
       */
      t = t - TimeFromYear(2040) - millisec_from_gmtime() - DaylightSavingTA(t);
#  else
      /* time() does not necessarily return seconds since 1970, so we create a timeval
       * representing January 1, 1970, and then do a difftime() to determine the difference
       * in seconds.  This is the most portable method.
       */
      struct tm tm1970;
      UnsignedWide   ms;
      time_t t1970, tNow;
      jsenumber seconds;
      jsenumber milliseconds;

      tm1970.tm_sec = 0;
      tm1970.tm_min = 0;
      tm1970.tm_hour = 0;
      tm1970.tm_mday = 1;
      tm1970.tm_mon = 0;
      tm1970.tm_year = 70;
      tm1970.tm_wday = 0;
      tm1970.tm_yday = 0;
      tm1970.tm_isdst = 0;
      /* Make the timeval */
      t1970 = mktime(&tm1970);

      t = t - t1970 * msPerSecond - millisec_from_gmtime() - DaylightSavingTA(t);
#  endif
   }
#endif

   do_date_construction(jsecontext,newobj,argc,argv);
   mem = jseMember(jsecontext,newobj,DATE_VALUE_PROPERTY,jseTypeNumber);
   jsePutNumber(jsecontext,mem,t);

   return newobj;
}
#endif /* #if defined(JSE_DATE_FROMSYSTEM) */

#if defined(JSE_DATE_TOSYSTEM)
/* Date.toSystem() */
static jseArgvLibFunc(Ecma_Date_toSystem)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber units;

   UNUSED_PARAMETER(argc);
   UNUSED_PARAMETER(argv);

   if( !ensure_valid_date(jsecontext,thisvar) )
      return NULL;

   units = jseGetNumberDatum(jsecontext,thisvar,DATE_VALUE_PROPERTY);
   return jseCreateLongVariable(jsecontext,
                                (slong)JSE_FP_CAST_TO_SLONG(JSE_FP_DIV(units,msPerSecond)));
}
#endif /* #if defined(JSE_DATE_TOSYSTEM) */

#if defined(JSE_DATE_UTC)
static jseArgvLibFunc(Ecma_Date_UTC)
{
   /* all of these perform more or less the same way. The values that are
    * not included are all set to 0.
    */

   jsenumber years;
   jsenumber months;
   /* if date is not supplied, use 1. - ecma262 15.9.4.3 */
   jsenumber date = jseOne;
   jsenumber hours = jseZero;
   jsenumber minutes = jseZero;
   jsenumber seconds = jseZero;
   jsenumber millis = jseZero;

   assert( argc>=2 );

   years = jseGetNumberDatum(jsecontext,argv[0],NULL);
#  if !JSE_MILLENIUM
   if( !jseIsNegative(years) && JSE_FP_LTE(years,JSE_FP_CAST_FROM_SLONG(99)) )
      JSE_FP_ADD_EQ(years,JSE_FP_CAST_FROM_SLONG(1900));
#  endif
   months = jseGetNumberDatum(jsecontext,argv[1],NULL);

   if( argc>2 )
   {
      date = jseGetNumberDatum(jsecontext,argv[2],NULL);
   }
   if( argc>3 )
   {
      hours = jseGetNumberDatum(jsecontext,argv[3],NULL);
   }
   if( argc>4 )
   {
      minutes = jseGetNumberDatum(jsecontext,argv[4],NULL);
   }
   if( argc>5 )
   {
      seconds = jseGetNumberDatum(jsecontext,argv[5],NULL);
   }
   if( argc>6 )
   {
      millis = jseGetNumberDatum(jsecontext,argv[6],NULL);
   }

   return jseCreateNumberVariable(jsecontext,TimeClip(MakeDate(MakeDay(years,months,date),
                                                MakeTime(hours,minutes,seconds,millis))));
}
#endif

#if defined(JSE_DATE_PARSE)
static jseLibFunc(Ecma_Date_parse)
{
   /* This is how the spec demands it be done. */
   jseVariable string = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),
                                                   jseToString);

   jsenumber t;

   if( string == NULL )
      return;

   t = do_parse(jsecontext,string);

   if( !jseQuitFlagged(jsecontext) )
      jseReturnNumber(jsecontext,t);

   jseDestroyVariable(jsecontext,string);
}
#endif

static jseLibFunc(Ecma_Date_toString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber units;
   jsecharptr value;
   jseVariable ret;
   jsechar buffer[MY_ASCTIME_BUFFER_SIZE];

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   units = jseGetNumber(jsecontext,
                        jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));

   if( jseIsNaN(units) )
   {
      value = UNISTR("invalid date");
   }
   else
   {
      my_asctime(buffer,units,True);
      value = (jsecharptr)buffer;
   }

   ret = jseCreateVariable(jsecontext,jseTypeString);
   jsePutString(jsecontext,ret,value);
   jseReturnVar(jsecontext,ret,jseRetTempVar);
}

#if defined(JSE_DATE_TODATESTRING) || defined(JSE_DATE_TOLOCALEDATESTRING)
static jseLibFunc(Ecma_Date_toDateString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber units;
   jsecharptr value;
   jseVariable ret;
   jsechar buffer[MY_ASCTIME_BUFFER_SIZE];

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   units = jseGetNumber(jsecontext,
                        jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));

   if( jseIsNaN(units) )
      value = UNISTR("invalid date");
   else
   {
      long dt;

      units = LocalTime(units);
      dt = DateFromTime(units);

      sprintf_jsechar((jsecharptr)buffer,UNISTR("%s %ld, %04d"),
           monthnames[MonthFromTime(units)],dt,
           (int)YearFromTime(units));
      value = (jsecharptr)buffer;
   }

   ret = jseCreateVariable(jsecontext,jseTypeString);
   jsePutString(jsecontext,ret,value);
   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

#if defined(JSE_DATE_TOTIMESTRING) || defined(JSE_DATE_TOLOCALETIMESTRING)
static jseLibFunc(Ecma_Date_toTimeString)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber units;
   jsecharptr value;
   jseVariable ret;
   jsechar buffer[MY_ASCTIME_BUFFER_SIZE];

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   units = jseGetNumber(jsecontext,
                        jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));

   if( jseIsNaN(units) )
      value = UNISTR("invalid date");
   else
   {
      units = LocalTime(units);

      sprintf_jsechar((jsecharptr)buffer,UNISTR("%02d:%02d:%02d"),
                      HourFromTime(units),MinFromTime(units),SecFromTime(units));
      value = (jsecharptr)buffer;
   }

   ret = jseCreateVariable(jsecontext,jseTypeString);
   jsePutString(jsecontext,ret,value);
   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

static jseLibFunc(Ecma_Date_valueOf)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   jseReturnNumber(jsecontext,jseGetNumber(jsecontext,
                                jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber)));
}

static jseLibFunc(Ecma_Date_defaultValue)
{
   jseVariable hintVar = jseFuncVar(jsecontext,0);
   assert( NULL != hintVar );
   if ( jseTypeNumber == jseGetType(jsecontext,hintVar) )
   {
      Ecma_Date_valueOf(jsecontext);
   }
   else
   {
      /* default to string type if no hint */
      Ecma_Date_toString(jsecontext);
   }
}

#if defined(JSE_DATE_GETMILLISECONDS) || defined(JSE_DATE_GETUTCMILLISECONDS)
#  define GET_MILLI 1
#endif
#if defined(JSE_DATE_GETSECONDS) || defined(JSE_DATE_GETUTCSECONDS)
#  define GET_SEC   2
#endif
#if defined(JSE_DATE_GETMINUTES) || defined(JSE_DATE_GETUTCMINUTES)
#  define GET_MIN   3
#endif
#if defined(JSE_DATE_GETHOURS) || defined(JSE_DATE_GETUTCHOURS)
#  define GET_HOUR  4
#endif
#if defined(JSE_DATE_GETDATE) || defined(JSE_DATE_GETUTCDATE)
#  define GET_DATE  5
#endif
#if defined(JSE_DATE_GETDAY) || defined(JSE_DATE_GETUTCDAY)
#  define GET_DAY   6
#endif
#if defined(JSE_DATE_GETMONTH) || defined(JSE_DATE_GETUTCMONTH)
#  define GET_MONTH 7
#endif
#if defined(JSE_DATE_GETFULLYEAR) || defined(JSE_DATE_GETUTCFULLYEAR)
#  define GET_YEAR  8
#endif
#if defined(JSE_DATE_GETYEAR)
#  define GET_YEAR_1900   9
#endif

#if defined(GET_MILLI) \
 || defined(GET_SEC)   \
 || defined(GET_MIN)   \
 || defined(GET_HOUR)  \
 || defined(GET_DATE)  \
 || defined(GET_DAY)   \
 || defined(GET_MONTH) \
 || defined(GET_YEAR)  \
 || defined(GET_YEAR_1900)
   static void NEAR_CALL
DateGet(jseContext jsecontext,int WhichGet,jsebool Local)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber t;

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   t = jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));
   if( !jseIsNaN(t))
   {
      if ( Local )
      {
         t = LocalTime(t);
      }
      switch ( WhichGet )
      {
#        if defined(GET_MILLI)
         case GET_MILLI:
            t = JSE_FP_CAST_FROM_SLONG(msFromTime(t));
            break;
#        endif
#        if defined(GET_SEC)
         case GET_SEC:
            t = JSE_FP_CAST_FROM_SLONG(SecFromTime(t));
            break;
#        endif
#        if defined(GET_MIN)
         case GET_MIN:
            t = JSE_FP_CAST_FROM_SLONG(MinFromTime(t));
            break;
#        endif
#        if defined(GET_HOUR)
         case GET_HOUR:
            t = JSE_FP_CAST_FROM_SLONG(HourFromTime(t));
            break;
#        endif
#        if defined(GET_DATE)
         case GET_DATE:
            t = JSE_FP_CAST_FROM_SLONG(DateFromTime(t));
            break;
#        endif
#        if defined(GET_DAY)
         case GET_DAY:
            t = JSE_FP_CAST_FROM_SLONG(WeekDay(t));
            break;
#        endif
#        if defined(GET_MONTH)
         case GET_MONTH:
            t = JSE_FP_CAST_FROM_SLONG(MonthFromTime(t));
            break;
#        endif
#        if defined(GET_YEAR)
         case GET_YEAR:
            t = JSE_FP_CAST_FROM_SLONG(YearFromTime(t));
            break;
#        endif
#        if defined(GET_YEAR_1900)
         case GET_YEAR_1900:
            t = JSE_FP_CAST_FROM_SLONG(YearFromTime(t));
            /* This line is not according to the ECMAScript documentation.  ECMAScript
             * statest that we "Return YearFromTime(LocalTime(t)) - 1900".  Therefore,
             * this line has been commented out
             */
            /* if ( 1900 <= t  &&  t <= 1999 ) */
               JSE_FP_SUB_EQ(t,JSE_FP_CAST_FROM_SLONG(1900));
            break;
#        endif
      }
   }

   jseReturnNumber(jsecontext,t);
}
#endif

#if defined(JSE_DATE_GETYEAR)
#  if JSE_MILLENIUM
#     error JSE_DATE_GETYEAR should not be defined if #define JSE_MILLENIUM 1
#  endif
static jseLibFunc(Ecma_Date_getYear)
{
   DateGet(jsecontext,GET_YEAR_1900,True);
}
#endif

#if defined(JSE_DATE_GETFULLYEAR)
static jseLibFunc(Ecma_Date_getFullYear)
{
   DateGet(jsecontext,GET_YEAR,True);
}
#endif

#if defined(JSE_DATE_GETUTCFULLYEAR)
static jseLibFunc(Ecma_Date_getUTCFullYear)
{
   DateGet(jsecontext,GET_YEAR,False);
}
#endif

#if defined(JSE_DATE_GETMONTH)
static jseLibFunc(Ecma_Date_getMonth)
{
   DateGet(jsecontext,GET_MONTH,True);
}
#endif

#if defined(JSE_DATE_GETUTCMONTH)
static jseLibFunc(Ecma_Date_getUTCMonth)
{
   DateGet(jsecontext,GET_MONTH,False);
}
#endif

#if defined(JSE_DATE_GETDATE)
static jseLibFunc(Ecma_Date_getDate)
{
   DateGet(jsecontext,GET_DATE,True);
}
#endif

#if defined(JSE_DATE_GETUTCDATE)
static jseLibFunc(Ecma_Date_getUTCDate)
{
   DateGet(jsecontext,GET_DATE,False);
}
#endif

#if defined(JSE_DATE_GETDAY)
static jseLibFunc(Ecma_Date_getDay)
{
   DateGet(jsecontext,GET_DAY,True);
}
#endif

#if defined(JSE_DATE_GETUTCDAY)
static jseLibFunc(Ecma_Date_getUTCDay)
{
   DateGet(jsecontext,GET_DAY,False);
}
#endif

#if defined(JSE_DATE_GETHOURS)
static jseLibFunc(Ecma_Date_getHours)
{
   DateGet(jsecontext,GET_HOUR,True);
}
#endif

#if defined(JSE_DATE_GETUTCHOURS)
static jseLibFunc(Ecma_Date_getUTCHours)
{
   DateGet(jsecontext,GET_HOUR,False);
}
#endif

#if defined(JSE_DATE_GETMINUTES)
static jseLibFunc(Ecma_Date_getMinutes)
{
   DateGet(jsecontext,GET_MIN,True);
}
#endif

#if defined(JSE_DATE_GETUTCMINUTES)
static jseLibFunc(Ecma_Date_getUTCMinutes)
{
   DateGet(jsecontext,GET_MIN,False);
}
#endif

#if defined(JSE_DATE_GETSECONDS)
static jseLibFunc(Ecma_Date_getSeconds)
{
   DateGet(jsecontext,GET_SEC,True);
}
#endif

#if defined(JSE_DATE_GETUTCSECONDS)
static jseLibFunc(Ecma_Date_getUTCSeconds)
{
   DateGet(jsecontext,GET_SEC,False);
}
#endif

#if defined(JSE_DATE_GETMILLISECONDS)
static jseLibFunc(Ecma_Date_getMilliseconds)
{
   DateGet(jsecontext,GET_MILLI,True);
}
#endif

#if defined(JSE_DATE_GETUTCMILLISECONDS)
static jseLibFunc(Ecma_Date_getUTCMilliseconds)
{
   DateGet(jsecontext,GET_MILLI,False);
}
#endif

#if defined(JSE_DATE_GETTIMEZONEOFFSET)
static jseLibFunc(Ecma_Date_getTimezoneOffset)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber t;

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   t = jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));
   if( !jseIsNaN(t))
      t = JSE_FP_DIV(JSE_FP_SUB(t,LocalTime(t)),msPerMinute);

   jseReturnNumber(jsecontext,t);
}
#endif

#if defined(JSE_DATE_SETTIME)
static jseLibFunc(Ecma_Date_setTime)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber t;
   jseVariable n;

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   n = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,0),jseToNumber);
   if( n == NULL )
      return;

   t = TimeClip(jseGetNumber(jsecontext,n));

   jseDestroyVariable(jsecontext,n);

   jsePutNumber(jsecontext,jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber),t);
   jseReturnNumber(jsecontext,t);
}
#endif

#if defined(JSE_DATE_SETMILLISECONDS) || defined(JSE_DATE_SETUTCMILLISECONDS) \
 || defined(JSE_DATE_SETSECONDS) || defined(JSE_DATE_SETUTCSECONDS) \
 || defined(JSE_DATE_SETMINUTES) || defined(JSE_DATE_SETUTCMINUTES) \
 || defined(JSE_DATE_SETHOURS) || defined(JSE_DATE_SETUTCHOURS) \
 || defined(JSE_DATE_SETDATE) || defined(JSE_DATE_SETUTCDATE) \
 || defined(JSE_DATE_SETMONTH) || defined(JSE_DATE_SETUTCMONTH) \
 || defined(JSE_DATE_SETFULLYEAR) || defined(JSE_DATE_SETUTCFULLYEAR) \
 || defined(JSE_DATE_SETYEAR)
   static jsenumber NEAR_CALL
ForceNumberFromFuncVar(jseContext jsecontext,int WhichParameter)
{
   jseVariable var;
   jsenumber ret;
   var = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,(uint)WhichParameter),jseToNumber);

   if( var == NULL )
      return jseZero;

   ret = jseGetNumber(jsecontext,var);
   jseDestroyVariable(jsecontext,var);
   return ret;
}
#endif

#if defined(JSE_DATE_SETMILLISECONDS) || defined(JSE_DATE_SETUTCMILLISECONDS) \
 || defined(JSE_DATE_SETSECONDS) || defined(JSE_DATE_SETUTCSECONDS) \
 || defined(JSE_DATE_SETMINUTES) || defined(JSE_DATE_SETUTCMINUTES) \
 || defined(JSE_DATE_SETHOURS) || defined(JSE_DATE_SETUTCHOURS)
   static void NEAR_CALL
SetHourMinSecMilli(jseContext jsecontext,int MaxParams,
                   jsebool Local)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber hour,mins,sec,milli;
   jsenumber t,val;
   uint ParmCount = jseFuncVarCount(jsecontext);

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   t = jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));
   if ( Local )
   {
      t = LocalTime(t);
   }

   /* HOUR */
   if ( MaxParams == 4 )
   {
      hour = ForceNumberFromFuncVar(jsecontext,0);
      if( jseQuitFlagged(jsecontext) )
         return;
      ParmCount--;
   }
   else
   {
      hour = JSE_FP_CAST_FROM_SLONG(HourFromTime(t));
   }

   /* MINUTE */
   if ( 3 <= MaxParams  &&  ParmCount )
   {
      mins = ForceNumberFromFuncVar(jsecontext,MaxParams-3);
      if( jseQuitFlagged(jsecontext) )
         return;
      ParmCount--;
   }
   else
   {
      mins = JSE_FP_CAST_FROM_SLONG(MinFromTime(t));
   }

   /* SECOND */
   if ( 2 <= MaxParams  &&  ParmCount )
   {
      sec = ForceNumberFromFuncVar(jsecontext,MaxParams-2);
      if( jseQuitFlagged(jsecontext) )
         return;
      ParmCount--;
   }
   else
   {
      sec = JSE_FP_CAST_FROM_SLONG(SecFromTime(t));
   }

   /* MILLI */
   if ( ParmCount )
   {
      milli = ForceNumberFromFuncVar(jsecontext,MaxParams-1);
      if( jseQuitFlagged(jsecontext) )
         return;
   }
   else
   {
      milli = JSE_FP_CAST_FROM_SLONG(msFromTime(t));
   }

   val = MakeDate(Day(t),MakeTime(hour,mins,sec,milli));
   if ( Local )
   {
      val = UTC(val);
   }

   if( !jseQuitFlagged(jsecontext) )
   {
      jsePutNumber(jsecontext,jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber),val);
      jseReturnNumber(jsecontext,val);
   }
}
#endif

#if defined(JSE_DATE_SETMILLISECONDS)
static jseLibFunc(Ecma_Date_setMilliseconds)
{
   SetHourMinSecMilli(jsecontext,1,True);
}
#endif

#if defined(JSE_DATE_SETUTCMILLISECONDS)
static jseLibFunc(Ecma_Date_setUTCMilliseconds)
{
   SetHourMinSecMilli(jsecontext,1,False);
}
#endif

#if defined(JSE_DATE_SETSECONDS)
static jseLibFunc(Ecma_Date_setSeconds)
{
   SetHourMinSecMilli(jsecontext,2,True);
}
#endif

#if defined(JSE_DATE_SETUTCSECONDS)
static jseLibFunc(Ecma_Date_setUTCSeconds)
{
   SetHourMinSecMilli(jsecontext,2,False);
}
#endif

#if defined(JSE_DATE_SETMINUTES)
static jseLibFunc(Ecma_Date_setMinutes)
{
   SetHourMinSecMilli(jsecontext,3,True);
}
#endif

#if defined(JSE_DATE_SETUTCMINUTES)
static jseLibFunc(Ecma_Date_setUTCMinutes)
{
   SetHourMinSecMilli(jsecontext,3,False);
}
#endif

#if defined(JSE_DATE_SETHOURS)
static jseLibFunc(Ecma_Date_setHours)
{
   SetHourMinSecMilli(jsecontext,4,True);
}
#endif

#if defined(JSE_DATE_SETUTCHOURS)
static jseLibFunc(Ecma_Date_setUTCHours)
{
   SetHourMinSecMilli(jsecontext,4,False);
}
#endif

#if defined(JSE_DATE_SETDATE) || defined(JSE_DATE_SETUTCDATE) \
 || defined(JSE_DATE_SETMONTH) || defined(JSE_DATE_SETUTCMONTH) \
 || defined(JSE_DATE_SETFULLYEAR) || defined(JSE_DATE_SETUTCFULLYEAR) \
 || defined(JSE_DATE_SETYEAR)
   static void NEAR_CALL
SetYearMonDay(jseContext jsecontext,int MaxParams/*year,mon,day*/,
              jsebool Local,jsebool CheckMonAndDay,jsebool century1900)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber year,mon,day;
   jsenumber t,val;
   uint ParmCount = jseFuncVarCount(jsecontext);

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   t = jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));
   if ( Local )
   {
      t = LocalTime(t);
   }

   /* YEAR */
   if ( MaxParams == 3 )
   {
      if( jseIsNaN(t)) t = jseZero;
      year = ForceNumberFromFuncVar(jsecontext,0);
      if( jseQuitFlagged(jsecontext) )
         return;
#     if !JSE_MILLENIUM
         if ( century1900 )
         {
            if ( !jseIsNegative(year)  &&  JSE_FP_LTE(year,JSE_FP_CAST_FROM_SLONG(99)) )
               JSE_FP_ADD_EQ(year,JSE_FP_CAST_FROM_SLONG(1900));
         }
#     endif
      ParmCount--;
   }
   else
   {
      year = JSE_FP_CAST_FROM_SLONG(YearFromTime(t));
   }

   /* MONTH */
   if ( CheckMonAndDay  &&  2 <= MaxParams  &&  ParmCount )
   {
      mon = ForceNumberFromFuncVar(jsecontext,MaxParams-2);
      if( jseQuitFlagged(jsecontext) )
         return;
      ParmCount--;
   }
   else
   {
      mon = JSE_FP_CAST_FROM_SLONG(MonthFromTime(t));
   }

   /* DAY */
   if ( CheckMonAndDay  &&  ParmCount )
   {
      day = ForceNumberFromFuncVar(jsecontext,MaxParams-1);
      if( jseQuitFlagged(jsecontext) )
         return;
   }
   else
   {
      day = JSE_FP_CAST_FROM_SLONG(DateFromTime(t));
   }

   val = MakeDate(MakeDay(year,mon,day),TimeWithinDay(t));
   if ( Local )
   {
      val = UTC(val);
   }

   if( !jseQuitFlagged(jsecontext) )
   {
      jsePutNumber(jsecontext,jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber),val);
      jseReturnNumber(jsecontext,val);
   }
}
#endif

#if defined(JSE_DATE_SETDATE)
static jseLibFunc(Ecma_Date_setDate)
{
   SetYearMonDay(jsecontext,1,True,True,False);
}
#endif

#if defined(JSE_DATE_SETUTCDATE)
static jseLibFunc(Ecma_Date_setUTCDate)
{
   SetYearMonDay(jsecontext,1,False,True,False);
}
#endif

#if defined(JSE_DATE_SETMONTH)
static jseLibFunc(Ecma_Date_setMonth)
{
   SetYearMonDay(jsecontext,2,True,True,False);
}
#endif

#if defined(JSE_DATE_SETUTCMONTH)
static jseLibFunc(Ecma_Date_setUTCMonth)
{
   SetYearMonDay(jsecontext,2,False,True,False);
}
#endif

#if defined(JSE_DATE_SETFULLYEAR)
static jseLibFunc(Ecma_Date_setFullYear)
{
   SetYearMonDay(jsecontext,3,True,True,False);
}
#endif

#if defined(JSE_DATE_SETUTCFULLYEAR)
static jseLibFunc(Ecma_Date_setUTCFullYear)
{
   SetYearMonDay(jsecontext,3,False,True,False);
}
#endif

#if defined(JSE_DATE_SETYEAR)
static jseLibFunc(Ecma_Date_setYear)
{
   SetYearMonDay(jsecontext,3,True,False,True);
}
#endif

#if defined(JSE_DATE_TOLOCALESTRING) \
 || defined(JSE_DATE_TOUTCSTRING) \
 || defined(JSE_DATE_TOGMTSTRING)
   static void NEAR_CALL
DateToString(jseContext jsecontext,jsebool toLocale)
{
   jseVariable thisvar = jseGetCurrentThisVariable(jsecontext);
   jsenumber t;
   jseVariable ret;
   jsechar buf[MY_ASCTIME_BUFFER_SIZE];

   if( !ensure_valid_date(jsecontext,thisvar) )
      return;

   t = jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisvar,DATE_VALUE_PROPERTY,jseTypeNumber));

   my_asctime(buf,t,toLocale);

   ret = jseCreateVariable(jsecontext,jseTypeString);

   jsePutString(jsecontext,ret,(jsecharptr)buf);

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

#if defined(JSE_DATE_TOLOCALESTRING)
static jseLibFunc(Ecma_Date_toLocaleString)
{
   DateToString(jsecontext,True);
}
#endif

#if defined(JSE_DATE_TOUTCSTRING) || defined(JSE_DATE_TOGMTSTRING)
static jseLibFunc(Ecma_Date_toUTCString)
{
   DateToString(jsecontext,False);
}
#endif

#if defined(JSE_DATE_TOSOURCE)
static jseLibFunc(Ecma_Date_toSource)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   struct dynamicBuffer buffer;
   jsenumber t;
   jsechar date_num_buffer[ECMA_NUMTOSTRING_MAX];

   dynamicBufferInit(&buffer);
   dynamicBufferAppend(&buffer,UNISTR("new Date("));

   t = ensure_valid_date(jsecontext,thisVar)
     ? jseGetNumber(jsecontext,
                    jseMember(jsecontext,thisVar,DATE_VALUE_PROPERTY,jseTypeNumber))
     : jseNaN ;

   EcmaNumberToString(date_num_buffer,t);
   dynamicBufferAppend(&buffer,(jsecharptr)date_num_buffer);

   dynamicBufferAppend(&buffer,UNISTR(")"));

   jseReturnVar(jsecontext,
                objectToSourceHelper(jsecontext,thisVar,dynamicBufferGetString(&buffer)),
                jseRetTempVar);

   dynamicBufferTerm(&buffer);
}
#endif /* #if defined(JSE_DATE_TOSOURCE) */

/* ---------------------------------------------------------------------- */

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

static CONST_DATA(struct jseFunctionDescription) DateObjectFunctionList[] =
{
   JSE_ARGVLIBOBJECT( DATE_PROPERTY,       DateCall,               0, 7,
                                           jseDontEnum ,           jseFunc_Secure ),
   JSE_ARGVLIBMETHOD( CONSTRUCT_PROPERTY,  DateConstruct,          0, 7,
                                           jseDontEnum ,           jseFunc_Secure ),

#  if defined(JSE_DATE_PARSE)
      JSE_LIBMETHOD( UNISTR("parse"),         Ecma_Date_parse,        1 ,      1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_UTC)
      JSE_ARGVLIBMETHOD( UNISTR("UTC"),       Ecma_Date_UTC,          2, 7,
                                              jseDontEnum ,           jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_FROMSYSTEM)
      JSE_ARGVLIBMETHOD( UNISTR("fromSystem"),Ecma_Date_fromSystem,   1, 1,
                                              jseDontEnum ,        jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOSTRING)
      JSE_PROTOMETH( TOSTRING_PROPERTY,             Ecma_Date_toString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TODATESTRING)
      JSE_PROTOMETH( UNISTR("toDateString"),        Ecma_Date_toDateString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOTIMESTRING)
      JSE_PROTOMETH( UNISTR("toTimeString"),        Ecma_Date_toTimeString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
   /* In the future these may be their own functions */
#  if defined(JSE_DATE_TOLOCALESTRING)
      JSE_PROTOMETH( UNISTR("toLocaleString"),      Ecma_Date_toString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOLOCALEDATESTRING)
      JSE_PROTOMETH( UNISTR("toLocaleDateString"),  Ecma_Date_toDateString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOLOCALETIMESTRING)
      JSE_PROTOMETH( UNISTR("toLocaleTimeString"),  Ecma_Date_toTimeString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETTIME)
      JSE_PROTOMETH( UNISTR("getTime"),             Ecma_Date_valueOf,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif

#  if defined(JSE_DATE_GETYEAR)
      JSE_PROTOMETH( UNISTR("getYear"),             Ecma_Date_getYear,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETFULLYEAR)
      JSE_PROTOMETH( UNISTR("getFullYear"),         Ecma_Date_getFullYear,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCFULLYEAR)
      JSE_PROTOMETH( UNISTR("getUTCFullYear"),      Ecma_Date_getUTCFullYear,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETMONTH)
      JSE_PROTOMETH( UNISTR("getMonth"),            Ecma_Date_getMonth,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCMONTH)
      JSE_PROTOMETH( UNISTR("getUTCMonth"),         Ecma_Date_getUTCMonth,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETDATE)
      JSE_PROTOMETH( UNISTR("getDate"),             Ecma_Date_getDate,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCDATE)
      JSE_PROTOMETH( UNISTR("getUTCDate"),          Ecma_Date_getUTCDate,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETDAY)
      JSE_PROTOMETH( UNISTR("getDay"),              Ecma_Date_getDay,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCDAY)
      JSE_PROTOMETH( UNISTR("getUTCDay"),           Ecma_Date_getUTCDay,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETHOURS)
      JSE_PROTOMETH( UNISTR("getHours"),            Ecma_Date_getHours,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCHOURS)
      JSE_PROTOMETH( UNISTR("getUTCHours"),         Ecma_Date_getUTCHours,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETMINUTES)
      JSE_PROTOMETH( UNISTR("getMinutes"),          Ecma_Date_getMinutes,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCMINUTES)
      JSE_PROTOMETH( UNISTR("getUTCMinutes"),       Ecma_Date_getUTCMinutes,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETSECONDS)
      JSE_PROTOMETH( UNISTR("getSeconds"),          Ecma_Date_getSeconds,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCSECONDS)
      JSE_PROTOMETH( UNISTR("getUTCSeconds"),       Ecma_Date_getUTCSeconds,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETMILLISECONDS)
      JSE_PROTOMETH( UNISTR("getMilliseconds"),     Ecma_Date_getMilliseconds,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETUTCMILLISECONDS)
      JSE_PROTOMETH( UNISTR("getUTCMilliseconds"),  Ecma_Date_getUTCMilliseconds,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_GETTIMEZONEOFFSET)
      JSE_PROTOMETH( UNISTR("getTimezoneOffset"),   Ecma_Date_getTimezoneOffset,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETTIME)
      JSE_PROTOMETH( UNISTR("setTime"),             Ecma_Date_setTime,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETMILLISECONDS)
      JSE_PROTOMETH( UNISTR("setMilliseconds"),     Ecma_Date_setMilliseconds,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCMILLISECONDS)
      JSE_PROTOMETH( UNISTR("setUTCMilliseconds"),  Ecma_Date_setUTCMilliseconds,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETSECONDS)
      JSE_PROTOMETH( UNISTR("setSeconds"),          Ecma_Date_setSeconds,
                     1,       2,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCSECONDS)
      JSE_PROTOMETH( UNISTR("setUTCSeconds"),       Ecma_Date_setUTCSeconds,
                     1,       2,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETMINUTES)
      JSE_PROTOMETH( UNISTR("setMinutes"),          Ecma_Date_setMinutes,
                     1,       3,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCMINUTES)
      JSE_PROTOMETH( UNISTR("setUTCMinutes"),       Ecma_Date_setUTCMinutes,
                     1,       3,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETHOURS)
      JSE_PROTOMETH( UNISTR("setHours"),            Ecma_Date_setHours,
                     1,       4,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCHOURS)
      JSE_PROTOMETH( UNISTR("setUTCHours"),         Ecma_Date_setUTCHours,
                     1,       4,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETDATE)
      JSE_PROTOMETH( UNISTR("setDate"),             Ecma_Date_setDate,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCDATE)
      JSE_PROTOMETH( UNISTR("setUTCDate"),          Ecma_Date_setUTCDate,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETMONTH)
      JSE_PROTOMETH( UNISTR("setMonth"),            Ecma_Date_setMonth,
                     1,       2,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCMONTH)
      JSE_PROTOMETH( UNISTR("setUTCMonth"),         Ecma_Date_setUTCMonth,
                     1,       2,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETFULLYEAR)
      JSE_PROTOMETH( UNISTR("setFullYear"),         Ecma_Date_setFullYear,
                     1,       3,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETUTCFULLYEAR)
      JSE_PROTOMETH( UNISTR("setUTCFullYear"),      Ecma_Date_setUTCFullYear,
                     1,       3,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_SETYEAR)
      JSE_PROTOMETH( UNISTR("setYear"),             Ecma_Date_setYear,
                     1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOLOCALESTRING)
      JSE_PROTOMETH( UNISTR("toLocaleString"),      Ecma_Date_toLocaleString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
   /* These two share the same function */
#  if defined(JSE_DATE_TOUTCSTRING)
      JSE_PROTOMETH( UNISTR("toUTCString"),         Ecma_Date_toUTCString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOGMTSTRING)
      JSE_PROTOMETH( UNISTR("toGMTString"),         Ecma_Date_toUTCString,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOSYSTEM)
      JSE_ARGVPROTOMETH( UNISTR("toSystem"),        Ecma_Date_toSystem,
                         0, 0,        jseDontEnum ,           jseFunc_Secure ),
#  endif
#  if defined(JSE_DATE_TOSOURCE)
      JSE_PROTOMETH( TOSOURCE_PROPERTY,             Ecma_Date_toSource,
                     0,       0,      jseDontEnum , jseFunc_Secure ),
#  endif

   /* I've moved these to last, because they have the potential to
    * make the prototype object 'dynamic'. Thus, the core will try
    * to dynamic puts for each of these. Granted, it finds out it
    * doesn't have a put and cuts out, but it is slower, so a simple
    * reorder speeds stuff up.
    */
   JSE_PROTOMETH( CONSTRUCTOR_PROPERTY,    BuiltinDateConstructor, 0,       0,      jseDontEnum , jseFunc_Secure ),
   JSE_PROTOMETH( DEFAULT_PROPERTY,        Ecma_Date_defaultValue, 1,       -1,     jseDontEnum , jseFunc_Secure ),
   JSE_PROTOMETH( VALUEOF_PROPERTY,        Ecma_Date_valueOf,      0,       0,      jseDontEnum , jseFunc_Secure ),

   JSE_ATTRIBUTE( ORIG_PROTOTYPE_PROPERTY, jseDontEnum | jseReadOnly | jseDontDelete ),

JSE_FUNC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

   void NEAR_CALL
InitializeLibrary_Ecma_Date(jseContext jsecontext)
{
#  if (defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR))
      initialize_jseFPdate();
#  endif
   jseAddLibrary(jsecontext,NULL,DateObjectFunctionList,NULL,NULL,NULL);
}

#endif /* #ifdef JSE_DATE_ANY */

ALLOW_EMPTY_FILE
