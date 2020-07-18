# -*- mode: python ; coding: utf-8 -*-

block_cipher = None


a = Analysis(['/home/vpntech/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version4/_scripts/__tester.py'],
             pathex=['/home/vpntech/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version4/.specs_1595033588'],
             binaries=[],
             datas=[],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          [],
          exclude_binaries=True,
          name='/home/vpntech/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version4/_scripts/__tester',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=False,
               upx=True,
               upx_exclude=[],
               name='/home/vpntech/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version4/_scripts/__tester')
