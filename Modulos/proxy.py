#!/usr/bin/env python3
import select
import socket
import sys
import threading

HOST = "0.0.0.0"
DEFAULT_PORT = 80
DEFAULT_TARGET = "0.0.0.0:22"
BUFFER = 64 * 1024
IDLE_TIMEOUT = 60

def parse_target(value, default_port=22):
    value = value.strip()
    if ":" in value and not value.startswith("["):
        host, port = value.rsplit(":", 1)
        try: return host or "127.0.0.1", int(port)
        except ValueError: pass
    return value or "127.0.0.1", default_port

class ProxyHandler(threading.Thread):
    daemon = True
    def __init__(self, client, address):
        super().__init__(); self.client = client; self.address = address; self.target = None
    def close(self):
        for sock in (self.client, self.target):
            if sock:
                try: sock.shutdown(socket.SHUT_RDWR)
                except OSError: pass
                try: sock.close()
                except OSError: pass
    def run(self):
        try:
            self.client.settimeout(10); request = self.client.recv(BUFFER)
            if not request: return
            text = request.decode("latin1", "replace")
            headers = {}
            for line in text.split("\r\n")[1:]:
                if ":" in line:
                    key, value = line.split(":", 1); headers[key.strip().lower()] = value.strip()
            host, port = parse_target(headers.get("x-real-host") or DEFAULT_TARGET)
            self.target = socket.create_connection((host, port), timeout=10)
            self.client.sendall(b"HTTP/1.1 200 Connection established\r\n\r\n")
            self.client.settimeout(None); self.target.settimeout(None); self.relay()
        except Exception as exc:
            print("Conexao %s - erro: %s" % (self.address, exc), flush=True)
        finally: self.close()
    def relay(self):
        sockets = [self.client, self.target]; idle = 0
        while idle < IDLE_TIMEOUT:
            readable, _, exceptional = select.select(sockets, [], sockets, 1)
            if exceptional: return
            if not readable: idle += 1; continue
            idle = 0
            for source in readable:
                data = source.recv(BUFFER)
                if not data: return
                (self.target if source is self.client else self.client).sendall(data)

def main():
    try:
        port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
        if not 1 <= port <= 65535: raise ValueError
    except ValueError:
        print("Porta invalida", file=sys.stderr); return 2
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); server.bind((HOST, port)); server.listen(128)
    print("PROXY SOCKS ativo em 0.0.0.0:%d" % port, flush=True)
    try:
        while True:
            client, address = server.accept(); ProxyHandler(client, address).start()
    except KeyboardInterrupt: return 0
    finally: server.close()

if __name__ == "__main__": raise SystemExit(main())
