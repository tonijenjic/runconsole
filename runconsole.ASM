
FORMAT PE GUI 5.0
ENTRY START

INCLUDE '\FASM\INCLUDE\WIN32AX.INC'

SECTION '.DATA' DATA READABLE WRITABLE

TEXTBOX_ID = 12
BUTTON_ID = 13
CLEARTYPE_QUALITY = 5
IDR_APPICON = 72

 align 4
 dwInstanceHandle dd ?
 dwTextBoxHandle dd ?
 dwWindowHandle dd ?
 dwButtonHandle dd ?
 dwFontHandle dd ?
 dwBackgroundColor dd ?
 dwWindowXPosition dd ?
 dwWindowYPosition dd ?
 dwOldEditboxProcedure dd ?
 dwOldButtonProcedure dd ?
 _szAppTitle db 'Run Console App', 0
 _szFilter db '*.exe', 0, 0
 _szHomePathEnvironmentVar db 'HomePath', 0
 _szConsoleError db 'Unable to run Windows ''cmd.exe''', 0
 _szUnableToRunApp db 'Unable to run the specified app', 0
 _szRunDiffAppQ db 'Press yes to run the same app. To run a different app, press no, press cancel to close.', 0
 _szUnableToCreateWindow db 'Unable to create Win32 window', 0
 _szParameters db 'If you need to specify command line arguments and parameters, simply specify them below', 0
 _szProcedeButton db 'Proceed', 0
 _szErrorTitle db 'Win32 error', 0
 _szEditClass db 'EDIT', 0
 _szButtonClass db 'BUTTON', 0
 _szWndClass db 'ClassProcedure', 0
 _szWndTitle db 'Command Arguments and Parameters', 0
 _szTextFont db 'Arial', 0
 _szCommandSyntax db '%s %s', 0
 _szHomePath db 128 dup (0)
 _szStringBuffer db 256 dup (0)
 _szExecutableFile db 256 dup (0)
 _szResultingCommand db 512 dup (0)
 align 8
 wc WNDCLASS 0, WINDOWPROC, 0, 0, NULL, NULL, NULL, COLOR_BACKGROUND OR 1, NULL, _szWndClass
 executableFile OPENFILENAME sizeof.OPENFILENAME, NULL, NULL, _szFilter, NULL, 0, 1, _szExecutableFile, 256, NULL, NULL, _szHomePath, _szAppTitle,\
                OFN_FILEMUSTEXIST OR OFN_NOLONGNAMES, 0, 0, NULL, NULL, NULL
 msg MSG
 ps PAINTSTRUCT
 textRect RECT 10, 10, 330, 50

SECTION '.CODE' DATA READABLE EXECUTABLE

EDITBOX_PROC:
 mov eax, [esp+8]
 mov ebx, [esp+12]
 mov ecx, [esp+16]
 cmp eax, WM_CHAR
 jz EDITBOX_CHAR
EDITBOX_GETDLGCODE:
 invoke CallWindowProcA, [dwOldEditboxProcedure], [dwTextBoxHandle], eax, ebx, ecx
 ret
EDITBOX_CHAR:
 cmp ebx, 0DH
 jz GENERATE_COMMAND
 cmp ebx, 09H
 jz SET_BUTTON_FOCUS
 jmp EDITBOX_GETDLGCODE
SET_BUTTON_FOCUS:
 invoke SetFocus, [dwButtonHandle]
 xor eax, eax
 ret

PROCEED_BUTTON_PROC:
 mov eax, [esp+8]
 mov ebx, [esp+12]
 mov ecx, [esp+16]
 cmp eax, WM_KEYUP
 jz CHECK_RELEASED_KEY
INVOKE_DEF_BUTTON:
 invoke CallWindowProcA, [dwOldButtonProcedure], [dwButtonHandle], eax, ebx, ecx
 ret
CHECK_RELEASED_KEY:
 cmp ebx, 0DH
 jnz INVOKE_DEF_BUTTON
 invoke PostMessageA, [dwButtonHandle], BM_CLICK, 0, 0
 jmp INVOKE_DEF_BUTTON

WINDOWPROC:
 mov eax, [esp+8]
 cmp eax, WM_DESTROY
 jz DESTROY_WINDOW
 cmp eax, WM_PAINT
 jz PAINT_WINDOW
 cmp eax, WM_COMMAND
 jz WIN_CTRL_EVENTS
 cmp eax, WM_QUIT
 jz QUITTING_WINDOW
 mov eax, [esp+4]
 mov ebx, [esp+8]
 mov ecx, [esp+12]
 mov edx, [esp+16]
 invoke DefWindowProcA, eax, ebx, ecx, edx
 ret
