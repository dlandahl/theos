@echo off

if not exist build mkdir build

pushd build
cl   /nologo /FC /GS- /c /I.. ../example/lil_uefi_example.c
link /nologo /ENTRY:EfiMain /ALIGN:16 /SUBSYSTEM:EFI_APPLICATION /OUT:bootx64.efi lil_uefi_example.obj
if not exist EFI mkdir EFI
if not exist EFI\BOOT mkdir EFI\BOOT
copy bootx64.efi EFI\BOOT\bootx64.efi
popd
