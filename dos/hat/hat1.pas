program Hat;

{$N+}

uses Crt, Graph, SysTimer;

procedure DrawPiece(p, q:integer; xx, yy, zz:double);
var x1, y1:integer;
begin
    x1 := Round(p - xx - zz);
    y1 := Round(q - yy + zz);
    PutPixel(x1, y1, 3);
    SetColor(0);
    Line(x1, y1+1, x1, 200);
end;

var p, q, gr, gm, xp, yp, yr, zp, zi, zz, xl, xi:integer;
    xr, xf, yf, zf, zt, xx, xt, yy:double;
    start, finish:real;
    c:char;

begin
    gr := CGA;
    gm := 1;
    InitGraph(gr, gm, '');
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
    c := ReadKey;
    CloseGraph;
    WriteLn('Start time: ', start:5:2);
    WriteLn('Finish time: ', finish:5:2);
    WriteLn('Total execution time: ', (finish - start):5:2);
end.