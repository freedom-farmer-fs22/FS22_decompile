import os

"""
byte[] _lut = new byte[8] { 0x14, 0x0B, 0x09, 0x02, 0x08, 0x03, 0x03, 0x03 };

bool DecodeFile(string src, string dest)
{
    byte[] file = File.ReadAllBytes(src);

    if (file[0] != 0x1B || file[1] != 'L' || file[2] != 'J') return false;

    if (file[3] == 0x03) file[3] = 0x02;
    else return false;

    for (int i = 4; i < file.Length; i++)
    {
        file[i] += (byte)(_lut[i & 0x07] + i);
    }

    Directory.CreateDirectory(Path.GetDirectoryName(dest));
    File.WriteAllBytes(dest, file);

    return true;
}
"""

lut = [0x14, 0x0B, 0x09, 0x02, 0x08, 0x03, 0x03, 0x03]
last_lut = [0x06, 0x10, 0x0C, 0x02, 0x09, 0x03, 0x04, 0x04, 0x09, 0x05, 0x04, 0x02, 0x05, 0x08, 0x09, 0x15]


def decode_file(target_file, output_folder):
    with open(target_file, 'rb') as f:
        read_file = bytearray(f.read())
    if read_file[3] == 0x03:
        read_file[3] = 2
        for i in range(4, len(read_file)):
            read_file[i] = (read_file[i] + (lut[i & 0x07] + i)) & 0xFF
    elif read_file[3] == 0x04:
        read_file[3] = 2
        for i in range(4, len(read_file)):
            read_file[i] = (read_file[i] + (last_lut[i & 0x0F] + i)) & 0xFF
    file_lua = os.path.splitext(os.path.split(target_file)[1])[0] + '.lua'
    full_lua_path = os.path.join(output_folder, file_lua)
    with open(full_lua_path, 'wb') as f:
        f.write(read_file)


def decoder(l64_files_path, output_path, rec_path=''):
    source_dir = os.path.join(l64_files_path, rec_path)
    output_dir = os.path.join(output_path, rec_path)
    os.makedirs(output_dir, exist_ok=True)
    with os.scandir(source_dir) as dir_entries:
        for file_object in dir_entries:
            if file_object.name.endswith('.l64'):
                decode_file(os.path.join(source_dir, file_object.name), output_dir)
            elif file_object.is_dir():
                decoder(l64_files_path, output_path, os.path.join(rec_path, file_object.name))


target = input('Path to *.l64 files:\n')
output = input('Output path:\n')

decoder(target, output)
