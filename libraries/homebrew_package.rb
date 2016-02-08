#
# Author:: Joshua Timberman (<jtimberman@opscode.com>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
# Cookbook Name:: homebrew
# Libraries:: homebrew_package
#
# Copyright 2011-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider/package'
require 'chef/resource/package'
require 'chef/platform'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Homebrewalt < Package

        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(current_installed_version)

          @current_resource
        end

        def install_package(name, version)
          brew('install', @new_resource.options, name)
        end

        def upgrade_package(name, version)
          if shell_out!("brew outdated | grep #{name}", :returns => [0,1]).exitstatus.zero?
            brew('upgrade', name)
          end
        end

        def remove_package(name, version)
          brew('uninstall', @new_resource.options, name)
        end

        # Homebrew doesn't really have a notion of purging, so just remove.
        def purge_package(name, version)
          @new_resource.options = ((@new_resource.options || "") << " --force").strip
          remove_package(name, version)
        end

        protected
        def brew(*args)
          get_response_from_command("sudo -u #{node['current_user']} brew #{args.join(' ')}")
        end

        def current_installed_version
          get_version_from_command("brew list --versions | awk '/^#{@new_resource.package_name} / { print $2 }'")
        end

        def candidate_version
          get_version_from_command("brew info #{@new_resource.package_name} | awk '/^#{@new_resource.package_name}: / { print $3 }'")
        end

        def get_version_from_command(command)
          version = get_response_from_command(command).chomp
          version.empty? ? nil : version
        end

        def get_response_from_command(command)
          output = shell_out!(command, :timeout => 10000)
          output.stdout
        end
      end
      Homebrew = Homebrewalt
    end
  end
end

Chef::Platform.set :platform => :mac_os_x_server, :resource => :package, :provider => Chef::Provider::Package::Homebrewalt
Chef::Platform.set :platform => :mac_os_x, :resource => :package, :provider => Chef::Provider::Package::Homebrewalt
