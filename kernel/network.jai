
// All fields are in network byte order.

bs16 :: #bake_constants byte_swap(T=u16);
bs32 :: #bake_constants byte_swap(T=u32);

BROADCAST_MAC :: u8.[0xff, 0xff, 0xff, 0xff, 0xff, 0xff];

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

init_ethernet_header :: (net: *Network_Connection) -> Ethernet_Header {
    eth: Ethernet_Header;
    eth.destination_mac = net.router_mac_address;
    eth.source_mac = net.adapter.mac_address;
    eth.ethertype = .IPv4;

    return eth;
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
    set(header, .total_length,   bs16(get(header.*, .total_length).(u16)));
    set(header, .identification, bs16(get(header.*, .identification).(u16)));
    header.checksum = bs16(header.checksum);
}

internet_checksum :: (header: $H) -> u16 {
    return internet_checksum(cast(*u8, *header), size_of(H));
}

internet_checksum :: (bytes: *u8, count: int) -> u16 {
    sum: u32 = 0;

    assert(count % 2 == 0); // Todo

    num_words := count / size_of(u16);

    for 0..num_words-1 {
        high := bytes[it*2    ].(u16) << 8;
        low  := bytes[it*2 + 1].(u16);

        sum += high.(u32) + low.(u32);
    }

    while sum > 0xffff {
        sum = (sum >> 16) + (sum & 0xffff);
    }

    return ~bs16(xx sum);
}

init_ip_header :: (
    net: *Network_Connection,
    protocol: type_of(Ipv4_Header.protocol),
    destination_ip: u32,
    total_length: int
) -> Ipv4_Header {

    assert(total_length >= size_of(Ipv4_Header) && total_length < 0xffff);

    ip: Ipv4_Header;
    set(*ip, .version, 4);
    set(*ip, .ihl, 5);
    set(*ip, .total_length, total_length);

    ip.time_to_live = 128;
    ip.protocol = protocol;
    ip.source_address = net.our_ip;
    ip.destination_address = destination_ip;

    byte_swap_ip(*ip);
    ip.checksum = internet_checksum(ip);

    return ip;
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
    SPA__sender_protocol_address: u32 #align 1;

    THA__target_hardware_address: [6]u8;
    TPA__target_protocol_address: u32 #align 1;
}

#assert size_of(Arp_Packet) == 28;

transmit_arp_probe :: (net: *Network_Connection) {

    probe: struct {
        using eth: Ethernet_Header;
        using arp: Arp_Packet;
    }

    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    probe.destination_mac = BROADCAST_MAC;
    probe.source_mac      = net.adapter.mac_address;
    probe.ethertype       = .ARP;

    probe.HTYPE__hardware_type = .ethernet;
    probe.PTYPE__protocol_type = .IPv4;
    probe.HLEN__hardware_length = 6;
    probe.PLEN__protocol_length = 4;
    probe.OPER__operation       = .request;

    probe.SHA__sender_hardware_address = net.adapter.mac_address;
    probe.SPA__sender_protocol_address = 0;
    probe.THA__target_hardware_address = .[0,0,0,0,0,0];
    probe.TPA__target_protocol_address = net.our_ip;

    add_to_packet(*packet, probe);
    i8254x_transmit_packet(*net.adapter, packet);

    // Todo: actually respond to IP address conflicts

    free_4k_page(cast(u64, packet.data - DIRECT_MAPPING_BASE));
}

