/*
        GEODUMP.C

        by Marcus Gr�ber 1991-95

        Creates structured dumps of PC/Geos files (Geodes, VM Files, fonts)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <ctype.h>

#include "geos.h"
#include "geos2.h"
#include "geostool.inc"

void DisplayBSWF(FILE *f);

void init_disasm(void);
void deinit_disasm(void);
void add_global_jmp(unsigned seg,unsigned ofs,char *label,int size);
void add_jmplist(unsigned seg,unsigned ofs,unsigned len,unsigned size);
void disasm_info(char *fname);
void load_symbols(char *fname);
char *DispFix(char *buf,FILE *f,long pos,GEOSfixup *fix);
void DisplayUdata(unsigned start,unsigned seglen);
void DispCode(FILE *f,long pos,unsigned size,GEOSfixup *fix,unsigned fixlen,
              unsigned seg,unsigned ofs,unsigned disasm_silent);


#define MAX_PASSES 10      /* max. pass number before disassembly is aborted */

#define GetStruct(str)      fread(&(str),sizeof(str),1,f)
#define GetStructP(str,ptr) fseek(f,ptr,SEEK_SET);fread(&(str),sizeof(str),1,f)

unsigned ver;
unsigned base;

struct {                        /*** Segment-Beschreibung */
  GEOSseglen len;               // L�nge
  GEOSsegpos pos;               // Position in der Datei
  GEOSsegfix fixlen;            // L�nge der Fixup-Tabelle
  GEOSsegflags flags;           // Flags
} *segd;
unsigned numexp,numseg;         // Anzahl Export-Routinen, Segmente
GEOSexplist *expt;              // Export-Routinen
GEOSliblist *lib;               // Library-Namen
char selfname[GEOS_FNAME+1];    // Base name of currently disassembled geode

unsigned dodump,dolist,disasm_silent,engine_silent;
int one_segment;                // if >=0, number of only segment to be dumped
int one_pass;                   // if non-zero, indicates that listing is to
                                // be generated in first pass

unsigned global_inf_changed;


/******************************************************************************/
char *strncpy2(char *d,char *s,int n)
{
        strncpy(d,s,n);
        d[n]='\0';
        return d;
}

void strtrunc(char *s,int len)
{
        char *p;

        if(p=strchr(s,'\r')) *p='\0';   // Max. 1. Zeile anzeigen
        if(strlen(s)>(size_t)len)       // String trotzdem zu lang?
          strcpy(s+len-3,"...");        // Ja: String mit "..." abschneiden
}

/******************************************************************************/
char *DispTok(char *buf,GEOStoken *tok)
{
        char t[GEOS_TOKENLEN+1];

        strncpy(t,tok->str,GEOS_TOKENLEN);
                                        // Token in Puffer
        t[GEOS_TOKENLEN]='\0';          // Endnull anf�gen
        if(*t)                          // Token vorhanden?
          sprintf(buf,"%4s,%u",t,tok->num);
                                        // Token in Buffer formatieren
        else
          strcpy(buf,"-");              // Sonst nur Ersatz
        return buf;                     // Zeiger auf Puffer zur�ck
}

char *DispRel(char *buf,GEOSrelease *rel)
{
        sprintf(buf,"%u.%u  %u-%u",     // Release-Nummer formatieren
                    rel->versmaj,rel->versmin,rel->revmaj,rel->revmin);
        return buf;                     // Zeiger auf Puffer zur�ck
}

char *DispPro(char *buf,GEOSprotocol *rel)
{
        sprintf(buf,"%u.%03u",rel->vers,rel->rev);
                                        // Protokoll-Nummer formatieren
        return buf;                     // Zeiger auf Puffer zur�ck
}

/******************************************************************************/

/*
   The following record describes one possible field value in a bitmapped
   packed record (up to word size). The "and" field marks the bits of the
   field to be checked with "ones"; the "test" field contains the value these
   bits are to be compared to. If (value & MaskDesc_s.and)==MaskDesc_s.test,
   MakeDesc_s.desc gives the name of the selected field's value.

   In an array of this structure, the end of the array is marked by a record
   contain all zeroes / NULLs.
 */

struct MaskDesc_s {
  unsigned and;
  unsigned test;
  char *desc;
};

char *DispBitMask(char *buf,unsigned value,struct MaskDesc_s *desc,char *sep)
{
        int i;

        *buf=0;                         // clear result buffer

        for(i=0; desc[i].and; i++)      // ...up to end of array
        {
          if((value & desc[i].and)==desc[i].test)
          {                             // found matching field/value pair:
            if(*buf)                    // add separator if required
              strcat(buf,sep);
            strcat(buf,desc[i].desc);   // add value name
            value&=(~desc[i].and);      // mask out bits that were processed
          }
        }
        if(value)                       // still unprocessed bits left?
        {
          if(*buf)                      // add separator if required
            strcat(buf,sep);
          sprintf(buf+strlen(buf),"0x%04x",value);
                                        // print out unprocessed bits
        }
        return buf;
}

