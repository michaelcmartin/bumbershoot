unit SysTimer;

interface

{ Return the system time, in hundredths of a second since midnight. }
function SysTime:real;

implementation

uses Dos;

function SysTime:real;
var regs:registers;
    result:real;
begin
    regs.ah := $2C;
    MsDos(regs);
    result := regs.ch;
    result := result * 3600;
    result := result + regs.cl * 60 + regs.dh + regs.dl / 100;
    SysTime := result
end;

begin
end.
