# == Schema Information
# Schema version: 2
#
# Table name: recordings
#
#  id         :integer       not null, primary key
#  title      :string(255)   
#  starttime  :datetime      
#  duration   :integer       
#  station_id :integer       
#  recorder   :text          
#  state      :string(255)   
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

require 'recorder'
require 'mp3info'

# Custom Exceptions for the Recording class
module RecordingExceptions
  # Exception to be invoked on illegal state changes
  class InvalidStateChange < RuntimeError
  end
end

# keep track of Recordings and their state
class Recording < ActiveRecord::Base

  belongs_to :station
  serialize  :recorder
  
  validates_length_of       :title, :within => 1..255
  validates_numericality_of :duration

  before_destroy :delete_recorded_file # make sure deletion also removes corresponding output file

  # Constants for valid Recording states
  RECORDING_STATE_SCHEDULED = :scheduled
  RECORDING_STATE_MISSED    = :missed
  RECORDING_STATE_RECORDING = :recording
  RECORDING_STATE_ABORTED   = :aborted
  RECORDING_STATE_DONE      = :done
  RECORDING_STATES_DELETABLE = [RECORDING_STATE_SCHEDULED,RECORDING_STATE_MISSED,RECORDING_STATE_DONE]
  RECORDING_STATES_TO_BE_SCHEDULED = [RECORDING_STATE_SCHEDULED,RECORDING_STATE_RECORDING,RECORDING_STATE_ABORTED]

  # set defaults for new Recordings
  def initialize(attributes = {})
    attributes[:state] = RECORDING_STATE_SCHEDULED.to_s unless attributes[:state]
    attributes[:starttime] = Time.now unless attributes[:starttime]

    # new Recordings may only be created in SCHEDULED state
    raise RecordingExceptions::InvalidStateChange, 'Recordings may only be created in SCHEDULED state' unless attributes[:state] == RECORDING_STATE_SCHEDULED.to_s

    super
  end

  # find all Recordings in state DONE ordered by starttime descending and include the Station
  def self.find_all_in_done_state
    Recording.find(:all, :conditions => ['state = ?',RECORDING_STATE_DONE.to_s], :include => :station, :order => 'starttime desc')
  end
  
  # find all Recordings ordered by starttime descending and include the Station
  def self.find_all_including_station
    Recording.find(:all, :include => :station, :order => 'starttime desc')
  end
  
  # find all Recordings with a relevant state for scheduling and include the Station
  def self.find_all_to_be_scheduled
    relevant_states = RECORDING_STATES_TO_BE_SCHEDULED.collect(&:to_s)
    Recording.find(:all, :conditions => ['state IN (?)',relevant_states], :include => :station)
  end

  # schedule the recordings according to time and state
  def self.schedule_recordings
    Recording.find_all_to_be_scheduled.each do |r|
      case r.state.intern
      when RECORDING_STATE_SCHEDULED
        if r.starttime < 60.seconds.from_now && Time.now < r.endtime
          r.record!
        elsif Time.now >= r.endtime
          r.missed!
        end
      when RECORDING_STATE_RECORDING
        r.done! if Time.now > r.endtime
      when RECORDING_STATE_ABORTED
        r.done!
      end
    end
  end
  
  # return the scheduled end time of the recording
  def endtime
    self.starttime + self.duration.minutes
  end

  # return the on-disk-filename of the recording
  def filename
    File.readable?(self.storage_file) ? self.storage_file : nil
  end
  
  # return a suggested download filename for the recording
  def suggested_filename
    return nil unless self.station && self.title
    self.starttime.strftime(_('FILENAME_DATETIME_FMT')) +
    "_#{sanitize_for_filename(self.station.name)}_" +
    truncate(sanitize_for_filename(self.title)) + '.mp3'
  end

  # get Station name if applicable
  def station_name
    self.station ? self.station.name : _('unknown station')
  end

  # add ID3 tag to the recorded file
  def tag_file!
    to_iso = Iconv.new('iso-8859-1','utf-8')
    begin
      Mp3Info.open(self.filename) do |mp3|
        mp3.tag.title = to_iso.iconv(self.title)
        mp3.tag.artist = to_iso.iconv(self.station_name)
        mp3.tag.album = to_iso.iconv(_('MP3_ALBUM_NAME'))
        mp3.tag.year = self.starttime.year
