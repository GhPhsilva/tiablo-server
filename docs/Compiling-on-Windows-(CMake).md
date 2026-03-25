# Microsoft Visual Studio 2026 with CMake

## 1. Download/install the required software

To compile on Windows, you will need to download and install:
* [Git](https://git-scm.com/download/win)
* [Visual Studio 2026 Community](https://visualstudio.microsoft.com/vs/) (compiler and english language pack)
* [vcpkg](https://github.com/Microsoft/vcpkg) (package manager)

## 2. Set up vcpkg

Make sure to follow full installation of `vcpkg`, per [Official Quickstart](https://github.com/Microsoft/vcpkg#quick-start) execute the following in _Powershell_:

To open Powershell navigate to your desired directory e.g. `C:\` and choose `Open PowerShell window here` (shift + right click).

Then you can safely proceed with configuring vcpkg:


```powershell
git clone https://github.com/microsoft/vcpkg
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

Execute the following command in _Powershell_ with Administrator permission to set vcpkg environment variable:

```powershell
[System.Environment]::SetEnvironmentVariable('VCPKG_ROOT','C:\vcpkg', [System.EnvironmentVariableTarget]::Machine)
```

## 3. Download the source code
```powershell
    cd C:\
    git clone --recursive https://github.com/opentibiabr/canary.git
```

## 4. Build

1. Open Visual Studio. In "**Get started**", select "**Open a local folder**" and open the server main folder.

2. Wait for the Visual Studio to load. It will automatically install the libraries and generate the cmake cache. (Be patient, the first cache may take a few minutes).

3. After the cmake cache is successfully generated, you can compile the server by going to the menu **Build** and choose **Build All**.

---