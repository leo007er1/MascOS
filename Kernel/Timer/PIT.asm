[bits 16]
[cpu 8086]



; *Byte to insert in Mode/Command register at I/O port 0x43:
; Bits 7-6: channel             00
; Bits 5-4: access mode         11
; Bits 3-1: operating mode      010
; Bit 0: BCD or binary mode     0
;
; Which gives us: 00110100



; I don't understand anything about this


InitPit:
    


    ret
