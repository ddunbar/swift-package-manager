/*
 This source file is part of the Swift.org open source project

 Copyright 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

@import Foundation;
@import XCTest;

int main(int argc, char **argv) {
  @autoreleasepool {
      NSString *bundlePath = @(argv[1]);

      // Normalize the path.
      if (!bundlePath.absolutePath) {
          bundlePath = [NSFileManager.defaultManager.currentDirectoryPath stringByAppendingPathComponent:bundlePath];
      }
      bundlePath = [bundlePath stringByStandardizingPath];
      
      // Load the bundle from the command line.
      NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
      if (![bundle load]) {
          NSLog(@"unable to load bundle: %s", argv[1]);
      }
    
      // Get the test suite for the given bundle.
      printf("{ \"testSpecifiers\": [\n");
      XCTestSuite *suite = [XCTestSuite testSuiteForBundlePath:bundlePath];
      NSString *suitePrefix = [suite.name stringByDeletingPathExtension];
      NSCharacterSet *splitSet = [NSCharacterSet characterSetWithCharactersInString:@" ]:"];
      for (XCTestSuite *testCaseSuite in suite.tests) {
          for (XCTestCase *test in testCaseSuite.tests) {
              // Extract the test name.
              NSString *name = [test.name componentsSeparatedByCharactersInSet:splitSet][1];

              // Unmangle names for Swift test cases which throw.
              if ([name hasSuffix:@"AndReturnError"]) {
                  name = [name substringWithRange:NSMakeRange(0, name.length - 14)];
              }
                    
              printf("  \"%s/%s\",\n", [[test class] debugDescription].UTF8String, name.UTF8String);
          }
      }
      printf("  null] }\n");
  }
  
  return 0;
}
