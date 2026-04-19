IBM PC ↔ Raspberry Pi AI Terminal Project. A modern AI inference system accessed through a 1980s serial terminal interface.

This project allows a vintage IBM PC/XT (or compatible) to communicate with a local AI model running on a Raspberry Pi over a serial connection.

The IBM acts as a terminal, and the Raspberry Pi runs the AI and responds in real time.

Requirements
Hardware:
IBM PC / XT (or compatible) with serial port (COM1)
Raspberry Pi (Pi 4 or Pi 5 recommended)
USB to RS-232 adapter (FTDI chipset recommended)
Null modem adapter or cable (VERY IMPORTANT)

Wiring:
IBM COM1 ←→ Null Modem ←→ USB Serial Adapter ←→ Raspberry Pi

Raspberry Pi Setup
1. Install dependencies
sudo apt update
sudo apt install python3 python3-pip git cmake build-essential
pip3 install pyserial
2. Build llama.cpp
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
mkdir build
cd build
cmake ..
make -j4
3. Download a model

Example (Qwen 1.5B):

cd ~/llama.cpp
wget https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf
4. Start AI server
cd ~/llama.cpp/build/bin
./llama-server -m ~/llama.cpp/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf

Server runs at:

http://127.0.0.1:8080
5. Run the bridge script
python3 xt_ai_bridge.py
IBM PC Setup

Run the provided BASIC terminal program.

Recommended serial settings:

Port: COM1
Baud: 1200
Parity: None
Data bits: 8
Stop bits: 1
Usage:
Start IBM terminal program
Start Raspberry Pi script
Type messages on IBM
AI responses will appear on screen
Notes:
You MUST use a null modem adapter
AI responses are automatically split into 60-character lines
Designed for slow serial links and vintage systems
Works on monochrome displays (MDA/Hercules)
Example:
TX> What color is a polar bear?
RX> White

TX> Where is Lake Tahoe?
RX> Lake Tahoe is in the Sierra Nevada mountains of
RX> California and Nevada.
Enjoy!

You are now chatting with an AI from a 1980s computer.