#        mp3.tag2.options[:lang] = "GER" # Internationalization prob!
        mp3.tag.comments = to_iso.iconv(_('Recorded at') + ' ' + self.starttime.strftime(_('DATE_FMT') + ' ' + _('at') + ' ' + _('TIME_FMT')) + ' ' + _('on') + ' ' + self.station_name)
      end
      true
    rescue
      # ignore any errors
      logger.warn "File '#{self.filename}' could not be tagged with Mp3Info."
      false
    end
  end

  # switch to RECORDING state
  def record!
    raise RecordingExceptions::InvalidStateChange unless [RECORDING_STATE_SCHEDULED].include?(self.state.intern)
    self.recorder = Recorder.new(self.station.stream_url,self.storage_file)
    self.state = RECORDING_STATE_RECORDING.to_s
    self.save!
  end

  # switch to DONE state
  def done!
    raise RecordingExceptions::InvalidStateChange unless [RECORDING_STATE_RECORDING,RECORDING_STATE_ABORTED].include?(self.state.intern)
    self.recorder.end_recording
    self.state = RECORDING_STATE_DONE.to_s
    self.save!
    self.tag_file!
  end

  # switch to ABORT state
  def abort!
    raise RecordingExceptions::InvalidStateChange unless [RECORDING_STATE_RECORDING].include?(self.state.intern)
    self.state = RECORDING_STATE_ABORTED.to_s
    self.save!
  end

  # switch to MISSED state
  def missed!
    raise RecordingExceptions::InvalidStateChange unless [RECORDING_STATE_SCHEDULED].include?(self.state.intern)
    self.state = RECORDING_STATE_MISSED.to_s
    self.save!
  end
  
  # make sure Recording is allowed state for destruction
  def destroy
    raise RecordingExceptions::InvalidStateChange unless [RECORDING_STATE_SCHEDULED,RECORDING_STATE_MISSED,RECORDING_STATE_DONE].include?(self.state.intern)
    super
  end
  
  # is the recording in SCHEDULED state?
  def scheduled?
    self.state.intern == RECORDING_STATE_SCHEDULED
  end
  
  # is the recording in MISSED state?
  def missed?
    self.state.intern == RECORDING_STATE_MISSED
  end
  
  # is the recording in RECORDING state?
  def recording?
    self.state.intern == RECORDING_STATE_RECORDING
  end
  
  # is the recording in ABORTED state?
  def aborted?
    self.state.intern == RECORDING_STATE_ABORTED
  end
  
  # is the recording in DONE state?
  def done?
    self.state.intern == RECORDING_STATE_DONE
  end
  
  # is the recording in SCHEDULED state and about to begin?
  def about_to_begin?
    self.state.intern == RECORDING_STATE_SCHEDULED && self.starttime < 90.seconds.from_now
  end
  
  # get relative URL to Recording file storage
  def storage_url
    self.filename ? "/recordings_files/#{File.basename(self.filename)}" : nil
  end

  # get full path and filename to Recording file storage
  def storage_file
    File.join(RAILS_ROOT,'public','recordings_files',"#{self.id}.mp3")
  end
  
  private

  include ActionView::Helpers::TextHelper # we need Rails' truncate method!

  # delete associated MP3 file with recording
  def delete_recorded_file
    # check if the recording is in a legitimate state for deletion
    return false unless RECORDING_STATES_DELETABLE.include?(self.state.intern)

    # delete the produced output file (if existant)
    begin
      mp3_file = self.filename
      File.delete(mp3_file) if mp3_file
    rescue
      # ignore any errors
      logger.warn "File '#{mp3_file}' could not be deleted while destroying recording #{self.id}."
    end
  end
  
  # return a suitable filename replacing any special characters in the given string
  def sanitize_for_filename(string)
    string.gsub(/ä/,'ae').gsub(/Ä/,'Ae').gsub(/ö/,'oe').gsub(/Ö/,'Oe').gsub(/ü/,'ue').gsub(/Ü/,'Ue').gsub(/ß/,'ss').gsub(/[^a-z|A-Z|_,.\-()&%$!@]/,' ').gsub(/ +/,' ')
  end

end
