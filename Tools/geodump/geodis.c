/*
        GEODIS.C

        by Marcus Gr�ber 1995

        Geos-specific routines for disassembly engine
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include "geos.h"
#include "geos2.h"


extern unsigned global_inf_changed;
extern unsigned numexp;
extern GEOSexplist *expt;
extern GEOSliblist *lib;
extern char selfname[GEOS_FNAME+1];
extern engine_silent;
extern struct {
  GEOSseglen len;
  GEOSsegpos pos;
  GEOSsegfix fixlen;
  GEOSsegflags flags;
} *segd;
extern unsigned base;

void disassemble(unsigned char *c,unsigned len,unsigned ofs,int all_silent);


#define MAX_GLOBAL_JMP 8000

static unsigned code_fixlen;
static GEOSfixup *code_fixup;
static FILE *code_file;
static unsigned this_seg;       // Segment number that is currently processed

struct {
  unsigned seg,ofs;
  int size;
} *global_jmp_map;
char **global_jmp_label;
unsigned n_global_jmp;          // number of global jumps

void init_global_jmp(void)
{
        global_jmp_map=calloc(MAX_GLOBAL_JMP,sizeof(global_jmp_map[0]));
        global_jmp_label=calloc(MAX_GLOBAL_JMP,sizeof(global_jmp_label[0]));
        n_global_jmp=0;                 // no global jump
}

void add_global_jmp(unsigned seg,unsigned ofs,char *label,int size)
{
        unsigned i;

        for(i=0;i<n_global_jmp;i++)     // all existing global jumps
          if(global_jmp_map[i].seg==seg && global_jmp_map[i].ofs==ofs)
            return;                     // already in there - no change
        if(i==MAX_GLOBAL_JMP) return;   // global jump table full - abort
        global_jmp_map[i].seg=seg;      // add global jmp target
        global_jmp_map[i].ofs=ofs;
        global_jmp_map[i].size=size;    // store type/size of object
        if(label==NULL)                 // no label specified?
          global_jmp_label[i]=NULL;     // don't define one
        else
        {
          global_jmp_label[i]=malloc(strlen(label)+1);
          strcpy(global_jmp_label[i],label);
                                        // store label
        }
        n_global_jmp++;                 // one more global jmp target
        global_inf_changed=1;           // in case anyone wants to know...
}

unsigned enumerate_global_jmp(unsigned n,unsigned *ofs)
{
        for(;n<n_global_jmp;n++)
          if(global_jmp_map[n].seg == this_seg && global_jmp_map[n].size == 0)
          {                             // found matching code entry point
            *ofs=global_jmp_map[n].ofs; // return offset of entry point
            return n+1;                 // return enumeration pointer
          }
        return 0xFFFF;                  // no more entries found
}

int test_data_map(unsigned ofs)
{
        unsigned i;

        for(i=0;i<n_global_jmp;i++)
          if(global_jmp_map[i].size &&
             global_jmp_map[i].ofs == ofs && global_jmp_map[i].seg == this_seg)
            return 1;                   // found matching data entry point
        return 0;
}


struct {
  unsigned seg,ofs;                     // location of jump list
  unsigned len;                         // size of list
  unsigned char size;                   // size of each entry
} jmplist[256];
unsigned n_jmplist;                     // number of jumplists

void init_jmplist(void)
{
        n_jmplist=0;                    // no jumplist yet
}

unsigned test_jmplist(unsigned ofs,unsigned *flag,int *addinfo)
{
        unsigned i;
        int firsthalf,ptrfirst,type;

        *flag=0;                        // default: no jumplist
        *addinfo=0xFFFF;                // additional info: just jumplist...
        for(i=0;i<n_jmplist;i++)        // all jumplists
          if(jmplist[i].seg == this_seg &&
             ofs >= jmplist[i].ofs &&
             ofs < jmplist[i].ofs+jmplist[i].len) {
            if(ofs == jmplist[i].ofs ||
               (jmplist[i].size>15 && ofs == (jmplist[i].ofs+jmplist[i].len/2)))
              *flag=1;                  // set flag if jumplist just starts...
            if(jmplist[i].size<16)      // location in normal jumplist?
              return jmplist[i].size;   // just return size

            /* the following piece of trickery creates a special return
               value for split pointer tables indicating whether this is
               the segment or the offset half and where the other half can
               be found (distance must be less than 2048 bytes). */

            if( ofs<jmplist[i].ofs+(jmplist[i].len/2) )
              firsthalf = 1;            // indicates if in 1st half of jmplist
            else
              firsthalf = 0;

            /* (the lines above may seem strange, but the "natural" way of
               putting it [firsthalf = (ofs<...)] causes MSC7 to go wild... */

            ptrfirst = (jmplist[i].size==17);
                                        // indicates if segment or pointer first
            if(firsthalf^ptrfirst)      // is this segment half? [^ is xor!]
              type=0x2800;              // fixup for split ptr segment
            else
              type=0x1800;              // fixup for split ptr offset
            *addinfo=type+(int)(jmplist[i].len/2)*(int)(firsthalf?1:-1);
                                        // offset to other half of pointer
            return 2;                   // this will create a "dw" instruction
          }
        *addinfo=0;                     // no jumplist
        return 0;                       // no jumplist applies
}

