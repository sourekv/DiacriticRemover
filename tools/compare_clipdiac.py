"""Compare ClipDiac's character tables with the plugin's diacritics removal.

ClipDiac.exe (2003) holds four 128-byte tables that map the upper half
(0x80-0xFF) of Kamenicky, CP852, ISO-8859-2 and Windows-1250 to ASCII;
'_' means "leave unchanged". For every byte this script decodes the
character, asks the plugin (field "Cely nazev bez diakritiky") and prints
the cases where the two differ.

Usage (64-bit Python):
  python tools/compare_clipdiac.py C:/path/ClipDiac.exe out/diacritics.wdx64
"""
import ctypes
import sys

# Kamenicky (KEYBCS2) 0x80-0xAF; the rest matches CP437.
KAMENICKY = "ČüéďäĎŤčěĚĹÍľĺÄÁÉžŽôöÓůÚýÖÜŠĽÝŘťáíóúňŇŮÔšřŕŔ¼§«»"
ENCODINGS = ["kamenicky", "cp852", "iso8859_2", "cp1250"]


def decode(enc, b):
    if enc == "kamenicky":
        return KAMENICKY[b - 0x80] if b < 0xB0 else bytes([b]).decode("cp437")
    try:
        return bytes([b]).decode(enc)
    except UnicodeDecodeError:
        return None


def main(exe, wdx):
    data = open(exe, "rb").read()
    start = data.index(b"CuedaDTce")
    # Four NUL-terminated 128-char strings, padded to 4-byte alignment.
    tables = [t.decode("ascii") for t in data[start:start + 600].split(b"\0") if t][:4]
    assert all(len(t) == 128 for t in tables), [len(t) for t in tables]

    dll = ctypes.WinDLL(wdx)
    get = dll.ContentGetValueW
    get.argtypes = [ctypes.c_wchar_p, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
    buf = ctypes.create_unicode_buffer(1024)

    def strip(ch):
        get("C:\\x\\" + ch, 3, 0, buf, ctypes.sizeof(buf), 0)
        return buf.value

    for enc, table in zip(ENCODINGS, tables):
        print(f"== {enc}")
        for i, clip in enumerate(table):
            ch = decode(enc, 0x80 + i)
            if ch is None or not ch.isprintable():
                continue
            ours = strip(ch)
            clip_out = ch if clip == "_" else clip
            if ours != clip_out:
                print(f"  0x{0x80 + i:02X} {ch!r:6} ClipDiac {clip_out!r:6} plugin {ours!r}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