PAINT_WINDOW:
 invoke BeginPaint, [dwWindowHandle], ps
 mov ebx, eax
 invoke SelectObject, eax, [dwFontHandle]
 mov esi, eax
 invoke SetBkMode, ebx, TRANSPARENT
 invoke strlen, _szParameters
 add esp, 4
 invoke DrawTextA, ebx, _szParameters, eax, textRect, DT_LEFT OR DT_TOP OR DT_WORDBREAK
 invoke SelectObject, ebx, esi
 invoke EndPaint, [dwWindowHandle], ps
 ret
WIN_CTRL_EVENTS:
 mov eax, [esp+12]
 cmp ax, BUTTON_ID
 setz cl
 shr eax, 16
 cmp ax, BN_CLICKED
 setz ch
 mov eax, [esp+16]
 cmp eax, [dwButtonHandle]
 setz dl
 and cl, ch
 and cl, dl
 jz END_CTRL_EVENTS
GENERATE_COMMAND:
 invoke GetWindowTextA, [dwTextBoxHandle], _szStringBuffer, 256
 invoke sprintf, _szResultingCommand, _szCommandSyntax, _szExecutableFile, _szStringBuffer
 invoke DestroyWindow, [dwWindowHandle]
 add esp, 16
END_CTRL_EVENTS:
 ret
DESTROY_WINDOW:
 invoke PostQuitMessage, 0
 xor eax, eax
 ret
QUITTING_WINDOW:
 invoke strcpy, _szResultingCommand, _szStringBuffer
 add esp, 8
 ret

ANY_PARAMETERS_REQUIRED:
 invoke RegisterClassA, wc
 test eax, eax
 jz UNABLE_TO_CREATE_WINDOW_ERROR
 invoke CreateWindowExA, 0, _szWndClass, _szWndTitle, WS_VISIBLE OR WS_DLGFRAME OR WS_SYSMENU or WS_THICKFRAME,\
        [dwWindowXPosition], [dwWindowYPosition], 356, 162, [executableFile.hwndOwner], NULL, [wc.hInstance], NULL
 test eax, eax
 jz UNABLE_TO_CREATE_WINDOW_ERROR
 mov ebx, eax
 mov [dwWindowHandle], eax
 invoke CreateWindowExA, 0, _szEditClass, NULL, 50000000H OR ES_AUTOHSCROLL, 10, 95, 250, 20, eax, TEXTBOX_ID, [wc.hInstance], NULL
 mov [dwTextBoxHandle], eax
 invoke CreateWindowExA, 0, _szButtonClass, _szProcedeButton, WS_VISIBLE OR WS_CHILD OR BS_DEFPUSHBUTTON,\
        275, 95, 60, 20, ebx, BUTTON_ID, [wc.hInstance], NULL
 mov [dwButtonHandle], eax
 invoke SendMessageA, eax, WM_SETFONT, [dwFontHandle], FALSE
 invoke SetWindowTextA, [dwTextBoxHandle], _szStringBuffer
 invoke SendMessageA, [dwTextBoxHandle], WM_SETFONT, [dwFontHandle], TRUE
 invoke SetWindowLongA, [dwTextBoxHandle], GWL_WNDPROC, EDITBOX_PROC
 mov [dwOldEditboxProcedure], eax
 invoke SetWindowLongA, [dwButtonHandle], GWL_WNDPROC, PROCEED_BUTTON_PROC
 mov [dwOldButtonProcedure], eax
 invoke strlen, _szStringBuffer
 add esp, 4
 invoke SendMessageA, [dwTextBoxHandle], EM_SETSEL, eax, eax
 invoke SetFocus, [dwTextBoxHandle]
MSG_LOOP:
 invoke GetMessageA, msg, NULL, 0, 0
 cmp eax, 1
 jb EXIT_PROC
 jne MSG_LOOP
 invoke TranslateMessage, msg
 invoke DispatchMessageA, msg
 jmp MSG_LOOP
EXIT_PROC:
 ret

START:
 invoke GetModuleHandle, NULL
 mov [dwInstanceHandle], eax
 mov [executableFile.hInstance], eax
 mov [wc.hInstance], eax
 invoke LoadCursorA, 0, IDC_ARROW
 mov [wc.hCursor], eax
 invoke LoadIconA, 0, IDI_APPLICATION
 mov [wc.hIcon], eax
 invoke CreateFontA, 16, 0, 0, 0, 0, 0, 0, 0, OEM_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,\
        FF_DONTCARE, _szTextFont
 mov [dwFontHandle], eax
 invoke GetSystemMetrics, SM_CXSCREEN
 sar eax, 1
 sub eax, 356 / 2
 mov [dwWindowXPosition], eax
 invoke GetSystemMetrics, SM_CYSCREEN
 sar eax, 1
 sub eax, 162 / 2
 mov [dwWindowYPosition], eax
 call [AllocConsole]
 test eax, eax
 jz CONSOLE_ERROR
 invoke GetEnvironmentVariableA, _szHomePathEnvironmentVar, _szHomePath, 128
 invoke GetConsoleTitleA, _szStringBuffer, 256
 invoke FindWindowA, NULL, _szStringBuffer
 mov [executableFile.hwndOwner], eax
 xor eax, eax
 mov edi, _szStringBuffer
 mov ecx, 64
 rep stosd