/******************************************************************************/
#define Hexdump(buf) DispHex(#buf":",(unsigned char *)&buf,-(int)sizeof(buf))
void DispHex(char *s,unsigned char *p,int n)
{
        int i,j;

        if(n<0) {                       // n negativ: Leerbereiche unterdr�cken
          n=-n;
          for(i=0;i<n && !p[i];i++)     // Pr�fen, ob alles Nullen
            ;                           
          if(i==n) return;              // Nur Nullen: Nicht zeigen
        }
        for(i=0;i<n;i++) {              // Ganzen Buffer durchgehen
          if(i%16==0)                   // Neue Zeile?
            printf("%14s ",i?"":s);     // Einr�ckung ausgeben
          printf("%02x ",p[i]);         // Ein Byte ausgeben
          if(i%16==15 || i==n-1) {      // Zeilenende?
            for(j=i%16;j<15;j++)        // Evtl. bis zum rechten Rand fuellen
              printf("   ");
            for(j=i-(i%16);j<=i;j++)    // Bytes der letzten Zeile durgehen
              if(p[j]>=' ' && p[j]<='z')// ASCII-Zeichen?
                putchar(p[j]);          // Ausgeben
              else
                putchar('.');           // Sonst durch "." ersetzen
            putchar('\n');
          }
        }
}

void DispFile(FILE *f,long pos,unsigned len,unsigned ofs,long hdl)
{
        char buf[80],adr[16];
        unsigned short x,bs;

        if(pos!=-1)                     // Position angebgen?
          fseek(f,pos,SEEK_SET);        // Ja: zum Anfang des Blocks
        for(x=0;x<len;x+=bs) {          // Segment lesen
          bs=len-x;                     // default: Ganzen Rest lesen
          if(bs>16)                     // Zu gro� f�r Puffer?
            bs=16;                      // Nur einen Puffer lesen
          if(hdl>-1)                    // Handle �bergeben?
            sprintf(adr,"[%04X] %04X:",(unsigned)hdl,x+ofs);
                                        // Handle/Offset als Hexzahlen
          else
            sprintf(adr,(hdl==-2)?"* Data: %04X:":"%04X:",x+ofs);
                                        // Offset als Hexzahl
          hdl=-1;                       // Handles etc. nur in erster Zeile
          fread(buf,bs,1,f);            // Daten in Puffer lesen
          DispHex(adr,buf,bs);          // Pufferinhalt ausgeben
        }
}

void DisplayHeap(FILE *f,long pos,unsigned size)
{
        GEOSlocalheap lh;               // Kopf des lokalen Heaps
        GEOSObjLMemBlockHeader oh;      // additional obj block header
        GEOSlocallist *hdl;             // Maximal 256 Handles pro Heap
        unsigned short i;
        unsigned short blksize;
        struct { unsigned blksize; unsigned nextofs; } freehead;
        unsigned ofs;

        GetStructP(lh,pos);             // Kopf des lokalen Heaps holen
        printf("\n"
               " * LMem: Size: %5d Bytes   Handle list: @ 0x%04x   Entries: %d\n"
               "         Free: %5d Bytes\n"
               "        Flags: %04x\n"
               "         Type: %04x\n",
               lh.blocksize,lh.hdllistofs,lh.hdllistnum,lh.freesize,
               lh.LMBH_flags,lh.LMBH_lmemType);
                                        // Heap anzeigen
        if(lh.LMBH_lmemType==LMEM_TYPE_OBJ_BLOCK) {
          GetStruct(oh);                // Get object block header
          printf(" * ObjBlock: inUseCount: %-5u\n"
                 "      interactibleCount: %-5u\n"
                 "                 output: %08lx\n"
                 "           resourceSize: %-5u\n",
                 oh.OLMBH_inUseCount,oh.OLMBH_interactibleCount,
                 oh.OLMBH_output,oh.OLMBH_resourceSize);
        }
        hdl=calloc(lh.hdllistnum,sizeof(hdl[0]));
                                        // Platz f�r Handle-Liste reservieren
        fseek(f,pos+lh.hdllistofs,SEEK_SET);
                                        // Zum Anfang der Handle-Liste im File
        fread(hdl,lh.hdllistnum,sizeof(hdl[0]),f);
                                        // Handle-Liste einlesen
        for(i=0;i<lh.hdllistnum;i++) {  // Liste durchgehen
          if(hdl[i] && hdl[i]!=0xFFFF && hdl[i]>lh.hdllistofs && hdl[i]<size)
                                        // freie/falsche Handles nicht zeigen
          {                             
            GetStructP(blksize,pos+hdl[i]-2);
                                        // Angeforderte L�nge des Blocks
                                        // (tats�chlich belegte L�nge ist immer
                                        // auf Vielfache von 4 aufgerundet)
            if(blksize>2)               // Nur wenn Block wirklich gef�llt
              DispFile(f,-1,blksize-2,
                       hdl[i],lh.hdllistofs+i*sizeof(GEOSlocallist));
                                        // Daten des Handles anzeigen
          }
        }
        ofs=lh.freeofs;                 // Offset des ersten freien Blocks
        while(ofs) {                    // Solange freien Bl�cke da sind
          GetStructP(freehead,pos+ofs-2);
                                        // Kopf des freien Blocks holen
          printf("         %04X: *** free: %5d bytes\n",ofs,freehead.blksize);
                                        // Freien Block anzeigen
          ofs=freehead.nextofs;         // Zeiger auf n�chsten Block
        }
        free(hdl);                      // Handle-Liste nicht mehr n�tig
}

