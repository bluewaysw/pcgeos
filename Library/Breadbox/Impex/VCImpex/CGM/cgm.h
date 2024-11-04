

#define DUMP

#ifdef DUMP
extern FILE *fDump;
#define fputc(_ch,_f) { char _c; _c=(char)(_ch); fwrite(&_c,1,1,_f); }
#endif

extern FileHandle fCGM;

#define CGM_MAXARGSIZE  16384
#define CGM_MAXARGNUM   4096
#define CGM_MAXCOLORTBL 256

#define OPCODE(cl,id) (((cl)<<7)+(id))

union U_args {
  void    *ptr;
  dword   uval;
  sdword  sval;
  WWFixed fval;
  struct {
    struct _cgm_point { /* two VDU coordinates describing a point */
      sdword x,y;       /* for single VDU coordinate, both values are equal */
    } p;
    word flag;          /* special flag for "polygon set" data type */
  } point;
  struct _cgm_rgb {     /* a color triplet (RGB) */
    word flag;          /* flag: if true, r component contains color index */
    word r,g,b;
  } rgb;
};

struct _cgm_rgb;

typedef int _pascal CGM_handler(word opcode,word argc,union U_args *_argv);
typedef int _pascal pcfm_CGM_handler(word opcode,word argc,union U_args *_argv, void *pf);
struct _cgm_commands { word opcode; char *args; CGM_handler *hdl; };

#define argv(n) (&_argv[n])

extern word CGM_raw_Start(void);
extern void CGM_raw_End(void);
extern struct _cgm_rgb *cgm_color_deref(struct _cgm_rgb *c);
extern int CGM_docommand(struct _cgm_commands *cmds,word n_cmds,int *ret);
