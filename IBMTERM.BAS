'==============================================================
'  IBM SERIAL TERMINAL (QuickBASIC 4.0)
'  04/05/2026 by aimutt.com
'
'  Description:
'  ------------
'  This program implements a simple text-based terminal interface
'  designed for communication between two IBM PCs (e.g., 5150/5160)
'  or between an IBM PC and a Raspberry Pi connected to the COM1
'  serial port.
'
'  The interface mimics a structured terminal layout with:
'    - A fixed menu bar at the top
'    - A scrolling message window (viewport) in the center
'    - A fixed status display showing COM port settings
'    - A command/help line at the bottom
'
'  Messages sent and received over the serial port are displayed
'  in the scrolling viewport using the AddLine SUB.
'
'  Controls:
'    ESC  - Exit program
'    Enter - Send the currently typed message
'
'
'  Screen Layout (80x25 text mode):
'  --------------------------------
'
'    Row 1        -> Menu (fixed)
'    Row 2        -> Top border
'    Row 3-21     -> Scrolling text viewport  <- AddLine writes here
'    Row 22       -> Bottom border
'    Row 23-24    -> Status area (COM settings + connection status)
'    Row 25       -> Command/help prompt
'
'
'  VIEW PRINT Usage:
'  -----------------
'    VIEW PRINT 3 TO 21 is used to define the scrolling region.
'
'    - AddLine SUB:
'        Writes ONLY inside the viewport (rows 3-21)
'        Causes scrolling within this region only
'
'    - DrawScreen / UpdateStatus / DrawPrompt:
'        Temporarily use VIEW PRINT 1 TO 25
'        to update fixed UI elements outside the viewport
'
'
'  Serial Port:
'  ------------
'    COM1 is opened using parameters:
'      Baud     = 1200
'      Parity   = N
'      DataBits = 8
'      StopBits = 1
'
'    Hardware handshaking signals are disabled with:
'      CS0,DS0,CD0
'
'    This is important when using null modem cables and USB serial
'    adapters that do not provide full modem-control signaling.
'
'
'  Receive Logic:
'  --------------
'    Incoming serial data is read character-by-character using
'    INPUT$(LOC(1), #1) instead of LINE INPUT #1.
'
'    This prevents the program from blocking while waiting for a
'    complete line terminator and allows the XT keyboard to remain
'    responsive after messages are received from a Raspberry Pi.
'
'==============================================================

DECLARE SUB DrawScreen ()
DECLARE SUB AddLine (Msg$)
DECLARE SUB UpdateStatus (Msg$)
DECLARE SUB DrawPrompt (InputLine$)
DECLARE FUNCTION Stamp$ ()
DECLARE FUNCTION MakeTagged$ (Tag$, Msg$)

CLS

CONST MENUROW = 1
CONST TOPBORDER = 2
CONST VIEWTOP = 3
CONST VIEWBOTTOM = 21
CONST BOTTOMBORDER = 22
CONST STATUSROW1 = 23
CONST STATUSROW2 = 24
CONST PROMPTROW = 25

DIM SHARED PortName$
DIM SHARED Baud$
DIM SHARED Parity$
DIM SHARED DataBits$
DIM SHARED StopBits$
DIM SHARED PortOpen%
DIM SHARED OpenSpec$
DIM SHARED InPortOpen%
DIM SHARED RxBuffer$

DIM InputLine$
DIM Msg$
DIM k$
DIM OutMsg$
DIM raw$
DIM ch$
DIM chars%
DIM i%

PortName$ = "COM1"
Baud$ = "1200"
Parity$ = "N"
DataBits$ = "8"
StopBits$ = "1"

PortOpen% = 0
InPortOpen% = 0
RxBuffer$ = ""

OpenSpec$ = PortName$ + ":" + Baud$ + "," + Parity$ + "," + DataBits$ + "," + StopBits$ + ",CS0,DS0,CD0"

ON ERROR GOTO ErrorHandler

COLOR 2, 0
CLS

CALL DrawScreen
CALL UpdateStatus("Opening " + PortName$ + "...")

InPortOpen% = -1
OPEN OpenSpec$ FOR RANDOM AS #1 LEN = 1
InPortOpen% = 0

PortOpen% = -1
CALL UpdateStatus("Connected / Ready")
CALL AddLine(MakeTagged$("SYS", PortName$ + " opened successfully."))
CALL AddLine(MakeTagged$("SYS", "Terminal started."))
CALL AddLine(MakeTagged$("SYS", "Waiting for data on " + PortName$ + "..."))
CALL AddLine(MakeTagged$("SYS", "Type a message and press Enter to send."))
CALL AddLine(MakeTagged$("SYS", "Press ESC to quit."))

InputLine$ = ""
CALL DrawPrompt(InputLine$)