void DisassembleHeap(FILE *f,long pos,unsigned size,char *segname,
                     GEOSfixup *fix,unsigned fixlen,unsigned seg)
{
        GEOSlocalheap lh;               // Kopf des lokalen Heaps
        GEOSObjLMemBlockHeader oh;      // additional obj block header
        GEOSlocallist *hdl;             // Maximal 256 Handles pro Heap
        unsigned short i;
        unsigned short blksize;

        GetStructP(lh,pos);             // Kopf des lokalen Heaps holen

/* display header of local heap */
        printf("\n"
               "; * LMem: Size: %5d Bytes   Handle list: @ 0x%04x   Entries: %d\n"
               ";         Free: %5d Bytes\n",
               lh.blocksize,lh.hdllistofs,lh.hdllistnum,lh.freesize);
                                        // Heapkopf anzeigen
        if(lh.LMBH_lmemType==LMEM_TYPE_OBJ_BLOCK) {
          GetStructP(oh,pos+sizeof(lh));// Get object block header
          printf("; * ObjBlock: inUseCount: %-5u\n"
                 ";      interactibleCount: %-5u\n"
                 ";                 output: %08lx\n"
                 ";           resourceSize: %-5u\n",
                 oh.OLMBH_inUseCount,oh.OLMBH_interactibleCount,
                 oh.OLMBH_output,oh.OLMBH_resourceSize);
                                        // Daten anzeigen (evtl. + 2 Pad Bytes)
        }

        hdl=calloc(lh.hdllistnum,sizeof(hdl[0]));
                                        // Platz f�r Handle-Liste reservieren
        fseek(f,pos+lh.hdllistofs,SEEK_SET);
                                        // Zum Anfang der Handle-Liste im File
        fread(hdl,lh.hdllistnum,sizeof(hdl[0]),f);
                                        // Handle-Liste einlesen

/* display data blocks of local heap */
        for(i=0;i<lh.hdllistnum;i++) {  // Liste durchgehen
          if(hdl[i] && hdl[i]!=0xFFFF && hdl[i]>lh.hdllistofs && hdl[i]<size)
                                        // Unbenutzte Handles nicht zeigen
          {
            printf("\n_%s_%04x chunk byte\n",
                   segname,lh.hdllistofs+i*sizeof(GEOSlocallist));
            GetStructP(blksize,pos+hdl[i]-2);
                                        // Angeforderte L�nge des Blocks
                                        // (tats�chlich belegte L�nge ist immer
                                        // auf Vielfache von 4 aufgerundet)
            if(blksize>2)               // Nur wenn Block wirklich gef�llt
              DispCode(f,-1,blksize-2,fix,fixlen,seg,hdl[i],disasm_silent);
                                        // Daten des Handles anzeigen
            printf("_%s_%04x endc\n",
                   segname,lh.hdllistofs+i*sizeof(GEOSlocallist));
          }
        }

        free(hdl);                      // Handle-Liste nicht mehr n�tig
}

