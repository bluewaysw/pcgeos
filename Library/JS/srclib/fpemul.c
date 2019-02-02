#include "jseopt.h"
//#include <math.h>

#define GEOS_JSE_FP_EMUL_EXPONENT_MAX   0x7000

#if defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR) && defined(__JSE_GEOS__)

static void IConvertToFloat(jsenumber *p_f)
{
    /* Push a dword, pop a float */
    FloatDwordToFloat(p_f->l) ;
    FloatPopNumber((double*) &p_f->f) ;
}

#define IIsFloat(p_f)  ((p_f)->t.type!=JSENUMBER_TYPE_LONG)
static void IEnsureFloat(jsenumber *p_f)  
{
    /* Only do something if this is a long that needs to be a float */
    if (!IIsFloat(p_f))
        IConvertToFloat(p_f) ;
}


static void IPushFloat(jsenumber *p_f)
{
    if (IIsFloat(p_f))
        FloatPushNumber((double*)&(p_f->f)) ;
    else
        FloatDwordToFloat(p_f->l) ;
}
 
#define IPopFloat(p_f)   FloatPopNumber((double*)&(p_f)->f)

double JSE_FP_CAST_TO_DOUBLE(jsenumber F)
{
    double r ;
    IPushFloat(&F) ;
    FloatGeos80ToIEEE64(&r) ;
    return r ;
}

FloatNum JSE_GEOS_FP_TO_FLOAT(jsenumber f)
{
    IEnsureFloat(&f) ;
    return *((FloatNum *)&f.f) ;
}

jsenumber JSE_FP_ADD(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        FP1.l += FP2.l ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        FloatAdd() ;
        IPopFloat(&FP1) ;
    }
    return FP1 ;
}

jsenumber JSE_FP_SUB(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        FP1.l -= FP2.l ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        FloatSub() ;
        IPopFloat(&FP1) ;
    }
    return FP1 ;
}

void _pascal Mult3232To64(dword fp1, dword fp2, sdword *mult64) ;

jsenumber JSE_FP_MUL(jsenumber FP1,jsenumber FP2)
{
    sdword mult64[2] ;
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        Mult3232To64(FP1.l, FP2.l, mult64) ;
        /* Check to see if we have a really big number of signed number */
        if (mult64[1])  {
            /* Man, it's just too big.  Do the true multiply */
            IPushFloat(&FP1) ;
            IPushFloat(&FP2) ;
            FloatMultiply() ;
            IPopFloat(&FP1) ;
        } else {
            /* No overflow, just take the lower 32 bits */
            FP1.l = mult64[0] ;
        }
//        FP1.l *= FP2.l ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        FloatMultiply() ;
        IPopFloat(&FP1) ;
    }
    return FP1 ;
}

jsenumber JSE_FP_DIV(jsenumber FP1,jsenumber FP2)
{
    IPushFloat(&FP1) ;
    IPushFloat(&FP2) ;
    FloatDivide() ;
    IPopFloat(&FP1) ;
    return FP1 ;
}

jsebool JSE_FP_EQ(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        return (FP1.l == FP2.l) ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        return (FloatCompAndDrop()==0) ;
    }
}

jsebool JSE_FP_NEQ(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        return (FP1.l != FP2.l) ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        return (FloatCompAndDrop()!=0) ;
    }
}

jsebool JSE_FP_LT(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        return (FP1.l < FP2.l) ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        return (((sword)FloatCompAndDrop())==-1) ;
    }
}

jsebool JSE_FP_LTE(jsenumber FP1,jsenumber FP2)
{
    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        return (FP1.l <= FP2.l) ;
    } else {
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
        return ((sword)FloatCompAndDrop()<=0) ;
    }
}

jsenumber JSE_FP_NEGATE(jsenumber FP)
{
    if (IIsFloat(&FP))  {
        FloatPushNumber((double*)&FP.f) ;
        FloatNegate() ;
        FloatPopNumber((double*)&FP.f) ;
    } else {
        FP.l = -FP.l ;
    }
    return FP ;
}

jsenumber JSE_FP_FMOD(jsenumber FP1,jsenumber FP2)
{
	jsenumber num ;

    if ((FP1.t.type == FP2.t.type) && (!IIsFloat(&FP1)))  {
        if (FP2.l != 0)
            FP1.l %= FP2.l ;
        else
            FP1.l = 0 ;
    } else {
		/* modvalue = FP1 - (int(FP1 / FP2) * FP2) */
        IPushFloat(&FP1) ;
        IPushFloat(&FP2) ;
		FloatDivide() ;
        FloatIntFrac() ;
		/* Ignore fraction */
		IPopFloat(&num) ;
		IPushFloat(&FP2) ;
		FloatMultiply() ;
		IPushFloat(&FP1) ;
		FloatSub() ;
		FloatNegate() ;
        IPopFloat(&FP1) ;
    }
    return FP1 ;
}

