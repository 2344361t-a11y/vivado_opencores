import os
import sys

def main():
    input_path = r"C:\Users\ryoic\.gemini\antigravity\scratch\vivado_opencores\wbuart32\trunk\bench\cpp\speech.txt"
    output_dirs = [
        r"C:\Users\ryoic\.gemini\antigravity\scratch\vivado_opencores\wbuart32\trunk\bench\verilog",
        r"C:\Users\ryoic\.gemini\antigravity\scratch\vivado_opencores",
    ]
    
    if not os.path.exists(input_path):
        print(f"Error: input file {input_path} does not exist")
        sys.exit(1)
        
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Process character by character and convert '\n' to '\r\n'
    processed_bytes = []
    for char in content:
        if char == '\n':
            processed_bytes.append(ord('\r'))
            processed_bytes.append(ord('\n'))
        else:
            processed_bytes.append(ord(char))
            
    # Format exactly like mkspeech.cpp
    hex_lines = []
    addr = 0
    i = 0
    while i < len(processed_bytes):
        line = f"@{addr:08x} "
        linelen = 10
        chunk_bytes = []
        while i < len(processed_bytes) and linelen < 77:
            chunk_bytes.append(f"{processed_bytes[i]:02x}")
            addr += 1
            i += 1
            linelen += 3
        line += " ".join(chunk_bytes) + " "
        hex_lines.append(line)
        
    hex_content = "\n".join(hex_lines) + "\n"
    
    for out_dir in output_dirs:
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "speech.hex")
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(hex_content)
        print(f"Generated {out_path}")

if __name__ == '__main__':
    main()
