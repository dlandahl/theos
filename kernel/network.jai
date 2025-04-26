
// All fields are in network byte order.
#import "Bit_Operations";

bs16 :: #bake_constants byte_swap(T=u16);
bs32 :: #bake_constants byte_swap(T=u32);

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

    checksum: u16;

    source_address: u32;
    destination_address: u32;
} #no_padding

byte_swap_ip :: (header: *Ipv4_Header) {
    set(header, .total_length,   bs16(cast(u16) get(header.*, .total_length)));
    set(header, .identification, bs16(cast(u16) get(header.*, .identification)));
    header.checksum = bs16(header.checksum);
}

ip4_checksum :: (ip: Ipv4_Header) -> u16 {
    in := cast(*u8) *ip;
    sum: u32 = 0;

    num_words := size_of(Ipv4_Header) / size_of(u16);

    for 0..num_words-1 {
        high := cast(u16, in[it*2]) << 8;
        low  := cast(u16, in[it*2 + 1]);

        sum += high + low;
    }

    while sum > 0xffff {
        sum = (sum >> 16) + (sum & 0xffff);
    }

    return ~cast(u16, sum);
}



Udp_Header :: struct {
    source_port: u16;
    destination_port: u16;

    length: u16;
    checksum: u16;
}

byte_swap_udp :: (udp: *Udp_Header) {
    udp.source_port      = bs16(udp.source_port);
    udp.destination_port = bs16(udp.destination_port);
    udp.length           = bs16(udp.length);
    udp.checksum         = bs16(udp.checksum);

    log("%", udp.*);
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

    client_mac:  [6] u8;
    mac_padding: [10] u8;

    boot_file_name: [192] u8;
    magic:         u32;
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

byte_swap_dhcp_message :: (dhcp: *Dhcp_Message) {
    dhcp.xid = bs32(dhcp.xid);
    dhcp.seconds = bs16(dhcp.seconds);
    dhcp.flags = bs16(dhcp.flags);
    dhcp.magic = bs32(dhcp.magic);
}

BROADCAST_MAC :: u8.[0xff, 0xff, 0xff, 0xff, 0xff, 0xff];



Network_Packet :: struct {
    data: *void;
    length: int;
}

add_to_packet :: (packet: *Network_Packet, data: *$T) {
    memcpy(packet.data + packet.length, data, size_of(T));
    packet.length += size_of(T);
}

do_networking :: (nic: *I8254x_Network_Interface_Card) {
    // Make a DHCP request, see if we get a response.
    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    eth: Ethernet_Header;
    eth.destination_mac = BROADCAST_MAC;
    eth.source_mac = nic.mac_address;
    eth.ethertype = .IPv4;

    add_to_packet(*packet, *eth);

    // DHCP options
    dhcp_opt_discover   := u8.[0x35, 0x1, 0x1];
    dhcp_opt_request_ip := u8.[0x32, 0x04, 0xc0, 0xa8, 0x01, 0x64];
    dhcp_opt_prl        := u8.[0x37, 0x04, 0x01, 0x03, 0x0f, 0x06, 0xff];

    dhcp_options_length : u16 = dhcp_opt_discover.count + dhcp_opt_request_ip.count + dhcp_opt_prl.count;

    ip_packet_length := size_of(Ipv4_Header)
        + size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    ip: Ipv4_Header;
    set(*ip, .version, 4);
    set(*ip, .ihl, 5);
    set(*ip, .total_length, ip_packet_length);

    ip.time_to_live = 128;
    ip.protocol = .UDP;
    ip.source_address = 0;
    ip.destination_address = 0xff_ff_ff_ff;
    ip.checksum = ip4_checksum(ip);

    byte_swap_ip(*ip);
    add_to_packet(*packet, *ip);

    udp: Udp_Header;
    udp.source_port = 68;
    udp.destination_port = 67;
    udp.length = size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    byte_swap_udp(*udp);
    add_to_packet(*packet, *udp);

    dhcp := New(Dhcp_Message,, temp);
    dhcp.opcode = 0x1;
    dhcp.hardware_type = 0x1;
    dhcp.mac_length = 0x6;
    dhcp.xid = xx rdtsc();
    dhcp.client_mac = nic.mac_address;
    dhcp.magic = 0x63825363;

    byte_swap_dhcp_message(dhcp);
    add_to_packet(*packet, dhcp);

    add_to_packet(*packet, *dhcp_opt_discover);
    add_to_packet(*packet, *dhcp_opt_request_ip);
    add_to_packet(*packet, *dhcp_opt_prl);

    log("Transmitting DHCP discover with XID % and IP total length %", hex(dhcp.xid), ip_packet_length);

    for 1..100 {
        i8254x_transmit_packet(nic, packet);
        busy_loop(500, .milliseconds);
    }

    while true {
        packets := i8254x_get_newly_received_packets(nic);
        for packets log_packet(it);

        busy_loop(50, .milliseconds);
    }
}

log_packet :: (using packet: Network_Packet) {
    ts := get_kernel_timestamp();

    frame := cast(*Ethernet_Header, data).*;

    if frame.ethertype != .IPv4 {
        return;
    }

    log("====== % ======", formatFloat(to_float64_seconds(ts), trailing_width=3, zero_removal=.NO));

    {
        Push_Print_Style().* = mac_address_print_style;
        log("% => %", frame.source_mac, frame.destination_mac);
    }

    log("Length: %", packet.length);

    if frame.ethertype == .IPv4 {
        ip := cast(*Ipv4_Header, data + size_of(Ethernet_Header));

        // Auto-dereference is not handled in our #as handling code for bitfields...
        assert(get(ip.*, .version) == 4);

        log("IP protocol %", ip.protocol);
    }
}
