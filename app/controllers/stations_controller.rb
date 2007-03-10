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

# provide administrative GUI for defining radio stations (scaffolded!)
class StationsController < ApplicationController
  # GET /stations
  # GET /stations.xml
  def index
    @stations = Station.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @stations.to_xml }
    end
  end

  # GET /stations/1.xml
  def show
    @station = Station.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @station.to_xml }
    end
  end

  # GET /stations/new
  def new
    @station = Station.new
  end

  # GET /stations/1;edit
  def edit
    @station = Station.find(params[:id])
  end

  # POST /stations
  # POST /stations.xml
  def create
    @station = Station.new(params[:station])

    respond_to do |format|
      if @station.save
        flash[:notice] = _('Station was successfully created.')
        format.html { redirect_to stations_url }
        format.xml  { head :created, :location => station_url(@station) }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @station.errors.to_xml }
      end
    end
  end

  # PUT /stations/1
  # PUT /stations/1.xml
  def update
    @station = Station.find(params[:id])

    respond_to do |format|
      if @station.update_attributes(params[:station])
        flash[:notice] = _('Station was successfully updated.')
        format.html { redirect_to stations_url }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @station.errors.to_xml }
      end
    end
  end

  # DELETE /stations/1
  # DELETE /stations/1.xml
  def destroy
    @station = Station.find(params[:id])
    @station.destroy

    respond_to do |format|
      format.html { redirect_to stations_url }
      format.xml  { head :ok }
    end
  end
end