jsenumber JSE_FP_FLOOR(jsenumber f)
{
    jsenumber integer ;

    /* Floor only on floats */
    if (IIsFloat(&f))  {
        FloatPushNumber((double*)&f.f) ;
        FloatIntFrac() ;
        if (!FloatEq0())  {
            FloatPopNumber((double*)&integer.f);
            FloatPushNumber((double*)&f.f) ;
            FloatMinus1() ;
            FloatAdd() ;
            FloatDup() ;
            if (FloatGt0())  {
                Float1() ;
                FloatAdd() ;
            }
            FloatIntFrac() ;
            /* Discard fraction */
            FloatPopNumber((double*)&f) ;
            /* Take integer */
            FloatPopNumber((double*)&f) ;
        } else {
            FloatPopNumber((double*)&f.f);
        }
    }
    return f ;
}

jsenumber JSE_FP_CEIL(jsenumber f)
{
    jsenumber integer ;

    /* Ceil only on floats */
    if (IIsFloat(&f))  {
        FloatPushNumber((double*)&f.f) ;
        FloatIntFrac() ;
        if (!FloatEq0())  {
            FloatPopNumber((double*)&integer.f);
            FloatPushNumber((double*)&f.f) ;
            Float1() ;
            FloatAdd() ;
            FloatDup() ;
            if (FloatLt0())  {
                FloatMinus1() ;
                FloatAdd() ;
            }
            FloatIntFrac() ;
            /* Discard fraction */
            FloatPopNumber((double*)&f) ;
            /* Take integer */
            FloatPopNumber((double*)&f) ;
        } else {
            FloatPopNumber((double*)&f.f);
        }
    }
    return f ;
}

void JSE_FP_INCREMENT_ptr(jsenumber *FP)
{
    if (IIsFloat(FP))  {
        FloatPushNumber((double*)&FP->f) ;
        Float1() ;
        FloatAdd() ;
        FloatPopNumber((double*)&FP->f) ;
    } else {
        FP->l++ ;
    }
}

void JSE_FP_DECREMENT_ptr(jsenumber *FP)
{
    if (IIsFloat(FP))  {
        FloatPushNumber((double*)&FP->f) ;
        Float1() ;
        FloatSub() ;
        FloatPopNumber((double*)&FP->f) ;
    } else {
        FP->l-- ;
    }
}

jsenumber JSE_FP_CAST_FROM_SLONG(slong L)
{
    jsenumber f ;

    /* Just store the number */
    f.t.type = JSENUMBER_TYPE_LONG ;
    f.l = L ;

    return f ;
}

slong JSE_FP_CAST_TO_SLONG(jsenumber f)
{
    if (IIsFloat(&f))  {
        FloatPushNumber((double*)&f) ;
	FloatTrunc();	/* prevent rounding */
        return FloatFloatToDword() ;
    } else {
        return f.l ;
    }
}

#define IS_PLUS_MINUS(c) ((c == '+') || (c == '-'))
#define IS_NUMBER(c)	 ((c >= '0') && (c <= '9'))
#define IS_EXPONENT(c)   ((c == 'E') || (c == 'e'))
#define IS_PERIOD(c)	  (c == '.')
jsenumber JSE_FP_STRTOD( const jsecharptr s, jsecharptr *endptr )
{
    jsenumber r ;
    int i = 0;		/* number of chars in a legal number */
    Boolean haveFrac ;
#ifdef DO_DBCS
    TCHAR dbF[50];
    word m, maxlen;
#endif

    /* GEOS doesn't actually parse the string for correctness so we'll
     * have to do that ourselves.  This is what we expect:
     *		"[+-] dddd.dddd [Ee] [+-] dddd"
     */
    /* Looking for an optional +/-, followed by numbers */
    if (IS_PLUS_MINUS(s[i])) i++;
    /* Get some numbers */
    if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) i++;
    /* Looking for an optional '.' */
    if (IS_PERIOD(s[i])) i++;
    /* Now looking for more numbers, if there */
    haveFrac = FALSE ;
    if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) { 
         if (s[i] != '0')
             haveFrac = TRUE ;
         i++;
    }
    /* Now looking for exponent, if there, and then a plus/minus */
    if (IS_EXPONENT(s[i])) {
	    i++;
	    if (IS_PLUS_MINUS(s[i])) i++;
	    if (IS_NUMBER(s[i])) while (IS_NUMBER(s[i])) i++;
    }

#ifdef DO_DBCS
    maxlen  = (sizeof(dbF)/sizeof(TCHAR))-1;
    if (i <= maxlen) {
	maxlen = i;
    }
    for (m = 0; m < maxlen; m++) {
	dbF[m] = s[m];
    }
    dbF[m] = 0;
    FloatAsciiToFloat(FAF_STORE_NUMBER, maxlen, dbF, &r.f) ;
