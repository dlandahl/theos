
#import "Formosa";

main :: (file_name: string) {
    file, result := read_file(file_name);

    if result != .success {
        write_string("Could not read file, not found: '");
        write_string(file_name);
        write_string("'.\n");
        return;
    }

    if !file.count {
        write_string("(empty)\n");
        return;
    }

    if file[0] == #char "\n" || file[0] == #char "\r" {
        file.data += 1;
        file.count -= 1;
    }

    output(cast(string) file);
}