handle_arp :: (net: *Network_Connection, eth: *Ethernet_Header) {
    arp := cast(*Arp_Packet) (eth + 1);

    if arp.SPA__sender_protocol_address == arp.TPA__target_protocol_address {
        // Gratuitous ARP
        table_add(*net.arp_table, arp.SPA__sender_protocol_address, arp.SHA__sender_hardware_address);
        return;
    }

    if net.our_ip != arp.TPA__target_protocol_address return;
    if arp.OPER__operation != .request return;

    reply: struct {
        using eth: Ethernet_Header;
        using arp: Arp_Packet;
    }

    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    reply.destination_mac = arp.SHA__sender_hardware_address;
    reply.source_mac      = net.adapter.mac_address;
    reply.ethertype       = .ARP;

    reply.HTYPE__hardware_type = .ethernet;
    reply.PTYPE__protocol_type = .IPv4;
    reply.HLEN__hardware_length = 6;
    reply.PLEN__protocol_length = 4;
    reply.OPER__operation       = .reply;

    reply.SHA__sender_hardware_address = net.adapter.mac_address;
    reply.SPA__sender_protocol_address = net.our_ip;
    reply.THA__target_hardware_address = arp.SHA__sender_hardware_address;
    reply.TPA__target_protocol_address = arp.SPA__sender_protocol_address;

    add_to_packet(*packet, reply);
    i8254x_transmit_packet(*net.adapter, packet);
    log("ARP reply sent");

    free_4k_page(cast(u64, packet.data - DIRECT_MAPPING_BASE));

    return;
}



Udp_Header :: struct {
    source_port: u16;
    destination_port: u16;

    length: u16;
    checksum: u16;
}

byte_swap_udp_header :: (udp: *Udp_Header) {
    udp.source_port      = bs16(udp.source_port);
    udp.destination_port = bs16(udp.destination_port);
    udp.length           = bs16(udp.length);
    udp.checksum         = bs16(udp.checksum);
}

FIRST_EPHEMERAL_PORT :: 0xc000;



tcp_checksum :: (tcp: Tcp_Header, source: u32, dest: u32, payload := "") -> u16 {
    Pseudo_Header :: struct {
        source_address: u32;
        destination_address: u32;
        zeroes: u8;
        protocol: type_of(Ipv4_Header.protocol);
        tcp_length: u16;

        tcp: Tcp_Header;

        payload: [0x100] u8;
    }

    pseudo: Pseudo_Header;
    pseudo.tcp = tcp;
    pseudo.source_address = source;
    pseudo.destination_address = dest;
    pseudo.protocol = .TCP;
    pseudo.tcp_length = bs16(cast(u16, size_of(Tcp_Header) + payload.count));

    memcpy(pseudo.payload.data, payload.data, payload.count);

    count := payload.count;
    if count % 2 count += 1;

    return internet_checksum(cast(*u8, *pseudo), size_of(Pseudo_Header) + count - 0x100);
}

byte_swap_tcp_header :: (tcp: *Tcp_Header) {
    tcp.source_port      = bs16(tcp.source_port);
    tcp.destination_port = bs16(tcp.destination_port);
    tcp.sequence_number  = bs32(tcp.sequence_number);
    tcp.ack_number       = bs32(tcp.ack_number);
    tcp.window           = bs16(tcp.window);
    tcp.urgent_pointer   = bs16(tcp.urgent_pointer);
}

init_tcp_header :: (net: *Network_Connection, con: *Tcp_Connection, flags: Tcp_Header.Flags, payload := "") -> Tcp_Header {
    tcp: Tcp_Header;
    tcp.source_port = con.port;
    tcp.destination_port = con.remote_port;
    tcp.sequence_number = con.our_sequence_number;
    tcp.ack_number = con.last_received_byte+1;
    tcp.data_offset = 5 << 4;
    tcp.flags = flags;
    tcp.window = 4096;

    byte_swap_tcp_header(*tcp);
    tcp.checksum = tcp_checksum(tcp, net.our_ip, con.remote_ip, payload);

    return tcp;
}

Tcp_Header :: struct {
    source_port: u16;
    destination_port: u16;

    sequence_number: u32;
    ack_number: u32;

    data_offset: u8;

    Flags :: enum_flags u8 {
        FIN;
        SYN;
        RST;
        PSH;
        ACK;
        URG;
        ECE;
        CWR;
    }

    flags: Flags;

    window: u16;
    checksum: u16;
    urgent_pointer: u16;
}

Tcp_Connection :: struct {
    port: u16;

    remote_port: u16;
    remote_ip: u32;

    handshake_state: enum {
        NOT_STARTED;
        SYN_SENT;
        COMPLETED;
    }

    // Accumulated each time we transmit new bytes that have not been transmitted before
    our_sequence_number: u32;

    // The next sequence number we expect to see is always this + 1.
    // Peer sequence numbers less than this have been acknowledged before.
    last_received_byte: u32;

    in_flight: [..] Tcp_Transmission_Info;

    received_segments: [..] string;
}

