module FedexApi
  module Service
    class Rate < Base
      include FedexApi::Service::RequestedShipment

      WSDL_FILENAME = 'RateService_v24.wsdl'
      VERSION = {
        service_id: 'crs',
        major: 24,
        intermediate: 0,
        minor: 0
      }

      attr_accessor :shipper, :recipient

      def add_package(hash)
        @packages << hash

        hash
      end

      def get_rates(options = {})
        options = {
          return_transit_and_commit: true,
          requested_shipment: {
            ship_timestamp: Time.now.iso8601,
            service_type: 'INTERNATIONAL_PRIORITY',
            packaging_type: 'YOUR_PACKAGING',
            total_weight: total_weight,
            shipper: shipper,
            recipient: recipient,
            shipping_charges_payment: {
              payment_type: 'SENDER',
              payor: {
                responsible_party: {
                  account_number: ENV['FEDEX_ACCOUNT_NUMBER']
                }
              }
            },
            package_count: @packages.count,
            requested_package_line_items: requested_package_line_items
          }
        }.merge(options)

        response = call(:get_rates, options)
        FedexApi::Reply::Base.new(response.body[:rate_reply])
      end
    end
  end
end
