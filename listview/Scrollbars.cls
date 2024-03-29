VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Scrollbars"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements ISubclass

' ===========================================================================
' Name:     cScrollBars
' Author:   Steve McMahon (steve@vbaccelerator.com)
' Date:     24 December 1998
' Requires: SSUBTMR.DLL
'
' ---------------------------------------------------------------------------
' Copyright ® 1998 Steve McMahon (steve@vbaccelerator.com)
' Visit vbAccelerator - free, advanced source code for VB programmers.
'     http://vbaccelerator.com
' ---------------------------------------------------------------------------
'
' Description:
' A class which can add scroll bars to VB Forms, Picture Boxes and
' UserControls.
' Features:
'  * True API scroll bars, which don't flash or draw badly like the VB ones
'  * Scroll bar values are long integers, i.e. >2 billion values
'  * Set Flat or Encarta scroll bar modes if your COMCTL32.DLL version supports it (>4.72)
'
' Updates:
' 2003-07-02
'  * Added Mouse Wheel Support.  Thanks to Chris Eastwood for the suggestion and starter code.
'    Visit his site at http://vbcodelibrary.co.uk/
'  * Scroll bar now goes to bottom when SB_BOTTOM fired (e.g. right click on scroll bar with mouse)
'  * New ScrollClick events to enable focus
'  * Removed a large quantity of redundant declares which had found their way into this class somehow...
' ===========================================================================


' ---------------------------------------------------------------------
' vbAccelerator Software License
' Version 1.0
' Copyright (c) 2002 vbAccelerator.com
'
' Redistribution and use in source and binary forms, with or
' without modification, are permitted provided that the following
' conditions are met:
'
' 1. Redistributions of source code must retain the above copyright
'    notice, this list of conditions and the following disclaimer.
'
' 2. Redistributions in binary form must reproduce the above copyright
'    notice, this list of conditions and the following disclaimer in
'    the documentation and/or other materials provided with the distribution.
'
' 3. The end-user documentation included with the redistribution, if any,
'    must include the following acknowledgment:
'
'  "This product includes software developed by vbAccelerator (http://vbaccelerator.com/)."
'
' Alternately, this acknowledgment may appear in the software itself, if
' and wherever such third-party acknowledgments normally appear.
'
' 4. The name "vbAccelerator" must not be used to endorse or promote products
'    derived from this software without prior written permission. For written
'    permission, please contact vbAccelerator through steve@vbaccelerator.com.
'
' 5. Products derived from this software may not be called "vbAccelerator",
'    nor may "vbAccelerator" appear in their name, without prior written
'    permission of vbAccelerator.
'
' THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES,
' INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
' AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
' VBACCELERATOR OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
' INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
' BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
' USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
' THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
' (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
' THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
' ---------------------------------------------------------------------

Private Type OSVERSIONINFO
    dwOSVersionInfoSize                 As Long
    dwMajorVersion                      As Long
    dwMinorVersion                      As Long
    dwBuildNumber                       As Long
    dwPlatformId                        As Long
    szCSDVersion                        As String * 128
End Type

Private Declare Function GetVersionEx Lib "kernel32" Alias "GetVersionExA" (lpVersionInformation As OSVERSIONINFO) As Long
Private Declare Function RegisterWindowMessage Lib "user32" Alias "RegisterWindowMessageA" (ByVal lpString As String) As Long
Private Declare Function SystemParametersInfo Lib "user32" Alias "SystemParametersInfoA" (ByVal uAction As Long, ByVal uParam As Long, ByRef lpvParam As Long, ByVal fuWinIni As Long) As Long

Private Declare Function InitialiseFlatSB Lib "comctl32.dll" Alias "InitializeFlatSB" (ByVal lHWnd As Long) As Long

Private Type SCROLLINFO
    cbSize                              As Long
    fMask                               As Long
    nMin                                As Long
    nMax                                As Long
    nPage                               As Long
    nPos                                As Long
    nTrackPos                           As Long