DO
    k$ = INKEY$

    IF k$ <> "" THEN

        IF k$ = CHR$(27) THEN
            CALL UpdateStatus("Exiting...")
            EXIT DO
        END IF

        IF k$ = CHR$(0) THEN
            dummy$ = INKEY$

            ' ALT+Q
            IF dummy$ = CHR$(16) THEN
                CALL UpdateStatus("Exiting...")
                EXIT DO
            END IF

        ELSEIF k$ = CHR$(13) THEN
            ' Enter sends current input line
            IF LEN(InputLine$) > 0 THEN
                IF PortOpen% THEN
                    OutMsg$ = InputLine$
                    PRINT #1, OutMsg$
                    CALL AddLine(MakeTagged$("TX", OutMsg$))
                    CALL UpdateStatus("Transmit OK")
                ELSE
                    CALL AddLine(MakeTagged$("ERR", PortName$ + " is not open."))
                    CALL UpdateStatus("Not connected")
                END IF
            END IF

            InputLine$ = ""
            CALL DrawPrompt(InputLine$)

        ELSEIF k$ = CHR$(8) THEN
            ' Backspace
            IF LEN(InputLine$) > 0 THEN
                InputLine$ = LEFT$(InputLine$, LEN(InputLine$) - 1)
                CALL DrawPrompt(InputLine$)
            END IF

        ELSEIF ASC(k$) >= 32 AND ASC(k$) <= 126 THEN
            ' Printable characters only
            IF LEN(InputLine$) < 67 THEN
                InputLine$ = InputLine$ + k$
                CALL DrawPrompt(InputLine$)
            END IF
        END IF
    END IF

    ' Check for incoming serial data (non-blocking, character-by-character)
    IF PortOpen% THEN
        chars% = LOC(1)
        IF chars% > 0 THEN
            raw$ = INPUT$(chars%, #1)

            FOR i% = 1 TO LEN(raw$)
                ch$ = MID$(raw$, i%, 1)

                IF ch$ = CHR$(13) THEN
                    IF LEN(RxBuffer$) > 0 THEN
                        CALL AddLine(MakeTagged$("RX", RxBuffer$))
                        CALL UpdateStatus("Receive OK")
                        RxBuffer$ = ""
                        CALL DrawPrompt(InputLine$)
                    END IF

                ELSEIF ch$ = CHR$(10) THEN
                    ' Ignore line feed

                ELSE
                    RxBuffer$ = RxBuffer$ + ch$

                    ' Safety limit in case sender never terminates line
                    IF LEN(RxBuffer$) >= 70 THEN
                        CALL AddLine(MakeTagged$("RX", RxBuffer$))
                        CALL UpdateStatus("Receive OK")
                        RxBuffer$ = ""
                        CALL DrawPrompt(InputLine$)
                    END IF
                END IF
            NEXT i%
        END IF
    END IF

LOOP

IF PortOpen% THEN
    CLOSE #1
    PortOpen% = 0
END IF

VIEW PRINT 1 TO 25
COLOR 7, 0
WIDTH 80, 25
CLS
END

ErrorHandler:
    IF InPortOpen% THEN
        PortOpen% = 0
        InPortOpen% = 0
        CALL UpdateStatus("COM1 open failed")
        CALL AddLine(MakeTagged$("ERR", "Unable to open " + PortName$ + "."))
        RESUME NEXT
    END IF

    CALL UpdateStatus("Runtime error " + LTRIM$(STR$(ERR)))
    CALL AddLine(MakeTagged$("ERR", "Runtime error " + LTRIM$(STR$(ERR))))
    END



SUB AddLine (Msg$)
    VIEW PRINT VIEWTOP TO VIEWBOTTOM
    COLOR 2, 0
    LOCATE VIEWBOTTOM, 1
    PRINT SPACE$(80);
    LOCATE VIEWBOTTOM, 1
    PRINT LEFT$(Msg$, 79)
END SUB

SUB DrawPrompt (InputLine$)
    VIEW PRINT 1 TO 25
    COLOR 2, 0
    LOCATE PROMPTROW, 1
    PRINT SPACE$(80);
    LOCATE PROMPTROW, 1
    PRINT "Command> "; LEFT$(InputLine$, 69);
    VIEW PRINT VIEWTOP TO VIEWBOTTOM
END SUB

SUB DrawScreen
    VIEW PRINT 1 TO 25

    COLOR 2, 0
    LOCATE MENUROW, 1
    PRINT SPACE$(80);
    LOCATE MENUROW, 1
    PRINT " IBM SERIAL TERMINAL   ESC=Exit   Enter=Send ";

    LOCATE TOPBORDER, 1
    PRINT STRING$(80, 196);

    LOCATE BOTTOMBORDER, 1
    PRINT STRING$(80, 196);

    LOCATE STATUSROW1, 1
    PRINT SPACE$(80);
    LOCATE STATUSROW1, 1
    PRINT " Port: "; PortName$; "   Baud: "; Baud$; "   Parity: "; Parity$; "   Data: "; DataBits$; "   Stop: "; StopBits$

    LOCATE STATUSROW2, 1
    PRINT SPACE$(80);
    LOCATE STATUSROW2, 1
    PRINT " Status: Initializing..."

    LOCATE PROMPTROW, 1
    PRINT SPACE$(80);
    LOCATE PROMPTROW, 1
    PRINT "Command> ";

    VIEW PRINT VIEWTOP TO VIEWBOTTOM
END SUB

FUNCTION MakeTagged$ (Tag$, Msg$)
    MakeTagged$ = Stamp$ + " " + Tag$ + "> " + Msg$
END FUNCTION

FUNCTION Stamp$
    Stamp$ = "[" + TIME$ + "]"
END FUNCTION

SUB UpdateStatus (Msg$)
    VIEW PRINT 1 TO 25
    COLOR 2, 0
    LOCATE STATUSROW2, 1
    PRINT SPACE$(80);
    LOCATE STATUSROW2, 1
    PRINT " Status: "; LEFT$(Msg$, 71)
    VIEW PRINT VIEWTOP TO VIEWBOTTOM
END SUB

