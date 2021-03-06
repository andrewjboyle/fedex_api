module FedexApi
  module Reply
    class Track < Base
      def tracking_details
        @tracking_details ||= begin
          if body[:completed_track_details].is_a? Array
            # multiple packages
            track_details = body[:completed_track_details].map { |d| d[:track_details] }
          else
            # single package
            track_details = [ body[:completed_track_details][:track_details] ]
          end

          track_details.reduce({}) do |res, details|
            if details.is_a? Array
              fail unless details.map { |d| d[:tracking_number] }.uniq.length == 1

              # TODO: find out why there are multiple tracking details for one package
              details = details.last
            end

            tracking_number = details.delete(:tracking_number)
            res[tracking_number] = details
            res
          end
        end
      end

      def tracking_details_for(number)
        tracking_details[number.to_s]
      end
    end
  end
end
