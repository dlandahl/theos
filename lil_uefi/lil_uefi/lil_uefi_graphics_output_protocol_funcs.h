// SPEC: Section 12.9
X(QueryMode, EFI_STATUS, (struct EFI_GRAPHICS_OUTPUT_PROTOCOL *prot, EFI_UINT32 mode_number, EFI_UINTN *size_of_info, EFI_GRAPHICS_OUTPUT_MODE_INFORMATION **info))
X(SetMode,   EFI_STATUS, (struct EFI_GRAPHICS_OUTPUT_PROTOCOL *prot, EFI_UINT32 mode_number))
X(Blt,       EFI_STATUS, (struct EFI_GRAPHICS_OUTPUT_PROTOCOL *prot, EFI_UINT32 *buffer, EFI_GRAPHICS_OUTPUT_BLT_OPERATION blt_operation, EFI_UINTN src_x, EFI_UINTN src_y, EFI_UINTN dst_x, EFI_UINTN dst_y, EFI_UINTN width, EFI_UINTN height, EFI_UINTN src_stride))
