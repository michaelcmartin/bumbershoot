        .outfile "simevo.xex"

        .alias  start   $2000
        .alias  bssstart $3000
        .alias  bitmap  $4000

        .word   $ffff, start, end-1
        .org    start

        .include "simevo_a800_shell.s"

end:    .word   $02e0, $02e1, start