void add_jmplist(unsigned seg,unsigned ofs,unsigned len,unsigned size)
{
        jmplist[n_jmplist].seg=seg;     // add new jump list
        jmplist[n_jmplist].ofs=ofs;
        jmplist[n_jmplist].len=len;
        jmplist[n_jmplist].size=size;
        n_jmplist++;                    // count entries
}

/******************************************************************************/
struct s_libsymbol {
  struct s_libsymbol *next;             // next symbol in chain
  char lib[8];                          // name of library
  unsigned ord;
  char name[1];
} *symbol_list;

char *create_libref(char *buf,char *lib,unsigned ord)
{
        struct s_libsymbol *s;

        if(engine_silent) return "*";   // return dummy in silent mode

        for(s=symbol_list;
            s && (s->ord!=ord || strncmp(s->lib,lib,8));
            s=s->next)
          ;
        if(s)                           // found a symbol?
          return strcpy(buf,s->name);   // use symbolic name

        sprintf(buf,"%s_%u",lib,ord);
        return buf;
}

/******************************************************************************/
char *create_label(unsigned seg,unsigned ofs,char type)
{
        static char buffer[32];
        unsigned i;

        if(engine_silent) return "*";   // return dummy in silent mode
        if(seg==0xFFFF) seg=this_seg;   // segment 0xFFFF means: current segment

        for(i=0;i<numexp;i++)           // check if address matches entry point
          if(expt[i].seg==seg && expt[i].ofs==ofs)
                                        // found entry point: use symbolic name
          {
            create_libref(buffer,selfname,i);
            return buffer;
          }

        for(i=0;i<n_global_jmp;i++)
          if(global_jmp_map[i].seg == seg && global_jmp_map[i].ofs == ofs &&
             global_jmp_label[i])
            return global_jmp_label[i];

        sprintf(buffer,"%c%d_%04X",type,seg,ofs);
        return buffer;
}

/******************************************************************************/
/*
  callback routine from disasm module to test if an adress is hit by a
  fixup. If yes, a string describing the symbolic value of the fixup
  is returned. Returns NULL if no fixup.

  addinfo give more information on the nature of the position being fixed up:
    0000h    a general data item that can only be identified by a fixup
    FFFFh    context indicates an absolute jump adress, no matter if fixed
             up or not
    other    passed from test_jmplist to handle more complex jumplists
 */
