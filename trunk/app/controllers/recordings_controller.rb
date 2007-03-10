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

# Controller for main GUI
class RecordingsController < ApplicationController

  # starting page, table list, XML-Export & Podcast RSS
  # GET /recordings (HTTP, XHR)
  # GET /recordings.xml
  # GET /recordings.rss -> Podcast RSS
  def index
    respond_to do |format|
      format.html { find_recordings } # index.rhtml
      format.js   { find_recordings; render :partial => 'list' }
      format.xml  { render :xml => Recording.find_all_including_station.to_xml(:except => [:station_id, :recorder], :include => :station) }
      format.rss  { @recordings = Recording.find_all_in_done_state; render :action => 'podcast', :layout => false }
    end
  end

  # get single recording as AJAX partial, MP3 file & XML export
  # GET /recordings/1 (XHR)
  # GET /recordings/1.mp3
  # GET /recordings/1.xml
  def show(recording_id = params[:id])
    respond_to do |format|
      begin
        @recording = Recording.find(recording_id, :include => :station) # might throw RecordNotFound
      rescue ActiveRecord::RecordNotFound
        format.js  { recording_not_found(recording_id); rerender_single_recording }
        format.mp3 { render_not_found_error }
        format.xml { render :xml => [].to_xml, :status => 404 }
      else
        format.js  { session[:active_recording_id] = @recording.id; rerender_single_recording }
        format.mp3 do
          if @recording.done?
            # TODO: re-test: with :stream => true I got streaming.rb:71: warning: syswrite for buffered IO in production environment
            send_file @recording.filename, :filename => @recording.suggested_filename, :stream => false
          else
            render_not_found_error
          end
        end
        format.xml { render :xml => @recording.to_xml(:except => [:station_id, :recorder], :include => :station) }
      end
    end
  end

  # show new recordings form
  # GET /recordings/new (XHR)
  def new
    @recording = Recording.new
    @stations = Station.find_all_ordered_by_name

    respond_to do |format|
      format.js do
        # show form (possibly with error markers if save failed)
        render :update do |page|
          page[:new_recording_form].replace_html :partial => 'new'
          page << "if(!Element.visible('new_recording_form')) {"
            page[:new_recording_form].visual_effect :slide_down, :duration => 0.5
          page << "}"
        end
      end
    end
  end

  # create new recording from form
  # POST /recordings (XHR)
  def create(recording_attributes = params[:recording])
    ensure_recording_title!(recording_attributes)
    @recording = Recording.new(recording_attributes)

    respond_to do |format|
      format.js do
        if @recording.save
          # successful save -> hide form and update view
          find_recordings
          render :update do |page|
            page[:recording_list_content].replace_html :partial => 'list'
            page.visual_effect :highlight, "recording_table_row_#{@recording.id}", :startcolor => "'#ffd2e8'", :endcolor => "'#C5E6F6'"
            page.delay(1.second) { page[:new_recording_form].visual_effect :slide_up, :duration => 0.5 }
          end
        else
          render(:update) {|page| page[:new_recording_form].replace_html :partial => 'new' }
        end
      end
    end
  end

  # update recording from form
  # PUT /recordings/1 (XHR)
  def update(recording_id = params[:id], recording_attributes = params[:recording])
    respond_to do |format|
      format.js do
        begin
          @recording = Recording.find(recording_id) # might throw RecordNotFound
    
          # check if the recording is about to begin, if so, only allow the title to be changed (see set_recording_title)
          if @recording.about_to_begin? && !(recording_attributes[:title] && recording_attributes.length == 1)
            @message = _('The recording will start soon and cannot be changed anymore!')
          else
            ensure_recording_title!(recording_attributes)
            if @recording.update_attributes(recording_attributes)
              # update suceeded -> "redirect" to list_recordings
              find_recordings
              render :update do |page|
                page[:recording_list_content].replace_html :partial => 'list'
                page[:selected_recording_content].replace_html :partial => 'show'
              end
              return
            end
          end
        rescue ActiveRecord::RecordNotFound
          recording_not_found(recording_id)
        end
        rerender_single_recording
      end
    end
  end

  # destroy single recording
  # DELETE /recordings/1 (XHR)
  def destroy(recording_id = params[:id])
    begin
      @recording = Recording.find(recording_id) # might throw RecordNotFound
      @recording.destroy
    rescue ActiveRecord::RecordNotFound
      # ignore RecordNotFound exceptions
    end

    respond_to do |format|
      format.js { reset_active_recording; rerender_single_recording }
    end
  end

  # set the recording title (used by inline_edit_field)
  def set_recording_title
    # transform params hash for use with update action
    params[:recording] = { :title => params.delete(:value) }
    update
  end  

  # abort a currently running Recording
  # PUT recordings/1;abort (XHR)
  def abort(recording_id = params[:id])
    respond_to do |format|
      format.js do
        begin
          @recording = Recording.find(recording_id) # might throw RecordNotFound
          @recording.abort!
        rescue ActiveRecord::RecordNotFound
          recording_not_found(recording_id)
        rescue RecordingExceptions::InvalidStateChange
          # ignore InvalidStateChange -> Recording must be already done
        ensure
          rerender_single_recording
        end
      end
    end
  end

  private

  # clear active recording in session and set message
  def reset_active_recording
    session[:active_recording_id] = nil
    @message = _('nothing selected...')
  end
  
  # find Recordings and set instance variables for recording list and active recording
  def find_recordings
    @recordings = Recording.find_all_including_station
    saved_active_recording_id = session[:active_recording_id]
    if saved_active_recording_id
      valid_active_recording = @recordings.detect {|r| r.id == saved_active_recording_id }
      # set @recording to active recording unless already set otherwise
      @recording ||= valid_active_recording
    end
    
    # reset session if saved active_recording_id does no longer exist
    reset_active_recording unless valid_active_recording
  end
  
  # make sure at least a default title is provided in a Recording's attributes
  def ensure_recording_title!(attributes)
    attributes ||= {}
    attributes[:title] = _('untitled recording') if attributes[:title].blank?
  end
  
  # set instance variables and session for not found errors
  def recording_not_found(recording_id)
    @message = _('Recording could not be found!')
    session[:active_recording_id] = nil
    @recording = Recording.new
    @recording.id = recording_id
    @recording.freeze
  end
  
  # render a "404 Not Found" HTML page
  def render_not_found_error
    response.headers['Content-Type'] = Mime::HTML.to_s
    render :text => '<h1>404 Not Found</h1>', :status => 404, :layout => true
  end
  
  # rerender all displayed content for a single Recording:
  # * the matching row in the Recordings table will be redrawn
  # * if a Recording was destroyed let the table row disappear
  # * refresh the display of the selected Recording
  def rerender_single_recording
    render :update do |page|
      if @recording && !@recording.frozen?
        # refresh the selected recording list row
        page["recording_table_row_#{@recording.id}"].replace :partial => 'list_row', :object => @recording
      elsif @recording && @recording.frozen?
        # if the recording was destroyed, remove it from the list
        page.visual_effect :switch_off, "recording_table_row_#{@recording.id}"
      end

      # refresh the selected recording content area
      page[:selected_recording_content].replace_html :partial => 'show'
    end
  end

end