End Type
Private Declare Function SetScrollInfo Lib "user32" (ByVal hwnd As Long, ByVal n As Long, lpcScrollInfo As SCROLLINFO, ByVal BOOL As Boolean) As Long
Private Declare Function GetScrollInfo Lib "user32" (ByVal hwnd As Long, ByVal n As Long, LPSCROLLINFO As SCROLLINFO) As Long
Private Declare Function GetScrollPos Lib "user32" (ByVal hwnd As Long, ByVal nBar As Long) As Long
Private Declare Function GetScrollRange Lib "user32" (ByVal hwnd As Long, ByVal nBar As Long, lpMinPos As Long, lpMaxPos As Long) As Long
Private Declare Function SetScrollPos Lib "user32" (ByVal hwnd As Long, ByVal nBar As Long, ByVal nPos As Long, ByVal bRedraw As Long) As Long
Private Declare Function SetScrollRange Lib "user32" (ByVal hwnd As Long, ByVal nBar As Long, ByVal nMinPos As Long, ByVal nMaxPos As Long, ByVal bRedraw As Long) As Long

 Private Const SB_BOTH                  As Long = 3
 Private Const SB_BOTTOM                As Long = 7
 Private Const SB_CTL                   As Long = 2
 Private Const SB_ENDSCROLL             As Long = 8
 Private Const SB_HORZ                  As Long = 0
 Private Const SB_LEFT                  As Long = 6
 Private Const SB_LINEDOWN              As Long = 1
 Private Const SB_LINELEFT              As Long = 0
 Private Const SB_LINERIGHT             As Long = 1
 Private Const SB_LINEUP                As Long = 0
 Private Const SB_PAGEDOWN              As Long = 3
 Private Const SB_PAGELEFT              As Long = 2
 Private Const SB_PAGERIGHT             As Long = 3
 Private Const SB_PAGEUP                As Long = 2
 Private Const SB_RIGHT                 As Long = 7
 Private Const SB_THUMBPOSITION         As Long = 4
 Private Const SB_THUMBTRACK            As Long = 5
 Private Const SB_TOP                   As Long = 6
 Private Const SB_VERT                  As Long = 1

 Private Const SIF_RANGE                As Long = &H1
 Private Const SIF_PAGE                 As Long = &H2
 Private Const SIF_POS                  As Long = &H4
 Private Const SIF_DISABLENOSCROLL      As Long = &H8
 Private Const SIF_TRACKPOS             As Long = &H10
 Private Const SIF_ALL                  As Long = (SIF_RANGE Or SIF_PAGE Or SIF_POS Or SIF_TRACKPOS)

Private Const ESB_DISABLE_BOTH          As Long = &H3
Private Const ESB_ENABLE_BOTH           As Long = &H0

Private Const SBS_SIZEGRIP              As Long = &H10&
   
Private Declare Function EnableScrollBar Lib "user32" (ByVal hwnd As Long, ByVal wSBflags As Long, ByVal wArrows As Long) As Long
Private Declare Function ShowScrollBar Lib "user32" (ByVal hwnd As Long, ByVal wBar As Long, ByVal bShow As Long) As Long

' Non-client messages:
Private Const WM_NCLBUTTONDOWN          As Long = &HA1
Private Const WM_NCRBUTTONDOWN          As Long = &HA4
Private Const WM_NCMBUTTONDOWN          As Long = &HA7

' Hit test codes for scroll bars:
Private Const HTHSCROLL                 As Long = 6
Private Const HTVSCROLL                 As Long = 7

' Scroll bar messages:
Private Const WM_VSCROLL                As Long = &H115
Private Const WM_HSCROLL                As Long = &H114
Private Const WM_MOUSEWHEEL             As Long = &H20A

' Mouse wheel stuff:
Private Const WHEEL_DELTA               As Long = 120
Private Const WHEEL_PAGESCROLL          As Long = -1
Private Const SPI_GETWHEELSCROLLLINES   As Long = &H68

' Old school Wheel Mouse is not supported in this class.
' NT3.51 or Win95 only
'// Class name for MSWHEEL.EXE's invisible window
'// use FindWindow to get hwnd to MSWHEEL
Private Const MSH_MOUSEWHEEL            As String = "MSWHEEL_ROLLMSG"
Private Const MSH_WHEELMODULE_CLASS     As String = "MouseZ"
Private Const MSH_WHEELMODULE_TITLE     As String = "Magellan MSWHEEL"
'// Apps need to call RegisterWindowMessage using the #defines
'// below to get the message numbers for:
'// 1) the message that can be sent to the MSWHEEL window to
'//    query if wheel support is active (MSH_WHEELSUPPORT)>
'// 2) the message to query for the number of scroll lines
'//    (MSH_SCROLL_LINES)
'//
'// To send a message to MSWheel window, use FindWindow with the #defines
'// for CLASS and TITLE above.  If FindWindow fails to find the MSWHEEL
'// window or the return from SendMessage is false, then Wheel support
'// is not currently available.
Private Const MSH_WHEELSUPPORT          As String = "MSH_WHEELSUPPORT_MSG"
Private Const MSH_SCROLL_LINES          As String = "MSH_SCROLL_LINES_MSG"

