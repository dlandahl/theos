//
// This file was auto-generated using the following command:
//
// jai first.jai
//



ELF32_FSZ_ADDR :: 4;
ELF32_FSZ_HALF :: 2;
ELF32_FSZ_OFF :: 4;
ELF32_FSZ_SWORD :: 4;
ELF32_FSZ_WORD :: 4;

ELF64_FSZ_ADDR :: 8;
ELF64_FSZ_HALF :: 2;
ELF64_FSZ_OFF :: 8;
ELF64_FSZ_SWORD :: 4;
ELF64_FSZ_WORD :: 4;
ELF64_FSZ_SXWORD :: 8;
ELF64_FSZ_XWORD :: 8;

EI_NIDENT :: 16;

EI_MAG0 :: 0;
EI_MAG1 :: 1;
EI_MAG2 :: 2;
EI_MAG3 :: 3;
EI_CLASS :: 4;
EI_DATA :: 5;
EI_VERSION :: 6;
EI_OSABI :: 7;
EI_ABIVERSION :: 8;
EI_PAD :: 9;

ELFMAG0 :: 0x7f;

ELFMAG :: "ELF";
SELFMAG :: 4;

ELFCLASSNONE :: 0;
ELFCLASS32 :: 1;
ELFCLASS64 :: 2;
ELFCLASSNUM :: 3;

ELFDATANONE :: 0;
ELFDATA2LSB :: 1;
ELFDATA2MSB :: 2;
ELFDATANUM :: 3;

ET_NONE :: 0;
ET_REL :: 1;
ET_EXEC :: 2;
ET_DYN :: 3;
ET_CORE :: 4;
ET_NUM :: 5;
ET_LOOS :: 0xfe00;
ET_LOSUNW :: 0xfeff;
ET_SUNWPSEUDO :: 0xfeff;
ET_HISUNW :: 0xfeff;
ET_HIOS :: 0xfeff;
ET_LOPROC :: 0xff00;
ET_HIPROC :: 0xffff;

EM_NONE :: 0;
EM_M32 :: 1;
EM_SPARC :: 2;
EM_386 :: 3;
EM_68K :: 4;
EM_88K :: 5;
EM_486 :: 6;
EM_860 :: 7;
EM_MIPS :: 8;
EM_S370 :: 9;
EM_MIPS_RS3_LE :: 10;
EM_RS6000 :: 11;
EM_UNKNOWN12 :: 12;
EM_UNKNOWN13 :: 13;
EM_UNKNOWN14 :: 14;
EM_PA_RISC :: 15;

EM_nCUBE :: 16;
EM_VPP500 :: 17;
EM_SPARC32PLUS :: 18;
EM_960 :: 19;
EM_PPC :: 20;
EM_PPC64 :: 21;
EM_S390 :: 22;

EM_UNKNOWN23 :: 23;
EM_UNKNOWN24 :: 24;
EM_UNKNOWN25 :: 25;
EM_UNKNOWN26 :: 26;
EM_UNKNOWN27 :: 27;
EM_UNKNOWN28 :: 28;
EM_UNKNOWN29 :: 29;
EM_UNKNOWN30 :: 30;
EM_UNKNOWN31 :: 31;
EM_UNKNOWN32 :: 32;
EM_UNKNOWN33 :: 33;
EM_UNKNOWN34 :: 34;
EM_UNKNOWN35 :: 35;
EM_V800 :: 36;
EM_FR20 :: 37;
EM_RH32 :: 38;
EM_RCE :: 39;
EM_ARM :: 40;
EM_ALPHA :: 41;
EM_SH :: 42;
EM_SPARCV9 :: 43;
EM_TRICORE :: 44;
EM_ARC :: 45;

EM_H8_300 :: 46;
EM_H8_300H :: 47;
EM_H8S :: 48;
EM_H8_500 :: 49;
EM_IA_64 :: 50;
EM_MIPS_X :: 51;
EM_COLDFIRE :: 52;
EM_68HC12 :: 53;
EM_MMA :: 54;
EM_PCP :: 55;
EM_NCPU :: 56;
EM_NDR1 :: 57;
EM_STARCORE :: 58;
EM_ME16 :: 59;
EM_ST100 :: 60;
EM_TINYJ :: 61;

