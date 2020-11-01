# encoding: utf-8
# frozen_string_literal: true
require 'rake/clean'

# Cross-platform way of finding an executable in the $PATH.
#   
#   which('ruby') #=> /usr/bin/ruby
#   See: https://stackoverflow.com/a/5471032
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

# FastSpin renmed to FlexSpin in version 5.0, autodetect which to use
HAVE_FLEXSPIN = !!which("flexspin")
HAVE_FASTSPIN = !!which("fastspin")
FASTSPIN_NAME = ENV['FASTSPIN_NAME'] || ((HAVE_FASTSPIN && !HAVE_FLEXSPIN) ? "fastspin" : "flexspin")
  

FCACHE_SIZE = 86
FASTSPINOPTS = "-O1,inline-single,loop-reduce -Werror --fcache=#{FCACHE_SIZE} -l"
task :default => :build_sd

CLEAN.include ["*.binary","*.BIN","*.BI2","*.dat"]
CLOBBER.include ["*.lst","*.pasm"]

XASM_DATS = FileList["*_xasm.spin"].map{|n|n.gsub('_xasm.spin','.dat')}

def loadopts
   ENV['LOADOPTS'] or raise "LOADOPTS not defined!"
end

rule '.dat' => '.spin' do |t|
  sh "#{FASTSPIN_NAME} #{FASTSPINOPTS} -c #{t.source}"
end

file 'hexagon.binary' => ['hexagon.spin',*XASM_DATS] do |t| # TODO: dependency shit and stuff
  sh "#{FASTSPIN_NAME} #{FASTSPINOPTS} #{t.source}"
end

file 'hexagon_boot.binary' => 'hexagon_boot.spin' do |t| # TODO: dependency shit and stuff
  #sh "homespun #{HOMESPUNOPTS} #{t.source}"
  sh "#{FASTSPIN_NAME} #{FASTSPINOPTS} #{t.source}"
end

def copyfile(*args)
  file *args do |t|
    puts "Copying #{t.source} to #{t.name}"
    FileUtils.copy t.source,t.name
    #sh "cp #{t.source} #{t.name}"
  end
end

copyfile 'HEXAGON.BI2' => 'hexagon.binary'
copyfile 'HEXAGON.BIN' => 'hexagon_boot.binary'

task :build_sd => %w[HEXAGON.BIN HEXAGON.BI2]
task :build_nosd => %w[hexagon.binary]

task :run_nosd => :build_nosd do |t|
  sh "proploader #{loadopts} hexagon.binary"
end

task :run_sd => :build_sd do |t|
  sh "proploader #{loadopts} -f HEXAGON.BI2"
  sh "proploader #{loadopts} hexagon_boot.binary"
  
end

