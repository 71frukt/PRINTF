#include <stdio.h>

extern "C" void MyPrintf(const char* str, ...);

int main()
{
    MyPrintf("PARASHA %s %d %b %o |%h|\n", "str", 666, 12, 777, 123);
    
    // MyPrintf("PARASHA %d \n", 666);

    return 0; 
}       