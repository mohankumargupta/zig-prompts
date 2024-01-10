#include "getch_windows.h"

int getch() {
    int d =-1, e=-1;
    d = _getch();
    // Arrow keys and num keys produce 2 key scan codes 
    if (d == 224 || d == 0) {
      e = _getch();
      return e;   
    }
    return d;
}
