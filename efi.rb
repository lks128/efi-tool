#!/usr/bin/env ruby

require 'plist'

def device_info(disk)
  Plist::parse_xml(`diskutil info -plist #{disk}`)
end

def efi_partitions(plist)
  parts = []
  plist['AllDisksAndPartitions'].select do |d|
     d['Partitions']
  end.each do |d|
    d['Partitions'].each do |p|
      p['DiskInfo'] = device_info(d['DeviceIdentifier'])
      p['PartitionInfo'] = device_info(p['DeviceIdentifier'])
      parts << p if p['Content'] == 'EFI'
    end
  end
  parts
end

puts
puts "Available EFI partitions:"
print "   loading..."
ep = efi_partitions Plist::parse_xml(`diskutil list -plist`)
print "\r"
ep.each_with_index do |p, i|
  if p['PartitionInfo']['MountPoint'] != ""
    puts "   #{i+1}) #{p['DeviceIdentifier']} (#{p['DiskInfo']['MediaName']}) mounted on #{p['PartitionInfo']['MountPoint']}"
  else
    puts "   #{i+1}) #{p['DeviceIdentifier']} (#{p['DiskInfo']['MediaName']})"
  end
end
puts "   Ctrl-C) exit"
puts
print "Select option: "

n = nil
begin
  n = gets.to_i
rescue SignalException => e
  puts "\rSelect option: exit"
  exit
rescue Exception => e
  puts e
  retry
end

partition_info = device_info ep[n.abs - 1]['DeviceIdentifier']

if partition_info['MountPoint'].empty?
  puts "Mounting partition #{partition_info['DeviceIdentifier']}..."
  `diskutil mount #{partition_info['DeviceIdentifier']}`
  partition_info = device_info ep[n.abs - 1]['DeviceIdentifier']
end

if n < 0
  puts "Unmounting #{partition_info['DeviceIdentifier']}..."
  `diskutil unmount #{partition_info['DeviceIdentifier']}`
else
  puts "Opening #{partition_info['MountPoint']} in Finder..."
  `open '#{partition_info['MountPoint']}'`
end

puts "Done"
