
Kernel_Timestamp :: struct {
    counter: u64;
    ticks:   u64;
}

get_kernel_timestamp :: () -> Kernel_Timestamp {
    using kernel_globals;
    ts: Kernel_Timestamp;

    sequence_read(*high_precision_timer.seq_lock, #code {
        // Todo: HPET might be worse than TSC or LAPIC for system time
        // This could also just use 16-byte compare exchange instead of a seqlock

        ts.counter = high_precision_timer.timers[0].counter;
        ts.ticks   = high_precision_timer.timers[0].ticks_at_last_interrupt;
    });

    // Todo: figure out the performace characteristics of reading this register
    ticks_now := cast(u64) read(.COUNTER);

    if ticks_now < ts.ticks {
        counter_max: u64 = 0xffff_ffff;
        if high_precision_timer.timers[0].counter_is_64_bit {
            counter_max = 0xffff_ffff_ffff_ffff;
        }

        ts.ticks = ticks_now + (counter_max - ts.ticks);
    } else {
        ts.ticks = ticks_now - ts.ticks;
    }

    return ts;
}

kernel_timestamp_to_apollo :: (ts: Kernel_Timestamp) -> Apollo_Time {
    using kernel_globals;

    time_represented_by_ticks: Apollo_Time;
    time_represented_by_ticks.low = cast(u64) ts.ticks;
    time_represented_by_ticks *= cast(s64) high_precision_timer.tick_period_femtoseconds;

    femtoseconds_per_millisecond := 1.e12;
    time_represented_by_counter: Apollo_Time;
    time_represented_by_counter.low = ts.counter;
    time_represented_by_counter *= cast(s64) (100 * femtoseconds_per_millisecond);

    return time_represented_by_counter + time_represented_by_ticks;
}

get_monotonic_system_time :: () -> Apollo_Time {
    using kernel_globals;

    ts := get_kernel_timestamp();

    return boot_time + kernel_timestamp_to_apollo(ts);
}

native_calendar_to_apollo :: (ct: Calendar_Time) -> Apollo_Time {
    leap_year_count := leap_years_before(cast(s64) ct.year - 1) - #run leap_years_before(1970);
    year_difference := cast(s64) ct.year - 1970;

    seconds := 31536000 * (year_difference - leap_year_count);
    seconds += 31622400 * leap_year_count;

    cumulative_days :: int.[
        0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365
    ];

    seconds += cumulative_days[ct.month_starting_at_0] * 86400;

    is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    if ct.month_starting_at_0 > 1 && is_leap_year {
        seconds += 86400;
    }

    seconds += 86400 * cast(int) ct.day_of_month_starting_at_0;
    seconds += cast(int) ct.hour * 60 * 60 + cast(int) ct.minute * 60 + cast(int) ct.second;

    APOLLO_TIME_FOR_JAN_1_1970 :: Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};

    apollo := seconds_to_apollo(seconds);
    apollo += milliseconds_to_apollo(ct.millisecond);
    apollo += APOLLO_TIME_FOR_JAN_1_1970;
    return apollo;
}

native_apollo_to_calendar :: (apollo: Apollo_Time) -> Calendar_Time {
    // Todo: this routine doesn't work, it's sometimes off by a day.
    APOLLO_TIME_FOR_JAN_1_1970 :: Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};
    milliseconds := to_milliseconds(apollo - APOLLO_TIME_FOR_JAN_1_1970);

    seconds      := milliseconds / 1000;
    minutes      := seconds      / 60;
    hours        := minutes      / 60;
    total_days   := hours        / 24;

    milliseconds -= seconds      * 1000;
    seconds      -= minutes      * 60;
    minutes      -= hours        * 60;
    hours        -= total_days   * 24;

    years := total_days / 365;
    leap_year_count := leap_years_before(years + 2);

    years = (total_days - leap_year_count * 366) / 365;
    years += leap_year_count;

    days := total_days - (years - leap_year_count) * 365;
    days -= leap_year_count * 366;

    years += 1970;
    is_leap_year := (years % 4 == 0) && (!(years % 100 == 0) || (years % 400 == 0));
    if is_leap_year && days < 59 days += 1;

    ct: Calendar_Time;

    days_in_month := int.[
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ];

    month: int;
    for days_in_month {
        month += 1;

        if days >= it {
            days -= it;
        } else {
            month = xx it_index;
            break;
        }
    }

    ct.year = xx years;
    // is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    // if is_leap_year && month < 2 month_day += 1;

    ct.day_of_week_starting_at_0 = xx ((4 + total_days) % 7);

    ct.month_starting_at_0 = xx month;
    ct.day_of_month_starting_at_0 = xx days;

    ct.hour = xx hours;
    ct.minute = xx minutes;
    ct.second = xx seconds;
    ct.millisecond = xx milliseconds;
    return ct;
}

