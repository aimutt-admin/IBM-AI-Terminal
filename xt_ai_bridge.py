#!/usr/bin/env python3

import glob
import json
import serial
import signal
import time
import urllib.request
import urllib.error

# -----------------------------
# CONFIGURATION
# -----------------------------
BAUD = 1200
SERVER_URL = "http://127.0.0.1:8080/v1/chat/completions"
LOG_FILE = "/home/user5/xt_ai_bridge.log"

MAX_LINE_LEN = 60

RUNNING = True


# -----------------------------
# HELPERS
# -----------------------------
def stamp():
    return time.strftime("[%Y-%m-%d %H:%M:%S]")


def log(msg):
    line = f"{stamp()} {msg}"
    print(line, flush=True)
    try:
        with open(LOG_FILE, "a") as f:
            f.write(line + "\n")
    except Exception:
        pass


def find_serial_port():
    ports = sorted(glob.glob("/dev/ttyUSB*"))
    if ports:
        return ports[0]
    return None


def send_line(ser, text):
    ser.write((text + "\r\n").encode("ascii", errors="ignore"))
    ser.flush()


def send_wrapped_response(ser, text):
    parts = wrap_text(text, MAX_LINE_LEN)
    for part in parts:
        log(f"TX {part}")
        send_line(ser, part)


def open_serial(port_name):
    return serial.Serial(
        port=port_name,
        baudrate=BAUD,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.2,
        xonxoff=False,
        rtscts=False,
        dsrdtr=False,
    )


def handle_signal(signum, frame):
    global RUNNING
    RUNNING = False
    log(f"SYS received signal {signum}, shutting down...")


def trim_response(text):
    text = text.strip()

    if not text:
        return "No response."

    return text


def wrap_text(text, width):
    text = " ".join(text.split())

    if not text:
        return ["No response."]

    words = text.split(" ")
    lines = []
    current = ""

    for word in words:
        # If a single word is longer than width, split it
        while len(word) > width:
            if current:
                lines.append(current)
                current = ""
            lines.append(word[:width])
            word = word[width:]

        if not current:
            current = word
        elif len(current) + 1 + len(word) <= width:
            current = current + " " + word
        else:
            lines.append(current)
            current = word

    if current:
        lines.append(current)

    return lines


def get_ai_response(user_msg):
    payload = {
        "model": "qwen",
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a remote computer connected to a 1980s IBM PC terminal. "
                    "Plain text only. No markdown. No bullet lists. "
                    "No extra explanation. Keep answers concise and direct."
                )
            },
            {
                "role": "user",
                "content": user_msg
            }
        ],
        "max_tokens": 120,
        "temperature": 0.2,
        "stream": False
    }

    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        SERVER_URL,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer no-key"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = resp.read().decode("utf-8")

        parsed = json.loads(body)
        response = parsed["choices"][0]["message"]["content"]
        return trim_response(response)

    except urllib.error.HTTPError as e:
        try:
            err_body = e.read().decode("utf-8", errors="ignore")
        except Exception:
            err_body = ""
        log(f"ERR HTTP error from llama-server: {e.code} {err_body}")
        return "AI server error."

    except Exception as e:
        log(f"ERR exception in get_ai_response: {e}")
        return "AI failure."


# -----------------------------
# MAIN
# -----------------------------
def main():
    global RUNNING

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    log("SYS xt_ai_bridge_server starting...")

    serial_port = None

    while RUNNING and serial_port is None:
        serial_port = find_serial_port()
        if serial_port is None:
            log("SYS waiting for serial device /dev/ttyUSB* ...")
            time.sleep(2)

    if not RUNNING:
        return

    try:
        ser = open_serial(serial_port)
    except Exception as e:
        log(f"ERR unable to open serial port {serial_port}: {e}")
        return

    log(f"SYS opened serial port {serial_port} at {BAUD} baud")

    time.sleep(1)
    send_line(ser, "AI HOST READY")
    send_line(ser, "QWEN SERVER ONLINE")
    send_line(ser, "TYPE YOUR MESSAGE")

    rx_buffer = ""

    while RUNNING:
        try:
            data = ser.read(1)

            if not data:
                continue

            ch = data.decode("ascii", errors="ignore")

            if ch == "\r":
                if rx_buffer.strip():
                    user_msg = rx_buffer.strip()
                    log(f"RX {user_msg}")

                    response = get_ai_response(user_msg)
                    send_wrapped_response(ser, response)

                rx_buffer = ""

            elif ch == "\n":
                pass

            else:
                rx_buffer += ch

                if len(rx_buffer) >= 200:
                    user_msg = rx_buffer.strip()
                    if user_msg:
                        log(f"RX {user_msg}")
                        response = get_ai_response(user_msg)
                        send_wrapped_response(ser, response)
                    rx_buffer = ""

        except Exception as e:
            log(f"ERR serial loop exception: {e}")
            time.sleep(1)

    try:
        ser.close()
    except Exception:
        pass

    log("SYS xt_ai_bridge_server stopped.")


if __name__ == "__main__":
    main()