' Flat scroll bars:
Private Const WSB_PROP_CYVSCROLL        As Long = &H1&
Private Const WSB_PROP_CXHSCROLL        As Long = &H2&
Private Const WSB_PROP_CYHSCROLL        As Long = &H4&
Private Const WSB_PROP_CXVSCROLL        As Long = &H8&
Private Const WSB_PROP_CXHTHUMB         As Long = &H10&
Private Const WSB_PROP_CYVTHUMB         As Long = &H20&
Private Const WSB_PROP_VBKGCOLOR        As Long = &H40&
Private Const WSB_PROP_HBKGCOLOR        As Long = &H80&
Private Const WSB_PROP_VSTYLE           As Long = &H100&
Private Const WSB_PROP_HSTYLE           As Long = &H200&
Private Const WSB_PROP_WINSTYLE         As Long = &H400&
Private Const WSB_PROP_PALETTE          As Long = &H800&
Private Const WSB_PROP_MASK             As Long = &HFFF&

Private Const FSB_FLAT_MODE             As Long = 2&
Private Const FSB_ENCARTA_MODE          As Long = 1&
Private Const FSB_REGULAR_MODE          As Long = 0&

Private Declare Function FlatSB_EnableScrollBar Lib "comctl32.dll" (ByVal hwnd As Long, ByVal int2 As Long, ByVal UINT3 As Long) As Long
Private Declare Function FlatSB_ShowScrollBar Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, ByVal fRedraw As Boolean) As Long

Private Declare Function FlatSB_GetScrollRange Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, ByVal LPINT1 As Long, ByVal LPINT2 As Long) As Long
Private Declare Function FlatSB_GetScrollInfo Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, LPSCROLLINFO As SCROLLINFO) As Long
Private Declare Function FlatSB_GetScrollPos Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long) As Long
Private Declare Function FlatSB_GetScrollProp Lib "comctl32.dll" (ByVal hwnd As Long, ByVal propIndex As Long, ByVal LPINT As Long) As Long

Private Declare Function FlatSB_SetScrollPos Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, ByVal Pos As Long, ByVal fRedraw As Boolean) As Long
Private Declare Function FlatSB_SetScrollInfo Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, LPSCROLLINFO As SCROLLINFO, ByVal fRedraw As Boolean) As Long
Private Declare Function FlatSB_SetScrollRange Lib "comctl32.dll" (ByVal hwnd As Long, ByVal code As Long, ByVal Min As Long, ByVal Max As Long, ByVal fRedraw As Boolean) As Long
Private Declare Function FlatSB_SetScrollProp Lib "comctl32.dll" (ByVal hwnd As Long, ByVal Index As Long, ByVal NewValue As Long, ByVal fRedraw As Boolean) As Long

Private Declare Function InitializeFlatSB Lib "comctl32.dll" (ByVal hwnd As Long) As Long
Private Declare Function UninitializeFlatSB Lib "comctl32.dll" (ByVal hwnd As Long) As Long

' XP detection
Private Declare Function GetVersion Lib "kernel32" () As Long

' Initialisation state:
Private m_bInitialised      As Boolean

' Orientation
Public Enum EFSOrientationConstants
    efsoHorizontal
    efsoVertical
    efsoBoth
End Enum
Private m_eOrientation      As EFSOrientationConstants

' Style
Public Enum EFSStyleConstants
    efsRegular = FSB_REGULAR_MODE
    efsEncarta = FSB_ENCARTA_MODE
    efsFlat = FSB_FLAT_MODE
End Enum
Private m_eStyle            As EFSStyleConstants

' Bars:
Public Enum EFSScrollBarConstants
   efsHorizontal = SB_HORZ
   efsVertical = SB_VERT
