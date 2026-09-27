# uACPI-NT

uACPI ported to NT based kernels.

```powershell
.\scripts\build-win7.ps1
.\scripts\build-win7.ps1 -Arch x86
.\scripts\build-win11.ps1 -Config Release
.\scripts\build-all.ps1 -Arch all
```

You might've noticed under scripts/ is various windows version targets. They layout of several of the structures
used in this driver change between different NT targets. This repo is designed to build multiple targets 
that will work on many different versions of windows. Allowing us to unify the code base for various cases.
