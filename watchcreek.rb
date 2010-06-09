#!/usr/bin/env ruby

 # =====================================================================================
 # = Fetch the current flow levels on Tumalo Creek and alert above a certain threshold =
 # =====================================================================================
 
 require 'open-uri'
 require 'rubygems'
 require 'hpricot'
 require 'tmail'
 require 'net/smtp'
 
 URL = "http://www.usbr.gov/pn-bin/rtgraph.pl/?sta=TUMO&parm=Q"
 MAIL_TO = "matt@thekerns.net"
 MAIL_CC = ""
 MAIL_FROM = "riverkeeper@thekerns.net"
 SUBJECT = "*** Neighborhood River Watch ***"
 
 pattern = /Last Value =\s+(\d+\.\d+)/
 severities = [{:label => "over flood stage", :value => 350}, {:label => "at flood stage", :value =>  250}, {:label => "getting fucking high", :value => 130}]
 
 
 open(URL) do |f|
   puts "opening url"
   doc = Hpricot(f)
   res = doc.at("center").inner_html
   #puts "result is #{res}"
   res =~ pattern
   puts "value is #{$1.to_f}"
   severities.each do |s|
     puts "testing against value: #{s[:value].to_f}"
     if $1.to_f >= s[:value].to_f 
       puts "River is #{s[:label]}"
       mail = TMail::Mail.new
       message = "At #{$1} CFS creek flow is #{s[:label]}. \n\nSee #{URL} for details."
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