Tcp_Transmission_Info :: struct {
    // There should be an instance of this for each unacknowledged transmitted packet in a connection.
    // Except for ACKs sent by us, as we don't expect to receive an ACK for those.

    last_sent_at: Apollo_Time; // To detect if we need to retransmit
    sequence: u32;
    packet: Network_Packet;
}

record_tcp_packet_for_potential_retransmission :: (net: *Network_Connection, con: *Tcp_Connection, packet: Network_Packet) {

    bytes_to_transmit := packet.length - (size_of(Ethernet_Header) + size_of(Ipv4_Header) + size_of(Tcp_Header));
    if bytes_to_transmit == 0 bytes_to_transmit = 1;
    con.our_sequence_number += cast(u32) bytes_to_transmit;

    info := array_add(*con.in_flight);
    info.last_sent_at = get_monotonic_time();
    info.packet = packet;

    // The sequence number in the ACK will include the bytes transmitted in this packet, so store that.
    // The sequence number of the packet we're transmitting right now does not match this sequence number, as it describes the first byte being transmitted in that packet.
    info.sequence = con.our_sequence_number;
}

transmit_tcp_packet :: (net: *Network_Connection, con: *Tcp_Connection, header_flags: Tcp_Header.Flags, payload := "", needs_acknowledgement := true) {
    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    eth := init_ethernet_header(net);
    add_to_packet(*packet, eth);

    datagram_length := size_of(Ipv4_Header) + size_of(Tcp_Header) + payload.count;
    ip := init_ip_header(net, .TCP, con.remote_ip, datagram_length);
    add_to_packet(*packet, ip);

    tcp := init_tcp_header(net, con, header_flags, payload);
    add_to_packet(*packet, tcp);

    add_to_packet(*packet, payload);

    if needs_acknowledgement {
        record_tcp_packet_for_potential_retransmission(net, con, packet);
    }

    i8254x_transmit_packet(*net.adapter, packet);
}

initiate_tcp_connection :: (net: *Network_Connection, remote_ip: u32, remote_port: u16) {
    port := FIRST_EPHEMERAL_PORT + cast(u16, rdtsc() & 0xfff);

    // Clear the high bit to ensure we have at least a couple gigabytes of headroom until we add code to handle overflow.
    sequence_number := cast(u32, random_get() & 0x7fff_ffff);

    con := array_add(*net.tcp_connections);
    con.* = .{
        port = port,
        remote_port = remote_port,
        remote_ip = remote_ip,
        handshake_state = .NOT_STARTED,
        our_sequence_number = sequence_number,
        last_received_byte = 0xffff_ffff,
    }; 

    transmit_tcp_packet(net, con, .SYN, needs_acknowledgement=false);
    con.handshake_state = .SYN_SENT;
}

update_tcp_connection :: (net: *Network_Connection, con: *Tcp_Connection) {
    // Periodically check if something needs to be retransmitted.
    time_now := get_monotonic_time();

    // Maybe we should have a back-off system.
    RETRANSMISSION_TIME :: #run seconds_to_apollo(1);

    for* info: con.in_flight {
        if time_now - info.last_sent_at > RETRANSMISSION_TIME {
            // Retransmit the segment
            i8254x_transmit_packet(*net.adapter, info.packet);
            info.last_sent_at = time_now;
        }
    }
}

