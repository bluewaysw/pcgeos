#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc,char *argv[])
{
        char *buf = NULL;
        char *p,*label,*proc;
        size_t len = 0;
        unsigned short seg,seg_valid;
        unsigned short ofs;
        int nread = 0;
        FILE *f = fopen(argv[1], "r");

        seg=0;                          // No segment read yet
        seg_valid=0;
        while((nread = getline(&buf,&len,f)) != -1)
        {
          if(strncmp(buf,"Segment ",8)==0)
          {
            if(strstr(buf,"type public") || strstr(buf,"type resource") ||
               strstr(buf,"type lmem"))
            {
              seg++;
              seg_valid=seg;
            }
            else
              seg_valid=0;
          }
          else if(strncmp(buf,"protocol:",9)==0)
          {
            strtok(buf,"\n");
            printf("; %s\n", buf);
          }
          else
          {
            label=strtok(buf," : ");
            p = strtok(NULL, "\n");
            if (p == NULL) continue;

            proc=strstr(p,"procedure at ");

            /* translate procedure entries */
            if(seg_valid && proc)
            {
              ofs=(unsigned)strtol(proc+13,&p,16);
              printf("C %u %x %s\n",seg_valid,ofs,label);
            }

            /* translate variable entries */
            proc=strstr(p,"variable at ");
            if(seg_valid && proc)
            {
              ofs=(unsigned)strtol(proc+12,&p,16);
              printf("D %u %x %s\n",seg_valid,ofs,label);
            }
          }
          fflush(stdout);
        }
        return 0;                       // no error
}