char *test_fixup(unsigned ofs,int type,char *buf,int addinfo)
{
  static char buffer[32],buf2[GEOS_FNAME+1];
  unsigned i,j;
  int dist;

  *buffer=0;
  for(i=0; i<code_fixlen && code_fixup[i].ofs!=ofs; i++)
    ;
/*
   handle cases where no fixup has been found but context indicates presence
   of a code pointer (e.g. in a jump table) - this is mainly for correctly
   identifying pointers to code inside the program in which the offset is
   not fixed up but stored as a constant.
*/
  if(i==code_fixlen) {                  // no fixup found
    if((addinfo & 0xF000)==0x1000 || (type==4 && addinfo==0xFFFF)) {
                                        // offset part of "split" 32 bit pointer
      if(addinfo==0xFFFF)               // no jumplist - plain pointer?
        dist = 2;                       // offset is 2 bytes after segment
      else
        dist = (addinfo & 0x0FFF)-0x800;// extract distance
      for(j=0;
          j<code_fixlen                 // scan for suitable segment
          && (code_fixup[j].ofs!=ofs+dist || (code_fixup[j].type & 0xFE)!=0x22);
          j++)
          ;
      if(j==code_fixlen && dist>=0) return NULL;
                                        // none found - quit (for offset-after-
                                        // segment split jumplists, the segment
                                        // has already been removed, so ignore
                                        // missing fixup)
      sprintf(buffer,(type==4)?"%s":"offset %s",
         create_label(*(unsigned *)(buf+dist),*(unsigned *)buf,'H'));
                                        // successive segment/offset is as
                                        // good as a seg/ofs single fixup
      add_global_jmp(*(unsigned *)(buf+dist),*(unsigned *)buf,NULL,0);
      if((dist<0 || type==4) && j<code_fixlen) code_fixup[j].ofs=0xFFFF;
                                        // segment fixup has been handled
    }
    else if(type==2 && addinfo==0xFFFF) {
      strcpy(buffer, create_label(0xFFFF,*(unsigned *)buf,'H') );
      add_global_jmp(this_seg,*(unsigned *)buf,NULL,0);
    }
    else
      return NULL;
  }

/*
   handle segment component of a split pointer jumplist consisting of separate
   tables containing segment & offset.
*/
  else if((addinfo & 0xF000)==0x2000) { // found fixup and is split ptr segment
    if((code_fixup[i].type & 0xFE)==0x22) {
      dist = (addinfo & 0x0FFF)-0x800;  // extract distance
      sprintf(buffer,"seg %s",
         create_label(*(unsigned *)buf,*(unsigned *)(buf+dist),'H'));
      add_global_jmp(*(unsigned *)buf,*(unsigned *)(buf+dist),NULL,0);
    }
  }

/*
   identify library name if library relative fixup
*/
  if(*buffer==0 && (code_fixup[i].type & 0xF0) == 0x10) {
    strcpy(buf2,lib[code_fixup[i].type>>8].name);
                                        // get library name
    for(j=GEOS_FNAME;j>0 && buf2[j-1]==' ';j--)
      ;
    buf2[j]=0;                          // truncate trailing spaces
  }

/*
  handle different fixup types
*/
  if(*buffer==0)                        // not identified anything yet
   switch(type) {

    case 2:
      switch(code_fixup[i].type & 0xFF) {
      case 0x11:                        // offset of library entry
        strcpy(buffer,"offset ");
        create_libref(buffer+strlen(buffer),buf2,*(unsigned *)buf);
        break;
      case 0x12:                        // segment of library entry
        strcpy(buffer,"segment ");
        create_libref(buffer+strlen(buffer),buf2,*(unsigned *)buf);
        break;
      case 0x13:                        // handle of library
        sprintf(buffer,"handle %s",buf2);
        break;
      case 0x22:                        // fixup program segments
        if(*(unsigned *)buf!=1)
          sprintf(buffer,"SEG%u",*(unsigned *)buf);
        else
          strcpy(buffer,"dgroup");      // special case for default data segment
        break;
      case 0x23:                        // fixup handles of program segments
        if(*(unsigned *)buf)
          sprintf(buffer,"handle SEG%u",*(unsigned *)buf);
        else
          strcpy(buffer,"handle 0");    // special case for CoreBlock
        break;
      default: return NULL;             
      }
      break;

    case 4:
      switch(code_fixup[i].type & 0xFF) {
      case 0x00:
        create_libref(buffer,"geos",*(unsigned *)buf);
        break;
      case 0x11:                        // offset of library entry
                                        // segment might follow...
        for(j=0;
            j<code_fixlen               // scan for suitable segment
            && (code_fixup[j].ofs!=ofs+2 || (code_fixup[j].type & 0xFF)!=0x12);
            j++)
          ;
        if(j==code_fixlen) return NULL;
        create_libref(buffer,buf2,*(unsigned *)buf);
                                        // successive segment/offset is as
                                        // good as a seg/ofs single fixup
        code_fixup[j].ofs=0xFFFF;       // segment fixup has been handled
        break;
      case 0x14:
        create_libref(buffer,buf2,*(unsigned *)buf);
        break;
      case 0x24:
        strcpy(buffer,create_label(*(unsigned *)buf,*(unsigned *)(buf+2),'H'));
        add_global_jmp(*(unsigned *)buf,*(unsigned *)(buf+2),NULL,0);
        break;
      default: return NULL;
      }
      break;

    default: return NULL;               // can only fixup words and dwords
   }
  code_fixup[i].ofs=0xFFFF;             // fixup has been handled
  return buffer;
}

