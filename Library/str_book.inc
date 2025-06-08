; book.inc
struc Book
    .title     resb 32
    .author    resb 32
    .year      resd 1
    .rate      resd 1
    .available resb 1
    alignb 4
endstruc
%define Book_size  (32 + 32 + 4 + 4 + 1 + 3) ; 76 байт + padding
