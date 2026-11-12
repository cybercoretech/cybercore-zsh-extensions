#!/usr/bin/env python3
"""Tiny HTTP server for provider tests.

Records each request (path, headers, JSON body) as one JSON line in the log
file, waits `delay` seconds, and answers with the canned reply for its path.

    mock_server.py <port-file> <log-file> <replies.json> [delay-seconds]

replies.json maps a path to {"status": 200, "body": {...}}. The chosen port is
written to <port-file> once the server is listening.
"""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

port_file, log_file, replies_file = sys.argv[1:4]
delay = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0
with open(replies_file) as f:
    replies = json.load(f)


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length)
        try:
            body = json.loads(raw)
        except ValueError:
            body = {"_unparsed": raw.decode("utf-8", "replace")}
        with open(log_file, "a") as f:
            f.write(json.dumps({"path": self.path,
                                "headers": {k.lower(): v for k, v in self.headers.items()},
                                "body": body}) + "\n")
        time.sleep(delay)
        reply = replies.get(self.path, {"status": 404, "body": {"error": "no such path"}})
        out = json.dumps(reply["body"]).encode()
        self.send_response(reply.get("status", 200))
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

    def log_message(self, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
with open(port_file, "w") as f:
    f.write(str(server.server_address[1]))
server.serve_forever()