EM_AMD64 :: 62;

EM_PDSP :: 63;
EM_UNKNOWN64 :: 64;
EM_UNKNOWN65 :: 65;
EM_FX66 :: 66;
EM_ST9PLUS :: 67;

EM_ST7 :: 68;

EM_68HC16 :: 69;
EM_68HC11 :: 70;
EM_68HC08 :: 71;
EM_68HC05 :: 72;
EM_SVX :: 73;
EM_ST19 :: 74;

EM_VAX :: 75;
EM_CRIS :: 76;

EM_JAVELIN :: 77;

EM_FIREPATH :: 78;
EM_ZSP :: 79;
EM_MMIX :: 80;

EM_HUANY :: 81;

EM_PRISM :: 82;
EM_AVR :: 83;
EM_FR30 :: 84;
EM_D10V :: 85;
EM_D30V :: 86;
EM_V850 :: 87;
EM_M32R :: 88;
EM_MN10300 :: 89;
EM_MN10200 :: 90;
EM_PJ :: 91;
EM_OPENRISC :: 92;
EM_ARC_A5 :: 93;
EM_XTENSA :: 94;
EM_NUM :: 95;

EV_NONE :: 0;
EV_CURRENT :: 1;
EV_NUM :: 2;

ELFOSABI_NONE :: 0;

ELFOSABI_HPUX :: 1;
ELFOSABI_NETBSD :: 2;
ELFOSABI_LINUX :: 3;
ELFOSABI_UNKNOWN4 :: 4;
ELFOSABI_UNKNOWN5 :: 5;
ELFOSABI_SOLARIS :: 6;
ELFOSABI_AIX :: 7;
ELFOSABI_IRIX :: 8;
ELFOSABI_FREEBSD :: 9;
ELFOSABI_TRU64 :: 10;
ELFOSABI_MODESTO :: 11;
ELFOSABI_OPENBSD :: 12;
ELFOSABI_OPENVMS :: 13;
ELFOSABI_NSK :: 14;
ELFOSABI_AROS :: 15;
ELFOSABI_ARM :: 97;
ELFOSABI_STANDALONE :: 255;

PT_NULL :: 0;
PT_LOAD :: 1;
PT_DYNAMIC :: 2;
PT_INTERP :: 3;
PT_NOTE :: 4;
PT_SHLIB :: 5;
PT_PHDR :: 6;
PT_TLS :: 7;
PT_NUM :: 8;

PT_LOOS :: 0x60000000;

PT_SUNW_UNWIND :: 0x6464e550;

PT_LOSUNW :: 0x6ffffffa;
PT_SUNWBSS :: 0x6ffffffa;
PT_SUNWSTACK :: 0x6ffffffb;
PT_SUNWDTRACE :: 0x6ffffffc;
PT_SUNWCAP :: 0x6ffffffd;
PT_HISUNW :: 0x6fffffff;
PT_HIOS :: 0x6fffffff;

PT_LOPROC :: 0x70000000;
PT_HIPROC :: 0x7fffffff;

PF_R :: 0x4;
PF_W :: 0x2;
PF_X :: 0x1;

PF_MASKOS :: 0x0ff00000;
PF_MASKPROC :: 0xf0000000;

PF_SUNW_FAILURE :: 0x00100000;

PN_XNUM :: 0xffff;

SHT_NULL :: 0;
SHT_PROGBITS :: 1;
SHT_SYMTAB :: 2;
SHT_STRTAB :: 3;
SHT_RELA :: 4;
SHT_HASH :: 5;
SHT_DYNAMIC :: 6;
SHT_NOTE :: 7;
SHT_NOBITS :: 8;
SHT_REL :: 9;
SHT_SHLIB :: 10;
SHT_DYNSYM :: 11;
SHT_UNKNOWN12 :: 12;
SHT_UNKNOWN13 :: 13;
SHT_INIT_ARRAY :: 14;
SHT_FINI_ARRAY :: 15;
SHT_PREINIT_ARRAY :: 16;
SHT_GROUP :: 17;
SHT_SYMTAB_SHNDX :: 18;
SHT_NUM :: 19;