handle_tcp_packet :: (net: *Network_Connection, eth_: *Ethernet_Header) {

    Tcp_Packet :: struct {
        eth: Ethernet_Header;
        ip: Ipv4_Header #align 1;
        tcp: Tcp_Header #align 1;
    }

    using packet := cast(*Tcp_Packet) eth_;

    byte_swap_tcp_header(*tcp);
    byte_swap_ip(*ip);

    con: *Tcp_Connection;
    for* net.tcp_connections {
        if it.port != tcp.destination_port continue;
        con = it;
        break;
    }

    if !con {
        log_error("Got TCP message for nonexistent connection on port %", tcp.destination_port);
        return;
    }

    if tcp.flags == .SYN | .ACK {
        if con.handshake_state == {
          case .COMPLETED;
            // It looks like the server missed the ACK the first time. Todo.

          case .SYN_SENT;
            con.last_received_byte = tcp.sequence_number;
            con.our_sequence_number += 1;
            transmit_tcp_packet(net, con, .ACK, needs_acknowledgement=false);
            con.handshake_state = .COMPLETED;
        }

        return;
    }

    if tcp.flags & .ACK {
        // Handle the fact that something we transmitted was acknowledged.

        for* info: con.in_flight {
            if info.sequence <= tcp.ack_number {
                // Any segment that has been acknowledged (bytes later than it have been received) will never need to be retransmitted.
                free_4k_page(cast(u64, info.packet.data - DIRECT_MAPPING_BASE));
                remove info;
            }
        }
    }

    if tcp.sequence_number == con.last_received_byte + 1 {
        length := get(ip, .total_length) - size_of(Ipv4_Header) - size_of(Tcp_Header);

        if length == 0 {
            // It's just an ACK or FIN, handled above.
            return;
        }

        con.last_received_byte += length.(u32);

        // Transmit ACK
        transmit_tcp_packet(net, con, .ACK, needs_acknowledgement=false);

        packet_data: string;
        packet_data.data = cast(*u8, *tcp + 1);
        packet_data.count = length.(s64);

        array_add(*con.received_segments, packet_data);
    }
}

HTTP_SERVER_PORT :: 80;



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

    MAGIC :: 0x63825363;
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

Dhcp_Option_Code :: enum u8 {
    request_ip   :: 0x32;
    message_type :: 0x35;
    prl          :: 0x37;
    terminator   :: 0xff;
}

byte_swap_dhcp_message :: (dhcp: *Dhcp_Message) {
    dhcp.xid     = bs32(dhcp.xid);
    dhcp.seconds = bs16(dhcp.seconds);
    dhcp.flags   = bs16(dhcp.flags);
    dhcp.magic   = bs32(dhcp.magic);
}

get_dhcp_message_type :: (dhcp: *Dhcp_Message) -> Dhcp_Message_Type {
    options := cast(*Dhcp_Option_Code, dhcp + 1);

    while options.* != .terminator {
        if options.* != .message_type {
            options += cast(u8) options[1] + 2;
        }

        return cast(Dhcp_Message_Type) options[2];
    }
}

DHCP_CLIENT_PORT :: 68;
DHCP_SERVER_PORT :: 67;

update_dhcp :: (using net: *Network_Connection) {
    if dhcp_handshake_state == .NOT_STARTED {
        packet:, dhcp_xid = make_dhcp_discover(net);

        log("Transmitting DHCP discover (XID %)...", hex(dhcp_xid));
        i8254x_transmit_packet(*adapter, packet);

        dhcp_handshake_state = .DISCOVER_TRANSMITTED;
    }

    if dhcp_handshake_state >= .ARP_PROBE_1_TRANSMITTED && dhcp_handshake_state <= .ARP_PROBE_3_TRANSMITTED {
        probe_time_elapsed := arp_probe_transmitted_at < get_monotonic_time() - seconds_to_apollo(1);

        if probe_time_elapsed {
            if dhcp_handshake_state != .ARP_PROBE_3_TRANSMITTED {
                transmit_arp_probe(net);
                log("ARP probe sent");
            }

            dhcp_handshake_state += 1;
            arp_probe_transmitted_at = get_monotonic_time();
        }
    }
}

Dhcp_Packet :: struct {
    eth: Ethernet_Header;
    ip: Ipv4_Header #align 1;
    udp: Udp_Header #align 1;
    dhcp: Dhcp_Message #align 1;
}

