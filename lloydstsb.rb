#!/usr/bin/env ruby

=begin
    Copyright 2011 Martin Paul Eve (martin@martineve.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


require 'lloydstsb_credentials'

require 'rubygems'
require 'hpricot'

def execute_curl(cmd)
  `#{cmd}`
end

# Store some cookies for later
curl_cmd = %[curl -s "https://online.lloydstsb.co.uk/personal/logon/login.jsp"]
html = execute_curl(curl_cmd)

# Obtain the key that we need to POST along with our Username and Password
doc = Hpricot(html)
key = (doc/'input[@name=submitToken]').first.attributes['value']

# POST the key, userid and password
curl_cmd = %[curl -s -L -c"#{COOKIE_LOCATION}" --user-agent "User-Agent	Mozilla/5.0 (Ubuntu; X11; Linux x86_64; rv:8.0) Gecko/20100101 Firefox/8.0" -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/personal/primarylogin" -d"frmLogin:strCustomerLogin_userID=#{USERID}" -d"frmLogin:strCustomerLogin_pwd=#{PASSWORD}" -d"frmLogin:loginRemember=on" -d"frmLogin=frmLogin" -d"submitToken=#{key}" -d"target=" -d"hasJS=true" -d"frmLogin:btnLogin1="]
html = execute_curl(curl_cmd)

# Obtain the three characters from our memorable info that we need to POST
doc = Hpricot(html)

position_of_char1 = 0
position_of_char2 = 0
position_of_char3 = 0

(doc/"form").each do |labels|
   labels = (labels/"label").inner_text.split(':')
   labels[0] = labels[0].gsub /[^0-9]/, ''
   labels[1] = labels[1].gsub /[^0-9]/, ''
   labels[2] = labels[2].gsub /[^0-9]/, ''

   position_of_char1 = Integer(labels[0])
   position_of_char2 = Integer(labels[1])
   position_of_char3 = Integer(labels[2])
end

char1 = MEMORABLE.split('')[position_of_char1 - 1]
char2 = MEMORABLE.split('')[position_of_char2 - 1]
char3 = MEMORABLE.split('')[position_of_char3 - 1]

key = (doc/'input[@name=submitToken]').first.attributes['value']

# POST our memorable info
curl_cmd = %[curl -s -L -H "application/x-www-form-urlencoded" --user-agent "User-Agent	Mozilla/5.0 (Ubuntu; X11; Linux x86_64; rv:8.0) Gecko/20100101 Firefox/8.0" -e "https://secure2.lloydstsb.co.uk/personal/a/logon/entermemorableinformation.jsp;auto" -c"#{COOKIE_LOCATION}" -b"#{COOKIE_LOCATION}" "https://secure2.lloydstsb.co.uk/personal/a/logon/entermemorableinformation.jsp"  -d "frmentermemorableinformation1%3AstrEnterMemorableInformation_memInfo1=%26nbsp%3B#{char1}&frmentermemorableinformation1%3AstrEnterMemorableInformation_memInfo2=%26nbsp%3B#{char2}&frmentermemorableinformation1%3AstrEnterMemorableInformation_memInfo3=%26nbsp%3B#{char3}&frmentermemorableinformation1%3AbtnContinue.x=26&frmentermemorableinformation1%3AbtnContinue.y=10&frmentermemorableinformation1=frmentermemorableinformation1&submitToken=#{key}"]
html = execute_curl(curl_cmd)

doc = Hpricot(html)
balances = Array.new
x = 0
(doc/"ul").each do |all|
   balancer = (all/'p[@class=balance]').each do |b|
      balances[x] = b.inner_text
      x = x + 1
   end
end

x = 0
acc_names = Array.new

(doc/'a[@title~=latest]').each do |ele|
   if ele != nil
       acc_names[x] = ele.inner_text
       x = x + 1
   end
end

got_to = 0
x = 0
y = 0
acc_balances = Array.new

acc_names.each do |acc|
   balances.each do |balance|
      if x < got_to
         x = x + 1
      else
         if balance != nil && balance != "Balance" && balance != " "
            acc_balances[y] = balance.gsub "Balance", ""
            acc_balances[y] = acc_balances[y].gsub /\s/, ""
            y = y + 1
         end
         x = x + 1
      end
   end
end

(0..acc_names.count - 1).each do |counter|
   print "#{acc_names[counter]} : #{acc_balances[counter]}\n"
end

# Remove the cookie
`rm #{COOKIE_LOCATION}`
