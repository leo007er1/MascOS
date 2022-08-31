[bits 16]
[cpu 286]


; *NOTES
; *FAT on disk looks like this:
; *-------------------------------------------------------------------------------
; *| Boot sector | Extra reserved sectors | FAT1 | FAT2 | Root dir | Data region |
; *-------------------------------------------------------------------------------
;
; *How to calculate start point of root directory:
; ReservedSectors + (NumberOfFATs * SectorsPerFAT) = 19
; *How to calculate the size of the root dir:
; 32(entry size) * RootDirEntries / BytesPerSector
;
; *How to convert LBA to CHS:
; sector = (LBA % SectorsPerTrack) + 1
; head = (LBA / SectorsPerTrack) % Heads
; track = LBA / (SectorsPerTrack * Heads)
;
; I saw online that entries with a file attribute of 0xf are "fake" ones to use for long file names
;
; *Useful stuff:
; https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html


; We load only the first FAT and reserve 4.5KB to it
FATMemLocation equ 0x500
; We load the root directory after the IVT and reserve 7KB to it
RootDirMemLocation equ 0x1700




; Reads the disk into the specified buffer in memory
; Input:
;   bx = buffer offset
;   al = sectors to read
ReadDisk:
    call ResetDisk

    ; Buffer to read to(ES:BX) is already set

    mov ah, 0x02 ; Read please
    ; Sectors to read are alraady set
    mov dl, byte [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    stc
    int 0x13
    jc .Check ; Carry flag set
    jmp .Exit
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add [ReadAttempts], byte 1 ; If I use inc I get and error
        cmp [ReadAttempts], byte 3
        je ReadDiskError

        jmp ReadDisk

    .Exit:
        mov [ReadAttempts], byte 0
        ret



; Loads the first FAT
LoadFAT:
    ; FATs are just after the reserved sectors, so...
    mov ax, word [ReservedSectors]
    call LbaToChs

    mov bx, FATMemLocation
    mov al, [SectorsPerFAT] ; Sectors to read
    call ReadDisk



; Loads the root directory
LoadRootDir:
    call GetRootDirInfo

    ; Get CHS info
    mov ax, word [RootDirStartPoint]
    call LbaToChs

    mov bx, RootDirMemLocation
    mov al, [RootDirSize] ; Sectors to read
    call ReadDisk



; Searches for an entry in the root dir with the kernel file name
SearchKernel:
    mov di, RootDirMemLocation
    mov ax, word [RootDirEntries] ; Counter

    .NextEntry:
        push di
        dec ax

        mov si, KernelFileName ; First string
        mov cx, 11 ; How many bytes to compare

        repe cmpsb

        pop di ; Get the original value back(current entry start)
        je LoadKernel

        add di, 32 ; Every entry is 32 bytes

        cmp ax, word 0
        jne .NextEntry

        ; Nope. Nope.
        jmp ReadDiskError



LoadKernel:
    mov ax, word [di + 0x1a] ; Bytes 26-27 is the first cluster
    mov word [CurrentCluster], ax ; Save it

    ; Where we load the kernel
    mov ax, 0x7e0
    mov es, ax
    mov bx, 0

    .LoadCluster:
        ; The actual data sector is start at sector 33.
        ; Also -2 because the first 2 entries are reserved
        mov ax, word [CurrentCluster]
        add ax, 31

        ; call ClusterToLba
        call LbaToChs

        mov bx, word [KernelOffset]
        mov al, byte [SectorsPerCluster]
        call ReadDisk

        ; Calculates next cluster
        ; Since the values for the clusters are 12 bits we need to read a two bytes
        ; and kick off the other 4 bits. We do:
        ; CurrentCluster + (CurrentCluster / 2)
        mov ax, word [CurrentCluster]
        mov dx, ax
        mov cx, ax
        shr cx, 1 ; Shift a bit to the right, aka divide by 2
        add ax, cx

        ; Get the 12 bits
        mov bx, FATMemLocation
        add bx, ax
        mov ax, word [bx]

        ; Checks if the current cluster is even or not
        ; Checks if the first bit is 1 or 0
        test dx, 1
        jz .EvenCluster

        .OddCluster:
            shr ax, 4
            jmp .Continue

        .EvenCluster:
            and ax, 0xfff

        .Continue:
            mov word [CurrentCluster], ax ; Save the new cluster

            cmp ax, word 0xfff ; 0xff8 represent the last cluster
            jae .KernelLoaded

            add word [KernelOffset], 512 ; Next sector
            jmp .LoadCluster


        .KernelLoaded:
            ; Clears the screen
            mov ah, 0
            mov al, 3
            int 0x10

            ; Jump to kernel
            jmp 0x7e0:0x0



; Resets the disk: moves to the first sector
; Output:
;   ah = status (0 if success)
;   cf = 0 if success, set if not
ResetDisk:
    push ax

    mov ah, 0
    mov dl, [BootDisk]
    int 0x13

    pop ax

    ret



; Converts LBA to CHS
; Input:
;   ax = lba address to convert
LbaToChs:
    push ax

    ; Sector
    mov dx, 0
    div word [SectorsPerTrack]
    inc dl ; Sectors start from 1
    mov byte [ChsSector], dl

    pop ax

    ; Head and track
    mov dx, 0
    div word [SectorsPerTrack]
    mov dx, 0
    div word [Heads]
    mov byte [ChsTrack], al
    mov byte [ChsHead], dl

    ret


; Gets a cluster number and converts it to LBA
; Input:
;   ax = chs address to convert
; Output:
;   ax = LBA
ClusterToLba:
    mov cx, 0
    mov dx, 0

    sub ax, 2
    mov cl, byte [SectorsPerCluster]
    mul cx

    ; add ax, word [FirstDataSector]

    ret




; Gets root dir info and stores it into variables
GetRootDirInfo:
    mov ax, 0
    mov dx, 0

    ; Gets the start point of the root dir
    mov al, byte [NumberOfFATs]
    mul word [SectorsPerFAT]
    add ax, word [ReservedSectors]

    mov word [RootDirStartPoint], ax
    ; mov word [FirstDataSector], ax

    ; Gets the size in sectors of the root dir
    mov ax, 32 ; Every entry is 32 bytes
    mul word [RootDirEntries]
    div word [BytesPerSector]

    mov word [RootDirSize], ax

    ; You little ******, I forgot about you and nothing worked
    ; add word [FirstDataSector], ax

    ret



ReadDiskError:
    mov si, ReadDiskErrorMessage
    call PrintString

    ; Wait for key press
    mov ah, 0
    int 0x16

    ; Reboot
    mov ah, 0
    int 0x19





BootDisk: db 0
RootDirSize: dw 0
RootDirStartPoint: dw 0
; FirstDataSector: dw 0
KernelFileName: db "KERNEL  BIN"
CurrentCluster: dw 0
KernelOffset: dw 0

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
ReadDiskErrorMessage: db 10, 13, "Disk read error", 0