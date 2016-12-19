!to "galaxy.nes",plain
*=$0000
;; iNES header
!8 $4e,$45,$53,$1a,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!source "macros.s"

        !set    data=$00
        !addr   sprites=$700

!pseudopc $c000 {
        !source "input.s"
        !source "random.s"
        !source "util.s"
        !source "main.s"
        !source "title.s"
        !source "instructions.s"
        !source "game.s"
        ;; Interrupt vectors
        !fill $fffa-*, 0
        !16 vblank, reset, irq
        !if data > $100 {
                !error "Zero page data has spilled over by ", $100-data, " bytes!"
        }
        !if * != $0000 {
                !error "PC is ", *, ", expected 0"
        }
}

!pseudopc $0000 {
        !source "graphics.s"
        !if * != $2000 {
                !error "Pattern table was ",*," bytes long, expected $2000"
        }
}
