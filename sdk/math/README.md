# Math library for ZX

Functions from http://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Multiplication

* mult_h_e - 8*8 multiplication - The following routine multiplies h by e and places the result in hl
* mult_a_de - 16*8 multiplication - The following routine multiplies de by a and places the result in ahl (which means a is the most significant byte of the product, l the least significant and h the intermediate one...)
* mult_de_bc - 16*16 multiplication  - The following routine multiplies bc by de and places the result in dehl.
