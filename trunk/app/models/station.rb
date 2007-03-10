# == Schema Information
# Schema version: 2
#
# Table name: stations
#
#  id         :integer       not null, primary key
#  name       :string(255)   
#  logo       :string(255)   
#  stream_url :string(255)   
#  epg_url    :string(255)   
#

#--
# Radio - a intranet based recorder of audio streams
# Copyright (C) 2006 GL Networks, Martin Rehfeld <martin.rehfeld@glnetworks.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#++

# define radio stations as recording sources
class Station < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_presence_of   :name
  validates_length_of     :name, :maximum => 255
  validates_length_of     :logo, :maximum => 255, :allow_nil => true
  validates_length_of     :stream_url, :maximum => 255
  validates_format_of     :stream_url, :with => /^...+:\/\/.+\..+/
  validates_length_of     :epg_url, :maximum => 255, :allow_nil => true
  validates_format_of     :epg_url, :with => /(^$|^...+:\/\/.+\..+)/
  
  # get all Stations ordered by name
  def self.find_all_ordered_by_name
    Station.find(:all, :order => 'name')
  end

  # get select list for all Stations
  def self.select_list
    self.find_all_ordered_by_name.collect {|s| [ s.name, s.id ] }
  end

  # check if logo image is available
  def logo_available?
    self.logo && self.logo =~ /.+\..+/ && File.readable?(File.join(RAILS_ROOT,'public','images','station_logos',self.logo))
  end
  
  # get relative image URL for Station logo image
  def logo_image_url
    ['station_logos',self.logo].join('/')
  end
  
end
