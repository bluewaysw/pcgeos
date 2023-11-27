/*
        DUMPFONT.C

        by Marcus Gr�ber 1991-95

        Creates structured dumps of PC/Geos files (Geodes, VM Files, fonts)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <malloc.h>

#include "geos.h"
#include "geos2.h"

extern unsigned dodump,dolist;

char *GeosToIBM(unsigned char *s,int approx);
void DispFile(FILE *f,long pos,unsigned len,unsigned ofs,long hdl);


#define GetStruct(str)      fread(&(str),sizeof(str),1,f)
#define GetStructP(str,ptr) fseek(f,ptr,SEEK_SET);fread(&(str),sizeof(str),1,f)

void DisplayChar(FILE *f,long pos,unsigned size)
{
        NimbusData chdr;                /* character header */
        NimbusTuple hint;               /* one hint tuple */
        NimbusLineData argMoveLine;
        NimbusBezierData argBezier;
        NimbusAccentData argAccent;
        int short argVHLine;
        NimbusRelLineData argRelLine;
        NimbusRelBezierData argRelBezier;
        char nhints,i;
        char opcode;

        GetStructP(chdr,pos);           /* get character header */
        printf(" Bounding box: (%d,%d)-(%d,%d)\n",
          chdr.ND_xmin,chdr.ND_ymin,chdr.ND_xmax,chdr.ND_ymax);
        GetStruct(nhints);
        if(nhints)
          printf(" Horizontal hints:\n");
        for(i=0; i<nhints; i++)
        {
          GetStruct(hint);
          printf("   x1=%d, x2=%d, width=%d\n",
            hint.NT_start,hint.NT_end,hint.NT_width);
        }
        GetStruct(nhints);
        if(nhints)
          printf(" Vertical hints:\n");
        for(i=0; i<nhints; i++)
        {
          GetStruct(hint);
          printf("   y1=%d, y2=%d, height=%d\n",
            hint.NT_start,hint.NT_end,hint.NT_width);
        }

        printf(" Character outline:\n");
        do {
          GetStruct(opcode);
          switch(opcode)
          {
            case NIMBUS_MOVE:
              GetStruct(argMoveLine);
              printf("   MOVE (%d,%d)\n",argMoveLine.NLD_x,argMoveLine.NLD_y);
              break;
            case NIMBUS_LINE:
              GetStruct(argMoveLine);
              printf("   LINE (%d,%d)\n",argMoveLine.NLD_x,argMoveLine.NLD_y);
              break;
            case NIMBUS_BEZIER:
              GetStruct(argBezier);
              printf("   BEZIER (%d,%d),(%d,%d),(%d,%d)\n",
                argBezier.NBD_x1,argBezier.NBD_y1,argBezier.NBD_x2,
                argBezier.NBD_y2,argBezier.NBD_x3,argBezier.NBD_y3);
              break;
            case NIMBUS_DONE:
              printf("   DONE\n");
              break;
            case NIMBUS_ILLEGAL:
              printf("   ILLEGAL\n");
              break;
            case NIMBUS_ACCENT:
              GetStruct(argAccent);
              printf("   ACCENT %d,(%d,%d),%d\n",
                argAccent.NAD_char1,argAccent.NAD_x,argAccent.NAD_y,
                argAccent.NAD_char2);
              break;
            case NIMBUS_VERT_LINE:
              GetStruct(argVHLine);
              printf("   VERT_LINE %d\n",argVHLine);
              break;
            case NIMBUS_HORZ_LINE:
              GetStruct(argVHLine);
              printf("   HORZ_LINE %d\n",argVHLine);
              break;
            case NIMBUS_REL_LINE:
              GetStruct(argRelLine);
              printf("   REL_LINE (%d,%d)\n",
                argRelLine.NRLD_x,argRelLine.NRLD_y);
              break;
            case NIMBUS_REL_CURVE:
              GetStruct(argRelBezier);
              printf("   REL_CURVE (%d,%d),(%d,%d),(%d,%d)\n",
                argRelBezier.NRBD_x1,argRelBezier.NRBD_y1,argRelBezier.NRBD_x2,
                argRelBezier.NRBD_y2,argRelBezier.NRBD_x3,argRelBezier.NRBD_y3);
              break;
          }
        } while(opcode!=3 && opcode!=5);
        putchar('\n');
}