handle_dhcp_packet :: (using net: *Network_Connection, eth_: *Ethernet_Header) {
    using packet := cast(*Dhcp_Packet) eth_;

    if udp.length < size_of(Dhcp_Message) + size_of(Udp_Header) {
        log_error("Bad DHCP packet, too small.");
        return;
    }

    byte_swap_dhcp_message(*dhcp);

    if dhcp.magic != Dhcp_Message.MAGIC {
        log_error("Bad DHCP packet, magic doesn't match.");
        return;
    }

    if _memcmp(dhcp.client_mac.data, adapter.mac_address.data, 6) != 0 {
        return;
    }

    if dhcp.xid != dhcp_xid {
        log_error("Got DHCP message with invalid transaction ID.");
        return;
    }

    if get_dhcp_message_type(*dhcp) == {
      case .offer;
        if dhcp_handshake_state != .DISCOVER_TRANSMITTED {
            log_error("Unexpected DHCP offer.");
            return;
        }

        our_ip = dhcp.your_ip;
        router_ip = ip.source_address;
        router_mac_address = eth.source_mac;

        log("Got DHCP offer for IP: %.", format_ip(our_ip));
        log("Server IP: %, server MAC: %.", format_ip(router_ip), format_mac(router_mac_address));

        packet := make_dhcp_request(net, dhcp_xid);
        i8254x_transmit_packet(*adapter, packet);

        dhcp_handshake_state = .OFFER_ACCEPTED;

      case .ack;
        if dhcp_handshake_state != .OFFER_ACCEPTED {
            log_error("Unexpected DHCP ACK.");
            return;
        }

        log("DHCP request acknowledged. Sending ARP probe...");

        transmit_arp_probe(net);
        arp_probe_transmitted_at = get_monotonic_time();

        dhcp_handshake_state = .ARP_PROBE_1_TRANSMITTED;
    }
}

make_dhcp_discover :: (net: *Network_Connection) -> Network_Packet, u32 {
    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    xid := cast(u32) random_get();

    eth: Ethernet_Header;
    eth.destination_mac = BROADCAST_MAC;
    eth.source_mac = net.adapter.mac_address;
    eth.ethertype = .IPv4;

    add_to_packet(*packet, eth);

    // DHCP options
    dhcp_opt_discover   := u8.[0x35, 0x01, 0x01];
    dhcp_opt_prl        := u8.[0x37, 0x04, 0x01, 0x03, 0x0f, 0x06, 0xff];

    dhcp_options_length : u16 = dhcp_opt_discover.count + dhcp_opt_prl.count;

    ip_length := size_of(Ipv4_Header)
        + size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    ip := init_ip_header(net, .UDP, 0xff_ff_ff_ff, ip_length);
    add_to_packet(*packet, ip);

    udp: Udp_Header;
    udp.source_port = DHCP_CLIENT_PORT;
    udp.destination_port = DHCP_SERVER_PORT;
    udp.length = size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    byte_swap_udp_header(*udp);
    add_to_packet(*packet, udp);

    dhcp: Dhcp_Message;
    dhcp.opcode = 0x1;
    dhcp.hardware_type = 0x1;
    dhcp.mac_length = 0x6;
    dhcp.xid = xid;
    dhcp.client_mac = net.adapter.mac_address;

    dhcp.magic = Dhcp_Message.MAGIC;

    byte_swap_dhcp_message(*dhcp);
    add_to_packet(*packet, dhcp);

    add_to_packet(*packet, dhcp_opt_discover);
    add_to_packet(*packet, dhcp_opt_prl);

    return packet, xid;
}