End Enum

' Can we have flat scroll bars?
Private m_bNoFlatScrollBars As Boolean

' hWnd we're adding scroll bars too:
Private m_hWnd              As Long

' Small change amount
Private m_lSmallChangeHorz  As Long
Private m_lSmallChangeVert  As Long
' Enabled:
Private m_bEnabledHorz      As Boolean
Private m_bEnabledVert      As Boolean
' Visible
Private m_bVisibleHorz      As Boolean
Private m_bVisibleVert      As Boolean

' Number of lines to scroll for each wheel click:
Private m_lWheelScrollLines As Long

Private m_blnSubclassing    As Boolean

Private m_clsSubclass       As Subclasser

Public Event ScrollClick(eBar As EFSScrollBarConstants, eButton As MouseButtonConstants)
Public Event Scroll(eBar As EFSScrollBarConstants)
Public Event Change(eBar As EFSScrollBarConstants)
Public Event MouseWheel(eBar As EFSScrollBarConstants, lAmount As Long)

Public Property Get Visible(ByVal eBar As EFSScrollBarConstants) As Boolean
    If (eBar = efsHorizontal) Then
        Visible = m_bVisibleHorz
    Else
        Visible = m_bVisibleVert
    End If
End Property

Public Property Let Visible(ByVal eBar As EFSScrollBarConstants, ByVal bState As Boolean)
    If (eBar = efsHorizontal) Then
        m_bVisibleHorz = bState
    Else
        m_bVisibleVert = bState
    End If
    
    If (m_bNoFlatScrollBars) Then
        ShowScrollBar m_hWnd, eBar, Abs(bState)
    Else
        FlatSB_ShowScrollBar m_hWnd, eBar, Abs(bState)
    End If
End Property

Public Property Get Orientation() As EFSOrientationConstants
    Orientation = m_eOrientation
End Property

Public Property Let Orientation(ByVal eOrientation As EFSOrientationConstants)
    m_eOrientation = eOrientation
    pSetOrientation
End Property

Private Sub pSetOrientation()
    ShowScrollBar m_hWnd, SB_HORZ, Abs((m_eOrientation = efsoBoth) Or (m_eOrientation = efsoHorizontal))
    ShowScrollBar m_hWnd, SB_VERT, Abs((m_eOrientation = efsoBoth) Or (m_eOrientation = efsoVertical))
End Sub

Private Sub pGetSI(ByVal eBar As EFSScrollBarConstants, ByRef tSI As SCROLLINFO, ByVal fMask As Long)
    Dim lO As Long
    
    lO = eBar
    tSI.fMask = fMask
    tSI.cbSize = LenB(tSI)
    
    If (m_bNoFlatScrollBars) Then
        GetScrollInfo m_hWnd, lO, tSI
    Else
        FlatSB_GetScrollInfo m_hWnd, lO, tSI
    End If
End Sub
Private Sub pLetSI(ByVal eBar As EFSScrollBarConstants, ByRef tSI As SCROLLINFO, ByVal fMask As Long)
    Dim lO As Long
        
    lO = eBar
    tSI.fMask = fMask
    tSI.cbSize = LenB(tSI)
    
    If (m_bNoFlatScrollBars) Then
        SetScrollInfo m_hWnd, lO, tSI, True
    Else
        FlatSB_SetScrollInfo m_hWnd, lO, tSI, True
    End If
End Sub

Public Property Get Style() As EFSStyleConstants
    Style = m_eStyle
End Property

Public Property Let Style(ByVal eStyle As EFSStyleConstants)
    Dim lR As Long
    
    If (eStyle <> efsRegular) Then
        If (m_bNoFlatScrollBars) Then
            ' can't do it..
            'debugmsg "Can't set non-regular style mode on this system - XP or COMCTL32.DLL version < 4.71."
            Exit Property
        End If
    End If
    
    If (m_eOrientation = efsoHorizontal) Or (m_eOrientation = efsoBoth) Then
        lR = FlatSB_SetScrollProp(m_hWnd, WSB_PROP_HSTYLE, eStyle, True)
    End If
    
    If (m_eOrientation = efsoVertical) Or (m_eOrientation = efsoBoth) Then
        lR = FlatSB_SetScrollProp(m_hWnd, WSB_PROP_VSTYLE, eStyle, True)
    End If
    
    m_eStyle = eStyle
