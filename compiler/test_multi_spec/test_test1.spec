block_cipher = None

test_a = Analysis(['test.py'],
             pathex=['/home/rblundell@product.healthinteractive.net/ansible-bundle-playbook-dev/compiler'],
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



test1_a = Analysis(['test1.py'],
             pathex=['/home/rblundell@product.healthinteractive.net/ansible-bundle-playbook-dev/compiler'],
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



MERGE( (test_a, 'test', 'test'), (test1_a, 'test1', 'test1') )



test_pyz = PYZ(test_a.pure, test_a.zipped_data,
             cipher=block_cipher)
test_exe = EXE(test_pyz,
          test_a.scripts,
          [],
          exclude_binaries=True,
          name='test',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
coll = COLLECT(test_exe,
               test_a.binaries,
               test_a.zipfiles,
               test_a.datas,
               strip=False,
               upx=True,
               upx_exclude=[],
               name='test')




test1_pyz = PYZ(test1_a.pure, test1_a.zipped_data,
             cipher=block_cipher)
test1_exe = EXE(test1_pyz,
          test1_a.scripts,
          [],
          exclude_binaries=True,
          name='test1',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
test1_coll = COLLECT(test1_exe,
               test1_a.binaries,
               test1_a.zipfiles,
               test1_a.datas,
               strip=False,
               upx=True,
               upx_exclude=[],
               name='test1')