#else
    FloatAsciiToFloat(FAF_STORE_NUMBER, i, (void*) s, (double*) &r.f) ;
#endif
    /* if not fractional and small, change to long */
    if (!haveFrac && ((r.f.F_exponent & 0x7fff) <= 0x401e))  {
        FloatPushNumber((double*)&r.f) ;
        r.l = FloatFloatToDword() ;        
        r.t.type = JSENUMBER_TYPE_LONG ;
    }
    if (endptr)
        *endptr = (char*) &(s[i]);

    return r ;
}

#define ECMA_NUMTOSTRING_MAX  100
#pragma argsused
void JSE_FP_DTOSTR(jsenumber theNum,int precision,
                   jsechar buffer[ECMA_NUMTOSTRING_MAX],const jsecharptr type)
{
    FloatNum f = JSE_GEOS_FP_TO_FLOAT(theNum) ;
    FloatFloatToAscii_StdFormat(
        buffer, 
        &f, 
        FFAF_FROM_ADDR | FFAF_NO_TRAIL_ZEROS, 
	DECIMAL_PRECISION, 
        precision);
}

jsebool jseIsNaN(jsenumber num) 
{
    return ((num.t.type != JSENUMBER_TYPE_LONG) && 
                (num.f.F_exponent == FP_NAN)) ;
}

jsebool jseIsFinite(jsenumber num)
{
    if (IIsFloat(&num))  {
        return ((num.f.F_exponent & FE_EXPONENT) < GEOS_JSE_FP_EMUL_EXPONENT_MAX) ;
    } else {
        return TRUE ;
    }
}

jsebool jseIsNegative(jsenumber num)
{
    if (IIsFloat(&num))  {
	return (num.f.F_exponent & FE_SIGN);
    } else {
        return (num.l < 0) ;
    }
}

jsebool jseIsInfOrNegInf(jsenumber num)
{
    if ((num.f.F_exponent == JSENUMBER_TYPE_LONG) || (num.f.F_exponent == FP_NAN))
        return FALSE ;
    return ((num.t.type & FE_EXPONENT) >= GEOS_JSE_FP_EMUL_EXPONENT_MAX) ;
}

jsebool jseIsInfinity(jsenumber num)
{
    if ((num.f.F_exponent == JSENUMBER_TYPE_LONG) || (num.f.F_exponent == FP_NAN))
        return FALSE ;
    return (((num.f.F_exponent & FE_EXPONENT) >= GEOS_JSE_FP_EMUL_EXPONENT_MAX) && 
        ((num.f.F_exponent & FE_SIGN)==0));
}

jsebool jseIsNegInfinity(jsenumber num)
{
    if ((num.f.F_exponent == JSENUMBER_TYPE_LONG) || (num.f.F_exponent == FP_NAN))
        return FALSE ;
    return (((num.f.F_exponent & FE_EXPONENT) >= GEOS_JSE_FP_EMUL_EXPONENT_MAX) && 
        (num.f.F_exponent & FE_SIGN));
}
jsebool jseIsZero(jsenumber num)
{
    sword sign ;
    if (IIsFloat(&num))  {
        FloatPushNumber((double*)&num.f) ;
        sign = FloatEq0() ;
        return (sign)?TRUE:FALSE ;
    } else {
        return (num.l == 0) ;
    }
}
#pragma argsused
jsebool jseIsNegZero(jsenumber num)
{
    return jseIsZero(num) && (num.f.F_exponent & FE_SIGN) ;
}
#pragma argsused
jsebool jseIsPosZero(jsenumber num)
{
    return jseIsZero(num) ;
}

jsenumber JSE_FP_FABS(jsenumber fp)
{
    if (IIsFloat(&fp))  {
        FloatPushNumber((double*)&fp.f) ;
        FloatPopNumber((double*)&fp.f) ;
    } else {
        if (fp.l < 0)
            fp.l = -fp.l ;
    }
    return fp ;
}

jsenumber JSE_FP_ATOF(const char *str)
{
    jsecharptr p_end ;
    return JSE_FP_STRTOD(str, &p_end) ;
}

jsenumber JSE_FP_CAST_FROM_ULONG(ulong u)
{
    jsenumber f ;

    /* THis is NOT correct, but this is the best we can do */
    /* because there are no unsigned conversions rules */
    f.l = u ;
    f.t.type = JSENUMBER_TYPE_LONG ;

    return f ;
}

ulong JSE_FP_CAST_TO_ULONG(jsenumber f)
{
    /* LIke ..._FROM_ULONG, this isn't quite correct */
    if (IIsFloat(&f))  {
        FloatPushNumber((double*)&f) ;
        return FloatFloatToDword() ;
    } else {
        return f.l ;
    }
}

