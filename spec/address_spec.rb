require 'spec_helper'

describe 'Spree::Address extended to validate address' do
  let(:ny) { create :state, name: 'New York', abbr: 'NY' }

  # Real address in US
  let(:valid_address) do
    Spree::Address.new address1: '45 Main Street', address2: 'Suite 850',
      city: 'Brooklyn', state: ny, zipcode: 11201, country: ny.country
  end

  # Fake address that looks real
  let(:invalid_address) do
    Spree::Address.new address1: '123 Foo Street', city: 'Albany',
      state: ny, zipcode: '11243', country: ny.country
  end

  let(:blank_address) do
    Spree::Address.new address1: ' ', city: ' ',
      state_name: ' ', zipcode: ' ', country: ny.country
  end

  # Real address in foreign country
  let(:foreign_address) do
    country = create :country, name: 'Germany',
      iso3: 'DEU', iso: 'DE', iso_name: 'GERMANY', numcode: '276'
    Spree::Address.new address1: 'Prinzessinnenstr. 20', city: 'Berlin',
      zipcode: '10969', country: country
  end

  it 'can determine if a US address' do
    expect( valid_address.in_united_states? ).to be true
    expect( foreign_address.in_united_states? ).to be false
  end

  it 'can validate and normalize an valid address' do
    expect( valid_address.deliverable_address? ).to be true
    expect( valid_address.address1 ).to eq '45 Main St'
    expect( valid_address.address2 ).to eq 'Ste 850'
    expect( valid_address.zipcode ).to eq '11201-8200'
  end

  it 'will throw an error if validating a foreign address' do
    expect { foreign_address.deliverable_address? }.to raise_error
  end

  it 'will indicate an invalid address is invalid' do
    expect( invalid_address.deliverable_address? ).to be false
  end

  it 'will indicate an incomplete address is invalid' do
    expect( blank_address.deliverable_address? ).to be false
  end

  it 'will automatically validate an us address' do
    fill_in_required_fields valid_address
    expect( valid_address.valid? ).to be true
    expect( valid_address.address1 ).to eq '45 Main St'
    expect( valid_address.address2 ).to eq 'Ste 850'
    expect( valid_address.zipcode ).to eq '11201-8200'
  end

  it 'will not automatically validate a foreign address' do
    fill_in_required_fields foreign_address
    expect( foreign_address.valid? ).to be true
  end

  # There are a few errors that we wnat to bubble up as they are due to
  # availability or configuration problems. These should generate an error
  # that the ops team can resolve.
  it 'will allow smarty street errors to bubble up' do
    begin
      WebMock.enable!
      stub_request(:post, /^https\:\/\/api.smartystreets.com\/street\-address/).to_return status: 500
      expect{ valid_address.deliverable_address? }.to raise_error
    ensure
      WebMock.disable!
    end
  end

  def fill_in_required_fields address
    address.firstname = 'John'
    address.lastname = 'Doe'
    address.phone = '555-123-4567'
  end

end
