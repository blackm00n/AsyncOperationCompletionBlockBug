source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

def mocking_pods
    pod 'Mockingjay', :git => 'https://github.com/kylef/Mockingjay', :commit=> 'a2ac2bf'
end

target 'AsyncOperationCompletionBlockBugTests' do
    workspace 'AsyncOperationCompletionBlockBug'
    project 'AsyncOperationCompletionBlockBug.xcodeproj'
    mocking_pods
end

