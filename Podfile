source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'Panna' do
    # local development
    pod 'Balizinha', :path => '../balizinha-pod'
    pod 'RenderCloud', :path => '../RenderCloud'
    pod 'RenderPay', :path => '../RenderPay'
    pod 'PannaPay', :path => '../PannaPay'

#    pod 'Balizinha', :git => 'git@bitbucket.org:renderapps/balizinha-pod.git'
#    pod 'RenderPay', :git => 'git@bitbucket.org:renderapps/renderpay.git'
#    pod 'RenderCloud', :git => 'git@bitbucket.org:renderapps/RenderCloud.git'
#    pod 'PannaPay', :git => 'git@bitbucket.org:renderapps/PannaPay.git'

    pod 'RACameraHelper', :git => 'https://github.com/bobbyren/RACameraHelper', :tag => '0.1.7'
#    pod 'RACameraHelper', :path => '../RACameraHelper'

    pod 'Crashlytics', '~> 3.10.7'
    pod 'Fabric', '~>1.7.11'

    pod 'FacebookSDK'
    pod 'FacebookSDK/LoginKit'
    pod 'FacebookSDK/ShareKit'
    pod 'FacebookSDK/PlacesKit'

    pod 'FBSDKMessengerShareKit'
    pod 'DateTools'
    pod 'Firebase/DynamicLinks'
    pod 'Firebase/Core'

    pod 'Batch'

    pod 'Stripe', '~> 14.0.0'

    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxOptional'

    target 'PannaTests' do
       inherit! :search_paths
    end
end

