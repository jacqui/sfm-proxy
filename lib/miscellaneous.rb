get %r{/geometries/([a-z]{2})\.(geojson|topojson)} do |id,extension|
  content_type 'application/json'

  filename = File.expand_path(File.join('..', 'data', extension, 'adm0', "#{id}.#{extension}"), __dir__)

  if File.exist?(filename)
    body = File.read(filename)
    if extension == 'geojson'
      etag_and_return(JSON.load(body)['features'])
    else
      etag_and_return(body, raw: true)
    end
  else
    404
  end
end

get '/countries/:id/geometries' do
  content_type 'application/json'

  criteria = {'division_id' => "ocd-division/country:#{params[:id]}"}

  if params[:classification]
    criteria['classification'] = params[:classification]
  end

  if params[:bbox]
    criteria['geo'] = {
      '$geoIntersects' => {
        '$geometry' => {
          type: 'Polygon',
          coordinates: [[
            [bounding_box[0], bounding_box[1]],
            [bounding_box[2], bounding_box[1]],
            [bounding_box[2], bounding_box[3]],
            [bounding_box[0], bounding_box[3]],
            [bounding_box[0], bounding_box[1]],
          ]]
        }
      },
    }
  end

  response = connection[:geometries].find(criteria).map do |result|
    {
      "type" => "Feature",
      "id" => result['_id'],
      "properties" => {
        "name" => result['name'],
        "classification" => result['classification'],
      },
      "geometry" => result['geo'],
    }
  end

  etag_and_return(response)
end

# @see https://github.com/britg/sinatra-cross_origin#responding-to-options
options '*' do
  response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'

  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

  200
end
