# IBM-AI-Terminal

IBM-AI-TERMINAL is a retro-modern computing project that enables a vintage IBM PC/XT to communicate with a locally hosted AI model using a serial connection.

The IBM PC acts as a terminal, while a Raspberry Pi runs a lightweight large language model (LLM) using `llama.cpp`. Messages are exchanged over a null-modem RS-232 link, creating the experience of a classic 1980s terminal connected to a modern AI system.

---

## Website
https://aimutt.com/

---
## ✨ Features

- 🖥️ Runs on real IBM PC/XT hardware (or compatible systems)
- 🔌 Serial communication over RS-232 (COM1)
- 🤖 Local AI inference (fully offline)
- ⚡ Fast responses using `llama-server` (persistent model)
- 🧠 Powered by Qwen 1.5B (or similar GGUF models)
- 📜 Terminal-style interface written in QuickBASIC 4.0 (DOS .exe terminal app provided in .zip file)
- 🧵 AI responses automatically wrapped for 80x25 text display
- 🚫 No internet required once setup is complete

---

## 🧩 System Architecture
IBM PC/XT (QB Terminal)
⇅ RS-232 (Null Modem)
Raspberry Pi (Python Bridge)
⇅ HTTP
llama-server (llama.cpp)
⇅
Local AI Model (GGUF)

---

## 🛠️ Components

### IBM Side

- QuickBASIC 4.0 terminal program
- Compiled `.EXE` for standalone use
- Character-by-character serial handling for responsiveness
- Supports `ESC` or `ALT+Q` to exit

### Raspberry Pi Side

- Python serial bridge (`xt_ai_bridge.py`)
- `llama-server` for persistent AI inference
- Auto-detection of USB serial device (`/dev/ttyUSB*`)
- systemd services for automatic startup

---

## 🚀 How It Works

1. The IBM PC sends a message over COM1  
2. The Raspberry Pi receives it via a USB-to-serial adapter  
3. The Python bridge forwards the message to `llama-server`  
4. The AI generates a response  
5. The response is split into terminal-safe lines  
6. The IBM displays the response in real time  

---

## 🧪 Example
TX> Where is Lake Tahoe?
RX> Lake Tahoe is in the Sierra Nevada mountains of
RX> California and Nevada.

---

## 🎯 Design Goals

- Preserve the look and feel of 1980s computing  
- Maintain real hardware compatibility  
- Keep the system simple, robust, and offline  
- Deliver fast, usable AI interaction over slow serial links  

---

## ⚠️ Requirements

- IBM PC/XT or compatible with serial port  
- Raspberry Pi 4 or 5  
- USB to RS-232 adapter (FTDI recommended)  
- Null modem cable or adapter (**required**)  
- DOS + QuickBASIC (for building/modifying the terminal). Or run the .exe DOS file located in the ALL-FILES-WITH-EXE.zip on the IBM PC.

---

## 🔥 Why This Project Exists

This project explores what computing might have looked like if modern AI existed in the 1980s:

> A text-based terminal connected to an intelligent remote system — powered not by a mainframe, but by a local AI model.

---

## 🧠 Future Ideas

- Character-by-character “typing” responses  
- Multiple AI personalities (DOS assistant, etc.)  
- Command system (`/help`, `/time`, etc.)  
- Expanded terminal UI features  

---

## 📜 License

MIT License
> You can use this code however you want — just give credit and don’t blame me if something breaks.
