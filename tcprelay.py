#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# tcprelay.py - TCP connection relay for usbmuxd
#
# Copyright (C) 2009	Hector Martin "marcan" <hector@marcansoft.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import usbmux
import SocketServer
import select
from optparse import OptionParser
import sys
import traceback

class SocketRelay(object):
    def __init__(self, a, b, maxBuffer = 65535):
        self.a = a
        self.b = b
        self.atob = ""
        self.btoa = ""
        self.maxBuffer = maxBuffer

    def handle(self):
        while True:
            rlist = []
            wlist = []
            xlist = [self.a, self.b]
            if self.atob:
                wlist.append(self.b)
            if self.btoa:
                wlist.append(self.a)
            if len(self.atob) < self.maxBuffer:
                rlist.append(self.a)
            if len(self.btoa) < self.maxBuffer:
                rlist.append(self.b)
            rlo, wlo, xlo = select.select(rlist, wlist, xlist)
            if xlo:
                return
            if self.a in wlo:
                n = self.a.send(self.btoa)
                self.btoa = self.btoa[n:]
            if self.b in wlo:
                n = self.b.send(self.atob)
                self.atob = self.atob[n:]
            if self.a in rlo:
                s = self.a.recv(self.maxBuffer - len(self.atob))
                if not s:
                    return
                self.atob += s
            if self.b in rlo:
                s = self.b.recv(self.maxBuffer - len(self.btoa))
                if not s:
                    return
                self.btoa += s
            #print "Relay iter: %8d atob, %8d btoa, lists: %r %r %r"%(len(self.atob), len(self.btoa), rlo, wlo, xlo)


class TCPRelay(SocketServer.BaseRequestHandler):
    def handle(self):
        print "Incoming connection to {0}".format(self.server.server_address[1])

        print "Waiting for devices..."
        if len(self.server.devices) == 0:
            print "No device found"
            self.request.close()
            return

        dev = None
        if options.udid is None:
            # Default to the first available device if no udid was specified
            dev = self.server.devices[0]
        else:
            for device in self.server.devices:
                # Look for the specified device UDID
                if device.serial == options.udid:
                    dev = device
                    break

        if not dev:
            raise Exception("Could not detect specified device UDID: {0}".format(repr(options.udid)))

        print "Connecting to device {0}".format(dev)
        dsock = mux.connect(dev, self.server.remotePort)
        lsock = self.request
        print "Connection established, relaying data"
        try:
            fwd = SocketRelay(dsock, lsock, self.server.bufferSize * 1024)
            fwd.handle()
        finally:
            dsock.close()
            lsock.close()
        print "Connection closed"


class TCPServer(SocketServer.TCPServer):
    allow_reuse_address = True


class ThreadedTCPServer(SocketServer.ThreadingMixIn, TCPServer):
    pass


parser = OptionParser(usage="usage: %prog [OPTIONS] [Host:]RemotePort[:LocalPort] [[Host:]RemotePort[:LocalPort]]...")
parser.add_option("-t", "--threaded", dest='threaded', action='store_true', default=False,
                  help="use threading to handle multiple connections at once")
parser.add_option("-b", "--bufsize", dest='bufsize', action='store', metavar='KILOBYTES', type='int', default=128,
                  help="specify buffer size for socket forwarding")
parser.add_option("-s", "--socket", dest='sockpath', action='store', metavar='PATH', type='str', default=None,
                  help="specify the path of the usbmuxd socket")
parser.add_option("-u", "--udid", dest='udid', action='store', metavar='UDID', type='str', default=None,
                  help="specify the device's udid if multiple devices are connected")

options, args = parser.parse_args()

serverClass = ThreadedTCPServer if options.threaded else TCPServer

if len(args) == 0:
    parser.print_help()
    sys.exit(1)

ports = []


mux = usbmux.USBMux(options.sockpath)
print "Waiting for devices..."
mux.process(0.1)
lastLength = len(mux.devices)

while True:
    mux.process(0.1)
    if len(mux.devices) == lastLength: break
    lastLength = len(mux.devices)

devices = mux.devices
print "Devices:\n{0}".format("\n".join([str(d) for d in devices]))

for arg in args:
    try:
        if ':' in arg:
            remotePort, localPort = arg.rsplit(":", 1)
            host, remotePort = remotePort.split(":") if len(remotePort.split(":")) > 1 else ("localhost", remotePort)
            remotePort = int(remotePort)
            localPort = int(localPort)
            ports.append((host, remotePort, localPort))
        else:
            ports.append(("localhost", int(arg), int(arg)))
    except:
        parser.print_help()
        sys.exit(1)

servers = []

for host, remotePort, localPort in ports:
    print "Forwarding local port {0}:{1} to remote port {2}".format(host, localPort, remotePort)
    server = serverClass((host, localPort), TCPRelay)
    server.remotePort = remotePort
    server.bufferSize = options.bufsize
    server.devices = devices
    servers.append(server)

alive = True

while alive:
    try:
        rl, wl, xl = select.select(servers, [], [])
        for server in rl:
            server.handle_request()
    except:
        traceback.print_exc()
        alive = False
