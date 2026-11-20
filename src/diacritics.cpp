// Diacritics - Total Commander content plugin (WDX)
// Provides file name fields without diacritics / with diacritics restored
// from a dictionary, for use in Multi-Rename Tool (Ctrl+M): [=diacritics.<field>]

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <string_view>
#include <deque>
#include <unordered_map>
#include <mutex>
#include <vector>

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
    F_NAME_ADD,     // name without extension, diacritics added
    F_EXT_STRIP,    // extension, diacritics removed
    F_FULL_STRIP,   // whole name, diacritics removed
    F_FULL_ADD,     // whole name, diacritics added
    F_COUNT
};

static const char* kFieldNames[F_COUNT] = {
    "Nazev bez diakritiky",
    "Nazev s diakritikou",
    "Pripona bez diakritiky",
    "Cely nazev bez diakritiky",
    "Cely nazev s diakritikou",
};

// ---- Globals ---------------------------------------------------------------
static HMODULE g_module = nullptr;
static std::once_flag g_loadOnce;
// Keys and values point into g_store (file texts and computed keys); a deque
// keeps them at stable addresses, so the map holds no strings of its own.
static std::deque<std::wstring> g_store;
static std::unordered_map<std::wstring_view, std::wstring_view> g_dict;
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

// ---- Dictionary ------------------------------------------------------------
static std::wstring ModuleDir() {
    wchar_t path[MAX_PATH * 2];
    DWORD n = GetModuleFileNameW(g_module, path, MAX_PATH * 2);
    std::wstring p(path, n);
    size_t slash = p.find_last_of(L"\\/");
    return slash == std::wstring::npos ? L"" : p.substr(0, slash + 1);
}

static std::wstring ToLower(const std::wstring& s) {
    std::wstring r = s;
    if (!r.empty()) CharLowerBuffW(&r[0], (DWORD)r.size());
    return r;
}

static bool ReadUtf8File(const std::wstring& path, std::wstring& text) {
    HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) return false;
    LARGE_INTEGER size;
    std::string bytes;
    bool ok = GetFileSizeEx(h, &size) && size.QuadPart < (64 << 20);
    if (ok) {
        bytes.resize((size_t)size.QuadPart);
        DWORD read = 0;
        ok = bytes.empty() || (ReadFile(h, &bytes[0], (DWORD)bytes.size(), &read, nullptr) &&
                               read == bytes.size());
    }
    CloseHandle(h);
    if (!ok) return false;
    size_t start = (bytes.size() >= 3 && bytes.compare(0, 3, "\xEF\xBB\xBF") == 0) ? 3 : 0;
    int len = (int)(bytes.size() - start);
    text.clear();
    if (len == 0) return true;
    int wlen = MultiByteToWideChar(CP_UTF8, 0, bytes.data() + start, len, nullptr, 0);
    text.resize(wlen);
    MultiByteToWideChar(CP_UTF8, 0, bytes.data() + start, len, &text[0], wlen);
    return true;
}

static std::wstring_view Trim(std::wstring_view s) {
    size_t a = s.find_first_not_of(L" \t\r");
    if (a == std::wstring_view::npos) return {};
    size_t b = s.find_last_not_of(L" \t\r");
    return s.substr(a, b - a + 1);
}

// Line formats:
//   plain<TAB>accented     (generated dictionary)
//   plain=accented         (user file)
//   accented               (user file; key = word without diacritics)
//   # comment
// Prefix-coded dictionary (tools/build_dict.py, "# format: prefix-coded v1"):
// each non-comment line is chr('0' + n) followed by the rest of the word,
// n = number of leading characters shared with the previous word. Only the
// lowercase form with diacritics is stored; the key is derived here.
static void LoadPrefixCoded(std::wstring_view text, size_t expected) {
    std::wstring values, keys;
    values.reserve(text.size() * 2);
    std::vector<std::pair<size_t, size_t>> spans;  // offset, length (same in both)
    spans.reserve(expected);
    std::wstring prev, word;
    size_t pos = 0;
    while (pos < text.size()) {
        size_t eol = text.find(L'\n', pos);
        if (eol == std::wstring_view::npos) eol = text.size();
        std::wstring_view line = text.substr(pos, eol - pos);
        pos = eol + 1;
        if (!line.empty() && line.back() == L'\r') line.remove_suffix(1);
        if (line.empty() || line[0] == L'#') continue;
        size_t shared = (size_t)(line[0] - L'0');
        if (line[0] < L'0' || shared > prev.size()) continue;  // damaged line
        word.assign(prev, 0, shared);
        word.append(line.substr(1));
        std::wstring key = StripAccents(word);
        if (key.size() == word.size()) {
            spans.emplace_back(values.size(), word.size());
            values += word;
            keys += key;
        }
        prev.swap(word);
    }
    values.shrink_to_fit();
    keys.shrink_to_fit();
    g_store.push_back(std::move(values));
    const std::wstring& v = g_store.back();
    g_store.push_back(std::move(keys));
    const std::wstring& k = g_store.back();
    g_dict.reserve(g_dict.size() + spans.size());
    for (auto& s : spans)
        g_dict[std::wstring_view(k).substr(s.first, s.second)] =
            std::wstring_view(v).substr(s.first, s.second);
}

