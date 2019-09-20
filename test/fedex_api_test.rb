require 'minitest/autorun'
require 'dotenv/load'
require 'fedex_api'

class FedexApiTest < Minitest::Test
  def setup
    @shipper = {
      account_number: ENV['FEDEX_ACCOUNT_NUMBER'],
      contact: {
        company_name: 'test',
        phone_number: '12345678'
      },
      address: {
           street_lines: [ 'address 1', 'address 2' ],
           city: 'Prague',
           postal_code: '13000',
           country_code: 'CZ'
      }
    }
    @recipient = {
      contact: {
        company_name: 'test2',
        phone_number: '87654321'
      },
      address: {
           street_lines: 'address',
           city: 'Brussels',
           postal_code: '1000',
           country_code: 'BE'
      }
    }
  end

  def test_configuration
    assert FedexApi.currency == 'EUR'
    FedexApi.currency = 'USD'
    assert FedexApi.currency == 'USD'
  end

  def test_request_units
    FedexApi.currency == 'USD'
    service = FedexApi::Service::Rate.new(currency: 'EUR')

    assert service.currency == 'EUR'
    assert service.weight_unit == 'KG'
  end

  def test_pickup_service
    @shipper.delete(:account_number)
    now = DateTime.now

    # no weekends
    if now.wday == 5 || now.wday == 6
      now = DateTime.new(now.year, now.month, now.day + 8 - now.wday, now.hour, now.minute)
    end

    service = FedexApi::Service::Pickup.new
    service.pickup_location = @shipper
    service.ready_timestamp = DateTime.new(now.year, now.month, now.day + 1, 9)
    service.company_close_time = DateTime.new(now.year, now.month, now.day + 1, 18)
    service.packages << { weight: 1 }
    service.remarks = 'Thank you!'
    reply = service.create_pickup

    assert reply.success?
  end


  def test_rate_service
    service = FedexApi::Service::Rate.new
    service.shipper = @shipper
    service.recipient = @recipient
    service.packages << { weight: 1, length: 10, width: 10, height: 10 }
    reply = service.get_rates

    assert reply.success?
  end

  def test_ship_service
    service = FedexApi::Service::Ship.new
    service.shipper = @shipper
    service.recipient = @recipient
    service.packages << { weight: 1, length: 10, width: 10, height: 10 }
    service.value = 10
    service.commodities = {
      description: 'test',
      country_of_manufacture: 'CZ',
      unit_price: 10,
      customs_value: 10
    }
    reply = service.process_shipment

    assert reply.success?
    assert reply.tracking_number
  end

  # Test Server Mock Tracking Numbers
  # https://www.fedex.com/us/developer/webhelp/ws/2019/US/wsdvg/Appendix_F_Test_Server_Mock_Tracking_Numbers.htm

  def test_track_service
    service = FedexApi::Service::Track.new
    reply = service.track('403934084723025', '122816215025810')

    assert reply.success?
    assert_equal 2, reply.tracking_details.size
    assert_equal 'Delivered', reply.tracking_details_for('122816215025810')[:status_detail][:description]
  end
end
