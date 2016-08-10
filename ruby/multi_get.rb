require 'thread'
require 'net/http'

# Date   : 28th July 2014
# Author : Prasad Velidi
#
# MultiGet provides a multi-threaded download manager.
#
# The threads are created dynamically as the urls are added and they will
# be destroyed dynamically as soon as the download queue is exhausted. Any
# newly added urls will spawn new threads and so on.
#
# MultiGet doesn't block the calling program when a new url is being submitted.
# It returns to the caller after enrolling it as a job. However, it provides a
# callback mechanism meaning which you can submit a block to the add() method
# and the thread executing the job yields to the block passed with job details.
#
# Since the MultiGet doesn't block the calling program, the calling program
# should stay alive until all the items on the queue were downloaded. This can
# be done by calling the #join() method in the main thread. Since this method
# tries to join all threads spawned so far, the main thread will stay alive until
# all the threads are done and destroyed.

class MultiGet

	# Initialize the MultiGet object allowing 10 threads as maximum by default.
	# params::
	# * *maxthreads* -> limit maximum threads that can be spawned by MultiGet
	# returns:: nothing
	#
	#	require 'multi_get'
	#	# To make MultiGet work with 15 threads ..
	#	downloader = MultiGet.new(15)
	#	=> ...
	def initialize(maxthreads = 10)
		# @index is an index into download @queue, accessed and maintained by threads.
		@index      = 0
		# @queue is an array of hashes with each hash representing the job information.
		@queue      = []
		# @threads is an array of thread objects already created and is used by join().
		@threads    = []
		@semaphore  = Mutex.new
		@maxthreads = maxthreads
	end

	# Download the url off the internet and hand over the response object to caller.
	# params::
	# * *url* -> points to the http link that needs to be downloaded
	# returns:: *response* -> return response object of type Net::HTTPFound class
	#
	#	=> ...
	#	# To download a url without getting the threads created ..
	#	response = downloader.get("http://google.com/")
	#	puts response.inspect
	def get(url)
		uri = URI(url)
		begin
			response = Net::HTTP.get_response(uri)
		rescue SocketError => err
			response = nil
		end
		case response
			when Net::HTTPInformation then
			when Net::HTTPSuccess then
			when Net::HTTPRedirection then
				while response.is_a?(Net::HTTPRedirection) && !response.is_a?(Net::HTTPSuccess)
					uri = URI(response['location'])
					response = Net::HTTP.get_response(uri)
				end
			when Net::HTTPClientError then
			when Net::HTTPServerError then
			else
				# HTTPUnknownResponse
		end
		response
	end

	# Submits the url as a job to the queue and registers given block as callback.
	# params::
	# * *url* -> points to the http link that needs to be downloaded
	# returns:: true
	#
	#	=> ...
	#	# When this job is executed by a thread, the response object is yielded back to block
	#	downloader.add("http://google.com/") { |job|
	#		puts job.inspect
	#	}
	#	=> ...
	def add(url, &callback)					# :yields: job
		job = Hash.new
		job[:id]         = @queue.length
		job[:url]        = url
		job[:callback]   = callback
		job[:content]    = nil
		job[:size]       = nil
		job[:start_time] = nil
		job[:end_time]   = nil
		job[:speed]      = nil
		job[:code]       = nil
		job[:message]    = nil
		job[:response]   = nil
		@queue.push(job)
		@threads.push(replicate) if @threads.length < @maxthreads
		true
	end

	# Returns the number of jobs pushed to download queue so far.
	# returns:: number of jobs currently present on download queue
	#
	#	=> ...
	#	# Since queue is not exposed publicly, length helps you iterate over the queue
	#	(0..downloader.length - 1).each { |index|
	#		downloader[index].inspect
	# 	}
	def length
		@queue.length
	end

	# Joins all the download threads so that the calling thread waits until all
	# the download threads are done and destroyed
	# returns:: true
	#
	#	=> ...
	#	(0...10).each {
	#		downloader.add("http://google.com/") { |job|
	#			puts job.inspect
	# 		}
	# 	}
	#	# Since we got nothing to do, join the threads created by downloader to keep alive.
	#	downloader.join
	def join
		@threads.each { |thread|
			thread.join
		}
	end

	# Returns the job hash at index from queue to caller.
	# params::
	# * *index* -> index of job in the download queue
	# returns:: job object of type Hash
	#
	#	=> ...
	#	(0..downloader.length - 1).each { |index|
	#		# if you need to access the job data later, use overridden subscript operator [].
	#		downloader[index].inspect
	# 	}
	#	=> ...
	def [](index)
		@queue[index]
	end

	private

	# Create a thread object for handling downloads and return add() i.e its caller.
	# returns:: thread object of type Thread
	#
	#	=> ...
	#	# replicate creates a new thread and returns the thread object back to caller.
	#	@threads.push(replicate) if @threads.length < @maxthreads
	#	=> ...
	def replicate
		Thread.new {
			# Each thread loops continuously to either pick up a job a) when it started fresh or
			# b) when its done with previous job OR to kill itself when jobs are not available
			while true
				job = nil
				@semaphore.synchronize {
					if @index < @queue.length
						job = @queue[@index]
						@index += 1
					end
				}
				if job.nil?
					@semaphore.synchronize {
						0.upto(@threads.length - 1) { |index|
							if Thread.current.__id__ == @threads[index].__id__
								@threads.delete_at(index)
							end
						}
						Thread.exit
					}
				else
					t1 = Time.now
					response = get(job[:url])
					t2 = Time.now
					unless response.nil?
						job[:content]    = response.body
						job[:size]       = response.body.length
						job[:start_time] = t1
						job[:end_time]   = t2
						job[:speed]      = response.body.length / (1024 * (t2 - t1).ceil)
						job[:code]       = response.code
						job[:message]    = response.message
						job[:response]   = response
						unless job[:callback].nil?
							job[:callback].yield job
							STDOUT.flush
						end
					end
				end
			end
		}
	end
end
