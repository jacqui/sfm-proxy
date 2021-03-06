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
    criteria['geo'] = bounding_box_criterion
  end

  response = connection[:geometries].find(criteria).projection({
    '_id' => 1,
    'name' => 1,
    'classification' => 1,
    'geo' => 1,
  }).map do |result|
    feature_formatter(result, result['geo'])
  end

  etag_and_return(response)
end