SHT_LOOS :: 0x60000000;
SHT_LOSUNW :: 0x6ffffff1;
SHT_SUNW_symsort :: 0x6ffffff1;
SHT_SUNW_tlssort :: 0x6ffffff2;
SHT_SUNW_LDYNSYM :: 0x6ffffff3;
SHT_SUNW_dof :: 0x6ffffff4;
SHT_SUNW_cap :: 0x6ffffff5;
SHT_SUNW_SIGNATURE :: 0x6ffffff6;
SHT_SUNW_ANNOTATE :: 0x6ffffff7;
SHT_SUNW_DEBUGSTR :: 0x6ffffff8;
SHT_SUNW_DEBUG :: 0x6ffffff9;
SHT_SUNW_move :: 0x6ffffffa;
SHT_SUNW_COMDAT :: 0x6ffffffb;
SHT_SUNW_syminfo :: 0x6ffffffc;
SHT_SUNW_verdef :: 0x6ffffffd;
SHT_SUNW_verneed :: 0x6ffffffe;
SHT_SUNW_versym :: 0x6fffffff;
SHT_HISUNW :: 0x6fffffff;
SHT_HIOS :: 0x6fffffff;

SHT_GNU_verdef :: 0x6ffffffd;
SHT_GNU_verneed :: 0x6ffffffe;
SHT_GNU_versym :: 0x6fffffff;

SHT_LOPROC :: 0x70000000;
SHT_HIPROC :: 0x7fffffff;

SHT_LOUSER :: 0x80000000;
SHT_HIUSER :: 0xffffffff;

SHF_WRITE :: 0x01;
SHF_ALLOC :: 0x02;
SHF_EXECINSTR :: 0x04;
SHF_MERGE :: 0x10;
SHF_STRINGS :: 0x20;
SHF_INFO_LINK :: 0x40;
SHF_LINK_ORDER :: 0x80;
SHF_OS_NONCONFORMING :: 0x100;
SHF_GROUP :: 0x200;
SHF_TLS :: 0x400;

SHF_MASKOS :: 0x0ff00000;

SHF_MASKPROC :: 0xf0000000;

SHN_UNDEF :: 0;
SHN_LORESERVE :: 0xff00;
SHN_LOPROC :: 0xff00;
SHN_HIPROC :: 0xff1f;
SHN_LOOS :: 0xff20;
SHN_LOSUNW :: 0xff3f;
SHN_SUNW_IGNORE :: 0xff3f;
SHN_HISUNW :: 0xff3f;
SHN_HIOS :: 0xff3f;
SHN_ABS :: 0xfff1;
SHN_COMMON :: 0xfff2;

SHN_XINDEX :: 0xffff;
SHN_HIRESERVE :: 0xffff;

STN_UNDEF :: 0;

STB_LOCAL :: 0;
STB_GLOBAL :: 1;
STB_WEAK :: 2;
STB_NUM :: 3;

STB_LOPROC :: 13;
STB_HIPROC :: 15;

STT_NOTYPE :: 0;
STT_OBJECT :: 1;
STT_FUNC :: 2;
STT_SECTION :: 3;
STT_FILE :: 4;
STT_COMMON :: 5;
STT_TLS :: 6;
STT_NUM :: 7;

STT_LOPROC :: 13;
STT_HIPROC :: 15;

STV_DEFAULT :: 0;
STV_INTERNAL :: 1;
STV_HIDDEN :: 2;
STV_PROTECTED :: 3;
STV_EXPORTED :: 4;
STV_SINGLETON :: 5;
STV_ELIMINATE :: 6;

STV_NUM :: 7;

GRP_COMDAT :: 0x01;

CA_SUNW_NULL :: 0;
CA_SUNW_HW_1 :: 1;
CA_SUNW_SF_1 :: 2;

SF1_SUNW_FPKNWN :: 0x001;
SF1_SUNW_FPUSED :: 0x002;

SF1_SUNW_MASK :: 0x003;

