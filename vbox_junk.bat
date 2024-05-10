
rm disk_image.vdi
VBoxManage convertfromraw --format VDI disk_image.img disk_image.vdi
VBoxManage storageattach new_os --storagectl AHCI --port 0 --medium none --device 0
VBoxManage closemedium disk_image.vdi
VBoxManage storageattach new_os --storagectl AHCI --port 0 --medium disk_image.vdi --device 0 --type hdd
VBoxManage setextradata new_os GUI/DefaultCloseAction PowerOff
VBoxManage startvm new_os -E VBOX_GUI_DBG_ENABLED=true
