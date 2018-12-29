#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc,char *argv[])
{
        char buf[256],*p;
        char *label,*proc;
        unsigned seg,seg_valid;
        unsigned ofs;

        seg=0;                          // No segment read yet
        seg_valid=0;
        while(fgets(buf,sizeof(buf),stdin))
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
            p=strtok(buf,"\n\r");
            printf("; %s\n",p);
          }
          else
          {
            label=strtok(buf," :\t\n\r");
                                        // first word in line
            p=strtok(NULL,"\t\n\r");    // remainder of line
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
        }
        return 0;                       // no error
}