End Property

Public Property Get SmallChange(ByVal eBar As EFSScrollBarConstants) As Long
    If (eBar = efsHorizontal) Then
        SmallChange = m_lSmallChangeHorz
    Else
        SmallChange = m_lSmallChangeVert
    End If
End Property

Public Property Let SmallChange(ByVal eBar As EFSScrollBarConstants, ByVal lSmallChange As Long)
    If (eBar = efsHorizontal) Then
        m_lSmallChangeHorz = lSmallChange
    Else
        m_lSmallChangeVert = lSmallChange
    End If
End Property

Public Property Get Enabled(ByVal eBar As EFSScrollBarConstants) As Boolean
    If (eBar = efsHorizontal) Then
        Enabled = m_bEnabledHorz
    Else
        Enabled = m_bEnabledVert
    End If
End Property

Public Property Let Enabled(ByVal eBar As EFSScrollBarConstants, ByVal bEnabled As Boolean)
    Dim lO As Long
    Dim lF As Long
        
    lO = eBar
    
    If eBar = efsVertical Then
        m_bEnabledVert = bEnabled
    Else
        m_bEnabledHorz = bEnabled
    End If
    
    If (bEnabled) Then
        lF = ESB_ENABLE_BOTH
    Else
        lF = ESB_DISABLE_BOTH
    End If
    
    If (m_bNoFlatScrollBars) Then
        EnableScrollBar m_hWnd, lO, lF
    Else
        FlatSB_EnableScrollBar m_hWnd, lO, lF
    End If
End Property

Public Property Get Min(ByVal eBar As EFSScrollBarConstants) As Long
    Dim tSI As SCROLLINFO
    
    pGetSI eBar, tSI, SIF_RANGE
    Min = tSI.nMin
End Property

Public Property Get Max(ByVal eBar As EFSScrollBarConstants) As Long
    Dim tSI As SCROLLINFO
    
    pGetSI eBar, tSI, SIF_RANGE Or SIF_PAGE
    Max = tSI.nMax - tSI.nPage
End Property

Public Property Get Value(ByVal eBar As EFSScrollBarConstants) As Long
    Dim tSI As SCROLLINFO

    pGetSI eBar, tSI, SIF_POS
    Value = tSI.nPos
End Property

Public Property Get LargeChange(ByVal eBar As EFSScrollBarConstants) As Long
    Dim tSI As SCROLLINFO
    
    pGetSI eBar, tSI, SIF_PAGE
    LargeChange = tSI.nPage
End Property

Public Property Let Min(ByVal eBar As EFSScrollBarConstants, ByVal iMin As Long)
    Dim tSI As SCROLLINFO
    
    tSI.nMin = iMin
    tSI.nMax = Max(eBar) + LargeChange(eBar)
    pLetSI eBar, tSI, SIF_RANGE
End Property

Public Property Let Max(ByVal eBar As EFSScrollBarConstants, ByVal iMax As Long)
    Dim tSI As SCROLLINFO
    
    tSI.nMax = iMax + LargeChange(eBar)
    tSI.nMin = Min(eBar)
    pLetSI eBar, tSI, SIF_RANGE
    pRaiseEvent eBar, False
End Property

Public Property Let Value(ByVal eBar As EFSScrollBarConstants, ByVal iValue As Long)
    Dim tSI As SCROLLINFO
    
    If (iValue <> Value(eBar)) Then
        tSI.nPos = iValue
        pLetSI eBar, tSI, SIF_POS
        pRaiseEvent eBar, False
    End If
End Property

Public Property Let LargeChange(ByVal eBar As EFSScrollBarConstants, ByVal iLargeChange As Long)
    Dim tSI             As SCROLLINFO
    Dim lCurMax         As Long
    Dim lCurLargeChange As Long
    
    pGetSI eBar, tSI, SIF_ALL
    tSI.nMax = tSI.nMax - tSI.nPage + iLargeChange
    tSI.nPage = iLargeChange
    pLetSI eBar, tSI, SIF_PAGE Or SIF_RANGE
End Property

Public Property Get CanBeFlat() As Boolean
    CanBeFlat = Not (m_bNoFlatScrollBars)
End Property