make_dhcp_request :: (net: *Network_Connection, xid: u32) -> Network_Packet {

    // Largely copy-pasted from "make_dhcp_discover"...

    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    eth: Ethernet_Header;
    eth.destination_mac = BROADCAST_MAC;
    eth.source_mac = net.adapter.mac_address;
    eth.ethertype = .IPv4;

    add_to_packet(*packet, eth);

    // DHCP options
    dhcp_opt_request := u8.[0x35, 0x01, 0x03];

    router_ip := (*net.router_ip).(*[4]u8).*;
    our_ip := (*net.our_ip).(*[4]u8).*;

    dhcp_opt_server := u8.[
        0x36, 0x04,
        router_ip[0],
        router_ip[1],
        router_ip[2],
        router_ip[3]
    ];

    dhcp_opt_requested_ip := u8.[
        0x32, 0x04,
        our_ip[0],
        our_ip[1],
        our_ip[2],
        our_ip[3],

        0xff
    ];

    dhcp_options_length : u16 = dhcp_opt_request.count + dhcp_opt_server.count + dhcp_opt_requested_ip.count;

    ip_length := size_of(Ipv4_Header)
        + size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    ip := init_ip_header(net, .UDP, 0xff_ff_ff_ff, ip_length);
    add_to_packet(*packet, ip);

    udp: Udp_Header;
    udp.source_port = DHCP_CLIENT_PORT;
    udp.destination_port = DHCP_SERVER_PORT;
    udp.length = size_of(Udp_Header)
        + size_of(Dhcp_Message)
        + dhcp_options_length;

    byte_swap_udp_header(*udp);
    add_to_packet(*packet, udp);

    dhcp: Dhcp_Message;
    dhcp.opcode = 0x1;
    dhcp.hardware_type = 0x1;
    dhcp.mac_length = 0x6;
    dhcp.xid = xid;
    dhcp.client_mac = net.adapter.mac_address;
    dhcp.server_ip = net.router_ip;
    dhcp.magic = Dhcp_Message.MAGIC;

    byte_swap_dhcp_message(*dhcp);
    add_to_packet(*packet, dhcp);

    add_to_packet(*packet, dhcp_opt_request);
    add_to_packet(*packet, dhcp_opt_server);
    add_to_packet(*packet, dhcp_opt_requested_ip);

    return packet;
}



Icmp_Header :: struct {
    control_message: enum u16 {
        // Type and code (subtype) combined into one field

        echo_reply   :: 0x00_00;
        echo_request :: 0x00_08;
    }

    checksum: u16;
    data: u32;
}

Icmp_Packet :: struct {
    eth: Ethernet_Header;
    ip: Ipv4_Header #align 1;
    using icmp: Icmp_Header #align 1;
}

handle_icmp_packet :: (net: *Network_Connection, eth: *Ethernet_Header) {
    icmp := cast(*Icmp_Packet) eth;

    if icmp.control_message == {
      case .echo_request;
        log("Got pinged by %, sending pong", format_ip(icmp.ip.source_address));
        transmit_pong(net, icmp);

      case .echo_reply;
        for net.pings_in_flight {
            if it.id == icmp.data {
                time := get_monotonic_time();

                delta_us := to_milliseconds(time - it.sent_at);
                log("Ping % = %ms", format_ip(it.destination_ip), delta_us);

                remove it;
                break;
            }
        }
    }
}

transmit_pong :: (net: *Network_Connection, ping: *Icmp_Packet) {
    using pong: Icmp_Packet;

    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;
    defer free_4k_page(cast(u64, packet.data - DIRECT_MAPPING_BASE));

    eth.destination_mac = ping.eth.source_mac;
    eth.source_mac      = ping.eth.destination_mac;
    eth.ethertype       = .IPv4;

    ip = init_ip_header(net, .ICMP, ping.ip.source_address, size_of(Ipv4_Header) + size_of(Icmp_Header));

    icmp.control_message = .echo_reply;
    icmp.data = ping.icmp.data;
    icmp.checksum = internet_checksum(icmp);

    add_to_packet(*packet, pong);

    i8254x_transmit_packet(*net.adapter, packet);
}

transmit_ping :: (net: *Network_Connection, destination_ip: u32) {
    using ping: Icmp_Packet;

    eth = init_ethernet_header(net);
    ip = init_ip_header(net, .ICMP, destination_ip, size_of(Ipv4_Header) + size_of(Icmp_Header));

    icmp.control_message = .echo_request;
    icmp.data = xx random_get() & 0xffff;
    icmp.checksum = internet_checksum(icmp);

    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    add_to_packet(*packet, ping);

    success := i8254x_transmit_packet(*net.adapter, packet);
    if !success bluescreen();

    time := get_monotonic_time();

    array_add(*net.pings_in_flight, .{
        id = icmp.data,
        destination_ip = destination_ip,
        sent_at = time,
    });
}



