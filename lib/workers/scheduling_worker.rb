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

# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.

# schedule recordings every minute
class SchedulingWorker < BackgrounDRb::Rails

  repeat_every 60.seconds
  @@mutex = Mutex.new

  def do_work(args)
    # make sure schedule_recordings is not run twice at the same time
    @@mutex.synchronize do
      begin
        Recording.schedule_recordings
      ensure # make sure the DB is connection is always terminated even in case of errors
        ActiveRecord::Base.connection.disconnect!
      end
    end
  end

end