Private Sub pCreateScrollBar()
    Dim lR      As Long
    Dim lStyle  As Long
    Dim hParent As Long
    Dim lMajor  As Long
    Dim lMinor  As Long
    Dim isXp    As Boolean

    ' Added 2003-11-26: Check for XP and above and
    ' don't use Flat Scroll bars.  They're useless
    ' under XP.
    GetWindowsVersion lMajor, lMinor
    If (lMajor > 5) Then
        isXp = True
    ElseIf (lMajor = 5) And (lMinor >= 1) Then
        isXp = True
    End If
   
    If isXp Then
        m_bNoFlatScrollBars = True
    Else
        ' Just checks for flag scroll bars...
        On Error Resume Next
        lR = InitialiseFlatSB(m_hWnd)
        If (Err.Number <> 0) Then
            'Can't find DLL entry point InitializeFlatSB in COMCTL32.DLL
            ' Means we have version prior to 4.71
            ' We get standard scroll bars.
            m_bNoFlatScrollBars = True
        Else
            Style = m_eStyle
        End If
    End If
End Sub

Private Sub GetWindowsVersion( _
    Optional ByRef lMajor = 0, _
    Optional ByRef lMinor = 0, _
    Optional ByRef lRevision = 0, _
    Optional ByRef lBuildNumber = 0 _
)

    Dim lR As Long
    
    lR = GetVersion()
    lBuildNumber = (lR And &H7F000000) \ &H1000000
    If (lR And &H80000000) Then lBuildNumber = lBuildNumber Or &H80
    lRevision = (lR And &HFF0000) \ &H10000
    lMinor = (lR And &HFF00&) \ &H100
    lMajor = (lR And &HFF)
End Sub

Public Sub Terminate()
    pClearUp
End Sub

Public Sub Create(ByVal hWndA As Long)
    If (hWndA <> 0) And (Not m_blnSubclassing) Then
        pClearUp
        m_hWnd = hWndA
        pCreateScrollBar
        pAttachMessages
    End If
End Sub

Private Sub pClearUp()
    If m_hWnd <> 0 Then
        On Error Resume Next
        ' Stop flat scroll bar if we have it:
        If Not (m_bNoFlatScrollBars) Then
            UninitializeFlatSB m_hWnd
        End If
        
        On Error GoTo 0
        ' Remove subclass:
        If m_blnSubclassing Then
            m_clsSubclass.UnSubclass m_hWnd
            m_blnSubclassing = False
        End If
    End If
    
    m_hWnd = 0
    m_bInitialised = False
End Sub

Private Sub pAttachMessages()
    If m_clsSubclass.Subclass(m_hWnd, Me) Then
        m_blnSubclassing = True
        
        m_clsSubclass.AddMsg m_hWnd, WM_HSCROLL
        m_clsSubclass.AddMsg m_hWnd, WM_VSCROLL
        m_clsSubclass.AddMsg m_hWnd, WM_MOUSEWHEEL
        m_clsSubclass.AddMsg m_hWnd, WM_NCLBUTTONDOWN
        m_clsSubclass.AddMsg m_hWnd, WM_NCMBUTTONDOWN
        m_clsSubclass.AddMsg m_hWnd, WM_NCRBUTTONDOWN
        
        SystemParametersInfo SPI_GETWHEELSCROLLLINES, 0, m_lWheelScrollLines, 0
        If (m_lWheelScrollLines <= 0) Then m_lWheelScrollLines = 3
        m_bInitialised = True
    End If
End Sub

Private Sub Class_Initialize()
    m_lSmallChangeHorz = 1
    m_lSmallChangeVert = 1
    m_eStyle = efsRegular
    m_eOrientation = efsoBoth
    
    Set m_clsSubclass = New Subclasser
End Sub

