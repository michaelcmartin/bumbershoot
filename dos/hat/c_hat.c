/* C_HAT - C implementation of the HAT function
 *
 * This is a straightforward translation of HAT4.PAS into C, with its
 * own set of assembly-language support routines rewritten to use near
 * calls and respect the C ABI instead of the Pascal one.
 */

#include <math.h>
#include <stdio.h>

/* Declare the functions defined in the assembly language file */
void cga_start();
void cga_end();
void wait_for_key();
void hat_slab(int x, int y);
long get_msdos_time();

int main()
{
    double start = get_msdos_time() / 100.0;
    int p = 160;
    int q = 100;
    int xp = 144;
    int yp = 56;
    int zp = 64;
    int yr = 1;
    double xr = 1.5*3.14159265358979323846;
    double xf = (double)xr/(double)xp;
    double yf = (double)yp/(double)yr;
    int zi;
    double finish;
    cga_start();
    for (zi = -q; zi < q; ++zi) {
        if ((zi >= -zp) && (zi <= zp)) {
            double zt = (double)zi * (double)xp/(double)zp;
            int zz = zi;
            int xl = 0.5 + sqrt((double)xp*(double)xp-zt*zt);
            int xi;
            for (xi = -xl; xi <= xl; ++xi) {
                double xt = sqrt(xi*xi+zt*zt) * xf;
                double xx = xi;
                double yy =(sin(xt)+0.4*sin(3*xt))*yf;
                int x1 = p - xx - zz;
                int y1 = q - yy + zz;
                hat_slab(x1, y1);
            }
        }
    }
    finish = get_msdos_time() / 100.0;
    wait_for_key();
    cga_end();
    printf("Start time: %5.2lf\nFinish time: %5.2lf\nTime spent: %5.2lf", start, finish, finish-start);
    return 0;
}
