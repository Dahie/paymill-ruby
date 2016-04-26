api_keys = {
  'organisation_1' => "<YOUR_PRIVATE_KEY_1>",
  'organisation_2' => "<YOUR_PRIVATE_KEY_2>"
}

api_keys.each do |api_key_slug, api_key|
  Paymill.add_api_key(api_key_slug, api_key)
end

# to switch between different access keys:

Paymill::Transaction.find('<YOUR_TRANSACTION_ID>', division: 'organisation_1')
