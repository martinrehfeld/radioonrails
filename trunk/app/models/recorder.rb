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

require 'session'

# threaded recording and convertion to MP3 using Mplayer and LAME.
class Recorder

  attr_reader :stream_url, :output_filename

  MPLAYER_CMD = 'mplayer -quiet -prefer-ipv4 -nolirc -nojoystick -ao pcm:file=__TMPFILE__ -vc null -vo null'
  LAME_CMD = 'lame --nohist'
  PS_CMD = "ps auxww | grep mplayer | grep '__TMPFILE__' | awk '{print $2}'"

  # create new Recorder and start recording immediately
  def initialize(stream_url, output_filename)
    log "Starting recording of stream '#{stream_url}' to output file '#{output_filename}'" 
    @stream_url = stream_url
    @output_filename = output_filename
    @tmpfile = Tempfile.new('radioRecorder', File.join(RAILS_ROOT,'tmp')) # make Tempfile...
    @tmpfile.close # ... and close right away
    @tmpfile = @tmpfile.path # we are just interested in the name
    system("rm #{@tmpfile} && mkfifo -m 600 #{@tmpfile}") # we use the name for the FIFO

    mplayer_stdin = StringIO.new
    mplayer_thread = Thread.new do
# TODO: handle final errors -> do not retry endlessly
      sh = Session.new
      output = ''
      begin # retry until actual audio encoding took place or mplayer was killed intentionally
        sh.execute("#{MPLAYER_CMD.sub(/__TMPFILE__/,@tmpfile)} #{@stream_url}", :stdin => mplayer_stdin) {|o,e| log o; log e; output << o if o; output << e if e }
      end until output.include?('Starting playback...') || output.include?('MPlayer interrupted by signal')
      sh.close
    end
    lame_stdin = StringIO.new
    lame_thread = Thread.new do
      sh = Session.new
      sh.execute("#{LAME_CMD} #{@tmpfile} #{@output_filename}", :stdin => lame_stdin) {|o,e| log o; log e }
      sh.close
    end
  end
  
  # end a running recording (kill Mplayer)
  def end_recording
    log "Stopping recording of stream '#{@stream_url}' to output file '#{@output_filename}'" 
    sh = Session.new
    kill_cmd = 'kill'
    begin
      pids = []; sh.execute(PS_CMD.sub(/__TMPFILE__/,@tmpfile)) { |o,e| pids << o.to_i }
      sh.execute("#{kill_cmd} #{pids.join(' ')}") {|o,e| log o; log e } if pids.length > 0
      kill_cmd = 'kill -9'
    end until pids.length == 0 # make sure no processes are left over
    sh.close
    begin File.unlink(@tmpfile); rescue; end # ignore errors on tmp file deletion
    log "Recording completed."
  end

  private

  # log messages to Rails default log file (skipping certain content)
  def log(msg)
     RAILS_DEFAULT_LOGGER.info msg.chomp if msg && !(msg =~ /Cache fill:/)
  end
  
end