NT_PRSTATUS :: 1;
NT_PRFPREG :: 2;
NT_PRPSINFO :: 3;
NT_PRXREG :: 4;
NT_PLATFORM :: 5;
NT_AUXV :: 6;
NT_GWINDOWS :: 7;
NT_ASRS :: 8;
NT_LDT :: 9;
NT_PSTATUS :: 10;
NT_PSINFO :: 13;
NT_PRCRED :: 14;
NT_UTSNAME :: 15;
NT_LWPSTATUS :: 16;
NT_LWPSINFO :: 17;
NT_PRPRIV :: 18;
NT_PRPRIVINFO :: 19;
NT_CONTENT :: 20;
NT_ZONENAME :: 21;
NT_NUM :: 21;

Elf32_Addr :: u32;
Elf32_Half :: u16;
Elf32_Off :: u32;
Elf32_Sword :: s32;
Elf32_Word :: u32;

Elf64_Addr :: u64;
Elf64_Half :: u16;
Elf64_Off :: u64;
Elf64_Sword :: s32;
Elf64_Sxword :: s64;
Elf64_Word :: u32;
Elf64_Xword :: u64;
Elf64_Lword :: u64;
Elf32_Lword :: u64;

Elf32_Ehdr :: struct {
    e_ident:     [16] u8; /* ident bytes */
    e_type:      Elf32_Half; /* file type */
    e_machine:   Elf32_Half; /* target machine */
    e_version:   Elf32_Word; /* file version */
    e_entry:     Elf32_Addr; /* start address */
    e_phoff:     Elf32_Off; /* phdr file offset */
    e_shoff:     Elf32_Off; /* shdr file offset */
    e_flags:     Elf32_Word; /* file flags */
    e_ehsize:    Elf32_Half; /* sizeof ehdr */
    e_phentsize: Elf32_Half; /* sizeof phdr */
    e_phnum:     Elf32_Half; /* number phdrs */
    e_shentsize: Elf32_Half; /* sizeof shdr */
    e_shnum:     Elf32_Half; /* number shdrs */
    e_shstrndx:  Elf32_Half; /* shdr string index */
}

Elf64_Ehdr :: struct {
    e_ident:     [16] u8; /* ident bytes */
    e_type:      Elf64_Half; /* file type */
    e_machine:   Elf64_Half; /* target machine */
    e_version:   Elf64_Word; /* file version */
    e_entry:     Elf64_Addr; /* start address */
    e_phoff:     Elf64_Off; /* phdr file offset */
    e_shoff:     Elf64_Off; /* shdr file offset */
    e_flags:     Elf64_Word; /* file flags */
    e_ehsize:    Elf64_Half; /* sizeof ehdr */
    e_phentsize: Elf64_Half; /* sizeof phdr */
    e_phnum:     Elf64_Half; /* number phdrs */
    e_shentsize: Elf64_Half; /* sizeof shdr */
    e_shnum:     Elf64_Half; /* number shdrs */
    e_shstrndx:  Elf64_Half; /* shdr string index */
}

/*
*  Program header
*/
Elf32_Phdr :: struct {
    p_type:   Elf32_Word; /* entry type */
    p_offset: Elf32_Off; /* file offset */
    p_vaddr:  Elf32_Addr; /* virtual address */
    p_paddr:  Elf32_Addr; /* physical address */
    p_filesz: Elf32_Word; /* file size */
    p_memsz:  Elf32_Word; /* memory size */
    p_flags:  Elf32_Word; /* entry flags */
    p_align:  Elf32_Word; /* memory/file alignment */
}

Elf64_Phdr :: struct {
    p_type:   Elf64_Word; /* entry type */
    p_flags:  Elf64_Word; /* entry flags */
    p_offset: Elf64_Off; /* file offset */
    p_vaddr:  Elf64_Addr; /* virtual address */
    p_paddr:  Elf64_Addr; /* physical address */
    p_filesz: Elf64_Xword; /* file size */
    p_memsz:  Elf64_Xword; /* memory size */
    p_align:  Elf64_Xword; /* memory/file alignment */
}

