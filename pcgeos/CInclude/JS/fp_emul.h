typedef word jsenumberTypeEnum ;
#define JSENUMBER_TYPE_LONG    0xFFF1
#define JSENUMBER_TYPE_POS_INFINITY 0x7FFE
#define JSENUMBER_TYPE_NEG_INFINITY 0xFFFE

typedef struct {
    word ignored[4] ;
    jsenumberTypeEnum type ;
} jsenumberType ;

typedef union {
    FloatNumStruct f ;
    sdword l ;
    jsenumberType t ;
} jsenumber ;

   /*
    * the following routines must be handled by an emulator
    *
    *    jsenumber JSE_FP_ADD(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_SUB(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_MUL(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_DIV(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_EQ(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_NEQ(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_LT(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_LTE(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_NEGATE(jsenumber FP);
    *    #define JSE_FP_ADD_EQ(FP1,FP2) ((FP1) = JSE_FP_ADD((FP1),(FP2)))
    *    #define JSE_FP_SUB_EQ(FP1,FP2) ((FP1) = JSE_FP_SUB((FP1),(FP2)))
    *    #define JSE_FP_MUL_EQ(FP1,FP2) ((FP1) = JSE_FP_MUL((FP1),(FP2)))
    *    #define JSE_FP_DIV_EQ(FP1,FP2) ((FP1) = JSE_FP_DIV((FP1),(FP2)))
    *
    *    jsenumber JSE_FP_FMOD(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_FLOOR(jsenumber FP);
    *
    *    void JSE_FP_INCREMENT_ptr(jsenumber *FP);
    *    #define JSE_FP_INCREMENT(FP) JSE_FP_INCREMENT_ptr(&(FP))
    *    void JSE_FP_DECREMENT_ptr(jsenumber *FP);
    *    #define JSE_FP_DECREMENT(FP) JSE_FP_DECREMENT_ptr(&(FP))
    *
    *    jsenumber JSE_FP_CAST_FROM_SLONG(slong L);
    *    slong JSE_FP_CAST_TO_SLONG(jsenumber f);
    *
    *    jsenumber JSE_FP_STRTOD( const jsecharptr __nptr, jsecharptr *__endptr );
    *    #define ECMA_NUMTOSTRING_MAX  100
    *    void JSE_FP_DTOSTR(jsenumber theNum,int precision,
    *                       jsechar buffer[ECMA_NUMTOSTRING_MAX],const jsecharptr type);
    *                                                            type is "g", "f", or "e"
    *
    *    extern VAR_DATA(jsenumber) jseNaN;
    *    extern VAR_DATA(jsenumber) jseInfinity;
    *    extern VAR_DATA(jsenumber) jseNegInfinity;
    *    extern VAR_DATA(jsenumber) jseZero;
    *    extern VAR_DATA(jsenumber) jseNegZero;
    *    extern VAR_DATA(jsenumber) jseOne;
    *    extern VAR_DATA(jsenumber) jseNegOne;
    *    jsebool jseIsNaN(jsenumber num);
    *    jsebool jseIsFinite(jsenumber num);
    *    jsebool jseIsNegative(jsenumber num);
    *    jsebool jseIsInfOrNegInf(jsenumber num);
    *    jsebool jseIsInfinity(jsenumber num);
    *    jsebool jseIsNegInfinity(jsenumber num);
    *    jsebool jseIsZero(jsenumber num);
    *    jsebool jseIsNegZero(jsenumber num);
    *    jsebool jseIsPosZero(jsenumber num);
    *
    *     ****************************************************************
    *     *** FUNCTIONS USED BY LIBRARIES.  WHAT YOU NEED TO IMPLEMENT ***
    *     *** DEPENDS ON THE LIBRARY FUNCTIONS YOU SUPPORT.  LET YOUR  ***
    *     *** LINKER TELL YOU WHAT'S MISSING.                          ***
    *     ****************************************************************
    *
    *    jsenumber JSE_FP_COS(jsenumber fp);
    *    jsenumber JSE_FP_ACOS(jsenumber fp);
    *    jsenumber JSE_FP_COSH(jsenumber fp);
    *    jsenumber JSE_FP_SIN(jsenumber fp);
    *    jsenumber JSE_FP_ASIN(jsenumber fp);
    *    jsenumber JSE_FP_SINH(jsenumber fp);
    *    jsenumber JSE_FP_TAN(jsenumber fp);
    *    jsenumber JSE_FP_ATAN(jsenumber fp);
    *    jsenumber JSE_FP_TANH(jsenumber fp);
    *    jsenumber JSE_FP_ATAN2(jsenumber fp1,jsenumber fp2);
    *    extern VAR_DATA(jsenumber) jsePI;
    *    extern VAR_DATA(jsenumber) jse_DBL_MAX;
    *    extern VAR_DATA(jsenumber) jse_DBL_MIN;
    *    jsenumber JSE_FP_CEIL(jsenumber FP);
    *    jsenumber JSE_FP_EXP(jsenumber fp);
    *    jsenumber JSE_FP_LOG(jsenumber fp);
    *    jsenumber JSE_FP_LOG10(jsenumber fp);
    *    jsenumber JSE_FP_POW(jsenumber fp1,jsenumber fp2);
    *    jsenumber JSE_FP_SQRT(jsenumber fp);
    *    jsenumber JSE_FP_FABS(jsenumber fp);
    *    jsenumber JSE_FP_ATOF(const char *str);
    *    jsenumber JSE_FP_FREXP(jsenumber fp,int *exp);
    *    jsenumber JSE_FP_LDEXP(jsenumber fp,int exp);
    *    jsenumber JSE_FP_MODF(jsenumber fp1,jsenumber *fp2);
    *
    *    jsenumber JSE_FP_CAST_FROM_ULONG(ulong u);
    *    ulong JSE_FP_CAST_TO_ULONG(jsenumber fp);
    *
    *    * casting from and to double is rare - may not be needed *
    *    jsenumber JSE_FP_CAST_FROM_DOUBLE(double D);
    *    double JSE_FP_CAST_TO_DOUBLE(jsenumber F);
    */