Dns_Header :: struct {
    transaction_id: u16;

    flags: u16;

    questions: u16;
    answers: u16;
    authority_rrs: u16;
    additional_rrs: u16;
}

byte_swap_dns_header :: (dns: *Dns_Header) {
    dns.transaction_id = bs16(dns.transaction_id);
    dns.questions      = bs16(dns.questions);
    dns.answers        = bs16(dns.answers);
    dns.authority_rrs  = bs16(dns.authority_rrs);
    dns.additional_rrs = bs16(dns.additional_rrs);
}

DNS_SERVER_PORT :: 53;

transmit_dns_query :: (net: *Network_Connection, url: string) {
    packet: Network_Packet;
    packet.data = cast(*void) get_4k_page() + DIRECT_MAPPING_BASE;

    xid := cast(u16) random_get();

    eth := init_ethernet_header(net);
    add_to_packet(*packet, eth);

    ip_length := size_of(Ipv4_Header)
        + size_of(Udp_Header)
        + size_of(Dns_Header)
        + cast(u16) url.count + 6; // 6 because TYPE, CLASS, first label length, and zero terminator.

    ip := init_ip_header(net, .UDP, net.router_ip, ip_length);
    add_to_packet(*packet, ip);

    udp: Udp_Header;
    udp.source_port = allocate_port(net);
    udp.destination_port = DNS_SERVER_PORT;
    udp.length = size_of(Udp_Header)
        + size_of(Dns_Header)
        + cast(u16) url.count + 6;

    byte_swap_udp_header(*udp);
    add_to_packet(*packet, udp);

    dns: Dns_Header;
    dns.transaction_id = xid;
    dns.flags = 1;
    dns.questions = 1;

    byte_swap_dns_header(*dns);
    add_to_packet(*packet, dns);

    current_label_length: u8;

    remaining := url;

    while true {
        found, left, right := split_from_left(remaining, #char ".");
        add_to_packet(*packet, left.count.(u8));
        add_to_packet(*packet, left);

        if !found break;

        remaining = right;
    }
    add_to_packet(*packet, (0).(u8));

    add_to_packet(*packet, bs16(1).(u16)); // TYPE
    add_to_packet(*packet, bs16(1).(u16)); // CLASS

    i8254x_transmit_packet(*net.adapter, packet);

    array_add(*net.dns_queries_in_flight, .{
        id = xid,
        url = url,
        sent_at = get_monotonic_time(),
    });
}

Dns_Packet :: struct {
    eth: Ethernet_Header;
    ip: Ipv4_Header #align 1;
    udp: Udp_Header #align 1;
    dns: Dns_Header #align 1;
} #no_padding

Dns_Record_Type :: enum u16 {
    A     :: 0x0100;
    CNAME :: 0x0500;
}

handle_dns_packet :: (net: *Network_Connection, eth_: *Ethernet_Header) {
    using packet := cast(*Dns_Packet) eth_;

    // Todo: parsing DNS records is very hardcoded right now

    byte_swap_dns_header(*packet.dns);

    for* query: net.dns_queries_in_flight {
        if query.id != dns.transaction_id {
            continue;
        }

        if query.complete {
            continue;
        }

        Skip_Name :: () #expand {
            while cursor.* != 0 {
                cursor += cursor.*;
                cursor += 1;
            }
            cursor += 1;
        }

        cursor := cast(*u8, *dns + 1);
        for 0..dns.questions-1 {
            // Skip all the questions.
            Skip_Name();

            cursor += 2; // TYPE
            cursor += 2; // CLASS
        }

        // Should now be at the answers. Find a host address.

        for 0..dns.answers-1 {
            // Detect if it's a pointer
            if (cursor[0] >> 6) == 0b11 {
                cursor += 2;
            } else {
                Skip_Name();
            }

            type := cursor.(*Dns_Record_Type).*;

            cursor += 8; // Class, type, TTL
            data_length := bs16(cursor.(*u16).*);

            cursor += 2; // Data length

            if type == .A {
                if data_length != 4 {
                    log_error("DNS response address is not IPv4");
                    return;
                }

                query.answer = cursor.(*u32).*;

                log("Got DNS response regarding \"%\". IP is %", query.url, format_ip(query.answer));

                query.complete = true;
                return;
            } else {
                cursor += data_length;
            }
        }
    }

    log_error("Got unexpected DNS response from %.", format_ip(ip.source_address));
}




