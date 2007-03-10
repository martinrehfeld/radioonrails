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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # get link_to_remote tag with added busy indicator callbacks
  def link_to_remote_with_busy(name, busy_indicator, options = {}, html_options = {})
    options.merge!(busy_indicator_callbacks(busy_indicator))
    link_to_remote(name, options, html_options)
  end
  
  # get remote_function tag with added busy indicator callbacks
  def remote_function_with_busy(busy_indicator, options = {})
    options.merge!(busy_indicator_callbacks(busy_indicator))
    remote_function(options)
  end

  # get form_remote tag with added busy indicator callbacks
  def form_remote_tag_with_busy(busy_indicator, options = {}, &block)
    options.merge!(busy_indicator_callbacks(busy_indicator))
    form_remote_tag(options, &block)
  end
  
  # get periodically_call_remote tag with added busy indicator callbacks
  def periodically_call_remote_with_busy(busy_indicator, options = {})
    options.merge!(busy_indicator_callbacks(busy_indicator))
    periodically_call_remote(options)
  end

  # get relative URL to asset specified by an array of path elements
  def url_for_path(*path_elements)
    [request.relative_url_root.to_s,path_elements].join('/').gsub(/\/\//,'/')
  end
  
  private
  
  # add busy indicator callbacks to options hash
  def busy_indicator_callbacks(busy_indicator)
    busy_indicators = [busy_indicator].flatten
    loading_actions = busy_indicators.collect {|element| "$('#{element}').style.visibility = 'visible'" }
    complete_actions = busy_indicators.collect {|element| "$('#{element}').style.visibility = 'hidden'" }

    { :loading => loading_actions.join(';'), :complete => complete_actions.join(';') }
  end

end