jsenumber JSE_FP_ADD(jsenumber FP1,jsenumber FP2);
jsenumber JSE_FP_SUB(jsenumber FP1,jsenumber FP2);
jsenumber JSE_FP_MUL(jsenumber FP1,jsenumber FP2);
jsenumber JSE_FP_DIV(jsenumber FP1,jsenumber FP2);
jsebool JSE_FP_EQ(jsenumber FP1,jsenumber FP2);
jsebool JSE_FP_NEQ(jsenumber FP1,jsenumber FP2);
jsebool JSE_FP_LT(jsenumber FP1,jsenumber FP2);
jsebool JSE_FP_LTE(jsenumber FP1,jsenumber FP2);
jsenumber JSE_FP_NEGATE(jsenumber FP);
#define JSE_FP_ADD_EQ(FP1,FP2) ((FP1) = JSE_FP_ADD((FP1),(FP2)))
#define JSE_FP_SUB_EQ(FP1,FP2) ((FP1) = JSE_FP_SUB((FP1),(FP2)))
#define JSE_FP_MUL_EQ(FP1,FP2) ((FP1) = JSE_FP_MUL((FP1),(FP2)))
#define JSE_FP_DIV_EQ(FP1,FP2) ((FP1) = JSE_FP_DIV((FP1),(FP2)))

jsenumber JSE_FP_FMOD(jsenumber FP1,jsenumber FP2);
jsenumber JSE_FP_FLOOR(jsenumber FP);

void JSE_FP_INCREMENT_ptr(jsenumber *FP);
#define JSE_FP_INCREMENT(FP) JSE_FP_INCREMENT_ptr(&(FP))
void JSE_FP_DECREMENT_ptr(jsenumber *FP);
#define JSE_FP_DECREMENT(FP) JSE_FP_DECREMENT_ptr(&(FP))

jsenumber JSE_FP_CAST_FROM_SLONG(slong L);
slong JSE_FP_CAST_TO_SLONG(jsenumber f);

jsenumber JSE_FP_STRTOD( const jsecharptr __nptr, jsecharptr *__endptr );
#define ECMA_NUMTOSTRING_MAX  100
void JSE_FP_DTOSTR(jsenumber theNum,int precision,
                   jsechar buffer[ECMA_NUMTOSTRING_MAX],const jsecharptr type);

extern VAR_DATA(jsenumber) jseNaN;
extern VAR_DATA(jsenumber) jseInfinity;
extern VAR_DATA(jsenumber) jseNegInfinity;
extern VAR_DATA(jsenumber) jseZero;
extern VAR_DATA(jsenumber) jseNegZero;
extern VAR_DATA(jsenumber) jseOne;
extern VAR_DATA(jsenumber) jseNegOne;
extern VAR_DATA(jsenumber) jse_DBL_MAX;
extern VAR_DATA(jsenumber) jse_DBL_MIN;
jsebool jseIsNaN(jsenumber num);
jsebool jseIsFinite(jsenumber num);
jsebool jseIsNegative(jsenumber num);
jsebool jseIsInfOrNegInf(jsenumber num);
jsebool jseIsInfinity(jsenumber num);
jsebool jseIsNegInfinity(jsenumber num);
jsebool jseIsZero(jsenumber num);
jsebool jseIsNegZero(jsenumber num);
jsebool jseIsPosZero(jsenumber num);

jsenumber JSE_FP_COS(jsenumber fp);
jsenumber JSE_FP_ACOS(jsenumber fp);
jsenumber JSE_FP_COSH(jsenumber fp);
jsenumber JSE_FP_SIN(jsenumber fp);
jsenumber JSE_FP_ASIN(jsenumber fp);
jsenumber JSE_FP_SINH(jsenumber fp);
jsenumber JSE_FP_TAN(jsenumber fp);
jsenumber JSE_FP_ATAN(jsenumber fp);
jsenumber JSE_FP_TANH(jsenumber fp);
jsenumber JSE_FP_ATAN2(jsenumber fp1,jsenumber fp2);
extern VAR_DATA(jsenumber) jsePI;
jsenumber JSE_FP_CEIL(jsenumber FP);
jsenumber JSE_FP_EXP(jsenumber fp);
jsenumber JSE_FP_RAND(void);
jsenumber JSE_FP_LOG(jsenumber fp);
jsenumber JSE_FP_LOG10(jsenumber fp);
jsenumber JSE_FP_POW(jsenumber fp1,jsenumber fp2);
jsenumber JSE_FP_SQRT(jsenumber fp);
jsenumber JSE_FP_FABS(jsenumber fp);
jsenumber JSE_FP_ATOF(const char *str);
jsenumber JSE_FP_FREXP(jsenumber fp,int *exp);
jsenumber JSE_FP_LDEXP(jsenumber fp,int exp);
jsenumber JSE_FP_MODF(jsenumber fp1,jsenumber *fp2);

jsenumber JSE_FP_CAST_FROM_ULONG(ulong u);
ulong JSE_FP_CAST_TO_ULONG(jsenumber fp);

jsenumber JSE_FP_CAST_FROM_DOUBLE(double D);
double JSE_FP_CAST_TO_DOUBLE(jsenumber F);

FloatNum JSE_GEOS_FP_TO_FLOAT(jsenumber f) ;

void initialize_FP_constants(void) ;
