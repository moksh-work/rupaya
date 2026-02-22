#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/rsingh/Documents/Projects/rupaya/ios/RUPAYA.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'RUPAYA' }

files = [
  'RUPAYA/Features/Home/EnhancedHomeView.swift',
  'RUPAYA/Features/Home/EnhancedHomeViewModel.swift',
  'RUPAYA/Features/Analytics/InsightsView.swift',
  'RUPAYA/Features/Analytics/AnalyticsViewModel.swift',
  'RUPAYA/Features/Transactions/AddTransactionView.swift',
  'RUPAYA/Features/Transactions/AddTransactionViewModel.swift',
  'RUPAYA/Features/Transactions/TransactionsFullView.swift',
  'RUPAYA/Features/Transactions/TransactionsViewModel.swift',
  'RUPAYA/Features/Accounts/AccountsTabView.swift',
  'RUPAYA/Features/Accounts/AccountsViewModel.swift',
  'RUPAYA/Features/Settings/SettingsTabView.swift',
  'RUPAYA/Features/Settings/SecuritySettingsView.swift',
  'RUPAYA/Features/Settings/PreferencesView.swift',
  'RUPAYA/Features/Settings/AppearanceSettingsView.swift',
  'RUPAYA/Features/Settings/DataManagementView.swift',
  'RUPAYA/Features/Settings/AboutView.swift',
  'RUPAYA/AppState.swift'
]

files.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  next unless File.exist?(full_path)
  
  file_ref = project.main_group.find_file_by_path(file_path)
  next if file_ref
  
  parts = file_path.split('/')
  group = project.main_group.find_subpath(parts[0..-2].join('/'), true)
  file_ref = group.new_reference(full_path)
  target.add_file_references([file_ref])
  puts "Added: #{file_path}"
end

project.save
puts "\n✅ All files added to Xcode project"