Network_Packet :: struct {
    data: *void;
    length: int;
}

add_to_packet :: (packet: *Network_Packet, data: Any) {
    if data.type.type == .STRING {
        s := data.value_pointer.(*string).*;

        memcpy(packet.data + packet.length, s.data, s.count);
        packet.length += s.count;

        return;
    }

    memcpy(packet.data + packet.length, data.value_pointer, data.type.runtime_size);
    packet.length += data.type.runtime_size;
}



format_mac :: (mac: [6] u8) -> string {
    Push_Print_Style(mac_address_print_style);
    return tprint("%", mac);
}

format_ip :: (ip: u32) -> string {
    ip_array := (*ip).(*[4]u8).*;

    return tprint("%.%.%.%",
        ip_array[0],
        ip_array[1],
        ip_array[2],
        ip_array[3]
    );
}

Network_Connection :: struct {
    router_mac_address: [6] u8;

    our_ip: u32;
    router_ip: u32;

    adapter: I8254x_Network_Interface_Card;

    dhcp_xid: u32;

    dhcp_handshake_state: enum {
        NOT_STARTED;
        DISCOVER_TRANSMITTED;
        OFFER_ACCEPTED;
        ARP_PROBE_1_TRANSMITTED;
        ARP_PROBE_2_TRANSMITTED;
        ARP_PROBE_3_TRANSMITTED;
        COMPLETED;
    }
    arp_probe_transmitted_at: Apollo_Time;
    arp_table: Table(u32, [6]u8);

    pings_in_flight: [..] struct {
        id: u32;
        destination_ip: u32;
        sent_at: Apollo_Time;
    };

    dns_queries_in_flight: [..] struct {
        id: u16;
        url: string;
        sent_at: Apollo_Time;
        complete: bool;
        answer: u32;
    };

    tcp_connections: [..] Tcp_Connection;
    next_port: u16;

    spinlock: Spinlock;
}

allocate_port :: (net: *Network_Connection) -> u16 {
    port := net.next_port;
    net.next_port += 1;

    return port;
}

network_thread :: () #c_call {
    push_context,defer_pop;

    core := get_current_core();
    release(*core.scheduler.spinlock);

    Log_Category("Net");
    using net := *kernel_globals.net;
    next_port = FIRST_EPHEMERAL_PORT;

    LOG_ALL_RECEIVED_ETHERNET_PACKETS :: false;

    while true  {
        acquire(*spinlock);

        if dhcp_handshake_state != .COMPLETED {
            update_dhcp(net);
        }

        packets := i8254x_get_newly_received_packets(*adapter);

        for packets {
            eth := cast(*Ethernet_Header) it.data;

            if LOG_ALL_RECEIVED_ETHERNET_PACKETS {
                Push_Print_Style(mac_address_print_style);
                log("% => % (%)", eth.source_mac, eth.destination_mac, eth.ethertype);
            }

            if eth.ethertype == .ARP {
                handle_arp(net, eth);
                continue;
            }

            if eth.ethertype != .IPv4 {
                log("Received network packet with unsupported protocol %.", eth.ethertype);
                continue;
            }

            ip := cast(*Ipv4_Header) (eth + 1);
            assert(get(ip.*, .ihl) == 5);

            if ip.protocol == {
              case .ICMP;
                handle_icmp_packet(net, eth);

              case .UDP;
                udp := cast(*Udp_Header) (ip + 1);
                byte_swap_udp_header(udp);

                if udp.destination_port == DHCP_CLIENT_PORT {
                    handle_dhcp_packet(net, eth);
                }

                if udp.source_port == DNS_SERVER_PORT {
                    handle_dns_packet(net, eth);
                }

              case .TCP;
                handle_tcp_packet(net, eth);

              case;
                log("Received IP packet with unsupported protocol %.", ip.protocol);
            }
        }

        release(*spinlock);

        sleep(5, .milliseconds);
    }
}