void DisplaySegment(FILE *f,unsigned n,unsigned i)
{
        GEOSfixup *fix;                 // Fixup-Eintrag
        GEOSlocalheap lh;               // Kopf des lokalen Heaps
        unsigned short x;
        char buf[128],segname[32];
        unsigned short data_ofs,data_len;

        struct MaskDesc_s segFlagMask[]={
          {(unsigned)(HAF_ZERO_INIT<<8),(unsigned)(HAF_ZERO_INIT<<8),"ZERO_INIT"},
          {HAF_LOCK<<8,HAF_LOCK<<8,"LOCK"},
          {HAF_NO_ERR<<8,HAF_NO_ERR<<8,"NO_ERR"},
          {HAF_UI<<8,HAF_UI<<8,"UI"},
          {HAF_READ_ONLY<<8,HAF_READ_ONLY<<8,"READ_ONLY"},
          {HAF_OBJECT_RESOURCE<<8,HAF_OBJECT_RESOURCE<<8,"OBJECT_RESOURCE"},
          {HAF_CODE<<8,HAF_CODE<<8,"CODE"},
          {HAF_CONFORMING<<8,HAF_CONFORMING<<8,"CONFORMING"},
          {HF_FIXED,HF_FIXED,"FIXED"},
          {HF_SHARABLE,HF_SHARABLE,"SHARABLE"},
          {HF_DISCARDABLE,HF_DISCARDABLE,"DISCARDABLE"},
          {HF_SWAPABLE,HF_SWAPABLE,"SWAPABLE"},
          {HF_LMEM,HF_LMEM,"LMEM"},
          {HF_DEBUG,HF_DEBUG,"DEBUG"},
          {HF_DISCARDED,HF_DISCARDED,"DISCARDED"},
          {HF_SWAPPED,HF_SWAPPED,"SWAPPED"},
          {0,0,NULL}};

        sprintf(segname,"SEG%d",i);     // name under which segment is displayed

        if(i==1)                        // Segment 1 is "initialized data"
          strcpy(segname,"idata");

        if(segd[i].flags & 0x8)         // Evtl. Kopf des lokalen Heaps holen
          GetStructP(lh,segd[i].pos+base);

        if( i==0 && !segd[i].len )      // SEG0 nicht dumpen, falls leer...
          return;

        if(!disasm_silent) {
          if(dolist)
          {
            if(segd[i].flags & 0x8)
              printf("%s\tSEGMENT lmem 0%04xh,0%04xh\n",segname,
                     lh.LMBH_lmemType,lh.LMBH_flags);
            else
              printf("%s\tSEGMENT\n",segname);
          }
          else
            printf("Resource %d:\n",i);
          printf("%c File offset: @ 0x0%-8lx Size: 0x0%04x     Relocs: %-4d\n"
                 "%c %s\n",
                 dolist?';':' ',
                 segd[i].pos+base,segd[i].len,segd[i].fixlen/sizeof(*fix),
                 dolist?';':' ',
                 DispBitMask(buf,segd[i].flags,segFlagMask,","));
        }
        if(dodump) {
          fix=malloc(segd[i].fixlen);   // Platz f�r Fixups
          fseek(f,segd[i].pos+base+((segd[i].len+0xF)&0xFFF0),SEEK_SET);
                                        // Zu Fixups springen
          fread(fix,1,segd[i].fixlen,f);// Fixups lesen

          data_ofs = 0;
          data_len = segd[i].len;

          if(segd[i].flags & 0x8) {
            data_ofs = sizeof(lh)+      // Kopf �berspringen
              ((lh.LMBH_lmemType==LMEM_TYPE_OBJ_BLOCK)?
               sizeof(GEOSObjLMemBlockHeader):0);
            data_len = lh.hdllistofs - data_ofs;
            if(lh.LMBH_lmemType==LMEM_TYPE_OBJ_BLOCK && data_len==2)
              data_len=0;               // 2 Pad-Bytes verschlucken
            if(lh.hdllistofs<data_ofs)
            {
              data_len=0;               // correct for invalid data area size
              if(!disasm_silent)
                printf("%c Warning: Handle list position inconsistent.\n",
                  dolist?';':' ');
            }
            if(dolist)
              if (fix[0].ofs==0)        // Fixup in Heap-Kopf immer vorhanden
                fix[0].ofs = 0xFFFF;
          }

          if(data_len)                  // Daten im Segment dumpen?
            if(dolist && segd[i].len>0)
            {
              if(!disasm_silent)
                printf("    assume cs:%s\n",segname);
              DispCode(f,segd[i].pos+base+data_ofs,data_len,fix,
                         segd[i].fixlen/sizeof(*fix),i,data_ofs,disasm_silent);
            }
            else
            {
              putchar('\n');
              DispFile(f,segd[i].pos+base+data_ofs,data_len,data_ofs,-2);
            }

          if(!disasm_silent && (segd[i].flags & 0x8))
            if(dolist)
              DisassembleHeap(f,segd[i].pos+base,segd[i].len,segname,
                              fix,segd[i].fixlen/sizeof(*fix),i);
            else
              DisplayHeap(f,segd[i].pos+base,segd[i].len);

          if(!disasm_silent) {
            for(x=0; x < segd[i].fixlen/sizeof(*fix); x++)
                                        // Alle Fixups durchgehen
              if(fix[x].ofs != 0xFFFF)  // Nur, wenn nicht im Listing
                printf(
                       dolist?"; %12s @ 0x%04x  %s\n":
                       "%14s @ 0x%04x  %s\n",
                       (x?"":"Relocs:"),
                       fix[x].ofs,DispFix(buf,f,segd[i].pos+base,&fix[x]));
            if(dolist)
              printf("%s\tENDS\n",segname,i);
            printf("\n");
          }
          free(fix);
        }
}

