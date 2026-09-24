#include <iostream>

#ifdef _WIN32
#include <windows.h>
#include <gdiplus.h>
#pragma comment (lib,"Gdiplus.lib")

// --- Error Codes ---
constexpr int E_SUCCESS = 0;
constexpr int E_PRINTER_UNAVAILABLE = -1;
constexpr int E_STARTDOC_FAILED = -2;
constexpr int E_STARTPAGE_FAILED = -3;
constexpr int E_ENDPAGE_FAILED = -4;
constexpr int E_ENDDOC_FAILED = -5;

// --- RAII Wrappers for Resource Management ---

// Manages GDI+ initialization and shutdown automatically.
class GdiplusManager {
public:
    GdiplusManager() {
        Gdiplus::GdiplusStartupInput gdiplusStartupInput;
        Gdiplus::GdiplusStartup(&token, &gdiplusStartupInput, nullptr);
    }
    ~GdiplusManager() {
        Gdiplus::GdiplusShutdown(token);
    }
private:
    ULONG_PTR token;
};

// Manages the lifetime of a device context (HDC).
class DeviceContextManager {
public:
    DeviceContextManager(const wchar_t* printerName) {
        hdc = CreateDCW(L"WINSPOOL", printerName, nullptr, nullptr);
    }
    ~DeviceContextManager() {
        if (hdc != nullptr) {
            DeleteDC(hdc);
        }
    }
    HDC get() const { return hdc; }
    operator HDC() const { return hdc; }
private:
    HDC hdc = nullptr;
};

// --- Rendering Logic ---

// Encapsulates the actual drawing logic.
// In a real implementation, this would parse a score data structure (e.g., from MusicXML).
void RenderScore(HDC hdc) {
    Gdiplus::Graphics graphics(hdc);
    Gdiplus::Pen pen(Gdiplus::Color(255, 0, 0, 0), 2); // 2px black pen

    // Get page dimensions in pixels (assuming 600 DPI for high quality)
    int pageWidthPx = GetDeviceCaps(hdc, HORZRES);
    int marginPx = 300; // 0.5 inch margin at 600 DPI

    // Draw 5 staff lines
    for (int i = 0; i < 5; ++i) {
        int y = marginPx + (i * 60); // 60px separation at 600 DPI
        graphics.DrawLine(&pen, marginPx, y, pageWidthPx - marginPx, y);
    }

    // Draw a simplified G-clef
    Gdiplus::FontFamily fontFamily(L"Arial");
    Gdiplus::Font font(&fontFamily, 48, Gdiplus::FontStyleRegular, Gdiplus::UnitPixel);
    Gdiplus::SolidBrush solidBrush(Gdiplus::Color(255, 0, 0, 0));
    Gdiplus::PointF pointF(static_cast<float>(marginPx) + 20.0f, static_cast<float>(marginPx) - 20.0f);
    graphics.DrawString(L"&", -1, &font, pointF, &solidBrush);
}

// --- FFI Exported Function ---

// Defines a C-style export to be called from Go/Electron (FFI).
// This function is now type-safe with wide characters and uses RAII for robust resource management.
extern "C" __declspec(dllexport) int KLIK_PrintVectorScore(const wchar_t* printerName, const wchar_t* scoreTitle) {
    GdiplusManager gdiplus; // RAII handles GDI+ startup/shutdown
    DeviceContextManager dc(printerName); // RAII handles device context creation/deletion

    if (dc.get() == nullptr) {
        std::cerr << "Error: Could not create device context for printer." << std::endl;
        return E_PRINTER_UNAVAILABLE;
    }

    DOCINFOW di = { sizeof(DOCINFOW) };
    di.lpszDocName = scoreTitle;

    if (StartDocW(dc, &di) <= 0) {
        std::cerr << "Error: StartDoc failed." << std::endl;
        return E_STARTDOC_FAILED;
    }

    if (StartPage(dc) <= 0) {
        std::cerr << "Error: StartPage failed." << std::endl;
        EndDoc(dc);
        return E_STARTPAGE_FAILED;
    }

    // Encapsulated rendering call
    RenderScore(dc.get());

    if (EndPage(dc) <= 0) {
        std::cerr << "Error: EndPage failed." << std::endl;
        EndDoc(dc);
        return E_ENDPAGE_FAILED;
    }

    if (EndDoc(dc) <= 0) {
        std::cerr << "Error: EndDoc failed." << std::endl;
        return E_ENDDOC_FAILED;
    }

    return E_SUCCESS; // Success
}
#endif // _WIN32