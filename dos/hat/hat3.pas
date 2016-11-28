program Hat3;

{ This implementation switches to a 100%-ASM CGA driver, linked in as
  a module in its own right. }

{$N+}

uses CgaAsm, KeyWait, SysTimer;

procedure DrawPiece(p, q:integer; xx, yy, zz:double);
var x1, y1, i:integer;
begin
    x1 := Round(p - xx - zz);
    y1 := Round(q - yy + zz);
    CgaPixel(x1, y1, 3);
    for i := y1+1 to 199 do
        CgaPixel(x1, i, 0)
end;

var p, q, gr, gm, xp, yp, yr, zp, zi, zz, xl, xi:integer;
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
                DrawPiece(p, q, xx, yy, zz);
            end;
        end;
    finish := SysTime;
    WaitForKey;
    CgaEnd;
    WriteLn('Start time: ', start:5:2);
    WriteLn('Finish time: ', finish:5:2);
    WriteLn('Total execution time: ', (finish - start):5:2);
end.