void DisplayApplication(FILE *f)
{
        GEOSappheader ah;               // Zusatz-Dateikopf f�r Programme
        char buf[80],buf2[80],*p;
        unsigned i;
        long segbase;
        int pass=1;

        GetStructP(ah,(ver==1)?0xC0:(base-8));
                                        // Dateikopf holen
        strcpy(buf,ah.name);            // Namen/Extension zusammensetzen
        strcpy(buf+GEOS_FNAME,ah.ext);
        buf[GEOS_FNAME+GEOS_FEXT]=0;
        printf("\n   Perm. name: %s\n",buf);

        buf[GEOS_FNAME]=0;              // Truncate after base name
        if(p=strchr(buf,' '))           // Remove trailing blanks
          *p='\0';                         
        if(dolist) {
          strcpy(selfname,buf);           // we'll need this later
          sprintf(buf2,"%s.sls",selfname);// Name of symbol file for "self"
          load_symbols(buf2);             // Attempt to load symbols
          sprintf(buf2,"%s.dis",selfname);// Dissassembly support for "self"
          disasm_info(buf2);              // Attempt to load disassembly info
        }

        printf(  "         Type: %02x %-33s\n"
                 "    Attribute: %04x\n",
                 ah.type,
                 (ah.type==1)?"[Application]":
                 (ah.type==2)?"[Library]":
                 (ah.type==3)?"[Driver]":
                              "???",
                 ah.attr);

        printf(  " Kernel prot.: %s\n",DispPro(buf,&ah.kernalprot));
        printf(  "         CRC?: 0x0%04x\n",ah.CRC);
        printf(  " Stack/Uninit: %u bytes\n",ah.stacksize);

        Hexdump(ah._x1); Hexdump(ah._x21);
        Hexdump(ah._x3); Hexdump(ah._x33); Hexdump(ah._x4);
        Hexdump(ah._x5);
            
        lib=malloc(ah.numlib*sizeof(*lib));
        segd=malloc(ah.numseg*sizeof(*segd));

        fread(lib,ah.numlib,sizeof(*lib),f);
                                        // Get libraries
        for(i=0;i<ah.numlib;i++) {      // Alle Libraries durchgehen
          strcpy(buf,lib[i].name);      // Library-Namen holen
          buf[GEOS_FNAME]=0;
          printf("%14s  %2d: %s %s (Protocol %s)\n",
                 i?"":"Libraries:",i,buf,
                 (lib[i].type==0x2000)?"Driver":
		 (lib[i].type==0x4000)?"Library":
                                    "???",
                 DispPro(buf2,&lib[i].protocol));
          sprintf(buf2,"%s.sls",buf);   // Name of symbol file
          if(dolist)
            load_symbols(buf2);         // Attempt to load symbols for library
        }

        if(ah.attr & 0x8000) {
          printf("Process class: Res:0x%04x Off:0x%04x\n",ah.x2_seg,ah.x2_ofs);
          printf("App object   : Res:0x%04x Chunk:0x%04x\n",ah.tokenres_seg,ah.tokenres_item);
          if(dolist) add_global_jmp(ah.x2_seg,ah.x2_ofs,NULL,-1);
                                        // I didn't find any code here...
        }
        if(ah.attr & 0x4000) {
          printf("         Init: Res:0x%04x Off:0x%04x\n",ah.initseg,ah.initofs);
          if(dolist) add_global_jmp(ah.initseg,ah.initofs,"LibraryEntry",0);
        }
        if(ah.attr & 0x2000) {
          printf(" Driver Table: Res:0x%04x Off:0x%04x\n",
                 ah.startseg,ah.startofs);
          if(dolist) {
            add_global_jmp(ah.startseg,ah.startofs,"DriverTable",-1);
                                        // Add label for driver entry
            add_jmplist(ah.startseg,ah.startofs,4,4);
                                        // Add entry point as "jmplist"
          }
        }

        numexp=ah.numexp;               // Anzahl Exportfunktionen global machen
        expt=malloc(numexp*sizeof(*expt));
        fread(expt,ah.numexp,sizeof(*expt),f);
                                        // Exportfunktionen lesen
        if(dodump) {                    // full listing?
          for(i=0;i<ah.numexp;i++) {    // Alle Exportfunktionen durchgehen
            if(i%4==0) printf("%14s ",i?"":"Exports:");
            printf("%5d=%04x:%04x ",i,expt[i].seg,expt[i].ofs);
            if((i%4==3) || (i==ah.numexp-1)) putchar('\n');
            add_global_jmp(expt[i].seg,expt[i].ofs,NULL,0);
          }
        }
        else
          if(ah.numexp)
            printf("%14s %d locations\n","Exports:",ah.numexp);

        segbase=ftell(f);               // Start der Segmenttabelle
        numseg=ah.numseg;
        for(i=0;i<ah.numseg;i++) {
          fseek(f,segbase+sizeof(GEOSseglen)*i,SEEK_SET);
          fread(&segd[i].len,sizeof(GEOSseglen),1,f);
          fseek(f,segbase+sizeof(GEOSseglen)*ah.numseg+sizeof(GEOSsegpos)*i,SEEK_SET);
          fread(&segd[i].pos,sizeof(GEOSsegpos),1,f);
          fseek(f,segbase+(sizeof(GEOSseglen)+sizeof(GEOSsegpos))*ah.numseg
                     +sizeof(GEOSsegfix)*i,SEEK_SET);
          fread(&segd[i].fixlen,sizeof(GEOSsegfix),1,f);
          fseek(f,segbase+(sizeof(GEOSseglen)+sizeof(GEOSsegpos)+sizeof(GEOSsegfix))*ah.numseg
                     +sizeof(GEOSsegflags)*i,SEEK_SET);
          fread(&segd[i].flags,sizeof(GEOSsegflags),1,f);
                                        // Aus jeder Tabelle 1 Eintrag holen
        }

        if(dolist) {
          puts("%\n\ninclude stdapp.def\n");
          for(i=0;i<ah.numlib;i++)      // Alle Libraries durchgehen
          {
            strcpy(buf,lib[i].name);    // Library-Namen holen
            buf[GEOS_FNAME]=0;
            if(p=strchr(buf,' '))       // Remove trailing blanks
              *p='\0';
            if(stricmp(buf,"geos") && stricmp(buf,"ui"))
                                        // Create UseLib lines
              printf("UseLib %s.def\n",buf);
          }
        }
        puts("");

        disasm_silent=1;                // first runs all silent
        global_inf_changed=(dolist && !one_pass);
                                        // at least 1 additional run for listing
        do {
          if(!global_inf_changed || pass>MAX_PASSES) disasm_silent=0;
                                        // converged? Then final run is visible
          if(disasm_silent) fprintf(stderr,"Pass %d...\n",pass);
          if(!disasm_silent && dolist) {
/*
            if(n_global_jmp==MAX_GLOBAL_JMP)
              printf("; Aborted prematurely - jump table limit exceeded.\n\n");
*/
            printf("; Disassembly Passes required: %d\n\n",pass);
          }
          global_inf_changed=0;         // notice all changes in jmp list
          for(i=((one_segment>=0)?one_segment:0);
              (one_segment<0 || i<(unsigned)one_segment+1) && i<ah.numseg; i++)
          {                             // check all segments
            if(disasm_silent) fprintf(stderr,"%4d",i);
            DisplaySegment(f,ah.numseg,i);
                                        // display segment
            if(i==1 && dolist && !disasm_silent)
            {
              printf("udata\tSEGMENT\n"
                     "; uninitialized data, placed in dgroup after idata\n");
              DisplayUdata(segd[i].len,ah.stacksize);
              printf("udata\tENDS\n\n",ah.stacksize);
                                        // list "segment" for uninitialized data
            }
          }
          if(disasm_silent) fputc('\n',stderr);
          pass++;                       // count passes
        } while(global_inf_changed || disasm_silent);

        free(expt);
        free(segd);
        free(lib);
}

