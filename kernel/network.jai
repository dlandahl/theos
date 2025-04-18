
#import "Bit_Operations";

Ethernet_Header :: struct {
    // In network byte order.

    destination_mac: [6] u8;
    source_mac:      [6] u8;

    ethertype: Ethertype;
}

Ethertype :: enum u16 {
    // In network byte order.

    IPv4                :: 0x0008;
    ARP                 :: 0x0608;
    IPv6                :: 0xDD86;
    UNKNOWN             :: 0xF086;
}

Ipv4_Header :: struct {
    // In network byte order.

    #as bitfield: enum u64 {
        ihl             :: 4;
        version         :: 4;
        ecn             :: 2;
        dscp            :: 6;
        total_length    :: 16;
        identification  :: 16;
        fragment_offset :: 13;
        flags           :: 3;
    }

    time_to_live: u8;

    protocol: enum u8 {
        ICMP  :: 1;
        IGMP  :: 2;
        TCP   :: 6;
        UDP   :: 17;
        ENCAP :: 41;
        OSPF  :: 89;
        SCTP  :: 132;
    }

    checksum: u32;

    source_address: u64;
    destination_address: u64;
}
