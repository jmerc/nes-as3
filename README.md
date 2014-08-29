nes-as3
=======

Nintendo Emulation in AS3


Progress:

ROM file parser - complete for iNES 1.0
Mappers Implemented: #0

CPU
Work needed: Optimization, cycle counting, interrupts, system registers

Instructions Implemented:
$20  JSR  ABS
$38  SEC IMP
$4C	JMP ABS
$6C  JMP IND
$86  STX ZPG
$A2  LDX IMM
$EA  NOP IMP