void DisplayDbHdr(FILE *f,long pos,unsigned size)
{
        GEOSdbheader dh;                // Header of dbmanager file

        GetStructP(dh,pos);             // Get header block
        printf("      Mem Hdl: [%04x]    Map: Group/Item:[%04x]/<%04x>  _x: %04x\n",
               dh.seg,dh.prim.group,dh.prim.item,dh.x);
}

void DisplayIdx(FILE *f,long pos,unsigned size)
{
        char *bl;
        GEOSdbidx *lh;                  // header of group index
        unsigned min_block,max_block;
        unsigned i,j,nextfree;

        bl=malloc(size);                // Allocate space for block data
        fseek(f,pos,SEEK_SET);          // Seek to block image
        fread(bl,size,1,f);             // Read block into memory
        lh=(GEOSdbidx *)bl;             // Pointer to block header
        printf("      Mem Hdl: [%04x]    Flags: %04x\n",lh->seg,lh->flags);
        if(!lh->maxitemlist) {          // no items: abort
          printf("        (empty index)\n");
          return;
        }

        min_block=0xFFFF; max_block=0;
        nextfree = lh->curitemlist;     // Next free block
        for(i=sizeof(GEOSdbidx),j=0;
            i<size;                     // should never be necessary
            i+=sizeof(GEOSdbitemlist)) {
                                        // Dump items
          while(i==nextfree && nextfree) {
            nextfree = *(unsigned short *)(bl+i);
                                        // Get pointer to next free entry
            i+=sizeof(GEOSdbitemlist);  // Skip over free entry
          }
          if(!nextfree) break;
          printf("       <%04x>: VM block [%04x], local hdl [%04x]\n",
                 i,
                 ((GEOSdbblocklist *)(bl+((GEOSdbitemlist *)(bl+i))->block))->hdl,
                 ((GEOSdbitemlist *)(bl+i))->hdl);
          min_block=min(((GEOSdbitemlist *)(bl+i))->block,min_block);
          max_block=max(((GEOSdbitemlist *)(bl+i))->block,max_block);
#if 0
          if(++j==64) {
            j=0;
            i+=30;
          }
#endif
        }

        for(i=min_block;i<=max_block;i+=sizeof(GEOSdbblocklist))
                                        // Dump blocks
          printf("   block %04x: VM block [%04x],%3d items  _x: %04x\n",
                 i,((GEOSdbblocklist *)(bl+i))->hdl,
                   ((GEOSdbblocklist *)(bl+i))->num,
                   ((GEOSdbblocklist *)(bl+i))->_x);

        free(bl);                       // Release memory for lists
}

