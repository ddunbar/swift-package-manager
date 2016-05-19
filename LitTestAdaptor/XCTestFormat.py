# This source file is part of the Swift.org open source project
#
# Copyright 2016 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

# Adaptor for running XCTest tests using 'lit'.

import json
import os
import pipes
import subprocess
import sys

import lit.Test
import lit.TestRunner
import lit.formats.base
import lit.util

class XCTestFormat(lit.formats.base.TestFormat):
    def __init__(self, tests_dir, bundle_test_finder_path):
        self.developer_dir = subprocess.check_output(
            ["xcode-select", "-p"]).strip()
        self.dyld_framework_path = os.path.join(
            self.developer_dir,
            "Platforms/MacOSX.platform/Developer/Library/Frameworks")
        
        self.tests_dir = tests_dir
        self.bundle_test_finder_path = bundle_test_finder_path
        
    def findTestBundles(self, path, enable_perf_tests):
        # Get all of the test bundles.
        for bundle in os.listdir(path):
            if not bundle.endswith(".xctest"):
                continue

            # Ignore perf tests, if desired.
            if 'PerfTests' in bundle and not enable_perf_tests:
                continue
            
            yield os.path.join(self.tests_dir, bundle)

    def getTestsInExecutable(self, testSuite, path_in_suite, execpath,
                             litConfig, localConfig):
        if not execpath.endswith(self.test_suffix):
            return
        (dirname, basename) = os.path.split(execpath)
        # Discover the tests in this executable.
        for testname in self.getGTestTests(execpath, litConfig, localConfig):
            testPath = path_in_suite + (basename, testname)
            yield lit.Test.Test(
                testSuite, testPath, localConfig, file_path=execpath)

    def getTestsInDirectory(self, testSuite, path_in_suite,
                            litConfig, localConfig):
        # We ignore the discovery path. C'est la vie.
        for bundle_path in sorted(self.findTestBundles(
                self.tests_dir, localConfig.root.enable_perf_tests)):
            # Find all of the tests in the bundle.
            data = json.loads(subprocess.check_output(
                [self.bundle_test_finder_path, bundle_path],
                env={
                    "DYLD_FRAMEWORK_PATH": self.dyld_framework_path
                }))
            for test in data["testSpecifiers"]:
                if test is None:
                    continue
                testPath = path_in_suite + (os.path.basename(bundle_path), test)
                yield lit.Test.Test(testSuite, testPath, localConfig)
                
    def execute(self, test, litConfig):
        bundle, specifier = test.path_in_suite

        cmd = ["xcrun", "xctest", "-XCTest", specifier,
               os.path.join(self.tests_dir, bundle)]
        
        if litConfig.noExecute:
            return lit.Test.PASS, ''

        out, err, exitCode = lit.util.executeCommand(
            cmd, env=test.config.environment)

        # If the test completed succesfully, ensure it was actually run.
        if exitCode == 0 and 'Executed 1 test' not in err:
            msg = ('unexpected XCTest output (test was not run):\n\n%s\n%s%s' %
                   (' '.join(map(pipes.quote, cmd)), out, err))
            return lit.Test.UNRESOLVED, msg
        
        if exitCode:
            err += "Exit Status: %d" % (exitCode,)
            return lit.Test.FAIL, out + err

        passing_test_line = """Test Suite 'Selected tests' passed"""
        if passing_test_line not in err:
            msg = ('Unable to find %r in XCTest output:\n\n%s%s' %
                   (passing_test_line, out, err))
            return lit.Test.UNRESOLVED, msg

        return lit.Test.PASS,''

