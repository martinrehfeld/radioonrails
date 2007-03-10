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


module RecordingsHelper

  # get proper text for a Recording's state
  def recording_state_text(recording)
    if recording.scheduled?
      _('scheduled')
    elsif recording.recording?
      _('recording in progress...')
    elsif recording.aborted?
      _('recording is being aborted...')
    elsif recording.done?
      _('done')
    elsif recording.missed?
      _('missed')
    else
      _('unknown state :-(')
    end
  end

  # get name as image tag or text for a Station
  def recording_station_name_or_logo(station)
    if station.logo_available?
      image_tag(station.logo_image_url)
    else
      station ? station.name : _('unknown station')
    end
  end
  
  # get name as image tag or text for a Station
  def recording_info_text(recording)
    text = ''
    starttime_to_s = recording.starttime.strftime(_('DATE_FMT') + ' ' + _('at') + ' ' + _('TIME_FMT')) + ' ' + _("o'clock")
    if recording.done?
      text = _('recorded on') + " #{starttime_to_s}"
    elsif recording.recording? || recording.aborted?
      text = _('recording since') + " #{starttime_to_s}"
    elsif recording.scheduled? && recording.about_to_begin?
      text = _('will be recorded on') + " #{starttime_to_s}"
    elsif recording.missed?
      text = _('could not be recorded on') + " #{starttime_to_s} " + _('(due to technical problems)')
    end
    
    if recording.recording?
      text += ' ' + _('until') + " #{recording.endtime.strftime(_('TIME_FMT'))} " + _("o'clock")
    elsif recording.aborted?
      text += ' ' + _('and is being finished')
    end
    
    unless recording.missed?
      text += ' ' + _('on') + ' '
      text += recording_station_name_or_logo(recording.station)
    end
    
    text
  end

  # get object tag for inline flash MP3 player  
  def inline_mp3_player(mp3_file_relative_url, background_color = "C5E6F6")
    player = url_for_path('flash','dewplayer.swf')
    mp3_file = url_for_path(mp3_file_relative_url)
    %(<object type="application/x-shockwave-flash" data="#{player}?mp3=#{mp3_file}&amp;bgcolor=#{background_color}" width="200" height="20"><param name="movie" value="#{player}?mp3=#{mp3_file}&amp;bgcolor=#{background_color}" /></object>)
  end
  
  # add protocol, hostname and port to partial url path
  def full_url(*url_path_elements)
    "#{request.protocol}#{request.port == request.standard_port ? request.host : request.host_with_port}#{url_for_path(url_path_elements)}"
  end

  # build onclick handler for a recording list row
  # * set all rows to class hoverable
  # * set clicked row additionnally to class active
  # * fire AJAX request to UserGuiController.select_recording(recording_id)
  def recordings_list_row_onclick_handler(recording)
    code = <<-JAVASCRIPT
      $$('#recording_list_content table tr.active').each(function(o) { o.className = 'hoverable' });
      this.className = 'hoverable active';
      #{remote_function_with_busy 'selected_recording_busy_indicator',
                                  :url => recording_path(recording), :method => :get };
      return false;
    JAVASCRIPT
    
    code.collect(&:strip).join
  end

end

module ActionView
  module Helpers
    module JavaScriptMacrosHelper
      # extend the standard Rails in_place_editor with additional options to be passed to Ajax.InPlaceEditor:
      # - savingText (already in edge rails)
      # - clickToEditText (already in edge rails)
      # - highlightcolor (patch pending, ticket #4336)
      # - highlightendcolor (patch pending, ticket #4336)
      def in_place_editor(field_id, options = {})
        function =  "new Ajax.InPlaceEditor("
        function << "'#{field_id}', "
        function << "'#{url_for(options[:url])}'"

        js_options = {}
        js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
        js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
        js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
        js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
        js_options['rows'] = options[:rows] if options[:rows]
        js_options['cols'] = options[:cols] if options[:cols]
        js_options['size'] = options[:size] if options[:size]
        js_options['externalControl'] = %('#{options[:external_control]}') if options[:external_control]
        js_options['loadTextURL'] = %('#{url_for options[:load_text_url]}') if options[:load_text_url]
        js_options['ajaxOptions'] = options[:options] if options[:options]
        js_options['evalScripts'] = options[:script] if options[:script]
        js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
        js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
        js_options['highlightcolor'] = %('#{options[:highlightcolor]}') if options[:highlightcolor]
        js_options['highlightendcolor'] = %('#{options[:highlightendcolor]}') if options[:highlightendcolor]

        function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

        function << ')'

        javascript_tag(function)
      end
    end
  end
end      
