mkdir build

cd build
rm *.exe
rm *.dll

cd ../client
"C:\Program Files (x86)\PascalABC.NET\pabcnetc.exe" client.pas
rm *.pdb
rm *.pcu
mv client.exe ../build/client.exe
cp MSHP.Sockets.dll ../build/MSHP.Sockets.dll

cd ../server
"C:\Program Files (x86)\PascalABC.NET\pabcnetc.exe" server.pas
rm *.pdb
rm *.pcu
mv server.exe ../build/server.exe

pause