/*
*  Section header
*/
Elf32_Shdr :: struct {
    sh_name:      Elf32_Word; /* section name */
    sh_type:      Elf32_Word; /* SHT_... */
    sh_flags:     Elf32_Word; /* SHF_... */
    sh_addr:      Elf32_Addr; /* virtual address */
    sh_offset:    Elf32_Off; /* file offset */
    sh_size:      Elf32_Word; /* section size */
    sh_link:      Elf32_Word; /* misc info */
    sh_info:      Elf32_Word; /* misc info */
    sh_addralign: Elf32_Word; /* memory alignment */
    sh_entsize:   Elf32_Word; /* entry size if table */
}

Elf64_Shdr :: struct {
    sh_name:      Elf64_Word; /* section name */
    sh_type:      Elf64_Word; /* SHT_... */
    sh_flags:     Elf64_Xword; /* SHF_... */
    sh_addr:      Elf64_Addr; /* virtual address */
    sh_offset:    Elf64_Off; /* file offset */
    sh_size:      Elf64_Xword; /* section size */
    sh_link:      Elf64_Word; /* misc info */
    sh_info:      Elf64_Word; /* misc info */
    sh_addralign: Elf64_Xword; /* memory alignment */
    sh_entsize:   Elf64_Xword; /* entry size if table */
}

/*
*  Symbol table
*/
Elf32_Sym :: struct {
    st_name:  Elf32_Word;
    st_value: Elf32_Addr;
    st_size:  Elf32_Word;
    st_info:  u8; /* bind, type: ELF_32_ST_... */
    st_other: u8;
    st_shndx: Elf32_Half; /* SHN_... */
}

Elf64_Sym :: struct {
    st_name:  Elf64_Word;

    st_info:  u8; /* bind, type: ELF_64_ST_... */
    st_other: u8;
    st_shndx: Elf64_Half; /* SHN_... */
    st_value: Elf64_Addr;
    st_size:  Elf64_Xword;
}

/*
*  Relocation
*/
Elf32_Rel :: struct {
    r_offset: Elf32_Addr;
    r_info:   Elf32_Word; /* sym, type: ELF32_R_... */
}

Elf32_Rela :: struct {
    r_offset: Elf32_Addr;
    r_info:   Elf32_Word; /* sym, type: ELF32_R_... */
    r_addend: Elf32_Sword;
}

Elf64_Rel :: struct {
    r_offset: Elf64_Addr;
    r_info:   Elf64_Xword; /* sym, type: ELF64_R_... */
}

Elf64_Rela :: struct {
    r_offset: Elf64_Addr;
    r_info:   Elf64_Xword; /* sym, type: ELF64_R_... */
    r_addend: Elf64_Sxword;
}

/*
*  Note entry header
*/
Elf32_Nhdr :: struct {
    n_namesz: Elf32_Word; /* length of note's name */
    n_descsz: Elf32_Word; /* length of note's "desc" */
    n_type:   Elf32_Word; /* type of note */
}

Elf64_Nhdr :: struct {
    n_namesz: Elf64_Word; /* length of note's name */
    n_descsz: Elf64_Word; /* length of note's "desc" */
    n_type:   Elf64_Word; /* type of note */
}

Elf32_Move :: struct {
    m_value:   Elf32_Lword; /* symbol value */
    m_info:    Elf32_Word; /* size + index */
    m_poffset: Elf32_Word; /* symbol offset */
    m_repeat:  Elf32_Half; /* repeat count */
    m_stride:  Elf32_Half; /* stride info */
}

Elf64_Move :: struct {
    m_value:   Elf64_Lword; /* symbol value */
    m_info:    Elf64_Xword; /* size + index */
    m_poffset: Elf64_Xword; /* symbol offset */
    m_repeat:  Elf64_Half; /* repeat count */
    m_stride:  Elf64_Half; /* stride info */
}

Elf32_Cap :: struct {
    c_tag: Elf32_Word; /* how to interpret value */
    c_un:  union {
        c_val: Elf32_Word;
        c_ptr: Elf32_Addr;
    };
}

Elf64_Cap :: struct {
    c_tag: Elf64_Xword; /* how to interpret value */
    c_un:  union {
        c_val: Elf64_Xword;
        c_ptr: Elf64_Addr;
    };
}