void DisplayVMFile(FILE *f)
{
        GEOSvmfheader vh;               // VM-Dateikopf
        GEOSvmfdirheader dh;            // Kopf des VM-DIR-Blocks
        GEOSvmfdirrec dr;               // Einzelner Eintrag im VM-DIR-Block
        int i;
        unsigned idx,hdl;
        long pos;
        long totalUsed,totalFree;

        GetStructP(vh,(ver==1)?0xC0:(base-8));
                                        // Dateikopf holen
        if(vh.IDVM!=GEOS_IDVM) {
          printf("Invalid VM file.\n");
          return;
        }
        printf("\n VM Directory: @ 0x%06lx   Length: %d bytes\n",
               vh.dirptr+base,vh.dirsize);

        GetStructP(dh,vh.dirptr+base);  // Kopf des DIR-Blocks holen
        printf("\n  Blocks free: %-25d"
                 " Handles free: %d"
               "\n  Blocks used: %-23d"
               "Blocks attached: %d"
               "\n   Total size: %ld Bytes"
               "\n        Flags: %04x\n",
               dh.nblocks_free,dh.nhdls_free,dh.nblocks_used,dh.nblocks_loaded,
               dh.totalsize,dh.flags);
        Hexdump(dh._x2); Hexdump(dh._x2b);

        printf("\n Map Block Hdl: [%04x]  DBMap Block Hdl: [%04x]\n"
                 "1st free block: [%04x]  last free block: [%04x]"
               "  1st free Hdl: [%04x]\n",
               dh.hdl_first,dh.hdl_dbmap,
               dh.hdl_1stfree,dh.hdl_lastfree,dh.hdl_1stunused);
        if(dolist) puts("%");
        puts("");

        idx=0;                          // Laufender Z�hler f�r Handle-Rechnung
        totalUsed=totalFree=0;
        for(i=(dh.dirsize-sizeof(dh))/sizeof(dr);i;i--) {
                                        // Alle DIR-Eintraege durchgehen
          GetStruct(dr);                // Einen Block-Eintrag holen
          printf("[%04x]: ",GeosIdx2Hdl(idx));
          if(dr.blocksize) {            // Belegter Block
            totalUsed += dr.blocksize;  // Blockgr��e aufsummieren
            printf("     @ 0x%06lx %5d bytes  MemHdl: %04x  UserID: %04x\n",
                   dr.blockptr+base,dr.blocksize,dr.used.hdl,dr.used.ID);
            if(dr.used.flags!=0x00FF) { // Ungew�hnliche Flags?
              printf("             Flags: %04x",dr.used.flags);
                                        // Flags ausgeben und aufschl�sseln
              if(dr.used.flags & 0x100) printf(", LMem heap");
              if(dr.used.flags & 0x200) printf(", unSAVEed");
              if(!(dr.used.flags & 4))  printf(", Changes in [%04x]",
                                               dr.used.ID);
              printf("\n");
            }
            if(dodump) {
              if(idx==0)                // Directory nicht mehr dumpen
                printf("        (Handle directory)\n");
              else {
                if(GeosIdx2Hdl(idx)==dh.hdl_first)
                  printf("        (Map block)\n");
                if(GeosIdx2Hdl(idx)==dh.hdl_dbmap)
                  printf("        (DBMap block)\n");
                                        // Map-Bl�cke markieren

                pos=ftell(f);           // Position merken
                GetStructP(hdl,dr.blockptr+base);
                                        // erste Bytes des Blocks lesen
                fseek(f,pos,SEEK_SET);  // Zur�ck zur Position in Tabelle
                if(dr.used.flags&0x100) // Block mit lokalem Heap?
                  DisplayHeap(f,dr.blockptr+base,dr.blocksize);
                                        // Ja: Im Heap-Format ausdumpen
                else if(GeosIdx2Hdl(idx)==dh.hdl_dbmap)
                                        // DBManager-Map Block
                  DisplayDbHdr(f,dr.blockptr+base,dr.blocksize);
                else if(dr.used.ID==0xFF01)
                  DisplayIdx(f,dr.blockptr+base,dr.blocksize);
                else
                  DispFile(f,dr.blockptr+base,dr.blocksize,0,-2);
                                        // Als Hexdatei ausdumpen
                fseek(f,pos,SEEK_SET);  // Zur�ck zur Position in Tabelle
              }
              printf("\n");
            }
          }
          else if(dr.blockptr) {        // Freier Block
            totalFree += dr.free.size;
            printf("free @ 0x%06lx %5d bytes   "
                   "Previous: [%04x]  Next: [%04x]\n",
                   dr.blockptr+base,dr.free.size,dr.free.prev,dr.free.next);
          }
          else                          // Freier Eintrag
            printf("**** (unused)\n");
          idx++;
        }
        printf("\nTotal in blocks: %ld Bytes (%ld used, %ld free)\n",
               totalUsed+totalFree,totalUsed,totalFree);
}

/*****************************************************************************
 *      Routines for displaying the common GEOS file header and choosing the
 *      type of file to use for dumping.
 *****************************************************************************/