Private Sub ISubclass_WndProc( _
    ByVal bBefore As Boolean, _
    bHandled As Boolean, _
    lReturn As Long, _
    ByVal lng_hWnd As Long, _
    ByVal uMsg As eMsg, _
    ByVal wParam As Long, _
    ByVal lParam As Long, _
    lParamUser As Long _
)

    Dim lScrollCode     As Long
    Dim tSI             As SCROLLINFO
    Dim lV              As Long
    Dim lSC             As Long
    Dim eBar            As EFSScrollBarConstants
    Dim zDelta          As Long
    Dim lDelta          As Long
    Dim wMKeyFlags      As Long

    Select Case uMsg
        Case WM_MOUSEWHEEL
            ' Low-word of wParam indicates whether virtual keys are down
            wMKeyFlags = wParam And &HFFFF&
            
            ' High order word is the distance the wheel has been rotated,
            ' in multiples of WHEEL_DELTA:
            If (wParam And &H8000000) Then
                ' Towards the user:
                zDelta = &H8000& - (wParam And &H7FFF0000) \ &H10000
            Else
                ' Away from the user:
                zDelta = -((wParam And &H7FFF0000) \ &H10000)
            End If
            
            lDelta = (zDelta \ WHEEL_DELTA) * SmallChange(efsVertical) * m_lWheelScrollLines
            eBar = efsVertical
            RaiseEvent MouseWheel(eBar, lDelta)
            
            If Not (lDelta = 0) Then
                If (Visible(eBar) And Enabled(eBar)) Then
                    Value(eBar) = Value(eBar) + lDelta
                    lReturn = 1
                    bHandled = True
                End If
            End If
   
        Case WM_VSCROLL, WM_HSCROLL
            If (uMsg = WM_HSCROLL) Then
                eBar = efsHorizontal
            Else
                eBar = efsVertical
            End If
            
            lScrollCode = (wParam And &HFFFF&)
            
            Select Case lScrollCode
                Case SB_THUMBTRACK
                    ' Is vertical/horizontal?
                    pGetSI eBar, tSI, SIF_TRACKPOS
                    Value(eBar) = tSI.nTrackPos
                    pRaiseEvent eBar, True
         
                Case SB_LEFT, SB_TOP
                    Value(eBar) = Min(eBar)
                    pRaiseEvent eBar, False
         
                Case SB_RIGHT, SB_BOTTOM
                    Value(eBar) = Max(eBar)
                    pRaiseEvent eBar, False
          
                Case SB_LINELEFT, SB_LINEUP
                    lV = Value(eBar)
                    If (eBar = efsHorizontal) Then
                        lSC = m_lSmallChangeHorz
                    Else
                        lSC = m_lSmallChangeVert
                    End If
                    If (lV - lSC < Min(eBar)) Then
                        Value(eBar) = Min(eBar)
                    Else
                        Value(eBar) = lV - lSC
                    End If
                    pRaiseEvent eBar, False
         
                Case SB_LINERIGHT, SB_LINEDOWN
                    lV = Value(eBar)
                    If (eBar = efsHorizontal) Then
                        lSC = m_lSmallChangeHorz
                    Else
                        lSC = m_lSmallChangeVert
                    End If
                    If (lV + lSC > Max(eBar) + 1) Then
                        Value(eBar) = Max(eBar) + 1
                    Else
                        Value(eBar) = lV + lSC
                    End If
                    pRaiseEvent eBar, False
          
                Case SB_PAGELEFT, SB_PAGEUP
                    Value(eBar) = Value(eBar) - LargeChange(eBar)
                    pRaiseEvent eBar, False
         
                Case SB_PAGERIGHT, SB_PAGEDOWN
                    Value(eBar) = Value(eBar) + LargeChange(eBar)
                    pRaiseEvent eBar, False
         
                Case SB_ENDSCROLL
                    pRaiseEvent eBar, False
         
            End Select
      
        Case WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN
            Dim eBtn As MouseButtonConstants
            eBtn = IIf(uMsg = WM_NCLBUTTONDOWN, vbLeftButton, vbRightButton)
            If wParam = HTVSCROLL Then
                RaiseEvent ScrollClick(efsHorizontal, eBtn)
            ElseIf wParam = HTHSCROLL Then
                RaiseEvent ScrollClick(efsVertical, eBtn)
            End If
       
    End Select
End Sub

Private Function pRaiseEvent(ByVal eBar As EFSScrollBarConstants, ByVal bScroll As Boolean)
    Static s_lLastValue(0 To 1) As Long
    
    If (Value(eBar) <> s_lLastValue(eBar)) Then
        If (bScroll) Then
            RaiseEvent Scroll(eBar)
        Else
            RaiseEvent Change(eBar)
        End If
        s_lLastValue(eBar) = Value(eBar)
    End If
End Function
