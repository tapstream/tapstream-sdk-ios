import re
import os.path
import pystache
from sdk_version import sdk_version
from fabric.api import lcd, local, task, execute, runs_once
from fabric.operations import prompt

@task
@runs_once
def test():
    """
    Use xctool to test both SDKs
    """
    schemes = {
        'TapstreamIOS': [
            'platform=iOS Simulator,name=iPhone 7,OS=10.0'
        ],
        'TapstreamMac': [
            'platform=OS X,arch=x86_64'
        ]
    }

    local('pod update')
    local('pod install')
    for scheme, sdks in schemes.items():
        for sdk in sdks:
            local("xcodebuild test -scheme %s -workspace tapstream-sdk-ios.xcworkspace -destination '%s'" % (scheme, sdk))


@task
@runs_once
def current_version():
    print sdk_version()

@task
@runs_once
def set_version(new_version):
    """
    Update TSDefs.h (via sed) and the project plist files (via agvtool) to a new version number
    """
    assert re.match(r"^3\.[0-9]{1,2}\.[0-9]{1,2}$", new_version)
    old_version = sdk_version()
    old_version_re = old_version.replace('.', '\\.')
    local("sed -i '' -e 's/%s/%s/g' tapstream-sdk-ios/TSDefs.h" % (old_version_re, new_version))
    local("agvtool new-marketing-version %s" % new_version)


@task
@runs_once
def package():
    """
    Depends on: test

    Create ios and mac .zip files in the package directory
    """
    version = sdk_version()
    cmd = 'zip -D'
    ios_dest = os.path.abspath('./package/tapstream-sdk-ios-%s.zip' % version)
    mac_dest = os.path.abspath('./package/tapstream-sdk-mac-%s.zip' % version)

    if not os.path.exists('./package'):
        local('mkdir package')

    if os.path.exists(ios_dest):
        local('rm %s' % ios_dest)

    if os.path.exists(mac_dest):
        local('rm %s' % mac_dest)

    common_files = ['*.h',
                    '*.m']

    ios_only_files = ['**/*.h',
                      '**/*.m',
                      '**/*.xib']

    with lcd('tapstream-sdk-ios'):
        for dir in common_files:
            local('%s %s %s' % (cmd, mac_dest, dir))
            local('%s %s %s' % (cmd, ios_dest, dir))

        for dir in ios_only_files:
            local('%s %s %s' % (cmd, ios_dest, dir))


@task
@runs_once
def generate_podspecs():
    """
    Use the template files to update the templates with current versions
    """
    v = sdk_version()
    with open('./TapstreamIOS.podspec.tpl') as infile:
        with open('./TapstreamIOS.podspec', 'w') as outfile:
            outfile.write(pystache.render(infile.read(), {'version': v}))

    with open('./TapstreamMac.podspec.tpl') as infile:
        with open('./TapstreamMac.podspec', 'w') as outfile:
            outfile.write(pystache.render(infile.read(), {'version': v}))


@task
@runs_once
def push_pods():
    """
    Depends: generate_podspecs

    Push the current revision (and version) to cocoapods
    """
    execute(generate_podspecs)

    local('pod trunk push TapstreamIOS.podspec')
    local('pod trunk push TapstreamMac.podspec')


@task
@runs_once
def release(new_version):
    execute(test)
    execute(set_version, new_version)
    execute(package)

    local('open package')

    prompt("""Now, create two releases on Github: v{v}-ios, and v{v}-macos.
Then, come back and press enter to continue deployment to cocoapods >
""".format(v=new_version))

    execute(push_pods)