leap_years_before :: (year: s64) -> s64 {
    floor_div :: (dividend: int, $ divisor: int) -> int {
        offset := cast(int) (dividend <= 0 && dividend % divisor);
        return dividend / divisor - offset;
    }

    result := floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400);
    return result;
}



// CMOS Real Time Clock (RTC)

Rtc_Port :: enum u16 {
    ADDRESS :: 0x70;
    DATA    :: 0x71;
}

Rtc_Register :: enum u8 {
    SECONDS          :: 0x00;
    SECONDS_ALARM    :: 0x01;
    MINUTES          :: 0x02;
    MINUTES_ALARM    :: 0x03;
    HOURS            :: 0x04;
    HOURS_ALARM      :: 0x05;
    WEEKDAY          :: 0x06;
    DAY_OF_THE_MONTH :: 0x07;
    MONTH            :: 0x08;
    YEAR             :: 0x09;
    STATUS_A         :: 0x0a;
    STATUS_B         :: 0x0b;
    STATUS_C         :: 0x0c;
}

rtc_init :: () {
    _24H_CLOCK : u8 : 0x2;
    BCD_MODE   : u8 : 0x4;

    status := rtc_read(.STATUS_B);
    status |= _24H_CLOCK;
    rtc_write(.STATUS_B, status);

    kernel_globals.rtc_format_is_bcd = status & BCD_MODE == 0;
}

rtc_read :: (register: Rtc_Register) -> u8 {
    using Rtc_Port;

    ax := cast(u8) register;
    #asm {
        ax === a;
        out.b ADDRESS, ax;
        in.b ax, DATA;
    }

    is_status_register := (register >= .STATUS_A) && (register <= .STATUS_C);

    if kernel_globals.rtc_format_is_bcd && !is_status_register {
        ax = (ax & 0xf) + (ax / 16) * 10;
    }

    return ax;
}

rtc_write :: (register: Rtc_Register, value: u8) {
    using Rtc_Port;

    ax := cast(u8) register;
    #asm {
        ax === a;
        out.b ADDRESS, ax;
        mov.b ax, value;
        out.b DATA, ax;
    }
}

rtc_get_calendar_time :: () -> Calendar_Time {
    cal: Calendar_Time;
    cal.time_zone = .UTC;

    cal.month\      _starting_at_0 = cast(s8) rtc_read(.MONTH) - 1;
    cal.day_of_month_starting_at_0 = cast(s8) rtc_read(.DAY_OF_THE_MONTH) - 1;
    cal.day_of_week\_starting_at_0 = cast(s8) rtc_read(.WEEKDAY) - 1;

    cal.year   = cast(s32) rtc_read(.YEAR);
    cal.hour   = cast(s8)  rtc_read(.HOURS);
    cal.minute = cast(s8)  rtc_read(.MINUTES);
    cal.second = cast(s8)  rtc_read(.SECONDS);

    fadt := kernel_globals.fadt;
    if fadt && fadt.century {
        century := cast(s32) rtc_read(cast(Rtc_Register) fadt.century);
        cal.year += century * 100;
    } else {
        cal.year += 2000;
    }

    return cal;
}



// High precision event timer (HPET)

Hpet_Acpi_Table :: struct {
    #as header: Acpi_Table_Header;
    hardware_revision: u8;
    flags: u8;
    vendor: u16;
    address_space: enum u8 { MAIN_MEMORY :: 0; IO :: 1; };
    stuff: [3] u8;
    base_address: u64 #align 1;
}

Hpet_Register :: enum u64 {
    CAPABILITIES :: 0x0;
    CONFIG       :: 0x10;
    STATUS       :: 0x20;
    COUNTER      :: 0xf0;

    TIMER0       :: 0x100;
    TIMER0_COMP  :: 0x108;
    TIMER1       :: 0x120;
    TIMER1_COMP  :: 0x128;
    TIMER2       :: 0x140;
    TIMER2_COMP  :: 0x148;
}

