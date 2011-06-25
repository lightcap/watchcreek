#!/usr/bin/env ruby

# =====================================================================================
# = Fetch the current flow levels on Tumalo Creek and alert above a certain threshold =
# =====================================================================================
if $0 == __FILE__

  require 'open-uri'
  require 'rubygems'
  require 'hpricot'
  require 'tmail'
  require 'net/smtp'

  URL = "http://www.usbr.gov/pn-bin/rtgraph.pl/?sta=TUMO&parm=Q"
  MAIL_TO = "matt@thekerns.net"
  MAIL_CC = "error_glory@hotmail.com"
  MAIL_FROM = "riverkeeper@thekerns.net"
  SUBJECT = "*** Neighborhood River Watch ***"
  PATTERN = /Last Value =\s+(\d+\.\d+)/
  SEVERITIES = [{:label => "over flood stage", :value => 350}, {:label => "at flood stage", :value =>  250}, {:label => "getting fucking high", :value => 130}]
  TMPDIR = "/tmp"
  
  def extract_cfs(doc)
    res = doc.at("center").inner_html
    #puts "result is #{res}"
    res =~ PATTERN
    puts "value is #{$1.to_f}"
    $1.to_f
  end
  
  def last_cfs
    File.open(File.join(TMPDIR, 'watchcreek'), 'r') do |f|
      @last_cfs = f.readline
    end
    return @last_cfs.to_f
  end

  open(URL) do |f|
    puts "opening url"
    @doc = Hpricot(f)
  end
  @cfs = extract_cfs(@doc)
  @last_cfs = last_cfs
  File.open(File.join(TMPDIR, 'watchcreek'), 'w') do |f|
    f.puts @cfs
  end
  exit if @last_cfs >= @cfs
  
  SEVERITIES.each do |s|
    puts "testing against value: #{s[:value].to_f}"
    if @cfs.to_f >= s[:value].to_f
      mail = TMail::Mail.new
      message = "At #{@cfs} CFS creek flow is #{s[:label]}. \n\nSee #{URL} for details."
      mail.body = message
      mail.to = MAIL_TO
      mail.from = MAIL_FROM
      mail.cc = MAIL_CC
      mail.subject = SUBJECT
      mail.date = Time.now
      puts "Mail body is: \n #{mail.body}"
      Net::SMTP.start('localhost', 25) do |smtp|
        smtp.send_message(mail.to_s, mail.from, mail.to)
      end
      break
    end
  end
end

