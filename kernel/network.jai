
#import "Bit_Operations";

Ethernet_Header :: struct (network_byte_order := false) {

    destination_mac: [6] u8;
    source_mac:      [6] u8;

    ethertype: Ethertype;
}

byteswap_ethernet_frame :: (frame: Ethernet_Header(true)) -> Ethernet_Header(false) {

    result: Ethernet_Header;

    for frame.destination_mac result.destination_mac[5-it_index] = it;
    for frame.source_mac      result.source_mac     [5-it_index] = it;

    result.ethertype = byte_swap(frame.ethertype);

    return result;
}

Ethertype :: enum u16 {
    IPv4                :: 0x0800;
    ARP                 :: 0x0806;
    INET_CDP            :: 0x2000;
    SRP                 :: 0x22EA;
    TSN                 :: 0x22F0;
    TRILL               :: 0x22F3;
    L2_ISIS             :: 0x22F4;
    INET_FLOODING       :: 0x36FC;
    RARP                :: 0x8035;
    IEEE8021Q_TAG       :: 0x8100;
    IPv6                :: 0x86DD;
    UNKNOWN             :: 0x86F0;
    INET_PROBABILISTIC  :: 0x86FD;
    INET_WISEROUTE      :: 0x86FE;
    NEXT_HOP_FORWARDING :: 0x86FF;
    FLOW_CONTROL        :: 0x8808;
    MPLS_UNICAST        :: 0x8847;
    MPLS_MULTICAST      :: 0x8848;
    IEEE8021ad_S_TAG    :: 0x88A8;
    LLDP                :: 0x88CC;
    IEEE8021AE          :: 0x88E5;
    GPTP                :: 0x88F7;
    TTETH               :: 0x891D;
    IEEE8021_R_TAG      :: 0xF1C1;
}



Ipv4_Header :: struct {
    // In network byte order.

    bitfield: enum u64 {
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