read :: (reg: Hpet_Register) -> u64 #no_context {
    return << cast(*u64) (kernel_globals.high_precision_timer.base_address + cast(u64) reg);
}

write :: (reg: Hpet_Register, value: u64) #no_context {
    << cast(*u64) (kernel_globals.high_precision_timer.base_address + cast(u64) reg) = value;
}

Hpet_Config_Flags :: enum_flags u64 {
    ENABLE         :: 0x1;
    LEGACY_ROUTING :: 0x2;
}

Hpet_Capability_Flags :: enum_flags u64 {
    SIXTYFOUR_BIT_COUNTER :: 0x2000;
    LEGACY_ROUTING        :: 0x8000;
}

Hpet_Timer_Flags :: enum_flags u64 {
    INTERRUPT_TYPE           :: 0x2;  // (0=edge  1=level)
    INTERRUPT_ENABLE         :: 0x4;
    PERIODIC_ENABLE          :: 0x8;
    PERIODIC_CAPABLE         :: 0x10;
    SIXTYFOUR_BIT_CAPABLE    :: 0x20;
    WRITE_ACCUMULATOR_ENABLE :: 0x40;
}

HPET :: struct {
    base_address: *void;
    tick_period_femtoseconds: u64;
    counters_are_64_bit: bool;

    Timer :: struct {
        counter: u64;
        counter_is_64_bit: bool;

        ticks_per_interrupt: u64;
        ticks_at_last_interrupt: u64;
    }

    timers: [3] Timer;

    seq_lock: Sequence_Lock;
}

initialize_hpet :: () {
    hpet := *kernel_globals.high_precision_timer;

    acpi_header := find_acpi_table("HPET");

    if acpi_header == null {
        log_error("HPET is not available");
        bluescreen();
    }

    acpi_table := cast(*Hpet_Acpi_Table) acpi_header;
    assert(acpi_table.address_space == .MAIN_MEMORY);

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096); // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet
    map_page(virtual, acpi_table.base_address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    offset_in_page := acpi_table.base_address % 0x1000;
    hpet.base_address = xx (virtual + offset_in_page);

    capabilities := cast(Hpet_Capability_Flags) read(Hpet_Register.CAPABILITIES);

    if !(capabilities & .LEGACY_ROUTING) {
        log_error("HPET does not support legacy replacement route");
        bluescreen();
    }

    hpet.counters_are_64_bit = capabilities & .SIXTYFOUR_BIT_COUNTER > 0;
    hpet.tick_period_femtoseconds = cast(u64) (capabilities >> 32);

    write(.CONFIG, read(.CONFIG) | cast(u64) Hpet_Config_Flags.LEGACY_ROUTING);

    hpet_restart();

    // Interrupt routing

    t0_gate := cast(u32) allocate_interrupt_gate();
    t1_gate := cast(u32) allocate_interrupt_gate();

    register_interrupt_gate(int__hpet_timer0_interrupt, t0_gate);
    register_interrupt_gate(int__hpet_timer1_interrupt, t1_gate);

    // Get INTI2/8 redirection entry. The numbers 2 and 8 come from the legacy replacement routing.
    // Todo: need to detect if there is an interrupt source override in the MADT.
    ioapic_add_interrupt_redirection_table_entry(2, t0_gate);
    ioapic_add_interrupt_redirection_table_entry(8, t1_gate);
}

hpet_configure_timer :: (timer_index: int, frequency: u64, periodic: bool) {
    hpet := *kernel_globals.high_precision_timer;

    register_offset := cast(Hpet_Register) (0x20 * timer_index);

    timer_flags := cast(Hpet_Timer_Flags) read(register_offset + .TIMER0);

    if !(timer_flags & .PERIODIC_CAPABLE)
        log("HPET timer % is not periodic capable", timer_index);

    if !(timer_flags & .SIXTYFOUR_BIT_CAPABLE)
        log("HPET timer % is not 64bit capable", timer_index);

    timer_flags |=  (.INTERRUPT_ENABLE | .WRITE_ACCUMULATOR_ENABLE);
    timer_flags &= ~ .INTERRUPT_TYPE;

    if periodic  timer_flags |=  .PERIODIC_ENABLE;
    else         timer_flags &= ~.PERIODIC_ENABLE;

    write(register_offset + .TIMER0, cast(u64) timer_flags);

    timer := *hpet.timers[timer_index];

    ticks_per_second := cast(u64) 1_000_000_000_000_000 / hpet.tick_period_femtoseconds;
    timer.ticks_per_interrupt = ticks_per_second / frequency;

    write(register_offset + .TIMER0_COMP, timer.ticks_per_interrupt);

    timer.counter = 0;
}