static void LoadDictFile(const std::wstring& path, size_t expected) {
    std::wstring tmp;
    if (!ReadUtf8File(path, tmp)) return;
    if (tmp.find(L"# format: prefix-coded v1") != std::wstring::npos) {
        LoadPrefixCoded(tmp, expected);
        return;
    }
    if (!tmp.empty()) CharLowerBuffW(&tmp[0], (DWORD)tmp.size());
    g_store.push_back(std::move(tmp));
    std::wstring_view text = g_store.back();
    if (expected) g_dict.reserve(g_dict.size() + expected);
    size_t pos = 0;
    while (pos < text.size()) {
        size_t eol = text.find(L'\n', pos);
        if (eol == std::wstring_view::npos) eol = text.size();
        std::wstring_view line = Trim(text.substr(pos, eol - pos));
        pos = eol + 1;
        if (line.empty() || line[0] == L'#') continue;
        size_t sep = line.find_first_of(L"\t=");
        std::wstring_view key, value;
        if (sep == std::wstring_view::npos) {
            value = line;
            g_store.push_back(StripAccents(std::wstring(line)));
            key = g_store.back();
        } else {
            key = Trim(line.substr(0, sep));
            value = Trim(line.substr(sep + 1));
        }
        if (!key.empty() && key.size() == value.size()) g_dict[key] = value;
    }
}

static void LoadDictionaries() {
    std::wstring dir = ModuleDir();
    LoadDictFile(dir + L"diacritics.dic", 300000);
    LoadDictFile(dir + L"diacritics.user.txt", 0);  // user entries win
}

// ---- Adding diacritics -----------------------------------------------------
static bool IsLetter(wchar_t c) { return IsCharAlphaW(c) != FALSE; }
static bool IsUpper(wchar_t c) { return IsCharUpperW(c) != FALSE; }

static std::wstring AccentWord(const std::wstring& word) {
    for (wchar_t c : word)
        if (c >= 0x80) return word;  // already has non-ASCII letters, leave it
    auto it = g_dict.find(ToLower(word));
    if (it == g_dict.end()) return word;
    std::wstring r(it->second);
    // Copy the case of each letter (lengths are equal).
    for (size_t i = 0; i < r.size(); ++i)
        if (IsUpper(word[i])) CharUpperBuffW(&r[i], 1);
    return r;
}

static std::wstring AddAccents(const std::wstring& s) {
    std::call_once(g_loadOnce, LoadDictionaries);
    std::wstring r;
    r.reserve(s.size());
    size_t i = 0;
    while (i < s.size()) {
        if (!IsLetter(s[i])) { r += s[i++]; continue; }
        // A word ends at a non-letter, or at a lower->upper step (CamelCase),
        // but an all-caps word stays together.
        size_t j = i + 1;
        while (j < s.size() && IsLetter(s[j]) && !(IsUpper(s[j]) && !IsUpper(s[j - 1])))
            ++j;
        r += AccentWord(s.substr(i, j - i));
        i = j;
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

static bool ComputeField(int field, const wchar_t* fileName, std::wstring& out) {
    std::wstring name = BaseName(fileName), stem, ext;
    SplitExt(name, stem, ext);
    switch (field) {
        case F_NAME_STRIP: out = StripAccents(stem); return true;
        case F_NAME_ADD:   out = AddAccents(stem); return true;
        case F_EXT_STRIP:  out = StripAccents(ext); return true;
        case F_FULL_STRIP: out = StripAccents(name); return true;
        case F_FULL_ADD:   out = AddAccents(stem) + (ext.empty() ? L"" : L"." + ext); return true;
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
        g_module = hinst;
        DisableThreadLibraryCalls(hinst);
    }
    return TRUE;
}
