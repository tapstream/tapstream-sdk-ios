import plistlib
import re
import os.path

from fabric import task
from fabric import Connection


def sdk_version():
    with open('./tapstream-sdk-ios/Info.plist', 'rb') as f:
        pl = plistlib.load(f)
        return pl['CFBundleShortVersionString']


@task
def test(c: Connection):
    """
    Use xctool to test multiple SDKs.
    """
    schemes = {
        'TapstreamIOS': [
            'platform=iOS Simulator,name=iPhone 12,OS=14.5.0',
        ]
    }

    c.run('pod update')
    c.run('pod install')
    for scheme, sdks in schemes.items():
        for sdk in sdks:
            c.run("xcodebuild test -scheme %s -workspace tapstream-sdk-ios.xcworkspace -destination '%s'" % (scheme, sdk))


@task
def current_version(c: Connection):
    print(sdk_version())

@task
def set_version(c: Connection, new_version: str):
    """
    Update TSDefs.h (via sed) and the project plist files (via agvtool) to a new version number
    """
    assert re.match(r"^3\.[0-9]{1,2}\.[0-9]{1,2}$", new_version)
    old_version = sdk_version()
    old_version_re = old_version.replace('.', '\\.')
    c.run("sed -i '' -e 's/%s/%s/g' tapstream-sdk-ios/TSDefs.h" % (old_version_re, new_version))
    c.run("agvtool new-marketing-version %s" % new_version)


@task
def package(c: Connection):
    """
    Create ios .zip files in the package directory
    """
    version = sdk_version()
    cmd = 'zip -D'
    ios_dest = os.path.abspath('./package/tapstream-sdk-ios-%s.zip' % version)

    if not os.path.exists('./package'):
        c.run('mkdir package')

    if os.path.exists(ios_dest):
        c.run('rm %s' % ios_dest)

    common_files = ['*.h',
                    '*.m']

    ios_only_files = ['**/*.h',
                      '**/*.m',
                      '**/*.xib']

    with c.cd('tapstream-sdk-ios'):
        for dir in common_files:
            c.run('%s %s %s' % (cmd, ios_dest, dir))

        for dir in ios_only_files:
            c.run('%s %s %s' % (cmd, ios_dest, dir))

    c.run('open package')


@task
def generate_podspecs(c: Connection):
    """
    Use the template files to update the templates with current versions
    """
    v = sdk_version()
    with (
        open('./TapstreamIOS.podspec.tpl', 'r') as infile, 
        open('./TapstreamIOS.podspec', 'w') as outfile,
    ):
        template = infile.read()
        podspec = re.sub(r"{{\s*version\s*}}", v, template)
        outfile.write(podspec)


@task
def push_pods(c: Connection):
    """
    Depends: generate_podspecs

    Push the current revision (and version) to cocoapods
    """
    generate_podspecs(c)
    c.run('pod trunk push TapstreamIOS.podspec')


@task
def release(c: Connection, new_version: str):
    test(c)
    set_version(c, new_version)
    package(c)
    push_pods(c)
