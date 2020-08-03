# encoding: utf-8
# frozen_string_literal: true

# This program inserts VU data into TinySDDA subcode slots

# TODO: fix audio LPF (LPF before absolute), change VU LPF (faster attack)

AUDIO_FILTER_CONSTANT = ((1/32_000r)/(1/150r)).to_f # 10 Hz LPF for source audio
VU_FILTER_CONSTANT = ((256/32_000r)/(1/10r)).to_f # 10 HZ LPF for VU itself
I2FCONSTANT = 0x2000.to_f

raise "Need exactly 2 parameters" if ARGV.size != 2

infile = File.open(ARGV[0],'rb')
outfile = File.open(ARGV[1],'wb')

maxvu = 0
alpf = 0.0
vulpf = 0.0

while blk = infile.read(256)
  blk.ljust(256,?\0)
  vu = (blk.unpack('s<*').each_slice(2).map{|(l,r)|alpf += ((l.abs+r.abs).to_f-alpf)*AUDIO_FILTER_CONSTANT}.sum / I2FCONSTANT)
  vulpf += (vu-vulpf) * VU_FILTER_CONSTANT
  vub = vulpf.to_i
  raise "VU byte out of range? (#{vub})" unless (0...256).include? vub
  blk[0] = vub.chr
  outfile.write(blk)
  maxvu = vub unless vub <= maxvu
end

puts "Maximum recorded VU value: #{maxvu}"