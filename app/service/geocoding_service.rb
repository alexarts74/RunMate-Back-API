# class GeocodingService
#   include HTTParty
#   base_uri 'https://api-adresse.data.gouv.fr'

#   def self.search_cities(query)
#     response = get('/search', query: {
#       q: query,
#       type: 'municipality',
#       limit: 10
#     })
# #
#     return [] unless response.success?

#     response['features'].map do |feature|
#       {
#         city: feature['properties']['city'],
#         postcode: feature['properties']['postcode'],
#         department: feature['properties']['context'].split(',')[0],
#         coordinates: feature['geometry']['coordinates'].reverse,
#         full_name: "#{feature['properties']['city']} (#{feature['properties']['postcode']})"
#       }
#     end
#   end
# end