void DisplayGeosFile(FILE *f)
{
        union {
          GEOSheader h1;
          GEOS2header h2;
        } hd;                         // Standard-Dateikopf
        char buf1[80],buf2[80];
        unsigned class;
        long magic;

        /* Description of some file attributes */
        struct MaskDesc_s fileAttrMask[] = {
           {0x8000,0x8000,"Template"},
           {0x4000,0x4000,"Public Multiple"},
           {0x2000,0x2000,"Public Single"},
           {0x0800,0x0800,"Hidden"},
           {0,0,NULL}};

        fseek(f,0,SEEK_SET);            // Anfang einlesen
        fread(&magic,sizeof(magic),1,f);
        if(magic==BSWF_ID)              // Ist es ein Font?
        {
          DisplayBSWF(f);               // Ja: ausgeben
          return;
        }

        fseek(f,0,SEEK_SET);            // Anfang neu einlesen
        fread(&hd,sizeof(hd),1,f);
        if(hd.h1.ID==GEOS_ID) {         // G1-Identifikation stimmt?

/*** Version 1 header ***/
          GeosToIBM(hd.h1.name,1);      // Zeichensatz konvertieren
          GeosToIBM(hd.h1.info,1);
          GeosToIBM(hd.h1._copyright,1);
          printf("         Name: %-36s       Token: %s\n",hd.h1.name,DispTok(buf1,&hd.h1.token));
          printf("GEOS filetype: %-36s Application: %s\n",(hd.h1.class==0)?"Executable (1.x)":"VM file (1.x)",DispTok(buf1,&hd.h1.appl));
          printf("      Release: %-36s    Procotol: %s\n",DispRel(buf1,&hd.h1.release),DispPro(buf2,&hd.h1.protocol));
          printf("        Flags: %04x\n",hd.h1.flags);
          if(*hd.h1.info) {             // Evtl. Info ausgeben
            strtrunc(hd.h1.info,60);    // Vor Ausgabe auf 60 Zeichen k�rzen
            printf("    User info: %s\n",hd.h1.info);
          }
          if(*hd.h1._copyright)  {      // Evtl. Copyright ausgeben
            strncpy2(buf1,hd.h1._copyright,sizeof(hd.h1._copyright));
            printf("    Copyright: %s\n",buf1);
          }

          ver=1;
          base=0;
          class=hd.h1.class;            // Dateityp speichern
        }
        else if(hd.h2.ID==GEOS2_ID) {   // G2-Identifikation stimmt?

/*** Version 2 header ***/
          GeosToIBM(hd.h2.name,1);      // Zeichensatz konvertieren
          GeosToIBM(hd.h2.info,1);
          GeosToIBM(hd.h2._copyright,1);
          printf("         Name: %-36s       Token: %s\n",hd.h2.name,DispTok(buf1,&hd.h2.token));
          printf("GEOS filetype: %-36s Application: %s\n",
            (hd.h2.class==1)?"Executable (2.x)":
            (hd.h2.class==2)?"VM file (2.x)":
            (hd.h2.class==3)?"Byte level file":
            (hd.h2.class==4)?"Directory info file":
            (hd.h2.class==5)?"Link":
                             "???",
            DispTok(buf1,&hd.h2.appl));
          printf("      Release: %-36s    Procotol: %s\n",DispRel(buf1,&hd.h2.release),DispPro(buf2,&hd.h2.protocol));
          printf("      Created: %02d/%02d/%04d  %02d:%02d.%02d",
            hd.h2.create_date.m,hd.h2.create_date.d,1980+hd.h2.create_date.y,
            hd.h2.create_time.h,hd.h2.create_time.m,2*hd.h2.create_time.s_2);
          if(*hd.h2.password) {         // Evtl. Password ausgeben
            strncpy2(buf1,hd.h2.password,sizeof(hd.h2.password));
            printf("                    Password: %s",buf1);
          }
          putchar('\n');
          printf("        Flags: %s\n",
            DispBitMask(buf1,hd.h2.flags,fileAttrMask,","));
          if(*hd.h2.info) {             // Evtl. Info ausgeben
            strtrunc(hd.h2.info,60);    // Vor Ausgabe auf 60 Zeichen k�rzen
            printf("    User info: %s\n",hd.h2.info);
          }
          if(*hd.h2._copyright) {       // Evtl. Copyright ausgeben
            strncpy2(buf1,hd.h2._copyright,sizeof(hd.h2._copyright));
            printf("    Copyright: %s\n",buf1);
          }

          ver=2;                        // GW-Version
          base=sizeof(GEOS2header);
          class=hd.h2.class;            // Dateityp zur�ckgeben
        }
        else
        {
          puts("Not a PC/GEOS file.");
          return;                       // Unbekannt: Abbruch
        }

        if((class==0 && ver==1) || (class==1 && ver!=1))
                                        // Dateityp "Applikation"
          DisplayApplication(f);        // Applikationsspezifische Informationen
        else if((class==1 && ver==1) || (class==2 && ver!=1))
                                        // Dateityp "VM-Datei"
          DisplayVMFile(f);             // Dateispezifische Informationen
}

void main(int argc,char *argv[])
{
        FILE *f;
        char path[_MAX_PATH],drive[_MAX_DRIVE],dir[_MAX_DIR],
             name[_MAX_FNAME],ext[_MAX_EXT],*p;
        int i;

        dodump=dolist=0;                // default: kein Dump
        one_pass=0;                     // do as many passes as required
        one_segment=-1;                 // dump all segments

        init_disasm();                  // initialize disassenbly module

        i=1;
        while(argc>i && (argv[i][0]=='-')) {
          switch(toupper(argv[i][1])) {
          case 'L':
            dolist=1;                   // '/L'-Switch: Listing
            dodump=1;                   // impliziert Dump
            break;
          case 'D':
            dodump=1;                   // '/D'-Switch: Dumpen
            break;
          case 'R':
            one_segment=(int)strtol(argv[i]+2,&p,10);
            break;                      // '/R<resource>': nur 1 Segment
          case '1':                     // '/1': one pass only
            one_pass=1;
            break;
          }
          i++;                          // Parameter �bergehen
        }
        if(argc<=i) {                   // Zu wenig Parameter?
          puts("\nGeoDump 0.5 -=- by Marcus Gr�ber, "__DATE__"\n"
                 "Disassembly engine based on a module by Robin Hilliard\n\n"
                 "Analysis of PC/Geos file formats\n");

          puts("Syntax: GEODUMP [/D|/L] [/Rnn] [/1] filename\n"
               "\t  -D      Dump contents of blocks/resources\n"
               "\t  -L      List code resources or font outlines (includes /D)\n"
               "\t  -Rnn    List/dump only resource number nn (dec.)\n"
               "\t  -1      List in first pass"
          );
          exit(1);
        }

	printf("argv[i]: %s\n", argv[i]);
        _splitpath(argv[i],drive,dir,name,ext);
        if(*ext=='\0')                  // Extension fehlt: GEO annehmen
          strcpy(ext,".GEO");
        _makepath(path,drive,dir,name,ext);

        if(!(f=fopen(path,"rb"))) {     // Datei zum Lesen �ffnen
          puts("File not found.");
          exit(1);                      // Datei fehlt? Fehlermeldung
        }

        if(dolist)                      // Header wird auskommentiert
          puts("comment %");
        printf("\n\t\t\t    Dump of %s%s\n\n",name,ext);
                                        // �berschrift
        DisplayGeosFile(f);             // Datei anzeigen
        fclose(f);                      // Datei schlie�en

        deinit_disasm();                // release data used by disassembly mod
}
