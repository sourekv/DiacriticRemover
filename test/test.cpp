// Loads the plugin like Total Commander does and prints all fields for sample names.
// Usage: test.exe <plugin.wdx|wdx64> [name ...]
// Copyright (C) 2026 Vladimir Sourek
// SPDX-License-Identifier: GPL-3.0-or-later
#include <windows.h>
#include <cstdio>

typedef int(__stdcall* GetFieldFn)(int, char*, char*, int);
typedef int(__stdcall* GetValueWFn)(WCHAR*, int, int, void*, int, int);

static void Print(const wchar_t* s) {
    char buf[2048];
    WideCharToMultiByte(CP_UTF8, 0, s, -1, buf, sizeof(buf), nullptr, nullptr);
    fputs(buf, stdout);
}

int wmain(int argc, wchar_t** argv) {
    SetConsoleOutputCP(CP_UTF8);
    if (argc < 2) { fputs("usage: test <plugin> [names]\n", stderr); return 2; }
    HMODULE h = LoadLibraryW(argv[1]);
    if (!h) {
        DWORD err = GetLastError();
        wchar_t msg[512] = L"";
        FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, nullptr, err,
                       0, msg, 512, nullptr);
        printf("LoadLibrary failed: error %lu: ", err);
        Print(msg);
        Print(L"\n");
        return 1;
    }
    printf("LoadLibrary OK (%s process)\n", sizeof(void*) == 8 ? "64-bit" : "32-bit");
    auto getField = (GetFieldFn)GetProcAddress(h, "ContentGetSupportedField");
    auto getValue = (GetValueWFn)GetProcAddress(h, "ContentGetValueW");
    if (!getField || !getValue || !GetProcAddress(h, "ContentGetValue")) {
        fputs("missing exports\n", stderr); return 1;
    }
    const wchar_t* defaults[] = {
        L"C:\\Fotky\\Český Krumlov - žlutý kůň.jpg",
        L"C:\\Docs\\Příliš žluťoučký kůň úpěl ďábelské ódy.txt",
        L"C:\\Docs\\ŠKOLA_dítě_2024.pdf",
        L"C:\\Docs\\Łódź, Straße, Ærø, Đoković, Ħamrun.příloha",
        L"C:\\Docs\\Složka s diakritikou\\",
        L"C:\\Docs\\.gitignore",
    };
    int n = argc > 2 ? argc - 2 : (int)(sizeof(defaults) / sizeof(*defaults));
    for (int i = 0; i < n; ++i) {
        const wchar_t* name = argc > 2 ? argv[i + 2] : defaults[i];
        Print(L"\n"); Print(name); Print(L"\n");
        char field[256], units[256];
        for (int f = 0; getField(f, field, units, sizeof(field)) != 0; ++f) {
            WCHAR value[1024];
            int r = getValue((WCHAR*)name, f, 0, value, sizeof(value), 0);
            printf("  %-28s ", field);
            if (r == 11) Print(value); else printf("(result %d)", r);
            Print(L"\n");
        }
    }
    return 0;
}
