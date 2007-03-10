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

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  init_gettext "radio"

  # change the preferred language for gettext by setting the :lang cookie
  def set_language(lang = params[:lang])
    cookies[:lang] = lang
    redirect_to :action => 'index'
  end

end
