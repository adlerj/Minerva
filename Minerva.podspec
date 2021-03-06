Pod::Spec.new do |s|
  s.name         = "Minerva"
  s.version      = "2.2.0"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.summary      = "This framework is a lightweight wrapper around IGListKit."

  s.homepage     = "https://github.com/OptimizeFitness/Minerva"
  s.author       = { "Joe Laws" => "joe@optimize.fitness" }

  s.source       = { :git => "https://github.com/OptimizeFitness/Minerva.git", :tag => s.version }

  s.default_subspecs = 'Core', 'Cells', 'Navigation', 'Swipeable'

  s.requires_arc               = true
  s.swift_versions             = '5.0'

  s.ios.deployment_target      = '11.0'
  s.ios.frameworks             = 'Foundation', 'UIKit'

  s.subspec 'Cells' do |ss|
    ss.source_files = 'Source/Cells/*.swift'

    ss.ios.deployment_target      = '11.0'
    ss.ios.frameworks             = 'Foundation', 'UIKit'

    ss.dependency 'Minerva/Core'

    ss.dependency 'IGListKit', '~> 3.4.0'
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'Source/Core/**/*.swift'

    ss.ios.deployment_target      = '11.0'
    ss.ios.frameworks             = 'Foundation', 'UIKit'

    ss.dependency 'IGListKit', '~> 3.4.0'
  end

  s.subspec 'Navigation' do |ss|
    ss.source_files = 'Source/Navigation/*.swift'

    ss.ios.deployment_target      = '11.0'
    ss.ios.frameworks             = 'Foundation', 'UIKit'

    ss.dependency 'Minerva/Core'

    ss.dependency 'IGListKit', '~> 3.4.0'
  end

  s.subspec 'Swipeable' do |ss|
    ss.source_files = 'Source/Swipeable/*.swift'

    ss.ios.deployment_target      = '11.0'
    ss.ios.frameworks             = 'Foundation', 'UIKit'

    ss.dependency 'Minerva/Core'
    ss.dependency 'Minerva/Cells'

    ss.dependency 'IGListKit', '~> 3.4.0'
    ss.dependency 'SwipeCellKit', '~> 2.7.0'
  end
end
