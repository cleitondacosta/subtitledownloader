#!/usr/bin/ruby

# Based on: https://github.com/manojmj92/subtitle-downloader

require 'digest'
require 'open-uri'
require 'net/http'

class SubtitleDownloader
  attr_accessor :movie_path, :subtitle_path, :language

  def initialize(movie_path, language)
    @movie_path = movie_path
    @language = language

    basedir = File.dirname(movie_path)
    base_subtitle_name = File.basename(movie_path, ".*") + ".srt"
    @subtitle_path = File.join(basedir, base_subtitle_name)
  end

  def download_from_subdb
    url = "http://api.thesubdb.com/?action=download&hash="\
          + subdb_movie_hash\
          + "&language=#{@language}"

    headers = { "User-Agent" => "SubDB/1.0 (subtitle-downloader/1.0;" }

    try_to_download_subtitle(url, headers)
  end

  private

  def subdb_movie_hash
    handle_movie_path_errors
    
    readsize = 64 * 1024
    data = nil

    File.open(@movie_path, "rb") do |movie|
      data = movie.read(readsize)
      movie.seek(-readsize, IO::SEEK_END)
      data += movie.read(readsize)
    end

    return Digest::MD5.hexdigest(data)
  end

  def try_to_download_subtitle(url, headers)
    handle_movie_path_errors
    handle_subtitle_path_errors
    handle_language_errors

    File.open(@subtitle_path, "wb") do |subtitle|
      begin
        IO.copy_stream(URI.open(url, headers), subtitle)
        puts "Subtitle downloaded."
      rescue OpenURI::HTTPError => error
        http_error_message = error.message
        puts "Subtitle not found for #{@movie_path} in #{@language} language."
        puts "#{url}: #{http_error_message}"
        File.delete(subtitle) if File.exist?(subtitle)
      # Workaround
      rescue StandardError => error
        $stderr.puts "Error: #{error.message}"
      end
    end
  end

  def handle_movie_path_errors
    unless File.exist?(@movie_path)
      $stderr.puts "Error: File #{@movie_path} doesn't exists."
      exit 1
    end

    unless File.file?(@movie_path)
      $stderr.puts "Error: File #{@movie_path} isn't a regular file."
      exit 1
    end

    known_extensions = %w[
     .avi .mp4 .mkv .mpg
     .mpeg .mov .rm .vob
     .wmv .flv .3gp. .3g2
    ]
    movie_extension = File.extname(@movie_path)
    
    unless known_extensions.include?(movie_extension)
      puts "This file doesn't seems to be a movie."\
           " Are you sure you want to continue? [y/n]"
      exit unless $stdin.gets.chomp =~ /^[yY]$/
    end
  end
  
  def handle_subtitle_path_errors
    if File.exist?(@subtitle_path)
      puts "The movie already has a subtitle. Do you want to delete it? [y/n]"
      $stdin.gets.chomp =~ /^[yY]$/ ? File.delete(@subtitle_path) : exit
    end
  end

  def handle_language_errors
    supported_languages = try_to_get_supported_language_array 

    unless supported_languages.include?(@language)
      $stderr.puts "Error: Language #{@language} isn't supported."
      $stderr.puts "Supported languages: #{supported_languages.join(", ")}"
      exit 1
    end
  end

  def try_to_get_supported_language_array
    begin
      uri = URI("http://api.thesubdb.com/?action=languages")
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "SubDB/1.0 (subtitle-downloader/1.0;"

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
    rescue StandardError => error
      $stderr.puts "Error: Failed to GET supported languages:"
      $stderr.puts "#{error.message}"
      exit 1
    end

    supported_language_array = response.body.split(',')

    return supported_language_array
  end
end

# Main file
if ARGV.size != 2
  $stderr.puts "Usage: subdownload.rb MOVIE_FILE LANGUAGE"
  exit 1
end

movie = ARGV[0]
language = ARGV[1]
sub_downloader = SubtitleDownloader.new(movie, language)
sub_downloader.download_from_subdb
