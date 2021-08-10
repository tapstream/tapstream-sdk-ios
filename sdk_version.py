import plistlib

def sdk_version():
    with open('./tapstream-sdk-ios/Info.plist') as f:
        pl = plistlib.readPlist(f)
        return pl['CFBundleShortVersionString']

if __name__ == "__main__":
    print(sdk_version())