void DisplayBSWF(FILE *f)
{
        BSWFheader hdr;
        my_PointSizeEntry facex;
        my_OutlineDataEntry face;
        NimbusNewFontHeader nfh;        // typeface info header
        NimbusNewWidth nw[256];         // character width array
        unsigned short charOfs[256];          // pointer to character shapes
        struct s_kerntab {
          struct {
            unsigned char c1,c2;
          } pair;                       // character pair
          short int kern;
        } *kerntab;
        unsigned short n_kern;

        unsigned long pos;
        long size,tsize=0;
        unsigned short ch,ch2,len,pos2;
        char buf[]=" ",buf2[]=" ";

        fseek(f,0,SEEK_SET);            // Read from top of file
        fread(&hdr,sizeof(hdr),1,f);    // Read header of font file
        printf("    Font Name: %s\n",hdr.name);
        printf("      Font ID: %04X\n",hdr.fontID);
        printf("       Family: %02X - Rasterizer: %04X\n",
          (unsigned char)hdr.family,hdr.rasterizer);

        if(hdr.outlineTab)
        {
          printf("\n*** Outline data ***\n");
          for(pos=hdr.outlineTab; pos<hdr.outlineEnd; pos+=sizeof(face))
          {
            GetStructP(face,pos+6);
            size=face.ODE_headerSize+face.ODE_firstSize+face.ODE_secondSize;

            printf("        Style: %02X - Weight: %02X",
              face.ODE_style,face.ODE_weight);

            if(dodump)
            {
              putchar('\n');

              // Read header
              GetStructP(nfh,face.ODE_headerPos);
                                        
              // Read width table
              fread(nw+nfh.NFH_firstchar,sizeof(nw[0]),nfh.NFH_numchars,f);

              // Read kern pairs if available
              n_kern=((unsigned)face.ODE_headerSize
                -sizeof(nfh)-sizeof(nw[0])*nfh.NFH_numchars)/4;
              if(n_kern)
              {
                printf("Kerning: (%d pairs)\n",n_kern);
                if(dolist)
                {
                  kerntab=(struct s_kerntab *)calloc(n_kern,sizeof(*kerntab));
                                        // reserve space for kerning table
                  for(pos2=0; pos2<n_kern; pos2++)
                    fread(&kerntab[pos2].pair,sizeof(kerntab[0].pair),1,f);
                  for(pos2=0; pos2<n_kern; pos2++)
                    fread(&kerntab[pos2].kern,sizeof(kerntab[0].kern),1,f);
                  for(pos2=0; pos2<n_kern; pos2++)
                  {
                    buf[0]=kerntab[pos2].pair.c1;
                    GeosToIBM(buf,0);
                    buf2[0]=kerntab[pos2].pair.c2;
                    GeosToIBM(buf2,0);
                    printf("  %u ('%c') / %u ('%c'): %d\n",
                      kerntab[pos2].pair.c2,*buf2,kerntab[pos2].pair.c1,*buf,
                      kerntab[pos2].kern);
                  }
                  free(kerntab);        // free kerning table
                  putchar('\n');
                }
              }

              if(nfh.NFH_firstchar<0x80)
              {
                fseek(f,face.ODE_firstPos,SEEK_SET);
                fread(charOfs+nfh.NFH_firstchar,2,0x80-nfh.NFH_firstchar,f);
              }
              if(nfh.NFH_lastchar>0x7F)
              {
                fseek(f,face.ODE_secondPos,SEEK_SET);
                fread(charOfs+0x80,2,nfh.NFH_lastchar-0x7F,f);
              }

              for(ch=nfh.NFH_firstchar; ch<=nfh.NFH_lastchar; ch++)
              {
                if(charOfs[ch]==0)      // ignore undefined characters
                  continue;
                if(ch==0x7F || (ch==nfh.NFH_lastchar && ch<0x80))
                  len=(unsigned)face.ODE_firstSize-charOfs[ch];
                else if(ch==nfh.NFH_lastchar)
                  len=(unsigned)face.ODE_secondSize-charOfs[ch];
                else
                {
                  len=charOfs[ch+1]-charOfs[ch];
                  if(charOfs[ch+1]==0)
                  {
                    pos2=(unsigned)face.ODE_secondSize;
                    for(ch2=ch+1; ch2<=nfh.NFH_lastchar; ch2++)
                      if(ch2==0x80)
                      {
                        pos2=(unsigned)face.ODE_firstSize;
                        break;
                      }
                      else if(charOfs[ch2])
                      {
                        pos2=charOfs[ch2];
                        break;
                      }
                    len=pos2-charOfs[ch];
                  }
                }
                buf[0]=(char)ch;        // convert character to IBM
                GeosToIBM(buf,0);
                printf("Character: %d ('%s') - Width: %d - Flags: %02x\n",
                  ch,buf,nw[ch].NW_width,nw[ch].NW_flags);

                if(hdr.rasterizer==0x1000 && dolist)
                  DisplayChar(f,
                    ((ch<0x80)?face.ODE_firstPos:face.ODE_secondPos)
                      +charOfs[ch],len);
              }
            }
            else
              printf(" - Total size: %ld bytes\n",size);

            tsize+=size;
          }
        }

        if(hdr.pointSizeTab)
        {
          printf("\n*** Raster (point size) data ***\n");
          for(pos=hdr.pointSizeTab; pos<hdr.pointSizeEnd; pos+=sizeof(facex))
          {
            GetStructP(facex,pos+6);

            printf("   Data block: @ %08lx - Size: %5u bytes "
                   "- Style: %02X - Pointsize: %02X%02X.%02X\n",
              facex.PSE_filePos,facex.PSE_dataSize,facex.PSE_style,
              facex.PSE_pointSize[0],facex.PSE_pointSize[1],
              facex.PSE_pointSize[2]);
            if(dolist)
              DispFile(f,facex.PSE_filePos,facex.PSE_dataSize,0,-1);
            tsize+=facex.PSE_dataSize;
          }
        }

        putchar('\n');

        // compute "missing" size
        fseek(f,0,SEEK_END);        // go to EOF
        printf(" Missing size: %ld bytes\n",ftell(f)
          -tsize
          -(hdr.pointSizeEnd-hdr.pointSizeTab)
          -(hdr.outlineEnd-hdr.outlineTab)
          -sizeof(hdr));
}
