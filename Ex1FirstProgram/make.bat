@echo off
set mikey_file_root=Ex1FirstProgram
set mikey_file_name=mips1
cd ../
armips ./%mikey_file_root%/%mikey_file_name%.asm
move /y .\%mikey_file_name%.bin .\%mikey_file_root%\
cd %mikey_file_root%
python ../bin2exe.py %mikey_file_name%.bin %mikey_file_name%.exe
