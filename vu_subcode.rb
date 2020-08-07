# encoding: utf-8
# frozen_string_literal: true

# This program inserts VU data into TinySDDA subcode slots

raise "Need exactly 3 parameters" if ARGV.size != 3

case ARGV[2].downcase
  when 'normal'
    AUDIO_FILTER_CONSTANT = ((1/32_000r)*260.0).to_f # 260 Hz LPF for source audio
    VU_FILTER_CONSTANT1 = ((64/32_000r)*0.5).to_f # 1 HZ bandpass low for VU itself
    VU_FILTER_CONSTANT2_ATT = ((64/32_000r)*32.0).to_f # 40 HZ bandpass high for VU itself when attacking
    VU_FILTER_CONSTANT2_REL = ((64/32_000r)*8.0).to_f # 10 HZ bandpass high for VU itself when releasing
    I2FCONSTANT = 0xA00.to_f
  when 'final'
    AUDIO_FILTER_CONSTANT = ((1/32_000r)*500.0).to_f # 500 Hz LPF for source audio
    VU_FILTER_CONSTANT1 = ((64/32_000r)*0.05).to_f # 0.2 HZ bandpass low for VU itself
    VU_FILTER_CONSTANT2_ATT = ((64/32_000r)*5.0).to_f # 10 HZ bandpass high for VU itself when attacking
    VU_FILTER_CONSTANT2_REL = ((64/32_000r)*2.0).to_f # 5 HZ bandpass high for VU itself when releasing
    I2FCONSTANT = 0xA00.to_f
   else raise "Unknown filter setting"
end


infile = File.open(ARGV[0],'rb')
outfile = File.open(ARGV[1],'wb')

maxvu = 0
alpf = 0.0
vulpf1 = 0.0
vulpf2 = 0.0

while blk = infile.read(256)
  blk.ljust(256,?\0)
  vu = (blk.unpack('s<*').each_slice(2).map{|(l,r)|(alpf += ((l+r).to_f-alpf)*AUDIO_FILTER_CONSTANT).abs}.sum / I2FCONSTANT)
  vulpf1 += (vu-vulpf1) * VU_FILTER_CONSTANT1
  vulpf2 += (vu-vulpf2) * (vu>vulpf2 ? VU_FILTER_CONSTANT2_ATT : VU_FILTER_CONSTANT2_REL)
  vub = (vulpf2 - vulpf1).to_i # Bandpass magic
  vub = 0 if vub < 0
  raise "VU byte out of range? (#{vub})" unless (0...256).include? vub
  blk[0] = vub.chr
  outfile.write(blk)
  maxvu = vub unless vub <= maxvu
end

puts "Maximum recorded VU value: #{maxvu}"