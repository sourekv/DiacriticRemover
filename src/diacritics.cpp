// Diacritics - Total Commander content plugin (WDX)
// Provides file name fields without diacritics, or with diacritics broken
// by a wrong encoding fixed, for use in the Multi-Rename Tool (Ctrl+M):
// [=diacritics.<field>]
// Copyright (C) 2026 Vladimir Sourek
// SPDX-License-Identifier: GPL-3.0-or-later

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <mutex>

// ---- WDX API constants -----------------------------------------------------
#define ft_nomorefields 0
#define ft_string 8
#define ft_stringw 11
#define ft_nosuchfield -1
#define ft_fileerror -2
#define ft_fieldempty -3

struct ContentDefaultParamStruct {
    int size;
    DWORD PluginInterfaceVersionLow;
    DWORD PluginInterfaceVersionHi;
    char DefaultIniName[MAX_PATH];
};

// ---- Fields ----------------------------------------------------------------
enum Field {
    F_NAME_STRIP,   // name without extension, diacritics removed
    F_EXT_STRIP,    // extension, diacritics removed
    F_FULL_STRIP,   // whole name, diacritics removed
    F_NAME_FIX,     // name without extension, broken encoding repaired
    F_EXT_FIX,      // extension, broken encoding repaired
    F_FULL_FIX,     // whole name, broken encoding repaired
    F_COUNT
};

// English names, so that users of all languages understand them. Total
// Commander stores them in rename masks, so changing them breaks old masks.
static const char* kFieldNames[F_COUNT] = {
    "Name without diacritics",
    "Extension without diacritics",
    "Full name without diacritics",
    "Name with fixed diacritics",
    "Extension with fixed diacritics",
    "Full name with fixed diacritics",
};

// ---- Globals ---------------------------------------------------------------
static wchar_t g_stripTable[0x2000];  // covers U+0000..U+1FFF
static std::once_flag g_tableOnce;

// ---- Removing diacritics ---------------------------------------------------
static void BuildStripTable() {
    for (int c = 0; c < 0x2000; ++c) g_stripTable[c] = (wchar_t)c;
    auto fill = [](int from, int to) {
        for (int c = from; c <= to; ++c) {
            wchar_t in[2] = {(wchar_t)c, 0};
            wchar_t out[8];
            int n = NormalizeString(NormalizationD, in, 1, out, 8);
            // Take the base letter only when the rest are combining marks.
            if (n >= 2 && out[0] < 0x80) {
                bool allMarks = true;
                for (int i = 1; i < n; ++i)
                    if (out[i] < 0x0300 || out[i] > 0x036F) allMarks = false;
                if (allMarks) g_stripTable[c] = out[0];
            }
        }
    };
    fill(0x00C0, 0x024F);  // Latin-1 Supplement, Latin Extended-A/B
    fill(0x1E00, 0x1EFF);  // Latin Extended Additional
    // Letters that do not decompose.
    g_stripTable[0x0110] = L'D'; g_stripTable[0x0111] = L'd';  // Đ đ
    g_stripTable[0x0141] = L'L'; g_stripTable[0x0142] = L'l';  // Ł ł
    g_stripTable[0x00D8] = L'O'; g_stripTable[0x00F8] = L'o';  // Ø ø
    g_stripTable[0x0131] = L'i';                                // ı
    g_stripTable[0x0126] = L'H'; g_stripTable[0x0127] = L'h';  // Ħ ħ
    g_stripTable[0x013F] = L'L'; g_stripTable[0x0140] = L'l';  // Ŀ ŀ
    g_stripTable[0x0166] = L'T'; g_stripTable[0x0167] = L't';  // Ŧ ŧ
    g_stripTable[0x01FE] = L'O'; g_stripTable[0x01FF] = L'o';  // Ǿ ǿ
}

// Letters with diacritics that become two letters (ligatures with a mark
// and the dž digraph). Plain ligatures and other letters stay, except the
// long-standing ß, Æ, Œ.
static const wchar_t* ExpandLetter(wchar_t c) {
    switch (c) {
    case 0x00DF: return L"ss";  // ß
    case 0x00C6: case 0x01E2: case 0x01FC: return L"AE";  // Æ Ǣ Ǽ
    case 0x00E6: case 0x01E3: case 0x01FD: return L"ae";  // æ ǣ ǽ
    case 0x0152: return L"OE";  // Œ
    case 0x0153: return L"oe";  // œ
    case 0x01C4: return L"DZ";  // Ǆ (DŽ)
    case 0x01C5: return L"Dz";  // ǅ (Dž)
    case 0x01C6: return L"dz";  // ǆ (dž)
    }
    return nullptr;
}

static std::wstring StripAccents(const std::wstring& s) {
    std::call_once(g_tableOnce, BuildStripTable);
    std::wstring r;
    r.reserve(s.size());
    for (wchar_t c : s) {
        if (c >= 0x0300 && c <= 0x036F) continue;  // stray combining mark
        if (const wchar_t* e = ExpandLetter(c)) { r += e; continue; }
        r +=(c < 0x2000) ? g_stripTable[c] : c;
    }
    return r;
}

// ---- File name helpers -----------------------------------------------------
static std::wstring BaseName(const wchar_t* path) {
    std::wstring p(path);
    while (!p.empty() && (p.back() == L'\\' || p.back() == L'/')) p.pop_back();
    size_t slash = p.find_last_of(L"\\/");
    return slash == std::wstring::npos ? p : p.substr(slash + 1);
}

static void SplitExt(const std::wstring& name, std::wstring& stem, std::wstring& ext) {
    size_t dot = name.find_last_of(L'.');
    if (dot == std::wstring::npos || dot == 0) { stem = name; ext.clear(); }
    else { stem = name.substr(0, dot); ext = name.substr(dot + 1); }
}

