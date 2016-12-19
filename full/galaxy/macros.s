!macro define ~.seg, ~.name, .size {
        !addr .name = .seg
        !set  .seg = .seg + .size
}

!macro mov16 .dest, .val {
        lda     #<.val
        sta     .dest
        lda     #>.val
        sta     .dest+1
}

!macro inc16 .dest, .val {
        clc
        lda     .dest
        adc     #<.val
        sta     .dest
        lda     .dest+1
        adc     #>.val
        sta     .dest+1
}