/******************************************************************************/
void init_disasm(void)
{
        init_global_jmp();              // no global jmp targets yet
        init_jmplist();                 // no jumplist yet
        symbol_list=NULL;               // no symbols yet
}

void deinit_disasm(void)
{
        free(global_jmp_map);           // play it safe...
        free(global_jmp_label);
}

/******************************************************************************/
char *DispFix(char *buf,FILE *f,long pos,GEOSfixup *fix)
{
        long old;
        unsigned w1,w2;
        char *p;

        old=ftell(f);                   // Position merken
        fseek(f,pos+fix->ofs,SEEK_SET); // Zur Fixup-Position
        sprintf(buf,"[%02x] ",fix->type & 0xFF);
        p=buf+strlen(buf);
        switch(fix->type & 0xF0) {
          case 0x00: strcpy(p, "Kernel       "); break;
          case 0x10: sprintf(p,"Library #%02x  ",fix->type>>8); break;
          case 0x20: strcpy(p,"Program      "); break;
            default: strcpy(p,"???          "); break;
        }
        p=buf+strlen(buf);
        switch(fix->type & 0x0F) {
          case 0x0: case 0x4:
            fread(&w1,sizeof(w1),1,f);
            fread(&w2,sizeof(w2),1,f);
            sprintf(p,((fix->type & 0xF0)==0x20)?"Seg:0x%04x Ofs:0x%04x":
                                                 "Ptr #0x%04x",w1,w2);
            break;
          case 0x1:
            fread(&w1,sizeof(w1),1,f);
            sprintf(p,"Off #0x%04x",w1);
            break;
          case 0x2: case 0x3:
            fread(&w1,sizeof(w1),1,f);
            sprintf(p,((fix->type & 0xF0)==0x20)?"Seg:0x%04x":
                                                 "Seg #0x%04x",w1);
            break;
        }
        fseek(f,old,SEEK_SET);          // Zur�ck zur gemerkten Position
        return buf;                     // Zeiger auf Puffer zur�ck
}

void prepost_hook(unsigned ofs,unsigned len,int silent_run,int type)
{
        unsigned i;
        char buf[64];

        switch(type) {                  // check various locations in code
          case 0:                       // "pre" before decoding instruction
            engine_silent=silent_run;   // remember "silent" mode of engine
            break;

          case 1:                       // "pre" hook before printing instr
            break;

          /* "post" hook: Display fixups in the range covered by the current
             instruction that could not be integrated. Usually, these are
             pointers in data areas being mistaken for code etc. */
          case 2:                       // after instruction
            if(silent_run==-1) break;
            for(i=0;i<code_fixlen; i++) // check all fixups
              if(code_fixup[i].ofs>=ofs && code_fixup[i].ofs<ofs+len) {
                                        // falls into instruction range
                if(silent_run==0)       // visible run: display fixup
                  printf("; Bad reloc @ 0x%04x %s\n",
                    code_fixup[i].ofs,
                    DispFix(buf,
                      code_file,segd[this_seg].pos+base,&code_fixup[i]));
                if(silent_run>=0) {     // Final run for each segment
                  if(silent_run==1)     // Make segment "data" in final
                                        // run for segment (globally invisible)
                    add_global_jmp(this_seg,ofs,NULL,-1);
                  code_fixup[i].ofs=0xFFFF;
                                        // fixup has been dealt with
                }
              }
            break;
        }
}

/******************************************************************************/
void DisplayUdata(unsigned start,unsigned seglen)
{
        unsigned ofs,len;

        this_seg=1;                     // udata belongs to dgroup segment
        for(ofs=start,len=0; ofs<start+seglen; ofs++,len++)
        {
          if(test_data_map(ofs))        // found data label
          {
            if(len)                     // previously collected data bytes?
              printf("    db   %5u dup (?)%21s; %04X\n",len,"",ofs-len);
            len=0;                      // data bytes have been dealt with
            printf("%s = $\n",create_label(0xFFFF,ofs,'D'));
                                        // insert label for this location
          }
        }
        if(len)                         // any more data bytes left?
          printf("    db   %5u dup (?)%21s; %04X\n",len,"",ofs-len);
}

