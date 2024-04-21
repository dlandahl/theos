@echo off

start "" "qemu" -serial stdio -bios OVMF.fd -drive format=raw,file=fat:rw:build
