
#import "Basic";
#import "Compiler";
#import "Bindings_Generator";
#import "File_Utilities";

#run {
    set_build_options_dc(.{do_output=false});

    options: Generate_Bindings_Options;
    //    array_add(*options.include_paths, ".");

    source_files := file_list("libecc/include/libecc");
    array_add(*options.source_files, ..source_files);
    array_add(*options.include_paths, "libecc/include");

    array_add(*options.libnames, "libarith", "libec", "libsign");
    array_add(*options.libpaths, ".");

    options.strip_enum_prefixes = false;
    options.auto_detect_enum_prefixes = false;
    options.alias_original_enum_names = false;
    // options.c_enum_emulation = false;

    options.log_unsupported = true;
    options.generate_compile_time_struct_checks = false;
    generate_bindings(options, "module.jai");
}
