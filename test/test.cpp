// Loads the plugin like Total Commander does and prints all fields for sample names.
// Usage: test.exe <plugin.wdx|wdx64> [name ...]
#include <windows.h>
#include <psapi.h>
#include <cstdio>
#pragma comment(lib, "psapi.lib")

static double MemMB() {
    PROCESS_MEMORY_COUNTERS pmc = {sizeof(pmc)};
    GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc));
    return pmc.PagefileUsage / 1048576.0;
}

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
    if (!h) { fprintf(stderr, "LoadLibrary failed: %lu\n", GetLastError()); return 1; }
    auto getField = (GetFieldFn)GetProcAddress(h, "ContentGetSupportedField");
    auto getValue = (GetValueWFn)GetProcAddress(h, "ContentGetValueW");
    if (!getField || !getValue || !GetProcAddress(h, "ContentGetValue")) {
        fputs("missing exports\n", stderr); return 1;
    }
    const wchar_t* defaults[] = {
        L"C:\\Fotky\\Cesky Krumlov - zluty kun.jpg",
        L"C:\\Docs\\Příliš žluťoučký kůň úpěl ďábelské ódy.txt",
        L"C:\\Docs\\SKOLA_dite_2024.pdf",
        L"C:\\Docs\\CeskyKrumlovVyletUz.docx",
        L"C:\\Docs\\Složka s diakritikou\\",
        L"C:\\Docs\\.gitignore",
        L"C:\\Docs\\nevycerpavejte konspiracni sukovita notysek.txt",
    };
    // First "with accents" call loads the dictionary: measure it.
    {
        double before = MemMB();
        LARGE_INTEGER f, t0, t1;
        QueryPerformanceFrequency(&f);
        QueryPerformanceCounter(&t0);
        WCHAR value[256];
        getValue((WCHAR*)L"x.txt", 1, 0, value, sizeof(value), 0);
        QueryPerformanceCounter(&t1);
        printf("dictionary load: %.0f ms, +%.1f MB memory\n",
               (t1.QuadPart - t0.QuadPart) * 1000.0 / f.QuadPart, MemMB() - before);
    }
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
