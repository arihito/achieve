# paths
app_path = "/var/www/achieve"
working_directory "#{app_path}"
pid	"#{app_path}/tmp/pids/unicorn.pid"

# listen
listen "#{app_path}/tmp/sockets/unicorn.sock",backlog: 64

# logging
stderr_path "#{app_path}/log/unicorn.stderr.log"
stdout_path "#{app_path}/log/unicorn.stdout.log"

# workers
worker_processes3

# use correct Gemfile on restarts
before_exec do |server|
	ENV['BUNDLE_GEMFILE'] = "#{app_path}/Gemfile"
end

# preload
preload_app true

before_fork do |server, worker|
	# the following is highly recomended for Rails + "preload_app true"
	# as there's no need for the master precess to hold a connection
	if defined?(ActiveRecord::Base)
		ActiveRecord::Base.connection.disconnect!
	end

	# Before forking, kill the master precess that belongs to the .oldbin PID.
	# This enables 0 downtime deploys.
	old_pid = "#{server.config[:pid]}.oldbin"
	if File.exists?(old_pid)&& server.pid != old_pid
		begin
			Process.kill("QUIT", File.read(old_pid).to_i)
			rescure Errno::ENOENT, Errno::ESRCH
			# someone else did our job for us
		end
	end
end

after_fork do |server, worker|
	if defined?(ActiveRecord::Base)
		ActiveRecord::Base.establish_connection
	end
end
