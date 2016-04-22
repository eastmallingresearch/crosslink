#ifndef __RJV_CUTILS_H__

long int get_time();
void rjverr(const char*message);

void parseend(int argc,char*argv[]);
void parseint(int argc,char*argv[],const char*name,int*p,unsigned hasdef,int defval);
void parseuns(int argc,char*argv[],const char*name,unsigned*p,unsigned hasdef,unsigned defval);
void parsedbl(int argc,char*argv[],const char*name,double*p,unsigned hasdef,double defval);
void parsestr(int argc,char*argv[],const char*name,char**p,unsigned hasdef,const char*defval);

#endif
