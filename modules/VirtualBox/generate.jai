
#import "Basic";
#import "Compiler";
#import "Bindings_Generator";

#run {
    set_build_options_dc(.{do_output=false});

    options: Generate_Bindings_Options;
//    array_add(*options.include_paths, ".");
    array_add(*options.source_files, "test.h");
    // array_add(*options.libnames, "ds5w_x64");
    // array_add(*options.libpaths, ".");
    // options.strip_enum_prefixes = false;
    // options.auto_detect_enum_prefixes = false;
    // options.alias_original_enum_names = false;
    // options.c_enum_emulation = true;
    options.log_unsupported = true;

    options.generate_compile_time_struct_checks = false;

    generate_bindings(options, "generated.jai");
}
