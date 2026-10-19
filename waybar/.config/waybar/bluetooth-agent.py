#!/usr/bin/env python3
import subprocess
import sys

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

AGENT_PATH = "/org/bluez/agent/wofi"
CAPABILITY = "KeyboardDisplay"
WOFI = [
    "wofi", "--dmenu", "--location", "3", "--xoffset", "-12", "--yoffset", "48",
    "--width", "320", "--cache-file", "/dev/null", "--insensitive",
]

bus = None


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


class Canceled(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Canceled"


def notify(msg):
    subprocess.run(["notify-send", "-t", "6000", "Bluetooth", msg])


def ask(prompt, options):
    p = subprocess.run(
        WOFI + ["--prompt", prompt],
        input="\n".join(options) + "\n",
        capture_output=True,
        text=True,
    )
    out = p.stdout.strip()
    return out if p.returncode == 0 and out else None


def yes_no(prompt, yes, no):
    return ask(prompt, [yes, no]) == yes


def props(path):
    obj = bus.get_object("org.bluez", str(path))
    return dbus.Interface(obj, "org.freedesktop.DBus.Properties")


def alias(path):
    try:
        return str(props(path).Get("org.bluez.Device1", "Alias"))
    except dbus.DBusException:
        return str(path).split("/")[-1]


def trust(path):
    try:
        props(path).Set("org.bluez.Device1", "Trusted", dbus.Boolean(True))
    except dbus.DBusException:
        pass


class Agent(dbus.service.Object):
    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        if not yes_no(f"{alias(device)} wants to connect", "Allow", "Deny"):
            raise Rejected("Rejected")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        pin = ask(f"PIN for {alias(device)}", ["0000", "1234"])
        if not pin:
            raise Canceled("Canceled")
        trust(device)
        return pin

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        notify(f"Enter PIN {pincode} on {alias(device)}")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        val = ask(f"Passkey shown on {alias(device)}", [])
        if not val or not val.isdigit():
            raise Canceled("Canceled")
        trust(device)
        return dbus.UInt32(int(val))

    @dbus.service.method("org.bluez.Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        if int(entered) == 0:
            notify(f"Type {int(passkey):06d} on {alias(device)}, then press Enter")

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        prompt = f"{alias(device)}: does {int(passkey):06d} match?"
        if not yes_no(prompt, "Yes, it matches", "No"):
            raise Rejected("Rejected")
        trust(device)

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        if not yes_no(f"Pair with {alias(device)}?", "Pair", "Cancel"):
            raise Rejected("Rejected")
        trust(device)

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        pass


def main():
    global bus
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    Agent(bus, AGENT_PATH)
    mgr = dbus.Interface(
        bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1"
    )
    try:
        mgr.RegisterAgent(AGENT_PATH, CAPABILITY)
        mgr.RequestDefaultAgent(AGENT_PATH)
    except dbus.DBusException as e:
        print(f"Could not register agent: {e}", file=sys.stderr)
        sys.exit(1)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