hpet_restart :: () {
    config := read(Hpet_Register.CONFIG);

    ENABLE_BIT :: cast(u64) Hpet_Config_Flags.ENABLE;

    write(.CONFIG, config & ~ENABLE_BIT);
    write(Hpet_Register.COUNTER, 0);
    write(.CONFIG, config | ENABLE_BIT);
}

#program_export hpet_timer0_interrupt :: (data: *Interrupt_Stack()) #c_call {
    using kernel_globals.high_precision_timer;

    sequence_write(*seq_lock, #code {
        timers[0].counter += 1;
        timers[0].ticks_at_last_interrupt = read(.COUNTER);
    });

    write_apic_register(.EOI__END_OF_INTERRUPT, 0);
} @InterruptRoutine

#program_export hpet_timer1_interrupt :: (data: *Interrupt_Stack()) #c_call {
    using kernel_globals.high_precision_timer;
    timers[0].counter += 1;
    write_apic_register(.EOI__END_OF_INTERRUPT, 0);
} @InterruptRoutine



calibrate_tsc :: () -> hz: u64 {
    // Try to read TSC frequency from CPUID. Modern CPUs support it, but it's not supported on either VirtualBox nor QEMU, so fallback to manual timing using HPET.
    eax, ebx, ecx, edx: u64;

    #asm {
        eax === a;
        ebx === b;
        ecx === c;
        edx === d;

        mov eax, 0x15;
        cpuid eax, ebx, ecx, edx;
    }

    if eax != 0 {
        return ecx * (ebx / eax);
    }


    // If TSC ratio is not provided by CPUID, it can in practice be derived from the processor base frequency. It's not guaranteed by the spec, but there isn't a CPU where it doesn't work.
    #asm {
        mov eax, 0x16;
        cpuid eax, ebx, ecx, edx;
    }

    if eax != 0 {
        return eax;
    }


    hpet := kernel_globals.high_precision_timer;

    calibration_time_fs: u64 = 50_000_000_000_000; // 50ms expressed as femtoseconds
    ticks_per_calibration_run := cast(u32) (calibration_time_fs / hpet.tick_period_femtoseconds);

    // Run until we get three consecutive results within a certain error
    max_error := 1000;
    delta: [3] int;

    counter_register := cast(*u32) (hpet.base_address + cast(u64) Hpet_Register.COUNTER);

    for 1..1000 {
        #asm { cli; }

        counter_start := counter_register.*;
        tsc0 := rdtsc();

        tsc1: type_of(tsc0);

        while true {
            counter_now := counter_register.*;
            tsc1 = rdtsc();

            if counter_now - counter_start > ticks_per_calibration_run {
                break;
            }
        }

        #asm { sti; }

        delta[2] = delta[1];
        delta[1] = delta[0];
        delta[0] = cast(int) (tsc1 - tsc0);

        abs :: (a: int) -> int {
            if a < 0 return -a;
            return a;
        }

        first_valid  := abs(delta[0] - delta[1]) < max_error;
        second_valid := abs(delta[0] - delta[2]) < max_error;

        if first_valid && second_valid {
            average_delta := (delta[0] + delta[1] + delta[2]) / 3;
            frequency := cast(u64) average_delta * 20; // Convert ticks per 50ms timing run to ticks per second

            log("Calibrating TSC took % 50ms calibration runs, frequency is %", it, frequency);
            return frequency;
        }
    }

    bluescreen();
    return 0;
}

debug_measure_tsc_drift :: () {
    #asm { cli; }

    tsc_start := rdtsc();
    time := get_monotonic_system_time();

    for 1..1_000_000 {
        time += seconds_to_apollo(1);
        sleep_until(time);

        tsc_now := rdtsc();
        seconds_according_to_tsc := cast(float) (tsc_now - tsc_start) / cast(float) kernel_globals.timestamp_counter_frequency;

        print("[%] Seconds elapsed according to TSC: %\n", it, seconds_according_to_tsc);
    }
}
