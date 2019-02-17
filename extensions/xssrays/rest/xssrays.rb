#
# Copyright (c) 2006-2019 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - http://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
  module Extension
    module Xssrays

      # This class handles the routing of RESTful API requests for XssRays
      class XssraysRest < BeEF::Core::Router::Router

        HB = BeEF::Core::Models::HookedBrowser
        XS = BeEF::Core::Models::Xssraysscan
        XD = BeEF::Core::Models::Xssraysdetail

        # Filters out bad requests before performing any routing
        before do
          config = BeEF::Core::Configuration.instance
          @nh = BeEF::Core::Models::NetworkHost
          @ns = BeEF::Core::Models::NetworkService

          # Require a valid API token from a valid IP address
          halt 401 unless params[:token] == config.get('beef.api_token')
          halt 403 unless BeEF::Core::Rest.permitted_source?(request.ip)

          headers 'Content-Type' => 'application/json; charset=UTF-8',
                  'Pragma' => 'no-cache',
                  'Cache-Control' => 'no-cache',
                  'Expires' => '0'
        end

        # Returns the entire list of rays for all zombies
        get '/rays' do
          begin
            rays = XD.all(:unique => true, :order => [:id.asc])
            count = rays.length

            result = {}
            result[:count] = count
            result[:rays] = []
            rays.each do |ray|
              result[:rays] << ray2hash(ray)
            end
            result.to_json
          rescue StandardError => e
            print_error "Internal error while retrieving rays (#{e.message})"
            halt 500
          end
        end

        # Returns all rays given a specific hooked browser id
        get '/rays/:id' do
          begin
            id = params[:id]

            rays = XD.all(:hooked_browser_id => id, :unique => true, :order => [:id.asc])
            count = rays.length

            result = {}
            result[:count] = count
            result[:rays] = []
            rays.each do |ray|
              result[:rays] << ray2hash(ray)
            end
            result.to_json
          rescue InvalidParamError => e
            print_error e.message
            halt 400
          rescue StandardError => e
            print_error "Internal error while retrieving rays list for hooked browser with id #{id} (#{e.message})"
            halt 500
          end
        end

        # Returns the entire list of scans for all zombies
        get '/scans' do
          begin
            scans = XS.all(:unique => true, :order => [:id.asc])
            count = scans.length

            result = {}
            result[:count] = count
            result[:scans] = []
            scans.each do |scan|
              result[:scans] << scan2hash(scan)
            end
            result.to_json
          rescue StandardError => e
            print_error "Internal error while retrieving scans (#{e.message})"
            halt 500
          end
        end

        # Returns all scans given a specific hooked browser id
        get '/scans/:id' do
          begin
            id = params[:id]

            scans = XS.all(:hooked_browser_id => id, :unique => true, :order => [:id.asc])
            count = scans.length

            result = {}
            result[:count] = count
            result[:scans] = []
            scans.each do |scans|
              result[:scans] << scan2hash(scan)
            end
            result.to_json
          rescue InvalidParamError => e
            print_error e.message
            halt 400
          rescue StandardError => e
            print_error "Internal error while retrieving scans list for hooked browser with id #{id} (#{e.message})"
            halt 500
          end
        end

        # Starts a new scan on the specified zombie ID
=begin
        post '/scan/:id' do
          begin
            # TODO
          rescue InvalidParamError => e
            print_error e.message
            halt 400
          rescue StandardError => e
            print_error "Internal error while retrieving host with id #{id} (#{e.message})"
            halt 500
          end
        end
=end

        private

        # Convert a ray object to JSON
        def ray2hash(ray)
          {
            :id => ray.id,
            :hooked_browser_id => ray.hooked_browser_id,
            :vector_name => ray.vector_name,
            :vector_method => ray.vector_method,
            :vector_poc => ray.vector_poc
          }
        end

        # Convert a scan object to JSON
        def scan2hash(scan)
          {
            :id => scan.id,
            :hooked_browser_id => scan.hooked_browser_id,
            :scan_start=> scan.scan_start,
            :scan_finish=> scan.scan_finish,
            :domain => scan.domain,
            :cross_domain => scan.cross_domain,
            :clean_timeout => scan.clean_timeout,
            :is_started => scan.is_started,
            :is_finished => scan.is_finished
          }
        end

        # Raised when invalid JSON input is passed to an /api/xssrays handler.
        class InvalidJsonError < StandardError
          DEFAULT_MESSAGE = 'Invalid JSON input passed to /api/xssrays handler'

          def initialize(message = nil)
            super(message || DEFAULT_MESSAGE)
          end
        end

        # Raised when an invalid named parameter is passed to an /api/xssrays handler.
        class InvalidParamError < StandardError
          DEFAULT_MESSAGE = 'Invalid parameter passed to /api/xssrays handler'

          def initialize(message = nil)
            str = "Invalid \"%s\" parameter passed to /api/xssrays handler"
            message = sprintf str, message unless message.nil?
            super(message)
          end
        end
      end
    end
  end
end