RUN_CONSOLE_APP:
 invoke GetOpenFileNameA, executableFile
 test eax, eax
 jz EXIT_APP
RUN_SAME_APP:
 call ANY_PARAMETERS_REQUIRED
 invoke system, _szResultingCommand
 add esp, 4
 test eax, eax
 js UNABLE_TO_RUN_APP
 invoke MessageBoxA, [executableFile.hwndOwner], _szRunDiffAppQ, _szAppTitle, MB_YESNOCANCEL OR MB_ICONQUESTION
 cmp eax, IDYES
 jz RUN_SAME_APP
 cmp eax, IDNO
 jz RUN_CONSOLE_APP
EXIT_APP:
 invoke DeleteObject, [dwFontHandle]
 call [FreeConsole]
 invoke ExitProcess, 0
CONSOLE_ERROR:
 invoke MessageBoxA, [executableFile.hwndOwner], _szConsoleError, _szErrorTitle, MB_OK OR MB_ICONERROR
 jmp EXIT_APP
UNABLE_TO_RUN_APP:
 invoke MessageBoxA, [executableFile.hwndOwner], _szUnableToRunApp, _szErrorTitle, MB_OK OR MB_ICONERROR
 jmp EXIT_APP

UNABLE_TO_CREATE_WINDOW_ERROR:
 invoke MessageBoxA, [executableFile.hwndOwner], _szUnableToCreateWindow, _szErrorTitle, MB_OK OR MB_ICONERROR
 invoke DeleteObject, [dwFontHandle]
 call [FreeConsole]
 add esp, 4
 invoke ExitProcess, 0

SECTION '.IDATA' DATA IMPORT READABLE

 library KERNEL32,'kernel32.dll',\
         COMDLG32,'comdlg32.dll',\
         USER32,'user32.dll',\
         MSVCRT,'msvcrt.dll',\
         GDI32,'gdi32.dll'

 import KERNEL32,\
        AllocConsole,'AllocConsole',\
        FreeConsole,'FreeConsole',\
        CreateProcessA,'CreateProcessA',\
        GetEnvironmentVariableA,'GetEnvironmentVariableA',\
        GetCurrentThread,'GetCurrentThread',\
        GetModuleHandle,'GetModuleHandleA',\
        CloseHandle,'CloseHandle',\
        ExitProcess,'ExitProcess',\
        GetConsoleTitleA,'GetConsoleTitleA'

 import COMDLG32,\
        GetOpenFileNameA,'GetOpenFileNameA'

 import USER32,\
        MessageBoxA,'MessageBoxA',\
        RegisterClassA,'RegisterClassA',\
        CreateWindowExA,'CreateWindowExA',\
        GetMessageA,'GetMessageA',\
        TranslateMessage,'TranslateMessage',\
        DispatchMessageA,'DispatchMessageA',\
        LoadIconA,'LoadIconA',\
        LoadCursorA,'LoadCursorA',\
        DefWindowProcA,'DefWindowProcA',\
        PostQuitMessage,'PostQuitMessage',\
        SendMessageA,'SendMessageA',\
        BeginPaint,'BeginPaint',\
        EndPaint,'EndPaint',\
        DrawTextA,'DrawTextA',\
        GetWindowTextA,'GetWindowTextA',\
        SetWindowTextA,'SetWindowTextA',\
        DestroyWindow,'DestroyWindow',\
        GetSystemMetrics,'GetSystemMetrics',\
        FindWindowA,'FindWindowA',\
        SetWindowLongA,'SetWindowLongA',\
        CallWindowProcA,'CallWindowProcA',\
        SetFocus,'SetFocus',\
        PostMessageA,'PostMessageA',\
        ShowWindow,'ShowWindow'

 import MSVCRT,\
        system,'system',\
        strlen,'strlen',\
        sprintf,'sprintf',\
        strcpy,'strcpy'

 import GDI32,\
        SelectObject,'SelectObject',\
        DeleteObject,'DeleteObject',\
        CreateFontA,'CreateFontA',\
        SetBkMode,'SetBkMode'


SECTION '.RSRC' RESOURCE DATA READABLE

 directory RT_ICON,icons,\
           RT_GROUP_ICON,group_icons

 resource icons,\
          1,LANG_NEUTRAL,main_icon

 resource group_icons,\
          IDR_APPICON,LANG_NEUTRAL,icon1

 icon icon1,main_icon,'runc_icon2.ico'
