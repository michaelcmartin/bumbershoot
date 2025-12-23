#!/bin/env python
import os.path
import sys
import zipfile

def go(pathbase):
	gromdata = open(f"{pathbase}g.bin", "rb").read()
	romdata = open(f"{pathbase}c.bin", "rb").read()
	metainf = f"""<?xml version='1.0'?>
<meta-inf>
    <name>{os.path.basename(pathbase)}</name>
</meta-inf>
"""
	layout = f"""<?xml version='1.0' encoding='utf-8'?>
<romset version='1.0'>
    <resources>
        <rom id='gromimage' file='grom.bin'/>
        <rom id='romimage' file='rom.bin'/>
    </resources>
    <configuration>
        <pcb type='standard'>
            <socket id='grom_socket' uses='gromimage'/>
            <socket id='rom_socket' uses='romimage'/>
        </pcb>
    </configuration>
</romset>
"""
	with zipfile.ZipFile(f"{pathbase}.rpk", "w") as rpk:
		rpk.writestr("meta-inf.xml", metainf)
		rpk.writestr("layout.xml", layout, zipfile.ZIP_DEFLATED)
		rpk.writestr("grom.bin", gromdata, zipfile.ZIP_DEFLATED)
		rpk.writestr("rom.bin", romdata, zipfile.ZIP_DEFLATED)


if __name__=='__main__':
	go(sys.argv[1])
