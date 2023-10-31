cd .\tests\
for %%x in (*.tri) do del "%%x" 
for %%x in (*.bin) do ..\tools\tricky.exe -b "%%x"

cd ..
cmd /c "BeebAsm.exe -v -i tricky_test.s.asm -do tricky_test.ssd -opt 3"