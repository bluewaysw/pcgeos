#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _LINUX
#define LINE_ENDING "\n"
#else
#define LINE_ENDING "\n\r"
#endif

int main(int argc,char *argv[])
{
        char buf[256],lib[256],*label,*proc,*cls,*p;
        unsigned short ord;

        *lib=0;                         // no library read yet
        while(fgets(buf,sizeof(buf),stdin))
        {
          if(strncmp(buf,"Segment ",8)==0)
          {
            p=strtok(buf," \t,:LINE_ENDING");
            p=strtok(NULL," \t,:LINE_ENDING");
            p=strtok(NULL," \t,:LINE_ENDING");
            p=strtok(NULL," \t,:LINE_ENDING"); // fourth word is lib name
            strcpy(lib,p);              // store library name
          }
          else if(strncmp(buf,"protocol:",9)==0)
          {
            p=strtok(buf,LINE_ENDING);
            printf("; %s\n",p);
          }
          else
          {
            label=strtok(buf," \tLINE_ENDING");
                                        // first word in line
            p=strtok(NULL,"\tLINE_ENDING");    // remainder of line
            proc=strstr(p,"procedure at ");
            cls=strstr(p,"class at ");
            if(*lib && (proc || cls) && strstr(p,"global entry"))
            {
              ord=(unsigned short)strtol(proc?(proc+13):(cls+9),&p,16);
              printf("%s %u %s\n",lib,ord,label);
            }
          }
        }
        return 0;                       // no error
}
