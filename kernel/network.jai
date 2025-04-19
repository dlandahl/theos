
// All fields are in network byte order.

Ethernet_Header :: struct {
    destination_mac: [6] u8;
    source_mac:      [6] u8;

    ethertype: Ethertype;
}

#assert size_of(Ethernet_Header) == 14;

Ethertype :: enum u16 {
    IPv4      :: 0x0008;
    ARP       :: 0x0608;
    IPv6      :: 0xDD86;
    UNKNOWN   :: 0xF086;
}

Ipv4_Header :: struct {

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

    source_address: u32;
    destination_address: u32;
}

Udp_Header :: struct {
    source_port: u16;
    destination_port: u16;

    length: u16;
    checksum: u16;
}

Arp_Packet :: struct {
    HTYPE__hardware_type: enum u16 {
        ethernet :: 0x0100;
    }

    PTYPE__protocol_type: Ethertype;

    HLEN__hardware_length: u8;
    PLEN__protocol_length: u8;

    OPER__operation: enum u16 {
        request :: 0x0100;
        reply   :: 0x0200;
    }

    SHA__sender_hardware_address: [6]u8;
    SPA__sender_protocol_address: [4]u8;

    THA__target_hardware_address: [6]u8;
    TPA__target_protocol_address: [4]u8;
}

#assert size_of(Arp_Packet) == 28;



Dhcp_Message :: struct {
    opcode:        u8;
    hardware_type: u8;
    mac_length:    u8;
    hops:          u8;
    xid:           u32;
    seconds:       u16;
    flags:         u16;

    client_ip:     u32;
    your_ip:       u32;
    server_ip:     u32;
    gateway_ip:    u32;

    client_mac:  [6]  u8;
    server_name: [64] u8;
}

Dhcp_Message_Type :: enum u8 {
    discover           :: 1;
    offer              :: 2;
    request            :: 3;
    decline            :: 4;
    ack                :: 5;
    nak                :: 6;
    release            :: 7;
    inform             :: 8;
    force_renew        :: 9;
    lease_query        :: 10;
    lease_unassigned   :: 11;
    lease_unknown      :: 12;
    lease_active       :: 13;
    bulk_lease_query   :: 14;
    lease_query_done   :: 15;
    active_lease_query :: 16;
    lease_query_status :: 17;
    tls                :: 18;
}