// ---- Repairing broken encoding ---------------------------------------------
// A UTF-8 name read in a single-byte code page shows each accented letter as
// two or three wrong characters: "Kaffeebehälter" becomes "Kaffeebeh├ñlter"
// (DOS 437) or "KaffeebehÃ¤lter" (Windows 1252). Turn the characters back
// into bytes of that code page and read the bytes as UTF-8. The result is
// accepted only when every character exists in the code page and the bytes
// are valid UTF-8, which practically never happens for a correct name.
static bool TryCodePage(const std::wstring& s, UINT cp, std::wstring& out) {
    BOOL usedDefault = FALSE;
    int n = WideCharToMultiByte(cp, WC_NO_BEST_FIT_CHARS, s.c_str(), (int)s.size(),
                                nullptr, 0, nullptr, &usedDefault);
    if (n <= 0 || usedDefault) return false;
    std::string bytes(n, '\0');
    WideCharToMultiByte(cp, WC_NO_BEST_FIT_CHARS, s.c_str(), (int)s.size(), &bytes[0], n,
                        nullptr, &usedDefault);
    if (usedDefault) return false;
    // The round trip must give the same text (no character was approximated).
    int m = MultiByteToWideChar(cp, 0, bytes.data(), n, nullptr, 0);
    std::wstring back(m, L'\0');
    MultiByteToWideChar(cp, 0, bytes.data(), n, &back[0], m);
    if (back != s) return false;
    int u = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes.data(), n, nullptr, 0);
    if (u <= 0) return false;
    out.assign(u, L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes.data(), n, &out[0], u);
    return out != s;
}

// Characters outside the common alphabets (Latin with accents, Greek,
// Cyrillic) make a repair less likely to be the right one.
static int Rarity(const std::wstring& s) {
    int r = 0;
    for (wchar_t c : s)
        if (!(c < 0x80 || (c >= 0xA0 && c <= 0x17F) || (c >= 0x370 && c <= 0x4FF) ||
              (c >= 0x1E00 && c <= 0x1EFF) || (c >= 0x2010 && c <= 0x2026)))
            ++r;
    return r;
}

static std::wstring FixEncoding(std::wstring s) {
    // Several code pages may give valid UTF-8, e.g. "Ã©" is "é" read in 1252
    // but also a rare letter read in DOS 850. Take the least rare result; on
    // a tie the order below decides.
    static const UINT kCodePages[] = {437, 850, 852, 1252, 1250};
    for (int round = 0; round < 3; ++round) {  // repairs double damage too
        bool nonAscii = false;
        for (wchar_t c : s) if (c >= 0x80) nonAscii = true;
        if (!nonAscii) break;
        std::wstring best, fixed;
        int bestRarity = 0x7FFFFFFF;
        for (UINT cp : kCodePages)
            if (TryCodePage(s, cp, fixed)) {
                int r = Rarity(fixed);
                if (r < bestRarity) { best = fixed; bestRarity = r; }
            }
        if (best.empty()) break;
        s = best;
    }
    return s;
}

static bool ComputeField(int field, const wchar_t* fileName, std::wstring& out) {
    std::wstring name = BaseName(fileName), stem, ext;
    SplitExt(name, stem, ext);
    switch (field) {
        case F_NAME_STRIP: out = StripAccents(stem); return true;
        case F_EXT_STRIP:  out = StripAccents(ext); return true;
        case F_FULL_STRIP: out = StripAccents(name); return true;
        case F_NAME_FIX:   out = FixEncoding(stem); return true;
        case F_EXT_FIX:    out = FixEncoding(ext); return true;
        case F_FULL_FIX:   out = FixEncoding(name); return true;
    }
    return false;
}

// ---- Exports ---------------------------------------------------------------
extern "C" {

int __stdcall ContentGetSupportedField(int FieldIndex, char* FieldName, char* Units, int maxlen) {
    if (FieldIndex < 0 || FieldIndex >= F_COUNT) return ft_nomorefields;
    lstrcpynA(FieldName, kFieldNames[FieldIndex], maxlen);
    if (maxlen > 0) Units[0] = 0;
    return ft_stringw;
}

int __stdcall ContentGetValueW(WCHAR* FileName, int FieldIndex, int UnitIndex,
                               void* FieldValue, int maxlen, int flags) {
    std::wstring v;
    if (!ComputeField(FieldIndex, FileName, v)) return ft_nosuchfield;
    if (v.empty()) return ft_fieldempty;
    lstrcpynW((WCHAR*)FieldValue, v.c_str(), maxlen / (int)sizeof(WCHAR));
    return ft_stringw;
}

int __stdcall ContentGetValue(char* FileName, int FieldIndex, int UnitIndex,
                              void* FieldValue, int maxlen, int flags) {
    wchar_t wname[MAX_PATH * 2];
    if (!MultiByteToWideChar(CP_ACP, 0, FileName, -1, wname, MAX_PATH * 2)) return ft_fileerror;
    std::wstring v;
    if (!ComputeField(FieldIndex, wname, v)) return ft_nosuchfield;
    if (v.empty()) return ft_fieldempty;
    WideCharToMultiByte(CP_ACP, 0, v.c_str(), -1, (char*)FieldValue, maxlen, nullptr, nullptr);
    ((char*)FieldValue)[maxlen - 1] = 0;
    return ft_string;
}

void __stdcall ContentSetDefaultParams(ContentDefaultParamStruct* dps) {}

void __stdcall ContentPluginUnloading(void) {}

}  // extern "C"

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinst);
    }
    return TRUE;
}
