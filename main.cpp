#include <stdio.h>
#include <math.h>

extern "C" void MyPrintf(const char *const str, ...);

int main()
{
    // printf("%b\n", 505);

    // MyPrintf("Этот принтф \n%s %s \nи их число больше %d и %d\n"                                 
    //          "вот например число %c: \t\t%f\n" 
    //          "число -P:\t\t\t%f\n"
    //          "%s если хотите:    \t%f\n"
    //          "и %cбесконечность: \t\t%f\n"
    //          "можно %s: \t\t\t%f\n"
    //          "оч маленькое 1e-%d \t\t%f\n"
    //          "и оч большое 1e%d\t\t%f\n"
    //          "ещё чисел %f %d %f %d\n"
    //          "hex %x, oct %o, bin %b\n"
    //          "может хватит с него уже\n\n\n",
    //     "получил самые разнообразные", "целочисленные и дробные аргументы", 5, 8, 'P',
    //     M_PI, -M_PI, "бесконечность", INFINITY, '-', -INFINITY, "nan", NAN, 6, 1e-6, 8, 1e8, 1.23, -777, 4.56, 888,
    //     123, 456, 789);

    MyPrintf ("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30);


    return 0; 
}       