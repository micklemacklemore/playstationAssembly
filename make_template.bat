@echo off
set mikey_file_root={0}
set mikey_file_name={1}
cd ../
armips ./%mikey_file_root%/%mikey_file_name%.asm
move /y .\%mikey_file_name%.bin .\%mikey_file_root%\
cd %mikey_file_root%
python ../bin2exe.py %mikey_file_name%.bin %mikey_file_name%.exe
