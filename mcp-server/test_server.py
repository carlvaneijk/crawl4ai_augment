import json
import subprocess
import sys

def test_mcp_server():
    # Start the server process
    process = subprocess.Popen(
        [sys.executable, "src/crawl4ai_mcp/server.py"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Send initialization
    init_msg = {
        "jsonrpc": "2.0",
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test", "version": "1.0"}
        },
        "id": 1
    }
    
    # Send initialized notification
    initialized_msg = {
        "jsonrpc": "2.0",
        "method": "notifications/initialized",
        "params": {}
    }
    
    # Send tools list request
    tools_msg = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 2
    }
    
    # Send all messages
    input_data = "\n".join([
        json.dumps(init_msg),
        json.dumps(initialized_msg),
        json.dumps(tools_msg)
    ]) + "\n"
    
    try:
        stdout, stderr = process.communicate(input=input_data, timeout=10)
        print("STDOUT:")
        for line in stdout.strip().split('\n'):
            if line.strip():
                try:
                    parsed = json.loads(line)
                    print(json.dumps(parsed, indent=2))
                except:
                    print(line)
        
        if stderr:
            print("\nSTDERR:")
            print(stderr)
            
    except subprocess.TimeoutExpired:
        process.kill()
        print("Server test timed out")
    
    return process.returncode

if __name__ == "__main__":
    test_mcp_server()