jsenumber JSE_FP_CAST_FROM_DOUBLE(double D)
{
    jsenumber f ;

    FloatIEEE64ToGeos80(&D);
    FloatPopNumber((double*)&f.f) ;

    return f ;
}



VAR_DATA(jsenumber) jsePI;
VAR_DATA(jsenumber) jseNaN;
VAR_DATA(jsenumber) jseInfinity;
VAR_DATA(jsenumber) jseNegInfinity;
VAR_DATA(jsenumber) jseZero;
VAR_DATA(jsenumber) jseNegZero;
VAR_DATA(jsenumber) jseOne;
VAR_DATA(jsenumber) jseNegOne;
VAR_DATA(jsenumber) jse_DBL_MAX;
VAR_DATA(jsenumber) jse_DBL_MIN;

#pragma codeseg FP_EMUL_RARE

void _export initialize_FP_constants(void)
{
    jseNaN.f.F_exponent = FP_NAN;
    Float1() ;
    FloatPopNumber((double*)&jseInfinity.f) ;
    jseInfinity.t.type = JSENUMBER_TYPE_POS_INFINITY;
    FloatMinus1() ;
    FloatPopNumber((double*)&jseNegInfinity.f) ;
    jseNegInfinity.t.type = JSENUMBER_TYPE_NEG_INFINITY;
    Float0() ;
    FloatNegate() ;
    FloatPopNumber((double*)&jseNegZero) ;
    jseZero.l = 0 ;
    jseZero.t.type = JSENUMBER_TYPE_LONG ;
    jseOne.l = 1 ;
    jseOne.t.type = JSENUMBER_TYPE_LONG ;
    jseNegOne.l = -1 ;
    jseNegOne.t.type = JSENUMBER_TYPE_LONG ;
    FloatPi() ;
    FloatPopNumber((double*)&jsePI) ;
    Float1() ;
    FloatPopNumber((double*)&jse_DBL_MAX) ;
    jse_DBL_MAX.f.F_exponent = DECIMAL_EXPONENT_UPPER_LIMIT ;
    FloatMinus1() ;
    FloatPopNumber((double*)&jse_DBL_MIN) ;
    jse_DBL_MIN.f.F_exponent = DECIMAL_EXPONENT_UPPER_LIMIT ;
}

#define JSEEmuMath(routine, geosRoutine)  \
    jsenumber routine (jsenumber fp) \
    { \
        IPushFloat(&fp) ; \
        geosRoutine () ; \
        IPopFloat(&fp) ; \
        return fp ; \
    }

JSEEmuMath(JSE_FP_COS, FloatCos) ;
JSEEmuMath(JSE_FP_ACOS, FloatArcCos) ;
JSEEmuMath(JSE_FP_SIN, FloatSin) ;
JSEEmuMath(JSE_FP_ASIN, FloatArcSin) ;
JSEEmuMath(JSE_FP_SINH, FloatSinh) ;
JSEEmuMath(JSE_FP_TAN, FloatTan) ;
JSEEmuMath(JSE_FP_ATAN, FloatArcTan) ;
JSEEmuMath(JSE_FP_TANH, FloatTanh) ;
JSEEmuMath(JSE_FP_EXP, FloatExp) ;
JSEEmuMath(JSE_FP_LOG, FloatLg) ;
JSEEmuMath(JSE_FP_LOG10, FloatLg10) ;
JSEEmuMath(JSE_FP_SQRT, FloatSqrt) ;

jsenumber JSE_FP_RAND(void)
{
    jsenumber f ;

    FloatRandom() ;
    FloatPopNumber((double*)&f.f) ;

    return f ;
}

jsenumber JSE_FP_MODF(jsenumber fp1,jsenumber *fp2)
{
    if (IIsFloat(&fp1))  {
        FloatPushNumber((double*)&fp1.f) ;
        FloatIntFrac() ;
        FloatPopNumber((double*)&fp2->f) ;
        FloatPopNumber((double*)&fp1.f) ;
        return fp1 ;
    } else {
        *fp2 = fp1 ;
        return jseZero ;
    }
}

jsenumber JSE_FP_POW(jsenumber fp1,jsenumber fp2)
{
    IPushFloat(&fp1) ;
    IPushFloat(&fp2) ;
    FloatExponential() ;
    IPopFloat(&fp1) ;
    return fp1 ;
}

jsenumber JSE_FP_ATAN2(jsenumber fp1,jsenumber fp2)
{
    IPushFloat(&fp1) ;
    IPushFloat(&fp2) ;
    FloatArcTan2() ;
    IPopFloat(&fp1) ;
    return fp1 ;
}

#endif
