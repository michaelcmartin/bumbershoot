program Hat4;

{$N+}

uses SysTimer;

{ This final Pascal edition of the HAT function uses a custom assembly
  language routine for drawing parts of the graph. HatSlab puts a
  white dot at the listed location and then black dots on all
  locations directly below it.

  Experimentation showed that this implementation was the fastest of
  the Pascal builds. }

procedure CgaStart; external;
procedure CgaEnd; external;
procedure HatSlab(x, y:integer); external;
procedure WaitForKey; external;

{$L HATAUX.OBJ}

var p, q, gr, gm, xp, yp, yr, zp, zi, zz, xl, xi, x1, y1:integer;
    xr, xf, yf, zf, zt, xx, xt, yy:double;
    start, finish:real;
    c:char;

begin
    CgaStart;
    start := SysTime;
    p := 160; q := 100;
    xp := 144; xr := 1.5*Pi; yp := 56; yr := 1; zp := 64;
    xf := xr/xp; yf := yp/yr; zf := xr/zp;
    for zi := -q to q-1 do
        if ((zi >= -zp) and (zi <= zp)) then begin
            zt := zi * xp/zp; zz := zi;
            xl := Round(0.5 + Sqrt(xp*xp-zt*zt));
            for xi := -xl to xl do begin
                xt := sqrt(xi*xi+zt*zt) * xf; xx := xi;
                yy :=(sin(xt)+0.4*sin(3*xt))*yf;
                x1 := Round(p - xx - zz);
                y1 := Round(q - yy + zz);
                HatSlab(x1, y1);
            end;
        end;
    finish := SysTime;
    WaitForKey;
    CgaEnd;
    WriteLn('Start time: ', start:5:2);
    WriteLn('Finish time: ', finish:5:2);
    WriteLn('Total execution time: ', (finish - start):5:2);
end.
