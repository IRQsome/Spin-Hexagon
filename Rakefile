# encoding: utf-8
# frozen_string_literal: true
require 'rake/clean'

FCACHE_SIZE = 86
FASTSPINOPTS = "-O1,inline-single,loop-reduce --fcache=#{FCACHE_SIZE} -l"
HOMESPUNOPTS = "-b"
task :default => :build_sd

CLEAN.include ["*.binary","*.BIN","*.BI2","*.dat"]
CLOBBER.include ["*.lst","*.pasm"]

XASM_DATS = FileList["*_xasm.spin"].map{|n|n.gsub('_xasm.spin','.dat')}

def loadopts
   ENV['LOADOPTS'] or raise "LOADOPTS not defined!"
end

rule '.dat' => '.spin' do |t|
  sh "fastspin -c #{t.source}"
end

file 'hexagon.binary' => ['hexagon.spin',*XASM_DATS] do |t| # TODO: dependency shit and stuff
  sh "fastspin #{FASTSPINOPTS} #{t.source}"
end

file 'hexagon_boot.binary' => 'hexagon_boot.spin' do |t| # TODO: dependency shit and stuff
  #sh "homespun #{HOMESPUNOPTS} #{t.source}"
  sh "fastspin #{FASTSPINOPTS} #{t.source}"
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

