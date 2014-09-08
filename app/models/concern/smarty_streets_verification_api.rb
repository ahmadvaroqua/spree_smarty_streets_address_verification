module SmartyStreetsVerificationAPI

  # This address verifier uses the LiveAddress API in order to verify and return the standard
  # address for every one entered.
  # The input is a hash with address information:
  #
  # location_hash = {
  #   street: "123 W 117th Street",
  #   city: "New York",
  #   state: "NY",
  #   zipcode: "10026"
  # }
  #
  # the verify() method uses the smartystreets gem in order to make a call to the api and returns
  # an address, pieces of which are in the components or metadata sub results
  # {:input_index=>0,
  #  :candidate_index=>0,
  #  :delivery_line_1=>"123 W 117th St",
  #  :last_line=>"New York NY 10026-2283",
  #  :delivery_point_barcode=>"100262283998",
  #  :components=>
  #   {:primary_number=>"123",
  #    :street_predirection=>"W",
  #    :street_name=>"117th",
  #    :street_suffix=>"St",
  #    :city_name=>"New York",
  #    :state_abbreviation=>"NY",
  #    :zipcode=>"10026",
  #    :plus4_code=>"2283",
  #    :delivery_point=>"99",
  #    :delivery_point_check_digit=>"8"},
  #  :metadata=>
  #   {:record_type=>"H",
  #    :zip_type=>"Standard",
  #    :county_fips=>"36061",
  #    :county_name=>"New York",
  #    :carrier_route=>"C006",
  #    :congressional_district=>"13",
  #    :building_default_indicator=>"Y",
  #    :rdi=>"Residential",
  #    :elot_sequence=>"0300",
  #    :elot_sort=>"A",
  #    :latitude=>40.80338,
  #    :longitude=>-73.95019,
  #    :precision=>"Zip9",
  #    :time_zone=>"Eastern",
  #    :utc_offset=>-5.0,
  #    :dst=>true},
  #  :analysis=>
  #   {:dpv_match_code=>"D",
  #    :dpv_footnotes=>"AAN1",
  #    :dpv_cmra=>"N",
  #    :dpv_vacant=>"N",
  #    :active=>"Y",
  #    :footnotes=>"H#N#"}}

  # Returns false if the address is not valid. Returns the normalized address
  # if the address is valid. The address components are specified via keyword
  # arguments named the same as in the SmartyStreets documentation
  #
  # An ArgumentError will be raised if the Smarty Streets API keys are not set.
  def deliverable_address? ** params

    SmartyStreets.set_auth(ENV['SMARTY_STREETS_AUTH_ID'], ENV['SMARTY_STREETS_AUTH_TOKEN'])

    # Build URI we are querying
    uri = URI.parse "https://api.smartystreets.com/street-address?#{params.to_query}"
    response = Net::HTTP.get_response uri
    raise VerificationError, response.code if response.code == 200
    response.body
  end


  def check_config
    # Check for API keys and add to params sent to Smarty Streets
    raise ArgumentError,
          'SMARTY_STREETS_AUTH_ID and SMARTY_STREETS_AUTH_TOKEN must be specified by the environment'
    if ENV['SMARTY_STREETS_AUTH_ID'].blank? || ENV['SMARTY_STREETS_AUTH_TOKEN'].blank?

    end

    private
    def self.verify(location_hash = nil)
      response = SmartyStreets::StreetAddressApi.call(
          SmartyStreets::StreetAddressRequest.new(
              location_hash
          )
      )
    rescue => e
      Rails.logger.error("Error verifying address for location hash: #{location_hash}: #{e.message}")
      {}
    end
  end

end