void DispCode(FILE *f,long pos,unsigned size,
              GEOSfixup *fix,unsigned fixlen,
              unsigned seg,unsigned ofs,
              unsigned disasm_silent)
{
        unsigned char *p=malloc(size);

        if(pos!=-1)
          fseek(f,pos,SEEK_SET);
        fread(p,size,1,f);
        code_fixup=fix;
        code_fixlen=fixlen;
        code_file=f;
        this_seg=seg;                   // make segment publicly available
        disassemble(p,size,ofs,disasm_silent);
        free(p);
}

/******************************************************************************/
void disasm_info(char *fname)
{
        FILE *f;
        char buf[256],label[256],*env;
        int line=0,n;
        unsigned seg,ofs,len;
        char type;

        if( (env=getenv("GEODUMP"))==NULL)
          env=".";
        strcpy(buf,env);
        if(*buf==0 || buf[strlen(buf)-1]!='\\')
          strcat(buf,"\\");
        strcat(buf,fname);              // Add base name to path from env var

        if(f=fopen(buf,"rt")) {
          while(fgets(buf,sizeof(buf),f)) {
                                        // Bis zum Dateiende
            line++;                     // Zeilen z�hlen
            switch(toupper(buf[0])) {
              case ' ':                 // Kommentarzeilen werden �bersprungen
              case '\t':
              case ';':
              case '\n':
                n=0;
                break;
              case 'C':                 // "C seg ofs [label]" adds code entry
                *label=0;               // Reset label in case none is read
                sscanf(buf+1," %u %04x %s ",&seg,&ofs,label);
                add_global_jmp(seg,ofs,(*label && *label!=';')?label:NULL,0);
                n=0;
                break;
              case 'D':                 // "D seg ofs [label]" adds data entry
                *label=0;               // Reset label in case none is read
                sscanf(buf+1," %u %04x %s ",&seg,&ofs,label);
                add_global_jmp(seg,ofs,(*label && *label!=';')?label:NULL,-1);
                n=0;
                break;
              case 'J':                 // "J seg ofs len type" adds jumplist
                n = sscanf(buf+1," %u %04x %04x %c",&seg,&ofs,&len,&type) - 4;
                type=toupper(type);     // Gro�/klein egal...
                add_jmplist(seg,ofs,len,
                  (type=='2')?2:        // near jumplist
                  (type=='4')?4:        // far jumplist
                  (type=='S')?16:       // split, segment list comes first
                  (type=='O')?17:       // split, offset list comes first
                              (n=2));   // unknown, force abort...
                break;
              default:
                n=1;
            }
            if(n) {
              printf("Bad disasm info in line %d.\n",line);
              exit(1);
            }
          }
          fclose(f);
        }
}

void load_symbols(char *fname)
{
        FILE *f;
        char buf[256],lib[256],name[256],*env;
        unsigned ord;
        struct s_libsymbol *p,**q;

        if( (env=getenv("GEODUMP"))==NULL)
          env=".";
        strcpy(buf,env);
        if(*buf==0 || buf[strlen(buf)-1]!='\\')
          strcat(buf,"\\");
        strcat(buf,fname);              // Add base name to path from env var

        if(f=fopen(buf,"rt")) {
          while(fgets(buf,sizeof(buf),f)) {
                                        // Bis zum Dateiende
            if(buf[0]!='\n' && buf[0]!=';') {
                                        // Kommentare �berspringen
              sscanf(buf,"%s %u %s",lib,&ord,name);
              for(q=&symbol_list,p=*q; p; q=&(p->next),p=*q)
                ;                       // Ende der Liste suchen
              p=malloc(sizeof(*p)+strlen(name));
                                        // Neuen Eintrag erzeugen
              if(p==NULL) {             // Fehler? Abbruch!
                puts("Out of memory loading symbol file.");
                break;
              }
              strncpy(p->lib,lib,8);    // Library-Name
              p->ord=ord;               // Ordinalwert des Einsprungs
              strcpy(p->name,name);     // Symbolischer Name f�r Einsprung
              p->next=NULL;             // Noch kein Nachfolger
              *q=p;                     // Zeiger im Vorg�nger
            }
          }
          fclose(f);
        }
}
