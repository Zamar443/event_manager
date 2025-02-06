require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

# Initialize CivicInfo API
civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

# Function to clean zipcodes
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

# Function to fetch legislators by zipcode
def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators.officials.map(&:name).join(", ")
  rescue
    'You can find your representatives at www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

# Read CSV file
CSV.foreach('event_attendees.csv', headers: true, header_converters: :symbol) do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  # Read and process ERB template
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  form_letter = erb_template.result(binding)

  # Create output directory if not exists
  Dir.mkdir('output') unless Dir.exist?('output')

  # Generate a unique ID for the file
  id = row[:id] || name.downcase.gsub(" ", "_")

  filename = "output/thanks_#{id}.html"

  # Save the personalized thank-you letter
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

  puts "Generated letter for #{name} (#{zipcode})"
end
